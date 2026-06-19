CREATE TABLE [dbo].[orders] (
    [order_id] BIGINT IDENTITY(1,1) NOT NULL,
    [customer_id] INT NOT NULL,
    [amount] DECIMAL(18,2) NOT NULL,
    [status] VARCHAR(32) DEFAULT 'pending',
    [created_at] DATETIME2 NOT NULL,
    PRIMARY KEY NONCLUSTERED ([order_id]) NOT ENFORCED
)
WITH
(
    DISTRIBUTION = ROUND_ROBIN,
    CLUSTERED COLUMNSTORE INDEX
);