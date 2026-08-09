-- SQLGlot databricks DML statements
-- Extracted from databricks.py test fixtures
-- Total statements: 126
-- ============================================================

-- Statement 1
INSERT INTO target REPLACE USING (c1, c2) SELECT c1, c2 FROM source;

-- Statement 2
SELECT CAST('a' AS STRING COLLATE UTF8_BINARY);

-- Statement 3
SELECT COSH(1.5);

-- Statement 4
SELECT BITMAP_BIT_POSITION(10);

-- Statement 5
SELECT BITMAP_BUCKET_NUMBER(32769);

-- Statement 6
SELECT BITMAP_CONSTRUCT_AGG(value);

-- Statement 7
SELECT EXP(1);

-- Statement 8
SELECT MODE(category);

-- Statement 9
SELECT MODE(price, TRUE) AS deterministic_mode FROM products;

-- Statement 10
SELECT CAST(NULL AS VOID);

-- Statement 11
SELECT void FROM t;

-- Statement 12
SELECT * FROM stream;

-- Statement 13
SELECT * FROM STREAM t;

-- Statement 14
SELECT t.current_time FROM t;

-- Statement 15
SELECT col1 FROM t CLUSTER BY col1;

-- Statement 16
SELECT col1, col2 FROM t CLUSTER BY col1, col2;

-- Statement 17
SELECT CAST('11 23:4:0' AS INTERVAL DAY TO HOUR);

-- Statement 18
SELECT CAST('11 23:4:0' AS INTERVAL DAY TO MINUTE);

-- Statement 19
SELECT CAST('11 23:4:0' AS INTERVAL DAY TO SECOND);

-- Statement 20
SELECT CAST('23:00:00' AS INTERVAL HOUR TO MINUTE);

-- Statement 21
SELECT CAST('23:00:00' AS INTERVAL HOUR TO SECOND);

-- Statement 22
SELECT CAST('23:00:00' AS INTERVAL MINUTE TO SECOND);

-- Statement 23
INSERT INTO a REPLACE WHERE cond VALUES (1), (2);

-- Statement 24
SELECT ${x} FROM ${y} WHERE ${z} > 1;

-- Statement 25
SELECT PARSE_JSON('{}');

-- Statement 26
SELECT RANDSTR(123);

-- Statement 27
SELECT RANDSTR(123, 456);

-- Statement 28
SELECT * FROM sales UNPIVOT INCLUDE NULLS (sales FOR quarter IN (q1 AS `Jan-Mar`));

-- Statement 29
SELECT * FROM sales UNPIVOT EXCLUDE NULLS (sales FOR quarter IN (q1 AS `Jan-Mar`));

-- Statement 30
COPY INTO target FROM `s3://link` FILEFORMAT = AVRO VALIDATE = ALL FILES = ('file1', 'file2') FORMAT_OPTIONS ('opt1'='true', 'opt2'='test') COPY_OPTIONS ('mergeSchema'='true');

-- Statement 31
SELECT * FROM t1, t2;

-- Statement 32
SELECT * FROM t1 CROSS JOIN t2;

-- Statement 33
SELECT TIMESTAMP '2025-04-29 18.47.18'::DATE;

-- Statement 34
SELECT CAST(CAST('2025-04-29 18.47.18' AS DATE) AS TIMESTAMP);

-- Statement 35
SELECT DATE_FORMAT(CAST(FROM_UTC_TIMESTAMP(foo, 'America/Los_Angeles') AS TIMESTAMP), 'yyyy-MM-dd HH:mm:ss') AS foo FROM t;

-- Statement 36
SELECT DATE_FORMAT(CAST(FROM_UTC_TIMESTAMP(CAST(foo AS TIMESTAMP), 'America/Los_Angeles') AS TIMESTAMP), 'yyyy-MM-dd HH:mm:ss') AS foo FROM t;

-- Statement 37
SELECT r"\\foo.bar\";

-- Statement 38
SELECT '\\\\foo.bar\\';

-- Statement 39
SELECT SUBSTRING_INDEX(str, delim, count);

-- Statement 40
SELECT SUBSTRING_INDEX('a.b.c.d', '.', 2);

-- Statement 41
SELECT SUBSTR('Spark' FROM 5 FOR 1);

-- Statement 42
SELECT SUBSTRING('Spark', 5, 1);

-- Statement 43
SELECT SUBSTR('Spark SQL', 5);

-- Statement 44
SELECT SUBSTRING('Spark SQL', 5);

-- Statement 45
SELECT SUBSTR(ENCODE('Spark SQL', 'utf-8'), 5);

-- Statement 46
SELECT SUBSTRING(ENCODE('Spark SQL', 'utf-8'), 5);

-- Statement 47
SELECT TYPEOF(1);

-- Statement 48
SELECT toTypeName(1);

-- Statement 49
SELECT c1:item[1].price;

-- Statement 50
SELECT GET_JSON_OBJECT(c1, '$.item[1].price');

-- Statement 51
SELECT X'1A2B';

-- Statement 52
SELECT ANY(col) FROM VALUES (TRUE), (FALSE) AS tab(col);

-- Statement 53
SELECT test, LISTAGG(email, '') AS Email FROM organizations GROUP BY test;

-- Statement 54
WITH t AS (VALUES ('foo_val') AS t(foo1)) SELECT foo1 FROM t;

-- Statement 55
WITH t AS (SELECT * FROM VALUES ('foo_val') AS t(foo1)) SELECT foo1 FROM t;

-- Statement 56
SELECT ELT(2, 'foo', 'bar', 'baz') AS Result;

-- Statement 57
SELECT MAKE_INTERVAL(100, 11, 12, 13, 14, 14, 15);

-- Statement 58
SELECT name, GROUPING_ID() FROM customer GROUP BY ROLLUP (name);

-- Statement 59
SELECT CURDATE();

-- Statement 60
SELECT CURRENT_DATE;

-- Statement 61
WITH t AS (SELECT '{"x-y": "z"}' AS c) SELECT get_json_object(c, '$.x-y') FROM t;

-- Statement 62
WITH t AS (SELECT '{"x-y": "z"}' AS c) SELECT GET_JSON_OBJECT(c, '$["x-y"]') FROM t;

-- Statement 63
INSERT INTO t REPLACE WHERE a = 1 SELECT * FROM src;

-- Statement 64
INSERT INTO t REPLACE WHERE a = 2 (SELECT * FROM src);

-- Statement 65
WITH s AS (SELECT * FROM src) INSERT INTO t REPLACE WHERE a = 1 SELECT * FROM s;

-- Statement 66
WITH s AS (SELECT * FROM src) INSERT INTO t REPLACE USING (a) SELECT * FROM s;

-- Statement 67
SELECT c1:price, c1:price.foo, c1:price.bar[1];

-- Statement 68
SELECT TRY_CAST(c1:price AS ARRAY<VARIANT>);

-- Statement 69
SELECT TRY_CAST(c1:["foo bar"]["baz qux"] AS ARRAY<VARIANT>);

-- Statement 70
SELECT c1:item[1].price FROM VALUES ('{ "item": [ { "model" : "basic", "price" : 6.12 }, { "model" : "medium", "price" : 9.24 } ] }') AS T(c1);

-- Statement 71
SELECT c1:item[*].price FROM VALUES ('{ "item": [ { "model" : "basic", "price" : 6.12 }, { "model" : "medium", "price" : 9.24 } ] }') AS T(c1);

-- Statement 72
SELECT FROM_JSON(c1:item[*].price, 'ARRAY<DOUBLE>')[0] FROM VALUES ('{ "item": [ { "model" : "basic", "price" : 6.12 }, { "model" : "medium", "price" : 9.24 } ] }') AS T(c1);

-- Statement 73
SELECT INLINE(FROM_JSON(c1:item[*], 'ARRAY<STRUCT<model STRING, price DOUBLE>>')) FROM VALUES ('{ "item": [ { "model" : "basic", "price" : 6.12 }, { "model" : "medium", "price" : 9.24 } ] }') AS T(c1);

-- Statement 74
SELECT c1:['price'] FROM VALUES ('{ "price": 5 }') AS T(c1);

-- Statement 75
SELECT c1:["price"] FROM VALUES ('{ "price": 5 }') AS T(c1);

-- Statement 76
SELECT GET_JSON_OBJECT(c1, '$.price') FROM VALUES ('{ "price": 5 }') AS T(c1);

-- Statement 77
SELECT GET_JSON_OBJECT(col, path_col);

-- Statement 78
SELECT GET_JSON_OBJECT(col, CONCAT('$.', field_name));

-- Statement 79
SELECT GET_JSON_OBJECT(GET_JSON_OBJECT(col, '$[0]'), '$.a');

-- Statement 80
SELECT raw:`zip code`, raw:`fb:testid`, raw:store['bicycle'], raw:store["zip code"];

-- Statement 81
SELECT raw:["zip code"], raw:["fb:testid"], raw:store["bicycle"], raw:store["zip code"];

-- Statement 82
SELECT col:`fr'uit`;

-- Statement 83
SELECT col:["fr'uit"];

-- Statement 84
SELECT JSON_EXTRACT_PATH(col, 'fr''uit');

-- Statement 85
SELECT DATEDIFF(year, 'start', 'end');

-- Statement 86
SELECT DATEDIFF(microsecond, 'start', 'end');

-- Statement 87
SELECT CAST(EXTRACT(epoch FROM CAST('end' AS TIMESTAMP) - CAST('start' AS TIMESTAMP)) * 1000000 AS BIGINT);

-- Statement 88
SELECT DATEDIFF(millisecond, 'start', 'end');

-- Statement 89
SELECT CAST(EXTRACT(epoch FROM CAST('end' AS TIMESTAMP) - CAST('start' AS TIMESTAMP)) * 1000 AS BIGINT);

-- Statement 90
SELECT DATEDIFF(second, 'start', 'end');

-- Statement 91
SELECT CAST(EXTRACT(epoch FROM CAST('end' AS TIMESTAMP) - CAST('start' AS TIMESTAMP)) AS BIGINT);

-- Statement 92
SELECT DATEDIFF(minute, 'start', 'end');

-- Statement 93
SELECT CAST(EXTRACT(epoch FROM CAST('end' AS TIMESTAMP) - CAST('start' AS TIMESTAMP)) / 60 AS BIGINT);

-- Statement 94
SELECT DATEDIFF(hour, 'start', 'end');

-- Statement 95
SELECT CAST(EXTRACT(epoch FROM CAST('end' AS TIMESTAMP) - CAST('start' AS TIMESTAMP)) / 3600 AS BIGINT);

-- Statement 96
SELECT DATEDIFF(day, 'start', 'end');

-- Statement 97
SELECT CAST(EXTRACT(epoch FROM CAST('end' AS TIMESTAMP) - CAST('start' AS TIMESTAMP)) / 86400 AS BIGINT);

-- Statement 98
SELECT DATEDIFF(week, 'start', 'end');

-- Statement 99
SELECT CAST(EXTRACT(days FROM (CAST('end' AS TIMESTAMP) - CAST('start' AS TIMESTAMP))) / 7 AS BIGINT);

-- Statement 100
SELECT DATEDIFF(month, 'start', 'end');

-- Statement 101
SELECT CAST(EXTRACT(year FROM AGE(CAST('end' AS TIMESTAMP), CAST('start' AS TIMESTAMP))) * 12 + EXTRACT(month FROM AGE(CAST('end' AS TIMESTAMP), CAST('start' AS TIMESTAMP))) AS BIGINT);

-- Statement 102
SELECT DATEDIFF(quarter, 'start', 'end');

-- Statement 103
SELECT CAST(EXTRACT(year FROM AGE(CAST('end' AS TIMESTAMP), CAST('start' AS TIMESTAMP))) * 4 + EXTRACT(month FROM AGE(CAST('end' AS TIMESTAMP), CAST('start' AS TIMESTAMP))) / 3 AS BIGINT);

-- Statement 104
SELECT CAST(EXTRACT(year FROM AGE(CAST('end' AS TIMESTAMP), CAST('start' AS TIMESTAMP))) AS BIGINT);

-- Statement 105
SELECT DATEADD(year, 1, '2020-01-01');

-- Statement 106
SELECT DATE_ADD(YEAR, 1, '2020-01-01');

-- Statement 107
SELECT DATEDIFF('end', 'start');

-- Statement 108
SELECT DATE_ADD('2020-01-01', 1);

-- Statement 109
SELECT DATEADD(DAY, 1, CAST(CAST('2020-01-01' AS DATETIME2) AS DATE));

-- Statement 110
SELECT DATE_ADD(MONTH, 1, '2020-01-01');

-- Statement 111
SELECT DATEADD(e, 24) FROM t;

-- Statement 112
SELECT DATE_ADD(e, 24) FROM t;

-- Statement 113
WITH x (select 1) SELECT * FROM x;

-- Statement 114
WITH x AS (SELECT 1) SELECT * FROM x;

-- Statement 115
SELECT TO_CHAR(12345, '#');

-- Statement 116
SELECT '20'?::INTEGER;

-- Statement 117
SELECT TRY_CAST('20' AS INT);

-- Statement 118
SELECT OVERLAY('Spark SQL', 'ANSI ', 7, 0);

-- Statement 119
SELECT OVERLAY('Spark SQL' PLACING 'ANSI ' FROM 7 FOR 0);

-- Statement 120
SELECT OVERLAY('Spark SQL' PLACING 'CORE' FROM 7);

-- Statement 121
SELECT OVERLAY(ENCODE('Spark SQL', 'utf-8') PLACING ENCODE('_', 'utf-8') FROM 6);

-- Statement 122
SELECT IF(x > 0, 'positive', 'non-positive');

-- Statement 123
SELECT IFF(x > 0, 'positive', 'non-positive');

-- Statement 124
SELECT TRY_DIVIDE(a, b);

-- Statement 125
SELECT IFF(b <> 0, a / b, NULL);

-- Statement 126
SELECT CASE WHEN b <> 0 THEN a / b ELSE NULL END;

