CREATE TABLE [analytics].[orders] (
    [order_id] BIGINT NOT NULL,
    [customer_id] INT NOT NULL,
    [amount] DECIMAL(18,2) NOT NULL,
    [status] VARCHAR(32),
    [created_at] DATETIME2(6) NOT NULL
)
WITH (CLUSTER BY ([created_at]));

ALTER TABLE [analytics].[orders] ADD CONSTRAINT [PK_orders] PRIMARY KEY NONCLUSTERED ([order_id]) NOT ENFORCED;