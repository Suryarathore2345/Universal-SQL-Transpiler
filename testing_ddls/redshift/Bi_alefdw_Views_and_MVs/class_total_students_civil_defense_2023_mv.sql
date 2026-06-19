DROP MATERIALIZED VIEW bi_alefdw_dev.class_total_students_civil_defense_2023_mv;

CREATE MATERIALIZED VIEW bi_alefdw_dev.class_total_students_civil_defense_2023_mv AS
WITH school_prveviousay AS ( -- define previous Academic Year start and end date by school
    SELECT academic_year_school_id,
           academic_year_id,
           academic_year_dw_id,
           academic_year_start_date AS previous_academic_year_start_date,
           academic_year_end_date   AS previous_academic_year_end_date
    FROM (
             SELECT *,
                    ROW_NUMBER() OVER (
                        PARTITION BY academic_year_school_id ORDER BY academic_year_end_date DESC
                        ) AS rank
             FROM alefdw.dim_academic_year
             WHERE academic_year_is_roll_over_completed
--                AND academic_year_school_id = 'c97921a8-6555-4c5f-acd2-9487803f2b66' -- test for 1 school
         ) pr_ay
--     WHERE pr_ay.rank = 2
       WHERE date_part(year, academic_year_start_date) >= 2021
       and   date_part(year, academic_year_end_date) <= 2023
),


     class_teachers AS ( --define teacher assigned to the class
         SELECT dc.class_dw_id,
                listagg(DISTINCT teacher_id, ',') WITHIN GROUP (ORDER BY class_user_created_time) AS teacher_ids
         FROM alefdw.dim_class dc
                  INNER JOIN alefdw.dim_class_user dcu
                             ON dcu.class_user_class_dw_id = dc.class_dw_id
                  INNER JOIN school_prveviousay ay
                             ON dc.class_academic_year_id = ay.academic_year_id
                                 AND dc.class_school_id = ay.academic_year_school_id
                  LEFT JOIN alefdw.dim_teacher dt
                            ON dcu.class_user_user_dw_id = dt.teacher_dw_id
                                AND teacher_id NOT IN (
                                    SELECT DISTINCT teacher_id
                                    FROM bi_alefdw.exclude_teacher_id
                                )
         WHERE dcu.class_user_role_dw_id = 1
           AND dc.class_course_status = 'CONCLUDED'
           AND dc.class_material_type <> 'PATHWAY'
--            AND class_school_id = 'c97921a8-6555-4c5f-acd2-9487803f2b66' -- test for 1 school
         GROUP BY 1
     ),


     civil_defense_lo AS
         (select instructional_plan_curriculum_grade_id,
                 instructional_plan_curriculum_subject_id,
                 instructional_plan_curriculum_id,
                 instructional_plan_content_academic_year_id,
                 instructional_plan_id,
                 lo_code
             from alefdw.dim_instructional_plan dip
             INNER JOIN alefdw.dim_learning_objective dlo
             on dip.instructional_plan_item_lo_dw_id = dlo.lo_dw_id
             where lo_code  in ('CD_MLO_000', 'CD_MLO_001', 'CD_MLO_002',
                                'CD_MLO_003', 'CD_MLO_004', 'CD_MLO_005')
                    AND lo_status=1
             )


SELECT DISTINCT dc.class_dw_id,
                dc.class_curriculum_instructional_plan_id as instructional_plan_id,
                sc.school_dw_id,
                initcap(dc.class_title)                   AS class_title,
                initcap(dc.class_gen_subject)             AS class_gen_subject,
                dc.class_curriculum_id,
                NVL(dsec.section_dw_id, '10001')          AS class_section_dw_id,
                initcap(NVL(dsec.section_name, 'NA'))     AS class_section_name,
                teacher_ids,
                dcg.curr_grade_dw_id,
                dcg.curr_grade_name,
                dg.grade_name,
                dcs.curr_subject_dw_id,
                dcs.curr_subject_name,
                dcay.content_academic_year_id,
                dcay.content_academic_year_name,
                count(DISTINCT dcu.class_user_user_dw_id) AS class_total_students
FROM alefdw.dim_class dc
         INNER JOIN alefdw.dim_class_user dcu
                    ON dcu.class_user_class_dw_id = dc.class_dw_id
         INNER JOIN bi_alefdw.bi_active_schools_dim_mv sc
                    ON md5(dc.class_school_id) = md5(sc.school_id)
         INNER JOIN alefdw.dim_content_repository org
                    ON md5(sc.school_organisation) = md5(org.content_repository_name)
         INNER JOIN alefdw.dim_student ds
                    ON dcu.class_user_user_dw_id = ds.student_dw_id
                    AND sc.school_dw_id = ds.student_school_dw_id
         INNER JOIN school_prveviousay ay
                    ON md5(dc.class_academic_year_id) = md5(ay.academic_year_id)
         INNER JOIN alefdw.dim_content_academic_year dcay
                    ON md5(dc.class_content_academic_year) = md5(dcay.content_academic_year_name)
         INNER JOIN alefdw.dim_curriculum_grade dcg
                    ON md5(dc.class_curriculum_grade_id) = md5(dcg.curr_grade_id)
         INNER JOIN alefdw.dim_curriculum_subject dcs
                    ON md5(dc.class_curriculum_subject_id) = md5(dcs.curr_subject_id)
         INNER JOIN civil_defense_lo cdl
                    ON dc.class_curriculum_grade_id = cdl.instructional_plan_curriculum_grade_id
                    AND dc.class_curriculum_subject_id = cdl.instructional_plan_curriculum_subject_id
                    AND dc.class_curriculum_id = cdl.instructional_plan_curriculum_id
                    AND dcay.content_academic_year_id = cdl.instructional_plan_content_academic_year_id
                    AND dc.class_curriculum_instructional_plan_id = cdl.instructional_plan_id
         INNER JOIN alefdw.dim_grade dg
                    ON md5(dg.grade_id) = md5(dc.class_grade_id)
         LEFT JOIN alefdw.dim_section dsec
                   ON md5(dsec.section_id) = md5(dc.class_section_id)
         LEFT JOIN class_teachers ct
                   ON ct.class_dw_id = dc.class_dw_id
WHERE dcu.class_user_role_dw_id = 2
  AND dc.class_course_status = 'CONCLUDED'
  AND dc.class_material_type <> 'PATHWAY'
  AND lo_code  in ('CD_MLO_000', 'CD_MLO_001', 'CD_MLO_002',
                                'CD_MLO_003', 'CD_MLO_004', 'CD_MLO_005')
--   AND dc.class_school_id = 'c97921a8-6555-4c5f-acd2-9487803f2b66' -- test for 1 school
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16;