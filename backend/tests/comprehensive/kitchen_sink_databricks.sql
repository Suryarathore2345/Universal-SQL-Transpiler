-- =============================================================================
-- KITCHEN SINK: Databricks (Delta Lake)
-- Exercises GENERATED ALWAYS AS IDENTITY, USING DELTA, PARTITIONED BY,
-- CLUSTER BY (liquid), TBLPROPERTIES, COMMENT, STRING/DECIMAL types,
-- CREATE VIEW, CREATE MATERIALIZED VIEW with CRON, CREATE FUNCTION.
-- Note: Databricks does NOT support CREATE PROCEDURE.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Dimension table — IDENTITY, all Databricks types, CLUSTER BY (liquid)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE main.public.dim_customers (
    customer_id         BIGINT          GENERATED ALWAYS AS IDENTITY,
    customer_uuid       STRING          NOT NULL,
    full_name           STRING          NOT NULL,
    email               STRING          NOT NULL,
    tier                STRING          DEFAULT 'standard' NOT NULL,
    score               DECIMAL(5, 2)   DEFAULT 0.00,
    is_active           BOOLEAN         DEFAULT TRUE,
    signup_date         DATE            NOT NULL,
    last_login          TIMESTAMP,
    region_code         STRING,
    lifetime_value      DOUBLE,
    age_bucket          INT,
    raw_flags           BIGINT          DEFAULT 0,
    PRIMARY KEY (customer_id)
)
USING DELTA
CLUSTER BY (tier, signup_date)
COMMENT 'Customer dimension table'
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'delta.autoOptimize.autoCompact'   = 'true'
);

-- ---------------------------------------------------------------------------
-- 2. Fact table — PARTITIONED BY (classic Hive partitioning)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE main.public.fact_orders (
    order_id        BIGINT          GENERATED ALWAYS AS IDENTITY,
    customer_id     INT             NOT NULL,
    product_id      INT             NOT NULL,
    order_amount    DECIMAL(18, 4)  NOT NULL DEFAULT 0.0000,
    discount_pct    DOUBLE          DEFAULT 0.0,
    tax_amount      DECIMAL(10, 2)  DEFAULT 0.00,
    quantity        INT             DEFAULT 1,
    is_gift         BOOLEAN         DEFAULT FALSE,
    notes           STRING          DEFAULT 'N/A',
    order_code      STRING,
    order_date      DATE            NOT NULL,
    created_at      TIMESTAMP       NOT NULL,
    updated_at      TIMESTAMP,
    PRIMARY KEY (order_id)
)
USING DELTA
PARTITIONED BY (DATE(created_at))
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'quality'                           = 'production'
);

-- ---------------------------------------------------------------------------
-- 3. Staging table — external Delta
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE main.public.staging_orders (
    order_id        BIGINT,
    customer_id     INT,
    order_amount    DECIMAL(18, 4),
    loaded_at       TIMESTAMP
)
USING DELTA;

-- ---------------------------------------------------------------------------
-- 4. Simple view
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW main.public.v_active_customers AS
SELECT
    customer_id,
    full_name,
    email,
    tier,
    COALESCE(region_code, 'UNK') AS region_code,
    signup_date
FROM main.public.dim_customers
WHERE is_active = TRUE;

-- ---------------------------------------------------------------------------
-- 5. Materialized view with scheduled refresh
-- ---------------------------------------------------------------------------
CREATE OR REPLACE MATERIALIZED VIEW main.public.mv_customer_totals
SCHEDULE CRON '0 0 * * *'
AS
SELECT
    c.tier,
    DATE_TRUNC('MONTH', o.created_at) AS order_month,
    COUNT(*)                           AS order_count,
    SUM(o.order_amount)                AS total_amount,
    AVG(o.discount_pct)                AS avg_discount
FROM main.public.fact_orders   o
JOIN main.public.dim_customers c ON o.customer_id = c.customer_id
GROUP BY c.tier, DATE_TRUNC('MONTH', o.created_at);

-- ---------------------------------------------------------------------------
-- 6. SQL function (Databricks does NOT support stored procedures)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION main.public.fn_safe_divide(
    numerator   DECIMAL(18, 4),
    denominator DECIMAL(18, 4)
)
RETURNS DECIMAL(18, 4)
RETURN CASE
    WHEN denominator = 0 THEN CAST(0.0 AS DECIMAL(18, 4))
    ELSE numerator / denominator
END;
