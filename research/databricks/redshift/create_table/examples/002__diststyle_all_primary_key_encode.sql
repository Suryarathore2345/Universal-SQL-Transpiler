-- SOURCE: aws-samples/getting-started-with-amazon-redshift-data-api
-- URL: https://github.com/aws-samples/getting-started-with-amazon-redshift-data-api/blob/main/use-cases/etl-orchestration-with-step-functions/scripts/sp_statements.sql
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DISTSTYLE ALL + PRIMARY KEY + ENCODE
-- DESCRIPTION: Dimension-table pattern commonly used in ETL setups.
CREATE TABLE IF NOT EXISTS public.customer
(
  c_customer_sk int4 not null encode az64,
  c_customer_id char(16) not null encode zstd,
  c_current_addr_sk int4 encode az64,
  c_first_name char(20) encode zstd,
  c_last_name char(30) encode zstd,
  primary key (c_customer_sk)
)
DISTSTYLE ALL;
