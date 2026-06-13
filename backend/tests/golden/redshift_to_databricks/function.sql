CREATE OR REPLACE FUNCTION `analytics`.`apply_tax`(amount DOUBLE)
RETURNS VARCHAR(MAX)
LANGUAGE PYTHON
AS $$
-- Translated from PLPYTHONU (source language: PLPYTHONU) → databricks
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
return amount * 1.1
$$;