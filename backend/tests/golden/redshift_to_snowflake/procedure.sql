CREATE OR REPLACE PROCEDURE analytics.upsert_order(p_order_id INTEGER, p_amount VARCHAR(MAX))
RETURNS VARIANT
LANGUAGE PLPGSQL
AS
$$
-- Translated from PLPGSQL (source language: PLPGSQL) → snowflake
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
    INSERT INTO analytics.orders(order_id, amount)
    VALUES (p_order_id, p_amount);
END;
$$;