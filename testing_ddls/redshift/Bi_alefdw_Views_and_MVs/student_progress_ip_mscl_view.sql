CREATE OR REPLACE VIEW bi_alefdw_dev.student_progress_ip_mscl_view AS
-- This view contains details only for MSCL org and Athena group
select distinct dc.class_dw_id,
                cont.course_id                         as instructional_plan_id,
                cont.school_organisation,
                cont.school_dw_id,
                cont.school_id,
                cont.school_name,
                cont.academic_year_start_date,
                cont.academic_year_end_date,
                initcap(dc.class_title)               as class_title,
                initcap(dc.class_gen_subject)         as class_gen_subject,
                NVL(dse.section_dw_id, '10001')       as section_dw_id,
                initcap(NVL(dse.section_alias, 'NA'))  as section_name,
                initcap(NVL(dsec.section_alias, 'NA')) as class_section_name,
                cont.grade_name,
                dc.class_academic_calendar_id as content_academic_year_id,
                date_part_year(cont.academic_year_end_date) as content_academic_year_name,
                ds.student_dw_id,
                ds.student_id,
                cont.activity_dw_id lo_dw_id,
                cont.lo_title,
                COALESCE(CASE cont.pacing
                        WHEN 'MONTH' THEN date_part(month, cont.week_start_date)
                        ELSE date_part(week, cont.week_start_date) END, 1)                                   AS week_number,
                cont.week_start_date,
                cont.week_end_date,
                cont.term_academic_period_order,
                cont.term_start_date,
                cont.term_end_date,
                cont.pacing,
                nvl(slp.lo_status, 'Not Started')     as lo_status,
                slp.local_date,
                slp.fle_score
FROM alefdw.dim_class dc
         JOIN alefdw.dim_class_user dcu
              on dcu.class_user_class_dw_id = dc.class_dw_id
         JOIN bi_alefdw.core_class_activity_content_mv cont
             ON cont.class_dw_id = dc.class_dw_id
         JOIN alefdw.dim_student ds
             ON dcu.class_user_user_dw_id = ds.student_dw_id
                  AND cont.school_dw_id = ds.student_school_dw_id
         LEFT JOIN alefdw.dim_section dse
                   ON dse.section_dw_id = ds.student_section_dw_id
         LEFT JOIN alefdw.dim_section dsec
                   on dsec.section_id = dc.class_section_id
         LEFT JOIN bi_alefdw.students_lesson_progress_mv slp
                   ON slp.student_dw_id = ds.student_dw_id
                       AND slp.lo_attempted = cont.activity_dw_id
                       AND slp.fle_class_dw_id = dc.class_dw_id
WHERE dcu.class_user_status = 1
  AND dcu.class_user_role_dw_id = 2
  AND dcu.class_user_attach_status = 1
  AND ds.student_status = 1
  AND dc.class_status = 1
  AND dc.class_course_status = 'ACTIVE'
  AND dc.class_material_type <> 'PATHWAY'
  AND (
    (cont.school_organisation = 'MHS') --- tbd when a MSCL organization will be crteated
        OR
    (cont.school_id in ('d01d0b9c-8d42-43d5-ae2b-529a2cedcdc4', '5b414b30-d74c-4d13-bae8-5c70ea826b27',
                      '3bb86284-f23b-4346-8ebb-f447405202a0', 'd8f4fd6d-5ec3-42ac-b145-a9efbbfd5cd0',
                      'f85d1bdb-619a-4b19-90a8-854bb880184d', '98fb3f44-4ba8-463a-a8d0-7e86a0ef98c2',
                      '84279568-232f-4f89-bf07-4053b7382fae', '1259b7ad-d86d-4bc7-a9ec-8bf0f9259835',
                      'f33955bd-8549-477c-a624-826f90777d91'))
    )
WITH NO SCHEMA BINDING;