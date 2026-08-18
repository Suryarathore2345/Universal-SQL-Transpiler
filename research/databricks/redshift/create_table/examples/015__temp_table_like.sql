-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: TEMP TABLE + LIKE
-- DESCRIPTION: Temporary table inheriting structure from an existing table.
CREATE TEMP TABLE tempevent(like event);
