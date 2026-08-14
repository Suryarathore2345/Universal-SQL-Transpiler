CREATE OR ALTER VIEW ${os_bi_coredw}.student_hourly_activity_dm_view AS
SELECT DISTINCT
    CONVERT(
        DATE,
        (
            sl.ful_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
        )
    ) AS local_date,

    CONVERT(
        FLOAT(53),
        DATEPART(
            HOUR,
            sl.ful_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
        )
    ) AS day_hour,

    ds.student_tags,
    ds.student_special_needs AS special_needs,

    CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_start_date)) + '-' +
    CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year,

    dse.section_dw_id,
    UPPER(dse.section_name) AS section,
    UPPER(dg.grade_k12grade) AS grade,

    dsc.tenant_name,
    dsc.school_dw_id,
    dsc.school_id,
    dsc.school_city_name,
    dsc.school_name,
    dsc.school_organisation,
    dsc.school_country_name,
    dsc.school_composition,
    dsc.school_latitude,
    dsc.school_longitude,
    dsc.school_alias AS adek_id,
    dsc.school_label,
    ts.total_students,

    COUNT(DISTINCT sl.ful_user_dw_id) AS active_students
FROM ${rs_coredw}.fact_user_login sl
INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
    ON dsc.school_dw_id = sl.ful_school_dw_id

INNER JOIN ${rs_bi_coredw}.bi_student_dim ds
    ON ds.student_dw_id = sl.ful_user_dw_id
INNER JOIN ${rs_coredw}.dim_section dse
    ON dse.section_dw_id = ds.student_section_dw_id
INNER JOIN ${rs_coredw}.dim_grade dg
    ON dse.grade_id = dg.grade_id
   AND dg.grade_dw_id = ds.student_grade_dw_id
   AND dsc.academic_year_id = dg.academic_year_id
INNER JOIN ${rs_bi_coredw}.total_students ts
    ON ts.section_dw_id = ds.student_section_dw_id
   AND ts.local_date =
       CONVERT(
           DATE,
           (
               sl.ful_created_time
                   AT TIME ZONE 'UTC'
                   AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
           )
       )
   AND ts.student_tags = ds.student_tags
   AND ts.student_special_needs = ds.student_special_needs
LEFT JOIN ${rs_coredw}.dim_tag dtg
    ON dtg.tag_association_id = dsc.school_id
WHERE sl.ful_role_dw_id = 2
  AND CONVERT(DATE,sl.ful_created_time) >= CONVERT(DATE, DATEADD(DAY, -90, GETDATE()))
  AND CONVERT(
        DATE,
        (
            sl.ful_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
        )
      ) BETWEEN dsc.academic_year_start_date
            AND dsc.academic_year_end_date
  AND (
        (
            ds.student_status = 2
            AND CONVERT(
                    DATE,
                    (
                        sl.ful_created_time
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
                    )
                ) >= CONVERT(
                    DATE,
                    (
                        ds.student_created_time
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
                    )
                )
            AND CONVERT(
                    DATE,
                    (
                        sl.ful_created_time
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
                    )
                ) < CONVERT(
                    DATE,
                    (
                        ds.student_active_until
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
                    )
                )
        )
        OR
        (
            ds.student_status = 1
            AND CONVERT(
                    DATE,
                    (
                        sl.ful_created_time
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
                    )
                ) >= CONVERT(
                    DATE,
                    (
                        ds.student_created_time
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
                    )
                )
        )
      )
GROUP BY
    CONVERT(
        DATE,
        (
            sl.ful_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
        )
    ),
    CONVERT(
        FLOAT(53),
        DATEPART(
            HOUR,
            sl.ful_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
        )
    ),
    ds.student_tags,
    ds.student_special_needs,
    CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_start_date)) + '-' +
    CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_end_date)),
    dse.section_dw_id,
    UPPER(dse.section_name),
    UPPER(dg.grade_k12grade),
    dsc.tenant_name,
    dsc.school_dw_id,
    dsc.school_id,
    dsc.school_city_name,
    dsc.school_name,
    dsc.school_organisation,
    dsc.school_country_name,
    dsc.school_composition,
    dsc.school_latitude,
    dsc.school_longitude,
    dsc.school_alias,
    dsc.school_label,
    ts.total_students;
