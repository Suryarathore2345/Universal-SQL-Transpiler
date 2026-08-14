DROP TABLE IF EXISTS ${os_bi_coredw}.students_stats_monthly;

CREATE TABLE ${os_bi_coredw}.students_stats_monthly 
AS
WITH calendar_year AS (
    SELECT DISTINCT
        calendar_year_start_date,
        calendar_year_end_date,
        calendar_month_start_date,
        calendar_month_end_date
    FROM ${rs_coredw}.dim_date
    WHERE calendar_month_start_date <= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0))
      AND YEAR(calendar_year_start_date) >= 2018
),
login_data AS (
    SELECT
           DATEADD(MONTH, DATEDIFF(MONTH, 0, login_local_date_time), 0) AS cy_month,
           CONVERT(DATE, login_local_date_time) AS login_date,
           ay.tenant_dw_id,
           ay.tenant_name_alias  AS tenant_name,
           ay.organisation_dw_id AS content_repository_dw_id,
           ay.school_organisation  AS content_repository_name,
           ay.academic_year_start_date,
           ay.academic_year_end_date,
           sl.student_dw_id,
           sl.school_dw_id
    FROM ${rs_bi_coredw}.student_login sl
    INNER JOIN ${rs_bi_coredw}.bi_student_dim ds
           ON ds.student_dw_id = sl.student_dw_id
    INNER JOIN ${rs_coredw}.dim_grade dg
           ON dg.grade_dw_id = ds.student_grade_dw_id
    INNER JOIN ${rs_bi_coredw}.bi_all_schools_dim ay
           ON ay.academic_year_id 
                = dg.academic_year_id 
          AND ay.school_id 
                = dg.school_id 
          AND sl.school_dw_id = ay.school_dw_id
    WHERE
        CONVERT(DATE, sl.login_local_date_time) BETWEEN ay.academic_year_start_date AND ay.academic_year_end_date
        AND (
                CONVERT(DATE, login_local_date_time) >= CONVERT(DATE, ds.student_created_time)
            AND (CONVERT(DATE, login_local_date_time) <= CONVERT(DATE, ds.student_active_until)
                 OR (ds.student_active_until IS NULL AND ds.student_status = 1))
        )
),
onboarding_data AS (
    SELECT
           tenant_dw_id,
           tenant_name,
           content_repository_dw_id,
           content_repository_name,
           academic_year_start_date,
           academic_year_end_date,
           student_dw_id,
           school_dw_id,
           MIN(login_date) AS first_login_date
    FROM login_data
    GROUP BY tenant_dw_id, tenant_name, content_repository_dw_id, content_repository_name, 
             academic_year_start_date, academic_year_end_date, student_dw_id, school_dw_id
)
SELECT
    reg.calendar_year_end_date,
    reg.calendar_month_end_date,
    reg.calendar_month_start_date,
    reg.tenant_dw_id,
    reg.tenant_name,
    reg.content_repository_dw_id,
    reg.content_repository_name,
    reg.school_city_name,
    reg.school_country_name,
    reg.academic_year_start_date,
    reg.academic_year_end_date,
    reg.AY,
    reg.student_dw_id,
    reg.school_dw_id,
    reg.school_name,
    reg.grade_name,
    reg.first_login_date,
    reg.is_active,
    CONVERT(DATETIME2(6), SYSDATETIME()) AS inserted_at
FROM (
    SELECT 
        cy.calendar_year_end_date,
        cy.calendar_month_end_date,
        cy.calendar_month_start_date,
        ay.tenant_dw_id,
        ay.tenant_name_alias  AS tenant_name,
        ay.organisation_dw_id AS content_repository_dw_id,
        ay.school_organisation  AS content_repository_name,
        sch.school_city_name  AS school_city_name,
        sch.school_country_name  AS school_country_name,
        ay.academic_year_start_date,
        ay.academic_year_end_date,
        CONVERT(VARCHAR, YEAR(ay.academic_year_start_date)) + '-' +
        CONVERT(VARCHAR, YEAR(ay.academic_year_end_date)) AS AY,
        ds.student_dw_id,
        sch.school_dw_id,
        sch.school_name  AS school_name,
        g.grade_name  AS grade_name,
        first_login_date,
        CASE WHEN COUNT(sl.student_dw_id) > 0 THEN 1 ELSE 0 END AS is_active
    FROM ${rs_coredw}.dim_student ds
    CROSS JOIN calendar_year cy
    INNER JOIN ${rs_coredw}.dim_grade g 
           ON ds.student_grade_dw_id = g.grade_dw_id
    INNER JOIN ${rs_coredw}.dim_school sch
           ON sch.school_id 
                = g.school_id 
          AND ds.student_school_dw_id = sch.school_dw_id
    INNER JOIN ${rs_bi_coredw}.bi_all_schools_dim ay
           ON ay.academic_year_id 
                = g.academic_year_id 
          AND ay.school_id 
                = g.school_id 
          AND ds.student_school_dw_id = ay.school_dw_id
    LEFT JOIN login_data sl 
           ON sl.student_dw_id = ds.student_dw_id
          AND sl.school_dw_id = ds.student_school_dw_id
          AND cy.calendar_month_start_date = sl.cy_month
          AND sl.academic_year_start_date = ay.academic_year_start_date
          AND sl.academic_year_end_date = ay.academic_year_end_date
    LEFT JOIN onboarding_data onb 
           ON onb.student_dw_id = ds.student_dw_id
          AND onb.school_dw_id = ds.student_school_dw_id
          AND onb.academic_year_start_date = ay.academic_year_start_date
          AND onb.academic_year_end_date = ay.academic_year_end_date
    WHERE (
            cy.calendar_month_start_date = DATEADD(MONTH, DATEDIFF(MONTH, 0, ds.student_created_time), 0)
        OR  cy.calendar_month_start_date = ds.student_active_until
        OR ( cy.calendar_month_start_date >= DATEADD(MONTH, DATEDIFF(MONTH, 0, ds.student_created_time), 0)
          AND cy.calendar_month_end_date <= DATEADD(MONTH, DATEDIFF(MONTH, 0, ds.student_active_until), 0) )
        OR ( ds.student_status = 1 
             AND ds.student_active_until IS NULL
             AND cy.calendar_month_start_date >= DATEADD(MONTH, DATEDIFF(MONTH, 0, student_created_time), 0)
           )
    )
    AND cy.calendar_month_start_date BETWEEN
            DATEADD(MONTH, DATEDIFF(MONTH, 0, ay.academic_year_start_date), 0)
        AND DATEADD(MONTH, DATEDIFF(MONTH, 0, ay.academic_year_end_date), 0)
    GROUP BY cy.calendar_year_end_date, cy.calendar_month_end_date, cy.calendar_month_start_date,
             ay.tenant_dw_id, ay.tenant_name_alias, ay.organisation_dw_id, ay.school_organisation,
             sch.school_city_name, sch.school_country_name, ay.academic_year_start_date, 
             ay.academic_year_end_date, ds.student_dw_id, sch.school_dw_id, sch.school_name,
             g.grade_name, first_login_date
) reg;
