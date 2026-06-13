-- SQL Server does not support CREATE MATERIALIZED VIEW.
-- Documented equivalent: indexed view with SCHEMABINDING.
-- Docs: https://learn.microsoft.com/en-us/sql/relational-databases/views/create-indexed-views
CREATE VIEW [dbo].[mv_daily_revenue] WITH SCHEMABINDING AS
SELECT CAST(created_at AS DATE) AS day, SUM(amount) AS total_revenue, COUNT_BIG(*) AS order_count FROM dbo.orders GROUP BY CAST(created_at AS DATE);
GO
-- Create unique clustered index to materialize the view
CREATE UNIQUE CLUSTERED INDEX [IX_mv_daily_revenue_clustered]
    ON [dbo].[mv_daily_revenue] (<unique_key_column>);