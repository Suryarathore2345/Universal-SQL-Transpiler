CREATE MATERIALIZED VIEW [dbo].[mv_daily_revenue]
WITH (DISTRIBUTION = HASH([day]))
AS
SELECT CAST(created_at AS DATE) AS day, SUM(amount) AS total_revenue, COUNT_BIG(*) AS order_count FROM dbo.orders GROUP BY CAST(created_at AS DATE);