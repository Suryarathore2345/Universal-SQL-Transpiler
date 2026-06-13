CREATE OR ALTER FUNCTION [analytics].[apply_tax](@amount REAL)
RETURNS REAL
AS
BEGIN
-- Translated from tsql → sqlserver
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
RETURNS FLOAT64
AS (
    amount * 1.1
)
END;