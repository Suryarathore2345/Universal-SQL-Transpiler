CREATE OR ALTER VIEW ${os_bi_coredw}.guardian_aggregared_alain_view AS
WITH calendar_year AS (
    SELECT
        a.week_start_date,
        a.week_end_date,
        CONVERT(DATE, DATEADD(year, DATEDIFF(year, 0, a.week_start_date), 0)) AS calendar_year_start_date,  -- OPT-1
        CONVERT(DATE,
            DATEADD(day, -1,
                DATEADD(year, 1, DATEADD(year, DATEDIFF(year, 0, a.week_start_date), 0))
            )
        ) AS calendar_year_end_date,  -- OPT-1
        CONVERT(DATE, DATEADD(month, DATEDIFF(month, 0, a.week_start_date), 0)) AS calendar_month_start_date,  -- OPT-1
        CONVERT(DATE,
            DATEADD(day, -1,
                DATEADD(month, 1, DATEADD(month, DATEDIFF(month, 0, a.week_start_date), 0))
            )
        ) AS calendar_month_end_date  -- OPT-1
    FROM (
        SELECT DISTINCT
            CONVERT(DATE, DATETRUNC(ISO_WEEK, full_date)) AS week_start_date,
            CONVERT(DATE, DATEADD(day, 6, DATETRUNC(ISO_WEEK, full_date))) AS week_end_date  -- OPT-1
        FROM ${rs_coredw}.dim_date
        WHERE CONVERT(DATE, DATETRUNC(ISO_WEEK, full_date)) <= CONVERT(DATE, GETDATE())
          AND full_date >= (
              SELECT MIN(activity_date)
              FROM ${rs_bi_coredw}.guardian_activity_dm_view
              WHERE academic_year IS NOT NULL
          )
    ) a
),

max_ay AS (
    SELECT school_dw_id, MAX(academic_year) AS max_ay
    FROM ${rs_bi_coredw}.guardian_activity_dm_view
    GROUP BY school_dw_id
)

SELECT
    cy.calendar_year_start_date,
    cy.calendar_year_end_date,
    cy.calendar_month_start_date,
    cy.calendar_month_end_date,
    cy.week_start_date,
    cy.week_end_date,
    ga.school_dw_id,
    ga.school_name,
    ga.tenant_name,
    ga.organisation_dw_id,
    ga.school_organisation,
    REPLACE(ay.max_ay, '-', ' - ') AS AY,
    ga.guardian_dw_id,
    ga.guardian_registered_date AS registered_date,
    COUNT(DISTINCT CASE WHEN ga.activity_date BETWEEN cy.week_start_date AND cy.week_end_date THEN ga.activity_date END) AS active_days
FROM calendar_year cy
CROSS JOIN ${rs_bi_coredw}.guardian_activity_dm_view ga
JOIN max_ay ay
    ON ga.school_dw_id = ay.school_dw_id
WHERE ga.guardian_registered_date <= cy.week_start_date
  AND ga.school_city_name = 'al ain'  -- OPT-4
GROUP BY
    cy.calendar_year_start_date,
    cy.calendar_year_end_date,
    cy.calendar_month_start_date,
    cy.calendar_month_end_date,
    cy.week_start_date,
    cy.week_end_date,
    ga.school_dw_id,
    ga.school_name,
    ga.tenant_name,
    ga.organisation_dw_id,
    ga.school_organisation,
    REPLACE(ay.max_ay, '-', ' - '),
    ga.guardian_dw_id,
    ga.guardian_registered_date;
