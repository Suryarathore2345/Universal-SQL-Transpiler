CREATE VIEW [dbo].[v_pending_orders] AS
SELECT order_id, customer_id, amount, created_at FROM dbo.orders WHERE status = 'pending';