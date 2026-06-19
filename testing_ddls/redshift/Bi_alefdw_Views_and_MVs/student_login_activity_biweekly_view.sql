CREATE OR REPLACE VIEW bi_alefdw_dev.student_login_activity_biweekly_view AS
WITH total_students AS -- Section Level
         (SELECT DISTINCT full_date                                                     AS local_date,
                          tenant_name,
                          dsc.school_dw_id,
                          dsc.school_id,
                          school_name,
                          school_city_name,
                          school_organisation,
                          organisation_dw_id,
                          school_country_name,
                          school_composition,
                          school_alias                                                  AS adek_id,
                          school_created_time,
                          date_part(year, dsc.academic_year_start_date) || '-' ||
                          date_part(year, dsc.academic_year_end_date)                   AS academic_year,
                          dsc.academic_year_start_date,
                          dsc.academic_year_end_date,
                          grade_k12grade                                                AS grade,
                          ''                                                            AS class,
                          section_dw_id,
                          section_alias                                                 AS section,
                          student_tags,
                          student_special_needs                                         AS special_needs,
                          ds.student_dw_id                                              AS available_student_dw_id,
                          ds.student_id,
                          student_username,
                          student_first_created_date,
                          first_value(student_status)
                          OVER (PARTITION BY school_dw_id, section_dw_id, student_dw_id
                              ORDER BY student_created_time DESC
                              ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS student_current_status,
                          school_label,
                          dsc.school_cx_cluster
          FROM (SELECT full_date, section_alias, section_dw_id, grade_id, school_id, tenant_id, section_id
                FROM alefdw.dim_section
                         CROSS JOIN (SELECT distinct full_date
                                     FROM alefdw.dim_date dt
                                     WHERE dt.full_date between trunc(sysdate) - 14 and trunc(sysdate))
                WHERE school_id is not null) dse
                   INNER JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                              ON dsc.school_id = dse.school_id
                                  AND
                                 (full_date >= dsc.academic_year_start_date and full_date <= dsc.academic_year_end_date)
                   INNER JOIN bi_alefdw.bi_student_dim_mv ds
                              ON ds.student_section_dw_id = dse.section_dw_id
                                  AND ((student_status = 2 AND
                                        full_date >=
                                        trunc(convert_timezone('UTC', dsc.tenant_timezone, student_created_time))
                                      AND full_date <
                                          trunc(convert_timezone('UTC', dsc.tenant_timezone, student_active_until)))
                                      OR (student_status = 1 AND full_date >= trunc(
                                              convert_timezone('UTC', dsc.tenant_timezone, student_created_time))))
                   INNER JOIN alefdw.dim_grade dg
                              ON dse.grade_id = dg.grade_id
                                  AND dg.grade_dw_id = ds.student_grade_dw_id
                                  AND MD5(dsc.academic_year_id) = MD5(dg.academic_year_id)),

     active_students AS -- Section Level
         (SELECT DISTINCT login_date,
                          student_section_dw_id,
                          student_tags,
                          special_needs,
                          active_student_dw_id
          FROM (SELECT DISTINCT Trunc(login_local_date_time) AS login_date,
                                student_section_dw_id,
                                student_tags,
                                student_special_needs        AS special_needs,
                                sl.student_dw_id             AS active_student_dw_id
                FROM bi_alefdw.student_login sl
                         INNER JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                                    ON dsc.school_dw_id = sl.school_dw_id
                         INNER JOIN bi_alefdw.bi_student_dim_mv ds
                                    ON ds.student_dw_id = sl.student_dw_id
                                        AND ((student_status = 2 AND
                                              trunc(login_local_date_time) >=
                                              trunc(
                                                      convert_timezone('UTC', dsc.tenant_timezone, student_created_time))
                                            AND trunc(login_local_date_time) <
                                                trunc(
                                                        convert_timezone('UTC', dsc.tenant_timezone, student_active_until)))
                                            OR (student_status = 1 AND trunc(login_local_date_time) >= trunc(
                                                    convert_timezone('UTC', dsc.tenant_timezone, student_created_time))))

                WHERE trunc(login_local_date_time) >=
                      trunc(convert_timezone('UTC', dsc.tenant_timezone, sysdate)) - 14
                  and trunc(login_local_date_time) <= trunc(convert_timezone('UTC', dsc.tenant_timezone, sysdate)))),
     student_onboarding as (select distinct student_dw_id,
                                            sl.school_dw_id,
                                            first_value(login_local_date_time)
                                            over (partition by student_dw_id, sl.school_dw_id order by login_local_date_time asc
                                                rows between unbounded preceding and unbounded following) AS student_first_login_date,
                                            first_value(login_local_date_time)
                                            over (partition by student_dw_id, sl.school_dw_id order by login_local_date_time desc
                                                rows between unbounded preceding and unbounded following) AS student_last_login_date
                            from bi_alefdw.student_login sl
                                     INNER JOIN bi_alefdw.bi_active_schools_dim_mv ds
                                                ON ds.school_dw_id = sl.school_dw_id
                                                    AND trunc(login_local_date_time) >= ds.academic_year_start_date),
     school_prveviousay as -- define previous Academic Year start and end date by school
         (select school_dw_id,
                 max(academic_year_start_date) as previous_academic_year_start_date,
                 max(academic_year_end_date)   as previous_academic_year_end_date
          from bi_alefdw.bi_all_schools_dim_mv
          where academic_year_is_roll_over_completed
          group by 1),
     student_onboarding_pay as
         -- list of students with logins in previous ay
         (select distinct student_dw_id
          from bi_alefdw.student_login sl
                   inner join school_prveviousay spay
                              on sl.school_dw_id = spay.school_dw_id
                                  and
                                 trunc(sl.login_local_date_time) between spay.previous_academic_year_start_date and spay.previous_academic_year_end_date),
     lessons_started as (SELECT distinct fle_student_dw_id,
                                         min(trunc(fle_created_time)) AS student_lesson_start_date
                         FROM alefdw.fact_learning_experience fle
                                  INNER JOIN bi_alefdw.bi_active_schools_dim_mv ds
                                             ON ds.school_dw_id = fle.fle_school_dw_id
                                                 AND trunc(fle_created_time) >= ds.academic_year_start_date
                         WHERE fle_activity_type <> 'INTERIM_CHECKPOINT'
                         GROUP BY 1),
     holidays_dimension as
         (SELECT DISTINCT cast(holiday_date AS date) AS holiday_date,
                          holiday_organisation_dw_id
          FROM alefdw.dim_holiday)

SELECT DISTINCT local_date,
                academic_year,
                ts.tenant_name,
                ts.school_dw_id,
                ts.school_id,
                ts.school_name,
                ts.school_created_time,
                ts.adek_id,
                ts.school_city_name,
                ts.school_organisation,
                ts.school_country_name,
                ts.school_composition,
                ts.school_label,
                ts.grade,
                initcap(ts.class)                                        AS class,
                initcap(ts.section)                                      AS section,
                ts.student_tags,
                ts.special_needs,
                ts.available_student_dw_id,
                case when pay_st.student_dw_id is null then 0 else 1 end as repeat_student_previous_ay,
                active_student_dw_id,
                student_id,
                student_username,
                student_first_created_date,
                student_current_status,
                student_first_login_date,
                student_last_login_date,
                student_lesson_start_date,
                ts.academic_year_start_date,
                ts.academic_year_end_date,
                ts.section_dw_id,
                case when holiday_date is null then FALSE ELSE TRUE END  as holiday_flag,
                ts.school_cx_cluster
FROM total_students ts
         LEFT JOIN active_students ast
                   ON ts.section_dw_id = ast.student_section_dw_id
                       AND ts.local_date = ast.login_date
                       AND ts.student_tags = ast.student_tags
                       AND ts.special_needs = ast.special_needs
                       AND ts.available_student_dw_id = ast.active_student_dw_id
         LEFT JOIN student_onboarding so
                   on ts.available_student_dw_id = so.student_dw_id
                       and ts.school_dw_id = so.school_dw_id
         LEFT JOIN student_onboarding_pay pay_st
                   on ts.available_student_dw_id = pay_st.student_dw_id
         LEFT JOIN lessons_started ls
                   on ts.available_student_dw_id = ls.fle_student_dw_id
         LEFT JOIN holidays_dimension dh
                   on dh.holiday_date = ts.local_date and
                      dh.holiday_organisation_dw_id = ts.organisation_dw_id
WITH NO SCHEMA BINDING;
