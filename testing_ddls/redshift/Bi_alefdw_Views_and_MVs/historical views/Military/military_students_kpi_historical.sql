CREATE OR REPLACE VIEW bi_alefdw_dev.military_students_kpi_historical AS
WITH term_details AS
    (SELECT DISTINCT academic_year,
                    term_start_date,
                    term_end_date,
                    school_dw_id,
                    term_academic_period_order AS term
    FROM bi_alefdw.student_progress_core_military_historical_data
),
     agg_data AS (SELECT school_dw_id,
                         school_name,
                         grade_name,
                         academic_year,
                         term_start_date,
                         term_end_date,
                         student_dw_id,
                         student_id,
                         class_gen_subject,
                         class_dw_id,
                         lo_dw_id,
                         local_date,
                         avg(fle_session_time) / 60                                                   AS fle_session_time,
                         avg(CASE WHEN lo_status = 'Completed' AND fle_score >= 0 THEN fle_score END) AS fle_score,
                         count(DISTINCT
                               CASE lo_status
                                   WHEN 'Completed' THEN lo_dw_id
                                   END)                                                                  completed_lessons,
                         count(DISTINCT lo_dw_id)                                                        total_lessons
                  FROM bi_alefdw.student_progress_core_military_historical_data
                  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
),
     core_kpi AS (SELECT school_dw_id,
                         school_name,
                         academic_year,
                         term_start_date,
                         term_end_date,
                         grade_name,
                         student_dw_id,
                         student_id,
                         sum(fle_session_time) / count(DISTINCT local_date) AS avg_time_spent,
                         sum(fle_session_time)                              AS total_time_spent,
                         avg(fle_score)                                     AS avg_score,
                         sum(fle_score)                                     AS total_score,
                         sum(completed_lessons)                             AS completed_lessons,
                         sum(total_lessons)                                 AS total_lessons_assigned,
                         sum(class_students)                                AS class_total_students
                  FROM agg_data ad
                           JOIN (SELECT class_dw_id,
                                        lo_dw_id,
                                        count(distinct student_dw_id) class_students
                                 FROM bi_alefdw.student_progress_core_military_historical_data
                                 GROUP BY 1, 2) cs ON
                      ad.class_dw_id = cs.class_dw_id AND
                      ad.lo_dw_id = cs.lo_dw_id
                  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
),
     login_kpi AS (SELECT school_dw_id,
                          school_id,
                          school_name,
                          grade_dw_id,
                          academic_year,
                          academic_year_start_date,
                          academic_year_end_date,
                          reg_student_dw_id,
                          reg_student_id,
                          term_start_date,
                          term_end_date,
                          term,
                          grade_name,
                          sum(login)                 total_login,
                          sum(registered_student) AS total_registered
                   FROM (SELECT log.school_dw_id,
                                log.school_id,
                                initcap(school_name)                 school_name,
                                grade_dw_id,
                                log.academic_year,
                                log.academic_year_start_date,
                                log.academic_year_end_date,
                                local_date,
                                reg_student_dw_id,
                                reg_student_id,
                                term,
                                term_start_date,
                                term_end_date,
                                grade_name,
                                count(DISTINCT log_student_dw_id) AS login,
                                count(DISTINCT reg_student_dw_id) AS registered_student
                         FROM bi_alefdw.student_login_military_historical_data log
                                  INNER JOIN
                              term_details t ON
                                  md5(log.academic_year) = md5(t.academic_year) AND
                                  log.school_dw_id = t.school_dw_id AND
                                  local_date BETWEEN term_start_date AND term_end_date
                         WHERE date_part(dayofweek, local_date) NOT IN (6, 0) --excluding weekends from login data
                         GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14) a
                   GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13)

SELECT login.school_dw_id,
       login.school_id,
       login.school_name,
       login.grade_name,
       login.term_start_date,
       login.term_end_date,
       CASE
           WHEN (sysdate - 1)::DATE BETWEEN login.term_start_date AND login.term_end_date
               THEN (sysdate - 1)::DATE
           ELSE
               login.term_end_date
           END                                                     AS term_date_till_date, --to calculate actual login % for students IN current term
       core.student_dw_id,
       core.student_id,
       core.academic_year                                             core_ay,
       core.total_lessons_assigned,
       login.term::VARCHAR,
       login.academic_year,
       login.academic_year_start_date,
       login.academic_year_end_date,
       login.total_login,
       login.total_registered,
       login.reg_student_dw_id,
       login.reg_student_id,
       DATEDIFF('day', login.term_start_date, term_date_till_date) -
       DATEDIFF('week', login.term_start_date, DATEADD('day', 1, term_date_till_date)) -
       DATEDIFF('week', login.term_start_date, term_date_till_date) +
       1                                                           AS term_days,           --calculating term days excluding weekends
       CASE WHEN core_ay is not NULL THEN avg_time_spent END       AS avg_time_spent,
       CASE WHEN core_ay is not NULL THEN total_time_spent END     AS total_time_spent,
       CASE WHEN core_ay is not NULL THEN avg_score END            AS avg_score,
       CASE WHEN core_ay is not NULL THEN total_score END          AS total_score,
       CASE WHEN core_ay is not NULL THEN completed_lessons END    AS completed_lessons,
       CASE WHEN core_ay is not NULL THEN class_total_students END AS class_total_students,
       CASE WHEN core_ay is not NULL THEN 'core' END               AS core_flag
FROM login_kpi login
         INNER JOIN
     core_kpi core ON
         core.term_start_date = login.term_start_date AND
         core.student_dw_id = login.reg_student_dw_id
ORDER BY 4, 5, 6, 7
WITH NO SCHEMA BINDING;