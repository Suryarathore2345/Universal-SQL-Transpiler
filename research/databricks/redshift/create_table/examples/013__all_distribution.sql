-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: ALL DISTRIBUTION
-- DESCRIPTION: Small replicated dimension table.
CREATE TABLE venue(
  venueid smallint not null,
  venuename varchar(100),
  venuecity varchar(30),
  venuestate char(2),
  venueseats integer,
  primary key(venueid)
)
diststyle all;
