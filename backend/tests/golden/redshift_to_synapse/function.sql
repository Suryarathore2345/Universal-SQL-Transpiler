CREATE OR ALTER FUNCTION [analytics].[apply_tax](@amount FLOAT)
RETURNS VARCHAR(MAX)
AS
BEGIN
-- Translated from PLPYTHONU (source language: PLPYTHONU) → synapse
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
END;