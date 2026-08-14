CREATE OR ALTER VIEW ${os_bi_coredw}.magg_teacher_login_activity_dm_view AS
WITH date_dimension AS (
    SELECT DISTINCT
        full_date                  AS local_date,
        calendar_week_number       AS week_num,
        uae_week_number            AS uae_week_num,
        calendar_year_week_number  AS wy_num,
        uae_year_week_number       AS uae_wy_num,
        calendar_year_month_number AS year_month
    FROM ${rs_coredw}.dim_date dt
    WHERE dt.full_date >= DATEADD(DAY, -1095, CONVERT(DATE, GETDATE()))
      AND dt.full_date <= DATEADD(DAY, -1,    CONVERT(DATE, GETDATE()))
),

monthly_active_teachers AS (
    SELECT DISTINCT
        dd.year_month,
        tl.school_dw_id,
        CONVERT(VARCHAR(4), DATEPART(YEAR, ay.academic_year_start_date))
            + '-' +
        CONVERT(VARCHAR(4), DATEPART(YEAR, ay.academic_year_end_date)) AS academic_year,
        DENSE_RANK() OVER (
            PARTITION BY dd.year_month, ay.academic_year_start_date, tl.school_dw_id
            ORDER BY tl.teacher_dw_id ASC
        )
        +
        DENSE_RANK() OVER (
            PARTITION BY dd.year_month, ay.academic_year_start_date, tl.school_dw_id
            ORDER BY tl.teacher_dw_id DESC
        ) - 1 AS monthly_active_teachers
    FROM ${rs_bi_coredw}.teacher_login tl
    INNER JOIN date_dimension dd
        ON CONVERT(DATE, tl.login_local_date_time) = dd.local_date
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim ds
        ON tl.school_dw_id = ds.school_dw_id

    INNER JOIN ${rs_coredw}.dim_teacher dtt
        ON dtt.teacher_school_dw_id = tl.school_dw_id
       AND dtt.teacher_dw_id        = tl.teacher_dw_id
       AND (
            (
                dtt.teacher_status = 2
                AND DATETRUNC(MONTH, dd.local_date) >=
                    DATETRUNC(
                        MONTH,
                        dtt.teacher_created_time
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                    )
                AND DATETRUNC(MONTH, dd.local_date) <
                    DATETRUNC(
                        MONTH,
                        dtt.teacher_active_until
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                    )
            )
            OR
            (
                dtt.teacher_status = 1
                AND DATETRUNC(MONTH, dd.local_date) >=
                    DATETRUNC(
                        MONTH,
                        dtt.teacher_created_time
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                    )
            )
       )
    INNER JOIN ${rs_coredw}.dim_academic_year ay
        ON ay.academic_year_school_id = ds.school_id
       AND dd.local_date >= ay.academic_year_start_date
       AND dd.local_date <= ay.academic_year_end_date
    WHERE NOT EXISTS (SELECT 1 FROM ${rs_bi_coredw}.exclude_teacher_id excl WHERE excl.teacher_id = dtt.teacher_id)  -- OPT-8
),

cte_total_teachers AS (
    SELECT DISTINCT
        tenant_name,
        school_dw_id,
        school_id,
        school_name,
        school_created_time,
        adek_id,
        school_city_name,
        school_organisation,
        school_country_name,
        school_composition,
        school_latitude,
        school_longitude,
        school_label,
        month_year_number,
        monthly_total_teachers,
        academic_year,
        org_dw_id,
        org_term,
        term_start_date,
        term_end_date,
        holiday_flag,
        school_cx_cluster,
        ROW_NUMBER() OVER (
            PARTITION BY school_name, month_year_number
            ORDER BY local_date DESC
        ) AS rn
    FROM ${rs_bi_coredw}.total_teachers
    WHERE local_date <> DATEFROMPARTS(2022, 1, 3)
)

SELECT DISTINCT
    tt.tenant_name,
    tt.school_dw_id,
    tt.school_id,
    tt.school_name,
    tt.school_created_time,
    tt.adek_id,
    tt.school_city_name,
    tt.school_organisation,
    tt.school_country_name,
    tt.school_composition,
    tt.school_latitude,
    tt.school_longitude,
    tt.school_label,
    tt.month_year_number,
    mat.monthly_active_teachers,
    tt.monthly_total_teachers,
    tt.academic_year,
    tt.org_dw_id,
    tt.org_term,
    tt.term_start_date,
    tt.term_end_date,
    tt.holiday_flag,
    tt.school_cx_cluster,
    'Monthly' AS aa_type
FROM cte_total_teachers tt
LEFT JOIN monthly_active_teachers mat
    ON tt.school_dw_id = mat.school_dw_id
   AND tt.month_year_number = mat.year_month
   AND ISNULL(tt.academic_year, 'NA') = ISNULL(mat.academic_year, 'NA')
WHERE tt.academic_year IS NOT NULL
  AND tt.rn = 1;
