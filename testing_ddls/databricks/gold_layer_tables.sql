-- Databricks: Gold Layer (Business Aggregates) Tables

CREATE OR REPLACE TABLE gold.customer_360 (
    customer_id         BIGINT NOT NULL,
    email               STRING,
    full_name           STRING,
    country_code        STRING,
    city                STRING,
    loyalty_tier        STRING,
    customer_segment    STRING,
    age_band            STRING,
    registered_date     DATE,
    days_since_signup   INTEGER,
    total_orders        INTEGER DEFAULT 0,
    total_items         INTEGER DEFAULT 0,
    total_spent         DECIMAL(14,2) DEFAULT 0.00,
    avg_order_value     DECIMAL(10,2),
    first_order_date    DATE,
    last_order_date     DATE,
    days_since_last_order INTEGER,
    favorite_category   STRING,
    favorite_brand      STRING,
    open_tickets        INTEGER DEFAULT 0,
    lifetime_sessions   INTEGER DEFAULT 0,
    rfm_score           DECIMAL(5,2),
    churn_risk_score    DECIMAL(5,4),
    clv_predicted       DECIMAL(12,2),
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
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
    total_orders        INTEGER DEFAULT 0,
    unique_customers    INTEGER DEFAULT 0,
    gross_revenue       DECIMAL(16,2) DEFAULT 0.00,
    discounts           DECIMAL(16,2) DEFAULT 0.00,
    net_revenue         DECIMAL(16,2) DEFAULT 0.00,
    cost_of_goods       DECIMAL(16,2) DEFAULT 0.00,
    gross_profit        DECIMAL(16,2) DEFAULT 0.00,
    gross_margin_pct    DECIMAL(6,4),
    avg_order_value     DECIMAL(10,2),
    units_sold          INTEGER DEFAULT 0,
    _updated_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
PARTITIONED BY (report_date)
TBLPROPERTIES ('quality.layer' = 'gold');

CREATE OR REPLACE TABLE gold.product_performance (
    product_id          BIGINT NOT NULL,
    sku                 STRING,
    product_name        STRING,
    brand               STRING,
    category_l1         STRING,
    category_l2         STRING,
    report_month        STRING NOT NULL,
    units_sold          INTEGER DEFAULT 0,
    revenue             DECIMAL(14,2) DEFAULT 0.00,
    cost_of_goods       DECIMAL(14,2) DEFAULT 0.00,
    gross_profit        DECIMAL(14,2) DEFAULT 0.00,
    gross_margin_pct    DECIMAL(6,4),
    avg_selling_price   DECIMAL(10,2),
    orders_count        INTEGER DEFAULT 0,
    return_rate_pct     DECIMAL(6,4),
    avg_rating          DECIMAL(3,2),
    review_count        INTEGER DEFAULT 0,
    _updated_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
PARTITIONED BY (report_month)
TBLPROPERTIES ('quality.layer' = 'gold');

CREATE OR REPLACE TABLE gold.marketing_roi (
    report_date         DATE NOT NULL,
    channel             STRING NOT NULL,
    platform            STRING,
    campaign_name       STRING,
    spend               DECIMAL(12,2) DEFAULT 0.00,
    impressions         BIGINT DEFAULT 0,
    clicks              BIGINT DEFAULT 0,
    conversions         INTEGER DEFAULT 0,
    revenue_attributed  DECIMAL(12,2) DEFAULT 0.00,
    roas                DECIMAL(8,4),
    cac                 DECIMAL(10,2),
    cpm                 DECIMAL(8,4),
    cpc                 DECIMAL(8,4),
    cvr                 DECIMAL(8,6),
    _updated_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
PARTITIONED BY (report_date)
TBLPROPERTIES ('quality.layer' = 'gold');

CREATE OR REPLACE TABLE gold.inventory_health (
    snapshot_date       DATE NOT NULL,
    warehouse_id        INTEGER,
    product_id          BIGINT NOT NULL,
    sku                 STRING,
    category            STRING,
    qty_on_hand         INTEGER DEFAULT 0,
    qty_reserved        INTEGER DEFAULT 0,
    qty_available       INTEGER DEFAULT 0,
    reorder_point       INTEGER,
    days_of_supply      DECIMAL(8,2),
    avg_daily_sales     DECIMAL(10,4),
    total_value         DECIMAL(14,2),
    stock_status        STRING,
    _updated_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
PARTITIONED BY (snapshot_date)
TBLPROPERTIES ('quality.layer' = 'gold');
