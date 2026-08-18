-- SOURCE: aws-samples/amazon-redshift-query-patterns-and-optimizations
-- URL: https://github.com/aws-samples/amazon-redshift-query-patterns-and-optimizations/blob/master/sql_scripts/schema_setup.sql
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: IDENTITY + PRIMARY KEY + DISTKEY + SORTKEY + ENCODE
-- DESCRIPTION: Common warehouse fact table shape with an identity key.
CREATE TABLE IF NOT EXISTS my_schema.cost
(
  recid BIGINT NOT NULL ENCODE az64,
  amount_per_year NUMERIC(38,4) ENCODE az64,
  insert_dts TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT getdate() ENCODE az64,
  PRIMARY KEY (recid)
)
DISTSTYLE KEY
DISTKEY (recid)
SORTKEY (recid);
