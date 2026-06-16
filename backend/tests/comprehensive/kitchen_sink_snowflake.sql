-- =============================================================================
-- KITCHEN SINK: Snowflake
-- Exercises AUTOINCREMENT, CLUSTER BY, TRANSIENT, SECURE VIEW,
-- MATERIALIZED VIEW, PROCEDURES, FUNCTIONS, all Snowflake types.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Dimension table — AUTOINCREMENT, all Snowflake types, CLUSTER BY
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE orders_db.public.dim_customers (
    customer_id         NUMBER          AUTOINCREMENT PRIMARY KEY,
    customer_uuid       VARCHAR(36)     NOT NULL UNIQUE,
    full_name           VARCHAR(255)    NOT NULL,
    email               VARCHAR(320)    NOT NULL UNIQUE,
    tier                VARCHAR(20)     DEFAULT 'standard' NOT NULL,
    score               NUMBER(5, 2)    DEFAULT 0.00,
    is_active           BOOLEAN         DEFAULT TRUE,
    signup_date         DATE            NOT NULL,
    last_login          TIMESTAMP_NTZ,
    last_login_tz       TIMESTAMP_TZ,
    updated_at          TIMESTAMP_LTZ,
    region_code         CHAR(3),
    lifetime_value      FLOAT,
    raw_metadata        VARIANT,
    tags                ARRAY,
    attributes          OBJECT,
    FOREIGN KEY (customer_id) REFERENCES orders_db.public.dim_customers (customer_id),
    CHECK (tier IN ('standard', 'premium', 'enterprise'))
)
DATA_RETENTION_TIME_IN_DAYS = 7
CLUSTER BY (tier, TO_DATE(signup_date));

-- ---------------------------------------------------------------------------
-- 2. Fact table — IDENTITY, CLUSTER BY expression, all numeric types
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE orders_db.public.fact_orders (
    order_id        NUMBER          IDENTITY(1, 1) NOT NULL,
    customer_id     NUMBER(10, 0)   NOT NULL,
    product_id      NUMBER(10, 0)   NOT NULL,
    order_amount    NUMBER(18, 4)   NOT NULL DEFAULT 0.0000,
    discount_pct    FLOAT           DEFAULT 0.0,
    tax_amount      NUMBER(10, 2)   DEFAULT 0.00,
    quantity        INTEGER         DEFAULT 1,
    is_gift         BOOLEAN         DEFAULT FALSE,
    notes           TEXT            DEFAULT 'N/A',
    order_code      CHAR(10),
    order_date      DATE            NOT NULL,
    created_at      TIMESTAMP_NTZ   NOT NULL,
    updated_at      TIMESTAMP_TZ,
    raw_payload     VARIANT,
    PRIMARY KEY (order_id),
    FOREIGN KEY (customer_id) REFERENCES orders_db.public.dim_customers (customer_id),
    UNIQUE (order_code)
)
CLUSTER BY (order_date, customer_id);

-- ---------------------------------------------------------------------------
-- 3. Transient table (no fail safe)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE orders_db.public.staging_orders (
    order_id        NUMBER,
    customer_id     NUMBER,
    order_amount    NUMBER(18, 4),
    loaded_at       TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------------
-- 4. Secure view
-- ---------------------------------------------------------------------------
CREATE OR REPLACE SECURE VIEW orders_db.public.v_active_customers AS
SELECT
    customer_id,
    full_name,
    email,
    tier,
    IFNULL(region_code, 'UNK') AS region_code,
    signup_date
FROM orders_db.public.dim_customers
WHERE is_active = TRUE;

-- ---------------------------------------------------------------------------
-- 5. Materialized view (Enterprise Edition)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE MATERIALIZED VIEW orders_db.public.mv_customer_totals AS
SELECT
    c.tier,
    DATE_TRUNC('month', o.order_date)  AS order_month,
    COUNT(*)                            AS order_count,
    SUM(o.order_amount)                 AS total_amount,
    AVG(o.discount_pct)                 AS avg_discount
FROM orders_db.public.fact_orders   o
JOIN orders_db.public.dim_customers c ON o.customer_id = c.customer_id
GROUP BY c.tier, DATE_TRUNC('month', o.order_date);

-- ---------------------------------------------------------------------------
-- 6. Stored procedure (Snowflake Scripting)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE orders_db.public.sp_update_customer_tier(
    P_CUSTOMER_ID   NUMBER,
    P_EMAIL         VARCHAR,
    P_TIER          VARCHAR
)
RETURNS STRING
LANGUAGE SQL
AS $$
BEGIN
    UPDATE orders_db.public.dim_customers
    SET
        email      = COALESCE(P_EMAIL, email),
        tier       = COALESCE(P_TIER, tier),
        updated_at = CURRENT_TIMESTAMP()
    WHERE customer_id = P_CUSTOMER_ID;
    RETURN 'OK';
END;
$$;

-- ---------------------------------------------------------------------------
-- 7. JavaScript UDF
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION orders_db.public.fn_safe_divide(
    numerator   FLOAT,
    denominator FLOAT
)
RETURNS FLOAT
LANGUAGE JAVASCRIPT
AS $$
    if (DENOMINATOR === 0) return 0.0;
    return NUMERATOR / DENOMINATOR;
$$;
