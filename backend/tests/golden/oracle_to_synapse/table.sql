CREATE TABLE [hr].[orders] (
    [order_id] DECIMAL(19) IDENTITY(1,1) NOT NULL,
    [customer_id] DECIMAL(10) NOT NULL,
    [amount] DECIMAL(18,2) NOT NULL,
    [status] VARCHAR(32) DEFAULT 'pending',
    [created_at] DATETIME2 NOT NULL
)
WITH
(
    DISTRIBUTION = ROUND_ROBIN,
    CLUSTERED COLUMNSTORE INDEX
);