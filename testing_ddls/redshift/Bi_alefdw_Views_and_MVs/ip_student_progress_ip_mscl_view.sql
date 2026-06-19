CREATE OR REPLACE VIEW bi_alefdw_dev.ip_student_progress_ip_mscl_view AS
-- This view contains details only for MSCL org and Athena group
select distinct dc.class_dw_id,
                dip.instructional_plan_id,
                sc.school_dw_id,
                sc.school_id,
                sc.school_name,
                initcap(dc.class_title)               as class_title,
                initcap(dc.class_gen_subject)         as class_gen_subject,
                dc.class_curriculum_id,
                NVL(dse.section_dw_id, '10001')       as section_dw_id,
                initcap(NVL(dse.section_name, 'NA'))  as section_name,
                initcap(NVL(dsec.section_name, 'NA')) as class_section_name,
                dcg.curr_grade_dw_id,
                dcg.curr_grade_name,
                dg.grade_name,
                dcs.curr_subject_dw_id,
                dcs.curr_subject_name,
                dcay.content_academic_year_id,
                dcay.content_academic_year_name,
                ds.student_dw_id,
                ds.student_id,
                lo.lo_dw_id,
                lo.lo_title,
                dw.week_start_date,
                dw.week_end_date,
                dtrm.term_academic_period_order,
                dtrm.term_start_date,
                dtrm.term_end_date,
                nvl(slp.lo_status, 'Not Started')     as lo_status,
                slp.local_date,
                slp.fle_score
FROM alefdw.dim_class dc
         JOIN alefdw.dim_class_user dcu
              on dcu.class_user_class_dw_id = dc.class_dw_id
         JOIN bi_alefdw.bi_active_schools_dim_mv sc ON md5(dc.class_school_id) = md5(sc.school_id)
         JOIN alefdw.dim_student ds ON dcu.class_user_user_dw_id = ds.student_dw_id
    AND sc.school_dw_id = ds.student_school_dw_id
         JOIN alefdw.dim_content_academic_year dcay
              ON md5(dc.class_content_academic_year) = md5(dcay.content_academic_year_name)
         JOIN alefdw.dim_curriculum_grade dcg
              ON md5(dc.class_curriculum_grade_id) = md5(dcg.curr_grade_id)
         JOIN alefdw.dim_curriculum_subject dcs
              ON md5(dc.class_curriculum_subject_id) = md5(dcs.curr_subject_id)
         JOIN alefdw.dim_instructional_plan dip
              ON dc.class_curriculum_grade_id = dip.instructional_plan_curriculum_grade_id
                  AND dc.class_curriculum_subject_id = dip.instructional_plan_curriculum_subject_id
                  AND dc.class_curriculum_id = dip.instructional_plan_curriculum_id
                  AND dcay.content_academic_year_id = dip.instructional_plan_content_academic_year_id
                  AND dc.class_curriculum_instructional_plan_id = dip.instructional_plan_id
                  AND dip.instructional_plan_status = 1
                  AND dip.instructional_plan_item_optional IS FALSE
         JOIN alefdw.dim_learning_objective lo
              ON lo.lo_dw_id = dip.instructional_plan_item_lo_dw_id
                  AND nvl(lo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
         JOIN alefdw.dim_week dw ON dip.instructional_plan_item_week_dw_id = dw.week_dw_id
         JOIN alefdw.dim_term dtrm ON md5(dw.week_term_id) = md5(dtrm.term_id)
         JOIN alefdw.dim_grade dg on md5(dg.grade_id) = md5(dc.class_grade_id)
         LEFT JOIN alefdw.dim_section dse
                   ON dse.section_dw_id = ds.student_section_dw_id
         LEFT JOIN alefdw.dim_section dsec
                   on md5(dsec.section_id) = md5(dc.class_section_id)
         LEFT JOIN bi_alefdw.students_lesson_progress_mv slp
                   ON slp.student_dw_id = ds.student_dw_id
                       AND slp.lo_attempted = lo.lo_dw_id
                       AND slp.fle_class_dw_id = dc.class_dw_id

WHERE dcu.class_user_status = 1
  AND dcu.class_user_role_dw_id = 2
  AND dcu.class_user_attach_status = 1
  AND ds.student_status = 1
  AND class_status = 1
  AND lo.lo_status=1
  AND curr_subject_status = 1
  AND curr_grade_status = 1
  AND class_course_status = 'ACTIVE'
  AND dc.class_material_type <> 'PATHWAY'
  AND (
        (sc.school_organisation = 'MSCL')
        OR
        (sc.school_id in ('d01d0b9c-8d42-43d5-ae2b-529a2cedcdc4', '5b414b30-d74c-4d13-bae8-5c70ea826b27',
                          '3bb86284-f23b-4346-8ebb-f447405202a0', 'd8f4fd6d-5ec3-42ac-b145-a9efbbfd5cd0',
                          'f85d1bdb-619a-4b19-90a8-854bb880184d', '98fb3f44-4ba8-463a-a8d0-7e86a0ef98c2',
                          '84279568-232f-4f89-bf07-4053b7382fae', '1259b7ad-d86d-4bc7-a9ec-8bf0f9259835',
                          'f33955bd-8549-477c-a624-826f90777d91'))
    )
WITH NO SCHEMA BINDING;
