-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: ENCODE AUTO + EXPLICIT ENCODE
-- DESCRIPTION: Explicit encoding seeds that Redshift may later optimize automatically.
CREATE TABLE t4(c0 int encode delta, c1 varchar encode lzo) encode auto;
