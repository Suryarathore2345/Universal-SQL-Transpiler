CREATE TABLE "analytics"."orders" (
    "order_id" NUMBER(19) NOT NULL,
    "customer_id" NUMBER(10) NOT NULL,
    "amount" NUMBER(18,2) NOT NULL,
    "status" VARCHAR2 DEFAULT 'pending',
    "created_at" TIMESTAMP WITH TIME ZONE NOT NULL
)
PARTITION BY LIST ("created_at") PARTITIONS 8;