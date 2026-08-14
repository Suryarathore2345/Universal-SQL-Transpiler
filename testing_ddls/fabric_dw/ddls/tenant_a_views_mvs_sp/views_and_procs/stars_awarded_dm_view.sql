CREATE OR ALTER VIEW ${os_bi_coredw}.stars_awarded_dm_view AS
SELECT DISTINCT 
    -- local date based on tenant timezone 
    CONVERT(
        DATE,
        (
            fsa.fsa_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
        )
    ) AS local_date,

    dsc.tenant_name,
    dsc.school_dw_id,
    dsc.school_id,
    dsc.school_name,
    dsc.school_organisation,
    dsc.school_country_name,
    dsc.school_city_name,
    dg.grade_k12grade AS grade,

    UPPER(ISNULL(dsu.subject_gen_subject, dc.class_gen_subject)) AS subject,

    ac.award_category_level_en AS award_category,
    ds.student_tags,
    ds.student_special_needs,
    dsc.school_label,

    CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_start_date)) + '-' +
    CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year,

    COUNT(DISTINCT fsa.fsa_id) AS stars_awarded
FROM ${rs_coredw}.fact_star_awarded fsa
JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
    ON dsc.school_dw_id = fsa.fsa_school_dw_id

JOIN ${rs_coredw}.dim_grade dg
    ON dg.grade_dw_id   = fsa.fsa_grade_dw_id
   AND dg.grade_status = 1

JOIN ${rs_bi_coredw}.bi_student_dim ds
    ON ds.student_dw_id = fsa.fsa_student_dw_id
   AND ds.student_status <> 4

JOIN ${rs_coredw}.dim_award_category ac
    ON ac.award_category_dw_id = fsa.fsa_award_category_dw_id

LEFT JOIN ${rs_coredw}.dim_class dc
    ON dc.class_dw_id = fsa.fsa_class_dw_id

LEFT JOIN ${rs_coredw}.dim_subject dsu
    ON dsu.subject_dw_id = fsa.fsa_subject_dw_id

WHERE
    dc.class_status = 1

    AND CONVERT(
            DATE,
            (
                fsa.fsa_created_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
            )
        ) BETWEEN dsc.academic_year_start_date
              AND dsc.academic_year_end_date

GROUP BY
    CONVERT(
        DATE,
        (
            fsa.fsa_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
        )
    ),
    dsc.tenant_name,
    dsc.school_dw_id,
    dsc.school_id,
    dsc.school_name,
    dsc.school_organisation,
    dsc.school_country_name,
    dsc.school_city_name,
    dg.grade_k12grade,
    UPPER(ISNULL(dsu.subject_gen_subject, dc.class_gen_subject)),
    ac.award_category_level_en,
    ds.student_tags,
    ds.student_special_needs,
    dsc.school_label,
    CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_start_date)) + '-' +
    CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_end_date));
