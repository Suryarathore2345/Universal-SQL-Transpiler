CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_alain_teachers_login
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        IF OBJECT_ID('${os_bi_coredw}.alain_teachers_login_staging') IS NOT NULL
            DROP TABLE IF EXISTS ${os_bi_coredw}.alain_teachers_login_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.alain_teachers_login_staging
        WITH (CLUSTER BY (school_dw_id, teacher_dw_id))
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
                CONVERT(DATE, DATETRUNC(month, tl.login_local_date_time))             AS cy_month,
                CONVERT(DATE, DATETRUNC(iso_week, tl.login_local_date_time))           AS cy_week_start,
                DATEADD(DAY, 6, CONVERT(DATE, DATETRUNC(iso_week, tl.login_local_date_time))) AS cy_week_end,
                CONVERT(DATE, tl.login_local_date_time)                                AS login_date,
                ay.tenant_dw_id,
                ay.tenant_name_alias                                                   AS tenant_name,
                ay.academic_year_end_date,
                ay.academic_year_start_date,
                ay.organisation_dw_id                                                  AS content_repository_dw_id,
                ay.school_organisation                                                 AS content_repository_name,
                tl.school_dw_id,
                tl.teacher_dw_id
            FROM ${rs_bi_coredw}.teacher_login AS tl
            JOIN ${rs_coredw}.dim_teacher AS dt
                ON dt.teacher_school_dw_id = tl.school_dw_id
               AND dt.teacher_dw_id        = tl.teacher_dw_id
            JOIN ${rs_coredw}.dim_school AS sch
                ON sch.school_dw_id        = dt.teacher_school_dw_id
            JOIN ${rs_bi_coredw}.bi_all_schools_dim AS ay
                ON ay.school_id            = sch.school_id
               AND dt.teacher_school_dw_id = ay.school_dw_id
               AND CONVERT(DATE, tl.login_local_date_time)
                   BETWEEN ay.academic_year_start_date AND ay.academic_year_end_date
            CROSS JOIN prev_academic_year AS pv
            WHERE dt.teacher_id NOT IN (
                      SELECT DISTINCT teacher_id
                      FROM ${rs_bi_coredw}.exclude_teacher_id
                  )
              AND ay.school_city_name = 'al ain'
              AND CONVERT(DATE, tl.login_local_date_time) >= pv.prev_AY
        ),
        onboarding_data AS (
            SELECT
                tenant_dw_id, tenant_name, content_repository_dw_id, content_repository_name,
                academic_year_start_date, academic_year_end_date,
                teacher_dw_id, school_dw_id,
                MIN(login_date) AS first_login_date
            FROM login_data
            GROUP BY
                tenant_dw_id, tenant_name, content_repository_dw_id, content_repository_name,
                academic_year_start_date, academic_year_end_date, teacher_dw_id, school_dw_id
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
            reg.active_days,
            CONVERT(DATETIME2(6), GETDATE()) AS inserted_at
        FROM (
            SELECT
                cy.calendar_year_end_date, cy.calendar_month_end_date, cy.calendar_month_start_date,
                cy.week_start_date, cy.week_end_date,
                ay.tenant_dw_id, ay.tenant_name_alias AS tenant_name,
                ay.organisation_dw_id AS content_repository_dw_id,
                ay.school_organisation AS content_repository_name,
                ay.academic_year_start_date, ay.academic_year_end_date,
                CONVERT(VARCHAR(15),
                    CONCAT(
                        CONVERT(VARCHAR(4), YEAR(ay.academic_year_start_date)),
                        ' - ',
                        CONVERT(VARCHAR(4), YEAR(ay.academic_year_end_date))
                    )
                )                                                                        AS AY,
                dt.teacher_dw_id,
                sch.school_dw_id, sch.school_name, sch.school_city_name, sch.school_country_name,
                onb.first_login_date,
                CASE WHEN COUNT(sl.teacher_dw_id) > 0 THEN 1 ELSE 0 END                AS is_active,
                COUNT(DISTINCT CONVERT(DATE, sl.login_date))                            AS active_days
            FROM ${rs_coredw}.dim_teacher AS dt
            CROSS JOIN calendar_year AS cy
            CROSS JOIN prev_academic_year AS pv
            INNER JOIN ${rs_coredw}.dim_school AS sch
                ON dt.teacher_school_dw_id = sch.school_dw_id
            INNER JOIN ${rs_bi_coredw}.bi_all_schools_dim AS ay
                ON ay.school_id            = sch.school_id
               AND dt.teacher_school_dw_id = ay.school_dw_id
               AND ay.school_city_name = 'al ain'
            LEFT JOIN login_data AS sl
                ON sl.teacher_dw_id             = dt.teacher_dw_id
               AND sl.school_dw_id              = dt.teacher_school_dw_id
               AND cy.week_start_date           = sl.cy_week_start
               AND sl.academic_year_start_date  = ay.academic_year_start_date
               AND sl.academic_year_end_date    = ay.academic_year_end_date
            LEFT JOIN onboarding_data AS onb
                ON onb.teacher_dw_id            = dt.teacher_dw_id
               AND onb.school_dw_id             = dt.teacher_school_dw_id
               AND onb.academic_year_start_date = ay.academic_year_start_date
               AND onb.academic_year_end_date   = ay.academic_year_end_date
            WHERE
                (
                    cy.week_start_date = DATETRUNC(iso_week, dt.teacher_created_time)
                    OR cy.week_end_date = DATETRUNC(iso_week, dt.teacher_active_until)
                    OR (
                        cy.week_start_date >= DATETRUNC(iso_week, dt.teacher_created_time)
                        AND cy.week_end_date <= DATETRUNC(iso_week, dt.teacher_active_until)
                    )
                    OR (
                        dt.teacher_active_until IS NULL
                        AND dt.teacher_status = 1
                        AND cy.calendar_year_end_date >= DATETRUNC(iso_week, dt.teacher_created_time)
                    )
                )
                AND (
                    sch.school_status = 1
                    OR DATETRUNC(iso_week, sch.school_updated_time) >= cy.week_start_date
                )
                AND cy.week_start_date BETWEEN
                    DATETRUNC(iso_week, ay.academic_year_start_date)
                    AND DATETRUNC(iso_week, ay.academic_year_end_date)
                AND ay.academic_year_start_date >= pv.prev_AY
            GROUP BY
                cy.calendar_year_end_date, cy.calendar_month_end_date, cy.calendar_month_start_date,
                cy.week_start_date, cy.week_end_date, ay.tenant_dw_id, ay.tenant_name_alias,
                ay.organisation_dw_id, ay.school_organisation, ay.academic_year_start_date,
                ay.academic_year_end_date,
                CONVERT(VARCHAR(9),
                    CONCAT(
                        CONVERT(VARCHAR(4), YEAR(ay.academic_year_start_date)), ' - ',
                        CONVERT(VARCHAR(4), YEAR(ay.academic_year_end_date))
                    )
                ),
                dt.teacher_dw_id, sch.school_dw_id, sch.school_name,
                sch.school_city_name, sch.school_country_name, onb.first_login_date
        ) AS reg;

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.alain_teachers_login;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.alain_teachers_login_staging', 'alain_teachers_login';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
