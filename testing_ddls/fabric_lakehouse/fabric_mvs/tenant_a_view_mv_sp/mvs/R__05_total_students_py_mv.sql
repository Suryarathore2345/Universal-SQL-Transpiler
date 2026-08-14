CREATE OR REPLACE MATERIALIZED LAKE VIEW {{os_bi_coredw}}.total_students_py_mv
AS
WITH date_dimension AS (
    SELECT DISTINCT
        full_date                  AS local_date,
        calendar_week_number       AS week_num,
        uae_week_number            AS uae_week_num,
        calendar_year_week_number  AS wy_num,
        uae_year_week_number       AS uae_wy_num,
        calendar_year_month_number AS year_month
    FROM {{rs_coredw}}.dim_date dt
    WHERE dt.full_date BETWEEN date_add(current_date(), -90) AND current_date()-- Date can be changed based on requirement
),

holidays_dimension AS (
    SELECT DISTINCT
        cast(holiday_date AS date) AS holiday_date,
        holiday_organisation_dw_id
    FROM {{rs_coredw}}.dim_holiday
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
    school_alias                                                AS adek_id,
    school_label,
    school_created_time,
    school_cx_cluster,
    concat(
        year(dsc.academic_year_start_date), '-',
        year(dsc.academic_year_end_date)
    )                                                           AS academic_year,
    grade_k12grade                                              AS grade,
    ''                                                          AS class,
    section_dw_id,
    UPPER(section_alias)                                      AS section,
    student_tags,
    student_special_needs,
    dse.week_num                                                AS week_number,
    DENSE_RANK() OVER (
        PARTITION BY wy_num, academic_year_start_date, dse.section_dw_id, student_tags, student_special_needs
        ORDER BY student_dw_id ASC
    ) +
    DENSE_RANK() OVER (
        PARTITION BY wy_num, academic_year_start_date, dse.section_dw_id, student_tags, student_special_needs
        ORDER BY student_dw_id DESC
    ) - 1                                                       AS weekly_total_students,
    DENSE_RANK() OVER (
        PARTITION BY local_date, academic_year_start_date, dse.section_dw_id, student_tags, student_special_needs
        ORDER BY student_dw_id ASC
    ) +
    DENSE_RANK() OVER (
        PARTITION BY local_date, academic_year_start_date, dse.section_dw_id, student_tags, student_special_needs
        ORDER BY student_dw_id DESC
    ) - 1                                                       AS total_students,
    DENSE_RANK() OVER (
        PARTITION BY year_month, academic_year_start_date, dse.section_dw_id, student_tags, student_special_needs
        ORDER BY student_dw_id ASC
    ) +
    DENSE_RANK() OVER (
        PARTITION BY year_month, academic_year_start_date, dse.section_dw_id, student_tags, student_special_needs
        ORDER BY student_dw_id DESC
    ) - 1                                                       AS monthly_total_students,
    dsc.school_id                                               AS school_id,
    dsc.organisation_dw_id                                      AS org_dw_id,
    CAST(NULL AS INT)                                           AS org_term,
    CAST(NULL AS DATE)                                          AS term_start_date,
    CAST(NULL AS DATE)                                          AS term_end_date,
    CASE
        WHEN holiday_date IS NULL THEN FALSE
        ELSE TRUE
    END                                                         AS holiday_flag,
    year_month                                                  AS month_year_number,
    wy_num                                                      AS week_year_number
FROM (
    SELECT section_alias, section_dw_id, grade_id, school_id, tenant_id, dd.*
    FROM {{rs_coredw}}.dim_section
    CROSS JOIN date_dimension dd
    WHERE school_id IS NOT NULL
) dse
INNER JOIN {{rs_bi_coredw}}.bi_all_schools_dim dsc
    ON dsc.school_id = dse.school_id
    AND (
        (
            school_status > 1
            AND local_date >= to_date(from_utc_timestamp(dsc.school_created_time, dsc.tenant_timezone))
            AND local_date <= to_date(from_utc_timestamp(dsc.school_updated_time, dsc.tenant_timezone))
        )
        OR (
            school_status = 1
            AND local_date >= to_date(from_utc_timestamp(dsc.school_created_time, dsc.tenant_timezone))
        )
    )
    AND (local_date >= dsc.academic_year_start_date AND local_date <= dsc.academic_year_end_date)
INNER JOIN {{rs_bi_coredw}}.bi_student_dim ds
    ON ds.student_section_dw_id = dse.section_dw_id
    AND (
        (
            student_status = 2
            AND local_date >= to_date(from_utc_timestamp(student_created_time, dsc.tenant_timezone))
            AND local_date <  to_date(from_utc_timestamp(student_active_until, dsc.tenant_timezone))
        )
        OR (
            student_status = 1
            AND local_date >= to_date(from_utc_timestamp(student_created_time, dsc.tenant_timezone))
        )
    )
INNER JOIN {{rs_coredw}}.dim_grade dg
    ON dse.grade_id = dg.grade_id
    AND dg.grade_dw_id = ds.student_grade_dw_id
    AND dsc.academic_year_id = dg.academic_year_id
LEFT JOIN holidays_dimension dh
    ON dh.holiday_date = dse.local_date
    AND dh.holiday_organisation_dw_id = dsc.organisation_dw_id;  