CREATE OR ALTER VIEW ${os_bi_coredw}.guardian_activity_dm_view
AS
WITH guardian_info AS (
    SELECT DISTINCT
        dg.guardian_dw_id,
        dsc.school_dw_id,
        dsc.school_id,
        dsc.school_name,
        dsc.school_city_name,
        dsc.school_country_name,
        dsc.school_composition,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dsc.tenant_name,
        dsc.school_label,

        FIRST_VALUE(dg.guardian_created_time)
            OVER (
                PARTITION BY dg.guardian_dw_id
                ORDER BY dg.guardian_created_time
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) AS guardian_registered_date

    FROM ${rs_coredw}.dim_guardian dg
    INNER JOIN (
        SELECT DISTINCT
            student_dw_id,
            student_school_dw_id
        FROM ${rs_bi_coredw}.bi_student_dim
        WHERE student_status = 1
    ) ds
        ON ds.student_dw_id = dg.guardian_student_dw_id
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
        ON dsc.school_dw_id = ds.student_school_dw_id
    WHERE dg.guardian_status = 1
      AND dg.guardian_invitation_status = 2
      AND dg.guardian_student_dw_id IS NOT NULL
)

SELECT DISTINCT
    gi.guardian_dw_id,
    gi.school_dw_id,
    gi.school_id,
    gi.school_name,
    gi.school_city_name,
    gi.school_country_name,
    gi.school_composition,
    gi.school_organisation,
    gi.organisation_dw_id,
    gi.tenant_name,
    gi.school_label,
    gi.guardian_registered_date,

    ga.activity_date,

    LAG(ga.activity_date, 1)
        OVER (
            PARTITION BY gi.school_dw_id, gi.guardian_dw_id
            ORDER BY ga.activity_date ASC
        ) AS previous_activity_date,

    ga.academic_year,
    ga.academic_year_start_date,
    ga.academic_year_end_date

FROM guardian_info gi
LEFT JOIN (
    SELECT DISTINCT
        fgaa.fgaa_guardian_dw_id,
        fgaa.fgaa_school_dw_id,
        dt.academic_year_start_date,
        dt.academic_year_end_date,

        CONVERT(VARCHAR(4), YEAR(dt.academic_year_start_date))
        + '-'
        + CONVERT(VARCHAR(4), YEAR(dt.academic_year_end_date)) AS academic_year,

        CONVERT(
            DATE,
            fgaa.fgaa_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
        ) AS activity_date

    FROM ${rs_coredw}.fact_guardian_app_activities fgaa
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim dt
        ON dt.school_dw_id = fgaa.fgaa_school_dw_id

    WHERE CONVERT(
               DATE,
               fgaa.fgaa_created_time
                   AT TIME ZONE 'UTC'
                   AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
           ) >= dt.academic_year_start_date
       AND CONVERT(
               DATE,
               fgaa.fgaa_created_time
                   AT TIME ZONE 'UTC'
                   AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
           ) <= dt.academic_year_end_date
) ga
    ON gi.guardian_dw_id = ga.fgaa_guardian_dw_id
   AND gi.school_dw_id   = ga.fgaa_school_dw_id;
