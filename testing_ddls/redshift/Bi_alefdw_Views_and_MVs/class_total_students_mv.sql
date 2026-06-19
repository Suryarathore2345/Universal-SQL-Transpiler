CREATE MATERIALIZED VIEW bi_alefdw_dev.class_total_students_mv AS
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
                dc.class_id,
                dcr.course_id as instructional_plan_id, --kept same alias to make is backward compatible.
                sc.school_dw_id,
                initcap(dc.class_title)               as class_title,
                initcap(dc.class_gen_subject)         as class_gen_subject,
                dc.class_curriculum_id,
                NVL(dse.section_dw_id, '10001')       as section_dw_id,
                initcap(NVL(dse.section_alias, 'NA'))  as section_name,
                initcap(NVL(dsec.section_alias, 'NA')) as class_section_name,
                teacher_ids,
                dg.grade_name,
                dc.class_academic_calendar_id as content_academic_year_id, -- kept same alias to make is backward compatible and add possibility to join with AC.
                CAST(date_part_year(sc.academic_year_end_date) AS VARCHAR(20)) as content_academic_year_name, -- kept same alias to make is backward compatible.
                dcsa.cs_subject_id AS course_subject_id,
                count(distinct ds.student_dw_id)      as class_total_students
FROM alefdw.dim_class dc
         JOIN alefdw.dim_class_user dcu
              on dcu.class_user_class_dw_id = dc.class_dw_id
         JOIN bi_alefdw.bi_active_schools_dim_mv sc ON md5(dc.class_school_id) = md5(sc.school_id)
         JOIN alefdw.dim_student ds ON dcu.class_user_user_dw_id = ds.student_dw_id
    AND sc.school_dw_id = ds.student_school_dw_id
         JOIN alefdw.dim_course dcr
             ON dcr.course_id = dc.class_material_id
         LEFT JOIN alefdw.dim_course_subject_association dcsa
                on dcsa.cs_course_dw_id=dcr.course_dw_id
                AND dcsa.cs_status=1
                AND dcsa.cs_subject_dw_id = 129 -- Arabits subject_dw_id , courses can have multiple subjects - with this condition we keep the unique value
         JOIN alefdw.dim_grade dg on dg.grade_id = dc.class_grade_id
         LEFT JOIN alefdw.dim_section dse
                   on dse.section_dw_id = ds.student_section_dw_id
         LEFT JOIN alefdw.dim_section dsec
                   on dsec.section_id = dc.class_section_id
         LEFT JOIN CLASS_TEACHERS ct on ct.class_dw_id = dc.class_dw_id
WHERE dcu.class_user_status = 1
  AND dcu.class_user_role_dw_id = 2
  AND dcu.class_user_attach_status = 1
  AND ds.student_status = 1
  AND dcr.course_status = 1
  AND dcr.course_type='CORE'
  AND class_status = 1
  AND class_course_status = 'ACTIVE'
  AND dc.class_material_type <> 'PATHWAY'
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15;