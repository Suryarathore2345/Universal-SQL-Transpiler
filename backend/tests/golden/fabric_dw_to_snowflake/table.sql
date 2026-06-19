CREATE TABLE dbo.orders (
    "order_id" BIGINT NOT NULL,
    "customer_id" VARCHAR(MAX) NOT NULL,
    "amount" NUMBER(18,2) NOT NULL,
    "status" VARCHAR(32) DEFAULT 'pending',
    "created_at" TIMESTAMP_NTZ NOT NULL
)
CLUSTER BY ("customer_id");