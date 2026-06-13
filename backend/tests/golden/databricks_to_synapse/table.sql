CREATE TABLE [analytics].[orders] (
    [order_id] BIGINT NOT NULL,
    [customer_id] INT NOT NULL,
    [amount] DECIMAL(18,2) NOT NULL,
    [status] VARCHAR DEFAULT 'pending',
    [created_at] DATETIMEOFFSET NOT NULL
)
WITH
(
    DISTRIBUTION = ROUND_ROBIN,
    CLUSTERED COLUMNSTORE INDEX,
    PARTITION ([created_at] RANGE RIGHT FOR VALUES ())
);