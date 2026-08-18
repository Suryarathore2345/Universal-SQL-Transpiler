-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DISTKEY + SORTKEY OPTIONS
-- DESCRIPTION: Column-level distkey and sortkey syntax variants.
CREATE TABLE t1(col1 int distkey, col2 int) diststyle key;
