-- WideWorldImporters OLTP Database Views - microsoft/sql-server-samples (MIT License)
-- Source: https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/wide-world-importers/wwi-ssdt


-- File: BuyingGroups.sql
﻿CREATE VIEW [WebApi].[BuyingGroups]
AS
SELECT BuyingGroupID, BuyingGroupName
FROM Sales.BuyingGroups
GO

-- File: Cities.sql
﻿CREATE VIEW [WebApi].[Cities]
AS
SELECT c.CityID, c.CityName, c.LatestRecordedPopulation, c.StateProvinceID, sp.StateProvinceName,
	Location = JSON_QUERY((SELECT
				type = 'Feature',
				[geometry.type] = 'Point',
				[geometry.coordinates] = JSON_QUERY(CONCAT('[',c.Location.Long,',',c.Location.Lat ,']'))
			FOR JSON PATH, WITHOUT_ARRAY_WRAPPER))
FROM Application.Cities c
	INNER JOIN Application.StateProvinces sp
		ON c.StateProvinceID = sp.StateProvinceID
GO

-- File: Colors.sql
﻿CREATE VIEW [WebApi].[Colors]
AS
SELECT ColorID, ColorName
FROM Warehouse.Colors

GO

-- File: Countries.sql
﻿CREATE VIEW [WebApi].[Countries]
AS
SELECT CountryID,CountryName,FormalName,IsoAlpha3Code,IsoNumericCode,CountryType,LatestRecordedPopulation,Continent,Region,Subregion
FROM Application.Countries
GO

-- File: CustomerCategories.sql
﻿CREATE VIEW [WebApi].[CustomerCategories]
AS
SELECT CustomerCategoryID, CustomerCategoryName
FROM Sales.CustomerCategories
GO

-- File: CustomerTransactions.sql
﻿CREATE VIEW [WebApi].[CustomerTransactions]
AS
SELECT ct.CustomerTransactionID, ct.TransactionDate, ct.AmountExcludingTax, ct.TaxAmount, ct.TransactionAmount, ct.OutstandingBalance, ct.FinalizationDate, ct.IsFinalized,
		c.CustomerName, tt.TransactionTypeName, i.InvoiceDate, i.CustomerPurchaseOrderNumber, pm.PaymentMethodName,
		ct.CustomerID, ct.TransactionTypeID, ct.InvoiceID, ct.PaymentMethodID
FROM Sales.CustomerTransactions AS ct
		JOIN Sales.Customers AS c ON ct.CustomerID = c.CustomerID
		JOIN Sales.Invoices AS i ON ct.InvoiceID = i.InvoiceID
		LEFT OUTER JOIN Application.TransactionTypes AS tt ON ct.TransactionTypeID = tt.TransactionTypeID
		LEFT OUTER JOIN Application.PaymentMethods AS pm ON ct.PaymentMethodID = pm.PaymentMethodID
GO

-- File: Customers.sql
﻿CREATE VIEW [WebApi].[Customers]
AS
SELECT c.CustomerID,
       c.CustomerName,
       sc.CustomerCategoryName,
       pp.FullName AS PrimaryContact,
       ap.FullName AS AlternateContact,
       c.PhoneNumber,
       c.FaxNumber,
       c.WebsiteURL,
	   c.PostalAddressLine1,
	   c.PostalAddressLine2,
	   c.PostalPostalCode,
	   c.PostalCityID,
	   PostalCity = pc.CityName,
	   c.AccountOpenedDate,
	   c.CreditLimit,
	   c.IsOnCreditHold,
	   c.IsStatementSent,
	   c.PaymentDays,
	   c.RunPosition,
	   c.StandardDiscountPercentage,
	   bg.BuyingGroupName,
       DeliveryLocation = JSON_QUERY((SELECT
				type = 'Feature',
				[geometry.type] = 'Point',
				[geometry.coordinates] = JSON_QUERY(CONCAT('[',c.DeliveryLocation.Long,',',c.DeliveryLocation.Lat ,']')),
				[properties.DeliveryMethod] = DeliveryMethodName,
				[properties.CityName] = pc.CityName,
				[properties.Province] = sp.StateProvinceName,
				[properties.Territory] = sp.SalesTerritory
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)),
		c.PrimaryContactPersonID,
		c.AlternateContactPersonID,
		c.BillToCustomerID,
		c.BuyingGroupID,
		c.CustomerCategoryID
FROM Sales.Customers AS c
LEFT OUTER JOIN Sales.CustomerCategories AS sc
ON c.CustomerCategoryID = sc.CustomerCategoryID
LEFT OUTER JOIN [Application].People AS pp
ON c.PrimaryContactPersonID = pp.PersonID
LEFT OUTER JOIN [Application].People AS ap
ON c.AlternateContactPersonID = ap.PersonID
LEFT OUTER JOIN Sales.BuyingGroups AS bg
ON c.BuyingGroupID = bg.BuyingGroupID
LEFT OUTER JOIN [Application].DeliveryMethods AS dm
ON c.DeliveryMethodID = dm.DeliveryMethodID
LEFT OUTER JOIN [Application].Cities AS pc
ON c.PostalCityID = pc.CityID
LEFT OUTER JOIN [Application].StateProvinces AS sp
ON sp.StateProvinceID = pc.StateProvinceID
GO

-- File: DeliveryMethods.sql
﻿CREATE VIEW [WebApi].[DeliveryMethods]
AS
SELECT DeliveryMethodID, DeliveryMethodName
FROM [Application].DeliveryMethods
GO

-- File: Invoices.sql
﻿CREATE VIEW [WebApi].[Invoices]
AS
SELECT  inv.InvoiceID, inv.InvoiceDate, inv.CustomerPurchaseOrderNumber, inv.IsCreditNote, inv.TotalDryItems, inv.TotalChillerItems, inv.DeliveryRun, inv.RunPosition,
        ReturnedDeliveryData = JSON_QUERY(inv.ReturnedDeliveryData), inv.ConfirmedDeliveryTime,
        inv.ConfirmedReceivedBy, c.CustomerName, sp.FullName AS SalesPersonName, contact.FullName AS ContactName, contact.PhoneNumber AS ContactPhone, contact.EmailAddress AS ContactEmail,
        sp.EmailAddress AS SalesPersonEmail, dm.DeliveryMethodName, inv.CustomerID, inv.OrderID, inv.DeliveryMethodID, inv.ContactPersonID, inv.AccountsPersonID, inv.SalespersonPersonID, inv.PackedByPersonID
FROM    Sales.Invoices AS inv INNER JOIN
            Sales.Customers AS c ON inv.CustomerID = c.CustomerID INNER JOIN
            Application.DeliveryMethods AS dm ON inv.DeliveryMethodID = dm.DeliveryMethodID INNER JOIN
            Application.People AS contact ON inv.ContactPersonID = contact.PersonID INNER JOIN
            Application.People AS sp ON inv.SalespersonPersonID = sp.PersonID
GO

-- File: PackageTypes.sql
﻿CREATE VIEW [WebApi].[PackageTypes]
AS
SELECT PackageTypeID, PackageTypeName
FROM Warehouse.PackageTypes

GO

-- File: PaymentMethods.sql
﻿CREATE VIEW [WebApi].[PaymentMethods]
AS
SELECT PaymentMethodID, PaymentMethodName
FROM [Application].PaymentMethods
GO

-- File: PurchaseOrderLines.sql
﻿CREATE VIEW [WebApi].[PurchaseOrderLines]
AS
SELECT	ol.PurchaseOrderLineID, ol.PurchaseOrderID, ol.Description, ol.IsOrderLineFinalized,
		ProductName = si.StockItemName, si.Brand, si.Size, c.ColorName, pt.PackageTypeName,
		ol.ReceivedOuters, ol.OrderedOuters, ol.ExpectedUnitPricePerOuter
FROM	Purchasing.PurchaseOrderLines ol
		INNER JOIN Warehouse.StockItems si
			ON ol.StockItemID = si.StockItemID
			INNER JOIN Warehouse.Colors c
				ON c.ColorID = si.ColorID
		INNER JOIN Warehouse.PackageTypes pt
			ON ol.PackageTypeID = pt.PackageTypeID

GO

-- File: PurchaseOrders.sql
﻿CREATE   VIEW [WebApi].[PurchaseOrders]
AS
SELECT	o.PurchaseOrderID, o.OrderDate, o.ExpectedDeliveryDate, o.SupplierReference, o.IsOrderFinalized,
		dm.DeliveryMethodName, o.DeliveryMethodID, o.SupplierID,
		ContactName = c.FullName, ContactPhone = c.PhoneNumber, ContactFax = c.FaxNumber, ContactEmail = c.EmailAddress
FROM	Purchasing.PurchaseOrders o
		INNER JOIN Application.People c
			ON o.ContactPersonID = c.PersonID
		INNER JOIN Application.DeliveryMethods dm
			ON o.DeliveryMethodID = dm.DeliveryMethodID

GO

-- File: SalesOrderLines.sql
﻿CREATE VIEW [WebApi].[SalesOrderLines]
AS
SELECT	ol.OrderLineID, ol.OrderID, ol.Description, ol.Quantity, ol.UnitPrice, ol.TaxRate, ol.PickingCompletedWhen,
		ProductName = si.StockItemName, si.Brand, si.Size, c.ColorName, pt.PackageTypeName
FROM	Sales.OrderLines ol
		INNER JOIN Warehouse.StockItems si
			ON ol.StockItemID = si.StockItemID
			INNER JOIN Warehouse.Colors c
				ON c.ColorID = si.ColorID
		INNER JOIN Warehouse.PackageTypes pt
			ON ol.PackageTypeID = pt.PackageTypeID
		


GO

-- File: SalesOrders.sql
﻿CREATE   VIEW [WebApi].[SalesOrders]
AS
SELECT	o.OrderID, o.OrderDate, o.CustomerPurchaseOrderNumber,
		o.ExpectedDeliveryDate, o.PickingCompletedWhen,
		o.CustomerID, c.CustomerName, c.PhoneNumber, c.FaxNumber, c.WebsiteURL,
		DeliveryLocation = JSON_QUERY((SELECT
				[type] = 'Feature',
				[geometry.type] = 'Point',
				[geometry.coordinates] = JSON_QUERY(CONCAT('[',c.DeliveryLocation.Long,',',c.DeliveryLocation.Lat ,']')),
				[properties.DeliveryMethod] = dm.DeliveryMethodName,
				[properties.AddressLine1] = c.DeliveryAddressLine1,
				[properties.AddressLine2] = c.DeliveryAddressLine2,
				[properties.PostalCode] = c.DeliveryPostalCode,
				[properties.Instructions] = o.DeliveryInstructions
			FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)),
		SalesPerson = sp.FullName, SalesPersonPhone = sp.PhoneNumber, SalesPersonEmail = sp.EmailAddress
FROM	Sales.Orders o
		INNER JOIN Sales.Customers c
			ON o.CustomerID = c.CustomerID
			LEFT OUTER JOIN [Application].DeliveryMethods AS dm
				ON c.DeliveryMethodID = dm.DeliveryMethodID
		INNER JOIN Application.People sp
			ON o.SalespersonPersonID = sp.PersonID
		
GO

-- File: SpecialDeals.sql
﻿CREATE VIEW [WebApi].[SpecialDeals]
AS
SELECT	deal.SpecialDealID, deal.DealDescription, deal.StartDate, deal.EndDate, deal.DiscountAmount, deal.DiscountPercentage, deal.UnitPrice,
		si.StockItemName, si.Brand, si.Size, c.CustomerName, bg.BuyingGroupName, cat.CustomerCategoryName,
		deal.StockItemID, deal.CustomerID, deal.BuyingGroupID, deal.CustomerCategoryID, deal.StockGroupID
FROM Sales.SpecialDeals AS deal
	LEFT OUTER JOIN Warehouse.StockItems AS si ON deal.StockItemID = si.StockItemID
	LEFT OUTER JOIN Sales.Customers AS c ON deal.CustomerID = c.CustomerID
	LEFT OUTER JOIN Sales.CustomerCategories AS cat ON deal.CustomerCategoryID = cat.CustomerCategoryID
	LEFT OUTER JOIN Sales.BuyingGroups AS bg ON deal.BuyingGroupID = bg.BuyingGroupID

		
GO

-- File: StateProvinces.sql
﻿CREATE VIEW [WebApi].[StateProvinces]
AS
SELECT sp.StateProvinceID, sp.StateProvinceCode, sp.StateProvinceName, sp.CountryID, sp.SalesTerritory, sp.LatestRecordedPopulation,
	Border = JSON_QUERY('{"type": "Feature","geometry":{' +
 (CASE sp.Border.STGeometryType()
	WHEN 'POLYGON' THEN
	'"type": "Polygon","coordinates":[' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(sp.Border.ToString(),'POLYGON ',''),'(','['),')',']'),'], ',']],['),', ','],['),' ',',') + ']'
	WHEN 'MULTIPOLYGON' THEN
	'"type": "MultiPolygon","coordinates":[' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(sp.Border.ToString(),'MULTIPOLYGON ',''),'(','['),')',']'),'], ',']],['),', ','],['),' ',',') + ']'
 ELSE NULL
 END)
+'}}'),
	c.CountryName
FROM	Application.StateProvinces AS sp
			INNER JOIN Application.Countries AS c
				ON c.CountryID = sp.CountryID
	 
GO

-- File: StockGroups.sql
﻿CREATE VIEW [WebApi].[StockGroups]
AS
SELECT StockGroupID, StockGroupName
FROM Warehouse.StockGroups

GO

-- File: StockItems.sql
﻿CREATE VIEW [WebApi].[StockItems]
AS
SELECT	si.StockItemID, si.StockItemName, s.SupplierName, s.SupplierReference, c.ColorName,
		opt.PackageTypeName AS OuterPackage, upt.PackageTypeName AS UnitPackage,
		si.Brand, si.Size, si.LeadTimeDays, si.QuantityPerOuter, si.IsChillerStock,
		si.Barcode, si.TaxRate, si.UnitPrice, si.RecommendedRetailPrice, si.TypicalWeightPerUnit,
		si.MarketingComments, si.InternalComments, si.CustomFields, sih.QuantityOnHand, sih.BinLocation,
		sih.LastStocktakeQuantity, sih.LastCostPrice, sih.ReorderLevel, sih.TargetStockLevel,
		si.SupplierID, si.ColorID, si.UnitPackageID, si.OuterPackageID
FROM	Warehouse.StockItems AS si
		INNER JOIN Warehouse.StockItemHoldings AS sih ON si.StockItemID = sih.StockItemID
		INNER JOIN Purchasing.Suppliers AS s ON si.SupplierID = s.SupplierID
		INNER JOIN Warehouse.Colors AS c ON si.ColorID = c.ColorID
		INNER JOIN Warehouse.PackageTypes AS opt ON si.OuterPackageID = opt.PackageTypeID
		INNER JOIN Warehouse.PackageTypes AS upt ON si.UnitPackageID = upt.PackageTypeID

GO

-- File: SupplierCategories.sql
﻿CREATE VIEW [WebApi].[SupplierCategories]
AS
SELECT SupplierCategoryID, SupplierCategoryName
FROM Purchasing.SupplierCategories
GO

-- File: SupplierTransactions.sql
﻿CREATE VIEW [WebApi].[SupplierTransactions]
AS
SELECT        st.SupplierTransactionID, st.TransactionDate, st.AmountExcludingTax, st.TaxAmount, st.TransactionAmount, st.OutstandingBalance, st.FinalizationDate, st.IsFinalized, s.SupplierName, tt.TransactionTypeName,
                         pm.PaymentMethodName, st.SupplierID, st.TransactionTypeID, st.PurchaseOrderID, st.PaymentMethodID, po.OrderDate, po.IsOrderFinalized, po.ExpectedDeliveryDate, po.SupplierReference
FROM            Purchasing.SupplierTransactions AS st LEFT OUTER JOIN
                         Purchasing.PurchaseOrders AS po ON st.PurchaseOrderID = po.PurchaseOrderID LEFT OUTER JOIN
                         Application.TransactionTypes AS tt ON st.TransactionTypeID = tt.TransactionTypeID LEFT OUTER JOIN
                         Purchasing.Suppliers AS s ON st.SupplierID = s.SupplierID LEFT OUTER JOIN
                         Application.PaymentMethods AS pm ON st.PaymentMethodID = pm.PaymentMethodID
GO

-- File: Suppliers.sql
﻿CREATE VIEW [WebApi].[Suppliers]
AS
SELECT s.SupplierID,
       s.SupplierName,
       sc.SupplierCategoryName,
       pp.FullName AS PrimaryContact,
       ap.FullName AS AlternateContact,
       s.PhoneNumber,
       s.FaxNumber,
       s.WebsiteURL,
       s.SupplierReference,
	   s.BankAccountName,
	   s.BankAccountBranch,
		s.BankAccountCode,
		s.BankAccountNumber,
		s.BankInternationalCode,
		s.PostalAddressLine1,
		s.PostalAddressLine2,
		s.PostalPostalCode,
		s.PaymentDays,
		s.SupplierCategoryID,
	   DeliveryLocation = JSON_QUERY((SELECT
				[type] = 'Feature',
				[geometry.type] = 'Point',
				[geometry.coordinates] = JSON_QUERY(CONCAT('[',s.DeliveryLocation.Long,',',s.DeliveryLocation.Lat ,']')),
				[properties.DeliveryMethod] = dm.DeliveryMethodName,
				[properties.DeliveryMethodID] = s.DeliveryMethodID,
				[properties.City] = c.CityName,
				[properties.Province] = sp.StateProvinceName,
				[properties.Territory] = sp.SalesTerritory
			FOR JSON PATH, WITHOUT_ARRAY_WRAPPER))
FROM Purchasing.Suppliers AS s
	LEFT OUTER JOIN Purchasing.SupplierCategories AS sc
		ON s.SupplierCategoryID = sc.SupplierCategoryID
	LEFT OUTER JOIN [Application].People AS pp
		ON s.PrimaryContactPersonID = pp.PersonID
	LEFT OUTER JOIN [Application].People AS ap
		ON s.AlternateContactPersonID = ap.PersonID
	LEFT OUTER JOIN [Application].DeliveryMethods AS dm
		ON s.DeliveryMethodID = dm.DeliveryMethodID
	LEFT OUTER JOIN [Application].Cities AS c
		ON s.DeliveryCityID = c.CityID
		LEFT OUTER JOIN [Application].StateProvinces AS sp
			ON sp.StateProvinceID = c.StateProvinceID

GO

-- File: TransactionTypes.sql
﻿CREATE VIEW [WebApi].[TransactionTypes]
AS
SELECT TransactionTypeID, TransactionTypeName
FROM [Application].TransactionTypes
GO

-- File: Customers.sql
﻿CREATE VIEW [Website].[Customers]
AS
SELECT s.CustomerID,
       s.CustomerName,
       sc.CustomerCategoryName,
       pp.FullName AS PrimaryContact,
       ap.FullName AS AlternateContact,
       s.PhoneNumber,
       s.FaxNumber,
       bg.BuyingGroupName,
       s.WebsiteURL,
       dm.DeliveryMethodName AS DeliveryMethod,
       c.CityName AS CityName,
       s.DeliveryLocation AS DeliveryLocation,
       s.DeliveryRun,
       s.RunPosition
FROM Sales.Customers AS s
LEFT OUTER JOIN Sales.CustomerCategories AS sc
ON s.CustomerCategoryID = sc.CustomerCategoryID
LEFT OUTER JOIN [Application].People AS pp
ON s.PrimaryContactPersonID = pp.PersonID
LEFT OUTER JOIN [Application].People AS ap
ON s.AlternateContactPersonID = ap.PersonID
LEFT OUTER JOIN Sales.BuyingGroups AS bg
ON s.BuyingGroupID = bg.BuyingGroupID
LEFT OUTER JOIN [Application].DeliveryMethods AS dm
ON s.DeliveryMethodID = dm.DeliveryMethodID
LEFT OUTER JOIN [Application].Cities AS c
ON s.DeliveryCityID = c.CityID
GO



GO

-- File: Suppliers.sql
﻿CREATE VIEW [Website].[Suppliers]
AS
SELECT s.SupplierID,
       s.SupplierName,
       sc.SupplierCategoryName,
       pp.FullName AS PrimaryContact,
       ap.FullName AS AlternateContact,
       s.PhoneNumber,
       s.FaxNumber,
       s.WebsiteURL,
       dm.DeliveryMethodName AS DeliveryMethod,
       c.CityName AS CityName,
       s.DeliveryLocation AS DeliveryLocation,
       s.SupplierReference
FROM Purchasing.Suppliers AS s
LEFT OUTER JOIN Purchasing.SupplierCategories AS sc
ON s.SupplierCategoryID = sc.SupplierCategoryID
LEFT OUTER JOIN [Application].People AS pp
ON s.PrimaryContactPersonID = pp.PersonID
LEFT OUTER JOIN [Application].People AS ap
ON s.AlternateContactPersonID = ap.PersonID
LEFT OUTER JOIN [Application].DeliveryMethods AS dm
ON s.DeliveryMethodID = dm.DeliveryMethodID
LEFT OUTER JOIN [Application].Cities AS c
ON s.DeliveryCityID = c.CityID
GO



GO

-- File: VehicleTemperatures.sql
﻿CREATE VIEW Website.VehicleTemperatures
AS
SELECT vt.VehicleTemperatureID,
       vt.VehicleRegistration,
       vt.ChillerSensorNumber,
       vt.RecordedWhen,
       vt.Temperature,
       CASE WHEN vt.IsCompressed <> 0
            THEN CAST(DECOMPRESS(vt.CompressedSensorData) AS nvarchar(1000))
            ELSE vt.FullSensorData
       END AS FullSensorData
FROM Warehouse.VehicleTemperatures AS vt;

GO
