-- Databricks SQL Views
-- Tests: Databricks-specific view syntax, backtick quoting, Spark SQL functions,
--        COALESCE, date functions, window functions, STRUCT types

CREATE OR REPLACE VIEW `analytics`.`active_customers` AS
SELECT
    customer_id,
    first_name,
    last_name,
    email,
    city,
    state,
    loyalty_tier,
    signup_date,
    DATEDIFF(CURRENT_DATE(), signup_date) AS days_since_signup,
    YEAR(signup_date) AS signup_year
FROM `analytics`.`customers`
WHERE is_active = TRUE;

CREATE OR REPLACE VIEW `analytics`.`order_summary` AS
SELECT
    o.order_id,
    o.order_date,
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.loyalty_tier,
    o.total_amount,
    COALESCE(o.discount_pct, 0.0) AS discount_pct,
    o.total_amount * (1 - COALESCE(o.discount_pct, 0.0)) AS net_amount,
    CASE
        WHEN o.total_amount > 1000 THEN 'High Value'
        WHEN o.total_amount > 500  THEN 'Medium Value'
        ELSE 'Standard'
    END AS order_tier,
    o.status,
    o.region,
    DATE_FORMAT(o.order_date, 'yyyy-MM') AS order_month_key
FROM `analytics`.`sales_orders` o
JOIN `analytics`.`customers` c ON o.customer_id = c.customer_id;

CREATE OR REPLACE VIEW `analytics`.`daily_sales_agg` AS
SELECT
    order_date,
    region,
    status,
    COUNT(order_id)       AS order_count,
    SUM(total_amount)     AS total_revenue,
    AVG(total_amount)     AS avg_order_value,
    MIN(total_amount)     AS min_order,
    MAX(total_amount)     AS max_order,
    PERCENTILE(total_amount, 0.5) AS median_order_value,
    COUNT(DISTINCT customer_id)   AS unique_customers
FROM `analytics`.`sales_orders`
WHERE status != 'CANCELLED'
GROUP BY order_date, region, status;

CREATE OR REPLACE VIEW `analytics`.`customer_ranking` AS
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.country,
    c.loyalty_tier,
    SUM(o.total_amount)   AS total_spent,
    COUNT(o.order_id)     AS total_orders,
    MAX(o.order_date)     AS last_order_date,
    RANK() OVER (PARTITION BY c.country ORDER BY SUM(o.total_amount) DESC) AS country_rank,
    NTILE(4) OVER (ORDER BY SUM(o.total_amount) DESC) AS spend_quartile
FROM `analytics`.`customers` c
JOIN `analytics`.`sales_orders` o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.country, c.loyalty_tier;
