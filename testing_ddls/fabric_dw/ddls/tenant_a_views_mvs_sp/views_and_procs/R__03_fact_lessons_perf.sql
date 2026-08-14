CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_fact_lessons_perf
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.fact_lessons_perf_staging;

        -- --------------------------------------------------------
        -- Step 2: Create EMPTY staging table mirroring production schema
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.fact_lessons_perf_staging
        WITH (CLUSTER BY (school_dw_id, class_dw_id))
        AS
        SELECT * FROM ${os_bi_coredw}.fact_lessons_perf
        WHERE 1 = 0;

        -- --------------------------------------------------------
        -- Step 3: Load data from the view
        -- --------------------------------------------------------
        INSERT INTO ${os_bi_coredw}.fact_lessons_perf_staging
        SELECT * FROM ${database}.${rs_bi_coredw}.fact_lessons_perf_mv;

        -- --------------------------------------------------------
        -- Step 4: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.fact_lessons_perf;

        -- --------------------------------------------------------
        -- Step 5: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.fact_lessons_perf_staging', 'fact_lessons_perf';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;