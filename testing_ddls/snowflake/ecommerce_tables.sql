-- Snowflake: E-Commerce Domain Tables

CREATE OR REPLACE TABLE ecommerce.customers (
    customer_id     BIGINT NOT NULL AUTOINCREMENT,
    email           VARCHAR(255) NOT NULL,
    first_name      VARCHAR(100),
    last_name       VARCHAR(100),
    phone           VARCHAR(30),
    date_of_birth   DATE,
    gender          VARCHAR(10),
    loyalty_tier    VARCHAR(20) DEFAULT 'BRONZE',
    total_orders    INTEGER DEFAULT 0,
    total_spent     DECIMAL(14,2) DEFAULT 0.00,
    is_active       BOOLEAN DEFAULT TRUE,
    registered_at   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (customer_id)
);

CREATE OR REPLACE TABLE ecommerce.customer_addresses (
    address_id      BIGINT NOT NULL AUTOINCREMENT,
    customer_id     BIGINT NOT NULL,
    address_type    VARCHAR(20) DEFAULT 'SHIPPING',
    address_line1   VARCHAR(255) NOT NULL,
    address_line2   VARCHAR(255),
    city            VARCHAR(100) NOT NULL,
    state           VARCHAR(100),
    postal_code     VARCHAR(20),
    country_code    CHAR(2) NOT NULL,
    is_default      BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (address_id),
    FOREIGN KEY (customer_id) REFERENCES ecommerce.customers(customer_id)
);

CREATE OR REPLACE TABLE ecommerce.categories (
    category_id     INTEGER NOT NULL AUTOINCREMENT,
    parent_id       INTEGER,
    category_name   VARCHAR(150) NOT NULL,
    slug            VARCHAR(150) NOT NULL UNIQUE,
    description     TEXT,
    image_url       VARCHAR(500),
    sort_order      INTEGER DEFAULT 0,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (category_id)
);

CREATE OR REPLACE TABLE ecommerce.products (
    product_id      BIGINT NOT NULL AUTOINCREMENT,
    category_id     INTEGER NOT NULL,
    sku             VARCHAR(100) NOT NULL UNIQUE,
    product_name    VARCHAR(255) NOT NULL,
    description     TEXT,
    brand           VARCHAR(100),
    unit_price      DECIMAL(12,2) NOT NULL,
    cost_price      DECIMAL(12,2),
    stock_qty       INTEGER DEFAULT 0,
    weight_kg       DECIMAL(8,3),
    is_digital      BOOLEAN DEFAULT FALSE,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (product_id),
    FOREIGN KEY (category_id) REFERENCES ecommerce.categories(category_id)
);

CREATE OR REPLACE TABLE ecommerce.orders (
    order_id        BIGINT NOT NULL AUTOINCREMENT,
    customer_id     BIGINT NOT NULL,
    address_id      BIGINT,
    order_status    VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    payment_method  VARCHAR(50),
    payment_status  VARCHAR(30) DEFAULT 'UNPAID',
    subtotal        DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(14,2) DEFAULT 0.00,
    shipping_amount DECIMAL(14,2) DEFAULT 0.00,
    tax_amount      DECIMAL(14,2) DEFAULT 0.00,
    total_amount    DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    currency_code   CHAR(3) DEFAULT 'USD',
    notes           TEXT,
    ordered_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    shipped_at      TIMESTAMP_NTZ,
    delivered_at    TIMESTAMP_NTZ,
    cancelled_at    TIMESTAMP_NTZ,
    PRIMARY KEY (order_id),
    FOREIGN KEY (customer_id) REFERENCES ecommerce.customers(customer_id)
);

CREATE OR REPLACE TABLE ecommerce.order_items (
    order_item_id   BIGINT NOT NULL AUTOINCREMENT,
    order_id        BIGINT NOT NULL,
    product_id      BIGINT NOT NULL,
    quantity        INTEGER NOT NULL,
    unit_price      DECIMAL(12,2) NOT NULL,
    discount_pct    DECIMAL(5,2) DEFAULT 0.00,
    line_total      DECIMAL(14,2) NOT NULL,
    PRIMARY KEY (order_item_id),
    FOREIGN KEY (order_id) REFERENCES ecommerce.orders(order_id),
    FOREIGN KEY (product_id) REFERENCES ecommerce.products(product_id)
);

CREATE OR REPLACE TABLE ecommerce.cart (
    cart_id         BIGINT NOT NULL AUTOINCREMENT,
    customer_id     BIGINT,
    session_id      VARCHAR(100),
    product_id      BIGINT NOT NULL,
    quantity        INTEGER NOT NULL DEFAULT 1,
    added_at        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (cart_id)
);

CREATE OR REPLACE TABLE ecommerce.promotions (
    promo_id        INTEGER NOT NULL AUTOINCREMENT,
    promo_code      VARCHAR(50) NOT NULL UNIQUE,
    promo_type      VARCHAR(30) NOT NULL,
    discount_value  DECIMAL(10,2) NOT NULL,
    min_order_value DECIMAL(10,2) DEFAULT 0.00,
    usage_limit     INTEGER,
    used_count      INTEGER DEFAULT 0,
    valid_from      DATE NOT NULL,
    valid_to        DATE NOT NULL,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (promo_id)
);

CREATE OR REPLACE TABLE ecommerce.product_reviews (
    review_id       BIGINT NOT NULL AUTOINCREMENT,
    product_id      BIGINT NOT NULL,
    customer_id     BIGINT NOT NULL,
    order_id        BIGINT,
    rating          SMALLINT NOT NULL,
    title           VARCHAR(255),
    body            TEXT,
    is_verified     BOOLEAN DEFAULT FALSE,
    helpful_count   INTEGER DEFAULT 0,
    status          VARCHAR(20) DEFAULT 'PENDING',
    reviewed_at     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (review_id)
);

CREATE OR REPLACE TABLE ecommerce.inventory_log (
    log_id          BIGINT NOT NULL AUTOINCREMENT,
    product_id      BIGINT NOT NULL,
    change_type     VARCHAR(30) NOT NULL,
    qty_before      INTEGER NOT NULL,
    qty_change      INTEGER NOT NULL,
    qty_after       INTEGER NOT NULL,
    reference_id    BIGINT,
    reference_type  VARCHAR(50),
    changed_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    changed_by      VARCHAR(100),
    PRIMARY KEY (log_id)
);
