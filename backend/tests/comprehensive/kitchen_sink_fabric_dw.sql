-- =============================================================================
-- KITCHEN SINK: Microsoft Fabric Data Warehouse
-- Exercises CLUSTER BY (max 4), all supported Fabric DW T-SQL types,
-- NO DEFAULT constraints (not supported), PK/FK NOT ENFORCED,
-- VIEW, PROCEDURE, FUNCTION.
-- Per official docs: https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Dimension table — supported Fabric DW types, CLUSTER BY, no DEFAULT
-- ---------------------------------------------------------------------------
CREATE TABLE dbo.dim_customers (
    customer_id         BIGINT          NOT NULL,
    customer_uuid       VARCHAR(36)     NOT NULL,
    full_name           VARCHAR(255)    NOT NULL,
    email               VARCHAR(320)    NOT NULL,
    tier                VARCHAR(20)     NOT NULL,
    score               DECIMAL(5, 2)   NOT NULL,
    is_active           BIT             NOT NULL,
    signup_date         DATE            NOT NULL,
    last_login          DATETIME2(6),
    last_login_tz       DATETIMEOFFSET(3),
    region_code         CHAR(3),
    lifetime_value      FLOAT,
    PRIMARY KEY (customer_id),
    UNIQUE (customer_uuid),
    UNIQUE (email)
)
WITH (CLUSTER BY (signup_date, tier));

-- ---------------------------------------------------------------------------
-- 2. Fact table — CLUSTER BY 4 columns (max allowed), FK NOT ENFORCED
-- ---------------------------------------------------------------------------
CREATE TABLE dbo.fact_orders (
    order_id        BIGINT          NOT NULL,
    customer_id     INT             NOT NULL,
    product_id      INT             NOT NULL,
    order_amount    DECIMAL(18, 4)  NOT NULL,
    discount_pct    FLOAT,
    tax_amount      NUMERIC(10, 2),
    quantity        SMALLINT,
    is_gift         BIT,
    notes           VARCHAR(1000),
    order_code      CHAR(10),
    order_date      DATE            NOT NULL,
    created_at      DATETIME2(6)    NOT NULL,
    updated_at      DATETIMEOFFSET,
    PRIMARY KEY (order_id),
    FOREIGN KEY (customer_id) REFERENCES dbo.dim_customers (customer_id),
    UNIQUE (order_code)
)
WITH (CLUSTER BY (order_date, customer_id, product_id, order_amount));

-- ---------------------------------------------------------------------------
-- 3. Staging table — no clustering
-- ---------------------------------------------------------------------------
CREATE TABLE dbo.staging_orders (
    order_id        BIGINT          NOT NULL,
    customer_id     INT             NOT NULL,
    order_amount    DECIMAL(18, 4)  NOT NULL,
    loaded_at       DATETIME2(6)    NOT NULL
);

-- ---------------------------------------------------------------------------
-- 4. Simple view
-- ---------------------------------------------------------------------------
CREATE VIEW dbo.v_active_customers AS
SELECT
    customer_id,
    full_name,
    email,
    tier,
    ISNULL(region_code, 'UNK') AS region_code,
    signup_date
FROM dbo.dim_customers
WHERE is_active = 1;

-- ---------------------------------------------------------------------------
-- 5. Stored procedure
-- ---------------------------------------------------------------------------
CREATE PROCEDURE dbo.sp_update_customer_tier
    @p_customer_id  BIGINT,
    @p_email        VARCHAR(320),
    @p_tier         VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.dim_customers
    SET
        email = ISNULL(@p_email, email),
        tier  = COALESCE(@p_tier, tier)
    WHERE customer_id = @p_customer_id;
END;

-- ---------------------------------------------------------------------------
-- 6. Scalar function
-- ---------------------------------------------------------------------------
CREATE FUNCTION dbo.fn_safe_divide(
    @numerator      DECIMAL(18, 4),
    @denominator    DECIMAL(18, 4)
)
RETURNS DECIMAL(18, 4)
AS
BEGIN
    RETURN CASE WHEN @denominator = 0 THEN 0 ELSE @numerator / @denominator END;
END;
