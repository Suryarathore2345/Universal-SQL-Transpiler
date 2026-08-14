CREATE OR ALTER VIEW ${os_bi_coredw}.student_activity_rolling_period_view AS
WITH students_lessons AS (
    SELECT
        slp.student_dw_id,
        sch.school_dw_id,
        COUNT(
            CASE
                WHEN slp.lo_status = 'Completed'
                     AND slp.local_date BETWEEN DATEADD(DAY, -7, CONVERT(DATE, GETDATE()))
                                           AND DATEADD(DAY, -1, CONVERT(DATE, GETDATE()))
                THEN slp.lo_attempted
            END
        ) AS lessons_completed_last7d,
        COUNT(
            CASE
                WHEN slp.lo_status = 'Completed'
                     AND slp.local_date BETWEEN DATEADD(DAY, -14, CONVERT(DATE, GETDATE()))
                                           AND DATEADD(DAY, -8, CONVERT(DATE, GETDATE()))
                THEN slp.lo_attempted
            END
        ) AS lessons_completed_prev7d
    FROM ${rs_bi_coredw}.students_lesson_progress slp
    INNER JOIN ${rs_bi_coredw}.bi_student_dim st
        ON st.student_dw_id = slp.student_dw_id
       AND st.student_status = 1
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim sch
        ON sch.school_dw_id = st.student_school_dw_id
    INNER JOIN (
        SELECT DISTINCT
            cts.class_dw_id,
            cts.section_dw_id,
            dcaa.caa_activity_dw_id AS instructional_plan_item_lo_dw_id
        FROM ${rs_bi_coredw}.class_total_students cts
        INNER JOIN ${rs_coredw}.dim_course_activity_association dcaa
            ON dcaa.caa_course_id = cts.instructional_plan_id
           AND dcaa.caa_activity_type = 1
           AND dcaa.caa_activity_is_optional = 0      -- was "IS FALSE"
        INNER JOIN ${rs_coredw}.dim_learning_objective dip_dlo
            ON dcaa.caa_activity_dw_id = dip_dlo.lo_dw_id
           AND ISNULL(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
        WHERE cts.class_title NOT LIKE '%power skills%'
          AND cts.class_title NOT LIKE '%extra resources%'
          AND cts.class_gen_subject <> 'core stars'
    ) cl
        ON cl.class_dw_id = slp.fle_class_dw_id
       AND cl.section_dw_id = slp.student_section_dw_id
       AND cl.instructional_plan_item_lo_dw_id = slp.lo_attempted
    GROUP BY
        slp.student_dw_id,
        sch.school_dw_id
),
active_students_period AS (
    SELECT
        sl.student_dw_id,
        sl.school_dw_id,
        ISNULL(slo.lessons_completed_last7d, 0) AS lessons_completed_last7d,
        ISNULL(slo.lessons_completed_prev7d, 0) AS lessons_completed_prev7d,
        COUNT(DISTINCT
            CASE
                WHEN CONVERT(DATE, sl.login_local_date_time)
                     BETWEEN DATEADD(DAY, -7, CONVERT(DATE, GETDATE()))
                         AND DATEADD(DAY, -1, CONVERT(DATE, GETDATE()))
                THEN CONVERT(DATE, sl.login_local_date_time)
            END
        ) AS active_days_last7d,
        COUNT(DISTINCT
            CASE
                WHEN CONVERT(DATE, sl.login_local_date_time)
                     BETWEEN DATEADD(DAY, -14, CONVERT(DATE, GETDATE()))
                         AND DATEADD(DAY, -8, CONVERT(DATE, GETDATE()))
                THEN CONVERT(DATE, sl.login_local_date_time)
            END
        ) AS active_days_prev7d,
        COUNT(DISTINCT
            CASE
                WHEN CONVERT(DATE, sl.login_local_date_time)
                     BETWEEN DATEADD(DAY, -30, CONVERT(DATE, GETDATE()))
                         AND DATEADD(DAY, -1, CONVERT(DATE, GETDATE()))
                THEN CONVERT(DATE, sl.login_local_date_time)
            END
        ) AS active_days_last30d,
        COUNT(DISTINCT
            CASE
                WHEN CONVERT(DATE, sl.login_local_date_time)
                     BETWEEN DATEADD(DAY, -60, CONVERT(DATE, GETDATE()))
                         AND DATEADD(DAY, -31, CONVERT(DATE, GETDATE()))
                THEN CONVERT(DATE, sl.login_local_date_time)
            END
        ) AS active_days_prev30d
    FROM ${rs_bi_coredw}.student_login sl
    LEFT JOIN students_lessons slo
        ON slo.student_dw_id = sl.student_dw_id
       AND slo.school_dw_id = sl.school_dw_id
    GROUP BY
        sl.student_dw_id,
        sl.school_dw_id,
        ISNULL(slo.lessons_completed_last7d, 0),
        ISNULL(slo.lessons_completed_prev7d, 0)
),
student_onboarding AS (
    SELECT DISTINCT
        student_dw_id,
        sl.school_dw_id,
        FIRST_VALUE(login_local_date_time) OVER (
            PARTITION BY student_dw_id, sl.school_dw_id
            ORDER BY login_local_date_time ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS student_first_login_date,
        FIRST_VALUE(login_local_date_time) OVER (
            PARTITION BY student_dw_id, sl.school_dw_id
            ORDER BY login_local_date_time DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS student_last_login_date
    FROM ${rs_bi_coredw}.student_login sl
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim ds
        ON ds.school_dw_id = sl.school_dw_id
       AND CONVERT(DATE, login_local_date_time) >= ds.academic_year_start_date
)
SELECT DISTINCT
    dsc.tenant_name,
    dsc.school_dw_id,
    dsc.school_id,
    dsc.school_name,
    dsc.school_alias AS adek_id,
    dsc.school_city_name,
    dsc.school_organisation,
    dsc.organisation_dw_id,
    dg.grade_k12grade AS grade,
    dse.section_dw_id,
    dse.section_name AS section,
    ds.student_dw_id,
    ds.student_id,
    ds.student_special_needs,
    ds.student_tags,
    ds.student_first_created_date,
    so.student_first_login_date,
    so.student_last_login_date,
    CONVERT(VARCHAR(4), YEAR(dsc.academic_year_start_date)) + '-' +
    CONVERT(VARCHAR(4), YEAR(dsc.academic_year_end_date)) AS academic_year,
    ISNULL(asp.active_days_last7d, 0)       AS active_days_last7d,
    ISNULL(asp.active_days_prev7d, 0)       AS active_days_prev7d,
    ISNULL(asp.active_days_last30d, 0)      AS active_days_last30d,
    ISNULL(asp.active_days_prev30d, 0)      AS active_days_prev30d,
    ISNULL(asp.lessons_completed_last7d, 0) AS lessons_completed_last7d,
    ISNULL(asp.lessons_completed_prev7d, 0) AS lessons_completed_prev7d
FROM ${rs_bi_coredw}.bi_student_dim ds
INNER JOIN ${rs_coredw}.dim_section dse
    ON ds.student_section_dw_id = dse.section_dw_id
   AND dse.section_status = 1
INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
    ON dsc.school_id
     = dse.school_id
INNER JOIN ${rs_coredw}.dim_grade dg
    ON dse.grade_id = dg.grade_id
   AND dg.grade_dw_id = ds.student_grade_dw_id
   AND dsc.academic_year_id = dg.academic_year_id
LEFT JOIN active_students_period asp
    ON asp.student_dw_id = ds.student_dw_id
   AND asp.school_dw_id = ds.student_school_dw_id
LEFT JOIN student_onboarding so
    ON ds.student_dw_id = so.student_dw_id
   AND ds.student_school_dw_id = so.school_dw_id
WHERE ds.student_status = 1;
