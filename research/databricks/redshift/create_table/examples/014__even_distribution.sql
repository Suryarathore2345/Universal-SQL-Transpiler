-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: EVEN DISTRIBUTION
-- DESCRIPTION: Evenly distributed table with no explicit sort key.
CREATE TABLE myevent(
  eventid int,
  eventname varchar(200),
  eventcity varchar(30)
)
diststyle even;
