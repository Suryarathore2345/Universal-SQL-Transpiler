CREATE materialized view bi_alefdw_dev.ip_class_total_students_mv
AS
WITH CLASS_TEACHERS AS (
    select dc.class_dw_id,
           listagg(distinct teacher_id, ',') within group (order by class_user_created_time) as teacher_ids
    from alefdw.dim_class dc
             JOIN alefdw.dim_class_user dcu ON dcu.class_user_class_dw_id = dc.class_dw_id
             LEFT JOIN alefdw.dim_teacher dt ON dcu.class_user_user_dw_id = dt.teacher_dw_id and dt.teacher_status = 1
               and teacher_id NOT IN (SELECT DISTINCT teacher_id FROM bi_alefdw.exclude_teacher_id)
    where class_status = 1
      AND dcu.class_user_role_dw_id = 1
      and class_course_status = 'ACTIVE'
      and class_user_status = 1
      AND dc.class_material_type <> 'PATHWAY'
      and dcu.class_user_attach_status = 1
    group by 1)

select distinct dc.class_dw_id,
                instructional_plan_id,
                sc.school_dw_id,
                initcap(dc.class_title)              as class_title,
                initcap(dc.class_gen_subject)        as class_gen_subject,
                dc.class_curriculum_id,
                NVL(dse.section_dw_id, '10001')      as section_dw_id,
                initcap(NVL(dse.section_name, 'NA')) as section_name,
                initcap(NVL(dsec.section_name, 'NA')) as class_section_name,
                teacher_ids,
                dcg.curr_grade_dw_id,
                dcg.curr_grade_name,
                dg.grade_name,
                dcs.curr_subject_dw_id,
                dcs.curr_subject_name,
                dcay.content_academic_year_id,
                dcay.content_academic_year_name,
                count(distinct ds.student_dw_id)     as class_total_students
FROM alefdw.dim_class dc
         JOIN alefdw.dim_class_user dcu
              on dcu.class_user_class_dw_id = dc.class_dw_id
         JOIN bi_alefdw.bi_active_schools_dim_mv sc ON md5(dc.class_school_id) = md5(sc.school_id)
         JOIN alefdw.dim_student ds ON dcu.class_user_user_dw_id = ds.student_dw_id
                                    AND sc.school_dw_id = ds.student_school_dw_id
         JOIN alefdw.dim_content_academic_year dcay ON md5(dc.class_content_academic_year) = md5(dcay.content_academic_year_name)
         JOIN alefdw.dim_curriculum_grade dcg
              ON md5(dc.class_curriculum_grade_id) = md5(dcg.curr_grade_id)
         JOIN alefdw.dim_curriculum_subject dcs
              ON md5(dc.class_curriculum_subject_id) = md5(dcs.curr_subject_id)
         JOIN alefdw.dim_instructional_plan dip
              ON  dc.class_curriculum_grade_id = dip.instructional_plan_curriculum_grade_id
                  AND dc.class_curriculum_subject_id = dip.instructional_plan_curriculum_subject_id
                  AND dc.class_curriculum_id = dip.instructional_plan_curriculum_id
                  AND dcay.content_academic_year_id = dip.instructional_plan_content_academic_year_id
                  AND dc.class_curriculum_instructional_plan_id = dip.instructional_plan_id
         JOIN alefdw.dim_grade dg on md5(dg.grade_id) = md5(dc.class_grade_id)
         LEFT JOIN alefdw.dim_section dse
                   on dse.section_dw_id = ds.student_section_dw_id
         LEFT JOIN alefdw.dim_section dsec
                   on md5(dsec.section_id) = md5(dc.class_section_id)
         LEFT JOIN CLASS_TEACHERS ct on ct.class_dw_id = dc.class_dw_id
WHERE dcu.class_user_status = 1
  AND dcu.class_user_role_dw_id = 2
  AND dcu.class_user_attach_status = 1
  AND ds.student_status = 1
  AND instructional_plan_status = 1
  AND class_status = 1
  AND curr_subject_status = 1
  AND curr_grade_status = 1
  AND class_course_status = 'ACTIVE'
  AND dc.class_material_type <> 'PATHWAY'
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17;
