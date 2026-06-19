-- Snowflake: IoT Telemetry Domain Tables

CREATE OR REPLACE TABLE iot.device_registry (
    device_id       VARCHAR(50) NOT NULL,
    device_name     VARCHAR(200),
    device_type     VARCHAR(50) NOT NULL,
    model           VARCHAR(100),
    firmware_version VARCHAR(20),
    site_id         INTEGER,
    location_desc   VARCHAR(200),
    latitude        DECIMAL(10,7),
    longitude       DECIMAL(10,7),
    timezone        VARCHAR(60) DEFAULT 'UTC',
    commissioned_at TIMESTAMP_NTZ,
    decommissioned_at TIMESTAMP_NTZ,
    status          VARCHAR(20) DEFAULT 'ACTIVE',
    tags            VARIANT,
    PRIMARY KEY (device_id)
);

CREATE OR REPLACE TABLE iot.telemetry_raw (
    telemetry_id    BIGINT NOT NULL AUTOINCREMENT,
    device_id       VARCHAR(50) NOT NULL,
    metric_name     VARCHAR(100) NOT NULL,
    metric_value    FLOAT NOT NULL,
    unit            VARCHAR(20),
    quality         SMALLINT DEFAULT 100,
    recorded_at     TIMESTAMP_NTZ NOT NULL,
    ingested_at     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (telemetry_id)
)
CLUSTER BY (device_id, DATE_TRUNC('day', recorded_at));

CREATE OR REPLACE TABLE iot.telemetry_hourly (
    agg_id          BIGINT NOT NULL AUTOINCREMENT,
    device_id       VARCHAR(50) NOT NULL,
    metric_name     VARCHAR(100) NOT NULL,
    hour_start      TIMESTAMP_NTZ NOT NULL,
    min_value       FLOAT,
    max_value       FLOAT,
    avg_value       FLOAT,
    sum_value       FLOAT,
    reading_count   INTEGER,
    null_count      INTEGER DEFAULT 0,
    PRIMARY KEY (agg_id)
);

CREATE OR REPLACE TABLE iot.alerts (
    alert_id        BIGINT NOT NULL AUTOINCREMENT,
    device_id       VARCHAR(50) NOT NULL,
    alert_rule_id   INTEGER,
    alert_type      VARCHAR(50) NOT NULL,
    severity        VARCHAR(20) NOT NULL DEFAULT 'INFO',
    metric_name     VARCHAR(100),
    metric_value    FLOAT,
    threshold_value FLOAT,
    message         TEXT,
    status          VARCHAR(20) DEFAULT 'OPEN',
    triggered_at    TIMESTAMP_NTZ NOT NULL,
    acknowledged_at TIMESTAMP_NTZ,
    acknowledged_by VARCHAR(100),
    resolved_at     TIMESTAMP_NTZ,
    PRIMARY KEY (alert_id)
);

CREATE OR REPLACE TABLE iot.maintenance_records (
    maintenance_id  BIGINT NOT NULL AUTOINCREMENT,
    device_id       VARCHAR(50) NOT NULL,
    maintenance_type VARCHAR(50) NOT NULL,
    description     TEXT,
    performed_by    VARCHAR(100),
    started_at      TIMESTAMP_NTZ NOT NULL,
    completed_at    TIMESTAMP_NTZ,
    downtime_min    INTEGER DEFAULT 0,
    cost            DECIMAL(10,2),
    parts_replaced  VARIANT,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (maintenance_id)
);

CREATE OR REPLACE TABLE iot.device_configurations (
    config_id       BIGINT NOT NULL AUTOINCREMENT,
    device_id       VARCHAR(50) NOT NULL,
    config_version  INTEGER NOT NULL,
    config_json     VARIANT NOT NULL,
    applied_at      TIMESTAMP_NTZ,
    applied_by      VARCHAR(100),
    is_current      BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (config_id)
);
