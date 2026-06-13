"""
Canonical SQL inputs for golden-file snapshot tests.

One representative statement per (dialect, object_type) pair.
Each sample exercises the key syntax features of that dialect so
that generator regressions are visible in the diff.

Object types: table, view, mv, procedure, function
"""

# ---------------------------------------------------------------------------
# TABLE
# ---------------------------------------------------------------------------

_TABLE = {
    "redshift": """\
CREATE TABLE analytics.orders (
    order_id    BIGINT        NOT NULL,
    customer_id INTEGER       NOT NULL,
    amount      DECIMAL(18,2) NOT NULL,
    status      VARCHAR(32)   DEFAULT 'pending',
    created_at  TIMESTAMP     NOT NULL,
    PRIMARY KEY (order_id)
)
DISTKEY(customer_id)
SORTKEY(created_at);
""",

    "snowflake": """\
CREATE OR REPLACE TABLE analytics.orders (
    order_id    BIGINT        NOT NULL,
    customer_id INTEGER       NOT NULL,
    amount      NUMBER(18,2)  NOT NULL,
    status      VARCHAR(32)   DEFAULT 'pending',
    created_at  TIMESTAMP_NTZ NOT NULL,
    PRIMARY KEY (order_id)
)
CLUSTER BY (created_at);
""",

    "sqlserver": """\
CREATE TABLE dbo.orders (
    order_id    BIGINT        IDENTITY(1,1) NOT NULL,
    customer_id INTEGER       NOT NULL,
    amount      DECIMAL(18,2) NOT NULL,
    status      NVARCHAR(32)  DEFAULT 'pending',
    created_at  DATETIME2     NOT NULL,
    PRIMARY KEY (order_id)
);
""",

    "synapse": """\
CREATE TABLE dbo.orders (
    order_id    BIGINT        NOT NULL,
    customer_id INTEGER       NOT NULL,
    amount      DECIMAL(18,2) NOT NULL,
    status      NVARCHAR(32)  DEFAULT 'pending',
    created_at  DATETIME2     NOT NULL
)
WITH (
    DISTRIBUTION = HASH(customer_id),
    CLUSTERED COLUMNSTORE INDEX
);
""",

    "fabric_dw": """\
CREATE TABLE dbo.orders (
    order_id    BIGINT        NOT NULL,
    customer_id INTEGER       NOT NULL,
    amount      DECIMAL(18,2) NOT NULL,
    status      NVARCHAR(32)  DEFAULT 'pending',
    created_at  DATETIME2     NOT NULL
)
WITH (CLUSTER BY (customer_id));
""",

    "databricks": """\
CREATE OR REPLACE TABLE analytics.orders (
    order_id    BIGINT        NOT NULL,
    customer_id INTEGER       NOT NULL,
    amount      DECIMAL(18,2) NOT NULL,
    status      STRING        DEFAULT 'pending',
    created_at  TIMESTAMP     NOT NULL
)
USING DELTA
PARTITIONED BY (created_at)
TBLPROPERTIES ('delta.autoOptimize.optimizeWrite' = 'true');
""",

    "oracle": """\
CREATE TABLE hr.orders (
    order_id    NUMBER(19)    GENERATED AS IDENTITY NOT NULL,
    customer_id NUMBER(10)    NOT NULL,
    amount      NUMBER(18,2)  NOT NULL,
    status      VARCHAR2(32)  DEFAULT 'pending',
    created_at  TIMESTAMP     NOT NULL,
    CONSTRAINT pk_orders PRIMARY KEY (order_id)
);
""",

    "bigquery": """\
CREATE OR REPLACE TABLE `analytics.orders` (
    order_id    INT64         NOT NULL,
    customer_id INT64         NOT NULL,
    amount      NUMERIC(18,2) NOT NULL,
    status      STRING        DEFAULT 'pending',
    created_at  TIMESTAMP     NOT NULL
)
PARTITION BY DATE(created_at)
CLUSTER BY (customer_id)
OPTIONS (require_partition_filter = false);
""",
}


# ---------------------------------------------------------------------------
# VIEW
# ---------------------------------------------------------------------------

_VIEW = {
    "redshift": """\
CREATE OR REPLACE VIEW analytics.v_pending_orders AS
SELECT order_id, customer_id, amount, created_at
FROM analytics.orders
WHERE status = 'pending';
""",

    "snowflake": """\
CREATE OR REPLACE VIEW analytics.v_pending_orders AS
SELECT order_id, customer_id, amount, created_at
FROM analytics.orders
WHERE status = 'pending';
""",

    "sqlserver": """\
CREATE VIEW dbo.v_pending_orders AS
SELECT order_id, customer_id, amount, created_at
FROM dbo.orders
WHERE status = 'pending';
""",

    "synapse": """\
CREATE VIEW dbo.v_pending_orders AS
SELECT order_id, customer_id, amount, created_at
FROM dbo.orders
WHERE status = 'pending';
""",

    "fabric_dw": """\
CREATE VIEW dbo.v_pending_orders AS
SELECT order_id, customer_id, amount, created_at
FROM dbo.orders
WHERE status = 'pending';
""",

    "databricks": """\
CREATE OR REPLACE VIEW analytics.v_pending_orders AS
SELECT order_id, customer_id, amount, created_at
FROM analytics.orders
WHERE status = 'pending';
""",

    "oracle": """\
CREATE OR REPLACE VIEW hr.v_pending_orders AS
SELECT order_id, customer_id, amount, created_at
FROM hr.orders
WHERE status = 'pending';
""",

    "bigquery": """\
CREATE OR REPLACE VIEW `analytics.v_pending_orders` AS
SELECT order_id, customer_id, amount, created_at
FROM `analytics.orders`
WHERE status = 'pending';
""",
}


# ---------------------------------------------------------------------------
# MATERIALIZED VIEW
# ---------------------------------------------------------------------------

_MV = {
    "redshift": """\
CREATE MATERIALIZED VIEW analytics.mv_daily_revenue AS
SELECT DATE_TRUNC('day', created_at) AS day,
       SUM(amount)                   AS total_revenue,
       COUNT(*)                      AS order_count
FROM analytics.orders
GROUP BY 1;
""",

    "snowflake": """\
CREATE OR REPLACE MATERIALIZED VIEW analytics.mv_daily_revenue AS
SELECT DATE_TRUNC('day', created_at) AS day,
       SUM(amount)                   AS total_revenue,
       COUNT(*)                      AS order_count
FROM analytics.orders
GROUP BY 1;
""",

    "sqlserver": """\
CREATE MATERIALIZED VIEW dbo.mv_daily_revenue AS
SELECT CAST(created_at AS DATE) AS day,
       SUM(amount)              AS total_revenue,
       COUNT(*)                 AS order_count
FROM dbo.orders
GROUP BY CAST(created_at AS DATE);
""",

    "synapse": """\
CREATE MATERIALIZED VIEW dbo.mv_daily_revenue
WITH (DISTRIBUTION = HASH(day))
AS
SELECT CAST(created_at AS DATE) AS day,
       SUM(amount)              AS total_revenue,
       COUNT_BIG(*)             AS order_count
FROM dbo.orders
GROUP BY CAST(created_at AS DATE);
""",

    "fabric_dw": """\
CREATE MATERIALIZED VIEW dbo.mv_daily_revenue AS
SELECT CAST(created_at AS DATE) AS day,
       SUM(amount)              AS total_revenue,
       COUNT(*)                 AS order_count
FROM dbo.orders
GROUP BY CAST(created_at AS DATE);
""",

    "databricks": """\
CREATE OR REPLACE MATERIALIZED VIEW analytics.mv_daily_revenue AS
SELECT DATE_TRUNC('day', created_at) AS day,
       SUM(amount)                   AS total_revenue,
       COUNT(*)                      AS order_count
FROM analytics.orders
GROUP BY 1;
""",

    "oracle": """\
CREATE MATERIALIZED VIEW hr.mv_daily_revenue AS
SELECT TRUNC(created_at, 'DD') AS day,
       SUM(amount)             AS total_revenue,
       COUNT(*)                AS order_count
FROM hr.orders
GROUP BY TRUNC(created_at, 'DD');
""",

    "bigquery": """\
CREATE OR REPLACE MATERIALIZED VIEW `analytics.mv_daily_revenue`
OPTIONS (enable_refresh = true, refresh_interval_minutes = 60)
AS
SELECT DATE(created_at)    AS day,
       SUM(amount)         AS total_revenue,
       COUNT(*)            AS order_count
FROM `analytics.orders`
GROUP BY 1;
""",
}


# ---------------------------------------------------------------------------
# PROCEDURE
# ---------------------------------------------------------------------------

_PROCEDURE = {
    "redshift": """\
CREATE OR REPLACE PROCEDURE analytics.upsert_order(
    IN p_order_id INTEGER,
    IN p_amount   DECIMAL(18,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO analytics.orders(order_id, amount)
    VALUES (p_order_id, p_amount);
END;
$$;
""",

    "snowflake": """\
CREATE OR REPLACE PROCEDURE analytics.upsert_order(
    p_order_id INT,
    p_amount   FLOAT
)
RETURNS VARIANT
LANGUAGE SQL
AS
$$
DECLARE
    v_count INT;
BEGIN
    INSERT INTO analytics.orders(order_id, amount)
    VALUES (p_order_id, p_amount);
    RETURN 'OK';
END;
$$;
""",

    "sqlserver": """\
CREATE OR ALTER PROCEDURE dbo.upsert_order
    @p_order_id INTEGER,
    @p_amount   DECIMAL(18,2)
AS
BEGIN
    INSERT INTO dbo.orders(order_id, amount)
    VALUES (@p_order_id, @p_amount);
END;
""",

    "synapse": """\
CREATE OR ALTER PROCEDURE dbo.upsert_order
    @p_order_id INTEGER,
    @p_amount   DECIMAL(18,2)
AS
BEGIN
    INSERT INTO dbo.orders(order_id, amount)
    VALUES (@p_order_id, @p_amount);
END;
""",

    "fabric_dw": """\
CREATE OR ALTER PROCEDURE dbo.upsert_order
    @p_order_id INTEGER,
    @p_amount   DECIMAL(18,2)
AS
BEGIN
    INSERT INTO dbo.orders(order_id, amount)
    VALUES (@p_order_id, @p_amount);
END;
""",

    "databricks": """\
CREATE OR REPLACE PROCEDURE analytics.upsert_order(
    IN p_order_id INTEGER,
    IN p_amount   DECIMAL(18,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO analytics.orders(order_id, amount)
    VALUES (p_order_id, p_amount);
END;
$$;
""",

    "oracle": """\
CREATE OR REPLACE PROCEDURE hr.upsert_order(
    p_order_id IN NUMBER,
    p_amount   IN NUMBER
)
AS
BEGIN
    INSERT INTO hr.orders(order_id, amount)
    VALUES (p_order_id, p_amount);
END upsert_order;
""",

    "bigquery": """\
CREATE OR REPLACE PROCEDURE `analytics.upsert_order`(
    IN p_order_id INT64,
    IN p_amount   NUMERIC
)
BEGIN
    INSERT INTO `analytics.orders`(order_id, amount)
    VALUES (p_order_id, p_amount);
END;
""",
}


# ---------------------------------------------------------------------------
# FUNCTION
# ---------------------------------------------------------------------------

_FUNCTION = {
    "redshift": """\
CREATE OR REPLACE FUNCTION analytics.apply_tax(amount FLOAT)
RETURNS FLOAT
STABLE
AS $$
    return amount * 1.1
$$ LANGUAGE plpythonu;
""",

    "snowflake": """\
CREATE OR REPLACE FUNCTION analytics.apply_tax(amount FLOAT)
RETURNS FLOAT
LANGUAGE SQL
AS
$$
    SELECT amount * 1.1
$$;
""",

    "sqlserver": """\
CREATE OR ALTER FUNCTION dbo.apply_tax(@amount DECIMAL(18,4))
RETURNS DECIMAL(18,4)
AS
BEGIN
    RETURN @amount * 1.1;
END;
""",

    "synapse": """\
CREATE OR ALTER FUNCTION dbo.apply_tax(@amount DECIMAL(18,4))
RETURNS DECIMAL(18,4)
AS
BEGIN
    RETURN @amount * 1.1;
END;
""",

    "fabric_dw": """\
CREATE OR ALTER FUNCTION dbo.apply_tax(@amount DECIMAL(18,4))
RETURNS DECIMAL(18,4)
AS
BEGIN
    RETURN @amount * 1.1;
END;
""",

    "databricks": """\
CREATE OR REPLACE FUNCTION analytics.apply_tax(amount DOUBLE)
RETURNS DOUBLE
RETURN amount * 1.1;
""",

    "oracle": """\
CREATE OR REPLACE FUNCTION hr.apply_tax(p_amount IN NUMBER)
RETURN NUMBER
AS
BEGIN
    RETURN p_amount * 1.1;
END apply_tax;
""",

    "bigquery": """\
CREATE OR REPLACE FUNCTION `analytics.apply_tax`(amount FLOAT64)
RETURNS FLOAT64
AS (
    amount * 1.1
);
""",
}


# ---------------------------------------------------------------------------
# Public registry
# ---------------------------------------------------------------------------

GOLDEN_SAMPLES: dict[str, dict[str, str]] = {
    dialect: {
        "table":     _TABLE[dialect],
        "view":      _VIEW[dialect],
        "mv":        _MV[dialect],
        "procedure": _PROCEDURE[dialect],
        "function":  _FUNCTION[dialect],
    }
    for dialect in (
        "redshift", "snowflake", "sqlserver", "synapse",
        "fabric_dw", "databricks", "oracle", "bigquery",
    )
}

ALL_DIALECTS = list(GOLDEN_SAMPLES.keys())
OBJECT_TYPES = ["table", "view", "mv", "procedure", "function"]
