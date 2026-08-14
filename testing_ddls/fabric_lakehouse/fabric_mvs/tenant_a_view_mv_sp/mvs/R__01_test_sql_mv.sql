CREATE OR REPLACE MATERIALIZED LAKE VIEW {{os_bi_coredw}}.test_sql_mv
AS
SELECT COUNT(*) AS schools FROM {{rs_coredw}}.dim_school;