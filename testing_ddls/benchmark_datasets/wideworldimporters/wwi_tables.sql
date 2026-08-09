-- WideWorldImporters OLTP Database Tables - microsoft/sql-server-samples (MIT License)
-- Source: https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/wide-world-importers/wwi-ssdt


-- File: Cities.sql
﻿CREATE TABLE [Application].[Cities] (
    [CityID]                   INT                                         CONSTRAINT [DF_Application_Cities_CityID] DEFAULT (NEXT VALUE FOR [Sequences].[CityID]) NOT NULL,
    [CityName]                 NVARCHAR (50)                               NOT NULL,
    [StateProvinceID]          INT                                         NOT NULL,
    [Location]                 [sys].[geography]                           NULL,
    [LatestRecordedPopulation] BIGINT                                      NULL,
    [LastEditedBy]             INT                                         NOT NULL,
    [ValidFrom]                DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]                  DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_Application_Cities] PRIMARY KEY CLUSTERED ([CityID] ASC),
    CONSTRAINT [FK_Application_Cities_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Application_Cities_StateProvinceID_Application_StateProvinces] FOREIGN KEY ([StateProvinceID]) REFERENCES [Application].[StateProvinces] ([StateProvinceID]),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Application].[Cities_Archive], DATA_CONSISTENCY_CHECK=ON));


GO
CREATE NONCLUSTERED INDEX [FK_Application_Cities_StateProvinceID]
    ON [Application].[Cities]([StateProvinceID] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Cities', @level2type = N'INDEX', @level2name = N'FK_Application_Cities_StateProvinceID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Cities that are part of any address (including geographic location)', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Cities';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a city within the database', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Cities', @level2type = N'COLUMN', @level2name = N'CityID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Formal name of the city', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Cities', @level2type = N'COLUMN', @level2name = N'CityName';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'State or province for this city', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Cities', @level2type = N'COLUMN', @level2name = N'StateProvinceID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Geographic location of the city', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Cities', @level2type = N'COLUMN', @level2name = N'Location';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Latest available population for the City', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Cities', @level2type = N'COLUMN', @level2name = N'LatestRecordedPopulation';


GO

-- File: Cities_Archive.sql
﻿CREATE TABLE [Application].[Cities_Archive] (
    [CityID]                   INT               NOT NULL,
    [CityName]                 NVARCHAR (50)     NOT NULL,
    [StateProvinceID]          INT               NOT NULL,
    [Location]                 [sys].[geography] NULL,
    [LatestRecordedPopulation] BIGINT            NULL,
    [LastEditedBy]             INT               NOT NULL,
    [ValidFrom]                DATETIME2 (7)     NOT NULL,
    [ValidTo]                  DATETIME2 (7)     NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_Cities_Archive]
    ON [Application].[Cities_Archive]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);


GO

-- File: Countries.sql
﻿CREATE TABLE [Application].[Countries] (
    [CountryID]                INT                                         CONSTRAINT [DF_Application_Countries_CountryID] DEFAULT (NEXT VALUE FOR [Sequences].[CountryID]) NOT NULL,
    [CountryName]              NVARCHAR (60)                               NOT NULL,
    [FormalName]               NVARCHAR (60)                               NOT NULL,
    [IsoAlpha3Code]            NVARCHAR (3)                                NULL,
    [IsoNumericCode]           INT                                         NULL,
    [CountryType]              NVARCHAR (20)                               NULL,
    [LatestRecordedPopulation] BIGINT                                      NULL,
    [Continent]                NVARCHAR (30)                               NOT NULL,
    [Region]                   NVARCHAR (30)                               NOT NULL,
    [Subregion]                NVARCHAR (30)                               NOT NULL,
    [Border]                   [sys].[geography]                           NULL,
    [LastEditedBy]             INT                                         NOT NULL,
    [ValidFrom]                DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]                  DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_Application_Countries] PRIMARY KEY CLUSTERED ([CountryID] ASC),
    CONSTRAINT [FK_Application_Countries_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [UQ_Application_Countries_CountryName] UNIQUE NONCLUSTERED ([CountryName] ASC),
    CONSTRAINT [UQ_Application_Countries_FormalName] UNIQUE NONCLUSTERED ([FormalName] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Application].[Countries_Archive], DATA_CONSISTENCY_CHECK=ON));


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Countries that contain the states or provinces (including geographic boundaries)', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Countries';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a country within the database', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Countries', @level2type = N'COLUMN', @level2name = N'CountryID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Name of the country', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Countries', @level2type = N'COLUMN', @level2name = N'CountryName';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Full formal name of the country as agreed by United Nations', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Countries', @level2type = N'COLUMN', @level2name = N'FormalName';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = '3 letter alphabetic code assigned to the country by ISO', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Countries', @level2type = N'COLUMN', @level2name = N'IsoAlpha3Code';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric code assigned to the country by ISO', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Countries', @level2type = N'COLUMN', @level2name = N'IsoNumericCode';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Type of country or administrative region', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Countries', @level2type = N'COLUMN', @level2name = N'CountryType';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Latest available population for the country', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Countries', @level2type = N'COLUMN', @level2name = N'LatestRecordedPopulation';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Name of the continent', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Countries', @level2type = N'COLUMN', @level2name = N'Continent';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Name of the region', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Countries', @level2type = N'COLUMN', @level2name = N'Region';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Name of the subregion', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Countries', @level2type = N'COLUMN', @level2name = N'Subregion';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Geographic border of the country as described by the United Nations', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Countries', @level2type = N'COLUMN', @level2name = N'Border';


GO

-- File: Countries_Archive.sql
﻿CREATE TABLE [Application].[Countries_Archive] (
    [CountryID]                INT               NOT NULL,
    [CountryName]              NVARCHAR (60)     NOT NULL,
    [FormalName]               NVARCHAR (60)     NOT NULL,
    [IsoAlpha3Code]            NVARCHAR (3)      NULL,
    [IsoNumericCode]           INT               NULL,
    [CountryType]              NVARCHAR (20)     NULL,
    [LatestRecordedPopulation] BIGINT            NULL,
    [Continent]                NVARCHAR (30)     NOT NULL,
    [Region]                   NVARCHAR (30)     NOT NULL,
    [Subregion]                NVARCHAR (30)     NOT NULL,
    [Border]                   [sys].[geography] NULL,
    [LastEditedBy]             INT               NOT NULL,
    [ValidFrom]                DATETIME2 (7)     NOT NULL,
    [ValidTo]                  DATETIME2 (7)     NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_Countries_Archive]
    ON [Application].[Countries_Archive]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);


GO

-- File: DeliveryMethods.sql
﻿CREATE TABLE [Application].[DeliveryMethods] (
    [DeliveryMethodID]   INT                                         CONSTRAINT [DF_Application_DeliveryMethods_DeliveryMethodID] DEFAULT (NEXT VALUE FOR [Sequences].[DeliveryMethodID]) NOT NULL,
    [DeliveryMethodName] NVARCHAR (50)                               NOT NULL,
    [LastEditedBy]       INT                                         NOT NULL,
    [ValidFrom]          DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]            DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_Application_DeliveryMethods] PRIMARY KEY CLUSTERED ([DeliveryMethodID] ASC),
    CONSTRAINT [FK_Application_DeliveryMethods_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [UQ_Application_DeliveryMethods_DeliveryMethodName] UNIQUE NONCLUSTERED ([DeliveryMethodName] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Application].[DeliveryMethods_Archive], DATA_CONSISTENCY_CHECK=ON));


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Ways that stock items can be delivered (ie: truck/van, post, pickup, courier, etc.', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'DeliveryMethods';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a delivery method within the database', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'DeliveryMethods', @level2type = N'COLUMN', @level2name = N'DeliveryMethodID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Full name of methods that can be used for delivery of customer orders', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'DeliveryMethods', @level2type = N'COLUMN', @level2name = N'DeliveryMethodName';


GO

-- File: DeliveryMethods_Archive.sql
﻿CREATE TABLE [Application].[DeliveryMethods_Archive] (
    [DeliveryMethodID]   INT           NOT NULL,
    [DeliveryMethodName] NVARCHAR (50) NOT NULL,
    [LastEditedBy]       INT           NOT NULL,
    [ValidFrom]          DATETIME2 (7) NOT NULL,
    [ValidTo]            DATETIME2 (7) NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_DeliveryMethods_Archive]
    ON [Application].[DeliveryMethods_Archive]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);


GO

-- File: Logs.sql
﻿CREATE TABLE [Application].[Logs](
	[Message] NVARCHAR(4000) NOT NULL,
	[Level] VARCHAR(16) NOT NULL,
	[EventTime] DATETIME2 (7) NOT NULL,
	[LogEvent] NVARCHAR(max) NULL,
	INDEX CCX_Application_Logs CLUSTERED COLUMNSTORE
)
GO


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'CLUSTERED COLUMNSTORE INDEX that compress application log.', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Logs', @level2type = N'INDEX', @level2name = N'CCX_Application_Logs';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Application logs that are stored in database', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Logs';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Logged message', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Logs', @level2type = N'COLUMN', @level2name = N'Message';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Severity of the log entry', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Logs', @level2type = N'COLUMN', @level2name = N'Level';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Time when the record is logged', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Logs', @level2type = N'COLUMN', @level2name = 'EventTime';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Details about the logged event', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'Logs', @level2type = N'COLUMN', @level2name = N'LogEvent';


GO

-- File: PaymentMethods.sql
﻿CREATE TABLE [Application].[PaymentMethods] (
    [PaymentMethodID]   INT                                         CONSTRAINT [DF_Application_PaymentMethods_PaymentMethodID] DEFAULT (NEXT VALUE FOR [Sequences].[PaymentMethodID]) NOT NULL,
    [PaymentMethodName] NVARCHAR (50)                               NOT NULL,
    [LastEditedBy]      INT                                         NOT NULL,
    [ValidFrom]         DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]           DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_Application_PaymentMethods] PRIMARY KEY CLUSTERED ([PaymentMethodID] ASC),
    CONSTRAINT [FK_Application_PaymentMethods_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [UQ_Application_PaymentMethods_PaymentMethodName] UNIQUE NONCLUSTERED ([PaymentMethodName] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Application].[PaymentMethods_Archive], DATA_CONSISTENCY_CHECK=ON));


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Ways that payments can be made (ie: cash, check, EFT, etc.', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'PaymentMethods';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a payment type within the database', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'PaymentMethods', @level2type = N'COLUMN', @level2name = N'PaymentMethodID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Full name of ways that customers can make payments or that suppliers can be paid', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'PaymentMethods', @level2type = N'COLUMN', @level2name = N'PaymentMethodName';


GO

-- File: PaymentMethods_Archive.sql
﻿CREATE TABLE [Application].[PaymentMethods_Archive] (
    [PaymentMethodID]   INT           NOT NULL,
    [PaymentMethodName] NVARCHAR (50) NOT NULL,
    [LastEditedBy]      INT           NOT NULL,
    [ValidFrom]         DATETIME2 (7) NOT NULL,
    [ValidTo]           DATETIME2 (7) NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_PaymentMethods_Archive]
    ON [Application].[PaymentMethods_Archive]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);


GO

-- File: People.sql
﻿CREATE TABLE [Application].[People] (
    [PersonID]                INT                                         CONSTRAINT [DF_Application_People_PersonID] DEFAULT (NEXT VALUE FOR [Sequences].[PersonID]) NOT NULL,
    [FullName]                NVARCHAR (50)                               NOT NULL,
    [PreferredName]           NVARCHAR (50)                               NOT NULL,
    [SearchName]              AS                                          (concat([PreferredName],N' ',[FullName])) PERSISTED NOT NULL,
    [IsPermittedToLogon]      BIT                                         NOT NULL,
    [LogonName]               NVARCHAR (256)                              NULL,
    [IsExternalLogonProvider] BIT                                         NOT NULL,
    [HashedPassword]          VARBINARY (MAX)                             NULL,
    [IsSystemUser]            BIT                                         NOT NULL,
    [IsEmployee]              BIT                                         NOT NULL,
    [IsSalesperson]           BIT                                         NOT NULL,
    [UserPreferences]         NVARCHAR (MAX)                              NULL,
    [PhoneNumber]             NVARCHAR (20)                               NULL,
    [FaxNumber]               NVARCHAR (20)                               NULL,
    [EmailAddress]            NVARCHAR (256)                              NULL,
    [Photo]                   VARBINARY (MAX)                             NULL,
    [CustomFields]            NVARCHAR (MAX)                              NULL,
    [OtherLanguages]          AS                                          (json_query([CustomFields],N'$.OtherLanguages')),
    [LastEditedBy]            INT                                         NOT NULL,
    [ValidFrom]               DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]                 DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_Application_People] PRIMARY KEY CLUSTERED ([PersonID] ASC),
    CONSTRAINT [FK_Application_People_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Application].[People_Archive], DATA_CONSISTENCY_CHECK=ON));




GO
CREATE NONCLUSTERED INDEX [IX_Application_People_IsEmployee]
    ON [Application].[People]([IsEmployee] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Application_People_IsSalesperson]
    ON [Application].[People]([IsSalesperson] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Application_People_FullName]
    ON [Application].[People]([FullName] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Application_People_Perf_20160301_05]
    ON [Application].[People]([IsPermittedToLogon] ASC, [PersonID] ASC)
    INCLUDE([FullName], [EmailAddress]);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Allows quickly locating employees', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'INDEX', @level2name = N'IX_Application_People_IsEmployee';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Allows quickly locating salespeople', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'INDEX', @level2name = N'IX_Application_People_IsSalesperson';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Improves performance of name-related queries', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'INDEX', @level2name = N'IX_Application_People_FullName';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Improves performance of order picking and invoicing', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'INDEX', @level2name = N'IX_Application_People_Perf_20160301_05';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'People known to the application (staff, customer contacts, supplier contacts)', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a person within the database', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'COLUMN', @level2name = N'PersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Full name for this person', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'COLUMN', @level2name = N'FullName';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Name that this person prefers to be called', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'COLUMN', @level2name = N'PreferredName';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Name to build full text search on (computed column)', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'COLUMN', @level2name = N'SearchName';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Is this person permitted to log on?', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'COLUMN', @level2name = N'IsPermittedToLogon';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Person''s system logon name', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'COLUMN', @level2name = N'LogonName';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Is logon token provided by an external system?', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'COLUMN', @level2name = N'IsExternalLogonProvider';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Hash of password for users without external logon tokens', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'COLUMN', @level2name = N'HashedPassword';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Is the currently permitted to make online access?', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'COLUMN', @level2name = N'IsSystemUser';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Is this person an employee?', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'COLUMN', @level2name = N'IsEmployee';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Is this person a staff salesperson?', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'COLUMN', @level2name = N'IsSalesperson';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'User preferences related to the website (holds JSON data)', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'COLUMN', @level2name = N'UserPreferences';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Phone number', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'COLUMN', @level2name = N'PhoneNumber';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Fax number  ', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'COLUMN', @level2name = N'FaxNumber';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Email address for this person', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'COLUMN', @level2name = N'EmailAddress';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Photo of this person', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'COLUMN', @level2name = N'Photo';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Custom fields for employees and salespeople', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'COLUMN', @level2name = N'CustomFields';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Other languages spoken (computed column from custom fields)', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'People', @level2type = N'COLUMN', @level2name = N'OtherLanguages';


GO

-- File: People_Archive.sql
﻿CREATE TABLE [Application].[People_Archive] (
    [PersonID]                INT             NOT NULL,
    [FullName]                NVARCHAR (50)   NOT NULL,
    [PreferredName]           NVARCHAR (50)   NOT NULL,
    [SearchName]              NVARCHAR (101)  NOT NULL,
    [IsPermittedToLogon]      BIT             NOT NULL,
    [LogonName]               NVARCHAR (256)  NULL,
    [IsExternalLogonProvider] BIT             NOT NULL,
    [HashedPassword]          VARBINARY (MAX) NULL,
    [IsSystemUser]            BIT             NOT NULL,
    [IsEmployee]              BIT             NOT NULL,
    [IsSalesperson]           BIT             NOT NULL,
    [UserPreferences]         NVARCHAR (MAX)  NULL,
    [PhoneNumber]             NVARCHAR (20)   NULL,
    [FaxNumber]               NVARCHAR (20)   NULL,
    [EmailAddress]            NVARCHAR (256)  NULL,
    [Photo]                   VARBINARY (MAX) NULL,
    [CustomFields]            NVARCHAR (MAX)  NULL,
    [OtherLanguages]          NVARCHAR (MAX)  NULL,
    [LastEditedBy]            INT             NOT NULL,
    [ValidFrom]               DATETIME2 (7)   NOT NULL,
    [ValidTo]                 DATETIME2 (7)   NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_People_Archive]
    ON [Application].[People_Archive]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);


GO

-- File: StateProvinces.sql
﻿CREATE TABLE [Application].[StateProvinces] (
    [StateProvinceID]          INT                                         CONSTRAINT [DF_Application_StateProvinces_StateProvinceID] DEFAULT (NEXT VALUE FOR [Sequences].[StateProvinceID]) NOT NULL,
    [StateProvinceCode]        NVARCHAR (5)                                NOT NULL,
    [StateProvinceName]        NVARCHAR (50)                               NOT NULL,
    [CountryID]                INT                                         NOT NULL,
    [SalesTerritory]           NVARCHAR (50)                               NOT NULL,
    [Border]                   [sys].[geography]                           NULL,
    [LatestRecordedPopulation] BIGINT                                      NULL,
    [LastEditedBy]             INT                                         NOT NULL,
    [ValidFrom]                DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]                  DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_Application_StateProvinces] PRIMARY KEY CLUSTERED ([StateProvinceID] ASC),
    CONSTRAINT [FK_Application_StateProvinces_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Application_StateProvinces_CountryID_Application_Countries] FOREIGN KEY ([CountryID]) REFERENCES [Application].[Countries] ([CountryID]),
    CONSTRAINT [UQ_Application_StateProvinces_StateProvinceName] UNIQUE NONCLUSTERED ([StateProvinceName] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Application].[StateProvinces_Archive], DATA_CONSISTENCY_CHECK=ON));


GO
CREATE NONCLUSTERED INDEX [FK_Application_StateProvinces_CountryID]
    ON [Application].[StateProvinces]([CountryID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Application_StateProvinces_SalesTerritory]
    ON [Application].[StateProvinces]([SalesTerritory] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'StateProvinces', @level2type = N'INDEX', @level2name = N'FK_Application_StateProvinces_CountryID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Index used to quickly locate sales territories', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'StateProvinces', @level2type = N'INDEX', @level2name = N'IX_Application_StateProvinces_SalesTerritory';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'States or provinces that contain cities (including geographic location)', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'StateProvinces';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a state or province within the database', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'StateProvinces', @level2type = N'COLUMN', @level2name = N'StateProvinceID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Common code for this state or province (such as WA - Washington for the USA)', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'StateProvinces', @level2type = N'COLUMN', @level2name = N'StateProvinceCode';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Formal name of the state or province', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'StateProvinces', @level2type = N'COLUMN', @level2name = N'StateProvinceName';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Country for this StateProvince', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'StateProvinces', @level2type = N'COLUMN', @level2name = N'CountryID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Sales territory for this StateProvince', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'StateProvinces', @level2type = N'COLUMN', @level2name = N'SalesTerritory';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Geographic boundary of the state or province', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'StateProvinces', @level2type = N'COLUMN', @level2name = N'Border';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Latest available population for the StateProvince', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'StateProvinces', @level2type = N'COLUMN', @level2name = N'LatestRecordedPopulation';


GO

-- File: StateProvinces_Archive.sql
﻿CREATE TABLE [Application].[StateProvinces_Archive] (
    [StateProvinceID]          INT               NOT NULL,
    [StateProvinceCode]        NVARCHAR (5)      NOT NULL,
    [StateProvinceName]        NVARCHAR (50)     NOT NULL,
    [CountryID]                INT               NOT NULL,
    [SalesTerritory]           NVARCHAR (50)     NOT NULL,
    [Border]                   [sys].[geography] NULL,
    [LatestRecordedPopulation] BIGINT            NULL,
    [LastEditedBy]             INT               NOT NULL,
    [ValidFrom]                DATETIME2 (7)     NOT NULL,
    [ValidTo]                  DATETIME2 (7)     NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_StateProvinces_Archive]
    ON [Application].[StateProvinces_Archive]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);


GO

-- File: SystemParameters.sql
﻿CREATE TABLE [Application].[SystemParameters] (
    [SystemParameterID]    INT               CONSTRAINT [DF_Application_SystemParameters_SystemParameterID] DEFAULT (NEXT VALUE FOR [Sequences].[SystemParameterID]) NOT NULL,
    [DeliveryAddressLine1] NVARCHAR (60)     NOT NULL,
    [DeliveryAddressLine2] NVARCHAR (60)     NULL,
    [DeliveryCityID]       INT               NOT NULL,
    [DeliveryPostalCode]   NVARCHAR (10)     NOT NULL,
    [DeliveryLocation]     [sys].[geography] NOT NULL,
    [PostalAddressLine1]   NVARCHAR (60)     NOT NULL,
    [PostalAddressLine2]   NVARCHAR (60)     NULL,
    [PostalCityID]         INT               NOT NULL,
    [PostalPostalCode]     NVARCHAR (10)     NOT NULL,
    [ApplicationSettings]  NVARCHAR (MAX)    NOT NULL,
    [LastEditedBy]         INT               NOT NULL,
    [LastEditedWhen]       DATETIME2 (7)     CONSTRAINT [DF_Application_SystemParameters_LastEditedWhen] DEFAULT (sysdatetime()) NOT NULL,
    CONSTRAINT [PK_Application_SystemParameters] PRIMARY KEY CLUSTERED ([SystemParameterID] ASC),
    CONSTRAINT [FK_Application_SystemParameters_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Application_SystemParameters_DeliveryCityID_Application_Cities] FOREIGN KEY ([DeliveryCityID]) REFERENCES [Application].[Cities] ([CityID]),
    CONSTRAINT [FK_Application_SystemParameters_PostalCityID_Application_Cities] FOREIGN KEY ([PostalCityID]) REFERENCES [Application].[Cities] ([CityID])
);


GO
CREATE NONCLUSTERED INDEX [FK_Application_SystemParameters_DeliveryCityID]
    ON [Application].[SystemParameters]([DeliveryCityID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Application_SystemParameters_PostalCityID]
    ON [Application].[SystemParameters]([PostalCityID] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'SystemParameters', @level2type = N'INDEX', @level2name = N'FK_Application_SystemParameters_DeliveryCityID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'SystemParameters', @level2type = N'INDEX', @level2name = N'FK_Application_SystemParameters_PostalCityID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Any configurable parameters for the whole system', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'SystemParameters';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for row holding system parameters', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'SystemParameters', @level2type = N'COLUMN', @level2name = N'SystemParameterID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'First address line for the company', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'SystemParameters', @level2type = N'COLUMN', @level2name = N'DeliveryAddressLine1';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Second address line for the company', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'SystemParameters', @level2type = N'COLUMN', @level2name = N'DeliveryAddressLine2';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'ID of the city for this address', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'SystemParameters', @level2type = N'COLUMN', @level2name = N'DeliveryCityID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Postal code for the company', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'SystemParameters', @level2type = N'COLUMN', @level2name = N'DeliveryPostalCode';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Geographic location for the company office', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'SystemParameters', @level2type = N'COLUMN', @level2name = N'DeliveryLocation';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'First postal address line for the company', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'SystemParameters', @level2type = N'COLUMN', @level2name = N'PostalAddressLine1';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Second postaladdress line for the company', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'SystemParameters', @level2type = N'COLUMN', @level2name = N'PostalAddressLine2';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'ID of the city for this postaladdress', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'SystemParameters', @level2type = N'COLUMN', @level2name = N'PostalCityID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Postal code for the company when sending via mail', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'SystemParameters', @level2type = N'COLUMN', @level2name = N'PostalPostalCode';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'JSON-structured application settings', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'SystemParameters', @level2type = N'COLUMN', @level2name = N'ApplicationSettings';


GO

-- File: TransactionTypes.sql
﻿CREATE TABLE [Application].[TransactionTypes] (
    [TransactionTypeID]   INT                                         CONSTRAINT [DF_Application_TransactionTypes_TransactionTypeID] DEFAULT (NEXT VALUE FOR [Sequences].[TransactionTypeID]) NOT NULL,
    [TransactionTypeName] NVARCHAR (50)                               NOT NULL,
    [LastEditedBy]        INT                                         NOT NULL,
    [ValidFrom]           DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]             DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_Application_TransactionTypes] PRIMARY KEY CLUSTERED ([TransactionTypeID] ASC),
    CONSTRAINT [FK_Application_TransactionTypes_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [UQ_Application_TransactionTypes_TransactionTypeName] UNIQUE NONCLUSTERED ([TransactionTypeName] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Application].[TransactionTypes_Archive], DATA_CONSISTENCY_CHECK=ON));


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Types of customer, supplier, or stock transactions (ie: invoice, credit note, etc.)', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'TransactionTypes';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a transaction type within the database', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'TransactionTypes', @level2type = N'COLUMN', @level2name = N'TransactionTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Full name of the transaction type', @level0type = N'SCHEMA', @level0name = N'Application', @level1type = N'TABLE', @level1name = N'TransactionTypes', @level2type = N'COLUMN', @level2name = N'TransactionTypeName';


GO

-- File: TransactionTypes_Archive.sql
﻿CREATE TABLE [Application].[TransactionTypes_Archive] (
    [TransactionTypeID]   INT           NOT NULL,
    [TransactionTypeName] NVARCHAR (50) NOT NULL,
    [LastEditedBy]        INT           NOT NULL,
    [ValidFrom]           DATETIME2 (7) NOT NULL,
    [ValidTo]             DATETIME2 (7) NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_TransactionTypes_Archive]
    ON [Application].[TransactionTypes_Archive]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);


GO

-- File: AreaCode.sql
﻿CREATE TABLE [DataLoadSimulation].[AreaCode]
(
    StateProvinceCode NVARCHAR(4)
  , AreaCode          NVARCHAR(4)
)

GO

-- File: ColdRoomTemperatures_temp.sql
﻿CREATE TABLE DataLoadSimulation.[ColdRoomTemperatures_temp] (
    [ColdRoomTemperatureID] BIGINT                                      NOT NULL,
    [ColdRoomSensorNumber]  INT                                         NOT NULL,
    [RecordedWhen]          DATETIME2 (7)                               NOT NULL,
    [Temperature]           DECIMAL (10, 2)                             NOT NULL,
    [ValidFrom]             DATETIME2 (7)								NOT NULL,
    [ValidTo]               DATETIME2 (7)								NOT NULL,
    INDEX [IX_DataSimulation_ColdRoomTemperatures_ColdRoomSensorNumber]
		NONCLUSTERED HASH ([ColdRoomSensorNumber]) WITH (BUCKET_COUNT=100000)
		-- 100K was chosen as bucket_count, since this number is always a good starting point, and
		--   number of sensors is not expected to exceed 1 million. (if it were to exceed 1 million,
		--   a performance degradation would be expected)
)
WITH (MEMORY_OPTIMIZED = ON, DURABILITY=SCHEMA_ONLY);


GO

-- File: FicticiousNamePool.sql
﻿CREATE TABLE [DataLoadSimulation].[FicticiousNamePool]
(
    FullName      NVARCHAR(50)
  , PreferredName NVARCHAR(25)
  , LastName      NVARCHAR(25)
  , ToEmail       NVARCHAR(75)
)

GO

-- File: SeasonVariation.sql
﻿	CREATE TABLE DataLoadSimulation.SeasonVariation
	(
		[Year] int NOT NULL,
		[Season] smallint NOT NULL,
		[YearlyVariation] float NOT NULL,
		[SeasonalVariation] float NOT NULL,
		CONSTRAINT PK_DataLoadSimulation_SeasonVariation PRIMARY KEY
			(Year, Season)
	)
GO

-- File: PurchaseOrderLines.sql
﻿CREATE TABLE [Purchasing].[PurchaseOrderLines] (
    [PurchaseOrderLineID]       INT             CONSTRAINT [DF_Purchasing_PurchaseOrderLines_PurchaseOrderLineID] DEFAULT (NEXT VALUE FOR [Sequences].[PurchaseOrderLineID]) NOT NULL,
    [PurchaseOrderID]           INT             NOT NULL,
    [StockItemID]               INT             NOT NULL,
    [OrderedOuters]             INT             NOT NULL,
    [Description]               NVARCHAR (100)  NOT NULL,
    [ReceivedOuters]            INT             NOT NULL,
    [PackageTypeID]             INT             NOT NULL,
    [ExpectedUnitPricePerOuter] DECIMAL (18, 2) NULL,
    [LastReceiptDate]           DATE            NULL,
    [IsOrderLineFinalized]      BIT             NOT NULL,
    [LastEditedBy]              INT             NOT NULL,
    [LastEditedWhen]            DATETIME2 (7)   CONSTRAINT [DF_Purchasing_PurchaseOrderLines_LastEditedWhen] DEFAULT (sysdatetime()) NOT NULL,
    CONSTRAINT [PK_Purchasing_PurchaseOrderLines] PRIMARY KEY CLUSTERED ([PurchaseOrderLineID] ASC),
    CONSTRAINT [FK_Purchasing_PurchaseOrderLines_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Purchasing_PurchaseOrderLines_PackageTypeID_Warehouse_PackageTypes] FOREIGN KEY ([PackageTypeID]) REFERENCES [Warehouse].[PackageTypes] ([PackageTypeID]),
    CONSTRAINT [FK_Purchasing_PurchaseOrderLines_PurchaseOrderID_Purchasing_PurchaseOrders] FOREIGN KEY ([PurchaseOrderID]) REFERENCES [Purchasing].[PurchaseOrders] ([PurchaseOrderID]),
    CONSTRAINT [FK_Purchasing_PurchaseOrderLines_StockItemID_Warehouse_StockItems] FOREIGN KEY ([StockItemID]) REFERENCES [Warehouse].[StockItems] ([StockItemID])
);


GO
CREATE NONCLUSTERED INDEX [FK_Purchasing_PurchaseOrderLines_PurchaseOrderID]
    ON [Purchasing].[PurchaseOrderLines]([PurchaseOrderID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Purchasing_PurchaseOrderLines_StockItemID]
    ON [Purchasing].[PurchaseOrderLines]([StockItemID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Purchasing_PurchaseOrderLines_PackageTypeID]
    ON [Purchasing].[PurchaseOrderLines]([PackageTypeID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Purchasing_PurchaseOrderLines_Perf_20160301_4]
    ON [Purchasing].[PurchaseOrderLines]([IsOrderLineFinalized] ASC, [StockItemID] ASC)
    INCLUDE([OrderedOuters], [ReceivedOuters]);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrderLines', @level2type = N'INDEX', @level2name = N'FK_Purchasing_PurchaseOrderLines_PurchaseOrderID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrderLines', @level2type = N'INDEX', @level2name = N'FK_Purchasing_PurchaseOrderLines_StockItemID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrderLines', @level2type = N'INDEX', @level2name = N'FK_Purchasing_PurchaseOrderLines_PackageTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Improves performance of order picking and invoicing', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrderLines', @level2type = N'INDEX', @level2name = N'IX_Purchasing_PurchaseOrderLines_Perf_20160301_4';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Detail lines from supplier purchase orders', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrderLines';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a line on a purchase order within the database', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrderLines', @level2type = N'COLUMN', @level2name = N'PurchaseOrderLineID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Purchase order that this line is associated with', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrderLines', @level2type = N'COLUMN', @level2name = N'PurchaseOrderID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Stock item for this purchase order line', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrderLines', @level2type = N'COLUMN', @level2name = N'StockItemID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity of the stock item that is ordered', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrderLines', @level2type = N'COLUMN', @level2name = N'OrderedOuters';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Description of the item to be supplied (Often the stock item name but could be supplier description)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrderLines', @level2type = N'COLUMN', @level2name = N'Description';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total quantity of the stock item that has been received so far', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrderLines', @level2type = N'COLUMN', @level2name = N'ReceivedOuters';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Type of package received', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrderLines', @level2type = N'COLUMN', @level2name = N'PackageTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'The unit price that we expect to be charged', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrderLines', @level2type = N'COLUMN', @level2name = N'ExpectedUnitPricePerOuter';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'The last date on which this stock item was received for this purchase order', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrderLines', @level2type = N'COLUMN', @level2name = N'LastReceiptDate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Is this purchase order line now considered finalized? (Receipted quantities and weights are often not precise)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrderLines', @level2type = N'COLUMN', @level2name = N'IsOrderLineFinalized';


GO

-- File: PurchaseOrders.sql
﻿CREATE TABLE [Purchasing].[PurchaseOrders] (
    [PurchaseOrderID]      INT            CONSTRAINT [DF_Purchasing_PurchaseOrders_PurchaseOrderID] DEFAULT (NEXT VALUE FOR [Sequences].[PurchaseOrderID]) NOT NULL,
    [SupplierID]           INT            NOT NULL,
    [OrderDate]            DATE           NOT NULL,
    [DeliveryMethodID]     INT            NOT NULL,
    [ContactPersonID]      INT            NOT NULL,
    [ExpectedDeliveryDate] DATE           NULL,
    [SupplierReference]    NVARCHAR (20)  NULL,
    [IsOrderFinalized]     BIT            NOT NULL,
    [Comments]             NVARCHAR (MAX) NULL,
    [InternalComments]     NVARCHAR (MAX) NULL,
    [LastEditedBy]         INT            NOT NULL,
    [LastEditedWhen]       DATETIME2 (7)  CONSTRAINT [DF_Purchasing_PurchaseOrders_LastEditedWhen] DEFAULT (sysdatetime()) NOT NULL,
    CONSTRAINT [PK_Purchasing_PurchaseOrders] PRIMARY KEY CLUSTERED ([PurchaseOrderID] ASC),
    CONSTRAINT [FK_Purchasing_PurchaseOrders_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Purchasing_PurchaseOrders_ContactPersonID_Application_People] FOREIGN KEY ([ContactPersonID]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Purchasing_PurchaseOrders_DeliveryMethodID_Application_DeliveryMethods] FOREIGN KEY ([DeliveryMethodID]) REFERENCES [Application].[DeliveryMethods] ([DeliveryMethodID]),
    CONSTRAINT [FK_Purchasing_PurchaseOrders_SupplierID_Purchasing_Suppliers] FOREIGN KEY ([SupplierID]) REFERENCES [Purchasing].[Suppliers] ([SupplierID])
);


GO
CREATE NONCLUSTERED INDEX [FK_Purchasing_PurchaseOrders_SupplierID]
    ON [Purchasing].[PurchaseOrders]([SupplierID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Purchasing_PurchaseOrders_DeliveryMethodID]
    ON [Purchasing].[PurchaseOrders]([DeliveryMethodID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Purchasing_PurchaseOrders_ContactPersonID]
    ON [Purchasing].[PurchaseOrders]([ContactPersonID] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrders', @level2type = N'INDEX', @level2name = N'FK_Purchasing_PurchaseOrders_SupplierID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrders', @level2type = N'INDEX', @level2name = N'FK_Purchasing_PurchaseOrders_DeliveryMethodID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrders', @level2type = N'INDEX', @level2name = N'FK_Purchasing_PurchaseOrders_ContactPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Details of supplier purchase orders', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrders';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a purchase order within the database', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrders', @level2type = N'COLUMN', @level2name = N'PurchaseOrderID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier for this purchase order', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrders', @level2type = N'COLUMN', @level2name = N'SupplierID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Date that this purchase order was raised', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrders', @level2type = N'COLUMN', @level2name = N'OrderDate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'How this purchase order should be delivered', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrders', @level2type = N'COLUMN', @level2name = N'DeliveryMethodID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'The person who is the primary contact for this purchase order', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrders', @level2type = N'COLUMN', @level2name = N'ContactPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Expected delivery date for this purchase order', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrders', @level2type = N'COLUMN', @level2name = N'ExpectedDeliveryDate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier reference for our organization (might be our account number at the supplier)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrders', @level2type = N'COLUMN', @level2name = N'SupplierReference';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Is this purchase order now considered finalized?', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrders', @level2type = N'COLUMN', @level2name = N'IsOrderFinalized';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Any comments related this purchase order (comments sent to the supplier)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrders', @level2type = N'COLUMN', @level2name = N'Comments';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Any internal comments related this purchase order (comments for internal reference only and not sent to the supplier)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'PurchaseOrders', @level2type = N'COLUMN', @level2name = N'InternalComments';


GO

-- File: SupplierCategories.sql
﻿CREATE TABLE [Purchasing].[SupplierCategories] (
    [SupplierCategoryID]   INT                                         CONSTRAINT [DF_Purchasing_SupplierCategories_SupplierCategoryID] DEFAULT (NEXT VALUE FOR [Sequences].[SupplierCategoryID]) NOT NULL,
    [SupplierCategoryName] NVARCHAR (50)                               NOT NULL,
    [LastEditedBy]         INT                                         NOT NULL,
    [ValidFrom]            DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]              DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_Purchasing_SupplierCategories] PRIMARY KEY CLUSTERED ([SupplierCategoryID] ASC),
    CONSTRAINT [FK_Purchasing_SupplierCategories_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [UQ_Purchasing_SupplierCategories_SupplierCategoryName] UNIQUE NONCLUSTERED ([SupplierCategoryName] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Purchasing].[SupplierCategories_Archive], DATA_CONSISTENCY_CHECK=ON));


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Categories for suppliers (ie novelties, toys, clothing, packaging, etc.)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierCategories';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a supplier category within the database', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierCategories', @level2type = N'COLUMN', @level2name = N'SupplierCategoryID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Full name of the category that suppliers can be assigned to', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierCategories', @level2type = N'COLUMN', @level2name = N'SupplierCategoryName';


GO

-- File: SupplierCategories_Archive.sql
﻿CREATE TABLE [Purchasing].[SupplierCategories_Archive] (
    [SupplierCategoryID]   INT           NOT NULL,
    [SupplierCategoryName] NVARCHAR (50) NOT NULL,
    [LastEditedBy]         INT           NOT NULL,
    [ValidFrom]            DATETIME2 (7) NOT NULL,
    [ValidTo]              DATETIME2 (7) NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_SupplierCategories_Archive]
    ON [Purchasing].[SupplierCategories_Archive]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);


GO

-- File: SupplierTransactions.sql
﻿CREATE TABLE [Purchasing].[SupplierTransactions] (
    [SupplierTransactionID] INT             CONSTRAINT [DF_Purchasing_SupplierTransactions_SupplierTransactionID] DEFAULT (NEXT VALUE FOR [Sequences].[TransactionID]) NOT NULL,
    [SupplierID]            INT             NOT NULL,
    [TransactionTypeID]     INT             NOT NULL,
    [PurchaseOrderID]       INT             NULL,
    [PaymentMethodID]       INT             NULL,
    [SupplierInvoiceNumber] NVARCHAR (20)   NULL,
    [TransactionDate]       DATE            NOT NULL,
    [AmountExcludingTax]    DECIMAL (18, 2) NOT NULL,
    [TaxAmount]             DECIMAL (18, 2) NOT NULL,
    [TransactionAmount]     DECIMAL (18, 2) NOT NULL,
    [OutstandingBalance]    DECIMAL (18, 2) NOT NULL,
    [FinalizationDate]      DATE            NULL,
    [IsFinalized]           AS              (case when [FinalizationDate] IS NULL then CONVERT([bit],(0)) else CONVERT([bit],(1)) end) PERSISTED,
    [LastEditedBy]          INT             NOT NULL,
    [LastEditedWhen]        DATETIME2 (7)   CONSTRAINT [DF_Purchasing_SupplierTransactions_LastEditedWhen] DEFAULT (sysdatetime()) NOT NULL,
    CONSTRAINT [PK_Purchasing_SupplierTransactions] PRIMARY KEY NONCLUSTERED ([SupplierTransactionID] ASC),
    CONSTRAINT [FK_Purchasing_SupplierTransactions_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Purchasing_SupplierTransactions_PaymentMethodID_Application_PaymentMethods] FOREIGN KEY ([PaymentMethodID]) REFERENCES [Application].[PaymentMethods] ([PaymentMethodID]),
    CONSTRAINT [FK_Purchasing_SupplierTransactions_PurchaseOrderID_Purchasing_PurchaseOrders] FOREIGN KEY ([PurchaseOrderID]) REFERENCES [Purchasing].[PurchaseOrders] ([PurchaseOrderID]),
    CONSTRAINT [FK_Purchasing_SupplierTransactions_SupplierID_Purchasing_Suppliers] FOREIGN KEY ([SupplierID]) REFERENCES [Purchasing].[Suppliers] ([SupplierID]),
    CONSTRAINT [FK_Purchasing_SupplierTransactions_TransactionTypeID_Application_TransactionTypes] FOREIGN KEY ([TransactionTypeID]) REFERENCES [Application].[TransactionTypes] ([TransactionTypeID])
);


GO
CREATE CLUSTERED INDEX [CX_Purchasing_SupplierTransactions]
    ON [Purchasing].[SupplierTransactions]([TransactionDate] ASC)
    ON [PS_TransactionDate] ([TransactionDate]);


GO
CREATE NONCLUSTERED INDEX [FK_Purchasing_SupplierTransactions_SupplierID]
    ON [Purchasing].[SupplierTransactions]([SupplierID] ASC)
    ON [PS_TransactionDate] ([TransactionDate]);


GO
CREATE NONCLUSTERED INDEX [FK_Purchasing_SupplierTransactions_TransactionTypeID]
    ON [Purchasing].[SupplierTransactions]([TransactionTypeID] ASC)
    ON [PS_TransactionDate] ([TransactionDate]);


GO
CREATE NONCLUSTERED INDEX [FK_Purchasing_SupplierTransactions_PurchaseOrderID]
    ON [Purchasing].[SupplierTransactions]([PurchaseOrderID] ASC)
    ON [PS_TransactionDate] ([TransactionDate]);


GO
CREATE NONCLUSTERED INDEX [FK_Purchasing_SupplierTransactions_PaymentMethodID]
    ON [Purchasing].[SupplierTransactions]([PaymentMethodID] ASC)
    ON [PS_TransactionDate] ([TransactionDate]);


GO
CREATE NONCLUSTERED INDEX [IX_Purchasing_SupplierTransactions_IsFinalized]
    ON [Purchasing].[SupplierTransactions]([IsFinalized] ASC)
    ON [PS_TransactionDate] ([TransactionDate]);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierTransactions', @level2type = N'INDEX', @level2name = N'FK_Purchasing_SupplierTransactions_SupplierID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierTransactions', @level2type = N'INDEX', @level2name = N'FK_Purchasing_SupplierTransactions_TransactionTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierTransactions', @level2type = N'INDEX', @level2name = N'FK_Purchasing_SupplierTransactions_PurchaseOrderID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierTransactions', @level2type = N'INDEX', @level2name = N'FK_Purchasing_SupplierTransactions_PaymentMethodID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Index used to quickly locate unfinalized transactions', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierTransactions', @level2type = N'INDEX', @level2name = N'IX_Purchasing_SupplierTransactions_IsFinalized';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'All financial transactions that are supplier-related', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierTransactions';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used to refer to a supplier transaction within the database', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierTransactions', @level2type = N'COLUMN', @level2name = N'SupplierTransactionID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier for this transaction', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierTransactions', @level2type = N'COLUMN', @level2name = N'SupplierID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Type of transaction', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierTransactions', @level2type = N'COLUMN', @level2name = N'TransactionTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'ID of an purchase order (for transactions associated with a purchase order)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierTransactions', @level2type = N'COLUMN', @level2name = N'PurchaseOrderID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'ID of a payment method (for transactions involving payments)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierTransactions', @level2type = N'COLUMN', @level2name = N'PaymentMethodID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Invoice number for an invoice received from the supplier', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierTransactions', @level2type = N'COLUMN', @level2name = N'SupplierInvoiceNumber';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Date for the transaction', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierTransactions', @level2type = N'COLUMN', @level2name = N'TransactionDate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Transaction amount (excluding tax)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierTransactions', @level2type = N'COLUMN', @level2name = N'AmountExcludingTax';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Tax amount calculated', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierTransactions', @level2type = N'COLUMN', @level2name = N'TaxAmount';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Transaction amount (including tax)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierTransactions', @level2type = N'COLUMN', @level2name = N'TransactionAmount';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Amount still outstanding for this transaction', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierTransactions', @level2type = N'COLUMN', @level2name = N'OutstandingBalance';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Date that this transaction was finalized (if it has been)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierTransactions', @level2type = N'COLUMN', @level2name = N'FinalizationDate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Is this transaction finalized (invoices, credits and payments have been matched)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'SupplierTransactions', @level2type = N'COLUMN', @level2name = N'IsFinalized';


GO

-- File: Suppliers.sql
﻿CREATE TABLE [Purchasing].[Suppliers] (
    [SupplierID]               INT                                                CONSTRAINT [DF_Purchasing_Suppliers_SupplierID] DEFAULT (NEXT VALUE FOR [Sequences].[SupplierID]) NOT NULL,
    [SupplierName]             NVARCHAR (100)                                     NOT NULL,
    [SupplierCategoryID]       INT                                                NOT NULL,
    [PrimaryContactPersonID]   INT                                                NOT NULL,
    [AlternateContactPersonID] INT                                                NOT NULL,
    [DeliveryMethodID]         INT                                                NULL,
    [DeliveryCityID]           INT                                                NOT NULL,
    [PostalCityID]             INT                                                NOT NULL,
    [SupplierReference]        NVARCHAR (20)                                      NULL,
    [BankAccountName]          NVARCHAR (50) MASKED WITH (FUNCTION = 'default()') NULL,
    [BankAccountBranch]        NVARCHAR (50) MASKED WITH (FUNCTION = 'default()') NULL,
    [BankAccountCode]          NVARCHAR (20) MASKED WITH (FUNCTION = 'default()') NULL,
    [BankAccountNumber]        NVARCHAR (20) MASKED WITH (FUNCTION = 'default()') NULL,
    [BankInternationalCode]    NVARCHAR (20) MASKED WITH (FUNCTION = 'default()') NULL,
    [PaymentDays]              INT                                                NOT NULL,
    [InternalComments]         NVARCHAR (MAX)                                     NULL,
    [PhoneNumber]              NVARCHAR (20)                                      NOT NULL,
    [FaxNumber]                NVARCHAR (20)                                      NOT NULL,
    [WebsiteURL]               NVARCHAR (256)                                     NOT NULL,
    [DeliveryAddressLine1]     NVARCHAR (60)                                      NOT NULL,
    [DeliveryAddressLine2]     NVARCHAR (60)                                      NULL,
    [DeliveryPostalCode]       NVARCHAR (10)                                      NOT NULL,
    [DeliveryLocation]         [sys].[geography]                                  NULL,
    [PostalAddressLine1]       NVARCHAR (60)                                      NOT NULL,
    [PostalAddressLine2]       NVARCHAR (60)                                      NULL,
    [PostalPostalCode]         NVARCHAR (10)                                      NOT NULL,
    [LastEditedBy]             INT                                                NOT NULL,
    [ValidFrom]                DATETIME2 (7) GENERATED ALWAYS AS ROW START        NOT NULL,
    [ValidTo]                  DATETIME2 (7) GENERATED ALWAYS AS ROW END          NOT NULL,
    CONSTRAINT [PK_Purchasing_Suppliers] PRIMARY KEY CLUSTERED ([SupplierID] ASC),
    CONSTRAINT [FK_Purchasing_Suppliers_AlternateContactPersonID_Application_People] FOREIGN KEY ([AlternateContactPersonID]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Purchasing_Suppliers_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Purchasing_Suppliers_DeliveryCityID_Application_Cities] FOREIGN KEY ([DeliveryCityID]) REFERENCES [Application].[Cities] ([CityID]),
    CONSTRAINT [FK_Purchasing_Suppliers_DeliveryMethodID_Application_DeliveryMethods] FOREIGN KEY ([DeliveryMethodID]) REFERENCES [Application].[DeliveryMethods] ([DeliveryMethodID]),
    CONSTRAINT [FK_Purchasing_Suppliers_PostalCityID_Application_Cities] FOREIGN KEY ([PostalCityID]) REFERENCES [Application].[Cities] ([CityID]),
    CONSTRAINT [FK_Purchasing_Suppliers_PrimaryContactPersonID_Application_People] FOREIGN KEY ([PrimaryContactPersonID]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Purchasing_Suppliers_SupplierCategoryID_Purchasing_SupplierCategories] FOREIGN KEY ([SupplierCategoryID]) REFERENCES [Purchasing].[SupplierCategories] ([SupplierCategoryID]),
    CONSTRAINT [UQ_Purchasing_Suppliers_SupplierName] UNIQUE NONCLUSTERED ([SupplierName] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Purchasing].[Suppliers_Archive], DATA_CONSISTENCY_CHECK=ON));




GO
CREATE NONCLUSTERED INDEX [FK_Purchasing_Suppliers_SupplierCategoryID]
    ON [Purchasing].[Suppliers]([SupplierCategoryID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Purchasing_Suppliers_PrimaryContactPersonID]
    ON [Purchasing].[Suppliers]([PrimaryContactPersonID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Purchasing_Suppliers_AlternateContactPersonID]
    ON [Purchasing].[Suppliers]([AlternateContactPersonID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Purchasing_Suppliers_DeliveryMethodID]
    ON [Purchasing].[Suppliers]([DeliveryMethodID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Purchasing_Suppliers_DeliveryCityID]
    ON [Purchasing].[Suppliers]([DeliveryCityID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Purchasing_Suppliers_PostalCityID]
    ON [Purchasing].[Suppliers]([PostalCityID] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'INDEX', @level2name = N'FK_Purchasing_Suppliers_SupplierCategoryID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'INDEX', @level2name = N'FK_Purchasing_Suppliers_PrimaryContactPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'INDEX', @level2name = N'FK_Purchasing_Suppliers_AlternateContactPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'INDEX', @level2name = N'FK_Purchasing_Suppliers_DeliveryMethodID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'INDEX', @level2name = N'FK_Purchasing_Suppliers_DeliveryCityID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'INDEX', @level2name = N'FK_Purchasing_Suppliers_PostalCityID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Main entity table for suppliers (organizations)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a supplier within the database', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'SupplierID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier''s full name (usually a trading name)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'SupplierName';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier''s category', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'SupplierCategoryID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Primary contact', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'PrimaryContactPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Alternate contact', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'AlternateContactPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Standard delivery method for stock items received from this supplier', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'DeliveryMethodID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'ID of the delivery city for this address', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'DeliveryCityID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'ID of the mailing city for this address', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'PostalCityID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier reference for our organization (might be our account number at the supplier)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'SupplierReference';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier''s bank account name (ie name on the account)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'BankAccountName';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier''s bank branch', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'BankAccountBranch';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier''s bank account code (usually a numeric reference for the bank branch)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'BankAccountCode';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier''s bank account number', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'BankAccountNumber';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier''s bank''s international code (such as a SWIFT code)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'BankInternationalCode';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Number of days for payment of an invoice (ie payment terms)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'PaymentDays';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Internal comments (not exposed outside organization)', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'InternalComments';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Phone number', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'PhoneNumber';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Fax number  ', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'FaxNumber';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'URL for the website for this supplier', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'WebsiteURL';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'First delivery address line for the supplier', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'DeliveryAddressLine1';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Second delivery address line for the supplier', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'DeliveryAddressLine2';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Delivery postal code for the supplier', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'DeliveryPostalCode';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Geographic location for the supplier''s office/warehouse', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'DeliveryLocation';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'First postal address line for the supplier', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'PostalAddressLine1';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Second postal address line for the supplier', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'PostalAddressLine2';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Postal code for the supplier when sending by mail', @level0type = N'SCHEMA', @level0name = N'Purchasing', @level1type = N'TABLE', @level1name = N'Suppliers', @level2type = N'COLUMN', @level2name = N'PostalPostalCode';


GO

-- File: Suppliers_Archive.sql
﻿CREATE TABLE [Purchasing].[Suppliers_Archive] (
    [SupplierID]               INT                                                NOT NULL,
    [SupplierName]             NVARCHAR (100)                                     NOT NULL,
    [SupplierCategoryID]       INT                                                NOT NULL,
    [PrimaryContactPersonID]   INT                                                NOT NULL,
    [AlternateContactPersonID] INT                                                NOT NULL,
    [DeliveryMethodID]         INT                                                NULL,
    [DeliveryCityID]           INT                                                NOT NULL,
    [PostalCityID]             INT                                                NOT NULL,
    [SupplierReference]        NVARCHAR (20)                                      NULL,
    [BankAccountName]          NVARCHAR (50) MASKED WITH (FUNCTION = 'default()') NULL,
    [BankAccountBranch]        NVARCHAR (50) MASKED WITH (FUNCTION = 'default()') NULL,
    [BankAccountCode]          NVARCHAR (20) MASKED WITH (FUNCTION = 'default()') NULL,
    [BankAccountNumber]        NVARCHAR (20) MASKED WITH (FUNCTION = 'default()') NULL,
    [BankInternationalCode]    NVARCHAR (20) MASKED WITH (FUNCTION = 'default()') NULL,
    [PaymentDays]              INT                                                NOT NULL,
    [InternalComments]         NVARCHAR (MAX)                                     NULL,
    [PhoneNumber]              NVARCHAR (20)                                      NOT NULL,
    [FaxNumber]                NVARCHAR (20)                                      NOT NULL,
    [WebsiteURL]               NVARCHAR (256)                                     NOT NULL,
    [DeliveryAddressLine1]     NVARCHAR (60)                                      NOT NULL,
    [DeliveryAddressLine2]     NVARCHAR (60)                                      NULL,
    [DeliveryPostalCode]       NVARCHAR (10)                                      NOT NULL,
    [DeliveryLocation]         [sys].[geography]                                  NULL,
    [PostalAddressLine1]       NVARCHAR (60)                                      NOT NULL,
    [PostalAddressLine2]       NVARCHAR (60)                                      NULL,
    [PostalPostalCode]         NVARCHAR (10)                                      NOT NULL,
    [LastEditedBy]             INT                                                NOT NULL,
    [ValidFrom]                DATETIME2 (7)                                      NOT NULL,
    [ValidTo]                  DATETIME2 (7)                                      NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_Suppliers_Archive]
    ON [Purchasing].[Suppliers_Archive]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);


GO

-- File: BuyingGroups.sql
﻿CREATE TABLE [Sales].[BuyingGroups] (
    [BuyingGroupID]   INT                                         CONSTRAINT [DF_Sales_BuyingGroups_BuyingGroupID] DEFAULT (NEXT VALUE FOR [Sequences].[BuyingGroupID]) NOT NULL,
    [BuyingGroupName] NVARCHAR (50)                               NOT NULL,
    [LastEditedBy]    INT                                         NOT NULL,
    [ValidFrom]       DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]         DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_Sales_BuyingGroups] PRIMARY KEY CLUSTERED ([BuyingGroupID] ASC),
    CONSTRAINT [FK_Sales_BuyingGroups_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [UQ_Sales_BuyingGroups_BuyingGroupName] UNIQUE NONCLUSTERED ([BuyingGroupName] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Sales].[BuyingGroups_Archive], DATA_CONSISTENCY_CHECK=ON));


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Customer organizations can be part of groups that exert greater buying power', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'BuyingGroups';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a buying group within the database', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'BuyingGroups', @level2type = N'COLUMN', @level2name = N'BuyingGroupID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Full name of a buying group that customers can be members of', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'BuyingGroups', @level2type = N'COLUMN', @level2name = N'BuyingGroupName';


GO

-- File: BuyingGroups_Archive.sql
﻿CREATE TABLE [Sales].[BuyingGroups_Archive] (
    [BuyingGroupID]   INT           NOT NULL,
    [BuyingGroupName] NVARCHAR (50) NOT NULL,
    [LastEditedBy]    INT           NOT NULL,
    [ValidFrom]       DATETIME2 (7) NOT NULL,
    [ValidTo]         DATETIME2 (7) NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_BuyingGroups_Archive]
    ON [Sales].[BuyingGroups_Archive]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);


GO

-- File: CustomerCategories.sql
﻿CREATE TABLE [Sales].[CustomerCategories] (
    [CustomerCategoryID]   INT                                         CONSTRAINT [DF_Sales_CustomerCategories_CustomerCategoryID] DEFAULT (NEXT VALUE FOR [Sequences].[CustomerCategoryID]) NOT NULL,
    [CustomerCategoryName] NVARCHAR (50)                               NOT NULL,
    [LastEditedBy]         INT                                         NOT NULL,
    [ValidFrom]            DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]              DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_Sales_CustomerCategories] PRIMARY KEY CLUSTERED ([CustomerCategoryID] ASC),
    CONSTRAINT [FK_Sales_CustomerCategories_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [UQ_Sales_CustomerCategories_CustomerCategoryName] UNIQUE NONCLUSTERED ([CustomerCategoryName] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Sales].[CustomerCategories_Archive], DATA_CONSISTENCY_CHECK=ON));


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Categories for customers (ie restaurants, cafes, supermarkets, etc.)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerCategories';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a customer category within the database', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerCategories', @level2type = N'COLUMN', @level2name = N'CustomerCategoryID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Full name of the category that customers can be assigned to', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerCategories', @level2type = N'COLUMN', @level2name = N'CustomerCategoryName';


GO

-- File: CustomerCategories_Archive.sql
﻿CREATE TABLE [Sales].[CustomerCategories_Archive] (
    [CustomerCategoryID]   INT           NOT NULL,
    [CustomerCategoryName] NVARCHAR (50) NOT NULL,
    [LastEditedBy]         INT           NOT NULL,
    [ValidFrom]            DATETIME2 (7) NOT NULL,
    [ValidTo]              DATETIME2 (7) NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_CustomerCategories_Archive]
    ON [Sales].[CustomerCategories_Archive]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);


GO

-- File: CustomerTransactions.sql
﻿CREATE TABLE [Sales].[CustomerTransactions] (
    [CustomerTransactionID] INT             CONSTRAINT [DF_Sales_CustomerTransactions_CustomerTransactionID] DEFAULT (NEXT VALUE FOR [Sequences].[TransactionID]) NOT NULL,
    [CustomerID]            INT             NOT NULL,
    [TransactionTypeID]     INT             NOT NULL,
    [InvoiceID]             INT             NULL,
    [PaymentMethodID]       INT             NULL,
    [TransactionDate]       DATE            NOT NULL,
    [AmountExcludingTax]    DECIMAL (18, 2) NOT NULL,
    [TaxAmount]             DECIMAL (18, 2) NOT NULL,
    [TransactionAmount]     DECIMAL (18, 2) NOT NULL,
    [OutstandingBalance]    DECIMAL (18, 2) NOT NULL,
    [FinalizationDate]      DATE            NULL,
    [IsFinalized]           AS              (case when [FinalizationDate] IS NULL then CONVERT([bit],(0)) else CONVERT([bit],(1)) end) PERSISTED,
    [LastEditedBy]          INT             NOT NULL,
    [LastEditedWhen]        DATETIME2 (7)   CONSTRAINT [DF_Sales_CustomerTransactions_LastEditedWhen] DEFAULT (sysdatetime()) NOT NULL,
    CONSTRAINT [PK_Sales_CustomerTransactions] PRIMARY KEY NONCLUSTERED ([CustomerTransactionID] ASC),
    CONSTRAINT [FK_Sales_CustomerTransactions_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Sales_CustomerTransactions_CustomerID_Sales_Customers] FOREIGN KEY ([CustomerID]) REFERENCES [Sales].[Customers] ([CustomerID]),
    CONSTRAINT [FK_Sales_CustomerTransactions_InvoiceID_Sales_Invoices] FOREIGN KEY ([InvoiceID]) REFERENCES [Sales].[Invoices] ([InvoiceID]),
    CONSTRAINT [FK_Sales_CustomerTransactions_PaymentMethodID_Application_PaymentMethods] FOREIGN KEY ([PaymentMethodID]) REFERENCES [Application].[PaymentMethods] ([PaymentMethodID]),
    CONSTRAINT [FK_Sales_CustomerTransactions_TransactionTypeID_Application_TransactionTypes] FOREIGN KEY ([TransactionTypeID]) REFERENCES [Application].[TransactionTypes] ([TransactionTypeID])
);


GO
CREATE CLUSTERED INDEX [CX_Sales_CustomerTransactions]
    ON [Sales].[CustomerTransactions]([TransactionDate] ASC)
    ON [PS_TransactionDate] ([TransactionDate]);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_CustomerTransactions_CustomerID]
    ON [Sales].[CustomerTransactions]([CustomerID] ASC)
    ON [PS_TransactionDate] ([TransactionDate]);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_CustomerTransactions_TransactionTypeID]
    ON [Sales].[CustomerTransactions]([TransactionTypeID] ASC)
    ON [PS_TransactionDate] ([TransactionDate]);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_CustomerTransactions_InvoiceID]
    ON [Sales].[CustomerTransactions]([InvoiceID] ASC)
    ON [PS_TransactionDate] ([TransactionDate]);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_CustomerTransactions_PaymentMethodID]
    ON [Sales].[CustomerTransactions]([PaymentMethodID] ASC)
    ON [PS_TransactionDate] ([TransactionDate]);


GO
CREATE NONCLUSTERED INDEX [IX_Sales_CustomerTransactions_IsFinalized]
    ON [Sales].[CustomerTransactions]([IsFinalized] ASC)
    ON [PS_TransactionDate] ([TransactionDate]);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerTransactions', @level2type = N'INDEX', @level2name = N'FK_Sales_CustomerTransactions_CustomerID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerTransactions', @level2type = N'INDEX', @level2name = N'FK_Sales_CustomerTransactions_TransactionTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerTransactions', @level2type = N'INDEX', @level2name = N'FK_Sales_CustomerTransactions_InvoiceID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerTransactions', @level2type = N'INDEX', @level2name = N'FK_Sales_CustomerTransactions_PaymentMethodID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Allows quick location of unfinalized transactions', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerTransactions', @level2type = N'INDEX', @level2name = N'IX_Sales_CustomerTransactions_IsFinalized';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'All financial transactions that are customer-related', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerTransactions';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used to refer to a customer transaction within the database', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerTransactions', @level2type = N'COLUMN', @level2name = N'CustomerTransactionID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer for this transaction', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerTransactions', @level2type = N'COLUMN', @level2name = N'CustomerID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Type of transaction', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerTransactions', @level2type = N'COLUMN', @level2name = N'TransactionTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'ID of an invoice (for transactions associated with an invoice)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerTransactions', @level2type = N'COLUMN', @level2name = N'InvoiceID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'ID of a payment method (for transactions involving payments)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerTransactions', @level2type = N'COLUMN', @level2name = N'PaymentMethodID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Date for the transaction', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerTransactions', @level2type = N'COLUMN', @level2name = N'TransactionDate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Transaction amount (excluding tax)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerTransactions', @level2type = N'COLUMN', @level2name = N'AmountExcludingTax';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Tax amount calculated', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerTransactions', @level2type = N'COLUMN', @level2name = N'TaxAmount';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Transaction amount (including tax)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerTransactions', @level2type = N'COLUMN', @level2name = N'TransactionAmount';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Amount still outstanding for this transaction', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerTransactions', @level2type = N'COLUMN', @level2name = N'OutstandingBalance';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Date that this transaction was finalized (if it has been)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerTransactions', @level2type = N'COLUMN', @level2name = N'FinalizationDate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Is this transaction finalized (invoices, credits and payments have been matched)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'CustomerTransactions', @level2type = N'COLUMN', @level2name = N'IsFinalized';


GO

-- File: Customers.sql
﻿CREATE TABLE [Sales].[Customers] (
    [CustomerID]                 INT                                         CONSTRAINT [DF_Sales_Customers_CustomerID] DEFAULT (NEXT VALUE FOR [Sequences].[CustomerID]) NOT NULL,
    [CustomerName]               NVARCHAR (100)                              NOT NULL,
    [BillToCustomerID]           INT                                         NOT NULL,
    [CustomerCategoryID]         INT                                         NOT NULL,
    [BuyingGroupID]              INT                                         NULL,
    [PrimaryContactPersonID]     INT                                         NOT NULL,
    [AlternateContactPersonID]   INT                                         NULL,
    [DeliveryMethodID]           INT                                         NOT NULL,
    [DeliveryCityID]             INT                                         NOT NULL,
    [PostalCityID]               INT                                         NOT NULL,
    [CreditLimit]                DECIMAL (18, 2)                             NULL,
    [AccountOpenedDate]          DATE                                        NOT NULL,
    [StandardDiscountPercentage] DECIMAL (18, 3)                             NOT NULL,
    [IsStatementSent]            BIT                                         NOT NULL,
    [IsOnCreditHold]             BIT                                         NOT NULL,
    [PaymentDays]                INT                                         NOT NULL,
    [PhoneNumber]                NVARCHAR (20)                               NOT NULL,
    [FaxNumber]                  NVARCHAR (20)                               NOT NULL,
    [DeliveryRun]                NVARCHAR (5)                                NULL,
    [RunPosition]                NVARCHAR (5)                                NULL,
    [WebsiteURL]                 NVARCHAR (256)                              NOT NULL,
    [DeliveryAddressLine1]       NVARCHAR (60)                               NOT NULL,
    [DeliveryAddressLine2]       NVARCHAR (60)                               NULL,
    [DeliveryPostalCode]         NVARCHAR (10)                               NOT NULL,
    [DeliveryLocation]           [sys].[geography]                           NULL,
    [PostalAddressLine1]         NVARCHAR (60)                               NOT NULL,
    [PostalAddressLine2]         NVARCHAR (60)                               NULL,
    [PostalPostalCode]           NVARCHAR (10)                               NOT NULL,
    [LastEditedBy]               INT                                         NOT NULL,
    [ValidFrom]                  DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]                    DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_Sales_Customers] PRIMARY KEY CLUSTERED ([CustomerID] ASC),
    CONSTRAINT [FK_Sales_Customers_AlternateContactPersonID_Application_People] FOREIGN KEY ([AlternateContactPersonID]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Sales_Customers_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Sales_Customers_BillToCustomerID_Sales_Customers] FOREIGN KEY ([BillToCustomerID]) REFERENCES [Sales].[Customers] ([CustomerID]),
    CONSTRAINT [FK_Sales_Customers_BuyingGroupID_Sales_BuyingGroups] FOREIGN KEY ([BuyingGroupID]) REFERENCES [Sales].[BuyingGroups] ([BuyingGroupID]),
    CONSTRAINT [FK_Sales_Customers_CustomerCategoryID_Sales_CustomerCategories] FOREIGN KEY ([CustomerCategoryID]) REFERENCES [Sales].[CustomerCategories] ([CustomerCategoryID]),
    CONSTRAINT [FK_Sales_Customers_DeliveryCityID_Application_Cities] FOREIGN KEY ([DeliveryCityID]) REFERENCES [Application].[Cities] ([CityID]),
    CONSTRAINT [FK_Sales_Customers_DeliveryMethodID_Application_DeliveryMethods] FOREIGN KEY ([DeliveryMethodID]) REFERENCES [Application].[DeliveryMethods] ([DeliveryMethodID]),
    CONSTRAINT [FK_Sales_Customers_PostalCityID_Application_Cities] FOREIGN KEY ([PostalCityID]) REFERENCES [Application].[Cities] ([CityID]),
    CONSTRAINT [FK_Sales_Customers_PrimaryContactPersonID_Application_People] FOREIGN KEY ([PrimaryContactPersonID]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [UQ_Sales_Customers_CustomerName] UNIQUE NONCLUSTERED ([CustomerName] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Sales].[Customers_Archive], DATA_CONSISTENCY_CHECK=ON));




GO
CREATE NONCLUSTERED INDEX [FK_Sales_Customers_CustomerCategoryID]
    ON [Sales].[Customers]([CustomerCategoryID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_Customers_BuyingGroupID]
    ON [Sales].[Customers]([BuyingGroupID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_Customers_PrimaryContactPersonID]
    ON [Sales].[Customers]([PrimaryContactPersonID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_Customers_AlternateContactPersonID]
    ON [Sales].[Customers]([AlternateContactPersonID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_Customers_DeliveryMethodID]
    ON [Sales].[Customers]([DeliveryMethodID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_Customers_DeliveryCityID]
    ON [Sales].[Customers]([DeliveryCityID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_Customers_PostalCityID]
    ON [Sales].[Customers]([PostalCityID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Sales_Customers_Perf_20160301_06]
    ON [Sales].[Customers]([IsOnCreditHold] ASC, [CustomerID] ASC, [BillToCustomerID] ASC)
    INCLUDE([PrimaryContactPersonID]);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'INDEX', @level2name = N'FK_Sales_Customers_CustomerCategoryID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'INDEX', @level2name = N'FK_Sales_Customers_BuyingGroupID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'INDEX', @level2name = N'FK_Sales_Customers_PrimaryContactPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'INDEX', @level2name = N'FK_Sales_Customers_AlternateContactPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'INDEX', @level2name = N'FK_Sales_Customers_DeliveryMethodID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'INDEX', @level2name = N'FK_Sales_Customers_DeliveryCityID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'INDEX', @level2name = N'FK_Sales_Customers_PostalCityID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Improves performance of order picking and invoicing', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'INDEX', @level2name = N'IX_Sales_Customers_Perf_20160301_06';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Main entity tables for customers (organizations or individuals)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a customer within the database', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'CustomerID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer''s full name (usually a trading name)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'CustomerName';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer that this is billed to (usually the same customer but can be another parent company)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'BillToCustomerID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer''s category', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'CustomerCategoryID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer''s buying group (optional)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'BuyingGroupID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Primary contact', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'PrimaryContactPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Alternate contact', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'AlternateContactPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Standard delivery method for stock items sent to this customer', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'DeliveryMethodID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'ID of the delivery city for this address', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'DeliveryCityID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'ID of the postal city for this address', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'PostalCityID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Credit limit for this customer (NULL if unlimited)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'CreditLimit';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Date this customer account was opened', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'AccountOpenedDate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Standard discount offered to this customer', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'StandardDiscountPercentage';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Is a statement sent to this customer? (Or do they just pay on each invoice?)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'IsStatementSent';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Is this customer on credit hold? (Prevents further deliveries to this customer)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'IsOnCreditHold';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Number of days for payment of an invoice (ie payment terms)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'PaymentDays';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Phone number', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'PhoneNumber';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Fax number  ', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'FaxNumber';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Normal delivery run for this customer', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'DeliveryRun';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Normal position in the delivery run for this customer', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'RunPosition';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'URL for the website for this customer', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'WebsiteURL';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'First delivery address line for the customer', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'DeliveryAddressLine1';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Second delivery address line for the customer', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'DeliveryAddressLine2';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Delivery postal code for the customer', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'DeliveryPostalCode';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Geographic location for the customer''s office/warehouse', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'DeliveryLocation';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'First postal address line for the customer', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'PostalAddressLine1';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Second postal address line for the customer', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'PostalAddressLine2';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Postal code for the customer when sending by mail', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'PostalPostalCode';


GO

-- File: Customers_Archive.sql
﻿CREATE TABLE [Sales].[Customers_Archive] (
    [CustomerID]                 INT               NOT NULL,
    [CustomerName]               NVARCHAR (100)    NOT NULL,
    [BillToCustomerID]           INT               NOT NULL,
    [CustomerCategoryID]         INT               NOT NULL,
    [BuyingGroupID]              INT               NULL,
    [PrimaryContactPersonID]     INT               NOT NULL,
    [AlternateContactPersonID]   INT               NULL,
    [DeliveryMethodID]           INT               NOT NULL,
    [DeliveryCityID]             INT               NOT NULL,
    [PostalCityID]               INT               NOT NULL,
    [CreditLimit]                DECIMAL (18, 2)   NULL,
    [AccountOpenedDate]          DATE              NOT NULL,
    [StandardDiscountPercentage] DECIMAL (18, 3)   NOT NULL,
    [IsStatementSent]            BIT               NOT NULL,
    [IsOnCreditHold]             BIT               NOT NULL,
    [PaymentDays]                INT               NOT NULL,
    [PhoneNumber]                NVARCHAR (20)     NOT NULL,
    [FaxNumber]                  NVARCHAR (20)     NOT NULL,
    [DeliveryRun]                NVARCHAR (5)      NULL,
    [RunPosition]                NVARCHAR (5)      NULL,
    [WebsiteURL]                 NVARCHAR (256)    NOT NULL,
    [DeliveryAddressLine1]       NVARCHAR (60)     NOT NULL,
    [DeliveryAddressLine2]       NVARCHAR (60)     NULL,
    [DeliveryPostalCode]         NVARCHAR (10)     NOT NULL,
    [DeliveryLocation]           [sys].[geography] NULL,
    [PostalAddressLine1]         NVARCHAR (60)     NOT NULL,
    [PostalAddressLine2]         NVARCHAR (60)     NULL,
    [PostalPostalCode]           NVARCHAR (10)     NOT NULL,
    [LastEditedBy]               INT               NOT NULL,
    [ValidFrom]                  DATETIME2 (7)     NOT NULL,
    [ValidTo]                    DATETIME2 (7)     NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_Customers_Archive]
    ON [Sales].[Customers_Archive]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);


GO

-- File: InvoiceLines.sql
﻿CREATE TABLE [Sales].[InvoiceLines] (
    [InvoiceLineID]  INT             CONSTRAINT [DF_Sales_InvoiceLines_InvoiceLineID] DEFAULT (NEXT VALUE FOR [Sequences].[InvoiceLineID]) NOT NULL,
    [InvoiceID]      INT             NOT NULL,
    [StockItemID]    INT             NOT NULL,
    [Description]    NVARCHAR (100)  NOT NULL,
    [PackageTypeID]  INT             NOT NULL,
    [Quantity]       INT             NOT NULL,
    [UnitPrice]      DECIMAL (18, 2) NULL,
    [TaxRate]        DECIMAL (18, 3) NOT NULL,
    [TaxAmount]      DECIMAL (18, 2) NOT NULL,
    [LineProfit]     DECIMAL (18, 2) NOT NULL,
    [ExtendedPrice]  DECIMAL (18, 2) NOT NULL,
    [LastEditedBy]   INT             NOT NULL,
    [LastEditedWhen] DATETIME2 (7)   CONSTRAINT [DF_Sales_InvoiceLines_LastEditedWhen] DEFAULT (sysdatetime()) NOT NULL,
    CONSTRAINT [PK_Sales_InvoiceLines] PRIMARY KEY CLUSTERED ([InvoiceLineID] ASC),
    CONSTRAINT [FK_Sales_InvoiceLines_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Sales_InvoiceLines_InvoiceID_Sales_Invoices] FOREIGN KEY ([InvoiceID]) REFERENCES [Sales].[Invoices] ([InvoiceID]),
    CONSTRAINT [FK_Sales_InvoiceLines_PackageTypeID_Warehouse_PackageTypes] FOREIGN KEY ([PackageTypeID]) REFERENCES [Warehouse].[PackageTypes] ([PackageTypeID]),
    CONSTRAINT [FK_Sales_InvoiceLines_StockItemID_Warehouse_StockItems] FOREIGN KEY ([StockItemID]) REFERENCES [Warehouse].[StockItems] ([StockItemID])
);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_InvoiceLines_InvoiceID]
    ON [Sales].[InvoiceLines]([InvoiceID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_InvoiceLines_StockItemID]
    ON [Sales].[InvoiceLines]([StockItemID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_InvoiceLines_PackageTypeID]
    ON [Sales].[InvoiceLines]([PackageTypeID] ASC);


GO
CREATE COLUMNSTORE INDEX [NCCX_Sales_InvoiceLines]
    ON [Sales].[InvoiceLines]([InvoiceID], [StockItemID], [Quantity], [UnitPrice], [LineProfit], [LastEditedWhen]);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'InvoiceLines', @level2type = N'INDEX', @level2name = N'FK_Sales_InvoiceLines_InvoiceID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'InvoiceLines', @level2type = N'INDEX', @level2name = N'FK_Sales_InvoiceLines_StockItemID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'InvoiceLines', @level2type = N'INDEX', @level2name = N'FK_Sales_InvoiceLines_PackageTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Detail lines from customer invoices', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'InvoiceLines';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a line on an invoice within the database', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'InvoiceLines', @level2type = N'COLUMN', @level2name = N'InvoiceLineID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Invoice that this line is associated with', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'InvoiceLines', @level2type = N'COLUMN', @level2name = N'InvoiceID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Stock item for this invoice line', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'InvoiceLines', @level2type = N'COLUMN', @level2name = N'StockItemID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Description of the item supplied (Usually the stock item name but can be overridden)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'InvoiceLines', @level2type = N'COLUMN', @level2name = N'Description';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Type of package supplied', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'InvoiceLines', @level2type = N'COLUMN', @level2name = N'PackageTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity supplied', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'InvoiceLines', @level2type = N'COLUMN', @level2name = N'Quantity';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Unit price charged', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'InvoiceLines', @level2type = N'COLUMN', @level2name = N'UnitPrice';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Tax rate to be applied', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'InvoiceLines', @level2type = N'COLUMN', @level2name = N'TaxRate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Tax amount calculated', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'InvoiceLines', @level2type = N'COLUMN', @level2name = N'TaxAmount';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Profit made on this line item at current cost price', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'InvoiceLines', @level2type = N'COLUMN', @level2name = N'LineProfit';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Extended line price charged', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'InvoiceLines', @level2type = N'COLUMN', @level2name = N'ExtendedPrice';


GO

-- File: Invoices.sql
﻿CREATE TABLE [Sales].[Invoices] (
    [InvoiceID]                   INT            CONSTRAINT [DF_Sales_Invoices_InvoiceID] DEFAULT (NEXT VALUE FOR [Sequences].[InvoiceID]) NOT NULL,
    [CustomerID]                  INT            NOT NULL,
    [BillToCustomerID]            INT            NOT NULL,
    [OrderID]                     INT            NULL,
    [DeliveryMethodID]            INT            NOT NULL,
    [ContactPersonID]             INT            NOT NULL,
    [AccountsPersonID]            INT            NOT NULL,
    [SalespersonPersonID]         INT            NOT NULL,
    [PackedByPersonID]            INT            NOT NULL,
    [InvoiceDate]                 DATE           NOT NULL,
    [CustomerPurchaseOrderNumber] NVARCHAR (20)  NULL,
    [IsCreditNote]                BIT            NOT NULL,
    [CreditNoteReason]            NVARCHAR (MAX) NULL,
    [Comments]                    NVARCHAR (MAX) NULL,
    [DeliveryInstructions]        NVARCHAR (MAX) NULL,
    [InternalComments]            NVARCHAR (MAX) NULL,
    [TotalDryItems]               INT            NOT NULL,
    [TotalChillerItems]           INT            NOT NULL,
    [DeliveryRun]                 NVARCHAR (5)   NULL,
    [RunPosition]                 NVARCHAR (5)   NULL,
    [ReturnedDeliveryData]        NVARCHAR (MAX) NULL,
    [ConfirmedDeliveryTime]       AS             (TRY_CONVERT([datetime2](7),json_value([ReturnedDeliveryData],N'$.DeliveredWhen'),(126))),
    [ConfirmedReceivedBy]         AS             (json_value([ReturnedDeliveryData],N'$.ReceivedBy')),
    [LastEditedBy]                INT            NOT NULL,
    [LastEditedWhen]              DATETIME2 (7)  CONSTRAINT [DF_Sales_Invoices_LastEditedWhen] DEFAULT (sysdatetime()) NOT NULL,
    CONSTRAINT [PK_Sales_Invoices] PRIMARY KEY CLUSTERED ([InvoiceID] ASC),
    CONSTRAINT [CK_Sales_Invoices_ReturnedDeliveryData_Must_Be_Valid_JSON] CHECK ([ReturnedDeliveryData] IS NULL OR isjson([ReturnedDeliveryData])<>(0)),
    CONSTRAINT [FK_Sales_Invoices_AccountsPersonID_Application_People] FOREIGN KEY ([AccountsPersonID]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Sales_Invoices_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Sales_Invoices_BillToCustomerID_Sales_Customers] FOREIGN KEY ([BillToCustomerID]) REFERENCES [Sales].[Customers] ([CustomerID]),
    CONSTRAINT [FK_Sales_Invoices_ContactPersonID_Application_People] FOREIGN KEY ([ContactPersonID]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Sales_Invoices_CustomerID_Sales_Customers] FOREIGN KEY ([CustomerID]) REFERENCES [Sales].[Customers] ([CustomerID]),
    CONSTRAINT [FK_Sales_Invoices_DeliveryMethodID_Application_DeliveryMethods] FOREIGN KEY ([DeliveryMethodID]) REFERENCES [Application].[DeliveryMethods] ([DeliveryMethodID]),
    CONSTRAINT [FK_Sales_Invoices_OrderID_Sales_Orders] FOREIGN KEY ([OrderID]) REFERENCES [Sales].[Orders] ([OrderID]),
    CONSTRAINT [FK_Sales_Invoices_PackedByPersonID_Application_People] FOREIGN KEY ([PackedByPersonID]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Sales_Invoices_SalespersonPersonID_Application_People] FOREIGN KEY ([SalespersonPersonID]) REFERENCES [Application].[People] ([PersonID])
);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_Invoices_CustomerID]
    ON [Sales].[Invoices]([CustomerID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_Invoices_BillToCustomerID]
    ON [Sales].[Invoices]([BillToCustomerID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_Invoices_OrderID]
    ON [Sales].[Invoices]([OrderID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_Invoices_DeliveryMethodID]
    ON [Sales].[Invoices]([DeliveryMethodID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_Invoices_ContactPersonID]
    ON [Sales].[Invoices]([ContactPersonID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_Invoices_AccountsPersonID]
    ON [Sales].[Invoices]([AccountsPersonID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_Invoices_SalespersonPersonID]
    ON [Sales].[Invoices]([SalespersonPersonID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_Invoices_PackedByPersonID]
    ON [Sales].[Invoices]([PackedByPersonID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Sales_Invoices_ConfirmedDeliveryTime]
    ON [Sales].[Invoices]([ConfirmedDeliveryTime] ASC)
    INCLUDE([ConfirmedReceivedBy]);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'INDEX', @level2name = N'FK_Sales_Invoices_CustomerID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'INDEX', @level2name = N'FK_Sales_Invoices_BillToCustomerID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'INDEX', @level2name = N'FK_Sales_Invoices_OrderID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'INDEX', @level2name = N'FK_Sales_Invoices_DeliveryMethodID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'INDEX', @level2name = N'FK_Sales_Invoices_ContactPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'INDEX', @level2name = N'FK_Sales_Invoices_AccountsPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'INDEX', @level2name = N'FK_Sales_Invoices_SalespersonPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'INDEX', @level2name = N'FK_Sales_Invoices_PackedByPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Allows quick retrieval of invoices confirmed to have been delivered in a given time period', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'INDEX', @level2name = N'IX_Sales_Invoices_ConfirmedDeliveryTime';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Ensures that if returned delivery data is present that it is valid JSON', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'CONSTRAINT', @level2name = N'CK_Sales_Invoices_ReturnedDeliveryData_Must_Be_Valid_JSON';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Details of customer invoices', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to an invoice within the database', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'InvoiceID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer for this invoice', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'CustomerID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Bill to customer for this invoice (invoices might be billed to a head office)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'BillToCustomerID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Sales order (if any) for this invoice', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'OrderID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'How these stock items are beign delivered', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'DeliveryMethodID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer contact for this invoice', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'ContactPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer accounts contact for this invoice', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'AccountsPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Salesperson for this invoice', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'SalespersonPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Person who packed this shipment (or checked the packing)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'PackedByPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Date that this invoice was raised', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'InvoiceDate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Purchase Order Number received from customer', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'CustomerPurchaseOrderNumber';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Is this a credit note (rather than an invoice)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'IsCreditNote';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Reason that this credit note needed to be generated (if applicable)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'CreditNoteReason';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Any comments related to this invoice (sent to customer)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'Comments';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Any comments related to delivery (sent to customer)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'DeliveryInstructions';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Any internal comments related to this invoice (not sent to the customer)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'InternalComments';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total number of dry packages (information for the delivery driver)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'TotalDryItems';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Total number of chiller packages (information for the delivery driver)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'TotalChillerItems';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Delivery run for this shipment', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'DeliveryRun';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Position in the delivery run for this shipment', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'RunPosition';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'JSON-structured data returned from delivery devices for deliveries made directly by the organization', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'ReturnedDeliveryData';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Confirmed delivery date and time promoted from JSON delivery data', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'ConfirmedDeliveryTime';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Confirmed receiver promoted from JSON delivery data', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Invoices', @level2type = N'COLUMN', @level2name = N'ConfirmedReceivedBy';


GO

-- File: OrderLines.sql
﻿CREATE TABLE [Sales].[OrderLines] (
    [OrderLineID]          INT             CONSTRAINT [DF_Sales_OrderLines_OrderLineID] DEFAULT (NEXT VALUE FOR [Sequences].[OrderLineID]) NOT NULL,
    [OrderID]              INT             NOT NULL,
    [StockItemID]          INT             NOT NULL,
    [Description]          NVARCHAR (100)  NOT NULL,
    [PackageTypeID]        INT             NOT NULL,
    [Quantity]             INT             NOT NULL,
    [UnitPrice]            DECIMAL (18, 2) NULL,
    [TaxRate]              DECIMAL (18, 3) NOT NULL,
    [PickedQuantity]       INT             NOT NULL,
    [PickingCompletedWhen] DATETIME2 (7)   NULL,
    [LastEditedBy]         INT             NOT NULL,
    [LastEditedWhen]       DATETIME2 (7)   CONSTRAINT [DF_Sales_OrderLines_LastEditedWhen] DEFAULT (sysdatetime()) NOT NULL,
    CONSTRAINT [PK_Sales_OrderLines] PRIMARY KEY CLUSTERED ([OrderLineID] ASC),
    CONSTRAINT [FK_Sales_OrderLines_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Sales_OrderLines_OrderID_Sales_Orders] FOREIGN KEY ([OrderID]) REFERENCES [Sales].[Orders] ([OrderID]),
    CONSTRAINT [FK_Sales_OrderLines_PackageTypeID_Warehouse_PackageTypes] FOREIGN KEY ([PackageTypeID]) REFERENCES [Warehouse].[PackageTypes] ([PackageTypeID]),
    CONSTRAINT [FK_Sales_OrderLines_StockItemID_Warehouse_StockItems] FOREIGN KEY ([StockItemID]) REFERENCES [Warehouse].[StockItems] ([StockItemID])
);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_OrderLines_OrderID]
    ON [Sales].[OrderLines]([OrderID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_OrderLines_PackageTypeID]
    ON [Sales].[OrderLines]([PackageTypeID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Sales_OrderLines_AllocatedStockItems]
    ON [Sales].[OrderLines]([StockItemID] ASC)
    INCLUDE([PickedQuantity]);


GO
CREATE NONCLUSTERED INDEX [IX_Sales_OrderLines_Perf_20160301_01]
    ON [Sales].[OrderLines]([PickingCompletedWhen] ASC, [OrderID] ASC, [OrderLineID] ASC)
    INCLUDE([Quantity], [StockItemID]);


GO
CREATE NONCLUSTERED INDEX [IX_Sales_OrderLines_Perf_20160301_02]
    ON [Sales].[OrderLines]([StockItemID] ASC, [PickingCompletedWhen] ASC)
    INCLUDE([OrderID], [PickedQuantity]);


GO
CREATE COLUMNSTORE INDEX [NCCX_Sales_OrderLines]
    ON [Sales].[OrderLines]([OrderID], [StockItemID], [Description], [Quantity], [UnitPrice], [PickedQuantity], [PackageTypeID]);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'OrderLines', @level2type = N'INDEX', @level2name = N'FK_Sales_OrderLines_OrderID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'OrderLines', @level2type = N'INDEX', @level2name = N'FK_Sales_OrderLines_PackageTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Allows quick summation of stock item quantites already allocated to uninvoiced orders', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'OrderLines', @level2type = N'INDEX', @level2name = N'IX_Sales_OrderLines_AllocatedStockItems';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Improves performance of order picking and invoicing', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'OrderLines', @level2type = N'INDEX', @level2name = N'IX_Sales_OrderLines_Perf_20160301_01';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Improves performance of order picking and invoicing', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'OrderLines', @level2type = N'INDEX', @level2name = N'IX_Sales_OrderLines_Perf_20160301_02';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Detail lines from customer orders', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'OrderLines';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a line on an Order within the database', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'OrderLines', @level2type = N'COLUMN', @level2name = N'OrderLineID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Order that this line is associated with', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'OrderLines', @level2type = N'COLUMN', @level2name = N'OrderID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Stock item for this order line (FK not indexed as separate index exists)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'OrderLines', @level2type = N'COLUMN', @level2name = N'StockItemID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Description of the item supplied (Usually the stock item name but can be overridden)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'OrderLines', @level2type = N'COLUMN', @level2name = N'Description';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Type of package to be supplied', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'OrderLines', @level2type = N'COLUMN', @level2name = N'PackageTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity to be supplied', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'OrderLines', @level2type = N'COLUMN', @level2name = N'Quantity';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Unit price to be charged', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'OrderLines', @level2type = N'COLUMN', @level2name = N'UnitPrice';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Tax rate to be applied', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'OrderLines', @level2type = N'COLUMN', @level2name = N'TaxRate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity picked from stock', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'OrderLines', @level2type = N'COLUMN', @level2name = N'PickedQuantity';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'When was picking of this line completed?', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'OrderLines', @level2type = N'COLUMN', @level2name = N'PickingCompletedWhen';


GO

-- File: Orders.sql
﻿CREATE TABLE [Sales].[Orders] (
    [OrderID]                     INT            CONSTRAINT [DF_Sales_Orders_OrderID] DEFAULT (NEXT VALUE FOR [Sequences].[OrderID]) NOT NULL,
    [CustomerID]                  INT            NOT NULL,
    [SalespersonPersonID]         INT            NOT NULL,
    [PickedByPersonID]            INT            NULL,
    [ContactPersonID]             INT            NOT NULL,
    [BackorderOrderID]            INT            NULL,
    [OrderDate]                   DATE           NOT NULL,
    [ExpectedDeliveryDate]        DATE           NOT NULL,
    [CustomerPurchaseOrderNumber] NVARCHAR (20)  NULL,
    [IsUndersupplyBackordered]    BIT            NOT NULL,
    [Comments]                    NVARCHAR (MAX) NULL,
    [DeliveryInstructions]        NVARCHAR (MAX) NULL,
    [InternalComments]            NVARCHAR (MAX) NULL,
    [PickingCompletedWhen]        DATETIME2 (7)  NULL,
    [LastEditedBy]                INT            NOT NULL,
    [LastEditedWhen]              DATETIME2 (7)  CONSTRAINT [DF_Sales_Orders_LastEditedWhen] DEFAULT (sysdatetime()) NOT NULL,
    CONSTRAINT [PK_Sales_Orders] PRIMARY KEY CLUSTERED ([OrderID] ASC),
    CONSTRAINT [FK_Sales_Orders_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Sales_Orders_BackorderOrderID_Sales_Orders] FOREIGN KEY ([BackorderOrderID]) REFERENCES [Sales].[Orders] ([OrderID]),
    CONSTRAINT [FK_Sales_Orders_ContactPersonID_Application_People] FOREIGN KEY ([ContactPersonID]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Sales_Orders_CustomerID_Sales_Customers] FOREIGN KEY ([CustomerID]) REFERENCES [Sales].[Customers] ([CustomerID]),
    CONSTRAINT [FK_Sales_Orders_PickedByPersonID_Application_People] FOREIGN KEY ([PickedByPersonID]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Sales_Orders_SalespersonPersonID_Application_People] FOREIGN KEY ([SalespersonPersonID]) REFERENCES [Application].[People] ([PersonID])
);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_Orders_CustomerID]
    ON [Sales].[Orders]([CustomerID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_Orders_SalespersonPersonID]
    ON [Sales].[Orders]([SalespersonPersonID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_Orders_PickedByPersonID]
    ON [Sales].[Orders]([PickedByPersonID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_Orders_ContactPersonID]
    ON [Sales].[Orders]([ContactPersonID] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Orders', @level2type = N'INDEX', @level2name = N'FK_Sales_Orders_CustomerID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Orders', @level2type = N'INDEX', @level2name = N'FK_Sales_Orders_SalespersonPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Orders', @level2type = N'INDEX', @level2name = N'FK_Sales_Orders_PickedByPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Orders', @level2type = N'INDEX', @level2name = N'FK_Sales_Orders_ContactPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Detail of customer orders', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Orders';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to an order within the database', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Orders', @level2type = N'COLUMN', @level2name = N'OrderID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer for this order', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Orders', @level2type = N'COLUMN', @level2name = N'CustomerID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Salesperson for this order', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Orders', @level2type = N'COLUMN', @level2name = N'SalespersonPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Person who picked this shipment', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Orders', @level2type = N'COLUMN', @level2name = N'PickedByPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer contact for this order', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Orders', @level2type = N'COLUMN', @level2name = N'ContactPersonID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'If this order is a backorder, this column holds the original order number', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Orders', @level2type = N'COLUMN', @level2name = N'BackorderOrderID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Date that this order was raised', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Orders', @level2type = N'COLUMN', @level2name = N'OrderDate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Expected delivery date', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Orders', @level2type = N'COLUMN', @level2name = N'ExpectedDeliveryDate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Purchase Order Number received from customer', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Orders', @level2type = N'COLUMN', @level2name = N'CustomerPurchaseOrderNumber';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'If items cannot be supplied are they backordered?', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Orders', @level2type = N'COLUMN', @level2name = N'IsUndersupplyBackordered';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Any comments related to this order (sent to customer)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Orders', @level2type = N'COLUMN', @level2name = N'Comments';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Any comments related to order delivery (sent to customer)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Orders', @level2type = N'COLUMN', @level2name = N'DeliveryInstructions';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Any internal comments related to this order (not sent to the customer)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Orders', @level2type = N'COLUMN', @level2name = N'InternalComments';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'When was picking of the entire order completed?', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'Orders', @level2type = N'COLUMN', @level2name = N'PickingCompletedWhen';


GO

-- File: SpecialDeals.sql
﻿CREATE TABLE [Sales].[SpecialDeals] (
    [SpecialDealID]      INT             CONSTRAINT [DF_Sales_SpecialDeals_SpecialDealID] DEFAULT (NEXT VALUE FOR [Sequences].[SpecialDealID]) NOT NULL,
    [StockItemID]        INT             NULL,
    [CustomerID]         INT             NULL,
    [BuyingGroupID]      INT             NULL,
    [CustomerCategoryID] INT             NULL,
    [StockGroupID]       INT             NULL,
    [DealDescription]    NVARCHAR (30)   NOT NULL,
    [StartDate]          DATE            NOT NULL,
    [EndDate]            DATE            NOT NULL,
    [DiscountAmount]     DECIMAL (18, 2) NULL,
    [DiscountPercentage] DECIMAL (18, 3) NULL,
    [UnitPrice]          DECIMAL (18, 2) NULL,
    [LastEditedBy]       INT             NOT NULL,
    [LastEditedWhen]     DATETIME2 (7)   CONSTRAINT [DF_Sales_SpecialDeals_LastEditedWhen] DEFAULT (sysdatetime()) NOT NULL,
    CONSTRAINT [PK_Sales_SpecialDeals] PRIMARY KEY CLUSTERED ([SpecialDealID] ASC),
    CONSTRAINT [CK_Sales_SpecialDeals_Exactly_One_NOT_NULL_Pricing_Option_Is_Required] CHECK (((case when [DiscountAmount] IS NULL then (0) else (1) end+case when [DiscountPercentage] IS NULL then (0) else (1) end)+case when [UnitPrice] IS NULL then (0) else (1) end)=(1)),
    CONSTRAINT [CK_Sales_SpecialDeals_Unit_Price_Deal_Requires_Special_StockItem] CHECK ([StockItemID] IS NOT NULL AND [UnitPrice] IS NOT NULL OR [UnitPrice] IS NULL),
    CONSTRAINT [FK_Sales_SpecialDeals_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Sales_SpecialDeals_BuyingGroupID_Sales_BuyingGroups] FOREIGN KEY ([BuyingGroupID]) REFERENCES [Sales].[BuyingGroups] ([BuyingGroupID]),
    CONSTRAINT [FK_Sales_SpecialDeals_CustomerCategoryID_Sales_CustomerCategories] FOREIGN KEY ([CustomerCategoryID]) REFERENCES [Sales].[CustomerCategories] ([CustomerCategoryID]),
    CONSTRAINT [FK_Sales_SpecialDeals_CustomerID_Sales_Customers] FOREIGN KEY ([CustomerID]) REFERENCES [Sales].[Customers] ([CustomerID]),
    CONSTRAINT [FK_Sales_SpecialDeals_StockGroupID_Warehouse_StockGroups] FOREIGN KEY ([StockGroupID]) REFERENCES [Warehouse].[StockGroups] ([StockGroupID]),
    CONSTRAINT [FK_Sales_SpecialDeals_StockItemID_Warehouse_StockItems] FOREIGN KEY ([StockItemID]) REFERENCES [Warehouse].[StockItems] ([StockItemID])
);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_SpecialDeals_StockItemID]
    ON [Sales].[SpecialDeals]([StockItemID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_SpecialDeals_CustomerID]
    ON [Sales].[SpecialDeals]([CustomerID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_SpecialDeals_BuyingGroupID]
    ON [Sales].[SpecialDeals]([BuyingGroupID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_SpecialDeals_CustomerCategoryID]
    ON [Sales].[SpecialDeals]([CustomerCategoryID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Sales_SpecialDeals_StockGroupID]
    ON [Sales].[SpecialDeals]([StockGroupID] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals', @level2type = N'INDEX', @level2name = N'FK_Sales_SpecialDeals_StockItemID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals', @level2type = N'INDEX', @level2name = N'FK_Sales_SpecialDeals_CustomerID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals', @level2type = N'INDEX', @level2name = N'FK_Sales_SpecialDeals_BuyingGroupID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals', @level2type = N'INDEX', @level2name = N'FK_Sales_SpecialDeals_CustomerCategoryID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals', @level2type = N'INDEX', @level2name = N'FK_Sales_SpecialDeals_StockGroupID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Ensures that each special price row contains one and only one of DiscountAmount, DiscountPercentage, and UnitPrice', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals', @level2type = N'CONSTRAINT', @level2name = N'CK_Sales_SpecialDeals_Exactly_One_NOT_NULL_Pricing_Option_Is_Required';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Ensures that if a specific price is allocated that it applies to a specific stock item', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals', @level2type = N'CONSTRAINT', @level2name = N'CK_Sales_SpecialDeals_Unit_Price_Deal_Requires_Special_StockItem';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Special pricing (can include fixed prices, discount $ or discount %)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'ID (sequence based) for a special deal', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals', @level2type = N'COLUMN', @level2name = N'SpecialDealID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Stock item that the deal applies to (if NULL, then only discounts are permitted not unit prices)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals', @level2type = N'COLUMN', @level2name = N'StockItemID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'ID of the customer that the special pricing applies to (if NULL then all customers)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals', @level2type = N'COLUMN', @level2name = N'CustomerID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'ID of the buying group that the special pricing applies to (optional)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals', @level2type = N'COLUMN', @level2name = N'BuyingGroupID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'ID of the customer category that the special pricing applies to (optional)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals', @level2type = N'COLUMN', @level2name = N'CustomerCategoryID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'ID of the stock group that the special pricing applies to (optional)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals', @level2type = N'COLUMN', @level2name = N'StockGroupID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Description of the special deal', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals', @level2type = N'COLUMN', @level2name = N'DealDescription';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Date that the special pricing starts from', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals', @level2type = N'COLUMN', @level2name = N'StartDate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Date that the special pricing ends on', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals', @level2type = N'COLUMN', @level2name = N'EndDate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Discount per unit to be applied to sale price (optional)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals', @level2type = N'COLUMN', @level2name = N'DiscountAmount';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Discount percentage per unit to be applied to sale price (optional)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals', @level2type = N'COLUMN', @level2name = N'DiscountPercentage';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Special price per unit to be applied instead of sale price (optional)', @level0type = N'SCHEMA', @level0name = N'Sales', @level1type = N'TABLE', @level1name = N'SpecialDeals', @level2type = N'COLUMN', @level2name = N'UnitPrice';


GO

-- File: ColdRoomTemperatures.sql
﻿CREATE TABLE [Warehouse].[ColdRoomTemperatures] (
    [ColdRoomTemperatureID] BIGINT                                      IDENTITY (1, 1) NOT NULL,
    [ColdRoomSensorNumber]  INT                                         NOT NULL,
    [RecordedWhen]          DATETIME2 (7)                               NOT NULL,
    [Temperature]           DECIMAL (10, 2)                             NOT NULL,
    [ValidFrom]             DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]               DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_Warehouse_ColdRoomTemperatures] PRIMARY KEY NONCLUSTERED ([ColdRoomTemperatureID] ASC),
    INDEX [IX_Warehouse_ColdRoomTemperatures_ColdRoomSensorNumber] NONCLUSTERED ([ColdRoomSensorNumber]),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (MEMORY_OPTIMIZED = ON, SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Warehouse].[ColdRoomTemperatures_Archive], DATA_CONSISTENCY_CHECK=ON));


GO

-- File: ColdRoomTemperatures_Archive.sql
﻿CREATE TABLE [Warehouse].[ColdRoomTemperatures_Archive] (
    [ColdRoomTemperatureID] BIGINT          NOT NULL,
    [ColdRoomSensorNumber]  INT             NOT NULL,
    [RecordedWhen]          DATETIME2 (7)   NOT NULL,
    [Temperature]           DECIMAL (10, 2) NOT NULL,
    [ValidFrom]             DATETIME2 (7)   NOT NULL,
    [ValidTo]               DATETIME2 (7)   NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_ColdRoomTemperatures_Archive]
    ON [Warehouse].[ColdRoomTemperatures_Archive]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);


GO

-- File: Colors.sql
﻿CREATE TABLE [Warehouse].[Colors] (
    [ColorID]      INT                                         CONSTRAINT [DF_Warehouse_Colors_ColorID] DEFAULT (NEXT VALUE FOR [Sequences].[ColorID]) NOT NULL,
    [ColorName]    NVARCHAR (20)                               NOT NULL,
    [LastEditedBy] INT                                         NOT NULL,
    [ValidFrom]    DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]      DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_Warehouse_Colors] PRIMARY KEY CLUSTERED ([ColorID] ASC),
    CONSTRAINT [FK_Warehouse_Colors_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [UQ_Warehouse_Colors_ColorName] UNIQUE NONCLUSTERED ([ColorName] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Warehouse].[Colors_Archive], DATA_CONSISTENCY_CHECK=ON));


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Stock items can (optionally) have colors', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'Colors';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a color within the database', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'Colors', @level2type = N'COLUMN', @level2name = N'ColorID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Full name of a color that can be used to describe stock items', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'Colors', @level2type = N'COLUMN', @level2name = N'ColorName';


GO

-- File: Colors_Archive.sql
﻿CREATE TABLE [Warehouse].[Colors_Archive] (
    [ColorID]      INT           NOT NULL,
    [ColorName]    NVARCHAR (20) NOT NULL,
    [LastEditedBy] INT           NOT NULL,
    [ValidFrom]    DATETIME2 (7) NOT NULL,
    [ValidTo]      DATETIME2 (7) NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_Colors_Archive]
    ON [Warehouse].[Colors_Archive]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);


GO

-- File: PackageTypes.sql
﻿CREATE TABLE [Warehouse].[PackageTypes] (
    [PackageTypeID]   INT                                         CONSTRAINT [DF_Warehouse_PackageTypes_PackageTypeID] DEFAULT (NEXT VALUE FOR [Sequences].[PackageTypeID]) NOT NULL,
    [PackageTypeName] NVARCHAR (50)                               NOT NULL,
    [LastEditedBy]    INT                                         NOT NULL,
    [ValidFrom]       DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]         DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_Warehouse_PackageTypes] PRIMARY KEY CLUSTERED ([PackageTypeID] ASC),
    CONSTRAINT [FK_Warehouse_PackageTypes_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [UQ_Warehouse_PackageTypes_PackageTypeName] UNIQUE NONCLUSTERED ([PackageTypeName] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Warehouse].[PackageTypes_Archive], DATA_CONSISTENCY_CHECK=ON));


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Ways that stock items can be packaged (ie: each, box, carton, pallet, kg, etc.', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'PackageTypes';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a package type within the database', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'PackageTypes', @level2type = N'COLUMN', @level2name = N'PackageTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Full name of package types that stock items can be purchased in or sold in', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'PackageTypes', @level2type = N'COLUMN', @level2name = N'PackageTypeName';


GO

-- File: PackageTypes_Archive.sql
﻿CREATE TABLE [Warehouse].[PackageTypes_Archive] (
    [PackageTypeID]   INT           NOT NULL,
    [PackageTypeName] NVARCHAR (50) NOT NULL,
    [LastEditedBy]    INT           NOT NULL,
    [ValidFrom]       DATETIME2 (7) NOT NULL,
    [ValidTo]         DATETIME2 (7) NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_PackageTypes_Archive]
    ON [Warehouse].[PackageTypes_Archive]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);


GO

-- File: StockGroups.sql
﻿CREATE TABLE [Warehouse].[StockGroups] (
    [StockGroupID]   INT                                         CONSTRAINT [DF_Warehouse_StockGroups_StockGroupID] DEFAULT (NEXT VALUE FOR [Sequences].[StockGroupID]) NOT NULL,
    [StockGroupName] NVARCHAR (50)                               NOT NULL,
    [LastEditedBy]   INT                                         NOT NULL,
    [ValidFrom]      DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]        DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_Warehouse_StockGroups] PRIMARY KEY CLUSTERED ([StockGroupID] ASC),
    CONSTRAINT [FK_Warehouse_StockGroups_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [UQ_Warehouse_StockGroups_StockGroupName] UNIQUE NONCLUSTERED ([StockGroupName] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Warehouse].[StockGroups_Archive], DATA_CONSISTENCY_CHECK=ON));


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Groups for categorizing stock items (ie: novelties, toys, edible novelties, etc.)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockGroups';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a stock group within the database', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockGroups', @level2type = N'COLUMN', @level2name = N'StockGroupID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Full name of groups used to categorize stock items', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockGroups', @level2type = N'COLUMN', @level2name = N'StockGroupName';


GO

-- File: StockGroups_Archive.sql
﻿CREATE TABLE [Warehouse].[StockGroups_Archive] (
    [StockGroupID]   INT           NOT NULL,
    [StockGroupName] NVARCHAR (50) NOT NULL,
    [LastEditedBy]   INT           NOT NULL,
    [ValidFrom]      DATETIME2 (7) NOT NULL,
    [ValidTo]        DATETIME2 (7) NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_StockGroups_Archive]
    ON [Warehouse].[StockGroups_Archive]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);


GO

-- File: StockItemHoldings.sql
﻿CREATE TABLE [Warehouse].[StockItemHoldings] (
    [StockItemID]           INT             NOT NULL,
    [QuantityOnHand]        INT             NOT NULL,
    [BinLocation]           NVARCHAR (20)   NOT NULL,
    [LastStocktakeQuantity] INT             NOT NULL,
    [LastCostPrice]         DECIMAL (18, 2) NOT NULL,
    [ReorderLevel]          INT             NOT NULL,
    [TargetStockLevel]      INT             NOT NULL,
    [LastEditedBy]          INT             NOT NULL,
    [LastEditedWhen]        DATETIME2 (7)   CONSTRAINT [DF_Warehouse_StockItemHoldings_LastEditedWhen] DEFAULT (sysdatetime()) NOT NULL,
    CONSTRAINT [PK_Warehouse_StockItemHoldings] PRIMARY KEY CLUSTERED ([StockItemID] ASC),
    CONSTRAINT [FK_Warehouse_StockItemHoldings_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [PKFK_Warehouse_StockItemHoldings_StockItemID_Warehouse_StockItems] FOREIGN KEY ([StockItemID]) REFERENCES [Warehouse].[StockItems] ([StockItemID])
);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Non-temporal attributes for stock items', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemHoldings';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'ID of the stock item that this holding relates to (this table holds non-temporal columns for stock)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemHoldings', @level2type = N'COLUMN', @level2name = N'StockItemID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity currently on hand (if tracked)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemHoldings', @level2type = N'COLUMN', @level2name = N'QuantityOnHand';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Bin location (ie location of this stock item within the depot)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemHoldings', @level2type = N'COLUMN', @level2name = N'BinLocation';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity at last stocktake (if tracked)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemHoldings', @level2type = N'COLUMN', @level2name = N'LastStocktakeQuantity';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Unit cost price the last time this stock item was purchased', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemHoldings', @level2type = N'COLUMN', @level2name = N'LastCostPrice';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity below which reordering should take place', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemHoldings', @level2type = N'COLUMN', @level2name = N'ReorderLevel';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Typical quantity ordered', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemHoldings', @level2type = N'COLUMN', @level2name = N'TargetStockLevel';


GO

-- File: StockItemStockGroups.sql
﻿CREATE TABLE [Warehouse].[StockItemStockGroups] (
    [StockItemStockGroupID] INT           CONSTRAINT [DF_Warehouse_StockItemStockGroups_StockItemStockGroupID] DEFAULT (NEXT VALUE FOR [Sequences].[StockItemStockGroupID]) NOT NULL,
    [StockItemID]           INT           NOT NULL,
    [StockGroupID]          INT           NOT NULL,
    [LastEditedBy]          INT           NOT NULL,
    [LastEditedWhen]        DATETIME2 (7) CONSTRAINT [DF_Warehouse_StockItemStockGroups_LastEditedWhen] DEFAULT (sysdatetime()) NOT NULL,
    CONSTRAINT [PK_Warehouse_StockItemStockGroups] PRIMARY KEY CLUSTERED ([StockItemStockGroupID] ASC),
    CONSTRAINT [FK_Warehouse_StockItemStockGroups_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Warehouse_StockItemStockGroups_StockGroupID_Warehouse_StockGroups] FOREIGN KEY ([StockGroupID]) REFERENCES [Warehouse].[StockGroups] ([StockGroupID]),
    CONSTRAINT [FK_Warehouse_StockItemStockGroups_StockItemID_Warehouse_StockItems] FOREIGN KEY ([StockItemID]) REFERENCES [Warehouse].[StockItems] ([StockItemID]),
    CONSTRAINT [UQ_StockItemStockGroups_StockGroupID_Lookup] UNIQUE NONCLUSTERED ([StockGroupID] ASC, [StockItemID] ASC),
    CONSTRAINT [UQ_StockItemStockGroups_StockItemID_Lookup] UNIQUE NONCLUSTERED ([StockItemID] ASC, [StockGroupID] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Which stock items are in which stock groups', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemStockGroups';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Internal reference for this linking row', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemStockGroups', @level2type = N'COLUMN', @level2name = N'StockItemStockGroupID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Stock item assigned to this stock group (FK indexed via unique constraint)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemStockGroups', @level2type = N'COLUMN', @level2name = N'StockItemID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'StockGroup assigned to this stock item (FK indexed via unique constraint)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemStockGroups', @level2type = N'COLUMN', @level2name = N'StockGroupID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Enforces uniqueness and indexes one side of the many to many relationship', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemStockGroups', @level2type = N'CONSTRAINT', @level2name = N'UQ_StockItemStockGroups_StockGroupID_Lookup';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Enforces uniqueness and indexes one side of the many to many relationship', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemStockGroups', @level2type = N'CONSTRAINT', @level2name = N'UQ_StockItemStockGroups_StockItemID_Lookup';


GO

-- File: StockItemTransactions.sql
﻿CREATE TABLE [Warehouse].[StockItemTransactions] (
    [StockItemTransactionID]  INT             CONSTRAINT [DF_Warehouse_StockItemTransactions_StockItemTransactionID] DEFAULT (NEXT VALUE FOR [Sequences].[TransactionID]) NOT NULL,
    [StockItemID]             INT             NOT NULL,
    [TransactionTypeID]       INT             NOT NULL,
    [CustomerID]              INT             NULL,
    [InvoiceID]               INT             NULL,
    [SupplierID]              INT             NULL,
    [PurchaseOrderID]         INT             NULL,
    [TransactionOccurredWhen] DATETIME2 (7)   NOT NULL,
    [Quantity]                DECIMAL (18, 3) NOT NULL,
    [LastEditedBy]            INT             NOT NULL,
    [LastEditedWhen]          DATETIME2 (7)   CONSTRAINT [DF_Warehouse_StockItemTransactions_LastEditedWhen] DEFAULT (sysdatetime()) NOT NULL,
    CONSTRAINT [PK_Warehouse_StockItemTransactions] PRIMARY KEY NONCLUSTERED ([StockItemTransactionID] ASC),
    CONSTRAINT [FK_Warehouse_StockItemTransactions_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Warehouse_StockItemTransactions_CustomerID_Sales_Customers] FOREIGN KEY ([CustomerID]) REFERENCES [Sales].[Customers] ([CustomerID]),
    CONSTRAINT [FK_Warehouse_StockItemTransactions_InvoiceID_Sales_Invoices] FOREIGN KEY ([InvoiceID]) REFERENCES [Sales].[Invoices] ([InvoiceID]),
    CONSTRAINT [FK_Warehouse_StockItemTransactions_PurchaseOrderID_Purchasing_PurchaseOrders] FOREIGN KEY ([PurchaseOrderID]) REFERENCES [Purchasing].[PurchaseOrders] ([PurchaseOrderID]),
    CONSTRAINT [FK_Warehouse_StockItemTransactions_StockItemID_Warehouse_StockItems] FOREIGN KEY ([StockItemID]) REFERENCES [Warehouse].[StockItems] ([StockItemID]),
    CONSTRAINT [FK_Warehouse_StockItemTransactions_SupplierID_Purchasing_Suppliers] FOREIGN KEY ([SupplierID]) REFERENCES [Purchasing].[Suppliers] ([SupplierID]),
    CONSTRAINT [FK_Warehouse_StockItemTransactions_TransactionTypeID_Application_TransactionTypes] FOREIGN KEY ([TransactionTypeID]) REFERENCES [Application].[TransactionTypes] ([TransactionTypeID])
);


GO
CREATE NONCLUSTERED INDEX [FK_Warehouse_StockItemTransactions_StockItemID]
    ON [Warehouse].[StockItemTransactions]([StockItemID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Warehouse_StockItemTransactions_TransactionTypeID]
    ON [Warehouse].[StockItemTransactions]([TransactionTypeID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Warehouse_StockItemTransactions_CustomerID]
    ON [Warehouse].[StockItemTransactions]([CustomerID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Warehouse_StockItemTransactions_InvoiceID]
    ON [Warehouse].[StockItemTransactions]([InvoiceID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Warehouse_StockItemTransactions_SupplierID]
    ON [Warehouse].[StockItemTransactions]([SupplierID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Warehouse_StockItemTransactions_PurchaseOrderID]
    ON [Warehouse].[StockItemTransactions]([PurchaseOrderID] ASC);


GO
CREATE CLUSTERED COLUMNSTORE INDEX [CCX_Warehouse_StockItemTransactions]
    ON [Warehouse].[StockItemTransactions];


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemTransactions', @level2type = N'INDEX', @level2name = N'FK_Warehouse_StockItemTransactions_StockItemID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemTransactions', @level2type = N'INDEX', @level2name = N'FK_Warehouse_StockItemTransactions_TransactionTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemTransactions', @level2type = N'INDEX', @level2name = N'FK_Warehouse_StockItemTransactions_CustomerID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemTransactions', @level2type = N'INDEX', @level2name = N'FK_Warehouse_StockItemTransactions_InvoiceID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemTransactions', @level2type = N'INDEX', @level2name = N'FK_Warehouse_StockItemTransactions_SupplierID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemTransactions', @level2type = N'INDEX', @level2name = N'FK_Warehouse_StockItemTransactions_PurchaseOrderID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Transactions covering all movements of all stock items', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemTransactions';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used to refer to a stock item transaction within the database', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemTransactions', @level2type = N'COLUMN', @level2name = N'StockItemTransactionID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'StockItem for this transaction', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemTransactions', @level2type = N'COLUMN', @level2name = N'StockItemID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Type of transaction', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemTransactions', @level2type = N'COLUMN', @level2name = N'TransactionTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Customer for this transaction (if applicable)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemTransactions', @level2type = N'COLUMN', @level2name = N'CustomerID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'ID of an invoice (for transactions associated with an invoice)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemTransactions', @level2type = N'COLUMN', @level2name = N'InvoiceID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Supplier for this stock transaction (if applicable)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemTransactions', @level2type = N'COLUMN', @level2name = N'SupplierID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'ID of an purchase order (for transactions associated with a purchase order)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemTransactions', @level2type = N'COLUMN', @level2name = N'PurchaseOrderID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Date and time when the transaction occurred', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemTransactions', @level2type = N'COLUMN', @level2name = N'TransactionOccurredWhen';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity of stock movement (positive is incoming stock, negative is outgoing)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItemTransactions', @level2type = N'COLUMN', @level2name = N'Quantity';


GO

-- File: StockItems.sql
﻿CREATE TABLE [Warehouse].[StockItems] (
    [StockItemID]            INT                                         CONSTRAINT [DF_Warehouse_StockItems_StockItemID] DEFAULT (NEXT VALUE FOR [Sequences].[StockItemID]) NOT NULL,
    [StockItemName]          NVARCHAR (100)                              NOT NULL,
    [SupplierID]             INT                                         NOT NULL,
    [ColorID]                INT                                         NULL,
    [UnitPackageID]          INT                                         NOT NULL,
    [OuterPackageID]         INT                                         NOT NULL,
    [Brand]                  NVARCHAR (50)                               NULL,
    [Size]                   NVARCHAR (20)                               NULL,
    [LeadTimeDays]           INT                                         NOT NULL,
    [QuantityPerOuter]       INT                                         NOT NULL,
    [IsChillerStock]         BIT                                         NOT NULL,
    [Barcode]                NVARCHAR (50)                               NULL,
    [TaxRate]                DECIMAL (18, 3)                             NOT NULL,
    [UnitPrice]              DECIMAL (18, 2)                             NOT NULL,
    [RecommendedRetailPrice] DECIMAL (18, 2)                             NULL,
    [TypicalWeightPerUnit]   DECIMAL (18, 3)                             NOT NULL,
    [MarketingComments]      NVARCHAR (MAX)                              NULL,
    [InternalComments]       NVARCHAR (MAX)                              NULL,
    [Photo]                  VARBINARY (MAX)                             NULL,
    [CustomFields]           NVARCHAR (MAX)                              NULL,
    [Tags]                   AS                                          (json_query([CustomFields],N'$.Tags')),
    [SearchDetails]          AS                                          (concat([StockItemName],N' ',[MarketingComments])),
    [LastEditedBy]           INT                                         NOT NULL,
    [ValidFrom]              DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]                DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_Warehouse_StockItems] PRIMARY KEY CLUSTERED ([StockItemID] ASC),
    CONSTRAINT [FK_Warehouse_StockItems_Application_People] FOREIGN KEY ([LastEditedBy]) REFERENCES [Application].[People] ([PersonID]),
    CONSTRAINT [FK_Warehouse_StockItems_ColorID_Warehouse_Colors] FOREIGN KEY ([ColorID]) REFERENCES [Warehouse].[Colors] ([ColorID]),
    CONSTRAINT [FK_Warehouse_StockItems_OuterPackageID_Warehouse_PackageTypes] FOREIGN KEY ([OuterPackageID]) REFERENCES [Warehouse].[PackageTypes] ([PackageTypeID]),
    CONSTRAINT [FK_Warehouse_StockItems_SupplierID_Purchasing_Suppliers] FOREIGN KEY ([SupplierID]) REFERENCES [Purchasing].[Suppliers] ([SupplierID]),
    CONSTRAINT [FK_Warehouse_StockItems_UnitPackageID_Warehouse_PackageTypes] FOREIGN KEY ([UnitPackageID]) REFERENCES [Warehouse].[PackageTypes] ([PackageTypeID]),
    CONSTRAINT [UQ_Warehouse_StockItems_StockItemName] UNIQUE NONCLUSTERED ([StockItemName] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Warehouse].[StockItems_Archive], DATA_CONSISTENCY_CHECK=ON));




GO
CREATE NONCLUSTERED INDEX [FK_Warehouse_StockItems_SupplierID]
    ON [Warehouse].[StockItems]([SupplierID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Warehouse_StockItems_ColorID]
    ON [Warehouse].[StockItems]([ColorID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Warehouse_StockItems_UnitPackageID]
    ON [Warehouse].[StockItems]([UnitPackageID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_Warehouse_StockItems_OuterPackageID]
    ON [Warehouse].[StockItems]([OuterPackageID] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'INDEX', @level2name = N'FK_Warehouse_StockItems_SupplierID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'INDEX', @level2name = N'FK_Warehouse_StockItems_ColorID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'INDEX', @level2name = N'FK_Warehouse_StockItems_UnitPackageID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Auto-created to support a foreign key', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'INDEX', @level2name = N'FK_Warehouse_StockItems_OuterPackageID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = N'Main entity table for stock items', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Numeric ID used for reference to a stock item within the database', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'StockItemID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Full name of a stock item (but not a full description)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'StockItemName';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Usual supplier for this stock item', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'SupplierID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Color (optional) for this stock item', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'ColorID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Usual package for selling units of this stock item', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'UnitPackageID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Usual package for selling outers of this stock item (ie cartons, boxes, etc.)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'OuterPackageID';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Brand for the stock item (if the item is branded)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'Brand';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Size of this item (eg: 100mm)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'Size';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Number of days typically taken from order to receipt of this stock item', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'LeadTimeDays';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Quantity of the stock item in an outer package', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'QuantityPerOuter';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Does this stock item need to be in a chiller?', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'IsChillerStock';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Barcode for this stock item', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'Barcode';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Tax rate to be applied', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'TaxRate';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Selling price (ex-tax) for one unit of this product', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'UnitPrice';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Recommended retail price for this stock item', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'RecommendedRetailPrice';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Typical weight for one unit of this product (packaged)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'TypicalWeightPerUnit';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Marketing comments for this stock item (shared outside the organization)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'MarketingComments';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Internal comments (not exposed outside organization)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'InternalComments';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Photo of the product', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'Photo';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Custom fields added by system users', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'CustomFields';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Advertising tags associated with this stock item (JSON array retrieved from CustomFields)', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'Tags';


GO
EXECUTE sp_addextendedproperty @name = N'Description', @value = 'Combination of columns used by full text search', @level0type = N'SCHEMA', @level0name = N'Warehouse', @level1type = N'TABLE', @level1name = N'StockItems', @level2type = N'COLUMN', @level2name = N'SearchDetails';


GO

-- File: StockItems_Archive.sql
﻿CREATE TABLE [Warehouse].[StockItems_Archive] (
    [StockItemID]            INT             NOT NULL,
    [StockItemName]          NVARCHAR (100)  NOT NULL,
    [SupplierID]             INT             NOT NULL,
    [ColorID]                INT             NULL,
    [UnitPackageID]          INT             NOT NULL,
    [OuterPackageID]         INT             NOT NULL,
    [Brand]                  NVARCHAR (50)   NULL,
    [Size]                   NVARCHAR (20)   NULL,
    [LeadTimeDays]           INT             NOT NULL,
    [QuantityPerOuter]       INT             NOT NULL,
    [IsChillerStock]         BIT             NOT NULL,
    [Barcode]                NVARCHAR (50)   NULL,
    [TaxRate]                DECIMAL (18, 3) NOT NULL,
    [UnitPrice]              DECIMAL (18, 2) NOT NULL,
    [RecommendedRetailPrice] DECIMAL (18, 2) NULL,
    [TypicalWeightPerUnit]   DECIMAL (18, 3) NOT NULL,
    [MarketingComments]      NVARCHAR (MAX)  NULL,
    [InternalComments]       NVARCHAR (MAX)  NULL,
    [Photo]                  VARBINARY (MAX) NULL,
    [CustomFields]           NVARCHAR (MAX)  NULL,
    [Tags]                   NVARCHAR (MAX)  NULL,
    [SearchDetails]          NVARCHAR (MAX)  NOT NULL,
    [LastEditedBy]           INT             NOT NULL,
    [ValidFrom]              DATETIME2 (7)   NOT NULL,
    [ValidTo]                DATETIME2 (7)   NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_StockItems_Archive]
    ON [Warehouse].[StockItems_Archive]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);


GO

-- File: VehicleTemperatures.sql
﻿CREATE TABLE [Warehouse].[VehicleTemperatures] (
    [VehicleTemperatureID] BIGINT          IDENTITY (1, 1) NOT NULL,
    [VehicleRegistration]  NVARCHAR (20)   COLLATE Latin1_General_CI_AS NOT NULL,
    [ChillerSensorNumber]  INT             NOT NULL,
    [RecordedWhen]         DATETIME2 (7)   NOT NULL,
    [Temperature]          DECIMAL (10, 2) NOT NULL,
    [FullSensorData]       NVARCHAR (1000) COLLATE Latin1_General_CI_AS NULL,
    [IsCompressed]         BIT             NOT NULL,
    [CompressedSensorData] VARBINARY (MAX) NULL,
    CONSTRAINT [PK_Warehouse_VehicleTemperatures] PRIMARY KEY NONCLUSTERED ([VehicleTemperatureID] ASC)
)
WITH (MEMORY_OPTIMIZED = ON);


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
