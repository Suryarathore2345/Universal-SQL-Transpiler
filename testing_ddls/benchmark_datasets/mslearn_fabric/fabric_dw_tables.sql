-- ============================================================================
-- Fabric Data Warehouse: CREATE TABLE statements
-- Source: MicrosoftLearning/mslearn-fabric (MIT License)
-- Dialect: Microsoft Fabric Data Warehouse (T-SQL subset)
-- Key constructs: PRIMARY KEY NONCLUSTERED NOT ENFORCED, FOREIGN KEY NOT ENFORCED,
--                 BIGINT IDENTITY, schemas (staging/dim/fact/gold), SCD Type 2
-- ============================================================================

-- ==========================================================
-- Lab 06: Basic Data Warehouse (star schema)
-- ==========================================================

CREATE TABLE dbo.DimProduct
(
    ProductKey INTEGER NOT NULL,
    ProductAltKey VARCHAR(25) NULL,
    ProductName VARCHAR(50) NOT NULL,
    Category VARCHAR(50) NULL,
    ListPrice DECIMAL(5,2) NULL
);
GO

CREATE TABLE dbo.DimCustomer
(
    CustomerKey INT NOT NULL,
    CustomerAltKey VARCHAR(50) NULL,
    Title VARCHAR(5) NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NULL,
    AddressLine1 VARCHAR(200) NULL,
    City VARCHAR(50) NULL,
    StateProvince VARCHAR(50) NULL,
    CountryRegion VARCHAR(50) NULL,
    PostalCode VARCHAR(20) NULL
);
GO

CREATE TABLE dbo.DimDate
(
    DateKey INT NOT NULL,
    DateAltKey DATE NOT NULL,
    DayOfWeek INT NOT NULL,
    WeekDayName VARCHAR(10),
    DayOfMonth INT NOT NULL,
    [Month] INT NOT NULL,
    MonthName VARCHAR(12),
    [Year] INT NOT NULL
);
GO

-- ==========================================================
-- Lab 06a: Warehouse Load (cross-warehouse queries, procedures)
-- Fabric-specific: 3-part naming for cross-warehouse references
-- ==========================================================

CREATE SCHEMA [Sales];
GO

CREATE TABLE Sales.Fact_Sales (
    CustomerID VARCHAR(255) NOT NULL,
    ItemID VARCHAR(255) NOT NULL,
    SalesOrderNumber VARCHAR(30),
    SalesOrderLineNumber INT,
    OrderDate DATE,
    Quantity INT,
    TaxAmount FLOAT,
    UnitPrice FLOAT
);

CREATE TABLE Sales.Dim_Customer (
    CustomerID VARCHAR(255) NOT NULL,
    CustomerName VARCHAR(255) NOT NULL,
    EmailAddress VARCHAR(255) NOT NULL
);

-- Fabric DW: PRIMARY KEY NONCLUSTERED ... NOT ENFORCED
ALTER TABLE Sales.Dim_Customer ADD CONSTRAINT PK_Dim_Customer
    PRIMARY KEY NONCLUSTERED (CustomerID) NOT ENFORCED;
GO

CREATE TABLE Sales.Dim_Item (
    ItemID VARCHAR(255) NOT NULL,
    ItemName VARCHAR(255) NOT NULL
);

ALTER TABLE Sales.Dim_Item ADD CONSTRAINT PK_Dim_Item
    PRIMARY KEY NONCLUSTERED (ItemID) NOT ENFORCED;
GO

-- ==========================================================
-- Lab 06d: Security (dynamic data masking, RLS, column security)
-- ==========================================================

CREATE TABLE dbo.Customers
(
    CustomerID INT NOT NULL,
    FirstName varchar(50) MASKED WITH (FUNCTION = 'partial(1,"XXXXXXX",0)') NULL,
    LastName varchar(50) NOT NULL,
    Phone varchar(20) MASKED WITH (FUNCTION = 'default()') NULL,
    Email varchar(50) MASKED WITH (FUNCTION = 'email()') NULL
);

CREATE TABLE dbo.Sales
(
    OrderID INT,
    SalesRep VARCHAR(60),
    Product VARCHAR(10),
    Quantity INT
);

CREATE TABLE dbo.Orders
(
    OrderID INT,
    CustomerID INT,
    CreditCard VARCHAR(20)
);

CREATE TABLE dbo.Parts
(
    PartID INT,
    PartName VARCHAR(25)
);

-- ==========================================================
-- Lab 26: Dimensional Model Design
-- Fabric-specific: PRIMARY KEY NONCLUSTERED NOT ENFORCED,
--                  FOREIGN KEY NOT ENFORCED
-- ==========================================================

CREATE TABLE f_Sales
(
    DateKey INT NOT NULL,
    StoreKey INT NOT NULL,
    ProductKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    SalesAmount DECIMAL(10,2) NOT NULL,
    DiscountAmount DECIMAL(10,2) NOT NULL
);

CREATE TABLE d_Date
(
    DateKey INT NOT NULL,
    FullDate DATE NOT NULL,
    [Year] INT NOT NULL,
    [Quarter] INT NOT NULL,
    [Month] INT NOT NULL,
    MonthName VARCHAR(10) NOT NULL,
    [Day] INT NOT NULL,
    [DayOfWeek] VARCHAR(10) NOT NULL,
    FiscalYear INT NOT NULL,
    FiscalQuarter INT NOT NULL,
    IsHoliday BIT NOT NULL,
    IsWeekday BIT NOT NULL
);

-- SCD Type 2 tracking columns
CREATE TABLE d_Store
(
    StoreKey INT NOT NULL,
    StoreNaturalKey VARCHAR(10) NOT NULL,
    StoreName VARCHAR(50) NOT NULL,
    StoreType VARCHAR(20) NOT NULL,
    City VARCHAR(50) NOT NULL,
    [State] VARCHAR(50) NOT NULL,
    Country VARCHAR(50) NOT NULL,
    Region VARCHAR(50) NOT NULL,
    OpenDate DATE NOT NULL,
    ValidFrom DATE NOT NULL,
    ValidTo DATE NOT NULL,
    IsCurrent BIT NOT NULL
);

-- SCD Type 2 tracking columns
CREATE TABLE d_Product
(
    ProductKey INT NOT NULL,
    ProductNaturalKey VARCHAR(10) NOT NULL,
    ProductName VARCHAR(50) NOT NULL,
    Brand VARCHAR(50) NOT NULL,
    Subcategory VARCHAR(50) NOT NULL,
    Category VARCHAR(50) NOT NULL,
    UnitCost DECIMAL(10,2) NOT NULL,
    ValidFrom DATE NOT NULL,
    ValidTo DATE NOT NULL,
    IsCurrent BIT NOT NULL
);

-- SCD Type 1 only
CREATE TABLE d_Customer
(
    CustomerKey INT NOT NULL,
    CustomerName VARCHAR(50) NOT NULL,
    Segment VARCHAR(20) NOT NULL,
    City VARCHAR(50) NOT NULL,
    [State] VARCHAR(50) NOT NULL,
    Country VARCHAR(50) NOT NULL,
    LoyaltyTier VARCHAR(20) NOT NULL,
    JoinDate DATE NOT NULL
);

-- Fabric DW: NOT ENFORCED constraints
ALTER TABLE d_Date
    ADD CONSTRAINT PK_d_Date PRIMARY KEY NONCLUSTERED (DateKey) NOT ENFORCED;

ALTER TABLE d_Store
    ADD CONSTRAINT PK_d_Store PRIMARY KEY NONCLUSTERED (StoreKey) NOT ENFORCED;

ALTER TABLE d_Product
    ADD CONSTRAINT PK_d_Product PRIMARY KEY NONCLUSTERED (ProductKey) NOT ENFORCED;

ALTER TABLE d_Customer
    ADD CONSTRAINT PK_d_Customer PRIMARY KEY NONCLUSTERED (CustomerKey) NOT ENFORCED;

ALTER TABLE f_Sales
    ADD CONSTRAINT FK_Sales_Date FOREIGN KEY (DateKey)
        REFERENCES d_Date(DateKey) NOT ENFORCED;

ALTER TABLE f_Sales
    ADD CONSTRAINT FK_Sales_Store FOREIGN KEY (StoreKey)
        REFERENCES d_Store(StoreKey) NOT ENFORCED;

ALTER TABLE f_Sales
    ADD CONSTRAINT FK_Sales_Product FOREIGN KEY (ProductKey)
        REFERENCES d_Product(ProductKey) NOT ENFORCED;

ALTER TABLE f_Sales
    ADD CONSTRAINT FK_Sales_Customer FOREIGN KEY (CustomerKey)
        REFERENCES d_Customer(CustomerKey) NOT ENFORCED;

-- ==========================================================
-- Lab 26d: T-SQL Transformations - staging/dim/fact/gold schemas
-- Fabric-specific: BIGINT IDENTITY columns, multi-schema design
-- ==========================================================

CREATE TABLE staging.customers (
    customer_id VARCHAR(20) NOT NULL,
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    region VARCHAR(50)
);

CREATE TABLE staging.products (
    product_id VARCHAR(20) NOT NULL,
    product_name VARCHAR(100),
    category VARCHAR(50),
    unit_price DECIMAL(10,2)
);

CREATE TABLE staging.orders (
    order_id INT NOT NULL,
    customer_id VARCHAR(20),
    product_id VARCHAR(20),
    order_date DATE,
    quantity INT,
    unit_price DECIMAL(10,2),
    discount DECIMAL(10,2),
    status VARCHAR(20)
);

CREATE TABLE staging.dates (
    calendar_date DATE NOT NULL,
    calendar_year INT,
    calendar_month INT,
    month_name VARCHAR(20),
    calendar_quarter INT
);

CREATE TABLE gold.monthly_sales (
    calendar_year INT,
    calendar_month INT,
    month_name VARCHAR(20),
    category VARCHAR(50),
    order_count INT,
    total_quantity INT,
    total_sales DECIMAL(12,2)
);

-- Fabric DW: BIGINT IDENTITY for surrogate keys
CREATE TABLE dim.date (
    date_key BIGINT IDENTITY,
    calendar_date DATE NOT NULL,
    calendar_year INT,
    calendar_month INT,
    month_name VARCHAR(20),
    calendar_quarter INT
);

-- SCD Type 2 dimension with BIGINT IDENTITY
CREATE TABLE dim.customer (
    customer_key BIGINT IDENTITY,
    customer_id VARCHAR(20) NOT NULL,
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    region VARCHAR(50),
    effective_date DATE,
    end_date DATE,
    is_current BIT
);

CREATE TABLE dim.product (
    product_key BIGINT IDENTITY,
    product_id VARCHAR(20) NOT NULL,
    product_name VARCHAR(100),
    category VARCHAR(50),
    unit_price DECIMAL(10,2)
);

CREATE TABLE fact.sales (
    sales_key BIGINT IDENTITY,
    date_key BIGINT NOT NULL,
    customer_key BIGINT NOT NULL,
    product_key BIGINT NOT NULL,
    quantity INT,
    unit_price DECIMAL(10,2),
    sales_amount DECIMAL(12,2)
);

-- ==========================================================
-- Lab 20: Fabric SQL Database (SalesLT schema)
-- ==========================================================

CREATE TABLE SalesLT.PublicHolidays (
    CountryOrRegion NVARCHAR(50),
    HolidayName NVARCHAR(100),
    Date DATE,
    IsPaidTimeOff BIT
);
