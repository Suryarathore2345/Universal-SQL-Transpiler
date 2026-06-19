-- Snowflake: Data Warehouse Fact Tables

CREATE OR REPLACE TABLE dwh.fact_orders (
    order_key           BIGINT NOT NULL AUTOINCREMENT,
    order_id            BIGINT NOT NULL,
    order_date_key      INTEGER NOT NULL,
    shipped_date_key    INTEGER,
    delivered_date_key  INTEGER,
    customer_key        BIGINT NOT NULL,
    geo_key             INTEGER,
    channel_key         INTEGER,
    currency_key        SMALLINT,
    order_status        VARCHAR(30),
    payment_method      VARCHAR(50),
    line_item_count     INTEGER,
    units_ordered       INTEGER,
    gross_amount        DECIMAL(14,2),
    discount_amount     DECIMAL(14,2),
    shipping_amount     DECIMAL(14,2),
    tax_amount          DECIMAL(14,2),
    net_amount          DECIMAL(14,2),
    fx_rate             DECIMAL(12,6) DEFAULT 1.000000,
    net_amount_usd      DECIMAL(14,2),
    inserted_at         TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (order_key)
);

CREATE OR REPLACE TABLE dwh.fact_order_lines (
    line_key            BIGINT NOT NULL AUTOINCREMENT,
    order_item_id       BIGINT NOT NULL,
    order_key           BIGINT NOT NULL,
    order_date_key      INTEGER NOT NULL,
    product_key         BIGINT NOT NULL,
    customer_key        BIGINT NOT NULL,
    channel_key         INTEGER,
    quantity            INTEGER NOT NULL,
    unit_price          DECIMAL(12,2) NOT NULL,
    cost_price          DECIMAL(12,2),
    discount_pct        DECIMAL(5,2),
    line_revenue        DECIMAL(14,2),
    line_cost           DECIMAL(14,2),
    gross_margin        DECIMAL(14,2),
    inserted_at         TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (line_key)
);

CREATE OR REPLACE TABLE dwh.fact_web_sessions (
    session_key         BIGINT NOT NULL AUTOINCREMENT,
    session_id          VARCHAR(100) NOT NULL,
    session_date_key    INTEGER NOT NULL,
    session_time_key    INTEGER,
    customer_key        BIGINT,
    geo_key             INTEGER,
    channel_key         INTEGER,
    device_type         VARCHAR(30),
    browser             VARCHAR(50),
    os                  VARCHAR(50),
    landing_page        VARCHAR(500),
    exit_page           VARCHAR(500),
    pages_viewed        INTEGER DEFAULT 0,
    session_duration_sec INTEGER DEFAULT 0,
    bounced             BOOLEAN DEFAULT FALSE,
    converted           BOOLEAN DEFAULT FALSE,
    conversion_value    DECIMAL(12,2),
    inserted_at         TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (session_key)
);

CREATE OR REPLACE TABLE dwh.fact_inventory_snapshot (
    snapshot_key        BIGINT NOT NULL AUTOINCREMENT,
    snapshot_date_key   INTEGER NOT NULL,
    product_key         BIGINT NOT NULL,
    warehouse_id        INTEGER,
    qty_on_hand         INTEGER NOT NULL DEFAULT 0,
    qty_reserved        INTEGER NOT NULL DEFAULT 0,
    qty_available       INTEGER NOT NULL DEFAULT 0,
    qty_in_transit      INTEGER DEFAULT 0,
    unit_cost           DECIMAL(12,2),
    total_value         DECIMAL(16,2),
    days_of_supply      DECIMAL(8,2),
    inserted_at         TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (snapshot_key)
);

CREATE OR REPLACE TABLE dwh.fact_marketing_spend (
    spend_key           BIGINT NOT NULL AUTOINCREMENT,
    spend_date_key      INTEGER NOT NULL,
    channel_key         INTEGER NOT NULL,
    campaign_id         BIGINT,
    campaign_name       VARCHAR(255),
    platform            VARCHAR(50),
    impressions         BIGINT DEFAULT 0,
    clicks              BIGINT DEFAULT 0,
    conversions         INTEGER DEFAULT 0,
    spend_amount        DECIMAL(14,2) NOT NULL,
    revenue_attributed  DECIMAL(14,2),
    roas                DECIMAL(8,4),
    inserted_at         TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (spend_key)
);
