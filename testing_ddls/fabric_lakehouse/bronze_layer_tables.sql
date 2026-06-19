-- Fabric Lakehouse (Spark SQL / Delta): Bronze Layer Tables

CREATE TABLE IF NOT EXISTS bronze.raw_orders (
    order_id        BIGINT,
    customer_id     BIGINT,
    order_json      STRING,
    source_system   STRING NOT NULL,
    operation       STRING,
    ingestion_ts    TIMESTAMP,
    batch_id        STRING,
    file_path       STRING,
    row_hash        STRING,
    is_duplicate    BOOLEAN DEFAULT FALSE,
    ingest_date     DATE
)
USING DELTA
PARTITIONED BY (ingest_date, source_system)
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'delta.autoOptimize.autoCompact' = 'true',
    'quality.layer' = 'bronze'
);

CREATE TABLE IF NOT EXISTS bronze.raw_customers (
    record_id       BIGINT,
    customer_id     BIGINT,
    email           STRING,
    payload         STRING,
    source_system   STRING NOT NULL,
    operation       STRING,
    ingestion_ts    TIMESTAMP,
    batch_id        STRING,
    ingest_date     DATE
)
USING DELTA
PARTITIONED BY (ingest_date, source_system)
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'quality.layer' = 'bronze'
);

CREATE TABLE IF NOT EXISTS bronze.raw_events (
    event_id        STRING NOT NULL,
    event_name      STRING,
    user_id         BIGINT,
    session_id      STRING,
    properties      STRING,
    ip_address      STRING,
    user_agent      STRING,
    occurred_at     TIMESTAMP,
    ingestion_ts    TIMESTAMP,
    source          STRING,
    ingest_date     DATE
)
USING DELTA
PARTITIONED BY (ingest_date)
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'quality.layer' = 'bronze'
);

CREATE TABLE IF NOT EXISTS bronze.raw_products (
    product_id      BIGINT,
    sku             STRING,
    product_name    STRING,
    payload         STRING,
    source_system   STRING NOT NULL,
    operation       STRING,
    ingestion_ts    TIMESTAMP,
    ingest_date     DATE
)
USING DELTA
PARTITIONED BY (ingest_date)
TBLPROPERTIES ('quality.layer' = 'bronze');

CREATE TABLE IF NOT EXISTS bronze.raw_payments (
    payment_id      STRING,
    order_id        BIGINT,
    amount          DECIMAL(14,2),
    currency        STRING,
    gateway         STRING,
    raw_response    STRING,
    occurred_at     TIMESTAMP,
    ingestion_ts    TIMESTAMP,
    ingest_date     DATE
)
USING DELTA
PARTITIONED BY (ingest_date)
TBLPROPERTIES ('quality.layer' = 'bronze');

CREATE TABLE IF NOT EXISTS bronze.raw_inventory (
    snapshot_ts     TIMESTAMP NOT NULL,
    warehouse_id    INT,
    product_id      BIGINT,
    quantity        INT,
    payload         STRING,
    ingestion_ts    TIMESTAMP,
    ingest_date     DATE
)
USING DELTA
PARTITIONED BY (ingest_date)
TBLPROPERTIES ('quality.layer' = 'bronze');
