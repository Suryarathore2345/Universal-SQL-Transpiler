CREATE TABLE [analytics].[orders] (
    [order_id] SMALLINT NOT NULL,
    [customer_id] SMALLINT NOT NULL,
    [amount] DECIMAL(18,2) NOT NULL,
    [status] CHAR DEFAULT 'pending',
    [created_at] DATETIME2 NOT NULL
);