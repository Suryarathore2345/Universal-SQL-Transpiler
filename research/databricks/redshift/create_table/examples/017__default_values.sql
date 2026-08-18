-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DEFAULT VALUES
-- DESCRIPTION: Table showing default literal values for every column.
CREATE TABLE categorydef(
  catid smallint not null default 0,
  catgroup varchar(10) default 'Special',
  catname varchar(10) default 'Other',
  catdesc varchar(50) default 'Special events',
  primary key(catid)
);
