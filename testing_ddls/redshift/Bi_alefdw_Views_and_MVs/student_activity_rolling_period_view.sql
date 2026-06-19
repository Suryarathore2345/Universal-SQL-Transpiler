CREATE OR REPLACE VIEW bi_alefdw_dev.student_activity_rolling_period_view AS
WITH students_lessons AS (SELECT slp.student_dw_id,
                                 sch.school_dw_id,
                                 count(CASE
                                           WHEN slp.lo_status = 'Completed'
                                               AND slp.local_date BETWEEN trunc(sysdate) - 7 AND trunc(sysdate) - 1
                                               THEN slp.lo_attempted
                                     END) AS lessons_completed_last7d,
                                 count(CASE
                                           WHEN slp.lo_status = 'Completed'
                                               AND slp.local_date BETWEEN trunc(sysdate) - 14 AND trunc(sysdate) - 8
                                               THEN slp.lo_attempted
                                     END) AS lessons_completed_prev7d
                          FROM bi_alefdw.students_lesson_progress_mv slp
                                   INNER JOIN bi_alefdw.bi_student_dim_mv st
                                              ON st.student_dw_id = slp.student_dw_id
                                                  AND st.student_status = 1
                                   INNER JOIN bi_alefdw.bi_active_schools_dim_mv sch
                                              ON sch.school_dw_id = st.student_school_dw_id
                                   INNER JOIN (SELECT DISTINCT cts.class_dw_id,
                                                               cts.section_dw_id,
                                                               dcaa.caa_activity_dw_id AS instructional_plan_item_lo_dw_id
                                               FROM bi_alefdw.class_total_students_mv cts
                                                        INNER JOIN alefdw.dim_course_activity_association dcaa
                                                                   ON md5(dcaa.caa_course_id) =
                                                                      md5(cts.instructional_plan_id)
                                                                       AND dcaa.caa_activity_type = 1
                                                                       AND dcaa.caa_activity_is_optional is FALSE
                                                        INNER JOIN alefdw.dim_learning_objective dip_dlo
                                                                   ON dcaa.caa_activity_dw_id = dip_dlo.lo_dw_id
                                                                       AND nvl(dip_dlo.lo_type, 'NA') <>
                                                                           'EXPERIENTIAL_LESSON'
                                               WHERE LOWER(cts.class_title) NOT LIKE '%power skills%'
                                                 AND LOWER(cts.class_title) NOT LIKE '%extra resources%'
                                                 AND LOWER(cts.class_gen_subject) != 'alef stars') cl
                                              ON cl.class_dw_id = slp.fle_class_dw_id
                                                  AND cl.section_dw_id = slp.student_section_dw_id
                                                  AND cl.instructional_plan_item_lo_dw_id = slp.lo_attempted
                          GROUP BY 1, 2),
     active_students_period AS (SELECT sl.student_dw_id,
                                       sl.school_dw_id,
                                       nvl(slo.lessons_completed_last7d, 0) AS lessons_completed_last7d,
                                       nvl(slo.lessons_completed_prev7d, 0) AS lessons_completed_prev7d,
                                       count(DISTINCT CASE
                                                          WHEN trunc(sl.login_local_date_time) BETWEEN trunc(sysdate) - 7
                                                              AND trunc(sysdate) - 1
                                                              THEN trunc(sl.login_local_date_time)
                                           END)                             AS active_days_last7d,
                                       count(DISTINCT CASE
                                                          WHEN trunc(sl.login_local_date_time) BETWEEN trunc(sysdate) - 14
                                                              AND trunc(sysdate) - 8
                                                              THEN trunc(sl.login_local_date_time)
                                           END)                             AS active_days_prev7d,
                                       count(DISTINCT CASE
                                                          WHEN trunc(sl.login_local_date_time) BETWEEN trunc(sysdate) - 30
                                                              AND trunc(sysdate) - 1
                                                              THEN trunc(sl.login_local_date_time)
                                           END)                             AS active_days_last30d,
                                       count(DISTINCT CASE
                                                          WHEN trunc(sl.login_local_date_time) BETWEEN trunc(sysdate) - 60
                                                              AND trunc(sysdate) - 31
                                                              THEN trunc(sl.login_local_date_time)
                                           END)                             AS active_days_prev30d
                                FROM bi_alefdw.student_login sl
                                         LEFT JOIN students_lessons slo
                                                   ON slo.student_dw_id = sl.student_dw_id
                                                       AND slo.school_dw_id = sl.school_dw_id
                                GROUP BY 1, 2, 3, 4),
     student_onboarding AS
         (SELECT DISTINCT student_dw_id,
                          sl.school_dw_id,
                          first_value(login_local_date_time) OVER (
                              PARTITION BY student_dw_id, sl.school_dw_id ORDER BY login_local_date_time ASC
                              rows BETWEEN unbounded preceding AND unbounded following
                              ) AS student_first_login_date,
                          first_value(login_local_date_time) OVER (
                              PARTITION BY student_dw_id, sl.school_dw_id ORDER BY login_local_date_time DESC
                              rows BETWEEN unbounded preceding AND unbounded following
                              ) AS student_last_login_date
          FROM bi_alefdw.student_login sl
                   INNER JOIN bi_alefdw.bi_active_schools_dim_mv ds
                       ON ds.school_dw_id = sl.school_dw_id
                      AND trunc(login_local_date_time) >= ds.academic_year_start_date)
SELECT DISTINCT dsc.tenant_name,
                dsc.school_dw_id,
                dsc.school_id,
                dsc.school_name,
                dsc.school_alias                           AS adek_id,
                dsc.school_city_name,
                dsc.school_organisation,
                dsc.organisation_dw_id,
                dg.grade_k12grade                          AS grade,
                dse.section_dw_id,
                dse.section_name                           AS section,
                ds.student_dw_id,
                ds.student_id,
                ds.student_special_needs,
                ds.student_tags,
                ds.student_first_created_date,
                so.student_first_login_date,
                so.student_last_login_date,
                date_part(year, dsc.academic_year_start_date) || '-' ||
                date_part(year, dsc.academic_year_end_date) AS academic_year,
                nvl(asp.active_days_last7d, 0)             as active_days_last7d,
                nvl(asp.active_days_prev7d, 0)             as active_days_prev7d,
                nvl(asp.active_days_last30d, 0)            as active_days_last30d,
                nvl(asp.active_days_prev30d, 0)            as active_days_prev30d,
                nvl(asp.lessons_completed_last7d, 0)       as lessons_completed_last7d,
                nvl(asp.lessons_completed_prev7d, 0)       as lessons_completed_prev7d
FROM bi_alefdw.bi_student_dim_mv ds
         INNER JOIN alefdw.dim_section dse
                    ON ds.student_section_dw_id = dse.section_dw_id
                        AND section_status = 1
         INNER JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                    ON dsc.school_id = dse.school_id
         INNER JOIN alefdw.dim_grade dg
                    ON dse.grade_id = dg.grade_id
                        AND dg.grade_dw_id = ds.student_grade_dw_id
                        AND MD5(dsc.academic_year_id) = MD5(dg.academic_year_id)
         LEFT JOIN active_students_period asp
                   ON asp.student_dw_id = ds.student_dw_id
                       AND asp.school_dw_id = ds.student_school_dw_id
         LEFT JOIN student_onboarding so
                   ON ds.student_dw_id = so.student_dw_id
                       AND ds.student_school_dw_id = so.school_dw_id
WHERE ds.student_status = 1
WITH NO SCHEMA BINDING;