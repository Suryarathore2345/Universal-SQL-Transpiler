CREATE OR REPLACE MATERIALIZED LAKE VIEW {{os_bi_coredw}}.teacher_activity_py_mv
AS
SELECT DISTINCT
    login_date_dw_id,
    teacher_dw_id,
    conjugated_data.tenant_dw_id,
    school_dw_id,
    TRUE                                                                        AS outside_school_flag,
    CAST(MIN(local_login_time) AS TIMESTAMP)                                    AS login_local_date_time,
    CAST(MIN(utc_login_time) AS TIMESTAMP)                                      AS login_date_time
FROM (
    /* ----------------------------------------------------
       Source 1: Teacher Activities
    ---------------------------------------------------- */
    SELECT DISTINCT
        fta.fta_date_dw_id                                                      AS login_date_dw_id,
        fta.fta_teacher_dw_id                                                   AS teacher_dw_id,
        fta.fta_tenant_dw_id                                                    AS tenant_dw_id,
        fta.fta_school_dw_id                                                    AS school_dw_id,

        cast(to_date(from_utc_timestamp(
            fta.fta_start_time,
            coalesce(dt.tenant_timezone, 'UTC')
        )) AS DATE)                                                              AS local_login_date,

        MIN(from_utc_timestamp(
            fta.fta_start_time,
            coalesce(dt.tenant_timezone, 'UTC')
        ))                                                                      AS local_login_time,

        MIN(cast(fta.fta_start_time AS TIMESTAMP))                              AS utc_login_time

    FROM {{rs_coredw}}.fact_teacher_activities fta
    INNER JOIN {{rs_coredw}}.dim_school ds
        ON fta.fta_school_dw_id = ds.school_dw_id
    INNER JOIN {{rs_coredw}}.dim_tenant dt
        ON fta.fta_tenant_dw_id = dt.tenant_dw_id
    GROUP BY
        fta.fta_date_dw_id,
        fta.fta_teacher_dw_id,
        fta.fta_tenant_dw_id,
        fta.fta_school_dw_id,
        cast(to_date(from_utc_timestamp(
            fta.fta_start_time,
            coalesce(dt.tenant_timezone, 'UTC')
        )) AS DATE)

    UNION ALL

    /* ----------------------------------------------------
       Source 2: User Login (Teachers)
    ---------------------------------------------------- */
    SELECT
        ful.ful_date_dw_id                                                      AS login_date_dw_id,
        ful.ful_user_dw_id                                                      AS teacher_dw_id,
        ful.ful_tenant_dw_id                                                    AS tenant_dw_id,
        ful.ful_school_dw_id                                                    AS school_dw_id,

        cast(to_date(from_utc_timestamp(
            ful.ful_created_time,
            coalesce(dt.tenant_timezone, 'UTC')
        )) AS DATE)                                                              AS local_login_date,

        MIN(from_utc_timestamp(
            ful.ful_created_time,
            coalesce(dt.tenant_timezone, 'UTC')
        ))                                                                      AS local_login_time,

        MIN(cast(ful.ful_created_time AS TIMESTAMP))                            AS utc_login_time

    FROM {{rs_coredw}}.fact_user_login ful
    INNER JOIN {{rs_coredw}}.dim_school ds
        ON ful.ful_school_dw_id = ds.school_dw_id
    INNER JOIN {{rs_coredw}}.dim_tenant dt
        ON ds.school_tenant_id = dt.tenant_id
    WHERE ful.ful_role_dw_id = 1
    GROUP BY
        ful.ful_date_dw_id,
        ful.ful_user_dw_id,
        ful.ful_tenant_dw_id,
        ful.ful_school_dw_id,
        cast(to_date(from_utc_timestamp(
            ful.ful_created_time,
            coalesce(dt.tenant_timezone, 'UTC')
        )) AS DATE)

    UNION ALL

    /* ----------------------------------------------------
       Source 3: Heartbeat (Teachers)
    ---------------------------------------------------- */
    SELECT
        hbt.fuhha_date_dw_id                                                    AS login_date_dw_id,
        hbt.fuhha_user_dw_id                                                    AS teacher_dw_id,
        hbt.fuhha_tenant_dw_id                                                  AS tenant_dw_id,
        hbt.fuhha_school_dw_id                                                  AS school_dw_id,

        cast(to_date(from_utc_timestamp(
            hbt.fuhha_created_time,
            coalesce(dt.tenant_timezone, 'UTC')
        )) AS DATE)                                                              AS local_login_date,

        MIN(from_utc_timestamp(
            hbt.fuhha_created_time,
            coalesce(dt.tenant_timezone, 'UTC')
        ))                                                                      AS local_login_time,

        MIN(cast(hbt.fuhha_created_time AS TIMESTAMP))                          AS utc_login_time

    FROM {{rs_coredw}}.fact_user_heartbeat_hourly_aggregated hbt
    INNER JOIN {{rs_coredw}}.dim_school ds
        ON hbt.fuhha_school_dw_id = ds.school_dw_id
    INNER JOIN {{rs_coredw}}.dim_tenant dt
        ON ds.school_tenant_id = dt.tenant_id
    WHERE hbt.fuhha_role_dw_id = 1
    GROUP BY
        hbt.fuhha_date_dw_id,
        hbt.fuhha_user_dw_id,
        hbt.fuhha_tenant_dw_id,
        hbt.fuhha_school_dw_id,
        cast(to_date(from_utc_timestamp(
            hbt.fuhha_created_time,
            coalesce(dt.tenant_timezone, 'UTC')
        )) AS DATE)

) conjugated_data
INNER JOIN {{rs_coredw}}.dim_tenant dt
    ON conjugated_data.tenant_dw_id = dt.tenant_dw_id
GROUP BY
    login_date_dw_id,
    teacher_dw_id,
    conjugated_data.tenant_dw_id,
    school_dw_id,
    local_login_date; 