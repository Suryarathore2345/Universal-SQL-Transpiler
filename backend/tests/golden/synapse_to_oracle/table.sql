CREATE TABLE "dbo"."orders" (
    "order_id" NUMBER(19) NOT NULL,
    "customer_id" NUMBER(10) NOT NULL,
    "amount" NUMBER(18,2) NOT NULL,
    "status" VARCHAR2(32) DEFAULT 'pending',
    "created_at" TIMESTAMP NOT NULL
);