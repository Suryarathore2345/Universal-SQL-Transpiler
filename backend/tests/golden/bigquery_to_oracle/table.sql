CREATE TABLE "analytics"."orders" (
    "order_id" NUMBER(3) NOT NULL,
    "customer_id" NUMBER(3) NOT NULL,
    "amount" NUMBER(18,2) NOT NULL,
    "status" CHAR DEFAULT 'pending',
    "created_at" TIMESTAMP WITH TIME ZONE NOT NULL
)
PARTITION BY DATE ("created_at");