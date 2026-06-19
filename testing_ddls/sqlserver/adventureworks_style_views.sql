-- SQL Server Sample Views (AdventureWorks-style)
-- Tests: T-SQL view syntax, ISNULL, COALESCE, CONVERT, DATEDIFF, DATEADD,
--        window functions, WITH SCHEMABINDING, string functions

CREATE OR ALTER VIEW [Sales].[vIndividualCustomer]
WITH SCHEMABINDING
AS
SELECT
    c.CustomerID,
    p.FirstName,
    p.LastName,
    p.FirstName + N' ' + ISNULL(p.MiddleName + N' ', N'') + p.LastName AS FullName,
    e.EmailAddress,
    ph.PhoneNumber,
    COALESCE(pp.PhoneNumberTypeID, 0) AS PhoneTypeID,
    a.AddressLine1,
    a.AddressLine2,
    a.City,
    sp.[Name]  AS StateProvince,
    a.PostalCode,
    cr.[Name]  AS CountryRegion
FROM [Sales].[Customer] AS c
INNER JOIN [Person].[Person] AS p ON p.BusinessEntityID = c.PersonID
INNER JOIN [Person].[EmailAddress] AS e ON e.BusinessEntityID = p.BusinessEntityID
INNER JOIN [Person].[PersonPhone] AS ph ON ph.BusinessEntityID = p.BusinessEntityID
INNER JOIN [Person].[PhoneNumberType] AS pp ON pp.PhoneNumberTypeID = ph.PhoneNumberTypeID
INNER JOIN [Person].[BusinessEntityAddress] AS bea ON bea.BusinessEntityID = c.PersonID
INNER JOIN [Person].[Address] AS a ON a.AddressID = bea.AddressID
INNER JOIN [Person].[StateProvince] AS sp ON sp.StateProvinceID = a.StateProvinceID
INNER JOIN [Person].[CountryRegion] AS cr ON cr.CountryRegionCode = sp.CountryRegionCode;

CREATE OR ALTER VIEW [Sales].[vSalesPersonSalesByFiscalYears] AS
SELECT
    sp.BusinessEntityID,
    p.FirstName + N' ' + ISNULL(p.MiddleName + N' ', N'') + p.LastName AS FullName,
    e.JobTitle,
    st.Name AS SalesTerritory,
    SUM(CASE WHEN DATEPART(yy, SOH.OrderDate) = DATEPART(yy, GETDATE()) - 2
             THEN SOH.TotalDue ELSE 0 END) AS SalesLastYear,
    SUM(CASE WHEN DATEPART(yy, SOH.OrderDate) = DATEPART(yy, GETDATE()) - 1
             THEN SOH.TotalDue ELSE 0 END) AS SalesThisYear,
    SUM(SOH.TotalDue) AS TotalSales,
    CONVERT(VARCHAR(10), MAX(SOH.OrderDate), 120) AS LastSaleDate,
    DATEDIFF(DAY, MIN(SOH.OrderDate), MAX(SOH.OrderDate)) AS SalesDaysRange,
    ROW_NUMBER() OVER (PARTITION BY st.Name ORDER BY SUM(SOH.TotalDue) DESC) AS TerritoryRank
FROM [Sales].[SalesPerson] AS sp
INNER JOIN [Person].[Person] AS p ON p.BusinessEntityID = sp.BusinessEntityID
INNER JOIN [HumanResources].[Employee] AS e ON e.BusinessEntityID = sp.BusinessEntityID
LEFT OUTER JOIN [Sales].[SalesTerritory] AS st ON st.TerritoryID = sp.TerritoryID
INNER JOIN [Sales].[SalesOrderHeader] AS SOH ON SOH.SalesPersonID = sp.BusinessEntityID
GROUP BY
    sp.BusinessEntityID,
    p.FirstName, p.MiddleName, p.LastName,
    e.JobTitle, st.Name;

CREATE OR ALTER VIEW [Production].[vProductAndDescription] AS
SELECT
    p.[ProductID],
    p.[Name],
    pm.[Name] AS ProductModel,
    pmx.[CultureID],
    pd.[Description],
    CASE
        WHEN p.ListPrice = 0 THEN 'Free'
        WHEN p.ListPrice < 100 THEN 'Low'
        WHEN p.ListPrice < 500 THEN 'Mid'
        ELSE 'Premium'
    END AS PriceCategory,
    CAST(p.ListPrice AS NVARCHAR(20)) + N' USD' AS FormattedPrice,
    DATEADD(YEAR, 2, p.SellStartDate) AS SupportEndDate,
    ISNULL(p.Color, 'No Color') AS ColorDisplay,
    LEN(p.Name) AS NameLength,
    SUBSTRING(p.ProductNumber, 1, 2) AS ProductPrefix
FROM [Production].[Product] p
INNER JOIN [Production].[ProductModel] pm ON pm.ProductModelID = p.ProductModelID
INNER JOIN [Production].[ProductModelProductDescriptionCulture] pmx ON pmx.ProductModelID = pm.ProductModelID
INNER JOIN [Production].[ProductDescription] pd ON pd.ProductDescriptionID = pmx.ProductDescriptionID;
