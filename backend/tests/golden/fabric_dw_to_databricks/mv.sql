CREATE VIEW `dbo`.`mv_daily_revenue` AS
SELECT CAST(created_at AS DATE) AS day, SUM(amount) AS total_revenue, COUNT(*) AS order_count FROM dbo.orders GROUP BY CAST(created_at AS DATE);