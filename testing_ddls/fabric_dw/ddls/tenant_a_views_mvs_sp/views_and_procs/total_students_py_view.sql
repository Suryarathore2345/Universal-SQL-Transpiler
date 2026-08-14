CREATE OR ALTER VIEW ${os_bi_coredw}.total_students_py_view AS
WITH date_dimension AS
(
    SELECT DISTINCT
        full_date                  AS local_date,
        calendar_week_number       AS week_num,
        uae_week_number            AS uae_week_num,
        calendar_year_week_number  AS wy_num,
        uae_year_week_number       AS uae_wy_num,
        calendar_year_month_number AS year_month
    FROM ${rs_coredw}.dim_date dt
    WHERE dt.full_date = DATEADD(DAY, -1, CAST(GETDATE() AS DATE))
),

holidays_dimension AS
(
    SELECT DISTINCT
        CAST(holiday_date AS DATE) AS holiday_date,
        holiday_organisation_dw_id
    FROM ${rs_coredw}.dim_holiday
)

SELECT DISTINCT
    dse.local_date,
    dsc.tenant_name,
    dsc.school_dw_id,
    dsc.school_name,
    dsc.school_city_name,
    dsc.school_organisation,
    dsc.school_country_name,
    dsc.school_composition,
    dsc.school_latitude,
    dsc.school_longitude,
    dsc.school_alias AS adek_id,
    dsc.school_label,
    dsc.school_created_time,
    dsc.school_cx_cluster,
    CAST(DATEPART(YEAR, dsc.academic_year_start_date) AS VARCHAR(4))
        + '-' +
    CAST(DATEPART(YEAR, dsc.academic_year_end_date) AS VARCHAR(4)) AS academic_year,
    dg.grade_k12grade AS grade,
    '' AS class,
    dse.section_dw_id,
    UPPER(dse.section_alias) AS section,
    ds.student_tags,
    ds.student_special_needs,
    dse.week_num AS week_number,

    DENSE_RANK() OVER (
        PARTITION BY dse.wy_num, dsc.academic_year_start_date,
                     dse.section_dw_id, ds.student_tags, ds.student_special_needs
        ORDER BY ds.student_dw_id ASC
    )
    +
    DENSE_RANK() OVER (
        PARTITION BY dse.wy_num, dsc.academic_year_start_date,
                     dse.section_dw_id, ds.student_tags, ds.student_special_needs
        ORDER BY ds.student_dw_id DESC
    ) - 1 AS weekly_total_students,

    DENSE_RANK() OVER (
        PARTITION BY dse.local_date, dsc.academic_year_start_date,
                     dse.section_dw_id, ds.student_tags, ds.student_special_needs
        ORDER BY ds.student_dw_id ASC
    )
    +
    DENSE_RANK() OVER (
        PARTITION BY dse.local_date, dsc.academic_year_start_date,
                     dse.section_dw_id, ds.student_tags, ds.student_special_needs
        ORDER BY ds.student_dw_id DESC
    ) - 1 AS total_students,

    DENSE_RANK() OVER (
        PARTITION BY dse.year_month, dsc.academic_year_start_date,
                     dse.section_dw_id, ds.student_tags, ds.student_special_needs
        ORDER BY ds.student_dw_id ASC
    )
    +
    DENSE_RANK() OVER (
        PARTITION BY dse.year_month, dsc.academic_year_start_date,
                     dse.section_dw_id, ds.student_tags, ds.student_special_needs
        ORDER BY ds.student_dw_id DESC
    ) - 1 AS monthly_total_students,

    dsc.school_id AS school_id,
    dsc.organisation_dw_id AS org_dw_id,
    NULL AS org_term,
    NULL AS term_start_date,
    NULL AS term_end_date,

    CAST(
        CASE
            WHEN dh.holiday_date IS NULL THEN 0
            ELSE 1
        END AS BIT
    ) AS holiday_flag,

    dse.year_month AS month_year_number,
    dse.wy_num AS week_year_number
FROM (
    SELECT section_alias, section_dw_id, grade_id, school_id, tenant_id, dd.*
    FROM ${rs_coredw}.dim_section
    CROSS JOIN date_dimension dd
    WHERE school_id IS NOT NULL
) dse

INNER JOIN ${database}.${rs_bi_coredw}.bi_all_schools_dim_mv dsc
    ON dsc.school_id = dse.school_id

LEFT JOIN ${rs_bi_coredw}.timezone_mapping tz
    ON tz.iana_timezone = dsc.tenant_timezone

INNER JOIN ${database}.${rs_bi_coredw}.bi_student_dim_mv ds
    ON ds.student_section_dw_id = dse.section_dw_id
   AND (
        (
            ds.student_status = 2
            AND dse.local_date >= CAST(
                ds.student_created_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE COALESCE(tz.windows_timezone,'UTC')
                AS DATE
            )
            AND dse.local_date < CAST(
                ds.student_active_until
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE COALESCE(tz.windows_timezone,'UTC')
                AS DATE
            )
        )
        OR (
            ds.student_status = 1
            AND dse.local_date >= CAST(
                ds.student_created_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE COALESCE(tz.windows_timezone,'UTC')
                AS DATE
            )
        )
    )

INNER JOIN ${rs_coredw}.dim_grade dg
    ON dse.grade_id = dg.grade_id
   AND dg.grade_dw_id = ds.student_grade_dw_id
   AND dsc.academic_year_id = dg.academic_year_id

LEFT JOIN holidays_dimension dh
    ON dh.holiday_date = dse.local_date
   AND dh.holiday_organisation_dw_id = dsc.organisation_dw_id

WHERE
(
    (
        dsc.school_status > 1
        AND dse.local_date >= CAST(
            dsc.school_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE COALESCE(tz.windows_timezone,'UTC')
            AS DATE
        )
        AND dse.local_date <= CAST(
            dsc.school_updated_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE COALESCE(tz.windows_timezone,'UTC')
            AS DATE
        )
    )
    OR (
        dsc.school_status = 1
        AND dse.local_date >= CAST(
            dsc.school_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE COALESCE(tz.windows_timezone,'UTC')
            AS DATE
        )
    )
)
AND dse.local_date BETWEEN dsc.academic_year_start_date
                        AND dsc.academic_year_end_date;