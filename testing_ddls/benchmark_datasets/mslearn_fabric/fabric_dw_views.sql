-- ============================================================================
-- Fabric Data Warehouse: CREATE VIEW statements
-- Source: MicrosoftLearning/mslearn-fabric (MIT License)
-- Dialect: Microsoft Fabric Data Warehouse (T-SQL subset)
-- Key constructs: cross-warehouse 3-part naming, CREATE VIEW, CREATE OR ALTER
-- ============================================================================

-- ==========================================================
-- Lab 06: Basic star schema view
-- ==========================================================

CREATE VIEW vSalesByRegion
AS
SELECT  d.[Year] AS CalendarYear,
        d.[Month] AS MonthOfYear,
        d.MonthName AS MonthName,
        c.CountryRegion AS SalesRegion,
       SUM(so.SalesTotal) AS SalesRevenue
FROM FactSalesOrder AS so
JOIN DimDate AS d ON so.SalesOrderDateKey = d.DateKey
JOIN DimCustomer AS c ON so.CustomerKey = c.CustomerKey
GROUP BY d.[Year], d.[Month], d.MonthName, c.CountryRegion;
GO

-- ==========================================================
-- Lab 06a: Cross-warehouse view using 3-part naming
-- Fabric-specific: references a Lakehouse SQL endpoint from a warehouse
-- ==========================================================

CREATE VIEW Sales.Staging_Sales
AS
SELECT * FROM [<lakehouse_name>].[dbo].[staging_sales];
GO

-- ==========================================================
-- Lab 22c: Copilot-generated view
-- ==========================================================

CREATE VIEW [dbo].[SalesRevenueView] AS
SELECT
    [DD].[Year],
    [DD].[Month],
    [DD].[MonthName],
    SUM([FS1].[SalesTotal]) AS [TotalRevenue]
FROM
    [dbo].[FactSalesOrder] AS [FS1]
JOIN
    [dbo].[DimDate] AS [DD] ON [FS1].[SalesOrderDateKey] = [DD].[DateKey]
GROUP BY
    [DD].[Year],
    [DD].[Month],
    [DD].[MonthName];
GO

-- ==========================================================
-- Lab 26d: Gold-layer view for monthly sales by category
-- ==========================================================

CREATE VIEW gold.vw_monthly_sales
AS
SELECT
    d.calendar_year,
    d.calendar_month,
    d.month_name,
    p.category,
    COUNT(*) AS order_count,
    SUM(o.quantity) AS total_quantity,
    SUM(o.quantity * o.unit_price) AS total_sales
FROM staging.orders AS o
INNER JOIN staging.dates AS d
    ON o.order_date = d.calendar_date
INNER JOIN staging.products AS p
    ON o.product_id = p.product_id
WHERE o.status = 'Completed'
GROUP BY d.calendar_year, d.calendar_month, d.month_name, p.category;
GO

-- ==========================================================
-- Lab 20: Fabric SQL Database view with ROLE-based security
-- ==========================================================

CREATE VIEW SalesLT.vw_SalesOrderHoliday AS
SELECT DISTINCT soh.SalesOrderID, soh.OrderDate, ph.HolidayName, ph.CountryOrRegion
FROM SalesLT.SalesOrderHeader AS soh
INNER JOIN SalesLT.Address a
    ON a.AddressID = soh.ShipToAddressID
INNER JOIN SalesLT.PublicHolidays AS ph
    ON soh.OrderDate = ph.Date AND a.CountryRegion = ph.CountryOrRegion
WHERE a.CountryRegion = 'United Kingdom';
GO

CREATE ROLE SalesOrderRole;
GRANT SELECT ON SalesLT.vw_SalesOrderHoliday TO SalesOrderRole;
GO
