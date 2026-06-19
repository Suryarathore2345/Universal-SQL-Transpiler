CREATE TABLE [hr].[orders] (
    [order_id] DECIMAL NOT NULL,
    [customer_id] DECIMAL NOT NULL,
    [amount] DECIMAL(18,2) NOT NULL,
    [status] VARCHAR(32),
    [created_at] DATETIME2(6) NOT NULL
);