CREATE OR REPLACE TABLE analytics.orders (
    "order_id" BIGINT NOT NULL,
    "customer_id" INTEGER NOT NULL,
    "amount" NUMBER(18,2) NOT NULL,
    "status" VARCHAR(32) DEFAULT 'pending',
    "created_at" TIMESTAMP_NTZ NOT NULL,
    PRIMARY KEY ("order_id")
)
CLUSTER BY ("created_at");