CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_structure_components_attempts
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.structure_components_attempts_staging;

        -- --------------------------------------------------------
        -- Step 2: Create EMPTY staging table mirroring production schema
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.structure_components_attempts_staging
        WITH (CLUSTER BY (school_dw_id, fle_lo_dw_id))
        AS
        SELECT * FROM ${os_bi_coredw}.structure_components_attempts
        WHERE 1 = 0;

        -- --------------------------------------------------------
        -- Step 3: Load data from Lakehouse Materialized View
        -- --------------------------------------------------------
        INSERT INTO ${os_bi_coredw}.structure_components_attempts_staging
        SELECT * FROM ${database}.${rs_bi_coredw}.structure_components_attempts_mv_view;

        -- --------------------------------------------------------
        -- Step 4: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.structure_components_attempts;

        -- --------------------------------------------------------
        -- Step 5: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.structure_components_attempts_staging', 'structure_components_attempts';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;

