-- WideWorldImporters OLTP Database Stored Procedures - microsoft/sql-server-samples (MIT License)
-- Source: https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/wide-world-importers/wwi-ssdt


-- File: AddRoleMemberIfNonexistent.sql
﻿
CREATE PROCEDURE [Application].AddRoleMemberIfNonexistent
@RoleName sysname,
@UserName sysname
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM sys.database_role_members AS drm
                            INNER JOIN sys.database_principals AS dpr
                            ON drm.role_principal_id = dpr.principal_id
                            AND dpr.type = N'R'
                            INNER JOIN sys.database_principals AS dpu
                            ON drm.member_principal_id = dpu.principal_id
                            AND dpu.type = N'S'
                            WHERE dpr.name = @RoleName
                            AND dpu.name = @UserName)
    BEGIN
        BEGIN TRY

            DECLARE @SQL nvarchar(max) = N'ALTER ROLE ' + QUOTENAME(@RoleName)
                                       + N' ADD MEMBER ' + QUOTENAME(@UserName) + N';'
            EXECUTE (@SQL);

            PRINT N'User ' + @UserName + N' added to role ' + @RoleName;

        END TRY
        BEGIN CATCH
            PRINT N'Unable to add user ' + @UserName + N' to role ' + @RoleName;
            THROW;
        END CATCH;
    END;
END;

GO

-- File: Configuration_ApplyAuditing.sql
﻿
CREATE PROCEDURE [Application].Configuration_ApplyAuditing
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AreDatabaseAuditSpecificationsSupported bit = 0;
    DECLARE @SQL nvarchar(max);

    -- TODO !! - currently no separate test for audit
    -- but same editions with XTP support database audit specs
    IF SERVERPROPERTY(N'IsXTPSupported') <> 0 SET @AreDatabaseAuditSpecificationsSupported = 1;

    BEGIN TRY;

        IF NOT EXISTS (SELECT 1 FROM sys.server_audits WHERE name = N'WWI_Audit')
        BEGIN
            SET @SQL = N'
USE master;

CREATE SERVER AUDIT [WWI_Audit]
TO APPLICATION_LOG
WITH
(
    QUEUE_DELAY = 1000,
	ON_FAILURE = CONTINUE
);';
            EXECUTE (@SQL);

            PRINT N'Server audit WWI_Audit created with Application Log as a target.';
            PRINT N'For stronger security, redirect the audit to the security log or a text file in a secure folder.';
            PRINT N'Additional configuration is required when using the security log.';
            PRINT N'For more information see: https://technet.microsoft.com/en-us/library/cc645889.aspx.';
        END;

        IF NOT EXISTS (SELECT 1 FROM sys.server_audit_specifications WHERE name = N'WWI_ServerAuditSpecification')
        BEGIN
            SET @SQL = N'
USE master;

CREATE SERVER AUDIT SPECIFICATION [WWI_ServerAuditSpecification]
FOR SERVER AUDIT [WWI_Audit]
ADD (AUDIT_CHANGE_GROUP),
ADD (DATABASE_CHANGE_GROUP),
ADD (DATABASE_OWNERSHIP_CHANGE_GROUP),
ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),
ADD (FAILED_LOGIN_GROUP),
ADD (TRACE_CHANGE_GROUP);';
            EXECUTE (@SQL);
        END;

        IF @AreDatabaseAuditSpecificationsSupported <> 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM sys.database_audit_specifications WHERE name = N'WWI_DatabaseAuditSpecification')
            BEGIN
                SET @SQL = N'
CREATE DATABASE AUDIT SPECIFICATION [WWI_DatabaseAuditSpecification]
FOR SERVER AUDIT [WWI_Audit]
ADD (AUDIT_CHANGE_GROUP),
ADD (DATABASE_CHANGE_GROUP),
ADD (DATABASE_OWNERSHIP_CHANGE_GROUP),
ADD (DATABASE_PRINCIPAL_CHANGE_GROUP),
ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),
ADD (DATABASE_OBJECT_CHANGE_GROUP),
ADD (SELECT ON OBJECT::[Sales].[CustomerTransactions] BY [public]),
ADD (SELECT ON OBJECT::[Purchasing].[SupplierTransactions] BY [public]);';
                EXECUTE (@SQL);
            END;
        END;

    END TRY
    BEGIN CATCH
        PRINT N'Unable to apply audit';
        THROW;
    END CATCH;
END;

GO

-- File: Configuration_ApplyColumnstoreIndexing.sql
﻿
CREATE PROCEDURE [Application].Configuration_ApplyColumnstoreIndexing
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF SERVERPROPERTY(N'IsXTPSupported') = 0 -- TODO !! - currently no separate test for columnstore
    BEGIN                                    -- but same editions with XTP support columnstore
        PRINT N'Warning: Columnstore indexes cannot be created on this edition.';
    END ELSE BEGIN -- if columnstore can be created
        DECLARE @SQL nvarchar(max) = N'';

        BEGIN TRY;

            BEGIN TRAN;

            -- enable page compression on archive tables
            SET @SQL = N''
            SELECT @SQL +=N'
ALTER INDEX [' + i.name + N'] ON [' + schema_name(o.schema_id) + N'].[' + o.name + N'] REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, DATA_COMPRESSION = PAGE);  '
            FROM sys.indexes i JOIN sys.tables o ON i.object_id=o.object_id
            WHERE o.temporal_type = 1 AND i.type=1
            EXECUTE (@SQL);

            IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'NCCX_Sales_OrderLines')
            BEGIN
                SET @SQL = N'
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCX_Sales_OrderLines
ON Sales.OrderLines
(
    OrderID,
    StockItemID,
	[Description],
    Quantity,
    UnitPrice,
    PickedQuantity
)';
				SET @SQL += N';';
                EXECUTE (@SQL);
            END;

            IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'NCCX_Sales_InvoiceLines')
            BEGIN
                SET @SQL = N'
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCX_Sales_InvoiceLines
ON Sales.InvoiceLines
(
    InvoiceID,
    StockItemID,
    Quantity,
    UnitPrice,
    LineProfit,
    LastEditedWhen
)';
				SET @SQL += N';';
                EXECUTE (@SQL);
            END;

            IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'CCX_Warehouse_StockItemTransactions')
            BEGIN
                SET @SQL = N'
ALTER TABLE Warehouse.StockItemTransactions
DROP CONSTRAINT PK_Warehouse_StockItemTransactions;';
                EXECUTE (@SQL);

                SET @SQL = N'
ALTER TABLE Warehouse.StockItemTransactions
ADD CONSTRAINT PK_Warehouse_StockItemTransactions PRIMARY KEY NONCLUSTERED (StockItemTransactionID);';
                EXECUTE (@SQL);

                SET @SQL = N'
CREATE CLUSTERED COLUMNSTORE INDEX CCX_Warehouse_StockItemTransactions
ON Warehouse.StockItemTransactions;';
                EXECUTE (@SQL);

                SET @SQL = N'
ALTER INDEX CCX_Warehouse_StockItemTransactions
ON Warehouse.StockItemTransactions
REORGANIZE WITH (COMPRESS_ALL_ROW_GROUPS = ON);';
                EXECUTE (@SQL);

                PRINT N'Successfully applied columnstore indexing';
            END; -- of if need to apply to stock item transactions

            COMMIT;
        END TRY
        BEGIN CATCH
            PRINT N'Unable to apply columnstore indexing';
            THROW;
        END CATCH;
    END; -- of columnstore is allowed
END;

GO

-- File: Configuration_ApplyFullTextIndexing.sql
﻿
CREATE PROCEDURE [Application].Configuration_ApplyFullTextIndexing
WITH EXECUTE AS OWNER
AS
BEGIN
    IF SERVERPROPERTY(N'IsFullTextInstalled') = 0
    BEGIN
        PRINT N'Warning: Full text options cannot be configured because full text indexing is not installed.';
    END ELSE BEGIN -- if full text is installed
        DECLARE @SQL nvarchar(max) = N'';

        IF NOT EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = N'FTCatalog')
        BEGIN
            SET @SQL =  N'CREATE FULLTEXT CATALOG FTCatalog AS DEFAULT;'
            EXECUTE (@SQL);
        END;

        IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes AS fti WHERE fti.object_id = OBJECT_ID(N'[Application].People'))
        BEGIN
            SET @SQL = N'
CREATE FULLTEXT INDEX
ON [Application].People (SearchName, CustomFields, OtherLanguages)
KEY INDEX PK_Application_People
WITH CHANGE_TRACKING AUTO;';
            EXECUTE (@SQL);
        END;

        IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes AS fti WHERE fti.object_id = OBJECT_ID(N'Sales.Customers'))
        BEGIN
            SET @SQL = N'
CREATE FULLTEXT INDEX
ON Sales.Customers (CustomerName)
KEY INDEX PK_Sales_Customers
WITH CHANGE_TRACKING AUTO;';
            EXECUTE (@SQL);
        END;

        IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes AS fti WHERE fti.object_id = OBJECT_ID(N'Purchasing.Suppliers'))
        BEGIN
            SET @SQL = N'
CREATE FULLTEXT INDEX
ON Purchasing.Suppliers (SupplierName)
KEY INDEX PK_Purchasing_Suppliers
WITH CHANGE_TRACKING AUTO;';
            EXECUTE (@SQL);
        END;


        IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes AS fti WHERE fti.object_id = OBJECT_ID(N'Warehouse.StockItems'))
        BEGIN
            SET @SQL = N'CREATE FULLTEXT INDEX
ON Warehouse.StockItems (SearchDetails, CustomFields, Tags)
KEY INDEX PK_Warehouse_StockItems
WITH CHANGE_TRACKING AUTO;';
            EXECUTE (@SQL);
        END;

        SET @SQL = N'DROP PROCEDURE IF EXISTS Website.SearchForPeople;';
        EXECUTE (@SQL);

        SET @SQL = N'
CREATE PROCEDURE Website.SearchForPeople
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
AS
BEGIN
    SELECT p.PersonID,
           p.FullName,
           p.PreferredName,
           CASE WHEN p.IsSalesperson <> 0 THEN N''Salesperson''
                WHEN p.IsEmployee <> 0 THEN N''Employee''
                WHEN c.CustomerID IS NOT NULL THEN N''Customer''
                WHEN sp.SupplierID IS NOT NULL THEN N''Supplier''
                WHEN sa.SupplierID IS NOT NULL THEN N''Supplier''
           END AS Relationship,
           COALESCE(c.CustomerName, sp.SupplierName, sa.SupplierName, N''WWI'') AS Company
    FROM [Application].People AS p
    INNER JOIN FREETEXTTABLE([Application].People, SearchName, @SearchText, @MaximumRowsToReturn) AS ft
    ON p.PersonID = ft.[KEY]
    LEFT OUTER JOIN Sales.Customers AS c
    ON c.PrimaryContactPersonID = p.PersonID
    LEFT OUTER JOIN Purchasing.Suppliers AS sp
    ON sp.PrimaryContactPersonID = p.PersonID
    LEFT OUTER JOIN Purchasing.Suppliers AS sa
    ON sa.AlternateContactPersonID = p.PersonID
    ORDER BY ft.[RANK]
    FOR JSON AUTO, ROOT(N''People'');
END;';
        EXECUTE (@SQL);

        SET @SQL = N'DROP PROCEDURE IF EXISTS Website.SearchForSuppliers;';
        EXECUTE (@SQL);

        SET @SQL = N'
CREATE PROCEDURE Website.SearchForSuppliers
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
AS
BEGIN
    SELECT s.SupplierID,
           s.SupplierName,
           c.CityName,
           s.PhoneNumber,
           s.FaxNumber ,
           p.FullName AS PrimaryContactFullName,
           p.PreferredName AS PrimaryContactPreferredName
    FROM Purchasing.Suppliers AS s
    INNER JOIN FREETEXTTABLE(Purchasing.Suppliers, SupplierName, @SearchText, @MaximumRowsToReturn) AS ft
    ON s.SupplierID = ft.[KEY]
    INNER JOIN [Application].Cities AS c
    ON s.DeliveryCityID = c.CityID
    LEFT OUTER JOIN [Application].People AS p
    ON s.PrimaryContactPersonID = p.PersonID
    ORDER BY ft.[RANK]
    FOR JSON AUTO, ROOT(N''Suppliers'');
END;';
        EXECUTE (@SQL);

        SET @SQL = N'DROP PROCEDURE IF EXISTS Website.SearchForCustomers;';
        EXECUTE (@SQL);

        SET @SQL = N'
CREATE PROCEDURE Website.SearchForCustomers
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
WITH EXECUTE AS OWNER
AS
BEGIN
    SELECT c.CustomerID,
           c.CustomerName,
           ct.CityName,
           c.PhoneNumber,
           c.FaxNumber,
           p.FullName AS PrimaryContactFullName,
           p.PreferredName AS PrimaryContactPreferredName
    FROM Sales.Customers AS c
    INNER JOIN FREETEXTTABLE(Sales.Customers, CustomerName, @SearchText, @MaximumRowsToReturn) AS ft
    ON c.CustomerID = ft.[KEY]
    INNER JOIN [Application].Cities AS ct
    ON c.DeliveryCityID = ct.CityID
    LEFT OUTER JOIN [Application].People AS p
    ON c.PrimaryContactPersonID = p.PersonID
    ORDER BY ft.[RANK]
    FOR JSON AUTO, ROOT(N''Customers'');
END;';
        EXECUTE (@SQL);

        SET @SQL = N'DROP PROCEDURE IF EXISTS Website.SearchForStockItems;';
        EXECUTE (@SQL);

        SET @SQL = N'
CREATE PROCEDURE Website.SearchForStockItems
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
WITH EXECUTE AS OWNER
AS
BEGIN
    SELECT si.StockItemID,
           si.StockItemName
    FROM Warehouse.StockItems AS si
    INNER JOIN FREETEXTTABLE(Warehouse.StockItems, SearchDetails, @SearchText, @MaximumRowsToReturn) AS ft
    ON si.StockItemID = ft.[KEY]
    ORDER BY ft.[RANK]
    FOR JSON AUTO, ROOT(N''StockItems'');
END;';
        EXECUTE (@SQL);

        SET @SQL = N'DROP PROCEDURE IF EXISTS Website.SearchForStockItemsByTags;';
        EXECUTE (@SQL);

        SET @SQL = N'
CREATE PROCEDURE Website.SearchForStockItemsByTags
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
WITH EXECUTE AS OWNER
AS
BEGIN
    SELECT si.StockItemID,
           si.StockItemName
    FROM Warehouse.StockItems AS si
    INNER JOIN FREETEXTTABLE(Warehouse.StockItems, Tags, @SearchText, @MaximumRowsToReturn) AS ft
    ON si.StockItemID = ft.[KEY]
    ORDER BY ft.[RANK]
    FOR JSON AUTO, ROOT(N''StockItems'');
END;';
        EXECUTE (@SQL);

        PRINT N'Full text successfully enabled';
    END;
END;

GO

-- File: Configuration_ApplyPartitioning.sql
﻿
CREATE PROCEDURE [Application].Configuration_ApplyPartitioning
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF SERVERPROPERTY(N'IsXTPSupported') = 0 -- TODO Check for a better way to check for partitioning
    BEGIN                                    -- Currently versions that support in-memory OLTP also support partitions
        PRINT N'Warning: Partitions are not supported in this edition.';
    END ELSE BEGIN -- if partitions are permitted

        BEGIN TRAN;

        DECLARE @SQL nvarchar(max) = N'';

        IF NOT EXISTS (SELECT 1 FROM sys.partition_functions WHERE name = N'PF_TransactionDateTime')
        BEGIN
            SET @SQL =  N'
CREATE PARTITION FUNCTION PF_TransactionDateTime(datetime)
AS RANGE RIGHT
FOR VALUES (N''20210101'', N''20220101'', N''20230101'', N''20240101'');';
            EXECUTE (@SQL);
        END;

        IF NOT EXISTS (SELECT 1 FROM sys.partition_functions WHERE name = N'PF_TransactionDate')
        BEGIN
            SET @SQL =  N'
CREATE PARTITION FUNCTION PF_TransactionDate(date)
AS RANGE RIGHT
FOR VALUES (N''20210101'', N''20220101'', N''20230101'', N''20240101'');';
            EXECUTE (@SQL);
        END;

        IF NOT EXISTS (SELECT * FROM sys.partition_schemes WHERE name = N'PS_TransactionDateTime')
        BEGIN

            -- for Azure DB, assign to primary filegroup
            IF SERVERPROPERTY('EngineEdition') = 5
                SET @SQL =  N'
CREATE PARTITION SCHEME PS_TransactionDateTime
AS PARTITION PF_TransactionDateTime
ALL TO ([PRIMARY]);';
            -- for other engine editions, assign to user data filegroup
            IF SERVERPROPERTY('EngineEdition') != 5
                SET @SQL =  N'
CREATE PARTITION SCHEME PS_TransactionDateTime
AS PARTITION PF_TransactionDateTime
ALL TO ([USERDATA]);';

            EXECUTE (@SQL);
        END;

        IF NOT EXISTS (SELECT 1 FROM sys.partition_schemes WHERE name = N'PS_TransactionDate')
        BEGIN
        -- for Azure DB, assign to primary filegroup
        IF SERVERPROPERTY('EngineEdition') = 5
            SET @SQL =  N'
CREATE PARTITION SCHEME PS_TransactionDate
AS PARTITION PF_TransactionDate
ALL TO ([PRIMARY]);';
        -- for other engine editions, assign to user data filegroup
        IF SERVERPROPERTY('EngineEdition') != 5
            SET @SQL =  N'
CREATE PARTITION SCHEME PS_TransactionDate
AS PARTITION PF_TransactionDate
ALL TO ([USERDATA]);';

            EXECUTE (@SQL);
        END;

        IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'CX_Sales_CustomerTransactions')
        BEGIN
            SET @SQL =  N'
ALTER TABLE Sales.CustomerTransactions
DROP CONSTRAINT PK_Sales_CustomerTransactions;';
            EXECUTE (@SQL);

            SET @SQL = N'
ALTER TABLE Sales.CustomerTransactions
ADD CONSTRAINT PK_Sales_CustomerTransactions PRIMARY KEY NONCLUSTERED
(
	CustomerTransactionID
);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE CLUSTERED INDEX CX_Sales_CustomerTransactions
ON Sales.CustomerTransactions
(
	TransactionDate
)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE INDEX FK_Sales_CustomerTransactions_CustomerID
ON Sales.CustomerTransactions
(
	CustomerID
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE INDEX FK_Sales_CustomerTransactions_InvoiceID
ON Sales.CustomerTransactions
(
	InvoiceID
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE INDEX FK_Sales_CustomerTransactions_PaymentMethodID
ON Sales.CustomerTransactions
(
	PaymentMethodID
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE INDEX FK_Sales_CustomerTransactions_TransactionTypeID
ON Sales.CustomerTransactions
(
	TransactionTypeID
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE INDEX IX_Sales_CustomerTransactions_IsFinalized
ON Sales.CustomerTransactions
(
	IsFinalized
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);
        END;

        IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'CX_Purchasing_SupplierTransactions')
        BEGIN
            SET @SQL =  N'
ALTER TABLE Purchasing.SupplierTransactions
DROP CONSTRAINT PK_Purchasing_SupplierTransactions;';
            EXECUTE (@SQL);

            SET @SQL =  N'
ALTER TABLE Purchasing.SupplierTransactions
ADD CONSTRAINT PK_Purchasing_SupplierTransactions PRIMARY KEY NONCLUSTERED
(
	SupplierTransactionID
);';
            EXECUTE (@SQL);

            SET @SQL =  N'
CREATE CLUSTERED INDEX CX_Purchasing_SupplierTransactions
ON Purchasing.SupplierTransactions
(
	TransactionDate
)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL =  N'
CREATE INDEX FK_Purchasing_SupplierTransactions_PaymentMethodID
ON Purchasing.SupplierTransactions
(
	PaymentMethodID
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL =  N'
CREATE INDEX FK_Purchasing_SupplierTransactions_PurchaseOrderID
ON Purchasing.SupplierTransactions
(
	PurchaseOrderID
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL =  N'
CREATE INDEX FK_Purchasing_SupplierTransactions_SupplierID
ON Purchasing.SupplierTransactions
(
	SupplierID
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL =  N'
CREATE INDEX FK_Purchasing_SupplierTransactions_TransactionTypeID
ON Purchasing.SupplierTransactions
(
	TransactionTypeID
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL =  N'
CREATE INDEX IX_Purchasing_SupplierTransactions_IsFinalized
ON Purchasing.SupplierTransactions
(
	IsFinalized
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);
        END;

        COMMIT;

        PRINT N'Partitioning successfully enabled';
    END;
END;

GO

-- File: Configuration_ApplyRowLevelSecurity.sql
﻿
CREATE PROCEDURE [Application].Configuration_ApplyRowLevelSecurity
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @SQL nvarchar(max);

    BEGIN TRY;

        SET @SQL = N'DROP SECURITY POLICY IF EXISTS [Application].FilterCustomersBySalesTerritoryRole;';
        EXECUTE (@SQL);

        SET @SQL = N'DROP FUNCTION IF EXISTS [Application].DetermineCustomerAccess;';
        EXECUTE (@SQL);

        SET @SQL = N'
CREATE FUNCTION [Application].DetermineCustomerAccess(@CityID int)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (SELECT 1 AS AccessResult
        WHERE IS_ROLEMEMBER(N''db_owner'') <> 0
        OR IS_ROLEMEMBER((SELECT sp.SalesTerritory
                          FROM [Application].Cities AS c
                          INNER JOIN [Application].StateProvinces AS sp
                          ON c.StateProvinceID = sp.StateProvinceID
                          WHERE c.CityID = @CityID) + N'' Sales'') <> 0
	    OR (ORIGINAL_LOGIN() = N''Website'' OR ORIGINAL_LOGIN() = N''WebApi''
		    AND EXISTS (SELECT 1
		                FROM [Application].Cities AS c
				        INNER JOIN [Application].StateProvinces AS sp
				        ON c.StateProvinceID = sp.StateProvinceID
				        WHERE c.CityID = @CityID
				        AND sp.SalesTerritory = SESSION_CONTEXT(N''SalesTerritory''))));';
        EXECUTE (@SQL);

        SET @SQL = N'
CREATE SECURITY POLICY [Application].FilterCustomersBySalesTerritoryRole
ADD FILTER PREDICATE [Application].DetermineCustomerAccess(DeliveryCityID)
ON Sales.Customers,
ADD BLOCK PREDICATE [Application].DetermineCustomerAccess(DeliveryCityID)
ON Sales.Customers AFTER UPDATE;';
        EXECUTE (@SQL);

        PRINT N'Successfully applied row level security';
    END TRY
    BEGIN CATCH
        PRINT N'Unable to apply row level security';
		PRINT ERROR_MESSAGE();
        THROW 51000, N'Unable to apply row level security', 1;
    END CATCH;
END;

GO

-- File: Configuration_ConfigureForEnterpriseEdition.sql
﻿
CREATE PROCEDURE [Application].[Configuration_ConfigureForEnterpriseEdition]
AS
BEGIN

    EXEC [Application].[Configuration_ApplyColumnstoreIndexing];

    EXEC [Application].[Configuration_ApplyFullTextIndexing];

    EXEC [Application].[Configuration_EnableInMemory];

    EXEC [Application].[Configuration_ApplyPartitioning];

END;

GO

-- File: Configuration_DisableInMemory.sql
﻿CREATE PROCEDURE [Application].[Configuration_DisableInMemory]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

		DECLARE @SQL nvarchar(max) = N'';

		BEGIN TRY

/*-------------------------------------------------------------------------------------*/
/* Drop the procedures that are used by the table types                                */
/*-------------------------------------------------------------------------------------*/
      SET @SQL = N'DROP PROCEDURE IF EXISTS Website.InvoiceCustomerOrders;';
      EXECUTE (@SQL);

      SET @SQL = N'DROP PROCEDURE IF EXISTS Website.InsertCustomerOrders;';
      EXECUTE (@SQL);
			
      SET @SQL = N'DROP PROCEDURE IF EXISTS Website.RecordColdRoomTemperatures;';
			EXECUTE (@SQL);

      -- Drop the table types
      SET @SQL = N'DROP TYPE IF EXISTS Website.OrderIDList;';
      EXECUTE (@SQL);

      SET @SQL = N'DROP TYPE IF EXISTS Website.OrderLineList;';
      EXECUTE (@SQL);

      SET @SQL = N'DROP TYPE IF EXISTS Website.OrderList;';
      EXECUTE (@SQL);

      SET @SQL = N'DROP TYPE IF EXISTS Website.SensorDataList;';
      EXECUTE (@SQL);


/*-------------------------------------------------------------------------------------*/
/* Cold Room Temperatures - Recreate as non temporal and not memory optimized          */
/*-------------------------------------------------------------------------------------*/
      IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'ColdRoomTemperatures' AND is_memory_optimized = 0)
      BEGIN

            SET @SQL = N'
ALTER TABLE Warehouse.ColdRoomTemperatures SET (SYSTEM_VERSIONING = OFF);
ALTER TABLE Warehouse.ColdRoomTemperatures DROP PERIOD FOR SYSTEM_TIME;';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE TABLE Warehouse.ColdRoomTemperatures_Staging
(
    ColdRoomTemperatureID bigint IDENTITY(1,1) NOT NULL,
    ColdRoomSensorNumber int NOT NULL,
    RecordedWhen datetime2(7) NOT NULL,
    Temperature decimal(10, 2) NOT NULL,
    ValidFrom datetime2(7) NOT NULL,
    ValidTo datetime2(7) NOT NULL,
);';
            EXECUTE (@SQL);

            SET @SQL = N'
SET IDENTITY_INSERT Warehouse.ColdRoomTemperatures_Staging ON;

INSERT Warehouse.ColdRoomTemperatures_Staging (ColdRoomTemperatureID, ColdRoomSensorNumber, RecordedWhen, Temperature,
                                       ValidFrom, ValidTo)
SELECT ColdRoomTemperatureID, ColdRoomSensorNumber, RecordedWhen, Temperature, ValidFrom, ValidTo
FROM Warehouse.ColdRoomTemperatures;

SET IDENTITY_INSERT Warehouse.ColdRoomTemperatures_Staging OFF;';
        EXECUTE (@SQL);

        SET @SQL = N'DROP TABLE Warehouse.ColdRoomTemperatures;';
        EXECUTE (@SQL);

        SET @SQL = N'
EXEC dbo.sp_rename @objname = N''Warehouse.ColdRoomTemperatures_Staging'',
                   @newname = N''ColdRoomTemperatures'',
                   @objtype = N''OBJECT'';';
        EXECUTE (@SQL);

        SET @SQL = '
CREATE NONCLUSTERED INDEX [IX_Warehouse_ColdRoomTemperatures_ColdRoomSensorNumber]
  ON Warehouse.ColdRoomTemperatures (ColdRoomSensorNumber)
                      ';
        EXECUTE (@SQL);

        SET @SQL = '
ALTER TABLE Warehouse.ColdRoomTemperatures
  ADD CONSTRAINT PK_Warehouse_ColdRoomTemperatures
  PRIMARY KEY CLUSTERED (ColdRoomTemperatureID)
                      ';
        EXECUTE (@SQL);
                SET @SQL = N'
ALTER TABLE Warehouse.ColdRoomTemperatures
ADD PERIOD FOR SYSTEM_TIME(ValidFrom, ValidTo);';
                EXECUTE (@SQL);

                SET @SQL = N'
ALTER TABLE Warehouse.ColdRoomTemperatures
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = Warehouse.ColdRoomTemperatures_Archive, DATA_CONSISTENCY_CHECK = ON));';
                EXECUTE (@SQL);
	  END
/*-------------------------------------------------------------------------------------*/
/* Vehicle Temperatures - Recreate as non temporal and not memory optimized            */
/*-------------------------------------------------------------------------------------*/

          SET @SQL = N'
CREATE TABLE Warehouse.VehicleTemperatures_Staging
(
  VehicleTemperatureID bigint IDENTITY(1,1) NOT NULL,
	VehicleRegistration nvarchar(20) COLLATE Latin1_General_CI_AS NOT NULL,
	ChillerSensorNumber int NOT NULL,
	RecordedWhen datetime2(7) NOT NULL,
	Temperature decimal(10, 2) NOT NULL,
	FullSensorData nvarchar(1000) COLLATE Latin1_General_CI_AS NULL,
  IsCompressed bit NOT NULL,
  CompressedSensorData varbinary(max) NULL
);';
          EXECUTE (@SQL);

          SET @SQL = N'
SET IDENTITY_INSERT Warehouse.VehicleTemperatures_Staging ON;

INSERT Warehouse.VehicleTemperatures_Staging
    (VehicleTemperatureID, VehicleRegistration, ChillerSensorNumber, RecordedWhen, Temperature, FullSensorData, IsCompressed, CompressedSensorData)
SELECT VehicleTemperatureID, VehicleRegistration, ChillerSensorNumber, RecordedWhen, Temperature, FullSensorData, IsCompressed, CompressedSensorData
FROM Warehouse.VehicleTemperatures;

SET IDENTITY_INSERT Warehouse.VehicleTemperatures_Staging OFF;';
          EXECUTE (@SQL);

          SET @SQL = N'DROP TABLE Warehouse.VehicleTemperatures;';
          EXECUTE (@SQL);

          SET @SQL = N'
EXEC dbo.sp_rename @objname = N''Warehouse.VehicleTemperatures_Staging'',
                   @newname = N''VehicleTemperatures'',
                   @objtype = N''OBJECT'';';
          EXECUTE (@SQL);

          SET @SQL = '
ALTER TABLE Warehouse.VehicleTemperatures
  ADD CONSTRAINT PK_Warehouse_VehicleTemperatures
  PRIMARY KEY NONCLUSTERED (VehicleTemperatureID)
                      ';
          EXECUTE (@SQL);

/*-------------------------------------------------------------------------------------*/
/* Create the new table types                                                          */
/*-------------------------------------------------------------------------------------*/

      SET @SQL = N'
CREATE TYPE Website.OrderIDList AS TABLE
(
  OrderID int PRIMARY KEY NONCLUSTERED
);';
      EXECUTE (@SQL);

      SET @SQL = N'
CREATE TYPE Website.OrderList AS TABLE
(
  OrderReference int PRIMARY KEY NONCLUSTERED,
  CustomerID int,
  ContactPersonID int,
  ExpectedDeliveryDate date,
  CustomerPurchaseOrderNumber nvarchar(20),
  IsUndersupplyBackordered bit,
  Comments nvarchar(max),
  DeliveryInstructions nvarchar(max)
);';
      EXECUTE (@SQL);

      SET @SQL = N'
CREATE TYPE Website.OrderLineList AS TABLE
(
  OrderReference int,
  StockItemID int,
  [Description] nvarchar(100),
  Quantity int,
  INDEX IX_Website_OrderLineList NONCLUSTERED (OrderReference)
);';
      EXECUTE (@SQL);

      SET @SQL = N'
CREATE TYPE Website.SensorDataList AS TABLE
(
	SensorDataListID int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
	ColdRoomSensorNumber int,
	RecordedWhen datetime2(7),
	Temperature decimal(18,2)
);';
      EXECUTE (@SQL);

      SET @SQL = N'
CREATE PROCEDURE Website.InvoiceCustomerOrders
@OrdersToInvoice Website.OrderIDList READONLY,
@PackedByPersonID int,
@InvoicedByPersonID int
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @InvoicesToGenerate TABLE
    (
        OrderID int PRIMARY KEY,
        InvoiceID int NOT NULL,
        TotalDryItems int NOT NULL,
        TotalChillerItems int NOT NULL
    );

    BEGIN TRY;

        -- Check that all orders exist, have been fully picked, and not already invoiced. Also allocate new invoice numbers.
        INSERT @InvoicesToGenerate (OrderID, InvoiceID, TotalDryItems, TotalChillerItems)
        SELECT oti.OrderID,
               NEXT VALUE FOR Sequences.InvoiceID,
               COALESCE((SELECT SUM(CASE WHEN si.IsChillerStock <> 0 THEN 0 ELSE 1 END)
                         FROM Sales.OrderLines AS ol
                         INNER JOIN Warehouse.StockItems AS si
                         ON ol.StockItemID = si.StockItemID
                         WHERE ol.OrderID = oti.OrderID), 0),
               COALESCE((SELECT SUM(CASE WHEN si.IsChillerStock <> 0 THEN 1 ELSE 0 END)
                         FROM Sales.OrderLines AS ol
                         INNER JOIN Warehouse.StockItems AS si
                         ON ol.StockItemID = si.StockItemID
                         WHERE ol.OrderID = oti.OrderID), 0)
        FROM @OrdersToInvoice AS oti
        INNER JOIN Sales.Orders AS o
        ON oti.OrderID = o.OrderID
        WHERE NOT EXISTS (SELECT 1 FROM Sales.Invoices AS i
                                   WHERE i.OrderID = oti.OrderID)
        AND o.PickingCompletedWhen IS NOT NULL;

        IF EXISTS (SELECT 1 FROM @OrdersToInvoice AS oti WHERE NOT EXISTS (SELECT 1 FROM @InvoicesToGenerate AS itg WHERE itg.OrderID = oti.OrderID))
        BEGIN
            PRINT N''At least one order ID either does not exist, is not picked, or is already invoiced'';
            THROW 51000, N''At least one orderID either does not exist, is not picked, or is already invoiced'', 1;
        END;

        BEGIN TRAN;

        INSERT Sales.Invoices
            (InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID, ContactPersonID, AccountsPersonID,
             SalespersonPersonID, PackedByPersonID, InvoiceDate, CustomerPurchaseOrderNumber,
             IsCreditNote, CreditNoteReason, Comments, DeliveryInstructions, InternalComments,
             TotalDryItems, TotalChillerItems,  DeliveryRun, RunPosition,
             ReturnedDeliveryData,
             LastEditedBy, LastEditedWhen)
        SELECT itg.InvoiceID, c.CustomerID, c.BillToCustomerID, itg.OrderID, c.DeliveryMethodID, o.ContactPersonID, btc.PrimaryContactPersonID,
               o.SalespersonPersonID, @PackedByPersonID, SYSDATETIME(), o.CustomerPurchaseOrderNumber,
               0, NULL, NULL, c.DeliveryAddressLine1 + N'', '' + c.DeliveryAddressLine2, NULL,
               itg.TotalDryItems, itg.TotalChillerItems, c.DeliveryRun, c.RunPosition,
               JSON_MODIFY(N''{"Events": []}'', N''append $.Events'',
                   JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(N''{ }'', N''$.Event'', N''Ready for collection''),
                   N''$.EventTime'', CONVERT(nvarchar(20), SYSDATETIME(), 126)),
                   N''$.ConNote'', N''EAN-125-'' + CAST(itg.InvoiceID + 1050 AS nvarchar(20)))),
               @InvoicedByPersonID, SYSDATETIME()
        FROM @InvoicesToGenerate AS itg
        INNER JOIN Sales.Orders AS o
        ON itg.OrderID = o.OrderID
        INNER JOIN Sales.Customers AS c
        ON o.CustomerID = c.CustomerID
        INNER JOIN Sales.Customers AS btc
        ON btc.CustomerID = c.BillToCustomerID;

        INSERT Sales.InvoiceLines
            (InvoiceID, StockItemID, [Description], PackageTypeID,
             Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice,
             LastEditedBy, LastEditedWhen)
        SELECT itg.InvoiceID, ol.StockItemID, ol.[Description], ol.PackageTypeID,
               ol.PickedQuantity, ol.UnitPrice, ol.TaxRate,
               ROUND(ol.PickedQuantity * ol.UnitPrice * ol.TaxRate / 100.0, 2),
               ROUND(ol.PickedQuantity * (ol.UnitPrice - sih.LastCostPrice), 2),
               ROUND(ol.PickedQuantity * ol.UnitPrice, 2)
                 + ROUND(ol.PickedQuantity * ol.UnitPrice * ol.TaxRate / 100.0, 2),
               @InvoicedByPersonID, SYSDATETIME()
        FROM @InvoicesToGenerate AS itg
        INNER JOIN Sales.OrderLines AS ol
        ON itg.OrderID = ol.OrderID
        INNER JOIN Warehouse.StockItems AS si
        ON ol.StockItemID = si.StockItemID
        INNER JOIN Warehouse.StockItemHoldings AS sih
        ON si.StockItemID = sih.StockItemID
        ORDER BY ol.OrderID, ol.OrderLineID;

        INSERT Warehouse.StockItemTransactions
            (StockItemID, TransactionTypeID, CustomerID, InvoiceID, SupplierID, PurchaseOrderID,
             TransactionOccurredWhen, Quantity, LastEditedBy, LastEditedWhen)
        SELECT il.StockItemID, (SELECT TransactionTypeID FROM [Application].TransactionTypes WHERE TransactionTypeName = N''Stock Issue''),
               i.CustomerID, i.InvoiceID, NULL, NULL,
               SYSDATETIME(), 0 - il.Quantity, @InvoicedByPersonID, SYSDATETIME()
        FROM @InvoicesToGenerate AS itg
        INNER JOIN Sales.InvoiceLines AS il
        ON itg.InvoiceID = il.InvoiceID
        INNER JOIN Sales.Invoices AS i
        ON il.InvoiceID = i.InvoiceID
        ORDER BY il.InvoiceID, il.InvoiceLineID;

        WITH StockItemTotals
        AS
        (
            SELECT il.StockItemID, SUM(il.Quantity) AS TotalQuantity
            FROM Sales.InvoiceLines aS il
            WHERE il.InvoiceID IN (SELECT InvoiceID FROM @InvoicesToGenerate)
            GROUP BY il.StockItemID
        )
        UPDATE sih
        SET sih.QuantityOnHand -= sit.TotalQuantity,
            sih.LastEditedBy = @InvoicedByPersonID,
            sih.LastEditedWhen = SYSDATETIME()
        FROM Warehouse.StockItemHoldings AS sih
        INNER JOIN StockItemTotals AS sit
        ON sih.StockItemID = sit.StockItemID;

        INSERT Sales.CustomerTransactions
            (CustomerID, TransactionTypeID, InvoiceID, PaymentMethodID,
             TransactionDate, AmountExcludingTax, TaxAmount, TransactionAmount,
             OutstandingBalance, FinalizationDate, LastEditedBy, LastEditedWhen)
        SELECT i.BillToCustomerID,
               (SELECT TransactionTypeID FROM [Application].TransactionTypes WHERE TransactionTypeName = N''Customer Invoice''),
               itg.InvoiceID,
               NULL,
               SYSDATETIME(),
               (SELECT SUM(il.ExtendedPrice - il.TaxAmount) FROM Sales.InvoiceLines AS il WHERE il.InvoiceID = itg.InvoiceID),
               (SELECT SUM(il.TaxAmount) FROM Sales.InvoiceLines AS il WHERE il.InvoiceID = itg.InvoiceID),
               (SELECT SUM(il.ExtendedPrice) FROM Sales.InvoiceLines AS il WHERE il.InvoiceID = itg.InvoiceID),
               (SELECT SUM(il.ExtendedPrice) FROM Sales.InvoiceLines AS il WHERE il.InvoiceID = itg.InvoiceID),
               NULL,
               @InvoicedByPersonID,
               SYSDATETIME()
        FROM @InvoicesToGenerate AS itg
        INNER JOIN Sales.Invoices AS i
        ON itg.InvoiceID = i.InvoiceID;

        COMMIT;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        PRINT N''Unable to invoice these orders'';
        THROW;
        RETURN -1;
    END CATCH;

    RETURN 0;
END;';
      EXECUTE (@SQL);

			SET @SQL = N'
CREATE PROCEDURE Website.RecordColdRoomTemperatures
@SensorReadings Website.SensorDataList READONLY
WITH EXECUTE AS OWNER
AS
BEGIN
    BEGIN TRY

		DECLARE @NumberOfReadings int = (SELECT MAX(SensorDataListID) FROM @SensorReadings);
		DECLARE @Counter int = (SELECT MIN(SensorDataListID) FROM @SensorReadings);

		DECLARE @ColdRoomSensorNumber int;
		DECLARE @RecordedWhen datetime2(7);
		DECLARE @Temperature decimal(18,2);

		-- note that we cannot use a merge here because multiple readings might exist for each sensor

		WHILE @Counter <= @NumberOfReadings
		BEGIN
			SELECT @ColdRoomSensorNumber = ColdRoomSensorNumber,
			       @RecordedWhen = RecordedWhen,
				   @Temperature = Temperature
			FROM @SensorReadings
			WHERE SensorDataListID = @Counter;

			UPDATE Warehouse.ColdRoomTemperatures
				SET RecordedWhen = @RecordedWhen,
				    Temperature = @Temperature
			WHERE ColdRoomSensorNumber = @ColdRoomSensorNumber;

			IF @@ROWCOUNT = 0
			BEGIN
				INSERT Warehouse.ColdRoomTemperatures
					(ColdRoomSensorNumber, RecordedWhen, Temperature)
				VALUES (@ColdRoomSensorNumber, @RecordedWhen, @Temperature);
			END;

			SET @Counter += 1;
		END;

    END TRY
    BEGIN CATCH
        THROW 51000, N''Unable to apply the sensor data'', 2;

        RETURN 1;
    END CATCH;
END;';
			EXECUTE (@SQL);

      SET @SQL = N'
CREATE PROCEDURE Website.InsertCustomerOrders
@Orders Website.OrderList READONLY,
@OrderLines Website.OrderLineList READONLY,
@OrdersCreatedByPersonID int,
@SalespersonPersonID int
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OrdersToGenerate AS TABLE
    (
        OrderReference int PRIMARY KEY,   -- reference from the application
        OrderID int
    );

    -- allocate the new order numbers

    INSERT @OrdersToGenerate (OrderReference, OrderID)
    SELECT OrderReference, NEXT VALUE FOR Sequences.OrderID
    FROM @Orders;

    BEGIN TRY

        BEGIN TRAN;

        INSERT Sales.Orders
            (OrderID, CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate,
             ExpectedDeliveryDate, CustomerPurchaseOrderNumber, IsUndersupplyBackordered, Comments, DeliveryInstructions, InternalComments,
             PickingCompletedWhen, LastEditedBy, LastEditedWhen)
        SELECT otg.OrderID, o.CustomerID, @SalespersonPersonID, NULL, o.ContactPersonID, NULL, SYSDATETIME(),
               o.ExpectedDeliveryDate, o.CustomerPurchaseOrderNumber, o.IsUndersupplyBackordered, o.Comments, o.DeliveryInstructions, NULL,
               NULL, @OrdersCreatedByPersonID, SYSDATETIME()
        FROM @OrdersToGenerate AS otg
        INNER JOIN @Orders AS o
        ON otg.OrderReference = o.OrderReference;

        INSERT Sales.OrderLines
            (OrderID, StockItemID, [Description], PackageTypeID, Quantity, UnitPrice,
             TaxRate, PickedQuantity, PickingCompletedWhen, LastEditedBy, LastEditedWhen)
        SELECT otg.OrderID, ol.StockItemID, ol.[Description], si.UnitPackageID, ol.Quantity,
               Website.CalculateCustomerPrice(o.CustomerID, ol.StockItemID, SYSDATETIME()),
               si.TaxRate, 0, NULL, @OrdersCreatedByPersonID, SYSDATETIME()
        FROM @OrdersToGenerate AS otg
        INNER JOIN @OrderLines AS ol
        ON otg.OrderReference = ol.OrderReference
		INNER JOIN @Orders AS o
		ON ol.OrderReference = o.OrderReference
        INNER JOIN Warehouse.StockItems AS si
        ON ol.StockItemID = si.StockItemID;

        COMMIT;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        PRINT N''Unable to create the customer orders.'';
        THROW;
        RETURN -1;
    END CATCH;

    RETURN 0;
END;';
      EXECUTE (@SQL);

			SET @SQL = N'
ALTER DATABASE CURRENT
SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = OFF;';
			EXECUTE (@SQL);

        END TRY
        BEGIN CATCH
            PRINT N'Unable to remove memory-optimized tables';
            THROW;
        END CATCH;
END;

GO

-- File: Configuration_EnableInMemory.sql
﻿
CREATE PROCEDURE [Application].[Configuration_EnableInMemory]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF SERVERPROPERTY(N'IsXTPSupported') = 0
    BEGIN
        PRINT N'Warning: In-memory tables cannot be created on this edition.';
    END ELSE BEGIN -- if in-memory can be created

		DECLARE @SQL nvarchar(max) = N'';

		BEGIN TRY
			IF CAST(SERVERPROPERTY(N'EngineEdition') AS int) <> 5   -- Not an Azure SQL DB
			BEGIN
				DECLARE @SQLDataFolder nvarchar(max) = CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS nvarchar(max));
				DECLARE @MemoryOptimizedFilegroupFolder nvarchar(max) = @SQLDataFolder + N'WideWorldImporters_MemoryOptimized_Data_1';

				IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE type=N'FX')
				BEGIN
				    SET @SQL = N'
ALTER DATABASE CURRENT
ADD FILEGROUP WWI_MemoryOptimized_Data CONTAINS MEMORY_OPTIMIZED_DATA;';
					EXECUTE (@SQL);

					SET @SQL = N'
ALTER DATABASE CURRENT
ADD FILE (name = N''WWI_MemoryOptimized_Data_1'', filename = '''
		                 + @MemoryOptimizedFilegroupFolder + N''')
TO FILEGROUP WWI_MemoryOptimized_Data;';
					EXECUTE (@SQL);

				END;
            END;

			SET @SQL = N'
ALTER DATABASE CURRENT
SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON;';
			EXECUTE (@SQL);

            IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'ColdRoomTemperatures' AND is_memory_optimized <> 0)
            BEGIN

                SET @SQL = N'
ALTER TABLE Warehouse.ColdRoomTemperatures SET (SYSTEM_VERSIONING = OFF);
ALTER TABLE Warehouse.ColdRoomTemperatures DROP PERIOD FOR SYSTEM_TIME;
ALTER TABLE Warehouse.ColdRoomTemperatures DROP CONSTRAINT PK_Warehouse_ColdRoomTemperatures;';
                EXECUTE (@SQL);

                SET @SQL = N'
EXEC dbo.sp_rename @objname = N''Warehouse.ColdRoomTemperatures'',
                   @newname = N''ColdRoomTemperatures_Backup'',
                   @objtype = N''OBJECT'';';
                EXECUTE (@SQL);

                SET @SQL = N'
CREATE TABLE Warehouse.ColdRoomTemperatures
(
    ColdRoomTemperatureID bigint IDENTITY(1,1) NOT NULL,
    ColdRoomSensorNumber int NOT NULL,
    RecordedWhen datetime2(7) NOT NULL,
    Temperature decimal(10, 2) NOT NULL,
    ValidFrom datetime2(7) NOT NULL,
    ValidTo datetime2(7) NOT NULL,
    INDEX [IX_Warehouse_ColdRoomTemperatures_ColdRoomSensorNumber] NONCLUSTERED (ColdRoomSensorNumber),
    CONSTRAINT PK_Warehouse_ColdRoomTemperatures PRIMARY KEY NONCLUSTERED (ColdRoomTemperatureID)
) WITH (MEMORY_OPTIMIZED = ON ,DURABILITY = SCHEMA_AND_DATA);';
                EXECUTE (@SQL);

                SET @SQL = N'
SET IDENTITY_INSERT Warehouse.ColdRoomTemperatures ON;

INSERT Warehouse.ColdRoomTemperatures (ColdRoomTemperatureID, ColdRoomSensorNumber, RecordedWhen, Temperature,
                                       ValidFrom, ValidTo)
SELECT ColdRoomTemperatureID, ColdRoomSensorNumber, RecordedWhen, Temperature, ValidFrom, ValidTo
FROM Warehouse.ColdRoomTemperatures_Backup;

SET IDENTITY_INSERT Warehouse.ColdRoomTemperatures OFF;';
                EXECUTE (@SQL);

                SET @SQL = N'DROP TABLE Warehouse.ColdRoomTemperatures_Backup;';
                EXECUTE (@SQL);

                SET @SQL = N'
ALTER TABLE Warehouse.ColdRoomTemperatures
ADD PERIOD FOR SYSTEM_TIME(ValidFrom, ValidTo);';
                EXECUTE (@SQL);

                SET @SQL = N'
ALTER TABLE Warehouse.ColdRoomTemperatures
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = Warehouse.ColdRoomTemperatures_Archive, DATA_CONSISTENCY_CHECK = ON));';
                EXECUTE (@SQL);

            END; -- of if we need to move ColdRoomTemperatures

            IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'VehicleTemperatures' AND is_memory_optimized <> 0)
            BEGIN

                SET @SQL = N'
ALTER TABLE Warehouse.VehicleTemperatures DROP CONSTRAINT PK_Warehouse_VehicleTemperatures;';
                EXECUTE (@SQL);

                SET @SQL = N'
EXEC dbo.sp_rename @objname = N''Warehouse.VehicleTemperatures'',
                   @newname = N''VehicleTemperatures_Backup'',
                   @objtype = N''OBJECT'';';
                EXECUTE (@SQL);

                SET @SQL = N'
CREATE TABLE Warehouse.VehicleTemperatures
(
	VehicleTemperatureID bigint IDENTITY(1,1) NOT NULL,
	VehicleRegistration nvarchar(20) COLLATE Latin1_General_CI_AS NOT NULL,
	ChillerSensorNumber int NOT NULL,
	RecordedWhen datetime2(7) NOT NULL,
	Temperature decimal(10, 2) NOT NULL,
	FullSensorData nvarchar(1000) COLLATE Latin1_General_CI_AS NULL,
    IsCompressed bit NOT NULL,
    CompressedSensorData varbinary(max) NULL,
    CONSTRAINT PK_Warehouse_VehicleTemperatures PRIMARY KEY NONCLUSTERED (VehicleTemperatureID)
) WITH (MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_AND_DATA);';
                EXECUTE (@SQL);

                SET @SQL = N'
SET IDENTITY_INSERT Warehouse.VehicleTemperatures ON;

INSERT Warehouse.VehicleTemperatures
    (VehicleTemperatureID, VehicleRegistration, ChillerSensorNumber, RecordedWhen, Temperature, FullSensorData, IsCompressed, CompressedSensorData)
SELECT VehicleTemperatureID, VehicleRegistration, ChillerSensorNumber, RecordedWhen, Temperature, FullSensorData, IsCompressed, CompressedSensorData
FROM Warehouse.VehicleTemperatures_Backup;

SET IDENTITY_INSERT Warehouse.VehicleTemperatures OFF;';
                EXECUTE (@SQL);

                SET @SQL = N'DROP TABLE Warehouse.VehicleTemperatures_Backup;';
                EXECUTE (@SQL);

            END; -- of if we need to move VehicleTemperatures

            -- Drop the procedures that are used by the table types

            SET @SQL = N'DROP PROCEDURE IF EXISTS Website.InvoiceCustomerOrders;';
            EXECUTE (@SQL);
            SET @SQL = N'DROP PROCEDURE IF EXISTS Website.InsertCustomerOrders;';
            EXECUTE (@SQL);
			SET @SQL = N'DROP PROCEDURE IF EXISTS Website.RecordColdRoomTemperatures;';
			EXECUTE (@SQL);

            -- Drop the table types

            SET @SQL = N'DROP TYPE IF EXISTS Website.OrderIDList;';
            EXECUTE (@SQL);
            SET @SQL = N'DROP TYPE IF EXISTS Website.OrderLineList;';
            EXECUTE (@SQL);
            SET @SQL = N'DROP TYPE IF EXISTS Website.OrderList;';
            EXECUTE (@SQL);
            SET @SQL = N'DROP TYPE IF EXISTS Website.SensorDataList;';
            EXECUTE (@SQL);

            -- Create the new table types

            SET @SQL = N'
CREATE TYPE Website.OrderIDList AS TABLE
(
    OrderID int PRIMARY KEY NONCLUSTERED
)
WITH (MEMORY_OPTIMIZED = ON);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE TYPE Website.OrderList AS TABLE
(
    OrderReference int PRIMARY KEY NONCLUSTERED,
    CustomerID int,
    ContactPersonID int,
    ExpectedDeliveryDate date,
    CustomerPurchaseOrderNumber nvarchar(20),
    IsUndersupplyBackordered bit,
    Comments nvarchar(max),
    DeliveryInstructions nvarchar(max)
)
WITH (MEMORY_OPTIMIZED = ON);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE TYPE Website.OrderLineList AS TABLE
(
    OrderReference int,
    StockItemID int,
    [Description] nvarchar(100),
    Quantity int,
    INDEX IX_Website_OrderLineList NONCLUSTERED (OrderReference)
)
WITH (MEMORY_OPTIMIZED = ON);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE TYPE Website.SensorDataList AS TABLE
(
	SensorDataListID int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
	ColdRoomSensorNumber int,
	RecordedWhen datetime2(7),
	Temperature decimal(18,2)
)
WITH (MEMORY_OPTIMIZED = ON);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE PROCEDURE Website.InvoiceCustomerOrders
@OrdersToInvoice Website.OrderIDList READONLY,
@PackedByPersonID int,
@InvoicedByPersonID int
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @InvoicesToGenerate TABLE
    (
        OrderID int PRIMARY KEY,
        InvoiceID int NOT NULL,
        TotalDryItems int NOT NULL,
        TotalChillerItems int NOT NULL
    );

    BEGIN TRY;

        -- Check that all orders exist, have been fully picked, and not already invoiced. Also allocate new invoice numbers.
        INSERT @InvoicesToGenerate (OrderID, InvoiceID, TotalDryItems, TotalChillerItems)
        SELECT oti.OrderID,
               NEXT VALUE FOR Sequences.InvoiceID,
               COALESCE((SELECT SUM(CASE WHEN si.IsChillerStock <> 0 THEN 0 ELSE 1 END)
                         FROM Sales.OrderLines AS ol
                         INNER JOIN Warehouse.StockItems AS si
                         ON ol.StockItemID = si.StockItemID
                         WHERE ol.OrderID = oti.OrderID), 0),
               COALESCE((SELECT SUM(CASE WHEN si.IsChillerStock <> 0 THEN 1 ELSE 0 END)
                         FROM Sales.OrderLines AS ol
                         INNER JOIN Warehouse.StockItems AS si
                         ON ol.StockItemID = si.StockItemID
                         WHERE ol.OrderID = oti.OrderID), 0)
        FROM @OrdersToInvoice AS oti
        INNER JOIN Sales.Orders AS o
        ON oti.OrderID = o.OrderID
        WHERE NOT EXISTS (SELECT 1 FROM Sales.Invoices AS i
                                   WHERE i.OrderID = oti.OrderID)
        AND o.PickingCompletedWhen IS NOT NULL;

        IF EXISTS (SELECT 1 FROM @OrdersToInvoice AS oti WHERE NOT EXISTS (SELECT 1 FROM @InvoicesToGenerate AS itg WHERE itg.OrderID = oti.OrderID))
        BEGIN
            PRINT N''At least one order ID either does not exist, is not picked, or is already invoiced'';
            THROW 51000, N''At least one orderID either does not exist, is not picked, or is already invoiced'', 1;
        END;

        BEGIN TRAN;

        INSERT Sales.Invoices
            (InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID, ContactPersonID, AccountsPersonID,
             SalespersonPersonID, PackedByPersonID, InvoiceDate, CustomerPurchaseOrderNumber,
             IsCreditNote, CreditNoteReason, Comments, DeliveryInstructions, InternalComments,
             TotalDryItems, TotalChillerItems,  DeliveryRun, RunPosition,
             ReturnedDeliveryData,
             LastEditedBy, LastEditedWhen)
        SELECT itg.InvoiceID, c.CustomerID, c.BillToCustomerID, itg.OrderID, c.DeliveryMethodID, o.ContactPersonID, btc.PrimaryContactPersonID,
               o.SalespersonPersonID, @PackedByPersonID, SYSDATETIME(), o.CustomerPurchaseOrderNumber,
               0, NULL, NULL, c.DeliveryAddressLine1 + N'', '' + c.DeliveryAddressLine2, NULL,
               itg.TotalDryItems, itg.TotalChillerItems, c.DeliveryRun, c.RunPosition,
               JSON_MODIFY(N''{"Events": []}'', N''append $.Events'',
                   JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(N''{ }'', N''$.Event'', N''Ready for collection''),
                   N''$.EventTime'', CONVERT(nvarchar(20), SYSDATETIME(), 126)),
                   N''$.ConNote'', N''EAN-125-'' + CAST(itg.InvoiceID + 1050 AS nvarchar(20)))),
               @InvoicedByPersonID, SYSDATETIME()
        FROM @InvoicesToGenerate AS itg
        INNER JOIN Sales.Orders AS o
        ON itg.OrderID = o.OrderID
        INNER JOIN Sales.Customers AS c
        ON o.CustomerID = c.CustomerID
        INNER JOIN Sales.Customers AS btc
        ON btc.CustomerID = c.BillToCustomerID;

        INSERT Sales.InvoiceLines
            (InvoiceID, StockItemID, [Description], PackageTypeID,
             Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice,
             LastEditedBy, LastEditedWhen)
        SELECT itg.InvoiceID, ol.StockItemID, ol.[Description], ol.PackageTypeID,
               ol.PickedQuantity, ol.UnitPrice, ol.TaxRate,
               ROUND(ol.PickedQuantity * ol.UnitPrice * ol.TaxRate / 100.0, 2),
               ROUND(ol.PickedQuantity * (ol.UnitPrice - sih.LastCostPrice), 2),
               ROUND(ol.PickedQuantity * ol.UnitPrice, 2)
                 + ROUND(ol.PickedQuantity * ol.UnitPrice * ol.TaxRate / 100.0, 2),
               @InvoicedByPersonID, SYSDATETIME()
        FROM @InvoicesToGenerate AS itg
        INNER JOIN Sales.OrderLines AS ol
        ON itg.OrderID = ol.OrderID
        INNER JOIN Warehouse.StockItems AS si
        ON ol.StockItemID = si.StockItemID
        INNER JOIN Warehouse.StockItemHoldings AS sih
        ON si.StockItemID = sih.StockItemID
        ORDER BY ol.OrderID, ol.OrderLineID;

        INSERT Warehouse.StockItemTransactions
            (StockItemID, TransactionTypeID, CustomerID, InvoiceID, SupplierID, PurchaseOrderID,
             TransactionOccurredWhen, Quantity, LastEditedBy, LastEditedWhen)
        SELECT il.StockItemID, (SELECT TransactionTypeID FROM [Application].TransactionTypes WHERE TransactionTypeName = N''Stock Issue''),
               i.CustomerID, i.InvoiceID, NULL, NULL,
               SYSDATETIME(), 0 - il.Quantity, @InvoicedByPersonID, SYSDATETIME()
        FROM @InvoicesToGenerate AS itg
        INNER JOIN Sales.InvoiceLines AS il
        ON itg.InvoiceID = il.InvoiceID
        INNER JOIN Sales.Invoices AS i
        ON il.InvoiceID = i.InvoiceID
        ORDER BY il.InvoiceID, il.InvoiceLineID;

        WITH StockItemTotals
        AS
        (
            SELECT il.StockItemID, SUM(il.Quantity) AS TotalQuantity
            FROM Sales.InvoiceLines aS il
            WHERE il.InvoiceID IN (SELECT InvoiceID FROM @InvoicesToGenerate)
            GROUP BY il.StockItemID
        )
        UPDATE sih
        SET sih.QuantityOnHand -= sit.TotalQuantity,
            sih.LastEditedBy = @InvoicedByPersonID,
            sih.LastEditedWhen = SYSDATETIME()
        FROM Warehouse.StockItemHoldings AS sih
        INNER JOIN StockItemTotals AS sit
        ON sih.StockItemID = sit.StockItemID;

        INSERT Sales.CustomerTransactions
            (CustomerID, TransactionTypeID, InvoiceID, PaymentMethodID,
             TransactionDate, AmountExcludingTax, TaxAmount, TransactionAmount,
             OutstandingBalance, FinalizationDate, LastEditedBy, LastEditedWhen)
        SELECT i.BillToCustomerID,
               (SELECT TransactionTypeID FROM [Application].TransactionTypes WHERE TransactionTypeName = N''Customer Invoice''),
               itg.InvoiceID,
               NULL,
               SYSDATETIME(),
               (SELECT SUM(il.ExtendedPrice - il.TaxAmount) FROM Sales.InvoiceLines AS il WHERE il.InvoiceID = itg.InvoiceID),
               (SELECT SUM(il.TaxAmount) FROM Sales.InvoiceLines AS il WHERE il.InvoiceID = itg.InvoiceID),
               (SELECT SUM(il.ExtendedPrice) FROM Sales.InvoiceLines AS il WHERE il.InvoiceID = itg.InvoiceID),
               (SELECT SUM(il.ExtendedPrice) FROM Sales.InvoiceLines AS il WHERE il.InvoiceID = itg.InvoiceID),
               NULL,
               @InvoicedByPersonID,
               SYSDATETIME()
        FROM @InvoicesToGenerate AS itg
        INNER JOIN Sales.Invoices AS i
        ON itg.InvoiceID = i.InvoiceID;

        COMMIT;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        PRINT N''Unable to invoice these orders'';
        THROW;
        RETURN -1;
    END CATCH;

    RETURN 0;
END;';
            EXECUTE (@SQL);

			SET @SQL = N'
CREATE PROCEDURE Website.RecordColdRoomTemperatures
@SensorReadings Website.SensorDataList READONLY
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH
(
	TRANSACTION ISOLATION LEVEL = SNAPSHOT,
	LANGUAGE = N''English''
)
    BEGIN TRY

		DECLARE @NumberOfReadings int = (SELECT MAX(SensorDataListID) FROM @SensorReadings);
		DECLARE @Counter int = (SELECT MIN(SensorDataListID) FROM @SensorReadings);

		DECLARE @ColdRoomSensorNumber int;
		DECLARE @RecordedWhen datetime2(7);
		DECLARE @Temperature decimal(18,2);

		-- note that we cannot use a merge here because multiple readings might exist for each sensor

		WHILE @Counter <= @NumberOfReadings
		BEGIN
			SELECT @ColdRoomSensorNumber = ColdRoomSensorNumber,
			       @RecordedWhen = RecordedWhen,
				   @Temperature = Temperature
			FROM @SensorReadings
			WHERE SensorDataListID = @Counter;

			UPDATE Warehouse.ColdRoomTemperatures
				SET RecordedWhen = @RecordedWhen,
				    Temperature = @Temperature
			WHERE ColdRoomSensorNumber = @ColdRoomSensorNumber;

			IF @@ROWCOUNT = 0
			BEGIN
				INSERT Warehouse.ColdRoomTemperatures
					(ColdRoomSensorNumber, RecordedWhen, Temperature)
				VALUES (@ColdRoomSensorNumber, @RecordedWhen, @Temperature);
			END;

			SET @Counter += 1;
		END;

    END TRY
    BEGIN CATCH
        THROW 51000, N''Unable to apply the sensor data'', 2;

        RETURN 1;
    END CATCH;
END;';
			EXECUTE (@SQL);

            SET @SQL = N'
CREATE PROCEDURE Website.InsertCustomerOrders
@Orders Website.OrderList READONLY,
@OrderLines Website.OrderLineList READONLY,
@OrdersCreatedByPersonID int,
@SalespersonPersonID int
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OrdersToGenerate AS TABLE
    (
        OrderReference int PRIMARY KEY,   -- reference from the application
        OrderID int
    );

    -- allocate the new order numbers

    INSERT @OrdersToGenerate (OrderReference, OrderID)
    SELECT OrderReference, NEXT VALUE FOR Sequences.OrderID
    FROM @Orders;

    BEGIN TRY

        BEGIN TRAN;

        INSERT Sales.Orders
            (OrderID, CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate,
             ExpectedDeliveryDate, CustomerPurchaseOrderNumber, IsUndersupplyBackordered, Comments, DeliveryInstructions, InternalComments,
             PickingCompletedWhen, LastEditedBy, LastEditedWhen)
        SELECT otg.OrderID, o.CustomerID, @SalespersonPersonID, NULL, o.ContactPersonID, NULL, SYSDATETIME(),
               o.ExpectedDeliveryDate, o.CustomerPurchaseOrderNumber, o.IsUndersupplyBackordered, o.Comments, o.DeliveryInstructions, NULL,
               NULL, @OrdersCreatedByPersonID, SYSDATETIME()
        FROM @OrdersToGenerate AS otg
        INNER JOIN @Orders AS o
        ON otg.OrderReference = o.OrderReference;

        INSERT Sales.OrderLines
            (OrderID, StockItemID, [Description], PackageTypeID, Quantity, UnitPrice,
             TaxRate, PickedQuantity, PickingCompletedWhen, LastEditedBy, LastEditedWhen)
        SELECT otg.OrderID, ol.StockItemID, ol.[Description], si.UnitPackageID, ol.Quantity,
               Website.CalculateCustomerPrice(o.CustomerID, ol.StockItemID, SYSDATETIME()),
               si.TaxRate, 0, NULL, @OrdersCreatedByPersonID, SYSDATETIME()
        FROM @OrdersToGenerate AS otg
        INNER JOIN @OrderLines AS ol
        ON otg.OrderReference = ol.OrderReference
		INNER JOIN @Orders AS o
		ON ol.OrderReference = o.OrderReference
        INNER JOIN Warehouse.StockItems AS si
        ON ol.StockItemID = si.StockItemID;

        COMMIT;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        PRINT N''Unable to create the customer orders.'';
        THROW;
        RETURN -1;
    END CATCH;

    RETURN 0;
END;';
            EXECUTE (@SQL);

        END TRY
        BEGIN CATCH
            PRINT N'Unable to apply memory-optimized tables';
            THROW;
        END CATCH;
    END; -- of in-memory is allowed
END;

GO

-- File: Configuration_PrepareForAzureStandard.sql
﻿-- remove features not supported in Azure SQL Database Standard tier
CREATE PROCEDURE [Application].[Configuration_PrepareForAzureStandard]
AS

  EXEC [Application].[Configuration_RemoveColumnstoreIndexing]

  EXEC [Application].[Configuration_DisableInMemory]

RETURN 0

GO

-- File: Configuration_RemoveAuditing.sql
﻿
CREATE PROCEDURE [Application].Configuration_RemoveAuditing
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AreDatabaseAuditSpecificationsSupported bit = 0;
    DECLARE @SQL nvarchar(max);

    -- TODO !! - currently no separate test for audit
    -- but same editions with XTP support database audit specs
    IF SERVERPROPERTY(N'IsXTPSupported') <> 0 SET @AreDatabaseAuditSpecificationsSupported = 1;

    BEGIN TRY;

        IF @AreDatabaseAuditSpecificationsSupported <> 0
        BEGIN
            IF EXISTS (SELECT 1 FROM sys.database_audit_specifications WHERE name = N'WWI_DatabaseAuditSpecification')
            BEGIN
                SET @SQL = N'
DROP DATABASE AUDIT SPECIFICATION WWI_DatabaseAuditSpecification;';
                EXECUTE (@SQL);
            END;
        END;

        IF EXISTS (SELECT 1 FROM sys.server_audit_specifications WHERE name = N'WWI_ServerAuditSpecification')
        BEGIN
            SET @SQL = N'
USE master;

DROP SERVER AUDIT SPECIFICATION WWI_ServerAuditSpecification;';
            EXECUTE (@SQL);
        END;

        IF EXISTS (SELECT 1 FROM sys.server_audits WHERE name = N'WWI_Audit')
        BEGIN
            SET @SQL = N'
USE master;

DROP SERVER AUDIT [WWI_Audit];';
            EXECUTE (@SQL);

        END;

    END TRY
    BEGIN CATCH
        PRINT N'Unable to remove audit';
        THROW;
    END CATCH;
END;

GO

-- File: Configuration_RemoveColumnstoreIndexing.sql
﻿
CREATE PROCEDURE [Application].[Configuration_RemoveColumnstoreIndexing]
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF SERVERPROPERTY(N'IsXTPSupported') = 0 -- TODO !! - currently no separate test for columnstore
    BEGIN                                    -- but same editions with XTP support columnstore
        PRINT N'Warning: Columnstore indexes cannot be created on this edition.';
    END ELSE BEGIN -- if columnstore can be created
        DECLARE @SQL nvarchar(max) = N'';

        BEGIN TRY;

            BEGIN TRAN;

            -- Disable page compression on archive tables
            SET @SQL = N''
            SELECT @SQL +=N'
ALTER INDEX [' + i.name + N'] ON [' + schema_name(o.schema_id) + N'].[' + o.name + N'] REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, DATA_COMPRESSION = NONE);  '
            FROM sys.indexes i JOIN sys.tables o ON i.object_id=o.object_id
            WHERE o.temporal_type = 1 AND i.type=1
            EXECUTE (@SQL);

            -- Convert to regular index
            IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'NCCX_Sales_OrderLines')
            BEGIN
                SET @SQL = N'DROP INDEX NCCX_Sales_OrderLines ON Sales.OrderLines'
        				SET @SQL += N';';
                EXECUTE (@SQL);
            END;

            IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'NCCX_Sales_OrderLines')
            BEGIN
                SET @SQL = N'
CREATE NONCLUSTERED INDEX NCCX_Sales_OrderLines
ON Sales.OrderLines
(
    OrderID,
    StockItemID,
	[Description],
    Quantity,
    UnitPrice,
    PickedQuantity
)';
                SET @SQL += N';';
                EXECUTE (@SQL);
            END;

            -- Convert to regular index
            IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'NCCX_Sales_InvoiceLines')
            BEGIN
                SET @SQL = N'DROP INDEX NCCX_Sales_InvoiceLines ON Sales.InvoiceLines'
        				SET @SQL += N';';
                EXECUTE (@SQL);
            END;

            IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'NCCX_Sales_InvoiceLines')
            BEGIN
                SET @SQL = N'
CREATE NONCLUSTERED INDEX NCCX_Sales_InvoiceLines
ON Sales.InvoiceLines
(
    InvoiceID,
    StockItemID,
    Quantity,
    UnitPrice,
    LineProfit,
    LastEditedWhen
)';
                SET @SQL += N';';
                EXECUTE (@SQL);
            END;

            -- Just remove this, don't replace with anything
            IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'CCX_Warehouse_StockItemTransactions')
            BEGIN
                SET @SQL = N'DROP INDEX CCX_Warehouse_StockItemTransactions ON Warehouse.StockItemTransactions;';
                EXECUTE (@SQL);
            END;

            COMMIT;
        END TRY
        BEGIN CATCH
            PRINT N'Unable to remove columnstore indexing';
            THROW;
        END CATCH;
    END; -- of columnstore is allowed
END;

GO

-- File: Configuration_RemoveRowLevelSecurity.sql
﻿
CREATE PROCEDURE [Application].Configuration_RemoveRowLevelSecurity
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @SQL nvarchar(max);

    BEGIN TRY;

        SET @SQL = N'DROP SECURITY POLICY IF EXISTS [Application].FilterCustomersBySalesTerritoryRole;';
        EXECUTE (@SQL);

        SET @SQL = N'DROP FUNCTION IF EXISTS [Application].DetermineCustomerAccess;';
        EXECUTE (@SQL);

        PRINT N'Successfully removed row level security';
    END TRY
    BEGIN CATCH
        PRINT N'Unable to remove row level security';
        THROW 51000, N'Unable to remove row level security', 1;
    END CATCH;
END;

GO

-- File: CreateRoleIfNonexistent.sql
﻿
CREATE PROCEDURE [Application].CreateRoleIfNonexistent
@RoleName sysname
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @RoleName AND type = N'R')
    BEGIN
        BEGIN TRY

            DECLARE @SQL nvarchar(max) = N'CREATE ROLE ' + QUOTENAME(@RoleName) + N';'
            EXECUTE (@SQL);

            PRINT N'Role ' + @RoleName + N' created';

        END TRY
        BEGIN CATCH
            PRINT N'Unable to create role ' + @RoleName;
            THROW;
        END CATCH;
    END;
END;

GO

-- File: ActivateWebsiteLogons.sql
﻿-- Note this procedure is not included in the regular build, it
-- is called during the post deployment process.
-- This is due to the fact it updates temporal tables, and SSDT
-- will throw up an error when this occurs, despite the fact we
-- have procedures to deactivate the temporal tables and reactivate
-- when done.
DROP PROCEDURE IF EXISTS DataLoadSimulation.ActivateWebsiteLogons;
GO

CREATE PROCEDURE DataLoadSimulation.ActivateWebsiteLogons
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Approximately 1 in 8 days has a new website activation

    DECLARE @NumberOfLogonsToActivate int = CASE WHEN (RAND() * 8) <= 1 THEN 1 ELSE 0 END;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Activating ' + CAST(@NumberOfLogonsToActivate AS nvarchar(20)) + N' logons for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

    DECLARE @Counter int = 0;
    DECLARE @PersonID int;
    DECLARE @EmailAddress nvarchar(256);
    DECLARE @HashedPassword varbinary(max);
    DECLARE @FullName nvarchar(50);
    DECLARE @UserPreferences nvarchar(max) = (SELECT UserPreferences FROM [Application].People WHERE PersonID = 1);

    WHILE @Counter < @NumberOfLogonsToActivate
    BEGIN
        SELECT TOP(1) @PersonID = PersonID,
                      @EmailAddress = EmailAddress,
                      @FullName = FullName
        FROM [Application].People
        WHERE IsPermittedToLogon = 0 AND PersonID <> 1
        ORDER BY NEWID();

        UPDATE [Application].People
        SET IsPermittedToLogon = 1,
            LogonName = @EmailAddress,
            HashedPassword = HASHBYTES(N'SHA2_256', N'SQLRocks!00' + @FullName),
            UserPreferences = @UserPreferences,
            [ValidFrom] = @StartingWhen
        WHERE PersonID = @PersonID;

        SET @Counter += 1;
    END;
END;
GO

GO

-- File: AddCustomers.sql
﻿-- Note this procedure is not included in the regular build, it
-- is called during the post deployment process.
-- This is due to the fact it updates temporal tables, and SSDT
-- will throw up an error when this occurs, despite the fact we
-- have procedures to deactivate the temporal tables and reactivate
-- when done.
DROP PROCEDURE IF EXISTS DataLoadSimulation.AddCustomers;
GO

CREATE PROCEDURE DataLoadSimulation.AddCustomers
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
WITH EXECUTE AS OWNER
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- add a customer one in 15 days average
    DECLARE @NumberOfCustomersToAdd int = (SELECT TOP(1) Quantity
                                              FROM (VALUES (0), (0), (0), (0), (0),
                                                           (0), (0), (0), (0), (0),
                                                           (0), (0), (0), (0), (0),
                                                           (0), (0), (0), (0), (0),
                                                           (0), (0), (0), (0), (1)) AS q(Quantity)
                                              ORDER BY NEWID());
    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Adding ' + CAST(@NumberOfCustomersToAdd AS nvarchar(20)) + N' customers for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

    DECLARE @Counter INT = 0;
    DECLARE @CityID INT;
    DECLARE @CityName NVARCHAR(max);
    DECLARE @CityStateProvinceID INT;
    DECLARE @CityStateProvinceCode NVARCHAR(5);
    DECLARE @CityStateProvinceName NVARCHAR(50);
    DECLARE @AreaCode INT;
    DECLARE @CustomerCategoryID INT;

    DECLARE @InUseCounter INT = 0;


    DECLARE @CustomerID int;
    DECLARE @PrimaryContactFullName nvarchar(50);
    DECLARE @PrimaryContactPersonID int;
    DECLARE @PrimaryContactFirstName nvarchar(50);
    DECLARE @PrimaryContactLastName AS NVARCHAR(20);
    DECLARE @CustomerName AS NVARCHAR(100);
    DECLARE @DeliveryMethodID int = [DataLoadSimulation].[GetDeliveryMethodID] (N'Delivery Van');
    DECLARE @DeliveryAddressLine1 nvarchar(max);
    DECLARE @DeliveryAddressLine2 nvarchar(max);
    DECLARE @DeliveryPostalCode nvarchar(max);
    DECLARE @PostalAddressLine1 nvarchar(max);
    DECLARE @PostalAddressLine2 nvarchar(max);
    DECLARE @PostalPostalCode nvarchar(max);
    DECLARE @StreetSuffix nvarchar(max);
    DECLARE @CompanySuffix nvarchar(max);
    DECLARE @StorePrefix nvarchar(max);
    DECLARE @CreditLimit int;

    DECLARE @BuyingGroupID INT
    DECLARE @BuyingGroupName NVARCHAR(50)

    DECLARE @BGWebDomain             AS NVARCHAR(256)
    DECLARE @BGEmailDomain           AS NVARCHAR(256)
    DECLARE @PhoneNumber             AS NVARCHAR(20)
    DECLARE @FaxNumber               AS NVARCHAR(20)
    DECLARE @EmailTo                 AS NVARCHAR(75)
    DECLARE @EmailAddress            AS NVARCHAR(256)
    DECLARE @phoneLast4              AS NVARCHAR(4)
    DECLARE @faxLast4                AS NVARCHAR(4)

    WHILE @Counter < @NumberOfCustomersToAdd
    BEGIN
      EXEC [DataLoadSimulation].[GetFicticiousName]
          @FirstName = @PrimaryContactFirstName OUTPUT
        , @LastName  = @PrimaryContactLastName  OUTPUT
        , @FullName  = @PrimaryContactFullName  OUTPUT
        , @Email     = @EmailTo                 OUTPUT

      -- If full name is null it means we've exhausted our list of
      -- available customer names, so we can no longer add customers
      IF @PrimaryContactFullName IS NULL
        RETURN

      EXEC [DataLoadSimulation].[GetRandomBuyingGroupNotInUse]
          @CityID            = @CityID                OUTPUT
        , @CityName          = @CityName              OUTPUT
        , @StateProvinceCode = @CityStateProvinceCode OUTPUT
        , @StateProvinceName = @CityStateProvinceName OUTPUT
        , @AreaCode          = @AreaCode              OUTPUT
        , @BuyingGroupID     = @BuyingGroupID         OUTPUT
        , @BuyingGroupName   = @BuyingGroupName       OUTPUT
        , @WebDomain         = @BGWebDomain           OUTPUT
        , @EmailDomain       = @BGEmailDomain         OUTPUT
        , @CustomerName      = @CustomerName          OUTPUT

      SET @CustomerID = NEXT VALUE FOR Sequences.CustomerID;
      EXEC [DataLoadSimulation].[GetRandomCustomerCategory]
        @RandomCustomerCategoryID = @CustomerCategoryID OUTPUT

      SET @CreditLimit = CEILING(RAND() * 30) * 100 + 1000;

      EXEC [DataLoadSimulation].[GetRandomStreet]
        @randomStreet = @DeliveryAddressLine1  OUTPUT;
      EXEC [DataLoadSimulation].[GetRandomSecondaryAddress]
        @randomSecondaryAddress = @DeliveryAddressLine2  OUTPUT

      EXEC [DataLoadSimulation].[GetRandomStreet]
        @randomStreet = @PostalAddressLine1 OUTPUT;
      EXEC [DataLoadSimulation].[GetRandomSecondaryAddress]
        @randomSecondaryAddress = @PostalAddressLine2 OUTPUT

      EXEC [DataLoadSimulation].[GetBogativePostalCode]
          @CityID = @CityID
        , @PostalCode = @DeliveryPostalCode OUTPUT
      SET @PostalPostalCode = @DeliveryPostalCode;

      SET @PrimaryContactPersonID = NEXT VALUE FOR Sequences.PersonID;

      SET @EmailAddress = @EmailTo + @BGEmailDomain

      -- Generate random phone numbers
      EXEC [DataLoadSimulation].[GetBogativePhoneNumber]
          @AreaCode = @AreaCode
        , @PhoneNumber = @PhoneNumber OUTPUT

      EXEC [DataLoadSimulation].[GetBogativePhoneNumber]
          @AreaCode = @AreaCode
        , @PhoneNumber = @FaxNumber OUTPUT

      BEGIN TRAN;

      INSERT [Application].People
          (PersonID, FullName, PreferredName, IsPermittedToLogon, LogonName,
           IsExternalLogonProvider, HashedPassword, IsSystemUser, IsEmployee,
           IsSalesperson, UserPreferences, PhoneNumber, FaxNumber,
           EmailAddress, LastEditedBy, ValidFrom, ValidTo)
      VALUES
          (@PrimaryContactPersonID, @PrimaryContactFullName, @PrimaryContactFirstName, 0, N'NO LOGON',
           0, NULL, 0, 0,
           0, NULL, @PhoneNumber, @FaxNumber,
           @EmailAddress, 1, @CurrentDateTime, @EndOfTime);

      INSERT Sales.Customers
          (CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID,
           BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID,
           DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage,
           IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber,
           DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2,
           DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2,
           PostalPostalCode, LastEditedBy, ValidFrom, ValidTo)
       VALUES
          (@CustomerID, @CustomerName, @CustomerID, @CustomerCategoryID,
           @BuyingGroupID, @PrimaryContactPersonID, NULL, @DeliveryMethodID,
           @CityID, @CityID, @CreditLimit, @StartingWhen, 0,
           0, 0, 7, @PhoneNumber, @FaxNumber,
           NULL, NULL, @BGWebDomain, @DeliveryAddressLine1, @DeliveryAddressLine2,
           @DeliveryPostalCode, [DataLoadSimulation].[GetCityLocation] (@CityID),
           @PostalAddressLine1, @PostalAddressLine2,
           @PostalPostalCode, 1, @CurrentDateTime, @EndOfTime);

      COMMIT;

      SET @Counter += 1;
    END;
END;
GO

GO

-- File: AddSpecialDeals.sql
﻿
CREATE PROCEDURE DataLoadSimulation.AddSpecialDeals
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF CAST(@CurrentDateTime AS date) = '20211231'
    BEGIN
        BEGIN TRAN;

        INSERT Sales.SpecialDeals
            (StockItemID, CustomerID, BuyingGroupID, CustomerCategoryID, StockGroupID,
             DealDescription, StartDate, EndDate, DiscountAmount, DiscountPercentage,
             UnitPrice, LastEditedBy, LastEditedWhen)
        VALUES
            (NULL, NULL, (SELECT BuyingGroupID FROM Sales.BuyingGroups WHERE BuyingGroupName = N'Wingtip Toys'),
             NULL, (SELECT StockGroupID FROM Warehouse.StockGroups WHERE StockGroupName = N'USB Novelties'),
             N'10% 1st qtr USB Wingtip', '20220101', '20220331', NULL, 10, NULL,
             2, @StartingWhen);

        INSERT Sales.SpecialDeals
            (StockItemID, CustomerID, BuyingGroupID, CustomerCategoryID, StockGroupID,
             DealDescription, StartDate, EndDate, DiscountAmount, DiscountPercentage,
             UnitPrice, LastEditedBy, LastEditedWhen)
        VALUES
            (NULL, NULL, (SELECT BuyingGroupID FROM Sales.BuyingGroups WHERE BuyingGroupName = N'Tailspin Toys'),
             NULL, (SELECT StockGroupID FROM Warehouse.StockGroups WHERE StockGroupName = N'USB Novelties'),
             N'15% 2nd qtr USB Tailspin', '20220401', '20220630', NULL, 15, NULL,
             2, @StartingWhen);

        COMMIT;

    END;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Adding special deals for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

END;
GO

-- File: AddStockItems.sql
﻿-- Note this procedure is not included in the regular build, it
-- is called during the post deployment process.
-- This is due to the fact it updates temporal tables, and SSDT
-- will throw up an error when this occurs, despite the fact we
-- have procedures to deactivate the temporal tables and reactivate
-- when done.
DROP PROCEDURE IF EXISTS DataLoadSimulation.AddStockItems;
GO

CREATE PROCEDURE DataLoadSimulation.AddStockItems
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @NumberOfStockItems int = 0;

    IF CAST(@CurrentDateTime AS date) = '20220101'
    BEGIN
        SET @NumberOfStockItems = 2;

        BEGIN TRAN;

        INSERT Warehouse.StockItems (StockItemID, StockItemName, SupplierID, ColorID,  UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, Photo, CustomFields, LastEditedBy, ValidFrom, ValidTo) VALUES (220,'Novelty chilli chocolates 250g',(SELECT SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'A Datum Corporation'),(SELECT ColorID FROM Warehouse.Colors WHERE ColorName = N'NULL'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Bag'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Carton'),NULL,'250g',3,24,1,'8302039293929',10,8.55,12.23,0.25,'Watch your friends faces when they eat these',NULL,NULL,NULL,1,@CurrentDateTime,@EndOfTime);
        INSERT Warehouse.StockItems (StockItemID, StockItemName, SupplierID, ColorID,  UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, Photo, CustomFields, LastEditedBy, ValidFrom, ValidTo) VALUES (221,'Novelty chilli chocolates 500g',(SELECT SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'A Datum Corporation'),(SELECT ColorID FROM Warehouse.Colors WHERE ColorName = N'NULL'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Bag'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Carton'),NULL,'500g',3,12,1,'8302039293647',10,14.5,20.74,0.5,'Watch your friends faces when they eat these',NULL,NULL,NULL,1,@CurrentDateTime,@EndOfTime);
        INSERT Warehouse.StockItemHoldings (StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen) VALUES (220,360,'CH-1',360,4.75,240,500,1,@CurrentDateTime);
        INSERT Warehouse.StockItemHoldings (StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen) VALUES (221,12,'CH-2',12,8.75,120,250,1,@CurrentDateTime);
        INSERT Warehouse.StockItemStockGroups (StockItemID, StockGroupID, LastEditedBy, LastEditedWhen) SELECT 220, sg.StockGroupID, 1, @CurrentDateTime FROM Warehouse.StockGroups AS sg WHERE sg.StockGroupName IN (N'Novelty Items', N'Edible Novelties');
        INSERT Warehouse.StockItemStockGroups (StockItemID, StockGroupID, LastEditedBy, LastEditedWhen) SELECT 221, sg.StockGroupID, 1, @CurrentDateTime FROM Warehouse.StockGroups AS sg WHERE sg.StockGroupName IN (N'Novelty Items', N'Edible Novelties');

        COMMIT;

    END ELSE IF CAST(@CurrentDateTime AS date) = '20220102'
    BEGIN
        SET @NumberOfStockItems = 2;

        BEGIN TRAN;

        INSERT Warehouse.StockItems (StockItemID, StockItemName, SupplierID, ColorID,  UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, Photo, CustomFields, LastEditedBy, ValidFrom, ValidTo) VALUES (222,'Chocolate beetles 250g',(SELECT SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'A Datum Corporation'),(SELECT ColorID FROM Warehouse.Colors WHERE ColorName = N'NULL'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Bag'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Carton'),NULL,'250g',3,24,1,'8792838293820',10,8.55,12.23,0.25,'Perfect for your child''s party',NULL,NULL,NULL,1,@CurrentDateTime,@EndOfTime);
        INSERT Warehouse.StockItems (StockItemID, StockItemName, SupplierID, ColorID,  UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, Photo, CustomFields, LastEditedBy, ValidFrom, ValidTo) VALUES (223,'Chocolate echidnas 250g',(SELECT SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'A Datum Corporation'),(SELECT ColorID FROM Warehouse.Colors WHERE ColorName = N'NULL'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Bag'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Carton'),NULL,'250g',3,24,1,'8792838293728',10,8.55,12.23,0.25,'Perfect for your child''s party',NULL,NULL,NULL,1,@CurrentDateTime,@EndOfTime);
        INSERT Warehouse.StockItemHoldings (StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen) VALUES (222,120,'CH-3',120,4.75,240,500,1,@CurrentDateTime);
        INSERT Warehouse.StockItemHoldings (StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen) VALUES (223,120,'CH-4',120,4.75,240,500,1,@CurrentDateTime);
        INSERT Warehouse.StockItemStockGroups (StockItemID, StockGroupID, LastEditedBy, LastEditedWhen) SELECT 222, sg.StockGroupID, 1, @CurrentDateTime FROM Warehouse.StockGroups AS sg WHERE sg.StockGroupName IN (N'Novelty Items', N'Edible Novelties');
        INSERT Warehouse.StockItemStockGroups (StockItemID, StockGroupID, LastEditedBy, LastEditedWhen) SELECT 223, sg.StockGroupID, 1, @CurrentDateTime FROM Warehouse.StockGroups AS sg WHERE sg.StockGroupName IN (N'Novelty Items', N'Edible Novelties');

        COMMIT;

    END ELSE IF CAST(@CurrentDateTime AS date) = '20220104'
    BEGIN
        SET @NumberOfStockItems = 2;

        BEGIN TRAN;

        INSERT Warehouse.StockItems (StockItemID, StockItemName, SupplierID, ColorID,  UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, Photo, CustomFields, LastEditedBy, ValidFrom, ValidTo) VALUES (224,'Chocolate frogs 250g',(SELECT SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'A Datum Corporation'),(SELECT ColorID FROM Warehouse.Colors WHERE ColorName = N'NULL'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Bag'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Carton'),NULL,'250g',3,24,1,'8792838293987',10,8.55,12.23,0.25,'Perfect for your child''s party',NULL,NULL,NULL,1,@CurrentDateTime,@EndOfTime);
        INSERT Warehouse.StockItems (StockItemID, StockItemName, SupplierID, ColorID,  UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, Photo, CustomFields, LastEditedBy, ValidFrom, ValidTo) VALUES (225,'Chocolate sharks 250g',(SELECT SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'A Datum Corporation'),(SELECT ColorID FROM Warehouse.Colors WHERE ColorName = N'NULL'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Bag'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Carton'),NULL,'250g',3,24,1,'8792838293234',10,8.55,12.23,0.25,'Perfect for your child''s party',NULL,NULL,NULL,1,@CurrentDateTime,@EndOfTime);
        INSERT Warehouse.StockItemHoldings (StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen) VALUES (224,144,'CH-5',144,4.75,240,500,1,@CurrentDateTime);
        INSERT Warehouse.StockItemHoldings (StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen) VALUES (225,160,'CH-6',160,4.75,240,500,1,@CurrentDateTime);
        INSERT Warehouse.StockItemStockGroups (StockItemID, StockGroupID, LastEditedBy, LastEditedWhen) SELECT 224, sg.StockGroupID, 1, @CurrentDateTime FROM Warehouse.StockGroups AS sg WHERE sg.StockGroupName IN (N'Novelty Items', N'Edible Novelties');
        INSERT Warehouse.StockItemStockGroups (StockItemID, StockGroupID, LastEditedBy, LastEditedWhen) SELECT 225, sg.StockGroupID, 1, @CurrentDateTime FROM Warehouse.StockGroups AS sg WHERE sg.StockGroupName IN (N'Novelty Items', N'Edible Novelties');

        COMMIT;

    END ELSE IF CAST (@CurrentDateTime AS date) = '20220105'
    BEGIN
        SET @NumberOfStockItems = 2;

        BEGIN TRAN;

        INSERT Warehouse.StockItems (StockItemID, StockItemName, SupplierID, ColorID,  UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, Photo, CustomFields, LastEditedBy, ValidFrom, ValidTo) VALUES (226,'White chocolate snow balls 250g',(SELECT SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'A Datum Corporation'),(SELECT ColorID FROM Warehouse.Colors WHERE ColorName = N'NULL'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Bag'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Carton'),NULL,'250g',3,24,1,'8792838293236',10,8.55,12.23,0.25,'Perfect for your child''s party',NULL,NULL,NULL,1,@CurrentDateTime,@EndOfTime);
        INSERT Warehouse.StockItems (StockItemID, StockItemName, SupplierID, ColorID,  UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, Photo, CustomFields, LastEditedBy, ValidFrom, ValidTo) VALUES (227,'White chocolate moon rocks 250g',(SELECT SupplierID FROM Purchasing.Suppliers WHERE SupplierName = N'A Datum Corporation'),(SELECT ColorID FROM Warehouse.Colors WHERE ColorName = N'NULL'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Bag'),(SELECT PackageTypeID FROM Warehouse.PackageTypes WHERE PackageTypeName = N'Carton'),NULL,'250g',3,24,1,'8792838293289',10,8.55,12.23,0.25,'Perfect for your child''s party',NULL,NULL,NULL,1,@CurrentDateTime,@EndOfTime);
        INSERT Warehouse.StockItemHoldings (StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen) VALUES (226,24,'CH-7',24,4.75,240,500,1,@CurrentDateTime);
        INSERT Warehouse.StockItemHoldings (StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen) VALUES (227,48,'CH-8',48,4.75,240,500,1,@CurrentDateTime);
        INSERT Warehouse.StockItemStockGroups (StockItemID, StockGroupID, LastEditedBy, LastEditedWhen) SELECT 226, sg.StockGroupID, 1, @CurrentDateTime FROM Warehouse.StockGroups AS sg WHERE sg.StockGroupName IN (N'Novelty Items', N'Edible Novelties');
        INSERT Warehouse.StockItemStockGroups (StockItemID, StockGroupID, LastEditedBy, LastEditedWhen) SELECT 227, sg.StockGroupID, 1, @CurrentDateTime FROM Warehouse.StockGroups AS sg WHERE sg.StockGroupName IN (N'Novelty Items', N'Edible Novelties');

        COMMIT;
    END;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Adding ' + CAST(@NumberOfStockItems AS nvarchar(20)) + N' stock items for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

END;
GO

GO

-- File: ChangePasswords.sql
﻿-- Note this procedure is not included in the regular build, it
-- is called during the post deployment process.
-- This is due to the fact it updates temporal tables, and SSDT
-- will throw up an error when this occurs, despite the fact we
-- have procedures to deactivate the temporal tables and reactivate
-- when done.
DROP PROCEDURE IF EXISTS DataLoadSimulation.ChangePasswords;
GO

CREATE PROCEDURE DataLoadSimulation.ChangePasswords
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- 1 in 4 days will be 1 password change, 1 in 8 days will be 2 passwords changed

    DECLARE @NumberOfPasswordsToChange int = (SELECT TOP(1) Quantity
                                              FROM (VALUES (0), (0), (0), (0), (0), (1), (1), (2)) AS q(Quantity)
                                              ORDER BY NEWID());
    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Changing ' + CAST(@NumberOfPasswordsToChange AS nvarchar(20)) + N' passwords for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

    DECLARE @Counter int = 0;
    DECLARE @PersonID int;
    DECLARE @EmailAddress nvarchar(256);
    DECLARE @HashedPassword varbinary(max);
    DECLARE @FullName nvarchar(50);

    WHILE @Counter < @NumberOfPasswordsToChange
    BEGIN
        SELECT TOP(1) @PersonID = PersonID,
                      @EmailAddress = EmailAddress,
                      @FullName = FullName
        FROM [Application].People
        WHERE IsPermittedToLogon <> 0 AND PersonID <> 1
        ORDER BY NEWID();

        UPDATE [Application].People
        SET HashedPassword = HASHBYTES(N'SHA2_256', N'SQLRocks!00' + @FullName),
            [ValidFrom] = @StartingWhen
        WHERE PersonID = @PersonID;

        SET @Counter += 1;
    END;
END;
GO

GO

-- File: CreateCustomerOrders.sql
﻿
CREATE PROCEDURE DataLoadSimulation.CreateCustomerOrders
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@NumberOfCustomerOrders int,
@IsSilentMode bit
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Creating ' + CAST(@NumberOfCustomerOrders AS nvarchar(20)) + N' customer orders for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

    DECLARE @OrderCounter int = 0;
    DECLARE @OrderLineCounter int = 0;
    DECLARE @CustomerID int;
    DECLARE @OrderID int;
    DECLARE @PrimaryContactPersonID int;
    DECLARE @SalespersonPersonID int;
    DECLARE @ExpectedDeliveryDate date = DATEADD(day, 1, @CurrentDateTime);
    DECLARE @OrderDateTime datetime = @StartingWhen;
    DECLARE @NumberOfOrderLines int;
    DECLARE @StockItemID int;
    DECLARE @StockItemName nvarchar(100);
    DECLARE @UnitPackageID int;
    DECLARE @QuantityPerOuter int;
    DECLARE @Quantity int;
    DECLARE @CustomerPrice decimal(18,2);
    DECLARE @TaxRate decimal(18,3);

    -- No deliveries on weekends

    SET DATEFIRST 7;

    WHILE DATEPART(weekday, @ExpectedDeliveryDate) IN (1, 7)
    BEGIN
        SET @ExpectedDeliveryDate = DATEADD(day, 1, @ExpectedDeliveryDate);
    END;

    -- Generate the required orders

    WHILE @OrderCounter < @NumberOfCustomerOrders
    BEGIN

        BEGIN TRAN;

        SET @OrderID = NEXT VALUE FOR Sequences.OrderID;

        -- SELECT TOP(1) @CustomerID = c.CustomerID,
        --               @PrimaryContactPersonID = c.PrimaryContactPersonID
        -- FROM Sales.Customers AS c
        -- WHERE c.IsOnCreditHold = 0
        -- ORDER BY NEWID();
        EXEC [DataLoadSimulation].[GetRandomCustomer]
            @RandomCustomerID = @CustomerID  OUTPUT
          , @CustomerPrimaryContactPersonID = @PrimaryContactPersonID OUTPUT


        -- SET @SalespersonPersonID = (SELECT TOP(1) PersonID
        --                             FROM [Application].People
        --                             WHERE IsSalesperson <> 0
        --                             ORDER BY NEWID());
        EXEC [DataLoadSimulation].[GetRandomSalesPersonID]
          @RandomSalesPersonID = @SalespersonPersonID OUTPUT

        INSERT Sales.Orders
            (OrderID, CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate,
             ExpectedDeliveryDate, CustomerPurchaseOrderNumber, IsUndersupplyBackordered, Comments, DeliveryInstructions, InternalComments,
             PickingCompletedWhen, LastEditedBy, LastEditedWhen)
        VALUES
            (@OrderID, @CustomerID, @SalespersonPersonID, NULL, @PrimaryContactPersonID, NULL, @CurrentDateTime,
             @ExpectedDeliveryDate, CAST(CEILING(RAND() * 10000) + 10000 AS nvarchar(20)), 1, NULL, NULL, NULL,
             NULL, 1, @OrderDateTime);

        SET @NumberOfOrderLines = 1 + CEILING(RAND() * 4);
        SET @OrderLineCounter = 0;

        WHILE @OrderLineCounter < @NumberOfOrderLines
        BEGIN
            SELECT TOP(1) @StockItemID = si.StockItemID,
                          @StockItemName = si.StockItemName,
                          @UnitPackageID = si.UnitPackageID,
                          @QuantityPerOuter = si.QuantityPerOuter,
                          @TaxRate = si.TaxRate
            FROM Warehouse.StockItems AS si
            WHERE NOT EXISTS (SELECT 1 FROM Sales.OrderLines AS ol
                                       WHERE ol.OrderID = @OrderID
                                       AND ol.StockItemID = si.StockItemID)
            ORDER BY NEWID();

            SET @Quantity = @QuantityPerOuter * (1 + FLOOR(RAND() * 10));
            SET @CustomerPrice = Website.CalculateCustomerPrice(@CustomerID, @StockItemID, @CurrentDateTime);

            INSERT Sales.OrderLines
                (OrderID, StockItemID, [Description], PackageTypeID, Quantity, UnitPrice,
                 TaxRate, PickedQuantity, PickingCompletedWhen, LastEditedBy, LastEditedWhen)
            VALUES
                (@OrderID, @StockItemID, @StockItemName, @UnitPackageID, @Quantity, @CustomerPrice,
                 @TaxRate, 0, NULL, 1, @StartingWhen);

            SET @OrderLineCounter += 1;
        END;

        COMMIT;

        SET @OrderCounter += 1;
    END;
END;
GO

-- File: DailyProcessToCreateHistory.sql
﻿
CREATE PROCEDURE [DataLoadSimulation].[DailyProcessToCreateHistory]
    @StartDate                           date
  , @EndDate                             date
  , @AverageNumberOfCustomerOrdersPerDay int = 30
  , @SaturdayPercentageOfNormalWorkDay   int
  , @SundayPercentageOfNormalWorkDay     int
  , @UpdateCustomFields                  bit
  , @IsSilentMode                        bit
  , @AreDatesPrinted                     bit
  , @MinYearlyGrowthPercent              int = -5
  , @MaxYearlyGrowthPercent              int = 15
  , @MinSeasonalVariationPercent         int = -10
  , @MaxSeasonalVariationPercent         int = 30
  , @MaxDailyVariationPercent            int = 20

AS
BEGIN
    SET NOCOUNT ON;
	SET XACT_ABORT ON;

    DECLARE @CurrentDateTime        datetime2(7) = @StartDate;
    DECLARE @EndOfTime              datetime2(7) =  '99991231 23:59:59.9999999';
    DECLARE @StartingWhen           datetime;
	DECLARE @OldNumberOfCustomerOrders int;
    DECLARE @NumberOfCustomerOrders int;
    DECLARE @IsWeekday              bit;
    DECLARE @IsSaturday             bit;
    DECLARE @IsSunday               bit;
    DECLARE @IsMonday               bit;
    DECLARE @Weekday                int;
    DECLARE @IsStaffOnly            bit;
    DECLARE @DateMessage            nvarchar(256);
	
	-- verify whether orders exist, and if so, compute the avg number of customer orders in the last year
	IF EXISTS (SELECT 1 FROM Sales.Orders)
	BEGIN
		SELECT @OldNumberOfCustomerOrders=	AVG(t.OrderCount)
		FROM (SELECT COUNT(*) AS OrderCount FROM Sales.Orders
			WHERE DATEPART(year,OrderDate) = DATEPART(year,(SELECT MAX(OrderDate) FROM Sales.Orders))
				AND DATEPART(weekday,OrderDate) NOT IN (1,7)
				AND BackorderOrderID IS NULL
			GROUP BY OrderDate) t
	END
	ELSE
		SET @OldNumberOfCustomerOrders = @AverageNumberOfCustomerOrdersPerDay


	/*


	delete from DataLoadSimulation.SeasonVariation
	DECLARE @MinSeasonalVariationPercent int = 7
	DECLARE @MaxSeasonalVariationPercent int = 25
	DECLARE @MinYearlyGrowthPercent int = 3
	DECLARE @MaxYearlyGrowthPercent int = 30
	declare @StartDate date = '20200101'
	declare @EndDate date = '20230101'
	declare @CurrentDateTime datetime2 = @StartDate
	declare @MaxDailyVariationPercent int = 5

	drop table if exists #result
	create table #result
	(OrderDate date, OrderCount int)*/
	
	-- compute actual seasonal variation
	DECLARE @CurrentYear int = DATEPART(year, @StartDate)
	WHILE @CurrentYear <= DATEPART(year, @EndDate)
	BEGIN
		DECLARE @CurrentSeason smallint = 1
		--compute new yearly variation for each year
		DECLARE @YearlyVariation float = 1 + (@MinYearlyGrowthPercent + RAND() * CAST(@MaxYearlyGrowthPercent - @MinYearlyGrowthPercent AS float))/100;
		WHILE @CurrentSeason <= 4
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM DataLoadSimulation.SeasonVariation WHERE [Year]=@CurrentYear and Season=@CurrentSeason)
			BEGIN
				-- compute seasonal variation
				DECLARE @SeasonalVariation float
				SET @SeasonalVariation = 1 + (@MinSeasonalVariationPercent + RAND() * CAST(@MaxSeasonalVariationPercent - @MinSeasonalVariationPercent AS float))/100
				IF @CurrentSeason % 2 = 1
					SET @SeasonalVariation = 1/@SeasonalVariation

				INSERT DataLoadSimulation.SeasonVariation ([Year], [Season], YearlyVariation, SeasonalVariation)
				VALUES (@CurrentYear, @CurrentSeason, @YearlyVariation, @SeasonalVariation)
			END
			SET @CurrentSeason += 1
		END
		SET @CurrentYear += 1
	END
	--select * from DataLoadSimulation.SeasonVariation


	/*
	DECLARE @OldNumberOfCustomerOrders int = 600;
    DECLARE @NumberOfCustomerOrders int;
	WHILE @CurrentDateTime <= @EndDate
	BEGIN
		SET @CurrentYear = DATEPART(year, @CurrentDateTime)
		SET @CurrentSeason = CEILING(CAST(DATEPART(month, @CurrentDateTime) AS float)/ 3)

		SELECT @SeasonalVariation=SeasonalVariation, @YearlyVariation=YearlyVariation
		FROM DataLoadSimulation.SeasonVariation
		WHERE [Year]=@CurrentYear AND Season=@CurrentSeason

		DECLARE @x float = CAST(DATEDIFF(day, DATEFROMPARTS(@CurrentYear, (@CurrentSeason*3)-2, 1), @CurrentDateTime) AS FLOAT)/90
		IF @x > 1
			SET @x = 1;

		--compute location on seasonal bell curve
		DECLARE @SeasonEffect float = (SIN(2 * 3.1415926 * (@x-0.25)) + 1) / 2;

		SET @SeasonEffect = ((@SeasonalVariation - 1) * @SeasonEffect) + 1

		-- compute effect of yearly growth on day at hand
		DECLARE @YearlyEffect float = 1+CAST((@YearlyVariation-1) AS float)*(CAST((DATEDIFF(day, DATEFROMPARTS(@CurrentYear-1, 12, 31), @CurrentDateTime)) AS float)/183)

		DECLARE @DailyEffect float = RAND()
		IF @DailyEffect < 0.5
			SET @DailyEffect = 0-@DailyEffect
			
		SET @DailyEffect = 1 + @DailyEffect * (CAST(@MaxDailyVariationPercent AS float)/100)

		SET @NumberOfCustomerOrders = @OldNumberOfCustomerOrders * @DailyEffect * @SeasonEffect * @YearlyEffect

		--INSERT #result select @CurrentDateTime, @NumberOfCustomerOrders
		
		SET @CurrentDateTime = DATEADD(day, 1, @CurrentDateTime);

		--when rolling over to new year, take the old order count as baseline
		IF DATEPART(day, @CurrentDateTime)=1 AND DATEPART(month, @CurrentDateTime)=1
			SET @OldNumberOfCustomerOrders=@OldNumberOfCustomerOrders* @YearlyEffect
	END*/
	--select * from #result


    SET DATEFIRST 7;  -- Week begins on Sunday

    EXEC DataLoadSimulation.DeactivateTemporalTablesBeforeDataLoad;

	BEGIN TRY

		WHILE @CurrentDateTime <= @EndDate
		BEGIN
			-- one transaction per day
			BEGIN TRAN
			SET @DateMessage = N'Processing '
							 + SUBSTRING(DATENAME(weekday, @CurrentDateTime), 1,3)
							 + N' '
							 + CONVERT(nvarchar(20), @CurrentDateTime, 107)
							 + N' '
							 + CAST(DATEDIFF(DAY, @CurrentDateTime, @EndDate) AS NVARCHAR)
							 + N' Days Remaining '
							 ;



			IF @AreDatesPrinted <> 0 OR @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage
			END;


		-- compute number of orders to process
			SET @CurrentYear = DATEPART(year, @CurrentDateTime)
			SET @CurrentSeason = CEILING(CAST(DATEPART(month, @CurrentDateTime) AS float)/ 3)

			SELECT @SeasonalVariation=SeasonalVariation, @YearlyVariation=YearlyVariation
			FROM DataLoadSimulation.SeasonVariation
			WHERE [Year]=@CurrentYear AND Season=@CurrentSeason

			DECLARE @x float = CAST(DATEDIFF(day, DATEFROMPARTS(@CurrentYear, (@CurrentSeason*3)-2, 1), @CurrentDateTime) AS FLOAT)/90
			IF @x > 1
				SET @x = 1;

			--compute location on seasonal bell curve
			DECLARE @SeasonEffect float = (SIN(2 * 3.1415926 * (@x-0.25)) + 1) / 2;

			SET @SeasonEffect = ((@SeasonalVariation - 1) * @SeasonEffect) + 1

			-- compute effect of yearly growth on day at hand
			DECLARE @YearlyEffect float = 1+CAST((@YearlyVariation-1) AS float)*(CAST((DATEDIFF(day, DATEFROMPARTS(@CurrentYear-1, 12, 31), @CurrentDateTime)) AS float)/183)

			DECLARE @DailyEffect float = RAND()
			IF @DailyEffect < 0.5
				SET @DailyEffect = 0-@DailyEffect
			
			SET @DailyEffect = 1 + @DailyEffect * (CAST(@MaxDailyVariationPercent AS float)/100)

			SET @NumberOfCustomerOrders = @OldNumberOfCustomerOrders * @DailyEffect * @SeasonEffect * @YearlyEffect

		  -- Calculate the days of the week - different processing happens on each day
			SET @Weekday = DATEPART(weekday, @CurrentDateTime);
			SET @IsSaturday = 0;
			SET @IsSunday = 0;
			SET @IsMonday = 0;
			SET @IsWeekday = 1;

			IF @Weekday = 7
			BEGIN
				SET @IsSaturday = 1;
				SET @IsWeekday = 0;
			END;
			IF @Weekday = 1
			BEGIN
				SET @IsSunday = 1;
				SET @IsWeekday = 0;
			END;
			IF @Weekday = 2 SET @IsMonday = 1;

		-- Purchase orders
			IF @IsWeekday <> 0
			BEGIN
				IF @IsSilentMode = 0
				BEGIN
					PRINT @DateMessage + N'- Receiving Purchase Orders'
				END;

				-- Start receiving purchase orders at 7AM on weekdays
				SET @StartingWhen = DATEADD(hour, 7, @CurrentDateTime);
				EXEC DataLoadSimulation.ReceivePurchaseOrders @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;
			END;

		-- Password changes
			IF @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage + N'- Receiving Changing Passwords'
			END;
			SET @StartingWhen = DATEADD(hour, 8, @CurrentDateTime);
			EXEC DataLoadSimulation.ChangePasswords @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

		-- Activate new website users
			IF @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage + N'- Activating Website Logins'
			END;
			SET @StartingWhen = DATEADD(minute, 10, DATEADD(hour, 8, @CurrentDateTime));
			EXEC DataLoadSimulation.ActivateWebsiteLogons @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

		-- Payments to suppliers
			IF DATEPART(weekday, @CurrentDateTime) = 2
			BEGIN
				IF @IsSilentMode = 0
				BEGIN
					PRINT @DateMessage + N'- Paying Suppliers'
				END;
				SET @StartingWhen = DATEADD(hour, 9, @CurrentDateTime); -- Suppliers are paid on Monday mornings
				EXEC DataLoadSimulation.PaySuppliers @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;
			END;

		-- Customer orders received
			SET @StartingWhen = DATEADD(hour, 10, @CurrentDateTime);
--			SET @NumberOfCustomerOrders = @AverageNumberOfCustomerOrdersPerDay / 2
--										+ CEILING(RAND() * @AverageNumberOfCustomerOrdersPerDay);
			SET @NumberOfCustomerOrders = CASE DATEPART(weekday, @CurrentDateTime)
											   WHEN 7
											   THEN FLOOR(@NumberOfCustomerOrders * @SaturdayPercentageOfNormalWorkDay / 100)
											   WHEN 1
											   THEN FLOOR(@NumberOfCustomerOrders * @SundayPercentageOfNormalWorkDay / 100)
											   ELSE @NumberOfCustomerOrders
										  END;
/*				SET @NumberOfCustomerOrders = FLOOR(@NumberOfCustomerOrders * CASE WHEN YEAR(@StartingWhen) = 2013 THEN 1.0
																				   WHEN YEAR(@StartingWhen) = 2014 THEN 1.12
																												   WHEN YEAR(@StartingWhen) = 2015 THEN 1.21
																												   WHEN YEAR(@StartingWhen) = 2016 THEN 1.23
																												   ELSE 1.26
																											END
											   );*/
			IF @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage + N'- Creating Customer Orders'
			END;
			EXEC DataLoadSimulation.CreateCustomerOrders @CurrentDateTime, @StartingWhen, @EndOfTime, @NumberOfCustomerOrders, @IsSilentMode;

		-- Pick any customer orders that can be picked
			IF @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage + N'- Picking Stock for Customer Orders'
			END;
			SET @StartingWhen = DATEADD(hour, 11, @CurrentDateTime);
			EXEC DataLoadSimulation.PickStockForCustomerOrders @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

		-- Process any payments from customers
			IF @Weekday <> 0
			BEGIN
				IF @IsSilentMode = 0
				BEGIN
					PRINT @DateMessage + N'- Process Customer Payments'
				END;
				SET @StartingWhen = DATEADD(minute, 30, DATEADD(hour, 11, @CurrentDateTime));
				EXEC DataLoadSimulation.ProcessCustomerPayments @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;
			END;

		-- Invoice orders that have been fully picked
			IF @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage + N'- Invoice Picked Orders'
			END;
			SET @StartingWhen = DATEADD(hour, 12, @CurrentDateTime);
			EXEC DataLoadSimulation.InvoicePickedOrders @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

		-- Place supplier orders
			IF @Weekday <> 0
			BEGIN
				IF @IsSilentMode = 0
				BEGIN
					PRINT @DateMessage + N'- Placing Supplier Orders'
				END;
				SET @StartingWhen = DATEADD(hour, 13, @CurrentDateTime);
				EXEC DataLoadSimulation.PlaceSupplierOrders @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;
			END;

		-- End of quarter stock take
			IF     (MONTH(@CurrentDateTime) =  1 AND DAY(@CurrentDateTime) = 31)
				OR (MONTH(@CurrentDateTime) =  4 AND DAY(@CurrentDateTime) = 30)
				OR (MONTH(@CurrentDateTime) =  7 AND DAY(@CurrentDateTime) = 31)
				OR (MONTH(@CurrentDateTime) = 10 AND DAY(@CurrentDateTime) = 31)
			BEGIN
				IF @IsSilentMode = 0
				BEGIN
					PRINT @DateMessage + N'- Performing Stock Take'
				END;
				SET @StartingWhen = DATEADD(hour, 14, @CurrentDateTime);
				EXEC DataLoadSimulation.PerformStocktake @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;
			END;

		-- Record invoice deliveries
			IF @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage + N'- Recording Invoice Deliveries'
			END;
			SET @StartingWhen = DATEADD(hour, 7, @CurrentDateTime);
			EXEC DataLoadSimulation.RecordInvoiceDeliveries @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

		-- Add customers
			IF @Weekday <> 0
			BEGIN
				IF @IsSilentMode = 0
				BEGIN
					PRINT @DateMessage + N'- Adding Customers'
				END;
				SET @StartingWhen = DATEADD(hour, 15, @CurrentDateTime);
				EXEC DataLoadSimulation.AddCustomers @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;
			END;

		 -- Add stock items
			IF @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage + N'- Adding Stock Items'
			END;
			SET @StartingWhen = DATEADD(hour, 16, @CurrentDateTime);
			EXEC DataLoadSimulation.AddStockItems @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

		-- Add special deals
			IF @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage + N'- Adding Special Deals'
			END;
			SET @StartingWhen = DATEADD(hour, 16, @CurrentDateTime);
			EXEC DataLoadSimulation.AddSpecialDeals @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

		 -- Temporal changes
			IF @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage + N'- Making Temporal Changes'
			END;
			SET @StartingWhen = DATEADD(hour, 16, @CurrentDateTime);
			EXEC DataLoadSimulation.MakeTemporalChanges @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

		-- Record delivery van temperatures
			IF @CurrentDateTime >= '20220101'
			BEGIN
				IF @IsSilentMode = 0
				BEGIN
					PRINT @DateMessage + N'- Recording Delivery Van Temperatures'
				END;
				SET @StartingWhen = DATEADD(hour, 7, @CurrentDateTime);
				EXEC DataLoadSimulation.RecordDeliveryVanTemperatures 300, 2, @CurrentDateTime, @StartingWhen, @IsSilentMode;
			END;

		-- Record cold room temperatures
			IF @CurrentDateTime >= '20211220'
			BEGIN
				IF @IsSilentMode = 0
				BEGIN
					PRINT @DateMessage + N'- Recording Cold Room Temperatures'
				END;
				EXEC DataLoadSimulation.RecordColdRoomTemperatures 3600, 40, @CurrentDateTime, @EndOfTime, @IsSilentMode;
			END;

			IF @IsSilentMode = 0
			BEGIN
				PRINT N' ';
			END;

			SET @CurrentDateTime = DATEADD(day, 1, @CurrentDateTime);
			-- if rolling over the year, re-baseline order count
			IF DATEPART(day, @CurrentDateTime)=1 AND DATEPART(month, @CurrentDateTime)=1
				SET @OldNumberOfCustomerOrders=@OldNumberOfCustomerOrders* @YearlyEffect
			COMMIT
		END; -- of processing each day

		IF @IsSilentMode = 0
		BEGIN
			PRINT N'Updating Custom Fields';
		END;
		IF @UpdateCustomFields <> 0
		BEGIN
			EXEC DataLoadSimulation.UpdateCustomFields @EndDate;
		END;

		IF @IsSilentMode = 0
		BEGIN
			PRINT N'Reactivating Temporal Tables After Data Load ';
		END;
		EXEC DataLoadSimulation.ReactivateTemporalTablesAfterDataLoad;

		IF @IsSilentMode = 0
		BEGIN
			PRINT N'Reseeding All Sequences';
		END;
		EXEC Sequences.ReseedAllSequences;

		-- Ensure RLS is applied
		IF @IsSilentMode = 0
		BEGIN
			PRINT N'Applying Row Level Security';
		END;
		EXEC [Application].Configuration_ApplyRowLevelSecurity

		IF @IsSilentMode = 0
		BEGIN
			PRINT N'Done Creating Wide World Importers Data History';
		END;
	END TRY
	BEGIN CATCH
		IF XACT_STATE() <> 0
		BEGIN
			ROLLBACK
		END

		PRINT N'Error Detected. Error ' + CAST(ERROR_NUMBER() AS nvarchar) + N': ' + ERROR_MESSAGE();
		PRINT N'Attempting cleanup before throwing.';

		PRINT N'Reactivating Temporal Tables After Data Load ';
		EXEC DataLoadSimulation.ReactivateTemporalTablesAfterDataLoad;

		PRINT N'Reseeding All Sequences';
		EXEC Sequences.ReseedAllSequences;

		PRINT N'Applying Row Level Security';
		EXEC [Application].Configuration_ApplyRowLevelSecurity;
		THROW;
	END CATCH

END;

GO

-- File: DeactivateTemporalTablesBeforeDataLoad.sql
﻿
CREATE PROCEDURE DataLoadSimulation.DeactivateTemporalTablesBeforeDataLoad
AS BEGIN
    -- Disables the temporal nature of the temporal tables before a simulated data load
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = N'Configuration_RemoveRowLevelSecurity')
    BEGIN
        EXEC [Application].Configuration_RemoveRowLevelSecurity;
    END;

    DECLARE @SQL nvarchar(max) = N'';
    DECLARE @CrLf nvarchar(2) = NCHAR(13) + NCHAR(10);
    DECLARE @Indent nvarchar(4) = N'    ';
    DECLARE @SchemaName sysname;
    DECLARE @TableName sysname;
    DECLARE @NormalColumnList nvarchar(max);
    DECLARE @NormalColumnListWithDPrefix nvarchar(max);
    DECLARE @PrimaryKeyColumn sysname;
    DECLARE @TemporalFromColumnName sysname = N'ValidFrom';
    DECLARE @TemporalToColumnName sysname = N'ValidTo';
    DECLARE @TemporalTableSuffix nvarchar(max) = N'Archive';
    DECLARE @LastEditedByColumnName sysname;

    ALTER TABLE [Application].[Cities] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Application].[Cities] DROP PERIOD FOR SYSTEM_TIME;

    ALTER TABLE [Application].[Countries] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Application].[Countries] DROP PERIOD FOR SYSTEM_TIME;

    ALTER TABLE [Application].[DeliveryMethods] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Application].[DeliveryMethods] DROP PERIOD FOR SYSTEM_TIME;

    ALTER TABLE [Application].[PaymentMethods] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Application].[PaymentMethods] DROP PERIOD FOR SYSTEM_TIME;

    ALTER TABLE [Application].[People] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Application].[People] DROP PERIOD FOR SYSTEM_TIME;

    ALTER TABLE [Application].[StateProvinces] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Application].[StateProvinces] DROP PERIOD FOR SYSTEM_TIME;

    ALTER TABLE [Application].[TransactionTypes] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Application].[TransactionTypes] DROP PERIOD FOR SYSTEM_TIME;

    ALTER TABLE [Purchasing].[SupplierCategories] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Purchasing].[SupplierCategories] DROP PERIOD FOR SYSTEM_TIME;

    ALTER TABLE [Purchasing].[Suppliers] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Purchasing].[Suppliers] DROP PERIOD FOR SYSTEM_TIME;

    ALTER TABLE [Sales].[BuyingGroups] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Sales].[BuyingGroups] DROP PERIOD FOR SYSTEM_TIME;

    ALTER TABLE [Sales].[CustomerCategories] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Sales].[CustomerCategories] DROP PERIOD FOR SYSTEM_TIME;

    ALTER TABLE [Sales].[Customers] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Sales].[Customers] DROP PERIOD FOR SYSTEM_TIME;

    ALTER TABLE [Warehouse].[ColdRoomTemperatures] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Warehouse].[ColdRoomTemperatures] DROP PERIOD FOR SYSTEM_TIME;

    ALTER TABLE [Warehouse].[Colors] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Warehouse].[Colors] DROP PERIOD FOR SYSTEM_TIME;

    ALTER TABLE [Warehouse].[PackageTypes] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Warehouse].[PackageTypes] DROP PERIOD FOR SYSTEM_TIME;

    ALTER TABLE [Warehouse].[StockGroups] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Warehouse].[StockGroups] DROP PERIOD FOR SYSTEM_TIME;

    ALTER TABLE [Warehouse].[StockItems] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Warehouse].[StockItems] DROP PERIOD FOR SYSTEM_TIME;

    SET @SQL = N'';
    SET @SchemaName = N'Application';
    SET @TableName = N'Cities';
    SET @PrimaryKeyColumn = N'CityID';
    SET @LastEditedByColumnName = N'LastEditedBy';
    SET @NormalColumnList = N' [CityID], [CityName], [StateProvinceID], [Location], [LatestRecordedPopulation],';
    SET @NormalColumnListWithDPrefix = N' d.[CityID], d.[CityName], d.[StateProvinceID], d.[Location], d.[LatestRecordedPopulation],';

    SET @SQL = N'DROP TRIGGER IF EXISTS ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify];'
    EXECUTE (@SQL);

    SET @SQL = N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify]' + @CrLf
              + N'ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + @CrLf
              + N'AFTER INSERT, UPDATE' + @CrLf
              + N'AS' + @CrLf
              + N'BEGIN' + @CrLf
              + @Indent + N'SET NOCOUNT ON;' + @CrLf + @CrLf
              + @Indent + N'IF NOT UPDATE(' + QUOTENAME(@TemporalFromColumnName) + N')' + @CrLf
              + @Indent + N'BEGIN' + @CrLf
              + @Indent + @Indent + N'THROW 51000, ''' + QUOTENAME(@TemporalFromColumnName)
                                  + N' must be updated when simulating data loads'', 1;' + @CrLf
              + @Indent + @Indent + N'ROLLBACK TRAN;' + @CrLf
              + @Indent + N'END;' + @CrLf + @CrLf
              + @Indent + N'INSERT ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName + N'_' + @TemporalTableSuffix) + @CrLf
              + @Indent + @Indent + N'(' + @NormalColumnList + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + QUOTENAME(@TemporalFromColumnName) + N',' + QUOTENAME(@TemporalToColumnName) + N')' + @CrLf
              + @Indent + N'SELECT' + @NormalColumnListWithDPrefix + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN N'd.' + QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + N' d.' + QUOTENAME(@TemporalFromColumnName) + N', i.' + QUOTENAME(@TemporalFromColumnName) + @CrLf
              + @Indent + N'FROM inserted AS i' + @CrLf
              + @Indent + N'INNER JOIN deleted AS d' + @CrLf
              + @Indent + N'ON i.' + QUOTENAME(@PrimaryKeyColumn) + N' = d.' + QUOTENAME(@PrimaryKeyColumn) + N';' + @CrLf
              + N'END;';
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName AND is_memory_optimized <> 0)
    BEGIN
        EXECUTE (@SQL);
    END;

    SET @SQL = N'';
    SET @SchemaName = N'Application';
    SET @TableName = N'Countries';
    SET @PrimaryKeyColumn = N'CountryID';
    SET @LastEditedByColumnName = N'LastEditedBy';
    SET @NormalColumnList = N' [CountryID], [CountryName], [FormalName], [IsoAlpha3Code], [IsoNumericCode], [CountryType], [LatestRecordedPopulation], [Continent], [Region], [Subregion], [Border],';
    SET @NormalColumnListWithDPrefix = N' d.[CountryID], d.[CountryName], d.[FormalName], d.[IsoAlpha3Code], d.[IsoNumericCode], d.[CountryType], d.[LatestRecordedPopulation], d.[Continent], d.[Region], d.[Subregion], d.[Border],';

    SET @SQL = N'DROP TRIGGER IF EXISTS ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify];'
    EXECUTE (@SQL);

    SET @SQL = N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify]' + @CrLf
              + N'ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + @CrLf
              + N'AFTER INSERT, UPDATE' + @CrLf
              + N'AS' + @CrLf
              + N'BEGIN' + @CrLf
              + @Indent + N'SET NOCOUNT ON;' + @CrLf + @CrLf
              + @Indent + N'IF NOT UPDATE(' + QUOTENAME(@TemporalFromColumnName) + N')' + @CrLf
              + @Indent + N'BEGIN' + @CrLf
              + @Indent + @Indent + N'THROW 51000, ''' + QUOTENAME(@TemporalFromColumnName)
                                  + N' must be updated when simulating data loads'', 1;' + @CrLf
              + @Indent + @Indent + N'ROLLBACK TRAN;' + @CrLf
              + @Indent + N'END;' + @CrLf + @CrLf
              + @Indent + N'INSERT ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName + N'_' + @TemporalTableSuffix) + @CrLf
              + @Indent + @Indent + N'(' + @NormalColumnList + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + QUOTENAME(@TemporalFromColumnName) + N',' + QUOTENAME(@TemporalToColumnName) + N')' + @CrLf
              + @Indent + N'SELECT' + @NormalColumnListWithDPrefix + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN N'd.' + QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + N' d.' + QUOTENAME(@TemporalFromColumnName) + N', i.' + QUOTENAME(@TemporalFromColumnName) + @CrLf
              + @Indent + N'FROM inserted AS i' + @CrLf
              + @Indent + N'INNER JOIN deleted AS d' + @CrLf
              + @Indent + N'ON i.' + QUOTENAME(@PrimaryKeyColumn) + N' = d.' + QUOTENAME(@PrimaryKeyColumn) + N';' + @CrLf
              + N'END;';
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName AND is_memory_optimized <> 0)
    BEGIN
        EXECUTE (@SQL);
    END;

    SET @SQL = N'';
    SET @SchemaName = N'Application';
    SET @TableName = N'DeliveryMethods';
    SET @PrimaryKeyColumn = N'DeliveryMethodID';
    SET @LastEditedByColumnName = N'LastEditedBy';
    SET @NormalColumnList = N' [DeliveryMethodID], [DeliveryMethodName],';
    SET @NormalColumnListWithDPrefix = N' d.[DeliveryMethodID], d.[DeliveryMethodName],';

    SET @SQL = N'DROP TRIGGER IF EXISTS ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify];'
    EXECUTE (@SQL);

    SET @SQL = N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify]' + @CrLf
              + N'ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + @CrLf
              + N'AFTER INSERT, UPDATE' + @CrLf
              + N'AS' + @CrLf
              + N'BEGIN' + @CrLf
              + @Indent + N'SET NOCOUNT ON;' + @CrLf + @CrLf
              + @Indent + N'IF NOT UPDATE(' + QUOTENAME(@TemporalFromColumnName) + N')' + @CrLf
              + @Indent + N'BEGIN' + @CrLf
              + @Indent + @Indent + N'THROW 51000, ''' + QUOTENAME(@TemporalFromColumnName)
                                  + N' must be updated when simulating data loads'', 1;' + @CrLf
              + @Indent + @Indent + N'ROLLBACK TRAN;' + @CrLf
              + @Indent + N'END;' + @CrLf + @CrLf
              + @Indent + N'INSERT ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName + N'_' + @TemporalTableSuffix) + @CrLf
              + @Indent + @Indent + N'(' + @NormalColumnList + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + QUOTENAME(@TemporalFromColumnName) + N',' + QUOTENAME(@TemporalToColumnName) + N')' + @CrLf
              + @Indent + N'SELECT' + @NormalColumnListWithDPrefix + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN N'd.' + QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + N' d.' + QUOTENAME(@TemporalFromColumnName) + N', i.' + QUOTENAME(@TemporalFromColumnName) + @CrLf
              + @Indent + N'FROM inserted AS i' + @CrLf
              + @Indent + N'INNER JOIN deleted AS d' + @CrLf
              + @Indent + N'ON i.' + QUOTENAME(@PrimaryKeyColumn) + N' = d.' + QUOTENAME(@PrimaryKeyColumn) + N';' + @CrLf
              + N'END;';
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName AND is_memory_optimized <> 0)
    BEGIN
        EXECUTE (@SQL);
    END;

    SET @SQL = N'';
    SET @SchemaName = N'Application';
    SET @TableName = N'PaymentMethods';
    SET @PrimaryKeyColumn = N'PaymentMethodID';
    SET @LastEditedByColumnName = N'LastEditedBy';
    SET @NormalColumnList = N' [PaymentMethodID], [PaymentMethodName],';
    SET @NormalColumnListWithDPrefix = N' d.[PaymentMethodID], d.[PaymentMethodName],';

    SET @SQL = N'DROP TRIGGER IF EXISTS ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify];'
    EXECUTE (@SQL);

    SET @SQL = N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify]' + @CrLf
              + N'ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + @CrLf
              + N'AFTER INSERT, UPDATE' + @CrLf
              + N'AS' + @CrLf
              + N'BEGIN' + @CrLf
              + @Indent + N'SET NOCOUNT ON;' + @CrLf + @CrLf
              + @Indent + N'IF NOT UPDATE(' + QUOTENAME(@TemporalFromColumnName) + N')' + @CrLf
              + @Indent + N'BEGIN' + @CrLf
              + @Indent + @Indent + N'THROW 51000, ''' + QUOTENAME(@TemporalFromColumnName)
                                  + N' must be updated when simulating data loads'', 1;' + @CrLf
              + @Indent + @Indent + N'ROLLBACK TRAN;' + @CrLf
              + @Indent + N'END;' + @CrLf + @CrLf
              + @Indent + N'INSERT ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName + N'_' + @TemporalTableSuffix) + @CrLf
              + @Indent + @Indent + N'(' + @NormalColumnList + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + QUOTENAME(@TemporalFromColumnName) + N',' + QUOTENAME(@TemporalToColumnName) + N')' + @CrLf
              + @Indent + N'SELECT' + @NormalColumnListWithDPrefix + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN N'd.' + QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + N' d.' + QUOTENAME(@TemporalFromColumnName) + N', i.' + QUOTENAME(@TemporalFromColumnName) + @CrLf
              + @Indent + N'FROM inserted AS i' + @CrLf
              + @Indent + N'INNER JOIN deleted AS d' + @CrLf
              + @Indent + N'ON i.' + QUOTENAME(@PrimaryKeyColumn) + N' = d.' + QUOTENAME(@PrimaryKeyColumn) + N';' + @CrLf
              + N'END;';
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName AND is_memory_optimized <> 0)
    BEGIN
        EXECUTE (@SQL);
    END;

    SET @SQL = N'';
    SET @SchemaName = N'Application';
    SET @TableName = N'People';
    SET @PrimaryKeyColumn = N'PersonID';
    SET @LastEditedByColumnName = N'LastEditedBy';
    SET @NormalColumnList = N' [PersonID], [FullName], [PreferredName], [SearchName], [IsPermittedToLogon], [LogonName], [IsExternalLogonProvider], [HashedPassword], [IsSystemUser], [IsEmployee], [IsSalesperson], [UserPreferences], [PhoneNumber], [FaxNumber], [EmailAddress], [Photo], [CustomFields], [OtherLanguages],';
    SET @NormalColumnListWithDPrefix = N' d.[PersonID], d.[FullName], d.[PreferredName], d.[SearchName], d.[IsPermittedToLogon], d.[LogonName], d.[IsExternalLogonProvider], d.[HashedPassword], d.[IsSystemUser], d.[IsEmployee], d.[IsSalesperson], d.[UserPreferences], d.[PhoneNumber], d.[FaxNumber], d.[EmailAddress], d.[Photo], d.[CustomFields], d.[OtherLanguages],';

    SET @SQL = N'DROP TRIGGER IF EXISTS ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify];'
    EXECUTE (@SQL);

    SET @SQL = N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify]' + @CrLf
              + N'ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + @CrLf
              + N'AFTER INSERT, UPDATE' + @CrLf
              + N'AS' + @CrLf
              + N'BEGIN' + @CrLf
              + @Indent + N'SET NOCOUNT ON;' + @CrLf + @CrLf
              + @Indent + N'IF NOT UPDATE(' + QUOTENAME(@TemporalFromColumnName) + N')' + @CrLf
              + @Indent + N'BEGIN' + @CrLf
              + @Indent + @Indent + N'THROW 51000, ''' + QUOTENAME(@TemporalFromColumnName)
                                  + N' must be updated when simulating data loads'', 1;' + @CrLf
              + @Indent + @Indent + N'ROLLBACK TRAN;' + @CrLf
              + @Indent + N'END;' + @CrLf + @CrLf
              + @Indent + N'INSERT ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName + N'_' + @TemporalTableSuffix) + @CrLf
              + @Indent + @Indent + N'(' + @NormalColumnList + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + QUOTENAME(@TemporalFromColumnName) + N',' + QUOTENAME(@TemporalToColumnName) + N')' + @CrLf
              + @Indent + N'SELECT' + @NormalColumnListWithDPrefix + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN N'd.' + QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + N' d.' + QUOTENAME(@TemporalFromColumnName) + N', i.' + QUOTENAME(@TemporalFromColumnName) + @CrLf
              + @Indent + N'FROM inserted AS i' + @CrLf
              + @Indent + N'INNER JOIN deleted AS d' + @CrLf
              + @Indent + N'ON i.' + QUOTENAME(@PrimaryKeyColumn) + N' = d.' + QUOTENAME(@PrimaryKeyColumn) + N';' + @CrLf
              + N'END;';
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName AND is_memory_optimized <> 0)
    BEGIN
        EXECUTE (@SQL);
    END;

    SET @SQL = N'';
    SET @SchemaName = N'Application';
    SET @TableName = N'StateProvinces';
    SET @PrimaryKeyColumn = N'StateProvinceID';
    SET @LastEditedByColumnName = N'LastEditedBy';
    SET @NormalColumnList = N' [StateProvinceID], [StateProvinceCode], [StateProvinceName], [CountryID], [SalesTerritory], [Border], [LatestRecordedPopulation],';
    SET @NormalColumnListWithDPrefix = N' d.[StateProvinceID], d.[StateProvinceCode], d.[StateProvinceName], d.[CountryID], d.[SalesTerritory], d.[Border], d.[LatestRecordedPopulation],';

    SET @SQL = N'DROP TRIGGER IF EXISTS ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify];'
    EXECUTE (@SQL);

    SET @SQL = N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify]' + @CrLf
              + N'ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + @CrLf
              + N'AFTER INSERT, UPDATE' + @CrLf
              + N'AS' + @CrLf
              + N'BEGIN' + @CrLf
              + @Indent + N'SET NOCOUNT ON;' + @CrLf + @CrLf
              + @Indent + N'IF NOT UPDATE(' + QUOTENAME(@TemporalFromColumnName) + N')' + @CrLf
              + @Indent + N'BEGIN' + @CrLf
              + @Indent + @Indent + N'THROW 51000, ''' + QUOTENAME(@TemporalFromColumnName)
                                  + N' must be updated when simulating data loads'', 1;' + @CrLf
              + @Indent + @Indent + N'ROLLBACK TRAN;' + @CrLf
              + @Indent + N'END;' + @CrLf + @CrLf
              + @Indent + N'INSERT ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName + N'_' + @TemporalTableSuffix) + @CrLf
              + @Indent + @Indent + N'(' + @NormalColumnList + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + QUOTENAME(@TemporalFromColumnName) + N',' + QUOTENAME(@TemporalToColumnName) + N')' + @CrLf
              + @Indent + N'SELECT' + @NormalColumnListWithDPrefix + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN N'd.' + QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + N' d.' + QUOTENAME(@TemporalFromColumnName) + N', i.' + QUOTENAME(@TemporalFromColumnName) + @CrLf
              + @Indent + N'FROM inserted AS i' + @CrLf
              + @Indent + N'INNER JOIN deleted AS d' + @CrLf
              + @Indent + N'ON i.' + QUOTENAME(@PrimaryKeyColumn) + N' = d.' + QUOTENAME(@PrimaryKeyColumn) + N';' + @CrLf
              + N'END;';
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName AND is_memory_optimized <> 0)
    BEGIN
        EXECUTE (@SQL);
    END;

    SET @SQL = N'';
    SET @SchemaName = N'Application';
    SET @TableName = N'TransactionTypes';
    SET @PrimaryKeyColumn = N'TransactionTypeID';
    SET @LastEditedByColumnName = N'LastEditedBy';
    SET @NormalColumnList = N' [TransactionTypeID], [TransactionTypeName],';
    SET @NormalColumnListWithDPrefix = N' d.[TransactionTypeID], d.[TransactionTypeName],';

    SET @SQL = N'DROP TRIGGER IF EXISTS ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify];'
    EXECUTE (@SQL);

    SET @SQL = N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify]' + @CrLf
              + N'ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + @CrLf
              + N'AFTER INSERT, UPDATE' + @CrLf
              + N'AS' + @CrLf
              + N'BEGIN' + @CrLf
              + @Indent + N'SET NOCOUNT ON;' + @CrLf + @CrLf
              + @Indent + N'IF NOT UPDATE(' + QUOTENAME(@TemporalFromColumnName) + N')' + @CrLf
              + @Indent + N'BEGIN' + @CrLf
              + @Indent + @Indent + N'THROW 51000, ''' + QUOTENAME(@TemporalFromColumnName)
                                  + N' must be updated when simulating data loads'', 1;' + @CrLf
              + @Indent + @Indent + N'ROLLBACK TRAN;' + @CrLf
              + @Indent + N'END;' + @CrLf + @CrLf
              + @Indent + N'INSERT ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName + N'_' + @TemporalTableSuffix) + @CrLf
              + @Indent + @Indent + N'(' + @NormalColumnList + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + QUOTENAME(@TemporalFromColumnName) + N',' + QUOTENAME(@TemporalToColumnName) + N')' + @CrLf
              + @Indent + N'SELECT' + @NormalColumnListWithDPrefix + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN N'd.' + QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + N' d.' + QUOTENAME(@TemporalFromColumnName) + N', i.' + QUOTENAME(@TemporalFromColumnName) + @CrLf
              + @Indent + N'FROM inserted AS i' + @CrLf
              + @Indent + N'INNER JOIN deleted AS d' + @CrLf
              + @Indent + N'ON i.' + QUOTENAME(@PrimaryKeyColumn) + N' = d.' + QUOTENAME(@PrimaryKeyColumn) + N';' + @CrLf
              + N'END;';
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName AND is_memory_optimized <> 0)
    BEGIN
        EXECUTE (@SQL);
    END;

    SET @SQL = N'';
    SET @SchemaName = N'Purchasing';
    SET @TableName = N'SupplierCategories';
    SET @PrimaryKeyColumn = N'SupplierCategoryID';
    SET @LastEditedByColumnName = N'LastEditedBy';
    SET @NormalColumnList = N' [SupplierCategoryID], [SupplierCategoryName],';
    SET @NormalColumnListWithDPrefix = N' d.[SupplierCategoryID], d.[SupplierCategoryName],';

    SET @SQL = N'DROP TRIGGER IF EXISTS ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify];'
    EXECUTE (@SQL);

    SET @SQL = N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify]' + @CrLf
              + N'ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + @CrLf
              + N'AFTER INSERT, UPDATE' + @CrLf
              + N'AS' + @CrLf
              + N'BEGIN' + @CrLf
              + @Indent + N'SET NOCOUNT ON;' + @CrLf + @CrLf
              + @Indent + N'IF NOT UPDATE(' + QUOTENAME(@TemporalFromColumnName) + N')' + @CrLf
              + @Indent + N'BEGIN' + @CrLf
              + @Indent + @Indent + N'THROW 51000, ''' + QUOTENAME(@TemporalFromColumnName)
                                  + N' must be updated when simulating data loads'', 1;' + @CrLf
              + @Indent + @Indent + N'ROLLBACK TRAN;' + @CrLf
              + @Indent + N'END;' + @CrLf + @CrLf
              + @Indent + N'INSERT ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName + N'_' + @TemporalTableSuffix) + @CrLf
              + @Indent + @Indent + N'(' + @NormalColumnList + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + QUOTENAME(@TemporalFromColumnName) + N',' + QUOTENAME(@TemporalToColumnName) + N')' + @CrLf
              + @Indent + N'SELECT' + @NormalColumnListWithDPrefix + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN N'd.' + QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + N' d.' + QUOTENAME(@TemporalFromColumnName) + N', i.' + QUOTENAME(@TemporalFromColumnName) + @CrLf
              + @Indent + N'FROM inserted AS i' + @CrLf
              + @Indent + N'INNER JOIN deleted AS d' + @CrLf
              + @Indent + N'ON i.' + QUOTENAME(@PrimaryKeyColumn) + N' = d.' + QUOTENAME(@PrimaryKeyColumn) + N';' + @CrLf
              + N'END;';
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName AND is_memory_optimized <> 0)
    BEGIN
        EXECUTE (@SQL);
    END;

    SET @SQL = N'';
    SET @SchemaName = N'Purchasing';
    SET @TableName = N'Suppliers';
    SET @PrimaryKeyColumn = N'SupplierID';
    SET @LastEditedByColumnName = N'LastEditedBy';
    SET @NormalColumnList = N' [SupplierID], [SupplierName], [SupplierCategoryID], [PrimaryContactPersonID], [AlternateContactPersonID], [DeliveryMethodID], [DeliveryCityID], [PostalCityID], [SupplierReference], [BankAccountName], [BankAccountBranch], [BankAccountCode], [BankAccountNumber], [BankInternationalCode], [PaymentDays], [InternalComments], [PhoneNumber], [FaxNumber], [WebsiteURL], [DeliveryAddressLine1], [DeliveryAddressLine2], [DeliveryPostalCode], [DeliveryLocation], [PostalAddressLine1], [PostalAddressLine2], [PostalPostalCode],';
    SET @NormalColumnListWithDPrefix = N' d.[SupplierID], d.[SupplierName], d.[SupplierCategoryID], d.[PrimaryContactPersonID], d.[AlternateContactPersonID], d.[DeliveryMethodID], d.[DeliveryCityID], d.[PostalCityID], d.[SupplierReference], d.[BankAccountName], d.[BankAccountBranch], d.[BankAccountCode], d.[BankAccountNumber], d.[BankInternationalCode], d.[PaymentDays], d.[InternalComments], d.[PhoneNumber], d.[FaxNumber], d.[WebsiteURL], d.[DeliveryAddressLine1], d.[DeliveryAddressLine2], d.[DeliveryPostalCode], d.[DeliveryLocation], d.[PostalAddressLine1], d.[PostalAddressLine2], d.[PostalPostalCode],';

    SET @SQL = N'DROP TRIGGER IF EXISTS ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify];'
    EXECUTE (@SQL);

    SET @SQL = N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify]' + @CrLf
              + N'ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + @CrLf
              + N'AFTER INSERT, UPDATE' + @CrLf
              + N'AS' + @CrLf
              + N'BEGIN' + @CrLf
              + @Indent + N'SET NOCOUNT ON;' + @CrLf + @CrLf
              + @Indent + N'IF NOT UPDATE(' + QUOTENAME(@TemporalFromColumnName) + N')' + @CrLf
              + @Indent + N'BEGIN' + @CrLf
              + @Indent + @Indent + N'THROW 51000, ''' + QUOTENAME(@TemporalFromColumnName)
                                  + N' must be updated when simulating data loads'', 1;' + @CrLf
              + @Indent + @Indent + N'ROLLBACK TRAN;' + @CrLf
              + @Indent + N'END;' + @CrLf + @CrLf
              + @Indent + N'INSERT ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName + N'_' + @TemporalTableSuffix) + @CrLf
              + @Indent + @Indent + N'(' + @NormalColumnList + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + QUOTENAME(@TemporalFromColumnName) + N',' + QUOTENAME(@TemporalToColumnName) + N')' + @CrLf
              + @Indent + N'SELECT' + @NormalColumnListWithDPrefix + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN N'd.' + QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + N' d.' + QUOTENAME(@TemporalFromColumnName) + N', i.' + QUOTENAME(@TemporalFromColumnName) + @CrLf
              + @Indent + N'FROM inserted AS i' + @CrLf
              + @Indent + N'INNER JOIN deleted AS d' + @CrLf
              + @Indent + N'ON i.' + QUOTENAME(@PrimaryKeyColumn) + N' = d.' + QUOTENAME(@PrimaryKeyColumn) + N';' + @CrLf
              + N'END;';
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName AND is_memory_optimized <> 0)
    BEGIN
        EXECUTE (@SQL);
    END;

    SET @SQL = N'';
    SET @SchemaName = N'Sales';
    SET @TableName = N'BuyingGroups';
    SET @PrimaryKeyColumn = N'BuyingGroupID';
    SET @LastEditedByColumnName = N'LastEditedBy';
    SET @NormalColumnList = N' [BuyingGroupID], [BuyingGroupName],';
    SET @NormalColumnListWithDPrefix = N' d.[BuyingGroupID], d.[BuyingGroupName],';

    SET @SQL = N'DROP TRIGGER IF EXISTS ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify];'
    EXECUTE (@SQL);

    SET @SQL = N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify]' + @CrLf
              + N'ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + @CrLf
              + N'AFTER INSERT, UPDATE' + @CrLf
              + N'AS' + @CrLf
              + N'BEGIN' + @CrLf
              + @Indent + N'SET NOCOUNT ON;' + @CrLf + @CrLf
              + @Indent + N'IF NOT UPDATE(' + QUOTENAME(@TemporalFromColumnName) + N')' + @CrLf
              + @Indent + N'BEGIN' + @CrLf
              + @Indent + @Indent + N'THROW 51000, ''' + QUOTENAME(@TemporalFromColumnName)
                                  + N' must be updated when simulating data loads'', 1;' + @CrLf
              + @Indent + @Indent + N'ROLLBACK TRAN;' + @CrLf
              + @Indent + N'END;' + @CrLf + @CrLf
              + @Indent + N'INSERT ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName + N'_' + @TemporalTableSuffix) + @CrLf
              + @Indent + @Indent + N'(' + @NormalColumnList + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + QUOTENAME(@TemporalFromColumnName) + N',' + QUOTENAME(@TemporalToColumnName) + N')' + @CrLf
              + @Indent + N'SELECT' + @NormalColumnListWithDPrefix + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN N'd.' + QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + N' d.' + QUOTENAME(@TemporalFromColumnName) + N', i.' + QUOTENAME(@TemporalFromColumnName) + @CrLf
              + @Indent + N'FROM inserted AS i' + @CrLf
              + @Indent + N'INNER JOIN deleted AS d' + @CrLf
              + @Indent + N'ON i.' + QUOTENAME(@PrimaryKeyColumn) + N' = d.' + QUOTENAME(@PrimaryKeyColumn) + N';' + @CrLf
              + N'END;';
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName AND is_memory_optimized <> 0)
    BEGIN
        EXECUTE (@SQL);
    END;

    SET @SQL = N'';
    SET @SchemaName = N'Sales';
    SET @TableName = N'CustomerCategories';
    SET @PrimaryKeyColumn = N'CustomerCategoryID';
    SET @LastEditedByColumnName = N'LastEditedBy';
    SET @NormalColumnList = N' [CustomerCategoryID], [CustomerCategoryName],';
    SET @NormalColumnListWithDPrefix = N' d.[CustomerCategoryID], d.[CustomerCategoryName],';

    SET @SQL = N'DROP TRIGGER IF EXISTS ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify];'
    EXECUTE (@SQL);

    SET @SQL = N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify]' + @CrLf
              + N'ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + @CrLf
              + N'AFTER INSERT, UPDATE' + @CrLf
              + N'AS' + @CrLf
              + N'BEGIN' + @CrLf
              + @Indent + N'SET NOCOUNT ON;' + @CrLf + @CrLf
              + @Indent + N'IF NOT UPDATE(' + QUOTENAME(@TemporalFromColumnName) + N')' + @CrLf
              + @Indent + N'BEGIN' + @CrLf
              + @Indent + @Indent + N'THROW 51000, ''' + QUOTENAME(@TemporalFromColumnName)
                                  + N' must be updated when simulating data loads'', 1;' + @CrLf
              + @Indent + @Indent + N'ROLLBACK TRAN;' + @CrLf
              + @Indent + N'END;' + @CrLf + @CrLf
              + @Indent + N'INSERT ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName + N'_' + @TemporalTableSuffix) + @CrLf
              + @Indent + @Indent + N'(' + @NormalColumnList + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + QUOTENAME(@TemporalFromColumnName) + N',' + QUOTENAME(@TemporalToColumnName) + N')' + @CrLf
              + @Indent + N'SELECT' + @NormalColumnListWithDPrefix + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN N'd.' + QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + N' d.' + QUOTENAME(@TemporalFromColumnName) + N', i.' + QUOTENAME(@TemporalFromColumnName) + @CrLf
              + @Indent + N'FROM inserted AS i' + @CrLf
              + @Indent + N'INNER JOIN deleted AS d' + @CrLf
              + @Indent + N'ON i.' + QUOTENAME(@PrimaryKeyColumn) + N' = d.' + QUOTENAME(@PrimaryKeyColumn) + N';' + @CrLf
              + N'END;';
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName AND is_memory_optimized <> 0)
    BEGIN
        EXECUTE (@SQL);
    END;

    SET @SQL = N'';
    SET @SchemaName = N'Sales';
    SET @TableName = N'Customers';
    SET @PrimaryKeyColumn = N'CustomerID';
    SET @LastEditedByColumnName = N'LastEditedBy';
    SET @NormalColumnList = N' [CustomerID], [CustomerName], [BillToCustomerID], [CustomerCategoryID], [BuyingGroupID], [PrimaryContactPersonID], [AlternateContactPersonID], [DeliveryMethodID], [DeliveryCityID], [PostalCityID], [CreditLimit], [AccountOpenedDate], [StandardDiscountPercentage], [IsStatementSent], [IsOnCreditHold], [PaymentDays], [PhoneNumber], [FaxNumber], [DeliveryRun], [RunPosition], [WebsiteURL], [DeliveryAddressLine1], [DeliveryAddressLine2], [DeliveryPostalCode], [DeliveryLocation], [PostalAddressLine1], [PostalAddressLine2], [PostalPostalCode],';
    SET @NormalColumnListWithDPrefix = N' d.[CustomerID], d.[CustomerName], d.[BillToCustomerID], d.[CustomerCategoryID], d.[BuyingGroupID], d.[PrimaryContactPersonID], d.[AlternateContactPersonID], d.[DeliveryMethodID], d.[DeliveryCityID], d.[PostalCityID], d.[CreditLimit], d.[AccountOpenedDate], d.[StandardDiscountPercentage], d.[IsStatementSent], d.[IsOnCreditHold], d.[PaymentDays], d.[PhoneNumber], d.[FaxNumber], d.[DeliveryRun], d.[RunPosition], d.[WebsiteURL], d.[DeliveryAddressLine1], d.[DeliveryAddressLine2], d.[DeliveryPostalCode], d.[DeliveryLocation], d.[PostalAddressLine1], d.[PostalAddressLine2], d.[PostalPostalCode],';

    SET @SQL = N'DROP TRIGGER IF EXISTS ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify];'
    EXECUTE (@SQL);

    SET @SQL = N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify]' + @CrLf
              + N'ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + @CrLf
              + N'AFTER INSERT, UPDATE' + @CrLf
              + N'AS' + @CrLf
              + N'BEGIN' + @CrLf
              + @Indent + N'SET NOCOUNT ON;' + @CrLf + @CrLf
              + @Indent + N'IF NOT UPDATE(' + QUOTENAME(@TemporalFromColumnName) + N')' + @CrLf
              + @Indent + N'BEGIN' + @CrLf
              + @Indent + @Indent + N'THROW 51000, ''' + QUOTENAME(@TemporalFromColumnName)
                                  + N' must be updated when simulating data loads'', 1;' + @CrLf
              + @Indent + @Indent + N'ROLLBACK TRAN;' + @CrLf
              + @Indent + N'END;' + @CrLf + @CrLf
              + @Indent + N'INSERT ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName + N'_' + @TemporalTableSuffix) + @CrLf
              + @Indent + @Indent + N'(' + @NormalColumnList + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + QUOTENAME(@TemporalFromColumnName) + N',' + QUOTENAME(@TemporalToColumnName) + N')' + @CrLf
              + @Indent + N'SELECT' + @NormalColumnListWithDPrefix + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN N'd.' + QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + N' d.' + QUOTENAME(@TemporalFromColumnName) + N', i.' + QUOTENAME(@TemporalFromColumnName) + @CrLf
              + @Indent + N'FROM inserted AS i' + @CrLf
              + @Indent + N'INNER JOIN deleted AS d' + @CrLf
              + @Indent + N'ON i.' + QUOTENAME(@PrimaryKeyColumn) + N' = d.' + QUOTENAME(@PrimaryKeyColumn) + N';' + @CrLf
              + N'END;';
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName AND is_memory_optimized <> 0)
    BEGIN
        EXECUTE (@SQL);
    END;

    SET @SQL = N'';
    SET @SchemaName = N'Warehouse';
    SET @TableName = N'ColdRoomTemperatures';
    SET @PrimaryKeyColumn = N'ColdRoomTemperatureID';
    SET @LastEditedByColumnName = N'';
    SET @NormalColumnList = N' [ColdRoomTemperatureID], [ColdRoomSensorNumber], [RecordedWhen], [Temperature],';
    SET @NormalColumnListWithDPrefix = N' d.[ColdRoomTemperatureID], d.[ColdRoomSensorNumber], d.[RecordedWhen], d.[Temperature],';

    SET @SQL = N'DROP TRIGGER IF EXISTS ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify];'
    EXECUTE (@SQL);

    SET @SQL = N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify]' + @CrLf
              + N'ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + @CrLf
              + N'AFTER INSERT, UPDATE' + @CrLf
              + N'AS' + @CrLf
              + N'BEGIN' + @CrLf
              + @Indent + N'SET NOCOUNT ON;' + @CrLf + @CrLf
              + @Indent + N'IF NOT UPDATE(' + QUOTENAME(@TemporalFromColumnName) + N')' + @CrLf
              + @Indent + N'BEGIN' + @CrLf
              + @Indent + @Indent + N'THROW 51000, ''' + QUOTENAME(@TemporalFromColumnName)
                                  + N' must be updated when simulating data loads'', 1;' + @CrLf
              + @Indent + @Indent + N'ROLLBACK TRAN;' + @CrLf
              + @Indent + N'END;' + @CrLf + @CrLf
              + @Indent + N'INSERT ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName + N'_' + @TemporalTableSuffix) + @CrLf
              + @Indent + @Indent + N'(' + @NormalColumnList + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + QUOTENAME(@TemporalFromColumnName) + N',' + QUOTENAME(@TemporalToColumnName) + N')' + @CrLf
              + @Indent + N'SELECT' + @NormalColumnListWithDPrefix + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN N'd.' + QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + N' d.' + QUOTENAME(@TemporalFromColumnName) + N', i.' + QUOTENAME(@TemporalFromColumnName) + @CrLf
              + @Indent + N'FROM inserted AS i' + @CrLf
              + @Indent + N'INNER JOIN deleted AS d' + @CrLf
              + @Indent + N'ON i.' + QUOTENAME(@PrimaryKeyColumn) + N' = d.' + QUOTENAME(@PrimaryKeyColumn) + N';' + @CrLf
              + N'END;';
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName AND is_memory_optimized <> 0)
    BEGIN
        EXECUTE (@SQL);
    END;

    SET @SQL = N'';
    SET @SchemaName = N'Warehouse';
    SET @TableName = N'Colors';
    SET @PrimaryKeyColumn = N'ColorID';
    SET @LastEditedByColumnName = N'LastEditedBy';
    SET @NormalColumnList = N' [ColorID], [ColorName],';
    SET @NormalColumnListWithDPrefix = N' d.[ColorID], d.[ColorName],';

    SET @SQL = N'DROP TRIGGER IF EXISTS ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify];'
    EXECUTE (@SQL);

    SET @SQL = N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify]' + @CrLf
              + N'ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + @CrLf
              + N'AFTER INSERT, UPDATE' + @CrLf
              + N'AS' + @CrLf
              + N'BEGIN' + @CrLf
              + @Indent + N'SET NOCOUNT ON;' + @CrLf + @CrLf
              + @Indent + N'IF NOT UPDATE(' + QUOTENAME(@TemporalFromColumnName) + N')' + @CrLf
              + @Indent + N'BEGIN' + @CrLf
              + @Indent + @Indent + N'THROW 51000, ''' + QUOTENAME(@TemporalFromColumnName)
                                  + N' must be updated when simulating data loads'', 1;' + @CrLf
              + @Indent + @Indent + N'ROLLBACK TRAN;' + @CrLf
              + @Indent + N'END;' + @CrLf + @CrLf
              + @Indent + N'INSERT ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName + N'_' + @TemporalTableSuffix) + @CrLf
              + @Indent + @Indent + N'(' + @NormalColumnList + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + QUOTENAME(@TemporalFromColumnName) + N',' + QUOTENAME(@TemporalToColumnName) + N')' + @CrLf
              + @Indent + N'SELECT' + @NormalColumnListWithDPrefix + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN N'd.' + QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + N' d.' + QUOTENAME(@TemporalFromColumnName) + N', i.' + QUOTENAME(@TemporalFromColumnName) + @CrLf
              + @Indent + N'FROM inserted AS i' + @CrLf
              + @Indent + N'INNER JOIN deleted AS d' + @CrLf
              + @Indent + N'ON i.' + QUOTENAME(@PrimaryKeyColumn) + N' = d.' + QUOTENAME(@PrimaryKeyColumn) + N';' + @CrLf
              + N'END;';
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName AND is_memory_optimized <> 0)
    BEGIN
        EXECUTE (@SQL);
    END;

    SET @SQL = N'';
    SET @SchemaName = N'Warehouse';
    SET @TableName = N'PackageTypes';
    SET @PrimaryKeyColumn = N'PackageTypeID';
    SET @LastEditedByColumnName = N'LastEditedBy';
    SET @NormalColumnList = N' [PackageTypeID], [PackageTypeName],';
    SET @NormalColumnListWithDPrefix = N' d.[PackageTypeID], d.[PackageTypeName],';

    SET @SQL = N'DROP TRIGGER IF EXISTS ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify];'
    EXECUTE (@SQL);

    SET @SQL = N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify]' + @CrLf
              + N'ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + @CrLf
              + N'AFTER INSERT, UPDATE' + @CrLf
              + N'AS' + @CrLf
              + N'BEGIN' + @CrLf
              + @Indent + N'SET NOCOUNT ON;' + @CrLf + @CrLf
              + @Indent + N'IF NOT UPDATE(' + QUOTENAME(@TemporalFromColumnName) + N')' + @CrLf
              + @Indent + N'BEGIN' + @CrLf
              + @Indent + @Indent + N'THROW 51000, ''' + QUOTENAME(@TemporalFromColumnName)
                                  + N' must be updated when simulating data loads'', 1;' + @CrLf
              + @Indent + @Indent + N'ROLLBACK TRAN;' + @CrLf
              + @Indent + N'END;' + @CrLf + @CrLf
              + @Indent + N'INSERT ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName + N'_' + @TemporalTableSuffix) + @CrLf
              + @Indent + @Indent + N'(' + @NormalColumnList + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + QUOTENAME(@TemporalFromColumnName) + N',' + QUOTENAME(@TemporalToColumnName) + N')' + @CrLf
              + @Indent + N'SELECT' + @NormalColumnListWithDPrefix + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN N'd.' + QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + N' d.' + QUOTENAME(@TemporalFromColumnName) + N', i.' + QUOTENAME(@TemporalFromColumnName) + @CrLf
              + @Indent + N'FROM inserted AS i' + @CrLf
              + @Indent + N'INNER JOIN deleted AS d' + @CrLf
              + @Indent + N'ON i.' + QUOTENAME(@PrimaryKeyColumn) + N' = d.' + QUOTENAME(@PrimaryKeyColumn) + N';' + @CrLf
              + N'END;';
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName AND is_memory_optimized <> 0)
    BEGIN
        EXECUTE (@SQL);
    END;

    SET @SQL = N'';
    SET @SchemaName = N'Warehouse';
    SET @TableName = N'StockGroups';
    SET @PrimaryKeyColumn = N'StockGroupID';
    SET @LastEditedByColumnName = N'LastEditedBy';
    SET @NormalColumnList = N' [StockGroupID], [StockGroupName],';
    SET @NormalColumnListWithDPrefix = N' d.[StockGroupID], d.[StockGroupName],';

    SET @SQL = N'DROP TRIGGER IF EXISTS ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify];'
    EXECUTE (@SQL);

    SET @SQL = N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify]' + @CrLf
              + N'ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + @CrLf
              + N'AFTER INSERT, UPDATE' + @CrLf
              + N'AS' + @CrLf
              + N'BEGIN' + @CrLf
              + @Indent + N'SET NOCOUNT ON;' + @CrLf + @CrLf
              + @Indent + N'IF NOT UPDATE(' + QUOTENAME(@TemporalFromColumnName) + N')' + @CrLf
              + @Indent + N'BEGIN' + @CrLf
              + @Indent + @Indent + N'THROW 51000, ''' + QUOTENAME(@TemporalFromColumnName)
                                  + N' must be updated when simulating data loads'', 1;' + @CrLf
              + @Indent + @Indent + N'ROLLBACK TRAN;' + @CrLf
              + @Indent + N'END;' + @CrLf + @CrLf
              + @Indent + N'INSERT ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName + N'_' + @TemporalTableSuffix) + @CrLf
              + @Indent + @Indent + N'(' + @NormalColumnList + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + QUOTENAME(@TemporalFromColumnName) + N',' + QUOTENAME(@TemporalToColumnName) + N')' + @CrLf
              + @Indent + N'SELECT' + @NormalColumnListWithDPrefix + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN N'd.' + QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + N' d.' + QUOTENAME(@TemporalFromColumnName) + N', i.' + QUOTENAME(@TemporalFromColumnName) + @CrLf
              + @Indent + N'FROM inserted AS i' + @CrLf
              + @Indent + N'INNER JOIN deleted AS d' + @CrLf
              + @Indent + N'ON i.' + QUOTENAME(@PrimaryKeyColumn) + N' = d.' + QUOTENAME(@PrimaryKeyColumn) + N';' + @CrLf
              + N'END;';
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName AND is_memory_optimized <> 0)
    BEGIN
        EXECUTE (@SQL);
    END;

    SET @SQL = N'';
    SET @SchemaName = N'Warehouse';
    SET @TableName = N'StockItems';
    SET @PrimaryKeyColumn = N'StockItemID';
    SET @LastEditedByColumnName = N'LastEditedBy';
    SET @NormalColumnList = N' [StockItemID], [StockItemName], [SupplierID], [ColorID], [UnitPackageID], [OuterPackageID], [Brand], [Size], [LeadTimeDays], [QuantityPerOuter], [IsChillerStock], [Barcode], [TaxRate], [UnitPrice], [RecommendedRetailPrice], [TypicalWeightPerUnit], [MarketingComments], [InternalComments], [Photo], [CustomFields], [Tags], [SearchDetails],';
    SET @NormalColumnListWithDPrefix = N' d.[StockItemID], d.[StockItemName], d.[SupplierID], d.[ColorID], d.[UnitPackageID], d.[OuterPackageID], d.[Brand], d.[Size], d.[LeadTimeDays], d.[QuantityPerOuter], d.[IsChillerStock], d.[Barcode], d.[TaxRate], d.[UnitPrice], d.[RecommendedRetailPrice], d.[TypicalWeightPerUnit], d.[MarketingComments], d.[InternalComments], d.[Photo], d.[CustomFields], d.[Tags], d.[SearchDetails],';

    SET @SQL = N'DROP TRIGGER IF EXISTS ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify];'
    EXECUTE (@SQL);

    SET @SQL = N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify]' + @CrLf
              + N'ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + @CrLf
              + N'AFTER INSERT, UPDATE' + @CrLf
              + N'AS' + @CrLf
              + N'BEGIN' + @CrLf
              + @Indent + N'SET NOCOUNT ON;' + @CrLf + @CrLf
              + @Indent + N'IF NOT UPDATE(' + QUOTENAME(@TemporalFromColumnName) + N')' + @CrLf
              + @Indent + N'BEGIN' + @CrLf
              + @Indent + @Indent + N'THROW 51000, ''' + QUOTENAME(@TemporalFromColumnName)
                                  + N' must be updated when simulating data loads'', 1;' + @CrLf
              + @Indent + @Indent + N'ROLLBACK TRAN;' + @CrLf
              + @Indent + N'END;' + @CrLf + @CrLf
              + @Indent + N'INSERT ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName + N'_' + @TemporalTableSuffix) + @CrLf
              + @Indent + @Indent + N'(' + @NormalColumnList + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + QUOTENAME(@TemporalFromColumnName) + N',' + QUOTENAME(@TemporalToColumnName) + N')' + @CrLf
              + @Indent + N'SELECT' + @NormalColumnListWithDPrefix + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN N'd.' + QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + N' d.' + QUOTENAME(@TemporalFromColumnName) + N', i.' + QUOTENAME(@TemporalFromColumnName) + @CrLf
              + @Indent + N'FROM inserted AS i' + @CrLf
              + @Indent + N'INNER JOIN deleted AS d' + @CrLf
              + @Indent + N'ON i.' + QUOTENAME(@PrimaryKeyColumn) + N' = d.' + QUOTENAME(@PrimaryKeyColumn) + N';' + @CrLf
              + N'END;';
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName AND is_memory_optimized <> 0)
    BEGIN
        EXECUTE (@SQL);
    END;

END;

GO

-- File: GetBogativePostalCode.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[GetBogativePostalCode]
  @CityID INT
, @PostalCode NVARCHAR(10) OUTPUT
AS
BEGIN

/*
Notes:
  Generates a fake postal code formatted accurately for the country
  needed.

  Note only countries for which data is being generated are included.
  As time goes by this will be expanded.

  If the country is not found then the procedure just defaults to the
  standard US format.

Usage:
  DECLARE @myPostalCode AS NVARCHAR(10)
  EXEC [DataLoadSimulation].[GetBogativePostalCode]
      @CityID = 1
    , @PostalCode = @myPostalCode OUTPUT
  SELECT @myPostalCode

*/

  DECLARE @CountryName AS NVARCHAR(60)

  SELECT TOP 1 @CountryName = o.[CountryName]
    FROM [Application].[Cities] c
    JOIN [Application].[StateProvinces] s
      ON c.StateProvinceID = s.StateProvinceID
    JOIN [Application].[Countries] o
      ON s.CountryID = o.CountryID
   WHERE c.[CityID] = @CityID
     AND c.[ValidTo] = '9999-12-31 23:59:59.9999999'

  -- Generate a fake postal code but formatted for the country
  SET @PostalCode
    = CASE @CountryName
        WHEN 'United States'
        THEN RIGHT('00000' + CAST((ABS(CHECKSUM(NEWID())) % 99999) AS NVARCHAR), 5)
        ELSE RIGHT('00000' + CAST((ABS(CHECKSUM(NEWID())) % 99999) AS NVARCHAR), 5)
      END

END



GO

-- File: GetBuyingGroupDomain.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[GetBuyingGroupDomain]
  @BuyingGroup AS NVARCHAR(50)
, @WebDomain   AS NVARCHAR(256) OUTPUT
, @EmailDomain AS NVARCHAR(256) OUTPUT
AS
BEGIN
/*
Notes:
  Unfortunately the URLs for the buying groups aren't found
  elsewhere, so we have to create a proc with them hard
  coded and use this proc to look them up

Usage:
  DECLARE @myDomain AS NVARCHAR(256)
  EXEC [DataLoadSimulation].[GetBuyingGroupDomain]
      @BuyingGroup = 'Woodgrove Bank'
    , @WebDomain   = @myWebDomain OUTPUT
    , @EmailDomain = @myEmailDomain OUTPUT
  SELECT @myURL

*/

  DECLARE @urls AS TABLE ( BuyingGroupName NVARCHAR(50)
                         , WebDomain       NVARCHAR(256)
                         , EmailDomain     NVARCHAR(256)
)

  INSERT INTO @urls (BuyingGroupName, WebDomain, EmailDomain)
  VALUES
      (N'Datum Corporation',                          N'http://www.adatum.com/',                               N'adatum.com')
    , (N'Adventure Works Cycles',                     N'http://www.adventure-works.com/',                      N'adventure-works.com')
    , (N'Alpine Ski House',                           N'http://www.alpineskihouse.com/',                       N'alpineskihouse.com')
    , (N'Bellows College',                            N'http://www.bellowscollege.com',                        N'bellowscollege.com')
    , (N'Best For You Organics Company',              N'http://www.bestforyouorganics.com',                    N'bestforyouorganics.com')
    , (N'Blue Younder Airlines',                      N'http://www.blueyonderairlines.com/',                   N'blueyonderairlines.com')
    , (N'City Power & Light',                         N'http://www.cpandl.com/',                               N'cpandl.com')
    , (N'Coho Vineyard',                              N'http://www.cohovineyard.com/',                         N'cohovineyard.com')
    , (N'Coho Winery',                                N'http://www.cohowinery.com/',                           N'cohowinery.com')
    , (N'Coho Vineyard & Winery',                     N'http://www.cohovineyardandwinery.com/',                N'cohovineyardandwinery.com')
    , (N'Contoso, Ltd.',                              N'http://www.contoso.com/',                              N'contoso.com')
    , (N'Contoso Pharmaceuticals',                    N'http://www.contoso.com/',                              N'contoso.com')
    , (N'Contoso Suites',                             N'http://www.contososuites.com',                         N'contososuites.com')
    , (N'Consolidated Messenger',                     N'http://www.consolidatedmessenger.com/',                N'consolidatedmessenger.com')
    , (N'Fabrikam, Inc.',                             N'http://www.fabrikam.com/',                             N'fabrikam.com')
    , (N'Fabrikam Residences',                        N'http://fabrikamresidences.com',                        N'fabrikamresidences.com')
    , (N'First Up Consultants',                       N'http://firstupconsultants.com',                        N'firstupconsultants.com')
    , (N'Fourth Coffee',                              N'http://www.fourthcoffee.com/',                         N'fourthcoffee.com')
    , (N'Graphic Design Institute',                   N'http://www.graphicdesigninstitute.com/',               N'graphicdesigninstitute.com')
    , (N'Humongous Insurance',                        N'http://www.humongousinsurance.com/',                   N'humongousinsurance.com')
    , (N'Lamna Healthcare Company',                   N'http://www.lamnahealtcare.com',                        N'lamnahealtcare.com')
    , (N'Litware, Inc.',                              N'http://www.litwareinc.com/',                           N'litwareinc.com')
    , (N'Liberty''s Delightful Sinful Bakery & Cafe', N'http://www.libertysdelightfulsinfulbakeryandcafe.com', N'libertysdelightfulsinfulbakeryandcafe.com')
    , (N'Lucerne Publishing',                         N'http://www.lucernepublishing.com/',                    N'lucernepublishing.com')
    , (N'Margie''s Travel',                           N'http://www.margiestravel.com/',                        N'margiestravel.com')
    , (N'Munson''s Pickles and Preserves Farm',       N'http://www.munsonspicklesandpreservesfarm.com',        N'munsonspicklesandpreservesfarm.com')
    , (N'Nod Publishers',                             N'http://www.nodpublishers.com',                         N'nodpublishers.com')
    , (N'Northwind Electric Cars',                    N'http://www.northwindelectriccars.com',                 N'northwindelectriccars.com')
    , (N'Northwind Traders',                          N'http://www.northwindtraders.com/',                     N'northwindtraders.com')
    , (N'Proseware, Inc.',                            N'http://www.proseware.com/',                            N'proseware.com')
    , (N'Relecloud',                                  N'http://www.relecloud.com',                             N'relecloud.com')
    , (N'School of Fine Art',                         N'http://www.fineartschool.net',                         N'fineartschool.net')
    , (N'Southridge Video',                           N'http://www.southridgevideo.com/',                      N'southridgevideo.com')
    , (N'Tailspin Toys',                              N'http://www.tailspintoys.com/',                         N'tailspintoys.com')
    , (N'Trey Research',                              N'http://www.treyresearch.net/',                         N'treyresearch.net')
    , (N'The Phone Company',                          N'http://www.thephone-company.com/',                     N'thephone-company.com')
    , (N'VanArsdel, Ltd.',                            N'http://www.vanarsdelltd.com',                          N'vanarsdelltd.com')
    , (N'Wide World Importers',                       N'http://www.wideworldimporters.com/',                   N'wideworldimporters.com')
    , (N'Wingtip Toys',                               N'http://wingtiptoys.com/',                              N'wingtiptoys.com')
    , (N'Woodgrove Bank',                             N'http://www.woodgrovebank.com/',                        N'woodgrovebank.com')
    , (N'Individual Buyer',                           N'N/A',                                                  N'N/A')

  SET @WebDomain = N'N/A'
  SET @EmailDomain = N'N/A'
  SELECT @WebDomain = WebDomain, @EmailDomain = EmailDomain
    FROM @urls
   WHERE BuyingGroupName = @BuyingGroup

END


GO

-- File: GetFicticiousName.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[GetFicticiousName]
  @FirstName AS NVARCHAR(20) OUTPUT
, @LastName  AS NVARCHAR(20) OUTPUT
, @FullName  AS NVARCHAR(40) OUTPUT
, @Email     AS NVARCHAR(200) OUTPUT
AS
BEGIN
/*
Notes:
  Reads the table of Microsoft lawyer approved names, then randomly
  selects one that has not already been used in the Application.People
  table.

Usage:
  DECLARE @myFirstName AS NVARCHAR(20)
  DECLARE @myLastName  AS NVARCHAR(20)
  DECLARE @myFullName  AS NVARCHAR(40)
  DECLARE @myEmail     AS NVARCHAR(200)

  EXEC [DataLoadSimulation].[GetFicticiousName] @FirstName = @myFirstName OUTPUT
                                              , @LastName  = @myLastName OUTPUT
                                              , @FullName  = @myFullName OUTPUT
                                              , @Email     = @myEmail OUTPUT

  SELECT @myFirstName, @myLastName, @myFullName, @myEmail

*/

  -- Randomly pick a name from the ficticious name pool that has not
  -- already been used in the application people table
  SELECT TOP 1
         @FirstName = PreferredName
       , @LastName  = LastName
       , @FullName  = FullName
       , @Email     = ToEmail
    FROM [DataLoadSimulation].[FicticiousNamePool] fnp
   WHERE fnp.FullName NOT IN (SELECT ap.FullName
                                FROM [Application].[People] ap
                               WHERE ap.FullName = fnp.FullName
                             )
  ORDER BY NEWID()

  RETURN
END
;
GO


GO

-- File: GetRandomBuyingGroup.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[GetRandomBuyingGroup]
  @BuyingGroupID   INT          OUTPUT
, @BuyingGroupName NVARCHAR(50) OUTPUT
AS
BEGIN
/*
Notes:
  Retrieves a random buying group.
  1 is reserved for individual buyers, so we want to
  get an ID above that.

Usage:
  DECLARE @BuyingGroupID INT
  DECLARE @BuyingGroupName NVARCHAR(50)
  EXEC [DataLoadSimulation].[GetRandomBuyingGroup]
      @BuyingGroupID   = @BuyingGroupID   OUTPUT
    , @BuyingGroupName = @BuyingGroupName OUTPUT
  SELECT @BuyingGroupID, @BuyingGroupName
*/

  SELECT TOP 1
         @BuyingGroupID = [BuyingGroupID]
       , @BuyingGroupName = [BuyingGroupName]
    FROM [Sales].[BuyingGroups]
   WHERE [ValidTo] = '9999-12-31 23:59:59.9999999'
     AND [BuyingGroupID] > 1
   ORDER BY NEWID()

END

GO

-- File: GetRandomBuyingGroupNotInUse.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[GetRandomBuyingGroupNotInUse]
  @CityID            AS INT           OUTPUT
, @CityName          AS NVARCHAR(50)  OUTPUT
, @StateProvinceCode AS NVARCHAR(5)   OUTPUT
, @StateProvinceName AS NVARCHAR(50)  OUTPUT
, @AreaCode          AS NVARCHAR(4)   OUTPUT
, @BuyingGroupID     AS INT           OUTPUT
, @BuyingGroupName   AS NVARCHAR(50)  OUTPUT
, @WebDomain         AS NVARCHAR(256) OUTPUT
, @EmailDomain       AS NVARCHAR(256) OUTPUT
, @CustomerName      AS NVARCHAR(100) OUTPUT
AS
BEGIN
/*
Notes:
  Gets a buying group/city combination that will be used
  as a new customer. Get one that is not already in use.

Usage:
  DECLARE @myCityID            AS INT
  DECLARE @myCityName          AS NVARCHAR(50)
  DECLARE @myStateProvinceCode AS NVARCHAR(5)
  DECLARE @myStateProvinceName AS NVARCHAR(50)
  DECLARE @myAreaCode          AS NVARCHAR(4)
  DECLARE @myBuyingGroupID     AS INT
  DECLARE @myBuyingGroupName   AS NVARCHAR(50)
  DECLARE @myWebDomain         AS NVARCHAR(256)
  DECLARE @myEmailDomain       AS NVARCHAR(256)
  DECLARE @myCustomerName      AS NVARCHAR(100)

  EXEC [DataLoadSimulation].[GetRandomBuyingGroupNotInUse]
      @CityID            = @myCityID            OUTPUT
    , @CityName          = @myCityName          OUTPUT
    , @StateProvinceCode = @myStateProvinceCode OUTPUT
    , @StateProvinceName = @myStateProvinceName OUTPUT
    , @AreaCode          = @myAreaCode          OUTPUT
    , @BuyingGroupID     = @myBuyingGroupID     OUTPUT
    , @BuyingGroupName   = @myBuyingGroupName   OUTPUT
    , @WebDomain         = @myWebDomain         OUTPUT
    , @EmailDomain       = @myEmailDomain       OUTPUT
    , @CustomerName      = @myCustomerName      OUTPUT

  SELECT @myCityID, @myCityName, @myStateProvinceCode
       , @myStateProvinceName, @myAreaCode, @myBuyingGroupID
       , @myBuyingGroupName, @myWebDomain, @myEmailDomain
       , @myCustomerName

*/
  DECLARE @InUseCounter AS INT

  SET @InUseCounter = 1 -- Reset from last run
  WHILE @InUseCounter > 0
  BEGIN
    EXEC [DataLoadSimulation].[GetRandomCity]
        @CityID            = @CityID            OUTPUT
      , @CityName          = @CityName          OUTPUT
      , @StateProvinceCode = @StateProvinceCode OUTPUT
      , @StateProvinceName = @StateProvinceName OUTPUT
      , @AreaCode          = @AreaCode          OUTPUT

    EXEC [DataLoadSimulation].[GetRandomBuyingGroup]
        @BuyingGroupID   = @BuyingGroupID   OUTPUT
      , @BuyingGroupName = @BuyingGroupName OUTPUT

    -- See if this is in use, if not it'll exit the loop and
    -- we can continue
    SET @InUseCounter = [DataLoadSimulation].[GetCustomerCount]
      ( @BuyingGroupName
        + ' (' + @CityName + ', '
        + @StateProvinceCode + ')'
      )
  END -- WHILE @InUseCounter > 0

  EXEC [DataLoadSimulation].[GetBuyingGroupDomain]
      @BuyingGroup = @BuyingGroupName
    , @WebDomain   = @WebDomain OUTPUT
    , @EmailDomain = @EmailDomain OUTPUT

  SET @CustomerName = @BuyingGroupName
                    + ' (' + @CityName
                    + ', ' + @StateProvinceCode + ')'

  RETURN 0
END

GO

-- File: GetRandomCity.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[GetRandomCity]
  @CityID            INT          OUTPUT
, @CityName          NVARCHAR(50) OUTPUT
, @StateProvinceCode NVARCHAR(5)  OUTPUT
, @StateProvinceName NVARCHAR(50) OUTPUT
, @AreaCode          NVARCHAR(4)  OUTPUT
AS
BEGIN
/*
  Usage:
    DECLARE @myCityID            AS INT
    DECLARE @myCityName          AS NVARCHAR(50)
    DECLARE @myStateProvinceCode AS NVARCHAR(5)
    DECLARE @myStateProvinceName AS NVARCHAR(50)
    DECLARE @myAreaCode          AS NVARCHAR(3)

    EXEC [DataLoadSimulation].[GetRandomCity]
      @CityID            = @myCityID            OUTPUT
    , @CityName          = @myCityName          OUTPUT
    , @StateProvinceCode = @myStateProvinceCode OUTPUT
    , @StateProvinceName = @myStateProvinceName OUTPUT
    , @AreaCode          = @myAreaCode          OUTPUT

    SELECT @myCityID , @myCityName, @myStateProvinceCode, @myStateProvinceName, @myAreaCode
*/

  SET @CityID = NULL
  WHILE @CityID IS NULL
  BEGIN
    SELECT TOP 1
           @CityID            = c.[CityID]
         , @CityName          = c.[CityName]
         , @StateProvinceCode = s.[StateProvinceCode]
         , @StateProvinceName = s.[StateProvinceName]
         , @AreaCode          = a.[AreaCode]
      FROM [Application].[Cities] c
      JOIN [Application].[StateProvinces] s
        ON c.[StateProvinceID] = s.[StateProvinceID]
      JOIN [DataLoadSimulation].[AreaCode] a
        ON a.[StateProvinceCode] = s.[StateProvinceCode]
     ORDER BY NEWID()
  END

  RETURN

END;

GO

-- File: GetRandomCustomer.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[GetRandomCustomer]
  @RandomCustomerID INT OUTPUT
, @CustomerPrimaryContactPersonID INT OUTPUT
AS
BEGIN
/*
Notes:
  Selects a random sales person ID.

  As with other similar procs, we have to use a proc as opposed
  to a function as random tools such as NEWID and RAND don't work
  in functions

Usage:
  DECLARE @myCustomerID INT
  DECLARE @myCustomerPrimaryContactPersonID INT
  EXEC [DataLoadSimulation].[GetRandomCustomer]
      @RandomCustomerID = @myCustomerID OUTPUT
    , @CustomerPrimaryContactPersonID = @myCustomerPrimaryContactPersonID OUTPUT
  SELECT @myCustomerID, @myCustomerPrimaryContactPersonID

*/

  SELECT TOP(1)
         @RandomCustomerID = c.CustomerID
       , @CustomerPrimaryContactPersonID = c.PrimaryContactPersonID
    FROM Sales.Customers AS c
   WHERE c.IsOnCreditHold = 0
     AND ValidTo = '99991231 23:59:59.9999999'
   ORDER BY NEWID()

  RETURN

END



GO

-- File: GetRandomCustomerCategory.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[GetRandomCustomerCategory]
@RandomCustomerCategoryID INT OUTPUT
AS
BEGIN
/*
Notes:
  Selects a random category ID from the customer category table
  for categories other than corporate (we only want the Head Office
  stores to be of type corporate, and that is set in another
  routine).

  As with other similar procs, we have to use a proc as opposed
  to a function as random tools such as NEWID and RAND don't work
  in functions

Usage:
  DECLARE @myCustomerCategoryID AS INT
  EXEC [DataLoadSimulation].[GetRandomCustomerCategory]
    @RandomCustomerCategoryID = @myCustomerCategoryID OUTPUT
  SELECT @myCustomerCategoryID

*/

  SELECT TOP 1
         @RandomCustomerCategoryID = CustomerCategoryID
    FROM [Sales].[CustomerCategories]
   WHERE CustomerCategoryID > 0
     AND CustomerCategoryName <> 'Corporate'
   ORDER BY NEWID()

  RETURN

END


GO

-- File: GetRandomDeliveryMethod.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[GetRandomDeliveryMethod]
@RandomDeliveryMethod INT OUTPUT
AS
BEGIN
/*
Notes:
  Selects a random delivery method.

  As with other similar procs, we have to use a proc as opposed
  to a function as random tools such as NEWID and RAND don't work
  in functions

Usage:
  DECLARE @DeliveryMethod INT
  EXEC [DataLoadSimulation].[GetRandomDeliveryMethod]
    @RandomDeliveryMethod = @DeliveryMethod OUTPUT
  SELECT @DeliveryMethod

*/
  SELECT TOP (1) @RandomDeliveryMethod = [DeliveryMethodID]
    FROM [Application].[DeliveryMethods]
   WHERE ValidTo = '99991231 23:59:59.9999999'
   ORDER BY NEWID()

  RETURN

END


GO

-- File: GetRandomEmployeePerson.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[GetRandomEmployeePerson]
  @EmployeePersonID INT OUTPUT
AS
BEGIN
/*
Notes:
  Selects a random person ID.

  As with other similar procs, we have to use a proc as opposed
  to a function as random tools such as NEWID and RAND don't work
  in functions

Usage:
  DECLARE @myEmployeePersonID INT
  EXEC [DataLoadSimulation].[GetRandomEmployeePerson]
      @EmployeePersonID = @myEmployeePersonID OUTPUT
  SELECT @myEmployeePersonID

*/

  SELECT TOP(1)
         @EmployeePersonID = PersonID
    FROM [Application].People
   WHERE IsEmployee <> 0
     AND ValidTo = '99991231 23:59:59.9999999'
   ORDER BY NEWID()

  RETURN

END



GO

-- File: GetRandomPaymentDays.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[GetRandomPaymentDays]
@RandomPaymentDays AS INT OUTPUT
AS
BEGIN
/*
Notes:
  Randomly generates a standard number of payment days

Usage:
  DECLARE @myPaymentDays AS INT
  EXEC [DataLoadSimulation].[GetRandomPaymentDays] @RandomPaymentDays = @myPaymentDays OUTPUT
  SELECT @myPaymentDays

*/
  DECLARE @pd AS INT

  SET @pd = CAST((ABS(CHECKSUM(NEWID())) % 8) AS INT)

  -- Note as 30 and 45 are the most common for payment day values,
  -- we want them to come up more often hence we included them
  -- multiple times
  SET @RandomPaymentDays = CASE WHEN @pd = 0 THEN 30
                                WHEN @pd = 1 THEN 45
                                WHEN @pd = 2 THEN 60
                                WHEN @pd = 3 THEN 90
                                WHEN @pd = 4 THEN 180
                                WHEN @pd = 5 THEN 30
                                WHEN @pd = 6 THEN 45
                                WHEN @pd = 7 THEN 30
                                WHEN @pd = 8 THEN 45
                                ELSE 30
                            END
END


GO

-- File: GetRandomSalesPersonID.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[GetRandomSalesPersonID]
@RandomSalesPersonID INT OUTPUT
AS
BEGIN
/*
Notes:
  Selects a random sales person ID.

  As with other similar procs, we have to use a proc as opposed
  to a function as random tools such as NEWID and RAND don't work
  in functions

Usage:
  DECLARE @SalesPersonID INT
  EXEC [DataLoadSimulation].[GetRandomSalesPersonID]
    @RandomSalesPersonID = @SalesPersonID OUTPUT
  SELECT @SalesPersonID

*/

  SELECT TOP 1
         @RandomSalesPersonID = PersonID
    FROM [Application].[People]
   WHERE IsSalesperson <> 0
     AND ValidTo = '99991231 23:59:59.9999999'
   ORDER BY NEWID()

  RETURN

END


GO

-- File: GetRandomSecondaryAddress.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[GetRandomSecondaryAddress]
@randomSecondaryAddress NVARCHAR(20) OUTPUT
AS
BEGIN
/*
Notes:
  This procedure will randomly select a street name from the table
  variable loaded herein.

  While it would be preferable to have implemented this as a function,
  the NEWID mechanism needed to make this work are not allowed within
  a function hence the requirement to implement in a stored procedure.

Usage:
  DECLARE @r AS NVARCHAR(20)
  EXEC [DataLoadSimulation].[GetRandomSecondaryAddress] @randomSecondaryAddress = @r OUTPUT;
  SELECT @r
*/

  DECLARE @seconaryAddress TABLE (secondAddress NVARCHAR(20))

  -- A high percentage of the time we want the secondary address to be
  -- blank, so we're putting blank entries in the table to give a good
  -- chance of a blank secondary coming up
  INSERT INTO @seconaryAddress
  VALUES ('PO Box ')
       , ('Suite ')
       , ('Office ')
       , ('Mail Stop ')
       , ('Box ')
       , ('Bin ')
       , ('Room ')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       ;

  DECLARE @sa AS NVARCHAR(20)
  SELECT TOP 1 @sa = secondAddress FROM @seconaryAddress ORDER BY NEWID()
  IF LEN(@sa) > 0
    SET @randomSecondaryAddress = @sa + CAST((ABS(CHECKSUM(NEWID())) % 899) AS NVARCHAR)
  ELSE
    SET @randomSecondaryAddress = ''

  RETURN

END;


GO

-- File: GetRandomStockItemToAdjust.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[GetRandomStockItemToAdjust]
  @QuantityToAdjust    INT
, @StockItemIDToAdjust INT OUTPUT
AS
BEGIN
/*
Notes:
  Selects stock item to adjust ID.

  As with other similar procs, we have to use a proc as opposed
  to a function as random tools such as NEWID and RAND don't work
  in functions

Usage:
  DECLARE @myStockItemIDToAdjust INT
  EXEC [DataLoadSimulation].[GetRandomStockItemToAdjust]
    10, @StockItemIDToAdjust = @myStockItemIDToAdjust OUTPUT
  SELECT @myStockItemIDToAdjust

*/

  SELECT TOP(1)
         @StockItemIDToAdjust = StockItemID
    FROM Warehouse.StockItemHoldings
   WHERE (QuantityOnHand + @QuantityToAdjust) >= 0
   ORDER BY NEWID()

  RETURN

END


GO

-- File: GetRandomStreet.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[GetRandomStreet]
@randomStreet NVARCHAR(50) OUTPUT
AS
BEGIN
/*
Notes:
  This procedure will randomly select a street name from the table
  variable loaded herein.

  While it would be preferable to have implemented this as a function,
  the NEWID mechanism needed to make this work are not allowed within
  a function hence the requirement to implement in a stored procedure.

Usage:
  DECLARE @r AS NVARCHAR(20)
  EXEC [DataLoadSimulation].[GetRandomStreet] @randomStreet = @r OUTPUT;
  SELECT @r
*/

  DECLARE @fullStreet AS NVARCHAR(50)
  DECLARE @streetNumber AS NVARCHAR(10)

  SET @streetNumber = CAST((ABS(CHECKSUM(NEWID())) % 8999) + 100 AS NVARCHAR)

  DECLARE @streetName AS NVARCHAR(20)
  EXEC [DataLoadSimulation].[GetRandomStreetName] @randomStreetName = @streetName OUTPUT;

  DECLARE @streetSuffix AS NVARCHAR(20)
  EXEC [DataLoadSimulation].[GetRandomStreetSuffix] @randomStreetSuffix = @streetSuffix OUTPUT;

  SET @randomStreet = @streetNumber + N' '
                    + @streetName + N' '
                    + @streetSuffix

END;


GO

-- File: GetRandomStreetName.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[GetRandomStreetName]
@randomStreetName NVARCHAR(20) OUTPUT
AS
BEGIN
/*
Notes:
  This procedure will randomly select a street name from the table
  variable loaded herein.

  While it would be preferable to have implemented this as a function,
  the NEWID mechanism needed to make this work are not allowed within
  a function hence the requirement to implement in a stored procedure.

Usage:
  DECLARE @r AS NVARCHAR(20)
  EXEC [DataLoadSimulation].[GetRandomStreetName] @randomStreetName = @r OUTPUT;
  SELECT @r
*/

  DECLARE @streetName TABLE (street NVARCHAR(20))

  INSERT INTO @streetName
  VALUES ('Elm')
       , ('Maple')
       , ('Oak')
       , ('Sugar')
       , ('Main')
       , ('Pine')
       , ('Spruce')
       , ('Aspen')
       , ('Birch')
       , ('Fir')
       , ('Hickory')
       , ('Walnut')
       , ('Willow')
       , ('Sycamore')
       , ('Tulip')
       , ('Rose')
       , ('Cotton')
       , ('Ash')
       , ('Lily')
       , ('Cherry')
       , ('Violet')
       , ('First')
       , ('Second')
       , ('Third')
       , ('Fourth')
       , ('Fifth')
       , ('Sixth')
       , ('Seventh')
       , ('Eighth')
       , ('Ninth')
       , ('Tenth')
       , ('Eleventh')
       , ('Twelfth')
       , ('Thirteenth')
       , ('Fourteenth')
       , ('Fifteenth')
       , ('Sixteenth')
       , ('Seventeenth')
       , ('Eighteenth')
       , ('Nineteenth')
       , ('Twentieth')
       , ('1st')
       , ('2nd')
       , ('3rd')
       , ('4th')
       , ('5th')
       , ('6th')
       , ('7th')
       , ('8th')
       , ('9th')
       , ('10th')
       , ('11th')
       , ('12th')
       , ('13th')
       , ('14th')
       , ('15th')
       , ('16th')
       , ('17th')
       , ('18th')
       , ('19th')
       , ('20th')
       ;

  SELECT TOP 1 @randomStreetName = street FROM @streetName ORDER BY NEWID()
  RETURN

END;


GO

-- File: GetRandomStreetSuffix.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[GetRandomStreetSuffix]
@randomStreetSuffix NVARCHAR(20) OUTPUT
AS
BEGIN
/*
Notes:
  This procedure will randomly select a street suffix from the table
  variable loaded herein.

  While it would be preferable to have implemented this as a function,
  the NEWID mechanism needed to make this work are not allowed within
  a function hence the requirement to implement in a stored procedure.

Usage:
  DECLARE @r AS NVARCHAR(20)
  EXEC [DataLoadSimulation].[GetRandomStreetSuffix] @randomStreetSuffix = @r OUTPUT;
  SELECT @r
*/

  DECLARE @streetSuffix TABLE (street NVARCHAR(20))

  INSERT INTO @streetSuffix
  VALUES ('Street')
       , ('Road')
       , ('Avenue')
       , ('Lane')
       , ('Drive')
       , ('Boulevard')
       , ('Court')
       , ('Circle')
       , ('Place')
       , ('Trail')
       , ('Path')
       , ('Loop')
       , ('Way')
       , ('Highway')
       , ('Alley')
       ;

  SELECT TOP 1 @randomStreetSuffix = street FROM @streetSuffix ORDER BY NEWID()
  RETURN

END;

GO

-- File: InvoicePickedOrders.sql
﻿
CREATE PROCEDURE DataLoadSimulation.InvoicePickedOrders
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Invoicing picked orders for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

    DECLARE @OrderID int;
    DECLARE @InvoiceID int;
    DECLARE @PickingCompletedWhen datetime;
    DECLARE @BackorderOrderID int;
    DECLARE @BillToCustomerID int;
    DECLARE @InvoicingPersonID int --= (SELECT TOP(1) PersonID FROM [Application].People WHERE IsEmployee <> 0 ORDER BY NEWID());
    EXEC [DataLoadSimulation].[GetRandomEmployeePerson]
      @EmployeePersonID = @InvoicingPersonID OUTPUT

    DECLARE @PackedByPersonID int --= (SELECT TOP(1) PersonID FROM [Application].People WHERE IsEmployee <> 0 ORDER BY NEWID());
    EXEC [DataLoadSimulation].[GetRandomEmployeePerson]
      @EmployeePersonID = @PackedByPersonID OUTPUT

    DECLARE @TotalDryItems int;
    DECLARE @TotalChillerItems int;
    DECLARE @TransactionAmount decimal(18,2);
    DECLARE @TaxAmount decimal(18,2);
    DECLARE @ReturnedDeliveryData nvarchar(max);
    DECLARE @DeliveryEvent nvarchar(max);

    DECLARE OrderList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT o.OrderID, o.PickingCompletedWhen, c.BillToCustomerID
      FROM Sales.Orders AS o
     INNER JOIN Sales.Customers AS c
        ON o.CustomerID = c.CustomerID
     WHERE NOT EXISTS (SELECT 1 FROM Sales.Invoices AS i WHERE i.OrderID = o.OrderID)     -- not already invoiced
       AND c.IsOnCreditHold = 0                                                           -- and customer not on credit hold
       AND ((o.PickingCompletedWhen IS NOT NULL)                                          -- order completely picked
            OR (o.PickingCompletedWhen IS NULL                                            -- order not picked but customer happy
                AND o.IsUndersupplyBackordered <> 0                                       -- for part shipments and at least one
                AND EXISTS (SELECT 1 FROM Sales.OrderLines AS ol                          -- order line has been picked
                                    WHERE ol.OrderID = o.OrderID
                                      AND ol.PickingCompletedWhen IS NOT NULL
                           )
               )
           );

    OPEN OrderList;
    FETCH NEXT FROM OrderList INTO @OrderID, @PickingCompletedWhen, @BillToCustomerID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @PickingCompletedWhen IS NULL
        BEGIN -- need to reorder undersupplied items

            BEGIN TRAN;

            SET @BackorderOrderID = NEXT VALUE FOR Sequences.OrderID;
            SET @PickingCompletedWhen = @StartingWhen;

            -- create the backorder order
            INSERT Sales.Orders
                (OrderID, CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID,
                 OrderDate, ExpectedDeliveryDate, CustomerPurchaseOrderNumber, IsUndersupplyBackordered,
                 Comments, DeliveryInstructions, InternalComments, PickingCompletedWhen, LastEditedBy, LastEditedWhen)
            SELECT @BackorderOrderID, o.CustomerID, o.SalespersonPersonID, NULL, o.ContactPersonID, NULL,
                   o.OrderDate, o.ExpectedDeliveryDate, o.CustomerPurchaseOrderNumber, 1,
                   o.Comments, o.DeliveryInstructions, o.InternalComments, NULL, @InvoicingPersonID, @StartingWhen
            FROM Sales.Orders AS o
            WHERE o.OrderID = @OrderID;

            -- move the items that haven't been supplied to the new order
            UPDATE Sales.OrderLines
            SET OrderID = @BackorderOrderID,
                LastEditedBy = @InvoicingPersonID,
                LastEditedWhen = @StartingWhen
            WHERE OrderID = @OrderID
            AND PickingCompletedWhen IS NULL;

            -- flag the original order as backordered and picking completed
            UPDATE Sales.Orders
            SET BackorderOrderID = @BackorderOrderID,
                PickingCompletedWhen = @PickingCompletedWhen,
                LastEditedBy = @InvoicingPersonID,
                LastEditedWhen = @StartingWhen
            WHERE OrderID = @OrderID;

            COMMIT;
        END;

        SELECT @TotalDryItems = SUM(CASE WHEN si.IsChillerStock <> 0 THEN 0 ELSE 1 END),
               @TotalChillerItems = SUM(CASE WHEN si.IsChillerStock <> 0 THEN 1 ELSE 0 END)
        FROM Sales.OrderLines AS ol
        INNER JOIN Warehouse.StockItems AS si
        ON ol.StockItemID = si.StockItemID
        WHERE ol.OrderID = @OrderID;

        -- now invoice whatever is left on the order
        BEGIN TRAN;

        SET @InvoiceID = NEXT VALUE FOR Sequences.InvoiceID;

        SET @ReturnedDeliveryData = N'{"Events": []}';
        SET @DeliveryEvent = N'{ }';

        SET @DeliveryEvent = JSON_MODIFY(@DeliveryEvent, N'$.Event', N'Ready for collection');
        SET @DeliveryEvent = JSON_MODIFY(@DeliveryEvent, N'$.EventTime', CONVERT(nvarchar(20), @StartingWhen, 126));
        SET @DeliveryEvent = JSON_MODIFY(@DeliveryEvent, N'$.ConNote', N'EAN-125-' + CAST(@InvoiceID + 1050 AS nvarchar(20)));

        SET @ReturnedDeliveryData = JSON_MODIFY(@ReturnedDeliveryData, N'append $.Events', JSON_QUERY(@DeliveryEvent));

        INSERT Sales.Invoices
            (InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID, ContactPersonID, AccountsPersonID,
             SalespersonPersonID, PackedByPersonID, InvoiceDate, CustomerPurchaseOrderNumber,
             IsCreditNote, CreditNoteReason, Comments, DeliveryInstructions, InternalComments,
             TotalDryItems, TotalChillerItems,
             DeliveryRun, RunPosition, ReturnedDeliveryData, LastEditedBy, LastEditedWhen)
        SELECT @InvoiceID, c.CustomerID, @BillToCustomerID, @OrderID, c.DeliveryMethodID, o.ContactPersonID, btc.PrimaryContactPersonID,
               o.SalespersonPersonID, @PackedByPersonID, @StartingWhen, o.CustomerPurchaseOrderNumber,
               0, NULL, NULL, c.DeliveryAddressLine1 + N', ' + c.DeliveryAddressLine2, NULL,
               @TotalDryItems, @TotalChillerItems,
               c.DeliveryRun, c.RunPosition, @ReturnedDeliveryData, @InvoicingPersonID, @StartingWhen
        FROM Sales.Orders AS o
        INNER JOIN Sales.Customers AS c
        ON o.CustomerID = c.CustomerID
        INNER JOIN Sales.Customers AS btc
        ON btc.CustomerID = c.BillToCustomerID
        WHERE o.OrderID = @OrderID;

        INSERT Sales.InvoiceLines
            (InvoiceID, StockItemID, [Description], PackageTypeID,
             Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice,
             LastEditedBy, LastEditedWhen)
        SELECT @InvoiceID, ol.StockItemID, ol.[Description], ol.PackageTypeID,
               ol.PickedQuantity, ol.UnitPrice, ol.TaxRate,
               ROUND(ol.PickedQuantity * ol.UnitPrice * ol.TaxRate / 100.0, 2),
               ROUND(ol.PickedQuantity * (ol.UnitPrice - sih.LastCostPrice), 2),
               ROUND(ol.PickedQuantity * ol.UnitPrice, 2)
                 + ROUND(ol.PickedQuantity * ol.UnitPrice * ol.TaxRate / 100.0, 2),
               @InvoicingPersonID, @StartingWhen
          FROM Sales.OrderLines AS ol
         INNER JOIN Warehouse.StockItems AS si
            ON ol.StockItemID = si.StockItemID
         INNER JOIN Warehouse.StockItemHoldings AS sih
            ON si.StockItemID = sih.StockItemID
         WHERE ol.OrderID = @OrderID
         ORDER BY ol.OrderLineID;

        INSERT Warehouse.StockItemTransactions
            (StockItemID, TransactionTypeID, CustomerID, InvoiceID, SupplierID, PurchaseOrderID,
             TransactionOccurredWhen, Quantity, LastEditedBy, LastEditedWhen)
        SELECT il.StockItemID, [DataLoadSimulation].[GetTransactionTypeID] (N'Stock Issue'),
               i.CustomerID, i.InvoiceID, NULL, NULL,
               @StartingWhen, 0 - il.Quantity, @InvoicingPersonID, @StartingWhen
          FROM Sales.InvoiceLines AS il
          INNER JOIN Sales.Invoices AS i
             ON il.InvoiceID = i.InvoiceID
          WHERE i.InvoiceID = @InvoiceID
          ORDER BY il.InvoiceLineID;

        WITH StockItemTotals
        AS
        (
            SELECT il.StockItemID, SUM(il.Quantity) AS TotalQuantity
              FROM Sales.InvoiceLines aS il
             WHERE il.InvoiceID = @InvoiceID
             GROUP BY il.StockItemID
        )
        UPDATE sih
        SET sih.QuantityOnHand -= sit.TotalQuantity,
            sih.LastEditedBy = @InvoicingPersonID,
            sih.LastEditedWhen = @StartingWhen
        FROM Warehouse.StockItemHoldings AS sih
        INNER JOIN StockItemTotals AS sit
        ON sih.StockItemID = sit.StockItemID;

        SELECT @TransactionAmount = SUM(il.ExtendedPrice),
               @TaxAmount = SUM(il.TaxAmount)
        FROM Sales.InvoiceLines AS il
        WHERE il.InvoiceID = @InvoiceID;

        INSERT Sales.CustomerTransactions
            (CustomerID, TransactionTypeID, InvoiceID, PaymentMethodID,
             TransactionDate, AmountExcludingTax, TaxAmount, TransactionAmount,
             OutstandingBalance, FinalizationDate, LastEditedBy, LastEditedWhen)
        VALUES
            (@BillToCustomerID, [DataLoadSimulation].[GetTransactionTypeID] (N'Customer Invoice'),
             @InvoiceID, NULL,
             @StartingWhen, @TransactionAmount - @TaxAmount, @TaxAmount, @TransactionAmount,
             @TransactionAmount, NULL, @InvoicingPersonID, @StartingWhen);

        COMMIT;
        FETCH NEXT FROM OrderList INTO @OrderID, @PickingCompletedWhen, @BillToCustomerID;
    END;

    CLOSE OrderList;
    DEALLOCATE OrderList;

END;
GO

-- File: MakeTemporalChanges.sql
﻿-- Note this procedure is not included in the regular build, it
-- is called during the post deployment process.
-- This is due to the fact it updates temporal tables, and SSDT
-- will throw up an error when this occurs, despite the fact we
-- have procedures to deactivate the temporal tables and reactivate
-- when done.
DROP PROCEDURE IF EXISTS DataLoadSimulation.MakeTemporalChanges;
GO

CREATE PROCEDURE DataLoadSimulation.MakeTemporalChanges
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Counter int;
    DECLARE @RowsToModify int;
    DECLARE @StaffMember int = (SELECT TOP(1) PersonID FROM [Application].People WHERE IsEmployee <> 0 ORDER BY NEWID());

    IF DAY(@StartingWhen) = 1 AND MONTH(@StartingWhen) = 7
    BEGIN
        SET @Counter = 0;
        SET @RowsToModify = CEILING(RAND() * 20);

        WHILE @Counter < @RowsToModify
        BEGIN
            UPDATE [Application].Cities
            SET LatestRecordedPopulation = LatestRecordedPopulation * 1.04,
                LastEditedBy = @StaffMember,
                ValidFrom = @StartingWhen
            WHERE CityID = (SELECT TOP(1) CityID FROM [Application].Cities ORDER BY NEWID());
            SET @Counter += 1;
        END;
    END;

    IF DAY(@StartingWhen) = 1 AND MONTH(@StartingWhen) = 7
    BEGIN
        SET @Counter = 0;
        SET @RowsToModify = CEILING(RAND() * 20);

        WHILE @Counter < @RowsToModify
        BEGIN
            UPDATE [Application].StateProvinces
            SET LatestRecordedPopulation = LatestRecordedPopulation * 1.04,
                LastEditedBy = @StaffMember,
                ValidFrom = @StartingWhen
            WHERE StateProvinceID = (SELECT TOP(1) StateProvinceID FROM [Application].StateProvinces ORDER BY NEWID());
            SET @Counter += 1;
        END;
    END;

    IF DAY(@StartingWhen) = 1 AND MONTH(@StartingWhen) = 7
    BEGIN
        SET @Counter = 0;
        SET @RowsToModify = CEILING(RAND() * 20);

        WHILE @Counter < @RowsToModify
        BEGIN
            UPDATE [Application].Countries
            SET LatestRecordedPopulation = LatestRecordedPopulation * 1.04,
                LastEditedBy = @StaffMember,
                ValidFrom = @StartingWhen
            WHERE CountryID = (SELECT TOP(1) CountryID FROM [Application].Countries ORDER BY NEWID());
            SET @Counter += 1;
        END;
    END;

    IF CAST(@StartingWhen AS date) = '20210101'
    BEGIN
        UPDATE [Application].DeliveryMethods
            SET DeliveryMethodName = N'Chilled Van',
                LastEditedBy = @StaffMember,
                ValidFrom = @StartingWhen
            WHERE DeliveryMethodName = N'Van with Chiller';
    END;

    IF CAST(@StartingWhen AS date) = '20220101'
    BEGIN
        UPDATE [Application].PaymentMethods
            SET PaymentMethodName = N'Credit-Card',
                LastEditedBy = @StaffMember,
                ValidFrom = @StartingWhen
            WHERE PaymentMethodName = N'Credit Card';

        INSERT [Application].TransactionTypes
            (TransactionTypeName, LastEditedBy, ValidFrom, ValidTo)
        VALUES
            (N'Contra', @StaffMember, @StartingWhen, @EndOfTime);

        UPDATE [Application].TransactionTypes
            SET TransactionTypeName = N'Customer Contra',
                LastEditedBy = @StaffMember,
                ValidFrom = DATEADD(minute, 5, @StartingWhen)
            WHERE TransactionTypeName = N'Contra';

        UPDATE Warehouse.Colors
            SET ColorName = N'Steel Gray',
                LastEditedBy = @StaffMember,
                ValidFrom = @StartingWhen
            WHERE ColorName = N'Gray';

        INSERT Warehouse.PackageTypes
            (PackageTypeName, LastEditedBy, ValidFrom, ValidTo)
        VALUES
            (N'Bin', @StaffMember, @StartingWhen, @EndOfTime);

        DELETE Warehouse.PackageTypes WHERE PackageTypeName = N'Bin';

        UPDATE Warehouse.StockGroups
            SET StockGroupName = N'Furry Footwear',
                LastEditedBy = @StaffMember,
                ValidFrom = @StartingWhen
            WHERE StockGroupName = N'Footwear';
    END;

    IF CAST(@StartingWhen AS date) = '20210101'
    BEGIN
        UPDATE Purchasing.SupplierCategories
            SET SupplierCategoryName = N'Courier Services Supplier',
                LastEditedBy = @StaffMember,
                ValidFrom = @StartingWhen
            WHERE SupplierCategoryName = N'Courier';
    END;

    IF CAST(@StartingWhen AS date) = '20200701'
    BEGIN
        INSERT Sales.CustomerCategories
            (CustomerCategoryName, LastEditedBy, ValidFrom, ValidTo)
        VALUES
            (N'Retailer', 1, @StartingWhen, @EndOfTime);

        UPDATE Sales.CustomerCategories
            SET CustomerCategoryName = N'General Retailer',
                LastEditedBy = @StaffMember,
                ValidFrom = DATEADD(minute, 15, @StartingWhen)
            WHERE CustomerCategoryName = N'Retailer';
    END;

    IF DAY(@StartingWhen) = 1 AND MONTH(@StartingWhen) = 7
    BEGIN
        SET @Counter = 0;
        SET @RowsToModify = CEILING(RAND() * 20);

        WHILE @Counter < @RowsToModify
        BEGIN
            UPDATE Sales.Customers
            SET CreditLimit = CreditLimit * 1.05,
                LastEditedBy = @StaffMember,
                ValidFrom = @StartingWhen
            WHERE CustomerID = (SELECT TOP(1) CustomerID FROM Sales.Customers WHERE CreditLimit > 0 ORDER BY NEWID());
            SET @Counter += 1;
        END;
    END;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Modifying a few temporal items for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

END;
GO
GO

-- File: PaySuppliers.sql
﻿
CREATE PROCEDURE DataLoadSimulation.PaySuppliers
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Paying suppliers for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

    DECLARE @StaffMemberPersonID int = (SELECT TOP(1) PersonID
                                        FROM [Application].People
                                        WHERE IsEmployee <> 0
                                        ORDER BY NEWID());

    DECLARE @TransactionsToPay TABLE
    (
        SupplierTransactionID int,
        SupplierID int,
        PurchaseOrderID int NULL,
        SupplierInvoiceNumber nvarchar(20) NULL,
        OutstandingBalance decimal(18,2)
    );

    INSERT @TransactionsToPay
        (SupplierTransactionID, SupplierID, PurchaseOrderID, SupplierInvoiceNumber, OutstandingBalance)
    SELECT SupplierTransactionID, SupplierID, PurchaseOrderID, SupplierInvoiceNumber, OutstandingBalance
    FROM Purchasing.SupplierTransactions
    WHERE IsFinalized = 0;

    BEGIN TRAN;

    UPDATE Purchasing.SupplierTransactions
    SET OutstandingBalance = 0,
        FinalizationDate = @StartingWhen,
        LastEditedBy = @StaffMemberPersonID,
        LastEditedWhen = @StartingWhen
    WHERE SupplierTransactionID IN (SELECT SupplierTransactionID FROM @TransactionsToPay);

    INSERT Purchasing.SupplierTransactions
        (SupplierID, TransactionTypeID, PurchaseOrderID, PaymentMethodID,
         SupplierInvoiceNumber, TransactionDate, AmountExcludingTax, TaxAmount, TransactionAmount,
         OutstandingBalance, FinalizationDate, LastEditedBy, LastEditedWhen)
    SELECT ttp.SupplierID, [DataLoadSimulation].[GetTransactionTypeID] (N'Supplier Payment Issued'),
           NULL, [DataLoadSimulation].[GetPaymentMethodID] (N'EFT'),
           NULL, CAST(@StartingWhen AS date), 0, 0, 0 - SUM(ttp.OutstandingBalance),
           0, CAST(@StartingWhen AS date), @StaffMemberPersonID, @StartingWhen
    FROM @TransactionsToPay AS ttp
    GROUP BY ttp.SupplierID;

    COMMIT;

END;
GO

-- File: PerformStocktake.sql
﻿
CREATE PROCEDURE DataLoadSimulation.PerformStocktake
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Performing stocktake for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

    DECLARE @StaffMemberPersonID INT
    EXEC [DataLoadSimulation].[GetRandomEmployeePerson]
      @EmployeePersonID = @StaffMemberPersonID OUTPUT


    DECLARE @Counter int = 0;
    DECLARE @NumberOfAdjustedStockItems int = (SELECT CEILING(RAND() * 5));
    DECLARE @StockItemIDToAdjust int;
    DECLARE @QuantityToAdjust int;

    BEGIN TRAN;

    UPDATE Warehouse.StockItemHoldings
    SET LastStocktakeQuantity = QuantityOnHand,
        LastEditedBy = @StaffMemberPersonID,
        LastEditedWhen = @StartingWhen;

    WHILE @Counter < @NumberOfAdjustedStockItems
    BEGIN
        SET @QuantityToAdjust = 5 - CEILING(RAND() * 10);
        --SET @StockItemIDToAdjust = (SELECT TOP(1) StockItemID
        --                              FROM Warehouse.StockItemHoldings
        --                             WHERE (QuantityOnHand + @QuantityToAdjust) >= 0
        --                             ORDER BY NEWID());
        EXEC [DataLoadSimulation].[GetRandomStockItemToAdjust]
            @QuantityToAdjust
          , @StockItemIDToAdjust = @StockItemIDToAdjust OUTPUT

        IF @StockItemIDToAdjust IS NOT NULL
        BEGIN
            UPDATE Warehouse.StockItemHoldings
               SET LastStocktakeQuantity += @QuantityToAdjust
                 , LastEditedBy = @StaffMemberPersonID
                 , LastEditedWhen = @StartingWhen
             WHERE StockItemID = @StockItemIDToAdjust;

            INSERT Warehouse.StockItemTransactions
                (StockItemID, TransactionTypeID, CustomerID, InvoiceID, SupplierID, PurchaseOrderID,
                 TransactionOccurredWhen, Quantity, LastEditedBy, LastEditedWhen)
            VALUES
                (@StockItemIDToAdjust,
                 [DataLoadSimulation].[GetTransactionTypeID] (N'Stock Adjustment at Stocktake'),
                 NULL, NULL, NULL, NULL,
                 @StartingWhen, @QuantityToAdjust, @StaffMemberPersonID, @StartingWhen);
        END;
        SET @Counter += 1;
    END;

    COMMIT;
END;
GO

-- File: PickStockForCustomerOrders.sql
﻿
CREATE PROCEDURE DataLoadSimulation.PickStockForCustomerOrders
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Picking stock for customer orders for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

    SET XACT_ABORT ON;

    DECLARE @UninvoicedOrders TABLE
    (
        OrderID int PRIMARY KEY
    );

    INSERT @UninvoicedOrders
    SELECT o.OrderID
      FROM Sales.Orders AS o
     WHERE NOT EXISTS (SELECT 1 FROM Sales.Invoices AS i WHERE i.OrderID = o.OrderID);

    DECLARE @StockAlreadyAllocated TABLE
    (
        StockItemID int PRIMARY KEY,
        QuantityAllocated int
    );

    WITH StockAlreadyAllocated
    AS
    (
        SELECT ol.StockItemID, SUM(ol.PickedQuantity) AS TotalPickedQuantity
          FROM Sales.OrderLines AS ol
         INNER JOIN @UninvoicedOrders AS uo
            ON ol.OrderID = uo.OrderID
         WHERE ol.PickingCompletedWhen IS NULL
         GROUP BY ol.StockItemID
    )
    INSERT @StockAlreadyAllocated (StockItemID, QuantityAllocated)
    SELECT sa.StockItemID, sa.TotalPickedQuantity
      FROM StockAlreadyAllocated AS sa;

    DECLARE OrderLineList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT ol.OrderID, ol.OrderLineID, ol.StockItemID, ol.Quantity
      FROM Sales.OrderLines AS ol
     WHERE ol.PickingCompletedWhen IS NULL
     ORDER BY ol.OrderID, ol.OrderLineID;

    DECLARE @OrderID int;
    DECLARE @OrderLineID int;
    DECLARE @StockItemID int;
    DECLARE @Quantity int;
    DECLARE @AvailableStock int;
    -- DECLARE @PickingPersonID int = (SELECT TOP(1) PersonID
    --                                 FROM [Application].People
    --                                 WHERE IsEmployee <> 0
    --                                 ORDER BY NEWID());
    DECLARE @PickingPersonID INT
    EXEC [DataLoadSimulation].[GetRandomEmployeePerson]
      @EmployeePersonID = @PickingPersonID OUTPUT

    OPEN OrderLineList;
    FETCH NEXT FROM OrderLineList INTO @OrderID, @OrderLineID, @StockItemID, @Quantity;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- work out available stock for this stock item (on hand less allocated)
        SET @AvailableStock = (SELECT QuantityOnHand FROM Warehouse.StockItemHoldings AS sih WHERE sih.StockItemID = @StockItemID);
        SET @AvailableStock -= COALESCE((SELECT QuantityAllocated FROM @StockAlreadyAllocated AS saa WHERE saa.StockItemID = @StockItemID), 0);

        IF @AvailableStock >= @Quantity
        BEGIN
            BEGIN TRAN;

            MERGE @StockAlreadyAllocated AS saa
            USING (VALUES (@StockItemID, @Quantity)) AS sa(StockItemID, Quantity)
            ON saa.StockItemID = sa.StockItemID
            WHEN MATCHED THEN
                UPDATE SET saa.QuantityAllocated += sa.Quantity
            WHEN NOT MATCHED THEN
                INSERT (StockItemID, QuantityAllocated) VALUES (sa.StockItemID, sa.Quantity);

            -- reserve the required stock
            UPDATE Sales.OrderLines
            SET PickedQuantity = @Quantity,
                PickingCompletedWhen = @StartingWhen,
                LastEditedBy = @PickingPersonID,
                LastEditedWhen = @StartingWhen
            WHERE OrderLineID = @OrderLineID;

            -- mark the order as ready to invoice (picking complete) if all lines picked
            IF NOT EXISTS (SELECT 1 FROM Sales.OrderLines AS ol
                                    WHERE ol.OrderID = @OrderID
                                    AND ol.PickingCompletedWhen IS NULL)
            BEGIN
                UPDATE Sales.Orders
                SET PickingCompletedWhen = @StartingWhen,
                    PickedByPersonID = @PickingPersonID,
                    LastEditedBy = @PickingPersonID,
                    LastEditedWhen = @StartingWhen
                WHERE OrderID = @OrderID;
            END;

            COMMIT;
        END;

        FETCH NEXT FROM OrderLineList INTO @OrderID, @OrderLineID, @StockItemID, @Quantity;
    END;

    CLOSE OrderLineList;
    DEALLOCATE OrderLineList;

END;
GO

-- File: PlaceSupplierOrders.sql
﻿
CREATE PROCEDURE DataLoadSimulation.PlaceSupplierOrders
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Placing supplier orders for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

    DECLARE @ContactPersonID INT --= (SELECT TOP(1) PersonID FROM [Application].People WHERE IsEmployee <> 0 ORDER BY NEWID());
    DECLARE @SupplierPersonID INT

    EXEC [DataLoadSimulation].[GetRandomEmployeePerson]
      @EmployeePersonID = @ContactPersonID OUTPUT
    EXEC [DataLoadSimulation].[GetRandomEmployeePerson]
      @EmployeePersonID = @SupplierPersonID OUTPUT

    DECLARE @Orders TABLE
    (
        SupplierID int,
        PurchaseOrderID int NULL,
        DeliveryMethodID int,
        ContactPersonID int,
        SupplierReference nvarchar(20) NULL
    );

    DECLARE @OrderLines TABLE
    (
        StockItemID int,
        [Description] nvarchar(100),
        SupplierID int,
        QuantityOfOuters int,
        LeadTimeDays int,
        OuterPackageID int,
        LastOuterCostPrice decimal(18,2)
    );

    BEGIN TRAN;

    WITH StockItemsToCheck
    AS
    (
        SELECT si.StockItemID,
               si.StockItemName AS [Description],
               si.SupplierID,
               sih.TargetStockLevel,
               sih.ReorderLevel,
               si.QuantityPerOuter,
               si.LeadTimeDays,
               si.OuterPackageID,
               sih.QuantityOnHand,
               sih.LastCostPrice,
               COALESCE((SELECT SUM(ol.Quantity)
                         FROM Sales.OrderLines AS ol
                         WHERE ol.StockItemID = si.StockItemID
                         AND ol.PickingCompletedWhen IS NULL), 0) AS StockNeededForOrders,
               COALESCE((SELECT si.QuantityPerOuter * SUM(pol.OrderedOuters - pol.ReceivedOuters)
                         FROM Purchasing.PurchaseOrderLines AS pol
                         WHERE pol.StockItemID = si.StockItemID
                         AND pol.IsOrderLineFinalized = 0), 0) AS StockOnOrder
        FROM Warehouse.StockItems AS si
        INNER JOIN Warehouse.StockItemHoldings AS sih
        ON si.StockItemID = sih.StockItemID
    ),
    StockItemsToOrder
    AS
    (
        SELECT sitc.StockItemID,
               sitc.[Description],
               sitc.SupplierID,
               (sitc.QuantityOnHand + sitc.StockOnOrder - sitc.StockNeededForOrders) AS EffectiveStockLevel,
               sitc.TargetStockLevel,
               sitc.QuantityPerOuter,
               sitc.LeadTimeDays,
               sitc.OuterPackageID,
               sitc.LastCostPrice
        FROM StockItemsToCheck AS sitc
        WHERE (sitc.QuantityOnHand + sitc.StockOnOrder - sitc.StockNeededForOrders) < sitc.ReorderLevel
        AND sitc.QuantityPerOuter <> 0
    )
    INSERT @OrderLines (StockItemID, [Description], SupplierID, QuantityOfOuters, LeadTimeDays, OuterPackageID, LastOuterCostPrice)
    SELECT sito.StockItemID,
           sito.[Description],
           sito.SupplierID,
           CEILING((sito.TargetStockLevel - sito.EffectiveStockLevel) / sito.QuantityPerOuter) AS OutersRequired,
           sito.LeadTimeDays,
           sito.OuterPackageID,
           ROUND(sito.LastCostPrice * sito.QuantityPerOuter, 2) AS LastOuterCostPrice
    FROM StockItemsToOrder AS sito;

    INSERT @Orders (SupplierID, PurchaseOrderID, DeliveryMethodID, ContactPersonID, SupplierReference)
    SELECT s.SupplierID
         , NEXT VALUE FOR Sequences.PurchaseOrderID
         , s.DeliveryMethodID
         , @SupplierPersonID
         , s.SupplierReference
    FROM Purchasing.Suppliers AS s
    WHERE s.SupplierID IN (SELECT SupplierID FROM @OrderLines);

    INSERT Purchasing.PurchaseOrders
        (PurchaseOrderID, SupplierID, OrderDate, DeliveryMethodID, ContactPersonID,
         ExpectedDeliveryDate, SupplierReference, IsOrderFinalized, Comments,
         InternalComments, LastEditedBy, LastEditedWhen)
    SELECT o.PurchaseOrderID, o.SupplierID, CAST(@StartingWhen AS date), o.DeliveryMethodID, o.ContactPersonID,
           DATEADD(day, (SELECT MAX(LeadTimeDays) FROM @OrderLines), CAST(@StartingWhen AS date)),
           o.SupplierReference, 0, NULL,
           NULL, 1, @StartingWhen
    FROM @Orders AS o;

    INSERT Purchasing.PurchaseOrderLines
        (PurchaseOrderID, StockItemID, OrderedOuters, [Description],
         ReceivedOuters, PackageTypeID, ExpectedUnitPricePerOuter, LastReceiptDate,
         IsOrderLineFinalized, LastEditedBy, LastEditedWhen)
    SELECT o.PurchaseOrderID, ol.StockItemID, ol.QuantityOfOuters, ol.[Description],
           0, ol.OuterPackageID, ol.LastOuterCostPrice, NULL,
           0, @ContactPersonID, @StartingWhen
    FROM @OrderLines AS ol
    INNER JOIN @Orders AS o
    ON ol.SupplierID = o.SupplierID;

    COMMIT;
END;
GO

-- File: PopulateColdRoomTemperatures_temp.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[PopulateColdRoomTemperatures_temp]
@AverageSecondsBetweenReadings int,
@NumberOfSensors int,
@TimeCounter datetime2(7),
@EndTime datetime2(7)
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH
	(TRANSACTION ISOLATION LEVEL=SNAPSHOT, LANGUAGE=N'English')

	DECLARE @ValidTo datetime2(7)
	DECLARE @DelayInSeconds int
	DECLARE @SensorCounter int
	DECLARE @Temperature decimal(10,2);
	DECLARE @ColdRoomTemperatureID bigint

	SELECT @ColdRoomTemperatureID = ISNULL(MAX(ColdRoomTemperatureID), 0) + 1
	FROM DataLoadSimulation.[ColdRoomTemperatures_temp]

	WHILE @TimeCounter < @EndTime
	BEGIN
		SET @SensorCounter = 0;
		SET @DelayInSeconds = CEILING(RAND() * @AverageSecondsBetweenReadings);
		SET @ValidTo = DATEADD(second, @DelayInSeconds, @TimeCounter);

		WHILE @SensorCounter < @NumberOfSensors
		BEGIN
			SET @Temperature = 3 + RAND() * 2;

			INSERT DataLoadSimulation.[ColdRoomTemperatures_temp]
				(ColdRoomTemperatureID, ColdRoomSensorNumber, RecordedWhen, Temperature, ValidFrom, ValidTo)
			VALUES
				(@ColdRoomTemperatureID, @SensorCounter + 1, @TimeCounter, @Temperature, @TimeCounter, @ValidTo);

			SET @SensorCounter += 1;
			SET @ColdRoomTemperatureID += 1;
		END;
		SET @TimeCounter = @ValidTo
	END;
END;
GO

-- File: PopulateDataTo180DaysAgo.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[PopulateDataTo180DaysAgo]
@AverageNumberOfCustomerOrdersPerDay int = 30,
@SaturdayPercentageOfNormalWorkDay int = 25,
@SundayPercentageOfNormalWorkDay int = 0,
@IsSilentMode bit = 0,
@AreDatesPrinted bit = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentMaximumDate date = COALESCE((SELECT MAX(OrderDate) FROM Sales.Orders), '20191231');
    DECLARE @StartingDate date = DATEADD(day, 1, @CurrentMaximumDate);
    DECLARE @EndingDate date = CAST(DATEADD(day, -1, SYSDATETIME()) AS date);

    EXEC DataLoadSimulation.DailyProcessToCreateHistory
        @StartDate = @StartingDate,
        @EndDate = @EndingDate,
        @AverageNumberOfCustomerOrdersPerDay = @AverageNumberOfCustomerOrdersPerDay,
        @SaturdayPercentageOfNormalWorkDay = @SaturdayPercentageOfNormalWorkDay,
        @SundayPercentageOfNormalWorkDay = @SundayPercentageOfNormalWorkDay,
        @UpdateCustomFields = 0, -- they were done in the initial load
        @IsSilentMode = @IsSilentMode,
        @AreDatesPrinted = @AreDatesPrinted;

END;

GO

-- File: PopulateDataToCurrentDate.sql
﻿
CREATE PROCEDURE DataLoadSimulation.PopulateDataToCurrentDate
@AverageNumberOfCustomerOrdersPerDay int,
@SaturdayPercentageOfNormalWorkDay int,
@SundayPercentageOfNormalWorkDay int,
@IsSilentMode bit,
@AreDatesPrinted bit
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentMaximumDate date = COALESCE((SELECT MAX(OrderDate) FROM Sales.Orders), '20191231');
    DECLARE @StartingDate date = DATEADD(day, 1, @CurrentMaximumDate);
    DECLARE @EndingDate date = CAST(DATEADD(day, -1, SYSDATETIME()) AS date);

    EXEC DataLoadSimulation.DailyProcessToCreateHistory
        @StartDate = @StartingDate,
        @EndDate = @EndingDate,
        @AverageNumberOfCustomerOrdersPerDay = @AverageNumberOfCustomerOrdersPerDay,
        @SaturdayPercentageOfNormalWorkDay = @SaturdayPercentageOfNormalWorkDay,
        @SundayPercentageOfNormalWorkDay = @SundayPercentageOfNormalWorkDay,
        @UpdateCustomFields = 0, -- they were done in the initial load
        @IsSilentMode = @IsSilentMode,
        @AreDatesPrinted = @AreDatesPrinted;

END;

GO

-- File: PopulateOneDayOfHistory.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[PopulateOneDayOfHistory]
@AverageNumberOfCustomerOrdersPerDay int = 30,
@SaturdayPercentageOfNormalWorkDay int = 25,
@SundayPercentageOfNormalWorkDay int = 0,
@IsSilentMode bit = 0,
@AreDatesPrinted bit = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentMaximumDate date = COALESCE((SELECT MAX(OrderDate) FROM Sales.Orders), '20191231');
    DECLARE @StartingDate date = DATEADD(day, 1, @CurrentMaximumDate);

    EXEC DataLoadSimulation.DailyProcessToCreateHistory
        @StartDate = @StartingDate,
        @EndDate = @StartingDate,
        @AverageNumberOfCustomerOrdersPerDay = @AverageNumberOfCustomerOrdersPerDay,
        @SaturdayPercentageOfNormalWorkDay = @SaturdayPercentageOfNormalWorkDay,
        @SundayPercentageOfNormalWorkDay = @SundayPercentageOfNormalWorkDay,
        @UpdateCustomFields = 0, -- they were done in the initial load
        @IsSilentMode = @IsSilentMode,
        @AreDatesPrinted = @AreDatesPrinted;

END;

GO

-- File: ProcessCustomerPayments.sql
﻿
CREATE PROCEDURE DataLoadSimulation.ProcessCustomerPayments
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Processing customer payments for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

    -- DECLARE @StaffMemberPersonID int = (SELECT TOP(1) PersonID
    --                                     FROM [Application].People
    --                                     WHERE IsEmployee <> 0
    --                                     ORDER BY NEWID());
    DECLARE @StaffMemberPersonID INT
    EXEC [DataLoadSimulation].[GetRandomEmployeePerson]
      @EmployeePersonID = @StaffMemberPersonID OUTPUT


    DECLARE @TransactionsToReceive TABLE
    (
        CustomerTransactionID int,
        CustomerID int,
        InvoiceID int NULL,
        OutstandingBalance decimal(18,2)
    );

    INSERT @TransactionsToReceive
        (CustomerTransactionID, CustomerID, InvoiceID, OutstandingBalance)
    SELECT CustomerTransactionID, CustomerID, InvoiceID, OutstandingBalance
    FROM Sales.CustomerTransactions
    WHERE IsFinalized = 0;

    BEGIN TRAN;

    UPDATE Sales.CustomerTransactions
    SET OutstandingBalance = 0,
        FinalizationDate = @StartingWhen,
        LastEditedBy = @StaffMemberPersonID,
        LastEditedWhen = @StartingWhen
    WHERE CustomerTransactionID IN (SELECT CustomerTransactionID FROM @TransactionsToReceive);

    INSERT Sales.CustomerTransactions
        (CustomerID, TransactionTypeID, InvoiceID, PaymentMethodID, TransactionDate,
         AmountExcludingTax, TaxAmount, TransactionAmount, OutstandingBalance,
         FinalizationDate, LastEditedBy, LastEditedWhen)
    SELECT ttr.CustomerID, [DataLoadSimulation].[GetTransactionTypeID] (N'Customer Payment Received'),
           NULL, [DataLoadSimulation].[GetPaymentMethodID] (N'EFT'),
           CAST(@StartingWhen AS date), 0, 0, 0 - SUM(ttr.OutstandingBalance),
           0, CAST(@StartingWhen AS date), @StaffMemberPersonID, @StartingWhen
    FROM @TransactionsToReceive AS ttr
    GROUP BY ttr.CustomerID;

    COMMIT;

END;
GO

-- File: ReactivateTemporalTablesAfterDataLoad.sql
﻿
CREATE PROCEDURE DataLoadSimulation.ReactivateTemporalTablesAfterDataLoad
AS BEGIN
    -- Re-enables the temporal nature of the temporal tables after a simulated data load
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = N'Configuration_ApplyRowLevelSecurity')
    BEGIN
        EXEC [Application].Configuration_ApplyRowLevelSecurity;
    END;

    DROP TRIGGER IF EXISTS [Application].[TR_Application_Cities_DataLoad_Modify];
    ALTER TABLE [Application].[Cities] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Application].[Cities] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Application].[Cities_Archive], DATA_CONSISTENCY_CHECK = ON));

    DROP TRIGGER IF EXISTS [Application].[TR_Application_Countries_DataLoad_Modify];
    ALTER TABLE [Application].[Countries] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Application].[Countries] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Application].[Countries_Archive], DATA_CONSISTENCY_CHECK = ON));

    DROP TRIGGER IF EXISTS [Application].[TR_Application_DeliveryMethods_DataLoad_Modify];
    ALTER TABLE [Application].[DeliveryMethods] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Application].[DeliveryMethods] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Application].[DeliveryMethods_Archive], DATA_CONSISTENCY_CHECK = ON));

    DROP TRIGGER IF EXISTS [Application].[TR_Application_PaymentMethods_DataLoad_Modify];
    ALTER TABLE [Application].[PaymentMethods] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Application].[PaymentMethods] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Application].[PaymentMethods_Archive], DATA_CONSISTENCY_CHECK = ON));

    DROP TRIGGER IF EXISTS [Application].[TR_Application_People_DataLoad_Modify];
    ALTER TABLE [Application].[People] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Application].[People] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Application].[People_Archive], DATA_CONSISTENCY_CHECK = ON));

    DROP TRIGGER IF EXISTS [Application].[TR_Application_StateProvinces_DataLoad_Modify];
    ALTER TABLE [Application].[StateProvinces] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Application].[StateProvinces] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Application].[StateProvinces_Archive], DATA_CONSISTENCY_CHECK = ON));

    DROP TRIGGER IF EXISTS [Application].[TR_Application_TransactionTypes_DataLoad_Modify];
    ALTER TABLE [Application].[TransactionTypes] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Application].[TransactionTypes] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Application].[TransactionTypes_Archive], DATA_CONSISTENCY_CHECK = ON));

    DROP TRIGGER IF EXISTS [Purchasing].[TR_Purchasing_SupplierCategories_DataLoad_Modify];
    ALTER TABLE [Purchasing].[SupplierCategories] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Purchasing].[SupplierCategories] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Purchasing].[SupplierCategories_Archive], DATA_CONSISTENCY_CHECK = ON));

    DROP TRIGGER IF EXISTS [Purchasing].[TR_Purchasing_Suppliers_DataLoad_Modify];
    ALTER TABLE [Purchasing].[Suppliers] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Purchasing].[Suppliers] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Purchasing].[Suppliers_Archive], DATA_CONSISTENCY_CHECK = ON));

    DROP TRIGGER IF EXISTS [Sales].[TR_Sales_BuyingGroups_DataLoad_Modify];
    ALTER TABLE [Sales].[BuyingGroups] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Sales].[BuyingGroups] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Sales].[BuyingGroups_Archive], DATA_CONSISTENCY_CHECK = ON));

    DROP TRIGGER IF EXISTS [Sales].[TR_Sales_CustomerCategories_DataLoad_Modify];
    ALTER TABLE [Sales].[CustomerCategories] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Sales].[CustomerCategories] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Sales].[CustomerCategories_Archive], DATA_CONSISTENCY_CHECK = ON));

    DROP TRIGGER IF EXISTS [Sales].[TR_Sales_Customers_DataLoad_Modify];
    ALTER TABLE [Sales].[Customers] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Sales].[Customers] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Sales].[Customers_Archive], DATA_CONSISTENCY_CHECK = ON));

    DROP TRIGGER IF EXISTS [Warehouse].[TR_Warehouse_ColdRoomTemperatures_DataLoad_Modify];
    ALTER TABLE [Warehouse].[ColdRoomTemperatures] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Warehouse].[ColdRoomTemperatures] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Warehouse].[ColdRoomTemperatures_Archive], DATA_CONSISTENCY_CHECK = ON));

    DROP TRIGGER IF EXISTS [Warehouse].[TR_Warehouse_Colors_DataLoad_Modify];
    ALTER TABLE [Warehouse].[Colors] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Warehouse].[Colors] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Warehouse].[Colors_Archive], DATA_CONSISTENCY_CHECK = ON));

    DROP TRIGGER IF EXISTS [Warehouse].[TR_Warehouse_PackageTypes_DataLoad_Modify];
    ALTER TABLE [Warehouse].[PackageTypes] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Warehouse].[PackageTypes] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Warehouse].[PackageTypes_Archive], DATA_CONSISTENCY_CHECK = ON));

    DROP TRIGGER IF EXISTS [Warehouse].[TR_Warehouse_StockGroups_DataLoad_Modify];
    ALTER TABLE [Warehouse].[StockGroups] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Warehouse].[StockGroups] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Warehouse].[StockGroups_Archive], DATA_CONSISTENCY_CHECK = ON));

    DROP TRIGGER IF EXISTS [Warehouse].[TR_Warehouse_StockItems_DataLoad_Modify];
    ALTER TABLE [Warehouse].[StockItems] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Warehouse].[StockItems] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Warehouse].[StockItems_Archive], DATA_CONSISTENCY_CHECK = ON));

END;

GO

-- File: ReceivePurchaseOrders.sql
﻿
CREATE PROCEDURE DataLoadSimulation.ReceivePurchaseOrders
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Receiving stock from purchase orders for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

    DECLARE @StaffMemberPersonID int = (SELECT TOP(1) PersonID
                                        FROM [Application].People
                                        WHERE IsEmployee <> 0
                                        ORDER BY NEWID());
    DECLARE @PurchaseOrderID int;
    DECLARE @SupplierID int;
    DECLARE @TotalExcludingTax decimal(18,2);
    DECLARE @TotalIncludingTax decimal(18,2);

    DECLARE PurchaseOrderList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT PurchaseOrderID, SupplierID
    FROM Purchasing.PurchaseOrders AS po
    WHERE po.IsOrderFinalized = 0
    AND po.ExpectedDeliveryDate >= @StartingWhen;

    OPEN PurchaseOrderList;
    FETCH NEXT FROM PurchaseOrderList INTO @PurchaseOrderID, @SupplierID;

    WHILE @@FETCH_STATUS = 0
    BEGIN

        BEGIN TRAN;

        UPDATE Purchasing.PurchaseOrderLines
        SET ReceivedOuters = OrderedOuters,
            IsOrderLineFinalized = 1,
            LastReceiptDate = CAST(@StartingWhen as date),
            LastEditedBy = @StaffMemberPersonID,
            LastEditedWhen = @StartingWhen
        WHERE PurchaseOrderID = @PurchaseOrderID;

        UPDATE sih
        SET sih.QuantityOnHand += pol.ReceivedOuters * si.QuantityPerOuter,
            sih.LastEditedBy = @StaffMemberPersonID,
            sih.LastEditedWhen = @StartingWhen
        FROM Warehouse.StockItemHoldings AS sih
        INNER JOIN Purchasing.PurchaseOrderLines AS pol
        ON sih.StockItemID = pol.StockItemID
        INNER JOIN Warehouse.StockItems AS si
        ON sih.StockItemID = si.StockItemID;

        INSERT Warehouse.StockItemTransactions
            (StockItemID, TransactionTypeID, CustomerID, InvoiceID, SupplierID, PurchaseOrderID,
             TransactionOccurredWhen, Quantity, LastEditedBy, LastEditedWhen)
        SELECT pol.StockItemID, (SELECT TransactionTypeID FROM [Application].TransactionTypes WHERE TransactionTypeName = N'Stock Receipt'),
               NULL, NULL, @SupplierID, pol.PurchaseOrderID,
               @StartingWhen, pol.ReceivedOuters * si.QuantityPerOuter, @StaffMemberPersonID, @StartingWhen
        FROM Purchasing.PurchaseOrderLines AS pol
        INNER JOIN Warehouse.StockItems AS si
        ON pol.StockItemID = si.StockItemID
        WHERE pol.PurchaseOrderID = @PurchaseOrderID;

        UPDATE Purchasing.PurchaseOrders
        SET IsOrderFinalized = 1,
            LastEditedBy = @StaffMemberPersonID,
            LastEditedWhen = @StartingWhen
        WHERE PurchaseOrderID = @PurchaseOrderID;

        SELECT @TotalExcludingTax = SUM(ROUND(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter,2)),
               @TotalIncludingTax = SUM(ROUND(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter,2))
                                  + SUM(ROUND(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter * si.TaxRate / 100.0,2))
        FROM Purchasing.PurchaseOrderLines AS pol
        INNER JOIN Warehouse.StockItems AS si
        ON pol.StockItemID = si.StockItemID
        WHERE pol.PurchaseOrderID = @PurchaseOrderID;

        INSERT Purchasing.SupplierTransactions
            (SupplierID, TransactionTypeID, PurchaseOrderID, PaymentMethodID,
             SupplierInvoiceNumber, TransactionDate, AmountExcludingTax,
             TaxAmount, TransactionAmount, OutstandingBalance,
             FinalizationDate, LastEditedBy, LastEditedWhen)
        VALUES
            (@SupplierID, (SELECT TransactionTypeID FROM [Application].TransactionTypes WHERE TransactionTypeName = N'Supplier Invoice'),
             @PurchaseOrderID, (SELECT PaymentMethodID FROM [Application].PaymentMethods WHERE PaymentMethodName = N'EFT'),
             CAST(CEILING(RAND() * 10000) AS nvarchar(20)), CAST(@StartingWhen AS date), @TotalExcludingTax,
             @TotalIncludingTax - @TotalExcludingTax, @TotalIncludingTax, @TotalIncludingTax,
             NULL, @StaffMemberPersonID, @StartingWhen);

        COMMIT;

        FETCH NEXT FROM PurchaseOrderList INTO @PurchaseOrderID, @SupplierID;
    END;

    CLOSE PurchaseOrderList;
    DEALLOCATE PurchaseOrderList;
END;
GO

-- File: RecordColdRoomTemperatures.sql
﻿-- Note this procedure is not included in the regular build, it
-- is called during the post deployment process.
-- This is due to the fact it updates temporal tables, and SSDT
-- will throw up an error when this occurs, despite the fact we
-- have procedures to deactivate the temporal tables and reactivate
-- when done.
DROP PROCEDURE IF EXISTS DataLoadSimulation.RecordColdRoomTemperatures;
GO

CREATE PROCEDURE DataLoadSimulation.RecordColdRoomTemperatures
@AverageSecondsBetweenReadings int,
@NumberOfSensors int,
@CurrentDateTime datetime2(7),
@EndOfTime datetime2(7),
@IsSilentMode bit
WITH EXECUTE AS OWNER
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

	BEGIN TRAN

    DECLARE @TimeCounter datetime2(7) = CAST(@CurrentDateTime AS date);
    DECLARE @SensorCounter int;
    DECLARE @DelayInSeconds int;
    DECLARE @TimeToFinishForTheDay datetime2(7) = DATEADD(second, -30, DATEADD(day, 1, @TimeCounter));
    DECLARE @Temperature decimal(10,2);

	-- clean up any artifacts from earlier runs
	DELETE FROM DataLoadSimulation.[ColdRoomTemperatures_temp] WITH (SNAPSHOT)

	IF @TimeCounter < @TimeToFinishForTheDay
	BEGIN
		-- seed temporary table with current status of sensors
		DELETE Warehouse.ColdRoomTemperatures WITH (SNAPSHOT)
		OUTPUT deleted.ColdRoomTemperatureID,
			 deleted.ColdRoomSensorNumber,
			 deleted.RecordedWhen,
			 deleted.Temperature,
			 deleted.ValidFrom,
			 @TimeCounter
		INTO DataLoadSimulation.[ColdRoomTemperatures_temp]
			(ColdRoomTemperatureID,
			 ColdRoomSensorNumber,
			 RecordedWhen,
			 Temperature,
			 ValidFrom,
			 ValidTo)

		-- populate data for the day in temp table
		DECLARE @ArchiveEndTime datetime2(7) = DATEADD(second, (0 - @AverageSecondsBetweenReadings),  @TimeToFinishForTheDay)
		EXEC DataLoadSimulation.PopulateColdRoomTemperatures_temp @AverageSecondsBetweenReadings, @NumberOfSensors, @TimeCounter, @ArchiveEndTime

		-- move daily data into archive table
		DELETE DataLoadSimulation.ColdRoomTemperatures_temp WITH (SNAPSHOT)
		OUTPUT deleted.ColdRoomTemperatureID,
			 deleted.ColdRoomSensorNumber,
			 deleted.RecordedWhen,
			 deleted.Temperature,
			 deleted.ValidFrom,
			 deleted.ValidTo
		INTO Warehouse.ColdRoomTemperatures_Archive

		-- add last daily reading to current table
		SET @SensorCounter = 0;
		WHILE @SensorCounter < @NumberOfSensors
		BEGIN
			SET @Temperature = 3 + RAND() * 2;

			INSERT Warehouse.ColdRoomTemperatures
				(ColdRoomSensorNumber, RecordedWhen, Temperature, ValidFrom, ValidTo)
			VALUES
				(@SensorCounter + 1, @ArchiveEndTime, @Temperature, @ArchiveEndTime, @EndOfTime);

			SET @SensorCounter += 1;
		END;

	END;
	COMMIT
END;

GO

-- File: RecordDeliveryVanTemperatures.sql
﻿
CREATE PROCEDURE DataLoadSimulation.RecordDeliveryVanTemperatures
@AverageSecondsBetweenReadings int,
@NumberOfSensors int,
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@IsSilentMode bit
WITH EXECUTE AS OWNER
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Recording delivery van temperatures for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

    DECLARE @VehicleRegistration nvarchar(20) = N'WWI-321-A';

    DECLARE @TimeCounter datetime2(7) = @StartingWhen;
    DECLARE @SensorCounter int;
    DECLARE @DelayInSeconds int;
    DECLARE @MidnightToday datetime2(7) = CAST(@StartingWhen AS date);
    DECLARE @TimeToFinishForTheDay datetime2(7) = DATEADD(hour, 16, @MidnightToday);
    DECLARE @Temperature decimal(10,2);
    DECLARE @FullSensorData nvarchar(1000);
    DECLARE @Latitude decimal(18,7);
    DECLARE @Longitude decimal(18,7);
    DECLARE @IsCompressed bit;

    WHILE @TimeCounter < @TimeToFinishForTheDay
    BEGIN
        SET @SensorCounter = 0;
        WHILE @SensorCounter < @NumberOfSensors
        BEGIN
            SET @Temperature = 3 + RAND() * 2;
            SET @Latitude = 37.78352 + RAND() * 30;
            SET @Longitude = -122.4169 + RAND() * 40;

            SET @IsCompressed = CASE WHEN @TimeCounter < '20220101' THEN 1 ELSE 0 END;

            SET @FullSensorData = N'{"Recordings": '
              + N'['
              + N'{"type":"Feature", "geometry": {"type":"Point", "coordinates":['
              + CAST(@Longitude AS nvarchar(20)) + N',' + CAST(@Latitude AS nvarchar(20))
              + N'] }, "properties":{"rego":"' + STRING_ESCAPE(@VehicleRegistration, N'json')
              + N'","sensor":' + CAST(@SensorCounter + 1 AS nvarchar(20))
              + N',"when":"' + CONVERT(nvarchar(30), @TimeCounter, 126)
              + N'","temp":' + CAST(@Temperature AS nvarchar(20))
              + N'}} ]'
              + N'}';

            INSERT Warehouse.VehicleTemperatures
                (VehicleRegistration, ChillerSensorNumber,
                 RecordedWhen, Temperature,
                 FullSensorData, IsCompressed, CompressedSensorData)
            VALUES
                (@VehicleRegistration, @SensorCounter + 1,
                 @TimeCounter, @Temperature,
                 CASE WHEN @IsCompressed = 0 THEN @FullSensorData END,
                 @IsCompressed,
                 CASE WHEN @IsCompressed <> 0 THEN COMPRESS(@FullSensorData) END);

            SET @SensorCounter += 1;
        END;
        SET @DelayInSeconds = CEILING(RAND() * @AverageSecondsBetweenReadings);
        SET @TimeCounter = DATEADD(second, @DelayInSeconds, @TimeCounter);
    END;
END;
GO

-- File: RecordInvoiceDeliveries.sql
﻿
CREATE PROCEDURE DataLoadSimulation.RecordInvoiceDeliveries
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Recording invoice deliveries for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

    --DECLARE @DeliveryDriverPersonID int = (SELECT TOP(1) PersonID
    --                                       FROM [Application].People
    --                                       WHERE IsEmployee <> 0
    --                                       ORDER BY NEWID());
    DECLARE @DeliveryDriverPersonID INT
    EXEC [DataLoadSimulation].[GetRandomEmployeePerson]
      @EmployeePersonID = @DeliveryDriverPersonID OUTPUT

    DECLARE @ReturnedDeliveryData nvarchar(max);
    DECLARE @InvoiceID int;
    DECLARE @CustomerName nvarchar(100);
    DECLARE @PrimaryContactFullName nvarchar(50);
    DECLARE @Latitude decimal(18,7);
    DECLARE @Longitude decimal(18,7);
    DECLARE @DeliveryAttemptWhen datetime2(7);
    DECLARE @Counter int = 0;
    DECLARE @DeliveryEvent nvarchar(max);
    DECLARE @IsDelivered bit;

    DECLARE InvoiceList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT i.InvoiceID, i.ReturnedDeliveryData, c.CustomerName
         , p.FullName, ct.[Location].Lat, ct.[Location].Long
      FROM Sales.Invoices AS i
     INNER JOIN Sales.Customers AS c
        ON i.CustomerID = c.CustomerID
     INNER JOIN [Application].Cities AS ct
        ON c.DeliveryCityID = ct.CityID
     INNER JOIN [Application].People AS p
        ON c.PrimaryContactPersonID = p.PersonID
     WHERE i.ConfirmedDeliveryTime IS NULL
       AND i.InvoiceDate < CAST(@StartingWhen AS date)
     ORDER BY i.InvoiceID;

    OPEN InvoiceList;
    FETCH NEXT FROM InvoiceList INTO @InvoiceID, @ReturnedDeliveryData, @CustomerName, @PrimaryContactFullName, @Latitude, @Longitude;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Counter += 1;
        SET @DeliveryAttemptWhen = DATEADD(minute, @Counter * 5, @StartingWhen);

        SET @DeliveryEvent = N'{ }';
        SET @DeliveryEvent = JSON_MODIFY(@DeliveryEvent, N'$.Event', N'DeliveryAttempt');
        SET @DeliveryEvent = JSON_MODIFY(@DeliveryEvent, N'$.EventTime', CONVERT(nvarchar(20), @DeliveryAttemptWhen, 126));
        SET @DeliveryEvent = JSON_MODIFY(@DeliveryEvent, N'$.ConNote', N'EAN-125-' + CAST(@InvoiceID + 1050 AS nvarchar(20)));
        SET @DeliveryEvent = JSON_MODIFY(@DeliveryEvent, N'$.DriverID', @DeliveryDriverPersonID);
        SET @DeliveryEvent = JSON_MODIFY(@DeliveryEvent, N'$.Latitude', @Latitude);
        SET @DeliveryEvent = JSON_MODIFY(@DeliveryEvent, N'$.Longitude', @Longitude);

        SET @IsDelivered = 0;

        IF RAND() < 0.1 -- 10 % chance of non-delivery on this attempt
        BEGIN
            SET @DeliveryEvent = JSON_MODIFY(@DeliveryEvent, N'$.Comment', N'Receiver not present');
        END ELSE BEGIN -- delivered
            SET @DeliveryEvent = JSON_MODIFY(@DeliveryEvent, N'$.Status', N'Delivered');
            SET @IsDelivered = 1;
        END;

        SET @ReturnedDeliveryData = JSON_MODIFY(@ReturnedDeliveryData, N'append $.Events', JSON_QUERY(@DeliveryEvent));
        SET @ReturnedDeliveryData = JSON_MODIFY(@ReturnedDeliveryData, N'$.DeliveredWhen', CONVERT(nvarchar(20), @DeliveryAttemptWhen, 126));
        SET @ReturnedDeliveryData = JSON_MODIFY(@ReturnedDeliveryData, N'$.ReceivedBy', @PrimaryContactFullName);

        UPDATE Sales.Invoices
        SET ReturnedDeliveryData = @ReturnedDeliveryData,
            LastEditedBy = @DeliveryDriverPersonID,
            LastEditedWhen = @StartingWhen
        WHERE InvoiceID = @InvoiceID;

        FETCH NEXT FROM InvoiceList INTO @InvoiceID, @ReturnedDeliveryData, @CustomerName, @PrimaryContactFullName, @Latitude, @Longitude;
    END;

    CLOSE InvoiceList;
    DEALLOCATE InvoiceList;
END;
GO

-- File: UpdateCustomFields.sql
﻿-- Note this procedure is not included in the regular build, it
-- is called during the post deployment process.
-- This is due to the fact it updates temporal tables, and SSDT
-- will throw up an error when this occurs, despite the fact we
-- have procedures to deactivate the temporal tables and reactivate
-- when done.
DROP PROCEDURE IF EXISTS DataLoadSimulation.UpdateCustomFields;
GO

CREATE PROCEDURE DataLoadSimulation.UpdateCustomFields
@CurrentDateTime AS date
WITH EXECUTE AS OWNER
AS
BEGIN
    DECLARE @StartingWhen datetime2(7) = CAST(@CurrentDateTime AS date);

    SET @StartingWhen = DATEADD(hour, 23, @StartingWhen);

    -- Populate custom data for stock items

    UPDATE Warehouse.StockItems
    SET CustomFields = N'{ "CountryOfManufacture": '
                     + CASE WHEN IsChillerStock <> 0 THEN N'"USA", "ShelfLife": "7 days"'
                            WHEN StockItemName LIKE N'%USB food%' THEN N'"Japan"'
                            ELSE N'"China"'
                       END
                     + N', "Tags": []'
                     + CASE WHEN Size IN (N'S', N'XS', N'XXS', N'3XS') THEN N', "Range": "Children"'
                            WHEN Size IN (N'M') THEN N', "Range": "Teens/Young Adult"'
                            WHEN Size IN (N'L', N'XL', N'XXL', N'3XL', N'4XL', N'5XL', N'6XL', N'7XL') THEN N', "Range": "Adult"'
                            ELSE N''
                       END
                     + CASE WHEN StockItemName LIKE N'RC %' THEN N', "MinimumAge": "10"'
                            ELSE N''
                       END
                     + N' }',
        ValidFrom = @StartingWhen;

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'Radio Control'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'RC %';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'Realistic Sound'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'RC %';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'Vintage'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'%vintage%';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'Halloween Fun'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'%halloween%';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'Super Value'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'%pack of%';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'So Realistic'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'%ride on%';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'Comfortable'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'%slipper%';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'Long Battery Life'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'%slipper%';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', CASE WHEN StockItemID % 2 = 0 THEN N'32GB' ELSE N'16GB' END),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'%USB food%';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'Comedy'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'%joke%';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'USB Powered'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'%USB%';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE si
    SET si.CustomFields = JSON_MODIFY(si.CustomFields, N'append $.Tags', N'Limited Stock'),
        ValidFrom = @StartingWhen
    FROM Warehouse.StockItems AS si
    WHERE EXISTS (SELECT 1
                  FROM Warehouse.StockItemStockGroups AS sisg
                  INNER JOIN Warehouse.StockGroups AS sg
                  ON sisg.StockGroupID = sg.StockGroupID
                  WHERE si.StockItemID = sisg.StockItemID
                  AND sg.StockGroupName LIKE N'%Packaging%');

    -- populate custom data for employees and salespeople

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    DECLARE EmployeeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT PersonID, IsSalesperson
    FROM [Application].People
    WHERE IsEmployee <> 0;

    DECLARE @EmployeeID int;
    DECLARE @IsSalesperson bit;
    DECLARE @CustomFields nvarchar(max);
    DECLARE @JobTitle nvarchar(max);
    DECLARE @NumberOfAdditionalLanguages int;
    DECLARE @LanguageCounter int;
    DECLARE @OtherLanguages TABLE ( LanguageName nvarchar(50) );
    DECLARE @LanguageName nvarchar(50);

    OPEN EmployeeList;
    FETCH NEXT FROM EmployeeList INTO @EmployeeID, @IsSalesperson;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @CustomFields = N'{ "OtherLanguages": [] }';

        SET @NumberOfAdditionalLanguages = FLOOR(RAND() * 4);
        DELETE @OtherLanguages;
        SET @LanguageCounter = 0;
        WHILE @LanguageCounter < @NumberOfAdditionalLanguages
        BEGIN
            SET @LanguageName = (SELECT TOP(1) alias
                                 FROM sys.syslanguages
                                 WHERE alias NOT LIKE N'%English%'
                                 AND alias NOT LIKE N'%Brazil%'
                                 ORDER BY NEWID());
            IF @LanguageName LIKE N'%Chinese%' SET @LanguageName = N'Chinese';
            IF NOT EXISTS (SELECT 1 FROM @OtherLanguages WHERE LanguageName = @LanguageName)
            BEGIN
                INSERT @OtherLanguages (LanguageName) VALUES(@LanguageName);
                SET @CustomFields = JSON_MODIFY(@CustomFields, N'append $.OtherLanguages', @LanguageName);
            END;
            SET @LanguageCounter += 1;
        END;

        SET @CustomFields = JSON_MODIFY(@CustomFields, N'$.HireDate',
                                        CONVERT(nvarchar(20), DATEADD(day, 0 - CEILING(RAND() * 2000) - 100, '20200101'), 126));

        SET @JobTitle = N'Team Member';
        SET @JobTitle = CASE WHEN RAND() < 0.05 THEN N'General Manager'
                             WHEN RAND() < 0.1 THEN N'Manager'
                             WHEN RAND() < 0.15 THEN N'Accounts Controller'
                             WHEN RAND() < 0.2 THEN N'Warehouse Supervisor'
                             ELSE @JobTitle
                        END;
        SET @CustomFields = JSON_MODIFY(@CustomFields, N'$.Title', @JobTitle);

        IF @IsSalesperson <> 0
        BEGIN
            SET @CustomFields = JSON_MODIFY(@CustomFields, N'$.PrimarySalesTerritory',
                                            (SELECT TOP(1) SalesTerritory FROM [Application].StateProvinces ORDER BY NEWID()));
            SET @CustomFields = JSON_MODIFY(@CustomFields, N'$.CommissionRate',
                                            CAST(CAST(RAND() * 5 AS decimal(18,2)) AS nvarchar(20)));
        END;

        UPDATE [Application].People
        SET CustomFields = @CustomFields,
            ValidFrom = @StartingWhen
        WHERE PersonID = @EmployeeID;

        FETCH NEXT FROM EmployeeList INTO @EmployeeID, @IsSalesperson;
    END;

    CLOSE EmployeeList;
    DEALLOCATE EmployeeList;

    -- Set user preferences

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Application.People
    SET UserPreferences = N'{"theme":"'+ (CASE (PersonID % 7)
                                              WHEN 0 THEN 'ui-darkness'
                                              WHEN 1 THEN 'blitzer'
                                              WHEN 2 THEN 'humanity'
                                              WHEN 3 THEN 'dark-hive'
                                              WHEN 4 THEN 'ui-darkness'
                                              WHEN 5 THEN 'le-frog'
                                              WHEN 6 THEN 'black-tie'
                                              ELSE 'ui-lightness'
                                          END)
                        + N'","dateFormat":"' + CASE (PersonID % 10)
                                                    WHEN 0 THEN 'mm/dd/yy'
                                                    WHEN 1 THEN 'yy-mm-dd'
                                                    WHEN 2 THEN 'dd/mm/yy'
                                                    WHEN 3 THEN 'DD, MM d, yy'
                                                    WHEN 4 THEN 'dd/mm/yy'
                                                    WHEN 5 THEN 'dd/mm/yy'
                                                    WHEN 6 THEN 'mm/dd/yy'
                                                    ELSE 'mm/dd/yy'
                                                END
                        + N'","timeZone": "PST"'
                        + N',"table":{"pagingType":"' + CASE (PersonID % 5)
                                                            WHEN 0 THEN 'numbers'
                                                            WHEN 1 THEN 'full_numbers'
                                                            WHEN 2 THEN 'full'
                                                            WHEN 3 THEN 'simple_numbers'
                                                            ELSE 'simple'
                                                        END
                        + N'","pageLength": ' + CASE (PersonID % 5)
                                                    WHEN 0 THEN '10'
                                                    WHEN 1 THEN '25'
                                                    WHEN 2 THEN '50'
                                                    WHEN 3 THEN '10'
                                                    ELSE '10'
                                                END + N'},"favoritesOnDashboard":true}',
        ValidFrom = @StartingWhen
    WHERE UserPreferences IS NOT NULL;
END;
GO

GO

-- File: GetCityUpdates.sql
﻿
CREATE PROCEDURE Integration.GetCityUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) = '99991231 23:59:59.9999999';
    DECLARE @InitialLoadDate date = '20200101';

    CREATE TABLE #CityChanges
    (
        [WWI City ID] int,
        City nvarchar(50),
        [State Province] nvarchar(50),
        Country nvarchar(50),
        Continent nvarchar(30),
        [Sales Territory] nvarchar(50),
        Region nvarchar(30),
        Subregion nvarchar(30),
        [Location] geography,
        [Latest Recorded Population] bigint,
        [Valid From] datetime2(7),
        [Valid To] datetime2(7) NULL
    );

    DECLARE @CountryID int;
    DECLARE @StateProvinceID int;
    DECLARE @CityID int;
    DECLARE @ValidFrom datetime2(7);

    -- first need to find any country changes that have occurred since initial load

    DECLARE CountryChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT co.CountryID,
           co.ValidFrom
    FROM [Application].Countries_Archive AS co
    WHERE co.ValidFrom > @LastCutoff
    AND co.ValidFrom <= @NewCutoff
    AND co.ValidFrom <> @InitialLoadDate
    UNION ALL
    SELECT co.CountryID,
           co.ValidFrom
    FROM [Application].Countries AS co
    WHERE co.ValidFrom > @LastCutoff
    AND co.ValidFrom <= @NewCutoff
    AND co.ValidFrom <> @InitialLoadDate
    ORDER BY ValidFrom;

    OPEN CountryChangeList;
    FETCH NEXT FROM CountryChangeList INTO @CountryID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #CityChanges
            ([WWI City ID], City, [State Province], Country, Continent, [Sales Territory], Region, Subregion,
             [Location], [Latest Recorded Population], [Valid From], [Valid To])
        SELECT c.CityID, c.CityName, sp.StateProvinceName, co.CountryName, co.Continent, sp.SalesTerritory, co.Region, co.Subregion,
               c.[Location], COALESCE(c.LatestRecordedPopulation, 0), @ValidFrom, NULL
        FROM [Application].Cities FOR SYSTEM_TIME AS OF @ValidFrom AS c
        INNER JOIN [Application].StateProvinces FOR SYSTEM_TIME AS OF @ValidFrom AS sp
        ON c.StateProvinceID = sp.StateProvinceID
        INNER JOIN [Application].Countries FOR SYSTEM_TIME AS OF @ValidFrom AS co
        ON sp.CountryID = co.CountryID
        WHERE co.CountryID = @CountryID;

        FETCH NEXT FROM CountryChangeList INTO @CountryID, @ValidFrom;
    END;

    CLOSE CountryChangeList;
    DEALLOCATE CountryChangeList;

    -- next need to find any stateprovince changes that have occurred since initial load

    DECLARE StateProvinceChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT sp.StateProvinceID,
           sp.ValidFrom
    FROM [Application].StateProvinces_Archive AS sp
    WHERE sp.ValidFrom > @LastCutoff
    AND sp.ValidFrom <= @NewCutoff
    AND sp.ValidFrom <> @InitialLoadDate
    UNION ALL
    SELECT sp.StateProvinceID,
           sp.ValidFrom
    FROM [Application].StateProvinces AS sp
    WHERE sp.ValidFrom > @LastCutoff
    AND sp.ValidFrom <= @NewCutoff
    AND sp.ValidFrom <> @InitialLoadDate
    ORDER BY ValidFrom;

    OPEN StateProvinceChangeList;
    FETCH NEXT FROM StateProvinceChangeList INTO @StateProvinceID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #CityChanges
            ([WWI City ID], City, [State Province], Country, Continent, [Sales Territory], Region, Subregion,
             [Location], [Latest Recorded Population], [Valid From], [Valid To])
        SELECT c.CityID, c.CityName, sp.StateProvinceName, co.CountryName, co.Continent, sp.SalesTerritory, co.Region, co.Subregion,
               c.[Location], COALESCE(c.LatestRecordedPopulation, 0), @ValidFrom, NULL
        FROM [Application].Cities FOR SYSTEM_TIME AS OF @ValidFrom AS c
        INNER JOIN [Application].StateProvinces FOR SYSTEM_TIME AS OF @ValidFrom AS sp
        ON c.StateProvinceID = sp.StateProvinceID
        INNER JOIN [Application].Countries FOR SYSTEM_TIME AS OF @ValidFrom AS co
        ON sp.CountryID = co.CountryID
        WHERE sp.StateProvinceID = @StateProvinceID;

        FETCH NEXT FROM StateProvinceChangeList INTO @StateProvinceID, @ValidFrom;
    END;

    CLOSE StateProvinceChangeList;
    DEALLOCATE StateProvinceChangeList;

    -- finally need to find any city changes that have occurred, including during the initial load

    DECLARE CityChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT c.CityID,
           c.ValidFrom
    FROM [Application].Cities_Archive AS c
    WHERE c.ValidFrom > @LastCutoff
    AND c.ValidFrom <= @NewCutoff
    UNION ALL
    SELECT c.CityID,
           c.ValidFrom
    FROM [Application].Cities AS c
    WHERE c.ValidFrom > @LastCutoff
    AND c.ValidFrom <= @NewCutoff
    ORDER BY ValidFrom;

    OPEN CityChangeList;
    FETCH NEXT FROM CityChangeList INTO @CityID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #CityChanges
            ([WWI City ID], City, [State Province], Country, Continent, [Sales Territory], Region, Subregion,
             [Location], [Latest Recorded Population], [Valid From], [Valid To])
        SELECT c.CityID, c.CityName, sp.StateProvinceName, co.CountryName, co.Continent, sp.SalesTerritory, co.Region, co.Subregion,
               c.[Location], COALESCE(c.LatestRecordedPopulation, 0), @ValidFrom, NULL
        FROM [Application].Cities FOR SYSTEM_TIME AS OF @ValidFrom AS c
        INNER JOIN [Application].StateProvinces FOR SYSTEM_TIME AS OF @ValidFrom AS sp
        ON c.StateProvinceID = sp.StateProvinceID
        INNER JOIN [Application].Countries FOR SYSTEM_TIME AS OF @ValidFrom AS co
        ON sp.CountryID = co.CountryID
        WHERE c.CityID = @CityID;

        FETCH NEXT FROM CityChangeList INTO @CityID, @ValidFrom;
    END;

    CLOSE CityChangeList;
    DEALLOCATE CityChangeList;

    -- add an index to make lookups faster

    CREATE INDEX IX_CityChanges ON #CityChanges ([WWI City ID], [Valid From]);

    -- work out the [Valid To] value by taking the [Valid From] of any row that's for the same city but later
    -- otherwise take the end of time

    UPDATE cc
    SET [Valid To] = COALESCE((SELECT MIN([Valid From]) FROM #CityChanges AS cc2
                                                        WHERE cc2.[WWI City ID] = cc.[WWI City ID]
                                                        AND cc2.[Valid From] > cc.[Valid From]), @EndOfTime)
    FROM #CityChanges AS cc;

    SELECT [WWI City ID], City, [State Province], Country, Continent, [Sales Territory],
           Region, Subregion, [Location] geography, [Latest Recorded Population], [Valid From],
           [Valid To]
    FROM #CityChanges
    ORDER BY [Valid From];

    DROP TABLE #CityChanges;

    RETURN 0;
END;

GO

-- File: GetCustomerUpdates.sql
﻿
CREATE PROCEDURE Integration.GetCustomerUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) = '99991231 23:59:59.9999999';
    DECLARE @InitialLoadDate date = '20200101';

    CREATE TABLE #CustomerChanges
    (
        [WWI Customer ID] int,
        Customer nvarchar(100),
        [Bill To Customer] nvarchar(100),
        Category nvarchar(50),
        [Buying Group] nvarchar(50),
        [Primary Contact] nvarchar(50),
        [Postal Code] nvarchar(10),
        [Valid From] datetime2(7),
        [Valid To] datetime2(7) NULL
    );

    DECLARE @BuyingGroupID int;
    DECLARE @CustomerCategoryID int;
    DECLARE @CustomerID int;
    DECLARE @ValidFrom datetime2(7);

    -- first need to find any buying group changes that have occurred since initial load

    DECLARE BuyingGroupChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT bg.BuyingGroupID,
           bg.ValidFrom
    FROM Sales.BuyingGroups_Archive AS bg
    WHERE bg.ValidFrom > @LastCutoff
    AND bg.ValidFrom <= @NewCutoff
    AND bg.ValidFrom <> @InitialLoadDate
    UNION ALL
    SELECT bg.BuyingGroupID,
           bg.ValidFrom
    FROM Sales.BuyingGroups AS bg
    WHERE bg.ValidFrom > @LastCutoff
    AND bg.ValidFrom <= @NewCutoff
    AND bg.ValidFrom <> @InitialLoadDate
    ORDER BY ValidFrom;

    OPEN BuyingGroupChangeList;
    FETCH NEXT FROM BuyingGroupChangeList INTO @BuyingGroupID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #CustomerChanges
            ([WWI Customer ID], Customer, [Bill To Customer], Category,
             [Buying Group], [Primary Contact], [Postal Code],
             [Valid From], [Valid To])
        SELECT c.CustomerID, c.CustomerName, bt.CustomerName, cc.CustomerCategoryName,
               bg.BuyingGroupName, p.FullName, c.DeliveryPostalCode,
               c.ValidFrom, c.ValidTo
        FROM Sales.Customers FOR SYSTEM_TIME AS OF @ValidFrom AS c
        INNER JOIN Sales.CustomerCategories FOR SYSTEM_TIME AS OF @ValidFrom AS cc
        ON c.CustomerCategoryID = cc.CustomerCategoryID
        INNER JOIN Sales.Customers FOR SYSTEM_TIME AS OF @ValidFrom AS bt
        ON c.BillToCustomerID = bt.CustomerID
        INNER JOIN [Application].People FOR SYSTEM_TIME AS OF @ValidFrom AS p
        ON c.PrimaryContactPersonID = p.PersonID
        LEFT JOIN Sales.BuyingGroups FOR SYSTEM_TIME AS OF @ValidFrom AS bg
        ON c.BuyingGroupID = bg.BuyingGroupID
        WHERE c.BuyingGroupID = @BuyingGroupID;

        FETCH NEXT FROM BuyingGroupChangeList INTO @BuyingGroupID, @ValidFrom;
    END;

    CLOSE BuyingGroupChangeList;
    DEALLOCATE BuyingGroupChangeList;

    -- next need to find any customer category changes that have occurred since initial load

    DECLARE CustomerCategoryChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT cc.CustomerCategoryID,
           cc.ValidFrom
    FROM Sales.CustomerCategories_Archive AS cc
    WHERE cc.ValidFrom > @LastCutoff
    AND cc.ValidFrom <= @NewCutoff
    AND cc.ValidFrom <> @InitialLoadDate
    UNION ALL
    SELECT cc.CustomerCategoryID,
           cc.ValidFrom
    FROM Sales.CustomerCategories AS cc
    WHERE cc.ValidFrom > @LastCutoff
    AND cc.ValidFrom <= @NewCutoff
    AND cc.ValidFrom <> @InitialLoadDate
    ORDER BY ValidFrom;

    OPEN CustomerCategoryChangeList;
    FETCH NEXT FROM CustomerCategoryChangeList INTO @CustomerCategoryID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #CustomerChanges
            ([WWI Customer ID], Customer, [Bill To Customer], Category,
             [Buying Group], [Primary Contact], [Postal Code],
             [Valid From], [Valid To])
        SELECT c.CustomerID, c.CustomerName, bt.CustomerName, cc.CustomerCategoryName,
               bg.BuyingGroupName, p.FullName, c.DeliveryPostalCode,
               c.ValidFrom, c.ValidTo
        FROM Sales.Customers FOR SYSTEM_TIME AS OF @ValidFrom AS c
        INNER JOIN Sales.CustomerCategories FOR SYSTEM_TIME AS OF @ValidFrom AS cc
        ON c.CustomerCategoryID = cc.CustomerCategoryID
        INNER JOIN Sales.Customers FOR SYSTEM_TIME AS OF @ValidFrom AS bt
        ON c.BillToCustomerID = bt.CustomerID
        INNER JOIN [Application].People FOR SYSTEM_TIME AS OF @ValidFrom AS p
        ON c.PrimaryContactPersonID = p.PersonID
        LEFT JOIN Sales.BuyingGroups FOR SYSTEM_TIME AS OF @ValidFrom AS bg
        ON c.BuyingGroupID = bg.BuyingGroupID
        WHERE cc.CustomerCategoryID = @CustomerCategoryID;

        FETCH NEXT FROM CustomerCategoryChangeList INTO @CustomerCategoryID, @ValidFrom;
    END;

    CLOSE CustomerCategoryChangeList;
    DEALLOCATE CustomerCategoryChangeList;

    -- finally need to find any customer changes that have occurred, including during the initial load

    DECLARE CustomerChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT c.CustomerID,
           c.ValidFrom
    FROM Sales.Customers_Archive AS c
    WHERE c.ValidFrom > @LastCutoff
    AND c.ValidFrom <= @NewCutoff
    UNION ALL
    SELECT c.CustomerID,
           c.ValidFrom
    FROM Sales.Customers AS c
    WHERE c.ValidFrom > @LastCutoff
    AND c.ValidFrom <= @NewCutoff
    ORDER BY ValidFrom;

    OPEN CustomerChangeList;
    FETCH NEXT FROM CustomerChangeList INTO @CustomerID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #CustomerChanges
            ([WWI Customer ID], Customer, [Bill To Customer], Category,
             [Buying Group], [Primary Contact], [Postal Code],
             [Valid From], [Valid To])
        SELECT c.CustomerID, c.CustomerName, bt.CustomerName, cc.CustomerCategoryName,
               bg.BuyingGroupName, p.FullName, c.DeliveryPostalCode,
               c.ValidFrom, c.ValidTo
        FROM Sales.Customers FOR SYSTEM_TIME AS OF @ValidFrom AS c
        INNER JOIN Sales.CustomerCategories FOR SYSTEM_TIME AS OF @ValidFrom AS cc
        ON c.CustomerCategoryID = cc.CustomerCategoryID
        INNER JOIN Sales.Customers FOR SYSTEM_TIME AS OF @ValidFrom AS bt
        ON c.BillToCustomerID = bt.CustomerID
        INNER JOIN [Application].People FOR SYSTEM_TIME AS OF @ValidFrom AS p
        ON c.PrimaryContactPersonID = p.PersonID
        LEFT JOIN Sales.BuyingGroups FOR SYSTEM_TIME AS OF @ValidFrom AS bg
        ON c.BuyingGroupID = bg.BuyingGroupID
        WHERE c.CustomerID = @CustomerID;

        FETCH NEXT FROM CustomerChangeList INTO @CustomerID, @ValidFrom;
    END;

    CLOSE CustomerChangeList;
    DEALLOCATE CustomerChangeList;

    -- add an index to make lookups faster

    CREATE INDEX IX_CustomerChanges ON #CustomerChanges ([WWI Customer ID], [Valid From]);

    -- work out the [Valid To] value by taking the [Valid From] of any row that's for the same customer but later
    -- otherwise take the end of time

    UPDATE cc
    SET [Valid To] = COALESCE((SELECT MIN([Valid From]) FROM #CustomerChanges AS cc2
                                                        WHERE cc2.[WWI Customer ID] = cc.[WWI Customer ID]
                                                        AND cc2.[Valid From] > cc.[Valid From]), @EndOfTime)
    FROM #CustomerChanges AS cc;

    SELECT [WWI Customer ID], Customer, [Bill To Customer], Category,
           [Buying Group], [Primary Contact], [Postal Code],
           [Valid From], [Valid To]
    FROM #CustomerChanges
    ORDER BY [Valid From];

    DROP TABLE #CustomerChanges;

    RETURN 0;
END;

GO

-- File: GetEmployeeUpdates.sql
﻿
CREATE PROCEDURE Integration.GetEmployeeUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) = '99991231 23:59:59.9999999';

    CREATE TABLE #EmployeeChanges
    (
        [WWI Employee ID] int,
        Employee nvarchar(50),
        [Preferred Name] nvarchar(50),
        [Is Salesperson] bit,
        Photo varbinary(max),
        [Valid From] datetime2(7),
        [Valid To] datetime2(7)
    );

    DECLARE @PersonID int;
    DECLARE @ValidFrom datetime2(7);

    -- need to find any employee changes that have occurred, including during the initial load

    DECLARE EmployeeChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT p.PersonID,
           p.ValidFrom
    FROM [Application].People_Archive AS p
    WHERE p.ValidFrom > @LastCutoff
    AND p.ValidFrom <= @NewCutoff
    AND p.IsEmployee <> 0
    UNION ALL
    SELECT p.PersonID,
           p.ValidFrom
    FROM [Application].People AS p
    WHERE p.ValidFrom > @LastCutoff
    AND p.ValidFrom <= @NewCutoff
    AND p.IsEmployee <> 0
    ORDER BY ValidFrom;

    OPEN EmployeeChangeList;
    FETCH NEXT FROM EmployeeChangeList INTO @PersonID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #EmployeeChanges
            ([WWI Employee ID], Employee, [Preferred Name], [Is Salesperson], Photo,
             [Valid From], [Valid To])
        SELECT p.PersonID, p.FullName, p.PreferredName, p.IsSalesperson, p.Photo,
               p.ValidFrom, p.ValidTo
        FROM [Application].People FOR SYSTEM_TIME AS OF @ValidFrom AS p
        WHERE p.PersonID = @PersonID;

        FETCH NEXT FROM EmployeeChangeList INTO @PersonID, @ValidFrom;
    END;

    CLOSE EmployeeChangeList;
    DEALLOCATE EmployeeChangeList;

    -- add an index to make lookups faster

    CREATE INDEX IX_EmployeeChanges ON #EmployeeChanges ([WWI Employee ID], [Valid From]);

    -- work out the [Valid To] value by taking the [Valid From] of any row that's for the same entry but later
    -- otherwise take the end of time

    UPDATE cc
    SET [Valid To] = COALESCE((SELECT MIN([Valid From]) FROM #EmployeeChanges AS cc2
                                                        WHERE cc2.[WWI Employee ID] = cc.[WWI Employee ID]
                                                        AND cc2.[Valid From] > cc.[Valid From]), @EndOfTime)
    FROM #EmployeeChanges AS cc;

    SELECT [WWI Employee ID], Employee, [Preferred Name], [Is Salesperson], Photo,
           [Valid From], [Valid To]
    FROM #EmployeeChanges
    ORDER BY [Valid From];

    DROP TABLE #EmployeeChanges;

    RETURN 0;
END;

GO

-- File: GetMovementUpdates.sql
﻿
CREATE PROCEDURE Integration.GetMovementUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT CAST(sit.TransactionOccurredWhen AS date) AS [Date Key],
           sit.StockItemTransactionID AS [WWI Stock Item Transaction ID],
           sit.InvoiceID AS [WWI Invoice ID],
           sit.PurchaseOrderID AS [WWI Purchase Order ID],
           CAST(sit.Quantity AS int) AS Quantity,
           sit.StockItemID AS [WWI Stock Item ID],
           sit.CustomerID AS [WWI Customer ID],
           sit.SupplierID AS [WWI Supplier ID],
           sit.TransactionTypeID AS [WWI Transaction Type ID],
           sit.TransactionOccurredWhen AS [Transaction Occurred When]
    FROM Warehouse.StockItemTransactions AS sit
    WHERE sit.LastEditedWhen > @LastCutoff
    AND sit.LastEditedWhen <= @NewCutoff
    ORDER BY sit.StockItemTransactionID;

    RETURN 0;
END;

GO

-- File: GetOrderUpdates.sql
﻿
CREATE PROCEDURE Integration.GetOrderUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;


    SELECT CAST(o.OrderDate AS date) AS [Order Date Key],
           CAST(ol.PickingCompletedWhen AS date) AS [Picked Date Key],
           o.OrderID AS [WWI Order ID],
           o.BackorderOrderID AS [WWI Backorder ID],
           ol.[Description],
           pt.PackageTypeName AS Package,
           ol.Quantity AS Quantity,
           ol.UnitPrice AS [Unit Price],
           ol.TaxRate AS [Tax Rate],
           ROUND(ol.Quantity * ol.UnitPrice, 2) AS [Total Excluding Tax],
           ROUND(ol.Quantity * ol.UnitPrice * ol.TaxRate / 100.0, 2) AS [Tax Amount],
           ROUND(ol.Quantity * ol.UnitPrice, 2) + ROUND(ol.Quantity * ol.UnitPrice * ol.TaxRate / 100.0, 2) AS [Total Including Tax],
           c.DeliveryCityID AS [WWI City ID],
           c.CustomerID AS [WWI Customer ID],
           ol.StockItemID AS [WWI Stock Item ID],
           o.SalespersonPersonID AS [WWI Salesperson ID],
           o.PickedByPersonID AS [WWI Picker ID],
           CASE WHEN ol.LastEditedWhen > o.LastEditedWhen THEN ol.LastEditedWhen ELSE o.LastEditedWhen END AS [Last Modified When]
    FROM Sales.Orders AS o
    INNER JOIN Sales.OrderLines AS ol
    ON o.OrderID = ol.OrderID
    INNER JOIN Warehouse.PackageTypes AS pt
    ON ol.PackageTypeID = pt.PackageTypeID
    INNER JOIN Sales.Customers AS c
    ON c.CustomerID = o.CustomerID
    WHERE CASE WHEN ol.LastEditedWhen > o.LastEditedWhen THEN ol.LastEditedWhen ELSE o.LastEditedWhen END > @LastCutoff
    AND CASE WHEN ol.LastEditedWhen > o.LastEditedWhen THEN ol.LastEditedWhen ELSE o.LastEditedWhen END <= @NewCutoff
    ORDER BY o.OrderID;

    RETURN 0;
END;

GO

-- File: GetPaymentMethodUpdates.sql
﻿
CREATE PROCEDURE Integration.GetPaymentMethodUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) = '99991231 23:59:59.9999999';

    CREATE TABLE #PaymentMethodChanges
    (
        [WWI Payment Method ID] int,
        [Payment Method] nvarchar(50),
        [Valid From] datetime2(7),
        [Valid To] datetime2(7)
    );

    DECLARE @PaymentMethodID int;
    DECLARE @ValidFrom datetime2(7);

    -- need to find any payment method changes that have occurred, including during the initial load

    DECLARE ChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT p.PaymentMethodID,
           p.ValidFrom
    FROM [Application].PaymentMethods_Archive AS p
    WHERE p.ValidFrom > @LastCutoff
    AND p.ValidFrom <= @NewCutoff
    UNION ALL
    SELECT p.PaymentMethodID,
           p.ValidFrom
    FROM [Application].PaymentMethods AS p
    WHERE p.ValidFrom > @LastCutoff
    AND p.ValidFrom <= @NewCutoff
    ORDER BY ValidFrom;

    OPEN ChangeList;
    FETCH NEXT FROM ChangeList INTO @PaymentMethodID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #PaymentMethodChanges
            ([WWI Payment Method ID], [Payment Method], [Valid From], [Valid To])
        SELECT p.PaymentMethodID, p.PaymentMethodName, p.ValidFrom, p.ValidTo
        FROM [Application].PaymentMethods FOR SYSTEM_TIME AS OF @ValidFrom AS p
        WHERE p.PaymentMethodID = @PaymentMethodID;

        FETCH NEXT FROM ChangeList INTO @PaymentMethodID, @ValidFrom;
    END;

    CLOSE ChangeList;
    DEALLOCATE ChangeList;

    -- add an index to make lookups faster

    CREATE INDEX IX_PaymentMethodChanges ON #PaymentMethodChanges ([WWI Payment Method ID], [Valid From]);

    -- work out the [Valid To] value by taking the [Valid From] of any row that's for the same entry but later
    -- otherwise take the end of time

    UPDATE cc
    SET [Valid To] = COALESCE((SELECT MIN([Valid From]) FROM #PaymentMethodChanges AS cc2
                                                        WHERE cc2.[WWI Payment Method ID] = cc.[WWI Payment Method ID]
                                                        AND cc2.[Valid From] > cc.[Valid From]), @EndOfTime)
    FROM #PaymentMethodChanges AS cc;

    SELECT [WWI Payment Method ID], [Payment Method], [Valid From], [Valid To]
    FROM #PaymentMethodChanges
    ORDER BY [Valid From];

    DROP TABLE #PaymentMethodChanges;

    RETURN 0;
END;

GO

-- File: GetPurchaseUpdates.sql
﻿
CREATE PROCEDURE Integration.GetPurchaseUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;


    SELECT CAST(po.OrderDate AS date) AS [Date Key],
           po.PurchaseOrderID AS [WWI Purchase Order ID],
           pol.OrderedOuters AS [Ordered Outers],
           pol.OrderedOuters * si.QuantityPerOuter AS [Ordered Quantity],
           pol.ReceivedOuters AS [Received Outers],
           pt.PackageTypeName AS Package,
           pol.IsOrderLineFinalized AS [Is Order Finalized],
           po.SupplierID AS [WWI Supplier ID],
           pol.StockItemID AS [WWI Stock Item ID],
           CASE WHEN pol.LastEditedWhen > po.LastEditedWhen THEN pol.LastEditedWhen ELSE po.LastEditedWhen END AS [Last Modified When]
    FROM Purchasing.PurchaseOrders AS po
    INNER JOIN Purchasing.PurchaseOrderLines AS pol
    ON po.PurchaseOrderID = pol.PurchaseOrderID
    INNER JOIN Warehouse.StockItems AS si
    ON pol.StockItemID = si.StockItemID
    INNER JOIN Warehouse.PackageTypes AS pt
    ON pol.PackageTypeID = pt.PackageTypeID
    WHERE CASE WHEN pol.LastEditedWhen > po.LastEditedWhen THEN pol.LastEditedWhen ELSE po.LastEditedWhen END > @LastCutoff
    AND CASE WHEN pol.LastEditedWhen > po.LastEditedWhen THEN pol.LastEditedWhen ELSE po.LastEditedWhen END <= @NewCutoff
    ORDER BY po.PurchaseOrderID;

    RETURN 0;
END;

GO

-- File: GetSaleUpdates.sql
﻿
CREATE PROCEDURE Integration.GetSaleUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT CAST(i.InvoiceDate AS date) AS [Invoice Date Key],
           CAST(i.ConfirmedDeliveryTime AS date) AS [Delivery Date Key],
           i.InvoiceID AS [WWI Invoice ID],
           il.[Description],
           pt.PackageTypeName AS Package,
           il.Quantity,
           il.UnitPrice AS [Unit Price],
           il.TaxRate AS [Tax Rate],
           il.ExtendedPrice - il.TaxAmount AS [Total Excluding Tax],
           il.TaxAmount AS [Tax Amount],
           il.LineProfit AS Profit,
           il.ExtendedPrice AS [Total Including Tax],
           CASE WHEN si.IsChillerStock = 0 THEN il.Quantity ELSE 0 END AS [Total Dry Items],
           CASE WHEN si.IsChillerStock <> 0 THEN il.Quantity ELSE 0 END AS [Total Chiller Items],
           c.DeliveryCityID AS [WWI City ID],
           i.CustomerID AS [WWI Customer ID],
           i.BillToCustomerID AS [WWI Bill To Customer ID],
           il.StockItemID AS [WWI Stock Item ID],
           i.SalespersonPersonID AS [WWI Saleperson ID],
           CASE WHEN il.LastEditedWhen > i.LastEditedWhen THEN il.LastEditedWhen ELSE i.LastEditedWhen END AS [Last Modified When]
    FROM Sales.Invoices AS i
    INNER JOIN Sales.InvoiceLines AS il
    ON i.InvoiceID = il.InvoiceID
    INNER JOIN Warehouse.StockItems AS si
    ON il.StockItemID = si.StockItemID
    INNER JOIN Warehouse.PackageTypes AS pt
    ON il.PackageTypeID = pt.PackageTypeID
    INNER JOIN Sales.Customers AS c
    ON i.CustomerID = c.CustomerID
    INNER JOIN Sales.Customers AS bt
    ON i.BillToCustomerID = bt.CustomerID
    WHERE CASE WHEN il.LastEditedWhen > i.LastEditedWhen THEN il.LastEditedWhen ELSE i.LastEditedWhen END > @LastCutoff
    AND CASE WHEN il.LastEditedWhen > i.LastEditedWhen THEN il.LastEditedWhen ELSE i.LastEditedWhen END <= @NewCutoff
    ORDER BY i.InvoiceID, il.InvoiceLineID;

    RETURN 0;
END;

GO

-- File: GetStockHoldingUpdates.sql
﻿
CREATE PROCEDURE Integration.GetStockHoldingUpdates
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT sih.QuantityOnHand AS [Quantity On Hand],
           sih.BinLocation AS [Bin Location],
           sih.LastStocktakeQuantity AS [Last Stocktake Quantity],
           sih.LastCostPrice AS [Last Cost Price],
           sih.ReorderLevel AS [Reorder Level],
           sih.TargetStockLevel AS [Target Stock Level],
           sih.StockItemID AS [WWI Stock Item ID]
    FROM Warehouse.StockItemHoldings AS sih
    ORDER BY sih.StockItemID;

    RETURN 0;
END;

GO

-- File: GetStockItemUpdates.sql
﻿
CREATE PROCEDURE Integration.GetStockItemUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) = '99991231 23:59:59.9999999';

    CREATE TABLE #StockItemChanges
    (
        [WWI Stock Item ID] int,
        [Stock Item] nvarchar(100),
        Color nvarchar(20),
        [Selling Package] nvarchar(50),
        [Buying Package] nvarchar(50),
        Brand nvarchar(50),
        Size nvarchar(20),
        [Lead Time Days] int,
        [Quantity Per Outer] int,
        [Is Chiller Stock] bit,
        Barcode nvarchar(50),
        [Tax Rate] decimal(18,3),
        [Unit Price] decimal(18,2),
        [Recommended Retail Price] decimal(18,2),
        [Typical Weight Per Unit] decimal(18,3),
        Photo varbinary(max),
        [Valid From] datetime2(7),
        [Valid To] datetime2(7)
    );

    DECLARE @StockItemID int;
    DECLARE @ValidFrom datetime2(7);

    -- need to find any StockItem changes that have occurred, including during the initial load

    DECLARE StockItemChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT c.StockItemID,
           c.ValidFrom
    FROM Warehouse.StockItems_Archive AS c
    WHERE c.ValidFrom > @LastCutoff
    AND c.ValidFrom <= @NewCutoff
    UNION ALL
    SELECT c.StockItemID,
           c.ValidFrom
    FROM Warehouse.StockItems AS c
    WHERE c.ValidFrom > @LastCutoff
    AND c.ValidFrom <= @NewCutoff
    ORDER BY ValidFrom;

    OPEN StockItemChangeList;
    FETCH NEXT FROM StockItemChangeList INTO @StockItemID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #StockItemChanges
            ([WWI Stock Item ID], [Stock Item], Color, [Selling Package],
             [Buying Package], Brand, Size, [Lead Time Days], [Quantity Per Outer],
             [Is Chiller Stock], Barcode, [Tax Rate], [Unit Price], [Recommended Retail Price],
             [Typical Weight Per Unit], Photo, [Valid From], [Valid To])
        SELECT si.StockItemID, si.StockItemName, c.ColorName, spt.PackageTypeName,
               bpt.PackageTypeName, si.Brand, si.Size, si.LeadTimeDays, si.QuantityPerOuter,
               si.IsChillerStock, si.Barcode, si.TaxRate, si.UnitPrice, si.RecommendedRetailPrice,
               si.TypicalWeightPerUnit, si.Photo, si.ValidFrom, si.ValidTo
        FROM Warehouse.StockItems FOR SYSTEM_TIME AS OF @ValidFrom AS si
        INNER JOIN Warehouse.PackageTypes FOR SYSTEM_TIME AS OF @ValidFrom AS spt
        ON si.UnitPackageID = spt.PackageTypeID
        INNER JOIN Warehouse.PackageTypes FOR SYSTEM_TIME AS OF @ValidFrom AS bpt
        ON si.OuterPackageID = bpt.PackageTypeID
        LEFT OUTER JOIN Warehouse.Colors FOR SYSTEM_TIME AS OF @ValidFrom AS c
        ON si.ColorID = c.ColorID
        WHERE si.StockItemID = @StockItemID;

        FETCH NEXT FROM StockItemChangeList INTO @StockItemID, @ValidFrom;
    END;

    CLOSE StockItemChangeList;
    DEALLOCATE StockItemChangeList;

    -- add an index to make lookups faster

    CREATE INDEX IX_StockItemChanges ON #StockItemChanges ([WWI Stock Item ID], [Valid From]);

    -- work out the [Valid To] value by taking the [Valid From] of any row that's for the same StockItem but later
    -- otherwise take the end of time

    UPDATE cc
    SET [Valid To] = COALESCE((SELECT MIN([Valid From]) FROM #StockItemChanges AS cc2
                                                        WHERE cc2.[WWI Stock Item ID] = cc.[WWI Stock Item ID]
                                                        AND cc2.[Valid From] > cc.[Valid From]), @EndOfTime)
    FROM #StockItemChanges AS cc;

    SELECT [WWI Stock Item ID], [Stock Item],
           ISNULL(Color, N'N/A') AS Color,
           [Selling Package], [Buying Package],
           ISNULL(Brand, N'N/A') AS Brand,
           ISNULL(Size, N'N/A') AS Size,
           [Lead Time Days], [Quantity Per Outer], [Is Chiller Stock],
           ISNULL(Barcode, N'N/A') AS Barcode,
           [Tax Rate], [Unit Price], [Recommended Retail Price], [Typical Weight Per Unit],
           Photo, [Valid From], [Valid To]
    FROM #StockItemChanges
    ORDER BY [Valid From];

    DROP TABLE #StockItemChanges;

    RETURN 0;
END;

GO

-- File: GetSupplierUpdates.sql
﻿
CREATE PROCEDURE Integration.GetSupplierUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) = '99991231 23:59:59.9999999';
    DECLARE @InitialLoadDate date = '20200101';

    CREATE TABLE #SupplierChanges
    (
        [WWI Supplier ID] int,
        Supplier nvarchar(100),
        Category nvarchar(50),
        [Primary Contact] nvarchar(50),
        [Supplier Reference] nvarchar(20),
        [Payment Days] int,
        [Postal Code] nvarchar(10),
        [Valid From] datetime2(7),
        [Valid To] datetime2(7)
    );

    DECLARE @SupplierCategoryID int;
    DECLARE @SupplierID int;
    DECLARE @ValidFrom datetime2(7);

    -- need to find any Supplier category changes that have occurred since initial load

    DECLARE SupplierCategoryChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT cc.SupplierCategoryID,
           cc.ValidFrom
    FROM Purchasing.SupplierCategories_Archive AS cc
    WHERE cc.ValidFrom > @LastCutoff
    AND cc.ValidFrom <= @NewCutoff
    AND cc.ValidFrom <> @InitialLoadDate
    UNION ALL
    SELECT cc.SupplierCategoryID,
           cc.ValidFrom
    FROM Purchasing.SupplierCategories AS cc
    WHERE cc.ValidFrom > @LastCutoff
    AND cc.ValidFrom <= @NewCutoff
    AND cc.ValidFrom <> @InitialLoadDate
    ORDER BY ValidFrom;

    OPEN SupplierCategoryChangeList;
    FETCH NEXT FROM SupplierCategoryChangeList INTO @SupplierCategoryID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #SupplierChanges
            ([WWI Supplier ID], Supplier, Category, [Primary Contact], [Supplier Reference],
             [Payment Days], [Postal Code], [Valid From], [Valid To])
        SELECT s.SupplierID, s.SupplierName, sc.SupplierCategoryName, p.FullName, s.SupplierReference,
               s.PaymentDays, s.DeliveryPostalCode, s.ValidFrom, s.ValidTo
        FROM Purchasing.Suppliers FOR SYSTEM_TIME AS OF @ValidFrom AS s
        INNER JOIN Purchasing.SupplierCategories FOR SYSTEM_TIME AS OF @ValidFrom AS sc
        ON s.SupplierCategoryID = sc.SupplierCategoryID
        INNER JOIN [Application].People FOR SYSTEM_TIME AS OF @ValidFrom AS p
        ON s.PrimaryContactPersonID = p.PersonID
        WHERE sc.SupplierCategoryID = @SupplierCategoryID;

        FETCH NEXT FROM SupplierCategoryChangeList INTO @SupplierCategoryID, @ValidFrom;
    END;

    CLOSE SupplierCategoryChangeList;
    DEALLOCATE SupplierCategoryChangeList;

    -- finally need to find any Supplier changes that have occurred, including during the initial load

    DECLARE SupplierChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT c.SupplierID,
           c.ValidFrom
    FROM Purchasing.Suppliers_Archive AS c
    WHERE c.ValidFrom > @LastCutoff
    AND c.ValidFrom <= @NewCutoff
    UNION ALL
    SELECT c.SupplierID,
           c.ValidFrom
    FROM Purchasing.Suppliers AS c
    WHERE c.ValidFrom > @LastCutoff
    AND c.ValidFrom <= @NewCutoff
    ORDER BY ValidFrom;

    OPEN SupplierChangeList;
    FETCH NEXT FROM SupplierChangeList INTO @SupplierID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #SupplierChanges
            ([WWI Supplier ID], Supplier, Category, [Primary Contact], [Supplier Reference],
             [Payment Days], [Postal Code], [Valid From], [Valid To])
        SELECT s.SupplierID, s.SupplierName, sc.SupplierCategoryName, p.FullName, s.SupplierReference,
               s.PaymentDays, s.DeliveryPostalCode, s.ValidFrom, s.ValidTo
        FROM Purchasing.Suppliers FOR SYSTEM_TIME AS OF @ValidFrom AS s
        INNER JOIN Purchasing.SupplierCategories FOR SYSTEM_TIME AS OF @ValidFrom AS sc
        ON s.SupplierCategoryID = sc.SupplierCategoryID
        INNER JOIN [Application].People FOR SYSTEM_TIME AS OF @ValidFrom AS p
        ON s.PrimaryContactPersonID = p.PersonID
        WHERE s.SupplierID = @SupplierID;

        FETCH NEXT FROM SupplierChangeList INTO @SupplierID, @ValidFrom;
    END;

    CLOSE SupplierChangeList;
    DEALLOCATE SupplierChangeList;

    -- add an index to make lookups faster

    CREATE INDEX IX_SupplierChanges ON #SupplierChanges ([WWI Supplier ID], [Valid From]);

    -- work out the [Valid To] value by taking the [Valid From] of any row that's for the same Supplier but later
    -- otherwise take the end of time

    UPDATE cc
    SET [Valid To] = COALESCE((SELECT MIN([Valid From]) FROM #SupplierChanges AS cc2
                                                        WHERE cc2.[WWI Supplier ID] = cc.[WWI Supplier ID]
                                                        AND cc2.[Valid From] > cc.[Valid From]), @EndOfTime)
    FROM #SupplierChanges AS cc;

    SELECT [WWI Supplier ID], Supplier, Category, [Primary Contact],
           [Supplier Reference], [Payment Days], [Postal Code],
           [Valid From], [Valid To]
    FROM #SupplierChanges
    ORDER BY [Valid From];

    DROP TABLE #SupplierChanges;

    RETURN 0;
END;

GO

-- File: GetTransactionTypeUpdates.sql
﻿
CREATE PROCEDURE Integration.GetTransactionTypeUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) = '99991231 23:59:59.9999999';

    CREATE TABLE #TransactionTypeChanges
    (
        [WWI Transaction Type ID] int,
        [Transaction Type] nvarchar(50),
        [Valid From] datetime2(7),
        [Valid To] datetime2(7)
    );

    DECLARE @TransactionTypeID int;
    DECLARE @ValidFrom datetime2(7);

    -- need to find any Transaction Type changes that have occurred, including during the initial load

    DECLARE ChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT tt.TransactionTypeID,
           tt.ValidFrom
    FROM [Application].TransactionTypes_Archive AS tt
    WHERE tt.ValidFrom > @LastCutoff
    AND tt.ValidFrom <= @NewCutoff
    UNION ALL
    SELECT tt.TransactionTypeID,
           tt.ValidFrom
    FROM [Application].TransactionTypes AS tt
    WHERE tt.ValidFrom > @LastCutoff
    AND tt.ValidFrom <= @NewCutoff
    ORDER BY ValidFrom;

    OPEN ChangeList;
    FETCH NEXT FROM ChangeList INTO @TransactionTypeID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #TransactionTypeChanges
            ([WWI Transaction Type ID], [Transaction Type], [Valid From], [Valid To])
        SELECT p.TransactionTypeID, p.TransactionTypeName, p.ValidFrom, p.ValidTo
        FROM [Application].TransactionTypes FOR SYSTEM_TIME AS OF @ValidFrom AS p
        WHERE p.TransactionTypeID = @TransactionTypeID;

        FETCH NEXT FROM ChangeList INTO @TransactionTypeID, @ValidFrom;
    END;

    CLOSE ChangeList;
    DEALLOCATE ChangeList;

    -- add an index to make lookups faster

    CREATE INDEX IX_TransactionTypeChanges ON #TransactionTypeChanges ([WWI Transaction Type ID], [Valid From]);

    -- work out the [Valid To] value by taking the [Valid From] of any row that's for the same entry but later
    -- otherwise take the end of time

    UPDATE cc
    SET [Valid To] = COALESCE((SELECT MIN([Valid From]) FROM #TransactionTypeChanges AS cc2
                                                        WHERE cc2.[WWI Transaction Type ID] = cc.[WWI Transaction Type ID]
                                                        AND cc2.[Valid From] > cc.[Valid From]), @EndOfTime)
    FROM #TransactionTypeChanges AS cc;

    SELECT [WWI Transaction Type ID], [Transaction Type], [Valid From], [Valid To]
    FROM #TransactionTypeChanges
    ORDER BY [Valid From];

    DROP TABLE #TransactionTypeChanges;

    RETURN 0;
END;

GO

-- File: GetTransactionUpdates.sql
﻿
CREATE PROCEDURE Integration.GetTransactionUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT CAST(ct.TransactionDate AS date) AS [Date Key],
           ct.CustomerTransactionID AS [WWI Customer Transaction ID],
           CAST(NULL AS int) AS [WWI Supplier Transaction ID],
           ct.InvoiceID AS [WWI Invoice ID],
           CAST(NULL AS int) AS [WWI Purchase Order ID],
           CAST(NULL AS nvarchar(20)) AS [Supplier Invoice Number],
           ct.AmountExcludingTax AS [Total Excluding Tax],
           ct.TaxAmount AS [Tax Amount],
           ct.TransactionAmount AS [Total Including Tax],
           ct.OutstandingBalance AS [Outstanding Balance],
           ct.IsFinalized AS [Is Finalized],
           COALESCE(i.CustomerID, ct.CustomerID) AS [WWI Customer ID],
           ct.CustomerID AS [WWI Bill To Customer ID],
           CAST(NULL AS int) AS [WWI Supplier ID],
           ct.TransactionTypeID AS [WWI Transaction Type ID],
           ct.PaymentMethodID AS [WWI Payment Method ID],
           ct.LastEditedWhen AS [Last Modified When]
    FROM Sales.CustomerTransactions AS ct
    LEFT OUTER JOIN Sales.Invoices AS i
    ON ct.InvoiceID = i.InvoiceID
    WHERE ct.LastEditedWhen > @LastCutoff
    AND ct.LastEditedWhen <= @NewCutoff

    UNION ALL

    SELECT CAST(st.TransactionDate AS date) AS [Date Key],
           CAST(NULL AS int) AS [WWI Customer Transaction ID],
           st.SupplierTransactionID AS [WWI Supplier Transaction ID],
           CAST(NULL AS int) AS [WWI Invoice ID],
           st.PurchaseOrderID AS [WWI Purchase Order ID],
           st.SupplierInvoiceNumber AS [Supplier Invoice Number],
           st.AmountExcludingTax AS [Total Excluding Tax],
           st.TaxAmount AS [Tax Amount],
           st.TransactionAmount AS [Total Including Tax],
           st.OutstandingBalance AS [Outstanding Balance],
           st.IsFinalized AS [Is Finalized],
           CAST(NULL AS int) AS [WWI Customer ID],
           CAST(NULL AS int) AS [WWI Bill To Customer ID],
           st.SupplierID AS [WWI Supplier ID],
           st.TransactionTypeID AS [WWI Transaction Type ID],
           st.PaymentMethodID AS [WWI Payment Method ID],
           st.LastEditedWhen AS [Last Modified When]
    FROM Purchasing.SupplierTransactions AS st
    WHERE st.LastEditedWhen > @LastCutoff
    AND st.LastEditedWhen <= @NewCutoff;

    RETURN 0;
END;

GO

-- File: ReseedAllSequences.sql
﻿
CREATE PROCEDURE Sequences.ReseedAllSequences
AS BEGIN
    -- Ensures that the next sequence values are above the maximum value of the related table columns
    SET NOCOUNT ON;

    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'BuyingGroupID', @SchemaName = 'Sales', @TableName = 'BuyingGroups', @ColumnName = 'BuyingGroupID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'CityID', @SchemaName = 'Application', @TableName = 'Cities', @ColumnName = 'CityID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'ColorID', @SchemaName = 'Warehouse', @TableName = 'Colors', @ColumnName = 'ColorID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'CountryID', @SchemaName = 'Application', @TableName = 'Countries', @ColumnName = 'CountryID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'CustomerCategoryID', @SchemaName = 'Sales', @TableName = 'CustomerCategories', @ColumnName = 'CustomerCategoryID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'CustomerID', @SchemaName = 'Sales', @TableName = 'Customers', @ColumnName = 'CustomerID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'DeliveryMethodID', @SchemaName = 'Application', @TableName = 'DeliveryMethods', @ColumnName = 'DeliveryMethodID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'InvoiceID', @SchemaName = 'Sales', @TableName = 'Invoices', @ColumnName = 'InvoiceID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'InvoiceLineID', @SchemaName = 'Sales', @TableName = 'InvoiceLines', @ColumnName = 'InvoiceLineID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'OrderID', @SchemaName = 'Sales', @TableName = 'Orders', @ColumnName = 'OrderID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'OrderLineID', @SchemaName = 'Sales', @TableName = 'OrderLines', @ColumnName = 'OrderLineID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'PackageTypeID', @SchemaName = 'Warehouse', @TableName = 'PackageTypes', @ColumnName = 'PackageTypeID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'PaymentMethodID', @SchemaName = 'Application', @TableName = 'PaymentMethods', @ColumnName = 'PaymentMethodID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'PersonID', @SchemaName = 'Application', @TableName = 'People', @ColumnName = 'PersonID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'PurchaseOrderID', @SchemaName = 'Purchasing', @TableName = 'PurchaseOrders', @ColumnName = 'PurchaseOrderID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'PurchaseOrderLineID', @SchemaName = 'Purchasing', @TableName = 'PurchaseOrderLines', @ColumnName = 'PurchaseOrderLineID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'SpecialDealID', @SchemaName = 'Sales', @TableName = 'SpecialDeals', @ColumnName = 'SpecialDealID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'StateProvinceID', @SchemaName = 'Application', @TableName = 'StateProvinces', @ColumnName = 'StateProvinceID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'StockGroupID', @SchemaName = 'Warehouse', @TableName = 'StockGroups', @ColumnName = 'StockGroupID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'StockItemID', @SchemaName = 'Warehouse', @TableName = 'StockItems', @ColumnName = 'StockItemID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'StockItemStockGroupID', @SchemaName = 'Warehouse', @TableName = 'StockItemStockGroups', @ColumnName = 'StockItemStockGroupID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'SupplierCategoryID', @SchemaName = 'Purchasing', @TableName = 'SupplierCategories', @ColumnName = 'SupplierCategoryID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'SupplierID', @SchemaName = 'Purchasing', @TableName = 'Suppliers', @ColumnName = 'SupplierID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'SystemParameterID', @SchemaName = 'Application', @TableName = 'SystemParameters', @ColumnName = 'SystemParameterID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'TransactionID', @SchemaName = 'Purchasing', @TableName = 'SupplierTransactions', @ColumnName = 'SupplierTransactionID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'TransactionID', @SchemaName = 'Sales', @TableName = 'CustomerTransactions', @ColumnName = 'CustomerTransactionID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'TransactionID', @SchemaName = 'Warehouse', @TableName = 'StockItemTransactions', @ColumnName = 'StockItemTransactionID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'TransactionTypeID', @SchemaName = 'Application', @TableName = 'TransactionTypes', @ColumnName = 'TransactionTypeID';
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

-- File: DeleteBuyingGroup.sql
﻿CREATE PROCEDURE [WebApi].[DeleteBuyingGroup](@BuyingGroupID int)
WITH EXECUTE AS OWNER
AS BEGIN
	DELETE Sales.BuyingGroups
	WHERE BuyingGroupID = @BuyingGroupID
END
GO

-- File: DeleteCity.sql
﻿CREATE PROCEDURE [WebApi].[DeleteCity](@CityID int)
WITH EXECUTE AS OWNER
AS BEGIN
	DELETE Application.Cities
	WHERE CityID = @CityID
END
GO

-- File: DeleteColor.sql
﻿CREATE PROCEDURE [WebApi].[DeleteColor](@ColorID int)
WITH EXECUTE AS OWNER
AS BEGIN
	DELETE Warehouse.Colors
	WHERE ColorID = @ColorID
END
GO

-- File: DeleteCountry.sql
﻿CREATE PROCEDURE [WebApi].[DeleteCountry](@CountryID int)
WITH EXECUTE AS OWNER
AS BEGIN
	DELETE Application.Countries
	WHERE CountryID = @CountryID;
END
GO

-- File: DeleteCustomer.sql
﻿CREATE PROCEDURE [WebApi].[DeleteCustomer](@CustomerID int)
WITH EXECUTE AS OWNER
AS BEGIN
	DELETE Sales.Customers
	WHERE CustomerID = @CustomerID;
END
GO

-- File: DeleteCustomerCategory.sql
﻿CREATE PROCEDURE [WebApi].[DeleteCustomerCategory](@CustomerCategoryID int)
WITH EXECUTE AS OWNER
AS BEGIN
	DELETE Sales.CustomerCategories
	WHERE CustomerCategoryID = @CustomerCategoryID
END
GO

-- File: DeleteDeliveryMethod.sql
﻿CREATE PROCEDURE [WebApi].[DeleteDeliveryMethod](@DeliveryMethodID int)
WITH EXECUTE AS OWNER
AS BEGIN
	DELETE Application.DeliveryMethods
	WHERE DeliveryMethodID = @DeliveryMethodID
END
GO

-- File: DeletePackageType.sql
﻿CREATE PROCEDURE [WebApi].[DeletePackageType](@PackageTypeID int)
WITH EXECUTE AS OWNER
AS BEGIN
	DELETE Warehouse.PackageTypes
	WHERE PackageTypeID = @PackageTypeID
END
GO

-- File: DeletePaymentMethod.sql
﻿CREATE PROCEDURE [WebApi].[DeletePaymentMethod](@PaymentMethodID int)
WITH EXECUTE AS OWNER
AS BEGIN
	DELETE Application.PaymentMethods
	WHERE PaymentMethodID = @PaymentMethodID
END
GO

-- File: DeleteStateProvince.sql
﻿CREATE PROCEDURE [WebApi].[DeleteStateProvince](@StateProvinceID int)
WITH EXECUTE AS OWNER
AS BEGIN
	DELETE Application.StateProvinces
	WHERE StateProvinceID = @StateProvinceID;
END

GO

-- File: DeleteStockGroup.sql
﻿CREATE PROCEDURE [WebApi].[DeleteStockGroup](@StockGroupID int)
WITH EXECUTE AS OWNER
AS BEGIN
	DELETE Warehouse.StockGroups
	WHERE StockGroupID = @StockGroupID
END
GO

-- File: DeleteStockItem.sql
﻿CREATE PROCEDURE [WebApi].[DeleteStockItem](@StockItemID int)
WITH EXECUTE AS OWNER
AS BEGIN
	DELETE Warehouse.StockItems
	WHERE StockItemID = @StockItemID;
END
GO

-- File: DeleteSupplier.sql
﻿CREATE PROCEDURE [WebApi].[DeleteSupplier](@SupplierID int)
WITH EXECUTE AS OWNER
AS BEGIN
	DELETE Purchasing.Suppliers
	WHERE SupplierID = @SupplierID;
END
GO

-- File: DeleteSupplierCategory.sql
﻿CREATE PROCEDURE [WebApi].[DeleteSupplierCategory](@SupplierCategoryID int)
WITH EXECUTE AS OWNER
AS BEGIN
	DELETE Purchasing.SupplierCategories
	WHERE SupplierCategoryID = @SupplierCategoryID
END
GO

-- File: DeleteTransactionType.sql
﻿CREATE PROCEDURE [WebApi].[DeleteTransactionType](@TransactionTypeID int)
WITH EXECUTE AS OWNER
AS BEGIN
	DELETE Application.TransactionTypes
	WHERE TransactionTypeID = @TransactionTypeID
END
GO

-- File: InsertBuyingGroupsFromJson.sql
﻿CREATE PROCEDURE [WebApi].[InsertBuyingGroupsFromJson](@BuyingGroups NVARCHAR(MAX), @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	INSERT INTO Sales.BuyingGroups(BuyingGroupName,LastEditedBy)
			OUTPUT  inserted.BuyingGroupID
			SELECT BuyingGroupName,@UserID
			FROM OPENJSON(@BuyingGroups)
				WITH (BuyingGroupName nvarchar(50))
END
GO

-- File: InsertCitiesFromJson.sql
﻿CREATE PROCEDURE [WebApi].[InsertCitiesFromJson](@Cities NVARCHAR(MAX), @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	INSERT INTO Application.Cities(CityName,StateProvinceID,LatestRecordedPopulation,LastEditedBy)
			OUTPUT  inserted.CityID
			SELECT CityName,StateProvinceID,LatestRecordedPopulation,@UserID
			FROM OPENJSON(@Cities)
				WITH (
					CityName nvarchar(50) N'strict $.CityName',
					StateProvinceID int N'strict $.StateProvinceID',
					LatestRecordedPopulation bigint)
END
GO

-- File: InsertColorsFromJson.sql
﻿CREATE PROCEDURE [WebApi].[InsertColorsFromJson](@Colors NVARCHAR(MAX), @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	INSERT INTO Warehouse.Colors(ColorName,LastEditedBy)
			OUTPUT  inserted.ColorID
			SELECT ColorName,@UserID
			FROM OPENJSON(@Colors)
				WITH (ColorName nvarchar(50))
END
GO

-- File: InsertCountriesFromJson.sql
﻿CREATE PROCEDURE [WebApi].[InsertCountriesFromJson](@Countries NVARCHAR(MAX), @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	INSERT INTO Application.Countries(CountryName,FormalName,IsoAlpha3Code,IsoNumericCode,CountryType,LatestRecordedPopulation,Continent,Region,Subregion, LastEditedBy)
	OUTPUT  inserted.CountryID
	SELECT CountryName,FormalName,IsoAlpha3Code,IsoNumericCode,CountryType,LatestRecordedPopulation,Continent,Region,Subregion, @UserID
	FROM OPENJSON (@Countries)
		WITH (
			CountryName nvarchar(60) N'strict $.CountryName',
			FormalName nvarchar(60) N'strict $.FormalName',
			IsoAlpha3Code nvarchar(3),
			IsoNumericCode int,
			CountryType nvarchar(20),
			LatestRecordedPopulation bigint,
			Continent nvarchar(30) N'strict $.Continent',
			Region nvarchar(30) N'strict $.Region',
			Subregion nvarchar(30) N'strict $.Subregion')
END
GO

-- File: InsertCustomerCategoriesFromJson.sql
﻿CREATE PROCEDURE [WebApi].[InsertCustomerCategoriesFromJson](@CustomerCategories NVARCHAR(MAX), @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	INSERT INTO Sales.CustomerCategories(CustomerCategoryName,LastEditedBy)
			OUTPUT  inserted.CustomerCategoryID
			SELECT CustomerCategoryName,@UserID
			FROM OPENJSON(@CustomerCategories)
				WITH (CustomerCategoryName nvarchar(50))
END
GO

-- File: InsertCustomersFromJson.sql
﻿CREATE PROCEDURE [WebApi].[InsertCustomersFromJson](@Customers NVARCHAR(MAX), @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	INSERT INTO Sales.Customers(CustomerName,BillToCustomerID,CustomerCategoryID,BuyingGroupID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryMethodID,DeliveryCityID,PostalCityID,CreditLimit,AccountOpenedDate,StandardDiscountPercentage,IsStatementSent,IsOnCreditHold,PaymentDays,PhoneNumber,FaxNumber,DeliveryRun,RunPosition,WebsiteURL,DeliveryAddressLine1,DeliveryAddressLine2,DeliveryPostalCode,PostalAddressLine1,PostalAddressLine2,PostalPostalCode,LastEditedBy)
	OUTPUT  inserted.CustomerID
	SELECT CustomerName,BillToCustomerID,CustomerCategoryID,BuyingGroupID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryMethodID,DeliveryCityID,PostalCityID,CreditLimit,AccountOpenedDate,StandardDiscountPercentage,IsStatementSent,IsOnCreditHold,PaymentDays,PhoneNumber,FaxNumber,DeliveryRun,RunPosition,WebsiteURL,DeliveryAddressLine1,DeliveryAddressLine2,DeliveryPostalCode,PostalAddressLine1,PostalAddressLine2,PostalPostalCode,@UserID
	FROM OPENJSON (@Customers)
		WITH (
			CustomerName nvarchar(100) N'strict $.CustomerName',
			BillToCustomerID int N'strict $.BillToCustomerID',
			CustomerCategoryID int N'strict $.CustomerCategoryID',
			BuyingGroupID int,
			PrimaryContactPersonID int N'strict $.PrimaryContactPersonID',
			AlternateContactPersonID int,
			DeliveryMethodID int N'strict $.DeliveryMethodID',
			DeliveryCityID int N'strict $.DeliveryCityID',
			PostalCityID int N'strict $.PostalCityID',
			CreditLimit decimal(18,2),
			AccountOpenedDate date N'strict $.AccountOpenedDate',
			StandardDiscountPercentage decimal(18,3) N'strict $.StandardDiscountPercentage',
			IsStatementSent bit N'strict $.IsStatementSent',
			IsOnCreditHold bit N'strict $.IsOnCreditHold',
			PaymentDays int N'strict $.PaymentDays',
			PhoneNumber nvarchar(20) N'strict $.PhoneNumber',
			FaxNumber nvarchar(20) N'strict $.FaxNumber',
			DeliveryRun nvarchar(5),
			RunPosition nvarchar(5),
			WebsiteURL nvarchar(256) N'strict $.WebsiteURL',
			DeliveryAddressLine1 nvarchar(60) N'strict $.DeliveryAddressLine1',
			DeliveryAddressLine2 nvarchar(60),
			DeliveryPostalCode nvarchar(10) N'strict $.DeliveryPostalCode',
			PostalAddressLine1 nvarchar(60) N'strict $.PostalAddressLine1',
			PostalAddressLine2 nvarchar(60),
			PostalPostalCode nvarchar(10) N'strict $.PostalPostalCode')
END
GO

-- File: InsertDeliveryMethodsFromJson.sql
﻿CREATE PROCEDURE [WebApi].[InsertDeliveryMethodsFromJson](@DeliveryMethods NVARCHAR(MAX), @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	INSERT INTO Application.DeliveryMethods(DeliveryMethodName,LastEditedBy)
			OUTPUT  inserted.DeliveryMethodID
			SELECT DeliveryMethodName,@UserID
			FROM OPENJSON(@DeliveryMethods)
				WITH (DeliveryMethodName nvarchar(50))
END
GO

-- File: InsertPackageTypesFromJson.sql
﻿CREATE PROCEDURE [WebApi].[InsertPackageTypesFromJson](@PackageTypes NVARCHAR(MAX), @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	INSERT INTO Warehouse.PackageTypes(PackageTypeName,LastEditedBy)
			OUTPUT  inserted.PackageTypeID
			SELECT PackageTypeName,@UserID
			FROM OPENJSON(@PackageTypes)
				WITH (PackageTypeName nvarchar(50))
END
GO

-- File: InsertPaymentMethodsFromJson.sql
﻿CREATE PROCEDURE [WebApi].[InsertPaymentMethodsFromJson](@PaymentMethods NVARCHAR(MAX), @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	INSERT INTO Application.PaymentMethods(PaymentMethodName,LastEditedBy)
			OUTPUT  inserted.PaymentMethodID
			SELECT PaymentMethodName,@UserID
			FROM OPENJSON(@PaymentMethods)
				WITH (PaymentMethodName nvarchar(50))
END
GO

-- File: InsertStateProvincesFromJson.sql
﻿CREATE PROCEDURE [WebApi].[InsertStateProvincesFromJson](@StateProvinces NVARCHAR(MAX), @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	INSERT INTO Application.StateProvinces(StateProvinceCode,StateProvinceName,CountryID,SalesTerritory,LatestRecordedPopulation,LastEditedBy)
	OUTPUT  inserted.StateProvinceID
	SELECT StateProvinceCode,StateProvinceName,CountryID,SalesTerritory,LatestRecordedPopulation,@UserID
	FROM OPENJSON(@StateProvinces)
		WITH (
			StateProvinceCode nvarchar(5) N'strict $.StateProvinceCode',
			StateProvinceName nvarchar(50) N'strict $.StateProvinceName',
			CountryID int N'strict $.CountryID',
			SalesTerritory nvarchar(50) N'strict $.SalesTerritory',
			LatestRecordedPopulation bigint)
END
GO

-- File: InsertStockGroupsFromJson.sql
﻿CREATE PROCEDURE [WebApi].[InsertStockGroupsFromJson](@StockGroups NVARCHAR(MAX), @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	INSERT INTO Warehouse.StockGroups(StockGroupName,LastEditedBy)
			OUTPUT  inserted.StockGroupID
			SELECT StockGroupName,@UserID
			FROM OPENJSON(@StockGroups)
				WITH (StockGroupName nvarchar(50))
END
GO

-- File: InsertStockItemsFromJson.sql
﻿CREATE PROCEDURE [WebApi].[InsertStockItemsFromJson](@StockItems NVARCHAR(MAX),@UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	INSERT INTO Warehouse.StockItems(StockItemName,SupplierID,ColorID,UnitPackageID,OuterPackageID,Brand,Size,LeadTimeDays,QuantityPerOuter,IsChillerStock,Barcode,TaxRate,UnitPrice,RecommendedRetailPrice,TypicalWeightPerUnit,MarketingComments,InternalComments,Photo,CustomFields,LastEditedBy)
	OUTPUT inserted.StockItemID
	SELECT StockItemName,SupplierID,ColorID,UnitPackageID,OuterPackageID,Brand,Size,LeadTimeDays,QuantityPerOuter,IsChillerStock,Barcode,TaxRate,UnitPrice,RecommendedRetailPrice,TypicalWeightPerUnit,MarketingComments,InternalComments,Photo,CustomFields,@UserID
	FROM OPENJSON (@StockItems)
		WITH (
			StockItemName nvarchar(100) N'strict $.StockItemName',
			SupplierID int N'strict $.SupplierID',
			ColorID int,
			UnitPackageID int N'strict $.UnitPackageID',
			OuterPackageID int N'strict $.OuterPackageID',
			Brand nvarchar(50),
			Size nvarchar(20),
			LeadTimeDays int N'strict $.LeadTimeDays',
			QuantityPerOuter int N'strict $.QuantityPerOuter',
			IsChillerStock bit N'strict $.IsChillerStock',
			Barcode nvarchar(50),
			TaxRate decimal(18,3) N'strict $.TaxRate',
			UnitPrice decimal(18,2) N'strict $.UnitPrice',
			RecommendedRetailPrice decimal(18,2),
			TypicalWeightPerUnit decimal(18,3) N'strict $.TypicalWeightPerUnit',
			MarketingComments nvarchar(MAX),
			InternalComments nvarchar(MAX),
			Photo varbinary(MAX),
			CustomFields nvarchar(MAX) AS JSON)
END
GO

-- File: InsertSupplierCategoriesFromJson.sql
﻿CREATE PROCEDURE [WebApi].[InsertSupplierCategoriesFromJson](@SupplierCategories NVARCHAR(MAX), @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	INSERT INTO Purchasing.SupplierCategories(SupplierCategoryName,LastEditedBy)
			OUTPUT  inserted.SupplierCategoryID
			SELECT SupplierCategoryName,@UserID
			FROM OPENJSON(@SupplierCategories)
				WITH (SupplierCategoryName nvarchar(50))
END
GO

-- File: InsertSuppliersFromJson.sql
﻿CREATE PROCEDURE [WebApi].[InsertSuppliersFromJson](@Suppliers NVARCHAR(MAX), @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	INSERT INTO Purchasing.Suppliers(SupplierName,SupplierCategoryID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryMethodID,DeliveryCityID,PostalCityID,SupplierReference,BankAccountName,BankAccountBranch,BankAccountCode,BankAccountNumber,BankInternationalCode,PaymentDays,InternalComments,PhoneNumber,FaxNumber,WebsiteURL,DeliveryAddressLine1,DeliveryAddressLine2,DeliveryPostalCode,PostalAddressLine1,PostalAddressLine2,PostalPostalCode, LastEditedBy)
	OUTPUT  inserted.SupplierID
	SELECT SupplierName,SupplierCategoryID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryMethodID,DeliveryCityID,PostalCityID,SupplierReference,BankAccountName,BankAccountBranch,BankAccountCode,BankAccountNumber,BankInternationalCode,PaymentDays,InternalComments,PhoneNumber,FaxNumber,WebsiteURL,DeliveryAddressLine1,DeliveryAddressLine2,DeliveryPostalCode,PostalAddressLine1,PostalAddressLine2,PostalPostalCode, @UserID
	FROM OPENJSON (@Suppliers)
		WITH (
			SupplierName nvarchar(100) N'strict $.SupplierName',
			SupplierCategoryID int N'strict $.SupplierCategoryID',
			PrimaryContactPersonID int N'strict $.PrimaryContactPersonID',
			AlternateContactPersonID int N'strict $.AlternateContactPersonID',
			DeliveryMethodID int,
			DeliveryCityID int N'strict $.DeliveryCityID',
			PostalCityID int N'strict $.PostalCityID',
			SupplierReference nvarchar(20),
			BankAccountName nvarchar(50),
			BankAccountBranch nvarchar(50),
			BankAccountCode nvarchar(20),
			BankAccountNumber nvarchar(20),
			BankInternationalCode nvarchar(20),
			PaymentDays int N'strict $.PaymentDays',
			InternalComments nvarchar(MAX),
			PhoneNumber nvarchar(20) N'strict $.PhoneNumber',
			FaxNumber nvarchar(20) N'strict $.FaxNumber',
			WebsiteURL nvarchar(256) N'strict $.WebsiteURL',
			DeliveryAddressLine1 nvarchar(60) N'strict $.DeliveryAddressLine1',
			DeliveryAddressLine2 nvarchar(60),
			DeliveryPostalCode nvarchar(10) N'strict $.DeliveryPostalCode',
			PostalAddressLine1 nvarchar(60) N'strict $.PostalAddressLine1',
			PostalAddressLine2 nvarchar(60),
			PostalPostalCode nvarchar(10) N'strict $.PostalPostalCode')
END
GO
GO

-- File: InsertTransactionTypesFromJson.sql
﻿CREATE PROCEDURE [WebApi].[InsertTransactionTypesFromJson](@TransactionTypes NVARCHAR(MAX), @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	INSERT INTO Application.TransactionTypes(TransactionTypeName,LastEditedBy)
			OUTPUT  inserted.TransactionTypeID
			SELECT TransactionTypeName,@UserID
			FROM OPENJSON(@TransactionTypes)
				WITH (TransactionTypeName nvarchar(50))
END
GO

-- File: Login.sql
﻿CREATE PROCEDURE [WebApi].[Login](@LogonName nvarchar(256), @Password nvarchar(256))
WITH EXECUTE AS OWNER
AS BEGIN
	select  PersonID, PreferredName, IsSalesperson, IsEmployee,
        Territory = JSON_VALUE(CustomFields,'$.PrimarySalesTerritory')
	from Application.People
	where IsPermittedToLogon = 1
	and LogonName = @LogonName
	--and HashedPassword = HASHBYTES(N'SHA2_256', @Password)",
END
GO

-- File: SearchForStockItems.sql
﻿CREATE PROCEDURE [WebApi].[SearchForStockItems]
@Name nvarchar(100),
@Tag nvarchar(100),
@MinPrice decimal(18,2),
@MaxPrice decimal(18,2),
@StockGroupID int,
@MaximumRowsToReturn int
WITH EXECUTE AS OWNER
AS
BEGIN
    WITH value AS
	(SELECT
           si.StockItemID,
           si.StockItemName,
		   si.Brand,
		   si.ColorName,
		   si.UnitPrice,
		   si.TaxRate,
		   si.Size,
		   si.MarketingComments,
		   si.CustomFields
    FROM WebApi.StockItems AS si
    WHERE (@Name IS NULL OR si.StockItemName LIKE ('%' + @Name + '%'))
	AND (@MinPrice IS NULL OR si.UnitPrice > @MinPrice)
	AND (@MaxPrice IS NULL OR si.UnitPrice < @MaxPrice)
	)
	SELECT
		value = (SELECT TOP(@MaximumRowsToReturn) v.StockItemID,v.StockItemName,v.Brand,v.ColorName,v.UnitPrice,v.TaxRate,v.Size,v.MarketingComments
					FROM value v
					WHERE (@Tag IS NULL OR EXISTS (SELECT * FROM OPENJSON (CustomFields, '$.Tags') WITH (Tag nvarchar(20) '$') WHERE Tag = @Tag) )
					AND (@StockGroupID IS NULL OR EXISTS (SELECT * FROM Warehouse.StockItemStockGroups sisg WHERE sisg.StockItemID = StockItemID AND sisg.StockGroupID = @StockGroupID) )
				FOR JSON PATH),
		tags = (SELECT Tag, Items = COUNT(*)
					FROM value
						CROSS APPLY OPENJSON (CustomFields, '$.Tags')
									 WITH (Tag NVARCHAR(20) '$')
				GROUP BY Tag
				FOR JSON PATH)
	FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
END;
GO



GO

-- File: UpdateBuyingGroupFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdateBuyingGroupFromJson](@BuyingGroup NVARCHAR(MAX), @BuyingGroupID int,@UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Sales.BuyingGroups SET
		BuyingGroupName = json.BuyingGroupName,
		LastEditedBy = @UserID
	FROM OPENJSON (@BuyingGroup)
		WITH (BuyingGroupName nvarchar(50)) as json
	WHERE
		Sales.BuyingGroups.BuyingGroupID = @BuyingGroupID
END
GO

-- File: UpdateCityFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdateCityFromJson](@City NVARCHAR(MAX), @CityID int,@UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Application.Cities SET
		CityName = json.CityName,
		StateProvinceID = json.StateProvinceID,
		LatestRecordedPopulation = json.LatestRecordedPopulation,
		LastEditedBy = @UserID
	FROM OPENJSON (@City)
		WITH (
			CityName nvarchar(50) N'strict $.CityName',
			StateProvinceID int N'strict $.StateProvinceID',
			LatestRecordedPopulation bigint) as json
	WHERE
		Application.Cities.CityID = @CityID

END
GO

-- File: UpdateColorFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdateColorFromJson](@Color NVARCHAR(MAX), @ColorID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Warehouse.Colors SET
		ColorName = json.ColorName,
		LastEditedBy = @UserID
	FROM OPENJSON (@Color)
		WITH (ColorName nvarchar(50)) as json
	WHERE
		Warehouse.Colors.ColorID = @ColorID

END
GO

-- File: UpdateCountryFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdateCountryFromJson](@Country NVARCHAR(MAX), @CountryID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN	UPDATE Application.Countries SET
				CountryName = json.CountryName,
				FormalName = json.FormalName,
				IsoAlpha3Code = json.IsoAlpha3Code,
				IsoNumericCode = json.IsoNumericCode,
				CountryType = json.CountryType,
				LatestRecordedPopulation = json.LatestRecordedPopulation,
				Continent = json.Continent,
				Region = json.Region,
				Subregion = json.Subregion,
				LastEditedBy = @UserID
			FROM OPENJSON (@Country)
				WITH (
					CountryName nvarchar(60) N'strict $.CountryName',
					FormalName nvarchar(60) N'strict $.FormalName',
					IsoAlpha3Code nvarchar(3),
					IsoNumericCode int,
					CountryType nvarchar(20),
					LatestRecordedPopulation bigint,
					Continent nvarchar(30) N'strict $.Continent',
					Region nvarchar(30) N'strict $.Region',
					Subregion nvarchar(30) N'strict $.Subregion') as json
			WHERE
				Application.Countries.CountryID = @CountryID
END
GO

-- File: UpdateCustomerCategoryFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdateCustomerCategoryFromJson](@CustomerCategory NVARCHAR(MAX), @CustomerCategoryID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Sales.CustomerCategories SET
		CustomerCategoryName = json.CustomerCategoryName,
		LastEditedBy = @UserID
	FROM OPENJSON (@CustomerCategory)
		WITH (CustomerCategoryName nvarchar(50)) as json
	WHERE
		Sales.CustomerCategories.CustomerCategoryID = @CustomerCategoryID
END
GO

-- File: UpdateCustomerFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdateCustomerFromJson](@Customer NVARCHAR(MAX), @CustomerID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Sales.Customers SET
		CustomerName = ISNULL(json.CustomerName, Sales.Customers.CustomerName),
		BillToCustomerID = ISNULL(json.BillToCustomerID, Sales.Customers.BillToCustomerID),
		CustomerCategoryID = ISNULL(json.CustomerCategoryID, Sales.Customers.CustomerCategoryID),
		BuyingGroupID = json.BuyingGroupID,
		PrimaryContactPersonID = ISNULL(json.PrimaryContactPersonID, Sales.Customers.PrimaryContactPersonID),
		AlternateContactPersonID = ISNULL(json.AlternateContactPersonID, Sales.Customers.AlternateContactPersonID),
		DeliveryMethodID = ISNULL(json.DeliveryMethodID, Sales.Customers.DeliveryMethodID),
		DeliveryCityID = ISNULL(json.DeliveryCityID, Sales.Customers.DeliveryCityID),
		PostalCityID = ISNULL(json.PostalCityID, Sales.Customers.PostalCityID),
		CreditLimit = json.CreditLimit,
		AccountOpenedDate = ISNULL(json.AccountOpenedDate, Sales.Customers.AccountOpenedDate),
		StandardDiscountPercentage = ISNULL(json.StandardDiscountPercentage, Sales.Customers.StandardDiscountPercentage),
		IsStatementSent = ISNULL(json.IsStatementSent, Sales.Customers.IsStatementSent),
		IsOnCreditHold = ISNULL(json.IsOnCreditHold, Sales.Customers.IsOnCreditHold),
		PaymentDays = ISNULL(json.PaymentDays, Sales.Customers.PaymentDays),
		PhoneNumber = ISNULL(json.PhoneNumber, Sales.Customers.PhoneNumber),
		FaxNumber = ISNULL(json.FaxNumber, Sales.Customers.FaxNumber),
		DeliveryRun = json.DeliveryRun,
		RunPosition = json.RunPosition,
		WebsiteURL = ISNULL(json.WebsiteURL, Sales.Customers.WebsiteURL),
		DeliveryAddressLine1 = ISNULL(json.DeliveryAddressLine1, Sales.Customers.DeliveryAddressLine1),
		DeliveryAddressLine2 = json.DeliveryAddressLine2,
		DeliveryPostalCode = ISNULL(json.DeliveryPostalCode, Sales.Customers.DeliveryPostalCode),
		PostalAddressLine1 = ISNULL(json.PostalAddressLine1, Sales.Customers.PostalAddressLine1),
		PostalAddressLine2 = json.PostalAddressLine2,
		PostalPostalCode = ISNULL(json.PostalPostalCode, Sales.Customers.PostalPostalCode),
		LastEditedBy = @UserID
	FROM OPENJSON(@Customer)
		WITH (
			CustomerName nvarchar(100),
			BillToCustomerID int,
			CustomerCategoryID int,
			BuyingGroupID int,
			PrimaryContactPersonID int,
			AlternateContactPersonID int,
			DeliveryMethodID int,
			DeliveryCityID int,
			PostalCityID int,
			CreditLimit decimal(18,2),
			AccountOpenedDate date,
			StandardDiscountPercentage decimal(18,3),
			IsStatementSent bit,
			IsOnCreditHold bit,
			PaymentDays int,
			PhoneNumber nvarchar(20),
			FaxNumber nvarchar(20),
			DeliveryRun nvarchar(5),
			RunPosition nvarchar(5),
			WebsiteURL nvarchar(256),
			DeliveryAddressLine1 nvarchar(60),
			DeliveryAddressLine2 nvarchar(60),
			DeliveryPostalCode nvarchar(10),
			PostalAddressLine1 nvarchar(60),
			PostalAddressLine2 nvarchar(60),
			PostalPostalCode nvarchar(10)) as json
	WHERE
		Sales.Customers.CustomerID = @CustomerID
END
GO

-- File: UpdateCustomerTransactionFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdateCustomerTransactionFromJson](@CustomerTransaction NVARCHAR(MAX), @CustomerTransactionID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Sales.CustomerTransactions SET
			TransactionTypeID = ISNULL(json.TransactionTypeID, Sales.CustomerTransactions.TransactionTypeID),
			PaymentMethodID = json.PaymentMethodID,
			TransactionDate = ISNULL(json.TransactionDate, Sales.CustomerTransactions.TransactionDate),
			AmountExcludingTax = ISNULL(json.AmountExcludingTax, Sales.CustomerTransactions.AmountExcludingTax),
			TaxAmount = ISNULL(json.TaxAmount, Sales.CustomerTransactions.TaxAmount),
			TransactionAmount = ISNULL(json.TransactionAmount, Sales.CustomerTransactions.TransactionAmount),
			OutstandingBalance = ISNULL(json.OutstandingBalance, Sales.CustomerTransactions.OutstandingBalance),
			FinalizationDate = json.FinalizationDate,
			LastEditedBy = @UserID
		FROM OPENJSON(@CustomerTransaction)
			WITH (
				TransactionTypeID int,
				PaymentMethodID int,
				TransactionDate date,
				FinalizationDate date,
				AmountExcludingTax decimal(18,2),
				TaxAmount decimal(18,2),
				TransactionAmount decimal(18,2),
				OutstandingBalance decimal(18,2)
				) as json
		WHERE
			Sales.CustomerTransactions.CustomerTransactionID = @CustomerTransactionID

END
GO

-- File: UpdateDeliveryMethodFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdateDeliveryMethodFromJson](@DeliveryMethod NVARCHAR(MAX), @DeliveryMethodID int,@UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Application.DeliveryMethods SET
		DeliveryMethodName = json.DeliveryMethodName,
		LastEditedBy = @UserID
	FROM OPENJSON (@DeliveryMethod)
		WITH (DeliveryMethodName nvarchar(50)) as json
	WHERE
		Application.DeliveryMethods.DeliveryMethodID = @DeliveryMethodID

END
GO

-- File: UpdateInvoiceFromJson.sql
﻿CREATE PROCEDURE [WebApi].UpdateInvoiceFromJson(@Invoice NVARCHAR(MAX), @InvoiceID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN	UPDATE Sales.Invoices SET
				CustomerID = ISNULL(json.CustomerID, Sales.Invoices.CustomerID),
				BillToCustomerID = ISNULL(json.BillToCustomerID, Sales.Invoices.BillToCustomerID),
				DeliveryMethodID = ISNULL(json.DeliveryMethodID, Sales.Invoices.DeliveryMethodID),
				ContactPersonID = ISNULL(json.ContactPersonID, Sales.Invoices.ContactPersonID),
				AccountsPersonID = ISNULL(json.AccountsPersonID, Sales.Invoices.AccountsPersonID),
				SalespersonPersonID = ISNULL(json.SalespersonPersonID, Sales.Invoices.SalespersonPersonID),
				PackedByPersonID = ISNULL(json.PackedByPersonID, Sales.Invoices.PackedByPersonID),
				InvoiceDate = ISNULL(json.InvoiceDate, Sales.Invoices.InvoiceDate),
				CustomerPurchaseOrderNumber = json.CustomerPurchaseOrderNumber,
				IsCreditNote = ISNULL(json.IsCreditNote, Sales.Invoices.IsCreditNote),
				TotalDryItems = ISNULL(json.TotalDryItems, Sales.Invoices.TotalDryItems),
				TotalChillerItems = ISNULL(json.TotalChillerItems, Sales.Invoices.TotalChillerItems),
				DeliveryRun = json.DeliveryRun,
				RunPosition = json.RunPosition,
				LastEditedBy = @UserID
			FROM OPENJSON(@Invoice)
				WITH (
					CustomerID int,
					BillToCustomerID int,
					OrderID int,
					DeliveryMethodID int,
					ContactPersonID int,
					AccountsPersonID int,
					SalespersonPersonID int,
					PackedByPersonID int,
					InvoiceDate date,
					CustomerPurchaseOrderNumber nvarchar(20),
					IsCreditNote bit,
					TotalDryItems int,
					TotalChillerItems int,
					DeliveryRun nvarchar(5),
					RunPosition nvarchar(5)) as json
			WHERE
				Sales.Invoices.InvoiceID = @InvoiceID

END
GO

-- File: UpdatePackageTypeFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdatePackageTypeFromJson](@PackageType NVARCHAR(MAX), @PackageTypeID int,@UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Warehouse.PackageTypes SET
		PackageTypeName = json.PackageTypeName,
		LastEditedBy = @UserID
	FROM OPENJSON (@PackageType)
		WITH (PackageTypeName nvarchar(50)) as json
	WHERE
		Warehouse.PackageTypes.PackageTypeID = @PackageTypeID

END
GO

-- File: UpdatePaymentMethodFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdatePaymentMethodFromJson](@PaymentMethod NVARCHAR(MAX), @PaymentMethodID int,@UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Application.PaymentMethods SET
		PaymentMethodName = json.PaymentMethodName,
		LastEditedBy = @UserID
	FROM OPENJSON (@PaymentMethod)
		WITH (PaymentMethodName nvarchar(50)) as json
	WHERE
		Application.PaymentMethods.PaymentMethodID = @PaymentMethodID

END
GO

-- File: UpdatePurchaseOrderFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdatePurchaseOrderFromJson](@PurchaseOrder NVARCHAR(MAX), @PurchaseOrderID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN	UPDATE Purchasing.PurchaseOrders SET
				SupplierID = ISNULL(json.SupplierID, Purchasing.PurchaseOrders.SupplierID),
				OrderDate = ISNULL(json.OrderDate,Purchasing.PurchaseOrders.OrderDate),
				DeliveryMethodID = ISNULL(json.DeliveryMethodID,Purchasing.PurchaseOrders.DeliveryMethodID),
				ContactPersonID = ISNULL(json.ContactPersonID,Purchasing.PurchaseOrders.ContactPersonID),
				ExpectedDeliveryDate = json.ExpectedDeliveryDate,
				SupplierReference = json.SupplierReference,
				IsOrderFinalized = ISNULL(json.IsOrderFinalized,Purchasing.PurchaseOrders.IsOrderFinalized)
			FROM OPENJSON(@PurchaseOrder)
				WITH (
					SupplierID int,
					OrderDate date,
					DeliveryMethodID int,
					ContactPersonID int,
					ExpectedDeliveryDate date,
					SupplierReference nvarchar(20),
					IsOrderFinalized bit) as json
			WHERE
				Purchasing.PurchaseOrders.PurchaseOrderID = @PurchaseOrderID

END
GO

-- File: UpdateSalesOrderFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdateSalesOrderFromJson](@SalesOrder NVARCHAR(MAX), @SalesOrderID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN	UPDATE Sales.Orders SET
				SalespersonPersonID = ISNULL(json.SalespersonPersonID,Sales.Orders.SalespersonPersonID),
				PickedByPersonID = ISNULL(json.PickedByPersonID,Sales.Orders.PickedByPersonID),
				ContactPersonID = ISNULL(json.ContactPersonID,Sales.Orders.ContactPersonID),
				BackorderOrderID = ISNULL(json.BackorderOrderID,Sales.Orders.BackorderOrderID),
				OrderDate = ISNULL(json.OrderDate,Sales.Orders.OrderDate),
				ExpectedDeliveryDate = ISNULL(json.ExpectedDeliveryDate,Sales.Orders.ExpectedDeliveryDate),
				CustomerPurchaseOrderNumber = ISNULL(json.CustomerPurchaseOrderNumber,Sales.Orders.CustomerPurchaseOrderNumber),
				IsUndersupplyBackordered = ISNULL(json.IsUndersupplyBackordered,Sales.Orders.IsUndersupplyBackordered),
				PickingCompletedWhen = ISNULL(json.PickingCompletedWhen,Sales.Orders.PickingCompletedWhen),
				LastEditedBy = @UserID
			FROM OPENJSON(@SalesOrder)
				WITH (
					SalespersonPersonID int,
					PickedByPersonID int,
					ContactPersonID int,
					BackorderOrderID int,
					OrderDate date,
					ExpectedDeliveryDate date,
					CustomerPurchaseOrderNumber nvarchar(20),
					IsUndersupplyBackordered bit,
					PickingCompletedWhen date) as json
			WHERE
				Sales.Orders.OrderID = @SalesOrderID

END
GO

-- File: UpdateSpecialDealFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdateSpecialDealFromJson](@SpecialDeal NVARCHAR(MAX), @SpecialDealID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN	UPDATE Sales.SpecialDeals SET
				StockItemID = json.StockItemID,
				CustomerID = json.CustomerID,
				BuyingGroupID = json.BuyingGroupID,
				CustomerCategoryID = json.CustomerCategoryID,
				StockGroupID = json.StockGroupID,
				DealDescription = ISNULL(json.DealDescription,Sales.SpecialDeals.DealDescription),
				StartDate = ISNULL(json.StartDate,Sales.SpecialDeals.StartDate),
				EndDate = ISNULL(json.EndDate,Sales.SpecialDeals.EndDate),
				DiscountAmount = json.DiscountAmount,
				DiscountPercentage = json.DiscountPercentage,
				UnitPrice = json.UnitPrice,
				LastEditedBy = @UserID
			FROM OPENJSON(@SpecialDeal)
				WITH (
					StockItemID int,
					CustomerID int,
					BuyingGroupID int,
					CustomerCategoryID int,
					StockGroupID int,
					DealDescription nvarchar(30),
					StartDate date,
					EndDate date,
					DiscountAmount decimal(18,2),
					DiscountPercentage decimal(18,3),
					UnitPrice decimal(18,2)) as json
			WHERE
				Sales.SpecialDeals.SpecialDealID = @SpecialDealID

END
GO

-- File: UpdateStateProvinceFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdateStateProvinceFromJson](@StateProvince NVARCHAR(MAX), @StateProvinceID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE	Application.StateProvinces SET
			StateProvinceCode = json.StateProvinceCode,
			StateProvinceName = json.StateProvinceName,
			CountryID = json.CountryID,
			SalesTerritory = json.SalesTerritory,
			LatestRecordedPopulation = json.LatestRecordedPopulation,
			LastEditedBy = @UserID
		FROM OPENJSON (@StateProvince)
			WITH (
				StateProvinceCode nvarchar(5) N'strict $.StateProvinceCode',
				StateProvinceName nvarchar(50) N'strict $.StateProvinceName',
				CountryID int N'strict $.CountryID',
				SalesTerritory nvarchar(50) N'strict $.SalesTerritory',
				LatestRecordedPopulation bigint) as json
		WHERE
			Application.StateProvinces.StateProvinceID = @StateProvinceID

END
GO

-- File: UpdateStockGroupFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdateStockGroupFromJson](@StockGroup NVARCHAR(MAX), @StockGroupID int,@UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Warehouse.StockGroups SET
		StockGroupName = json.StockGroupName,
		LastEditedBy = @UserID
	FROM OPENJSON (@StockGroup)
		WITH (StockGroupName nvarchar(50)) as json
	WHERE
		Warehouse.StockGroups.StockGroupID = @StockGroupID

END
GO

-- File: UpdateStockItemFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdateStockItemFromJson](@StockItem NVARCHAR(MAX), @StockItemID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	
	UPDATE Warehouse.StockItems SET
		StockItemName = ISNULL(json.StockItemName, Warehouse.StockItems.StockItemName),
		SupplierID = ISNULL(json.SupplierID, Warehouse.StockItems.SupplierID),
		ColorID = json.ColorID,
		UnitPackageID = ISNULL(json.UnitPackageID, Warehouse.StockItems.UnitPackageID),
		OuterPackageID = ISNULL(json.OuterPackageID, Warehouse.StockItems.OuterPackageID),
		Brand = json.Brand,
		Size = json.Size,
		LeadTimeDays = ISNULL(json.LeadTimeDays, Warehouse.StockItems.LeadTimeDays),
		QuantityPerOuter = ISNULL(json.QuantityPerOuter, Warehouse.StockItems.QuantityPerOuter),
		IsChillerStock = ISNULL(json.IsChillerStock, Warehouse.StockItems.IsChillerStock),
		Barcode = json.Barcode,
		TaxRate = ISNULL(json.TaxRate, Warehouse.StockItems.TaxRate),
		UnitPrice = ISNULL(json.UnitPrice, Warehouse.StockItems.UnitPrice),
		RecommendedRetailPrice = json.RecommendedRetailPrice,
		TypicalWeightPerUnit = ISNULL(json.TypicalWeightPerUnit, Warehouse.StockItems.TypicalWeightPerUnit),
		MarketingComments = json.MarketingComments,
		InternalComments = json.InternalComments,
		Photo = json.Photo,
		CustomFields = json.CustomFields,
		LastEditedBy = @UserID
	FROM OPENJSON (@StockItem)
		WITH (
			StockItemName nvarchar(100),
			SupplierID int,
			ColorID int,
			UnitPackageID int,
			OuterPackageID int,
			Brand nvarchar(50),
			Size nvarchar(20),
			LeadTimeDays int,
			QuantityPerOuter int,
			IsChillerStock bit,
			Barcode nvarchar(50),
			TaxRate decimal(18,3),
			UnitPrice decimal(18,2),
			RecommendedRetailPrice decimal(18,2),
			TypicalWeightPerUnit decimal(18,3),
			MarketingComments nvarchar(MAX),
			InternalComments nvarchar(MAX),
			Photo varbinary(MAX),
			CustomFields nvarchar(MAX) AS JSON) as json
	WHERE
		Warehouse.StockItems.StockItemID = @StockItemID

END
GO

-- File: UpdateSupplierCategoryFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdateSupplierCategoryFromJson](@SupplierCategory NVARCHAR(MAX), @SupplierCategoryID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Purchasing.SupplierCategories SET
		SupplierCategoryName = json.SupplierCategoryName,
		LastEditedBy = @UserID
	FROM OPENJSON (@SupplierCategory)
		WITH (SupplierCategoryName nvarchar(50)) as json
	WHERE
		Purchasing.SupplierCategories.SupplierCategoryID = @SupplierCategoryID

END
GO

-- File: UpdateSupplierFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdateSupplierFromJson](@Supplier NVARCHAR(MAX), @SupplierID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Purchasing.Suppliers SET
		SupplierName = ISNULL(json.SupplierName, Purchasing.Suppliers.SupplierName),
		SupplierCategoryID = ISNULL(json.SupplierCategoryID, Purchasing.Suppliers.SupplierCategoryID),
		PrimaryContactPersonID = ISNULL(json.PrimaryContactPersonID, Purchasing.Suppliers.PrimaryContactPersonID),
		AlternateContactPersonID = ISNULL(json.AlternateContactPersonID, Purchasing.Suppliers.AlternateContactPersonID),
		DeliveryMethodID = json.DeliveryMethodID,
		DeliveryCityID = ISNULL(json.DeliveryCityID, Purchasing.Suppliers.DeliveryCityID),
		PostalCityID = ISNULL(json.PostalCityID, Purchasing.Suppliers.PostalCityID),
		SupplierReference = json.SupplierReference,
		BankAccountName = ISNULL(json.BankAccountName, Purchasing.Suppliers.BankAccountName),
		BankAccountBranch = ISNULL(json.BankAccountBranch, Purchasing.Suppliers.BankAccountBranch),
		BankAccountCode = ISNULL(json.BankAccountCode, Purchasing.Suppliers.BankAccountCode),
		BankAccountNumber = ISNULL(json.BankAccountNumber, Purchasing.Suppliers.BankAccountNumber),
		BankInternationalCode = json.BankInternationalCode,
		PaymentDays = ISNULL(json.PaymentDays, Purchasing.Suppliers.PaymentDays),
		InternalComments = ISNULL(json.InternalComments, Purchasing.Suppliers.InternalComments),
		PhoneNumber = ISNULL(json.PhoneNumber, Purchasing.Suppliers.PhoneNumber),
		FaxNumber = ISNULL(json.FaxNumber, Purchasing.Suppliers.FaxNumber),
		WebsiteURL = ISNULL(json.WebsiteURL, Purchasing.Suppliers.WebsiteURL),
		DeliveryAddressLine1 = ISNULL(json.DeliveryAddressLine1, Purchasing.Suppliers.DeliveryAddressLine1),
		DeliveryAddressLine2 = ISNULL(json.DeliveryAddressLine2, Purchasing.Suppliers.DeliveryAddressLine2),
		DeliveryPostalCode = ISNULL(json.DeliveryPostalCode, Purchasing.Suppliers.DeliveryPostalCode),
		PostalAddressLine1 = ISNULL(json.PostalAddressLine1, Purchasing.Suppliers.PostalAddressLine1),
		PostalAddressLine2 = ISNULL(json.PostalAddressLine2, Purchasing.Suppliers.PostalAddressLine2),
		PostalPostalCode = ISNULL(json.PostalPostalCode, Purchasing.Suppliers.PostalPostalCode),
		LastEditedBy = @UserID
	FROM OPENJSON (@Supplier)
		WITH (
			SupplierName nvarchar(100),
			SupplierCategoryID int,
			PrimaryContactPersonID int,
			AlternateContactPersonID int,
			DeliveryMethodID int,
			DeliveryCityID int,
			PostalCityID int,
			SupplierReference nvarchar(20),
			BankAccountName nvarchar(50),
			BankAccountBranch nvarchar(50),
			BankAccountCode nvarchar(20),
			BankAccountNumber nvarchar(20),
			BankInternationalCode nvarchar(20),
			PaymentDays int,
			InternalComments nvarchar(MAX),
			PhoneNumber nvarchar(20),
			FaxNumber nvarchar(20),
			WebsiteURL nvarchar(256),
			DeliveryAddressLine1 nvarchar(60),
			DeliveryAddressLine2 nvarchar(60),
			DeliveryPostalCode nvarchar(10),
			PostalAddressLine1 nvarchar(60),
			PostalAddressLine2 nvarchar(60),
			PostalPostalCode nvarchar(10)) as json
	WHERE
		Purchasing.Suppliers.SupplierID = @SupplierID

END
GO

-- File: UpdateSupplierTransactionFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdateSupplierTransactionFromJson](@SupplierTransaction NVARCHAR(MAX), @SupplierTransactionID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Purchasing.SupplierTransactions SET
			SupplierID = ISNULL(json.SupplierID,Purchasing.SupplierTransactions.SupplierID),
			TransactionTypeID = ISNULL(json.TransactionTypeID,Purchasing.SupplierTransactions.TransactionTypeID),
			PurchaseOrderID = json.PurchaseOrderID,
			PaymentMethodID = json.PaymentMethodID,
			SupplierInvoiceNumber = ISNULL(json.SupplierInvoiceNumber,Purchasing.SupplierTransactions.SupplierInvoiceNumber),
			TransactionDate = ISNULL(json.TransactionDate,Purchasing.SupplierTransactions.TransactionDate),
			AmountExcludingTax = ISNULL(json.AmountExcludingTax,Purchasing.SupplierTransactions.AmountExcludingTax),
			TaxAmount = ISNULL(json.TaxAmount,Purchasing.SupplierTransactions.TaxAmount),
			TransactionAmount = ISNULL(json.TransactionAmount,Purchasing.SupplierTransactions.TransactionAmount),
			OutstandingBalance = ISNULL(json.OutstandingBalance,Purchasing.SupplierTransactions.OutstandingBalance),
			FinalizationDate = ISNULL(json.FinalizationDate,Purchasing.SupplierTransactions.FinalizationDate),
			LastEditedBy = @UserID
		FROM OPENJSON(@SupplierTransaction)
			WITH (
				SupplierID int,
				TransactionTypeID int,
				PurchaseOrderID int,
				PaymentMethodID int,
				SupplierInvoiceNumber nvarchar(20),
				TransactionDate date,
				AmountExcludingTax decimal(18,2),
				TaxAmount decimal(18,2),
				TransactionAmount decimal(18,2),
				OutstandingBalance decimal(18,2),
				FinalizationDate date) as json
		WHERE
			Purchasing.SupplierTransactions.SupplierTransactionID = @SupplierTransactionID

END
GO

-- File: UpdateTransactionTypeFromJson.sql
﻿CREATE PROCEDURE [WebApi].[UpdateTransactionTypeFromJson](@TransactionType NVARCHAR(MAX), @TransactionTypeID int,@UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Application.TransactionTypes SET
		TransactionTypeName = json.TransactionTypeName,
		LastEditedBy = @UserID
	FROM OPENJSON (@TransactionType)
		WITH (TransactionTypeName nvarchar(50)) as json
	WHERE
		Application.TransactionTypes.TransactionTypeID = @TransactionTypeID

END
GO

-- File: ActivateWebsiteLogon.sql
﻿
CREATE PROCEDURE Website.ActivateWebsiteLogon
@PersonID int,
@LogonName nvarchar(50),
@InitialPassword nvarchar(40)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    UPDATE [Application].People
    SET IsPermittedToLogon = 1,
        LogonName = @LogonName,
        HashedPassword = HASHBYTES(N'SHA2_256', @InitialPassword + FullName),
        UserPreferences = (SELECT UserPreferences FROM [Application].People WHERE PersonID = 1) -- Person 1 has User Preferences template
    WHERE PersonID = @PersonID
    AND PersonID <> 1
    AND IsPermittedToLogon = 0;

    IF @@ROWCOUNT = 0
    BEGIN
        PRINT N'The PersonID must be valid, must not be person 1, and must not already be enabled';
        THROW 51000, N'Invalid PersonID', 1;
        RETURN -1;
    END;
END;

GO

-- File: ChangePassword.sql
﻿
CREATE PROCEDURE Website.ChangePassword
@PersonID int,
@OldPassword nvarchar(40),
@NewPassword nvarchar(40)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    UPDATE [Application].People
    SET IsPermittedToLogon = 1,
        HashedPassword = HASHBYTES(N'SHA2_256', @NewPassword + FullName)
    WHERE PersonID = @PersonID
    AND PersonID <> 1
    AND HashedPassword = HASHBYTES(N'SHA2_256', @OldPassword + FullName);

    IF @@ROWCOUNT = 0
    BEGIN
        PRINT N'The PersonID must be valid, and the old password must be valid.';
        PRINT N'If the user has also changed name, please contact the IT staff to assist.';
        THROW 51000, N'Invalid Password Change', 1;
        RETURN -1;
    END;
END;

GO

-- File: InsertCustomerOrders.sql
﻿
CREATE PROCEDURE Website.InsertCustomerOrders
@Orders Website.OrderList READONLY,
@OrderLines Website.OrderLineList READONLY,
@OrdersCreatedByPersonID int,
@SalespersonPersonID int
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OrdersToGenerate AS TABLE
    (
        OrderReference int PRIMARY KEY,   -- reference from the application
        OrderID int
    );

    -- allocate the new order numbers

    INSERT @OrdersToGenerate (OrderReference, OrderID)
    SELECT OrderReference, NEXT VALUE FOR Sequences.OrderID
    FROM @Orders;

    BEGIN TRY

        BEGIN TRAN;

        INSERT Sales.Orders
            (OrderID, CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate,
             ExpectedDeliveryDate, CustomerPurchaseOrderNumber, IsUndersupplyBackordered, Comments, DeliveryInstructions, InternalComments,
             PickingCompletedWhen, LastEditedBy, LastEditedWhen)
        SELECT otg.OrderID, o.CustomerID, @SalespersonPersonID, NULL, o.ContactPersonID, NULL, SYSDATETIME(),
               o.ExpectedDeliveryDate, o.CustomerPurchaseOrderNumber, o.IsUndersupplyBackordered, o.Comments, o.DeliveryInstructions, NULL,
               NULL, @OrdersCreatedByPersonID, SYSDATETIME()
        FROM @OrdersToGenerate AS otg
        INNER JOIN @Orders AS o
        ON otg.OrderReference = o.OrderReference;

        INSERT Sales.OrderLines
            (OrderID, StockItemID, [Description], PackageTypeID, Quantity, UnitPrice,
             TaxRate, PickedQuantity, PickingCompletedWhen, LastEditedBy, LastEditedWhen)
        SELECT otg.OrderID, ol.StockItemID, ol.[Description], si.UnitPackageID, ol.Quantity,
               Website.CalculateCustomerPrice(o.CustomerID, ol.StockItemID, SYSDATETIME()),
               si.TaxRate, 0, NULL, @OrdersCreatedByPersonID, SYSDATETIME()
        FROM @OrdersToGenerate AS otg
        INNER JOIN @OrderLines AS ol
        ON otg.OrderReference = ol.OrderReference
		INNER JOIN @Orders AS o
		ON ol.OrderReference = o.OrderReference
        INNER JOIN Warehouse.StockItems AS si
        ON ol.StockItemID = si.StockItemID;

        COMMIT;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        PRINT N'Unable to create the customer orders.';
        THROW;
        RETURN -1;
    END CATCH;

    RETURN 0;
END;
GO

-- File: InvoiceCustomerOrders.sql
﻿
CREATE PROCEDURE Website.InvoiceCustomerOrders
@OrdersToInvoice Website.OrderIDList READONLY,
@PackedByPersonID int,
@InvoicedByPersonID int
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @InvoicesToGenerate TABLE
    (
        OrderID int PRIMARY KEY,
        InvoiceID int NOT NULL,
        TotalDryItems int NOT NULL,
        TotalChillerItems int NOT NULL
    );

    BEGIN TRY;

        -- Check that all orders exist, have been fully picked, and not already invoiced. Also allocate new invoice numbers.
        INSERT @InvoicesToGenerate (OrderID, InvoiceID, TotalDryItems, TotalChillerItems)
        SELECT oti.OrderID,
               NEXT VALUE FOR Sequences.InvoiceID,
               COALESCE((SELECT SUM(CASE WHEN si.IsChillerStock <> 0 THEN 0 ELSE 1 END)
                         FROM Sales.OrderLines AS ol
                         INNER JOIN Warehouse.StockItems AS si
                         ON ol.StockItemID = si.StockItemID
                         WHERE ol.OrderID = oti.OrderID), 0),
               COALESCE((SELECT SUM(CASE WHEN si.IsChillerStock <> 0 THEN 1 ELSE 0 END)
                         FROM Sales.OrderLines AS ol
                         INNER JOIN Warehouse.StockItems AS si
                         ON ol.StockItemID = si.StockItemID
                         WHERE ol.OrderID = oti.OrderID), 0)
        FROM @OrdersToInvoice AS oti
        INNER JOIN Sales.Orders AS o
        ON oti.OrderID = o.OrderID
        WHERE NOT EXISTS (SELECT 1 FROM Sales.Invoices AS i
                                   WHERE i.OrderID = oti.OrderID)
        AND o.PickingCompletedWhen IS NOT NULL;

        IF EXISTS (SELECT 1 FROM @OrdersToInvoice AS oti WHERE NOT EXISTS (SELECT 1 FROM @InvoicesToGenerate AS itg WHERE itg.OrderID = oti.OrderID))
        BEGIN
            PRINT N'At least one order ID either does not exist, is not picked, or is already invoiced';
            THROW 51000, N'At least one orderID either does not exist, is not picked, or is already invoiced', 1;
        END;

        BEGIN TRAN;

        INSERT Sales.Invoices
            (InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID, ContactPersonID, AccountsPersonID,
             SalespersonPersonID, PackedByPersonID, InvoiceDate, CustomerPurchaseOrderNumber,
             IsCreditNote, CreditNoteReason, Comments, DeliveryInstructions, InternalComments,
             TotalDryItems, TotalChillerItems,  DeliveryRun, RunPosition,
             ReturnedDeliveryData,
             LastEditedBy, LastEditedWhen)
        SELECT itg.InvoiceID, c.CustomerID, c.BillToCustomerID, itg.OrderID, c.DeliveryMethodID, o.ContactPersonID, btc.PrimaryContactPersonID,
               o.SalespersonPersonID, @PackedByPersonID, SYSDATETIME(), o.CustomerPurchaseOrderNumber,
               0, NULL, NULL, c.DeliveryAddressLine1 + N', ' + c.DeliveryAddressLine2, NULL,
               itg.TotalDryItems, itg.TotalChillerItems, c.DeliveryRun, c.RunPosition,
               JSON_MODIFY(N'{"Events": []}', N'append $.Events',
                   JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(N'{ }', N'$.Event', N'Ready for collection'),
                   N'$.EventTime', CONVERT(nvarchar(20), SYSDATETIME(), 126)),
                   N'$.ConNote', N'EAN-125-' + CAST(itg.InvoiceID + 1050 AS nvarchar(20)))),
               @InvoicedByPersonID, SYSDATETIME()
        FROM @InvoicesToGenerate AS itg
        INNER JOIN Sales.Orders AS o
        ON itg.OrderID = o.OrderID
        INNER JOIN Sales.Customers AS c
        ON o.CustomerID = c.CustomerID
        INNER JOIN Sales.Customers AS btc
        ON btc.CustomerID = c.BillToCustomerID;

        INSERT Sales.InvoiceLines
            (InvoiceID, StockItemID, [Description], PackageTypeID,
             Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice,
             LastEditedBy, LastEditedWhen)
        SELECT itg.InvoiceID, ol.StockItemID, ol.[Description], ol.PackageTypeID,
               ol.PickedQuantity, ol.UnitPrice, ol.TaxRate,
               ROUND(ol.PickedQuantity * ol.UnitPrice * ol.TaxRate / 100.0, 2),
               ROUND(ol.PickedQuantity * (ol.UnitPrice - sih.LastCostPrice), 2),
               ROUND(ol.PickedQuantity * ol.UnitPrice, 2)
                 + ROUND(ol.PickedQuantity * ol.UnitPrice * ol.TaxRate / 100.0, 2),
               @InvoicedByPersonID, SYSDATETIME()
        FROM @InvoicesToGenerate AS itg
        INNER JOIN Sales.OrderLines AS ol
        ON itg.OrderID = ol.OrderID
        INNER JOIN Warehouse.StockItems AS si
        ON ol.StockItemID = si.StockItemID
        INNER JOIN Warehouse.StockItemHoldings AS sih
        ON si.StockItemID = sih.StockItemID
        ORDER BY ol.OrderID, ol.OrderLineID;

        INSERT Warehouse.StockItemTransactions
            (StockItemID, TransactionTypeID, CustomerID, InvoiceID, SupplierID, PurchaseOrderID,
             TransactionOccurredWhen, Quantity, LastEditedBy, LastEditedWhen)
        SELECT il.StockItemID, (SELECT TransactionTypeID FROM [Application].TransactionTypes WHERE TransactionTypeName = N'Stock Issue'),
               i.CustomerID, i.InvoiceID, NULL, NULL,
               SYSDATETIME(), 0 - il.Quantity, @InvoicedByPersonID, SYSDATETIME()
        FROM @InvoicesToGenerate AS itg
        INNER JOIN Sales.InvoiceLines AS il
        ON itg.InvoiceID = il.InvoiceID
        INNER JOIN Sales.Invoices AS i
        ON il.InvoiceID = i.InvoiceID
        ORDER BY il.InvoiceID, il.InvoiceLineID;

        WITH StockItemTotals
        AS
        (
            SELECT il.StockItemID, SUM(il.Quantity) AS TotalQuantity
            FROM Sales.InvoiceLines aS il
            WHERE il.InvoiceID IN (SELECT InvoiceID FROM @InvoicesToGenerate)
            GROUP BY il.StockItemID
        )
        UPDATE sih
        SET sih.QuantityOnHand -= sit.TotalQuantity,
            sih.LastEditedBy = @InvoicedByPersonID,
            sih.LastEditedWhen = SYSDATETIME()
        FROM Warehouse.StockItemHoldings AS sih
        INNER JOIN StockItemTotals AS sit
        ON sih.StockItemID = sit.StockItemID;

        INSERT Sales.CustomerTransactions
            (CustomerID, TransactionTypeID, InvoiceID, PaymentMethodID,
             TransactionDate, AmountExcludingTax, TaxAmount, TransactionAmount,
             OutstandingBalance, FinalizationDate, LastEditedBy, LastEditedWhen)
        SELECT i.BillToCustomerID,
               (SELECT TransactionTypeID FROM [Application].TransactionTypes WHERE TransactionTypeName = N'Customer Invoice'),
               itg.InvoiceID,
               NULL,
               SYSDATETIME(),
               (SELECT SUM(il.ExtendedPrice - il.TaxAmount) FROM Sales.InvoiceLines AS il WHERE il.InvoiceID = itg.InvoiceID),
               (SELECT SUM(il.TaxAmount) FROM Sales.InvoiceLines AS il WHERE il.InvoiceID = itg.InvoiceID),
               (SELECT SUM(il.ExtendedPrice) FROM Sales.InvoiceLines AS il WHERE il.InvoiceID = itg.InvoiceID),
               (SELECT SUM(il.ExtendedPrice) FROM Sales.InvoiceLines AS il WHERE il.InvoiceID = itg.InvoiceID),
               NULL,
               @InvoicedByPersonID,
               SYSDATETIME()
        FROM @InvoicesToGenerate AS itg
        INNER JOIN Sales.Invoices AS i
        ON itg.InvoiceID = i.InvoiceID;

        COMMIT;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        PRINT N'Unable to invoice these orders';
        THROW;
        RETURN -1;
    END CATCH;

    RETURN 0;
END;
GO

-- File: RecordColdRoomTemperatures.sql
﻿
CREATE PROCEDURE Website.RecordColdRoomTemperatures
@SensorReadings Website.SensorDataList READONLY
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH
(
	TRANSACTION ISOLATION LEVEL = SNAPSHOT,
	LANGUAGE = N'English'
)
    BEGIN TRY

		DECLARE @NumberOfReadings int = (SELECT MAX(SensorDataListID) FROM @SensorReadings);
		DECLARE @Counter int = (SELECT MIN(SensorDataListID) FROM @SensorReadings);

		DECLARE @ColdRoomSensorNumber int;
		DECLARE @RecordedWhen datetime2(7);
		DECLARE @Temperature decimal(18,2);

		-- note that we cannot use a merge here because multiple readings might exist for each sensor

		WHILE @Counter <= @NumberOfReadings
		BEGIN
			SELECT @ColdRoomSensorNumber = ColdRoomSensorNumber,
			       @RecordedWhen = RecordedWhen,
				   @Temperature = Temperature
			FROM @SensorReadings
			WHERE SensorDataListID = @Counter;

			UPDATE Warehouse.ColdRoomTemperatures
				SET RecordedWhen = @RecordedWhen,
				    Temperature = @Temperature
			WHERE ColdRoomSensorNumber = @ColdRoomSensorNumber;

			IF @@ROWCOUNT = 0
			BEGIN
				INSERT Warehouse.ColdRoomTemperatures
					(ColdRoomSensorNumber, RecordedWhen, Temperature)
				VALUES (@ColdRoomSensorNumber, @RecordedWhen, @Temperature);
			END;

			SET @Counter += 1;
		END;

    END TRY
    BEGIN CATCH
        THROW 51000, N'Unable to apply the sensor data', 2;

        RETURN 1;
    END CATCH;
END;
GO

-- File: RecordVehicleTemperature.sql
﻿
CREATE PROCEDURE Website.RecordVehicleTemperature
@FullSensorDataArray nvarchar(1000)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET XACT_ABORT ON;

    DECLARE @CrLf nchar(2) = nchar(13) + nchar(10);
    DECLARE @HelpMessage nvarchar(max) = N'JSON sensor data is invalid. An example of what is required is as follows:' + @CrLf + @CrLf
              + N'{"Recordings":' + @CrLf
              + N'    [' + @CrLf
              + N'        {"type":"Feature", "geometry": {"type":"Point", "coordinates":[-89.7600464,50.4742420] }, "properties":{"rego":"WWI-321-A","sensor":1,"when":"2016-01-01T07:00:00","temp":3.96}},' + @CrLf
              + N'        {"type":"Feature", "geometry": {"type":"Point", "coordinates":[-89.7600464,50.4742420] }, "properties":{"rego":"WWI-321-A","sensor":2,"when":"2016-01-01T07:00:00","temp":3.98}}' + @CrLf
              + N'    ]' + @CrLf
              + N'}';

    IF ISJSON(@FullSensorDataArray) = 0
    BEGIN
        PRINT @HelpMessage;
        THROW 51000, N'FullSensorDataArray must be valid JSON data', 1;
        RETURN 1;
    END;

    BEGIN TRY

        BEGIN TRAN;

        INSERT Warehouse.VehicleTemperatures
            (VehicleRegistration, ChillerSensorNumber, RecordedWhen, Temperature,
			 FullSensorData, IsCompressed, CompressedSensorData)
		SELECT VehicleRegistration, ChillerSensorNumber, RecordedWhen, Temperature,
		       FullSensorData, 0, NULL
		FROM OPENJSON(@FullSensorDataArray, N'$.Recordings')
        WITH ( VehicleRegistration nvarchar(40) N'$.properties.rego',
               ChillerSensorNumber int N'$.properties.sensor',
        	   RecordedWhen datetime2(7) N'$.properties.when',
        	   Temperature decimal(18,2) N'$.properties.temp',
        	   FullSensorData nvarchar(max) N'$' AS JSON);

        IF @@ROWCOUNT = 0
        BEGIN
            PRINT N'Warning: No valid sensor data found';
            PRINT @HelpMessage;
        END;

        COMMIT;

    END TRY
    BEGIN CATCH
        PRINT @HelpMessage;

        THROW 51000, N'Valid JSON was supplied but does not match the temperature recordings array structure', 2;

        IF XACT_STATE() <> 0 ROLLBACK TRAN;

        RETURN 1;
    END CATCH;
END;

GO

-- File: SearchForCustomers.sql
﻿
CREATE PROCEDURE Website.SearchForCustomers
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
WITH EXECUTE AS OWNER
AS
BEGIN
    SELECT TOP(@MaximumRowsToReturn)
           c.CustomerID,
           c.CustomerName,
           ct.CityName,
           c.PhoneNumber,
           c.FaxNumber,
           p.FullName AS PrimaryContactFullName,
           p.PreferredName AS PrimaryContactPreferredName
    FROM Sales.Customers AS c
    INNER JOIN [Application].Cities AS ct
    ON c.DeliveryCityID = ct.CityID
    LEFT OUTER JOIN [Application].People AS p
    ON c.PrimaryContactPersonID = p.PersonID
    WHERE CONCAT(c.CustomerName, N' ', p.FullName, N' ', p.PreferredName) LIKE N'%' + @SearchText + N'%'
    ORDER BY c.CustomerName
    FOR JSON AUTO, ROOT(N'Customers');
END;

GO

-- File: SearchForPeople.sql
﻿
CREATE PROCEDURE Website.SearchForPeople
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
AS
BEGIN
    SELECT TOP(@MaximumRowsToReturn)
           p.PersonID,
           p.FullName,
           p.PreferredName,
           CASE WHEN p.IsSalesperson <> 0 THEN N'Salesperson'
                WHEN p.IsEmployee <> 0 THEN N'Employee'
                WHEN c.CustomerID IS NOT NULL THEN N'Customer'
                WHEN sp.SupplierID IS NOT NULL THEN N'Supplier'
                WHEN sa.SupplierID IS NOT NULL THEN N'Supplier'
           END AS Relationship,
           COALESCE(c.CustomerName, sp.SupplierName, sa.SupplierName, N'WWI') AS Company
    FROM [Application].People AS p
    LEFT OUTER JOIN Sales.Customers AS c
    ON c.PrimaryContactPersonID = p.PersonID
    LEFT OUTER JOIN Purchasing.Suppliers AS sp
    ON sp.PrimaryContactPersonID = p.PersonID
    LEFT OUTER JOIN Purchasing.Suppliers AS sa
    ON sa.AlternateContactPersonID = p.PersonID
    WHERE p.SearchName LIKE N'%' + @SearchText + N'%'
    ORDER BY p.FullName
    FOR JSON AUTO, ROOT(N'People');
END;

GO

-- File: SearchForStockItems.sql
﻿
CREATE PROCEDURE Website.SearchForStockItems
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
WITH EXECUTE AS OWNER
AS
BEGIN
    SELECT TOP(@MaximumRowsToReturn)
           si.StockItemID,
           si.StockItemName
    FROM Warehouse.StockItems AS si
    WHERE si.SearchDetails LIKE N'%' + @SearchText + N'%'
    ORDER BY si.StockItemName
    FOR JSON AUTO, ROOT(N'StockItems');
END;

GO

-- File: SearchForStockItemsByTags.sql
﻿
CREATE PROCEDURE Website.SearchForStockItemsByTags
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
WITH EXECUTE AS OWNER
AS
BEGIN
    SELECT TOP(@MaximumRowsToReturn)
           si.StockItemID,
           si.StockItemName
    FROM Warehouse.StockItems AS si
    WHERE si.Tags LIKE N'%' + @SearchText + N'%'
    ORDER BY si.StockItemName
    FOR JSON AUTO, ROOT(N'StockItems');
END;

GO

-- File: SearchForSuppliers.sql
﻿
CREATE PROCEDURE Website.SearchForSuppliers
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
AS
BEGIN
    SELECT TOP(@MaximumRowsToReturn)
           s.SupplierID,
           s.SupplierName,
           c.CityName,
           s.PhoneNumber,
           s.FaxNumber ,
           p.FullName AS PrimaryContactFullName,
           p.PreferredName AS PrimaryContactPreferredName
    FROM Purchasing.Suppliers AS s
    INNER JOIN [Application].Cities AS c
    ON s.DeliveryCityID = c.CityID
    LEFT OUTER JOIN [Application].People AS p
    ON s.PrimaryContactPersonID = p.PersonID
    WHERE CONCAT(s.SupplierName, N' ', p.FullName, N' ', p.PreferredName) LIKE N'%' + @SearchText + N'%'
    ORDER BY s.SupplierName
    FOR JSON AUTO, ROOT(N'Suppliers');
END;

GO
