CREATE OR ALTER VIEW ${os_bi_coredw}.interim_checkpoint_student_dm_view
AS

WITH FLE AS (
    SELECT
    CONVERT(
        DATE,
        MIN(
            fle_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
        )
    ) AS local_date,
        fle_lo_dw_id,
        fle_class_dw_id,
        dc.class_gen_subject,
        dg.grade_k12grade,
        fle_student_dw_id,
        SUM(fle_score) AS fle_score,
        SUM(
            CASE
                WHEN fle.fle_total_time <= 1200 THEN fle.fle_total_time
                WHEN fle.fle_total_time > 1200 THEN 1200
                ELSE 0
            END
        ) AS total_time
    FROM ${rs_coredw}.fact_learning_experience fle
    JOIN ${rs_coredw}.dim_class dc
        ON dc.class_dw_id = fle.fle_class_dw_id
    JOIN ${rs_coredw}.dim_class_user dcu
        ON dcu.class_user_class_dw_id = dc.class_dw_id
       AND dcu.class_user_user_dw_id = fle.fle_student_dw_id
    JOIN ${rs_bi_coredw}.bi_student_dim ds
        ON dcu.class_user_user_dw_id = ds.student_dw_id
    JOIN ${rs_coredw}.dim_grade dg
        ON dg.grade_dw_id = ds.student_grade_dw_id
    JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
        ON dsc.school_dw_id = ds.student_school_dw_id
       AND fle.fle_school_dw_id = ds.student_school_dw_id

    WHERE fle_activity_type = 'INTERIM_CHECKPOINT'
      AND fle_exp_id <> 'n/a'
      AND dcu.class_user_status = 1
      AND dc.class_status = 1
      AND student_status = 1
      AND class_user_attach_status = 1
      AND class_course_status = 'ACTIVE'
    GROUP BY
        fle_lo_dw_id,
        fle_class_dw_id,
        dc.class_gen_subject,
        dg.grade_k12grade,
        fle_student_dw_id,
        dsc.windows_timezone
)

SELECT DISTINCT
    fle.local_date,
    dcr.course_id AS instructional_plan_id,
    dcr.course_name AS instructional_plan_name,
    dic.ic_id AS icp_id,
    dic.ic_title AS icp_title,
    ctsm.content_academic_year_name,
    ctsm.school_dw_id,
    ctsm.class_gen_subject,
    grade_k12grade,
    ds.school_name,
    ds.school_country_name,
    ds.school_city_name,
    ds.tenant_name,
    ds.school_organisation,
    ctsm.class_dw_id,
    ctsm.section_dw_id,
    ctsm.class_title,
    ctsm.grade_name AS curr_grade_name,
    ctsm.class_gen_subject AS curr_subject_name,
    ISNULL(dtrm.actp_teaching_period_order, 1) AS term_academic_period_order,
    dic.ic_dw_id AS icp_dw_id,
    ctsm.class_total_students,
    fle.fle_score AS total_score,
    fle.total_time,
    fle.fle_student_dw_id,
    fle_lo_dw_id AS completed_lo_dw_id
FROM ${rs_bi_coredw}.class_total_students ctsm
INNER JOIN ${rs_coredw}.dim_course dcr
    ON dcr.course_id = ctsm.instructional_plan_id
   AND dcr.course_status = 1
INNER JOIN ${rs_coredw}.dim_course_activity_association dcaa
    ON dcaa.caa_course_id = ctsm.instructional_plan_id
   AND dcaa.caa_activity_type = 2
   AND dcaa.caa_status = 1
   AND dcaa.caa_attach_status = 1
INNER JOIN ${rs_coredw}.dim_interim_checkpoint dic
    ON dcaa.caa_activity_dw_id = dic.ic_dw_id
   AND dic.ic_status = 1
LEFT JOIN FLE fle
    ON fle.fle_lo_dw_id = dic.ic_dw_id
   AND ctsm.class_dw_id = fle.fle_class_dw_id
INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim ds
    ON ds.school_dw_id = ctsm.school_dw_id
LEFT JOIN ${rs_coredw}.dim_pacing_guide dpg
    ON ctsm.class_dw_id = dpg.pacing_class_dw_id
   AND dcaa.caa_activity_dw_id = dpg.pacing_activity_dw_id
   AND dpg.pacing_status = 1
LEFT JOIN ${rs_coredw}.dim_academic_calendar_teaching_period dtrm
    ON dpg.pacing_period_id = dtrm.actp_teaching_period_id
   AND dtrm.actp_status = 1;
