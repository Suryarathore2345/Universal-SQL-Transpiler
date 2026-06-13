CREATE OR REPLACE FUNCTION `analytics`.`apply_tax`(IN amount FLOAT64)
RETURNS ANY TYPE
AS (
  -- Translated from sql → bigquery
-- ============================================================
-- MANUAL REVIEW REQUIRED
-- The procedural body has been preserved from the source dialect.
-- Review and adapt the following before deploying:
--   1. Variable declaration syntax
--   2. Exception/error handling
--   3. Cursor syntax
--   4. Transaction control
--   5. Dialect-specific built-in functions
-- ============================================================
  CREATE OR REPLACE FUNCTION analytics.apply_tax(amount DOUBLE)
RETURNS DOUBLE
RETURN amount * 1.1
);