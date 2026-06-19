CREATE MATERIALIZED VIEW bi_alefdw_dev.students_lesson_progress_mv AS
WITH COMPLETED_LESSONS AS
                        (select *
                           from (select fle_ls_id,
                                        fle_dw_id,
                                        case when lo.lo_max_stars > 0 then fle_total_score end as                 fle_score,
                                        ROW_NUMBER() over (PARTITION BY fle_ls_id ORDER BY fle_created_time desc) rnk
                                 FROM alefdw.fact_learning_experience
                                          JOIN alefdw.dim_learning_objective lo
                                               ON lo.lo_dw_id = fle_lo_dw_id
                                                   AND lo.lo_status = 1
                                          JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                                               ON fle_school_dw_id = dsc.school_dw_id
                                                   AND trunc(fle_created_time) >= dsc.academic_year_start_date
                                                   AND trunc(fle_created_time) <= dsc.academic_year_end_date
                                 where fle_completion_node is true
                                   AND fact_learning_experience.fle_activity_type <> 'INTERIM_CHECKPOINT'
                                   AND fle_material_type <> 'PATHWAY'
                                   AND fle_is_additional_resource <> TRUE
                                 )-- get latest completed record for a student lesson
                           where rnk = 1
                           ),

     LESSON_PROGRESS AS
                (SELECT fle_dw_id, 0 as fle_score, 'In-Progress' AS lo_status
                         FROM (SELECT fle_ls_id,
                                      MAX(fle_dw_id) fle_dw_id
                               FROM alefdw.fact_learning_experience
                                        JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                                             ON fle_school_dw_id = dsc.school_dw_id
                                                 AND trunc(fle_created_time) >= dsc.academic_year_start_date
                                                 AND trunc(fle_created_time) <= dsc.academic_year_end_date
                               WHERE fle_ls_id NOT IN (select fle_ls_id from COMPLETED_LESSONS)
                                 AND fle_attempt = 1
                                 AND fact_learning_experience.fle_activity_type <> 'INTERIM_CHECKPOINT'
                                 AND fle_material_type <> 'PATHWAY'
                                 AND fle_is_additional_resource <> TRUE
                                 AND fle_abbreviation <> 'NA'
                               GROUP BY 1)-- get any in-progress record for the student lesson

                         UNION ALL

                         SELECT fle_dw_id, fle_score, 'Completed' AS lo_status
                         FROM COMPLETED_LESSONS
                ),

     student_lessons_assigned AS
            ( -- lesson level learning plan for each student
                SELECT DISTINCT d_cu.class_user_user_dw_id,
                                d_cu.class_user_class_dw_id,
                                dcaa.caa_activity_dw_id AS lo_dw_id
                FROM alefdw.dim_class_user d_cu
                         INNER JOIN alefdw.dim_class dc
                                    ON dc.class_dw_id = d_cu.class_user_class_dw_id
                         INNER JOIN alefdw.dim_course dcr
                                    ON md5(dcr.course_id) = md5(class_material_id)
                         INNER JOIN alefdw.dim_course_activity_association dcaa
                                    ON md5(dcaa.caa_course_id) = md5(dcr.course_id)
--                             AND dcaa.caa_activity_is_optional IS FALSE
                WHERE d_cu.class_user_attach_status = 1
                  AND d_cu.class_user_status = 1
                  AND d_cu.class_user_role_dw_id = 2
                  AND dc.class_course_status = 'ACTIVE'
                  AND dcr.course_status = 1
                  AND dcr.course_type = 'CORE'
                  AND dcaa.caa_status = 1
                  AND dcaa.caa_attach_status = 1
                  AND dc.class_status = 1
            )

SELECT fl.*, lps.fle_score, lps.lo_status
FROM (SELECT DISTINCT TRUNC(CONVERT_TIMEZONE('UTC', dsc.tenant_timezone, fle.fle_created_time)) AS local_date,
                      dcu.class_user_class_dw_id                                  AS fle_class_dw_id,
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
                      OVER (PARTITION BY local_date,student_dw_id,fle_lo_dw_id) AS session_time,
                      SUM((CASE
                               WHEN fle.fle_total_time <= 900 THEN fle.fle_total_time
                               WHEN fle.fle_total_time > 900 THEN 900
                               ELSE 0
                          END))
                      OVER (PARTITION BY local_date,student_dw_id,fle_lo_dw_id) AS fle_session_time,
                      dsc.academic_year_start_date,
                      dsc.academic_year_end_date
      FROM alefdw.fact_learning_experience fle
               JOIN bi_alefdw.bi_student_dim_mv dst
                    ON fle.fle_student_dw_id = dst.student_dw_id AND student_status = 1
               JOIN alefdw.dim_grade dg on dg.grade_dw_id = fle.fle_grade_dw_id
               JOIN student_lessons_assigned dcu
                    ON fle_student_dw_id = dcu.class_user_user_dw_id
                        AND fle_lo_dw_id = dcu.lo_dw_id
               JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                    ON fle.fle_school_dw_id = dsc.school_dw_id
                        AND trunc(fle_created_time) >= dsc.academic_year_start_date
                        AND trunc(fle_created_time) <= dsc.academic_year_end_date
      WHERE fle_abbreviation <> 'NA'
        AND FLE.fle_activity_type <> 'INTERIM_CHECKPOINT'
        AND fle_material_type <> 'PATHWAY'
        AND fle_is_additional_resource <> TRUE
        AND fle.fle_ls_id NOT IN
            (select distinct fle_ls_id from alefdw.fact_learning_experience where fle_state = 4)) fl
         JOIN LESSON_PROGRESS lps ON fl.fle_dw_id = lps.fle_dw_id
WHERE NVL(fle_lesson_category, 'NA') <> 'EXPERIENTIAL_LESSON';