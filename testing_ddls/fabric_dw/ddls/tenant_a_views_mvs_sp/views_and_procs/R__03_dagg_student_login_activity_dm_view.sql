CREATE OR ALTER VIEW ${os_bi_coredw}.dagg_student_login_activity_dm_view
AS
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

provisioned_students AS ( -- School Level
    SELECT
        student_first_created_date,
        student_school_dw_id,
        COUNT(DISTINCT student_dw_id) AS school_provisioned_students
    FROM ${rs_bi_coredw}.bi_student_dim
    GROUP BY
        student_first_created_date,
        student_school_dw_id
),

daily_active_students AS ( -- Section level
    SELECT DISTINCT
        dd.local_date,
        ds.student_section_dw_id,
        ds.student_tags,
        ds.student_special_needs AS special_needs,
        CONVERT(VARCHAR(4), YEAR(ay.academic_year_start_date))
        + '-' +
        CONVERT(VARCHAR(4), YEAR(ay.academic_year_end_date)) AS academic_year,

        DENSE_RANK() OVER (
            PARTITION BY
                dd.local_date,
                ay.academic_year_start_date,
                ds.student_section_dw_id,
                ds.student_tags,
                ds.student_special_needs
            ORDER BY sl.student_dw_id ASC
        )
        +
        DENSE_RANK() OVER (
            PARTITION BY
                dd.local_date,
                ay.academic_year_start_date,
                ds.student_section_dw_id,
                ds.student_tags,
                ds.student_special_needs
            ORDER BY sl.student_dw_id DESC
        ) - 1 AS active_students

    FROM ${rs_bi_coredw}.student_login sl
    INNER JOIN date_dimension dd
        ON CONVERT(DATE, sl.login_local_date_time) = dd.local_date
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
        ON dsc.school_dw_id = sl.school_dw_id
    INNER JOIN ${rs_bi_coredw}.bi_student_dim ds
        ON ds.student_dw_id = sl.student_dw_id
       AND (
            (ds.student_status = 2
             AND dd.local_date >= CONVERT(DATE, ds.student_created_time AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC'))
             AND dd.local_date <  CONVERT(DATE, ds.student_active_until AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')))
            OR
            (ds.student_status = 1
             AND dd.local_date >= CONVERT(DATE, ds.student_created_time AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')))
           )
    INNER JOIN ${rs_coredw}.dim_grade dg
        ON dg.grade_dw_id = ds.student_grade_dw_id
    INNER JOIN ${rs_coredw}.dim_academic_year ay
        ON ay.academic_year_id = dg.academic_year_id
       AND ay.academic_year_school_id = dsc.school_id
       AND dd.local_date BETWEEN ay.academic_year_start_date AND ay.academic_year_end_date
       AND ay.academic_year_status = 1
)

SELECT DISTINCT
    ts.local_date,
    ts.academic_year,
    ts.tenant_name,
    ts.school_dw_id,
    ts.school_id,
    ts.school_name,
    ts.school_created_time,
    ts.adek_id,
    ts.school_city_name,
    ts.school_organisation,
    ts.school_country_name,
    ts.school_composition,
    ts.school_latitude,
    ts.school_longitude,
    ts.school_label,
    ts.grade,

    CASE
        WHEN ts.class IS NULL OR ts.class = '' THEN ts.class
        ELSE UPPER(ts.class)
    END AS class,

    CASE
        WHEN ts.section IS NULL OR ts.section = '' THEN ts.section
        ELSE UPPER(ts.section)
    END AS section,

    ts.student_tags,
    ts.student_special_needs AS special_needs,
    ps.school_provisioned_students,
    ts.week_number,
    ts.week_year_number,
    ts.month_year_number,
    das.active_students,
    ts.total_students,
    ts.section_dw_id,
    ts.org_dw_id,
    ts.org_term,
    ts.term_start_date,
    ts.term_end_date,
    ts.holiday_flag,
    ts.school_cx_cluster

FROM ${rs_bi_coredw}.total_students ts
LEFT JOIN daily_active_students das
    ON ts.section_dw_id = das.student_section_dw_id
   AND ts.local_date = das.local_date
   AND ts.student_special_needs = das.special_needs
   AND ts.student_tags = das.student_tags
   AND ISNULL(ts.academic_year, 'NA') = ISNULL(das.academic_year, 'NA')
LEFT JOIN provisioned_students ps
    ON ts.school_dw_id = ps.student_school_dw_id
   AND ts.local_date = ps.student_first_created_date
WHERE ts.local_date <> CONVERT(DATE, '2022-01-03');