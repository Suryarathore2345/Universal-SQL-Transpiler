DROP TABLE IF EXISTS [analytics].[orders];
GO
CREATE TABLE [analytics].[orders] (
    [order_id] BIGINT NOT NULL,
    [customer_id] BIGINT NOT NULL,
    [amount] DECIMAL(18,2) NOT NULL,
    [status] VARCHAR(MAX) DEFAULT 'pending',
    [created_at] DATETIMEOFFSET NOT NULL
);