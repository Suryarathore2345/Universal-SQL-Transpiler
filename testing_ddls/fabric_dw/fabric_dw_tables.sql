-- Microsoft Fabric Data Warehouse DDL (T-SQL)
-- Tests: Fabric DW table syntax, no IDENTITY support (uses sequences),
--        DISTRIBUTION hints, data types, DEFAULT constraints

CREATE TABLE [dbo].[fact_sales] (
    sale_id          BIGINT         NOT NULL,
    order_date_key   INT            NOT NULL,
    customer_key     INT            NOT NULL,
    product_key      INT            NOT NULL,
    territory_key    INT            NOT NULL,
    order_quantity   SMALLINT       NOT NULL,
    unit_price       DECIMAL(15,4)  NOT NULL,
    unit_cost        DECIMAL(15,4)  NOT NULL,
    discount_amount  DECIMAL(15,4)  DEFAULT 0,
    sales_amount     DECIMAL(15,4)  NOT NULL,
    tax_amount       DECIMAL(15,4)  DEFAULT 0,
    freight          DECIMAL(15,4)  DEFAULT 0,
    order_ts         DATETIME2(6),
    ship_ts          DATETIME2(6),
    status           NVARCHAR(20)   DEFAULT 'PENDING'
);

CREATE TABLE [dbo].[dim_customer] (
    customer_key     INT            NOT NULL,
    customer_id      NVARCHAR(20)   NOT NULL,
    first_name       NVARCHAR(50),
    last_name        NVARCHAR(50),
    email            NVARCHAR(100),
    city             NVARCHAR(60),
    state_province   NVARCHAR(50),
    country          NVARCHAR(50),
    postal_code      NVARCHAR(20),
    loyalty_tier     NVARCHAR(20)   DEFAULT 'BRONZE',
    is_current       BIT            DEFAULT 1,
    start_date       DATE,
    end_date         DATE,
    created_at       DATETIME2(7)   DEFAULT GETDATE()
);

CREATE TABLE [dbo].[dim_product] (
    product_key      INT            NOT NULL,
    sku              NVARCHAR(50)   NOT NULL,
    product_name     NVARCHAR(200)  NOT NULL,
    category         NVARCHAR(100),
    sub_category     NVARCHAR(100),
    brand            NVARCHAR(100),
    unit_price       DECIMAL(12,4),
    cost_price       DECIMAL(12,4),
    is_active        BIT            DEFAULT 1,
    launch_date      DATE,
    discontinue_date DATE
);

CREATE TABLE [dbo].[dim_date] (
    date_key         INT      NOT NULL,
    full_date        DATE     NOT NULL,
    day_of_week      TINYINT  NOT NULL,
    day_name         NVARCHAR(10) NOT NULL,
    day_of_month     TINYINT  NOT NULL,
    day_of_year      SMALLINT NOT NULL,
    week_of_year     TINYINT  NOT NULL,
    month_name       NVARCHAR(10) NOT NULL,
    month_number     TINYINT  NOT NULL,
    quarter          TINYINT  NOT NULL,
    calendar_year    SMALLINT NOT NULL,
    fiscal_year      SMALLINT NOT NULL,
    fiscal_quarter   TINYINT  NOT NULL,
    is_weekend       BIT      NOT NULL,
    is_holiday       BIT      NOT NULL DEFAULT 0
);
