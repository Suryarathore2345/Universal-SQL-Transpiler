-- =============================================================================
-- Registered, onboarded and logged-in students on a monthly basis (IDN)
-- Student-level: one row per student per calendar_month_start_date (within AY).
-- Includes student grade. No aggregation.
-- Converted from Redshift to Fabric Spark SQL (Materialized Lake View)
-- =============================================================================
CREATE OR REPLACE MATERIALIZED LAKE VIEW {{os_bi_coredw}}.indonesia_student_login_mv AS
WITH calendar_year AS (
    SELECT DISTINCT
        calendar_year_start_date,
        calendar_year_end_date,
        calendar_month_start_date,
        calendar_month_end_date
    FROM {{rs_coredw}}.dim_date
    WHERE calendar_month_start_date <= DATE_TRUNC('month', DATE_SUB(CURRENT_DATE(), 1))
      AND YEAR(calendar_year_start_date) >= 2023
),

login_data AS (
    SELECT
        DATE_TRUNC('month', login_local_date_time)          AS login_month,
        DATE(login_local_date_time)                         AS login_date,
        ay.tenant_dw_id,
        ay.tenant_name_alias                                AS tenant_name,
        ay.organisation_dw_id                               AS content_repository_dw_id,
        ay.school_organisation                              AS content_repository_name,
        ay.academic_year_start_date,
        ay.academic_year_end_date,
        sl.student_dw_id,
        sl.school_dw_id,
        ds.student_grade_dw_id
    FROM {{rs_bi_coredw}}.student_login sl
    INNER JOIN {{rs_bi_coredw}}.bi_student_dim ds
        ON ds.student_dw_id = sl.student_dw_id
    INNER JOIN {{rs_coredw}}.dim_grade dg
        ON dg.grade_dw_id = ds.student_grade_dw_id
    INNER JOIN {{rs_coredw}}.dim_school dsch
        ON dsch.school_dw_id = ds.student_school_dw_id
    INNER JOIN {{rs_bi_coredw}}.bi_all_schools_dim ay
        ON dsch.school_dw_id = ay.school_dw_id
       AND sl.school_dw_id = ay.school_dw_id
       AND sl.tenant_dw_id = ay.tenant_dw_id
    WHERE LOWER(ay.tenant_name) = 'idn'
      AND YEAR(ay.academic_year_start_date) >= 2023
      AND DATE(sl.login_local_date_time)
          BETWEEN ay.academic_year_start_date AND ay.academic_year_end_date
      AND (
            (ds.student_status IN (2, 3, 4)
             AND DATE(login_local_date_time) >= DATE(
                                                    CONVERT_TIMEZONE(
                                                        'UTC',
                                                        dsch.school_timezone,
                                                        ds.student_created_time
                                                    )
                                                )
             AND DATE(login_local_date_time) < DATE(
                     CONVERT_TIMEZONE('UTC', dsch.school_timezone, ds.student_active_until))
            )
         OR (ds.student_status = 1
             AND DATE(login_local_date_time) >= DATE(
                        CONVERT_TIMEZONE(
                            'UTC',
                            dsch.school_timezone,
                            ds.student_created_time
                        )
                    )
            )
          )
),

student_registrations AS (
    SELECT DISTINCT
        str.student_dw_id,
        str.student_school_dw_id,
        str.academic_year_start_date,
        str.academic_year_end_date,
        CONCAT(
            CAST(YEAR(str.academic_year_start_date) AS STRING),
            '-',
            CAST(YEAR(str.academic_year_end_date) AS STRING)
        )                                                   AS academic_year,
        str.student_grade_dw_id,
        str.tenant_dw_id,
        str.organisation_dw_id,
        str.student_status,
        DATE(str.student_first_created_date)                AS student_first_created_date
    FROM (
        SELECT
            dst.student_dw_id,
            dst.student_school_dw_id,
            dsc.academic_year_start_date,
            dsc.academic_year_end_date,
            dst.student_grade_dw_id,
            dsc.tenant_dw_id,
            dsc.organisation_dw_id,
            MAX(dst.student_status)                         AS student_status,
            MIN(DATE(dst.student_created_time))             AS student_first_created_date
        FROM {{rs_coredw}}.dim_student dst
        INNER JOIN {{rs_coredw}}.dim_grade dg
            ON dg.grade_dw_id = dst.student_grade_dw_id
        INNER JOIN {{rs_bi_coredw}}.bi_all_schools_dim dsc
            ON dsc.academic_year_id = dg.academic_year_id
           AND dsc.school_id = dg.school_id
           AND dst.student_school_dw_id = dsc.school_dw_id
        WHERE YEAR(dsc.academic_year_start_date) >= 2023
          AND LOWER(dsc.tenant_name) = 'idn'
        GROUP BY
            dst.student_dw_id,
            dst.student_school_dw_id,
            dsc.academic_year_start_date,
            dsc.academic_year_end_date,
            dst.student_grade_dw_id,
            dsc.organisation_dw_id,
            dsc.tenant_dw_id
    ) str
),

onboarding_data AS (
    SELECT
        DATE(DATE_TRUNC('month', login_date))               AS onb_month,
        tenant_dw_id,
        tenant_name,
        content_repository_dw_id,
        content_repository_name,
        academic_year_start_date,
        academic_year_end_date,
        student_dw_id,
        school_dw_id,
        student_grade_dw_id,
        MIN(login_date)                                     AS student_first_login_date
    FROM login_data
    GROUP BY
        DATE(DATE_TRUNC('month', login_date)),
        tenant_dw_id,
        tenant_name,
        content_repository_dw_id,
        content_repository_name,
        academic_year_start_date,
        academic_year_end_date,
        student_dw_id,
        school_dw_id,
        student_grade_dw_id
),

-- Spine: one row per student per calendar month (within that student's AY)
student_month_spine AS (
    SELECT
        cy.calendar_month_start_date,
        cy.calendar_month_end_date,
        str.student_dw_id,
        str.student_school_dw_id                            AS school_dw_id,
        str.academic_year_start_date,
        str.academic_year_end_date,
        str.academic_year,
        str.student_grade_dw_id,
        str.tenant_dw_id,
        str.organisation_dw_id,
        str.student_status,
        str.student_first_created_date
    FROM student_registrations str
    INNER JOIN calendar_year cy
        ON cy.calendar_month_start_date
           BETWEEN DATE_TRUNC('month', str.academic_year_start_date)
               AND DATE_TRUNC('month', str.academic_year_end_date)
    WHERE str.student_first_created_date IS NOT NULL
      AND str.student_first_created_date
          BETWEEN str.academic_year_start_date AND str.academic_year_end_date
)

SELECT DISTINCT
    sms.calendar_month_start_date,
    sms.calendar_month_end_date,
    dsc.school_name,
    dsc.school_dw_id,
    dsc.tenant_dw_id,
    dsc.tenant_name,
    dsc.organisation_dw_id                                  AS org_dw_id,
    dsc.school_organisation                                  AS organization_name,
    dsc.school_city_name,
    dsc.school_label,
    dsc.school_country_name,
    dsc.academic_year_id,
    dsc.academic_year_start_date,
    dsc.academic_year_end_date,
    sms.academic_year,
    dst.student_dw_id,
    dst.student_id,
    sms.student_status,
    g.grade_dw_id,
    g.grade_name,
    g.grade_id,
    CASE
        WHEN DATE_TRUNC('month', sms.student_first_created_date) = sms.calendar_month_start_date
            THEN 1
        ELSE 0
    END                                                      AS is_registered,
    CASE
        WHEN onb.student_first_login_date IS NOT NULL
         AND DATE_TRUNC('month', onb.student_first_login_date) = sms.calendar_month_start_date
            THEN 1
        ELSE 0
    END                                                      AS is_onboarded,
    CASE WHEN sl.student_dw_id IS NOT NULL THEN 1 ELSE 0 END AS is_active,
    CASE WHEN sl_next_month.student_dw_id IS NOT NULL THEN 1 ELSE 0 END AS is_active_next_month

FROM student_month_spine sms

INNER JOIN {{rs_coredw}}.dim_student dst
    ON dst.student_dw_id = sms.student_dw_id
   AND dst.student_school_dw_id = sms.school_dw_id

INNER JOIN {{rs_bi_coredw}}.bi_all_schools_dim dsc
    ON dsc.school_dw_id = sms.school_dw_id
   AND dsc.academic_year_start_date = sms.academic_year_start_date
   AND dsc.academic_year_end_date = sms.academic_year_end_date
   AND LOWER(dsc.tenant_name) = 'idn'

INNER JOIN {{rs_coredw}}.dim_grade g
    ON g.grade_dw_id = sms.student_grade_dw_id
   AND g.school_id = dsc.school_id
   AND g.academic_year_id = dsc.academic_year_id

LEFT JOIN onboarding_data onb
    ON onb.student_dw_id = sms.student_dw_id
   AND onb.school_dw_id = sms.school_dw_id
   AND onb.student_grade_dw_id = sms.student_grade_dw_id
   AND onb.onb_month = sms.calendar_month_start_date
   AND onb.academic_year_start_date = sms.academic_year_start_date
   AND onb.academic_year_end_date = sms.academic_year_end_date

LEFT JOIN (
    SELECT DISTINCT
        student_dw_id,
        school_dw_id,
        student_grade_dw_id,
        login_month                                          AS calendar_month_start_date,
        academic_year_start_date,
        academic_year_end_date
    FROM login_data
) sl
    ON sl.student_dw_id = sms.student_dw_id
   AND sl.school_dw_id = sms.school_dw_id
   AND sl.student_grade_dw_id = sms.student_grade_dw_id
   AND sl.calendar_month_start_date = sms.calendar_month_start_date
   AND sl.academic_year_start_date = sms.academic_year_start_date
   AND sl.academic_year_end_date = sms.academic_year_end_date

LEFT JOIN (
    SELECT DISTINCT
        student_dw_id,
        school_dw_id,
        student_grade_dw_id,
        login_month                                          AS calendar_month_start_date,
        academic_year_start_date,
        academic_year_end_date
    FROM login_data
) sl_next_month
    ON sl_next_month.student_dw_id = sms.student_dw_id
   AND sl_next_month.school_dw_id = sms.school_dw_id
   AND sl_next_month.student_grade_dw_id = sms.student_grade_dw_id
   AND sl_next_month.calendar_month_start_date =
       DATE(ADD_MONTHS(sms.calendar_month_start_date, 1))
   AND sl_next_month.academic_year_start_date = sms.academic_year_start_date
   AND sl_next_month.academic_year_end_date = sms.academic_year_end_date;
