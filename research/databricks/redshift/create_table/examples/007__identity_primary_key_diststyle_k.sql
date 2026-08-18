-- SOURCE: snowplow/snowplow redshift storage definition
-- URL: https://github.com/snowplow/snowplow/blob/master/4-storage/redshift-storage/sql/atomic-def.sql
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: IDENTITY + PRIMARY KEY + DISTSTYLE KEY + DISTKEY + SORTKEY + COMMENT
-- DESCRIPTION: Large event fact table with column encodings and warehouse tuning.
CREATE TABLE atomic.events (
  event_id BIGINT IDENTITY(1,1),
  collector_tstamp TIMESTAMP ENCODE ZSTD,
  event_fingerprint VARCHAR(128) ENCODE ZSTD,
  true_tstamp TIMESTAMP ENCODE ZSTD,
  CONSTRAINT event_id_0110_pk PRIMARY KEY(event_id)
)
DISTSTYLE KEY
DISTKEY (event_id)
SORTKEY (collector_tstamp);
