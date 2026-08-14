CREATE OR ALTER VIEW ${os_bi_coredw}.ip_student_progress_ip_mscl_view AS
-- This view contains details only for MSCL org and Athena group
SELECT DISTINCT
    dc.class_dw_id,
    dip.instructional_plan_id,
    sc.school_dw_id,
    sc.school_id,
    sc.school_name,

    UPPER(dc.class_title) AS class_title,
    UPPER(dc.class_gen_subject) AS class_gen_subject,
    dc.class_curriculum_id,
    ISNULL(CONVERT(VARCHAR(50), dse.section_dw_id), '10001') AS section_dw_id,
    UPPER(ISNULL(dse.section_name, 'NA')) AS section_name,
    UPPER(ISNULL(dsec.section_name, 'NA')) AS class_section_name,

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
    ISNULL(slp.lo_status, 'Not Started') AS lo_status,
    slp.local_date,
    slp.fle_score
FROM ${rs_coredw}.dim_class dc
JOIN ${rs_coredw}.dim_class_user dcu
    ON dcu.class_user_class_dw_id = dc.class_dw_id
JOIN ${rs_bi_coredw}.bi_active_schools_dim sc
    ON dc.class_school_id = sc.school_id
JOIN ${rs_coredw}.dim_student ds
    ON dcu.class_user_user_dw_id = ds.student_dw_id
   AND sc.school_dw_id = ds.student_school_dw_id
JOIN ${rs_coredw}.dim_content_academic_year dcay
    ON dc.class_content_academic_year = dcay.content_academic_year_name
JOIN ${rs_coredw}.dim_curriculum_grade dcg
    ON dc.class_curriculum_grade_id = dcg.curr_grade_id
JOIN ${rs_coredw}.dim_curriculum_subject dcs
    ON dc.class_curriculum_subject_id = dcs.curr_subject_id
JOIN ${rs_coredw}.dim_instructional_plan dip
    ON dc.class_curriculum_grade_id   = dip.instructional_plan_curriculum_grade_id
   AND dc.class_curriculum_subject_id = dip.instructional_plan_curriculum_subject_id
   AND dc.class_curriculum_id         = dip.instructional_plan_curriculum_id
   AND dcay.content_academic_year_id  = dip.instructional_plan_content_academic_year_id
   AND dc.class_curriculum_instructional_plan_id = dip.instructional_plan_id
   AND dip.instructional_plan_status = 1
   AND dip.instructional_plan_item_optional = 0
JOIN ${rs_coredw}.dim_learning_objective lo
    ON lo.lo_dw_id = dip.instructional_plan_item_lo_dw_id
   AND ISNULL(lo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
JOIN ${rs_coredw}.dim_week dw
    ON dip.instructional_plan_item_week_dw_id = dw.week_dw_id
JOIN ${rs_coredw}.dim_term dtrm
    ON dw.week_term_id = dtrm.term_id
JOIN ${rs_coredw}.dim_grade dg
    ON dg.grade_id = dc.class_grade_id
LEFT JOIN ${rs_coredw}.dim_section dse
    ON dse.section_dw_id = ds.student_section_dw_id
LEFT JOIN ${rs_coredw}.dim_section dsec
    ON dsec.section_id = dc.class_section_id
LEFT JOIN ${rs_bi_coredw}.students_lesson_progress slp
    ON slp.student_dw_id   = ds.student_dw_id
   AND slp.lo_attempted    = lo.lo_dw_id
   AND slp.fle_class_dw_id = dc.class_dw_id
WHERE dcu.class_user_status = 1
  AND dcu.class_user_role_dw_id = 2
  AND dcu.class_user_attach_status = 1
  AND ds.student_status = 1
  AND dc.class_status = 1
  AND lo.lo_status = 1
  AND dcs.curr_subject_status = 1
  AND dcg.curr_grade_status = 1
  AND dc.class_course_status = 'ACTIVE'
  AND dc.class_material_type <> 'PATHWAY'
  AND (
        sc.school_organisation = 'MSCL'
        OR sc.school_id IN (
            'd01d0b9c-8d42-43d5-ae2b-529a2cedcdc4',
            '5b414b30-d74c-4d13-bae8-5c70ea826b27',
            '3bb86284-f23b-4346-8ebb-f447405202a0',
            'd8f4fd6d-5ec3-42ac-b145-a9efbbfd5cd0',
            'f85d1bdb-619a-4b19-90a8-854bb880184d',
            '98fb3f44-4ba8-463a-a8d0-7e86a0ef98c2',
            '84279568-232f-4f89-bf07-4053b7382fae',
            '1259b7ad-d86d-4bc7-a9ec-8bf0f9259835',
            'f33955bd-8549-477c-a624-826f90777d91'
        )
      );
