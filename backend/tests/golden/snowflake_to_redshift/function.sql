CREATE OR REPLACE FUNCTION analytics.apply_tax(IN amount REAL)
RETURNS REAL
STABLE
AS $$
-- Translated from SQL (source language: SQL) → redshift
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
SELECT amount * 1.1
$$ LANGUAGE SQL;