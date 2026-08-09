-- =============================================================================
-- Databricks Spark SQL / Delta Lake Benchmark DDL
-- Source: Synthetic, based on Databricks documentation and databricks/tech-talks
-- Dialect: Databricks SQL (Unity Catalog compatible)
-- Objects: 12 tables, 6 views, 4 MERGE statements, 2 OPTIMIZE/VACUUM
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Unity Catalog: Medallion Architecture - Bronze Layer
-- ---------------------------------------------------------------------------

CREATE CATALOG IF NOT EXISTS analytics_prod;
USE CATALOG analytics_prod;
CREATE SCHEMA IF NOT EXISTS analytics_prod.bronze;
CREATE SCHEMA IF NOT EXISTS analytics_prod.silver;
CREATE SCHEMA IF NOT EXISTS analytics_prod.gold;

-- Bronze: Raw ingestion table using DELTA with auto-loader metadata
CREATE TABLE IF NOT EXISTS analytics_prod.bronze.raw_clickstream (
    event_id            STRING          NOT NULL,
    user_id             BIGINT,
    session_id          STRING,
    event_type          STRING,
    page_url            STRING,
    referrer_url        STRING,
    user_agent          STRING,
    ip_address          STRING,
    event_timestamp     TIMESTAMP,
    event_date          DATE            GENERATED ALWAYS AS (CAST(event_timestamp AS DATE)),
    properties          MAP<STRING, STRING>,
    _rescued_data       STRING,
    _metadata           STRUCT<file_path: STRING, file_name: STRING, file_modification_time: TIMESTAMP>
)
USING DELTA
PARTITIONED BY (event_date)
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'delta.autoOptimize.autoCompact'   = 'true',
    'delta.logRetentionDuration'       = 'interval 30 days',
    'delta.deletedFileRetentionDuration' = 'interval 7 days',
    'quality'                          = 'bronze'
)
COMMENT 'Raw clickstream events ingested via Auto Loader from S3';

-- Bronze: Raw orders with schema evolution enabled
CREATE TABLE IF NOT EXISTS analytics_prod.bronze.raw_orders (
    order_id            STRING,
    customer_id         BIGINT,
    order_date          DATE,
    order_status        STRING,
    total_amount        DECIMAL(18, 2),
    currency_code       STRING,
    shipping_address    STRUCT<
                            street: STRING,
                            city: STRING,
                            state: STRING,
                            zip: STRING,
                            country: STRING
                        >,
    line_items          ARRAY<STRUCT<
                            sku: STRING,
                            product_name: STRING,
                            quantity: INT,
                            unit_price: DECIMAL(10, 2),
                            discount_pct: DOUBLE
                        >>,
    ingestion_timestamp TIMESTAMP       DEFAULT current_timestamp(),
    source_file         STRING
)
USING DELTA
PARTITIONED BY (order_date)
CLUSTER BY (customer_id)
TBLPROPERTIES (
    'delta.enableChangeDataFeed'       = 'true',
    'delta.columnMapping.mode'         = 'name',
    'delta.minReaderVersion'           = '2',
    'delta.minWriterVersion'           = '5'
)
COMMENT 'Raw e-commerce orders with nested structs and arrays';

-- Bronze: IoT sensor data with liquid clustering
CREATE TABLE IF NOT EXISTS analytics_prod.bronze.iot_sensor_readings (
    device_id           STRING          NOT NULL,
    sensor_type         STRING          NOT NULL,
    reading_value       DOUBLE,
    reading_unit        STRING,
    battery_level       FLOAT,
    signal_strength     INT,
    location            STRUCT<latitude: DOUBLE, longitude: DOUBLE, altitude: DOUBLE>,
    reading_timestamp   TIMESTAMP       NOT NULL,
    received_timestamp  TIMESTAMP       DEFAULT current_timestamp()
)
USING DELTA
CLUSTER BY (device_id, sensor_type, reading_timestamp)
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'delta.tuneFileSizesForRewrites'   = 'true'
)
COMMENT 'IoT sensor telemetry with liquid clustering';

-- ---------------------------------------------------------------------------
-- 2. Silver Layer - Cleaned and conformed
-- ---------------------------------------------------------------------------

-- Silver: Cleaned clickstream with quality constraints
CREATE TABLE IF NOT EXISTS analytics_prod.silver.cleaned_clickstream (
    event_id            STRING          NOT NULL,
    user_id             BIGINT          NOT NULL,
    session_id          STRING          NOT NULL,
    event_type          STRING          NOT NULL,
    page_url            STRING,
    referrer_url        STRING,
    event_timestamp     TIMESTAMP       NOT NULL,
    event_date          DATE            NOT NULL,
    is_bot              BOOLEAN         DEFAULT false,
    geo_country         STRING,
    geo_region          STRING,
    device_category     STRING,
    browser_family      STRING,
    processing_timestamp TIMESTAMP      DEFAULT current_timestamp(),
    CONSTRAINT valid_event_type CHECK (event_type IN ('page_view', 'click', 'scroll', 'form_submit', 'purchase'))
)
USING DELTA
PARTITIONED BY (event_date)
CLUSTER BY (user_id)
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'quality'                          = 'silver'
);

-- Silver: Conformed orders dimension (SCD Type 2)
CREATE TABLE IF NOT EXISTS analytics_prod.silver.dim_customer (
    customer_sk         BIGINT          GENERATED ALWAYS AS IDENTITY,
    customer_id         BIGINT          NOT NULL,
    customer_name       STRING,
    email               STRING,
    segment             STRING,
    region              STRING,
    country             STRING,
    city                STRING,
    effective_date      DATE            NOT NULL,
    end_date            DATE,
    is_current          BOOLEAN         NOT NULL DEFAULT true,
    record_hash         STRING
)
USING DELTA
CLUSTER BY (customer_id, is_current)
TBLPROPERTIES (
    'delta.enableChangeDataFeed' = 'true'
)
COMMENT 'SCD Type 2 customer dimension';

-- Silver: Fact orders
CREATE TABLE IF NOT EXISTS analytics_prod.silver.fact_orders (
    order_sk            BIGINT          GENERATED ALWAYS AS IDENTITY,
    order_id            STRING          NOT NULL,
    customer_sk         BIGINT          NOT NULL,
    order_date          DATE            NOT NULL,
    order_status        STRING,
    total_amount        DECIMAL(18, 2),
    currency_code       STRING,
    item_count          INT,
    discount_total      DECIMAL(18, 2),
    shipping_country    STRING,
    processing_timestamp TIMESTAMP      DEFAULT current_timestamp()
)
USING DELTA
PARTITIONED BY (order_date)
CLUSTER BY (customer_sk)
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true'
);

-- ---------------------------------------------------------------------------
-- 3. Gold Layer - Aggregated business metrics
-- ---------------------------------------------------------------------------

-- Gold: Daily revenue summary
CREATE TABLE IF NOT EXISTS analytics_prod.gold.daily_revenue_summary (
    report_date         DATE            NOT NULL,
    region              STRING          NOT NULL,
    segment             STRING          NOT NULL,
    order_count         BIGINT,
    total_revenue       DECIMAL(20, 2),
    avg_order_value     DECIMAL(18, 2),
    unique_customers    BIGINT,
    repeat_customers    BIGINT,
    new_customers       BIGINT,
    updated_at          TIMESTAMP       DEFAULT current_timestamp()
)
USING DELTA
PARTITIONED BY (report_date)
TBLPROPERTIES (
    'quality' = 'gold'
);

-- Gold: Customer lifetime value
CREATE TABLE IF NOT EXISTS analytics_prod.gold.customer_ltv (
    customer_id         BIGINT          NOT NULL,
    customer_name       STRING,
    segment             STRING,
    region              STRING,
    first_order_date    DATE,
    last_order_date     DATE,
    total_orders        BIGINT,
    total_revenue       DECIMAL(20, 2),
    avg_order_value     DECIMAL(18, 2),
    days_since_last_order INT,
    ltv_score           DOUBLE,
    rfm_segment         STRING,
    updated_at          TIMESTAMP       DEFAULT current_timestamp()
)
USING DELTA
CLUSTER BY (segment, region)
TBLPROPERTIES (
    'quality' = 'gold'
);

-- ---------------------------------------------------------------------------
-- 4. External Tables (Unity Catalog)
-- ---------------------------------------------------------------------------

CREATE EXTERNAL TABLE IF NOT EXISTS analytics_prod.bronze.ext_parquet_events (
    event_id            STRING,
    event_type          STRING,
    event_timestamp     STRING,
    payload             STRING
)
USING PARQUET
LOCATION 's3://data-lake-raw/events/parquet/'
TBLPROPERTIES (
    'delta.compatibility.symlinkFormatManifest.enabled' = 'true'
);

CREATE EXTERNAL TABLE IF NOT EXISTS analytics_prod.bronze.ext_csv_products (
    product_id          STRING,
    product_name        STRING,
    category            STRING,
    subcategory         STRING,
    unit_price          DOUBLE,
    cost_price          DOUBLE
)
USING CSV
OPTIONS (
    header = 'true',
    delimiter = ',',
    inferSchema = 'true'
)
LOCATION 's3://data-lake-raw/products/csv/';

-- ---------------------------------------------------------------------------
-- 5. Views using Spark SQL functions
-- ---------------------------------------------------------------------------

CREATE OR REPLACE VIEW analytics_prod.gold.v_monthly_cohort_analysis AS
SELECT
    date_trunc('MONTH', first_order_date)   AS cohort_month,
    date_trunc('MONTH', o.order_date)       AS order_month,
    months_between(o.order_date, first_order_date) AS months_since_first,
    COUNT(DISTINCT o.customer_sk)           AS active_customers,
    SUM(o.total_amount)                     AS cohort_revenue,
    PERCENTILE_APPROX(o.total_amount, 0.5)  AS median_order_value
FROM analytics_prod.silver.fact_orders o
JOIN (
    SELECT customer_sk, MIN(order_date) AS first_order_date
    FROM analytics_prod.silver.fact_orders
    GROUP BY customer_sk
) first_ord ON o.customer_sk = first_ord.customer_sk
GROUP BY 1, 2, 3;

CREATE OR REPLACE VIEW analytics_prod.gold.v_funnel_conversion AS
WITH funnel_steps AS (
    SELECT
        event_date,
        session_id,
        COLLECT_SET(event_type) AS events_in_session,
        MIN(event_timestamp) AS session_start,
        MAX(event_timestamp) AS session_end,
        COUNT(*) AS event_count
    FROM analytics_prod.silver.cleaned_clickstream
    WHERE event_date >= date_sub(current_date(), 30)
    GROUP BY event_date, session_id
)
SELECT
    event_date,
    COUNT(*)                                                                AS total_sessions,
    COUNT_IF(array_contains(events_in_session, 'page_view'))                AS sessions_with_pageview,
    COUNT_IF(array_contains(events_in_session, 'click'))                    AS sessions_with_click,
    COUNT_IF(array_contains(events_in_session, 'form_submit'))              AS sessions_with_form,
    COUNT_IF(array_contains(events_in_session, 'purchase'))                 AS sessions_with_purchase,
    ROUND(COUNT_IF(array_contains(events_in_session, 'purchase')) * 100.0
        / NULLIF(COUNT_IF(array_contains(events_in_session, 'page_view')), 0), 2)
                                                                            AS conversion_rate_pct,
    AVG(unix_timestamp(session_end) - unix_timestamp(session_start))        AS avg_session_duration_sec
FROM funnel_steps
GROUP BY event_date
ORDER BY event_date DESC;

CREATE OR REPLACE VIEW analytics_prod.silver.v_active_devices AS
SELECT
    device_id,
    sensor_type,
    COUNT(*) AS total_readings,
    AVG(reading_value) AS avg_reading,
    STDDEV(reading_value) AS stddev_reading,
    MIN(reading_timestamp) AS first_seen,
    MAX(reading_timestamp) AS last_seen,
    DATEDIFF(MAX(reading_timestamp), MIN(reading_timestamp)) AS active_days,
    APPROX_COUNT_DISTINCT(DATE(reading_timestamp)) AS distinct_active_days,
    PERCENTILE_APPROX(reading_value, ARRAY(0.25, 0.50, 0.75)) AS quartiles
FROM analytics_prod.bronze.iot_sensor_readings
WHERE reading_timestamp >= date_sub(current_timestamp(), 90)
GROUP BY device_id, sensor_type
HAVING COUNT(*) >= 100;

CREATE OR REPLACE VIEW analytics_prod.gold.v_revenue_yoy_comparison AS
SELECT
    r.report_date,
    r.region,
    r.segment,
    r.total_revenue                                             AS current_revenue,
    py.total_revenue                                            AS prior_year_revenue,
    r.total_revenue - COALESCE(py.total_revenue, 0)             AS revenue_change,
    ROUND((r.total_revenue - COALESCE(py.total_revenue, 0))
        / NULLIF(py.total_revenue, 0) * 100, 2)                AS yoy_growth_pct,
    r.order_count,
    r.unique_customers,
    r.avg_order_value
FROM analytics_prod.gold.daily_revenue_summary r
LEFT JOIN analytics_prod.gold.daily_revenue_summary py
    ON py.report_date = date_add(r.report_date, -365)
    AND py.region = r.region
    AND py.segment = r.segment;

-- Streaming table (Databricks-specific DLT syntax)
CREATE OR REPLACE STREAMING TABLE analytics_prod.silver.streaming_orders
COMMENT 'Streaming silver orders from bronze CDC feed'
TBLPROPERTIES ('quality' = 'silver')
AS SELECT
    order_id,
    customer_id,
    order_date,
    order_status,
    total_amount,
    currency_code,
    current_timestamp() AS processed_at
FROM STREAM(analytics_prod.bronze.raw_orders);

-- Materialized View (Databricks SQL Warehouse)
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics_prod.gold.mv_hourly_metrics AS
SELECT
    date_trunc('HOUR', event_timestamp)  AS event_hour,
    event_type,
    COUNT(*)                             AS event_count,
    APPROX_COUNT_DISTINCT(user_id)       AS unique_users,
    APPROX_COUNT_DISTINCT(session_id)    AS unique_sessions
FROM analytics_prod.silver.cleaned_clickstream
WHERE event_date >= date_sub(current_date(), 7)
GROUP BY 1, 2;

-- ---------------------------------------------------------------------------
-- 6. MERGE INTO Statements (SCD Type 2 and upserts)
-- ---------------------------------------------------------------------------

-- SCD Type 2 merge for customer dimension (inspired by databricks/tech-talks)
MERGE INTO analytics_prod.silver.dim_customer AS target
USING (
    SELECT
        src.customer_id,
        src.customer_name,
        src.email,
        src.segment,
        src.region,
        src.country,
        src.city,
        sha2(concat_ws('|', src.customer_name, src.email, src.segment, src.region), 256) AS record_hash
    FROM analytics_prod.bronze.raw_customers_staging src
) AS source
ON target.customer_id = source.customer_id AND target.is_current = true
WHEN MATCHED AND target.record_hash != source.record_hash THEN
    UPDATE SET
        target.is_current = false,
        target.end_date = current_date()
WHEN NOT MATCHED THEN
    INSERT (customer_id, customer_name, email, segment, region, country, city,
            effective_date, end_date, is_current, record_hash)
    VALUES (source.customer_id, source.customer_name, source.email, source.segment,
            source.region, source.country, source.city,
            current_date(), NULL, true, source.record_hash);

-- Insert new current records for changed customers
INSERT INTO analytics_prod.silver.dim_customer
    (customer_id, customer_name, email, segment, region, country, city,
     effective_date, end_date, is_current, record_hash)
SELECT
    src.customer_id, src.customer_name, src.email, src.segment,
    src.region, src.country, src.city,
    current_date(), NULL, true,
    sha2(concat_ws('|', src.customer_name, src.email, src.segment, src.region), 256)
FROM analytics_prod.bronze.raw_customers_staging src
JOIN analytics_prod.silver.dim_customer tgt
    ON src.customer_id = tgt.customer_id
    AND tgt.is_current = false
    AND tgt.end_date = current_date()
    AND sha2(concat_ws('|', src.customer_name, src.email, src.segment, src.region), 256) != tgt.record_hash;

-- Simple upsert merge for fact orders
MERGE INTO analytics_prod.silver.fact_orders AS target
USING analytics_prod.bronze.raw_orders_staging AS source
ON target.order_id = source.order_id
WHEN MATCHED AND source.order_status != target.order_status THEN
    UPDATE SET
        order_status = source.order_status,
        total_amount = source.total_amount,
        processing_timestamp = current_timestamp()
WHEN NOT MATCHED THEN
    INSERT (order_id, customer_sk, order_date, order_status, total_amount,
            currency_code, item_count, discount_total, shipping_country)
    VALUES (source.order_id, source.customer_sk, source.order_date, source.order_status,
            source.total_amount, source.currency_code, source.item_count,
            source.discount_total, source.shipping_country);

-- Merge with DELETE clause
MERGE INTO analytics_prod.gold.daily_revenue_summary AS target
USING analytics_prod.gold.daily_revenue_staging AS source
ON target.report_date = source.report_date
    AND target.region = source.region
    AND target.segment = source.segment
WHEN MATCHED AND source.is_deleted = true THEN
    DELETE
WHEN MATCHED THEN
    UPDATE SET *
WHEN NOT MATCHED THEN
    INSERT *;

-- ---------------------------------------------------------------------------
-- 7. OPTIMIZE and VACUUM (Delta Lake maintenance)
-- ---------------------------------------------------------------------------

OPTIMIZE analytics_prod.silver.fact_orders
WHERE order_date >= date_sub(current_date(), 30)
ZORDER BY (customer_sk, order_status);

OPTIMIZE analytics_prod.bronze.raw_clickstream
WHERE event_date >= date_sub(current_date(), 7);

VACUUM analytics_prod.bronze.raw_clickstream RETAIN 168 HOURS;
VACUUM analytics_prod.silver.fact_orders;

-- ---------------------------------------------------------------------------
-- 8. ALTER TABLE operations (Delta-specific)
-- ---------------------------------------------------------------------------

ALTER TABLE analytics_prod.bronze.raw_orders
SET TBLPROPERTIES ('delta.enableChangeDataFeed' = 'true');

ALTER TABLE analytics_prod.silver.dim_customer
ADD CONSTRAINT pk_customer_sk PRIMARY KEY (customer_sk);

ALTER TABLE analytics_prod.silver.fact_orders
ADD CONSTRAINT fk_customer FOREIGN KEY (customer_sk)
REFERENCES analytics_prod.silver.dim_customer (customer_sk);

ALTER TABLE analytics_prod.bronze.raw_clickstream
ADD COLUMNS (
    campaign_id STRING AFTER referrer_url,
    ab_test_variant STRING AFTER campaign_id
);

-- ---------------------------------------------------------------------------
-- 9. Grants (Unity Catalog)
-- ---------------------------------------------------------------------------

GRANT USAGE ON CATALOG analytics_prod TO `data_analysts`;
GRANT USAGE ON SCHEMA analytics_prod.gold TO `data_analysts`;
GRANT SELECT ON SCHEMA analytics_prod.gold TO `data_analysts`;
GRANT ALL PRIVILEGES ON SCHEMA analytics_prod.silver TO `data_engineers`;
