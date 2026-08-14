CREATE OR REPLACE MATERIALIZED LAKE VIEW {{os_bi_coredw}}.total_teachers_py_mv
AS
WITH date_dimension AS (
    SELECT DISTINCT
        full_date                    AS local_date,
        calendar_week_number         AS week_num,
        uae_week_number              AS uae_week_num,
        calendar_year_week_number    AS wy_num,
        uae_year_week_number         AS uae_wy_num,
        calendar_year_month_number   AS year_month
    FROM {{rs_coredw}}.dim_date dt
    WHERE dt.full_date BETWEEN date_add(current_date(), -90) AND current_date()  -- Date can be changed based on requirement
),

holidays_dimension AS (
    SELECT DISTINCT
        cast(holiday_date AS date)   AS holiday_date,
        holiday_organisation_dw_id
    FROM {{rs_coredw}}.dim_holiday
)

SELECT DISTINCT
    local_date,
    tenant_name,
    school_dw_id,
    school_name,
    school_alias                                                                AS adek_id,
    school_city_name,
    school_organisation,
    school_country_name,
    school_composition,
    school_latitude,
    school_longitude,
    school_label,
    school_cx_cluster,
    school_created_time,
    ds.week_num                                                                 AS week_number,
    ds.wy_num                                                                   AS week_year_number,
    DENSE_RANK() OVER (PARTITION BY academic_year_start_date, wy_num, ds.school_dw_id ORDER BY teacher_dw_id ASC)  +
    DENSE_RANK() OVER (PARTITION BY academic_year_start_date, wy_num, ds.school_dw_id ORDER BY teacher_dw_id DESC) - 1
                                                                                AS weekly_total_teachers,
    DENSE_RANK() OVER (PARTITION BY local_date, academic_year_start_date, ds.school_dw_id ORDER BY teacher_dw_id ASC)  +
    DENSE_RANK() OVER (PARTITION BY local_date, academic_year_start_date, ds.school_dw_id ORDER BY teacher_dw_id DESC) - 1
                                                                                AS total_teachers,
    DENSE_RANK() OVER (PARTITION BY year_month, academic_year_start_date, ds.school_dw_id ORDER BY teacher_dw_id ASC)  +
    DENSE_RANK() OVER (PARTITION BY year_month, academic_year_start_date, ds.school_dw_id ORDER BY teacher_dw_id DESC) - 1
                                                                                AS monthly_total_teachers,
    concat(
        year(ds.academic_year_start_date), '-',
        year(ds.academic_year_end_date)
    )                                                                           AS academic_year,
    ds.school_id,
    ds.organisation_dw_id                                                       AS org_dw_id,
    CAST(NULL AS INT)                                                           AS org_term,
    CAST(NULL AS DATE)                                                          AS term_start_date,
    CAST(NULL AS DATE)                                                          AS term_end_date,
    CASE
        WHEN holiday_date IS NULL THEN FALSE
        ELSE TRUE
    END                                                                         AS holiday_flag,
    ds.year_month                                                               AS month_year_number
FROM (
    SELECT DISTINCT *
    FROM {{rs_bi_coredw}}.bi_all_schools_dim
    CROSS JOIN date_dimension
    WHERE local_date >= academic_year_start_date
      AND local_date <= academic_year_end_date
) ds
INNER JOIN {{rs_coredw}}.dim_teacher dt
    ON dt.teacher_school_dw_id = ds.school_dw_id
    AND (
        (
            teacher_status = 2
            AND local_date >= to_date(from_utc_timestamp(teacher_created_time, ds.tenant_timezone))
            AND local_date <  to_date(from_utc_timestamp(teacher_active_until, ds.tenant_timezone))
        )
        OR (
            teacher_status = 1
            AND local_date >= to_date(from_utc_timestamp(teacher_created_time, ds.tenant_timezone))
        )
    )
LEFT JOIN holidays_dimension dh
    ON dh.holiday_date = ds.local_date
    AND dh.holiday_organisation_dw_id = ds.organisation_dw_id
WHERE dt.teacher_id NOT IN (
    SELECT DISTINCT teacher_id FROM {{rs_bi_coredw}}.exclude_teacher_id
)
AND (
    (
        ds.school_status > 1
        AND local_date >= to_date(from_utc_timestamp(ds.school_created_time, ds.tenant_timezone))
        AND local_date <= to_date(from_utc_timestamp(ds.school_updated_time, ds.tenant_timezone))
    )
    OR (
        ds.school_status = 1
        AND local_date >= to_date(from_utc_timestamp(ds.school_created_time, ds.tenant_timezone))
    )
);  