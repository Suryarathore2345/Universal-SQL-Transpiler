CREATE OR REPLACE view bi_alefdw.aggr_learning_experience_dm_view as
select *
from (select DISTINCT le_dm.local_date,
                      fle_outside_of_school,
                      le_dm.section_name,
                      ts.total_students                                                      AS section_total_students,
                      le_dm.class,
                      le_dm.grade_k12grade,
                      le_dm.learning_path_name,
                      le_dm.learning_path_experiential_learning,
                      le_dm.tenant_name,
                      le_dm.school_dw_id,
                      le_dm.school_id,
                      le_dm.school_name,
                      le_dm.school_adek_id,
                      le_dm.school_organisation,
                      le_dm.school_city_name,
                      le_dm.school_country_name,
                      le_dm.school_composition,
                      le_dm.school_label,
                      student_dw_id,
                      le_dm.student_tags,
                      le_dm.student_special_needs,
                      lesson_type,
                      DENSE_RANK() OVER (PARTITION BY le_dm.local_date,student_dw_id,le_dm.curr_subject_name
                          ORDER BY le_dm.lo_code ASC )
                          +
                      DENSE_RANK() OVER (PARTITION BY le_dm.local_date,le_dm.student_dw_id,le_dm.curr_subject_name
                          ORDER BY le_dm.lo_code DESC )
                          -
                      1                                                                      AS mlos_attempted,

                      CASE
                          WHEN lesson_type = 'SA' and fle_attempt = 1
                              THEN
                                      COUNT(lo_code)
                                      OVER (PARTITION BY le_dm.local_date,student_dw_id,subject_gen_subject,lesson_type,fle_attempt)
                          ELSE 0
                          END                                                                AS mlos_completed,

                      CASE
                          WHEN lesson_type = 'SA' and fle_attempt = 1
                              THEN
                                      SUM(fle_score)
                                      OVER (PARTITION BY le_dm.local_date,student_dw_id,subject_gen_subject,lesson_type,fle_attempt)
                          ELSE 0
                          END                                                                AS fle_score,
                      SUM(session_time)
                      OVER (PARTITION BY le_dm.local_date,student_dw_id,subject_gen_subject) AS time_spent,
                      le_dm.curr_name,
                      le_dm.curr_subject_name,
                      le_dm.subject_gen_subject,
                      le_dm.subject_online,
                      DENSE_RANK() OVER (PARTITION BY le_dm.local_date,
                          le_dm.school_dw_id,
                          le_dm.section_name,
                          le_dm.curr_subject_name
                          ORDER BY le_dm.student_dw_id ASC )
                          +
                      DENSE_RANK() OVER (PARTITION BY le_dm.local_date,
                          le_dm.school_dw_id,
                          le_dm.section_name,
                          le_dm.curr_subject_name
                          ORDER BY le_dm.student_dw_id DESC )
                          -
                      1                                                                      AS unique_students_attempted,

                      DENSE_RANK() OVER (PARTITION BY le_dm.local_date,
                          le_dm.school_dw_id,
                          le_dm.section_name,
                          le_dm.curr_subject_name
                          ORDER BY le_dm.lo_code ASC )
                          +
                      DENSE_RANK() OVER (PARTITION BY le_dm.local_date,
                          le_dm.school_dw_id,
                          le_dm.section_name,
                          le_dm.curr_subject_name
                          ORDER BY le_dm.lo_code DESC )
                          -
                      1                                                                      AS unique_mlos_attempted,

                      CASE
                          WHEN lesson_type = 'SA' and fle_attempt = 1
                              THEN
                                              DENSE_RANK() OVER (PARTITION BY le_dm.local_date,
                                          le_dm.school_dw_id,
                                          le_dm.section_name,
                                          le_dm.curr_subject_name,
                                          lesson_type,
                                          fle_attempt
                                          ORDER BY le_dm.lo_code ASC )
                                      +
                                              DENSE_RANK() OVER (PARTITION BY le_dm.local_date,
                                                  le_dm.school_dw_id,
                                                  le_dm.section_name,
                                                  le_dm.curr_subject_name,
                                                  lesson_type,
                                                  fle_attempt
                                                  ORDER BY le_dm.lo_code DESC )
                                  -
                                              1 END                                          AS unique_mlos_completed
      from (select *,
                   CASE
                       WHEN fle_lesson_type = 'SA'
                           THEN
                           fle_lesson_type
                       ELSE 'NOT SA'
                       END as lesson_type
            from bi_alefdw.learning_experience_dm where fle_lesson_type not in('n/a')) le_dm

      inner join bi_alefdw.total_students ts
          on le_dm.local_date = ts.local_date
          and le_dm.school_dw_id = ts.school_dw_id
          and md5(le_dm.section_name) = md5(ts.section)
          and le_dm.grade_k12grade = ts.grade
          and md5(le_dm.student_special_needs) = md5(ts.student_special_needs)
          and md5(le_dm.student_tags) = md5(ts.student_tags))
;
