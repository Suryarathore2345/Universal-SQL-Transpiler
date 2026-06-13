CREATE MATERIALIZED VIEW hr.mv_daily_revenue
AUTO REFRESH NO
AS
SELECT TRUNC(created_at, 'DD') AS day, SUM(amount) AS total_revenue, COUNT(*) AS order_count FROM hr.orders GROUP BY TRUNC(created_at, 'DD');