-- Fabric DW does NOT support CREATE MATERIALIZED VIEW.
-- Docs: https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area
-- Pattern: CTAS table + refresh stored procedure (atomic swap via sp_rename).

-- Step 1: Initial materialization via CTAS
CREATE TABLE [dbo].[mv_daily_revenue] AS
SELECT CAST(created_at AS DATE) AS day, SUM(amount) AS total_revenue, COUNT_BIG(*) AS order_count FROM dbo.orders GROUP BY CAST(created_at AS DATE);

-- Step 2: Refresh stored procedure (call on a schedule via Fabric Data Pipeline)
CREATE OR ALTER PROCEDURE [dbo].[usp_refresh_mv_daily_revenue]
AS
BEGIN
    -- Create temp table with fresh data
    DROP TABLE IF EXISTS [dbo].[mv_daily_revenue_tmp];
    CREATE TABLE [dbo].[mv_daily_revenue_tmp] AS
    SELECT CAST(created_at AS DATE) AS day, SUM(amount) AS total_revenue, COUNT_BIG(*) AS order_count FROM dbo.orders GROUP BY CAST(created_at AS DATE);

    -- Atomic swap: drop old, rename new
    DROP TABLE IF EXISTS [dbo].[mv_daily_revenue];
    EXEC sp_rename '[dbo].[mv_daily_revenue_tmp]', 'mv_daily_revenue';
END;