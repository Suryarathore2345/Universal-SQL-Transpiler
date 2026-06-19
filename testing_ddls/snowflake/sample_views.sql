-- Snowflake Sample Views DDL
-- Tests: Snowflake-specific view features, SECURE VIEW, MATERIALIZED VIEW,
--        IFF(), ZEROIFNULL, NULLIFZERO, SPLIT_PART, REGEXP_LIKE, QUALIFY

-- Simple view
CREATE OR REPLACE VIEW sales.active_customers AS
SELECT
    customer_id,
    first_name,
    last_name,
    email,
    loyalty_tier,
    signup_date,
    DATEDIFF('day', signup_date, CURRENT_DATE()) AS days_since_signup
FROM sales.customers
WHERE is_active = TRUE;

-- Secure view (no internal pushdown)
CREATE OR REPLACE SECURE VIEW sales.customer_pii_masked AS
SELECT
    customer_id,
    CONCAT(SUBSTR(first_name, 1, 1), '***') AS first_name_masked,
    last_name,
    REGEXP_REPLACE(email, '(.{2}).+(@.+)', '\\1***\\2') AS email_masked,
    region_code,
    loyalty_tier
FROM sales.customers;

-- View with Snowflake-specific functions
CREATE OR REPLACE VIEW analytics.order_summary AS
SELECT
    o.order_id,
    o.order_date,
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.loyalty_tier,
    o.total_amount,
    IFF(o.total_amount > 500, 'High Value', 'Standard') AS order_tier,
    ZEROIFNULL(o.discount_pct) AS discount_pct,
    o.status,
    SPLIT_PART(c.email, '@', 2) AS email_domain,
    NVL(o.order_notes, 'No notes') AS notes
FROM sales.orders o
JOIN sales.customers c ON o.customer_id = c.customer_id;

-- View with QUALIFY (window function filter)
CREATE OR REPLACE VIEW analytics.top_customers_per_region AS
SELECT
    c.customer_id,
    c.region_code,
    c.first_name,
    c.last_name,
    SUM(o.total_amount) AS total_spent,
    COUNT(o.order_id) AS order_count,
    RANK() OVER (PARTITION BY c.region_code ORDER BY SUM(o.total_amount) DESC) AS regional_rank
FROM sales.customers c
JOIN sales.orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.region_code, c.first_name, c.last_name
QUALIFY RANK() OVER (PARTITION BY c.region_code ORDER BY SUM(o.total_amount) DESC) <= 10;

-- Materialized view
CREATE OR REPLACE MATERIALIZED VIEW analytics.daily_sales_summary AS
SELECT
    DATE_TRUNC('day', order_date) AS sale_date,
    status,
    COUNT(order_id)               AS order_count,
    SUM(total_amount)             AS total_revenue,
    AVG(total_amount)             AS avg_order_value,
    MIN(total_amount)             AS min_order,
    MAX(total_amount)             AS max_order
FROM sales.orders
WHERE status != 'CANCELLED'
GROUP BY 1, 2;

-- Secure materialized view
CREATE OR REPLACE SECURE MATERIALIZED VIEW analytics.product_performance AS
SELECT
    p.category,
    p.sub_category,
    COUNT(DISTINCT p.product_id) AS product_count,
    SUM(p.unit_price)            AS total_list_value,
    AVG(p.unit_price)            AS avg_price,
    ZEROIFNULL(SUM(p.stock_qty)) AS total_stock
FROM sales.products p
WHERE p.is_active = TRUE
GROUP BY p.category, p.sub_category;
