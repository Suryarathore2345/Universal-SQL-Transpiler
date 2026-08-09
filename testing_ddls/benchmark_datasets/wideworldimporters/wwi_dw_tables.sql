-- WideWorldImporters DW Database Tables - microsoft/sql-server-samples (MIT License)
-- Source: https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/wide-world-importers/wwi-dw-ssdt


-- File: City.sql
﻿CREATE TABLE [Dimension].[City] (
    [City Key]                   INT               CONSTRAINT [DF_Dimension_City_City_Key] DEFAULT (NEXT VALUE FOR [Sequences].[CityKey]) NOT NULL,
    [WWI City ID]                INT               NOT NULL,
    [City]                       NVARCHAR (50)     NOT NULL,
    [State Province]             NVARCHAR (50)     NOT NULL,
    [Country]                    NVARCHAR (60)     NOT NULL,
    [Continent]                  NVARCHAR (30)     NOT NULL,
    [Sales Territory]            NVARCHAR (50)     NOT NULL,
    [Region]                     NVARCHAR (30)     NOT NULL,
    [Subregion]                  NVARCHAR (30)     NOT NULL,
    [Location]                   [sys].[geography] NULL,
    [Latest Recorded Population] BIGINT            NOT NULL,
    [Valid From]                 DATETIME2 (7)     NOT NULL,
    [Valid To]                   DATETIME2 (7)     NOT NULL,
    [Lineage Key]                INT               NOT NULL,
    CONSTRAINT [PK_Dimension_City] PRIMARY KEY CLUSTERED ([City Key] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Dimension_City_WWICityID]
    ON [Dimension].[City]([WWI City ID] ASC, [Valid From] ASC, [Valid To] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Allows quickly locating by WWI ID', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'City', @level2type = N'INDEX', @level2name = N'IX_Dimension_City_WWICityID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'City dimension', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'City';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'DW key for the city dimension', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'City', @level2type = N'COLUMN', @level2name = N'City Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a city within the WWI database', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'City', @level2type = N'COLUMN', @level2name = N'WWI City ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Formal name of the city', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'City', @level2type = N'COLUMN', @level2name = N'City';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'State or province for this city', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'City', @level2type = N'COLUMN', @level2name = N'State Province';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Country name', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'City', @level2type = N'COLUMN', @level2name = N'Country';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Continent that this city is on', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'City', @level2type = N'COLUMN', @level2name = N'Continent';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Sales territory for this StateProvince', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'City', @level2type = N'COLUMN', @level2name = N'Sales Territory';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Name of the region', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'City', @level2type = N'COLUMN', @level2name = N'Region';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Name of the subregion', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'City', @level2type = N'COLUMN', @level2name = N'Subregion';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Geographic location of the city', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'City', @level2type = N'COLUMN', @level2name = N'Location';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Latest available population for the City', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'City', @level2type = N'COLUMN', @level2name = N'Latest Recorded Population';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Valid from this date and time', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'City', @level2type = N'COLUMN', @level2name = N'Valid From';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Valid until this date and time', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'City', @level2type = N'COLUMN', @level2name = N'Valid To';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Lineage Key for the data load for this row', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'City', @level2type = N'COLUMN', @level2name = N'Lineage Key';


GO

-- File: Customer.sql
﻿CREATE TABLE [Dimension].[Customer] (
    [Customer Key]     INT            CONSTRAINT [DF_Dimension_Customer_Customer_Key] DEFAULT (NEXT VALUE FOR [Sequences].[CustomerKey]) NOT NULL,
    [WWI Customer ID]  INT            NOT NULL,
    [Customer]         NVARCHAR (100) NOT NULL,
    [Bill To Customer] NVARCHAR (100) NOT NULL,
    [Category]         NVARCHAR (50)  NOT NULL,
    [Buying Group]     NVARCHAR (50)  NOT NULL,
    [Primary Contact]  NVARCHAR (50)  NOT NULL,
    [Postal Code]      NVARCHAR (10)  NOT NULL,
    [Valid From]       DATETIME2 (7)  NOT NULL,
    [Valid To]         DATETIME2 (7)  NOT NULL,
    [Lineage Key]      INT            NOT NULL,
    CONSTRAINT [PK_Dimension_Customer] PRIMARY KEY CLUSTERED ([Customer Key] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Dimension_Customer_WWICustomerID]
    ON [Dimension].[Customer]([WWI Customer ID] ASC, [Valid From] ASC, [Valid To] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Allows quickly locating by WWI ID', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Customer', @level2type = N'INDEX', @level2name = N'IX_Dimension_Customer_WWICustomerID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Customer dimension', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Customer';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'DW key for the customer dimension', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Customer', @level2type = N'COLUMN', @level2name = N'Customer Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a customer within the WWI database', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Customer', @level2type = N'COLUMN', @level2name = N'WWI Customer ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer''s full name (usually a trading name)', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Customer', @level2type = N'COLUMN', @level2name = N'Customer';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Bill to customer''s full name', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Customer', @level2type = N'COLUMN', @level2name = N'Bill To Customer';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer''s category', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Customer', @level2type = N'COLUMN', @level2name = N'Category';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer''s buying group', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Customer', @level2type = N'COLUMN', @level2name = N'Buying Group';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Primary contact', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Customer', @level2type = N'COLUMN', @level2name = N'Primary Contact';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Delivery postal code for the customer', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Customer', @level2type = N'COLUMN', @level2name = N'Postal Code';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Valid from this date and time', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Customer', @level2type = N'COLUMN', @level2name = N'Valid From';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Valid until this date and time', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Customer', @level2type = N'COLUMN', @level2name = N'Valid To';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Lineage Key for the data load for this row', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Customer', @level2type = N'COLUMN', @level2name = N'Lineage Key';


GO

-- File: Date.sql
﻿CREATE TABLE [Dimension].[Date] (
    [Date]                                DATE          NOT NULL  -- 2013-01-01
  , [DateKey]                             INT           NOT NULL  -- 20130101
  , [Day Number]                          INT           NOT NULL  -- 1 (to last day of month)
  , [Day]                                 NVARCHAR (10) NOT NULL  -- 1 (to last day of month)
  , [Day of Year]                         NVARCHAR (5)  NOT NULL  -- 1 (to 365)
  , [Day of Year Number]                  INT           NOT NULL  -- 1 (to 365)
  , [Day of Week]                         NVARCHAR (20) NOT NULL  -- Tuesday
  , [Day of Week Number]                  INT           NOT NULL  -- 3
  , [Week of Year]                        NVARCHAR (5)  NOT NULL  -- 1
  , [Month]                               NVARCHAR (10) NOT NULL  -- January
  , [Short Month]                         NVARCHAR (3)  NOT NULL  -- Jan
  , [Quarter]                             NVARCHAR (2)  NOT NULL  -- Q1 (to Q4)
  , [Half of Year]                        NVARCHAR (3)  NOT NULL  -- H1 (or H2)
  , [Beginning of Month]                  DATE          NOT NULL  -- 2013-01-01
  , [Beginning of Quarter]                DATE          NOT NULL  -- 2013-01-01
  , [Beginning of Half Year]              DATE          NOT NULL  -- 2013-01-01
  , [Beginning of Year]                   DATE          NOT NULL  -- 2013-01-01
  , [Beginning of Month Label]            NVARCHAR (40) NOT NULL  -- January 1, 2013
  , [Beginning of Month Label Short]      NVARCHAR (40) NOT NULL  -- Jan 1, 2013
  , [Beginning of Quarter Label]          NVARCHAR (40) NOT NULL  -- January 1, 2013
  , [Beginning of Quarter Label Short]    NVARCHAR (40) NOT NULL  -- Jan 1, 2013
  , [Beginning of Half Year Label]        NVARCHAR (40) NOT NULL  -- January 1, 2013
  , [Beginning of Half Year Label Short]  NVARCHAR (40) NOT NULL  -- Jan 1, 2013
  , [Beginning of Year Label]             NVARCHAR (40) NOT NULL  -- January 1, 2013
  , [Beginning of Year Label Short]       NVARCHAR (40) NOT NULL  -- Jan 1, 2013
  , [Calendar Day Label]                  NVARCHAR (20) NOT NULL  -- January 1, 2013
  , [Calendar Day Label Short]            NVARCHAR (20) NOT NULL  -- Jan 1, 2013
  , [Calendar Week Number]                INT           NOT NULL  -- 1
  , [Calendar Week Label]                 NVARCHAR (20) NOT NULL  -- CY2013-W01
  , [Calendar Month Number]               INT           NOT NULL  -- 1 (to 12)
  , [Calendar Month Label]                NVARCHAR (20) NOT NULL  -- CY2013-Jan
  , [Calendar Month Year Label]           NVARCHAR (20) NOT NULL  -- Jan-2013
  , [Calendar Quarter Number]             INT           NOT NULL  -- 1 (to 4)
  , [Calendar Quarter Label]              NVARCHAR (20) NOT NULL  -- CY2013-Q1
  , [Calendar Quarter Year Label]         NVARCHAR (20) NOT NULL  -- Q1-2013
  , [Calendar Half of Year Number]        INT           NOT NULL  -- 1 (to 2)
  , [Calendar Half of Year Label]         NVARCHAR (20) NOT NULL  -- CY2013-H1
  , [Calendar Year Half of Year Label]    NVARCHAR (20) NOT NULL  -- H1-2013
  , [Calendar Year]                       INT           NOT NULL  -- 2013
  , [Calendar Year Label]                 NVARCHAR (10) NOT NULL  -- CY2013
  , [Fiscal Month Number]                 INT           NOT NULL  -- 3
  , [Fiscal Month Label]                  NVARCHAR (20) NOT NULL  -- FY2013-Jan
  , [Fiscal Quarter Number]               INT           NOT NULL  -- 2
  , [Fiscal Quarter Label]                NVARCHAR (20) NOT NULL  -- FY2013-Q2
  , [Fiscal Half of Year Number]          INT           NOT NULL  -- 1 (to 2)
  , [Fiscal Half of Year Label]           NVARCHAR (20) NOT NULL  -- FY2013-H2
  , [Fiscal Year]                         INT           NOT NULL  -- 2013
  , [Fiscal Year Label]                   NVARCHAR (10) NOT NULL  -- FY2013
  , [Date Key]                            INT           NOT NULL  -- 20130101 (to 20131231)
  , [Year Week Key]                       INT           NOT NULL  -- 201301 (to 201353)
  , [Year Month Key]                      INT           NOT NULL  -- 201301 (to 201312)
  , [Year Quarter Key]                    INT           NOT NULL  -- 20131  (to 20134)
  , [Year Half of Year Key]               INT           NOT NULL  -- 20131  (to 20132)
  , [Year Key]                            INT           NOT NULL  -- 2013
  , [Beginning of Month Key]              INT           NOT NULL  -- 20130101
  , [Beginning of Quarter Key]            INT           NOT NULL  -- 20130101
  , [Beginning of Half Year Key]          INT           NOT NULL  -- 20130101
  , [Beginning of Year Key]               INT           NOT NULL  -- 20130101
  , [Fiscal Year Month Key]               INT           NOT NULL  -- 201301 (to 201312)
  , [Fiscal Year Quarter Key]             INT           NOT NULL  -- 20131 (to 20134)
  , [Fiscal Year Half of Year Key]        INT           NOT NULL  -- 20131 (to 20132)
  , [ISO Week Number]                     INT           NOT NULL  -- 1
    CONSTRAINT [PK_Dimension_Date] PRIMARY KEY CLUSTERED ([Date] ASC)
);
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = N'Date dimension'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'DW key for date dimension (actual date is used for key)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Date';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The date in integer format, can be used as the DW Key if desired'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'DateKey';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Day of the month in integer format (1 to the last day of the month, 28 30 or 31 typically)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Day Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Day of the month in string format (1 to the last day of the month, 28 30 or 31 typically)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Day';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Day number of year (1 to 365) as a string'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Day of Year';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Day number of year (1 to 365) as an integer'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Day of Year Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Day of the week (Monday, Tuesday, etc)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Day of Week';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Numeric day of the week (1=Sunday, etc)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Day of Week Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Week number of the year as a string'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Week of Year';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The full month name (January)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Month';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The abbreviated current month (Jan)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Short Month';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The current quarter as text (Q1, Q2, etc)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Quarter';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The Half of the year (H1, H2)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Half of Year';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The first day of the month in date format'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Month';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The first day of the quarter in date format'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Quarter';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The first date of the current half of year in date format'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Half Year';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The first day of the year in date format'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Year';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'First day of the month as a string (January 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Month Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'First day of the month as a string with the month abbreviated (Jan 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Month Label Short';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'First day of the quarter as a string (January 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Quarter Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'First day of the quarter as a string with the month abbreviated (Jan 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Quarter Label Short';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'First day of the current half of the year as a string (January 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Half Year Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'First day of the current half year as a string with the month abbreviated (Jan 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Half Year Label Short';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'First day of the year as a string (January 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Year Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'First day of the year as a string with the month abbreviated (Jan 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Year Label Short';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Current day of the year as a string (January 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Day Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Current day of the year as a string with abbreviated month (Jan 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Day Label Short';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Week Number of the Year'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Week Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Week of the year as a displayable string (CY2013-W01)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Week Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Month of the year as a number'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Month Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Year and month as a string (CY2013-Jan)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Month Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Alternate format for year month with month first (Jan-2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Month Year Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Quarter number of the year (1 to 4)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Quarter Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Year and Quarter as string (CY2013-Q1)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Quarter Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Alternate form of Year/Quarter with Quarter first (Q1-2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Quarter Year Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Number denoting which half of the year (1 or 2)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Half of Year Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Year and half the year (CY2013-H1)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Half of Year Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Alternate form of half the year label (H1-2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Year Half of Year Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Calendar Year as an integer'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Year';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Calendar Year as a formatted string (CY2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Year Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The Month Number of the Fiscal year'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Month Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Fiscal Year Month formatted as a string (FY2013-Jan)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Month Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The Quarter Number of the Fiscal year (1 to 4)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Quarter Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The Fiscal Year and Quarter as a string (FY2013-Q3)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Quarter Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The Fiscal Half of Year as a number (1 or 2)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Half of Year Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The Fiscal Half of Year as a formatted string (FY2013-H2)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Half of Year Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The Fiscal Year as a number (2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Year';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The Fiscal Year as a formatted string (FY2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Year Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current date (20130101 to 20131231)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Date Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current year-week (201301 to 201353)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Year Week Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current year-month (201301 to 201312)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Year Month Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current year-quarter (20131 to 20134)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Year Quarter Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current year-half of year (20131 to 20132)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Year Half of Year Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current year (2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Year Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current beginning of the month (20130101)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Month Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current beginning of quarter (20130101)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Quarter Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current beginning of the half year (20130101)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Half Year Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current beginning of the year (20130101)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Year Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current fiscal year month (201301 to 201312)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Year Month Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current fiscal year quarter (20131 to 20134)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Year Quarter Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current fiscal year half of year (20131 to 20132)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Year Half of Year Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The ISO Week Number'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'ISO Week Number';
GO



GO

-- File: Employee.sql
﻿CREATE TABLE [Dimension].[Employee] (
    [Employee Key]    INT             CONSTRAINT [DF_Dimension_Employee_Employee_Key] DEFAULT (NEXT VALUE FOR [Sequences].[EmployeeKey]) NOT NULL,
    [WWI Employee ID] INT             NOT NULL,
    [Employee]        NVARCHAR (50)   NOT NULL,
    [Preferred Name]  NVARCHAR (50)   NOT NULL,
    [Is Salesperson]  BIT             NOT NULL,
    [Photo]           VARBINARY (MAX) NULL,
    [Valid From]      DATETIME2 (7)   NOT NULL,
    [Valid To]        DATETIME2 (7)   NOT NULL,
    [Lineage Key]     INT             NOT NULL,
    CONSTRAINT [PK_Dimension_Employee] PRIMARY KEY CLUSTERED ([Employee Key] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Dimension_Employee_WWIEmployeeID]
    ON [Dimension].[Employee]([WWI Employee ID] ASC, [Valid From] ASC, [Valid To] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Allows quickly locating by WWI ID', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Employee', @level2type = N'INDEX', @level2name = N'IX_Dimension_Employee_WWIEmployeeID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Employee dimension', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Employee';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'DW key for the employee dimension', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Employee', @level2type = N'COLUMN', @level2name = N'Employee Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID (PersonID) in the WWI database', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Employee', @level2type = N'COLUMN', @level2name = N'WWI Employee ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Full name for this person', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Employee', @level2type = N'COLUMN', @level2name = N'Employee';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Name that this person prefers to be called', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Employee', @level2type = N'COLUMN', @level2name = N'Preferred Name';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Is this person a staff salesperson?', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Employee', @level2type = N'COLUMN', @level2name = N'Is Salesperson';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Photo of this person', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Employee', @level2type = N'COLUMN', @level2name = N'Photo';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Valid from this date and time', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Employee', @level2type = N'COLUMN', @level2name = N'Valid From';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Valid until this date and time', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Employee', @level2type = N'COLUMN', @level2name = N'Valid To';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Lineage Key for the data load for this row', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Employee', @level2type = N'COLUMN', @level2name = N'Lineage Key';


GO

-- File: Payment Method.sql
﻿CREATE TABLE [Dimension].[Payment Method] (
    [Payment Method Key]    INT           CONSTRAINT [DF_Dimension_Payment_Method_Payment_Method_Key] DEFAULT (NEXT VALUE FOR [Sequences].[PaymentMethodKey]) NOT NULL,
    [WWI Payment Method ID] INT           NOT NULL,
    [Payment Method]        NVARCHAR (50) NOT NULL,
    [Valid From]            DATETIME2 (7) NOT NULL,
    [Valid To]              DATETIME2 (7) NOT NULL,
    [Lineage Key]           INT           NOT NULL,
    CONSTRAINT [PK_Dimension_Payment_Method] PRIMARY KEY CLUSTERED ([Payment Method Key] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Dimension_Payment_Method_WWIPaymentMethodID]
    ON [Dimension].[Payment Method]([WWI Payment Method ID] ASC, [Valid From] ASC, [Valid To] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Allows quickly locating by WWI ID', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Payment Method', @level2type = N'INDEX', @level2name = N'IX_Dimension_Payment_Method_WWIPaymentMethodID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'PaymentMethod dimension', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Payment Method';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'DW key for the payment method dimension', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Payment Method', @level2type = N'COLUMN', @level2name = N'Payment Method Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID for the payment method in the WWI database', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Payment Method', @level2type = N'COLUMN', @level2name = N'WWI Payment Method ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Payment method name', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Payment Method', @level2type = N'COLUMN', @level2name = N'Payment Method';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Valid from this date and time', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Payment Method', @level2type = N'COLUMN', @level2name = N'Valid From';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Valid until this date and time', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Payment Method', @level2type = N'COLUMN', @level2name = N'Valid To';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Lineage Key for the data load for this row', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Payment Method', @level2type = N'COLUMN', @level2name = N'Lineage Key';


GO

-- File: Stock Item.sql
﻿CREATE TABLE [Dimension].[Stock Item] (
    [Stock Item Key]           INT             CONSTRAINT [DF_Dimension_Stock_Item_Stock_Item_Key] DEFAULT (NEXT VALUE FOR [Sequences].[StockItemKey]) NOT NULL,
    [WWI Stock Item ID]        INT             NOT NULL,
    [Stock Item]               NVARCHAR (100)  NOT NULL,
    [Color]                    NVARCHAR (20)   NOT NULL,
    [Selling Package]          NVARCHAR (50)   NOT NULL,
    [Buying Package]           NVARCHAR (50)   NOT NULL,
    [Brand]                    NVARCHAR (50)   NOT NULL,
    [Size]                     NVARCHAR (20)   NOT NULL,
    [Lead Time Days]           INT             NOT NULL,
    [Quantity Per Outer]       INT             NOT NULL,
    [Is Chiller Stock]         BIT             NOT NULL,
    [Barcode]                  NVARCHAR (50)   NULL,
    [Tax Rate]                 DECIMAL (18, 3) NOT NULL,
    [Unit Price]               DECIMAL (18, 2) NOT NULL,
    [Recommended Retail Price] DECIMAL (18, 2) NULL,
    [Typical Weight Per Unit]  DECIMAL (18, 3) NOT NULL,
    [Photo]                    VARBINARY (MAX) NULL,
    [Valid From]               DATETIME2 (7)   NOT NULL,
    [Valid To]                 DATETIME2 (7)   NOT NULL,
    [Lineage Key]              INT             NOT NULL,
    CONSTRAINT [PK_Dimension_Stock_Item] PRIMARY KEY CLUSTERED ([Stock Item Key] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Dimension_Stock_Item_WWIStockItemID]
    ON [Dimension].[Stock Item]([WWI Stock Item ID] ASC, [Valid From] ASC, [Valid To] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Allows quickly locating by WWI ID', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'INDEX', @level2name = N'IX_Dimension_Stock_Item_WWIStockItemID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'StockItem dimension', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'DW key for the stock item dimension', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'Stock Item Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a stock item within the WWI database', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'WWI Stock Item ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Full name of a stock item (but not a full description)', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'Stock Item';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Color (optional) for this stock item', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'Color';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Usual package for selling units of this stock item', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'Selling Package';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Usual package for selling outers of this stock item (ie cartons, boxes, etc.)', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'Buying Package';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Brand for the stock item (if the item is branded)', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'Brand';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Size of this item (eg: 100mm)', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'Size';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Number of days typically taken from order to receipt of this stock item', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'Lead Time Days';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity of the stock item in an outer package', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'Quantity Per Outer';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Does this stock item need to be in a chiller?', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'Is Chiller Stock';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Barcode for this stock item', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'Barcode';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Tax rate to be applied', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'Tax Rate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Selling price (ex-tax) for one unit of this product', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'Unit Price';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Recommended retail price for this stock item', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'Recommended Retail Price';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Typical weight for one unit of this product (packaged)', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'Typical Weight Per Unit';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Photo of the product', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'Photo';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Valid from this date and time', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'Valid From';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Valid until this date and time', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'Valid To';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Lineage Key for the data load for this row', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Stock Item', @level2type = N'COLUMN', @level2name = N'Lineage Key';


GO

-- File: Supplier.sql
﻿CREATE TABLE [Dimension].[Supplier] (
    [Supplier Key]       INT            CONSTRAINT [DF_Dimension_Supplier_Supplier_Key] DEFAULT (NEXT VALUE FOR [Sequences].[SupplierKey]) NOT NULL,
    [WWI Supplier ID]    INT            NOT NULL,
    [Supplier]           NVARCHAR (100) NOT NULL,
    [Category]           NVARCHAR (50)  NOT NULL,
    [Primary Contact]    NVARCHAR (50)  NOT NULL,
    [Supplier Reference] NVARCHAR (20)  NULL,
    [Payment Days]       INT            NOT NULL,
    [Postal Code]        NVARCHAR (10)  NOT NULL,
    [Valid From]         DATETIME2 (7)  NOT NULL,
    [Valid To]           DATETIME2 (7)  NOT NULL,
    [Lineage Key]        INT            NOT NULL,
    CONSTRAINT [PK_Dimension_Supplier] PRIMARY KEY CLUSTERED ([Supplier Key] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Dimension_Supplier_WWISupplierID]
    ON [Dimension].[Supplier]([WWI Supplier ID] ASC, [Valid From] ASC, [Valid To] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Allows quickly locating by WWI ID', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Supplier', @level2type = N'INDEX', @level2name = N'IX_Dimension_Supplier_WWISupplierID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Supplier dimension', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Supplier';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'DW key for the supplier dimension', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Supplier', @level2type = N'COLUMN', @level2name = N'Supplier Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a supplier within the WWI database', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Supplier', @level2type = N'COLUMN', @level2name = N'WWI Supplier ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier''s full name (usually a trading name)', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Supplier', @level2type = N'COLUMN', @level2name = N'Supplier';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier''s category', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Supplier', @level2type = N'COLUMN', @level2name = N'Category';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Primary contact', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Supplier', @level2type = N'COLUMN', @level2name = N'Primary Contact';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier reference for our organization (might be our account number at the supplier)', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Supplier', @level2type = N'COLUMN', @level2name = N'Supplier Reference';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Number of days for payment of an invoice (ie payment terms)', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Supplier', @level2type = N'COLUMN', @level2name = N'Payment Days';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Delivery postal code for the supplier', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Supplier', @level2type = N'COLUMN', @level2name = N'Postal Code';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Valid from this date and time', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Supplier', @level2type = N'COLUMN', @level2name = N'Valid From';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Valid until this date and time', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Supplier', @level2type = N'COLUMN', @level2name = N'Valid To';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Lineage Key for the data load for this row', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Supplier', @level2type = N'COLUMN', @level2name = N'Lineage Key';


GO

-- File: Transaction Type.sql
﻿CREATE TABLE [Dimension].[Transaction Type] (
    [Transaction Type Key]    INT           CONSTRAINT [DF_Dimension_Transaction_Type_Transaction_Type_Key] DEFAULT (NEXT VALUE FOR [Sequences].[TransactionTypeKey]) NOT NULL,
    [WWI Transaction Type ID] INT           NOT NULL,
    [Transaction Type]        NVARCHAR (50) NOT NULL,
    [Valid From]              DATETIME2 (7) NOT NULL,
    [Valid To]                DATETIME2 (7) NOT NULL,
    [Lineage Key]             INT           NOT NULL,
    CONSTRAINT [PK_Dimension_Transaction_Type] PRIMARY KEY CLUSTERED ([Transaction Type Key] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Dimension_Transaction_Type_WWITransactionTypeID]
    ON [Dimension].[Transaction Type]([WWI Transaction Type ID] ASC, [Valid From] ASC, [Valid To] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Allows quickly locating by WWI ID', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Transaction Type', @level2type = N'INDEX', @level2name = N'IX_Dimension_Transaction_Type_WWITransactionTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'TransactionType dimension', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Transaction Type';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'DW key for the transaction type dimension', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Transaction Type', @level2type = N'COLUMN', @level2name = N'Transaction Type Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a transaction type within the WWI database', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Transaction Type', @level2type = N'COLUMN', @level2name = N'WWI Transaction Type ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Full name of the transaction type', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Transaction Type', @level2type = N'COLUMN', @level2name = N'Transaction Type';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Valid from this date and time', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Transaction Type', @level2type = N'COLUMN', @level2name = N'Valid From';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Valid until this date and time', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Transaction Type', @level2type = N'COLUMN', @level2name = N'Valid To';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Lineage Key for the data load for this row', @level0type = N'SCHEMA', @level0name = N'Dimension', @level1type = N'TABLE', @level1name = N'Transaction Type', @level2type = N'COLUMN', @level2name = N'Lineage Key';


GO

-- File: Movement.sql
﻿CREATE TABLE [Fact].[Movement] (
    [Movement Key]                  BIGINT IDENTITY (1, 1) NOT NULL,
    [Date Key]                      DATE   NOT NULL,
    [Stock Item Key]                INT    NOT NULL,
    [Customer Key]                  INT    NULL,
    [Supplier Key]                  INT    NULL,
    [Transaction Type Key]          INT    NOT NULL,
    [WWI Stock Item Transaction ID] INT    NOT NULL,
    [WWI Invoice ID]                INT    NULL,
    [WWI Purchase Order ID]         INT    NULL,
    [Quantity]                      INT    NOT NULL,
    [Lineage Key]                   INT    NOT NULL,
    CONSTRAINT [PK_Fact_Movement] PRIMARY KEY NONCLUSTERED ([Movement Key] ASC, [Date Key] ASC) ON [PS_Date] ([Date Key]),
    CONSTRAINT [FK_Fact_Movement_Customer_Key_Dimension_Customer] FOREIGN KEY ([Customer Key]) REFERENCES [Dimension].[Customer] ([Customer Key]),
    CONSTRAINT [FK_Fact_Movement_Date_Key_Dimension_Date] FOREIGN KEY ([Date Key]) REFERENCES [Dimension].[Date] ([Date]),
    CONSTRAINT [FK_Fact_Movement_Stock_Item_Key_Dimension_Stock Item] FOREIGN KEY ([Stock Item Key]) REFERENCES [Dimension].[Stock Item] ([Stock Item Key]),
    CONSTRAINT [FK_Fact_Movement_Supplier_Key_Dimension_Supplier] FOREIGN KEY ([Supplier Key]) REFERENCES [Dimension].[Supplier] ([Supplier Key]),
    CONSTRAINT [FK_Fact_Movement_Transaction_Type_Key_Dimension_Transaction Type] FOREIGN KEY ([Transaction Type Key]) REFERENCES [Dimension].[Transaction Type] ([Transaction Type Key])
);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Movement_Customer_Key]
    ON [Fact].[Movement]([Customer Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Movement_Date_Key]
    ON [Fact].[Movement]([Date Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Movement_Stock_Item_Key]
    ON [Fact].[Movement]([Stock Item Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Movement_Supplier_Key]
    ON [Fact].[Movement]([Supplier Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Movement_Transaction_Type_Key]
    ON [Fact].[Movement]([Transaction Type Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE NONCLUSTERED INDEX [IX_Integration_Movement_WWI_Stock_Item_Transaction_ID]
    ON [Fact].[Movement]([WWI Stock Item Transaction ID] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE CLUSTERED COLUMNSTORE INDEX [CCX_Fact_Movement]
    ON [Fact].[Movement]
    ON [PS_Date] ([Date Key]);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Movement fact table (movements of stock items)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'DW key for a row in the Movement fact', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'Movement Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Transaction date', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'Date Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Stock item for this purchase order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'Stock Item Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer (if applicable)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'Customer Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier (if applicable)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'Supplier Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Type of transaction', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'Transaction Type Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Stock item transaction ID in source system', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'WWI Stock Item Transaction ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Invoice ID in source system', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'WWI Invoice ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Purchase order ID in source system', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'WWI Purchase Order ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity of stock movement (positive is incoming stock, negative is outgoing)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'Quantity';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Lineage Key for the data load for this row', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Movement', @level2type = N'COLUMN', @level2name = N'Lineage Key';


GO

-- File: Order.sql
﻿CREATE TABLE [Fact].[Order] (
    [Order Key]           BIGINT          IDENTITY (1, 1) NOT NULL,
    [City Key]            INT             NOT NULL,
    [Customer Key]        INT             NOT NULL,
    [Stock Item Key]      INT             NOT NULL,
    [Order Date Key]      DATE            NOT NULL,
    [Picked Date Key]     DATE            NULL,
    [Salesperson Key]     INT             NOT NULL,
    [Picker Key]          INT             NULL,
    [WWI Order ID]        INT             NOT NULL,
    [WWI Backorder ID]    INT             NULL,
    [Description]         NVARCHAR (100)  NOT NULL,
    [Package]             NVARCHAR (50)   NOT NULL,
    [Quantity]            INT             NOT NULL,
    [Unit Price]          DECIMAL (18, 2) NOT NULL,
    [Tax Rate]            DECIMAL (18, 3) NOT NULL,
    [Total Excluding Tax] DECIMAL (18, 2) NOT NULL,
    [Tax Amount]          DECIMAL (18, 2) NOT NULL,
    [Total Including Tax] DECIMAL (18, 2) NOT NULL,
    [Lineage Key]         INT             NOT NULL,
    CONSTRAINT [PK_Fact_Order] PRIMARY KEY NONCLUSTERED ([Order Key] ASC, [Order Date Key] ASC) ON [PS_Date] ([Order Date Key]),
    CONSTRAINT [FK_Fact_Order_City_Key_Dimension_City] FOREIGN KEY ([City Key]) REFERENCES [Dimension].[City] ([City Key]),
    CONSTRAINT [FK_Fact_Order_Customer_Key_Dimension_Customer] FOREIGN KEY ([Customer Key]) REFERENCES [Dimension].[Customer] ([Customer Key]),
    CONSTRAINT [FK_Fact_Order_Order_Date_Key_Dimension_Date] FOREIGN KEY ([Order Date Key]) REFERENCES [Dimension].[Date] ([Date]),
    CONSTRAINT [FK_Fact_Order_Picked_Date_Key_Dimension_Date] FOREIGN KEY ([Picked Date Key]) REFERENCES [Dimension].[Date] ([Date]),
    CONSTRAINT [FK_Fact_Order_Picker_Key_Dimension_Employee] FOREIGN KEY ([Picker Key]) REFERENCES [Dimension].[Employee] ([Employee Key]),
    CONSTRAINT [FK_Fact_Order_Salesperson_Key_Dimension_Employee] FOREIGN KEY ([Salesperson Key]) REFERENCES [Dimension].[Employee] ([Employee Key]),
    CONSTRAINT [FK_Fact_Order_Stock_Item_Key_Dimension_Stock Item] FOREIGN KEY ([Stock Item Key]) REFERENCES [Dimension].[Stock Item] ([Stock Item Key])
);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Order_City_Key]
    ON [Fact].[Order]([City Key] ASC)
    ON [PS_Date] ([Order Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Order_Customer_Key]
    ON [Fact].[Order]([Customer Key] ASC)
    ON [PS_Date] ([Order Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Order_Order_Date_Key]
    ON [Fact].[Order]([Order Date Key] ASC)
    ON [PS_Date] ([Order Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Order_Picked_Date_Key]
    ON [Fact].[Order]([Picked Date Key] ASC)
    ON [PS_Date] ([Order Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Order_Picker_Key]
    ON [Fact].[Order]([Picker Key] ASC)
    ON [PS_Date] ([Order Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Order_Salesperson_Key]
    ON [Fact].[Order]([Salesperson Key] ASC)
    ON [PS_Date] ([Order Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Order_Stock_Item_Key]
    ON [Fact].[Order]([Stock Item Key] ASC)
    ON [PS_Date] ([Order Date Key]);


GO
CREATE NONCLUSTERED INDEX [IX_Integration_Order_WWI_Order_ID]
    ON [Fact].[Order]([WWI Order ID] ASC)
    ON [PS_Date] ([Order Date Key]);


GO
CREATE CLUSTERED COLUMNSTORE INDEX [CCX_Fact_Order]
    ON [Fact].[Order]
    ON [PS_Date] ([Order Date Key]);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Order fact table (customer orders)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'DW key for a row in the Order fact', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Order Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'City for this order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'City Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer for this order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Customer Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Stock item for this order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Stock Item Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Order date for this order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Order Date Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Picked date for this order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Picked Date Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Salesperson for this order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Salesperson Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Picker for this order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Picker Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'OrderID in source system', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'WWI Order ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'BackorderID in source system', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'WWI Backorder ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Description of the item supplied (Usually the stock item name but can be overridden)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Description';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Type of package to be supplied', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Package';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity to be supplied', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Quantity';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Unit price to be charged', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Unit Price';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Tax rate to be applied', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Tax Rate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total amount excluding tax', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Total Excluding Tax';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total amount of tax', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Tax Amount';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total amount including tax', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Total Including Tax';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Lineage Key for the data load for this row', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Order', @level2type = N'COLUMN', @level2name = N'Lineage Key';


GO

-- File: Purchase.sql
﻿CREATE TABLE [Fact].[Purchase] (
    [Purchase Key]          BIGINT        IDENTITY (1, 1) NOT NULL,
    [Date Key]              DATE          NOT NULL,
    [Supplier Key]          INT           NOT NULL,
    [Stock Item Key]        INT           NOT NULL,
    [WWI Purchase Order ID] INT           NULL,
    [Ordered Outers]        INT           NOT NULL,
    [Ordered Quantity]      INT           NOT NULL,
    [Received Outers]       INT           NOT NULL,
    [Package]               NVARCHAR (50) NOT NULL,
    [Is Order Finalized]    BIT           NOT NULL,
    [Lineage Key]           INT           NOT NULL,
    CONSTRAINT [PK_Fact_Purchase] PRIMARY KEY NONCLUSTERED ([Purchase Key] ASC, [Date Key] ASC) ON [PS_Date] ([Date Key]),
    CONSTRAINT [FK_Fact_Purchase_Date_Key_Dimension_Date] FOREIGN KEY ([Date Key]) REFERENCES [Dimension].[Date] ([Date]),
    CONSTRAINT [FK_Fact_Purchase_Stock_Item_Key_Dimension_Stock Item] FOREIGN KEY ([Stock Item Key]) REFERENCES [Dimension].[Stock Item] ([Stock Item Key]),
    CONSTRAINT [FK_Fact_Purchase_Supplier_Key_Dimension_Supplier] FOREIGN KEY ([Supplier Key]) REFERENCES [Dimension].[Supplier] ([Supplier Key])
);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Purchase_Date_Key]
    ON [Fact].[Purchase]([Date Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Purchase_Stock_Item_Key]
    ON [Fact].[Purchase]([Stock Item Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Purchase_Supplier_Key]
    ON [Fact].[Purchase]([Supplier Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE CLUSTERED COLUMNSTORE INDEX [CCX_Fact_Purchase]
    ON [Fact].[Purchase]
    ON [PS_Date] ([Date Key]);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Purchase fact table (stock purchases from suppliers)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'DW key for a row in the Purchase fact', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Purchase Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Purchase order date', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Date Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier for this purchase order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Supplier Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Stock item for this purchase order', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Stock Item Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Purchase order ID in source system ', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'WWI Purchase Order ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity of outers (ordering packages)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Ordered Outers';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity of inners (selling packages)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Ordered Quantity';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Received outers (so far)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Received Outers';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Package ordered', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Package';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Is this purchase order now finalized?', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Is Order Finalized';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Lineage Key for the data load for this row', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Purchase', @level2type = N'COLUMN', @level2name = N'Lineage Key';


GO

-- File: Sale.sql
﻿CREATE TABLE [Fact].[Sale] (
    [Sale Key]             BIGINT          IDENTITY (1, 1) NOT NULL,
    [City Key]             INT             NOT NULL,
    [Customer Key]         INT             NOT NULL,
    [Bill To Customer Key] INT             NOT NULL,
    [Stock Item Key]       INT             NOT NULL,
    [Invoice Date Key]     DATE            NOT NULL,
    [Delivery Date Key]    DATE            NULL,
    [Salesperson Key]      INT             NOT NULL,
    [WWI Invoice ID]       INT             NOT NULL,
    [Description]          NVARCHAR (100)  NOT NULL,
    [Package]              NVARCHAR (50)   NOT NULL,
    [Quantity]             INT             NOT NULL,
    [Unit Price]           DECIMAL (18, 2) NOT NULL,
    [Tax Rate]             DECIMAL (18, 3) NOT NULL,
    [Total Excluding Tax]  DECIMAL (18, 2) NOT NULL,
    [Tax Amount]           DECIMAL (18, 2) NOT NULL,
    [Profit]               DECIMAL (18, 2) NOT NULL,
    [Total Including Tax]  DECIMAL (18, 2) NOT NULL,
    [Total Dry Items]      INT             NOT NULL,
    [Total Chiller Items]  INT             NOT NULL,
    [Lineage Key]          INT             NOT NULL,
    CONSTRAINT [PK_Fact_Sale] PRIMARY KEY NONCLUSTERED ([Sale Key] ASC, [Invoice Date Key] ASC) ON [PS_Date] ([Invoice Date Key]),
    CONSTRAINT [FK_Fact_Sale_Bill_To_Customer_Key_Dimension_Customer] FOREIGN KEY ([Bill To Customer Key]) REFERENCES [Dimension].[Customer] ([Customer Key]),
    CONSTRAINT [FK_Fact_Sale_City_Key_Dimension_City] FOREIGN KEY ([City Key]) REFERENCES [Dimension].[City] ([City Key]),
    CONSTRAINT [FK_Fact_Sale_Customer_Key_Dimension_Customer] FOREIGN KEY ([Customer Key]) REFERENCES [Dimension].[Customer] ([Customer Key]),
    CONSTRAINT [FK_Fact_Sale_Delivery_Date_Key_Dimension_Date] FOREIGN KEY ([Delivery Date Key]) REFERENCES [Dimension].[Date] ([Date]),
    CONSTRAINT [FK_Fact_Sale_Invoice_Date_Key_Dimension_Date] FOREIGN KEY ([Invoice Date Key]) REFERENCES [Dimension].[Date] ([Date]),
    CONSTRAINT [FK_Fact_Sale_Salesperson_Key_Dimension_Employee] FOREIGN KEY ([Salesperson Key]) REFERENCES [Dimension].[Employee] ([Employee Key]),
    CONSTRAINT [FK_Fact_Sale_Stock_Item_Key_Dimension_Stock Item] FOREIGN KEY ([Stock Item Key]) REFERENCES [Dimension].[Stock Item] ([Stock Item Key])
);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Sale_Bill_To_Customer_Key]
    ON [Fact].[Sale]([Bill To Customer Key] ASC)
    ON [PS_Date] ([Invoice Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Sale_City_Key]
    ON [Fact].[Sale]([City Key] ASC)
    ON [PS_Date] ([Invoice Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Sale_Customer_Key]
    ON [Fact].[Sale]([Customer Key] ASC)
    ON [PS_Date] ([Invoice Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Sale_Delivery_Date_Key]
    ON [Fact].[Sale]([Delivery Date Key] ASC)
    ON [PS_Date] ([Invoice Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Sale_Invoice_Date_Key]
    ON [Fact].[Sale]([Invoice Date Key] ASC)
    ON [PS_Date] ([Invoice Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Sale_Salesperson_Key]
    ON [Fact].[Sale]([Salesperson Key] ASC)
    ON [PS_Date] ([Invoice Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Sale_Stock_Item_Key]
    ON [Fact].[Sale]([Stock Item Key] ASC)
    ON [PS_Date] ([Invoice Date Key]);


GO
CREATE CLUSTERED COLUMNSTORE INDEX [CCX_Fact_Sale]
    ON [Fact].[Sale]
    ON [PS_Date] ([Invoice Date Key]);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Sale fact table (invoiced sales to customers)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'DW key for a row in the Sale fact', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Sale Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'City for this invoice', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'City Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer for this invoice', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Customer Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Bill To Customer for this invoice', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Bill To Customer Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Stock item for this invoice', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Stock Item Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Invoice date for this invoice', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Invoice Date Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Date that these items were delivered', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Delivery Date Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Salesperson for this invoice', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Salesperson Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'InvoiceID in source system', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'WWI Invoice ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Description of the item supplied (Usually the stock item name but can be overridden)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Description';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Type of package supplied', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Package';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity supplied', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Quantity';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Unit price charged', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Unit Price';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Tax rate applied', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Tax Rate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total amount excluding tax', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Total Excluding Tax';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total amount of tax', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Tax Amount';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total amount of profit', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Profit';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total amount including tax', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Total Including Tax';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total number of dry items', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Total Dry Items';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total number of chiller items', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Total Chiller Items';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Lineage Key for the data load for this row', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Sale', @level2type = N'COLUMN', @level2name = N'Lineage Key';


GO

-- File: Stock Holding.sql
﻿CREATE TABLE [Fact].[Stock Holding] (
    [Stock Holding Key]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [Stock Item Key]          INT             NOT NULL,
    [Quantity On Hand]        INT             NOT NULL,
    [Bin Location]            NVARCHAR (20)   NOT NULL,
    [Last Stocktake Quantity] INT             NOT NULL,
    [Last Cost Price]         DECIMAL (18, 2) NOT NULL,
    [Reorder Level]           INT             NOT NULL,
    [Target Stock Level]      INT             NOT NULL,
    [Lineage Key]             INT             NOT NULL,
    CONSTRAINT [PK_Fact_Stock_Holding] PRIMARY KEY NONCLUSTERED ([Stock Holding Key] ASC),
    CONSTRAINT [FK_Fact_Stock_Holding_Stock_Item_Key_Dimension_Stock Item] FOREIGN KEY ([Stock Item Key]) REFERENCES [Dimension].[Stock Item] ([Stock Item Key])
);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Stock_Holding_Stock_Item_Key]
    ON [Fact].[Stock Holding]([Stock Item Key] ASC);


GO
CREATE CLUSTERED COLUMNSTORE INDEX [CCX_Fact_Stock_Holding]
    ON [Fact].[Stock Holding];


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'INDEX', @level2name = N'FK_Fact_Stock_Holding_Stock_Item_Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Holdings of stock items', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'DW key for a row in the Stock Holding fact', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'COLUMN', @level2name = N'Stock Holding Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Stock item being held', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'COLUMN', @level2name = N'Stock Item Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity on hand', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'COLUMN', @level2name = N'Quantity On Hand';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Bin location (where is this stock in the warehouse)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'COLUMN', @level2name = N'Bin Location';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity present at last stocktake', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'COLUMN', @level2name = N'Last Stocktake Quantity';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Unit cost when the stock item was last purchased', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'COLUMN', @level2name = N'Last Cost Price';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity below which reordering should take place', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'COLUMN', @level2name = N'Reorder Level';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Typical stock level held', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'COLUMN', @level2name = N'Target Stock Level';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Lineage Key for the data load for this row', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Stock Holding', @level2type = N'COLUMN', @level2name = N'Lineage Key';


GO

-- File: Transaction.sql
﻿CREATE TABLE [Fact].[Transaction] (
    [Transaction Key]             BIGINT          IDENTITY (1, 1) NOT NULL,
    [Date Key]                    DATE            NOT NULL,
    [Customer Key]                INT             NULL,
    [Bill To Customer Key]        INT             NULL,
    [Supplier Key]                INT             NULL,
    [Transaction Type Key]        INT             NOT NULL,
    [Payment Method Key]          INT             NULL,
    [WWI Customer Transaction ID] INT             NULL,
    [WWI Supplier Transaction ID] INT             NULL,
    [WWI Invoice ID]              INT             NULL,
    [WWI Purchase Order ID]       INT             NULL,
    [Supplier Invoice Number]     NVARCHAR (20)   NULL,
    [Total Excluding Tax]         DECIMAL (18, 2) NOT NULL,
    [Tax Amount]                  DECIMAL (18, 2) NOT NULL,
    [Total Including Tax]         DECIMAL (18, 2) NOT NULL,
    [Outstanding Balance]         DECIMAL (18, 2) NOT NULL,
    [Is Finalized]                BIT             NOT NULL,
    [Lineage Key]                 INT             NOT NULL,
    CONSTRAINT [PK_Fact_Transaction] PRIMARY KEY NONCLUSTERED ([Transaction Key] ASC, [Date Key] ASC) ON [PS_Date] ([Date Key]),
    CONSTRAINT [FK_Fact_Transaction_Bill_To_Customer_Key_Dimension_Customer] FOREIGN KEY ([Bill To Customer Key]) REFERENCES [Dimension].[Customer] ([Customer Key]),
    CONSTRAINT [FK_Fact_Transaction_Customer_Key_Dimension_Customer] FOREIGN KEY ([Customer Key]) REFERENCES [Dimension].[Customer] ([Customer Key]),
    CONSTRAINT [FK_Fact_Transaction_Date_Key_Dimension_Date] FOREIGN KEY ([Date Key]) REFERENCES [Dimension].[Date] ([Date]),
    CONSTRAINT [FK_Fact_Transaction_Payment_Method_Key_Dimension_Payment Method] FOREIGN KEY ([Payment Method Key]) REFERENCES [Dimension].[Payment Method] ([Payment Method Key]),
    CONSTRAINT [FK_Fact_Transaction_Supplier_Key_Dimension_Supplier] FOREIGN KEY ([Supplier Key]) REFERENCES [Dimension].[Supplier] ([Supplier Key]),
    CONSTRAINT [FK_Fact_Transaction_Transaction_Type_Key_Dimension_Transaction Type] FOREIGN KEY ([Transaction Type Key]) REFERENCES [Dimension].[Transaction Type] ([Transaction Type Key])
);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Transaction_Bill_To_Customer_Key]
    ON [Fact].[Transaction]([Bill To Customer Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Transaction_Customer_Key]
    ON [Fact].[Transaction]([Customer Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Transaction_Date_Key]
    ON [Fact].[Transaction]([Date Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Transaction_Payment_Method_Key]
    ON [Fact].[Transaction]([Payment Method Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Transaction_Supplier_Key]
    ON [Fact].[Transaction]([Supplier Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE NONCLUSTERED INDEX [FK_Fact_Transaction_Transaction_Type_Key]
    ON [Fact].[Transaction]([Transaction Type Key] ASC)
    ON [PS_Date] ([Date Key]);


GO
CREATE CLUSTERED COLUMNSTORE INDEX [CCX_Fact_Transaction]
    ON [Fact].[Transaction]
    ON [PS_Date] ([Date Key]);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Transaction fact table (financial transactions involving customers and supppliers)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Transaction';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'DW key for a row in the Transaction fact', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Transaction', @level2type = N'COLUMN', @level2name = N'Transaction Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Transaction date', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Transaction', @level2type = N'COLUMN', @level2name = N'Date Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer (if applicable)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Transaction', @level2type = N'COLUMN', @level2name = N'Customer Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Bill to customer (if applicable)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Transaction', @level2type = N'COLUMN', @level2name = N'Bill To Customer Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier (if applicable)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Transaction', @level2type = N'COLUMN', @level2name = N'Supplier Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Type of transaction', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Transaction', @level2type = N'COLUMN', @level2name = N'Transaction Type Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Payment method (if applicable)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Transaction', @level2type = N'COLUMN', @level2name = N'Payment Method Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer transaction ID in source system', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Transaction', @level2type = N'COLUMN', @level2name = N'WWI Customer Transaction ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier transaction ID in source system', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Transaction', @level2type = N'COLUMN', @level2name = N'WWI Supplier Transaction ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Invoice ID in source system', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Transaction', @level2type = N'COLUMN', @level2name = N'WWI Invoice ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Purchase order ID in source system', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Transaction', @level2type = N'COLUMN', @level2name = N'WWI Purchase Order ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier invoice number (if applicable)', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Transaction', @level2type = N'COLUMN', @level2name = N'Supplier Invoice Number';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total amount excluding tax', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Transaction', @level2type = N'COLUMN', @level2name = N'Total Excluding Tax';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total amount of tax', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Transaction', @level2type = N'COLUMN', @level2name = N'Tax Amount';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total amount including tax', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Transaction', @level2type = N'COLUMN', @level2name = N'Total Including Tax';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Amount still outstanding for this transaction', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Transaction', @level2type = N'COLUMN', @level2name = N'Outstanding Balance';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Has this transaction been finalized?', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Transaction', @level2type = N'COLUMN', @level2name = N'Is Finalized';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Lineage Key for the data load for this row', @level0type = N'SCHEMA', @level0name = N'Fact', @level1type = N'TABLE', @level1name = N'Transaction', @level2type = N'COLUMN', @level2name = N'Lineage Key';


GO

-- File: City_Staging.sql
﻿CREATE TABLE [Integration].[City_Staging] (
    [City Staging Key]           INT               IDENTITY (1, 1) NOT NULL,
    [WWI City ID]                INT               NOT NULL,
    [City]                       NVARCHAR (50)     NOT NULL,
    [State Province]             NVARCHAR (50)     NOT NULL,
    [Country]                    NVARCHAR (60)     NOT NULL,
    [Continent]                  NVARCHAR (30)     NOT NULL,
    [Sales Territory]            NVARCHAR (50)     NOT NULL,
    [Region]                     NVARCHAR (30)     NOT NULL,
    [Subregion]                  NVARCHAR (30)     NOT NULL,
    [Location]                   [sys].[geography] NULL,
    [Latest Recorded Population] BIGINT            NOT NULL,
    [Valid From]                 DATETIME2 (7)     NOT NULL,
    [Valid To]                   DATETIME2 (7)     NOT NULL,
    CONSTRAINT [PK_Integration_City_Staging] PRIMARY KEY CLUSTERED ([City Staging Key] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Integration_City_Staging_WWI_City_ID]
    ON [Integration].[City_Staging]([WWI City ID] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Allows quickly locating by WWI City Key', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'City_Staging', @level2type = N'INDEX', @level2name = N'IX_Integration_City_Staging_WWI_City_ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'City staging table', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'City_Staging';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Row ID within the staging table', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'City_Staging', @level2type = N'COLUMN', @level2name = N'City Staging Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a city within the WWI database', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'City_Staging', @level2type = N'COLUMN', @level2name = N'WWI City ID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Formal name of the city', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'City_Staging', @level2type = N'COLUMN', @level2name = N'City';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'State or province for this city', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'City_Staging', @level2type = N'COLUMN', @level2name = N'State Province';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Country name', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'City_Staging', @level2type = N'COLUMN', @level2name = N'Country';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Continent that this city is on', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'City_Staging', @level2type = N'COLUMN', @level2name = N'Continent';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Sales territory for this StateProvince', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'City_Staging', @level2type = N'COLUMN', @level2name = N'Sales Territory';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Name of the region', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'City_Staging', @level2type = N'COLUMN', @level2name = N'Region';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Name of the subregion', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'City_Staging', @level2type = N'COLUMN', @level2name = N'Subregion';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Geographic location of the city', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'City_Staging', @level2type = N'COLUMN', @level2name = N'Location';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Latest available population for the City', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'City_Staging', @level2type = N'COLUMN', @level2name = N'Latest Recorded Population';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Valid from this date and time', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'City_Staging', @level2type = N'COLUMN', @level2name = N'Valid From';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Valid until this date and time', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'City_Staging', @level2type = N'COLUMN', @level2name = N'Valid To';


GO

-- File: Customer_Staging.sql
﻿CREATE TABLE [Integration].[Customer_Staging] (
    [Customer Staging Key] INT            IDENTITY (1, 1) NOT NULL,
    [WWI Customer ID]      INT            NOT NULL,
    [Customer]             NVARCHAR (100) NOT NULL,
    [Bill To Customer]     NVARCHAR (100) NOT NULL,
    [Category]             NVARCHAR (50)  NOT NULL,
    [Buying Group]         NVARCHAR (50)  NOT NULL,
    [Primary Contact]      NVARCHAR (50)  NOT NULL,
    [Postal Code]          NVARCHAR (10)  NOT NULL,
    [Valid From]           DATETIME2 (7)  NOT NULL,
    [Valid To]             DATETIME2 (7)  NOT NULL,
    CONSTRAINT [PK_Integration_Customer_Staging] PRIMARY KEY NONCLUSTERED ([Customer Staging Key] ASC)
)
WITH (DURABILITY = SCHEMA_ONLY, MEMORY_OPTIMIZED = ON);


GO

-- File: ETL Cutoff.sql
﻿CREATE TABLE [Integration].[ETL Cutoff] (
    [Table Name]  [sysname]     NOT NULL,
    [Cutoff Time] DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_Integration_ETL_Cutoff] PRIMARY KEY CLUSTERED ([Table Name] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'ETL Cutoff Times', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'ETL Cutoff';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Table name', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'ETL Cutoff', @level2type = N'COLUMN', @level2name = N'Table Name';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Time up to which data has been loaded', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'ETL Cutoff', @level2type = N'COLUMN', @level2name = N'Cutoff Time';


GO

-- File: Employee_Staging.sql
﻿CREATE TABLE [Integration].[Employee_Staging] (
    [Employee Staging Key] INT             IDENTITY (1, 1) NOT NULL,
    [WWI Employee ID]      INT             NOT NULL,
    [Employee]             NVARCHAR (50)   NOT NULL,
    [Preferred Name]       NVARCHAR (50)   NOT NULL,
    [Is Salesperson]       BIT             NOT NULL,
    [Photo]                VARBINARY (MAX) NULL,
    [Valid From]           DATETIME2 (7)   NOT NULL,
    [Valid To]             DATETIME2 (7)   NOT NULL,
    CONSTRAINT [PK_Integration_Employee_Staging] PRIMARY KEY NONCLUSTERED ([Employee Staging Key] ASC)
)
WITH (DURABILITY = SCHEMA_ONLY, MEMORY_OPTIMIZED = ON);


GO

-- File: Lineage.sql
﻿CREATE TABLE [Integration].[Lineage] (
    [Lineage Key]               INT           CONSTRAINT [DF_Integration_Lineage_Lineage_Key] DEFAULT (NEXT VALUE FOR [Sequences].[LineageKey]) NOT NULL,
    [Data Load Started]         DATETIME2 (7) NOT NULL,
    [Table Name]                [sysname]     NOT NULL,
    [Data Load Completed]       DATETIME2 (7) NULL,
    [Was Successful]            BIT           NOT NULL,
    [Source System Cutoff Time] DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_Integration_Lineage] PRIMARY KEY CLUSTERED ([Lineage Key] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Details of data load attempts', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'Lineage';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'DW key for lineage data', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'Lineage', @level2type = N'COLUMN', @level2name = N'Lineage Key';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Time when the data load attempt began', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'Lineage', @level2type = N'COLUMN', @level2name = N'Data Load Started';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Name of the table for this data load event', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'Lineage', @level2type = N'COLUMN', @level2name = N'Table Name';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Time when the data load attempt completed (successfully or not)', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'Lineage', @level2type = N'COLUMN', @level2name = N'Data Load Completed';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Was the attempt successful?', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'Lineage', @level2type = N'COLUMN', @level2name = N'Was Successful';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Time that rows from the source system were loaded up until', @level0type = N'SCHEMA', @level0name = N'Integration', @level1type = N'TABLE', @level1name = N'Lineage', @level2type = N'COLUMN', @level2name = N'Source System Cutoff Time';


GO

-- File: Movement_Staging.sql
﻿CREATE TABLE [Integration].[Movement_Staging] (
    [Movement Staging Key]          BIGINT        IDENTITY (1, 1) NOT NULL,
    [Date Key]                      DATE          NULL,
    [Stock Item Key]                INT           NULL,
    [Customer Key]                  INT           NULL,
    [Supplier Key]                  INT           NULL,
    [Transaction Type Key]          INT           NULL,
    [WWI Stock Item Transaction ID] INT           NULL,
    [WWI Invoice ID]                INT           NULL,
    [WWI Purchase Order ID]         INT           NULL,
    [Quantity]                      INT           NULL,
    [WWI Stock Item ID]             INT           NULL,
    [WWI Customer ID]               INT           NULL,
    [WWI Supplier ID]               INT           NULL,
    [WWI Transaction Type ID]       INT           NULL,
    [Last Modifed When]             DATETIME2 (7) NULL,
    CONSTRAINT [PK_Integration_Movement_Staging] PRIMARY KEY NONCLUSTERED ([Movement Staging Key] ASC)
)
WITH (DURABILITY = SCHEMA_ONLY, MEMORY_OPTIMIZED = ON);


GO

-- File: Order_Staging.sql
﻿CREATE TABLE [Integration].[Order_Staging] (
    [Order Staging Key]   BIGINT          IDENTITY (1, 1) NOT NULL,
    [City Key]            INT             NULL,
    [Customer Key]        INT             NULL,
    [Stock Item Key]      INT             NULL,
    [Order Date Key]      DATE            NULL,
    [Picked Date Key]     DATE            NULL,
    [Salesperson Key]     INT             NULL,
    [Picker Key]          INT             NULL,
    [WWI Order ID]        INT             NULL,
    [WWI Backorder ID]    INT             NULL,
    [Description]         NVARCHAR (100)  NULL,
    [Package]             NVARCHAR (50)   NULL,
    [Quantity]            INT             NULL,
    [Unit Price]          DECIMAL (18, 2) NULL,
    [Tax Rate]            DECIMAL (18, 3) NULL,
    [Total Excluding Tax] DECIMAL (18, 2) NULL,
    [Tax Amount]          DECIMAL (18, 2) NULL,
    [Total Including Tax] DECIMAL (18, 2) NULL,
    [Lineage Key]         INT             NULL,
    [WWI City ID]         INT             NULL,
    [WWI Customer ID]     INT             NULL,
    [WWI Stock Item ID]   INT             NULL,
    [WWI Salesperson ID]  INT             NULL,
    [WWI Picker ID]       INT             NULL,
    [Last Modified When]  DATETIME2 (7)   NULL,
    CONSTRAINT [PK_Integration_Order_Staging] PRIMARY KEY NONCLUSTERED ([Order Staging Key] ASC)
)
WITH (DURABILITY = SCHEMA_ONLY, MEMORY_OPTIMIZED = ON);


GO

-- File: PaymentMethod_Staging.sql
﻿CREATE TABLE [Integration].[PaymentMethod_Staging] (
    [Payment Method Staging Key] INT           IDENTITY (1, 1) NOT NULL,
    [WWI Payment Method ID]      INT           NOT NULL,
    [Payment Method]             NVARCHAR (50) NOT NULL,
    [Valid From]                 DATETIME2 (7) NOT NULL,
    [Valid To]                   DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_Integration_Payment_Method_Staging] PRIMARY KEY NONCLUSTERED ([Payment Method Staging Key] ASC)
)
WITH (DURABILITY = SCHEMA_ONLY, MEMORY_OPTIMIZED = ON);


GO

-- File: Purchase_Staging.sql
﻿CREATE TABLE [Integration].[Purchase_Staging] (
    [Purchase Staging Key]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [Date Key]              DATE          NULL,
    [Supplier Key]          INT           NULL,
    [Stock Item Key]        INT           NULL,
    [WWI Purchase Order ID] INT           NULL,
    [Ordered Outers]        INT           NULL,
    [Ordered Quantity]      INT           NULL,
    [Received Outers]       INT           NULL,
    [Package]               NVARCHAR (50) NULL,
    [Is Order Finalized]    BIT           NULL,
    [WWI Supplier ID]       INT           NULL,
    [WWI Stock Item ID]     INT           NULL,
    [Last Modified When]    DATETIME2 (7) NULL,
    CONSTRAINT [PK_Integration_Purchase_Staging] PRIMARY KEY NONCLUSTERED ([Purchase Staging Key] ASC)
)
WITH (DURABILITY = SCHEMA_ONLY, MEMORY_OPTIMIZED = ON);


GO

-- File: Sale_Staging.sql
﻿CREATE TABLE [Integration].[Sale_Staging] (
    [Sale Staging Key]        BIGINT          IDENTITY (1, 1) NOT NULL,
    [City Key]                INT             NULL,
    [Customer Key]            INT             NULL,
    [Bill To Customer Key]    INT             NULL,
    [Stock Item Key]          INT             NULL,
    [Invoice Date Key]        DATE            NULL,
    [Delivery Date Key]       DATE            NULL,
    [Salesperson Key]         INT             NULL,
    [WWI Invoice ID]          INT             NULL,
    [Description]             NVARCHAR (100)  NULL,
    [Package]                 NVARCHAR (50)   NULL,
    [Quantity]                INT             NULL,
    [Unit Price]              DECIMAL (18, 2) NULL,
    [Tax Rate]                DECIMAL (18, 3) NULL,
    [Total Excluding Tax]     DECIMAL (18, 2) NULL,
    [Tax Amount]              DECIMAL (18, 2) NULL,
    [Profit]                  DECIMAL (18, 2) NULL,
    [Total Including Tax]     DECIMAL (18, 2) NULL,
    [Total Dry Items]         INT             NULL,
    [Total Chiller Items]     INT             NULL,
    [WWI City ID]             INT             NULL,
    [WWI Customer ID]         INT             NULL,
    [WWI Bill To Customer ID] INT             NULL,
    [WWI Stock Item ID]       INT             NULL,
    [WWI Salesperson ID]      INT             NULL,
    [Last Modified When]      DATETIME2 (7)   NULL,
    CONSTRAINT [PK_Integration_Sale_Staging] PRIMARY KEY NONCLUSTERED ([Sale Staging Key] ASC)
)
WITH (DURABILITY = SCHEMA_ONLY, MEMORY_OPTIMIZED = ON);


GO

-- File: StockHolding_Staging.sql
﻿CREATE TABLE [Integration].[StockHolding_Staging] (
    [Stock Holding Staging Key] BIGINT          IDENTITY (1, 1) NOT NULL,
    [Stock Item Key]            INT             NULL,
    [Quantity On Hand]          INT             NULL,
    [Bin Location]              NVARCHAR (20)   NULL,
    [Last Stocktake Quantity]   INT             NULL,
    [Last Cost Price]           DECIMAL (18, 2) NULL,
    [Reorder Level]             INT             NULL,
    [Target Stock Level]        INT             NULL,
    [WWI Stock Item ID]         INT             NULL,
    CONSTRAINT [PK_Integration_Stock_Holding_Staging] PRIMARY KEY NONCLUSTERED ([Stock Holding Staging Key] ASC)
)
WITH (DURABILITY = SCHEMA_ONLY, MEMORY_OPTIMIZED = ON);


GO

-- File: StockItem_Staging.sql
﻿CREATE TABLE [Integration].[StockItem_Staging] (
    [Stock Item Staging Key]   INT             IDENTITY (1, 1) NOT NULL,
    [WWI Stock Item ID]        INT             NOT NULL,
    [Stock Item]               NVARCHAR (100)  NOT NULL,
    [Color]                    NVARCHAR (20)   NOT NULL,
    [Selling Package]          NVARCHAR (50)   NOT NULL,
    [Buying Package]           NVARCHAR (50)   NOT NULL,
    [Brand]                    NVARCHAR (50)   NOT NULL,
    [Size]                     NVARCHAR (20)   NOT NULL,
    [Lead Time Days]           INT             NOT NULL,
    [Quantity Per Outer]       INT             NOT NULL,
    [Is Chiller Stock]         BIT             NOT NULL,
    [Barcode]                  NVARCHAR (50)   NULL,
    [Tax Rate]                 DECIMAL (18, 3) NOT NULL,
    [Unit Price]               DECIMAL (18, 2) NOT NULL,
    [Recommended Retail Price] DECIMAL (18, 2) NULL,
    [Typical Weight Per Unit]  DECIMAL (18, 3) NOT NULL,
    [Photo]                    VARBINARY (MAX) NULL,
    [Valid From]               DATETIME2 (7)   NOT NULL,
    [Valid To]                 DATETIME2 (7)   NOT NULL,
    CONSTRAINT [PK_Integration_Stock_Item_Staging] PRIMARY KEY NONCLUSTERED ([Stock Item Staging Key] ASC)
)
WITH (DURABILITY = SCHEMA_ONLY, MEMORY_OPTIMIZED = ON);


GO

-- File: Supplier_Staging.sql
﻿CREATE TABLE [Integration].[Supplier_Staging] (
    [Supplier Staging Key] INT            IDENTITY (1, 1) NOT NULL,
    [WWI Supplier ID]      INT            NOT NULL,
    [Supplier]             NVARCHAR (100) NOT NULL,
    [Category]             NVARCHAR (50)  NOT NULL,
    [Primary Contact]      NVARCHAR (50)  NOT NULL,
    [Supplier Reference]   NVARCHAR (20)  NULL,
    [Payment Days]         INT            NOT NULL,
    [Postal Code]          NVARCHAR (10)  NOT NULL,
    [Valid From]           DATETIME2 (7)  NOT NULL,
    [Valid To]             DATETIME2 (7)  NOT NULL,
    CONSTRAINT [PK_Integration_Supplier_Staging] PRIMARY KEY NONCLUSTERED ([Supplier Staging Key] ASC)
)
WITH (DURABILITY = SCHEMA_ONLY, MEMORY_OPTIMIZED = ON);


GO

-- File: TransactionType_Staging.sql
﻿CREATE TABLE [Integration].[TransactionType_Staging] (
    [Transaction Type Staging Key] INT           IDENTITY (1, 1) NOT NULL,
    [WWI Transaction Type ID]      INT           NOT NULL,
    [Transaction Type]             NVARCHAR (50) NOT NULL,
    [Valid From]                   DATETIME2 (7) NOT NULL,
    [Valid To]                     DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_Integration_Transaction_Type_Staging] PRIMARY KEY NONCLUSTERED ([Transaction Type Staging Key] ASC)
)
WITH (DURABILITY = SCHEMA_ONLY, MEMORY_OPTIMIZED = ON);


GO

-- File: Transaction_Staging.sql
﻿CREATE TABLE [Integration].[Transaction_Staging] (
    [Transaction Staging Key]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [Date Key]                    DATE            NULL,
    [Customer Key]                INT             NULL,
    [Bill To Customer Key]        INT             NULL,
    [Supplier Key]                INT             NULL,
    [Transaction Type Key]        INT             NULL,
    [Payment Method Key]          INT             NULL,
    [WWI Customer Transaction ID] INT             NULL,
    [WWI Supplier Transaction ID] INT             NULL,
    [WWI Invoice ID]              INT             NULL,
    [WWI Purchase Order ID]       INT             NULL,
    [Supplier Invoice Number]     NVARCHAR (20)   NULL,
    [Total Excluding Tax]         DECIMAL (18, 2) NULL,
    [Tax Amount]                  DECIMAL (18, 2) NULL,
    [Total Including Tax]         DECIMAL (18, 2) NULL,
    [Outstanding Balance]         DECIMAL (18, 2) NULL,
    [Is Finalized]                BIT             NULL,
    [WWI Customer ID]             INT             NULL,
    [WWI Bill To Customer ID]     INT             NULL,
    [WWI Supplier ID]             INT             NULL,
    [WWI Transaction Type ID]     INT             NULL,
    [WWI Payment Method ID]       INT             NULL,
    [Last Modified When]          DATETIME2 (7)   NULL,
    CONSTRAINT [PK_Integration_Transaction_Staging] PRIMARY KEY NONCLUSTERED ([Transaction Staging Key] ASC)
)
WITH (DURABILITY = SCHEMA_ONLY, MEMORY_OPTIMIZED = ON);


GO

-- File: SampleVersion.sql
﻿CREATE TABLE [dbo].[SampleVersion]
(
	MajorSampleVersion INT NOT NULL,
	MinorSampleVersion INT NOT NULL,
	MinSQLServerBuild NVARCHAR(25) NOT NULL,
	[RowCount] INT NOT NULL DEFAULT (1),
	CONSTRAINT uq_SampleVersion_RowCount
	  UNIQUE ([RowCount]),
	CONSTRAINT chk_SampleVersion_Cardinality
	  CHECK ([RowCount]= 1)
)


GO
