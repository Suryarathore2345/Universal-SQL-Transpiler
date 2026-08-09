-- WideWorldImporters DW Database Stored Procedures - microsoft/sql-server-samples (MIT License)
-- Source: https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/wide-world-importers/wwi-dw-ssdt


-- File: Configuration_ApplyPolybase.sql
﻿
CREATE PROCEDURE [Application].Configuration_ApplyPolybase
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF SERVERPROPERTY(N'IsPolybaseInstalled') = 0
    BEGIN
        PRINT N'Warning: Either Polybase cannot be created on this edition or it has not been installed.';
	END ELSE BEGIN -- if installed
		IF (SELECT value FROM sys.configurations WHERE name = 'hadoop connectivity') NOT IN (1, 4, 7)
		BEGIN
	        PRINT N'Warning: Hadoop connectivity has not been enabled. It must be set to 1, 4, or 7 for Azure Storage connectivity.';
		END ELSE BEGIN -- if Polybase can be created

			DECLARE @SQL nvarchar(max) = N'';

			BEGIN TRY

				SET @SQL = N'
CREATE EXTERNAL DATA SOURCE AzureStorage
WITH
(
	TYPE=HADOOP, LOCATION = ''wasbs://data@sqldwdatasets.blob.core.windows.net''
);';
				EXECUTE (@SQL);

				SET @SQL = N'
CREATE EXTERNAL FILE FORMAT CommaDelimitedTextFileFormat
WITH
(
	FORMAT_TYPE = DELIMITEDTEXT,
	FORMAT_OPTIONS
	(
		FIELD_TERMINATOR = '',''
	)
);';
				EXECUTE (@SQL);

				SET @SQL = N'
CREATE EXTERNAL TABLE dbo.CityPopulationStatistics
(
	CityID int NOT NULL,
	StateProvinceCode nvarchar(5) NOT NULL,
	CityName nvarchar(50) NOT NULL,
	YearNumber int NOT NULL,
	LatestRecordedPopulation bigint NULL
)
WITH
(
	LOCATION = ''/'',
	DATA_SOURCE = AzureStorage,
	FILE_FORMAT = CommaDelimitedTextFileFormat,
	REJECT_TYPE = VALUE,
	REJECT_VALUE = 4 -- skipping 1 header row per file
);';
				EXECUTE (@SQL);

	        END TRY
			BEGIN CATCH
				PRINT N'Unable to apply Polybase connectivity to Azure storage';
				THROW;
			END CATCH;
		END; -- if connectivity enabled
    END; -- of Polybase is allowed and installed
END;

GO

-- File: Configuration_PopulateLargeSaleTable.sql
﻿
CREATE PROCEDURE [Application].[Configuration_PopulateLargeSaleTable]
@EstimatedRowsFor2012 bigint = 12000000
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

	EXEC Integration.PopulateDateDimensionForYear 2012;
	DECLARE @ReturnValue int;

	EXEC @ReturnValue = [Application].Configuration_ApplyPartitionedColumnstoreIndexing;
	DECLARE @LineageKey int = NEXT VALUE FOR Sequences.LineageKey;

	INSERT Integration.Lineage
		([Lineage Key], [Data Load Started], [Table Name], [Data Load Completed], [Was Successful],
		 [Source System Cutoff Time])
	VALUES
		(@LineageKey, SYSDATETIME(), N'Sale', NULL, 0, '20121231')

	DECLARE @OrderCounter bigint = 0;
	DECLARE @NumberOfSalesPerDay bigint = @EstimatedRowsFor2012 / 365;
	DECLARE @DateCounter date = '20120101';
	DECLARE @StartingSaleKey bigint;
	DECLARE @MaximumSaleKey bigint = (SELECT MAX([Sale Key]) FROM Fact.Sale);

	PRINT 'Targeting ' + CAST(@NumberOfSalesPerDay AS varchar(20)) + ' sales per day.';
	IF @NumberOfSalesPerDay > 50000
	BEGIN
		PRINT 'WARNING: Limiting sales to 40000 per day';
		SET @NumberOfSalesPerDay = 50000;
	END;

	DECLARE @OutputCounter varchar(20);


-- DROP CONSTRAINTS
	ALTER TABLE [Fact].[Sale] DROP CONSTRAINT [FK_Fact_Sale_City_Key_Dimension_City]
	ALTER TABLE [Fact].[Sale] DROP CONSTRAINT [FK_Fact_Sale_Customer_Key_Dimension_Customer]
	ALTER TABLE [Fact].[Sale] DROP CONSTRAINT [FK_Fact_Sale_Delivery_Date_Key_Dimension_Date]
	ALTER TABLE [Fact].[Sale] DROP CONSTRAINT [FK_Fact_Sale_Invoice_Date_Key_Dimension_Date]
	ALTER TABLE [Fact].[Sale] DROP CONSTRAINT [FK_Fact_Sale_Salesperson_Key_Dimension_Employee]
	ALTER TABLE [Fact].[Sale] DROP CONSTRAINT [FK_Fact_Sale_Stock_Item_Key_Dimension_Stock Item]
	ALTER TABLE [Fact].[Sale] DROP CONSTRAINT [FK_Fact_Sale_Bill_To_Customer_Key_Dimension_Customer]
	ALTER TABLE [Fact].[Sale] DROP CONSTRAINT [PK_Fact_Sale]
	DROP INDEX  IF EXISTS [FK_Fact_Sale_Bill_To_Customer_Key] ON [Fact].[Sale]
	DROP INDEX  IF EXISTS [FK_Fact_Sale_City_Key] ON [Fact].[Sale]
	DROP INDEX  IF EXISTS [FK_Fact_Sale_Customer_Key] ON [Fact].[Sale]
	DROP INDEX  IF EXISTS [FK_Fact_Sale_Delivery_Date_Key] ON [Fact].[Sale]
	DROP INDEX  IF EXISTS [FK_Fact_Sale_Invoice_Date_Key] ON [Fact].[Sale]
	DROP INDEX  IF EXISTS [FK_Fact_Sale_Salesperson_Key] ON [Fact].[Sale]
	DROP INDEX  IF EXISTS [FK_Fact_Sale_Stock_Item_Key] ON [Fact].[Sale]

	WHILE @DateCounter < '20121231'
	BEGIN
		SET @OutputCounter = CONVERT(varchar(20), @DateCounter, 112);
		RAISERROR(@OutputCounter, 0, 1) WITH NOWAIT;

		SET @StartingSaleKey = @MaximumSaleKey - @NumberOfSalesPerDay - FLOOR(RAND() * 20000);
		SET @OrderCounter = 0;

		INSERT Fact.Sale WITH (TABLOCK)
			([City Key], [Customer Key], [Bill To Customer Key], [Stock Item Key], [Invoice Date Key],
			 [Delivery Date Key], [Salesperson Key], [WWI Invoice ID], [Description],
			 Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax],
			 [Tax Amount], Profit, [Total Including Tax], [Total Dry Items], [Total Chiller Items],
			 [Lineage Key])
		SELECT TOP(@NumberOfSalesPerDay)
			   [City Key], [Customer Key], [Bill To Customer Key], [Stock Item Key], @DateCounter,
			   DATEADD(day, 1, @DateCounter), [Salesperson Key], [WWI Invoice ID], [Description],
			   Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax],
			   [Tax Amount], Profit, [Total Including Tax], [Total Dry Items], [Total Chiller Items],
			   @LineageKey
		FROM Fact.Sale
		WHERE [Sale Key] > @StartingSaleKey
			and [Invoice Date Key] >='2013-01-01'
		ORDER BY [Sale Key];

		SET @DateCounter = DATEADD(day, 1, @DateCounter);
	END;

	RAISERROR('Compressing all open Rowgroups', 0, 1) WITH NOWAIT;

	ALTER INDEX CCX_Fact_Sale
	ON Fact.Sale
	REORGANIZE WITH (COMPRESS_ALL_ROW_GROUPS = ON);

	UPDATE Integration.Lineage
		SET [Data Load Completed] = SYSDATETIME(),
		    [Was Successful] = 1;

	-- Add back Constraints
	RAISERROR('Adding Constraints', 0, 1) WITH NOWAIT;

	ALTER TABLE [Fact].[Sale]
	ADD CONSTRAINT [PK_Fact_Sale] PRIMARY KEY NONCLUSTERED
	(
		[Sale Key] ASC,
		[Invoice Date Key] ASC
	);

	ALTER TABLE [Fact].[Sale]
	WITH CHECK ADD CONSTRAINT [FK_Fact_Sale_Bill_To_Customer_Key_Dimension_Customer]
	FOREIGN KEY([Bill To Customer Key])
	REFERENCES [Dimension].[Customer] ([Customer Key]);

	ALTER TABLE [Fact].[Sale] CHECK CONSTRAINT [FK_Fact_Sale_Bill_To_Customer_Key_Dimension_Customer];

	ALTER TABLE [Fact].[Sale]
	WITH CHECK ADD CONSTRAINT [FK_Fact_Sale_Stock_Item_Key_Dimension_Stock Item]
	FOREIGN KEY([Stock Item Key])
	REFERENCES [Dimension].[Stock Item] ([Stock Item Key]);

	ALTER TABLE [Fact].[Sale] CHECK CONSTRAINT [FK_Fact_Sale_Stock_Item_Key_Dimension_Stock Item];

	ALTER TABLE [Fact].[Sale]
	WITH CHECK ADD  CONSTRAINT [FK_Fact_Sale_Salesperson_Key_Dimension_Employee]
	FOREIGN KEY([Salesperson Key])
	REFERENCES [Dimension].[Employee] ([Employee Key]);

	ALTER TABLE [Fact].[Sale] CHECK CONSTRAINT [FK_Fact_Sale_Salesperson_Key_Dimension_Employee];

	ALTER TABLE [Fact].[Sale]
	WITH CHECK ADD  CONSTRAINT [FK_Fact_Sale_Invoice_Date_Key_Dimension_Date]
	FOREIGN KEY([Invoice Date Key])
	REFERENCES [Dimension].[Date] ([Date]);

	ALTER TABLE [Fact].[Sale] CHECK CONSTRAINT [FK_Fact_Sale_Invoice_Date_Key_Dimension_Date];

	ALTER TABLE [Fact].[Sale]
	WITH CHECK ADD CONSTRAINT [FK_Fact_Sale_Delivery_Date_Key_Dimension_Date]
	FOREIGN KEY([Delivery Date Key])
	REFERENCES [Dimension].[Date] ([Date]);

	ALTER TABLE [Fact].[Sale] CHECK CONSTRAINT [FK_Fact_Sale_Delivery_Date_Key_Dimension_Date];

	ALTER TABLE [Fact].[Sale]
	WITH CHECK ADD CONSTRAINT [FK_Fact_Sale_Customer_Key_Dimension_Customer]
	FOREIGN KEY([Customer Key])
	REFERENCES [Dimension].[Customer] ([Customer Key]);

	ALTER TABLE [Fact].[Sale] CHECK CONSTRAINT [FK_Fact_Sale_Customer_Key_Dimension_Customer];

	ALTER TABLE [Fact].[Sale]
	WITH CHECK ADD  CONSTRAINT [FK_Fact_Sale_City_Key_Dimension_City]
	FOREIGN KEY([City Key])
	REFERENCES [Dimension].[City] ([City Key]);

	ALTER TABLE [Fact].[Sale] CHECK CONSTRAINT [FK_Fact_Sale_City_Key_Dimension_City];

	-- Recreate indexes
	RAISERROR('Adding Non-clustered Indexes', 0, 1) WITH NOWAIT;
	CREATE NONCLUSTERED INDEX [FK_Fact_Sale_Salesperson_Key] ON [Fact].[Sale] ([Salesperson Key] ASC);
	CREATE NONCLUSTERED INDEX [FK_Fact_Sale_Invoice_Date_Key] ON [Fact].[Sale] ([Invoice Date Key] ASC);
	CREATE NONCLUSTERED INDEX [FK_Fact_Sale_Delivery_Date_Key] ON [Fact].[Sale] ([Delivery Date Key] ASC);
	CREATE NONCLUSTERED INDEX [FK_Fact_Sale_Bill_To_Customer_Key] ON [Fact].[Sale] ([Bill To Customer Key] ASC);
	CREATE NONCLUSTERED INDEX [FK_Fact_Sale_City_Key] ON [Fact].[Sale] ([City Key] ASC);
	CREATE NONCLUSTERED INDEX [FK_Fact_Sale_Customer_Key] ON [Fact].[Sale] ([Customer Key] ASC);

	RETURN 0;
END;

GO

-- File: Configuration_ReseedETL.sql
﻿
CREATE PROCEDURE [Application].Configuration_ReseedETL
WITH EXECUTE AS OWNER
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @StartingETLCutoffTime datetime2(7) = '20121231';
	DECLARE @StartOfTime datetime2(7) = '20130101';
	DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999';

	UPDATE Integration.[ETL Cutoff]
		SET [Cutoff Time] = @StartingETLCutoffTime;

	TRUNCATE TABLE Fact.Movement;
	TRUNCATE TABLE Fact.[Order];
	TRUNCATE TABLE Fact.Purchase;
	TRUNCATE TABLE Fact.Sale;
	TRUNCATE TABLE Fact.[Stock Holding];
	TRUNCATE TABLE Fact.[Transaction];

	DELETE Dimension.City;
	DELETE Dimension.Customer;
	DELETE Dimension.Employee;
	DELETE Dimension.[Payment Method];
	DELETE Dimension.[Stock Item];
	DELETE Dimension.Supplier;
	DELETE Dimension.[Transaction Type];

    INSERT Dimension.City
        ([City Key], [WWI City ID], City, [State Province], Country, Continent, [Sales Territory], Region, Subregion,
         [Location], [Latest Recorded Population], [Valid From], [Valid To], [Lineage Key])
    VALUES
        (0, 0, N'Unknown', N'N/A', N'N/A', N'N/A', N'N/A', N'N/A', N'N/A',
         NULL, 0, @StartOfTime, @EndOfTime, 0);

    INSERT Dimension.Customer
        ([Customer Key], [WWI Customer ID], [Customer], [Bill To Customer], Category, [Buying Group],
         [Primary Contact], [Postal Code], [Valid From], [Valid To], [Lineage Key])
    VALUES
        (0, 0, N'Unknown', N'N/A', N'N/A', N'N/A',
         N'N/A', N'N/A', @StartOfTime, @EndOfTime, 0);

    INSERT Dimension.Employee
        ([Employee Key], [WWI Employee ID], Employee, [Preferred Name],
         [Is Salesperson], Photo, [Valid From], [Valid To], [Lineage Key])
    VALUES
        (0, 0, N'Unknown', N'N/A',
         0, NULL, @StartOfTime, @EndOfTime, 0);

    INSERT Dimension.[Payment Method]
        ([Payment Method Key], [WWI Payment Method ID], [Payment Method], [Valid From], [Valid To], [Lineage Key])
    VALUES
        (0, 0, N'Unknown', @StartOfTime, @EndOfTime, 0);

    INSERT Dimension.[Stock Item]
        ([Stock Item Key], [WWI Stock Item ID], [Stock Item], Color, [Selling Package], [Buying Package],
         Brand, Size, [Lead Time Days], [Quantity Per Outer], [Is Chiller Stock],
         Barcode, [Tax Rate], [Unit Price], [Recommended Retail Price], [Typical Weight Per Unit],
         Photo, [Valid From], [Valid To], [Lineage Key])
    VALUES
        (0, 0, N'Unknown', N'N/A', N'N/A', N'N/A',
         N'N/A', N'N/A', 0, 0, 0,
         N'N/A', 0, 0, 0, 0,
         NULL, @StartOfTime, @EndOfTime, 0);

    INSERT Dimension.[Supplier]
        ([Supplier Key], [WWI Supplier ID], Supplier, Category, [Primary Contact], [Supplier Reference],
         [Payment Days], [Postal Code], [Valid From], [Valid To], [Lineage Key])
    VALUES
        (0, 0, N'Unknown', N'N/A', N'N/A', N'N/A',
         0, N'N/A', @StartOfTime, @EndOfTime, 0);

    INSERT Dimension.[Transaction Type]
        ([Transaction Type Key], [WWI Transaction Type ID], [Transaction Type], [Valid From], [Valid To], [Lineage Key])
    VALUES
        (0, 0, N'Unknown', @StartOfTime, @EndOfTime, 0);
END;

GO

-- File: GetLastETLCutoffTime.sql
﻿
CREATE PROCEDURE Integration.GetLastETLCutoffTime
@TableName sysname
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT [Cutoff Time] AS CutoffTime
    FROM Integration.[ETL Cutoff]
    WHERE [Table Name] = @TableName;

    IF @@ROWCOUNT = 0
    BEGIN
        PRINT N'Invalid ETL table name';
        THROW 51000, N'Invalid ETL table name', 1;
        RETURN -1;
    END;

    RETURN 0;
END;

GO

-- File: GetLineageKey.sql
﻿
CREATE PROCEDURE Integration.GetLineageKey
@TableName sysname,
@NewCutoffTime datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @DataLoadStartedWhen datetime2(7) = SYSDATETIME();

    INSERT Integration.Lineage
        ([Data Load Started], [Table Name], [Data Load Completed],
         [Was Successful], [Source System Cutoff Time])
    OUTPUT
        inserted.[Lineage Key] as LineageKey
    VALUES
        (@DataLoadStartedWhen, @TableName, NULL,
         0, @NewCutoffTime);

    RETURN 0;
END;

GO

-- File: MigrateStagedCityData.sql
﻿
CREATE PROCEDURE Integration.MigrateStagedCityData
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999';

    BEGIN TRAN;

    DECLARE @LineageKey int = (SELECT TOP(1) [Lineage Key]
                               FROM Integration.Lineage
                               WHERE [Table Name] = N'City'
                               AND [Data Load Completed] IS NULL
                               ORDER BY [Lineage Key] DESC);

    WITH RowsToCloseOff
    AS
    (
        SELECT c.[WWI City ID], MIN(c.[Valid From]) AS [Valid From]
        FROM Integration.City_Staging AS c
        GROUP BY c.[WWI City ID]
    )
    UPDATE c
        SET c.[Valid To] = rtco.[Valid From]
    FROM Dimension.City AS c
    INNER JOIN RowsToCloseOff AS rtco
    ON c.[WWI City ID] = rtco.[WWI City ID]
    WHERE c.[Valid To] = @EndOfTime;

    INSERT Dimension.City
        ([WWI City ID], City, [State Province], Country, Continent,
         [Sales Territory], Region, Subregion, [Location],
         [Latest Recorded Population], [Valid From], [Valid To],
         [Lineage Key])
    SELECT [WWI City ID], City, [State Province], Country, Continent,
           [Sales Territory], Region, Subregion, [Location],
           [Latest Recorded Population], [Valid From], [Valid To],
           @LineageKey
    FROM Integration.City_Staging;

    UPDATE Integration.Lineage
        SET [Data Load Completed] = SYSDATETIME(),
            [Was Successful] = 1
    WHERE [Lineage Key] = @LineageKey;

    UPDATE Integration.[ETL Cutoff]
        SET [Cutoff Time] = (SELECT [Source System Cutoff Time]
                             FROM Integration.Lineage
                             WHERE [Lineage Key] = @LineageKey)
    FROM Integration.[ETL Cutoff]
    WHERE [Table Name] = N'City';

    COMMIT;

    RETURN 0;
END;

GO

-- File: MigrateStagedCustomerData.sql
﻿
CREATE PROCEDURE Integration.MigrateStagedCustomerData
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999';

    BEGIN TRAN;

    DECLARE @LineageKey int = (SELECT TOP(1) [Lineage Key]
                               FROM Integration.Lineage
                               WHERE [Table Name] = N'Customer'
                               AND [Data Load Completed] IS NULL
                               ORDER BY [Lineage Key] DESC);

    WITH RowsToCloseOff
    AS
    (
        SELECT c.[WWI Customer ID], MIN(c.[Valid From]) AS [Valid From]
        FROM Integration.Customer_Staging AS c
        GROUP BY c.[WWI Customer ID]
    )
    UPDATE c
        SET c.[Valid To] = rtco.[Valid From]
    FROM Dimension.Customer AS c
    INNER JOIN RowsToCloseOff AS rtco
    ON c.[WWI Customer ID] = rtco.[WWI Customer ID]
    WHERE c.[Valid To] = @EndOfTime;

    INSERT Dimension.Customer
        ([WWI Customer ID], Customer, [Bill To Customer], Category,
         [Buying Group], [Primary Contact], [Postal Code], [Valid From], [Valid To],
         [Lineage Key])
    SELECT [WWI Customer ID], Customer, [Bill To Customer], Category,
           [Buying Group], [Primary Contact], [Postal Code], [Valid From], [Valid To],
           @LineageKey
    FROM Integration.Customer_Staging;

    UPDATE Integration.Lineage
        SET [Data Load Completed] = SYSDATETIME(),
            [Was Successful] = 1
    WHERE [Lineage Key] = @LineageKey;

    UPDATE Integration.[ETL Cutoff]
        SET [Cutoff Time] = (SELECT [Source System Cutoff Time]
                             FROM Integration.Lineage
                             WHERE [Lineage Key] = @LineageKey)
    FROM Integration.[ETL Cutoff]
    WHERE [Table Name] = N'Customer';

    COMMIT;

    RETURN 0;
END;

GO

-- File: MigrateStagedEmployeeData.sql
﻿
CREATE PROCEDURE Integration.MigrateStagedEmployeeData
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999';

    BEGIN TRAN;

    DECLARE @LineageKey int = (SELECT TOP(1) [Lineage Key]
                               FROM Integration.Lineage
                               WHERE [Table Name] = N'Employee'
                               AND [Data Load Completed] IS NULL
                               ORDER BY [Lineage Key] DESC);

    WITH RowsToCloseOff
    AS
    (
        SELECT e.[WWI Employee ID], MIN(e.[Valid From]) AS [Valid From]
        FROM Integration.Employee_Staging AS e
        GROUP BY e.[WWI Employee ID]
    )
    UPDATE e
        SET e.[Valid To] = rtco.[Valid From]
    FROM Dimension.Employee AS e
    INNER JOIN RowsToCloseOff AS rtco
    ON e.[WWI Employee ID] = rtco.[WWI Employee ID]
    WHERE e.[Valid To] = @EndOfTime;

    INSERT Dimension.Employee
        ([WWI Employee ID], Employee, [Preferred Name], [Is Salesperson], Photo, [Valid From], [Valid To], [Lineage Key])
    SELECT [WWI Employee ID], Employee, [Preferred Name], [Is Salesperson], Photo, [Valid From], [Valid To],
           @LineageKey
    FROM Integration.Employee_Staging;

    UPDATE Integration.Lineage
        SET [Data Load Completed] = SYSDATETIME(),
            [Was Successful] = 1
    WHERE [Lineage Key] = @LineageKey;

    UPDATE Integration.[ETL Cutoff]
        SET [Cutoff Time] = (SELECT [Source System Cutoff Time]
                             FROM Integration.Lineage
                             WHERE [Lineage Key] = @LineageKey)
    FROM Integration.[ETL Cutoff]
    WHERE [Table Name] = N'Employee';

    COMMIT;

    RETURN 0;
END;

GO

-- File: MigrateStagedMovementData.sql
﻿
CREATE PROCEDURE Integration.MigrateStagedMovementData
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRAN;

    DECLARE @LineageKey int = (SELECT TOP(1) [Lineage Key]
                               FROM Integration.Lineage
                               WHERE [Table Name] = N'Movement'
                               AND [Data Load Completed] IS NULL
                               ORDER BY [Lineage Key] DESC);

    -- Find the dimension keys required

    UPDATE m
        SET m.[Stock Item Key] = COALESCE((SELECT TOP(1) si.[Stock Item Key]
                                           FROM Dimension.[Stock Item] AS si
                                           WHERE si.[WWI Stock Item ID] = m.[WWI Stock Item ID]
                                           AND m.[Last Modifed When] > si.[Valid From]
                                           AND m.[Last Modifed When] <= si.[Valid To]
									       ORDER BY si.[Valid From]), 0),
            m.[Customer Key] = COALESCE((SELECT TOP(1) c.[Customer Key]
                                         FROM Dimension.Customer AS c
                                         WHERE c.[WWI Customer ID] = m.[WWI Customer ID]
                                         AND m.[Last Modifed When] > c.[Valid From]
                                         AND m.[Last Modifed When] <= c.[Valid To]
									     ORDER BY c.[Valid From]), 0),
            m.[Supplier Key] = COALESCE((SELECT TOP(1) s.[Supplier Key]
                                         FROM Dimension.Supplier AS s
                                         WHERE s.[WWI Supplier ID] = m.[WWI Supplier ID]
                                         AND m.[Last Modifed When] > s.[Valid From]
                                         AND m.[Last Modifed When] <= s.[Valid To]
									     ORDER BY s.[Valid From]), 0),
            m.[Transaction Type Key] = COALESCE((SELECT TOP(1) tt.[Transaction Type Key]
                                                 FROM Dimension.[Transaction Type] AS tt
                                                 WHERE tt.[WWI Transaction Type ID] = m.[WWI Transaction Type ID]
                                                 AND m.[Last Modifed When] > tt.[Valid From]
                                                 AND m.[Last Modifed When] <= tt.[Valid To]
									             ORDER BY tt.[Valid From]), 0)
    FROM Integration.Movement_Staging AS m;

    -- Merge the data into the fact table

    MERGE Fact.Movement AS m
    USING Integration.Movement_Staging AS ms
    ON m.[WWI Stock Item Transaction ID] = ms.[WWI Stock Item Transaction ID]
    WHEN MATCHED THEN
        UPDATE SET m.[Date Key] = ms.[Date Key],
                   m.[Stock Item Key] = ms.[Stock Item Key],
                   m.[Customer Key] = ms.[Customer Key],
                   m.[Supplier Key] = ms.[Supplier Key],
                   m.[Transaction Type Key] = ms.[Transaction Type Key],
                   m.[WWI Invoice ID] = ms.[WWI Invoice ID],
                   m.[WWI Purchase Order ID] = ms.[WWI Purchase Order ID],
                   m.Quantity = ms.Quantity,
                   m.[Lineage Key] = @LineageKey
    WHEN NOT MATCHED THEN
        INSERT ([Date Key], [Stock Item Key], [Customer Key], [Supplier Key], [Transaction Type Key],
                [WWI Stock Item Transaction ID], [WWI Invoice ID], [WWI Purchase Order ID], Quantity, [Lineage Key])
        VALUES (ms.[Date Key], ms.[Stock Item Key], ms.[Customer Key], ms.[Supplier Key], ms.[Transaction Type Key],
                ms.[WWI Stock Item Transaction ID], ms.[WWI Invoice ID], ms.[WWI Purchase Order ID], ms.Quantity, @LineageKey);

    UPDATE Integration.Lineage
        SET [Data Load Completed] = SYSDATETIME(),
            [Was Successful] = 1
    WHERE [Lineage Key] = @LineageKey;

    UPDATE Integration.[ETL Cutoff]
        SET [Cutoff Time] = (SELECT [Source System Cutoff Time]
                             FROM Integration.Lineage
                             WHERE [Lineage Key] = @LineageKey)
    FROM Integration.[ETL Cutoff]
    WHERE [Table Name] = N'Movement';

    COMMIT;

    RETURN 0;
END;

GO

-- File: MigrateStagedOrderData.sql
﻿
CREATE PROCEDURE Integration.MigrateStagedOrderData
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRAN;

    DECLARE @LineageKey int = (SELECT TOP(1) [Lineage Key]
                               FROM Integration.Lineage
                               WHERE [Table Name] = N'Order'
                               AND [Data Load Completed] IS NULL
                               ORDER BY [Lineage Key] DESC);

    -- Find the dimension keys required

    UPDATE o
        SET o.[City Key] = COALESCE((SELECT TOP(1) c.[City Key]
                                     FROM Dimension.City AS c
                                     WHERE c.[WWI City ID] = o.[WWI City ID]
                                     AND o.[Last Modified When] > c.[Valid From]
                                     AND o.[Last Modified When] <= c.[Valid To]
									 ORDER BY c.[Valid From]), 0),
            o.[Customer Key] = COALESCE((SELECT TOP(1) c.[Customer Key]
                                         FROM Dimension.Customer AS c
                                         WHERE c.[WWI Customer ID] = o.[WWI Customer ID]
                                         AND o.[Last Modified When] > c.[Valid From]
                                         AND o.[Last Modified When] <= c.[Valid To]
    									 ORDER BY c.[Valid From]), 0),
            o.[Stock Item Key] = COALESCE((SELECT TOP(1) si.[Stock Item Key]
                                           FROM Dimension.[Stock Item] AS si
                                           WHERE si.[WWI Stock Item ID] = o.[WWI Stock Item ID]
                                           AND o.[Last Modified When] > si.[Valid From]
                                           AND o.[Last Modified When] <= si.[Valid To]
					                       ORDER BY si.[Valid From]), 0),
            o.[Salesperson Key] = COALESCE((SELECT TOP(1) e.[Employee Key]
                                         FROM Dimension.Employee AS e
                                         WHERE e.[WWI Employee ID] = o.[WWI Salesperson ID]
                                         AND o.[Last Modified When] > e.[Valid From]
                                         AND o.[Last Modified When] <= e.[Valid To]
									     ORDER BY e.[Valid From]), 0),
            o.[Picker Key] = COALESCE((SELECT TOP(1) e.[Employee Key]
                                       FROM Dimension.Employee AS e
                                       WHERE e.[WWI Employee ID] = o.[WWI Picker ID]
                                       AND o.[Last Modified When] > e.[Valid From]
                                       AND o.[Last Modified When] <= e.[Valid To]
									   ORDER BY e.[Valid From]), 0)
    FROM Integration.Order_Staging AS o;

    -- Remove any existing entries for any of these orders

    DELETE o
    FROM Fact.[Order] AS o
    WHERE o.[WWI Order ID] IN (SELECT [WWI Order ID] FROM Integration.Order_Staging);

    -- Insert all current details for these orders

    INSERT Fact.[Order]
        ([City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key],
         [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID], [Description],
         Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount],
         [Total Including Tax], [Lineage Key])
    SELECT [City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key],
           [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID], [Description],
           Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount],
           [Total Including Tax], @LineageKey
    FROM Integration.Order_Staging;

    UPDATE Integration.Lineage
        SET [Data Load Completed] = SYSDATETIME(),
            [Was Successful] = 1
    WHERE [Lineage Key] = @LineageKey;

    UPDATE Integration.[ETL Cutoff]
        SET [Cutoff Time] = (SELECT [Source System Cutoff Time]
                             FROM Integration.Lineage
                             WHERE [Lineage Key] = @LineageKey)
    FROM Integration.[ETL Cutoff]
    WHERE [Table Name] = N'Order';

    COMMIT;

    RETURN 0;
END;

GO

-- File: MigrateStagedPaymentMethodData.sql
﻿
CREATE PROCEDURE Integration.MigrateStagedPaymentMethodData
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999';

    BEGIN TRAN;

    DECLARE @LineageKey int = (SELECT TOP(1) [Lineage Key]
                               FROM Integration.Lineage
                               WHERE [Table Name] = N'Payment Method'
                               AND [Data Load Completed] IS NULL
                               ORDER BY [Lineage Key] DESC);

    WITH RowsToCloseOff
    AS
    (
        SELECT pm.[WWI Payment Method ID], MIN(pm.[Valid From]) AS [Valid From]
        FROM Integration.PaymentMethod_Staging AS pm
        GROUP BY pm.[WWI Payment Method ID]
    )
    UPDATE pm
        SET pm.[Valid To] = rtco.[Valid From]
    FROM Dimension.[Payment Method] AS pm
    INNER JOIN RowsToCloseOff AS rtco
    ON pm.[WWI Payment Method ID] = rtco.[WWI Payment Method ID]
    WHERE pm.[Valid To] = @EndOfTime;

    INSERT Dimension.[Payment Method]
        ([WWI Payment Method ID], [Payment Method], [Valid From], [Valid To], [Lineage Key])
    SELECT [WWI Payment Method ID], [Payment Method], [Valid From], [Valid To],
           @LineageKey
    FROM Integration.PaymentMethod_Staging;

    UPDATE Integration.Lineage
        SET [Data Load Completed] = SYSDATETIME(),
            [Was Successful] = 1
    WHERE [Lineage Key] = @LineageKey;

    UPDATE Integration.[ETL Cutoff]
        SET [Cutoff Time] = (SELECT [Source System Cutoff Time]
                             FROM Integration.Lineage
                             WHERE [Lineage Key] = @LineageKey)
    FROM Integration.[ETL Cutoff]
    WHERE [Table Name] = N'Payment Method';

    COMMIT;

    RETURN 0;
END;

GO

-- File: MigrateStagedPurchaseData.sql
﻿
CREATE PROCEDURE Integration.MigrateStagedPurchaseData
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRAN;

    DECLARE @LineageKey int = (SELECT TOP(1) [Lineage Key]
                               FROM Integration.Lineage
                               WHERE [Table Name] = N'Purchase'
                               AND [Data Load Completed] IS NULL
                               ORDER BY [Lineage Key] DESC);

    -- Find the dimension keys required

    UPDATE p
        SET p.[Supplier Key] = COALESCE((SELECT TOP(1) s.[Supplier Key]
                                     FROM Dimension.Supplier AS s
                                     WHERE s.[WWI Supplier ID] = p.[WWI Supplier ID]
                                     AND p.[Last Modified When] > s.[Valid From]
                                     AND p.[Last Modified When] <= s.[Valid To]
									 ORDER BY s.[Valid From]), 0),
            p.[Stock Item Key] = COALESCE((SELECT TOP(1) si.[Stock Item Key]
                                           FROM Dimension.[Stock Item] AS si
                                           WHERE si.[WWI Stock Item ID] = p.[WWI Stock Item ID]
                                           AND p.[Last Modified When] > si.[Valid From]
                                           AND p.[Last Modified When] <= si.[Valid To]
									       ORDER BY si.[Valid From]), 0)
    FROM Integration.Purchase_Staging AS p;

    -- Remove any existing entries for any of these purchase orders

    DELETE p
    FROM Fact.Purchase AS p
    WHERE p.[WWI Purchase Order ID] IN (SELECT [WWI Purchase Order ID] FROM Integration.Purchase_Staging);

    -- Insert all current details for these purchase orders

    INSERT Fact.Purchase
        ([Date Key], [Supplier Key], [Stock Item Key], [WWI Purchase Order ID], [Ordered Outers], [Ordered Quantity],
         [Received Outers], Package, [Is Order Finalized], [Lineage Key])
    SELECT [Date Key], [Supplier Key], [Stock Item Key], [WWI Purchase Order ID], [Ordered Outers], [Ordered Quantity],
           [Received Outers], Package, [Is Order Finalized], @LineageKey
    FROM Integration.Purchase_Staging;

    UPDATE Integration.Lineage
        SET [Data Load Completed] = SYSDATETIME(),
            [Was Successful] = 1
    WHERE [Lineage Key] = @LineageKey;

    UPDATE Integration.[ETL Cutoff]
        SET [Cutoff Time] = (SELECT [Source System Cutoff Time]
                             FROM Integration.Lineage
                             WHERE [Lineage Key] = @LineageKey)
    FROM Integration.[ETL Cutoff]
    WHERE [Table Name] = N'Purchase';

    COMMIT;

    RETURN 0;
END;

GO

-- File: MigrateStagedSaleData.sql
﻿
CREATE PROCEDURE Integration.MigrateStagedSaleData
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRAN;

    DECLARE @LineageKey int = (SELECT TOP(1) [Lineage Key]
                               FROM Integration.Lineage
                               WHERE [Table Name] = N'Sale'
                               AND [Data Load Completed] IS NULL
                               ORDER BY [Lineage Key] DESC);

    -- Find the dimension keys required

    UPDATE s
        SET s.[City Key] = COALESCE((SELECT TOP(1) c.[City Key]
                                     FROM Dimension.City AS c
                                     WHERE c.[WWI City ID] = s.[WWI City ID]
                                     AND s.[Last Modified When] > c.[Valid From]
                                     AND s.[Last Modified When] <= c.[Valid To]
									 ORDER BY c.[Valid From]), 0),
            s.[Customer Key] = COALESCE((SELECT TOP(1) c.[Customer Key]
                                           FROM Dimension.Customer AS c
                                           WHERE c.[WWI Customer ID] = s.[WWI Customer ID]
                                           AND s.[Last Modified When] > c.[Valid From]
                                           AND s.[Last Modified When] <= c.[Valid To]
									       ORDER BY c.[Valid From]), 0),
            s.[Bill To Customer Key] = COALESCE((SELECT TOP(1) c.[Customer Key]
                                                 FROM Dimension.Customer AS c
                                                 WHERE c.[WWI Customer ID] = s.[WWI Bill To Customer ID]
                                                 AND s.[Last Modified When] > c.[Valid From]
                                                 AND s.[Last Modified When] <= c.[Valid To]
									             ORDER BY c.[Valid From]), 0),
            s.[Stock Item Key] = COALESCE((SELECT TOP(1) si.[Stock Item Key]
                                           FROM Dimension.[Stock Item] AS si
                                           WHERE si.[WWI Stock Item ID] = s.[WWI Stock Item ID]
                                           AND s.[Last Modified When] > si.[Valid From]
                                           AND s.[Last Modified When] <= si.[Valid To]
									       ORDER BY si.[Valid From]), 0),
            s.[Salesperson Key] = COALESCE((SELECT TOP(1) e.[Employee Key]
                                            FROM Dimension.Employee AS e
                                            WHERE e.[WWI Employee ID] = s.[WWI Salesperson ID]
                                            AND s.[Last Modified When] > e.[Valid From]
                                            AND s.[Last Modified When] <= e.[Valid To]
									        ORDER BY e.[Valid From]), 0)
    FROM Integration.Sale_Staging AS s;

    -- Remove any existing entries for any of these invoices

    DELETE s
    FROM Fact.Sale AS s
    WHERE s.[WWI Invoice ID] IN (SELECT [WWI Invoice ID] FROM Integration.Sale_Staging);

    -- Insert all current details for these invoices

    INSERT Fact.Sale
        ([City Key], [Customer Key], [Bill To Customer Key], [Stock Item Key], [Invoice Date Key], [Delivery Date Key],
         [Salesperson Key], [WWI Invoice ID], [Description], Package, Quantity, [Unit Price], [Tax Rate],
         [Total Excluding Tax], [Tax Amount], Profit, [Total Including Tax], [Total Dry Items], [Total Chiller Items], [Lineage Key])
    SELECT [City Key], [Customer Key], [Bill To Customer Key], [Stock Item Key], [Invoice Date Key], [Delivery Date Key],
           [Salesperson Key], [WWI Invoice ID], [Description], Package, Quantity, [Unit Price], [Tax Rate],
           [Total Excluding Tax], [Tax Amount], Profit, [Total Including Tax], [Total Dry Items], [Total Chiller Items], @LineageKey
    FROM Integration.Sale_Staging;

    UPDATE Integration.Lineage
        SET [Data Load Completed] = SYSDATETIME(),
            [Was Successful] = 1
    WHERE [Lineage Key] = @LineageKey;

    UPDATE Integration.[ETL Cutoff]
        SET [Cutoff Time] = (SELECT [Source System Cutoff Time]
                             FROM Integration.Lineage
                             WHERE [Lineage Key] = @LineageKey)
    FROM Integration.[ETL Cutoff]
    WHERE [Table Name] = N'Sale';

    COMMIT;

    RETURN 0;
END;

GO

-- File: MigrateStagedStockHoldingData.sql
﻿
CREATE PROCEDURE Integration.MigrateStagedStockHoldingData
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRAN;

    DECLARE @LineageKey int = (SELECT TOP(1) [Lineage Key]
                               FROM Integration.Lineage
                               WHERE [Table Name] = N'Stock Holding'
                               AND [Data Load Completed] IS NULL
                               ORDER BY [Lineage Key] DESC);

    -- Find the dimension keys required

    UPDATE s
        SET s.[Stock Item Key] = COALESCE((SELECT TOP(1) si.[Stock Item Key]
                                           FROM Dimension.[Stock Item] AS si
                                           WHERE si.[WWI Stock Item ID] = s.[WWI Stock Item ID]
                                           ORDER BY si.[Valid To] DESC), 0)
    FROM Integration.StockHolding_Staging AS s;

    -- Remove all existing holdings

    TRUNCATE TABLE Fact.[Stock Holding];

    -- Insert all current stock holdings

    INSERT Fact.[Stock Holding]
        ([Stock Item Key], [Quantity On Hand], [Bin Location], [Last Stocktake Quantity],
         [Last Cost Price], [Reorder Level], [Target Stock Level], [Lineage Key])
    SELECT [Stock Item Key], [Quantity On Hand], [Bin Location], [Last Stocktake Quantity],
           [Last Cost Price], [Reorder Level], [Target Stock Level], @LineageKey
    FROM Integration.StockHolding_Staging;

    UPDATE Integration.Lineage
        SET [Data Load Completed] = SYSDATETIME(),
            [Was Successful] = 1
    WHERE [Lineage Key] = @LineageKey;

    UPDATE Integration.[ETL Cutoff]
        SET [Cutoff Time] = (SELECT [Source System Cutoff Time]
                             FROM Integration.Lineage
                             WHERE [Lineage Key] = @LineageKey)
    FROM Integration.[ETL Cutoff]
    WHERE [Table Name] = N'Stock Holding';

    COMMIT;

    RETURN 0;
END;

GO

-- File: MigrateStagedStockItemData.sql
﻿
CREATE PROCEDURE Integration.MigrateStagedStockItemData
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999';

    BEGIN TRAN;

    DECLARE @LineageKey int = (SELECT TOP(1) [Lineage Key]
                               FROM Integration.Lineage
                               WHERE [Table Name] = N'Stock Item'
                               AND [Data Load Completed] IS NULL
                               ORDER BY [Lineage Key] DESC);

    WITH RowsToCloseOff
    AS
    (
        SELECT s.[WWI Stock Item ID], MIN(s.[Valid From]) AS [Valid From]
        FROM Integration.StockItem_Staging AS s
        GROUP BY s.[WWI Stock Item ID]
    )
    UPDATE s
        SET s.[Valid To] = rtco.[Valid From]
    FROM Dimension.[Stock Item] AS s
    INNER JOIN RowsToCloseOff AS rtco
    ON s.[WWI Stock Item ID] = rtco.[WWI Stock Item ID]
    WHERE s.[Valid To] = @EndOfTime;

    INSERT Dimension.[Stock Item]
        ([WWI Stock Item ID], [Stock Item], Color, [Selling Package], [Buying Package],
         Brand, Size, [Lead Time Days], [Quantity Per Outer], [Is Chiller Stock],
         Barcode, [Tax Rate], [Unit Price], [Recommended Retail Price], [Typical Weight Per Unit],
         Photo, [Valid From], [Valid To], [Lineage Key])
    SELECT [WWI Stock Item ID], [Stock Item], Color, [Selling Package], [Buying Package],
           Brand, Size, [Lead Time Days], [Quantity Per Outer], [Is Chiller Stock],
           Barcode, [Tax Rate], [Unit Price], [Recommended Retail Price], [Typical Weight Per Unit],
           Photo, [Valid From], [Valid To],
           @LineageKey
    FROM Integration.StockItem_Staging;

    UPDATE Integration.Lineage
        SET [Data Load Completed] = SYSDATETIME(),
            [Was Successful] = 1
    WHERE [Lineage Key] = @LineageKey;

    UPDATE Integration.[ETL Cutoff]
        SET [Cutoff Time] = (SELECT [Source System Cutoff Time]
                             FROM Integration.Lineage
                             WHERE [Lineage Key] = @LineageKey)
    FROM Integration.[ETL Cutoff]
    WHERE [Table Name] = N'Stock Item';

    COMMIT;

    RETURN 0;
END;

GO

-- File: MigrateStagedSupplierData.sql
﻿
CREATE PROCEDURE Integration.MigrateStagedSupplierData
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999';

    BEGIN TRAN;

    DECLARE @LineageKey int = (SELECT TOP(1) [Lineage Key]
                               FROM Integration.Lineage
                               WHERE [Table Name] = N'Supplier'
                               AND [Data Load Completed] IS NULL
                               ORDER BY [Lineage Key] DESC);

    WITH RowsToCloseOff
    AS
    (
        SELECT s.[WWI Supplier ID], MIN(s.[Valid From]) AS [Valid From]
        FROM Integration.Supplier_Staging AS s
        GROUP BY s.[WWI Supplier ID]
    )
    UPDATE s
        SET s.[Valid To] = rtco.[Valid From]
    FROM Dimension.[Supplier] AS s
    INNER JOIN RowsToCloseOff AS rtco
    ON s.[WWI Supplier ID] = rtco.[WWI Supplier ID]
    WHERE s.[Valid To] = @EndOfTime;

    INSERT Dimension.[Supplier]
        ([WWI Supplier ID], Supplier, Category, [Primary Contact], [Supplier Reference],
         [Payment Days], [Postal Code], [Valid From], [Valid To], [Lineage Key])
    SELECT [WWI Supplier ID], Supplier, Category, [Primary Contact], [Supplier Reference],
           [Payment Days], [Postal Code], [Valid From], [Valid To],
           @LineageKey
    FROM Integration.Supplier_Staging;

    UPDATE Integration.Lineage
        SET [Data Load Completed] = SYSDATETIME(),
            [Was Successful] = 1
    WHERE [Lineage Key] = @LineageKey;

    UPDATE Integration.[ETL Cutoff]
        SET [Cutoff Time] = (SELECT [Source System Cutoff Time]
                             FROM Integration.Lineage
                             WHERE [Lineage Key] = @LineageKey)
    FROM Integration.[ETL Cutoff]
    WHERE [Table Name] = N'Supplier';

    COMMIT;

    RETURN 0;
END;

GO

-- File: MigrateStagedTransactionData.sql
﻿
CREATE PROCEDURE Integration.MigrateStagedTransactionData
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRAN;

    DECLARE @LineageKey int = (SELECT TOP(1) [Lineage Key]
                               FROM Integration.Lineage
                               WHERE [Table Name] = N'Transaction'
                               AND [Data Load Completed] IS NULL
                               ORDER BY [Lineage Key] DESC);

    -- Find the dimension keys required

    UPDATE t
        SET t.[Customer Key] = COALESCE((SELECT TOP(1) c.[Customer Key]
                                         FROM Dimension.Customer AS c
                                         WHERE c.[WWI Customer ID] = t.[WWI Customer ID]
                                         AND t.[Last Modified When] > c.[Valid From]
                                         AND t.[Last Modified When] <= c.[Valid To]
									     ORDER BY c.[Valid From]), 0),
            t.[Bill To Customer Key] = COALESCE((SELECT TOP(1) c.[Customer Key]
                                                 FROM Dimension.Customer AS c
                                                 WHERE c.[WWI Customer ID] = t.[WWI Bill To Customer ID]
                                                 AND t.[Last Modified When] > c.[Valid From]
                                                 AND t.[Last Modified When] <= c.[Valid To]
									             ORDER BY c.[Valid From]), 0),
            t.[Supplier Key] = COALESCE((SELECT TOP(1) s.[Supplier Key]
                                         FROM Dimension.Supplier AS s
                                         WHERE s.[WWI Supplier ID] = t.[WWI Supplier ID]
                                         AND t.[Last Modified When] > s.[Valid From]
                                         AND t.[Last Modified When] <= s.[Valid To]
									     ORDER BY s.[Valid From]), 0),
            t.[Transaction Type Key] = COALESCE((SELECT TOP(1) tt.[Transaction Type Key]
                                                 FROM Dimension.[Transaction Type] AS tt
                                                 WHERE tt.[WWI Transaction Type ID] = t.[WWI Transaction Type ID]
                                                 AND t.[Last Modified When] > tt.[Valid From]
                                                 AND t.[Last Modified When] <= tt.[Valid To]
									             ORDER BY tt.[Valid From]), 0),
            t.[Payment Method Key] = COALESCE((SELECT TOP(1) pm.[Payment Method Key]
                                                 FROM Dimension.[Payment Method] AS pm
                                                 WHERE pm.[WWI Payment Method ID] = t.[WWI Payment Method ID]
                                                 AND t.[Last Modified When] > pm.[Valid From]
                                                 AND t.[Last Modified When] <= pm.[Valid To]
									             ORDER BY pm.[Valid From]), 0)
    FROM Integration.Transaction_Staging AS t;

    -- Insert all the transactions

    INSERT Fact.[Transaction]
        ([Date Key], [Customer Key], [Bill To Customer Key], [Supplier Key], [Transaction Type Key],
         [Payment Method Key], [WWI Customer Transaction ID], [WWI Supplier Transaction ID],
         [WWI Invoice ID], [WWI Purchase Order ID], [Supplier Invoice Number], [Total Excluding Tax],
         [Tax Amount], [Total Including Tax], [Outstanding Balance], [Is Finalized], [Lineage Key])
    SELECT [Date Key], [Customer Key], [Bill To Customer Key], [Supplier Key], [Transaction Type Key],
         [Payment Method Key], [WWI Customer Transaction ID], [WWI Supplier Transaction ID],
         [WWI Invoice ID], [WWI Purchase Order ID], [Supplier Invoice Number], [Total Excluding Tax],
         [Tax Amount], [Total Including Tax], [Outstanding Balance], [Is Finalized], @LineageKey
    FROM Integration.Transaction_Staging;

    UPDATE Integration.Lineage
        SET [Data Load Completed] = SYSDATETIME(),
            [Was Successful] = 1
    WHERE [Lineage Key] = @LineageKey;

    UPDATE Integration.[ETL Cutoff]
        SET [Cutoff Time] = (SELECT [Source System Cutoff Time]
                             FROM Integration.Lineage
                             WHERE [Lineage Key] = @LineageKey)
    FROM Integration.[ETL Cutoff]
    WHERE [Table Name] = N'Transaction';

    COMMIT;

    RETURN 0;
END;

GO

-- File: MigrateStagedTransactionTypeData.sql
﻿
CREATE PROCEDURE Integration.MigrateStagedTransactionTypeData
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999';

    BEGIN TRAN;

    DECLARE @LineageKey int = (SELECT TOP(1) [Lineage Key]
                               FROM Integration.Lineage
                               WHERE [Table Name] = N'Transaction Type'
                               AND [Data Load Completed] IS NULL
                               ORDER BY [Lineage Key] DESC);

    WITH RowsToCloseOff
    AS
    (
        SELECT pm.[WWI Transaction Type ID], MIN(pm.[Valid From]) AS [Valid From]
        FROM Integration.TransactionType_Staging AS pm
        GROUP BY pm.[WWI Transaction Type ID]
    )
    UPDATE pm
        SET pm.[Valid To] = rtco.[Valid From]
    FROM Dimension.[Transaction Type] AS pm
    INNER JOIN RowsToCloseOff AS rtco
    ON pm.[WWI Transaction Type ID] = rtco.[WWI Transaction Type ID]
    WHERE pm.[Valid To] = @EndOfTime;

    INSERT Dimension.[Transaction Type]
        ([WWI Transaction Type ID], [Transaction Type], [Valid From], [Valid To], [Lineage Key])
    SELECT [WWI Transaction Type ID], [Transaction Type], [Valid From], [Valid To],
           @LineageKey
    FROM Integration.TransactionType_Staging;

    UPDATE Integration.Lineage
        SET [Data Load Completed] = SYSDATETIME(),
            [Was Successful] = 1
    WHERE [Lineage Key] = @LineageKey;

    UPDATE Integration.[ETL Cutoff]
        SET [Cutoff Time] = (SELECT [Source System Cutoff Time]
                             FROM Integration.Lineage
                             WHERE [Lineage Key] = @LineageKey)
    FROM Integration.[ETL Cutoff]
    WHERE [Table Name] = N'Transaction Type';

    COMMIT;

    RETURN 0;
END;

GO

-- File: PopulateDateDimensionForYear.sql
﻿CREATE PROCEDURE Integration.PopulateDateDimensionForYear
@YearNumber int
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @DateCounter date = DATEFROMPARTS(@YearNumber, 1, 1);

    BEGIN TRY;

        BEGIN TRAN;

        WHILE YEAR(@DateCounter) = @YearNumber
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM Dimension.[Date] WHERE [Date] = @DateCounter)
            BEGIN
                INSERT Dimension.[Date]
                       ( [Date]
                       , [DateKey]
                       , [Day Number]
                       , [Day]
                       , [Day of Year]
                       , [Day of Year Number]
                       , [Day of Week]
                       , [Day of Week Number]
                       , [Week of Year]
                       , [Month]
                       , [Short Month]
                       , [Quarter]
                       , [Half of Year]
                       , [Beginning of Month]
                       , [Beginning of Quarter]
                       , [Beginning of Half Year]
                       , [Beginning of Year]
                       , [Beginning of Month Label]
                       , [Beginning of Month Label Short]
                       , [Beginning of Quarter Label]
                       , [Beginning of Quarter Label Short]
                       , [Beginning of Half Year Label]
                       , [Beginning of Half Year Label Short]
                       , [Beginning of Year Label]
                       , [Beginning of Year Label Short]
                       , [Calendar Day Label]
                       , [Calendar Day Label Short]
                       , [Calendar Week Number]
                       , [Calendar Week Label]
                       , [Calendar Month Number]
                       , [Calendar Month Label]
                       , [Calendar Month Year Label]
                       , [Calendar Quarter Number]
                       , [Calendar Quarter Label]
                       , [Calendar Quarter Year Label]
                       , [Calendar Half of Year Number]
                       , [Calendar Half of Year Label]
                       , [Calendar Year Half of Year Label]
                       , [Calendar Year]
                       , [Calendar Year Label]
                       , [Fiscal Month Number]
                       , [Fiscal Month Label]
                       , [Fiscal Quarter Number]
                       , [Fiscal Quarter Label]
                       , [Fiscal Half of Year Number]
                       , [Fiscal Half of Year Label]
                       , [Fiscal Year]
                       , [Fiscal Year Label]
                       , [Date Key]
                       , [Year Week Key]
                       , [Year Month Key]
                       , [Year Quarter Key]
                       , [Year Half of Year Key]
                       , [Year Key]
                       , [Beginning of Month Key]
                       , [Beginning of Quarter Key]
                       , [Beginning of Half Year Key]
                       , [Beginning of Year Key]
                       , [Fiscal Year Month Key]
                       , [Fiscal Year Quarter Key]
                       , [Fiscal Year Half of Year Key]
                       , [ISO Week Number]
                       )
                SELECT [Date]
                       , [DateKey]
                       , [Day Number]
                       , [Day]
                       , [Day of Year]
                       , [Day of Year Number]
                       , [Day of Week]
                       , [Day of Week Number]
                       , [Week of Year]
                       , [Month]
                       , [Short Month]
                       , [Quarter]
                       , [Half of Year]
                       , [Beginning of Month]
                       , [Beginning of Quarter]
                       , [Beginning of Half of Year]
                       , [Beginning of Year]
                       , [Beginning of Month Label]
                       , [Beginning of Month Label Short]
                       , [Beginning of Quarter Label]
                       , [Beginning of Quarter Label Short]
                       , [Beginning of Half Year Label]
                       , [Beginning of Half Year Label Short]
                       , [Beginning of Year Label]
                       , [Beginning of Year Label Short]
                       , [Calendar Day Label]
                       , [Calendar Day Label Short]
                       , [Calendar Week Number]
                       , [Calendar Week Label]
                       , [Calendar Month Number]
                       , [Calendar Month Label]
                       , [Calendar Month Year Label]
                       , [Calendar Quarter Number]
                       , [Calendar Quarter Label]
                       , [Calendar Quarter Year Label]
                       , [Calendar Half of Year Number]
                       , [Calendar Half of Year Label]
                       , [Calendar Year Half of Year Label]
                       , [Calendar Year]
                       , [Calendar Year Label]
                       , [Fiscal Month Number]
                       , [Fiscal Month Label]
                       , [Fiscal Quarter Number]
                       , [Fiscal Quarter Label]
                       , [Fiscal Half of Year Number]
                       , [Fiscal Half of Year Label]
                       , [Fiscal Year]
                       , [Fiscal Year Label]
                       , [Date Key]
                       , [Year Week Key]
                       , [Year Month Key]
                       , [Year Quarter Key]
                       , [Year Half of Year Key]
                       , [Year Key]
                       , [Beginning of Month Key]
                       , [Beginning of Quarter Key]
                       , [Beginning of Half of Year Key]
                       , [Beginning of Year Key]
                       , [Fiscal Year Month Key]
                       , [Fiscal Year Quarter Key]
                       , [Fiscal Year Half of Year Key]
                       , [ISO Week Number]
                    FROM Integration.GenerateDateDimensionColumns(@DateCounter);
            END;
            SET @DateCounter = DATEADD(day, 1, @DateCounter);
        END;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        PRINT N'Unable to populate dates for the year';
        THROW;
        RETURN -1;
    END CATCH;

    RETURN 0;
END;

GO

-- File: ReseedAllSequences.sql
﻿
CREATE PROCEDURE Sequences.ReseedAllSequences
AS BEGIN
    -- Ensures that the next sequence values are above the maximum value of the related table columns
    SET NOCOUNT ON;

    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'CityKey', @SchemaName = 'Dimension', @TableName = 'City', @ColumnName = 'City Key';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'CustomerKey', @SchemaName = 'Dimension', @TableName = 'Customer', @ColumnName = 'Customer Key';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'EmployeeKey', @SchemaName = 'Dimension', @TableName = 'Employee', @ColumnName = 'Employee Key';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'LineageKey', @SchemaName = 'Integration', @TableName = 'Lineage', @ColumnName = 'Lineage Key';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'PaymentMethodKey', @SchemaName = 'Dimension', @TableName = 'Payment Method', @ColumnName = 'Payment Method Key';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'StockItemKey', @SchemaName = 'Dimension', @TableName = 'Stock Item', @ColumnName = 'Stock Item Key';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'SupplierKey', @SchemaName = 'Dimension', @TableName = 'Supplier', @ColumnName = 'Supplier Key';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'TransactionTypeKey', @SchemaName = 'Dimension', @TableName = 'Transaction Type', @ColumnName = 'Transaction Type Key';
END;

GO

-- File: ReseedSequenceBeyondTableValues.sql
﻿
CREATE PROCEDURE Sequences.ReseedSequenceBeyondTableValues
@SequenceName sysname,
@SchemaName sysname,
@TableName sysname,
@ColumnName sysname
AS BEGIN
    -- Ensures that the next sequence value is above the maximum value of the supplied table column
    SET NOCOUNT ON;

    DECLARE @SQL nvarchar(max);
    DECLARE @CurrentTableMaximumValue bigint;
    DECLARE @NewSequenceValue bigint;
    DECLARE @CurrentSequenceMaximumValue bigint
        = (SELECT CAST(current_value AS bigint) FROM sys.sequences
                                                WHERE name = @SequenceName
                                                AND SCHEMA_NAME(schema_id) = N'Sequences');
    CREATE TABLE #CurrentValue
    (
        CurrentValue bigint
    )

    SET @SQL = N'INSERT #CurrentValue (CurrentValue) SELECT COALESCE(MAX(' + QUOTENAME(@ColumnName) + N'), 0) FROM ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + N';';
    EXECUTE (@SQL);
    SET @CurrentTableMaximumValue = (SELECT CurrentValue FROM #CurrentValue);
    DROP TABLE #CurrentValue;

    IF @CurrentTableMaximumValue >= @CurrentSequenceMaximumValue
    BEGIN
        SET @NewSequenceValue = @CurrentTableMaximumValue + 1;
        SET @SQL = N'ALTER SEQUENCE Sequences.' + QUOTENAME(@SequenceName) + N' RESTART WITH ' + CAST(@NewSequenceValue AS nvarchar(20)) + N';';
        EXECUTE (@SQL);
    END;
END;

GO
