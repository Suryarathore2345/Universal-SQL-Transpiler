CREATE OR ALTER VIEW ${os_bi_coredw}.teacher_heartbeat_activity_py_view AS
SELECT DISTINCT
    FORMAT(
        MIN(
            ful.fuhha_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
        ),
        'yyyyMMdd'
    ) AS login_date_dw_id,

    ful.fuhha_user_dw_id   AS teacher_dw_id,
    ful.fuhha_tenant_dw_id AS tenant_dw_id,
    ful.fuhha_school_dw_id AS school_dw_id,

    CONVERT(
        DATE,
        MIN(
            ful.fuhha_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
        )
    ) AS login_local_date,

    CONVERT(
        DATETIME2,
        MIN(
            ful.fuhha_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
)
    ) AS login_local_date_time

FROM ${rs_coredw}.fact_user_heartbeat_hourly_aggregated ful

JOIN ${rs_coredw}.dim_school ds
    ON ful.fuhha_school_dw_id = ds.school_dw_id

JOIN ${rs_coredw}.dim_tenant dt
    ON ds.school_tenant_id = dt.tenant_id

WHERE ful.fuhha_role_dw_id = 1

GROUP BY
    ful.fuhha_user_dw_id,
    ful.fuhha_tenant_dw_id,
    ful.fuhha_school_dw_id,
    ds.school_windows_timezone,
    dt.windows_timezone,
    CONVERT(
        DATE,
        ful.fuhha_created_time
            AT TIME ZONE 'UTC'
            AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
);
