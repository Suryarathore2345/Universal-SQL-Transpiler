CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_magg_student_kpi_historical
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.magg_student_kpi_historical_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.magg_student_kpi_historical_staging
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
                grade_name,
                COUNT(student_dw_id) AS registered_students,
                COUNT(
                    CASE
                        WHEN DATETRUNC(month, first_login_date) = calendar_month_start_date
                            THEN student_dw_id
                    END
                ) AS onboarded_students,
                SUM(is_active) AS students_logged_in
            FROM ${rs_bi_coredw}.students_stats_monthly
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
                school_name,
                grade_name
        ),
        distinct_students AS (
            SELECT DISTINCT
                student_dw_id,
                calendar_month_start_date,
                tenant_dw_id,
                tenant_name,
                content_repository_dw_id,
                content_repository_name,
                academic_year_start_date,
                academic_year_end_date,
                school_dw_id,
                school_name,
                grade_name,
                first_login_date
            FROM ${rs_bi_coredw}.students_stats_monthly
        ),
        cumulative_distinct_students AS (
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
                ds.grade_name,
                COUNT(DISTINCT ds.school_dw_id)   AS reg_school_cumsum,
                COUNT(DISTINCT ds.student_dw_id)  AS reg_student_cumsum,
                COUNT(DISTINCT CASE
                    WHEN ds.first_login_date >= ds.academic_year_start_date
                     AND ds.first_login_date <= EOMONTH(ds.calendar_month_start_date)
                        THEN ds.school_dw_id
                END) AS onb_school_cumsum,
                COUNT(DISTINCT CASE
                    WHEN ds.first_login_date >= ds.academic_year_start_date
                     AND ds.first_login_date <= EOMONTH(ds.calendar_month_start_date)
                        THEN ds.student_dw_id
                END) AS onb_student_cumsum
            FROM (
                SELECT DISTINCT
                    calendar_month_start_date,
                    academic_year_start_date,
                    academic_year_end_date
                FROM ${rs_bi_coredw}.students_stats_monthly
            ) AS cm
            LEFT JOIN distinct_students AS ds
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
                ds.school_name,
                ds.grade_name
        ),
        CY_stats AS (
            SELECT
                calendar_year_end_date,
                tenant_dw_id,
                tenant_name,
                content_repository_dw_id,
                content_repository_name,
                COUNT(DISTINCT student_dw_id) AS registered_students_cy,
                COUNT(DISTINCT CASE
                    WHEN first_login_date BETWEEN academic_year_start_date AND academic_year_end_date
                     AND first_login_date <= calendar_year_end_date
                     AND is_active = 1
                        THEN student_dw_id
                END) AS onboarded_students_cy
            FROM ${rs_bi_coredw}.students_stats_monthly
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
                grade_name,
                COUNT(DISTINCT student_dw_id) AS registered_students_ay,
                COUNT(DISTINCT CASE
                    WHEN first_login_date BETWEEN academic_year_start_date AND academic_year_end_date
                        THEN student_dw_id
                END) AS onboarded_students_ay
            FROM ${rs_bi_coredw}.students_stats_monthly
            GROUP BY
                academic_year_start_date,
                academic_year_end_date,
                tenant_dw_id,
                tenant_name,
                content_repository_dw_id,
                content_repository_name,
                school_dw_id,
                school_name,
                grade_name
        ),
        max_insert_date AS (
            SELECT MAX(inserted_at) AS inserted_at
            FROM ${rs_bi_coredw}.students_stats_monthly
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
            dt.grade_name,
            dt.ay,
            dt.registered_students,
            dt.onboarded_students,
            dt.students_logged_in,
            dt.reg_school_cumsum,
            dt.reg_student_cumsum,
            dt.onb_school_cumsum,
            dt.onb_student_cumsum,
            dt.ay_rank,
            dt.registered_students_cy,
            dt.onboarded_students_cy,
            dt.registered_students_ay,
            dt.onboarded_students_ay,
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
                        DATEADD(DAY, -1, DATEADD(MONTH, 12, DATETRUNC(year, cum_stu.calendar_month_start_date)))
                    )
                ) AS calendar_year_end_date,
                ISNULL(reg.calendar_month_start_date, cum_stu.calendar_month_start_date)     AS calendar_month_start_date,
                ISNULL(reg.calendar_month_end_date, EOMONTH(cum_stu.calendar_month_start_date)) AS calendar_month_end_date,
                ISNULL(reg.tenant_dw_id, cum_stu.tenant_dw_id)                              AS tenant_dw_id,
                ISNULL(reg.tenant_name, cum_stu.tenant_name)                                AS tenant_name,
                ISNULL(reg.content_repository_dw_id, cum_stu.content_repository_dw_id)      AS content_repository_dw_id,
                ISNULL(reg.content_repository_name, cum_stu.content_repository_name)        AS content_repository_name,
                ISNULL(reg.academic_year_start_date, cum_stu.academic_year_start_date)      AS academic_year_start_date,
                ISNULL(reg.academic_year_end_date, cum_stu.academic_year_end_date)          AS academic_year_end_date,
                ISNULL(reg.school_dw_id, cum_stu.school_dw_id)                              AS school_dw_id,
                ISNULL(reg.school_name, cum_stu.school_name)                                AS school_name,
                ISNULL(reg.grade_name, cum_stu.grade_name)                                  AS grade_name,
                ISNULL(reg.ay, cum_stu.ay)                                                  AS ay,
                reg.registered_students,
                reg.onboarded_students,
                reg.students_logged_in,
                cum_stu.reg_school_cumsum,
                cum_stu.reg_student_cumsum,
                cum_stu.onb_school_cumsum,
                cum_stu.onb_student_cumsum,
                DENSE_RANK() OVER (
                    PARTITION BY
                        reg.academic_year_start_date,
                        reg.academic_year_end_date,
                        reg.tenant_dw_id,
                        reg.tenant_name,
                        reg.content_repository_dw_id
                    ORDER BY reg.calendar_month_start_date ASC
                ) AS ay_rank,
                CY_stats.registered_students_cy,
                CY_stats.onboarded_students_cy,
                AY_stats.registered_students_ay,
                AY_stats.onboarded_students_ay,
                ins.inserted_at
            FROM reg_data AS reg
            FULL OUTER JOIN cumulative_distinct_students AS cum_stu
                ON reg.calendar_month_start_date = cum_stu.calendar_month_start_date
               AND reg.tenant_dw_id              = cum_stu.tenant_dw_id
               AND reg.tenant_name               = cum_stu.tenant_name
               AND reg.content_repository_dw_id  = cum_stu.content_repository_dw_id
               AND reg.school_dw_id              = cum_stu.school_dw_id
               AND reg.grade_name                = cum_stu.grade_name
               AND reg.academic_year_end_date    = cum_stu.academic_year_end_date
               AND reg.academic_year_start_date  = cum_stu.academic_year_start_date
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
               AND reg.grade_name                = AY_stats.grade_name
            CROSS JOIN max_insert_date AS ins
        ) AS dt;

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.magg_student_kpi_historical;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.magg_student_kpi_historical_staging', 'magg_student_kpi_historical';


    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
