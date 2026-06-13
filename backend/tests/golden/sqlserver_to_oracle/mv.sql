CREATE MATERIALIZED VIEW "dbo"."mv_daily_revenue"
BUILD IMMEDIATE
REFRESH ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT CAST(created_at AS DATE) AS day, SUM(amount) AS total_revenue, COUNT(*) AS order_count FROM dbo.orders GROUP BY CAST(created_at AS DATE);