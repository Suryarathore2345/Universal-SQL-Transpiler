CREATE TABLE "dbo"."orders" (
    "order_id" NUMBER(19) NOT NULL,
    "customer_id" VARCHAR(MAX) NOT NULL,
    "amount" NUMBER(18,2) NOT NULL,
    "status" VARCHAR(MAX) DEFAULT 'pending',
    "created_at" TIMESTAMP NOT NULL
)
PARTITION BY HASH ("customer_id") PARTITIONS 8;