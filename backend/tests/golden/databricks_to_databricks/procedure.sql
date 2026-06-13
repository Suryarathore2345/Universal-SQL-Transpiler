-- Databricks does NOT support CREATE PROCEDURE.
-- Docs: https://docs.databricks.com/en/sql/language-manual/
-- Converted to a SQL UDF. Body requires significant manual adaptation.
CREATE OR REPLACE FUNCTION `analytics`.`upsert_order`(p_order_id INT, p_amount VARCHAR(MAX))
RETURNS STRING
RETURN (
  -- -- Translated from PLPGSQL (source language: PLPGSQL) → databricks
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
  -- Original body preserved below — NOT executable as-is:
  -- BEGIN
  --     INSERT INTO analytics.orders(order_id, amount)
  --     VALUES (p_order_id, p_amount);
  -- END;
  NULL
);