-- SOURCE: awslabs/amazon-redshift-utils issue example
-- URL: https://github.com/awslabs/amazon-redshift-utils/issues/333
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DISTSTYLE EVEN + SORTKEY + ENCODE RAW
-- DESCRIPTION: Wide event table pattern with many compressed columns.
CREATE TABLE IF NOT EXISTS public.appsclub_user_clicks(
  log_source VARCHAR(20) ENCODE RAW,
  time_stamp TIMESTAMP WITHOUT TIME ZONE ENCODE RAW,
  user_id VARCHAR(128) ENCODE RAW,
  ecid VARCHAR(10) ENCODE RAW,
  opx_user_id VARCHAR(20) ENCODE RAW,
  opx_site_id VARCHAR(20) ENCODE RAW,
  "operator" VARCHAR(20) ENCODE RAW,
  country_code VARCHAR(2) ENCODE RAW,
  platform VARCHAR(64) ENCODE RAW,
  platform_version VARCHAR(64) ENCODE RAW,
  device_make VARCHAR(96) ENCODE RAW,
  device_model VARCHAR(96) ENCODE RAW,
  network_connection VARCHAR(20) ENCODE RAW,
  browser VARCHAR(64) ENCODE RAW,
  browser_version VARCHAR(64) ENCODE RAW,
  utm_source VARCHAR(40) ENCODE RAW,
  utm_campaign VARCHAR(40) ENCODE RAW,
  utm_content VARCHAR(40) ENCODE RAW,
  distr_source VARCHAR(10) ENCODE RAW,
  subscription_status VARCHAR(20) ENCODE RAW,
  visit_id VARCHAR(20) ENCODE RAW,
  clicked_content VARCHAR(255) ENCODE RAW,
  date_created TIMESTAMP WITHOUT TIME ZONE ENCODE RAW,
  opx_site_name VARCHAR(64) ENCODE RAW,
  ip_address VARCHAR(45) ENCODE lzo
)
DISTSTYLE EVEN
SORTKEY (opx_site_id, time_stamp);
