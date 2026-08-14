CREATE OR ALTER VIEW ${OS_EAGLES_COREDW}.teacher_absentees_noholiday_weekly AS
WITH total_teachers AS (
    SELECT DISTINCT
        ds.tenant_name,
        ds.school_name,
        ds.school_id,
        ds.school_dw_id,
        ds.organisation_dw_id,
        ds.windows_timezone,
        ds.academic_year_start_date,
        ds.academic_year_end_date,
        dse.full_date AS local_date,
        CONVERT(datetime2(7), DATETRUNC(iso_week, dse.full_date))  AS week_start_date,
        DATEPART(WEEKDAY, dse.full_date) AS weekend,
        dt.teacher_dw_id AS available_teacher_dw_id,
        dt.teacher_id,
        FIRST_VALUE(CONVERT(date, dt.teacher_created_time))
        OVER (
            PARTITION BY dt.teacher_dw_id
            ORDER BY dt.teacher_created_time
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS teacher_first_created_date,
        FIRST_VALUE(dt.teacher_status) OVER (
            PARTITION BY dt.teacher_dw_id
            ORDER BY dt.teacher_created_time DESC ,teacher_status ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS teacher_current_status
    FROM ${RS_BI_COREDW}.bi_active_schools_dim ds
    CROSS JOIN (
        SELECT DISTINCT full_date
        FROM ${RS_COREDW}.dim_date
        WHERE full_date BETWEEN
              DATEADD(day, -360, CONVERT(date, GETDATE()))
          AND DATEADD(day, -1, CONVERT(date, GETDATE()))
    ) dse
    LEFT JOIN (
        SELECT DISTINCT
            CONVERT(date, holiday_date) AS holiday_date,
            holiday_organisation_dw_id
        FROM ${RS_COREDW}.dim_holiday
    ) dh
        ON dh.holiday_date = dse.full_date
       AND dh.holiday_organisation_dw_id = ds.organisation_dw_id
    INNER JOIN ${RS_COREDW}.dim_teacher dt
        ON dt.teacher_school_dw_id = ds.school_dw_id
       AND (
            (
                dt.teacher_status = 2
                AND dse.full_date >= CONVERT(date, dt.teacher_created_time
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC'))
                AND dse.full_date < CONVERT(date, dt.teacher_active_until
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC'))
            )
            OR
            (
                dt.teacher_status = 1
                AND dse.full_date >= CONVERT(date, dt.teacher_created_time
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC'))
            )
       )
       AND dt.teacher_id NOT IN (
           SELECT DISTINCT teacher_id
           FROM ${RS_BI_COREDW}.exclude_teacher_id
       )
    WHERE dh.holiday_date IS NULL
      AND DATEPART(WEEKDAY, dse.full_date) BETWEEN 2 AND 6
      AND dse.full_date >= ds.academic_year_start_date
      AND dse.full_date <= ds.academic_year_end_date
),

active_teachers AS (
    SELECT DISTINCT
        CONVERT(date, tl.login_local_date_time) AS login_date,
        tl.school_dw_id,
        tl.teacher_dw_id AS active_teacher_dw_id
    FROM ${RS_BI_COREDW}.teacher_login tl
    INNER JOIN ${RS_BI_COREDW}.bi_active_schools_dim ds
        ON tl.school_dw_id = ds.school_dw_id
    INNER JOIN ${RS_COREDW}.dim_teacher dt
        ON dt.teacher_school_dw_id = tl.school_dw_id
       AND dt.teacher_dw_id = tl.teacher_dw_id
       AND CONVERT(date, tl.login_local_date_time) >= CONVERT(date, dt.teacher_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC'))
       AND (
            CONVERT(date, tl.login_local_date_time) < CONVERT(date, dt.teacher_active_until
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC'))
            OR dt.teacher_status = 1
       )
    WHERE CONVERT(date, tl.login_local_date_time) BETWEEN
          DATEADD(day, -360, CONVERT(date, GETDATE()))
      AND CONVERT(date, GETDATE())
)

SELECT
    tt.week_start_date,
    STRING_AGG(
        CASE WHEN at.active_teacher_dw_id IS NULL THEN CONVERT(varchar(10), tt.local_date, 120) END,
        '|'
    ) WITHIN GROUP (ORDER BY tt.local_date) AS absent_days,
    COUNT(CASE WHEN at.active_teacher_dw_id IS NULL THEN tt.local_date END) AS total_absent_days,
    tt.tenant_name,
    tt.school_name,
    tt.school_id,
    tt.school_dw_id,
    tt.available_teacher_dw_id,
    tt.teacher_id,
    tt.teacher_first_created_date,
    tt.teacher_current_status,
    CONVERT(varchar(4), YEAR(tt.academic_year_start_date)) + '-' +
    CONVERT(varchar(4), YEAR(tt.academic_year_end_date)) AS academic_year,
    tt.academic_year_start_date,
    tt.academic_year_end_date
FROM total_teachers tt
LEFT JOIN active_teachers at
    ON tt.school_dw_id = at.school_dw_id
   AND tt.local_date = at.login_date
   AND tt.available_teacher_dw_id = at.active_teacher_dw_id
GROUP BY
    tt.week_start_date,
    tt.tenant_name,
    tt.school_name,
    tt.school_id,
    tt.school_dw_id,
    tt.available_teacher_dw_id,
    tt.teacher_id,
    tt.teacher_first_created_date,
    tt.teacher_current_status,
    CONVERT(varchar(4), YEAR(tt.academic_year_start_date)) + '-' +
    CONVERT(varchar(4), YEAR(tt.academic_year_end_date)),
    tt.academic_year_start_date,
    tt.academic_year_end_date;