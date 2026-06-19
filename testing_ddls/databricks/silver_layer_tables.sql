-- Databricks: Silver Layer (Cleaned & Conformed) Tables

CREATE OR REPLACE TABLE silver.customers (
    customer_id     BIGINT NOT NULL,
    email           STRING NOT NULL,
    first_name      STRING,
    last_name       STRING,
    phone           STRING,
    date_of_birth   DATE,
    gender          STRING,
    country_code    STRING,
    city            STRING,
    loyalty_tier    STRING DEFAULT 'BRONZE',
    is_active       BOOLEAN DEFAULT TRUE,
    source_system   STRING,
    registered_at   TIMESTAMP,
    updated_at      TIMESTAMP,
    dq_score        DECIMAL(5,2) DEFAULT 100.00,
    _ingest_ts      TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    _updated_ts     TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
TBLPROPERTIES (
    'delta.enableChangeDataFeed' = 'true',
    'delta.autoOptimize.optimizeWrite' = 'true',
    'quality.layer' = 'silver'
);

CREATE OR REPLACE TABLE silver.orders (
    order_id        BIGINT NOT NULL,
    customer_id     BIGINT NOT NULL,
    order_status    STRING NOT NULL,
    payment_method  STRING,
    payment_status  STRING,
    subtotal        DECIMAL(14,2),
    discount_amount DECIMAL(14,2) DEFAULT 0.00,
    shipping_amount DECIMAL(14,2) DEFAULT 0.00,
    tax_amount      DECIMAL(14,2) DEFAULT 0.00,
    total_amount    DECIMAL(14,2) NOT NULL,
    currency_code   STRING DEFAULT 'USD',
    ordered_at      TIMESTAMP NOT NULL,
    shipped_at      TIMESTAMP,
    delivered_at    TIMESTAMP,
    source_system   STRING,
    _ingest_ts      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
PARTITIONED BY (DATE(ordered_at))
TBLPROPERTIES (
    'delta.enableChangeDataFeed' = 'true',
    'quality.layer' = 'silver'
);

CREATE OR REPLACE TABLE silver.order_items (
    order_item_id   BIGINT NOT NULL,
    order_id        BIGINT NOT NULL,
    product_id      BIGINT NOT NULL,
    quantity        INTEGER NOT NULL,
    unit_price      DECIMAL(12,2) NOT NULL,
    discount_pct    DECIMAL(5,2) DEFAULT 0.00,
    line_total      DECIMAL(14,2) NOT NULL,
    ordered_at      TIMESTAMP,
    _ingest_ts      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
PARTITIONED BY (DATE(ordered_at))
TBLPROPERTIES ('quality.layer' = 'silver');

CREATE OR REPLACE TABLE silver.products (
    product_id      BIGINT NOT NULL,
    sku             STRING NOT NULL,
    product_name    STRING NOT NULL,
    brand           STRING,
    category_l1     STRING,
    category_l2     STRING,
    category_l3     STRING,
    unit_price      DECIMAL(12,2) NOT NULL,
    cost_price      DECIMAL(12,2),
    is_active       BOOLEAN DEFAULT TRUE,
    source_system   STRING,
    updated_at      TIMESTAMP,
    _ingest_ts      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
TBLPROPERTIES (
    'delta.enableChangeDataFeed' = 'true',
    'quality.layer' = 'silver'
);

CREATE OR REPLACE TABLE silver.events (
    event_id        STRING NOT NULL,
    event_name      STRING NOT NULL,
    event_category  STRING,
    user_id         BIGINT,
    session_id      STRING,
    page_url        STRING,
    properties      MAP<STRING, STRING>,
    occurred_at     TIMESTAMP NOT NULL,
    source          STRING,
    _ingest_ts      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
PARTITIONED BY (DATE(occurred_at))
TBLPROPERTIES ('quality.layer' = 'silver');

CREATE OR REPLACE TABLE silver.payments (
    payment_id      STRING NOT NULL,
    order_id        BIGINT NOT NULL,
    amount          DECIMAL(14,2) NOT NULL,
    currency        STRING NOT NULL DEFAULT 'USD',
    amount_usd      DECIMAL(14,2),
    payment_method  STRING,
    gateway         STRING,
    status          STRING DEFAULT 'COMPLETED',
    paid_at         TIMESTAMP,
    refunded_at     TIMESTAMP,
    _ingest_ts      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
TBLPROPERTIES (
    'delta.enableChangeDataFeed' = 'true',
    'quality.layer' = 'silver'
);
