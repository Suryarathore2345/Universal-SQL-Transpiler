CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_alain_students_login
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.alain_students_login_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.alain_students_login_staging
        WITH (CLUSTER BY (school_dw_id, student_dw_id))
        AS
        WITH calendar_year AS (
            SELECT
                a.week_start_date,
                a.week_end_date,
                CONVERT(DATE, DATETRUNC(year, week_start_date))     AS calendar_year_start_date,
                CAST(DATEADD(DAY, -1, DATEADD(MONTH, 12, DATETRUNC(year, week_start_date))) AS DATE) AS calendar_year_end_date,
                CONVERT(DATE, DATETRUNC(month, week_start_date))    AS calendar_month_start_date,
                CAST(DATEADD(DAY, -1, DATEADD(MONTH, 1, DATETRUNC(month, week_start_date))) AS DATE) AS calendar_month_end_date
            FROM (
                SELECT DISTINCT
                    CONVERT(DATE, DATETRUNC(iso_week, full_date))   AS week_start_date,
                    DATEADD(DAY, 6, CONVERT(DATE, DATETRUNC(iso_week, full_date))) AS week_end_date
                FROM ${rs_coredw}.dim_date
                WHERE DATETRUNC(iso_week, full_date) <= CONVERT(DATE, GETDATE())
                  AND calendar_year_start_date >= DATEADD(DAY, 0, DATEADD(MONTH, -24, DATETRUNC(year, GETDATE())))
            ) AS a
        ),
        prev_academic_year AS (
            SELECT
                CAST(DATEADD(MONTH, -12, DATETRUNC(year, MAX(academic_year_start_date))) AS DATE) AS prev_AY
            FROM ${rs_bi_coredw}.bi_all_schools_dim
            WHERE school_city_name = 'al ain'
        ),
        login_data AS (
            SELECT
                DATETRUNC(month, sl.login_local_date_time)                      AS cy_month,
                DATETRUNC(iso_week, sl.login_local_date_time)                   AS cy_week_start,
                DATEADD(DAY, 6, DATETRUNC(iso_week, sl.login_local_date_time)) AS cy_week_end,
                CONVERT(DATE, sl.login_local_date_time)                         AS login_date,
                ay.tenant_dw_id,
                ay.tenant_name_alias                                            AS tenant_name,
                ay.organisation_dw_id                                           AS content_repository_dw_id,
                ay.school_organisation                                          AS content_repository_name,
                ay.academic_year_start_date,
                ay.academic_year_end_date,
                sl.student_dw_id,
                sl.school_dw_id,
                sec.section_name,
                sec.section_dw_id
            FROM ${rs_bi_coredw}.student_login AS sl
            INNER JOIN ${rs_bi_coredw}.bi_student_dim AS ds
                ON ds.student_dw_id = sl.student_dw_id
            INNER JOIN ${rs_coredw}.dim_grade AS dg
                ON dg.grade_dw_id = ds.student_grade_dw_id
            INNER JOIN ${rs_coredw}.dim_section AS sec
                ON ds.student_section_dw_id = sec.section_dw_id
            INNER JOIN ${rs_bi_coredw}.bi_all_schools_dim AS ay
                ON ay.academic_year_id = dg.academic_year_id
               AND ay.school_id        = dg.school_id
               AND sl.school_dw_id     = ay.school_dw_id
            CROSS JOIN prev_academic_year AS pv
            WHERE CONVERT(DATE, sl.login_local_date_time)
                      BETWEEN ay.academic_year_start_date AND ay.academic_year_end_date
                AND (
                    CONVERT(DATE, sl.login_local_date_time) >= CONVERT(DATE, ds.student_created_time)
                    AND (
                        CONVERT(DATE, sl.login_local_date_time) <= CONVERT(DATE, ds.student_active_until)
                        OR (ds.student_active_until IS NULL AND ds.student_status = 1)
                    )
                )
                AND ay.school_city_name = 'al ain'
                AND CONVERT(DATE, sl.login_local_date_time) >= pv.prev_AY
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
            GROUP BY
                tenant_dw_id, tenant_name, content_repository_dw_id, content_repository_name,
                academic_year_start_date, academic_year_end_date, student_dw_id, school_dw_id
        )
        SELECT
            reg.calendar_year_end_date,
            reg.calendar_month_end_date,
            reg.calendar_month_start_date,
            reg.week_start_date,
            reg.week_end_date,
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
            reg.section_dw_id,
            reg.section_name,
            reg.first_login_date,
            reg.is_active,
            reg.active_days,
            CONVERT(DATETIME2(6), GETDATE()) AS inserted_at
        FROM (
            SELECT
                cy.calendar_year_end_date,
                cy.calendar_month_end_date,
                cy.calendar_month_start_date,
                cy.week_start_date,
                cy.week_end_date,
                ay.tenant_dw_id,
                ay.tenant_name_alias                                                AS tenant_name,
                ay.organisation_dw_id                                               AS content_repository_dw_id,
                ay.school_organisation                                              AS content_repository_name,
                sch.school_city_name,
                sch.school_country_name,
                ay.academic_year_start_date,
                ay.academic_year_end_date,
                CONVERT(VARCHAR(15),
                    CONCAT(
                        CONVERT(VARCHAR(4), YEAR(ay.academic_year_start_date)),
                        ' - ',
                        CONVERT(VARCHAR(4), YEAR(ay.academic_year_end_date))
                    )
                )                                                                   AS AY,
                ds.student_dw_id,
                sch.school_dw_id,
                sch.school_name,
                g.grade_name,
                sec.section_dw_id,
                sec.section_name,
                onb.first_login_date,
                CASE WHEN COUNT(sl.student_dw_id) > 0 THEN 1 ELSE 0 END            AS is_active,
                COUNT(DISTINCT CONVERT(DATE, sl.login_date))                        AS active_days
            FROM ${rs_coredw}.dim_student AS ds
            CROSS JOIN calendar_year AS cy
            CROSS JOIN prev_academic_year AS pv
            INNER JOIN ${rs_coredw}.dim_grade AS g
                ON ds.student_grade_dw_id = g.grade_dw_id
            INNER JOIN ${rs_coredw}.dim_section AS sec
                ON ds.student_section_dw_id = sec.section_dw_id
            INNER JOIN ${rs_coredw}.dim_school AS sch
                ON sch.school_id           = g.school_id
               AND ds.student_school_dw_id = sch.school_dw_id
            INNER JOIN ${rs_bi_coredw}.bi_all_schools_dim AS ay
                ON ay.academic_year_id     = g.academic_year_id
               AND ay.school_id            = g.school_id
               AND ds.student_school_dw_id = ay.school_dw_id
               AND ay.school_city_name = 'al ain'
            LEFT JOIN login_data AS sl
                ON sl.student_dw_id             = ds.student_dw_id
               AND sl.school_dw_id              = ds.student_school_dw_id
               AND cy.week_start_date           = CONVERT(DATE, sl.cy_week_start)
               AND sl.academic_year_start_date  = ay.academic_year_start_date
               AND sl.academic_year_end_date    = ay.academic_year_end_date
            LEFT JOIN onboarding_data AS onb
                ON onb.student_dw_id            = ds.student_dw_id
               AND onb.school_dw_id             = ds.student_school_dw_id
               AND onb.academic_year_start_date = ay.academic_year_start_date
               AND onb.academic_year_end_date   = ay.academic_year_end_date
            WHERE
                (
                    cy.week_start_date = CONVERT(DATE, DATETRUNC(iso_week, ds.student_created_time))
                    OR cy.week_start_date = ds.student_active_until
                    OR (
                        cy.week_start_date >= CONVERT(DATE, DATETRUNC(iso_week, ds.student_created_time))
                        AND cy.week_end_date <= CONVERT(DATE, DATETRUNC(iso_week, ds.student_active_until))
                    )
                    OR (
                        ds.student_status = 1
                        AND ds.student_active_until IS NULL
                        AND cy.week_start_date >= CONVERT(DATE, DATETRUNC(iso_week, ds.student_created_time))
                    )
                )
                AND cy.week_start_date BETWEEN
                    CONVERT(DATE, DATETRUNC(iso_week, ay.academic_year_start_date))
                    AND CONVERT(DATE, DATETRUNC(iso_week, ay.academic_year_end_date))
                AND ay.academic_year_start_date >= pv.prev_AY
            GROUP BY
                cy.calendar_year_end_date, cy.calendar_month_end_date, cy.calendar_month_start_date,
                cy.week_start_date, cy.week_end_date, ay.tenant_dw_id, ay.tenant_name_alias,
                ay.organisation_dw_id, ay.school_organisation, sch.school_city_name,
                sch.school_country_name, ay.academic_year_start_date, ay.academic_year_end_date,
                CONVERT(VARCHAR(9),
                    CONCAT(
                        CONVERT(VARCHAR(4), YEAR(ay.academic_year_start_date)), ' - ',
                        CONVERT(VARCHAR(4), YEAR(ay.academic_year_end_date))
                    )
                ),
                ds.student_dw_id, sch.school_dw_id, sch.school_name, g.grade_name,
                sec.section_dw_id, sec.section_name, onb.first_login_date
        ) AS reg;

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.alain_students_login;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.alain_students_login_staging', 'alain_students_login';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
