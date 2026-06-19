-- Microsoft Fabric Lakehouse Views and Materialized Lake Views (Spark SQL)
-- Tests: MLV syntax (CREATE MATERIALIZED LAKE VIEW), Spark functions,
--        COALESCE, CONCAT, DATE_FORMAT, DATEDIFF, window functions

CREATE OR REPLACE VIEW `gold`.`active_customers` AS
SELECT
    customer_id,
    first_name,
    last_name,
    email,
    city,
    state,
    country,
    loyalty_tier,
    signup_date,
    DATEDIFF(CURRENT_DATE(), signup_date)   AS days_since_signup,
    YEAR(signup_date)                       AS signup_year,
    COALESCE(state, 'Unknown')              AS state_display,
    CONCAT(first_name, ' ', last_name)      AS full_name
FROM `silver`.`customers`
WHERE is_active = TRUE;

CREATE OR REPLACE VIEW `gold`.`order_summary` AS
SELECT
    f.sale_key,
    f.order_id,
    f.sale_date,
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)         AS customer_name,
    c.loyalty_tier,
    f.quantity,
    f.unit_price,
    COALESCE(f.discount_pct, 0.0)                  AS discount_pct,
    f.gross_amount,
    f.net_amount,
    f.status,
    CASE
        WHEN f.net_amount > 1000 THEN 'High Value'
        WHEN f.net_amount > 500  THEN 'Medium Value'
        ELSE 'Standard'
    END AS order_tier,
    DATE_FORMAT(f.sale_date, 'yyyy-MM')             AS sale_month_key
FROM `gold`.`fact_sales` f
JOIN `silver`.`customers` c ON f.customer_key = c.customer_id;

-- Materialized Lake View (MLV) — Fabric Lakehouse Runtime 1.3+
CREATE OR REPLACE MATERIALIZED LAKE VIEW `gold`.`mv_monthly_revenue` AS
SELECT
    sale_year,
    sale_month,
    status,
    COUNT(sale_key)         AS sale_count,
    SUM(gross_amount)       AS gross_revenue,
    SUM(net_amount)         AS net_revenue,
    AVG(net_amount)         AS avg_order_value,
    COUNT(DISTINCT customer_key) AS unique_customers
FROM `gold`.`fact_sales`
WHERE status IN ('COMPLETED', 'SHIPPED')
GROUP BY sale_year, sale_month, status;

CREATE OR REPLACE MATERIALIZED LAKE VIEW `gold`.`mv_customer_ltv` AS
SELECT
    c.customer_id,
    c.loyalty_tier,
    c.country,
    COUNT(f.sale_key)       AS total_orders,
    SUM(f.net_amount)       AS lifetime_value,
    AVG(f.net_amount)       AS avg_order_value,
    MAX(f.sale_date)        AS last_order_date,
    RANK() OVER (PARTITION BY c.country ORDER BY SUM(f.net_amount) DESC) AS country_ltv_rank
FROM `silver`.`customers` c
JOIN `gold`.`fact_sales` f ON c.customer_id = f.customer_key
GROUP BY c.customer_id, c.loyalty_tier, c.country;
