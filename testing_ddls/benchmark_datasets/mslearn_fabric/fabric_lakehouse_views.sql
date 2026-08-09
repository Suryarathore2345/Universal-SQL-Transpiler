-- ============================================================================
-- Fabric Lakehouse: SQL Analytics Endpoint Queries
-- Source: MicrosoftLearning/mslearn-fabric (MIT License)
-- Dialect: Microsoft Fabric Lakehouse SQL Analytics Endpoint (read-only T-SQL)
-- Key constructs: Queries against Delta tables via SQL endpoint,
--                 dbo schema for managed tables, medallion architecture
-- ============================================================================

-- ==========================================================
-- Lab 01: Lakehouse - query Delta tables via SQL endpoint
-- ==========================================================

SELECT Item, SUM(Quantity * UnitPrice) AS Revenue
FROM sales
GROUP BY Item
ORDER BY Revenue DESC;

-- ==========================================================
-- Lab 03b: Medallion Lakehouse - silver-layer queries
-- ==========================================================

SELECT YEAR(OrderDate) AS Year,
    CAST(SUM(Quantity * (UnitPrice + Tax)) AS DECIMAL(12, 2)) AS TotalSales
FROM dbo.sales_silver
GROUP BY YEAR(OrderDate)
ORDER BY YEAR(OrderDate);

SELECT TOP (10) CustomerName, SUM(Quantity) AS TotalQuantity
FROM dbo.sales_silver
GROUP BY CustomerName
ORDER BY TotalQuantity DESC;
