CREATE TABLE [dbo].[orders] (
    [order_id] BIGINT NOT NULL,
    [customer_id] INT NOT NULL,
    [amount] DECIMAL(18,2) NOT NULL,
    [status] VARCHAR(32),
    [created_at] DATETIME2(6) NOT NULL
);

ALTER TABLE [dbo].[orders] ADD CONSTRAINT [PK_orders] PRIMARY KEY NONCLUSTERED ([order_id]) NOT ENFORCED;