CREATE OR REPLACE MATERIALIZED LAKE VIEW {{os_bi_coredw}}.student_activity_py_mv
AS
SELECT DISTINCT
    login_date_dw_id,
    student_dw_id,
    conjugated_data.tenant_dw_id,
    school_dw_id,
    TRUE                                                                        AS outside_school_flag,
    MIN(local_login_time)                                                       AS login_local_date_time,
    to_utc_timestamp(MIN(local_login_time), dt.tenant_timezone)                 AS login_date_time
FROM (
    -- Source 1: Student Activities
    SELECT DISTINCT
        fsa.fsta_date_dw_id                                                     AS login_date_dw_id,
        fsa.fsta_student_dw_id                                                  AS student_dw_id,
        fsa.fsta_tenant_dw_id                                                   AS tenant_dw_id,
        fsa.fsta_school_dw_id                                                   AS school_dw_id,
        to_date(
            MIN(from_utc_timestamp(fsa.fsta_start_time, dt.tenant_timezone))
        )                                                                       AS local_login_date,
        MIN(from_utc_timestamp(fsa.fsta_start_time, dt.tenant_timezone))        AS local_login_time
    FROM {{rs_coredw}}.fact_student_activities fsa
    INNER JOIN {{rs_coredw}}.dim_school ds
        ON fsa.fsta_school_dw_id = ds.school_dw_id
    INNER JOIN {{rs_coredw}}.dim_tenant dt
        ON fsa.fsta_tenant_dw_id = dt.tenant_dw_id
    GROUP BY
        fsa.fsta_date_dw_id,
        fsa.fsta_student_dw_id,
        fsa.fsta_tenant_dw_id,
        fsa.fsta_school_dw_id,
        ds.school_timezone,
        dt.tenant_timezone,
        to_date(from_utc_timestamp(fsa.fsta_start_time, dt.tenant_timezone))

    UNION

    -- Source 2: User Login
    SELECT DISTINCT
        ful.ful_date_dw_id                                                      AS login_date_dw_id,
        ful.ful_user_dw_id                                                      AS student_dw_id,
        ful.ful_tenant_dw_id                                                    AS tenant_dw_id,
        ful.ful_school_dw_id                                                    AS school_dw_id,
        to_date(
            MIN(from_utc_timestamp(ful.ful_created_time, dt.tenant_timezone))
        )                                                                       AS local_login_date,
        MIN(from_utc_timestamp(ful.ful_created_time, dt.tenant_timezone))       AS local_login_time
    FROM {{rs_coredw}}.fact_user_login ful
    INNER JOIN {{rs_coredw}}.dim_school ds
        ON ful.ful_school_dw_id = ds.school_dw_id
    INNER JOIN {{rs_coredw}}.dim_tenant dt
        ON ds.school_tenant_id = dt.tenant_id
    WHERE ful.ful_role_dw_id = 2
    GROUP BY
        ful.ful_date_dw_id,
        ful.ful_user_dw_id,
        ful.ful_tenant_dw_id,
        ful.ful_school_dw_id,
        ds.school_timezone,
        dt.tenant_timezone,
        to_date(from_utc_timestamp(ful.ful_created_time, dt.tenant_timezone))

    UNION

    -- Source 3: Heartbeat
    SELECT DISTINCT
        hbt.fuhha_date_dw_id                                                    AS login_date_dw_id,
        hbt.fuhha_user_dw_id                                                    AS student_dw_id,
        hbt.fuhha_tenant_dw_id                                                  AS tenant_dw_id,
        hbt.fuhha_school_dw_id                                                  AS school_dw_id,
        to_date(
            from_utc_timestamp(hbt.fuhha_created_time, dt.tenant_timezone)
        )                                                                       AS local_login_date,
        MIN(from_utc_timestamp(hbt.fuhha_created_time, dt.tenant_timezone))     AS local_login_time
    FROM {{rs_coredw}}.fact_user_heartbeat_hourly_aggregated hbt
    INNER JOIN {{rs_coredw}}.dim_school ds
        ON hbt.fuhha_school_dw_id = ds.school_dw_id
    INNER JOIN {{rs_coredw}}.dim_tenant dt
        ON ds.school_tenant_id = dt.tenant_id
    WHERE hbt.fuhha_role_dw_id = 2
    GROUP BY
        hbt.fuhha_date_dw_id,
        hbt.fuhha_user_dw_id,
        hbt.fuhha_tenant_dw_id,
        hbt.fuhha_school_dw_id,
        dt.tenant_timezone,
        to_date(from_utc_timestamp(hbt.fuhha_created_time, dt.tenant_timezone))

) conjugated_data
INNER JOIN {{rs_coredw}}.dim_tenant dt
    ON conjugated_data.tenant_dw_id = dt.tenant_dw_id
GROUP BY
    login_date_dw_id,
    student_dw_id,
    conjugated_data.tenant_dw_id,
    school_dw_id,
    outside_school_flag,
    local_login_date,
    dt.tenant_timezone; 