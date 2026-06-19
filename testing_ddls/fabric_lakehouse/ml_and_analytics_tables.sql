-- Fabric Lakehouse: ML Feature Tables and Analytics

CREATE OR REPLACE TABLE ml.customer_features (
    customer_id         BIGINT NOT NULL,
    feature_date        DATE NOT NULL,
    recency_days        INT,
    frequency_30d       INT DEFAULT 0,
    frequency_90d       INT DEFAULT 0,
    monetary_30d        DECIMAL(12,2) DEFAULT 0,
    monetary_90d        DECIMAL(12,2) DEFAULT 0,
    avg_order_value_30d DECIMAL(10,2),
    unique_categories_90d INT DEFAULT 0,
    session_count_30d   INT DEFAULT 0,
    email_open_rate_90d DECIMAL(6,4),
    churn_probability   DECIMAL(8,6),
    ltv_predicted_12m   DECIMAL(12,2),
    segment_label       STRING,
    _feature_ts         TIMESTAMP
)
USING DELTA
PARTITIONED BY (feature_date)
TBLPROPERTIES (
    'ml.feature_table' = 'true',
    'quality.layer' = 'ml'
);

CREATE OR REPLACE TABLE ml.model_predictions (
    prediction_id   STRING NOT NULL,
    model_name      STRING NOT NULL,
    model_version   STRING NOT NULL,
    entity_type     STRING NOT NULL,
    entity_id       STRING NOT NULL,
    prediction      DOUBLE,
    probability     DOUBLE,
    class_label     STRING,
    feature_values  MAP<STRING, DOUBLE>,
    predicted_at    TIMESTAMP NOT NULL,
    prediction_date DATE NOT NULL
)
USING DELTA
PARTITIONED BY (prediction_date, model_name)
TBLPROPERTIES ('quality.layer' = 'ml');

CREATE OR REPLACE TABLE analytics.ab_tests (
    test_id         BIGINT NOT NULL,
    test_name       STRING NOT NULL,
    hypothesis      STRING,
    variant_count   INT NOT NULL DEFAULT 2,
    primary_metric  STRING NOT NULL,
    status          STRING DEFAULT 'RUNNING',
    start_date      DATE NOT NULL,
    end_date        DATE,
    winner_variant  STRING,
    confidence_level DECIMAL(5,4),
    created_by      STRING,
    created_at      TIMESTAMP
)
USING DELTA
TBLPROPERTIES ('domain' = 'analytics');

CREATE OR REPLACE TABLE analytics.ab_test_assignments (
    assignment_id   BIGINT NOT NULL,
    test_id         BIGINT NOT NULL,
    user_id         BIGINT NOT NULL,
    variant_name    STRING NOT NULL,
    assigned_at     TIMESTAMP NOT NULL,
    assignment_date DATE NOT NULL
)
USING DELTA
PARTITIONED BY (assignment_date)
TBLPROPERTIES ('domain' = 'analytics');

CREATE OR REPLACE TABLE analytics.ab_test_results (
    result_id       BIGINT NOT NULL,
    test_id         BIGINT NOT NULL,
    variant_name    STRING NOT NULL,
    metric_name     STRING NOT NULL,
    sample_size     BIGINT NOT NULL DEFAULT 0,
    conversions     BIGINT NOT NULL DEFAULT 0,
    conversion_rate DECIMAL(8,6),
    revenue_per_user DECIMAL(10,4),
    avg_value       DECIMAL(12,4),
    p_value         DECIMAL(10,8),
    is_significant  BOOLEAN DEFAULT FALSE,
    lift_pct        DECIMAL(8,4),
    calculated_at   TIMESTAMP,
    result_date     DATE
)
USING DELTA
PARTITIONED BY (result_date)
TBLPROPERTIES ('domain' = 'analytics');
