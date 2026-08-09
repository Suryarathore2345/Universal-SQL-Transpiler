-- ============================================================================
-- Fabric Data Warehouse: Dimensional Model Loading
-- Source: MicrosoftLearning/mslearn-fabric (MIT License)
-- Dialect: Microsoft Fabric Data Warehouse (T-SQL subset)
-- Key constructs: INSERT INTO ... SELECT, BIGINT IDENTITY surrogate keys,
--                 SCD Type 2 loading, fact table with surrogate key lookups
-- ============================================================================

-- ==========================================================
-- Load date dimension from staging
-- ==========================================================

INSERT INTO dim.date
    (calendar_date, calendar_year, calendar_month, month_name, calendar_quarter)
SELECT DISTINCT
    calendar_date, calendar_year, calendar_month, month_name, calendar_quarter
FROM staging.dates;

-- ==========================================================
-- Load customer dimension (SCD Type 2 initial load)
-- ==========================================================

INSERT INTO dim.customer
    (customer_id, customer_name, segment, region, effective_date, is_current)
SELECT
    customer_id,
    customer_name,
    segment,
    region,
    CAST(GETDATE() AS DATE),
    1
FROM staging.customers;

-- ==========================================================
-- Load product dimension
-- ==========================================================

INSERT INTO dim.product
    (product_id, product_name, category, unit_price)
SELECT
    product_id, product_name, category, unit_price
FROM staging.products;

-- ==========================================================
-- Load fact table with surrogate key lookups
-- ==========================================================

INSERT INTO fact.sales
    (date_key, customer_key, product_key, quantity, unit_price, sales_amount)
SELECT
    d.date_key,
    c.customer_key,
    p.product_key,
    o.quantity,
    o.unit_price,
    o.quantity * o.unit_price
FROM staging.orders AS o
INNER JOIN dim.date AS d
    ON o.order_date = d.calendar_date
INNER JOIN dim.customer AS c
    ON o.customer_id = c.customer_id
    AND c.is_current = 1
INNER JOIN dim.product AS p
    ON o.product_id = p.product_id
WHERE o.status = 'Completed';
