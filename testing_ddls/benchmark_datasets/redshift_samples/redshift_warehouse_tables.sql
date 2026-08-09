-- =============================================================================
-- Amazon Redshift Benchmark DDL
-- Source: Synthetic, based on awslabs/amazon-redshift-utils and AWS documentation
-- Dialect: Amazon Redshift
-- Objects: 14 tables, 6 views, 2 materialized views, COPY/UNLOAD statements
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Tables with DISTKEY, SORTKEY, DISTSTYLE, ENCODE
-- ---------------------------------------------------------------------------

-- Fact: Sales transactions - DISTKEY on high-cardinality join column
CREATE TABLE IF NOT EXISTS sales.fact_sales (
    sale_id             BIGINT          IDENTITY(1,1) NOT NULL,
    sale_date           DATE            NOT NULL        ENCODE delta,
    sale_timestamp      TIMESTAMP       NOT NULL        ENCODE az64,
    customer_id         BIGINT          NOT NULL        ENCODE az64,
    product_id          INTEGER         NOT NULL        ENCODE az64,
    store_id            INTEGER         NOT NULL        ENCODE az64,
    promotion_id        INTEGER                         ENCODE az64,
    quantity_sold       SMALLINT        NOT NULL        ENCODE az64,
    unit_price          DECIMAL(10,2)   NOT NULL        ENCODE az64,
    discount_amount     DECIMAL(10,2)   DEFAULT 0.00    ENCODE az64,
    net_amount          DECIMAL(12,2)   NOT NULL        ENCODE az64,
    tax_amount          DECIMAL(10,2)                   ENCODE az64,
    payment_method      VARCHAR(30)                     ENCODE lzo,
    channel             VARCHAR(20)                     ENCODE bytedict,
    PRIMARY KEY (sale_id)
)
DISTSTYLE KEY
DISTKEY (customer_id)
COMPOUND SORTKEY (sale_date, store_id);

-- Fact: Web clickstream - even distribution for large table
CREATE TABLE IF NOT EXISTS web.fact_clickstream (
    click_id            BIGINT          IDENTITY(1,1),
    session_id          VARCHAR(64)     NOT NULL        ENCODE lzo,
    user_id             BIGINT                          ENCODE az64,
    event_timestamp     TIMESTAMP       NOT NULL        ENCODE az64,
    event_type          VARCHAR(30)     NOT NULL        ENCODE bytedict,
    page_url            VARCHAR(2048)                   ENCODE lzo,
    referrer_url        VARCHAR(2048)                   ENCODE lzo,
    user_agent          VARCHAR(512)                    ENCODE lzo,
    ip_address          VARCHAR(45)                     ENCODE lzo,
    country_code        CHAR(2)                         ENCODE bytedict,
    device_type         VARCHAR(20)                     ENCODE bytedict,
    browser             VARCHAR(50)                     ENCODE bytedict,
    duration_ms         INTEGER                         ENCODE az64
)
DISTSTYLE EVEN
INTERLEAVED SORTKEY (event_timestamp, user_id, event_type);

-- Dimension: Customer - ALL distribution for small lookup table
CREATE TABLE IF NOT EXISTS sales.dim_customer (
    customer_id         BIGINT          NOT NULL,
    customer_key        VARCHAR(32)     NOT NULL        ENCODE lzo,
    first_name          VARCHAR(100)                    ENCODE lzo,
    last_name           VARCHAR(100)                    ENCODE lzo,
    email               VARCHAR(256)                    ENCODE lzo,
    phone               VARCHAR(30)                     ENCODE lzo,
    date_of_birth       DATE                            ENCODE delta32k,
    gender              CHAR(1)                         ENCODE raw,
    marital_status      VARCHAR(10)                     ENCODE bytedict,
    education_level     VARCHAR(50)                     ENCODE bytedict,
    income_bracket      VARCHAR(30)                     ENCODE bytedict,
    address_line1       VARCHAR(200)                    ENCODE lzo,
    address_line2       VARCHAR(200)                    ENCODE lzo,
    city                VARCHAR(100)                    ENCODE lzo,
    state_province      VARCHAR(100)                    ENCODE lzo,
    postal_code         VARCHAR(20)                     ENCODE lzo,
    country             VARCHAR(60)                     ENCODE bytedict,
    registration_date   DATE            NOT NULL        ENCODE delta,
    loyalty_tier        VARCHAR(20)                     ENCODE bytedict,
    is_active           BOOLEAN         DEFAULT TRUE,
    created_at          TIMESTAMP       DEFAULT GETDATE(),
    updated_at          TIMESTAMP       DEFAULT GETDATE(),
    PRIMARY KEY (customer_id)
)
DISTSTYLE ALL
SORTKEY (customer_id);

-- Dimension: Product with ENCODE directives
CREATE TABLE IF NOT EXISTS sales.dim_product (
    product_id          INTEGER         NOT NULL,
    sku                 VARCHAR(50)     NOT NULL        ENCODE lzo,
    product_name        VARCHAR(256)    NOT NULL        ENCODE lzo,
    description         VARCHAR(2000)                   ENCODE lzo,
    category_l1         VARCHAR(100)    NOT NULL        ENCODE bytedict,
    category_l2         VARCHAR(100)                    ENCODE bytedict,
    category_l3         VARCHAR(100)                    ENCODE bytedict,
    brand               VARCHAR(100)                    ENCODE bytedict,
    supplier_id         INTEGER                         ENCODE az64,
    unit_cost           DECIMAL(10,2)                   ENCODE az64,
    list_price          DECIMAL(10,2)                   ENCODE az64,
    weight_kg           DECIMAL(8,3)                    ENCODE az64,
    color               VARCHAR(30)                     ENCODE bytedict,
    size                VARCHAR(20)                     ENCODE bytedict,
    is_active           BOOLEAN         DEFAULT TRUE,
    launch_date         DATE                            ENCODE delta,
    discontinue_date    DATE                            ENCODE delta,
    PRIMARY KEY (product_id)
)
DISTSTYLE ALL
SORTKEY (product_id);

-- Dimension: Date with dense columns
CREATE TABLE IF NOT EXISTS sales.dim_date (
    date_key            INTEGER         NOT NULL,
    full_date           DATE            NOT NULL        ENCODE delta,
    day_of_week         SMALLINT        NOT NULL        ENCODE az64,
    day_name            VARCHAR(10)     NOT NULL        ENCODE bytedict,
    day_of_month        SMALLINT        NOT NULL        ENCODE az64,
    day_of_year         SMALLINT        NOT NULL        ENCODE az64,
    week_of_year        SMALLINT        NOT NULL        ENCODE az64,
    month_num           SMALLINT        NOT NULL        ENCODE az64,
    month_name          VARCHAR(10)     NOT NULL        ENCODE bytedict,
    quarter_num         SMALLINT        NOT NULL        ENCODE az64,
    quarter_name        CHAR(2)         NOT NULL        ENCODE lzo,
    year_num            SMALLINT        NOT NULL        ENCODE az64,
    fiscal_month        SMALLINT                        ENCODE az64,
    fiscal_quarter      SMALLINT                        ENCODE az64,
    fiscal_year         SMALLINT                        ENCODE az64,
    is_weekend          BOOLEAN         NOT NULL,
    is_holiday          BOOLEAN         DEFAULT FALSE,
    holiday_name        VARCHAR(50)                     ENCODE lzo,
    PRIMARY KEY (date_key)
)
DISTSTYLE ALL
SORTKEY (full_date);

-- Staging table with AUTO distribution
CREATE TABLE IF NOT EXISTS staging.stg_daily_sales (
    record_id           BIGINT          IDENTITY(1,1),
    source_system       VARCHAR(30)     NOT NULL        ENCODE bytedict,
    sale_date           DATE            NOT NULL,
    store_code          VARCHAR(20)     NOT NULL        ENCODE lzo,
    product_sku         VARCHAR(50)     NOT NULL        ENCODE lzo,
    quantity            INTEGER,
    amount              DECIMAL(12,2),
    load_timestamp      TIMESTAMP       DEFAULT GETDATE()
)
DISTSTYLE AUTO;

-- ---------------------------------------------------------------------------
-- 2. External Tables (Redshift Spectrum)
-- ---------------------------------------------------------------------------

CREATE EXTERNAL SCHEMA IF NOT EXISTS spectrum_schema
FROM DATA CATALOG
DATABASE 'analytics_lake'
IAM_ROLE 'arn:aws:iam::123456789012:role/RedshiftSpectrumRole'
CREATE EXTERNAL DATABASE IF NOT EXISTS;

CREATE EXTERNAL TABLE spectrum_schema.ext_server_logs (
    log_timestamp       TIMESTAMP,
    log_level           VARCHAR(10),
    service_name        VARCHAR(100),
    request_id          VARCHAR(64),
    http_method         VARCHAR(10),
    endpoint            VARCHAR(500),
    status_code         INTEGER,
    response_time_ms    INTEGER,
    user_id             BIGINT,
    error_message       VARCHAR(2000)
)
PARTITIONED BY (log_date DATE)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    'separatorChar' = ',',
    'quoteChar' = '"',
    'escapeChar' = '\\'
)
STORED AS TEXTFILE
LOCATION 's3://data-lake/server-logs/'
TABLE PROPERTIES ('numRows' = '100000000');

CREATE EXTERNAL TABLE spectrum_schema.ext_parquet_events (
    event_id            VARCHAR(64),
    event_type          VARCHAR(50),
    event_timestamp     TIMESTAMP,
    user_id             BIGINT,
    properties          VARCHAR(65535)
)
PARTITIONED BY (event_date VARCHAR(10))
STORED AS PARQUET
LOCATION 's3://data-lake/events/parquet/';

-- Super (semi-structured) data type table
CREATE TABLE IF NOT EXISTS analytics.json_events (
    event_id            VARCHAR(64)     NOT NULL        ENCODE lzo,
    event_timestamp     TIMESTAMP       NOT NULL        ENCODE az64,
    event_payload       SUPER                           ENCODE lzo,
    PRIMARY KEY (event_id)
)
DISTSTYLE KEY
DISTKEY (event_id)
SORTKEY (event_timestamp);

-- ---------------------------------------------------------------------------
-- 3. Views (including late-binding)
-- ---------------------------------------------------------------------------

-- Standard view with Redshift-specific functions
CREATE OR REPLACE VIEW analytics.v_customer_segments AS
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS full_name,
    c.loyalty_tier,
    c.country,
    COUNT(s.sale_id) AS total_orders,
    SUM(s.net_amount) AS total_spend,
    AVG(s.net_amount) AS avg_order_value,
    DATEDIFF(day, MAX(s.sale_date), GETDATE()) AS days_since_last_order,
    LISTAGG(DISTINCT s.channel, ', ') WITHIN GROUP (ORDER BY s.channel) AS channels_used,
    NTILE(5) OVER (ORDER BY SUM(s.net_amount) DESC) AS spend_quintile,
    CASE
        WHEN DATEDIFF(day, MAX(s.sale_date), GETDATE()) <= 30 THEN 'Active'
        WHEN DATEDIFF(day, MAX(s.sale_date), GETDATE()) <= 90 THEN 'At Risk'
        WHEN DATEDIFF(day, MAX(s.sale_date), GETDATE()) <= 180 THEN 'Lapsing'
        ELSE 'Churned'
    END AS recency_segment
FROM sales.dim_customer c
LEFT JOIN sales.fact_sales s ON c.customer_id = s.customer_id
WHERE c.is_active = TRUE
GROUP BY c.customer_id, c.first_name, c.last_name, c.loyalty_tier, c.country;

-- Late-binding view (Spectrum)
CREATE VIEW analytics.v_combined_events AS
SELECT
    event_id,
    event_type,
    event_timestamp,
    user_id,
    'spectrum' AS source
FROM spectrum_schema.ext_parquet_events
UNION ALL
SELECT
    CAST(click_id AS VARCHAR(64)) AS event_id,
    event_type,
    event_timestamp,
    user_id,
    'native' AS source
FROM web.fact_clickstream
WITH NO SCHEMA BINDING;

-- View with APPROXIMATE functions
CREATE OR REPLACE VIEW analytics.v_traffic_summary AS
SELECT
    TRUNC(event_timestamp) AS event_date,
    event_type,
    country_code,
    COUNT(*) AS event_count,
    APPROXIMATE COUNT(DISTINCT user_id) AS approx_unique_users,
    APPROXIMATE COUNT(DISTINCT session_id) AS approx_unique_sessions,
    APPROXIMATE PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY duration_ms) AS p50_duration_ms,
    APPROXIMATE PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY duration_ms) AS p95_duration_ms,
    APPROXIMATE PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY duration_ms) AS p99_duration_ms,
    MEDIAN(duration_ms) AS median_duration_ms
FROM web.fact_clickstream
GROUP BY 1, 2, 3;

-- View using Redshift system tables (inspired by awslabs/amazon-redshift-utils)
CREATE OR REPLACE VIEW admin.v_table_storage_info AS
SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    ti."diststyle",
    ti."sortkey1",
    ti.tbl_rows AS row_count,
    ti.size AS size_mb,
    ti.pct_used,
    ti.unsorted,
    ti.stats_off,
    ti.skew_rows,
    ti.skew_sortkey1
FROM svv_table_info ti
JOIN pg_class c ON c.oid = ti.table_id
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_internal')
ORDER BY ti.size DESC;

-- View with window functions and Redshift JSON parsing
CREATE OR REPLACE VIEW analytics.v_session_analysis AS
SELECT
    session_id,
    user_id,
    MIN(event_timestamp) AS session_start,
    MAX(event_timestamp) AS session_end,
    DATEDIFF(second, MIN(event_timestamp), MAX(event_timestamp)) AS session_duration_sec,
    COUNT(*) AS total_events,
    SUM(CASE WHEN event_type = 'page_view' THEN 1 ELSE 0 END) AS page_views,
    SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchases,
    FIRST_VALUE(page_url) OVER (
        PARTITION BY session_id ORDER BY event_timestamp
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS landing_page,
    LAST_VALUE(page_url) OVER (
        PARTITION BY session_id ORDER BY event_timestamp
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS exit_page,
    RATIO_TO_REPORT(COUNT(*)) OVER () AS event_share
FROM web.fact_clickstream
GROUP BY session_id, user_id, page_url, event_timestamp;

-- Admin view for query monitoring
CREATE OR REPLACE VIEW admin.v_running_queries AS
SELECT
    userid,
    query,
    pid,
    starttime,
    DATEDIFF(second, starttime, GETDATE()) AS duration_sec,
    TRIM(querytxt) AS query_text,
    label,
    stl.aborted,
    stl.insert_pristine,
    svl.elapsed / 1000000.0 AS total_elapsed_sec,
    svl.rows AS row_count,
    svl.bytes / (1024*1024.0) AS data_mb
FROM stl_query stl
LEFT JOIN svl_query_summary svl ON stl.query = svl.query
WHERE stl.endtime > GETDATE() - INTERVAL '1 hour'
    AND userid > 1
    AND aborted = 0
ORDER BY starttime DESC;

-- ---------------------------------------------------------------------------
-- 4. Materialized Views
-- ---------------------------------------------------------------------------

CREATE MATERIALIZED VIEW analytics.mv_daily_product_sales
DISTSTYLE KEY
DISTKEY (product_id)
SORTKEY (sale_date)
AUTO REFRESH YES
AS
SELECT
    s.sale_date,
    s.product_id,
    p.product_name,
    p.category_l1,
    p.brand,
    COUNT(*) AS transactions,
    SUM(s.quantity_sold) AS units_sold,
    SUM(s.net_amount) AS total_revenue,
    AVG(s.net_amount) AS avg_transaction_value,
    SUM(s.discount_amount) AS total_discounts
FROM sales.fact_sales s
JOIN sales.dim_product p ON s.product_id = p.product_id
GROUP BY s.sale_date, s.product_id, p.product_name, p.category_l1, p.brand;

CREATE MATERIALIZED VIEW analytics.mv_hourly_traffic
DISTSTYLE EVEN
SORTKEY (event_hour)
AUTO REFRESH YES
AS
SELECT
    DATE_TRUNC('hour', event_timestamp) AS event_hour,
    event_type,
    country_code,
    device_type,
    COUNT(*) AS event_count,
    COUNT(DISTINCT user_id) AS unique_users,
    COUNT(DISTINCT session_id) AS unique_sessions,
    AVG(duration_ms) AS avg_duration_ms
FROM web.fact_clickstream
GROUP BY 1, 2, 3, 4;

-- ---------------------------------------------------------------------------
-- 5. COPY and UNLOAD Statements
-- ---------------------------------------------------------------------------

-- COPY from S3 with various options
COPY staging.stg_daily_sales
FROM 's3://my-bucket/data/daily_sales/'
IAM_ROLE 'arn:aws:iam::123456789012:role/RedshiftLoadRole'
FORMAT AS PARQUET
ACCEPTANYDATE
DATEFORMAT 'auto'
TIMEFORMAT 'auto'
COMPUPDATE ON
STATUPDATE ON
MAXERROR 100;

COPY staging.stg_daily_sales
FROM 's3://my-bucket/data/daily_sales_csv/'
IAM_ROLE 'arn:aws:iam::123456789012:role/RedshiftLoadRole'
CSV
IGNOREHEADER 1
DELIMITER ','
REGION 'us-east-1'
GZIP
TRUNCATECOLUMNS
BLANKSASNULL
EMPTYASNULL
ACCEPTINVCHARS '?'
COMPUPDATE PRESET;

-- UNLOAD to S3
UNLOAD ('SELECT * FROM analytics.mv_daily_product_sales WHERE sale_date >= DATEADD(day, -7, GETDATE())')
TO 's3://my-bucket/exports/weekly_product_sales_'
IAM_ROLE 'arn:aws:iam::123456789012:role/RedshiftUnloadRole'
FORMAT AS PARQUET
ALLOWOVERWRITE
PARALLEL ON
MAXFILESIZE 256 MB;

UNLOAD ('SELECT customer_id, full_name, total_spend, recency_segment FROM analytics.v_customer_segments')
TO 's3://my-bucket/exports/customer_segments_'
IAM_ROLE 'arn:aws:iam::123456789012:role/RedshiftUnloadRole'
CSV
HEADER
DELIMITER ','
ADDQUOTES
GZIP
ALLOWOVERWRITE;

-- ---------------------------------------------------------------------------
-- 6. Stored Procedure (Redshift PL/pgSQL)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE analytics.sp_refresh_daily_summary(p_date DATE)
AS $$
BEGIN
    DELETE FROM analytics.daily_summary WHERE report_date = p_date;

    INSERT INTO analytics.daily_summary
    SELECT
        p_date AS report_date,
        s.store_id,
        p.category_l1,
        COUNT(DISTINCT s.customer_id) AS unique_customers,
        COUNT(*) AS transaction_count,
        SUM(s.net_amount) AS total_revenue,
        AVG(s.net_amount) AS avg_transaction_value,
        SUM(s.discount_amount) AS total_discounts,
        SUM(s.quantity_sold) AS total_units
    FROM sales.fact_sales s
    JOIN sales.dim_product p ON s.product_id = p.product_id
    WHERE s.sale_date = p_date
    GROUP BY s.store_id, p.category_l1;

    RAISE INFO 'Daily summary refreshed for %', p_date;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- 7. User and permissions (Redshift-specific)
-- ---------------------------------------------------------------------------

CREATE GROUP data_analysts;
CREATE GROUP data_engineers;

ALTER DEFAULT PRIVILEGES IN SCHEMA analytics
GRANT SELECT ON TABLES TO GROUP data_analysts;

ALTER DEFAULT PRIVILEGES IN SCHEMA sales
GRANT SELECT ON TABLES TO GROUP data_analysts;

GRANT USAGE ON SCHEMA analytics TO GROUP data_analysts;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO GROUP data_analysts;
GRANT ALL ON SCHEMA staging TO GROUP data_engineers;
