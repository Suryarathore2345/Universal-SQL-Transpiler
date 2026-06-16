-- =============================================================================
-- KITCHEN SINK: Azure Synapse Analytics
-- Exercises DISTRIBUTION, PARTITION, CLUSTERED COLUMNSTORE INDEX,
-- NOT ENFORCED constraints, all T-SQL types, MV, PROCEDURE, FUNCTION.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Dimension table — REPLICATE distribution, HEAP index
-- ---------------------------------------------------------------------------
CREATE TABLE dbo.dim_customers (
    customer_id         BIGINT          NOT NULL,
    customer_uuid       NVARCHAR(36)    NOT NULL,
    full_name           NVARCHAR(255)   NOT NULL,
    email               NVARCHAR(320)   NOT NULL,
    tier                VARCHAR(20)     NOT NULL DEFAULT 'standard',
    score               DECIMAL(5, 2)   DEFAULT 0.00,
    is_active           BIT             NOT NULL DEFAULT 1,
    signup_date         DATE            NOT NULL,
    last_login          DATETIME2,
    region_code         CHAR(3),
    lifetime_value      FLOAT,
    PRIMARY KEY NONCLUSTERED (customer_id) NOT ENFORCED,
    UNIQUE NONCLUSTERED (customer_uuid) NOT ENFORCED,
    UNIQUE NONCLUSTERED (email) NOT ENFORCED
)
WITH (
    DISTRIBUTION = REPLICATE,
    HEAP
);

-- ---------------------------------------------------------------------------
-- 2. Fact table — HASH distribution, CLUSTERED COLUMNSTORE INDEX, PARTITION
-- ---------------------------------------------------------------------------
CREATE TABLE dbo.fact_orders (
    order_id        BIGINT          NOT NULL,
    customer_id     INT             NOT NULL,
    product_id      INT             NOT NULL,
    order_amount    DECIMAL(18, 4)  NOT NULL DEFAULT 0.0000,
    discount_pct    FLOAT           DEFAULT 0.0,
    tax_amount      NUMERIC(10, 2)  DEFAULT 0.00,
    quantity        SMALLINT        DEFAULT 1,
    is_gift         BIT             DEFAULT 0,
    notes           NVARCHAR(1000)  DEFAULT 'N/A',
    order_code      CHAR(10),
    order_date      DATE            NOT NULL,
    created_at      DATETIME2       NOT NULL,
    updated_at      DATETIMEOFFSET,
    PRIMARY KEY NONCLUSTERED (order_id) NOT ENFORCED,
    FOREIGN KEY (customer_id) REFERENCES dbo.dim_customers (customer_id) NOT ENFORCED,
    UNIQUE NONCLUSTERED (order_code) NOT ENFORCED
)
WITH (
    DISTRIBUTION = HASH(customer_id),
    CLUSTERED COLUMNSTORE INDEX,
    PARTITION (order_date RANGE RIGHT FOR VALUES (
        '2023-01-01', '2024-01-01', '2025-01-01', '2026-01-01'
    ))
);

-- ---------------------------------------------------------------------------
-- 3. ROUND_ROBIN table for staging
-- ---------------------------------------------------------------------------
CREATE TABLE dbo.staging_orders (
    order_id        BIGINT,
    customer_id     INT,
    order_amount    DECIMAL(18, 4),
    loaded_at       DATETIME2       NOT NULL DEFAULT GETDATE()
)
WITH (
    DISTRIBUTION = ROUND_ROBIN,
    HEAP
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
-- 5. Materialized view with ROUND_ROBIN distribution
-- ---------------------------------------------------------------------------
CREATE MATERIALIZED VIEW dbo.mv_customer_totals
WITH (DISTRIBUTION = ROUND_ROBIN) AS
SELECT
    c.tier,
    CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, o.order_date), 0) AS DATE) AS order_month,
    COUNT_BIG(*)                                                        AS order_count,
    SUM(o.order_amount)                                                 AS total_amount
FROM dbo.fact_orders   o
JOIN dbo.dim_customers c ON o.customer_id = c.customer_id
GROUP BY c.tier, CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, o.order_date), 0) AS DATE);

-- ---------------------------------------------------------------------------
-- 6. Stored procedure
-- ---------------------------------------------------------------------------
CREATE PROCEDURE dbo.sp_update_customer_tier
    @p_customer_id  BIGINT,
    @p_email        NVARCHAR(320),
    @p_tier         VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.dim_customers
    SET
        email   = ISNULL(@p_email, email),
        tier    = COALESCE(@p_tier, tier)
    WHERE customer_id = @p_customer_id;
END;
