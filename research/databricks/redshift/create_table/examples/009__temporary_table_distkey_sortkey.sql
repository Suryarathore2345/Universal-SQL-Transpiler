-- SOURCE: amazon-redshift-python-driver issue example
-- URL: https://github.com/aws/amazon-redshift-python-driver/issues/82
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: TEMPORARY TABLE + DISTKEY + SORTKEY
-- DESCRIPTION: Multi-statement temp-table pattern used in scripts.
CREATE TEMPORARY TABLE _tmp (
  key char(32) DISTKEY,
  payload varchar(256)
)
DISTSTYLE KEY
SORTKEY(key);
