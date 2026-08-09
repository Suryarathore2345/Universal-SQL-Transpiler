-- WideWorldImporters OLTP Database Functions - microsoft/sql-server-samples (MIT License)
-- Source: https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/wide-world-importers/wwi-ssdt


-- File: DetermineCustomerAccess.sql
﻿
CREATE FUNCTION [Application].DetermineCustomerAccess(@CityID int)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (SELECT 1 AS AccessResult
        WHERE IS_ROLEMEMBER(N'db_owner') <> 0
        OR IS_ROLEMEMBER((SELECT sp.SalesTerritory
                          FROM [Application].Cities AS c
                          INNER JOIN [Application].StateProvinces AS sp
                          ON c.StateProvinceID = sp.StateProvinceID
                          WHERE c.CityID = @CityID) + N' Sales') <> 0
	    OR ((ORIGINAL_LOGIN() = N'Website' OR ORIGINAL_LOGIN() = N'WebApi')
		    AND EXISTS (SELECT 1
		                FROM [Application].Cities AS c
				        INNER JOIN [Application].StateProvinces AS sp
				        ON c.StateProvinceID = sp.StateProvinceID
				        WHERE c.CityID = @CityID
				        AND sp.SalesTerritory = SESSION_CONTEXT(N'SalesTerritory'))));
GO

-- File: GetAreaCode.sql
﻿
CREATE FUNCTION [DataLoadSimulation].[GetAreaCode]
(
    @StateProvinceCode NVARCHAR(4)
)
RETURNS NVARCHAR(4)
WITH EXECUTE AS OWNER
AS
BEGIN
/*
Notes:
  Retrieves the area code from the area code table.
  This is used as part of data generation.

Usage:
  DECLARE @myAreaCode NVARCHAR(4)
  SET @myAreaCode = DataLoadSimulation.GetAreaCode ('AL')
  SELECT @myAreaCode

*/
  DECLARE @AreaCode AS NVARCHAR(4)

  SELECT TOP 1
         @AreaCode = ac.[AreaCode]
    FROM [DataLoadSimulation].[AreaCode] AS ac
   WHERE ac.StateProvinceCode = @StateProvinceCode;

  RETURN @AreaCode;
END;


GO

-- File: GetBogativePhoneNumber.sql
﻿CREATE PROCEDURE [DataLoadSimulation].[GetBogativePhoneNumber]
(
    @AreaCode NVARCHAR(4)
  , @PhoneNumber AS NVARCHAR(20) OUTPUT
)
AS
BEGIN
/*
Notes:
  Generates a fake phone number based on the area code

Usage:
  DECLARE @myPhoneNumber AS NVARCHAR(20)
  EXEC [DataLoadSimulation].[GetBogativePhoneNumber]
      @AreaCode = '205'
    , @PhoneNumber = @myPhoneNumber OUTPUT
  SELECT @myPhoneNumber

*/

  DECLARE @phoneLast4  AS NVARCHAR(4)

  SET @phoneLast4 = RIGHT('0000' + CAST((ABS(CHECKSUM(NEWID())) % 9999) AS NVARCHAR) , 4)

  SET @PhoneNumber = '(' + @AreaCode + ') 555-' + @phoneLast4

  RETURN

END


GO

-- File: GetCityLocation.sql
﻿CREATE FUNCTION [DataLoadSimulation].[GetCityLocation]
(@CityID INT)
RETURNS GEOGRAPHY
AS
BEGIN
/*
Notes:
  Returns the location for the passed in city id

Usage:
  DECLARE @myLoc GEOGRAPHY = [DataLoadSimulation].[GetCityLocation] (1)
  SELECT @myLoc

*/

  DECLARE @Loc AS GEOGRAPHY

  SELECT TOP 1 @Loc = [Location]
    FROM [Application].Cities
   WHERE CityID = @CityID

  RETURN @Loc

END


GO

-- File: GetCustomerCount.sql
﻿CREATE FUNCTION [DataLoadSimulation].[GetCustomerCount]
(@CustomerName NVARCHAR(50))
RETURNS INT
AS
BEGIN
/*
Notes:
  Returns the number of rows with that customer name.
  This will either be 1 or 0, and is used to validate
  a customer doesn't exist prior to inserting them

Usage:
  DECLARE @CustCount INT = [DataLoadSimulation].[GetCustomerCount] (N'Tailspin Toys (Head Office)')
  SELECT @CustCount
*/

  DECLARE @CustCount INT

  SELECT @CustCount = COUNT(*)
    FROM [Sales].[Customers]
   WHERE [CustomerName] = @CustomerName

  RETURN @CustCount

END


GO

-- File: GetDeliveryMethodID.sql
﻿CREATE FUNCTION [DataLoadSimulation].[GetDeliveryMethodID]
( @DeliveryMethodName NVARCHAR(50) )
RETURNS INT
AS
BEGIN
/*
Notes:
  Returns the delivery method id for the passed in name

Usage:
  DECLARE @myDeliveryMethodId INT = [DataLoadSimulation].[GetDeliveryMethodID] ('Road Freight')
  SELECT @myDeliveryMethodId

*/
  DECLARE @DelivMethodId INT

  SELECT TOP 1
         @DelivMethodId = DeliveryMethodID
    FROM [Application].DeliveryMethods
   WHERE DeliveryMethodName = @DeliveryMethodName
     AND ValidTo = '99991231 23:59:59.9999999'

  RETURN @DelivMethodId

END

GO

-- File: GetPaymentMethodID.sql
﻿CREATE FUNCTION [DataLoadSimulation].[GetPaymentMethodID]
( @PaymentMethodName NVARCHAR(50) )
RETURNS INT
AS
BEGIN
/*
Notes:
  Returns the transaction type id for the passed in name

Usage:
  DECLARE @myTransactionTypeId INT = [DataLoadSimulation].[GetPaymentMethodID] (N'EFT')
  SELECT @myTransactionTypeId

*/
  DECLARE @PayMethodId INT
  SELECT TOP 1
         @PayMethodId = PaymentMethodID
    FROM [Application].PaymentMethods
   WHERE PaymentMethodName = @PaymentMethodName
     AND ValidTo = '99991231 23:59:59.9999999'

  RETURN @PayMethodId

END

GO

-- File: GetPersonID.sql
﻿CREATE FUNCTION [DataLoadSimulation].[GetPersonID]
( @FullName NVARCHAR(50) )
RETURNS INT
AS
BEGIN
/*
Notes:
  Returns the person id for the passed in full name

Usage:
  DECLARE @myPersonId INT = [DataLoadSimulation].[GetPersonID] ('Hubert Helms')
  SELECT @myPersonId

*/
  DECLARE @PerId INT

  SELECT TOP 1
         @PerId = PersonID
    FROM [Application].[People]
   WHERE FullName = @FullName
     AND ValidTo = '99991231 23:59:59.9999999'

  RETURN @PerId

END

GO

-- File: GetStateProvinceID.sql
﻿CREATE FUNCTION [DataLoadSimulation].[GetStateProvinceID]
( @StateProvinceCode NVARCHAR(5) )
RETURNS INT
AS
BEGIN
/*
Notes:
  Returns the state province id for the passed in state province code

Usage:
  DECLARE @myStateProvinceId INT
  SELECT @myStateProvinceId = [DataLoadSimulation].[GetStateProvinceID] ('AL')

*/
  DECLARE @SPId INT
  SELECT @SPId = StateProvinceID
    FROM [Application].StateProvinces
   WHERE StateProvinceCode = @StateProvinceCode
     AND ValidTo = '99991231 23:59:59.9999999'

  RETURN @SPId

END

GO

-- File: GetSupplierCategoryID.sql
﻿CREATE FUNCTION [DataLoadSimulation].[GetSupplierCategoryID]
( @SupplierCategoryName NVARCHAR(50) )
RETURNS INT
AS
BEGIN

/*
Notes:
  Returns the SupplierCategoryID for the passed in Supplier Category Name

Usage:
  DECLARE @SupplierCatID INT
  SET @SupplierCatID = [DataLoadSimulation].[GetSupplierCategoryID] ('Toy Supplier')
  SELECT @SupplierCatID

*/

  DECLARE @SupCatID INT

  SELECT TOP 1 @SupCatID = SupplierCategoryID
    FROM Purchasing.SupplierCategories
   WHERE SupplierCategoryName = @SupplierCategoryName
     AND ValidTo = '99991231 23:59:59.9999999'

  RETURN @SupCatID

END

GO

-- File: GetTransactionTypeID.sql
﻿CREATE FUNCTION [DataLoadSimulation].[GetTransactionTypeID]
( @TransactionTypeName NVARCHAR(50) )
RETURNS INT
AS
BEGIN
/*
Notes:
  Returns the transaction type id for the passed in name

Usage:
  DECLARE @myTransactionTypeId INT = [DataLoadSimulation].[GetTransactionTypeID] (N'Supplier Payment Issued')
  SELECT @myTransactionTypeId

*/
  DECLARE @TransTypeId INT
  SELECT TOP 1
         @TransTypeId = TransactionTypeID
   FROM [Application].TransactionTypes
  WHERE TransactionTypeName = @TransactionTypeName
     AND ValidTo = '99991231 23:59:59.9999999'

  RETURN @TransTypeId

END

GO

-- File: CalculateCustomerPrice.sql
﻿
CREATE FUNCTION Website.CalculateCustomerPrice
(
    @CustomerID int,
    @StockItemID int,
    @PricingDate date
)
RETURNS decimal(18,2)
WITH EXECUTE AS OWNER
AS
BEGIN
    DECLARE @CalculatedPrice decimal(18,2);
    DECLARE @UnitPrice decimal(18,2);
    DECLARE @LowestUnitPrice decimal(18,2);
    DECLARE @HighestDiscountAmount decimal(18,2);
    DECLARE @HighestDiscountPercentage decimal(18,3);
    DECLARE @BuyingGroupID int;
    DECLARE @CustomerCategoryID int;
    DECLARE @DiscountedUnitPrice decimal(18,2);

    SELECT @BuyingGroupID = BuyingGroupID,
           @CustomerCategoryID = CustomerCategoryID
    FROM Sales.Customers
    WHERE CustomerID = @CustomerID;

    SELECT @UnitPrice = si.UnitPrice
    FROM Warehouse.StockItems AS si
    WHERE si.StockItemID = @StockItemID;

    SET @CalculatedPrice = @UnitPrice;

    SET @LowestUnitPrice = (SELECT MIN(sd.UnitPrice)
                            FROM Sales.SpecialDeals AS sd
                            WHERE ((sd.StockItemID = @StockItemID) OR (sd.StockItemID IS NULL))
                            AND ((sd.CustomerID = @CustomerID) OR (sd.CustomerID IS NULL))
                            AND ((sd.BuyingGroupID = @BuyingGroupID) OR (sd.BuyingGroupID IS NULL))
                            AND ((sd.CustomerCategoryID = @CustomerCategoryID) OR (sd.CustomerCategoryID IS NULL))
                            AND ((sd.StockGroupID IS NULL) OR EXISTS (SELECT 1 FROM Warehouse.StockItemStockGroups AS sisg
                                                                               WHERE sisg.StockItemID = @StockItemID
                                                                               AND sisg.StockGroupID = sd.StockGroupID))
                            AND sd.UnitPrice IS NOT NULL
                            AND @PricingDate BETWEEN sd.StartDate AND sd.EndDate);

    IF @LowestUnitPrice IS NOT NULL AND @LowestUnitPrice < @UnitPrice
    BEGIN
        SET @CalculatedPrice = @LowestUnitPrice;
    END;

    SET @HighestDiscountAmount = (SELECT MAX(sd.DiscountAmount)
                                  FROM Sales.SpecialDeals AS sd
                                  WHERE ((sd.StockItemID = @StockItemID) OR (sd.StockItemID IS NULL))
                                  AND ((sd.CustomerID = @CustomerID) OR (sd.CustomerID IS NULL))
                                  AND ((sd.BuyingGroupID = @BuyingGroupID) OR (sd.BuyingGroupID IS NULL))
                                  AND ((sd.CustomerCategoryID = @CustomerCategoryID) OR (sd.CustomerCategoryID IS NULL))
                                  AND ((sd.StockGroupID IS NULL) OR EXISTS (SELECT 1 FROM Warehouse.StockItemStockGroups AS sisg
                                                                                     WHERE sisg.StockItemID = @StockItemID
                                                                                     AND sisg.StockGroupID = sd.StockGroupID))
                                  AND sd.DiscountAmount IS NOT NULL
                                  AND @PricingDate BETWEEN sd.StartDate AND sd.EndDate);

    IF @HighestDiscountAmount IS NOT NULL AND (@UnitPrice - @HighestDiscountAmount) < @CalculatedPrice
    BEGIN
        SET @CalculatedPrice = @UnitPrice - @HighestDiscountAmount;
    END;

    SET @HighestDiscountPercentage = (SELECT MAX(sd.DiscountPercentage)
                                      FROM Sales.SpecialDeals AS sd
                                      WHERE ((sd.StockItemID = @StockItemID) OR (sd.StockItemID IS NULL))
                                      AND ((sd.CustomerID = @CustomerID) OR (sd.CustomerID IS NULL))
                                      AND ((sd.BuyingGroupID = @BuyingGroupID) OR (sd.BuyingGroupID IS NULL))
                                      AND ((sd.CustomerCategoryID = @CustomerCategoryID) OR (sd.CustomerCategoryID IS NULL))
                                      AND ((sd.StockGroupID IS NULL) OR EXISTS (SELECT 1 FROM Warehouse.StockItemStockGroups AS sisg
                                                                                         WHERE sisg.StockItemID = @StockItemID
                                                                                         AND sisg.StockGroupID = sd.StockGroupID))
                                      AND sd.DiscountPercentage IS NOT NULL
                                      AND @PricingDate BETWEEN sd.StartDate AND sd.EndDate);

    IF @HighestDiscountPercentage IS NOT NULL
    BEGIN
        SET @DiscountedUnitPrice = ROUND(@UnitPrice * @HighestDiscountPercentage / 100.0, 2);
        IF @DiscountedUnitPrice < @CalculatedPrice SET @CalculatedPrice = @DiscountedUnitPrice;
    END;


    RETURN @CalculatedPrice;
END;

GO
