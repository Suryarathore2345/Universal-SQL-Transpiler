CREATE OR REPLACE VIEW bi_alefdw_dev.principal_login_activity_ay_view as
WITH total_principals as (SELECT DISTINCT ds.*,
                                          full_date                                                     AS local_date,
                                          dp.staff_user_dw_id                                                AS available_principal_dw_id,
                                          dp.staff_user_id                                                   as principal_id,
                                          first_value(
                                          trunc(staff_user_created_time))
                                          OVER (
                                              PARTITION BY dp.staff_user_dw_id
                                              ORDER BY staff_user_created_time
                                              ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS principal_first_created_date,
                                          first_value(staff_user_status)
                                          OVER (PARTITION BY dp.staff_user_dw_id
                                              ORDER BY staff_user_created_time DESC
                                              ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS principal_current_status
                          FROM bi_alefdw.bi_active_schools_dim_mv ds
                                   CROSS JOIN (SELECT distinct full_date
                                               FROM alefdw.dim_date dt
                                               WHERE dt.full_date between '2024-07-10' and trunc(sysdate)) date_dateset
                                   INNER JOIN alefdw.dim_staff_user_school_role_association dsusra
                                              on dsusra.susra_school_dw_id = ds.school_dw_id
                                                  AND dsusra.susra_status = 1
                                   INNER JOIN alefdw.dim_staff_user dp
                                              ON dp.staff_user_dw_id = dsusra.susra_staff_dw_id
                                                  AND (((staff_user_status = 2 AND staff_user_enabled is TRUE)
                                                      AND full_date >= trunc(convert_timezone('UTC', ds.tenant_timezone, staff_user_created_time))
                                                      AND full_date < trunc(convert_timezone('UTC', ds.tenant_timezone, staff_user_active_until)))
                                                      OR (staff_user_status = 1 AND staff_user_enabled is TRUE))
                          where dsusra.susra_role_dw_id = 6
                          AND (full_date >= ds.academic_year_start_date AND full_date <= ds.academic_year_end_date)
                          ),
     active_principals AS (SELECT DISTINCT login_date,
                                           school_dw_id,
                                           active_principal_dw_id
                           FROM (SELECT DISTINCT trunc(login_local_date_time) as login_date,
                                                 pl.school_dw_id,
                                                 pl.principal_dw_id           AS active_principal_dw_id
                                 FROM bi_alefdw.principal_login pl
                                          INNER JOIN bi_alefdw.bi_active_schools_dim_mv ds
                                                     ON pl.school_dw_id = ds.school_dw_id
                                          INNER JOIN alefdw.dim_staff_user_school_role_association dsusra
                                              on dsusra.susra_school_dw_id = ds.school_dw_id
                                                  AND dsusra.susra_status = 1
                                          INNER JOIN alefdw.dim_staff_user dp1
                                              ON dp1.staff_user_dw_id = dsusra.susra_staff_dw_id
                                                  AND dsusra.susra_school_dw_id = pl.school_dw_id
                                                  AND (((staff_user_status = 2 AND staff_user_enabled is TRUE)
                                                      AND trunc(login_local_date_time) >= trunc(convert_timezone('UTC', ds.tenant_timezone, staff_user_created_time))
                                                      AND trunc(login_local_date_time) < trunc(convert_timezone('UTC', ds.tenant_timezone, staff_user_active_until)))
                                                      OR (staff_user_status = 1 AND staff_user_enabled is TRUE))
                                 WHERE Trunc(login_local_date_time) between '2024-07-10' and trunc(sysdate)) prin_dateset),
     principal_onboarding as (SELECT DISTINCT principal_dw_id,
                                              ds.school_dw_id,
                                              first_value(login_local_date_time)
                                              OVER (
                                                  PARTITION BY tl.principal_dw_id, ds.school_dw_id
                                                  ORDER BY tl.login_local_date_time
                                                  ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS principal_first_login_date,
                                              first_value(login_local_date_time)
                                              OVER (
                                                  PARTITION BY tl.principal_dw_id, ds.school_dw_id
                                                  ORDER BY tl.login_local_date_time DESC
                                                  ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS principal_last_login_date
                              FROM bi_alefdw.principal_login tl
                                       INNER JOIN bi_alefdw.bi_active_schools_dim_mv ds
                                                  ON ds.school_dw_id = tl.school_dw_id
                                                  AND trunc(login_local_date_time) >= ds.academic_year_start_date
                              ),
     holidays_dimension as
         (SELECT DISTINCT cast(holiday_date AS date) AS holiday_date,
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
                available_principal_dw_id,
                active_principal_dw_id,
                tt.principal_id,
                tt.principal_first_created_date,
                tob.principal_first_login_date,
                principal_last_login_date,
                tt.principal_current_status,
                date_part(year, tt.academic_year_start_date) || '-' ||
                date_part(year, tt.academic_year_end_date)              AS academic_year,
                tt.academic_year_start_date,
                tt.academic_year_end_date,
                case when holiday_date is null then FALSE ELSE TRUE END as holiday_flag
FROM total_principals tt
         LEFT JOIN active_principals at
                   ON tt.school_dw_id = at.school_dw_id
                       AND tt.local_date = at.login_date
                       AND tt.available_principal_dw_id = at.active_principal_dw_id
         LEFT JOIN principal_onboarding tob
                   ON tt.available_principal_dw_id = tob.principal_dw_id
                       AND tt.school_dw_id = tob.school_dw_id
         LEFT JOIN holidays_dimension dh
                   on dh.holiday_date = tt.local_date and holiday_organisation_dw_id = tt.organisation_dw_id
WITH NO SCHEMA BINDING;