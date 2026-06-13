CREATE OR REPLACE PROCEDURE "analytics"."upsert_order"(
    p_order_id IN NUMBER(3),
    p_amount IN NUMBER
)
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
CREATE OR REPLACE PROCEDURE `analytics.upsert_order`(
    IN p_order_id INT64,
    IN p_amount   NUMERIC
)
BEGIN
    INSERT INTO `analytics.orders`(order_id, amount)
    VALUES (p_order_id, p_amount)
END upsert_order;