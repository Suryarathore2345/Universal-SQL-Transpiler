CREATE TABLE dbo.orders (
    "order_id" BIGINT IDENTITY(1,1) NOT NULL,
    "customer_id" INTEGER NOT NULL,
    "amount" NUMBER(18,2) NOT NULL,
    "status" VARCHAR(MAX) DEFAULT 'pending',
    "created_at" TIMESTAMP_NTZ NOT NULL,
    PRIMARY KEY ("order_id")
);