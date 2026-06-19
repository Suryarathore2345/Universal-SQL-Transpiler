-- Snowflake Sample Tables DDL
-- Tests: Snowflake-specific data types (VARIANT, ARRAY, OBJECT), clustering keys,
--        column-level masking, AUTO_INCREMENT, TIMESTAMP_NTZ

CREATE OR REPLACE TABLE sales.orders (
    order_id        NUMBER(10,0)      NOT NULL AUTOINCREMENT,
    customer_id     NUMBER(10,0)      NOT NULL,
    order_date      DATE              NOT NULL,
    order_ts        TIMESTAMP_NTZ(6),
    ship_date       DATE,
    status          VARCHAR(20)       NOT NULL DEFAULT 'PENDING',
    total_amount    NUMBER(15,2),
    discount_pct    FLOAT,
    is_gift         BOOLEAN           DEFAULT FALSE,
    order_notes     TEXT,
    metadata        VARIANT,
    tags            ARRAY,
    PRIMARY KEY (order_id)
)
CLUSTER BY (order_date);

CREATE OR REPLACE TABLE sales.customers (
    customer_id   NUMBER(10,0)  NOT NULL,
    first_name    VARCHAR(50)   NOT NULL,
    last_name     VARCHAR(50)   NOT NULL,
    email         VARCHAR(100)  NOT NULL UNIQUE,
    phone         VARCHAR(20),
    address       OBJECT,
    preferences   VARIANT,
    signup_date   DATE,
    signup_ts     TIMESTAMP_LTZ,
    loyalty_tier  VARCHAR(10)   DEFAULT 'BRONZE',
    is_active     BOOLEAN       DEFAULT TRUE,
    region_code   CHAR(2),
    PRIMARY KEY (customer_id)
);

CREATE OR REPLACE TABLE sales.products (
    product_id    NUMBER(10,0)  NOT NULL,
    sku           VARCHAR(50)   NOT NULL UNIQUE,
    product_name  VARCHAR(200)  NOT NULL,
    description   TEXT,
    category      VARCHAR(100),
    sub_category  VARCHAR(100),
    unit_price    NUMBER(12,4)  NOT NULL,
    cost_price    NUMBER(12,4),
    stock_qty     INTEGER       DEFAULT 0,
    weight_kg     FLOAT,
    attributes    VARIANT,
    created_at    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at    TIMESTAMP_NTZ,
    is_active     BOOLEAN       DEFAULT TRUE,
    PRIMARY KEY (product_id)
);

CREATE OR REPLACE TABLE analytics.events (
    event_id      VARCHAR(36)   NOT NULL DEFAULT UUID_STRING(),
    session_id    VARCHAR(36),
    user_id       NUMBER(10,0),
    event_type    VARCHAR(50)   NOT NULL,
    event_ts      TIMESTAMP_NTZ(6) NOT NULL,
    page_url      VARCHAR(2048),
    referrer_url  VARCHAR(2048),
    device_type   VARCHAR(20),
    ip_address    VARCHAR(45),
    country_code  CHAR(2),
    properties    VARIANT,
    PRIMARY KEY (event_id)
)
CLUSTER BY (TO_DATE(event_ts));
