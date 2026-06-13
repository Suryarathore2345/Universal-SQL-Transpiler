-- Fabric DW does NOT support CREATE MATERIALIZED VIEW.
-- Docs: https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area
-- Option 1: Create a standard VIEW (no pre-computation)
CREATE VIEW [analytics].[mv_daily_revenue] AS
SELECT DATE_TRUNC('DAY', created_at) AS day, SUM(amount) AS total_revenue, COUNT(*) AS order_count FROM analytics.orders GROUP BY 1;

-- Option 2: Materialize via CTAS (run manually or on a schedule)
-- CREATE TABLE [analytics].[mv_daily_revenue]_snapshot AS
-- SELECT * FROM (SELECT DATE_TRUNC('DAY', created_at) AS day, SUM(amount) AS total_revenue, COUNT(*) AS order_count FROM analytics.orders GROUP BY 1) AS src;