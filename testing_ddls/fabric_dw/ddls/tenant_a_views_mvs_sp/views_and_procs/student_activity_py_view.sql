CREATE OR ALTER VIEW ${os_bi_coredw}.student_activity_py_view
AS
SELECT DISTINCT
    login_date_dw_id,
    student_dw_id,
    conjugated_Data.tenant_dw_id,
    school_dw_id,
    CAST(1 AS BIT) AS outside_school_flag,
    CAST(MIN(local_login_time) AS DATETIME2) AS login_local_date_time,
    CAST(
        (
            MIN(local_login_time)
                AT TIME ZONE COALESCE(tz.windows_timezone, 'UTC')
                AT TIME ZONE 'UTC'
        ) AS DATETIME2
    ) AS login_date_time

FROM (
    SELECT DISTINCT
        fsa.fsta_date_dw_id    AS login_date_dw_id,
        fsa.fsta_student_dw_id AS student_dw_id,
        fsa.fsta_tenant_dw_id  AS tenant_dw_id,
        fsa.fsta_school_dw_id  AS school_dw_id,

        CAST(
            MIN(
                fsa.fsta_start_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE COALESCE(tz.windows_timezone, 'UTC')
            ) AS DATE
        ) AS local_login_date,

        CAST(
            MIN(
                fsa.fsta_start_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE COALESCE(tz.windows_timezone, 'UTC')
            ) AS DATETIME2
        ) AS local_login_time

    FROM ${rs_coredw}.fact_student_activities fsa
    JOIN ${rs_coredw}.dim_school ds
        ON fsa.fsta_school_dw_id = ds.school_dw_id
    JOIN ${rs_coredw}.dim_tenant dt
        ON fsa.fsta_tenant_dw_id = dt.tenant_dw_id
    LEFT JOIN ${rs_bi_coredw}.timezone_mapping tz
        ON tz.iana_timezone = dt.tenant_timezone
    GROUP BY
        fsa.fsta_date_dw_id,
        fsa.fsta_student_dw_id,
        fsa.fsta_tenant_dw_id,
        fsa.fsta_school_dw_id,
        ds.school_timezone,
        dt.tenant_timezone,
        CAST(
            fsa.fsta_start_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE COALESCE(tz.windows_timezone, 'UTC')
            AS DATE
        )

    UNION
    SELECT DISTINCT
        ful.ful_date_dw_id    AS login_date_dw_id,
        ful.ful_user_dw_id    AS student_dw_id,
        ful.ful_tenant_dw_id  AS tenant_dw_id,
        ful.ful_school_dw_id  AS school_dw_id,

        CAST(
            MIN(
                ful.ful_created_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE COALESCE(tz.windows_timezone, 'UTC')
            ) AS DATE
        ) AS local_login_date,

        CAST(
            MIN(
                ful.ful_created_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE COALESCE(tz.windows_timezone, 'UTC')
            ) AS DATETIME2
        ) AS local_login_time

    FROM ${rs_coredw}.fact_user_login ful
    JOIN ${rs_coredw}.dim_school ds
        ON ful.ful_school_dw_id = ds.school_dw_id
    JOIN ${rs_coredw}.dim_tenant dt
        ON ds.school_tenant_id = dt.tenant_id
    LEFT JOIN ${rs_bi_coredw}.timezone_mapping tz
        ON tz.iana_timezone = dt.tenant_timezone
    WHERE ful.ful_role_dw_id = 2
    GROUP BY
        ful.ful_date_dw_id,
        ful.ful_user_dw_id,
        ful.ful_tenant_dw_id,
        ful.ful_school_dw_id,
        ds.school_timezone,
        dt.tenant_timezone,
        CAST(
            ful.ful_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE COALESCE(tz.windows_timezone, 'UTC')
            AS DATE
        )

    UNION
    SELECT DISTINCT
        hbt.fuhha_date_dw_id    AS login_date_dw_id,
        hbt.fuhha_user_dw_id    AS student_dw_id,
        hbt.fuhha_tenant_dw_id  AS tenant_dw_id,
        hbt.fuhha_school_dw_id  AS school_dw_id,

        CAST(
            MIN(
                hbt.fuhha_created_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE COALESCE(tz.windows_timezone, 'UTC')
            ) AS DATE
        ) AS local_login_date,

        CAST(
            MIN(
                hbt.fuhha_created_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE COALESCE(tz.windows_timezone, 'UTC')
            ) AS DATETIME2
        ) AS local_login_time

    FROM ${rs_coredw}.fact_user_heartbeat_hourly_aggregated hbt
    JOIN ${rs_coredw}.dim_school ds
        ON hbt.fuhha_school_dw_id = ds.school_dw_id
    JOIN ${rs_coredw}.dim_tenant dt
        ON ds.school_tenant_id = dt.tenant_id
    LEFT JOIN ${rs_bi_coredw}.timezone_mapping tz
        ON tz.iana_timezone = dt.tenant_timezone
    WHERE fuhha_role_dw_id = 2
    GROUP BY
        hbt.fuhha_date_dw_id,
        hbt.fuhha_user_dw_id,
        hbt.fuhha_tenant_dw_id,
        hbt.fuhha_school_dw_id,
        ds.school_timezone,
        dt.tenant_timezone,
        CAST(
            hbt.fuhha_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE COALESCE(tz.windows_timezone, 'UTC')
            AS DATE
        )
) conjugated_Data
JOIN ${rs_coredw}.dim_tenant dt
    ON conjugated_Data.tenant_dw_id = dt.tenant_dw_id
LEFT JOIN ${rs_bi_coredw}.timezone_mapping tz
    ON tz.iana_timezone = dt.tenant_timezone
GROUP BY
    login_date_dw_id,
    student_dw_id,
    conjugated_Data.tenant_dw_id,
    school_dw_id,
    local_login_date,
    dt.tenant_timezone,
    tz.windows_timezone;