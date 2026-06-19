-- Azure Synapse Analytics DDL
-- Tests: DISTRIBUTION options (HASH, ROUND_ROBIN, REPLICATE),
--        CLUSTERED COLUMNSTORE INDEX, HEAP, partitioning

CREATE TABLE [dbo].[FactInternetSales] (
    [ProductKey]            INT          NOT NULL,
    [OrderDateKey]          INT          NOT NULL,
    [DueDateKey]            INT          NOT NULL,
    [ShipDateKey]           INT          NOT NULL,
    [CustomerKey]           INT          NOT NULL,
    [PromotionKey]          INT          NOT NULL,
    [CurrencyKey]           INT          NOT NULL,
    [SalesTerritoryKey]     INT          NOT NULL,
    [SalesOrderNumber]      NVARCHAR(20) NOT NULL,
    [SalesOrderLineNumber]  TINYINT      NOT NULL,
    [RevisionNumber]        TINYINT      NOT NULL,
    [OrderQuantity]         SMALLINT     NOT NULL,
    [UnitPrice]             MONEY        NOT NULL,
    [ExtendedAmount]        MONEY        NOT NULL,
    [UnitPriceDiscountPct]  FLOAT        NOT NULL,
    [DiscountAmount]        FLOAT        NOT NULL,
    [ProductStandardCost]   MONEY        NOT NULL,
    [TotalProductCost]      MONEY        NOT NULL,
    [SalesAmount]           MONEY        NOT NULL,
    [TaxAmt]                MONEY        NOT NULL,
    [Freight]               MONEY        NOT NULL,
    [CarrierTrackingNumber] NVARCHAR(25) NULL,
    [CustomerPONumber]      NVARCHAR(25) NULL,
    [OrderDate]             DATETIME     NULL,
    [DueDate]               DATETIME     NULL,
    [ShipDate]              DATETIME     NULL
)
WITH (
    DISTRIBUTION = HASH([ProductKey]),
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE [dbo].[DimCustomer] (
    [CustomerKey]           INT          NOT NULL,
    [GeographyKey]          INT          NULL,
    [CustomerAlternateKey]  NVARCHAR(15) NOT NULL,
    [Title]                 NVARCHAR(8)  NULL,
    [FirstName]             NVARCHAR(50) NULL,
    [MiddleName]            NVARCHAR(50) NULL,
    [LastName]              NVARCHAR(50) NULL,
    [NameStyle]             BIT          NULL,
    [BirthDate]             DATE         NULL,
    [MaritalStatus]         NCHAR(1)     NULL,
    [Suffix]                NVARCHAR(10) NULL,
    [Gender]                NVARCHAR(1)  NULL,
    [EmailAddress]          NVARCHAR(50) NULL,
    [YearlyIncome]          MONEY        NULL,
    [TotalChildren]         TINYINT      NULL,
    [NumberChildrenAtHome]  TINYINT      NULL,
    [EnglishEducation]      NVARCHAR(40) NULL,
    [EnglishOccupation]     NVARCHAR(100) NULL,
    [HouseOwnerFlag]        NCHAR(1)     NULL,
    [NumberCarsOwned]       TINYINT      NULL,
    [AddressLine1]          NVARCHAR(120) NULL,
    [AddressLine2]          NVARCHAR(120) NULL,
    [Phone]                 NVARCHAR(20) NULL,
    [DateFirstPurchase]     DATE         NULL,
    [CommuteDistance]       NVARCHAR(15) NULL
)
WITH (
    DISTRIBUTION = REPLICATE,
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE [dbo].[DimDate] (
    [DateKey]               INT          NOT NULL,
    [FullDateAlternateKey]  DATE         NOT NULL,
    [DayNumberOfWeek]       TINYINT      NOT NULL,
    [EnglishDayNameOfWeek]  NVARCHAR(10) NOT NULL,
    [DayNumberOfMonth]      TINYINT      NOT NULL,
    [DayNumberOfYear]       SMALLINT     NOT NULL,
    [WeekNumberOfYear]      TINYINT      NOT NULL,
    [EnglishMonthName]      NVARCHAR(10) NOT NULL,
    [MonthNumberOfYear]     TINYINT      NOT NULL,
    [CalendarQuarter]       TINYINT      NOT NULL,
    [CalendarYear]          SMALLINT     NOT NULL,
    [CalendarSemester]      TINYINT      NOT NULL,
    [FiscalQuarter]         TINYINT      NOT NULL,
    [FiscalYear]            SMALLINT     NOT NULL,
    [FiscalSemester]        TINYINT      NOT NULL
)
WITH (
    DISTRIBUTION = REPLICATE,
    HEAP
);

CREATE TABLE [dbo].[FactWebActivity] (
    [SessionKey]    BIGINT        NOT NULL,
    [DateKey]       INT           NOT NULL,
    [UserKey]       INT           NULL,
    [ProductKey]    INT           NULL,
    [PageURL]       NVARCHAR(512) NULL,
    [EventType]     NVARCHAR(50)  NOT NULL,
    [EventTS]       DATETIME2(6)  NOT NULL,
    [Duration_ms]   INT           NULL,
    [IsConversion]  BIT           DEFAULT 0,
    [Revenue]       DECIMAL(15,4) NULL
)
WITH (
    DISTRIBUTION = ROUND_ROBIN,
    CLUSTERED COLUMNSTORE INDEX
);
