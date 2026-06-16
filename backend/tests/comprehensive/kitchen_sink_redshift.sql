-- =============================================================================
-- KITCHEN SINK: Amazon Redshift
-- Exercises every code path the Redshift parser + all 8 generators handle.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Dimension table — DISTSTYLE ALL, INTERLEAVED SORTKEY,
--    all basic types, DEFAULT values, CHECK, UNIQUE
-- ---------------------------------------------------------------------------
CREATE TABLE analytics.dim_customers (
    customer_id     BIGINT          IDENTITY(1,1)   NOT NULL,
    customer_uuid   VARCHAR(36)     NOT NULL,
    full_name       VARCHAR(255)    NOT NULL,
    email           VARCHAR(320)    NOT NULL,
    tier            VARCHAR(20)     DEFAULT 'standard'  NOT NULL,
    score           DECIMAL(5, 2)   DEFAULT 0.00,
    is_active       BOOLEAN         DEFAULT TRUE,
    signup_date     DATE            NOT NULL,
    last_login      TIMESTAMP,
    last_login_tz   TIMESTAMPTZ,
    region_code     CHAR(3),
    age_bucket      SMALLINT,
    lifetime_value  REAL,
    raw_flags       INTEGER         DEFAULT 0,
    PRIMARY KEY (customer_id),
    UNIQUE (customer_uuid),
    UNIQUE (email),
    CHECK (tier IN ('standard', 'premium', 'enterprise'))
)
DISTSTYLE ALL
INTERLEAVED SORTKEY (signup_date, score);

-- ---------------------------------------------------------------------------
-- 2. Fact table — DISTSTYLE KEY, DISTKEY, COMPOUND SORTKEY,
--    FK reference, ENCODE hint, all numeric types
-- ---------------------------------------------------------------------------
CREATE TABLE analytics.fact_orders (
    order_id        BIGINT          IDENTITY(1,1),
    customer_id     INTEGER         NOT NULL,
    product_id      INTEGER         NOT NULL,
    order_amount    DECIMAL(18, 4)  NOT NULL DEFAULT 0.0000,
    discount_pct    FLOAT           DEFAULT 0.0,
    tax_amount      NUMERIC(10, 2)  DEFAULT 0.00,
    quantity        INTEGER         DEFAULT 1,
    is_gift         BOOLEAN         DEFAULT FALSE,
    notes           VARCHAR(1000)   DEFAULT 'N/A',
    order_code      CHAR(10),
    order_date      DATE            NOT NULL,
    created_at      TIMESTAMP       NOT NULL,
    updated_at      TIMESTAMPTZ,
    raw_payload     VARCHAR(65535),
    PRIMARY KEY (order_id),
    FOREIGN KEY (customer_id) REFERENCES analytics.dim_customers (customer_id),
    UNIQUE (order_code)
)
DISTSTYLE KEY
DISTKEY (customer_id)
COMPOUND SORTKEY (order_date, customer_id);

-- ---------------------------------------------------------------------------
-- 3. Simple SELECT view
-- ---------------------------------------------------------------------------
CREATE VIEW analytics.v_active_customers AS
SELECT
    customer_id,
    full_name,
    email,
    tier,
    NVL(region_code, 'UNK') AS region_code,
    signup_date
FROM analytics.dim_customers
WHERE is_active = TRUE;

-- ---------------------------------------------------------------------------
-- 4. Late binding view (detects WITH NO SCHEMA BINDING keyword)
-- ---------------------------------------------------------------------------
CREATE VIEW analytics.v_orders_external
WITH NO SCHEMA BINDING AS
SELECT order_id, customer_id, order_amount, order_date
FROM analytics.fact_orders;

-- ---------------------------------------------------------------------------
-- 5. Materialized view with AUTO REFRESH
-- ---------------------------------------------------------------------------
CREATE MATERIALIZED VIEW analytics.mv_customer_totals
AUTO REFRESH YES AS
SELECT
    c.tier,
    DATE_TRUNC('month', o.order_date)   AS order_month,
    COUNT(*)                             AS order_count,
    SUM(o.order_amount)                  AS total_amount,
    AVG(o.discount_pct)                  AS avg_discount
FROM analytics.fact_orders   o
JOIN analytics.dim_customers c ON o.customer_id = c.customer_id
GROUP BY c.tier, DATE_TRUNC('month', o.order_date);

-- ---------------------------------------------------------------------------
-- 6. Stored procedure — exercises NVL, NVL2, DECODE, :: cast, GETDATE()
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE analytics.sp_update_customer_tier(
    p_customer_id   INTEGER,
    p_email         VARCHAR(320),
    p_tier          VARCHAR(20)
)
AS $$
DECLARE
    v_current_tier VARCHAR(20);
BEGIN
    SELECT tier INTO v_current_tier
    FROM analytics.dim_customers
    WHERE customer_id = p_customer_id;

    UPDATE analytics.dim_customers
    SET
        email        = NVL(p_email, email),
        tier         = NVL2(
                         p_tier,
                         DECODE(p_tier,
                             'gold',   'premium',
                             'silver', 'standard',
                             'bronze', 'standard',
                             p_tier
                         ),
                         v_current_tier
                       ),
        last_login   = CAST(GETDATE() AS TIMESTAMP),
        score        = score + 1.0::DECIMAL(5,2)
    WHERE customer_id = p_customer_id;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- 7. SQL function — exercises :: cast and CASE
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION analytics.fn_safe_divide(
    p_numerator   DECIMAL(18, 4),
    p_denominator DECIMAL(18, 4)
)
RETURNS DECIMAL(18, 4)
AS $$
    SELECT CASE
        WHEN p_denominator = 0 THEN 0.0::DECIMAL(18,4)
        ELSE p_numerator / p_denominator
    END;
$$ LANGUAGE sql;
