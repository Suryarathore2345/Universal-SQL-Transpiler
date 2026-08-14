CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_teacher_login_aggregated
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.teacher_login_aggregated_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.teacher_login_aggregated_staging
        WITH (CLUSTER BY (school_dw_id, local_date))
        AS
        WITH weekly_active_teachers AS (
            SELECT
                DATETRUNC(ISO_WEEK, tl.login_local_date_time) AS local_week,
                tl.school_dw_id,
                COUNT(DISTINCT tl.teacher_dw_id) AS weekly_active_teachers
            FROM ${rs_bi_coredw}.teacher_login AS tl
            JOIN ${rs_coredw}.dim_teacher AS t
                ON tl.teacher_dw_id = t.teacher_dw_id
                AND tl.school_dw_id = t.teacher_school_dw_id
                AND (
                    (t.teacher_status = 2
                        AND DATETRUNC(ISO_WEEK, tl.login_local_date_time) >= DATETRUNC(ISO_WEEK, t.teacher_created_time)
                        AND DATETRUNC(ISO_WEEK, tl.login_local_date_time) < DATETRUNC(ISO_WEEK, t.teacher_active_until))
                    OR (t.teacher_status = 1
                        AND DATETRUNC(ISO_WEEK, tl.login_local_date_time) >= DATETRUNC(ISO_WEEK, t.teacher_created_time))
                )
            WHERE CONVERT(DATE, tl.login_local_date_time) < CONVERT(DATE, GETUTCDATE())
            GROUP BY DATETRUNC(ISO_WEEK, tl.login_local_date_time), tl.school_dw_id
        ),
        monthly_active_teachers AS (
            SELECT
                DATETRUNC(MONTH, tl.login_local_date_time) AS local_month,
                tl.school_dw_id,
                COUNT(DISTINCT tl.teacher_dw_id) AS monthly_active_teachers
            FROM ${rs_bi_coredw}.teacher_login AS tl
            JOIN ${rs_coredw}.dim_teacher AS t
                ON tl.teacher_dw_id = t.teacher_dw_id
                AND tl.school_dw_id = t.teacher_school_dw_id
                AND (
                    (t.teacher_status = 2
                        AND DATETRUNC(MONTH, tl.login_local_date_time) >= DATETRUNC(MONTH, t.teacher_created_time)
                        AND DATETRUNC(MONTH, tl.login_local_date_time) < DATETRUNC(MONTH, t.teacher_active_until))
                    OR (t.teacher_status = 1
                        AND DATETRUNC(MONTH, tl.login_local_date_time) >= DATETRUNC(MONTH, t.teacher_created_time))
                )
            WHERE CONVERT(DATE, tl.login_local_date_time) < CONVERT(DATE, GETUTCDATE())
            GROUP BY DATETRUNC(MONTH, tl.login_local_date_time), tl.school_dw_id
        ),
        daily_active_teachers AS (
            SELECT
                CONVERT(DATE, tl.login_local_date_time) AS local_date,
                tl.school_dw_id,
                COUNT(DISTINCT tl.teacher_dw_id) AS daily_active_teachers
            FROM ${rs_bi_coredw}.teacher_login AS tl
            JOIN ${rs_coredw}.dim_teacher AS t
                ON tl.teacher_dw_id = t.teacher_dw_id
                AND tl.school_dw_id = t.teacher_school_dw_id
                AND (
                    (t.teacher_status = 2
                     AND DATETRUNC(day, tl.login_local_date_time) >= DATETRUNC(day, t.teacher_created_time)
                     AND DATETRUNC(day, tl.login_local_date_time) < DATETRUNC(day, t.teacher_active_until))
                    OR (t.teacher_status = 1
                        AND DATETRUNC(day, tl.login_local_date_time) >= DATETRUNC(day, t.teacher_created_time))
                )
            GROUP BY CONVERT(DATE, tl.login_local_date_time), tl.school_dw_id
        )
        SELECT
            dd.full_date                                        AS local_date,
            ISNULL(wat.local_week, DATETRUNC(ISO_WEEK, dd.full_date)) AS local_week,
            mat.local_month,
            mat.school_dw_id,
            ISNULL(wat.weekly_active_teachers, 0)               AS weekly_active_teachers,
            mat.monthly_active_teachers,
            ISNULL(dat.daily_active_teachers, 0)                AS daily_active_teachers
        FROM ${rs_coredw}.dim_date AS dd
        JOIN monthly_active_teachers AS mat
            ON DATETRUNC(month, dd.full_date) = mat.local_month
        LEFT JOIN weekly_active_teachers AS wat
            ON mat.school_dw_id = wat.school_dw_id
            AND DATETRUNC(ISO_WEEK, dd.full_date) = wat.local_week
        LEFT JOIN daily_active_teachers AS dat
            ON mat.school_dw_id = dat.school_dw_id
            AND dd.full_date = dat.local_date
        WHERE dd.full_date BETWEEN DATEADD(MONTH, -36, DATETRUNC(MONTH, CONVERT(DATE, GETUTCDATE())))
                                AND CONVERT(DATE, GETUTCDATE());

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.teacher_login_aggregated;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.teacher_login_aggregated_staging', 'teacher_login_aggregated';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
