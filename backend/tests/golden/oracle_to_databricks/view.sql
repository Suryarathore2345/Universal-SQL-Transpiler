CREATE OR REPLACE VIEW `hr`.`v_pending_orders` AS
SELECT order_id, customer_id, amount, created_at FROM hr.orders WHERE status = 'pending';