CREATE TABLE [hr].[orders] (
    [order_id] DECIMAL(19) NOT NULL,
    [customer_id] DECIMAL(10) NOT NULL,
    [amount] DECIMAL(18,2) NOT NULL,
    [status] VARCHAR(32),
    [created_at] DATETIME2(6) NOT NULL,
    CONSTRAINT [pk_orders] PRIMARY KEY ([order_id])
);