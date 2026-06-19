-- Microsoft Fabric Lakehouse DDL (Spark SQL / Delta Lake)
-- Tests: Spark SQL syntax, backtick quoting, USING DELTA, PARTITIONED BY,
--        TBLPROPERTIES, STRING type (no length), BIGINT, DOUBLE, FLOAT, BOOLEAN

CREATE TABLE IF NOT EXISTS `bronze`.`raw_orders` (
    order_id       STRING    NOT NULL COMMENT 'Source system order ID',
    source_system  STRING    NOT NULL,
    customer_id    STRING,
    order_date     DATE,
    order_ts       TIMESTAMP,
    status         STRING,
    total_amount   DOUBLE,
    currency       STRING,
    raw_payload    STRING    COMMENT 'Original JSON payload',
    ingested_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    ingestion_date DATE      GENERATED ALWAYS AS (CAST(ingested_at AS DATE))
)
USING DELTA
PARTITIONED BY (ingestion_date)
TBLPROPERTIES (
    'delta.enableChangeDataFeed' = 'true',
    'delta.autoOptimize.optimizeWrite' = 'true'
)
COMMENT 'Bronze layer: raw order ingestion';

CREATE TABLE IF NOT EXISTS `silver`.`customers` (
    customer_id    BIGINT    NOT NULL COMMENT 'Surrogate customer key',
    source_id      STRING    NOT NULL,
    first_name     STRING,
    last_name      STRING,
    email          STRING,
    phone          STRING,
    city           STRING,
    state          STRING,
    country        STRING,
    loyalty_tier   STRING    DEFAULT 'BRONZE',
    is_active      BOOLEAN   DEFAULT TRUE,
    signup_date    DATE,
    updated_at     TIMESTAMP,
    record_hash    STRING    COMMENT 'MD5 of natural key fields'
)
USING DELTA
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true')
COMMENT 'Silver layer: cleansed customer data';

CREATE TABLE IF NOT EXISTS `gold`.`fact_sales` (
    sale_key       BIGINT     NOT NULL,
    order_id       STRING     NOT NULL,
    customer_key   BIGINT     NOT NULL,
    product_key    BIGINT     NOT NULL,
    sale_date      DATE       NOT NULL,
    sale_year      INT        GENERATED ALWAYS AS (YEAR(sale_date)),
    sale_month     INT        GENERATED ALWAYS AS (MONTH(sale_date)),
    quantity       INT        NOT NULL,
    unit_price     DECIMAL(15,4) NOT NULL,
    discount_pct   DOUBLE     DEFAULT 0.0,
    gross_amount   DECIMAL(15,4) NOT NULL,
    net_amount     DECIMAL(15,4) NOT NULL,
    status         STRING     NOT NULL
)
USING DELTA
PARTITIONED BY (sale_year, sale_month)
COMMENT 'Gold layer: fact sales';
