-- Google BigQuery Views
-- Tests: BigQuery view syntax, SAFE_DIVIDE, IF(), IFNULL, EXCEPT(), REPLACE(),
--        DATE_TRUNC, EXTRACT, TIMESTAMP_DIFF, FARM_FINGERPRINT, STRUCT, ARRAY_AGG

CREATE OR REPLACE VIEW `my_project.sales.active_customer_summary`
OPTIONS(description='Summary of active customers with aggregates')
AS
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.address.city     AS city,
    c.address.country  AS country,
    c.loyalty_tier,
    c.signup_date,
    DATE_DIFF(CURRENT_DATE(), c.signup_date, DAY)     AS days_since_signup,
    EXTRACT(YEAR FROM c.signup_date)                  AS signup_year,
    IFNULL(c.address.state, 'Unknown')                AS state
FROM `my_project.sales.customers` c
WHERE c.is_active = TRUE;

CREATE OR REPLACE VIEW `my_project.sales.order_metrics`
OPTIONS(description='Daily order aggregates')
AS
SELECT
    DATE_TRUNC(o.order_ts, DAY)                          AS order_date,
    o.status,
    o.region,
    COUNT(o.order_id)                                    AS order_count,
    SUM(o.total_amount)                                  AS total_revenue,
    SAFE_DIVIDE(SUM(o.total_amount), COUNT(o.order_id)) AS avg_order_value,
    COUNTIF(o.is_priority = TRUE)                        AS priority_count,
    IF(SUM(o.total_amount) > 10000, 'High', 'Normal')   AS revenue_tier
FROM `my_project.sales.orders` o
GROUP BY 1, 2, 3;

CREATE OR REPLACE VIEW `my_project.analytics.customer_360`
OPTIONS(description='360-degree customer view joining orders and events')
AS
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.loyalty_tier,
    SUM(o.total_amount)         AS lifetime_value,
    COUNT(DISTINCT o.order_id)  AS total_orders,
    MAX(o.order_date)           AS last_order_date,
    COUNT(DISTINCT e.event_id)  AS total_events,
    COUNT(DISTINCT e.session_id) AS total_sessions,
    TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), MAX(e.event_ts), DAY) AS days_since_last_event,
    ARRAY_AGG(DISTINCT o.status IGNORE NULLS) AS order_statuses
FROM `my_project.sales.customers` c
LEFT JOIN `my_project.sales.orders` o        ON c.customer_id = o.customer_id
LEFT JOIN `my_project.analytics.events` e    ON CAST(c.customer_id AS STRING) = CAST(e.user_id AS STRING)
GROUP BY c.customer_id, c.first_name, c.last_name, c.loyalty_tier;

CREATE OR REPLACE MATERIALIZED VIEW `my_project.analytics.mv_daily_revenue`
OPTIONS(enable_refresh=TRUE, refresh_interval_minutes=60)
AS
SELECT
    DATE(order_ts)    AS sale_date,
    region,
    status,
    COUNT(order_id)   AS orders,
    SUM(total_amount) AS revenue
FROM `my_project.sales.orders`
WHERE status IN ('COMPLETED', 'SHIPPED')
GROUP BY 1, 2, 3;
