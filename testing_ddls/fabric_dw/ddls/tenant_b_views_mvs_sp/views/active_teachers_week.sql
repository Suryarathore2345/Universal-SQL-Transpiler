CREATE OR ALTER PROCEDURE ${OS_EAGLES_COREDW}.usp_refresh_active_teachers_week
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${OS_EAGLES_COREDW}.active_teachers_week_staging;

        -- --------------------------------------------------------
        -- Step 2: Create EMPTY staging table mirroring production schema
        -- --------------------------------------------------------
        CREATE TABLE ${OS_EAGLES_COREDW}.active_teachers_week_staging
        WITH (CLUSTER BY (school_dw_id, teacher_dw_id))
        AS
        SELECT * FROM ${OS_EAGLES_COREDW}.active_teachers_week
        WHERE 1 = 0;

        -- --------------------------------------------------------
        -- Step 3: Load data from Lakehouse Materialized View
        -- --------------------------------------------------------
        INSERT INTO ${OS_EAGLES_COREDW}.active_teachers_week_staging
        SELECT * FROM ${database}.${RS_EAGLES_COREDW}.active_teachers_week_mv;

        -- --------------------------------------------------------
        -- Step 4: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${OS_EAGLES_COREDW}.active_teachers_week;

        -- --------------------------------------------------------
        -- Step 5: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${OS_EAGLES_COREDW}.active_teachers_week_staging', 'active_teachers_week';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;