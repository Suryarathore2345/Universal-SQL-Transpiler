CREATE OR ALTER VIEW ${os_bi_coredw}.principal_activity_bw_py_view AS
SELECT
    cd.login_date_dw_id,
    cd.principal_dw_id,
    cd.tenant_dw_id,
    cd.school_dw_id,
    cd.outside_school_flag,
    MIN(cd.local_login_time) AS login_local_date_time,
    CONVERT(
        DATETIME2,
        MIN(cd.local_login_time)
            AT TIME ZONE ISNULL(cd.windows_timezone, 'UTC')
            AT TIME ZONE 'UTC'
    ) AS login_date_time
FROM (
    SELECT DISTINCT
        ful.ful_date_dw_id          AS login_date_dw_id,
        ful.ful_user_dw_id          AS principal_dw_id,
        ful.ful_tenant_dw_id        AS tenant_dw_id,
        ful.ful_school_dw_id        AS school_dw_id,
        ful.ful_outside_of_school   AS outside_school_flag,

        CONVERT(
            DATE,
            MIN(
                (
                    ful.ful_created_time
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(windows_timezone, 'UTC')
                )
            )
        ) AS local_login_date,

        MIN(
            CONVERT(
                DATETIME2,
                ful.ful_created_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
            )
        ) AS local_login_time,

        dt.windows_timezone
    FROM ${rs_coredw}.fact_user_login ful
    JOIN ${rs_coredw}.dim_school ds
        ON ful.ful_school_dw_id = ds.school_dw_id
    JOIN ${rs_coredw}.dim_tenant dt
        ON ds.school_tenant_id = dt.tenant_id

    WHERE ful.ful_role_dw_id = 6
      AND CONVERT(DATE, ful.ful_dw_created_time)
          BETWEEN CONVERT(DATE, DATEADD(DAY, -15, GETDATE()))
              AND CONVERT(DATE, GETDATE())
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
            (
                ful.ful_created_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
            )
        )
) AS cd
GROUP BY
    cd.login_date_dw_id,
    cd.principal_dw_id,
    cd.tenant_dw_id,
    cd.school_dw_id,
    cd.outside_school_flag,
    cd.local_login_date,
    cd.windows_timezone;
