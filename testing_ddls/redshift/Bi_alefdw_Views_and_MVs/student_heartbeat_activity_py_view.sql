CREATE OR REPLACE VIEW bi_alefdw_dev.student_heartbeat_activity_py_view AS
SELECT DISTINCT to_char(min(convert_timezone('UTC', dt.tenant_timezone, ful.fuhha_created_time)),
                        'YYYYMMDD')                                                           AS login_date_dw_id,
                ful.fuhha_user_dw_id                                                          AS student_dw_id,
                ful.fuhha_tenant_dw_id                                                        AS tenant_dw_id,
                ful.fuhha_school_dw_id                                                        AS school_dw_id,
                TRUNC(MIN(
                        CONVERT_TIMEZONE('UTC', dt.tenant_timezone, ful.fuhha_created_time))) AS login_local_date,
                MIN(CONVERT_TIMEZONE('UTC', dt.tenant_timezone, ful.fuhha_created_time))      AS login_local_date_time
FROM alefdw.fact_user_heartbeat_hourly_aggregated ful
         JOIN alefdw.dim_school ds
              ON ful.fuhha_school_dw_id = ds.school_dw_id
         JOIN alefdw.dim_tenant dt
              ON ds.school_tenant_id = dt.tenant_id
WHERE ful.fuhha_role_dw_id = 2
GROUP BY ful.fuhha_user_dw_id,
         ful.fuhha_tenant_dw_id,
         ful.fuhha_school_dw_id,
         ds.school_timezone,
         dt.tenant_timezone,
         TRUNC(CONVERT_TIMEZONE('UTC', dt.tenant_timezone, ful.fuhha_created_time))
WITH NO SCHEMA BINDING;