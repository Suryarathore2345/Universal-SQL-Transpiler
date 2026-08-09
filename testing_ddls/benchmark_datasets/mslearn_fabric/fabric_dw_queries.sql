-- ============================================================================
-- Fabric Data Warehouse: Analytical Queries
-- Source: MicrosoftLearning/mslearn-fabric (MIT License)
-- Dialect: Microsoft Fabric Data Warehouse (T-SQL subset)
-- Key constructs: Window functions, CTEs, CASE, ISNULL, aggregate queries,
--                 SCD Type 2 updates, DMV queries (queryinsights)
-- ============================================================================

-- ==========================================================
-- Lab 06: Basic star schema queries
-- ==========================================================

SELECT  d.[Year] AS CalendarYear,
        d.[Month] AS MonthOfYear,
        d.MonthName AS MonthName,
       SUM(so.SalesTotal) AS SalesRevenue
FROM FactSalesOrder AS so
JOIN DimDate AS d ON so.SalesOrderDateKey = d.DateKey
GROUP BY d.[Year], d.[Month], d.MonthName
ORDER BY CalendarYear, MonthOfYear;

SELECT  d.[Year] AS CalendarYear,
        d.[Month] AS MonthOfYear,
        d.MonthName AS MonthName,
        c.CountryRegion AS SalesRegion,
       SUM(so.SalesTotal) AS SalesRevenue
FROM FactSalesOrder AS so
JOIN DimDate AS d ON so.SalesOrderDateKey = d.DateKey
JOIN DimCustomer AS c ON so.CustomerKey = c.CustomerKey
GROUP BY d.[Year], d.[Month], d.MonthName, c.CountryRegion
ORDER BY CalendarYear, MonthOfYear, SalesRegion;

-- ==========================================================
-- Lab 06a: Top customers / products / categorized ranking
-- ==========================================================

SELECT c.CustomerName, SUM(s.UnitPrice * s.Quantity) AS TotalSales
FROM Sales.Fact_Sales s
JOIN Sales.Dim_Customer c
ON s.CustomerID = c.CustomerID
WHERE YEAR(s.OrderDate) = 2021
GROUP BY c.CustomerName
ORDER BY TotalSales DESC;

SELECT i.ItemName, SUM(s.UnitPrice * s.Quantity) AS TotalSales
FROM Sales.Fact_Sales s
JOIN Sales.Dim_Item i
ON s.ItemID = i.ItemID
WHERE YEAR(s.OrderDate) = 2021
GROUP BY i.ItemName
ORDER BY TotalSales DESC;

-- CTE with ROW_NUMBER for top-1-per-category
WITH CategorizedSales AS (
SELECT
    CASE
        WHEN i.ItemName LIKE '%Helmet%' THEN 'Helmet'
        WHEN i.ItemName LIKE '%Bike%' THEN 'Bike'
        WHEN i.ItemName LIKE '%Gloves%' THEN 'Gloves'
        ELSE 'Other'
    END AS Category,
    c.CustomerName,
    s.UnitPrice * s.Quantity AS Sales
FROM Sales.Fact_Sales s
JOIN Sales.Dim_Customer c
ON s.CustomerID = c.CustomerID
JOIN Sales.Dim_Item i
ON s.ItemID = i.ItemID
WHERE YEAR(s.OrderDate) = 2021
),
RankedSales AS (
    SELECT
        Category,
        CustomerName,
        SUM(Sales) AS TotalSales,
        ROW_NUMBER() OVER (PARTITION BY Category ORDER BY SUM(Sales) DESC) AS SalesRank
    FROM CategorizedSales
    WHERE Category IN ('Helmet', 'Bike', 'Gloves')
    GROUP BY Category, CustomerName
)
SELECT Category, CustomerName, TotalSales
FROM RankedSales
WHERE SalesRank = 1
ORDER BY TotalSales DESC;

-- ==========================================================
-- Lab 06b: NYC Taxi trip analytics
-- ==========================================================

SELECT
D.MonthName,
COUNT(*) AS TotalTrips,
SUM(T.TotalAmount) AS TotalRevenue
FROM dbo.Trip AS T
JOIN dbo.[Date] AS D
    ON T.[DateID]=D.[DateID]
GROUP BY D.MonthName;

SELECT
D.DayName,
AVG(T.TripDurationSeconds) AS AvgDuration,
AVG(T.TripDistanceMiles) AS AvgDistance
FROM dbo.Trip AS T
JOIN dbo.[Date] AS D
    ON T.[DateID]=D.[DateID]
GROUP BY D.DayName;

SELECT TOP 10
    G.City,
    COUNT(*) AS TotalTrips
FROM dbo.Trip AS T
JOIN dbo.Geography AS G
    ON T.DropoffGeographyID=G.GeographyID
GROUP BY G.City
ORDER BY TotalTrips DESC;

-- Data quality checks
SELECT COUNT(*) FROM dbo.Trip WHERE TripDurationSeconds > 86400;
SELECT COUNT(*) FROM dbo.Trip WHERE TripDurationSeconds < 0;
DELETE FROM dbo.Trip WHERE TripDurationSeconds < 0;

-- ==========================================================
-- Lab 06c: Monitoring DMVs (Fabric-specific queryinsights)
-- ==========================================================

SELECT * FROM sys.dm_exec_connections;
SELECT * FROM sys.dm_exec_sessions;
SELECT * FROM sys.dm_exec_requests;

SELECT connections.connection_id,
    sessions.session_id, sessions.login_name, sessions.login_time,
    requests.command, requests.start_time, requests.total_elapsed_time
FROM sys.dm_exec_connections AS connections
INNER JOIN sys.dm_exec_sessions AS sessions
    ON connections.session_id=sessions.session_id
INNER JOIN sys.dm_exec_requests AS requests
    ON requests.session_id = sessions.session_id
WHERE requests.status = 'running'
    AND requests.database_id = DB_ID()
ORDER BY requests.total_elapsed_time DESC;

-- Fabric-specific: queryinsights system views
SELECT * FROM queryinsights.exec_requests_history;
SELECT * FROM queryinsights.frequently_run_queries;
SELECT * FROM queryinsights.long_running_queries;

-- ==========================================================
-- Lab 26d: T-SQL transformations with window functions
-- ==========================================================

-- Calculated columns with CASE and ISNULL
SELECT
    order_id,
    customer_id,
    order_date,
    quantity,
    unit_price,
    quantity * unit_price AS line_total,
    ISNULL(discount, 0) AS discount,
    (quantity * unit_price) - ISNULL(discount, 0) AS net_amount,
    CASE
        WHEN quantity * unit_price > 200 THEN 'High'
        WHEN quantity * unit_price > 100 THEN 'Medium'
        ELSE 'Standard'
    END AS order_tier
FROM staging.orders
WHERE status = 'Completed';

-- Aggregation with JOIN
SELECT
    c.region,
    c.segment,
    COUNT(*) AS order_count,
    SUM(o.quantity * o.unit_price) AS total_sales,
    AVG(o.quantity * o.unit_price) AS avg_order_value
FROM staging.orders AS o
INNER JOIN staging.customers AS c
    ON o.customer_id = c.customer_id
WHERE o.status = 'Completed'
GROUP BY c.region, c.segment
ORDER BY total_sales DESC;

-- Window functions: ROW_NUMBER, running SUM, LAG
SELECT
    o.customer_id,
    c.customer_name,
    o.order_date,
    o.quantity * o.unit_price AS line_total,
    ROW_NUMBER() OVER (
        PARTITION BY o.customer_id ORDER BY o.order_date
    ) AS order_sequence,
    SUM(o.quantity * o.unit_price) OVER (
        PARTITION BY o.customer_id ORDER BY o.order_date
    ) AS running_total,
    LAG(o.quantity * o.unit_price) OVER (
        PARTITION BY o.customer_id ORDER BY o.order_date
    ) AS prev_order_amount
FROM staging.orders AS o
INNER JOIN staging.customers AS c
    ON o.customer_id = c.customer_id
WHERE o.status = 'Completed'
ORDER BY o.customer_id, o.order_date;

-- CTE with YTD running total
WITH monthly_totals AS (
    SELECT
        YEAR(order_date) AS yr,
        MONTH(order_date) AS mo,
        SUM(quantity * unit_price) AS monthly_total
    FROM staging.orders
    WHERE status = 'Completed'
    GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT
    yr,
    mo,
    monthly_total,
    SUM(monthly_total) OVER (ORDER BY yr, mo) AS ytd_total
FROM monthly_totals
ORDER BY yr, mo;

-- ==========================================================
-- Lab 26: SCD Type 2 update pattern
-- ==========================================================

-- Expire current version
UPDATE d_Product
SET ValidTo = '2026-03-01',
    IsCurrent = 0
WHERE ProductNaturalKey = 'MB-PRO'
  AND IsCurrent = 1;

-- Insert new version with updated cost
INSERT INTO d_Product VALUES
(6, 'MB-PRO', 'Mountain Bike Pro', 'AdventureWorks', 'Mountain Bikes', 'Bikes', 1350.00, '2026-03-01', '9999-12-31', 1);

-- Sale referencing new product version
INSERT INTO f_Sales VALUES
(20260504, 1, 6, 5, 1, 1500.00, 1500.00, 0.00);

-- Query showing cost versions over time
SELECT
    d.FullDate,
    p.ProductName,
    p.UnitCost AS ProductCostVersion,
    p.ValidFrom AS CostEffectiveDate,
    f.Quantity,
    f.SalesAmount
FROM f_Sales f
JOIN d_Date d ON f.DateKey = d.DateKey
JOIN d_Product p ON f.ProductKey = p.ProductKey
WHERE p.ProductNaturalKey = 'MB-PRO'
ORDER BY d.FullDate;

-- SCD Type 1 update (in-place)
UPDATE d_Product
SET ProductName = 'Insulated Water Bottle'
WHERE ProductNaturalKey = 'WB-STD';

-- ==========================================================
-- Lab 26: Full star schema query across all dimensions
-- ==========================================================

SELECT
    d.FullDate,
    d.[Year],
    d.MonthName,
    s.StoreName,
    s.Region,
    p.ProductName,
    p.Category,
    c.CustomerName,
    c.Segment,
    f.Quantity,
    f.UnitPrice,
    f.SalesAmount,
    f.DiscountAmount
FROM f_Sales f
JOIN d_Date d ON f.DateKey = d.DateKey
JOIN d_Store s ON f.StoreKey = s.StoreKey
JOIN d_Product p ON f.ProductKey = p.ProductKey
JOIN d_Customer c ON f.CustomerKey = c.CustomerKey
ORDER BY d.FullDate, s.StoreName;

-- ==========================================================
-- Lab 26d: INFORMATION_SCHEMA introspection
-- ==========================================================

SELECT
    TABLE_SCHEMA AS [schema],
    TABLE_NAME AS [name],
    TABLE_TYPE AS [type]
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA IN ('staging', 'dim', 'fact', 'gold')
UNION ALL
SELECT
    ROUTINE_SCHEMA,
    ROUTINE_NAME,
    ROUTINE_TYPE
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA IN ('staging', 'dim', 'fact', 'gold')
ORDER BY [schema], [type], [name];

-- ==========================================================
-- Lab 20: Fabric SQL Database queries
-- ==========================================================

SELECT
    p.Name AS ProductName,
    pc.Name AS CategoryName,
    p.ListPrice
FROM
    SalesLT.Product p
INNER JOIN
    SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
ORDER BY
p.ListPrice DESC;

SELECT
    c.FirstName,
    c.LastName,
    soh.OrderDate,
    soh.SubTotal
FROM
    SalesLT.Customer c
INNER JOIN
    SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
ORDER BY
    soh.OrderDate DESC;

SELECT DISTINCT soh.SalesOrderID, soh.OrderDate, ph.HolidayName, ph.CountryOrRegion
FROM SalesLT.SalesOrderHeader AS soh
INNER JOIN SalesLT.Address a
    ON a.AddressID = soh.ShipToAddressID
INNER JOIN SalesLT.PublicHolidays AS ph
    ON soh.OrderDate = ph.Date AND a.CountryRegion = ph.CountryOrRegion;
