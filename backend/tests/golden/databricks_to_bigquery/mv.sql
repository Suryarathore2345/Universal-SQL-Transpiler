CREATE MATERIALIZED VIEW `analytics`.`mv_daily_revenue`
OPTIONS(
  enable_refresh = TRUE,
  refresh_interval_minutes = 60
)
AS
SELECT DATE_TRUNC(created_at, DAY) AS day, SUM(amount) AS total_revenue, COUNT(*) AS order_count FROM analytics.orders GROUP BY 1;