-- BigQuery: E-Commerce Domain Tables (partitioned, clustered)

CREATE OR REPLACE TABLE `analytics.ecommerce.customers` (
    customer_id     INT64 NOT NULL,
    email           STRING NOT NULL,
    first_name      STRING,
    last_name       STRING,
    phone           STRING,
    date_of_birth   DATE,
    gender          STRING,
    loyalty_tier    STRING,
    country_code    STRING,
    city            STRING,
    is_active       BOOL DEFAULT TRUE,
    registered_at   TIMESTAMP,
    updated_at      TIMESTAMP
)
OPTIONS (
    description = 'Customer master record',
    labels = [('domain', 'ecommerce'), ('tier', 'gold')]
);

CREATE OR REPLACE TABLE `analytics.ecommerce.products` (
    product_id      INT64 NOT NULL,
    sku             STRING NOT NULL,
    product_name    STRING NOT NULL,
    description     STRING,
    brand           STRING,
    category_path   ARRAY<STRING>,
    unit_price      NUMERIC NOT NULL,
    cost_price      NUMERIC,
    weight_kg       FLOAT64,
    attributes      STRUCT<
        color       STRING,
        size        STRING,
        material    STRING,
        is_digital  BOOL
    >,
    is_active       BOOL DEFAULT TRUE,
    created_at      TIMESTAMP,
    updated_at      TIMESTAMP
)
OPTIONS (description = 'Product catalogue');

CREATE OR REPLACE TABLE `analytics.ecommerce.orders` (
    order_id        INT64 NOT NULL,
    customer_id     INT64 NOT NULL,
    order_status    STRING NOT NULL,
    payment_method  STRING,
    payment_status  STRING,
    shipping_address    STRUCT<
        line1       STRING,
        line2       STRING,
        city        STRING,
        state       STRING,
        postal_code STRING,
        country     STRING
    >,
    subtotal        NUMERIC,
    discount_amount NUMERIC,
    shipping_amount NUMERIC,
    tax_amount      NUMERIC,
    total_amount    NUMERIC NOT NULL,
    currency_code   STRING DEFAULT 'USD',
    ordered_at      TIMESTAMP NOT NULL,
    shipped_at      TIMESTAMP,
    delivered_at    TIMESTAMP,
    cancelled_at    TIMESTAMP
)
PARTITION BY DATE(ordered_at)
CLUSTER BY customer_id, order_status
OPTIONS (
    partition_expiration_days = 1095,
    description = 'Order transactions partitioned by order date'
);

CREATE OR REPLACE TABLE `analytics.ecommerce.order_items` (
    order_item_id   INT64 NOT NULL,
    order_id        INT64 NOT NULL,
    product_id      INT64 NOT NULL,
    quantity        INT64 NOT NULL,
    unit_price      NUMERIC NOT NULL,
    discount_pct    NUMERIC,
    line_total      NUMERIC NOT NULL,
    ordered_at      DATE NOT NULL
)
PARTITION BY ordered_at
CLUSTER BY order_id, product_id;

CREATE OR REPLACE TABLE `analytics.ecommerce.product_reviews` (
    review_id       INT64 NOT NULL,
    product_id      INT64 NOT NULL,
    customer_id     INT64 NOT NULL,
    order_id        INT64,
    rating          INT64 NOT NULL,
    title           STRING,
    body            STRING,
    sentiment_score FLOAT64,
    tags            ARRAY<STRING>,
    is_verified     BOOL DEFAULT FALSE,
    status          STRING DEFAULT 'PENDING',
    reviewed_at     TIMESTAMP
)
PARTITION BY DATE(reviewed_at)
CLUSTER BY product_id;
