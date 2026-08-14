DROP TABLE IF EXISTS ${os_bi_coredw}.student_login_military_historical_data;

CREATE TABLE ${os_bi_coredw}.student_login_military_historical_data
AS
WITH calendar_year AS (
    SELECT DISTINCT
        full_date
    FROM ${rs_coredw}.dim_date
    WHERE
        full_date <= CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
        AND YEAR(full_date) >= YEAR(CONVERT(DATE, GETDATE())) - 5
),
login_data AS (
    SELECT DISTINCT
        CONVERT(DATE, sl.login_local_date_time) AS local_date,
        t.tenant_dw_id,
        t.tenant_name  AS tenant_name,
        ay.organisation_dw_id AS content_repository_dw_id,
        ds.student_grade_dw_id,
        ay.school_organisation  AS content_repository_name,
        sl.student_dw_id
    FROM ${rs_bi_coredw}.student_login sl
    INNER JOIN ${rs_coredw}.dim_tenant t
        ON t.tenant_dw_id = sl.tenant_dw_id
    INNER JOIN ${rs_bi_coredw}.bi_student_dim ds
        ON ds.student_dw_id = sl.student_dw_id
    INNER JOIN ${rs_coredw}.dim_grade dg
        ON dg.grade_dw_id = ds.student_grade_dw_id
    INNER JOIN ${rs_coredw}.dim_school sch
        ON sch.school_id = dg.school_id
       AND sch.school_dw_id = sl.school_dw_id
    INNER JOIN ${rs_bi_coredw}.bi_all_schools_dim ay
        ON ay.academic_year_id 
             = dg.academic_year_id 
       AND ay.school_dw_id = sch.school_dw_id
    WHERE
        sl.school_dw_id IN (2081, 2113, 2145)
        AND CONVERT(DATE, sl.login_local_date_time)
            BETWEEN ay.academic_year_start_date AND ay.academic_year_end_date
),
reg_data AS (
    SELECT DISTINCT
        CONVERT(VARCHAR(4), YEAR(ay.academic_year_start_date)) + '-' +
        CONVERT(VARCHAR(4), YEAR(ay.academic_year_end_date)) AS academic_year,
        ay.academic_year_start_date,
        ay.academic_year_end_date,
        sch.school_dw_id,
        sch.school_id,
        sch.school_name  AS school_name,
        t.tenant_dw_id,
        ds.student_dw_id AS reg_student_dw_id,
        ds.student_id AS reg_student_id,
        ay.organisation_dw_id AS content_repository_dw_id,
        ay.school_organisation  AS content_repository_name,
        cy.full_date AS local_date,
        t.tenant_name  AS tenant_name,
        g.grade_dw_id,
        g.grade_name  AS grade_name
    FROM ${rs_coredw}.dim_student ds
    CROSS JOIN calendar_year cy
    INNER JOIN ${rs_coredw}.dim_grade g
        ON ds.student_grade_dw_id = g.grade_dw_id
    INNER JOIN ${rs_coredw}.dim_school sch
        ON sch.school_id = g.school_id
       AND ds.student_school_dw_id = sch.school_dw_id
    INNER JOIN ${rs_bi_coredw}.bi_all_schools_dim ay
        ON ay.academic_year_id 
             = g.academic_year_id 
       AND ay.school_id 
             = g.school_id 
       AND ds.student_school_dw_id = ay.school_dw_id
    INNER JOIN ${rs_coredw}.dim_tenant t
        ON t.tenant_id = sch.school_tenant_id
    WHERE
        ds.student_school_dw_id IN (2081, 2113, 2145)
        AND (
            cy.full_date BETWEEN
                CONVERT(DATE,
                    ds.student_created_time
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(t.windows_timezone, 'UTC')
                )
                AND
                CONVERT(DATE,
                    ds.student_active_until
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(t.windows_timezone, 'UTC')
                )
            OR (
                ds.student_status = 1
                AND ds.student_active_until IS NULL
                AND cy.full_date >= CONVERT(DATE,
                    ds.student_created_time
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(t.windows_timezone, 'UTC')
                )
            )
        )
        AND cy.full_date BETWEEN ay.academic_year_start_date AND ay.academic_year_end_date
)
SELECT
    reg_data.academic_year,
    reg_data.academic_year_start_date,
    reg_data.academic_year_end_date,
    reg_data.school_dw_id,
    reg_data.school_id,
    reg_data.school_name,
    reg_data.tenant_dw_id,
    reg_data.reg_student_dw_id,
    reg_data.reg_student_id,
    reg_data.content_repository_dw_id,
    reg_data.content_repository_name,
    reg_data.local_date,
    reg_data.tenant_name,
    reg_data.grade_dw_id,
    reg_data.grade_name,
    log.student_dw_id AS log_student_dw_id,
    CONVERT(DATETIME2(6), SYSDATETIME()) AS inserted_at
FROM reg_data
LEFT JOIN login_data log
    ON log.tenant_dw_id = reg_data.tenant_dw_id
   AND log.local_date = reg_data.local_date
   AND reg_data.content_repository_dw_id = log.content_repository_dw_id
   AND reg_data.content_repository_name = log.content_repository_name
   AND reg_data.grade_dw_id = log.student_grade_dw_id
   AND reg_data.reg_student_dw_id = log.student_dw_id;
