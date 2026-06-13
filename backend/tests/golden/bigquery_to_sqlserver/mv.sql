-- SQL Server does not support CREATE MATERIALIZED VIEW.
-- Documented equivalent: indexed view with SCHEMABINDING.
-- Docs: https://learn.microsoft.com/en-us/sql/relational-databases/views/create-indexed-views
CREATE VIEW [analytics].[mv_daily_revenue] WITH SCHEMABINDING AS
SELECT DATE(created_at) AS day, SUM(amount) AS total_revenue, COUNT(*) AS order_count FROM `analytics.orders` GROUP BY 1;
GO
-- Create unique clustered index to materialize the view
CREATE UNIQUE CLUSTERED INDEX [IX_mv_daily_revenue_clustered]
    ON [analytics].[mv_daily_revenue] (<unique_key_column>);