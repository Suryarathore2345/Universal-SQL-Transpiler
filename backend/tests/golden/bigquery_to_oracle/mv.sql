CREATE MATERIALIZED VIEW "analytics"."mv_daily_revenue"
BUILD IMMEDIATE
REFRESH ON COMMIT
ENABLE QUERY REWRITE
AS
SELECT DATE(created_at) AS day, SUM(amount) AS total_revenue, COUNT(*) AS order_count FROM `analytics.orders` GROUP BY 1;