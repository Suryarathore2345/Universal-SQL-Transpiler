CREATE OR REPLACE FUNCTION hr.apply_tax(IN p_amount VARCHAR(MAX))
RETURNS FLOAT
STABLE
AS $$
-- Translated from unknown → redshift
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
BEGIN
    RETURN p_amount * 1.1
$$ LANGUAGE plpythonu;