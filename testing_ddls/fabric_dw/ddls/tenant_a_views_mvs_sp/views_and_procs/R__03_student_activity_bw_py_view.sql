CREATE OR ALTER VIEW ${os_bi_coredw}.student_activity_bw_py_view
AS
SELECT DISTINCT
    login_date_dw_id,
    student_dw_id,
    cd.tenant_dw_id,
    school_dw_id,
    CONVERT(BIT, 1) AS outside_school_flag,

    CONVERT(datetime2(6), MIN(local_login_time)) AS login_local_date_time,

    /* local → UTC */
    CONVERT(
        datetime2(6),
        MIN(local_login_time)
            AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
            AT TIME ZONE 'UTC'
    ) AS login_date_time

FROM (
    /* ----------------------------------------------------
       Student activity
    ---------------------------------------------------- */
    SELECT
        fsa.fsta_date_dw_id AS login_date_dw_id,
        fsa.fsta_student_dw_id AS student_dw_id,
        fsa.fsta_tenant_dw_id AS tenant_dw_id,
        fsa.fsta_school_dw_id AS school_dw_id,

        CONVERT(
            DATE,
            MIN(
                fsa.fsta_start_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
            )
        ) AS local_login_date,

        MIN(
            fsa.fsta_start_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
        ) AS local_login_time

    FROM ${rs_coredw}.fact_student_activities fsa
    JOIN ${rs_coredw}.dim_school ds
        ON fsa.fsta_school_dw_id = ds.school_dw_id
    JOIN ${rs_coredw}.dim_tenant dt
        ON fsa.fsta_tenant_dw_id = dt.tenant_dw_id
    WHERE
        CONVERT(DATE, fsa.fsta_dw_created_time)
            BETWEEN DATEADD(DAY, -15, CONVERT(DATE, GETDATE()))
                AND CONVERT(DATE, GETDATE())
    GROUP BY
        fsa.fsta_date_dw_id,
        fsa.fsta_student_dw_id,
        fsa.fsta_tenant_dw_id,
        fsa.fsta_school_dw_id,
        ds.school_timezone,
        dt.windows_timezone,
        CONVERT(
            DATE,
            fsa.fsta_start_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
        )

    UNION

    /* ----------------------------------------------------
       Student login
    ---------------------------------------------------- */
    SELECT
        ful.ful_date_dw_id,
        ful.ful_user_dw_id,
        ful.ful_tenant_dw_id,
        ful.ful_school_dw_id,

        CONVERT(
            DATE,
            MIN(
                ful.ful_created_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
            )
        ),

        MIN(
            ful.ful_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
        )

    FROM ${rs_coredw}.fact_user_login ful
    JOIN ${rs_coredw}.dim_school ds
        ON ful.ful_school_dw_id = ds.school_dw_id
    JOIN ${rs_coredw}.dim_tenant dt
        ON ds.school_tenant_id = dt.tenant_id
    WHERE
        ful.ful_role_dw_id = 2
        AND CONVERT(DATE, ful.ful_dw_created_time)
            BETWEEN DATEADD(DAY, -15, CONVERT(DATE, GETDATE()))
                AND CONVERT(DATE, GETDATE())
    GROUP BY
        ful.ful_date_dw_id,
        ful.ful_user_dw_id,
        ful.ful_tenant_dw_id,
        ful.ful_school_dw_id,
        ds.school_timezone,
        dt.windows_timezone,
        CONVERT(
            DATE,
            ful.ful_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
        )

    UNION

    /* ----------------------------------------------------
       Heartbeat login
    ---------------------------------------------------- */
    SELECT
        hbt.fuhha_date_dw_id,
        hbt.fuhha_user_dw_id,
        hbt.fuhha_tenant_dw_id,
        hbt.fuhha_school_dw_id,

        CONVERT(
            DATE,
            MIN(
                hbt.fuhha_created_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
            )
        ),

        MIN(
            hbt.fuhha_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
        )

    FROM ${rs_coredw}.fact_user_heartbeat_hourly_aggregated hbt
    JOIN ${rs_coredw}.dim_school ds
        ON hbt.fuhha_school_dw_id = ds.school_dw_id
    JOIN ${rs_coredw}.dim_tenant dt
        ON ds.school_tenant_id = dt.tenant_id
    WHERE hbt.fuhha_role_dw_id  = 2
        AND CONVERT(DATE, hbt.fuhha_dw_created_time)
            BETWEEN DATEADD(DAY, -15, CONVERT(DATE, GETDATE()))
                AND CONVERT(DATE, GETDATE())
    GROUP BY
        hbt.fuhha_date_dw_id,
        hbt.fuhha_user_dw_id,
        hbt.fuhha_tenant_dw_id,
        hbt.fuhha_school_dw_id,
        ds.school_timezone,
        dt.windows_timezone,
        CONVERT(
            DATE,
            hbt.fuhha_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
        )
) cd
JOIN ${rs_coredw}.dim_tenant dt
    ON cd.tenant_dw_id = dt.tenant_dw_id
GROUP BY
    login_date_dw_id,
    student_dw_id,
    cd.tenant_dw_id,
    school_dw_id,
    local_login_date,
    dt.windows_timezone;