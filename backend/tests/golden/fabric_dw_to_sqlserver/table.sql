CREATE TABLE [dbo].[orders] (
    [order_id] BIGINT NOT NULL,
    [customer_id] VARCHAR(MAX) NOT NULL,
    [amount] DECIMAL(18,2) NOT NULL,
    [status] VARCHAR(MAX) DEFAULT 'pending',
    [created_at] DATETIME2 NOT NULL
);