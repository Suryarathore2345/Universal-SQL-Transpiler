DROP TABLE IF EXISTS analytics.orders;
CREATE TABLE analytics.orders (
    "order_id" BIGINT NOT NULL,
    "customer_id" INTEGER NOT NULL,
    "amount" DECIMAL(18,2) NOT NULL,
    "status" VARCHAR DEFAULT 'pending',
    "created_at" TIMESTAMPTZ NOT NULL
);