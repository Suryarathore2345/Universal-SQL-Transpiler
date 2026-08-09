-- ============================================================================
-- Fabric Data Warehouse: Stored Procedures
-- Source: MicrosoftLearning/mslearn-fabric (MIT License)
-- Dialect: Microsoft Fabric Data Warehouse (T-SQL subset)
-- Key constructs: CREATE OR ALTER PROCEDURE, cross-warehouse INSERT,
--                 parameterized procedures, DELETE+INSERT refresh pattern
-- ============================================================================

-- ==========================================================
-- Lab 06a: Cross-warehouse ETL procedure
-- Fabric-specific: Reads from a Lakehouse SQL endpoint via cross-warehouse view
-- ==========================================================

CREATE OR ALTER PROCEDURE Sales.LoadDataFromStaging (@OrderYear INT)
AS
BEGIN
    -- Load data into the Customer dimension table
    INSERT INTO Sales.Dim_Customer (CustomerID, CustomerName, EmailAddress)
    SELECT DISTINCT CustomerName, CustomerName, EmailAddress
    FROM [Sales].[Staging_Sales]
    WHERE YEAR(OrderDate) = @OrderYear
    AND NOT EXISTS (
        SELECT 1
        FROM Sales.Dim_Customer
        WHERE Sales.Dim_Customer.CustomerName = Sales.Staging_Sales.CustomerName
        AND Sales.Dim_Customer.EmailAddress = Sales.Staging_Sales.EmailAddress
    );

    -- Load data into the Item dimension table
    INSERT INTO Sales.Dim_Item (ItemID, ItemName)
    SELECT DISTINCT Item, Item
    FROM [Sales].[Staging_Sales]
    WHERE YEAR(OrderDate) = @OrderYear
    AND NOT EXISTS (
        SELECT 1
        FROM Sales.Dim_Item
        WHERE Sales.Dim_Item.ItemName = Sales.Staging_Sales.Item
    );

    -- Load data into the Sales fact table
    INSERT INTO Sales.Fact_Sales (CustomerID, ItemID, SalesOrderNumber, SalesOrderLineNumber, OrderDate, Quantity, TaxAmount, UnitPrice)
    SELECT CustomerName, Item, SalesOrderNumber, CAST(SalesOrderLineNumber AS INT), CAST(OrderDate AS DATE), CAST(Quantity AS INT), CAST(TaxAmount AS FLOAT), CAST(UnitPrice AS FLOAT)
    FROM [Sales].[Staging_Sales]
    WHERE YEAR(OrderDate) = @OrderYear;
END;
GO

EXEC Sales.LoadDataFromStaging 2021;
GO

-- ==========================================================
-- Lab 06d: Simple stored procedure (security demo)
-- ==========================================================

CREATE PROCEDURE dbo.sp_PrintMessage
AS
PRINT 'Hello World.';
GO

-- ==========================================================
-- Lab 26d: Parameterized monthly refresh procedure
-- Fabric-specific: DELETE + INSERT pattern for incremental refresh
-- ==========================================================

CREATE PROCEDURE gold.usp_refresh_monthly_sales
    @year INT,
    @month INT
AS
BEGIN
    -- Remove existing data for the target period
    DELETE FROM gold.monthly_sales
    WHERE calendar_year = @year AND calendar_month = @month;

    -- Insert fresh aggregated data
    INSERT INTO gold.monthly_sales
        (calendar_year, calendar_month, month_name, category,
         order_count, total_quantity, total_sales)
    SELECT
        d.calendar_year,
        d.calendar_month,
        d.month_name,
        p.category,
        COUNT(*),
        SUM(o.quantity),
        SUM(o.quantity * o.unit_price)
    FROM staging.orders AS o
    INNER JOIN staging.dates AS d
        ON o.order_date = d.calendar_date
    INNER JOIN staging.products AS p
        ON o.product_id = p.product_id
    WHERE o.status = 'Completed'
        AND d.calendar_year = @year
        AND d.calendar_month = @month
    GROUP BY d.calendar_year, d.calendar_month, d.month_name, p.category;
END;
GO

EXEC gold.usp_refresh_monthly_sales @year = 2026, @month = 1;
EXEC gold.usp_refresh_monthly_sales @year = 2026, @month = 2;
EXEC gold.usp_refresh_monthly_sales @year = 2026, @month = 3;
EXEC gold.usp_refresh_monthly_sales @year = 2026, @month = 4;
GO
