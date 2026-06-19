-- Azure Synapse Analytics Views
-- Tests: T-SQL view syntax in Synapse context, ISNULL, COALESCE,
--        window functions, CONVERT, CAST, date functions

CREATE OR ALTER VIEW [dbo].[vw_sales_summary] AS
SELECT
    fis.[ProductKey],
    dp.[EnglishProductName]                    AS ProductName,
    dc.[FirstName] + ' ' + dc.[LastName]      AS CustomerName,
    dd.[CalendarYear],
    dd.[MonthNumberOfYear]                     AS MonthNumber,
    dd.[EnglishMonthName]                      AS MonthName,
    SUM(fis.[OrderQuantity])                   AS TotalQuantity,
    SUM(fis.[SalesAmount])                     AS TotalSales,
    SUM(fis.[TaxAmt])                          AS TotalTax,
    SUM(fis.[Freight])                         AS TotalFreight,
    SUM(fis.[SalesAmount] - fis.[TotalProductCost]) AS GrossProfit,
    AVG(fis.[UnitPrice])                       AS AvgUnitPrice,
    COUNT(DISTINCT fis.[SalesOrderNumber])     AS OrderCount,
    ISNULL(AVG(fis.[UnitPriceDiscountPct]), 0) AS AvgDiscountPct
FROM [dbo].[FactInternetSales] fis
INNER JOIN [dbo].[DimDate] dd    ON dd.DateKey = fis.OrderDateKey
INNER JOIN [dbo].[DimCustomer] dc ON dc.CustomerKey = fis.CustomerKey
INNER JOIN [dbo].[DimProduct] dp  ON dp.ProductKey = fis.ProductKey
GROUP BY
    fis.ProductKey, dp.EnglishProductName,
    dc.FirstName, dc.LastName,
    dd.CalendarYear, dd.MonthNumberOfYear, dd.EnglishMonthName;

CREATE OR ALTER VIEW [dbo].[vw_customer_ranking] AS
SELECT
    [CustomerKey],
    [FirstName] + ISNULL(' ' + [MiddleName], '') + ' ' + [LastName] AS FullName,
    COALESCE([EnglishOccupation], 'Unknown')                          AS Occupation,
    COALESCE([YearlyIncome], 0)                                       AS YearlyIncome,
    [DateFirstPurchase],
    DATEDIFF(DAY, [DateFirstPurchase], GETDATE())                     AS DaysSinceFirstPurchase,
    CAST([YearlyIncome] AS DECIMAL(15,2))                             AS IncomeDecimal,
    CASE
        WHEN [YearlyIncome] >= 100000 THEN 'High'
        WHEN [YearlyIncome] >= 50000  THEN 'Mid'
        ELSE 'Low'
    END AS IncomeCategory,
    ROW_NUMBER() OVER (ORDER BY [YearlyIncome] DESC)                  AS OverallRank,
    NTILE(4) OVER (ORDER BY ISNULL([YearlyIncome], 0) DESC)           AS IncomeQuartile
FROM [dbo].[DimCustomer]
WHERE [DateFirstPurchase] IS NOT NULL;

CREATE OR ALTER VIEW [dbo].[vw_product_performance] AS
SELECT
    dp.ProductKey,
    dp.EnglishProductName                     AS ProductName,
    dp.Color,
    dp.StandardCost,
    dp.ListPrice,
    dp.ListPrice - dp.StandardCost            AS GrossMargin,
    CASE WHEN dp.StandardCost > 0
         THEN (dp.ListPrice - dp.StandardCost) / dp.StandardCost * 100
         ELSE NULL
    END AS MarginPct,
    SUM(fis.SalesAmount)                      AS TotalRevenue,
    SUM(fis.OrderQuantity)                    AS UnitsSold,
    COUNT(DISTINCT fis.SalesOrderNumber)      AS TransactionCount,
    SUM(fis.SalesAmount) / NULLIF(SUM(fis.OrderQuantity), 0) AS AvgSellingPrice,
    RANK() OVER (ORDER BY SUM(fis.SalesAmount) DESC) AS RevenueRank
FROM [dbo].[DimProduct] dp
LEFT JOIN [dbo].[FactInternetSales] fis ON fis.ProductKey = dp.ProductKey
GROUP BY
    dp.ProductKey, dp.EnglishProductName, dp.Color,
    dp.StandardCost, dp.ListPrice;
