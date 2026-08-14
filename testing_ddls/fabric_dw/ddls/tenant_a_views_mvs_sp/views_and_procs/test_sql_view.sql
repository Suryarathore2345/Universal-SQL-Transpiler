CREATE OR ALTER VIEW ${os_bi_coredw}.test_sql_view
AS
SELECT COUNT(*) AS schools FROM ${rs_coredw}.dim_school;