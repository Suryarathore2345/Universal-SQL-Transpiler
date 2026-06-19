-- Fabric DW does NOT support CREATE MATERIALIZED VIEW.
-- Docs: https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area
-- Pattern: CTAS table + refresh stored procedure (atomic swap via sp_rename).

-- Step 1: Initial materialization via CTAS
CREATE TABLE [analytics].[mv_daily_revenue] AS
SELECT DATE(created_at) AS day, SUM(amount) AS total_revenue, COUNT(*) AS order_count FROM "analytics.orders" GROUP BY 1;

-- Step 2: Refresh stored procedure (call on a schedule via Fabric Data Pipeline)
CREATE OR ALTER PROCEDURE [analytics].[usp_refresh_mv_daily_revenue]
AS
BEGIN
    -- Create temp table with fresh data
    DROP TABLE IF EXISTS [analytics].[mv_daily_revenue_tmp];
    CREATE TABLE [analytics].[mv_daily_revenue_tmp] AS
    SELECT DATE(created_at) AS day, SUM(amount) AS total_revenue, COUNT(*) AS order_count FROM "analytics.orders" GROUP BY 1;

    -- Atomic swap: drop old, rename new
    DROP TABLE IF EXISTS [analytics].[mv_daily_revenue];
    EXEC sp_rename '[analytics].[mv_daily_revenue_tmp]', 'mv_daily_revenue';
END;