# Redshift Dialect — Official Documentation References

All syntax rules, type mappings, and limitation decisions in this module are
sourced from the following official AWS documentation pages (verified June 2026).

## Data Types
- Full type list: https://docs.aws.amazon.com/redshift/latest/dg/c_Supported_data_types.html
- Numeric types: https://docs.aws.amazon.com/redshift/latest/dg/r_Numeric_types201.html
- Character types: https://docs.aws.amazon.com/redshift/latest/dg/r_Character_types.html
- Datetime types: https://docs.aws.amazon.com/redshift/latest/dg/r_Datetime_types.html
- Boolean: https://docs.aws.amazon.com/redshift/latest/dg/r_Boolean_type.html
- SUPER type: https://docs.aws.amazon.com/redshift/latest/dg/r_SUPER_type.html
- VARBYTE: https://docs.aws.amazon.com/redshift/latest/dg/r_VARBYTE_type.html
- HLLSKETCH: https://docs.aws.amazon.com/redshift/latest/dg/r_HLLSKTECH_type.html

## DDL Statements
- CREATE TABLE: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html
- CREATE VIEW: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_VIEW.html
- CREATE MATERIALIZED VIEW: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_MATERIALIZED_VIEW.html
- CREATE PROCEDURE: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_PROCEDURE.html
- CREATE FUNCTION: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_FUNCTION.html
- CREATE SCHEMA: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_SCHEMA.html
- ALTER TABLE: https://docs.aws.amazon.com/redshift/latest/dg/r_ALTER_TABLE.html

## Distribution & Sort Keys
- DISTSTYLE/DISTKEY: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html#r_CREATE_TABLE_NEW-parameters-distkey
- SORTKEY: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html#r_CREATE_TABLE_NEW-parameters-sortkey
- Choosing distribution style: https://docs.aws.amazon.com/redshift/latest/dg/c_best-practices-best-dist-key.html

## Identity / Auto-Increment
- IDENTITY(seed, step): https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html

## MV Refresh
- AUTO REFRESH: https://docs.aws.amazon.com/redshift/latest/dg/materialized-view-refresh.html

## Stored Procedures
- PL/pgSQL language: https://docs.aws.amazon.com/redshift/latest/dg/stored-procedure-overview.html
- Supported PL/pgSQL constructs: https://docs.aws.amazon.com/redshift/latest/dg/c_PLpgSQL-supported-constructs.html

## SQL Reference (general)
- https://docs.aws.amazon.com/redshift/latest/dg/cm_chap_SQLCommandRef.html
