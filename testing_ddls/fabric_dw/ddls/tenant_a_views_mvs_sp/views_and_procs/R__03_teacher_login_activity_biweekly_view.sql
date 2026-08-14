CREATE OR ALTER VIEW ${os_bi_coredw}.teacher_login_activity_biweekly_view AS
WITH date_range AS (
    SELECT full_date
    FROM ${rs_coredw}.dim_date
    WHERE full_date BETWEEN DATEADD(DAY, -14, CONVERT(DATE, GETDATE()))
                        AND CONVERT(DATE, GETDATE())
),

total_teachers AS (
    SELECT DISTINCT
        ds.*,
        dr.full_date AS local_date,
        t.teacher_dw_id AS available_teacher_dw_id,
        t.teacher_id,
        FIRST_VALUE(CONVERT(DATE, t.teacher_created_time)) OVER (
            PARTITION BY t.teacher_dw_id
            ORDER BY t.teacher_created_time
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS teacher_first_created_date,
        FIRST_VALUE(t.teacher_status) OVER (
            PARTITION BY t.teacher_school_dw_id, t.teacher_dw_id
            ORDER BY t.teacher_created_time DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS teacher_current_status
    FROM ${rs_bi_coredw}.bi_active_schools_dim ds
    CROSS JOIN date_range dr

    INNER JOIN ${rs_coredw}.dim_teacher t
        ON t.teacher_school_dw_id = ds.school_dw_id
       AND (
            (
                t.teacher_status = 2
                AND dr.full_date >= CONVERT(
                        DATE,
                        CONVERT(DATETIME2, t.teacher_created_time)
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
)
                AND dr.full_date < CONVERT(
                        DATE,
                        CONVERT(DATETIME2, t.teacher_active_until)
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
)
            )
            OR
            (
                t.teacher_status = 1
                AND dr.full_date >= CONVERT(
                        DATE,
                        CONVERT(DATETIME2, t.teacher_created_time)
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
)
            )
       )
    WHERE NOT EXISTS (SELECT 1 FROM ${rs_bi_coredw}.exclude_teacher_id excl WHERE excl.teacher_id = t.teacher_id)  -- OPT-8
      AND dr.full_date >= ds.academic_year_start_date 
      AND dr.full_date <= ds.academic_year_end_date
),

active_teachers AS (
    SELECT DISTINCT
        CONVERT(DATE, tl.login_local_date_time) AS login_date,
        tl.school_dw_id,
        tl.teacher_dw_id AS active_teacher_dw_id
    FROM ${rs_bi_coredw}.teacher_login tl
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim ds
        ON ds.school_dw_id = tl.school_dw_id

    INNER JOIN ${rs_coredw}.dim_teacher t
        ON t.teacher_dw_id = tl.teacher_dw_id
       AND t.teacher_school_dw_id = tl.school_dw_id
       AND (
            (
                t.teacher_status = 2
                AND CONVERT(DATE, tl.login_local_date_time) >= CONVERT(
                        DATE,
                        CONVERT(DATETIME2, t.teacher_created_time)
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
)
                AND CONVERT(DATE, tl.login_local_date_time) < CONVERT(
                        DATE,
                        CONVERT(DATETIME2, t.teacher_active_until)
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
)
            )
            OR t.teacher_status = 1
       )
    WHERE CONVERT(DATE, tl.login_local_date_time)
          BETWEEN DATEADD(DAY, -14, CONVERT(DATE, GETDATE()))
              AND CONVERT(DATE, GETDATE())
      AND NOT EXISTS (SELECT 1 FROM ${rs_bi_coredw}.exclude_teacher_id excl WHERE excl.teacher_id = t.teacher_id)  -- OPT-8
),

teacher_onboarding AS (
    SELECT DISTINCT
        tl.teacher_dw_id,
        ds.school_dw_id,
        FIRST_VALUE(tl.login_local_date_time) OVER (
            PARTITION BY tl.teacher_dw_id, ds.school_dw_id
            ORDER BY tl.login_local_date_time
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS teacher_first_login_date,
        FIRST_VALUE(tl.login_local_date_time) OVER (
            PARTITION BY tl.teacher_dw_id, ds.school_dw_id
            ORDER BY tl.login_local_date_time DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS teacher_last_login_date
    FROM ${rs_bi_coredw}.teacher_login tl
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim ds
        ON ds.school_dw_id = tl.school_dw_id
       AND CONVERT(DATE, tl.login_local_date_time) >= ds.academic_year_start_date
),

school_prveviousay AS (
    SELECT
        school_dw_id,
        MAX(academic_year_start_date) AS previous_academic_year_start_date,
        MAX(academic_year_end_date)   AS previous_academic_year_end_date
    FROM ${rs_bi_coredw}.bi_all_schools_dim
    WHERE academic_year_is_roll_over_completed = 1
    GROUP BY school_dw_id
),

teacher_onboarding_pay AS (
    SELECT DISTINCT tl.teacher_dw_id
    FROM ${rs_bi_coredw}.teacher_login tl
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim ds
        ON ds.school_dw_id = tl.school_dw_id
    INNER JOIN school_prveviousay sp
        ON sp.school_dw_id = ds.school_dw_id
       AND CONVERT(DATE, tl.login_local_date_time)
           BETWEEN sp.previous_academic_year_start_date
               AND sp.previous_academic_year_end_date
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
    tt.school_alias AS adek_id,
    tt.school_city_name,
    tt.school_organisation,
    tt.school_country_name,
    tt.school_composition,
    tt.school_id,
    tt.school_label,
    tt.available_teacher_dw_id,
    CASE WHEN pay.teacher_dw_id IS NULL THEN 0 ELSE 1 END AS repeat_teacher_previous_ay,
    at.active_teacher_dw_id,
    tt.teacher_id,
    tt.teacher_first_created_date,
    tob.teacher_first_login_date,
    tob.teacher_last_login_date,
    tt.teacher_current_status,
    CONVERT(VARCHAR(4), DATEPART(YEAR, tt.academic_year_start_date))
        + '-' +
    CONVERT(VARCHAR(4), DATEPART(YEAR, tt.academic_year_end_date)) AS academic_year,
    tt.academic_year_start_date,
    tt.academic_year_end_date,
    CONVERT(
        BIT,
        CASE WHEN dh.holiday_date IS NULL THEN 0 ELSE 1 END
) AS holiday_flag,
    tt.school_cx_cluster
FROM total_teachers tt
LEFT JOIN active_teachers at
    ON at.school_dw_id = tt.school_dw_id
   AND at.login_date = tt.local_date
   AND at.active_teacher_dw_id = tt.available_teacher_dw_id
LEFT JOIN teacher_onboarding tob
    ON tob.teacher_dw_id = tt.available_teacher_dw_id
   AND tob.school_dw_id = tt.school_dw_id
LEFT JOIN teacher_onboarding_pay pay
    ON pay.teacher_dw_id = tt.available_teacher_dw_id
LEFT JOIN holidays_dimension dh
    ON dh.holiday_date = tt.local_date
   AND dh.holiday_organisation_dw_id = tt.organisation_dw_id;
