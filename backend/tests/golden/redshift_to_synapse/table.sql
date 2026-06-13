CREATE TABLE [analytics].[orders] (
    [order_id] BIGINT NOT NULL,
    [customer_id] INT NOT NULL,
    [amount] DECIMAL(18,2) NOT NULL,
    [status] VARCHAR(32) DEFAULT 'pending',
    [created_at] DATETIME2 NOT NULL,
    PRIMARY KEY NONCLUSTERED ([order_id]) NOT ENFORCED
)
WITH
(
    DISTRIBUTION = HASH([CREATED_AT]),
    CLUSTERED COLUMNSTORE INDEX
);