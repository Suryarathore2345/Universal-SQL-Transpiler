CREATE OR ALTER VIEW ${os_bi_coredw}.teacher_activity_py_view AS
SELECT DISTINCT
    login_date_dw_id,
    teacher_dw_id,
    conjugated_data.tenant_dw_id,
    school_dw_id,
    CONVERT(BIT, 1) AS outside_school_flag,
    CONVERT(DATETIME2, MIN(local_login_time)) AS login_local_date_time,
    CONVERT(DATETIME2, MIN(utc_login_time)) AS login_date_time
FROM (
    /* ----------------------------------------------------
       Teacher activity (fact_teacher_activities)
    ---------------------------------------------------- */
    SELECT DISTINCT
        fta.fta_date_dw_id        AS login_date_dw_id,
        fta.fta_teacher_dw_id     AS teacher_dw_id,
        fta.fta_tenant_dw_id      AS tenant_dw_id,
        fta.fta_school_dw_id      AS school_dw_id,

        CONVERT(
            DATE,
            MIN(
                CONVERT(DATETIME2, fta.fta_start_time)
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
            )
        ) AS local_login_date,

        MIN(
            CONVERT(DATETIME2, fta.fta_start_time)
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
        ) AS local_login_time,

        MIN(
            CONVERT(DATETIME2, fta.fta_start_time)
                AT TIME ZONE 'UTC'
        ) AS utc_login_time

    FROM ${rs_coredw}.fact_teacher_activities fta
    JOIN ${rs_coredw}.dim_school ds
        ON fta.fta_school_dw_id = ds.school_dw_id
    JOIN ${rs_coredw}.dim_tenant dt
        ON fta.fta_tenant_dw_id = dt.tenant_dw_id

    GROUP BY
        fta.fta_date_dw_id,
        fta.fta_teacher_dw_id,
        fta.fta_tenant_dw_id,
        fta.fta_school_dw_id,
        CONVERT(
            DATE,
            CONVERT(DATETIME2, fta.fta_start_time)
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
        )

    UNION ALL

    /* ----------------------------------------------------
       Teacher login (fact_user_login)
    ---------------------------------------------------- */
    SELECT
        ful.ful_date_dw_id        AS login_date_dw_id,
        ful.ful_user_dw_id        AS teacher_dw_id,
        ful.ful_tenant_dw_id      AS tenant_dw_id,
        ful.ful_school_dw_id      AS school_dw_id,

        CONVERT(
            DATE,
            MIN(
                CONVERT(DATETIME2, ful.ful_created_time)
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
            )
        ) AS local_login_date,

        MIN(
            CONVERT(DATETIME2, ful.ful_created_time)
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
        ) AS local_login_time,

        MIN(
            CONVERT(DATETIME2, ful.ful_created_time)
                AT TIME ZONE 'UTC'
        ) AS utc_login_time

    FROM ${rs_coredw}.fact_user_login ful
    JOIN ${rs_coredw}.dim_school ds
        ON ful.ful_school_dw_id = ds.school_dw_id
    JOIN ${rs_coredw}.dim_tenant dt
        ON ds.school_tenant_id = dt.tenant_id

    WHERE ful.ful_role_dw_id = 1
    GROUP BY
        ful.ful_date_dw_id,
        ful.ful_user_dw_id,
        ful.ful_tenant_dw_id,
        ful.ful_school_dw_id,
        CONVERT(
            DATE,
            CONVERT(DATETIME2, ful.ful_created_time)
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
        )

    UNION ALL

    /* ----------------------------------------------------
       Teacher heartbeat
    ---------------------------------------------------- */
    SELECT
        hbt.fuhha_date_dw_id      AS login_date_dw_id,
        hbt.fuhha_user_dw_id      AS teacher_dw_id,
        hbt.fuhha_tenant_dw_id    AS tenant_dw_id,
        hbt.fuhha_school_dw_id    AS school_dw_id,

        CONVERT(
            DATE,
            CONVERT(DATETIME2, hbt.fuhha_created_time)
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
        ) AS local_login_date,

        MIN(
            CONVERT(DATETIME2, hbt.fuhha_created_time)
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
        ) AS local_login_time,

        MIN(
            CONVERT(DATETIME2, hbt.fuhha_created_time)
                AT TIME ZONE 'UTC'
        ) AS utc_login_time

    FROM ${rs_coredw}.fact_user_heartbeat_hourly_aggregated hbt
    JOIN ${rs_coredw}.dim_school ds
        ON hbt.fuhha_school_dw_id = ds.school_dw_id
    JOIN ${rs_coredw}.dim_tenant dt
        ON ds.school_tenant_id = dt.tenant_id

    WHERE hbt.fuhha_role_dw_id = 1
    GROUP BY
        hbt.fuhha_date_dw_id,
        hbt.fuhha_user_dw_id,
        hbt.fuhha_tenant_dw_id,
        hbt.fuhha_school_dw_id,
        CONVERT(
            DATE,
            CONVERT(DATETIME2, hbt.fuhha_created_time)
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
        )
) conjugated_data
join ${rs_coredw}.dim_tenant dt
              on conjugated_Data.tenant_dw_id = dt.tenant_dw_id
GROUP BY
    login_date_dw_id,
    teacher_dw_id,
    conjugated_Data.tenant_dw_id,
    school_dw_id,
    local_login_date;
