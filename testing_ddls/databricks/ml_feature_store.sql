-- Databricks: ML Feature Store Tables

CREATE TABLE IF NOT EXISTS ml.customer_features (
    customer_id             BIGINT NOT NULL,
    feature_date            DATE NOT NULL,
    recency_days            INTEGER,
    frequency_30d           INTEGER,
    frequency_90d           INTEGER,
    frequency_365d          INTEGER,
    monetary_30d            DECIMAL(14,2),
    monetary_90d            DECIMAL(14,2),
    monetary_365d           DECIMAL(14,2),
    avg_order_value_30d     DECIMAL(10,2),
    avg_order_value_90d     DECIMAL(10,2),
    orders_cancelled_pct    DECIMAL(6,4),
    days_since_first_order  INTEGER,
    unique_categories_90d   INTEGER,
    unique_products_90d     INTEGER,
    support_tickets_90d     INTEGER,
    session_count_30d       INTEGER,
    page_views_30d          INTEGER,
    avg_session_duration_30d DECIMAL(8,2),
    email_open_rate_90d     DECIMAL(6,4),
    churn_probability       DECIMAL(8,6),
    ltv_predicted_12m       DECIMAL(12,2),
    segment_label           STRING,
    _feature_ts             TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
PARTITIONED BY (feature_date)
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'ml.feature_table' = 'true',
    'ml.primary_keys' = 'customer_id,feature_date'
);

CREATE TABLE IF NOT EXISTS ml.product_features (
    product_id              BIGINT NOT NULL,
    feature_date            DATE NOT NULL,
    units_sold_7d           INTEGER DEFAULT 0,
    units_sold_30d          INTEGER DEFAULT 0,
    units_sold_90d          INTEGER DEFAULT 0,
    revenue_30d             DECIMAL(14,2) DEFAULT 0,
    revenue_90d             DECIMAL(14,2) DEFAULT 0,
    avg_rating_90d          DECIMAL(4,2),
    review_count_90d        INTEGER DEFAULT 0,
    return_rate_30d         DECIMAL(6,4),
    cart_add_rate_30d       DECIMAL(6,4),
    view_to_purchase_rate   DECIMAL(6,4),
    price_change_count_90d  INTEGER DEFAULT 0,
    stock_out_days_30d      INTEGER DEFAULT 0,
    cross_sell_score        DECIMAL(6,4),
    demand_forecast_7d      DECIMAL(10,2),
    _feature_ts             TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
PARTITIONED BY (feature_date)
TBLPROPERTIES (
    'ml.feature_table' = 'true',
    'ml.primary_keys' = 'product_id,feature_date'
);

CREATE TABLE IF NOT EXISTS ml.model_registry (
    model_id        BIGINT NOT NULL AUTOINCREMENT,
    model_name      STRING NOT NULL,
    model_version   STRING NOT NULL,
    model_type      STRING,
    framework       STRING,
    artifact_path   STRING,
    metrics         MAP<STRING, DOUBLE>,
    parameters      MAP<STRING, STRING>,
    tags            MAP<STRING, STRING>,
    status          STRING DEFAULT 'STAGING',
    trained_by      STRING,
    trained_at      TIMESTAMP,
    deployed_at     TIMESTAMP,
    retired_at      TIMESTAMP,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
TBLPROPERTIES ('ml.model_registry' = 'true');

CREATE TABLE IF NOT EXISTS ml.predictions_log (
    prediction_id   STRING NOT NULL,
    model_name      STRING NOT NULL,
    model_version   STRING NOT NULL,
    entity_type     STRING NOT NULL,
    entity_id       STRING NOT NULL,
    feature_values  MAP<STRING, DOUBLE>,
    prediction      DOUBLE,
    probability     DOUBLE,
    class_label     STRING,
    predicted_at    TIMESTAMP NOT NULL,
    prediction_date DATE NOT NULL
)
USING DELTA
PARTITIONED BY (prediction_date, model_name)
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true'
);
