CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_magg_teacher_kpi_historical
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.magg_teacher_kpi_historical_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.magg_teacher_kpi_historical_staging
        WITH (CLUSTER BY (school_dw_id, calendar_month_start_date))
        AS
        WITH reg_data AS (
            SELECT
                calendar_year_end_date,
                calendar_month_end_date,
                calendar_month_start_date,
                tenant_dw_id,
                tenant_name,
                content_repository_dw_id,
                content_repository_name,
                academic_year_start_date,
                academic_year_end_date,
                ay,
                school_dw_id,
                school_name,
                COUNT(teacher_dw_id) AS registered_teachers,
                COUNT(
                    CASE
                        WHEN DATETRUNC(month, first_login_date) = calendar_month_start_date
                            THEN teacher_dw_id
                    END
                ) AS onboarded_teachers,
                SUM(is_active) AS teachers_logged_in
            FROM ${rs_bi_coredw}.teacher_stats_monthly
            GROUP BY
                calendar_year_end_date,
                calendar_month_end_date,
                calendar_month_start_date,
                tenant_dw_id,
                tenant_name,
                content_repository_dw_id,
                content_repository_name,
                academic_year_start_date,
                academic_year_end_date,
                ay,
                school_dw_id,
                school_name
        ),
        distinct_teachers AS (
            SELECT DISTINCT
                teacher_dw_id,
                calendar_month_start_date,
                tenant_dw_id,
                tenant_name,
                content_repository_dw_id,
                content_repository_name,
                academic_year_start_date,
                academic_year_end_date,
                school_dw_id,
                school_name,
                first_login_date
            FROM ${rs_bi_coredw}.teacher_stats_monthly
        ),
        cumulative_distinct_teachers AS (
            SELECT
                cm.calendar_month_start_date,
                ds.tenant_dw_id,
                ds.tenant_name,
                ds.content_repository_name,
                ds.content_repository_dw_id,
                ds.academic_year_start_date,
                ds.academic_year_end_date,
                CONCAT(
                    CONVERT(VARCHAR(4), YEAR(ds.academic_year_start_date)),
                    '-',
                    CONVERT(VARCHAR(4), YEAR(ds.academic_year_end_date))
                ) AS ay,
                ds.school_dw_id,
                ds.school_name,
                COUNT(DISTINCT ds.teacher_dw_id) AS reg_teacher_cumsum,
                COUNT(DISTINCT CASE
                    WHEN ds.first_login_date >= ds.academic_year_start_date
                     AND ds.first_login_date <= EOMONTH(ds.calendar_month_start_date)
                        THEN ds.teacher_dw_id
                END) AS onb_teacher_cumsum
            FROM (
                SELECT DISTINCT
                    calendar_month_start_date,
                    academic_year_start_date,
                    academic_year_end_date
                FROM ${rs_bi_coredw}.teacher_stats_monthly
            ) AS cm
            LEFT JOIN distinct_teachers AS ds
                ON ds.calendar_month_start_date <= cm.calendar_month_start_date
               AND ds.academic_year_start_date  = cm.academic_year_start_date
               AND cm.calendar_month_start_date BETWEEN DATETRUNC(month, ds.academic_year_start_date)
                                                    AND DATETRUNC(month, ds.academic_year_end_date)
            GROUP BY
                cm.calendar_month_start_date,
                ds.tenant_dw_id,
                ds.tenant_name,
                ds.content_repository_dw_id,
                ds.content_repository_name,
                ds.academic_year_start_date,
                ds.academic_year_end_date,
                YEAR(ds.academic_year_start_date),
                YEAR(ds.academic_year_end_date),
                ds.school_dw_id,
                ds.school_name
        ),
        CY_stats AS (
            SELECT
                calendar_year_end_date,
                tenant_dw_id,
                tenant_name,
                content_repository_dw_id,
                content_repository_name,
                COUNT(DISTINCT teacher_dw_id) AS registered_teachers_cy,
                COUNT(DISTINCT CASE
                    WHEN first_login_date BETWEEN academic_year_start_date AND academic_year_end_date
                     AND first_login_date <= calendar_year_end_date
                     AND is_active = 1
                        THEN teacher_dw_id
                END) AS onboarded_teachers_cy
            FROM ${rs_bi_coredw}.teacher_stats_monthly
            GROUP BY
                calendar_year_end_date,
                tenant_dw_id,
                tenant_name,
                content_repository_dw_id,
                content_repository_name
        ),
        AY_stats AS (
            SELECT
                academic_year_start_date,
                academic_year_end_date,
                tenant_dw_id,
                tenant_name,
                content_repository_dw_id,
                content_repository_name,
                school_dw_id,
                school_name,
                COUNT(DISTINCT teacher_dw_id) AS registered_teachers_ay,
                COUNT(DISTINCT CASE
                    WHEN first_login_date BETWEEN academic_year_start_date AND academic_year_end_date
                        THEN teacher_dw_id
                END) AS onboarded_teachers_ay
            FROM ${rs_bi_coredw}.teacher_stats_monthly
            GROUP BY
                academic_year_start_date,
                academic_year_end_date,
                tenant_dw_id,
                tenant_name,
                content_repository_dw_id,
                content_repository_name,
                school_dw_id,
                school_name
        ),
        max_insert_date AS (
            SELECT MAX(inserted_at) AS inserted_at
            FROM ${rs_bi_coredw}.teacher_stats_monthly
        )
        SELECT
            dt.calendar_year_end_date,
            dt.calendar_month_start_date,
            dt.calendar_month_end_date,
            dt.tenant_dw_id,
            dt.tenant_name,
            dt.content_repository_dw_id,
            dt.content_repository_name,
            dt.academic_year_start_date,
            dt.academic_year_end_date,
            dt.school_dw_id,
            dt.school_name,
            dt.ay,
            dt.registered_teachers,
            dt.onboarded_teachers,
            dt.teachers_logged_in,
            dt.reg_teacher_cumsum,
            dt.onb_teacher_cumsum,
            dt.registered_teachers_cy,
            dt.onboarded_teachers_cy,
            dt.registered_teachers_ay,
            dt.onboarded_teachers_ay,
            dt.inserted_at,
            DENSE_RANK() OVER (
                PARTITION BY
                    dt.calendar_month_start_date,
                    dt.tenant_dw_id,
                    dt.tenant_name,
                    dt.content_repository_dw_id
                ORDER BY YEAR(dt.academic_year_end_date) DESC
            ) AS dense_rank
        FROM (
            SELECT
                CONVERT(DATE,
                    ISNULL(
                        reg.calendar_year_end_date,
                        DATEADD(DAY, -1, DATEADD(MONTH, 12, DATETRUNC(year, cum_tch.calendar_month_start_date)))
                    )
                ) AS calendar_year_end_date,
                ISNULL(reg.calendar_month_start_date, cum_tch.calendar_month_start_date)      AS calendar_month_start_date,
                ISNULL(reg.calendar_month_end_date, EOMONTH(cum_tch.calendar_month_start_date)) AS calendar_month_end_date,
                ISNULL(reg.tenant_dw_id, cum_tch.tenant_dw_id)                               AS tenant_dw_id,
                ISNULL(reg.tenant_name, cum_tch.tenant_name)                                 AS tenant_name,
                ISNULL(reg.content_repository_dw_id, cum_tch.content_repository_dw_id)       AS content_repository_dw_id,
                ISNULL(reg.content_repository_name, cum_tch.content_repository_name)         AS content_repository_name,
                ISNULL(reg.academic_year_start_date, cum_tch.academic_year_start_date)       AS academic_year_start_date,
                ISNULL(reg.academic_year_end_date, cum_tch.academic_year_end_date)           AS academic_year_end_date,
                ISNULL(reg.school_dw_id, cum_tch.school_dw_id)                               AS school_dw_id,
                ISNULL(reg.school_name, cum_tch.school_name)                                 AS school_name,
                ISNULL(reg.ay, cum_tch.ay)                                                   AS ay,
                reg.registered_teachers,
                reg.onboarded_teachers,
                reg.teachers_logged_in,
                cum_tch.reg_teacher_cumsum,
                cum_tch.onb_teacher_cumsum,
                CY_stats.registered_teachers_cy,
                CY_stats.onboarded_teachers_cy,
                AY_stats.registered_teachers_ay,
                AY_stats.onboarded_teachers_ay,
                ins.inserted_at
            FROM reg_data AS reg
            FULL OUTER JOIN cumulative_distinct_teachers AS cum_tch
                ON reg.calendar_month_start_date = cum_tch.calendar_month_start_date
               AND reg.tenant_dw_id              = cum_tch.tenant_dw_id
               AND reg.tenant_name               = cum_tch.tenant_name
               AND reg.content_repository_dw_id  = cum_tch.content_repository_dw_id
               AND reg.school_dw_id              = cum_tch.school_dw_id
               AND reg.academic_year_end_date    = cum_tch.academic_year_end_date
               AND reg.academic_year_start_date  = cum_tch.academic_year_start_date
            LEFT JOIN CY_stats
                ON reg.calendar_year_end_date    = CY_stats.calendar_year_end_date
               AND reg.tenant_dw_id              = CY_stats.tenant_dw_id
               AND reg.tenant_name               = CY_stats.tenant_name
               AND reg.content_repository_dw_id  = CY_stats.content_repository_dw_id
            LEFT JOIN AY_stats
                ON reg.academic_year_start_date  = AY_stats.academic_year_start_date
               AND reg.academic_year_end_date    = AY_stats.academic_year_end_date
               AND reg.tenant_dw_id              = AY_stats.tenant_dw_id
               AND reg.tenant_name               = AY_stats.tenant_name
               AND reg.content_repository_dw_id  = AY_stats.content_repository_dw_id
               AND reg.school_dw_id              = AY_stats.school_dw_id
            CROSS JOIN max_insert_date AS ins
        ) AS dt;

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.magg_teacher_kpi_historical;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.magg_teacher_kpi_historical_staging', 'magg_teacher_kpi_historical';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
