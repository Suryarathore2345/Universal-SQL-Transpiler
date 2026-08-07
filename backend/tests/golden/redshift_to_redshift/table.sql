CREATE TABLE "analytics"."orders" (
    "order_id" BIGINT NOT NULL,
    "customer_id" INTEGER NOT NULL,
    "amount" DECIMAL(18,2) NOT NULL,
    "status" VARCHAR(32) DEFAULT 'pending',
    "created_at" TIMESTAMP NOT NULL,
    PRIMARY KEY ("order_id")
)
DISTSTYLE KEY
DISTKEY ("customer_id")
SORTKEY ("created_at");