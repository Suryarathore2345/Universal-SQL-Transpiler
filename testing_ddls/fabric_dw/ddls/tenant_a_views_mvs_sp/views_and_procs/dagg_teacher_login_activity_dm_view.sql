CREATE OR ALTER VIEW ${os_bi_coredw}.dagg_teacher_login_activity_dm_view AS
WITH date_dimension AS (
    SELECT DISTINCT
        full_date AS local_date,
        calendar_week_number       AS week_num,
        uae_week_number            AS uae_week_num,
        calendar_year_week_number  AS wy_num,
        uae_year_week_number       AS uae_wy_num,
        calendar_year_month_number AS year_month
    FROM ${rs_coredw}.dim_date dt
    WHERE dt.full_date >= DATEADD(day, -365, CONVERT(DATE, GETDATE()))
      AND dt.full_date <= DATEADD(day, -1, CONVERT(DATE, GETDATE()))
),

daily_active_teachers AS (
    SELECT DISTINCT
        CONVERT(DATE, tl.login_local_date_time)                                 AS login_date,
        tl.school_dw_id,
        CONVERT(VARCHAR(4), DATEPART(year, ay.academic_year_start_date))
          + '-' +
        CONVERT(VARCHAR(4), DATEPART(year, ay.academic_year_end_date))           AS academic_year,
        DENSE_RANK() OVER (
            PARTITION BY CONVERT(DATE, tl.login_local_date_time), ay.academic_year_start_date, tl.school_dw_id
            ORDER BY tl.teacher_dw_id ASC
        )
        + DENSE_RANK() OVER (
            PARTITION BY CONVERT(DATE, tl.login_local_date_time), ay.academic_year_start_date, tl.school_dw_id
            ORDER BY tl.teacher_dw_id DESC
        ) - 1                                                                 AS active_teachers
    FROM ${rs_bi_coredw}.teacher_login tl
    INNER JOIN date_dimension dd
        ON CONVERT(DATE, tl.login_local_date_time) = dd.local_date
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim ds
        ON tl.school_dw_id = ds.school_dw_id
    INNER JOIN ${rs_coredw}.dim_teacher dt
        ON dt.teacher_school_dw_id = tl.school_dw_id
       AND dt.teacher_dw_id = tl.teacher_dw_id
       AND (
           (dt.teacher_status = 2
            AND dd.local_date >= CONVERT(DATE, dt.teacher_created_time AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC'))
            AND dd.local_date <  CONVERT(DATE, dt.teacher_active_until AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC'))
           )
           OR (dt.teacher_status = 1
               AND dd.local_date >= CONVERT(DATE, dt.teacher_created_time AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC'))
           )
       )
    INNER JOIN ${rs_coredw}.dim_academic_year ay
        ON ay.academic_year_school_id = ds.school_id
       AND (dd.local_date >= ay.academic_year_start_date
            AND dd.local_date <= ay.academic_year_end_date)
       AND ay.academic_year_status = 1
    WHERE NOT EXISTS (SELECT 1 FROM ${rs_bi_coredw}.exclude_teacher_id excl WHERE excl.teacher_id = dt.teacher_id)
)

SELECT DISTINCT
    tt.local_date,
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
    tt.week_number,
    tt.week_year_number,
    dat.active_teachers,
    tt.total_teachers,
    tt.academic_year,
    tt.org_dw_id,
    tt.org_term,
    tt.term_start_date,
    tt.term_end_date,
    tt.holiday_flag,
    tt.school_cx_cluster,
    'Daily' AS aa_type
FROM ${rs_bi_coredw}.total_teachers tt
LEFT JOIN daily_active_teachers dat
    ON tt.school_dw_id = dat.school_dw_id
   AND tt.local_date = dat.login_date
   AND ISNULL(tt.academic_year, 'NA') = ISNULL(dat.academic_year, 'NA')
WHERE tt.academic_year IS NOT NULL;
