-- SOURCE: dbeaver/dbeaver issue example
-- URL: https://github.com/dbeaver/dbeaver/issues/13218
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: BPCHAR + ENCODE + DISTSTYLE AUTO
-- DESCRIPTION: Real-world driver/export issue exposing a Redshift-specific type and auto distribution.
CREATE TABLE IF NOT EXISTS testzz(Column1 BPCHAR ENCODE lzo) DISTSTYLE AUTO;
