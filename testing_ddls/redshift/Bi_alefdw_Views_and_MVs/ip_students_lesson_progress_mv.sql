create materialized view bi_alefdw_dev.ip_students_lesson_progress_mv AS
WITH COMPLETED_LESSONS AS (select *
                           from (select fle_ls_id,
                                        fle_dw_id,
                                        case when lo.lo_max_stars > 0 then fle_total_score end as                 fle_score,
                                        ROW_NUMBER() over (PARTITION BY fle_ls_id ORDER BY fle_created_time desc) rnk
                                 FROM alefdw.fact_learning_experience
                                          JOIN alefdw.dim_learning_objective lo
                                               ON lo.lo_dw_id = fle_lo_dw_id AND lo_status=1
                                          JOIN alefdw.dim_academic_year ay
                                               ON fle_academic_year_dw_id = ay.academic_year_dw_id
                                                   AND ay.academic_year_is_roll_over_completed = FALSE
                                                   AND ay.academic_year_status = 1
                                 where fle_completion_node is true
                                   AND fact_learning_experience.fle_activity_type <> 'INTERIM_CHECKPOINT'
                                   AND fle_material_type <> 'PATHWAY') -- get latest completed record for a student lesson
                           where rnk = 1),

     LESSON_PROGRESS AS (SELECT fle_dw_id, 0 as fle_score, 'In-Progress' AS lo_status
                         FROM (SELECT fle_ls_id,
                                      MAX(fle_dw_id) fle_dw_id
                               FROM alefdw.fact_learning_experience
                                        JOIN alefdw.dim_academic_year ay
                                             ON fle_academic_year_dw_id = ay.academic_year_dw_id
                                                 AND ay.academic_year_is_roll_over_completed = FALSE
                                                 AND ay.academic_year_status = 1
                               WHERE fle_ls_id NOT IN (select fle_ls_id from COMPLETED_LESSONS)
                                 AND fle_attempt = 1
                                 AND fact_learning_experience.fle_activity_type <> 'INTERIM_CHECKPOINT'
                                 AND fle_material_type <> 'PATHWAY'
                                 AND fle_abbreviation <> 'NA'
                               GROUP BY 1) -- get any in-progress record for the student lesson

                         UNION ALL

                         SELECT fle_dw_id, fle_score, 'Completed' AS lo_status
                         FROM COMPLETED_LESSONS),
     student_lessons_assigned AS ( -- lesson level learning plan for each student
         SELECT DISTINCT d_cu.class_user_user_dw_id,
                         d_cu.class_user_class_dw_id,
                         dcs.curr_subject_dw_id,
                         dip.instructional_plan_item_lo_dw_id AS lo_dw_id
         FROM alefdw.dim_class_user d_cu
                  INNER JOIN alefdw.dim_class dc
                             ON dc.class_dw_id = d_cu.class_user_class_dw_id
                  INNER JOIN alefdw.dim_curriculum_subject dcs
                             ON md5(dc.class_curriculum_subject_id) = md5(dcs.curr_subject_id)
                  INNER JOIN alefdw.dim_instructional_plan dip
                             ON dc.class_curriculum_grade_id = dip.instructional_plan_curriculum_grade_id
                                 AND dc.class_curriculum_subject_id = dip.instructional_plan_curriculum_subject_id
                                 AND dc.class_curriculum_id = dip.instructional_plan_curriculum_id
                                 AND dc.class_curriculum_instructional_plan_id = dip.instructional_plan_id
                                 AND dip.instructional_plan_status = 1
--                   AND dip.instructional_plan_item_optional IS FALSE
         WHERE d_cu.class_user_attach_status = 1
           AND d_cu.class_user_status = 1
           AND d_cu.class_user_role_dw_id = 2
           AND dc.class_course_status = 'ACTIVE'
           AND dc.class_status = 1)

SELECT fl.*, lps.fle_score, lps.lo_status
FROM (SELECT DISTINCT dd.full_date                                                AS local_date,
                      dcu.class_user_class_dw_id                                  AS fle_class_dw_id,
                      term_curriculum_id,
                      fle_lo_dw_id                                                AS lo_attempted,
                      fle_lesson_category,
                      fle_dw_id,
                      fle_source,
                      dst.student_dw_id,
                      dst.student_section_dw_id,
                      fle_academic_year_dw_id,
                      dst.student_tags,
                      dst.student_special_needs,
                      dg.grade_k12grade,
                      SUM((CASE
                               WHEN fle.fle_total_time <= 900 THEN fle.fle_total_time
                               WHEN fle.fle_total_time > 900 THEN 900
                               ELSE 0
                          END))
                      OVER (PARTITION BY dd.full_date,student_dw_id,fle_lo_dw_id) AS session_time,
                      SUM((CASE
                               WHEN fle.fle_total_time <= 900 THEN fle.fle_total_time
                               WHEN fle.fle_total_time > 900 THEN 900
                               ELSE 0
                          END))
                      OVER (PARTITION BY dd.full_date,student_dw_id,fle_lo_dw_id) AS fle_session_time,
                      academic_year_start_date,
                      academic_year_end_date
      FROM alefdw.fact_learning_experience fle
               JOIN alefdw.dim_term fle_dtrm ON fle.fle_term_dw_id = fle_dtrm.term_dw_id
               JOIN bi_alefdw.bi_student_dim_mv dst
                    ON fle.fle_student_dw_id = dst.student_dw_id AND student_status = 1
               JOIN alefdw.dim_date dd ON fle.fle_date_dw_id = dd.date_id
               JOIN alefdw.dim_grade dg on dg.grade_dw_id = fle.fle_grade_dw_id
               JOIN student_lessons_assigned dcu
                    ON fle_student_dw_id = dcu.class_user_user_dw_id
                        AND fle_lo_dw_id = dcu.lo_dw_id
               JOIN alefdw.dim_academic_year ay
                    ON fle.fle_academic_year_dw_id = ay.academic_year_dw_id
                        AND ay.academic_year_is_roll_over_completed = FALSE
                        AND ay.academic_year_status = 1
      WHERE fle_abbreviation <> 'NA'
        AND FLE.fle_activity_type <> 'INTERIM_CHECKPOINT'
        AND fle_material_type <> 'PATHWAY'
        AND
          fle.fle_ls_id NOT IN (select distinct fle_ls_id from alefdw.fact_learning_experience where fle_state = 4)) fl
         JOIN LESSON_PROGRESS lps ON fl.fle_dw_id = lps.fle_dw_id
WHERE NVL(fle_lesson_category, 'NA') <> 'EXPERIENTIAL_LESSON';