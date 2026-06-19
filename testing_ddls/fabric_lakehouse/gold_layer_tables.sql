-- Fabric Lakehouse (Spark SQL / Delta): Gold Layer Tables

CREATE OR REPLACE TABLE gold.customer_360 (
    customer_id         BIGINT NOT NULL,
    email               STRING,
    full_name           STRING,
    country_code        STRING,
    city                STRING,
    loyalty_tier        STRING,
    customer_segment    STRING,
    registered_date     DATE,
    total_orders        INT DEFAULT 0,
    total_items         INT DEFAULT 0,
    total_spent         DECIMAL(14,2) DEFAULT 0,
    avg_order_value     DECIMAL(10,2),
    first_order_date    DATE,
    last_order_date     DATE,
    days_since_last_order INT,
    favorite_category   STRING,
    open_tickets        INT DEFAULT 0,
    rfm_score           DECIMAL(5,2),
    churn_risk          DECIMAL(5,4),
    clv_predicted       DECIMAL(12,2),
    updated_at          TIMESTAMP
)
USING DELTA
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'quality.layer' = 'gold'
);

CREATE OR REPLACE TABLE gold.daily_revenue (
    report_date         DATE NOT NULL,
    channel             STRING,
    product_category    STRING,
    country_code        STRING,
    total_orders        INT DEFAULT 0,
    unique_customers    INT DEFAULT 0,
    gross_revenue       DECIMAL(16,2) DEFAULT 0,
    discounts           DECIMAL(14,2) DEFAULT 0,
    net_revenue         DECIMAL(16,2) DEFAULT 0,
    cogs                DECIMAL(16,2) DEFAULT 0,
    gross_profit        DECIMAL(16,2) DEFAULT 0,
    gross_margin_pct    DECIMAL(6,4),
    avg_order_value     DECIMAL(10,2),
    units_sold          INT DEFAULT 0,
    _updated_at         TIMESTAMP
)
USING DELTA
PARTITIONED BY (report_date)
TBLPROPERTIES ('quality.layer' = 'gold');

CREATE OR REPLACE TABLE gold.product_performance_monthly (
    product_id          BIGINT NOT NULL,
    sku                 STRING,
    product_name        STRING,
    brand               STRING,
    category_l1         STRING,
    report_month        STRING NOT NULL,
    units_sold          INT DEFAULT 0,
    revenue             DECIMAL(14,2) DEFAULT 0,
    cogs                DECIMAL(14,2) DEFAULT 0,
    gross_profit        DECIMAL(14,2) DEFAULT 0,
    gross_margin_pct    DECIMAL(6,4),
    avg_selling_price   DECIMAL(10,2),
    orders_count        INT DEFAULT 0,
    avg_rating          DECIMAL(3,2),
    _updated_at         TIMESTAMP
)
USING DELTA
PARTITIONED BY (report_month)
TBLPROPERTIES ('quality.layer' = 'gold');

CREATE OR REPLACE TABLE gold.marketing_performance (
    report_date         DATE NOT NULL,
    channel             STRING NOT NULL,
    platform            STRING,
    campaign_name       STRING,
    spend               DECIMAL(12,2) DEFAULT 0,
    impressions         BIGINT DEFAULT 0,
    clicks              BIGINT DEFAULT 0,
    conversions         INT DEFAULT 0,
    revenue_attributed  DECIMAL(12,2) DEFAULT 0,
    roas                DECIMAL(8,4),
    cac                 DECIMAL(10,2),
    _updated_at         TIMESTAMP
)
USING DELTA
PARTITIONED BY (report_date)
TBLPROPERTIES ('quality.layer' = 'gold');

CREATE OR REPLACE TABLE gold.hr_analytics (
    snapshot_date       DATE NOT NULL,
    department          STRING NOT NULL,
    location            STRING,
    headcount           INT NOT NULL DEFAULT 0,
    new_hires_mtd       INT DEFAULT 0,
    terminations_mtd    INT DEFAULT 0,
    avg_tenure_months   DECIMAL(8,2),
    avg_salary          DECIMAL(12,2),
    total_salary_cost   DECIMAL(16,2),
    open_positions      INT DEFAULT 0,
    attrition_rate_ytd  DECIMAL(6,4),
    _updated_at         TIMESTAMP
)
USING DELTA
PARTITIONED BY (snapshot_date)
TBLPROPERTIES ('quality.layer' = 'gold');
