-- Expected Snowflake output for input_table_basic.sql
-- Key transformations:
--   IDENTITY(1,1)       → IDENTITY(1,1)        [same syntax in Snowflake]
--   DECIMAL(18,2)       → NUMBER(18,2)          [Snowflake NUMBER = DECIMAL]
--   VARCHAR(65535)      → VARCHAR(65535)        [within Snowflake's 16MB limit]
--   BOOLEAN             → BOOLEAN
--   TIMESTAMPTZ         → TIMESTAMP_TZ
--   SUPER               → VARIANT              [Snowflake semi-structured equivalent]
--   VARBYTE             → VARBINARY
--   DISTSTYLE KEY       → removed + INFO warning (Snowflake manages distribution)
--   COMPOUND SORTKEY    → CLUSTER BY (order_date, customer_id)   [closest equivalent]

CREATE TABLE "public"."orders" (
    "order_id" NUMBER NOT NULL IDENTITY(1,1),
    "customer_id" NUMBER NOT NULL,
    "order_date" DATE NOT NULL,
    "amount" NUMBER(18,2) NOT NULL,
    "status" VARCHAR(50),
    "notes" VARCHAR(65535),
    "is_active" BOOLEAN DEFAULT TRUE,
    "created_at" TIMESTAMP_TZ DEFAULT SYSDATE,
    "metadata" VARIANT,
    "raw_bytes" VARBINARY
)
CLUSTER BY ("order_date", "customer_id");
