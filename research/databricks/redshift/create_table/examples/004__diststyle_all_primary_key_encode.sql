-- SOURCE: aws-samples/getting-started-with-amazon-redshift-data-api
-- URL: https://github.com/aws-samples/getting-started-with-amazon-redshift-data-api/blob/main/use-cases/etl-orchestration-with-step-functions/scripts/sp_statements.sql
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DISTSTYLE ALL + PRIMARY KEY + ENCODE
-- DESCRIPTION: Date dimension example with a small replicated table.
CREATE TABLE IF NOT EXISTS public.date_dim
(
  d_date_sk integer not null encode az64,
  d_date_id char(16) not null encode zstd,
  d_date date encode az64,
  d_day_name char(9) encode zstd,
  primary key (d_date_sk)
)
DISTSTYLE ALL;
