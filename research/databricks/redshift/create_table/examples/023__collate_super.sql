-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_SHOW_TABLE.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: COLLATE + SUPER
-- DESCRIPTION: Case-insensitive collation example with SUPER type.
CREATE TABLE public.foo (
  a CHAR,
  b VARCHAR(10) COLLATE CASE_INSENSITIVE,
  c SUPER COLLATE CASE_INSENSITIVE
);
