-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: SORTKEY + DISTSTYLE ALL
-- DESCRIPTION: Sortkey declared at column level with ALL distribution.
CREATE TABLE t3(col1 int, col2 int sortkey) diststyle all;
