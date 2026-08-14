CREATE OR ALTER PROCEDURE ${OS_EAGLES_COREDW}.usp_refresh_student_absentees_noholiday_weekly
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${OS_EAGLES_COREDW}.student_absentees_noholiday_weekly_staging;

        -- --------------------------------------------------------
        -- Step 2: Create EMPTY staging table mirroring production schema
        -- --------------------------------------------------------
        CREATE TABLE ${OS_EAGLES_COREDW}.student_absentees_noholiday_weekly_staging
        WITH (CLUSTER BY (school_dw_id, student_id))
        AS
        SELECT * FROM ${OS_EAGLES_COREDW}.student_absentees_noholiday_weekly
        WHERE 1 = 0;

        -- --------------------------------------------------------
        -- Step 3: Load data from Lakehouse Materialized View
        -- --------------------------------------------------------
        INSERT INTO ${OS_EAGLES_COREDW}.student_absentees_noholiday_weekly_staging
        SELECT * FROM ${database}.${RS_EAGLES_COREDW}.student_absentees_noholiday_weekly_mv;

        -- --------------------------------------------------------
        -- Step 4: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${OS_EAGLES_COREDW}.student_absentees_noholiday_weekly;

        -- --------------------------------------------------------
        -- Step 5: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${OS_EAGLES_COREDW}.student_absentees_noholiday_weekly_staging', 'student_absentees_noholiday_weekly';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;