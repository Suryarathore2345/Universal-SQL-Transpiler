-- Fabric DW does NOT support CREATE MATERIALIZED VIEW.
-- Docs: https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area
-- Option 1: Create a standard VIEW (no pre-computation)
CREATE VIEW [hr].[mv_daily_revenue] AS
SELECT TRUNC(created_at, 'DD') AS day, SUM(amount) AS total_revenue, COUNT(*) AS order_count FROM hr.orders GROUP BY TRUNC(created_at, 'DD');

-- Option 2: Materialize via CTAS (run manually or on a schedule)
-- CREATE TABLE [hr].[mv_daily_revenue]_snapshot AS
-- SELECT * FROM (SELECT TRUNC(created_at, 'DD') AS day, SUM(amount) AS total_revenue, COUNT(*) AS order_count FROM hr.orders GROUP BY TRUNC(created_at, 'DD')) AS src;