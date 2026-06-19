-- SQL Server Sample Tables (AdventureWorks-style)
-- Tests: T-SQL specific syntax, IDENTITY, NVARCHAR, DATETIME2, BIT, MONEY,
--        DEFAULT GETDATE(), UNIQUEIDENTIFIER, computed columns

CREATE TABLE [Sales].[SalesOrderHeader] (
    [SalesOrderID]        INT              NOT NULL IDENTITY(1,1),
    [RevisionNumber]      TINYINT          NOT NULL DEFAULT 0,
    [OrderDate]           DATETIME2(7)     NOT NULL DEFAULT GETDATE(),
    [DueDate]             DATETIME2(7)     NOT NULL,
    [ShipDate]            DATETIME2(7)     NULL,
    [Status]              TINYINT          NOT NULL DEFAULT 1,
    [OnlineOrderFlag]     BIT              NOT NULL DEFAULT 1,
    [SalesOrderNumber]    AS (N'SO' + CONVERT(NVARCHAR(23), [SalesOrderID])) PERSISTED,
    [PurchaseOrderNumber] NVARCHAR(25)     NULL,
    [AccountNumber]       NVARCHAR(15)     NULL,
    [CustomerID]          INT              NOT NULL,
    [SalesPersonID]       INT              NULL,
    [TerritoryID]         INT              NULL,
    [BillToAddressID]     INT              NOT NULL,
    [ShipToAddressID]     INT              NOT NULL,
    [ShipMethodID]        INT              NOT NULL,
    [CreditCardID]        INT              NULL,
    [CurrencyRateID]      INT              NULL,
    [SubTotal]            MONEY            NOT NULL DEFAULT 0.00,
    [TaxAmt]              MONEY            NOT NULL DEFAULT 0.00,
    [Freight]             MONEY            NOT NULL DEFAULT 0.00,
    [TotalDue]            AS (ISNULL([SubTotal] + [TaxAmt] + [Freight], 0)) PERSISTED,
    [Comment]             NVARCHAR(128)    NULL,
    [rowguid]             UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    [ModifiedDate]        DATETIME2(7)     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT [PK_SalesOrderHeader_SalesOrderID] PRIMARY KEY CLUSTERED ([SalesOrderID] ASC)
);

CREATE TABLE [Sales].[Customer] (
    [CustomerID]   INT              NOT NULL IDENTITY(1,1),
    [PersonID]     INT              NULL,
    [StoreID]      INT              NULL,
    [TerritoryID]  INT              NULL,
    [AccountNumber] AS (ISNULL(N'AW' + [dbo].[ufnLeadingZeros](CustomerID), N'')) PERSISTED,
    [rowguid]      UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    [ModifiedDate] DATETIME2(7)     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT [PK_Customer_CustomerID] PRIMARY KEY CLUSTERED ([CustomerID] ASC)
);

CREATE TABLE [Production].[Product] (
    [ProductID]            INT            NOT NULL IDENTITY(1,1),
    [Name]                 NVARCHAR(50)   NOT NULL,
    [ProductNumber]        NVARCHAR(25)   NOT NULL,
    [MakeFlag]             BIT            NOT NULL DEFAULT 1,
    [FinishedGoodsFlag]    BIT            NOT NULL DEFAULT 1,
    [Color]                NVARCHAR(15)   NULL,
    [SafetyStockLevel]     SMALLINT       NOT NULL,
    [ReorderPoint]         SMALLINT       NOT NULL,
    [StandardCost]         MONEY          NOT NULL,
    [ListPrice]            MONEY          NOT NULL,
    [Size]                 NVARCHAR(5)    NULL,
    [SizeUnitMeasureCode]  NCHAR(3)       NULL,
    [WeightUnitMeasureCode] NCHAR(3)      NULL,
    [Weight]               DECIMAL(8,2)   NULL,
    [DaysToManufacture]    INT            NOT NULL,
    [ProductLine]          NCHAR(2)       NULL,
    [Class]                NCHAR(2)       NULL,
    [Style]                NCHAR(2)       NULL,
    [ProductSubcategoryID] INT            NULL,
    [ProductModelID]       INT            NULL,
    [SellStartDate]        DATETIME2(7)   NOT NULL,
    [SellEndDate]          DATETIME2(7)   NULL,
    [DiscontinuedDate]     DATETIME2(7)   NULL,
    [rowguid]              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    [ModifiedDate]         DATETIME2(7)   NOT NULL DEFAULT GETDATE(),
    CONSTRAINT [PK_Product_ProductID] PRIMARY KEY CLUSTERED ([ProductID] ASC)
);

CREATE TABLE [HumanResources].[Employee] (
    [BusinessEntityID]  INT            NOT NULL,
    [NationalIDNumber]  NVARCHAR(15)   NOT NULL,
    [LoginID]           NVARCHAR(256)  NOT NULL,
    [OrganizationNode]  HIERARCHYID    NULL,
    [OrganizationLevel] AS ([OrganizationNode].[GetLevel]()) PERSISTED,
    [JobTitle]          NVARCHAR(50)   NOT NULL,
    [BirthDate]         DATE           NOT NULL,
    [MaritalStatus]     NCHAR(1)       NOT NULL,
    [Gender]            NCHAR(1)       NOT NULL,
    [HireDate]          DATE           NOT NULL,
    [SalariedFlag]      BIT            NOT NULL DEFAULT 1,
    [VacationHours]     SMALLINT       NOT NULL DEFAULT 0,
    [SickLeaveHours]    SMALLINT       NOT NULL DEFAULT 0,
    [CurrentFlag]       BIT            NOT NULL DEFAULT 1,
    [rowguid]           UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    [ModifiedDate]      DATETIME2(7)   NOT NULL DEFAULT GETDATE(),
    CONSTRAINT [PK_Employee_BusinessEntityID] PRIMARY KEY CLUSTERED ([BusinessEntityID] ASC)
);
