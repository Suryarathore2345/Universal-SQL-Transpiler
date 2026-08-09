-- =============================================================================
-- Google BigQuery Benchmark DDL
-- Source: Synthetic, based on GoogleCloudPlatform/bigquery-utils and GCP docs
-- Dialect: Google BigQuery Standard SQL
-- Objects: 12 tables, 7 views, 2 materialized views, 2 MERGE, 1 MODEL, STRUCT/ARRAY
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Tables with PARTITION BY, CLUSTER BY, OPTIONS()
-- ---------------------------------------------------------------------------

-- E-commerce events table with nested STRUCT and ARRAY columns
CREATE TABLE IF NOT EXISTS `analytics_project.ecommerce.events` (
    event_id            STRING          NOT NULL,
    event_name          STRING          NOT NULL,
    event_timestamp     TIMESTAMP       NOT NULL,
    event_date          DATE            NOT NULL,
    user_id             STRING,
    user_pseudo_id      STRING          NOT NULL,
    platform            STRING,
    traffic_source      STRUCT<
                            source      STRING,
                            medium      STRING,
                            campaign    STRING,
                            content     STRING,
                            term        STRING
                        >,
    device              STRUCT<
                            category    STRING,
                            mobile_brand STRING,
                            mobile_model STRING,
                            operating_system STRING,
                            os_version  STRING,
                            browser     STRING,
                            browser_version STRING,
                            language    STRING
                        >,
    geo                 STRUCT<
                            continent   STRING,
                            country     STRING,
                            region      STRING,
                            city        STRING,
                            metro       STRING
                        >,
    ecommerce           STRUCT<
                            total_item_quantity  INT64,
                            purchase_revenue     FLOAT64,
                            refund_value         FLOAT64,
                            shipping_value       FLOAT64,
                            tax_value            FLOAT64,
                            unique_items         INT64,
                            transaction_id       STRING
                        >,
    items               ARRAY<STRUCT<
                            item_id      STRING,
                            item_name    STRING,
                            item_brand   STRING,
                            item_category STRING,
                            item_category2 STRING,
                            price        FLOAT64,
                            quantity     INT64,
                            item_revenue FLOAT64,
                            coupon       STRING,
                            affiliation  STRING,
                            promotion_id STRING,
                            promotion_name STRING
                        >>,
    event_params        ARRAY<STRUCT<
                            key          STRING,
                            value        STRUCT<
                                string_value STRING,
                                int_value    INT64,
                                float_value  FLOAT64,
                                double_value FLOAT64
                            >
                        >>
)
PARTITION BY event_date
CLUSTER BY user_pseudo_id, event_name
OPTIONS (
    description = 'GA4-style event data with nested structs and arrays',
    labels = [('team', 'analytics'), ('env', 'production')],
    partition_expiration_days = 365,
    require_partition_filter = true
);

-- Customer dimension table
CREATE TABLE IF NOT EXISTS `analytics_project.ecommerce.customers` (
    customer_id         STRING          NOT NULL,
    email               STRING,
    first_name          STRING,
    last_name           STRING,
    phone_number        STRING,
    created_at          TIMESTAMP       NOT NULL,
    updated_at          TIMESTAMP,
    addresses           ARRAY<STRUCT<
                            address_type STRING,
                            street       STRING,
                            city         STRING,
                            state        STRING,
                            postal_code  STRING,
                            country      STRING,
                            is_default   BOOL
                        >>,
    segments            ARRAY<STRING>,
    lifetime_value      FLOAT64,
    loyalty_tier        STRING,
    opt_in_email        BOOL            DEFAULT FALSE,
    opt_in_sms          BOOL            DEFAULT FALSE
)
CLUSTER BY customer_id
OPTIONS (
    description = 'Customer master data with nested addresses'
);

-- Product catalog with JSON column
CREATE TABLE IF NOT EXISTS `analytics_project.ecommerce.products` (
    product_id          STRING          NOT NULL,
    sku                 STRING          NOT NULL,
    product_name        STRING          NOT NULL,
    description         STRING,
    category_path       ARRAY<STRING>,
    brand               STRING,
    attributes          JSON,
    price               NUMERIC(10, 2)  NOT NULL,
    cost                NUMERIC(10, 2),
    currency_code       STRING          DEFAULT 'USD',
    weight_grams        FLOAT64,
    dimensions          STRUCT<
                            length_cm    FLOAT64,
                            width_cm     FLOAT64,
                            height_cm    FLOAT64
                        >,
    images              ARRAY<STRUCT<
                            url          STRING,
                            alt_text     STRING,
                            is_primary   BOOL
                        >>,
    is_active           BOOL            DEFAULT TRUE,
    created_at          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP(),
    updated_at          TIMESTAMP
)
CLUSTER BY product_id
OPTIONS (
    description = 'Product catalog with JSON attributes and nested arrays'
);

-- Transactions table partitioned by ingestion time
CREATE TABLE IF NOT EXISTS `analytics_project.ecommerce.transactions` (
    transaction_id      STRING          NOT NULL,
    customer_id         STRING          NOT NULL,
    transaction_date    DATE            NOT NULL,
    transaction_timestamp TIMESTAMP     NOT NULL,
    status              STRING          NOT NULL,
    payment_method      STRING,
    subtotal            NUMERIC(12, 2)  NOT NULL,
    tax                 NUMERIC(10, 2)  DEFAULT 0,
    shipping            NUMERIC(10, 2)  DEFAULT 0,
    discount            NUMERIC(10, 2)  DEFAULT 0,
    total               NUMERIC(12, 2)  NOT NULL,
    currency_code       STRING          DEFAULT 'USD',
    billing_address     STRUCT<
                            street      STRING,
                            city        STRING,
                            state       STRING,
                            postal_code STRING,
                            country     STRING
                        >,
    shipping_address    STRUCT<
                            street      STRING,
                            city        STRING,
                            state       STRING,
                            postal_code STRING,
                            country     STRING
                        >,
    line_items          ARRAY<STRUCT<
                            product_id   STRING,
                            sku          STRING,
                            quantity     INT64,
                            unit_price   NUMERIC(10, 2),
                            line_total   NUMERIC(12, 2),
                            discount     NUMERIC(10, 2)
                        >>
)
PARTITION BY transaction_date
CLUSTER BY customer_id, status
OPTIONS (
    description = 'Order transactions with nested line items',
    partition_expiration_days = 730,
    require_partition_filter = true
);

-- Time-series IoT data with INTEGER range partitioning
CREATE TABLE IF NOT EXISTS `analytics_project.iot.sensor_readings` (
    device_id           STRING          NOT NULL,
    sensor_type         STRING          NOT NULL,
    reading_value       FLOAT64,
    reading_unit        STRING,
    battery_pct         FLOAT64,
    signal_dbm          INT64,
    location            GEOGRAPHY,
    reading_timestamp   TIMESTAMP       NOT NULL,
    reading_date        DATE            NOT NULL,
    partition_key       INT64           NOT NULL
)
PARTITION BY RANGE_BUCKET(partition_key, GENERATE_ARRAY(0, 1000000, 1000))
CLUSTER BY device_id, sensor_type
OPTIONS (
    description = 'IoT sensor readings with range partitioning'
);

-- Geospatial data
CREATE TABLE IF NOT EXISTS `analytics_project.geo.store_locations` (
    store_id            STRING          NOT NULL,
    store_name          STRING          NOT NULL,
    store_type          STRING,
    address             STRING,
    city                STRING,
    state               STRING,
    country             STRING,
    postal_code         STRING,
    location            GEOGRAPHY       NOT NULL,
    timezone            STRING,
    opening_date        DATE,
    capacity            INT64,
    operating_hours     ARRAY<STRUCT<
                            day_of_week  STRING,
                            open_time    STRING,
                            close_time   STRING,
                            is_closed    BOOL
                        >>
)
CLUSTER BY country, state
OPTIONS (
    description = 'Store locations with GEOGRAPHY type for spatial queries'
);

-- Snapshot table with time-travel friendly design
CREATE SNAPSHOT TABLE IF NOT EXISTS `analytics_project.snapshots.daily_inventory`
CLONE `analytics_project.ecommerce.products`
FOR SYSTEM_TIME AS OF TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
OPTIONS (
    description = 'Daily snapshot of product inventory',
    expiration_timestamp = TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
);

-- Table with column-level security and data masking
CREATE TABLE IF NOT EXISTS `analytics_project.pii.customer_pii` (
    customer_id         STRING          NOT NULL,
    email               STRING          OPTIONS (description = 'PII: email address'),
    phone               STRING          OPTIONS (description = 'PII: phone number'),
    ssn_hash            BYTES,
    date_of_birth       DATE,
    full_name           STRING,
    created_at          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP()
)
CLUSTER BY customer_id
OPTIONS (
    description = 'Customer PII data - restricted access',
    labels = [('data_classification', 'confidential'), ('pii', 'true')]
);

-- ---------------------------------------------------------------------------
-- 2. Views with BigQuery-specific functions
-- ---------------------------------------------------------------------------

-- View with UNNEST, STRUCT access, and array functions
CREATE OR REPLACE VIEW `analytics_project.ecommerce.v_flattened_events` AS
SELECT
    e.event_id,
    e.event_name,
    e.event_timestamp,
    e.event_date,
    e.user_id,
    e.user_pseudo_id,
    e.traffic_source.source AS traffic_source,
    e.traffic_source.medium AS traffic_medium,
    e.traffic_source.campaign AS traffic_campaign,
    e.device.category AS device_category,
    e.device.operating_system AS device_os,
    e.device.browser AS device_browser,
    e.geo.country AS country,
    e.geo.city AS city,
    e.ecommerce.purchase_revenue,
    e.ecommerce.transaction_id,
    item.item_id,
    item.item_name,
    item.item_brand,
    item.item_category,
    item.price AS item_price,
    item.quantity AS item_quantity,
    item.item_revenue,
    (SELECT p.value.string_value FROM UNNEST(e.event_params) p WHERE p.key = 'page_location') AS page_location,
    (SELECT p.value.string_value FROM UNNEST(e.event_params) p WHERE p.key = 'page_title') AS page_title,
    (SELECT p.value.int_value FROM UNNEST(e.event_params) p WHERE p.key = 'engagement_time_msec') AS engagement_time_msec,
    (SELECT p.value.int_value FROM UNNEST(e.event_params) p WHERE p.key = 'session_engaged') AS session_engaged
FROM `analytics_project.ecommerce.events` e
LEFT JOIN UNNEST(e.items) AS item;

-- View with GEOGRAPHY functions
CREATE OR REPLACE VIEW `analytics_project.geo.v_store_proximity` AS
SELECT
    a.store_id AS store_a_id,
    a.store_name AS store_a_name,
    b.store_id AS store_b_id,
    b.store_name AS store_b_name,
    ROUND(ST_DISTANCE(a.location, b.location) / 1000, 2) AS distance_km,
    ST_MAKELINE(a.location, b.location) AS connecting_line,
    ST_CENTROID(ST_UNION_AGG(a.location)) OVER () AS centroid_all_stores
FROM `analytics_project.geo.store_locations` a
CROSS JOIN `analytics_project.geo.store_locations` b
WHERE a.store_id < b.store_id
    AND ST_DISTANCE(a.location, b.location) < 50000;

-- View with JSON functions
CREATE OR REPLACE VIEW `analytics_project.ecommerce.v_product_attributes` AS
SELECT
    product_id,
    product_name,
    brand,
    price,
    JSON_VALUE(attributes, '$.color') AS color,
    JSON_VALUE(attributes, '$.material') AS material,
    JSON_VALUE(attributes, '$.warranty_years') AS warranty_years,
    JSON_QUERY(attributes, '$.specifications') AS specifications,
    JSON_VALUE_ARRAY(attributes, '$.tags') AS tags,
    ARRAY_LENGTH(JSON_VALUE_ARRAY(attributes, '$.tags')) AS tag_count,
    SAFE_CAST(JSON_VALUE(attributes, '$.rating') AS FLOAT64) AS rating,
    SAFE_CAST(JSON_VALUE(attributes, '$.review_count') AS INT64) AS review_count,
    category_path[SAFE_OFFSET(0)] AS top_category,
    category_path[SAFE_OFFSET(1)] AS sub_category,
    ARRAY_TO_STRING(category_path, ' > ') AS category_breadcrumb
FROM `analytics_project.ecommerce.products`
WHERE is_active = TRUE;

-- View with INFORMATION_SCHEMA (inspired by GoogleCloudPlatform/bigquery-utils)
CREATE OR REPLACE VIEW `analytics_project.admin.v_table_metadata` AS
SELECT
    t.table_catalog AS project_id,
    t.table_schema AS dataset_id,
    t.table_name,
    t.table_type,
    t.creation_time,
    TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), t.creation_time, DAY) AS age_days,
    ts.total_rows,
    ROUND(SAFE_DIVIDE(ts.total_logical_bytes, POW(2, 30)), 3) AS logical_gb,
    ROUND(SAFE_DIVIDE(ts.total_physical_bytes, POW(2, 30)), 3) AS physical_gb,
    ROUND(SAFE_DIVIDE(ts.active_logical_bytes, POW(2, 30)), 3) AS active_logical_gb,
    ROUND(SAFE_DIVIDE(ts.long_term_logical_bytes, POW(2, 30)), 3) AS long_term_logical_gb,
    ROUND(SAFE_DIVIDE(ts.total_physical_bytes, NULLIF(ts.total_logical_bytes, 0)), 3) AS compression_ratio,
    cp.ddl AS table_ddl
FROM `analytics_project.region-us.INFORMATION_SCHEMA.TABLES` t
LEFT JOIN `analytics_project.region-us.INFORMATION_SCHEMA.TABLE_STORAGE` ts
    ON t.table_catalog = ts.project_id
    AND t.table_schema = ts.table_schema
    AND t.table_name = ts.table_name
LEFT JOIN `analytics_project.region-us.INFORMATION_SCHEMA.COLUMNS` cp
    ON FALSE  -- placeholder join
WHERE t.table_schema NOT IN ('_script', 'INFORMATION_SCHEMA');

-- View with window functions and QUALIFY
CREATE OR REPLACE VIEW `analytics_project.ecommerce.v_customer_rfm` AS
WITH customer_metrics AS (
    SELECT
        customer_id,
        COUNT(DISTINCT transaction_id) AS frequency,
        SUM(total) AS monetary,
        DATE_DIFF(CURRENT_DATE(), MAX(transaction_date), DAY) AS recency_days,
        MIN(transaction_date) AS first_purchase_date,
        MAX(transaction_date) AS last_purchase_date,
        DATE_DIFF(MAX(transaction_date), MIN(transaction_date), DAY) AS customer_tenure_days,
        COUNTIF(status = 'completed') AS completed_orders,
        COUNTIF(status = 'refunded') AS refunded_orders,
        AVG(total) AS avg_order_value,
        APPROX_QUANTILES(total, 4)[OFFSET(2)] AS median_order_value
    FROM `analytics_project.ecommerce.transactions`
    WHERE transaction_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY)
        AND status IN ('completed', 'shipped')
    GROUP BY customer_id
)
SELECT
    *,
    NTILE(5) OVER (ORDER BY recency_days ASC)   AS r_score,
    NTILE(5) OVER (ORDER BY frequency DESC)      AS f_score,
    NTILE(5) OVER (ORDER BY monetary DESC)       AS m_score,
    CONCAT(
        CAST(NTILE(5) OVER (ORDER BY recency_days ASC) AS STRING),
        CAST(NTILE(5) OVER (ORDER BY frequency DESC) AS STRING),
        CAST(NTILE(5) OVER (ORDER BY monetary DESC) AS STRING)
    ) AS rfm_segment
FROM customer_metrics
QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY monetary DESC) = 1;

-- View with PIVOT
CREATE OR REPLACE VIEW `analytics_project.ecommerce.v_monthly_category_revenue` AS
SELECT *
FROM (
    SELECT
        FORMAT_DATE('%Y-%m', t.transaction_date) AS month,
        p.brand,
        li.line_total
    FROM `analytics_project.ecommerce.transactions` t,
    UNNEST(t.line_items) li
    JOIN `analytics_project.ecommerce.products` p ON li.product_id = p.product_id
    WHERE t.transaction_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
)
PIVOT (
    SUM(line_total) AS revenue
    FOR brand IN ('BrandA', 'BrandB', 'BrandC', 'BrandD', 'BrandE')
);

-- View with ML prediction reference
CREATE OR REPLACE VIEW `analytics_project.ecommerce.v_churn_predictions` AS
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    avg_order_value,
    predicted_label AS will_churn,
    predicted_label_probs[OFFSET(0)].prob AS churn_probability
FROM ML.PREDICT(
    MODEL `analytics_project.ml_models.customer_churn_model`,
    (
        SELECT
            customer_id,
            DATE_DIFF(CURRENT_DATE(), MAX(transaction_date), DAY) AS recency_days,
            COUNT(*) AS frequency,
            SUM(total) AS monetary,
            AVG(total) AS avg_order_value
        FROM `analytics_project.ecommerce.transactions`
        WHERE status = 'completed'
        GROUP BY customer_id
    )
);

-- ---------------------------------------------------------------------------
-- 3. Materialized Views
-- ---------------------------------------------------------------------------

CREATE MATERIALIZED VIEW IF NOT EXISTS `analytics_project.ecommerce.mv_daily_sales`
PARTITION BY transaction_date
CLUSTER BY customer_id
OPTIONS (
    description = 'Daily aggregated sales metrics',
    enable_refresh = true,
    refresh_interval_minutes = 30
)
AS
SELECT
    transaction_date,
    customer_id,
    COUNT(*) AS order_count,
    SUM(total) AS total_revenue,
    SUM(tax) AS total_tax,
    SUM(shipping) AS total_shipping,
    SUM(discount) AS total_discount,
    AVG(total) AS avg_order_value,
    ARRAY_AGG(DISTINCT status) AS statuses
FROM `analytics_project.ecommerce.transactions`
GROUP BY transaction_date, customer_id;

CREATE MATERIALIZED VIEW IF NOT EXISTS `analytics_project.ecommerce.mv_product_performance`
CLUSTER BY product_id
OPTIONS (
    enable_refresh = true,
    refresh_interval_minutes = 60,
    max_staleness = INTERVAL '4' HOUR
)
AS
SELECT
    li.product_id,
    li.sku,
    COUNT(DISTINCT t.transaction_id) AS order_count,
    SUM(li.quantity) AS total_units_sold,
    SUM(li.line_total) AS total_revenue,
    AVG(li.unit_price) AS avg_selling_price,
    SUM(li.discount) AS total_discounts,
    APPROX_COUNT_DISTINCT(t.customer_id) AS unique_customers
FROM `analytics_project.ecommerce.transactions` t,
UNNEST(t.line_items) li
WHERE t.status IN ('completed', 'shipped')
GROUP BY li.product_id, li.sku;

-- ---------------------------------------------------------------------------
-- 4. MERGE Statements
-- ---------------------------------------------------------------------------

-- Merge for customer dimension updates
MERGE INTO `analytics_project.ecommerce.customers` AS target
USING `analytics_project.staging.customer_updates` AS source
ON target.customer_id = source.customer_id
WHEN MATCHED AND source._operation = 'DELETE' THEN
    DELETE
WHEN MATCHED THEN
    UPDATE SET
        email = source.email,
        first_name = source.first_name,
        last_name = source.last_name,
        phone_number = source.phone_number,
        addresses = source.addresses,
        segments = source.segments,
        lifetime_value = source.lifetime_value,
        loyalty_tier = source.loyalty_tier,
        opt_in_email = source.opt_in_email,
        opt_in_sms = source.opt_in_sms,
        updated_at = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN
    INSERT ROW;

-- Merge for incremental transaction loading
MERGE INTO `analytics_project.ecommerce.transactions` AS target
USING (
    SELECT *
    FROM `analytics_project.staging.new_transactions`
    WHERE transaction_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
) AS source
ON target.transaction_id = source.transaction_id
    AND target.transaction_date = source.transaction_date
WHEN MATCHED AND target.status != source.status THEN
    UPDATE SET
        status = source.status,
        total = source.total,
        tax = source.tax,
        shipping = source.shipping,
        discount = source.discount
WHEN NOT MATCHED BY TARGET THEN
    INSERT (transaction_id, customer_id, transaction_date, transaction_timestamp,
            status, payment_method, subtotal, tax, shipping, discount, total,
            currency_code, billing_address, shipping_address, line_items)
    VALUES (source.transaction_id, source.customer_id, source.transaction_date,
            source.transaction_timestamp, source.status, source.payment_method,
            source.subtotal, source.tax, source.shipping, source.discount,
            source.total, source.currency_code, source.billing_address,
            source.shipping_address, source.line_items);

-- ---------------------------------------------------------------------------
-- 5. BigQuery ML Model
-- ---------------------------------------------------------------------------

CREATE OR REPLACE MODEL `analytics_project.ml_models.customer_churn_model`
OPTIONS (
    model_type = 'LOGISTIC_REG',
    input_label_cols = ['churned'],
    auto_class_weights = TRUE,
    data_split_method = 'AUTO_SPLIT',
    max_iterations = 20,
    learn_rate_strategy = 'LINE_SEARCH',
    l1_reg = 0.1,
    l2_reg = 0.1,
    early_stop = TRUE,
    min_rel_progress = 0.001
)
AS
SELECT
    customer_id,
    DATE_DIFF(CURRENT_DATE(), MAX(transaction_date), DAY) AS recency_days,
    COUNT(*) AS frequency,
    SUM(total) AS monetary,
    AVG(total) AS avg_order_value,
    COUNTIF(status = 'refunded') / COUNT(*) AS refund_rate,
    DATE_DIFF(MAX(transaction_date), MIN(transaction_date), DAY) AS tenure_days,
    CASE
        WHEN DATE_DIFF(CURRENT_DATE(), MAX(transaction_date), DAY) > 180 THEN 1
        ELSE 0
    END AS churned
FROM `analytics_project.ecommerce.transactions`
GROUP BY customer_id;

-- ---------------------------------------------------------------------------
-- 6. BigQuery Scripting and Procedures
-- ---------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE `analytics_project.ops.sp_partition_maintenance`(
    target_dataset STRING,
    retention_days INT64
)
BEGIN
    DECLARE tables ARRAY<STRING>;
    DECLARE i INT64 DEFAULT 0;

    SET tables = (
        SELECT ARRAY_AGG(table_name)
        FROM `analytics_project.region-us.INFORMATION_SCHEMA.TABLE_OPTIONS`
        WHERE table_schema = target_dataset
            AND option_name = 'partition_expiration_days'
    );

    WHILE i < ARRAY_LENGTH(tables) DO
        EXECUTE IMMEDIATE FORMAT(
            "DELETE FROM `%s.%s.%s` WHERE DATE(_PARTITIONTIME) < DATE_SUB(CURRENT_DATE(), INTERVAL %d DAY)",
            'analytics_project', target_dataset, tables[OFFSET(i)], retention_days
        );
        SET i = i + 1;
    END WHILE;
END;

-- ---------------------------------------------------------------------------
-- 7. Row-level security and authorized views
-- ---------------------------------------------------------------------------

CREATE ROW ACCESS POLICY region_filter
ON `analytics_project.ecommerce.transactions`
GRANT TO ('group:us-analysts@example.com')
FILTER USING (
    shipping_address.country = 'US'
);

-- Table function (TVF)
CREATE OR REPLACE TABLE FUNCTION `analytics_project.ecommerce.fn_customer_orders`(
    p_customer_id STRING,
    p_start_date DATE,
    p_end_date DATE
)
AS
SELECT
    t.transaction_id,
    t.transaction_date,
    t.status,
    t.total,
    li.product_id,
    li.sku,
    li.quantity,
    li.unit_price,
    li.line_total
FROM `analytics_project.ecommerce.transactions` t,
UNNEST(t.line_items) li
WHERE t.customer_id = p_customer_id
    AND t.transaction_date BETWEEN p_start_date AND p_end_date
ORDER BY t.transaction_date DESC;

-- ---------------------------------------------------------------------------
-- 8. BigQuery BI Engine and data transfer
-- ---------------------------------------------------------------------------

-- Reservation-based capacity commitment (DDL reference)
-- Note: These are admin operations typically done via API
ALTER BI_CAPACITY `analytics_project.region-us.default`
SET OPTIONS (preferred_tables = [
    'analytics_project.ecommerce.mv_daily_sales',
    'analytics_project.ecommerce.mv_product_performance'
]);
