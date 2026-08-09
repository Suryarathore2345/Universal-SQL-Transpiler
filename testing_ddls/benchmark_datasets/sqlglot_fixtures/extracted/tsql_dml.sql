-- SQLGlot tsql DML statements
-- Extracted from tsql.py test fixtures
-- Total statements: 315
-- ============================================================

-- Statement 1
WITH x AS (SELECT 1 AS [1]) SELECT TOP 0 * FROM (SELECT * FROM x UNION SELECT * FROM x) AS _l_0 ORDER BY 1;

-- Statement 2
WITH x AS (SELECT 1) SELECT * FROM x UNION SELECT * FROM x ORDER BY 1 LIMIT 0;

-- Statement 3
SELECT * FROM a..b;

-- Statement 4
SELECT TOP (SELECT 1) * FROM t;

-- Statement 5
SELECT ATN2(x, y);

-- Statement 6
SELECT EXP(1);

-- Statement 7
SELECT SYSDATETIMEOFFSET();

-- Statement 8
SELECT COMPRESS('Hello World');

-- Statement 9
SELECT go;

-- Statement 10
SELECT TRIM('     test    ') AS Result;

-- Statement 11
SELECT TRIM('.,! ' FROM '     #     test    .') AS Result;

-- Statement 12
SELECT * FROM t TABLESAMPLE (10 PERCENT);

-- Statement 13
SELECT * FROM t TABLESAMPLE (20 ROWS);

-- Statement 14
SELECT * FROM t TABLESAMPLE (10 PERCENT) REPEATABLE (123);

-- Statement 15
SELECT CONCAT(column1, column2);

-- Statement 16
SELECT TestSpecialChar.Test# FROM TestSpecialChar;

-- Statement 17
SELECT TestSpecialChar.Test@ FROM TestSpecialChar;

-- Statement 18
SELECT TestSpecialChar.Test$ FROM TestSpecialChar;

-- Statement 19
SELECT TestSpecialChar.Test_ FROM TestSpecialChar;

-- Statement 20
SELECT TOP (2 + 1) 1;

-- Statement 21
SELECT * FROM t WHERE NOT c;

-- Statement 22
SELECT * FROM t WHERE NOT c <> 0;

-- Statement 23
WITH t1 AS (SELECT 1 AS a), t2 AS (SELECT 1 AS a) SELECT TOP 10 a FROM t1 UNION ALL SELECT TOP 10 a FROM t2;

-- Statement 24
SELECT TOP 10 s.RECORDID, n.c.VALUE('(/*:FORM_ROOT/*:SOME_TAG)[1]', 'float') AS SOME_TAG_VALUE FROM source_table.dbo.source_data AS s(nolock) CROSS APPLY FormContent.nodes('/*:FORM_ROOT') AS N(C);

-- Statement 25
COPY INTO test_1 FROM 'path' WITH (FORMAT_NAME = test, FILE_TYPE = 'CSV', CREDENTIAL = (IDENTITY='Shared Access Signature', SECRET='token'), FIELDTERMINATOR = ';', ROWTERMINATOR = '0X0A', ENCODING = 'UTF8', DATEFORMAT = 'ymd', MAXERRORS = 10, ERRORFILE = 'errorsfolder', IDENTITY_INSERT = 'ON');

-- Statement 26
WITH t1 AS (SELECT 1 AS a), t2 AS (SELECT 1 AS a) SELECT TOP 10 a FROM t1 UNION ALL SELECT TOP 10 a FROM t2 ORDER BY a DESC;

-- Statement 27
WITH t1 AS (SELECT 1 AS a), t2 AS (SELECT 1 AS a) SELECT COUNT(*) FROM (SELECT TOP 10 a FROM t1 UNION ALL SELECT TOP 10 a FROM t2 ORDER BY a DESC) AS t;

-- Statement 28
SELECT 1 AS "[x]";

-- Statement 29
SELECT 1 AS [[x]]];

-- Statement 30
INSERT INTO foo.bar WITH cte AS (SELECT 1 AS one) SELECT * FROM cte;

-- Statement 31
WITH cte AS (SELECT 1 AS one) INSERT INTO foo.bar SELECT * FROM cte;

-- Statement 32
SELECT 1 WHERE EXISTS(SELECT 1);

-- Statement 33
SELECT CONVERT(DATETIME, '2006-04-25T15:50:59.997', 126);

-- Statement 34
SELECT STRPTIME('2006-04-25T15:50:59.997', '%Y-%m-%dT%H:%M:%S.%f');

-- Statement 35
WITH A AS (SELECT 2 AS value), C AS (SELECT * FROM A) SELECT * INTO TEMP_NESTED_WITH FROM (SELECT * FROM C) AS temp;

-- Statement 36
SELECT IIF(cond <> 0, 'True', 'False');

-- Statement 37
SELECT IF(cond, 'True', 'False');

-- Statement 38
SELECT IIF(cond, 'True', 'False');

-- Statement 39
SELECT TRIM(BOTH 'a' FROM a);

-- Statement 40
SELECT TIMEFROMPARTS(23, 59, 59, 0, 0);

-- Statement 41
SELECT MAKE_TIME(23, 59, 59);

-- Statement 42
SELECT MAKETIME(23, 59, 59);

-- Statement 43
SELECT TIME_FROM_PARTS(23, 59, 59);

-- Statement 44
SELECT DATETIMEFROMPARTS(2013, 4, 5, 12, 00, 00, 0);

-- Statement 45
SELECT TIMESTAMP_FROM_PARTS(2013, 4, 5, 12, 00, 00, 987654321);

-- Statement 46
SELECT MAKE_TIMESTAMP(2013, 4, 5, 12, 00, 00 + (0 / 1000.0));

-- Statement 47
SELECT TIMESTAMP_FROM_PARTS(2013, 4, 5, 12, 00, 00, 0 * 1000000);

-- Statement 48
SELECT TOP 1 * FROM (SELECT x FROM t1 UNION ALL SELECT x FROM t2) AS _l_0;

-- Statement 49
SELECT x FROM t1 UNION ALL SELECT x FROM t2 LIMIT 1;

-- Statement 50
WITH t(c) AS (SELECT 1) SELECT * INTO foo FROM (SELECT c AS c FROM t) AS temp;

-- Statement 51
WITH t(c) AS (SELECT 1) SELECT * INTO foo FROM (SELECT c AS c FROM t) temp;

-- Statement 52
WITH t(c) AS (SELECT 1) SELECT * INTO UNLOGGED #foo FROM (SELECT c AS c FROM t) AS temp;

-- Statement 53
WITH t(c) AS (SELECT 1) SELECT * INTO TEMPORARY foo FROM (SELECT c AS c FROM t) AS temp;

-- Statement 54
WITH t(c) AS (SELECT 1) SELECT c INTO #foo FROM t;

-- Statement 55
WITH t(c) AS (SELECT 1) SELECT c INTO TEMPORARY foo FROM t;

-- Statement 56
WITH t(c) AS (SELECT 1) SELECT * INTO UNLOGGED foo FROM (SELECT c AS c FROM t) AS temp;

-- Statement 57
WITH y AS (SELECT 2 AS c) INSERT INTO #t SELECT * FROM y;

-- Statement 58
WITH y AS (SELECT 2 AS c) INSERT INTO t SELECT * FROM y;

-- Statement 59
WITH t(c) AS (SELECT 1) SELECT 1 AS c UNION (SELECT c FROM t);

-- Statement 60
SELECT 1 AS c UNION (WITH t(c) AS (SELECT 1) SELECT c FROM t);

-- Statement 61
WITH t(c) AS (SELECT 1) MERGE INTO x AS z USING (SELECT c AS c FROM t) AS y ON a = b WHEN MATCHED THEN UPDATE SET a = y.b;

-- Statement 62
MERGE INTO x AS z USING (WITH t(c) AS (SELECT 1) SELECT c FROM t) AS y ON a = b WHEN MATCHED THEN UPDATE SET a = y.b;

-- Statement 63
WITH t(n) AS (SELECT 1 AS n UNION ALL SELECT n + 1 AS n FROM t WHERE n < 4) SELECT * FROM (SELECT SUM(n) AS s4 FROM t) AS subq;

-- Statement 64
SELECT * FROM (WITH RECURSIVE t(n) AS (SELECT 1 AS n UNION ALL SELECT n + 1 AS n FROM t WHERE n < 4) SELECT SUM(n) AS s4 FROM t) AS subq;

-- Statement 65
SELECT a = 1;

-- Statement 66
SELECT 1 AS a;

-- Statement 67
MERGE INTO mytable WITH (HOLDLOCK) AS T USING mytable_merge AS S;

-- Statement 68
UPDATE STATISTICS x;

-- Statement 69
UPDATE x SET y = 1 OUTPUT x.a, x.b INTO @y FROM y;

-- Statement 70
UPDATE x SET y = 1 OUTPUT x.a, x.b FROM y;

-- Statement 71
INSERT INTO x (y) OUTPUT x.a, x.b INTO l SELECT * FROM z;

-- Statement 72
INSERT INTO x (y) OUTPUT x.a, x.b SELECT * FROM z;

-- Statement 73
DELETE x OUTPUT x.a FROM z;

-- Statement 74
SELECT * FROM t WITH (TABLOCK, INDEX(myindex));

-- Statement 75
SELECT * FROM t WITH (NOWAIT);

-- Statement 76
SELECT CASE WHEN a > 1 THEN b END;

-- Statement 77
SELECT * FROM taxi ORDER BY 1 OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY;

-- Statement 78
SELECT Employee_ID, Department_ID FROM @MyTableVar;

-- Statement 79
INSERT INTO @TestTable VALUES (1, 'Value1', 12, 20);

-- Statement 80
SELECT * FROM #foo;

-- Statement 81
SELECT * FROM ##foo;

-- Statement 82
SELECT a = 1 UNION ALL SELECT a = b;

-- Statement 83
SELECT 1 AS a UNION ALL SELECT b AS a;

-- Statement 84
SELECT x FROM @MyTableVar AS m JOIN Employee ON m.EmployeeID = Employee.EmployeeID;

-- Statement 85
SELECT DISTINCT DepartmentName, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY BaseRate) OVER (PARTITION BY DepartmentName) AS MedianCont FROM dbo.DimEmployee;

-- Statement 86
SELECT "x"."y" FROM foo;

-- Statement 87
SELECT [x].[y] FROM foo;

-- Statement 88
SELECT * FROM t ORDER BY (SELECT NULL) OFFSET 2 ROWS;

-- Statement 89
SELECT * FROM t OFFSET 2;

-- Statement 90
SELECT * FROM t ORDER BY (SELECT NULL) NULLS FIRST OFFSET 2;

-- Statement 91
SELECT * FROM t ORDER BY (SELECT NULL) OFFSET 5 ROWS FETCH FIRST 10 ROWS ONLY;

-- Statement 92
SELECT * FROM t LIMIT 10 OFFSET 5;

-- Statement 93
SELECT * FROM t LIMIT 5, 10;

-- Statement 94
SELECT * FROM t ORDER BY (SELECT NULL) NULLS FIRST LIMIT 10 OFFSET 5;

-- Statement 95
SELECT * FROM t ORDER BY (SELECT NULL) LIMIT 10 OFFSET 5;

-- Statement 96
SELECT CAST([a].[b] AS SMALLINT) FROM foo;

-- Statement 97
SELECT CAST(`a`.`b` AS SMALLINT) FROM foo;

-- Statement 98
SELECT val FROM (VALUES ((TRUE), (FALSE), (NULL))) AS t(val);

-- Statement 99
SELECT val FROM (VALUES ((1), (0), (NULL))) AS t(val);

-- Statement 100
SELECT begin;

-- Statement 101
SELECT * FROM t UNPIVOT(revenue FOR month IN (jan, feb)) AS u;

-- Statement 102
SELECT e.employee_id FROM employees AS e LEFT JOIN employee_positions AS ep;

-- Statement 103
SELECT e.employee_id FROM employees e;

-- Statement 104
SELECT (-1) * col AS col FROM t1 LEFT JOIN t2 USING (id);

-- Statement 105
SELECT (-1) * col AS col FROM t1 LEFT JOIN t2 USING(id) ORDER BY col;

-- Statement 106
SELECT t1.x + t2.y AS s FROM t1 JOIN t2 ON t1.id = t2.id;

-- Statement 107
SELECT t1.x + t2.y AS s FROM t1 JOIN t2 ON t1.id = t2.id ORDER BY s;

-- Statement 108
MERGE UNION;

-- Statement 109
MERGE JOIN;

-- Statement 110
SELECT * FROM Table1;

-- Statement 111
SELECT * FROM Table1 WHERE id = 2;

-- Statement 112
UPDATE t1 SET k = t2.k FROM t2;

-- Statement 113
SELECT * FROM Table1 OPTION HASH GROUP;

-- Statement 114
SELECT * FROM Table1 OPTION(KEEPFIXED);

-- Statement 115
SELECT * FROM Table1 OPTION(HASH GROUP HASH GROUP);

-- Statement 116
SELECT col FROM t OPTION(LABEL = 'foo');

-- Statement 117
SELECT * FROM t FOR XML {xml_option};

-- Statement 118
SELECT * FROM t FOR XML PATH, BINARY BASE64, ELEMENTS XSINIL;

-- Statement 119
SELECT * FROM t FOR JSON {json_option};

-- Statement 120
SELECT (SELECT TOP 5 a, b FROM t ORDER BY b DESC FOR JSON PATH) AS j FROM x;

-- Statement 121
SELECT j FROM (SELECT a AS j FROM t FOR JSON PATH) AS x;

-- Statement 122
SELECT * FROM t FOR JSON PATH, ROOT('Root'), INCLUDE_NULL_VALUES;

-- Statement 123
SELECT * FROM t FOR JSON AUTO;

-- Statement 124
SELECT * FROM t;

-- Statement 125
SELECT * FROM t FOR BROWSE;

-- Statement 126
SELECT TRUE, FALSE;

-- Statement 127
SELECT 1, 0;

-- Statement 128
SELECT TRUE AS a, FALSE AS b;

-- Statement 129
SELECT 1 AS a, 0 AS b;

-- Statement 130
SELECT 1 FROM a WHERE TRUE;

-- Statement 131
SELECT 1 FROM a WHERE (1 = 1);

-- Statement 132
INSERT INTO Production.UpdatedInventory SELECT ProductID, LocationID, NewQty, PreviousQty FROM (MERGE INTO Production.ProductInventory AS pi USING (SELECT ProductID, SUM(OrderQty) FROM Sales.SalesOrderDetail AS sod INNER JOIN Sales.SalesOrderHeader AS soh ON sod.SalesOrderID = soh.SalesOrderID AND soh.OrderDate BETWEEN '20030701' AND '20030731' GROUP BY ProductID) AS src(ProductID, OrderQty) ON pi.ProductID = src.ProductID WHEN MATCHED AND pi.Quantity - src.OrderQty >= 0 THEN UPDATE SET pi.Quantity = pi.Quantity - src.OrderQty WHEN MATCHED AND pi.Quantity - src.OrderQty <= 0 THEN DELETE OUTPUT $action, Inserted.ProductID, Inserted.LocationID, Inserted.Quantity AS NewQty, Deleted.Quantity AS PreviousQty) AS Changes(Action, ProductID, LocationID, NewQty, PreviousQty) WHERE Action = 'UPDATE';

-- Statement 133
INSERT INTO Production.UpdatedInventory
SELECT
  ProductID,
  LocationID,
  NewQty,
  PreviousQty
FROM (
  MERGE INTO Production.ProductInventory AS pi
  USING (
    SELECT
      ProductID,
      SUM(OrderQty)
    FROM Sales.SalesOrderDetail AS sod
    INNER JOIN Sales.SalesOrderHeader AS soh
      ON sod.SalesOrderID = soh.SalesOrderID
      AND soh.OrderDate BETWEEN '20030701' AND '20030731'
    GROUP BY
      ProductID
  ) AS src(ProductID, OrderQty)
  ON pi.ProductID = src.ProductID
  WHEN MATCHED AND pi.Quantity - src.OrderQty >= 0 THEN UPDATE SET
    pi.Quantity = pi.Quantity - src.OrderQty
  WHEN MATCHED AND pi.Quantity - src.OrderQty <= 0 THEN DELETE
  OUTPUT $action, Inserted.ProductID, Inserted.LocationID, Inserted.Quantity AS NewQty, Deleted.Quantity AS PreviousQty
) AS Changes(Action, ProductID, LocationID, NewQty, PreviousQty)
WHERE
  Action = 'UPDATE';

-- Statement 134
SELECT * INTO foo.bar.baz FROM (SELECT * FROM a.b.c) AS temp;

-- Statement 135
SELECT CAST(SUBSTRING('ABCD~1234', CHARINDEX('~', 'ABCD~1234') + 1, LEN('ABCD~1234')) AS BIGINT);

-- Statement 136
SELECT DATEFROMPARTS('2020', 10, 01);

-- Statement 137
SELECT MAKE_DATE('2020', 10, 01);

-- Statement 138
SELECT DATENAME(mm, '1970-01-01');

-- Statement 139
SELECT DATE_FORMAT(CAST('1970-01-01' AS TIMESTAMP), 'MMMM');

-- Statement 140
SELECT FORMAT(CAST('1970-01-01' AS DATETIME2), 'MMMM');

-- Statement 141
SELECT DATENAME(dw, '1970-01-01');

-- Statement 142
SELECT DATE_FORMAT(CAST('1970-01-01' AS TIMESTAMP), 'EEEE');

-- Statement 143
SELECT FORMAT(CAST('1970-01-01' AS DATETIME2), 'dddd');

-- Statement 144
SELECT DATEPART({fmt}, '2024-11-21');

-- Statement 145
SELECT DATEPART({canonical}, '2024-11-21');

-- Statement 146
SELECT DATEPART(month,'1970-01-01');

-- Statement 147
SELECT EXTRACT(month FROM '1970-01-01');

-- Statement 148
SELECT DATEPART(month, '1970-01-01');

-- Statement 149
SELECT DATEPART(YEAR, CAST('2017-01-01' AS DATE));

-- Statement 150
SELECT DATE_PART('YEAR', '2017-01-01'::DATE);

-- Statement 151
SELECT EXTRACT(YEAR FROM CAST('2017-01-01' AS DATE));

-- Statement 152
SELECT DATEPART(month, CAST('2017-03-01' AS DATE));

-- Statement 153
SELECT DATE_PART('month', '2017-03-01'::DATE);

-- Statement 154
SELECT EXTRACT(month FROM CAST('2017-03-01' AS DATE));

-- Statement 155
SELECT DATEPART(day, CAST('2017-01-02' AS DATE));

-- Statement 156
SELECT DATE_PART('day', '2017-01-02'::DATE);

-- Statement 157
SELECT EXTRACT(day FROM CAST('2017-01-02' AS DATE));

-- Statement 158
SELECT DATEPART("dd", x);

-- Statement 159
SELECT DATEPART(DAY, x);

-- Statement 160
SELECT CONVERT(VARCHAR(10), testdb.dbo.test.x, 120) y FROM testdb.dbo.test;

-- Statement 161
SELECT CAST(DATE_FORMAT(testdb.dbo.test.x, '%Y-%m-%d %T') AS CHAR(10)) AS y FROM testdb.dbo.test;

-- Statement 162
SELECT CAST(DATE_FORMAT(testdb.dbo.test.x, 'yyyy-MM-dd HH:mm:ss') AS VARCHAR(10)) AS y FROM testdb.dbo.test;

-- Statement 163
SELECT CONVERT(VARCHAR(10), testdb.dbo.test.x, 120) AS y FROM testdb.dbo.test;

-- Statement 164
SELECT CONVERT(VARCHAR(10), y.x) z FROM testdb.dbo.test y;

-- Statement 165
SELECT CAST(y.x AS CHAR(10)) AS z FROM testdb.dbo.test AS y;

-- Statement 166
SELECT CAST(y.x AS VARCHAR(10)) AS z FROM testdb.dbo.test AS y;

-- Statement 167
SELECT CONVERT(VARCHAR(10), y.x) AS z FROM testdb.dbo.test AS y;

-- Statement 168
SELECT CAST((SELECT x FROM y) AS VARCHAR) AS test;

-- Statement 169
SELECT CAST((SELECT x FROM y) AS STRING) AS test;

-- Statement 170
SELECT DATEADD(YEAR, 1, '2017/08/25');

-- Statement 171
SELECT ADD_MONTHS('2017/08/25', 12);

-- Statement 172
SELECT DATEADD(qq, 1, '2017/08/25');

-- Statement 173
SELECT ADD_MONTHS('2017/08/25', 3);

-- Statement 174
SELECT DATEADD(wk, 1, '2017/08/25');

-- Statement 175
SELECT DATE_ADD('2017/08/25', 7);

-- Statement 176
SELECT DATEADD(WEEK, 1, '2017/08/25');

-- Statement 177
SELECT DATEDIFF(HOUR, 1.5, '2021-01-01');

-- Statement 178
SELECT DATEDIFF_BIG(HOUR, 1.5, '2021-01-01');

-- Statement 179
SELECT {fnc}(quarter, 0, '2021-01-01');

-- Statement 180
SELECT {fnc}(QUARTER, CAST('1900-01-01' AS DATETIME2), CAST('2021-01-01' AS DATETIME2));

-- Statement 181
SELECT DATEDIFF(QUARTER, CAST('1900-01-01' AS TIMESTAMP), CAST('2021-01-01' AS TIMESTAMP));

-- Statement 182
SELECT DATE_DIFF('QUARTER', CAST('1900-01-01' AS TIMESTAMP), CAST('2021-01-01' AS TIMESTAMP));

-- Statement 183
SELECT {fnc}(day, 1, '2021-01-01');

-- Statement 184
SELECT {fnc}(DAY, CAST('1900-01-02' AS DATETIME2), CAST('2021-01-01' AS DATETIME2));

-- Statement 185
SELECT DATEDIFF(DAY, CAST('1900-01-02' AS TIMESTAMP), CAST('2021-01-01' AS TIMESTAMP));

-- Statement 186
SELECT DATE_DIFF('DAY', CAST('1900-01-02' AS TIMESTAMP), CAST('2021-01-01' AS TIMESTAMP));

-- Statement 187
SELECT {fnc}(year, '2020-01-01', '2021-01-01');

-- Statement 188
SELECT {fnc}(YEAR, CAST('2020-01-01' AS DATETIME2), CAST('2021-01-01' AS DATETIME2));

-- Statement 189
SELECT DATEDIFF(YEAR, CAST('2020-01-01' AS TIMESTAMP), CAST('2021-01-01' AS TIMESTAMP));

-- Statement 190
SELECT CAST(MONTHS_BETWEEN(CAST('2021-01-01' AS TIMESTAMP), CAST('2020-01-01' AS TIMESTAMP)) / 12 AS INT);

-- Statement 191
SELECT {fnc}(mm, 'start', 'end');

-- Statement 192
SELECT DATEDIFF(MONTH, CAST('start' AS TIMESTAMP), CAST('end' AS TIMESTAMP));

-- Statement 193
SELECT CAST(MONTHS_BETWEEN(CAST('end' AS TIMESTAMP), CAST('start' AS TIMESTAMP)) AS INT);

-- Statement 194
SELECT {fnc}(MONTH, CAST('start' AS DATETIME2), CAST('end' AS DATETIME2));

-- Statement 195
SELECT {fnc}(quarter, 'start', 'end');

-- Statement 196
SELECT DATEDIFF(QUARTER, CAST('start' AS TIMESTAMP), CAST('end' AS TIMESTAMP));

-- Statement 197
SELECT CAST(MONTHS_BETWEEN(CAST('end' AS TIMESTAMP), CAST('start' AS TIMESTAMP)) / 3 AS INT);

-- Statement 198
SELECT {fnc}(QUARTER, CAST('start' AS DATETIME2), CAST('end' AS DATETIME2));

-- Statement 199
SELECT {fnc}(DAY, CAST(a AS DATETIME2), CAST(b AS DATETIME2)) AS x FROM foo;

-- Statement 200
SELECT DATE_DIFF(DAY, CAST(CAST(a AS Nullable(DateTime)) AS DateTime64(6)), CAST(CAST(b AS Nullable(DateTime)) AS DateTime64(6))) AS x FROM foo;

-- Statement 201
SELECT DATEADD(DAY, {fnc}(DAY, -3, GETDATE()), '08:00:00');

-- Statement 202
SELECT DATEADD(DAY, {fnc}(DAY, CAST('1899-12-29' AS DATETIME2), CAST(GETDATE() AS DATETIME2)), '08:00:00');

-- Statement 203
SELECT x.a, x.b, t.v, t.y FROM x CROSS APPLY (SELECT v, y FROM t) t(v, y);

-- Statement 204
SELECT x.a, x.b, t.v, t.y FROM x INNER JOIN LATERAL (SELECT v, y FROM t) AS t(v, y);

-- Statement 205
SELECT x.a, x.b, t.v, t.y FROM x INNER JOIN LATERAL (SELECT v, y FROM t) AS t(v, y) ON TRUE;

-- Statement 206
SELECT x.a, x.b, t.v, t.y FROM x CROSS APPLY (SELECT v, y FROM t) AS t(v, y);

-- Statement 207
SELECT x.a, x.b, t.v, t.y FROM x OUTER APPLY (SELECT v, y FROM t) t(v, y);

-- Statement 208
SELECT x.a, x.b, t.v, t.y FROM x LEFT JOIN LATERAL (SELECT v, y FROM t) AS t(v, y);

-- Statement 209
SELECT x.a, x.b, t.v, t.y FROM x LEFT JOIN LATERAL (SELECT v, y FROM t) AS t(v, y) ON TRUE;

-- Statement 210
SELECT x.a, x.b, t.v, t.y FROM x OUTER APPLY (SELECT v, y FROM t) AS t(v, y);

-- Statement 211
SELECT x.a, x.b, t.v, t.y, s.v, s.y FROM x OUTER APPLY (SELECT v, y FROM t) t(v, y) OUTER APPLY (SELECT v, y FROM t) s(v, y) LEFT JOIN z ON z.id = s.id;

-- Statement 212
SELECT x.a, x.b, t.v, t.y, s.v, s.y FROM x LEFT JOIN LATERAL (SELECT v, y FROM t) AS t(v, y) LEFT JOIN LATERAL (SELECT v, y FROM t) AS s(v, y) LEFT JOIN z ON z.id = s.id;

-- Statement 213
SELECT x.a, x.b, t.v, t.y, s.v, s.y FROM x LEFT JOIN LATERAL (SELECT v, y FROM t) AS t(v, y) ON TRUE LEFT JOIN LATERAL (SELECT v, y FROM t) AS s(v, y) ON TRUE LEFT JOIN z ON z.id = s.id;

-- Statement 214
SELECT x.a, x.b, t.v, t.y, s.v, s.y FROM x OUTER APPLY (SELECT v, y FROM t) AS t(v, y) OUTER APPLY (SELECT v, y FROM t) AS s(v, y) LEFT JOIN z ON z.id = s.id;

-- Statement 215
SELECT t.x, y.z FROM x CROSS APPLY tvfTest(t.x) y(z);

-- Statement 216
SELECT t.x, y.z FROM x INNER JOIN LATERAL TVFTEST(t.x) AS y(z);

-- Statement 217
SELECT t.x, y.z FROM x INNER JOIN LATERAL TVFTEST(t.x) AS y(z) ON TRUE;

-- Statement 218
SELECT t.x, y.z FROM x CROSS APPLY TVFTEST(t.x) AS y(z);

-- Statement 219
SELECT t.x, y.z FROM x OUTER APPLY tvfTest(t.x)y(z);

-- Statement 220
SELECT t.x, y.z FROM x LEFT JOIN LATERAL TVFTEST(t.x) AS y(z);

-- Statement 221
SELECT t.x, y.z FROM x LEFT JOIN LATERAL TVFTEST(t.x) AS y(z) ON TRUE;

-- Statement 222
SELECT t.x, y.z FROM x OUTER APPLY TVFTEST(t.x) AS y(z);

-- Statement 223
SELECT t.x, y.z FROM x OUTER APPLY a.b.tvfTest(t.x)y(z);

-- Statement 224
SELECT t.x, y.z FROM x LEFT JOIN LATERAL a.b.tvfTest(t.x) AS y(z);

-- Statement 225
SELECT t.x, y.z FROM x LEFT JOIN LATERAL a.b.tvfTest(t.x) AS y(z) ON TRUE;

-- Statement 226
SELECT t.x, y.z FROM x OUTER APPLY a.b.tvfTest(t.x) AS y(z);

-- Statement 227
SELECT DISTINCT TOP 3 * FROM A;

-- Statement 228
SELECT DISTINCT * FROM A LIMIT 3;

-- Statement 229
SELECT TOP (3) * FROM A;

-- Statement 230
SELECT * FROM A LIMIT 3;

-- Statement 231
SELECT * INTO schema.table FROM (SELECT a AS a, id AS id FROM (SELECT a AS a, (SELECT TOP 1 id FROM tb ORDER BY t DESC) AS id FROM tbl) AS _subquery) AS temp;

-- Statement 232
SELECT TOP 10 PERCENT;

-- Statement 233
SELECT TOP 10 PERCENT WITH TIES;

-- Statement 234
SELECT FORMAT(foo, 'dddd', 'de-CH');

-- Statement 235
SELECT FORMAT(EndOfDayRate, 'N', 'en-us');

-- Statement 236
SELECT FORMAT('01-01-1991', 'd.mm.yyyy');

-- Statement 237
SELECT FORMAT(12345, '###.###.###');

-- Statement 238
SELECT FORMAT(1234567, 'f');

-- Statement 239
SELECT FORMAT(1000000.01,'###,###.###');

-- Statement 240
SELECT FORMAT_NUMBER(1000000.01, '###,###.###');

-- Statement 241
SELECT FORMAT(1000000.01, '###,###.###');

-- Statement 242
SELECT FORMAT_NUMBER(1234567, 'f');

-- Statement 243
SELECT FORMAT('01-01-1991', 'dd.mm.yyyy');

-- Statement 244
SELECT DATE_FORMAT('01-01-1991', 'dd.mm.yyyy');

-- Statement 245
SELECT FORMAT(date_col, 'dd.mm.yyyy');

-- Statement 246
SELECT DATE_FORMAT(date_col, 'dd.mm.yyyy');

-- Statement 247
SELECT FORMAT(date_col, 'm');

-- Statement 248
SELECT DATE_FORMAT(date_col, 'MMMM d');

-- Statement 249
SELECT FORMAT(date_col, 'MMMM d');

-- Statement 250
SELECT FORMAT(num_col, 'c');

-- Statement 251
SELECT FORMAT_NUMBER(num_col, 'c');

-- Statement 252
SELECT N'test';

-- Statement 253
SELECT 'test';

-- Statement 254
SELECT '''test''';

-- Statement 255
SELECT '\'test\'';

-- Statement 256
WITH t AS (SELECT 0 AS col) SELECT YEAR(col) FROM t;

-- Statement 257
SELECT * FROM [#temp_table];

-- Statement 258
SELECT * FROM [##temp_table];

-- Statement 259
SELECT * FROM @x;

-- Statement 260
SELECT @x;

-- Statement 261
SELECT ${x};

-- Statement 262
SELECT * FROM #mytemptable;

-- Statement 263
SELECT * FROM mytemptable;

-- Statement 264
SELECT * FROM ##mytemptable;

-- Statement 265
SELECT [x] FROM [a].[b] FOR SYSTEM_TIME AS OF 'foo';

-- Statement 266
SELECT [x] FROM [a].[b] FOR SYSTEM_TIME AS OF 'foo' AS alias;

-- Statement 267
SELECT [x] FROM [a].[b] FOR SYSTEM_TIME FROM c TO d;

-- Statement 268
SELECT [x] FROM [a].[b] FOR SYSTEM_TIME BETWEEN c AND d;

-- Statement 269
SELECT [x] FROM [a].[b] FOR SYSTEM_TIME CONTAINED IN (c, d);

-- Statement 270
SELECT [x] FROM [a].[b] FOR SYSTEM_TIME ALL AS alias;

-- Statement 271
SELECT x FROM a INNER HASH JOIN b ON b.id = a.id;

-- Statement 272
SELECT x FROM a INNER JOIN b ON b.id = a.id;

-- Statement 273
SELECT x FROM a INNER LOOP JOIN b ON b.id = a.id;

-- Statement 274
SELECT x FROM a INNER REMOTE JOIN b ON b.id = a.id;

-- Statement 275
SELECT x FROM a INNER MERGE JOIN b ON b.id = a.id;

-- Statement 276
SELECT x FROM a WITH (NOLOCK);

-- Statement 277
SELECT x FROM a;

-- Statement 278
SELECT x FROM start WITH (NOLOCK);

-- Statement 279
SELECT * FROM t AS start WITH (NOLOCK);

-- Statement 280
UPDATE start WITH (ROWLOCK) SET a = 1;

-- Statement 281
DELETE FROM start WITH (ROWLOCK);

-- Statement 282
SELECT * FROM OPENJSON(@json);

-- Statement 283
SELECT [key], value FROM OPENJSON(@json,'$.path.to."sub-object"');

-- Statement 284
SELECT [key], value FROM OPENJSON(@json, '$.path.to."sub-object"');

-- Statement 285
SELECT * FROM OPENJSON(@array) WITH (month VARCHAR(3), temp int, month_id tinyint '$.sql:identity()') as months;

-- Statement 286
SELECT * FROM OPENJSON(@array) WITH (month VARCHAR(3), temp INTEGER, month_id TINYINT '$.sql:identity()') AS months;

-- Statement 287
SELECT *
FROM OPENJSON ( @json )
WITH (
              Number   VARCHAR(200)   '$.Order.Number',
              Date     DATETIME       '$.Order.Date',
              Customer VARCHAR(200)   '$.AccountNumber',
              Quantity INT            '$.Item.Quantity',
              [Order]  NVARCHAR(MAX)  AS JSON
 );

-- Statement 288
WITH t AS (SELECT 1) SELECT * FROM t;

-- Statement 289
WITH t AS (SELECT 1 AS [1]) SELECT * FROM t;

-- Statement 290
WITH t AS (SELECT "c") SELECT * FROM t;

-- Statement 291
WITH t AS (SELECT [c] AS [c]) SELECT * FROM t;

-- Statement 292
SELECT * FROM (SELECT 1) AS subq;

-- Statement 293
SELECT * FROM (SELECT 1 AS [1]) AS subq;

-- Statement 294
SELECT * FROM (SELECT "c") AS subq;

-- Statement 295
SELECT * FROM (SELECT [c] AS [c]) AS subq;

-- Statement 296
WITH t1(c) AS (SELECT 1), t2 AS (SELECT CAST(c AS INTEGER) AS c FROM t1) SELECT * FROM t2;

-- Statement 297
WITH t1(c) AS (SELECT 1), t2 AS (SELECT CAST(c AS INTEGER) FROM t1) SELECT * FROM t2;

-- Statement 298
SELECT COUNT(1) FROM x;

-- Statement 299
SELECT COUNT_BIG(1) FROM x;

-- Statement 300
SELECT PARSENAME('1.2.3', {i});

-- Statement 301
SELECT SPLIT_PART('1.2.3', '.', {4 - i});

-- Statement 302
SELECT SPLIT_PART('1,2,3', ',', 1);

-- Statement 303
WITH t AS (SELECT 'a.b.c' AS value, 1 AS idx) SELECT SPLIT_PART(value, '.', idx) FROM t;

-- Statement 304
SELECT NEXT VALUE FOR db.schema.sequence_name OVER (ORDER BY foo), col;

-- Statement 305
SELECT NEXT VALUE FOR db.schema.sequence_name;

-- Statement 306
SELECT DATETRUNC(month, 'foo');

-- Statement 307
SELECT DATE_TRUNC('MONTH', CAST('foo' AS TIMESTAMP));

-- Statement 308
SELECT DATETRUNC(MONTH, CAST('foo' AS DATETIME2));

-- Statement 309
SELECT DATETRUNC(month, foo);

-- Statement 310
SELECT DATE_TRUNC('MONTH', foo);

-- Statement 311
SELECT DATETRUNC(year, CAST('foo1' AS date));

-- Statement 312
SELECT DATE_TRUNC('YEAR', CAST('foo1' AS DATE));

-- Statement 313
INSERT INTO tab(ds) VALUES ({value});

-- Statement 314
SELECT 1; SELECT 2;

-- Statement 315
SELECT @SalesAmountBefore = SUM(SalesAmount) FROM TRANSF.[Pre_Merge_Sales_Real] AS S;

