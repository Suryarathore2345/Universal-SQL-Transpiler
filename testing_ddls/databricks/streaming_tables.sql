-- Databricks: Streaming / Real-time Tables

CREATE TABLE IF NOT EXISTS streaming.kafka_events_raw (
    kafka_offset    BIGINT NOT NULL,
    kafka_partition INTEGER NOT NULL,
    kafka_topic     STRING NOT NULL,
    event_key       STRING,
    event_payload   BINARY,
    event_headers   MAP<STRING, BINARY>,
    kafka_timestamp TIMESTAMP NOT NULL,
    ingest_date     DATE
)
USING DELTA
PARTITIONED BY (kafka_topic, ingest_date)
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'streaming.source' = 'kafka'
);

CREATE TABLE IF NOT EXISTS streaming.click_stream (
    event_id        STRING NOT NULL,
    session_id      STRING NOT NULL,
    user_id         BIGINT,
    anonymous_id    STRING,
    event_name      STRING NOT NULL,
    element_id      STRING,
    element_type    STRING,
    page_url        STRING,
    properties      MAP<STRING, STRING>,
    occurred_at     TIMESTAMP NOT NULL,
    processed_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    event_date      DATE
)
USING DELTA
PARTITIONED BY (event_date)
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'streaming.latency_sla_seconds' = '30'
);

CREATE TABLE IF NOT EXISTS streaming.order_events (
    event_id        STRING NOT NULL,
    order_id        BIGINT NOT NULL,
    customer_id     BIGINT,
    event_type      STRING NOT NULL,
    old_status      STRING,
    new_status      STRING,
    triggered_by    STRING,
    metadata        MAP<STRING, STRING>,
    occurred_at     TIMESTAMP NOT NULL,
    processed_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    event_date      DATE
)
USING DELTA
PARTITIONED BY (event_date)
TBLPROPERTIES ('delta.autoOptimize.optimizeWrite' = 'true');

CREATE TABLE IF NOT EXISTS streaming.payment_events (
    event_id        STRING NOT NULL,
    payment_id      STRING NOT NULL,
    order_id        BIGINT,
    event_type      STRING NOT NULL,
    amount          DECIMAL(14,2),
    currency        STRING,
    gateway         STRING,
    gateway_ref     STRING,
    error_code      STRING,
    error_message   STRING,
    occurred_at     TIMESTAMP NOT NULL,
    event_date      DATE
)
USING DELTA
PARTITIONED BY (event_date)
TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

CREATE TABLE IF NOT EXISTS streaming.inventory_changes (
    change_id       STRING NOT NULL,
    product_id      BIGINT NOT NULL,
    warehouse_id    INTEGER,
    change_type     STRING NOT NULL,
    qty_before      INTEGER,
    qty_delta       INTEGER NOT NULL,
    qty_after       INTEGER,
    reference_type  STRING,
    reference_id    STRING,
    occurred_at     TIMESTAMP NOT NULL,
    event_date      DATE
)
USING DELTA
PARTITIONED BY (event_date)
TBLPROPERTIES ('delta.autoOptimize.optimizeWrite' = 'true');
