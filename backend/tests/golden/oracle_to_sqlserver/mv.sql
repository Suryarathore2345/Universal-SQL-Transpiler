-- SQL Server does not support CREATE MATERIALIZED VIEW.
-- Documented equivalent: indexed view with SCHEMABINDING.
-- Docs: https://learn.microsoft.com/en-us/sql/relational-databases/views/create-indexed-views
CREATE VIEW [hr].[mv_daily_revenue] WITH SCHEMABINDING AS
SELECT TRUNC(created_at, 'DD') AS day, SUM(amount) AS total_revenue, COUNT(*) AS order_count FROM hr.orders GROUP BY TRUNC(created_at, 'DD');
GO
-- Create unique clustered index to materialize the view
CREATE UNIQUE CLUSTERED INDEX [IX_mv_daily_revenue_clustered]
    ON [hr].[mv_daily_revenue] (<unique_key_column>);