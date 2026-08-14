CREATE OR ALTER VIEW ${os_bi_coredw}.principal_activity_py_view
AS
SELECT DISTINCT
    login_date_dw_id,
    principal_dw_id,
    tenant_dw_id,
    school_dw_id,
    outside_school_flag,
    CONVERT(DATETIME2, MIN(local_login_time)) AS login_local_date_time,

    CONVERT(
        DATETIME2,
        MIN(local_login_time)
            AT TIME ZONE ISNULL(windows_timezone, 'UTC')
            AT TIME ZONE 'UTC'
    ) AS login_date_time

FROM (
    SELECT DISTINCT
        ful.ful_date_dw_id AS login_date_dw_id,
        ful.ful_user_dw_id AS principal_dw_id,
        ful.ful_tenant_dw_id AS tenant_dw_id,
            ful.ful_school_dw_id AS school_dw_id,
        ful.ful_outside_of_school AS outside_school_flag,

        CONVERT(
            DATE,
            MIN(
                ful.ful_created_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
            )
        )                        AS local_login_date,

        CONVERT(
            DATETIME2,
            MIN(
                ful.ful_created_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
            )
        )                        AS local_login_time,

        dt.windows_timezone

    FROM ${rs_coredw}.fact_user_login ful
    JOIN ${rs_coredw}.dim_school ds
        ON ful.ful_school_dw_id = ds.school_dw_id
    JOIN ${rs_coredw}.dim_tenant dt
        ON ds.school_tenant_id = dt.tenant_id
       AND dt.tenant_dw_id = ful.ful_tenant_dw_id
    WHERE ful.ful_role_dw_id = 6
    GROUP BY
        ful.ful_date_dw_id,
        ful.ful_user_dw_id,
        ful.ful_tenant_dw_id,
        ful.ful_school_dw_id,
        ful.ful_outside_of_school,
        ds.school_timezone,
        dt.windows_timezone,
        CONVERT(
            DATE,
            ful.ful_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
        )
) x
GROUP BY
    login_date_dw_id,
    principal_dw_id,
    tenant_dw_id,
    school_dw_id,
    outside_school_flag,
    local_login_date,
    windows_timezone;
