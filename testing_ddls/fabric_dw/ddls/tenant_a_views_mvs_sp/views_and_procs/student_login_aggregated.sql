CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_student_login_aggregated
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.student_login_aggregated_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.student_login_aggregated_staging
        WITH (CLUSTER BY (school_dw_id, local_date))
        AS
        WITH weekly_active_students AS (
            SELECT
                DATETRUNC(iso_week, sl.login_local_date_time)   AS local_week,
                sl.school_dw_id,
                st.student_grade_dw_id,
                st.student_section_dw_id,
                st.student_special_needs,
                st.student_tags,
                COUNT(DISTINCT sl.student_dw_id)                AS weekly_active_students
            FROM ${rs_bi_coredw}.student_login AS sl
            JOIN ${rs_bi_coredw}.bi_student_dim AS st
                ON sl.student_dw_id = st.student_dw_id
                AND sl.school_dw_id = st.student_school_dw_id
                AND (
                    (st.student_status = 2
                     AND DATETRUNC(iso_week, sl.login_local_date_time) >= DATETRUNC(iso_week, st.student_created_time)
                     AND DATETRUNC(iso_week, sl.login_local_date_time) < DATETRUNC(iso_week, st.student_active_until))
                    OR (st.student_status = 1
                        AND DATETRUNC(iso_week, sl.login_local_date_time) >= DATETRUNC(iso_week, st.student_created_time))
                )
            WHERE CONVERT(DATE, sl.login_local_date_time) < CONVERT(DATE, GETDATE())
            GROUP BY DATETRUNC(iso_week, sl.login_local_date_time), sl.school_dw_id,
                     st.student_grade_dw_id, st.student_section_dw_id, st.student_special_needs, st.student_tags
        ),
        monthly_active_students AS (
            SELECT
                DATETRUNC(month, sl.login_local_date_time)      AS local_month,
                sl.school_dw_id,
                st.student_grade_dw_id,
                dg.grade_k12grade                               AS grade_name,
                st.student_section_dw_id,
                st.student_special_needs,
                st.student_tags,
                COUNT(DISTINCT sl.student_dw_id)                AS monthly_active_students
            FROM ${rs_bi_coredw}.student_login AS sl
            JOIN ${rs_bi_coredw}.bi_student_dim AS st
                ON sl.student_dw_id = st.student_dw_id
                AND sl.school_dw_id = st.student_school_dw_id
                AND (
                    (st.student_status = 2
                     AND DATETRUNC(month, sl.login_local_date_time) >= DATETRUNC(month, st.student_created_time)
                     AND DATETRUNC(month, sl.login_local_date_time) < DATETRUNC(month, st.student_active_until))
                    OR (st.student_status = 1
                        AND DATETRUNC(month, sl.login_local_date_time) >= DATETRUNC(month, st.student_created_time))
                )
            JOIN ${rs_coredw}.dim_grade AS dg
                ON st.student_grade_dw_id = dg.grade_dw_id
            WHERE CONVERT(DATE, sl.login_local_date_time) < CONVERT(DATE, GETDATE())
            GROUP BY DATETRUNC(month, sl.login_local_date_time), sl.school_dw_id,
                     st.student_grade_dw_id, dg.grade_k12grade, st.student_section_dw_id,
                     st.student_special_needs, st.student_tags
        ),
        daily_active_students AS (
            SELECT
                CONVERT(DATE, sl.login_local_date_time)         AS local_date,
                sl.school_dw_id,
                st.student_grade_dw_id,
                st.student_section_dw_id,
                st.student_special_needs,
                st.student_tags,
                COUNT(DISTINCT sl.student_dw_id)                AS daily_active_students
            FROM ${rs_bi_coredw}.student_login AS sl
            JOIN ${rs_bi_coredw}.bi_student_dim AS st
                ON sl.student_dw_id = st.student_dw_id
                AND sl.school_dw_id = st.student_school_dw_id
                AND (
                    (st.student_status = 2
                     AND DATETRUNC(day, sl.login_local_date_time) >= DATETRUNC(day, st.student_created_time)
                     AND DATETRUNC(day, sl.login_local_date_time) < DATETRUNC(day, st.student_active_until))
                    OR (st.student_status = 1
                        AND DATETRUNC(day, sl.login_local_date_time) >= DATETRUNC(day, st.student_created_time))
                )
            GROUP BY CONVERT(DATE, sl.login_local_date_time), sl.school_dw_id,
                     st.student_grade_dw_id, st.student_section_dw_id, st.student_special_needs, st.student_tags
        )
        SELECT
            dd.full_date                                        AS local_date,
            was.local_week,
            mas.local_month,
            mas.school_dw_id,
            mas.student_grade_dw_id,
            mas.grade_name,
            mas.student_section_dw_id,
            mas.student_special_needs,
            mas.student_tags,
            ISNULL(was.weekly_active_students, 0)               AS weekly_active_students,
            mas.monthly_active_students,
            ISNULL(das.daily_active_students, 0)                AS daily_active_students
        FROM ${rs_coredw}.dim_date AS dd
        JOIN monthly_active_students AS mas
            ON DATETRUNC(month, dd.full_date) = mas.local_month
        LEFT JOIN weekly_active_students AS was
            ON mas.student_section_dw_id = was.student_section_dw_id
            AND mas.student_special_needs = was.student_special_needs
            AND mas.student_tags = was.student_tags
            AND DATETRUNC(iso_week, dd.full_date) = was.local_week
        LEFT JOIN daily_active_students AS das
            ON mas.student_section_dw_id = das.student_section_dw_id
            AND mas.student_special_needs = das.student_special_needs
            AND mas.student_tags = das.student_tags
            AND dd.full_date = das.local_date
        WHERE dd.full_date BETWEEN DATEADD(MONTH, -36, DATETRUNC(month, CONVERT(DATE, GETDATE()))) AND CONVERT(DATE, GETDATE());

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.student_login_aggregated;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.student_login_aggregated_staging', 'student_login_aggregated';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
