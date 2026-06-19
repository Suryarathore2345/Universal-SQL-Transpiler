-- Azure Synapse Analytics: E-Commerce Tables
-- Uses DISTRIBUTION and clustered columnstore indexes

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
)
WITH (
    DISTRIBUTION = REPLICATE,
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE ecommerce.products (
    product_id      BIGINT NOT NULL,
    category_id     INT NOT NULL,
    sku             NVARCHAR(100) NOT NULL,
    product_name    NVARCHAR(255) NOT NULL,
    brand           NVARCHAR(100),
    unit_price      DECIMAL(12,2) NOT NULL,
    cost_price      DECIMAL(12,2),
    is_active       BIT NOT NULL DEFAULT 1,
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE()
)
WITH (
    DISTRIBUTION = REPLICATE,
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE ecommerce.orders (
    order_id        BIGINT NOT NULL,
    customer_id     BIGINT NOT NULL,
    order_status    NVARCHAR(30) NOT NULL DEFAULT 'PENDING',
    payment_method  NVARCHAR(50),
    subtotal        DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    shipping_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    tax_amount      DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    total_amount    DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    currency_code   CHAR(3) NOT NULL DEFAULT 'USD',
    ordered_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    shipped_at      DATETIME2,
    delivered_at    DATETIME2
)
WITH (
    DISTRIBUTION = HASH(customer_id),
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE ecommerce.order_items (
    order_item_id   BIGINT NOT NULL,
    order_id        BIGINT NOT NULL,
    product_id      BIGINT NOT NULL,
    quantity        INT NOT NULL,
    unit_price      DECIMAL(12,2) NOT NULL,
    discount_pct    DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    line_total      DECIMAL(14,2) NOT NULL
)
WITH (
    DISTRIBUTION = HASH(order_id),
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE ecommerce.cart_events (
    event_id        BIGINT NOT NULL,
    session_id      NVARCHAR(100),
    customer_id     BIGINT,
    product_id      BIGINT NOT NULL,
    event_type      NVARCHAR(30) NOT NULL,
    quantity        INT DEFAULT 1,
    occurred_at     DATETIME2 NOT NULL DEFAULT GETDATE()
)
WITH (
    DISTRIBUTION = HASH(customer_id),
    CLUSTERED COLUMNSTORE INDEX
);
