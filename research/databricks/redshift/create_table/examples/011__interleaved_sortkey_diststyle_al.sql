-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: INTERLEAVED SORTKEY + DISTSTYLE ALL
-- DESCRIPTION: Interleaved sort example used for customer-style lookup patterns.
CREATE TABLE customer_interleaved (
  c_custkey integer not null,
  c_name varchar(25) not null,
  c_address varchar(25) not null,
  c_city varchar(10) not null,
  c_nation varchar(15) not null,
  c_region varchar(12) not null,
  c_phone varchar(15) not null,
  c_mktsegment varchar(10) not null
)
diststyle all
interleaved sortkey (c_custkey, c_city, c_mktsegment);
