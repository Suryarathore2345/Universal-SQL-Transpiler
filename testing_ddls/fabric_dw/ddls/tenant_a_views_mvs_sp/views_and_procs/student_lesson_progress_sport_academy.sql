CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_student_lesson_progress_sport_academy
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.student_lesson_progress_sport_academy_staging;

        -- --------------------------------------------------------
        -- Step 2: Create EMPTY staging table mirroring production schema
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.student_lesson_progress_sport_academy_staging
        WITH (CLUSTER BY (class_user_user_dw_id, lo_id))
        AS
        SELECT * FROM ${os_bi_coredw}.student_lesson_progress_sport_academy
        WHERE 1 = 0;

        -- --------------------------------------------------------
        -- Step 3: Load data from Lakehouse Materialized View
        -- --------------------------------------------------------
        INSERT INTO ${os_bi_coredw}.student_lesson_progress_sport_academy_staging
        SELECT * FROM ${database}.${rs_bi_coredw}.student_lesson_progress_sport_academy_mv;

        -- --------------------------------------------------------
        -- Step 4: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.student_lesson_progress_sport_academy;

        -- --------------------------------------------------------
        -- Step 5: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.student_lesson_progress_sport_academy_staging', 'student_lesson_progress_sport_academy';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;

