CREATE OR ALTER VIEW ${os_bi_coredw}.principal_login_activity_biweekly_view AS
WITH date_range AS (
    SELECT DISTINCT full_date
    FROM ${rs_coredw}.dim_date dt
    WHERE dt.full_date BETWEEN DATEADD(DAY, -14, CONVERT(DATE, GETDATE()))
                          AND CONVERT(DATE, GETDATE())
),

total_principals AS (
    SELECT DISTINCT
        ds.school_dw_id,
        ds.school_id,
        ds.school_name,
        ds.school_city_name,
        ds.school_organisation,
        ds.organisation_dw_id,
        ds.school_country_name,
        ds.school_composition,
        ds.school_alias,
        ds.tenant_id,
        ds.tenant_name,
        ds.windows_timezone,
        ds.school_label,
        ds.school_created_time,
        ds.academic_year_start_date,
        ds.academic_year_end_date,
        dr.full_date                         AS local_date,
        dp.staff_user_dw_id                  AS available_principal_dw_id,
        dp.staff_user_id                     AS principal_id,
        FIRST_VALUE(CONVERT(DATE, dp.staff_user_created_time)) OVER (
            PARTITION BY dp.staff_user_dw_id
            ORDER BY dp.staff_user_created_time
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )                                    AS principal_first_created_date,
        FIRST_VALUE(dp.staff_user_status) OVER (
            PARTITION BY dp.staff_user_dw_id
            ORDER BY dp.staff_user_created_time DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )                                    AS principal_current_status
    FROM ${rs_bi_coredw}.bi_active_schools_dim ds

    CROSS JOIN date_range dr
    INNER JOIN ${rs_coredw}.dim_staff_user_school_role_association dsusra
        ON dsusra.susra_school_dw_id = ds.school_dw_id
       AND dsusra.susra_status       = 1
    INNER JOIN ${rs_coredw}.dim_staff_user dp
        ON dp.staff_user_dw_id = dsusra.susra_staff_dw_id
       AND (
            (
                dp.staff_user_status  = 2
                AND dp.staff_user_enabled = 1
                AND dr.full_date >= CONVERT(
                    DATE,
                    dp.staff_user_created_time
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                )
                AND dr.full_date < CONVERT(
                    DATE,
                    dp.staff_user_active_until
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                )
            )
         OR (
                dp.staff_user_status  = 1
                AND dp.staff_user_enabled = 1
            )
       )
    WHERE dsusra.susra_role_dw_id = 6
      AND dr.full_date BETWEEN ds.academic_year_start_date
                          AND ds.academic_year_end_date
),

active_principals AS (
    SELECT DISTINCT
        CONVERT(DATE, pl.login_local_date_time) AS login_date,
        pl.school_dw_id,
        pl.principal_dw_id                    AS active_principal_dw_id
    FROM ${rs_bi_coredw}.principal_login pl
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim ds
        ON pl.school_dw_id = ds.school_dw_id

    INNER JOIN ${rs_coredw}.dim_staff_user_school_role_association dsusra
        ON dsusra.susra_school_dw_id = ds.school_dw_id
       AND dsusra.susra_status       = 1
    INNER JOIN ${rs_coredw}.dim_staff_user dp1
        ON dp1.staff_user_dw_id      = dsusra.susra_staff_dw_id
       AND dsusra.susra_school_dw_id = pl.school_dw_id
       AND (
            (
                dp1.staff_user_status  = 2
                AND dp1.staff_user_enabled = 1
                AND CONVERT(DATE, pl.login_local_date_time) >= CONVERT(
                    DATE,
                    dp1.staff_user_created_time
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                )
                AND CONVERT(DATE, pl.login_local_date_time) < CONVERT(
                    DATE,
                    dp1.staff_user_active_until
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                )
            )
         OR (
                dp1.staff_user_status  = 1
                AND dp1.staff_user_enabled = 1
            )
       )
    WHERE CONVERT(DATE, pl.login_local_date_time)
          BETWEEN DATEADD(DAY, -14, CONVERT(DATE, GETDATE()))
              AND CONVERT(DATE, GETDATE())
),
 
principal_onboarding AS (
    SELECT DISTINCT
        tl.principal_dw_id,
        ds.school_dw_id,
        FIRST_VALUE(tl.login_local_date_time) OVER (
            PARTITION BY tl.principal_dw_id, ds.school_dw_id
            ORDER BY tl.login_local_date_time
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS principal_first_login_date,
        FIRST_VALUE(tl.login_local_date_time) OVER (
            PARTITION BY tl.principal_dw_id, ds.school_dw_id
            ORDER BY tl.login_local_date_time DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS principal_last_login_date
    FROM ${rs_bi_coredw}.principal_login tl
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim ds
        ON ds.school_dw_id = tl.school_dw_id
       AND CONVERT(DATE, tl.login_local_date_time) >= ds.academic_year_start_date
),

holidays_dimension AS (
    SELECT DISTINCT
        CONVERT(DATE, holiday_date) AS holiday_date,
        holiday_organisation_dw_id
    FROM ${rs_coredw}.dim_holiday
)

SELECT DISTINCT
    tt.local_date,
    tt.tenant_name,
    tt.school_dw_id,
    tt.school_name,
    tt.school_created_time,
    tt.school_alias                                    AS adek_id,
    tt.school_city_name,
    tt.school_organisation,
    tt.school_country_name,
    tt.school_composition,
    tt.school_id,
    tt.school_label,
    tt.available_principal_dw_id,
    ap.active_principal_dw_id,
    tt.principal_id,
    tt.principal_first_created_date,
    po.principal_first_login_date,
    po.principal_last_login_date,
    tt.principal_current_status,
    CONVERT(VARCHAR(4), DATEPART(YEAR, tt.academic_year_start_date))
        + '-' +
    CONVERT(VARCHAR(4), DATEPART(YEAR, tt.academic_year_end_date)) AS academic_year,
    tt.academic_year_start_date,
    tt.academic_year_end_date,
    CONVERT(
        BIT,
        CASE
            WHEN dh.holiday_date IS NULL THEN 0
            ELSE 1
        END
) AS holiday_flag
FROM total_principals tt
LEFT JOIN active_principals ap
    ON tt.school_dw_id              = ap.school_dw_id
   AND tt.local_date                = ap.login_date
   AND tt.available_principal_dw_id = ap.active_principal_dw_id
LEFT JOIN principal_onboarding po
    ON tt.available_principal_dw_id = po.principal_dw_id
   AND tt.school_dw_id              = po.school_dw_id
LEFT JOIN holidays_dimension dh
    ON dh.holiday_date               = tt.local_date
   AND dh.holiday_organisation_dw_id = tt.organisation_dw_id;
