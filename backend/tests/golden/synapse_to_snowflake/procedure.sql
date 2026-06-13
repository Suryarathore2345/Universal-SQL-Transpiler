CREATE PROCEDURE dbo.upsert_order()
RETURNS VARIANT
LANGUAGE SQL
AS
$$
-- Translated from unknown → snowflake
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
    INSERT INTO dbo.orders(order_id, amount)
    VALUES (@p_order_id, @p_amount)
$$;