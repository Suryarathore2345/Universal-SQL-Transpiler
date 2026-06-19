-- Google BigQuery DDL
-- Tests: BigQuery-specific syntax, OPTIONS, PARTITION BY, CLUSTER BY,
--        STRUCT, ARRAY, INT64, FLOAT64, BIGNUMERIC, GEOGRAPHY

CREATE OR REPLACE TABLE `my_project.sales.orders` (
    order_id        INT64         NOT NULL OPTIONS(description='Unique order identifier'),
    customer_id     INT64         NOT NULL,
    order_date      DATE          NOT NULL,
    order_ts        TIMESTAMP     NOT NULL,
    status          STRING        NOT NULL,
    total_amount    NUMERIC(15,2),
    discount_pct    FLOAT64,
    is_priority     BOOL          DEFAULT FALSE,
    region          STRING,
    shipping_addr   STRUCT<
        line1    STRING,
        city     STRING,
        state    STRING,
        zip      STRING,
        country  STRING
    >,
    item_keys       ARRAY<INT64>,
    created_at      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(order_ts)
CLUSTER BY customer_id, status
OPTIONS(
    description='Sales orders fact table',
    labels=[('env','prod'),('team','data')]
);

CREATE OR REPLACE TABLE `my_project.sales.customers` (
    customer_id   INT64    NOT NULL OPTIONS(description='Customer surrogate key'),
    first_name    STRING   NOT NULL,
    last_name     STRING   NOT NULL,
    email         STRING   NOT NULL,
    phone         STRING,
    location      GEOGRAPHY,
    address       STRUCT<
        city     STRING,
        state    STRING,
        country  STRING,
        zip      STRING
    >,
    loyalty_tier  STRING   DEFAULT 'BRONZE',
    signup_date   DATE,
    is_active     BOOL     DEFAULT TRUE,
    tags          ARRAY<STRING>,
    preferences   JSON
)
OPTIONS(description='Customer dimension');

CREATE OR REPLACE TABLE `my_project.analytics.events` (
    event_id     STRING    NOT NULL,
    session_id   STRING,
    user_id      INT64,
    event_type   STRING    NOT NULL,
    event_ts     TIMESTAMP NOT NULL,
    page_url     STRING,
    device_type  STRING,
    country_code STRING,
    properties   JSON
)
PARTITION BY DATE(event_ts)
CLUSTER BY event_type, country_code
OPTIONS(
    partition_expiration_days=365,
    description='User event tracking'
);

CREATE OR REPLACE TABLE `my_project.finance.transactions` (
    transaction_id  STRING        NOT NULL,
    account_id      INT64         NOT NULL,
    txn_date        DATE          NOT NULL,
    txn_ts          TIMESTAMP     NOT NULL,
    txn_type        STRING        NOT NULL,
    amount          BIGNUMERIC    NOT NULL,
    currency        STRING(3)     NOT NULL,
    balance_after   BIGNUMERIC,
    description     STRING,
    metadata        JSON
)
PARTITION BY txn_date
OPTIONS(require_partition_filter=TRUE);
