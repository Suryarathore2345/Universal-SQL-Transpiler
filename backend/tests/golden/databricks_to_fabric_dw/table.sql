DROP TABLE IF EXISTS [analytics].[orders];
CREATE TABLE [analytics].[orders] (
    [order_id] BIGINT NOT NULL,
    [customer_id] INT NOT NULL,
    [amount] DECIMAL(18,2) NOT NULL,
    [status] VARCHAR,
    [created_at] DATETIME2(6) NOT NULL
);