CREATE OR REPLACE VIEW "analytics"."v_pending_orders" AS
SELECT order_id, customer_id, amount, created_at FROM "analytics.orders" WHERE status = 'pending';