CREATE OR ALTER PROCEDURE [analytics].[upsert_order](
    @p_order_id INT,
    @p_amount REAL
)
AS
BEGIN
-- Translated from SQL (source language: SQL) → synapse
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
END;