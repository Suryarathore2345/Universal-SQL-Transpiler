DROP TABLE IF EXISTS ${os_bi_coredw}.teacher_stats_monthly;

CREATE TABLE ${os_bi_coredw}.teacher_stats_monthly
AS
WITH calendar_year AS (
    SELECT DISTINCT
        calendar_year_start_date,
        calendar_year_end_date,
        calendar_month_start_date,
        calendar_month_end_date
    FROM ${rs_coredw}.dim_date
    WHERE
        calendar_month_start_date <= DATEADD(
            DAY, -1,
            DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
        )
        AND YEAR(calendar_year_start_date) >= 2018
),
login_data AS (
    SELECT
        DATEADD(MONTH, DATEDIFF(MONTH, 0, tl.login_local_date_time), 0) AS cy_month,
        CONVERT(DATE, tl.login_local_date_time) AS login_date,
        ay.tenant_dw_id,
        ay.tenant_name_alias  AS tenant_name,
        ay.academic_year_end_date,
        ay.academic_year_start_date,
        ay.organisation_dw_id AS content_repository_dw_id,
        ay.school_organisation  AS content_repository_name,
        tl.school_dw_id,
        tl.teacher_dw_id
    FROM ${rs_bi_coredw}.teacher_login tl
    JOIN ${rs_coredw}.dim_teacher dt
        ON dt.teacher_school_dw_id = tl.school_dw_id
       AND dt.teacher_dw_id = tl.teacher_dw_id
    JOIN ${rs_coredw}.dim_school sch
        ON sch.school_dw_id = dt.teacher_school_dw_id
    JOIN ${rs_bi_coredw}.bi_all_schools_dim ay
        ON ay.school_id 
             = sch.school_id 
       AND dt.teacher_school_dw_id = ay.school_dw_id
       AND CONVERT(DATE, tl.login_local_date_time)
           BETWEEN ay.academic_year_start_date AND ay.academic_year_end_date
    WHERE dt.teacher_id NOT IN (
        SELECT DISTINCT teacher_id
        FROM ${rs_bi_coredw}.exclude_teacher_id
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
        teacher_dw_id,
        school_dw_id,
        MIN(login_date) AS first_login_date
    FROM login_data
    GROUP BY
        tenant_dw_id, tenant_name,
        content_repository_dw_id, content_repository_name,
        academic_year_start_date, academic_year_end_date,
        teacher_dw_id, school_dw_id
)
SELECT
    reg.calendar_year_end_date,
    reg.calendar_month_end_date,
    reg.calendar_month_start_date,
    reg.tenant_dw_id,
    reg.tenant_name,
    reg.content_repository_dw_id,
    reg.content_repository_name,
    reg.academic_year_start_date,
    reg.academic_year_end_date,
    reg.AY,
    reg.teacher_dw_id,
    reg.school_dw_id,
    reg.school_name,
    reg.school_city_name,
    reg.school_country_name,
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
        ay.academic_year_start_date,
        ay.academic_year_end_date,
        CONVERT(VARCHAR(4), YEAR(ay.academic_year_start_date)) + '-' +
        CONVERT(VARCHAR(4), YEAR(ay.academic_year_end_date)) AS AY,
        dt.teacher_dw_id,
        sch.school_dw_id,
        sch.school_name  AS school_name,
        sch.school_city_name  AS school_city_name,
        sch.school_country_name  AS school_country_name,
        first_login_date,
        CASE WHEN COUNT(sl.teacher_dw_id) > 0 THEN 1 ELSE 0 END AS is_active
    FROM ${rs_coredw}.dim_teacher dt
    CROSS JOIN calendar_year cy
    INNER JOIN ${rs_coredw}.dim_school sch
        ON dt.teacher_school_dw_id = sch.school_dw_id
    INNER JOIN ${rs_bi_coredw}.bi_all_schools_dim ay
        ON ay.school_id 
             = sch.school_id 
       AND dt.teacher_school_dw_id = ay.school_dw_id
    LEFT JOIN login_data sl
        ON sl.teacher_dw_id = dt.teacher_dw_id
       AND sl.school_dw_id = dt.teacher_school_dw_id
       AND cy.calendar_month_start_date = sl.cy_month
       AND sl.academic_year_start_date = ay.academic_year_start_date
       AND sl.academic_year_end_date = ay.academic_year_end_date
    LEFT JOIN onboarding_data onb
        ON onb.teacher_dw_id = dt.teacher_dw_id
       AND onb.school_dw_id = dt.teacher_school_dw_id
       AND onb.academic_year_start_date = ay.academic_year_start_date
       AND onb.academic_year_end_date = ay.academic_year_end_date
    WHERE
        (
            cy.calendar_month_start_date = DATEADD(
                MONTH,
                DATEDIFF(MONTH, 0, dt.teacher_created_time),
                0
            )
            OR cy.calendar_month_end_date = DATEADD(
                MONTH,
                DATEDIFF(MONTH, 0, dt.teacher_active_until),
                0
            )
            OR (
                cy.calendar_month_start_date >= DATEADD(
                    MONTH,
                    DATEDIFF(MONTH, 0, dt.teacher_created_time),
                    0
                )
                AND cy.calendar_month_end_date <= DATEADD(
                    MONTH,
                    DATEDIFF(MONTH, 0, dt.teacher_active_until),
                    0
                )
            )
            OR (
                dt.teacher_active_until IS NULL
                AND dt.teacher_status = 1
                AND cy.calendar_year_end_date >= DATEADD(
                    MONTH,
                    DATEDIFF(MONTH, 0, dt.teacher_created_time),
                    0
                )
            )
        )
        AND (
            sch.school_status = 1
            OR DATEADD(
                MONTH,
                DATEDIFF(MONTH, 0, sch.school_updated_time),
                0
            ) >= cy.calendar_month_start_date
        )
        AND cy.calendar_month_start_date BETWEEN
            DATEADD(MONTH, DATEDIFF(MONTH, 0, ay.academic_year_start_date), 0)
            AND DATEADD(MONTH, DATEDIFF(MONTH, 0, ay.academic_year_end_date), 0)
    GROUP BY
        cy.calendar_year_end_date,
        cy.calendar_month_end_date,
        cy.calendar_month_start_date,
        ay.tenant_dw_id,
        ay.tenant_name_alias,
        ay.organisation_dw_id,
        ay.school_organisation,
        ay.academic_year_start_date,
        ay.academic_year_end_date,
        dt.teacher_dw_id,
        sch.school_dw_id,
        sch.school_name,
        sch.school_city_name,
        sch.school_country_name,
        first_login_date
) reg;
