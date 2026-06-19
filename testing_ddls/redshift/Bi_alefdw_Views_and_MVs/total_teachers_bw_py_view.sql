CREATE OR REPLACE VIEW bi_alefdw.total_teachers_bw_py_view AS
WITH date_dimension AS
         (SELECT DISTINCT full_date                 AS local_date,
                          calendar_week_number      AS week_num,
                          uae_week_number           AS uae_week_num,
                          calendar_year_week_number AS wy_num,
                          uae_year_week_number      AS uae_wy_num,
                          calendar_year_month_number as year_month
    FROM alefdw.dim_date dt
    WHERE dt.full_date between (trunc(sysdate) - 15) and (trunc(sysdate) - 1) -- Date can be changed based on requirement
),

    holidays_dimension AS
    (SELECT DISTINCT cast(holiday_date AS date) AS holiday_date,
    holiday_organisation_dw_id
    FROM alefdw.dim_holiday
)

SELECT DISTINCT local_date,
                tenant_name,
                school_dw_id,
                school_name,
                school_alias                                   AS adek_id,
                school_city_name,
                school_organisation,
                school_country_name,
                school_composition,
                school_latitude,
                school_longitude,
                school_label,
                school_cx_cluster,
                school_created_time,
                week_num                                       AS week_number,
                wy_num                                         AS week_year_number,
                DENSE_RANK() OVER (PARTITION BY academic_year_start_date,wy_num,ds.school_dw_id ORDER BY teacher_dw_id ASC ) +
                    DENSE_RANK() OVER (PARTITION BY academic_year_start_date,wy_num,ds.school_dw_id ORDER BY teacher_dw_id DESC) - 1
                                                               AS weekly_total_teachers,
                DENSE_RANK() OVER (PARTITION BY local_date,academic_year_start_date,ds.school_dw_id ORDER BY teacher_dw_id ASC ) +
                    DENSE_RANK() OVER (PARTITION BY local_date,academic_year_start_date,ds.school_dw_id ORDER BY teacher_dw_id DESC) - 1
                                                               AS total_teachers,
                DENSE_RANK() OVER (PARTITION BY year_month,academic_year_start_date,ds.school_dw_id ORDER BY teacher_dw_id ASC ) +
                    DENSE_RANK() OVER (PARTITION BY year_month,academic_year_start_date,ds.school_dw_id ORDER BY teacher_dw_id DESC) - 1
                                                               AS monthly_total_teachers,
                extract('year' from ds.academic_year_start_date) || '-' ||
                    extract('year' from ds.academic_year_end_date) AS academic_year,
                ds.school_id,
                ds.organisation_dw_id                          AS org_dw_id,
                null AS org_term,
                null AS term_start_date,
                null AS term_end_date,
                CASE
                    WHEN holiday_date IS NULL THEN FALSE
                    ELSE TRUE
                    END                                        AS holiday_flag,
                year_month                                     AS month_year_number
FROM (SELECT DISTINCT *
    FROM bi_alefdw.bi_all_schools_dim_mv
    CROSS JOIN date_dimension
    WHERE (local_date >= academic_year_start_date AND local_date <= academic_year_end_date)) ds
    JOIN alefdw.dim_teacher dt
        ON dt.teacher_school_dw_id = ds.school_dw_id
        AND ((teacher_status = 2 AND local_date >= trunc(convert_timezone('UTC', ds.tenant_timezone, teacher_created_time))
            AND local_date < trunc(convert_timezone('UTC', ds.tenant_timezone, teacher_active_until)))
            OR (teacher_status = 1 AND local_date >= trunc(convert_timezone('UTC', ds.tenant_timezone, teacher_created_time))))
    LEFT JOIN holidays_dimension dh
        ON dh.holiday_date = ds.local_date
        AND dh.holiday_organisation_dw_id = ds.organisation_dw_id
WHERE dt.teacher_id NOT IN (SELECT DISTINCT teacher_id FROM bi_alefdw.exclude_teacher_id)
 AND ((ds.school_status > 1 AND
      local_date >= trunc(convert_timezone('UTC', ds.tenant_timezone, ds.school_created_time))
      AND local_date <= trunc(convert_timezone('UTC', ds.tenant_timezone, ds.school_updated_time)))
      OR (ds.school_status = 1 AND local_date >= trunc(convert_timezone('UTC', ds.tenant_timezone, ds.school_created_time))))
WITH NO SCHEMA BINDING;