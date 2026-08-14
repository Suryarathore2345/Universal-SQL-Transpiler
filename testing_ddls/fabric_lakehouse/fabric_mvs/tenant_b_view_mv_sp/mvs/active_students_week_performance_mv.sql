CREATE OR REPLACE MATERIALIZED LAKE VIEW ${OS_EAGLES_COREDW}.active_students_week_performance_mv
AS 
WITH dim_school AS (
    SELECT
        dsc.school_dw_id,
        dsc.school_id,
        dsc.tenant_name,
        dsc.tenant_timezone,
        dsc.organisation_dw_id,
        dsc.school_name,
        d.full_date,
        date_trunc('week', d.full_date)  AS week,
        dayofweek(d.full_date) - 1       AS dow,  -- Spark: dayofweek returns 1=Sun..7=Sat; subtract 1 to match Redshift DOW (0=Sun..6=Sat)
        COUNT(d.full_date)               AS week_days
    FROM ${RS_COREDW}.dim_date d
    CROSS JOIN ${RS_BI_COREDW}.bi_active_schools_dim dsc
    LEFT JOIN (
        SELECT DISTINCT
            cast(holiday_date AS DATE) AS holiday_date,
            holiday_organisation_dw_id
        FROM ${RS_COREDW}.dim_holiday
    ) dh
        ON dh.holiday_date = d.full_date
        AND dh.holiday_organisation_dw_id = dsc.organisation_dw_id
    WHERE d.full_date BETWEEN dsc.academic_year_start_date AND date_add(current_date(), -1)
      AND holiday_date IS NULL
      AND (dayofweek(d.full_date) - 1) BETWEEN 1 AND 5
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
),

total_student AS (
    SELECT
        dsc.tenant_name,
        dsc.organisation_dw_id,
        dsc.school_dw_id,
        dsc.school_id,
        dsc.school_name,
        dg.grade_k12grade               AS grade_name,
        ds.student_grade_dw_id,
        s.section_dw_id                 AS student_section_dw_id,
        s.section_name,
        ds.student_dw_id,
        ds.student_id,
        dsc.week,
        MAX(dsc.week_days)              AS week_days
    FROM dim_school dsc
    INNER JOIN ${RS_BI_COREDW}.bi_student_dim ds
        ON ds.student_school_dw_id = dsc.school_dw_id
        AND (
            (
                student_status = 2
                AND to_date(dsc.full_date) >= to_date(from_utc_timestamp(student_created_time, dsc.tenant_timezone))
                AND to_date(dsc.full_date) <  to_date(from_utc_timestamp(student_active_until, dsc.tenant_timezone))
            )
            OR (
                student_status = 1
                AND to_date(dsc.full_date) >= to_date(from_utc_timestamp(student_created_time, dsc.tenant_timezone))
            )
        )
    INNER JOIN ${RS_COREDW}.dim_grade dg
        ON dg.grade_dw_id = ds.student_grade_dw_id
    INNER JOIN ${RS_COREDW}.dim_section s
        ON s.section_dw_id = ds.student_section_dw_id
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
),

active_students AS (
    SELECT
        date_trunc('week', sl.login_local_date_time)          AS login_week,
        sl.student_dw_id                                       AS active_student_dw_id,
        count(distinct to_date(sl.login_local_date_time))      AS active_days
    FROM ${RS_BI_COREDW}.student_login sl
    INNER JOIN ${RS_BI_COREDW}.bi_active_schools_dim dsc
        ON dsc.school_dw_id = sl.school_dw_id
    INNER JOIN ${RS_BI_COREDW}.bi_student_dim ds
        ON ds.student_dw_id = sl.student_dw_id
        AND (
            (
                student_status = 2
                AND to_date(login_local_date_time) >= to_date(from_utc_timestamp(student_created_time, dsc.tenant_timezone))
                AND to_date(login_local_date_time) <  to_date(from_utc_timestamp(student_active_until, dsc.tenant_timezone))
            )
            OR (
                student_status = 1
                AND to_date(login_local_date_time) >= to_date(from_utc_timestamp(student_created_time, dsc.tenant_timezone))
            )
        )
    LEFT JOIN (
        SELECT DISTINCT
            cast(holiday_date AS DATE) AS holiday_date,
            holiday_organisation_dw_id
        FROM ${RS_COREDW}.dim_holiday
    ) dh
        ON dh.holiday_date = to_date(login_local_date_time)
        AND dh.holiday_organisation_dw_id = dsc.organisation_dw_id
    WHERE to_date(login_local_date_time) >= academic_year_start_date
      AND to_date(login_local_date_time) <= academic_year_end_date
      AND holiday_date IS NULL
      AND (dayofweek(to_date(login_local_date_time)) - 1) BETWEEN 1 AND 5
      AND to_date(login_local_date_time) <= date_add(current_date(), -1)
    GROUP BY 1, 2
),

total_lessons AS (
    SELECT
        cts.section_dw_id,
        cts.section_name,
        coalesce(dpg.pacing_interval_start_date,
                 dtrm.actp_teaching_period_start_date,
                 dsc.academic_year_start_date)          AS week_start_date,
        coalesce(dpg.pacing_interval_end_date,
                 dtrm.actp_teaching_period_end_date,
                 dsc.academic_year_end_date)            AS week_end_date,
        dip_dlo.lo_dw_id
    FROM ${RS_BI_COREDW}.class_total_students cts
    INNER JOIN ${RS_COREDW}.dim_course_activity_association dcaa
        ON cts.instructional_plan_id = dcaa.caa_course_id
        AND dcaa.caa_attach_status = 1
        AND dcaa.caa_status = 1
        AND dcaa.caa_activity_is_optional = FALSE
    LEFT JOIN ${RS_COREDW}.dim_pacing_guide dpg
        ON cts.class_dw_id = dpg.pacing_class_dw_id
        AND dcaa.caa_activity_dw_id = dpg.pacing_activity_dw_id
        AND dpg.pacing_status = 1
    LEFT JOIN (
        SELECT DISTINCT pacing_class_dw_id
        FROM ${RS_COREDW}.dim_pacing_guide
        WHERE pacing_status = 1
    ) cp
        ON cp.pacing_class_dw_id = cts.class_dw_id
    LEFT JOIN ${RS_COREDW}.dim_academic_calendar_teaching_period dtrm
        ON dpg.pacing_period_id = dtrm.actp_teaching_period_id
        AND dtrm.actp_status = 1
    INNER JOIN ${RS_BI_COREDW}.bi_active_schools_dim dsc
        ON cts.school_dw_id = dsc.school_dw_id
    INNER JOIN ${RS_COREDW}.dim_learning_objective dip_dlo
        ON dcaa.caa_activity_dw_id = dip_dlo.lo_dw_id
        AND coalesce(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
        AND coalesce(lo_template_uuid, 'DISTINCT_VALUE') NOT IN (
            '235229fa-4707-4286-8ec2-85f70347096a',
            '15295fd1-b5e3-46f9-9045-86ee3b13552b'
        )
    WHERE lower(cts.class_title) NOT LIKE '%power skills%'
      AND lower(cts.class_title) NOT LIKE '%extra resources%'
      AND lower(cts.class_gen_subject) != 'core stars'
      AND (
          cp.pacing_class_dw_id IS NULL
          OR dpg.pacing_activity_dw_id IS NOT NULL
      )
),

ip_defined AS (
    SELECT
        slp.*,
        cl.week_start_date,
        cl.week_end_date
    FROM ${RS_BI_COREDW}.students_lesson_progress slp
    INNER JOIN (
        SELECT DISTINCT
            cts.class_dw_id,
            cts.class_curriculum_id,
            cts.section_dw_id,
            dcaa.caa_activity_dw_id,
            coalesce(dpg.pacing_interval_start_date,
                     dtrm.actp_teaching_period_start_date,
                     dsc.academic_year_start_date)      AS week_start_date,
            coalesce(dpg.pacing_interval_end_date,
                     dtrm.actp_teaching_period_end_date,
                     dsc.academic_year_end_date)        AS week_end_date
        FROM ${RS_BI_COREDW}.class_total_students cts
        JOIN ${RS_COREDW}.dim_course_activity_association dcaa
            ON cts.instructional_plan_id = dcaa.caa_course_id
            AND dcaa.caa_attach_status = 1
            AND dcaa.caa_status = 1
            AND dcaa.caa_activity_is_optional = FALSE
        LEFT JOIN ${RS_COREDW}.dim_pacing_guide dpg
            ON cts.class_dw_id = dpg.pacing_class_dw_id
            AND dcaa.caa_activity_dw_id = dpg.pacing_activity_dw_id
            AND dpg.pacing_status = 1
        LEFT JOIN (
            SELECT DISTINCT pacing_class_dw_id
            FROM ${RS_COREDW}.dim_pacing_guide
            WHERE pacing_status = 1
        ) cp
            ON cp.pacing_class_dw_id = cts.class_dw_id
        LEFT JOIN ${RS_COREDW}.dim_academic_calendar_teaching_period dtrm
            ON dpg.pacing_period_id = dtrm.actp_teaching_period_id
            AND dtrm.actp_status = 1
        JOIN ${RS_BI_COREDW}.bi_active_schools_dim dsc
            ON cts.school_dw_id = dsc.school_dw_id
        JOIN ${RS_COREDW}.dim_learning_objective dip_dlo
            ON dcaa.caa_activity_dw_id = dip_dlo.lo_dw_id
            AND coalesce(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
            AND coalesce(lo_template_uuid, 'DISTINCT_VALUE') NOT IN (
                '235229fa-4707-4286-8ec2-85f70347096a',
                '15295fd1-b5e3-46f9-9045-86ee3b13552b'
            )
        WHERE lower(cts.class_title) NOT LIKE '%power skills%'
          AND lower(cts.class_title) NOT LIKE '%extra resources%'
          AND lower(cts.class_gen_subject) != 'core stars'
          AND (
              cp.pacing_class_dw_id IS NULL
              OR dpg.pacing_activity_dw_id IS NOT NULL
          )
    ) cl
        ON  cl.section_dw_id = slp.student_section_dw_id
        AND cl.caa_activity_dw_id = slp.lo_attempted
)

SELECT
    ds.student_section_dw_id,
    ds.section_name,
    ds.school_dw_id,
    ds.school_id,
    ds.school_name,
    ds.tenant_name,
    ds.organisation_dw_id,
    ds.grade_name,
    ds.student_dw_id,
    ds.student_grade_dw_id,
    ds.student_id,
    ds.week,
    acs.active_days,
    ds.week_days,
    COUNT(DISTINCT tl.lo_dw_id)                                                      AS total_lessons,
    COUNT(DISTINCT CASE lo_status WHEN 'Completed' THEN lo_attempted END)            AS completed_lessons,
    AVG(CASE lo_status WHEN 'Completed' THEN CAST(fle_score AS decimal(10, 2)) END)  AS average_score
FROM total_student ds
INNER JOIN active_students acs
    ON ds.student_dw_id = acs.active_student_dw_id
    AND ds.week = acs.login_week
INNER JOIN total_lessons tl
    ON tl.section_dw_id = ds.student_section_dw_id
    AND ds.week BETWEEN tl.week_start_date AND tl.week_end_date
INNER JOIN ip_defined ip
    ON ds.student_dw_id = ip.student_dw_id
    AND ip.week_start_date = tl.week_start_date
    AND ip.week_end_date = tl.week_end_date
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14;
