CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_indonesia_student_login
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.indonesia_student_login_staging;

        -- --------------------------------------------------------
        -- Step 2: Create EMPTY staging table mirroring production schema
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.indonesia_student_login_staging
        WITH (CLUSTER BY (school_dw_id, student_dw_id))
        AS
        SELECT * FROM ${os_bi_coredw}.indonesia_student_login
        WHERE 1 = 0;

        -- --------------------------------------------------------
        -- Step 3: Load data from Lakehouse Materialized View
        -- --------------------------------------------------------
        INSERT INTO ${os_bi_coredw}.indonesia_student_login_staging
        SELECT * FROM ${database}.${rs_bi_coredw}.indonesia_student_login_mv;

        -- --------------------------------------------------------
        -- Step 4: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.indonesia_student_login;

        -- --------------------------------------------------------
        -- Step 5: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.indonesia_student_login_staging', 'indonesia_student_login';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;

