CREATE MATERIALIZED VIEW dbo.mv_daily_revenue
DISTSTYLE KEY
DISTKEY ("day")
AUTO REFRESH YES
AS
SELECT CAST(created_at AS DATE) AS day, SUM(amount) AS total_revenue, COUNT_BIG(*) AS order_count FROM dbo.orders GROUP BY CAST(created_at AS DATE);