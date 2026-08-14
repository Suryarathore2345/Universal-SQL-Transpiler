CREATE OR ALTER VIEW ${os_bi_coredw}.total_teachers_bw_py_view AS
WITH date_dimension AS (
    SELECT DISTINCT
        full_date                  AS local_date,
        calendar_week_number       AS week_num,
        uae_week_number            AS uae_week_num,
        calendar_year_week_number  AS wy_num,
        uae_year_week_number       AS uae_wy_num,
        calendar_year_month_number AS year_month
    FROM ${rs_coredw}.dim_date dt
    WHERE dt.full_date BETWEEN DATEADD(DAY, -15, CONVERT(DATE, GETDATE()))
                           AND DATEADD(DAY, -1,  CONVERT(DATE, GETDATE()))
),

holidays_dimension AS (
    SELECT DISTINCT
        CONVERT(DATE, holiday_date) AS holiday_date,
        holiday_organisation_dw_id
    FROM ${rs_coredw}.dim_holiday
)

SELECT DISTINCT
    ds.local_date,
    ds.tenant_name,
    ds.school_dw_id,
    ds.school_name,
    ds.school_alias               AS adek_id,
    ds.school_city_name,
    ds.school_organisation,
    ds.school_country_name,
    ds.school_composition,
    ds.school_latitude,
    ds.school_longitude,
    ds.school_label,
    ds.school_cx_cluster,
    ds.school_created_time,
    ds.week_num                   AS week_number,
    ds.wy_num                     AS week_year_number,

    DENSE_RANK() OVER (
        PARTITION BY ds.academic_year_start_date, ds.wy_num, ds.school_dw_id
        ORDER BY dt.teacher_dw_id ASC
    )
    +
    DENSE_RANK() OVER (
        PARTITION BY ds.academic_year_start_date, ds.wy_num, ds.school_dw_id
        ORDER BY dt.teacher_dw_id DESC
    ) - 1 AS weekly_total_teachers,

    DENSE_RANK() OVER (
        PARTITION BY ds.local_date, ds.academic_year_start_date, ds.school_dw_id
        ORDER BY dt.teacher_dw_id ASC
    )
    +
    DENSE_RANK() OVER (
        PARTITION BY ds.local_date, ds.academic_year_start_date, ds.school_dw_id
        ORDER BY dt.teacher_dw_id DESC
    ) - 1 AS total_teachers,

    DENSE_RANK() OVER (
        PARTITION BY ds.year_month, ds.academic_year_start_date, ds.school_dw_id
        ORDER BY dt.teacher_dw_id ASC
    )
    +
    DENSE_RANK() OVER (
        PARTITION BY ds.year_month, ds.academic_year_start_date, ds.school_dw_id
        ORDER BY dt.teacher_dw_id DESC
    ) - 1 AS monthly_total_teachers,

    CONVERT(VARCHAR(4), YEAR(ds.academic_year_start_date)) + '-' +
    CONVERT(VARCHAR(4), YEAR(ds.academic_year_end_date)) AS academic_year,

    ds.school_id,
    ds.organisation_dw_id          AS org_dw_id,
    CONVERT(VARCHAR(50), NULL)      AS org_term,
    CONVERT(DATE, NULL)             AS term_start_date,
    CONVERT(DATE, NULL)             AS term_end_date,

    CONVERT(
        BIT,
        CASE
            WHEN dh.holiday_date IS NULL THEN 0
            ELSE 1
        END
    ) AS holiday_flag,

    ds.year_month AS month_year_number

FROM (
    SELECT DISTINCT
        s.tenant_name,
        s.windows_timezone,
        s.school_dw_id,
        s.school_id,
        s.school_name,
        s.school_alias,
        s.school_city_name,
        s.school_organisation,
        s.school_country_name,
        s.school_composition,
        s.school_latitude,
        s.school_longitude,
        s.school_label,
        s.school_cx_cluster,
        s.school_created_time,
        s.school_updated_time,
        s.school_status,
        s.organisation_dw_id,
        s.academic_year_start_date,
        s.academic_year_end_date,
        d.local_date,
        d.week_num,
        d.uae_week_num,
        d.wy_num,
        d.uae_wy_num,
        d.year_month
    FROM ${rs_bi_coredw}.bi_all_schools_dim s
    CROSS JOIN date_dimension d
    WHERE d.local_date >= s.academic_year_start_date
      AND d.local_date <= s.academic_year_end_date
) ds

JOIN ${rs_coredw}.dim_teacher dt
    ON dt.teacher_school_dw_id = ds.school_dw_id
   AND (
        (
            dt.teacher_status = 2
            AND ds.local_date >= CONVERT(
                    DATE,
                    dt.teacher_created_time
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                )
            AND ds.local_date < CONVERT(
                    DATE,
                    dt.teacher_active_until
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                )
        )
        OR
        (
            dt.teacher_status = 1
            AND ds.local_date >= CONVERT(
                    DATE,
                    dt.teacher_created_time
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                )
        )
   )

LEFT JOIN holidays_dimension dh
    ON dh.holiday_date = ds.local_date
   AND dh.holiday_organisation_dw_id = ds.organisation_dw_id

WHERE NOT EXISTS (SELECT 1 FROM ${rs_bi_coredw}.exclude_teacher_id excl WHERE excl.teacher_id = dt.teacher_id)  -- OPT-8
AND (
    (
        ds.school_status > 1
        AND ds.local_date >= CONVERT(
                DATE,
                ds.school_created_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
            )
        AND ds.local_date <= CONVERT(
                DATE,
                ds.school_updated_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
            )
    )
    OR
    (
        ds.school_status = 1
        AND ds.local_date >= CONVERT(
                DATE,
                ds.school_created_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
            )
    )
);
