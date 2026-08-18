-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DISTKEY + SORTKEY OPTIONS
-- DESCRIPTION: Same column declared as both distkey and sortkey.
CREATE TABLE t2(col1 int distkey sortkey, col2 int);
