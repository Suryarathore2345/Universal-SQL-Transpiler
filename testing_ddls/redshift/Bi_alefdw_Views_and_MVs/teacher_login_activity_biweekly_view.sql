CREATE OR REPLACE VIEW bi_alefdw_dev.teacher_login_activity_biweekly_view as
WITH total_teachers AS (SELECT DISTINCT ds.*,
                                        full_date                                                     AS local_date,
                                        dt.teacher_dw_id                                              AS available_teacher_dw_id,
                                        dt.teacher_id,
                                        first_value(trunc(teacher_created_time))
                                        OVER (PARTITION BY teacher_dw_id
                                            ORDER BY teacher_created_time
                                            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS teacher_first_created_date,
                                        first_value(teacher_status)
                                        OVER (PARTITION BY school_dw_id, teacher_dw_id
                                            ORDER BY teacher_created_time DESC
                                            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS teacher_current_status
                        FROM bi_alefdw.bi_active_schools_dim_mv ds
                                 CROSS JOIN (SELECT DISTINCT full_date
                                             FROM alefdw.dim_date dt
                                             WHERE dt.full_date BETWEEN TRUNC(SYSDATE) - 14 AND TRUNC(SYSDATE))
                                 INNER JOIN alefdw.dim_teacher dt
                                            ON dt.teacher_school_dw_id = ds.school_dw_id
                                                AND ((
                                                         teacher_status = 2
                                                             AND full_date >=
                                                                 TRUNC(convert_timezone('UTC', ds.tenant_timezone, teacher_created_time))
                                                             AND full_date <
                                                                 TRUNC(convert_timezone('UTC', ds.tenant_timezone, teacher_active_until)))
                                                    OR (teacher_status = 1 AND
                                                        full_date >=
                                                        trunc(convert_timezone('UTC', ds.tenant_timezone, teacher_created_time))))
                        WHERE dt.teacher_id NOT IN (SELECT DISTINCT teacher_id FROM bi_alefdw.exclude_teacher_id)
                          AND (full_date >= ds.academic_year_start_date AND full_date <= ds.academic_year_end_date)),
     active_teachers AS (SELECT DISTINCT login_date,
                                         school_dw_id,
                                         active_teacher_dw_id
                         FROM (SELECT DISTINCT TRUNC(login_local_date_time) AS login_date,
                                               tl.school_dw_id,
                                               tl.teacher_dw_id             AS active_teacher_dw_id
                               FROM bi_alefdw.teacher_login tl
                                        INNER JOIN bi_alefdw.bi_active_schools_dim_mv ds
                                                   ON tl.school_dw_id = ds.school_dw_id
                                        INNER JOIN alefdw.dim_teacher dt
                                                   ON dt.teacher_school_dw_id = tl.school_dw_id
                                                       AND dt.teacher_dw_id = tl.teacher_dw_id
                                                       AND ((teacher_status = 2
                                                           AND TRUNC(login_local_date_time) >=
                                                               TRUNC(convert_timezone('UTC', ds.tenant_timezone, teacher_created_time))
                                                           AND TRUNC(login_local_date_time) <
                                                               TRUNC(convert_timezone('UTC', ds.tenant_timezone, teacher_active_until)))
                                                           OR teacher_status = 1)
                               WHERE TRUNC(login_local_date_time) between TRUNC(SYSDATE) - 14 AND TRUNC(SYSDATE)
                                 AND dt.teacher_id NOT IN
                                     (SELECT DISTINCT teacher_id FROM bi_alefdw.exclude_teacher_id))),
     teacher_onboarding AS (SELECT DISTINCT teacher_dw_id,
                                            ds.school_dw_id,
                                            first_value(login_local_date_time)
                                            OVER (
                                                PARTITION BY tl.teacher_dw_id, ds.school_dw_id
                                                ORDER BY tl.login_local_date_time
                                                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS teacher_first_login_date,
                                            first_value(login_local_date_time)
                                            OVER (
                                                PARTITION BY tl.teacher_dw_id, ds.school_dw_id
                                                ORDER BY tl.login_local_date_time DESC
                                                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS teacher_last_login_date
                            FROM bi_alefdw.teacher_login tl
                                     INNER JOIN bi_alefdw.bi_active_schools_dim_mv ds
                                                ON ds.school_dw_id = tl.school_dw_id
                                                    AND TRUNC(login_local_date_time) >= ds.academic_year_start_date),
     school_prveviousay as -- define previous Academic Year start and end date by school
         (select school_dw_id,
                 max(academic_year_start_date) as previous_academic_year_start_date,
                 max(academic_year_end_date)   as previous_academic_year_end_date
          from bi_alefdw.bi_all_schools_dim_mv
          where academic_year_is_roll_over_completed
          group by 1),
     teacher_onboarding_pay as
         -- list of teachers with logins in previous ay
         (select distinct teacher_dw_id
          from bi_alefdw.teacher_login tl
                   inner join bi_alefdw.bi_active_schools_dim_mv ds
                              on ds.school_dw_id = tl.school_dw_id
                   inner join school_prveviousay spay
                              on ds.school_dw_id = spay.school_dw_id
                                  and
                                 trunc(tl.login_local_date_time) between spay.previous_academic_year_start_date and spay.previous_academic_year_end_date),
     holidays_dimension AS (SELECT DISTINCT CAST(holiday_date AS DATE) AS holiday_date,
                                            holiday_organisation_dw_id
                            FROM alefdw.dim_holiday)

SELECT DISTINCT local_date,
                tenant_name,
                tt.school_dw_id,
                school_name,
                school_created_time,
                school_alias                                            AS adek_id,
                tt.school_city_name,
                tt.school_organisation,
                tt.school_country_name,
                tt.school_composition,
                tt.school_id,
                school_label,
                available_teacher_dw_id,
                case when pay_t.teacher_dw_id is null then 0 else 1 end as repeat_teacher_previous_ay,
                active_teacher_dw_id,
                tt.teacher_id,
                tt.teacher_first_created_date,
                tob.teacher_first_login_date,
                teacher_last_login_date,
                tt.teacher_current_status,
                date_part(year, tt.academic_year_start_date) || '-' ||
                date_part(year, tt.academic_year_end_date)              AS academic_year,
                tt.academic_year_start_date,
                tt.academic_year_end_date,
                CASE WHEN holiday_date IS NULL THEN FALSE ELSE TRUE END AS holiday_flag,
                tt.school_cx_cluster
FROM total_teachers tt
         LEFT JOIN active_teachers at
                   ON tt.school_dw_id = at.school_dw_id
                       AND tt.local_date = at.login_date
                       AND tt.available_teacher_dw_id = at.active_teacher_dw_id
         LEFT JOIN teacher_onboarding tob
                   ON tt.available_teacher_dw_id = tob.teacher_dw_id
                       AND tt.school_dw_id = tob.school_dw_id
         LEFT JOIN teacher_onboarding_pay pay_t
                   on tt.available_teacher_dw_id = pay_t.teacher_dw_id
         LEFT JOIN holidays_dimension dh
                   ON dh.holiday_date = tt.local_date AND
                      dh.holiday_organisation_dw_id = tt.organisation_dw_id
WITH NO SCHEMA BINDING;
