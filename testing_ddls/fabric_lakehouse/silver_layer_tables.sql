-- Fabric Lakehouse (Spark SQL / Delta): Silver Layer Tables

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
    _ingest_ts      TIMESTAMP
)
USING DELTA
TBLPROPERTIES (
    'delta.enableChangeDataFeed' = 'true',
    'quality.layer' = 'silver'
);

CREATE OR REPLACE TABLE silver.orders (
    order_id        BIGINT NOT NULL,
    customer_id     BIGINT NOT NULL,
    order_status    STRING NOT NULL,
    payment_method  STRING,
    payment_status  STRING,
    subtotal        DECIMAL(14,2),
    discount_amount DECIMAL(14,2) DEFAULT 0,
    shipping_amount DECIMAL(14,2) DEFAULT 0,
    tax_amount      DECIMAL(14,2) DEFAULT 0,
    total_amount    DECIMAL(14,2) NOT NULL,
    currency_code   STRING DEFAULT 'USD',
    ordered_at      TIMESTAMP NOT NULL,
    shipped_at      TIMESTAMP,
    delivered_at    TIMESTAMP,
    source_system   STRING,
    _ingest_ts      TIMESTAMP
)
USING DELTA
PARTITIONED BY (DATE(ordered_at))
TBLPROPERTIES (
    'delta.enableChangeDataFeed' = 'true',
    'quality.layer' = 'silver'
);

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
    _ingest_ts      TIMESTAMP
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
    _ingest_ts      TIMESTAMP
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
    _ingest_ts      TIMESTAMP
)
USING DELTA
TBLPROPERTIES (
    'delta.enableChangeDataFeed' = 'true',
    'quality.layer' = 'silver'
);

CREATE OR REPLACE TABLE silver.inventory_snapshots (
    snapshot_id     BIGINT NOT NULL,
    snapshot_date   DATE NOT NULL,
    warehouse_id    INT,
    product_id      BIGINT NOT NULL,
    qty_on_hand     INT NOT NULL DEFAULT 0,
    qty_reserved    INT NOT NULL DEFAULT 0,
    qty_available   INT NOT NULL DEFAULT 0,
    unit_cost       DECIMAL(12,2),
    total_value     DECIMAL(14,2),
    _ingest_ts      TIMESTAMP
)
USING DELTA
PARTITIONED BY (snapshot_date)
TBLPROPERTIES ('quality.layer' = 'silver');
