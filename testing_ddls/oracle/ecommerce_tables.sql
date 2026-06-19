-- Oracle: E-Commerce Domain Tables

CREATE TABLE ecommerce.customers (
    customer_id     NUMBER(19) NOT NULL,
    email           VARCHAR2(255) NOT NULL,
    first_name      VARCHAR2(100),
    last_name       VARCHAR2(100),
    phone           VARCHAR2(30),
    date_of_birth   DATE,
    gender          VARCHAR2(10),
    loyalty_tier    VARCHAR2(20) DEFAULT 'BRONZE',
    total_orders    NUMBER(10) DEFAULT 0,
    total_spent     NUMBER(14,2) DEFAULT 0,
    is_active       NUMBER(1) DEFAULT 1,
    registered_at   TIMESTAMP DEFAULT SYSTIMESTAMP,
    updated_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    CONSTRAINT uq_customers_email UNIQUE (email)
);

CREATE TABLE ecommerce.categories (
    category_id     NUMBER(10) NOT NULL,
    parent_id       NUMBER(10),
    category_name   VARCHAR2(150) NOT NULL,
    slug            VARCHAR2(150) NOT NULL,
    description     CLOB,
    sort_order      NUMBER(5) DEFAULT 0,
    is_active       NUMBER(1) DEFAULT 1,
    created_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_categories PRIMARY KEY (category_id),
    CONSTRAINT uq_categories_slug UNIQUE (slug),
    CONSTRAINT fk_cat_parent FOREIGN KEY (parent_id) REFERENCES ecommerce.categories(category_id)
);

CREATE TABLE ecommerce.products (
    product_id      NUMBER(19) NOT NULL,
    category_id     NUMBER(10) NOT NULL,
    sku             VARCHAR2(100) NOT NULL,
    product_name    VARCHAR2(255) NOT NULL,
    description     CLOB,
    brand           VARCHAR2(100),
    unit_price      NUMBER(12,2) NOT NULL,
    cost_price      NUMBER(12,2),
    stock_qty       NUMBER(10) DEFAULT 0,
    weight_kg       NUMBER(8,3),
    is_digital      NUMBER(1) DEFAULT 0,
    is_active       NUMBER(1) DEFAULT 1,
    created_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    updated_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_products PRIMARY KEY (product_id),
    CONSTRAINT uq_products_sku UNIQUE (sku),
    CONSTRAINT fk_products_cat FOREIGN KEY (category_id) REFERENCES ecommerce.categories(category_id)
);

CREATE TABLE ecommerce.orders (
    order_id        NUMBER(19) NOT NULL,
    customer_id     NUMBER(19) NOT NULL,
    order_status    VARCHAR2(30) DEFAULT 'PENDING' NOT NULL,
    payment_method  VARCHAR2(50),
    payment_status  VARCHAR2(30) DEFAULT 'UNPAID',
    subtotal        NUMBER(14,2) DEFAULT 0,
    discount_amount NUMBER(14,2) DEFAULT 0,
    shipping_amount NUMBER(14,2) DEFAULT 0,
    tax_amount      NUMBER(14,2) DEFAULT 0,
    total_amount    NUMBER(14,2) NOT NULL,
    currency_code   CHAR(3) DEFAULT 'USD',
    notes           CLOB,
    ordered_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    shipped_at      TIMESTAMP,
    delivered_at    TIMESTAMP,
    cancelled_at    TIMESTAMP,
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_cust FOREIGN KEY (customer_id) REFERENCES ecommerce.customers(customer_id)
);

CREATE TABLE ecommerce.order_items (
    order_item_id   NUMBER(19) NOT NULL,
    order_id        NUMBER(19) NOT NULL,
    product_id      NUMBER(19) NOT NULL,
    quantity        NUMBER(10) NOT NULL,
    unit_price      NUMBER(12,2) NOT NULL,
    discount_pct    NUMBER(5,2) DEFAULT 0,
    line_total      NUMBER(14,2) NOT NULL,
    CONSTRAINT pk_order_items PRIMARY KEY (order_item_id),
    CONSTRAINT fk_oi_order FOREIGN KEY (order_id) REFERENCES ecommerce.orders(order_id),
    CONSTRAINT fk_oi_product FOREIGN KEY (product_id) REFERENCES ecommerce.products(product_id)
);

CREATE TABLE ecommerce.product_reviews (
    review_id       NUMBER(19) NOT NULL,
    product_id      NUMBER(19) NOT NULL,
    customer_id     NUMBER(19) NOT NULL,
    rating          NUMBER(1) NOT NULL,
    title           VARCHAR2(255),
    body            CLOB,
    is_verified     NUMBER(1) DEFAULT 0,
    status          VARCHAR2(20) DEFAULT 'PENDING',
    reviewed_at     TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_reviews PRIMARY KEY (review_id),
    CONSTRAINT ck_rating CHECK (rating BETWEEN 1 AND 5)
);
