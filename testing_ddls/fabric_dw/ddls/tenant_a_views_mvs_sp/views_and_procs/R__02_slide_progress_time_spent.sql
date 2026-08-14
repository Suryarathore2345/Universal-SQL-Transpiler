CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_slide_progress_time_spent
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.slide_progress_time_spent_staging;

        -- --------------------------------------------------------
        -- Step 2: Create EMPTY staging table mirroring production schema
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.slide_progress_time_spent_staging
        WITH (CLUSTER BY (fle_lo_dw_id, school_dw_id))
        AS
        SELECT * FROM ${os_bi_coredw}.slide_progress_time_spent
        WHERE 1 = 0;

        -- --------------------------------------------------------
        -- Step 3: Load data from Lakehouse Materialized View
        -- --------------------------------------------------------
        INSERT INTO ${os_bi_coredw}.slide_progress_time_spent_staging
        SELECT * FROM ${database}.${rs_bi_coredw}.slide_progress_time_spent_mv;

        -- --------------------------------------------------------
        -- Step 4: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.slide_progress_time_spent;

        -- --------------------------------------------------------
        -- Step 5: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.slide_progress_time_spent_staging', 'slide_progress_time_spent';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;

