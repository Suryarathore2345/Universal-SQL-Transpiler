CREATE TABLE [dbo].[orders] (
    [order_id] BIGINT NOT NULL,
    [customer_id] VARCHAR(MAX) NOT NULL,
    [amount] DECIMAL(18,2) NOT NULL,
    [status] VARCHAR(32),
    [created_at] DATETIME2(6) NOT NULL
)
WITH (CLUSTER BY ([customer_id]));