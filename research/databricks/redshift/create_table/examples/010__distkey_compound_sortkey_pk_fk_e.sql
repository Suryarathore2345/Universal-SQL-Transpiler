-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DISTKEY + COMPOUND SORTKEY + PK/FK + ENCODE
-- DESCRIPTION: Canonical warehouse SALES table with compression and relational constraints.
CREATE TABLE sales(
  salesid integer not null,
  listid integer not null,
  sellerid integer not null,
  buyerid integer not null,
  eventid integer not null encode mostly16,
  dateid smallint not null,
  qtysold smallint not null encode mostly8,
  pricepaid decimal(8,2) encode delta32k,
  commission decimal(8,2) encode delta32k,
  saletime timestamp,
  primary key(salesid),
  foreign key(listid) references listing(listid),
  foreign key(sellerid) references users(userid)
)
distkey(listid)
sortkey(listid, sellerid);
