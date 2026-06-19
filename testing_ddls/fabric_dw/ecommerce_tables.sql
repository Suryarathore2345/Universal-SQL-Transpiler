-- Microsoft Fabric Data Warehouse: E-Commerce Tables

CREATE TABLE ecommerce.customers (
    customer_id     BIGINT NOT NULL,
    email           NVARCHAR(255) NOT NULL,
    first_name      NVARCHAR(100),
    last_name       NVARCHAR(100),
    phone           NVARCHAR(30),
    date_of_birth   DATE,
    gender          NVARCHAR(10),
    loyalty_tier    NVARCHAR(20) NOT NULL DEFAULT 'BRONZE',
    country_code    CHAR(2),
    city            NVARCHAR(100),
    is_active       BIT NOT NULL DEFAULT 1,
    registered_at   DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at      DATETIME2 NOT NULL DEFAULT GETDATE()
);

CREATE TABLE ecommerce.products (
    product_id      BIGINT NOT NULL,
    sku             NVARCHAR(100) NOT NULL,
    product_name    NVARCHAR(255) NOT NULL,
    brand           NVARCHAR(100),
    category_l1     NVARCHAR(150),
    category_l2     NVARCHAR(150),
    unit_price      DECIMAL(12,2) NOT NULL,
    cost_price      DECIMAL(12,2),
    is_active       BIT NOT NULL DEFAULT 1,
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE()
);

CREATE TABLE ecommerce.orders (
    order_id        BIGINT NOT NULL,
    customer_id     BIGINT NOT NULL,
    order_status    NVARCHAR(30) NOT NULL DEFAULT 'PENDING',
    payment_method  NVARCHAR(50),
    payment_status  NVARCHAR(30) NOT NULL DEFAULT 'UNPAID',
    subtotal        DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    shipping_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    tax_amount      DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    total_amount    DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    currency_code   CHAR(3) NOT NULL DEFAULT 'USD',
    ordered_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    shipped_at      DATETIME2,
    delivered_at    DATETIME2,
    cancelled_at    DATETIME2
);

CREATE TABLE ecommerce.order_items (
    order_item_id   BIGINT NOT NULL,
    order_id        BIGINT NOT NULL,
    product_id      BIGINT NOT NULL,
    quantity        INT NOT NULL,
    unit_price      DECIMAL(12,2) NOT NULL,
    discount_pct    DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    line_total      DECIMAL(14,2) NOT NULL
);

CREATE TABLE ecommerce.promotions (
    promo_id        INT NOT NULL,
    promo_code      NVARCHAR(50) NOT NULL,
    promo_type      NVARCHAR(30) NOT NULL,
    discount_value  DECIMAL(10,2) NOT NULL,
    min_order_value DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    usage_limit     INT,
    used_count      INT NOT NULL DEFAULT 0,
    valid_from      DATE NOT NULL,
    valid_to        DATE NOT NULL,
    is_active       BIT NOT NULL DEFAULT 1,
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE()
);

CREATE TABLE ecommerce.product_reviews (
    review_id       BIGINT NOT NULL,
    product_id      BIGINT NOT NULL,
    customer_id     BIGINT NOT NULL,
    rating          TINYINT NOT NULL,
    title           NVARCHAR(255),
    body            NVARCHAR(MAX),
    is_verified     BIT NOT NULL DEFAULT 0,
    status          NVARCHAR(20) NOT NULL DEFAULT 'PENDING',
    reviewed_at     DATETIME2 NOT NULL DEFAULT GETDATE()
);
