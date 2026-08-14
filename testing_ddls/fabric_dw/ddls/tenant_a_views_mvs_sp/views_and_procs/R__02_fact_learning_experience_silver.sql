CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_fact_learning_experience_silver
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.fact_learning_experience_silver_staging;

        -- --------------------------------------------------------
        -- Step 2: Create EMPTY staging table mirroring production schema
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.fact_learning_experience_silver_staging
        WITH (CLUSTER BY (school_dw_id, fle_student_dw_id))
        AS
        SELECT * FROM ${os_bi_coredw}.fact_learning_experience_silver
        WHERE 1 = 0;

        -- --------------------------------------------------------
        -- Step 3: Load data from Lakehouse Materialized View
        -- --------------------------------------------------------
        INSERT INTO ${os_bi_coredw}.fact_learning_experience_silver_staging
        SELECT * FROM ${database}.${rs_bi_coredw}.fact_learning_experience_silver_mv;

        -- --------------------------------------------------------
        -- Step 4: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.fact_learning_experience_silver;

        -- --------------------------------------------------------
        -- Step 5: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.fact_learning_experience_silver_staging', 'fact_learning_experience_silver';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;

