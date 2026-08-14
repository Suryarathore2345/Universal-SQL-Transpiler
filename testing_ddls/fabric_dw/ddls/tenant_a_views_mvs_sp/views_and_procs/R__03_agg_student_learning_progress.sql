CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_agg_student_learning_progress
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.agg_student_learning_progress_staging;

        -- --------------------------------------------------------
        -- Step 2: Create EMPTY staging table mirroring production schema
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.agg_student_learning_progress_staging
        WITH (CLUSTER BY (school_dw_id, student_dw_id))
        AS
        SELECT * FROM ${os_bi_coredw}.agg_student_learning_progress
        WHERE 1 = 0;

        -- --------------------------------------------------------
        -- Step 3: Load data from Lakehouse Materialized View
        -- --------------------------------------------------------
        INSERT INTO ${os_bi_coredw}.agg_student_learning_progress_staging
        SELECT * FROM ${database}.${rs_bi_coredw}.agg_student_learning_progress_mv;

        -- --------------------------------------------------------
        -- Step 4: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.agg_student_learning_progress;

        -- --------------------------------------------------------
        -- Step 5: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.agg_student_learning_progress_staging', 'agg_student_learning_progress';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;