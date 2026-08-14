CREATE OR ALTER VIEW ${os_bi_coredw}.dag_student_progress_core_military_historical_data AS
SELECT DISTINCT
    dc.class_dw_id,
    cont.course_id AS instructional_plan_id,
    cont.school_dw_id,
    cont.school_id,
    UPPER(cont.school_name) AS school_name,
    UPPER(dc.class_title) AS class_title,
    UPPER(dc.class_gen_subject) AS class_gen_subject,
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
    cont.academic_year,
    'new' AS academic_year_type,
    dse.section_alias AS section_name,
    dse.section_dw_id,
    dse.section_id
FROM ${rs_coredw}.dim_class dc
JOIN ${rs_coredw}.dim_class_user dcu
    ON dcu.class_user_class_dw_id = dc.class_dw_id
JOIN ${rs_bi_coredw}.core_class_activity_content cont
    ON dc.class_dw_id = cont.class_dw_id
JOIN ${rs_coredw}.dim_student ds
    ON dcu.class_user_user_dw_id = ds.student_dw_id
   AND cont.school_dw_id = ds.student_school_dw_id
LEFT JOIN ${rs_coredw}.dim_section dse
    ON dse.section_dw_id = ds.student_section_dw_id
LEFT JOIN ${rs_coredw}.dim_section dsec
    ON dsec.section_id = dc.class_section_id
LEFT JOIN ${rs_bi_coredw}.students_lesson_progress slp
    ON slp.student_dw_id = ds.student_dw_id
   AND slp.lo_attempted = cont.activity_dw_id
   AND slp.fle_class_dw_id = dc.class_dw_id
WHERE
    dcu.class_user_status = 1
    AND dcu.class_user_role_dw_id = 2
    AND dcu.class_user_attach_status = 1
    AND ds.student_status = 1
    AND dc.class_status = 1
    AND dc.class_course_status = 'ACTIVE'
    AND dc.class_material_type <> 'PATHWAY'
    AND cont.school_organisation = 'MHS';
