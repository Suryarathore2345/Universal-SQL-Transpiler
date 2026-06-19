CREATE OR REPLACE TABLE analytics.orders (
    "order_id" BIGINT NOT NULL,
    "customer_id" INTEGER NOT NULL,
    "amount" NUMBER(18,2) NOT NULL,
    "status" VARCHAR DEFAULT 'pending',
    "created_at" TIMESTAMP_TZ NOT NULL
);