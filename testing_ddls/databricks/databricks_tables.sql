-- Databricks SQL / Delta Lake DDL
-- Tests: USING DELTA, LOCATION, PARTITIONED BY, TBLPROPERTIES,
--        backtick identifiers, COMMENT, GENERATED columns

CREATE TABLE IF NOT EXISTS `analytics`.`sales_orders` (
    order_id        BIGINT        NOT NULL COMMENT 'Unique order identifier',
    customer_id     BIGINT        NOT NULL,
    order_date      DATE          NOT NULL,
    order_timestamp TIMESTAMP     NOT NULL,
    status          STRING        NOT NULL DEFAULT 'PENDING',
    total_amount    DECIMAL(15,2),
    discount_pct    DOUBLE,
    is_priority     BOOLEAN       DEFAULT FALSE,
    order_year      INT           GENERATED ALWAYS AS (YEAR(order_date)),
    order_month     INT           GENERATED ALWAYS AS (MONTH(order_date)),
    region          STRING,
    tags            ARRAY<STRING>,
    attributes      MAP<STRING, STRING>
)
USING DELTA
PARTITIONED BY (order_year, order_month)
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'delta.autoOptimize.autoCompact'   = 'true'
)
COMMENT 'Transactional sales orders fact table';

CREATE TABLE IF NOT EXISTS `analytics`.`customers` (
    customer_id    BIGINT   NOT NULL,
    first_name     STRING   NOT NULL,
    last_name      STRING   NOT NULL,
    email          STRING   NOT NULL,
    phone          STRING,
    city           STRING,
    state          STRING,
    country        STRING,
    signup_date    DATE,
    loyalty_tier   STRING   DEFAULT 'BRONZE',
    is_active      BOOLEAN  DEFAULT TRUE,
    preferences    MAP<STRING, STRING>,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true')
COMMENT 'Customer dimension table';

CREATE TABLE IF NOT EXISTS `analytics`.`products` (
    product_id   BIGINT        NOT NULL,
    sku          STRING        NOT NULL,
    product_name STRING        NOT NULL,
    category     STRING,
    sub_category STRING,
    unit_price   DECIMAL(12,4) NOT NULL,
    cost_price   DECIMAL(12,4),
    stock_qty    INT           DEFAULT 0,
    weight_kg    FLOAT,
    attributes   MAP<STRING, STRING>,
    is_active    BOOLEAN       DEFAULT TRUE,
    updated_at   TIMESTAMP
)
USING DELTA
COMMENT 'Product catalog dimension';

CREATE TABLE IF NOT EXISTS `analytics`.`events` (
    event_id     STRING    NOT NULL,
    session_id   STRING,
    user_id      BIGINT,
    event_type   STRING    NOT NULL,
    event_ts     TIMESTAMP NOT NULL,
    event_date   DATE      GENERATED ALWAYS AS (CAST(event_ts AS DATE)),
    page_url     STRING,
    device_type  STRING,
    country_code STRING,
    properties   MAP<STRING, STRING>
)
USING DELTA
PARTITIONED BY (event_date)
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true'
)
COMMENT 'User event tracking table';
