CREATE FUNCTION "dbo"."apply_tax"(amount IN VARCHAR(MAX))
RETURN NUMBER(18,4)
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
    RETURN @amount * 1.1
END apply_tax;