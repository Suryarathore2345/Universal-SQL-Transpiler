CREATE OR ALTER VIEW ${os_bi_coredw}.dag_student_progress_core_military_historical_data_adhoc AS
SELECT DISTINCT
    dc.class_dw_id,
    cont.course_id AS instructional_plan_id,
    cont.school_dw_id,
    cont.school_id,

    CASE
        WHEN cont.school_name IS NULL OR cont.school_name = ''
        THEN cont.school_name
        ELSE UPPER(cont.school_name)
    END AS school_name,

    CASE
        WHEN dc.class_title IS NULL OR dc.class_title = ''
        THEN dc.class_title
        ELSE UPPER(dc.class_title)
    END AS class_title,

    CASE
        WHEN dc.class_gen_subject IS NULL OR dc.class_gen_subject = ''
        THEN dc.class_gen_subject
        ELSE UPPER(dc.class_gen_subject)
    END AS class_gen_subject,

    CONVERT(VARCHAR, cont.grade_name) AS grade_name,
    CONVERT(VARCHAR(36), cont.academic_year_id) AS content_academic_year_id,
    CONVERT(VARCHAR, YEAR(cont.academic_year_end_date)) AS content_academic_year_name,

    ds.student_dw_id,
    ds.student_id,
    cont.activity_dw_id AS lo_dw_id,
    cont.lo_title,
    cont.week_start_date,
    cont.week_end_date,
    cont.term_academic_period_order,
    cont.term_start_date,
    cont.term_end_date,
    cont.pacing,

    ISNULL(slp.lo_status, 'Not Started') AS lo_status,
    slp.local_date,
    slp.session_time,
    slp.fle_session_time,
    slp.fle_score,

    CONVERT(VARCHAR, YEAR(cont.academic_year_start_date))
        + ' - ' +
    CONVERT(VARCHAR, YEAR(cont.academic_year_end_date)) AS academic_year,

    'old' AS academic_year_type,

    dsec.section_alias AS section_name,
    dsec.section_dw_id,
    dsec.section_id
FROM ${rs_coredw}.dim_class_user dcu
JOIN ${rs_coredw}.dim_class dc
    ON dcu.class_user_class_dw_id = dc.class_dw_id
JOIN ${rs_bi_coredw}.core_class_activity_content cont
    ON dc.class_dw_id = cont.class_dw_id
JOIN ${rs_coredw}.dim_student ds
    ON dcu.class_user_user_dw_id = ds.student_dw_id
   AND cont.school_dw_id = ds.student_school_dw_id
LEFT JOIN ${rs_coredw}.dim_section dsec
    ON dsec.section_id = dc.class_section_id
INNER JOIN ${rs_bi_coredw}.students_lesson_progress_military_historical_data slp
    ON slp.student_dw_id = ds.student_dw_id
   AND slp.lo_attempted = cont.activity_dw_id
   AND slp.fle_class_dw_id = dc.class_dw_id
WHERE
    cont.school_organisation = 'MHS'
    AND dcu.class_user_role_dw_id = 2
    AND dcu.class_user_attach_status = 1
    AND (
        dcu.class_user_status = 1
        OR (
            dcu.class_user_status = 2
            AND CONVERT(DATE, dcu.class_user_active_until) >= cont.academic_year_start_date
            AND dcu.class_user_created_time <= cont.academic_year_end_date
        )
    )
    AND (
        ds.student_status = 1
        OR (
            ds.student_status = 2
            AND CONVERT(DATE, ds.student_active_until) >= cont.academic_year_start_date
            AND ds.student_created_time <= cont.academic_year_end_date
        )
    );
