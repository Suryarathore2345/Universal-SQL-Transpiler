-- BigQuery: IoT Telemetry Tables

CREATE OR REPLACE TABLE `analytics.iot.device_registry` (
    device_id       STRING NOT NULL,
    device_name     STRING,
    device_type     STRING NOT NULL,
    model           STRING,
    firmware        STRING,
    site_id         INT64,
    location        STRUCT<
        description STRING,
        latitude    FLOAT64,
        longitude   FLOAT64,
        timezone    STRING,
        indoor      BOOL
    >,
    tags            JSON,
    commissioned_at TIMESTAMP,
    decommissioned_at TIMESTAMP,
    status          STRING DEFAULT 'ACTIVE'
);

CREATE OR REPLACE TABLE `analytics.iot.telemetry` (
    telemetry_id    STRING NOT NULL,
    device_id       STRING NOT NULL,
    metric_name     STRING NOT NULL,
    metric_value    FLOAT64 NOT NULL,
    unit            STRING,
    quality         INT64 DEFAULT 100,
    tags            JSON,
    recorded_at     TIMESTAMP NOT NULL,
    recorded_date   DATE NOT NULL
)
PARTITION BY recorded_date
CLUSTER BY device_id, metric_name
OPTIONS (
    partition_expiration_days = 365,
    require_partition_filter = TRUE,
    description = 'Raw IoT telemetry readings'
);

CREATE OR REPLACE TABLE `analytics.iot.alerts` (
    alert_id        INT64 NOT NULL,
    device_id       STRING NOT NULL,
    rule_name       STRING,
    alert_type      STRING NOT NULL,
    severity        STRING NOT NULL,
    metric_name     STRING,
    metric_value    FLOAT64,
    threshold       FLOAT64,
    message         STRING,
    status          STRING DEFAULT 'OPEN',
    triggered_at    TIMESTAMP NOT NULL,
    resolved_at     TIMESTAMP,
    alert_date      DATE NOT NULL
)
PARTITION BY alert_date
CLUSTER BY device_id, severity;

CREATE OR REPLACE TABLE `analytics.iot.device_metrics_hourly` (
    agg_id          INT64 NOT NULL,
    device_id       STRING NOT NULL,
    metric_name     STRING NOT NULL,
    hour_start      TIMESTAMP NOT NULL,
    min_value       FLOAT64,
    max_value       FLOAT64,
    avg_value       FLOAT64,
    p50_value       FLOAT64,
    p95_value       FLOAT64,
    reading_count   INT64,
    agg_date        DATE NOT NULL
)
PARTITION BY agg_date
CLUSTER BY device_id, metric_name;
