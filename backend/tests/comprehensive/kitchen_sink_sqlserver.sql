-- =============================================================================
-- KITCHEN SINK: Microsoft SQL Server
-- Exercises IDENTITY, all T-SQL types, named constraints, ISNULL,
-- CREATE VIEW WITH SCHEMABINDING, PROCEDURE, FUNCTION.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Dimension table — IDENTITY, all T-SQL types, named constraints
-- ---------------------------------------------------------------------------
CREATE TABLE dbo.dim_customers (
    customer_id         BIGINT          IDENTITY(1,1)   NOT NULL,
    customer_uuid       UNIQUEIDENTIFIER                NOT NULL DEFAULT NEWID(),
    full_name           NVARCHAR(255)                   NOT NULL,
    email               NVARCHAR(320)                   NOT NULL,
    tier                VARCHAR(20)                     NOT NULL DEFAULT 'standard',
    score               DECIMAL(5, 2)                   NOT NULL DEFAULT 0.00,
    is_active           BIT                             NOT NULL DEFAULT 1,
    signup_date         DATE                            NOT NULL,
    last_login          DATETIME2(6),
    last_login_tz       DATETIMEOFFSET(3),
    region_code         CHAR(3),
    lifetime_value      FLOAT,
    raw_notes           NVARCHAR(MAX),
    row_version         ROWVERSION,
    CONSTRAINT PK_dim_customers            PRIMARY KEY CLUSTERED (customer_id),
    CONSTRAINT UQ_dim_customers_uuid       UNIQUE (customer_uuid),
    CONSTRAINT UQ_dim_customers_email      UNIQUE (email),
    CONSTRAINT CK_dim_customers_tier       CHECK (tier IN ('standard', 'premium', 'enterprise')),
    CONSTRAINT CK_dim_customers_score      CHECK (score >= 0 AND score <= 100)
);

-- ---------------------------------------------------------------------------
-- 2. Fact table — named FK, composite PK, all numeric types
-- ---------------------------------------------------------------------------
CREATE TABLE dbo.fact_orders (
    order_id        BIGINT          IDENTITY(1,1)   NOT NULL,
    customer_id     INT                             NOT NULL,
    product_id      INT                             NOT NULL,
    order_amount    DECIMAL(18, 4)                  NOT NULL DEFAULT 0.0000,
    discount_pct    FLOAT                           DEFAULT 0.0,
    tax_amount      NUMERIC(10, 2)                  DEFAULT 0.00,
    quantity        SMALLINT                        DEFAULT 1,
    is_gift         BIT                             DEFAULT 0,
    notes           NVARCHAR(1000)                  DEFAULT N'N/A',
    order_code      CHAR(10),
    order_date      DATE                            NOT NULL,
    created_at      DATETIME2(6)                    NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at      DATETIMEOFFSET,
    CONSTRAINT PK_fact_orders              PRIMARY KEY CLUSTERED (order_id),
    CONSTRAINT FK_fact_orders_customer     FOREIGN KEY (customer_id)
                                           REFERENCES dbo.dim_customers (customer_id),
    CONSTRAINT UQ_fact_orders_code         UNIQUE (order_code),
    CONSTRAINT CK_fact_orders_qty          CHECK (quantity > 0)
);

-- ---------------------------------------------------------------------------
-- 3. Simple view
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
-- 4. Schema-bound view (for indexed view)
-- ---------------------------------------------------------------------------
CREATE VIEW dbo.v_orders_summary
WITH SCHEMABINDING AS
SELECT
    c.tier,
    CAST(DATEADD(DAY, 1 - DAY(o.order_date), o.order_date) AS DATE) AS order_month,
    COUNT_BIG(*)                                                       AS order_count,
    SUM(o.order_amount)                                                AS total_amount
FROM dbo.fact_orders   o
JOIN dbo.dim_customers c ON o.customer_id = c.customer_id
GROUP BY c.tier, CAST(DATEADD(DAY, 1 - DAY(o.order_date), o.order_date) AS DATE);

-- ---------------------------------------------------------------------------
-- 5. Stored procedure — exercises ISNULL, COALESCE, CASE
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_update_customer_tier
    @p_customer_id  BIGINT,
    @p_email        NVARCHAR(320),
    @p_tier         VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.dim_customers
    SET
        email        = ISNULL(@p_email, email),
        tier         = COALESCE(@p_tier, tier),
        last_login   = SYSUTCDATETIME()
    WHERE customer_id = @p_customer_id;
END;

-- ---------------------------------------------------------------------------
-- 6. Table-valued function
-- ---------------------------------------------------------------------------
CREATE FUNCTION dbo.fn_get_customer_orders(
    @customer_id BIGINT
)
RETURNS TABLE
AS
RETURN (
    SELECT order_id, order_amount, order_date
    FROM dbo.fact_orders
    WHERE customer_id = @customer_id
);
