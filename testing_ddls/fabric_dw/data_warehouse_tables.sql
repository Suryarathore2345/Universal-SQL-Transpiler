-- Microsoft Fabric Data Warehouse: Star Schema Tables

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
    holiday_name    NVARCHAR(100)
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
);

CREATE TABLE dwh.dim_geography (
    geo_key         INT NOT NULL,
    country_code    CHAR(2) NOT NULL,
    country_name    NVARCHAR(100) NOT NULL,
    region          NVARCHAR(100),
    state_province  NVARCHAR(100),
    city            NVARCHAR(100),
    timezone        NVARCHAR(60)
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
);

CREATE TABLE dwh.fact_marketing_performance (
    perf_key            BIGINT NOT NULL,
    report_date_key     INT NOT NULL,
    campaign_id         BIGINT,
    channel             NVARCHAR(50) NOT NULL,
    platform            NVARCHAR(50),
    geo_key             INT,
    impressions         BIGINT NOT NULL DEFAULT 0,
    clicks              BIGINT NOT NULL DEFAULT 0,
    conversions         INT NOT NULL DEFAULT 0,
    spend_usd           DECIMAL(14,2) NOT NULL DEFAULT 0,
    revenue_attributed  DECIMAL(14,2),
    roas                DECIMAL(8,4),
    inserted_at         DATETIME2 NOT NULL DEFAULT GETDATE()
);

CREATE TABLE dwh.fact_hr_headcount (
    headcount_key       BIGINT NOT NULL,
    snapshot_date_key   INT NOT NULL,
    department_name     NVARCHAR(100) NOT NULL,
    location            NVARCHAR(100),
    employment_type     NVARCHAR(30),
    headcount           INT NOT NULL DEFAULT 0,
    new_hires           INT NOT NULL DEFAULT 0,
    terminations        INT NOT NULL DEFAULT 0,
    total_salary_usd    DECIMAL(16,2),
    avg_salary_usd      DECIMAL(14,2),
    inserted_at         DATETIME2 NOT NULL DEFAULT GETDATE()
);
