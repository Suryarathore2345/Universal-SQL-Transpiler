CREATE TABLE analytics.orders (
    "order_id" INT2 NOT NULL,
    "customer_id" INT2 NOT NULL,
    "amount" DECIMAL(18,2) NOT NULL,
    "status" CHAR DEFAULT 'pending',
    "created_at" TIMESTAMPTZ NOT NULL
);