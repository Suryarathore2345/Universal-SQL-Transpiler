-- BigQuery: Data Warehouse Dimension Tables

CREATE OR REPLACE TABLE `analytics.dwh.dim_date` (
    date_key        INT64 NOT NULL,
    full_date       DATE NOT NULL,
    day_of_week     INT64 NOT NULL,
    day_name        STRING NOT NULL,
    day_of_month    INT64 NOT NULL,
    day_of_year     INT64 NOT NULL,
    week_of_year    INT64 NOT NULL,
    month_num       INT64 NOT NULL,
    month_name      STRING NOT NULL,
    quarter_num     INT64 NOT NULL,
    quarter_name    STRING NOT NULL,
    year_num        INT64 NOT NULL,
    fiscal_quarter  INT64 NOT NULL,
    fiscal_year     INT64 NOT NULL,
    is_weekend      BOOL NOT NULL,
    is_holiday      BOOL DEFAULT FALSE,
    holiday_name    STRING
);

CREATE OR REPLACE TABLE `analytics.dwh.dim_customer` (
    customer_key    INT64 NOT NULL,
    customer_id     INT64 NOT NULL,
    email           STRING,
    full_name       STRING,
    city            STRING,
    country_code    STRING,
    loyalty_tier    STRING,
    customer_segment STRING,
    age_band        STRING,
    effective_from  DATE NOT NULL,
    effective_to    DATE,
    is_current      BOOL DEFAULT TRUE
);

CREATE OR REPLACE TABLE `analytics.dwh.dim_product` (
    product_key     INT64 NOT NULL,
    product_id      INT64 NOT NULL,
    sku             STRING,
    product_name    STRING,
    brand           STRING,
    category_l1     STRING,
    category_l2     STRING,
    unit_price      NUMERIC,
    effective_from  DATE NOT NULL,
    effective_to    DATE,
    is_current      BOOL DEFAULT TRUE
);

CREATE OR REPLACE TABLE `analytics.dwh.dim_geography` (
    geo_key         INT64 NOT NULL,
    country_code    STRING NOT NULL,
    country_name    STRING NOT NULL,
    region          STRING,
    sub_region      STRING,
    state_province  STRING,
    city            STRING,
    timezone        STRING,
    latitude        FLOAT64,
    longitude       FLOAT64
);

CREATE OR REPLACE TABLE `analytics.dwh.fact_orders` (
    order_key           INT64 NOT NULL,
    order_id            INT64 NOT NULL,
    order_date_key      INT64 NOT NULL,
    customer_key        INT64 NOT NULL,
    product_key         INT64 NOT NULL,
    geo_key             INT64,
    channel_name        STRING,
    order_status        STRING,
    quantity            INT64,
    unit_price          NUMERIC,
    line_revenue        NUMERIC,
    discount_amount     NUMERIC,
    net_revenue         NUMERIC,
    order_date          DATE NOT NULL
)
PARTITION BY order_date
CLUSTER BY customer_key, product_key;

CREATE OR REPLACE TABLE `analytics.dwh.fact_marketing_performance` (
    perf_key            INT64 NOT NULL,
    report_date         DATE NOT NULL,
    channel             STRING NOT NULL,
    campaign_name       STRING,
    platform            STRING,
    geo_key             INT64,
    impressions         INT64 DEFAULT 0,
    clicks              INT64 DEFAULT 0,
    conversions         INT64 DEFAULT 0,
    spend_usd           NUMERIC DEFAULT 0,
    revenue_attributed  NUMERIC DEFAULT 0
)
PARTITION BY report_date
CLUSTER BY channel, platform;
