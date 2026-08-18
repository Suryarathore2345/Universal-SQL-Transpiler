-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: IDENTITY + PRIMARY KEY
-- DESCRIPTION: Example table with an identity column and primary key.
CREATE TABLE venue_ident(
  venueid bigint identity(0, 1),
  venuename varchar(100),
  venuecity varchar(30),
  venuestate char(2),
  venueseats integer,
  primary key(venueid)
);
