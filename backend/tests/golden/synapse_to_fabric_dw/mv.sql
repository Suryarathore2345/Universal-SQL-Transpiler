-- Fabric DW does NOT support CREATE MATERIALIZED VIEW.
-- Docs: https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area
-- Option 1: Create a standard VIEW (no pre-computation)
CREATE VIEW [dbo].[mv_daily_revenue] AS
SELECT CAST(created_at AS DATE) AS day, SUM(amount) AS total_revenue, COUNT_BIG(*) AS order_count FROM dbo.orders GROUP BY CAST(created_at AS DATE);

-- Option 2: Materialize via CTAS (run manually or on a schedule)
-- CREATE TABLE [dbo].[mv_daily_revenue]_snapshot AS
-- SELECT * FROM (SELECT CAST(created_at AS DATE) AS day, SUM(amount) AS total_revenue, COUNT_BIG(*) AS order_count FROM dbo.orders GROUP BY CAST(created_at AS DATE)) AS src;