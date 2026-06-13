CREATE TABLE [hr].[orders] (
    [order_id] DECIMAL IDENTITY(1,1) NOT NULL,
    [customer_id] DECIMAL NOT NULL,
    [amount] DECIMAL(18,2) NOT NULL,
    [status] VARCHAR(32) DEFAULT 'pending',
    [created_at] DATETIME2 NOT NULL
);