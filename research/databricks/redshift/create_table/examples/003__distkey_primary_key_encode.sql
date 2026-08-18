-- SOURCE: aws-samples/getting-started-with-amazon-redshift-data-api
-- URL: https://github.com/aws-samples/getting-started-with-amazon-redshift-data-api/blob/main/use-cases/etl-orchestration-with-step-functions/scripts/sp_statements.sql
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DISTKEY + PRIMARY KEY + ENCODE
-- DESCRIPTION: Staging-table style DDL with distribution key and compression.
CREATE TABLE IF NOT EXISTS public.customer_address
(
  ca_address_sk int4 not null encode az64,
  ca_address_id char(16) not null encode zstd,
  ca_state char(2) encode zstd,
  ca_zip char(10) encode zstd,
  ca_country varchar(20) encode zstd,
  primary key (ca_address_id)
)
DISTKEY(ca_address_id);
