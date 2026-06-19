-- SQL Server: Data Warehouse Tables (Star Schema)

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
    quarter_name    NVARCHAR(6) NOT NULL,
    year_num        SMALLINT NOT NULL,
    fiscal_quarter  TINYINT NOT NULL,
    fiscal_year     SMALLINT NOT NULL,
    is_weekend      BIT NOT NULL DEFAULT 0,
    is_holiday      BIT NOT NULL DEFAULT 0,
    holiday_name    NVARCHAR(100),
    CONSTRAINT PK_dim_date PRIMARY KEY (date_key)
);

CREATE TABLE dwh.dim_customer (
    customer_key    BIGINT NOT NULL IDENTITY(1,1),
    customer_id     BIGINT NOT NULL,
    email           NVARCHAR(255),
    full_name       NVARCHAR(200),
    city            NVARCHAR(100),
    state           NVARCHAR(100),
    country_code    CHAR(2),
    loyalty_tier    NVARCHAR(20),
    customer_segment NVARCHAR(50),
    age_band        NVARCHAR(20),
    effective_from  DATE NOT NULL,
    effective_to    DATE,
    is_current      BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_dim_customer PRIMARY KEY (customer_key)
);

CREATE TABLE dwh.dim_product (
    product_key     BIGINT NOT NULL IDENTITY(1,1),
    product_id      BIGINT NOT NULL,
    sku             NVARCHAR(100),
    product_name    NVARCHAR(255),
    brand           NVARCHAR(100),
    category_l1     NVARCHAR(150),
    category_l2     NVARCHAR(150),
    unit_price      DECIMAL(12,2),
    effective_from  DATE NOT NULL,
    effective_to    DATE,
    is_current      BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_dim_product PRIMARY KEY (product_key)
);

CREATE TABLE dwh.fact_orders (
    order_key           BIGINT NOT NULL IDENTITY(1,1),
    order_id            BIGINT NOT NULL,
    order_date_key      INT NOT NULL,
    shipped_date_key    INT,
    customer_key        BIGINT NOT NULL,
    product_key         BIGINT NOT NULL,
    order_status        NVARCHAR(30),
    quantity            INT,
    unit_price          DECIMAL(12,2),
    line_revenue        DECIMAL(14,2),
    discount_amount     DECIMAL(14,2),
    net_revenue         DECIMAL(14,2),
    cost_of_goods       DECIMAL(14,2),
    gross_profit        DECIMAL(14,2),
    inserted_at         DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_fact_orders PRIMARY KEY (order_key),
    CONSTRAINT FK_fact_orders_date FOREIGN KEY (order_date_key) REFERENCES dwh.dim_date(date_key),
    CONSTRAINT FK_fact_orders_customer FOREIGN KEY (customer_key) REFERENCES dwh.dim_customer(customer_key),
    CONSTRAINT FK_fact_orders_product FOREIGN KEY (product_key) REFERENCES dwh.dim_product(product_key)
);

CREATE TABLE dwh.fact_marketing_spend (
    spend_key           BIGINT NOT NULL IDENTITY(1,1),
    spend_date_key      INT NOT NULL,
    channel             NVARCHAR(50) NOT NULL,
    platform            NVARCHAR(50),
    campaign_name       NVARCHAR(255),
    impressions         BIGINT NOT NULL DEFAULT 0,
    clicks              BIGINT NOT NULL DEFAULT 0,
    conversions         INT NOT NULL DEFAULT 0,
    spend_amount        DECIMAL(14,2) NOT NULL,
    revenue_attributed  DECIMAL(14,2),
    roas                DECIMAL(8,4),
    inserted_at         DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_fact_marketing PRIMARY KEY (spend_key)
);

CREATE TABLE dwh.fact_inventory_snapshot (
    snapshot_key        BIGINT NOT NULL IDENTITY(1,1),
    snapshot_date_key   INT NOT NULL,
    product_key         BIGINT NOT NULL,
    warehouse_id        INT,
    qty_on_hand         INT NOT NULL DEFAULT 0,
    qty_reserved        INT NOT NULL DEFAULT 0,
    qty_available       INT NOT NULL DEFAULT 0,
    unit_cost           DECIMAL(12,2),
    total_value         DECIMAL(16,2),
    days_of_supply      DECIMAL(8,2),
    inserted_at         DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_fact_inventory PRIMARY KEY (snapshot_key)
);
