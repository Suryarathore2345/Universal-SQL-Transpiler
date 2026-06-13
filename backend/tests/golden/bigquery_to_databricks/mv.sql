CREATE MATERIALIZED VIEW `analytics`.`mv_daily_revenue`
AS
SELECT DATE(created_at) AS day, SUM(amount) AS total_revenue, COUNT(*) AS order_count FROM `analytics.orders` GROUP BY 1;