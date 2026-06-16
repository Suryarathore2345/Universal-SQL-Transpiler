-- =============================================================================
-- KITCHEN SINK: Google BigQuery
-- Exercises all BigQuery types (INT64, FLOAT64, NUMERIC, BIGNUMERIC, STRING,
-- BOOL, DATE, TIMESTAMP, DATETIME), PARTITION BY expression,
-- CLUSTER BY (max 4), NOT ENFORCED PK/FK, OPTIONS(), CREATE VIEW,
-- CREATE MATERIALIZED VIEW with OPTIONS, CREATE PROCEDURE, CREATE FUNCTION.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Dimension table — all BigQuery scalar types, NOT ENFORCED constraints,
--    OPTIONS(), CLUSTER BY
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE `myproject.analytics.dim_customers` (
    customer_id         INT64           NOT NULL,
    customer_uuid       STRING          NOT NULL,
    full_name           STRING          NOT NULL,
    email               STRING          NOT NULL,
    tier                STRING          DEFAULT 'standard',
    score               NUMERIC         DEFAULT 0.00,
    is_active           BOOL            DEFAULT TRUE,
    signup_date         DATE            NOT NULL,
    last_login          TIMESTAMP,
    last_login_dt       DATETIME,
    region_code         STRING,
    lifetime_value      FLOAT64,
    age_bucket          INT64,
    big_number          BIGNUMERIC,
    raw_bytes           BYTES,
    PRIMARY KEY (customer_id) NOT ENFORCED,
    FOREIGN KEY (customer_id) REFERENCES `myproject.analytics.dim_customers` (customer_id) NOT ENFORCED
)
OPTIONS (
    description        = 'Customer dimension table',
    expiration_timestamp = TIMESTAMP '2099-12-31 00:00:00 UTC',
    require_partition_filter = FALSE
)
PARTITION BY DATE(signup_date)
CLUSTER BY tier, region_code;

-- ---------------------------------------------------------------------------
-- 2. Fact table — PARTITION BY TIMESTAMP_TRUNC, CLUSTER BY 4 cols
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE `myproject.analytics.fact_orders` (
    order_id        INT64           NOT NULL,
    customer_id     INT64           NOT NULL,
    product_id      INT64           NOT NULL,
    order_amount    NUMERIC         NOT NULL DEFAULT 0.0,
    discount_pct    FLOAT64         DEFAULT 0.0,
    tax_amount      NUMERIC         DEFAULT 0.0,
    quantity        INT64           DEFAULT 1,
    is_gift         BOOL            DEFAULT FALSE,
    notes           STRING,
    order_code      STRING,
    order_date      DATE            NOT NULL,
    created_at      TIMESTAMP       NOT NULL,
    updated_at      TIMESTAMP,
    PRIMARY KEY (order_id) NOT ENFORCED,
    FOREIGN KEY (customer_id)
        REFERENCES `myproject.analytics.dim_customers` (customer_id) NOT ENFORCED
)
PARTITION BY TIMESTAMP_TRUNC(created_at, MONTH)
CLUSTER BY customer_id, product_id, order_date, is_gift;

-- ---------------------------------------------------------------------------
-- 3. RANGE_BUCKET partition (advanced)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE `myproject.analytics.fact_orders_bucketed` (
    order_id        INT64           NOT NULL,
    customer_id     INT64           NOT NULL,
    order_amount    NUMERIC         NOT NULL,
    score_bucket    INT64           NOT NULL
)
PARTITION BY RANGE_BUCKET(score_bucket, GENERATE_ARRAY(0, 100, 10))
CLUSTER BY customer_id;

-- ---------------------------------------------------------------------------
-- 4. Simple view
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `myproject.analytics.v_active_customers` AS
SELECT
    customer_id,
    full_name,
    email,
    tier,
    IFNULL(region_code, 'UNK') AS region_code,
    signup_date
FROM `myproject.analytics.dim_customers`
WHERE is_active = TRUE;

-- ---------------------------------------------------------------------------
-- 5. Materialized view with OPTIONS
-- ---------------------------------------------------------------------------
CREATE OR REPLACE MATERIALIZED VIEW `myproject.analytics.mv_customer_totals`
OPTIONS (
    enable_refresh         = TRUE,
    refresh_interval_minutes = 60
) AS
SELECT
    c.tier,
    DATE_TRUNC(o.order_date, MONTH)  AS order_month,
    COUNT(*)                          AS order_count,
    SUM(o.order_amount)               AS total_amount,
    AVG(o.discount_pct)               AS avg_discount
FROM `myproject.analytics.fact_orders`   o
JOIN `myproject.analytics.dim_customers` c ON o.customer_id = c.customer_id
GROUP BY c.tier, DATE_TRUNC(o.order_date, MONTH);

-- ---------------------------------------------------------------------------
-- 6. Stored procedure (BigQuery Scripting)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE `myproject.analytics.sp_update_customer_tier`(
    IN  p_customer_id   INT64,
    IN  p_email         STRING,
    IN  p_tier          STRING
)
BEGIN
    UPDATE `myproject.analytics.dim_customers`
    SET
        email      = IFNULL(p_email, email),
        tier       = COALESCE(p_tier, tier),
        last_login = CURRENT_TIMESTAMP()
    WHERE customer_id = p_customer_id;
END;

-- ---------------------------------------------------------------------------
-- 7. SQL UDF
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION `myproject.analytics.fn_safe_divide`(
    numerator   FLOAT64,
    denominator FLOAT64
)
RETURNS FLOAT64
AS (
    CASE WHEN denominator = 0 THEN 0.0 ELSE numerator / denominator END
);
