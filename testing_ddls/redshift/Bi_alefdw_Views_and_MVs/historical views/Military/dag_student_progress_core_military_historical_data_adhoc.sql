CREATE OR REPLACE VIEW bi_alefdw_dev.dag_student_progress_core_military_historical_data_adhoc AS
SELECT DISTINCT dc.class_dw_id,
                cont.course_id AS instructional_plan_id,
                cont.school_dw_id,
                cont.school_id,
                initcap(cont.school_name) AS school_name,
                initcap(dc.class_title)  AS class_title,
                initcap(dc.class_gen_subject)  AS class_gen_subject,
                cont.grade_name::VARCHAR,
                cast(cont.academic_year_id AS VARCHAR) AS content_academic_year_id,
                cast(date_part_year(cont.academic_year_end_date) AS VARCHAR) AS content_academic_year_name,
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
                nvl(slp.lo_status, 'Not Started')                                  AS lo_status,
                slp.local_date,
                slp.session_time,
                slp.fle_session_time,
                slp.fle_score,
                DATE_PART_YEAR(cont.academic_year_start_date) || ' - ' ||
                DATE_PART_YEAR(cont.academic_year_end_date)                          AS academic_year,
                'old'                                                              AS academic_year_type,
                dsec.section_alias AS section_name,
                dsec.section_dw_id,
                dsec.section_id
FROM alefdw.dim_class_user dcu
         JOIN alefdw.dim_class dc
             ON dcu.class_user_class_dw_id = dc.class_dw_id
         JOIN bi_alefdw.core_class_activity_content_mv cont
             ON dcu.class_user_class_dw_id = cont.class_dw_id
         JOIN alefdw.dim_student ds
             ON dcu.class_user_user_dw_id = ds.student_dw_id
                  AND cont.school_dw_id = ds.student_school_dw_id
         LEFT JOIN alefdw.dim_section dsec
                   on dsec.section_id = dc.class_section_id
         INNER JOIN bi_alefdw.students_lesson_progress_military_historical_data slp
                   ON slp.student_dw_id = ds.student_dw_id
                       AND slp.lo_attempted = cont.activity_dw_id
                       AND slp.fle_class_dw_id = dc.class_dw_id
WHERE cont.school_organisation = 'MHS'
  AND dcu.class_user_role_dw_id = 2
  AND dcu.class_user_attach_status = 1
AND
    (dcu.class_user_status = 1
     OR (dcu.class_user_status = 2
     AND DATE(dcu.class_user_active_until) >= cont.academic_year_start_date
     AND dcu.class_user_created_time <= cont.academic_year_end_date))
AND
    (ds.student_status = 1
    OR (ds.student_status = 2
    AND DATE(ds.student_active_until) >= cont.academic_year_start_date
    AND ds.student_created_time <= cont.academic_year_end_date))
WITH NO SCHEMA BINDING;