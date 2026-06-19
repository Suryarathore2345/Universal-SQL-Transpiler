-- Azure Synapse Analytics: Data Warehouse Star Schema Tables

CREATE TABLE dwh.dim_date (
    date_key        INT NOT NULL,
    full_date       DATE NOT NULL,
    day_of_week     TINYINT NOT NULL,
    day_name        NVARCHAR(10) NOT NULL,
    day_of_month    TINYINT NOT NULL,
    day_of_year     SMALLINT NOT NULL,
    week_of_year    TINYINT NOT NULL,
    month_num       TINYINT NOT NULL,
    month_name      NVARCHAR(10) NOT NULL,
    quarter_num     TINYINT NOT NULL,
    year_num        SMALLINT NOT NULL,
    fiscal_quarter  TINYINT NOT NULL,
    fiscal_year     SMALLINT NOT NULL,
    is_weekend      BIT NOT NULL DEFAULT 0,
    is_holiday      BIT NOT NULL DEFAULT 0,
    holiday_name    NVARCHAR(100)
)
WITH (
    DISTRIBUTION = REPLICATE,
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE dwh.dim_customer (
    customer_key    BIGINT NOT NULL,
    customer_id     BIGINT NOT NULL,
    email           NVARCHAR(255),
    full_name       NVARCHAR(200),
    country_code    CHAR(2),
    city            NVARCHAR(100),
    loyalty_tier    NVARCHAR(20),
    customer_segment NVARCHAR(50),
    age_band        NVARCHAR(20),
    effective_from  DATE NOT NULL,
    effective_to    DATE,
    is_current      BIT NOT NULL DEFAULT 1
)
WITH (
    DISTRIBUTION = REPLICATE,
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE dwh.dim_product (
    product_key     BIGINT NOT NULL,
    product_id      BIGINT NOT NULL,
    sku             NVARCHAR(100),
    product_name    NVARCHAR(255),
    brand           NVARCHAR(100),
    category_l1     NVARCHAR(150),
    category_l2     NVARCHAR(150),
    unit_price      DECIMAL(12,2),
    effective_from  DATE NOT NULL,
    effective_to    DATE,
    is_current      BIT NOT NULL DEFAULT 1
)
WITH (
    DISTRIBUTION = REPLICATE,
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE dwh.dim_geography (
    geo_key         INT NOT NULL,
    country_code    CHAR(2) NOT NULL,
    country_name    NVARCHAR(100) NOT NULL,
    region          NVARCHAR(100),
    state_province  NVARCHAR(100),
    city            NVARCHAR(100),
    timezone        NVARCHAR(60)
)
WITH (
    DISTRIBUTION = REPLICATE,
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE dwh.fact_orders (
    order_key           BIGINT NOT NULL,
    order_id            BIGINT NOT NULL,
    order_date_key      INT NOT NULL,
    customer_key        BIGINT NOT NULL,
    product_key         BIGINT NOT NULL,
    geo_key             INT,
    order_status        NVARCHAR(30),
    quantity            INT,
    unit_price          DECIMAL(12,2),
    line_revenue        DECIMAL(14,2),
    discount_amount     DECIMAL(14,2),
    net_revenue         DECIMAL(14,2),
    cost_of_goods       DECIMAL(14,2),
    gross_profit        DECIMAL(14,2),
    inserted_at         DATETIME2 NOT NULL DEFAULT GETDATE()
)
WITH (
    DISTRIBUTION = HASH(customer_key),
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE dwh.fact_web_sessions (
    session_key         BIGINT NOT NULL,
    session_id          NVARCHAR(100) NOT NULL,
    session_date_key    INT NOT NULL,
    customer_key        BIGINT,
    geo_key             INT,
    channel             NVARCHAR(50),
    device_type         NVARCHAR(30),
    browser             NVARCHAR(50),
    pages_viewed        INT DEFAULT 0,
    session_duration_sec INT DEFAULT 0,
    bounced             BIT DEFAULT 0,
    converted           BIT DEFAULT 0,
    conversion_value    DECIMAL(12,2),
    inserted_at         DATETIME2 NOT NULL DEFAULT GETDATE()
)
WITH (
    DISTRIBUTION = HASH(customer_key),
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE dwh.fact_inventory_snapshot (
    snapshot_key        BIGINT NOT NULL,
    snapshot_date_key   INT NOT NULL,
    product_key         BIGINT NOT NULL,
    warehouse_id        INT,
    qty_on_hand         INT NOT NULL DEFAULT 0,
    qty_reserved        INT NOT NULL DEFAULT 0,
    qty_available       INT NOT NULL DEFAULT 0,
    unit_cost           DECIMAL(12,2),
    total_value         DECIMAL(16,2),
    days_of_supply      DECIMAL(8,2),
    inserted_at         DATETIME2 NOT NULL DEFAULT GETDATE()
)
WITH (
    DISTRIBUTION = HASH(product_key),
    CLUSTERED COLUMNSTORE INDEX
);
