CREATE OR REPLACE FUNCTION "hr"."apply_tax"(p_amount IN VARCHAR(MAX))
RETURN VARCHAR2(4000)
AS
BEGIN
-- Translated from plsql → oracle
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
END apply_tax;