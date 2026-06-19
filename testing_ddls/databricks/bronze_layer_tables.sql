-- Databricks: Bronze Layer (Raw Ingestion) Tables

CREATE TABLE IF NOT EXISTS bronze.raw_orders (
    order_id        BIGINT NOT NULL,
    customer_id     BIGINT,
    order_json      STRING,
    source_system   STRING,
    ingestion_ts    TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    batch_id        STRING,
    file_path       STRING,
    row_hash        STRING,
    is_duplicate    BOOLEAN DEFAULT FALSE,
    ingest_date     DATE
)
USING DELTA
PARTITIONED BY (ingest_date)
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'delta.autoOptimize.autoCompact' = 'true',
    'quality.layer' = 'bronze'
);

CREATE TABLE IF NOT EXISTS bronze.raw_customers (
    record_id       BIGINT NOT NULL,
    customer_id     BIGINT,
    email           STRING,
    raw_payload     STRING,
    source_system   STRING NOT NULL,
    operation       STRING,
    ingestion_ts    TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
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
    raw_properties  STRING,
    ip_address      STRING,
    user_agent      STRING,
    occurred_at     TIMESTAMP NOT NULL,
    ingestion_ts    TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    source          STRING,
    ingest_date     DATE
)
USING DELTA
PARTITIONED BY (ingest_date, source)
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'delta.logRetentionDuration' = 'interval 30 days',
    'quality.layer' = 'bronze'
);

CREATE TABLE IF NOT EXISTS bronze.raw_inventory (
    record_id       BIGINT NOT NULL AUTOINCREMENT,
    warehouse_id    INTEGER,
    product_id      BIGINT,
    quantity        INTEGER,
    snapshot_ts     TIMESTAMP NOT NULL,
    raw_payload     STRING,
    ingestion_ts    TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    ingest_date     DATE
)
USING DELTA
PARTITIONED BY (ingest_date)
TBLPROPERTIES ('quality.layer' = 'bronze');

CREATE TABLE IF NOT EXISTS bronze.raw_payments (
    payment_id      STRING NOT NULL,
    order_id        BIGINT,
    amount          DECIMAL(14,2),
    currency        STRING,
    payment_method  STRING,
    gateway         STRING,
    raw_response    STRING,
    occurred_at     TIMESTAMP,
    ingestion_ts    TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    ingest_date     DATE
)
USING DELTA
PARTITIONED BY (ingest_date)
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'quality.layer' = 'bronze'
);

CREATE TABLE IF NOT EXISTS bronze.raw_support_tickets (
    ticket_raw_id   BIGINT NOT NULL AUTOINCREMENT,
    ticket_id       STRING,
    account_id      BIGINT,
    raw_payload     STRING,
    source          STRING,
    ingestion_ts    TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    ingest_date     DATE
)
USING DELTA
PARTITIONED BY (ingest_date);
