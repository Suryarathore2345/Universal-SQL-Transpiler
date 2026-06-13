CREATE OR REPLACE PROCEDURE analytics.upsert_order(p_order_id INTEGER, p_amount FLOAT)
RETURNS VARIANT
LANGUAGE SQL
AS
$$
-- Translated from SQL (source language: SQL) → snowflake
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
DECLARE
    v_count INT;
BEGIN
    INSERT INTO analytics.orders(order_id, amount)
    VALUES (p_order_id, p_amount);
    RETURN 'OK';
END;
$$;