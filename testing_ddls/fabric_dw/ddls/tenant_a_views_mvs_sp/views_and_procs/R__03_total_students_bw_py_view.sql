CREATE OR ALTER VIEW ${os_bi_coredw}.total_students_bw_py_view AS
WITH date_dimension AS (
    SELECT DISTINCT
        full_date                    AS local_date,
        calendar_week_number         AS week_num,
        uae_week_number              AS uae_week_num,
        calendar_year_week_number    AS wy_num,
        uae_year_week_number         AS uae_wy_num,
        calendar_year_month_number   AS year_month
    FROM ${rs_coredw}.dim_date dt
    WHERE dt.full_date BETWEEN DATEADD(day, -15, CONVERT(DATE, GETDATE()))
                           AND DATEADD(day, -1, CONVERT(DATE, GETDATE()))
),
holidays_dimension AS (
    SELECT DISTINCT
        CONVERT(DATE, holiday_date) AS holiday_date,
        holiday_organisation_dw_id
    FROM ${rs_coredw}.dim_holiday
)
SELECT DISTINCT
    local_date,
    tenant_name,
    school_dw_id,
    school_name,
    school_city_name,
    school_organisation,
    school_country_name,
    school_composition,
    school_latitude,
    school_longitude,
    school_alias AS adek_id,
    school_label,
    school_created_time,
    school_cx_cluster,
    CONCAT(
        DATEPART(year, dsc.academic_year_start_date), '-',
        DATEPART(year, dsc.academic_year_end_date)
    ) AS academic_year,
    grade_k12grade AS grade,
    '' AS class,
    section_dw_id,
    CASE
        WHEN section_alias IS NULL THEN NULL
        ELSE UPPER(section_alias)
    END AS section,
    student_tags,
    student_special_needs,
    week_num AS week_number,

    DENSE_RANK() OVER (
        PARTITION BY wy_num, academic_year_start_date,
                     dse.section_dw_id, student_tags, student_special_needs
        ORDER BY student_dw_id ASC
    )
    + DENSE_RANK() OVER (
        PARTITION BY wy_num, academic_year_start_date,
                     dse.section_dw_id, student_tags, student_special_needs
        ORDER BY student_dw_id DESC
    ) - 1 AS weekly_total_students,

    DENSE_RANK() OVER (
        PARTITION BY local_date, academic_year_start_date,
                     dse.section_dw_id, student_tags, student_special_needs
        ORDER BY student_dw_id ASC
    )
    + DENSE_RANK() OVER (
        PARTITION BY local_date, academic_year_start_date,
                     dse.section_dw_id, student_tags, student_special_needs
        ORDER BY student_dw_id DESC
    ) - 1 AS total_students,

    DENSE_RANK() OVER (
        PARTITION BY year_month, academic_year_start_date,
                     dse.section_dw_id, student_tags, student_special_needs
        ORDER BY student_dw_id ASC
    )
    + DENSE_RANK() OVER (
        PARTITION BY year_month, academic_year_start_date,
                     dse.section_dw_id, student_tags, student_special_needs
        ORDER BY student_dw_id DESC
    ) - 1 AS monthly_total_students,

    dsc.school_id AS school_id,
    dsc.organisation_dw_id AS org_dw_id,
    CONVERT(VARCHAR(50), NULL) AS org_term,
    CONVERT(DATE, NULL) AS term_start_date,
    CONVERT(DATE, NULL) AS term_end_date,

    CASE
        WHEN dh.holiday_date IS NULL THEN CONVERT(bit, 0)
        ELSE CONVERT(bit, 1)
    END AS holiday_flag,

    dse.year_month AS month_year_number,
    dse.wy_num AS week_year_number
FROM (
    SELECT
        section_alias,
        section_dw_id,
        grade_id,
        school_id,
        tenant_id,
        dd.local_date,
        dd.week_num,
        dd.uae_week_num,
        dd.wy_num,
        dd.uae_wy_num,
        dd.year_month
    FROM ${rs_coredw}.dim_section
    CROSS JOIN date_dimension dd
    WHERE school_id IS NOT NULL
) dse

INNER JOIN ${rs_bi_coredw}.bi_all_schools_dim dsc
    ON dsc.school_id = dse.school_id

INNER JOIN ${rs_bi_coredw}.bi_student_dim ds
    ON ds.student_section_dw_id = dse.section_dw_id
   AND (
        (
            student_status = 2
            AND local_date >= CONVERT(
                DATE,
                ds.student_created_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(dsc.windows_timezone,'UTC')
            )
            AND local_date < CONVERT(
                DATE,
                ds.student_active_until
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(dsc.windows_timezone,'UTC')
            )
        )
        OR (
            student_status = 1
            AND local_date >= CONVERT(
                DATE,
                ds.student_created_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(dsc.windows_timezone,'UTC')
            )
        )
    )

INNER JOIN ${rs_coredw}.dim_grade dg
    ON dse.grade_id = dg.grade_id
   AND dg.grade_dw_id = ds.student_grade_dw_id
   AND dg.academic_year_id = dsc.academic_year_id

LEFT JOIN holidays_dimension dh
    ON dh.holiday_date = dse.local_date
   AND dh.holiday_organisation_dw_id = dsc.organisation_dw_id

WHERE
(
    (
        school_status > 1
        AND local_date >= CONVERT(
            DATE,
            dsc.school_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dsc.windows_timezone,'UTC')
        )
        AND local_date <= CONVERT(
            DATE,
            dsc.school_updated_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dsc.windows_timezone,'UTC')
        )
    )
    OR (
        school_status = 1
        AND local_date >= CONVERT(
            DATE,
            dsc.school_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dsc.windows_timezone,'UTC')
        )
    )
)
AND local_date BETWEEN dsc.academic_year_start_date
                    AND dsc.academic_year_end_date;
 