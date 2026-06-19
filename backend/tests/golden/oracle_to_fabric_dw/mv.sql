-- Fabric DW does NOT support CREATE MATERIALIZED VIEW.
-- Docs: https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area
-- Pattern: CTAS table + refresh stored procedure (atomic swap via sp_rename).

-- Step 1: Initial materialization via CTAS
CREATE TABLE [hr].[mv_daily_revenue] AS
SELECT TRUNC(created_at, 'DD') AS day, SUM(amount) AS total_revenue, COUNT(*) AS order_count FROM hr.orders GROUP BY TRUNC(created_at, 'DD');

-- Step 2: Refresh stored procedure (call on a schedule via Fabric Data Pipeline)
CREATE OR ALTER PROCEDURE [hr].[usp_refresh_mv_daily_revenue]
AS
BEGIN
    -- Create temp table with fresh data
    DROP TABLE IF EXISTS [hr].[mv_daily_revenue_tmp];
    CREATE TABLE [hr].[mv_daily_revenue_tmp] AS
    SELECT TRUNC(created_at, 'DD') AS day, SUM(amount) AS total_revenue, COUNT(*) AS order_count FROM hr.orders GROUP BY TRUNC(created_at, 'DD');

    -- Atomic swap: drop old, rename new
    DROP TABLE IF EXISTS [hr].[mv_daily_revenue];
    EXEC sp_rename '[hr].[mv_daily_revenue_tmp]', 'mv_daily_revenue';
END;