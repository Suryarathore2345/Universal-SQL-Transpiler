CREATE OR REPLACE VIEW bi_alefdw_dev.teacher_activity_rolling_period_view AS
WITH active_teacher_period AS (SELECT tl.teacher_dw_id,
                                      tl.school_dw_id,
                                      count(DISTINCT CASE
                                                         WHEN trunc(tl.login_local_date_time) BETWEEN trunc(sysdate) - 7
                                                             AND trunc(sysdate) - 1
                                                             THEN trunc(tl.login_local_date_time)
                                          END) AS active_days_last7d,
                                      count(DISTINCT CASE
                                                         WHEN trunc(tl.login_local_date_time) BETWEEN trunc(sysdate) - 14
                                                             AND trunc(sysdate) - 8
                                                             THEN trunc(tl.login_local_date_time)
                                          END) AS active_days_prev7d,
                                      count(DISTINCT CASE
                                                         WHEN trunc(tl.login_local_date_time) BETWEEN trunc(sysdate) - 30
                                                             AND trunc(sysdate) - 1
                                                             THEN trunc(tl.login_local_date_time)
                                          END) AS active_days_last30d,
                                      count(DISTINCT CASE
                                                         WHEN trunc(tl.login_local_date_time) BETWEEN trunc(sysdate) - 60
                                                             AND trunc(sysdate) - 31
                                                             THEN trunc(tl.login_local_date_time)
                                          END) AS active_days_prev30d
                               FROM bi_alefdw.teacher_login tl
                               GROUP BY 1, 2),

     teacher_onboarding AS
         (SELECT DISTINCT tl.teacher_dw_id,
                          tl.school_dw_id,
                          first_value(login_local_date_time) OVER (
                              PARTITION BY tl.teacher_dw_id, tl.school_dw_id ORDER BY tl.login_local_date_time ASC
                              rows BETWEEN unbounded preceding AND unbounded following
                              ) AS teacher_first_login_date,
                          first_value(login_local_date_time) OVER (
                              PARTITION BY tl.teacher_dw_id, tl.school_dw_id ORDER BY tl.login_local_date_time DESC
                              rows BETWEEN unbounded preceding AND unbounded following
                              ) AS teacher_last_login_date
          FROM bi_alefdw.teacher_login tl
                   INNER JOIN bi_alefdw.bi_active_schools_dim_mv ds
                       ON ds.school_dw_id = tl.school_dw_id
                        AND trunc(login_local_date_time) >= ds.academic_year_start_date)

SELECT DISTINCT dsc.tenant_name,
                dsc.school_dw_id,
                dsc.school_id,
                dsc.school_name,
                dsc.school_alias                                              AS adek_id,
                dsc.school_city_name,
                dsc.school_organisation,
                dsc.organisation_dw_id,
                dt.teacher_dw_id,
                dt.teacher_id,
                first_value(trunc(dt.teacher_created_time)) OVER
                    (PARTITION BY dt.teacher_dw_id ORDER BY dt.teacher_created_time
                    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS teacher_first_created_date,
                ton.teacher_first_login_date,
                ton.teacher_last_login_date,
                date_part(year, dsc.academic_year_start_date) || '-' ||
                date_part(year, dsc.academic_year_end_date)                    AS academic_year,
                nvl(atp.active_days_last7d, 0)                                as active_days_last7d,
                nvl(atp.active_days_prev7d, 0)                                as active_days_prev7d,
                nvl(atp.active_days_last30d, 0)                               as active_days_last30d,
                nvl(atp.active_days_prev30d, 0)                               as active_days_prev30d
FROM alefdw.dim_teacher dt
         INNER JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                    ON dsc.school_dw_id = dt.teacher_school_dw_id
         LEFT JOIN active_teacher_period atp
                   ON atp.teacher_dw_id = dt.teacher_dw_id
                       AND atp.school_dw_id = dt.teacher_school_dw_id
         LEFT JOIN teacher_onboarding ton
                   ON ton.teacher_dw_id = dt.teacher_dw_id
                       AND ton.school_dw_id = dt.teacher_school_dw_id
WHERE dt.teacher_status = 1
WITH NO SCHEMA BINDING;