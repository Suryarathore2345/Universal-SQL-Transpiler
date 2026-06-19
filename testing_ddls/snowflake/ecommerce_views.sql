-- Snowflake: E-Commerce Analytical Views

CREATE OR REPLACE VIEW ecommerce.vw_customer_summary AS
SELECT
    c.customer_id,
    c.email,
    c.first_name || ' ' || c.last_name AS full_name,
    c.loyalty_tier,
    c.registered_at,
    COUNT(DISTINCT o.order_id)              AS total_orders,
    SUM(o.total_amount)                     AS lifetime_value,
    AVG(o.total_amount)                     AS avg_order_value,
    MAX(o.ordered_at)                       AS last_order_date,
    DATEDIFF('day', MAX(o.ordered_at), CURRENT_TIMESTAMP()) AS days_since_last_order
FROM ecommerce.customers c
LEFT JOIN ecommerce.orders o
    ON c.customer_id = o.customer_id
    AND o.order_status NOT IN ('CANCELLED', 'REFUNDED')
GROUP BY 1, 2, 3, 4, 5;

CREATE OR REPLACE VIEW ecommerce.vw_daily_revenue AS
SELECT
    DATE_TRUNC('day', ordered_at)           AS order_date,
    COUNT(DISTINCT order_id)                AS total_orders,
    COUNT(DISTINCT customer_id)             AS unique_customers,
    SUM(subtotal)                           AS gross_revenue,
    SUM(discount_amount)                    AS total_discounts,
    SUM(total_amount)                       AS net_revenue,
    SUM(tax_amount)                         AS total_tax,
    SUM(shipping_amount)                    AS total_shipping,
    AVG(total_amount)                       AS avg_order_value,
    SUM(CASE WHEN payment_status = 'PAID' THEN total_amount ELSE 0 END) AS collected_revenue
FROM ecommerce.orders
WHERE order_status NOT IN ('CANCELLED')
GROUP BY 1;

CREATE OR REPLACE VIEW ecommerce.vw_product_performance AS
SELECT
    p.product_id,
    p.sku,
    p.product_name,
    p.brand,
    c.category_name,
    SUM(oi.quantity)                        AS units_sold,
    SUM(oi.line_total)                      AS total_revenue,
    AVG(oi.unit_price)                      AS avg_selling_price,
    p.unit_price                            AS current_price,
    COUNT(DISTINCT oi.order_id)             AS orders_containing,
    AVG(pr.rating)                          AS avg_rating,
    COUNT(pr.review_id)                     AS review_count
FROM ecommerce.products p
LEFT JOIN ecommerce.categories c ON p.category_id = c.category_id
LEFT JOIN ecommerce.order_items oi ON p.product_id = oi.product_id
LEFT JOIN ecommerce.product_reviews pr ON p.product_id = pr.product_id AND pr.status = 'APPROVED'
GROUP BY 1, 2, 3, 4, 5, p.unit_price;

CREATE OR REPLACE VIEW ecommerce.vw_monthly_cohort AS
SELECT
    DATE_TRUNC('month', c.registered_at)   AS cohort_month,
    DATE_TRUNC('month', o.ordered_at)      AS order_month,
    DATEDIFF('month',
        DATE_TRUNC('month', c.registered_at),
        DATE_TRUNC('month', o.ordered_at))  AS months_since_signup,
    COUNT(DISTINCT c.customer_id)           AS customers,
    SUM(o.total_amount)                     AS revenue
FROM ecommerce.customers c
JOIN ecommerce.orders o ON c.customer_id = o.customer_id
WHERE o.order_status NOT IN ('CANCELLED', 'REFUNDED')
GROUP BY 1, 2, 3;

CREATE OR REPLACE VIEW ecommerce.vw_cart_abandonment AS
SELECT
    DATE_TRUNC('day', ca.added_at)         AS cart_date,
    COUNT(DISTINCT ca.cart_id)             AS carts_created,
    COUNT(DISTINCT o.order_id)             AS orders_placed,
    COUNT(DISTINCT ca.cart_id)
        - COUNT(DISTINCT o.order_id)       AS abandoned_carts,
    ROUND(
        (COUNT(DISTINCT ca.cart_id)
         - COUNT(DISTINCT o.order_id)) * 100.0
        / NULLIF(COUNT(DISTINCT ca.cart_id), 0), 2
    )                                      AS abandonment_rate_pct
FROM ecommerce.cart ca
LEFT JOIN ecommerce.orders o
    ON ca.customer_id = o.customer_id
    AND DATE_TRUNC('day', ca.added_at) = DATE_TRUNC('day', o.ordered_at)
GROUP BY 1;

CREATE OR REPLACE VIEW ecommerce.vw_top_categories AS
SELECT
    cat.category_name,
    COUNT(DISTINCT p.product_id)           AS product_count,
    SUM(oi.quantity)                       AS units_sold,
    SUM(oi.line_total)                     AS total_revenue,
    RANK() OVER (ORDER BY SUM(oi.line_total) DESC) AS revenue_rank
FROM ecommerce.categories cat
JOIN ecommerce.products p ON cat.category_id = p.category_id
JOIN ecommerce.order_items oi ON p.product_id = oi.product_id
GROUP BY 1;
