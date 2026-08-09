-- SQLGlot tsql DDL statements
-- Extracted from tsql.py test fixtures
-- Total statements: 172
-- ============================================================

-- Statement 1
CREATE view a.b.c;

-- Statement 2
CREATE VIEW b.c;

-- Statement 3
DROP view a.b.c;

-- Statement 4
DROP VIEW b.c;

-- Statement 5
TRUNCATE TABLE t1 WITH (PARTITIONS(1, 2 TO 5, 10 TO 20, 84));

-- Statement 6
CREATE CLUSTERED INDEX [IX_OfficeTagDetail_TagDetailID] ON [dbo].[OfficeTagDetail]([TagDetailID] ASC);

-- Statement 7
CREATE INDEX [x] ON [y]([z] ASC) WITH (allow_page_locks=on) ON X([y]);

-- Statement 8
CREATE INDEX [x] ON [y]([z] ASC) WITH (allow_page_locks=on) ON PRIMARY;

-- Statement 9
CREATE TABLE test_table([ID] [BIGINT] NOT NULL,[EffectiveFrom] [DATETIME2] (3) NOT NULL);

-- Statement 10
CREATE TABLE test_table (`ID` BIGINT NOT NULL, `EffectiveFrom` TIMESTAMP NOT NULL);

-- Statement 11
CREATE TABLE test_table ([ID] BIGINT NOT NULL, [EffectiveFrom] DATETIME2(3) NOT NULL);

-- Statement 12
CREATE TABLE TEMP_NESTED_WITH AS WITH C AS (WITH A AS (SELECT 2 AS value) SELECT * FROM A) SELECT * FROM C;

-- Statement 13
CREATE TABLE TEMP_NESTED_WITH AS WITH A AS (SELECT 2 AS value), C AS (SELECT * FROM A) SELECT * FROM (SELECT * FROM C) AS temp;

-- Statement 14
CREATE TABLE foo AS WITH t(c) AS (SELECT 1) SELECT c FROM t;

-- Statement 15
CREATE TABLE foo AS WITH t(c) AS (SELECT 1) SELECT * FROM (SELECT c AS c FROM t) AS temp;

-- Statement 16
CREATE TEMPORARY TABLE foo AS WITH t(c) AS (SELECT 1) SELECT * FROM (SELECT c AS c FROM t) AS temp;

-- Statement 17
CREATE TEMPORARY TABLE foo AS WITH t(c) AS (SELECT 1) SELECT c FROM t;

-- Statement 18
CREATE TABLE #mytemptable (a INTEGER);

-- Statement 19
CREATE TEMPORARY TABLE mytemptable (a INT);

-- Statement 20
CREATE GLOBAL TEMPORARY TABLE mytemptable (a INT);

-- Statement 21
CREATE TEMPORARY TABLE mytemptable (a INT) USING PARQUET;

-- Statement 22
CREATE TABLE #mytemp (a INTEGER, b CHAR(2), c TIME(4), d FLOAT(24));

-- Statement 23
CREATE TEMPORARY TABLE mytemp (a INT, b CHAR(2), c TIMESTAMP, d FLOAT) USING PARQUET;

-- Statement 24
CREATE TABLE [dbo].[mytable](
[email] [varchar](255) NOT NULL,
CONSTRAINT [UN_t_mytable] UNIQUE NONCLUSTERED
(
    [email] ASC
)
);

-- Statement 25
CREATE TABLE `dbo`.`mytable` (`email` VARCHAR(255) NOT NULL);

-- Statement 26
CREATE TABLE x ( A INTEGER NOT NULL, B INTEGER NULL );

-- Statement 27
CREATE TABLE x (A INTEGER NOT NULL, B INTEGER NULL);

-- Statement 28
CREATE TABLE x (A INT NOT NULL, B INT);

-- Statement 29
CREATE TABLE x (CONSTRAINT "pk_mytable" UNIQUE NONCLUSTERED (a DESC)) ON b (c);

-- Statement 30
CREATE TABLE x (CONSTRAINT [pk_mytable] UNIQUE NONCLUSTERED (a DESC)) ON b (c);

-- Statement 31
CREATE TABLE x ([zip_cd] VARCHAR(5) NULL NOT FOR REPLICATION, [zip_cd_mkey] VARCHAR(5) NOT NULL, CONSTRAINT [pk_mytable] PRIMARY KEY CLUSTERED ([zip_cd_mkey] ASC) WITH (PAD_INDEX=ON, STATISTICS_NORECOMPUTE=OFF) ON [INDEX]) ON [SECONDARY];

-- Statement 32
CREATE TABLE x (`zip_cd` VARCHAR(5), `zip_cd_mkey` VARCHAR(5) NOT NULL, CONSTRAINT `pk_mytable` PRIMARY KEY (`zip_cd_mkey`));

-- Statement 33
CREATE TABLE tbl (a AS (x + 1) PERSISTED, b AS (y + 2), c AS (y / 3) PERSISTED NOT NULL);

-- Statement 34
CREATE TABLE [db].[tbl]([a] [int]);

-- Statement 35
CREATE TABLE [db].[tbl] ([a] INTEGER);

-- Statement 36
DROP TABLE IF EXISTS TempTableName;

-- Statement 37
DECLARE @TestVariable AS VARCHAR(100) = 'Save Our Planet';

-- Statement 38
DECLARE @TestVariable VARCHAR(100) = 'Save Our Planet';

-- Statement 39
CREATE TABLE db.t1 (a INTEGER, b VARCHAR(50), CONSTRAINT c PRIMARY KEY (a DESC));

-- Statement 40
CREATE TABLE db.t1 (a INTEGER, b INTEGER, CONSTRAINT c PRIMARY KEY (a DESC, b));

-- Statement 41
CREATE PROCEDURE test(@v1 INTEGER = 1, @v2 CHAR(1) = 'c');

-- Statement 42
DECLARE @v1 AS INTEGER = 1, @v2 AS CHAR(1) = 'c';

-- Statement 43
DECLARE @v1 INTEGER = 1, @v2 CHAR(1) = 'c';

-- Statement 44
CREATE PROCEDURE test(@v1 INTEGER = 1 {output}, @v2 CHAR(1) {output});

-- Statement 45
CREATE PROCEDURE test(@v1 AS INTEGER = 1, @v2 AS CHAR(1) = 'c');

-- Statement 46
CREATE TABLE t (col1 DATETIME2(2));

-- Statement 47
CREATE TABLE t (col1 TIMESTAMP_NTZ(2));

-- Statement 48
CREATE {colstore} INDEX index_name ON foo.bar;

-- Statement 49
CREATE VIEW a.b WITH {view_attr} AS SELECT * FROM x;

-- Statement 50
CREATE VIEW start WITH SCHEMABINDING AS SELECT a FROM x;

-- Statement 51
ALTER TABLE dbo.DocExe DROP CONSTRAINT FK_Column_B;

-- Statement 52
CREATE TABLE "dbo"."benchmark" (;

-- Statement 53
CREATE TABLE [dbo].[benchmark] (;

-- Statement 54
CREATE SCHEMA testSchema;

-- Statement 55
CREATE VIEW t AS WITH cte AS (SELECT 1 AS c) SELECT c FROM cte;

-- Statement 56
ALTER TABLE tbl SET (SYSTEM_VERSIONING=OFF);

-- Statement 57
ALTER TABLE tbl SET (FILESTREAM_ON = 'test');

-- Statement 58
ALTER TABLE tbl SET (DATA_DELETION=ON);

-- Statement 59
ALTER TABLE tbl SET (DATA_DELETION=OFF);

-- Statement 60
ALTER TABLE t1 WITH CHECK ADD CONSTRAINT ctr FOREIGN KEY (c1) REFERENCES t2 (c2);

-- Statement 61
ALTER TABLE tbl SET (SYSTEM_VERSIONING=ON(HISTORY_TABLE=db.tbl, DATA_CONSISTENCY_CHECK=OFF, HISTORY_RETENTION_PERIOD=5 DAYS));

-- Statement 62
ALTER TABLE tbl SET (SYSTEM_VERSIONING=ON(HISTORY_TABLE=db.tbl, HISTORY_RETENTION_PERIOD=INFINITE));

-- Statement 63
ALTER TABLE tbl SET (DATA_DELETION=ON(FILTER_COLUMN=col, RETENTION_PERIOD=5 MONTHS));

-- Statement 64
ALTER VIEW v AS SELECT a, b, c, d FROM foo;

-- Statement 65
ALTER VIEW v AS SELECT * FROM foo WHERE c > 100;

-- Statement 66
ALTER VIEW v WITH SCHEMABINDING AS SELECT * FROM foo WHERE c > 100;

-- Statement 67
ALTER VIEW v WITH ENCRYPTION AS SELECT * FROM foo WHERE c > 100;

-- Statement 68
ALTER VIEW v WITH VIEW_METADATA AS SELECT * FROM foo WHERE c > 100;

-- Statement 69
CREATE COLUMNSTORE INDEX index_name ON foo.bar;

-- Statement 70
CREATE NONCLUSTERED COLUMNSTORE INDEX index_name ON foo.bar;

-- Statement 71
CREATE PROCEDURE foo AS BEGIN DELETE FROM bla WHERE foo < CURRENT_TIMESTAMP - 7; END;

-- Statement 72
CREATE PROCEDURE foo AS BEGIN DELETE FROM bla WHERE foo < GETDATE() - 7; END;

-- Statement 73
CREATE TABLE [#temptest] (name INTEGER);

-- Statement 74
CREATE TEMPORARY TABLE 'temptest' (name INTEGER);

-- Statement 75
CREATE TABLE tbl (id INTEGER IDENTITY PRIMARY KEY);

-- Statement 76
CREATE TABLE tbl (id INT AUTO_INCREMENT PRIMARY KEY);

-- Statement 77
CREATE TABLE tbl (id INTEGER NOT NULL IDENTITY(10, 1) PRIMARY KEY);

-- Statement 78
CREATE TABLE tbl (id INT NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 10) PRIMARY KEY);

-- Statement 79
CREATE TABLE tbl (id BIGINT NOT NULL GENERATED BY DEFAULT AS IDENTITY (START WITH 10 INCREMENT BY 1) PRIMARY KEY);

-- Statement 80
CREATE TABLE tbl (id INT NOT NULL GENERATED BY DEFAULT AS IDENTITY (START WITH 10 INCREMENT BY 1) PRIMARY KEY);

-- Statement 81
CREATE TABLE x (a UNIQUEIDENTIFIER, b VARBINARY);

-- Statement 82
CREATE TABLE x (a UUID, b BLOB);

-- Statement 83
CREATE TABLE x (a UUID, b VARBINARY);

-- Statement 84
CREATE TABLE x (a STRING, b BINARY);

-- Statement 85
CREATE TABLE x (a UUID, b BYTEA);

-- Statement 86
CREATE TABLE foo.bar.baz AS SELECT * FROM a.b.c;

-- Statement 87
CREATE TABLE foo.bar.baz AS (SELECT * FROM a.b.c);

-- Statement 88
CREATE INDEX IF NOT EXISTS idx ON db.tbl;

-- Statement 89
CREATE SCHEMA IF NOT EXISTS foo;

-- Statement 90
CREATE TABLE IF NOT EXISTS foo.bar.baz (a INTEGER);

-- Statement 91
CREATE TABLE IF NOT EXISTS foo.bar.baz AS SELECT '2020' AS z FROM a.b.c;

-- Statement 92
CREATE TABLE IF NOT EXISTS foo.bar.baz AS WITH cte1 AS (SELECT 1 AS col_a), cte2 AS (SELECT 1 AS col_b) SELECT col_a FROM cte1 UNION ALL SELECT col_b FROM cte2;

-- Statement 93
CREATE OR ALTER VIEW a.b AS SELECT 1;

-- Statement 94
CREATE OR REPLACE VIEW a.b AS SELECT 1;

-- Statement 95
ALTER TABLE a ADD b INTEGER, c INTEGER;

-- Statement 96
ALTER TABLE a ADD COLUMN b INT, ADD COLUMN c INT;

-- Statement 97
ALTER TABLE a ALTER COLUMN b INTEGER;

-- Statement 98
ALTER TABLE a ALTER COLUMN b INT;

-- Statement 99
ALTER TABLE a ALTER COLUMN b SET DATA TYPE INT;

-- Statement 100
ALTER TABLE a ALTER COLUMN b INTEGER NOT NULL;

-- Statement 101
ALTER TABLE a ALTER COLUMN b INTEGER NULL;

-- Statement 102
ALTER TABLE a ALTER COLUMN b VARCHAR(10) COLLATE Latin1_General_CI_AS NOT NULL;

-- Statement 103
ALTER TABLE a MODIFY COLUMN b INT NOT NULL;

-- Statement 104
ALTER TABLE a MODIFY COLUMN b INT NULL;

-- Statement 105
ALTER TABLE tbl ADD CONSTRAINT cnstr PRIMARY KEY CLUSTERED (ID), CONSTRAINT cnstr2 UNIQUE CLUSTERED (ID);

-- Statement 106
DECLARE @DWH_DateCreated AS DATETIME2 = CONVERT(DATETIME2, GETDATE(), 104);

-- Statement 107
DECLARE @DWH_DateCreated DATETIME2 = CONVERT(DATETIME2, GETDATE(), 104);

-- Statement 108
CREATE PROCEDURE foo @a INTEGER, @b INTEGER AS SELECT @a = SUM(bla) FROM baz AS bar;

-- Statement 109
CREATE PROC foo @ID INTEGER, @AGE INTEGER AS SELECT DB_NAME(@ID) AS ThatDB;

-- Statement 110
CREATE PROC foo AS SELECT BAR() AS baz;

-- Statement 111
CREATE PROCEDURE foo AS SELECT BAR() AS baz;

-- Statement 112
CREATE PROCEDURE foo WITH ENCRYPTION AS SELECT 1;

-- Statement 113
CREATE PROCEDURE foo WITH RECOMPILE AS SELECT 1;

-- Statement 114
CREATE PROCEDURE foo WITH SCHEMABINDING AS SELECT 1;

-- Statement 115
CREATE PROCEDURE foo WITH NATIVE_COMPILATION AS SELECT 1;

-- Statement 116
CREATE PROCEDURE foo WITH EXECUTE AS OWNER AS SELECT 1;

-- Statement 117
CREATE PROCEDURE foo WITH EXECUTE AS 'username' AS SELECT 1;

-- Statement 118
CREATE PROCEDURE foo WITH EXECUTE AS OWNER, SCHEMABINDING, NATIVE_COMPILATION AS SELECT 1;

-- Statement 119
CREATE FUNCTION foo(@bar INTEGER) RETURNS TABLE AS RETURN SELECT 1;

-- Statement 120
CREATE FUNCTION dbo.ISOweek(@DATE DATETIME2) RETURNS INTEGER;

-- Statement 121
CREATE FUNCTION dbo.f() RETURNS TABLE AS RETURN (WITH subquery AS (SELECT id AS id FROM subtable) SELECT other_id FROM main_table AS mt INNER JOIN subquery ON subquery.id = mt.other_id);

-- Statement 122
CREATE FUNCTION foo(@bar INTEGER) RETURNS @foo TABLE (x INTEGER, y NUMERIC) AS RETURN SELECT 1;

-- Statement 123
CREATE FUNCTION foo() RETURNS @contacts TABLE (first_name VARCHAR(50), phone VARCHAR(25)) AS SELECT @fname, @phone;

-- Statement 124
CREATE FUNCTION udfProductInYear (
    @model_year INT
)
RETURNS TABLE
AS
RETURN
    SELECT
        product_name,
        model_year,
        list_price
    FROM
        production.products
    WHERE
        model_year = @model_year;

-- Statement 125
CREATE FUNCTION udfProductInYear(
    @model_year INTEGER
)
RETURNS TABLE AS
RETURN SELECT
  product_name,
  model_year,
  list_price
FROM production.products
WHERE
  model_year = @model_year;

-- Statement 126
CREATE TABLE schema.table AS SELECT a, id FROM (SELECT a, (SELECT id FROM tb ORDER BY t DESC LIMIT 1) as id FROM tbl) AS _subquery;

-- Statement 127
CREATE TEMPORARY TABLE "temptest" (name INT);

-- Statement 128
CREATE TABLE test ("data" CHAR(7), "valid_from" DATETIME2(2) GENERATED ALWAYS AS ROW START NOT NULL, "valid_to" DATETIME2(2) GENERATED ALWAYS AS ROW END NOT NULL, PERIOD FOR SYSTEM_TIME ("valid_from", "valid_to")) WITH(SYSTEM_VERSIONING=ON);

-- Statement 129
CREATE TABLE test ([data] CHAR(7), [valid_from] DATETIME2(2) GENERATED ALWAYS AS ROW START NOT NULL, [valid_to] DATETIME2(2) GENERATED ALWAYS AS ROW END NOT NULL, PERIOD FOR SYSTEM_TIME ([valid_from], [valid_to])) WITH(SYSTEM_VERSIONING=ON);

-- Statement 130
CREATE TABLE test ([data] CHAR(7), [valid_from] DATETIME2(2) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL, [valid_to] DATETIME2(2) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL, PERIOD FOR SYSTEM_TIME ([valid_from], [valid_to])) WITH(SYSTEM_VERSIONING=ON(HISTORY_TABLE=[dbo].[benchmark_history], DATA_CONSISTENCY_CHECK=ON));

-- Statement 131
CREATE TABLE test ([data] CHAR(7), [valid_from] DATETIME2(2) GENERATED ALWAYS AS ROW START NOT NULL, [valid_to] DATETIME2(2) GENERATED ALWAYS AS ROW END NOT NULL, PERIOD FOR SYSTEM_TIME ([valid_from], [valid_to])) WITH(SYSTEM_VERSIONING=ON(HISTORY_TABLE=[dbo].[benchmark_history], DATA_CONSISTENCY_CHECK=ON));

-- Statement 132
CREATE TABLE test ([data] CHAR(7), [valid_from] DATETIME2(2) GENERATED ALWAYS AS ROW START NOT NULL, [valid_to] DATETIME2(2) GENERATED ALWAYS AS ROW END NOT NULL, PERIOD FOR SYSTEM_TIME ([valid_from], [valid_to])) WITH(SYSTEM_VERSIONING=ON(HISTORY_TABLE=[dbo].[benchmark_history], DATA_CONSISTENCY_CHECK=OFF));

-- Statement 133
CREATE TABLE test ([data] CHAR(7), [valid_from] DATETIME2(2) GENERATED ALWAYS AS ROW START NOT NULL, [valid_to] DATETIME2(2) GENERATED ALWAYS AS ROW END NOT NULL, PERIOD FOR SYSTEM_TIME ([valid_from], [valid_to])) WITH(SYSTEM_VERSIONING=ON(HISTORY_TABLE=[dbo].[benchmark_history]));

-- Statement 134
DECLARE @X INT;

-- Statement 135
DECLARE @X INTEGER;

-- Statement 136
DECLARE @X INT = 1;

-- Statement 137
DECLARE @X INTEGER = 1;

-- Statement 138
DECLARE @X INT, @Y VARCHAR(10);

-- Statement 139
DECLARE @X INTEGER, @Y VARCHAR(10);

-- Statement 140
declare @X int = (select col from table where id = 1);

-- Statement 141
DECLARE @X INTEGER = (SELECT col FROM table WHERE id = 1);

-- Statement 142
declare @X TABLE (Id INT NOT NULL, Name VARCHAR(100) NOT NULL);

-- Statement 143
DECLARE @X TABLE (Id INTEGER NOT NULL, Name VARCHAR(100) NOT NULL);

-- Statement 144
declare @X TABLE (Id INT NOT NULL, constraint PK_Id primary key (Id));

-- Statement 145
DECLARE @X TABLE (Id INTEGER NOT NULL, CONSTRAINT PK_Id PRIMARY KEY (Id));

-- Statement 146
declare @X UserDefinedTableType;

-- Statement 147
DECLARE @MyTableVar TABLE (EmpID INT NOT NULL, PRIMARY KEY CLUSTERED (EmpID), UNIQUE NONCLUSTERED (EmpID), INDEX CustomNonClusteredIndex NONCLUSTERED (EmpID));

-- Statement 148
DECLARE vendor_cursor CURSOR FOR SELECT VendorID, Name FROM Purchasing.Vendor WHERE PreferredVendorStatus = 1 ORDER BY VendorID;

-- Statement 149
ALTER TABLE a ALTER COLUMN b CHAR(10) COLLATE abc;

-- Statement 150
CREATE TRIGGER reminder ON customers AFTER INSERT AS BEGIN INSERT INTO audit_log (customer_id, action, created_at) SELECT id, 'INSERT', GETDATE() FROM inserted END;

-- Statement 151
CREATE TRIGGER updview ON vw_employees INSTEAD OF UPDATE AS BEGIN UPDATE employees SET salary = inserted.salary FROM inserted WHERE employees.id = inserted.id END;

-- Statement 152
CREATE TRIGGER ddl_trig ON DATABASE FOR CREATE_TABLE AS BEGIN INSERT INTO schema_changes (event_type, event_time, login_name) VALUES ('CREATE_TABLE', GETDATE(), SYSTEM_USER) END;

-- Statement 153
CREATE PROCEDURE test2(@in1 INTEGER, @c CHAR(1))
AS
BEGIN
    IF @in1 > 1 AND @c = 'c'
    BEGIN
        SELECT col1 FROM t WHERE t.col2 = @in1;
    END;
END;

-- Statement 154
CREATE PROCEDURE test(@in1 INTEGER)
AS
BEGIN
    SELECT 1;
    IF @in1 > 1
    BEGIN
        SELECT 1;
        SELECT 2;
    END;
    ELSE
    BEGIN
        SELECT 3;
        SELECT 4;
    END;
END;

-- Statement 155
CREATE PROCEDURE test(@in1 INTEGER)
AS
BEGIN
    IF @in1 > 1
    BEGIN
        SELECT col1 FROM t WHERE t.col2 = @in1;
        SELECT 100;
    END;
    IF @in1 > 1
    BEGIN
        SELECT col2 FROM t1;
    END;
END;

-- Statement 156
CREATE PROCEDURE test(@in1 INTEGER)
AS
BEGIN
    DECLARE @q1 INTEGER, @q2 INTEGER, @q3 INTEGER;
    SET @q1 = (SELECT MAX(col1) FROM t1);
    SET @q2 = (SELECT MIN(col1) FROM t2);
    IF @in1 > 1
    BEGIN
        SELECT 3;
        SET @q3 = (SELECT MAX(col2) FROM t1);
        IF @q3 < 5
        BEGIN
            SELECT 1;
            SELECT 2;
        END;
    END;
    IF @in1 > 1
    BEGIN
        SELECT 1;
    END;
END;

-- Statement 157
CREATE PROCEDURE test(@in1 INTEGER)
AS
BEGIN
    SELECT 1;
    IF @in1 > 1
    BEGIN
        SELECT 3;
    END;
    ELSE
    BEGIN
        SELECT 4;
        SELECT 5;
        IF @in1 < 0
        BEGIN
            SELECT 1;
        END;
    END;
END;

-- Statement 158
CREATE PROCEDURE test(@in1 INTEGER, @c CHAR(1))
AS
BEGIN
    WHILE @in1 > 100
    BEGIN
        SELECT col1 FROM t WHERE t.col2 = @in1 AND t.col3 = @c;
        SET @in1 = @in1 - 1;
    END;
END;

-- Statement 159
CREATE PROCEDURE test(@in1 INTEGER)
AS
BEGIN
    DECLARE @temp INTEGER;
    WHILE @in1 > 100
    BEGIN
        SET @temp = (SELECT MAX(col1) FROM t WHERE t.col2 = @in1);
        SET @in1 = @in1 - @temp;
    END;
    SET @in1 = 50;
    WHILE @in1 > 5
    BEGIN
        SELECT col2 FROM t1 WHERE t1.col3 = @in1;
        SET @in1 = @in1 - 1;
    END;
END;

-- Statement 160
CREATE PROCEDURE dbo.test(@in1 INTEGER = 5, @in2 VARCHAR(40) = 'empty', @in3 INTEGER = 1)
AS
BEGIN
    INSERT INTO t (id, col1, col2) VALUES (@in1, @in2, @in3);
END;
CREATE PROCEDURE c.s.test2
AS
BEGIN
    EXECUTE dbo.test;
    DECLARE @i INTEGER = 0;
    WHILE @i < 100
    BEGIN
        EXECUTE test @in2 = 'temp_new';
        SET @i = @i + 100;
    END;
END;

-- Statement 161
CREATE PROCEDURE DropTableIfExists
    @TableName NVARCHAR(128)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = N'DROP TABLE IF EXISTS [' + @TableName + ']';
    EXECUTE sp_executesql 'SELECT 1 AS c';
    EXECUTE sp_executesql N'SELECT 1 AS c';
    EXECUTE sp_executesql @SQL;
    EXECUTE sp_executesql @stmt = @SQL;
END;

-- Statement 162
CREATE PROCEDURE test
AS
BEGIN
    DECLARE @x INTEGER = 100;
    IF @x > ANY (SELECT 100)
    BEGIN
        SET @x = 100;
    END;
    ELSE
    BEGIN
        SET @x = 0;
    END;
END;

-- Statement 163
CREATE procedure [TRANSF].[SP_Merge_Sales_Real]
    @Loadid INTEGER
   ,@NumberOfRows INTEGER
WITH EXECUTE AS OWNER, SCHEMABINDING, NATIVE_COMPILATION
AS
BEGIN
    SET XACT_ABORT ON;

    DECLARE @DWH_DateCreated AS DATETIME = CONVERT(DATETIME, getdate(), 104);
    DECLARE @DWH_DateModified DATETIME2 = CONVERT(DATETIME2, GETDATE(), 104);
    DECLARE @DWH_IdUserCreated INTEGER = SUSER_ID (CURRENT_USER());
    DECLARE @DWH_IdUserModified INTEGER = SUSER_ID (SYSTEM_USER);

    DECLARE @SalesAmountBefore float;
    SELECT @SalesAmountBefore=SUM(SalesAmount) FROM TRANSF.[Pre_Merge_Sales_Real] S;
END;

-- Statement 164
CREATE PROCEDURE [TRANSF].[SP_Merge_Sales_Real] @Loadid INTEGER, @NumberOfRows INTEGER WITH EXECUTE AS OWNER, SCHEMABINDING, NATIVE_COMPILATION AS BEGIN SET XACT_ABORT ON;

-- Statement 165
DECLARE @DWH_DateCreated DATETIME = CONVERT(DATETIME, GETDATE(), 104);

-- Statement 166
DECLARE @DWH_DateModified DATETIME2 = CONVERT(DATETIME2, GETDATE(), 104);

-- Statement 167
DECLARE @DWH_IdUserCreated INTEGER = SUSER_ID(CURRENT_USER());

-- Statement 168
DECLARE @DWH_IdUserModified INTEGER = SUSER_ID(CURRENT_USER());

-- Statement 169
DECLARE @SalesAmountBefore FLOAT;

-- Statement 170
CREATE PROC [dbo].[transform_proc] AS

DECLARE @CurrentDate VARCHAR(20);
SET @CurrentDate = CONVERT(VARCHAR(20), GETDATE(), 120);

CREATE TABLE [target_schema].[target_table]
(a INTEGER)
WITH (DISTRIBUTION = REPLICATE, HEAP);

-- Statement 171
CREATE PROC [dbo].[transform_proc] AS DECLARE @CurrentDate VARCHAR(20);

-- Statement 172
CREATE TABLE [target_schema].[target_table] (a INTEGER) WITH (DISTRIBUTION=REPLICATE, HEAP);

