-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: IF NOT EXISTS
-- DESCRIPTION: Basic create-if-missing warehouse table.
CREATE TABLE IF NOT EXISTS cities(
  cityid integer not null,
  city varchar(100) not null,
  state char(2) not null
);
