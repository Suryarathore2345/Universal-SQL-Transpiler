-- SQL Server: E-Commerce Domain Tables

CREATE TABLE ecommerce.customers (
    customer_id     BIGINT NOT NULL IDENTITY(1,1),
    email           NVARCHAR(255) NOT NULL,
    first_name      NVARCHAR(100),
    last_name       NVARCHAR(100),
    phone           NVARCHAR(30),
    date_of_birth   DATE,
    gender          NVARCHAR(10),
    loyalty_tier    NVARCHAR(20) NOT NULL DEFAULT 'BRONZE',
    total_orders    INT NOT NULL DEFAULT 0,
    total_spent     DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    is_active       BIT NOT NULL DEFAULT 1,
    registered_at   DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_customers PRIMARY KEY (customer_id),
    CONSTRAINT UQ_customers_email UNIQUE (email)
);

CREATE TABLE ecommerce.categories (
    category_id     INT NOT NULL IDENTITY(1,1),
    parent_id       INT NULL,
    category_name   NVARCHAR(150) NOT NULL,
    slug            NVARCHAR(150) NOT NULL,
    description     NVARCHAR(MAX),
    sort_order      INT NOT NULL DEFAULT 0,
    is_active       BIT NOT NULL DEFAULT 1,
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_categories PRIMARY KEY (category_id),
    CONSTRAINT UQ_categories_slug UNIQUE (slug)
);

CREATE TABLE ecommerce.products (
    product_id      BIGINT NOT NULL IDENTITY(1,1),
    category_id     INT NOT NULL,
    sku             NVARCHAR(100) NOT NULL,
    product_name    NVARCHAR(255) NOT NULL,
    description     NVARCHAR(MAX),
    brand           NVARCHAR(100),
    unit_price      DECIMAL(12,2) NOT NULL,
    cost_price      DECIMAL(12,2),
    stock_qty       INT NOT NULL DEFAULT 0,
    weight_kg       DECIMAL(8,3),
    is_digital      BIT NOT NULL DEFAULT 0,
    is_active       BIT NOT NULL DEFAULT 1,
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_products PRIMARY KEY (product_id),
    CONSTRAINT UQ_products_sku UNIQUE (sku),
    CONSTRAINT FK_products_category FOREIGN KEY (category_id) REFERENCES ecommerce.categories(category_id)
);

CREATE TABLE ecommerce.orders (
    order_id        BIGINT NOT NULL IDENTITY(1,1),
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
    notes           NVARCHAR(MAX),
    ordered_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    shipped_at      DATETIME2,
    delivered_at    DATETIME2,
    cancelled_at    DATETIME2,
    CONSTRAINT PK_orders PRIMARY KEY (order_id),
    CONSTRAINT FK_orders_customer FOREIGN KEY (customer_id) REFERENCES ecommerce.customers(customer_id)
);

CREATE TABLE ecommerce.order_items (
    order_item_id   BIGINT NOT NULL IDENTITY(1,1),
    order_id        BIGINT NOT NULL,
    product_id      BIGINT NOT NULL,
    quantity        INT NOT NULL,
    unit_price      DECIMAL(12,2) NOT NULL,
    discount_pct    DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    line_total      DECIMAL(14,2) NOT NULL,
    CONSTRAINT PK_order_items PRIMARY KEY (order_item_id),
    CONSTRAINT FK_order_items_order FOREIGN KEY (order_id) REFERENCES ecommerce.orders(order_id),
    CONSTRAINT FK_order_items_product FOREIGN KEY (product_id) REFERENCES ecommerce.products(product_id)
);

CREATE TABLE ecommerce.product_reviews (
    review_id       BIGINT NOT NULL IDENTITY(1,1),
    product_id      BIGINT NOT NULL,
    customer_id     BIGINT NOT NULL,
    order_id        BIGINT,
    rating          TINYINT NOT NULL,
    title           NVARCHAR(255),
    body            NVARCHAR(MAX),
    is_verified     BIT NOT NULL DEFAULT 0,
    helpful_count   INT NOT NULL DEFAULT 0,
    status          NVARCHAR(20) NOT NULL DEFAULT 'PENDING',
    reviewed_at     DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_product_reviews PRIMARY KEY (review_id)
);

CREATE TABLE ecommerce.promotions (
    promo_id        INT NOT NULL IDENTITY(1,1),
    promo_code      NVARCHAR(50) NOT NULL,
    promo_type      NVARCHAR(30) NOT NULL,
    discount_value  DECIMAL(10,2) NOT NULL,
    min_order_value DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    usage_limit     INT,
    used_count      INT NOT NULL DEFAULT 0,
    valid_from      DATE NOT NULL,
    valid_to        DATE NOT NULL,
    is_active       BIT NOT NULL DEFAULT 1,
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_promotions PRIMARY KEY (promo_id),
    CONSTRAINT UQ_promo_code UNIQUE (promo_code)
);
