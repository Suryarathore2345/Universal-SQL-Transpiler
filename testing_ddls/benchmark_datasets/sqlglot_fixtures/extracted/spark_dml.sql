-- SQLGlot spark DML statements
-- Extracted from spark.py test fixtures
-- Total statements: 274
-- ============================================================

-- Statement 1
SELECT MODE(category);

-- Statement 2
SELECT MODE(price, TRUE) AS deterministic_mode FROM products;

-- Statement 3
SELECT MODE() WITHIN GROUP (ORDER BY status) FROM orders;

-- Statement 4
INSERT OVERWRITE TABLE db1.tb1 TABLE db2.tb2;

-- Statement 5
SELECT /*+ COALESCE(3) */ * FROM x;

-- Statement 6
SELECT * FROM x;

-- Statement 7
SELECT /*+ COALESCE(3), REPARTITION(1) */ * FROM x;

-- Statement 8
SELECT /*+ BROADCAST(table) */ cola FROM table;

-- Statement 9
SELECT cola FROM table;

-- Statement 10
SELECT /*+ BROADCASTJOIN(table) */ cola FROM table;

-- Statement 11
SELECT /*+ MAPJOIN(table) */ cola FROM table;

-- Statement 12
SELECT /*+ MERGE(table) */ cola FROM table;

-- Statement 13
SELECT /*+ SHUFFLEMERGE(table) */ cola FROM table;

-- Statement 14
SELECT /*+ MERGEJOIN(table) */ cola FROM table;

-- Statement 15
SELECT /*+ SHUFFLE_HASH(table) */ cola FROM table;

-- Statement 16
SELECT /*+ SHUFFLE_REPLICATE_NL(table) */ cola FROM table;

-- Statement 17
SELECT CAST('a' AS CHAR(10) COLLATE UTF8_BINARY);

-- Statement 18
SELECT CAST('a' AS STRING COLLATE UTF8_BINARY);

-- Statement 19
SELECT CAST('a' AS VARCHAR(10) COLLATE UTF8_BINARY);

-- Statement 20
SELECT CAST('a' AS STRING COLLATE foo);

-- Statement 21
SELECT CAST('a' AS VARCHAR COLLATE foo);

-- Statement 22
SELECT APPROX_TOP_K_ACCUMULATE(col, 10);

-- Statement 23
SELECT APPROX_TOP_K_ACCUMULATE(col);

-- Statement 24
SELECT BITMAP_BIT_POSITION(10);

-- Statement 25
SELECT BITMAP_CONSTRUCT_AGG(value);

-- Statement 26
SELECT * FROM test TABLESAMPLE (50 PERCENT);

-- Statement 27
SELECT * FROM test TABLESAMPLE (5 ROWS);

-- Statement 28
SELECT * FROM test TABLESAMPLE (BUCKET 4 OUT OF 10);

-- Statement 29
SELECT CASE WHEN a = NULL THEN 1 ELSE 2 END;

-- Statement 30
SELECT * FROM t1 SEMI JOIN t2 ON t1.x = t2.x;

-- Statement 31
SELECT TRANSFORM(ARRAY(1, 2, 3), x -> x + 1);

-- Statement 32
SELECT TRANSFORM(ARRAY(1, 2, 3), (x, i) -> x + i);

-- Statement 33
SELECT * FROM t1, t2;

-- Statement 34
SELECT * FROM t1 CROSS JOIN t2;

-- Statement 35
SELECT 1 limit;

-- Statement 36
SELECT 1 AS limit;

-- Statement 37
SELECT 1 offset;

-- Statement 38
SELECT 1 AS offset;

-- Statement 39
SELECT UNIX_TIMESTAMP();

-- Statement 40
SELECT UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

-- Statement 41
SELECT CAST('2023-01-01' AS TIMESTAMP) + INTERVAL 23 HOUR + 59 MINUTE + 59 SECONDS;

-- Statement 42
SELECT CAST('2023-01-01' AS TIMESTAMP) + INTERVAL '23' HOUR + INTERVAL '59' MINUTE + INTERVAL '59' SECONDS;

-- Statement 43
SELECT CAST('2023-01-01' AS TIMESTAMP) + INTERVAL '23' HOUR + '59' MINUTE + '59' SECONDS;

-- Statement 44
SELECT INTERVAL '5' HOURS '30' MINUTES '5' SECONDS '6' MILLISECONDS '7' MICROSECONDS;

-- Statement 45
SELECT INTERVAL '5' HOURS + INTERVAL '30' MINUTES + INTERVAL '5' SECONDS + INTERVAL '6' MILLISECONDS + INTERVAL '7' MICROSECONDS;

-- Statement 46
SELECT INTERVAL 5 HOURS 30 MINUTES 5 SECONDS 6 MILLISECONDS 7 MICROSECONDS;

-- Statement 47
SELECT REGEXP_REPLACE('100-200', r'([^0-9])', '');

-- Statement 48
SELECT REGEXP_REPLACE('100-200', '([^0-9])', '');

-- Statement 49
SELECT STR_TO_MAP('a:1,b:2,c:3');

-- Statement 50
SELECT STR_TO_MAP('a:1,b:2,c:3', ',', ':');

-- Statement 51
SELECT * FROM parquet.`name.parquet`;

-- Statement 52
SELECT * FROM READ_PARQUET('name.parquet');

-- Statement 53
SELECT TO_JSON(STRUCT('blah' AS x)) AS y;

-- Statement 54
SELECT JSON_FORMAT(CAST(CAST(ROW('blah') AS ROW(x VARCHAR)) AS JSON)) AS y;

-- Statement 55
SELECT TRY_ELEMENT_AT(ARRAY(1, 2, 3), 2);

-- Statement 56
SELECT ELEMENT_AT(ARRAY[1, 2, 3], 2);

-- Statement 57
SELECT [1, 2, 3][2];

-- Statement 58
SELECT ([1, 2, 3])[2];

-- Statement 59
SELECT ELEMENT_AT(ARRAY(1, 2, 3), 1);

-- Statement 60
SELECT h.id, amount FROM hourlycostagg h LATERAL VIEW inline(h.costs) c;

-- Statement 61
SELECT h.id, amount FROM hourlycostagg AS h CROSS JOIN LATERAL (SELECT UNNEST(h.costs, max_depth => 2)) AS c;

-- Statement 62
SELECT h.id, amount FROM hourlycostagg h LATERAL VIEW inline(h.adjustments) as type, val, curr;

-- Statement 63
SELECT h.id, amount FROM hourlycostagg AS h CROSS JOIN LATERAL (SELECT UNNEST(h.adjustments, max_depth => 2)) AS _u_0(type, val, curr);

-- Statement 64
WITH hourlycostagg AS (
    SELECT
        101 AS id,
        ARRAY(
            STRUCT(10.0 AS amount, 'USD' AS currency),
            STRUCT(20.0 AS amount, 'EUR' AS currency)
        ) AS costs,
        ARRAY(
            STRUCT('tax' AS type, 0.15 AS val, 'EUR' AS currency),
            STRUCT('fee' AS type, 5.00 AS val, 'EUR' AS currency)
        ) AS adjustments,
        ARRAY(
            STRUCT(
                12.0 AS length,
                STRUCT('A' AS tag, 98.5 AS score) AS details
            ),
            STRUCT(
                23.0 AS length,
                STRUCT('B' AS tag, 99.5 AS score) AS details
            )
        ) AS info
)
SELECT
    h.id,
    amount,
    currency,
    type,
    val,
    leng
FROM hourlycostagg h
LATERAL VIEW inline(h.costs) c
LATERAL VIEW inline(h.adjustments) as type, val, curr
LATERAL VIEW inline(h.info) exploded as leng, det;

-- Statement 65
WITH hourlycostagg AS (SELECT 101 AS id, [{'amount': 10.0, 'currency': 'USD'}, {'amount': 20.0, 'currency': 'EUR'}] AS costs, [{'type': 'tax', 'val': 0.15, 'currency': 'EUR'}, {'type': 'fee', 'val': 5.00, 'currency': 'EUR'}] AS adjustments, [{'length': 12.0, 'details': {'tag': 'A', 'score': 98.5}}, {'length': 23.0, 'details': {'tag': 'B', 'score': 99.5}}] AS info) SELECT h.id, amount, currency, type, val, leng FROM hourlycostagg AS h CROSS JOIN LATERAL (SELECT UNNEST(h.costs, max_depth => 2)) AS c CROSS JOIN LATERAL (SELECT UNNEST(h.adjustments, max_depth => 2)) AS _u_1(type, val, curr) CROSS JOIN LATERAL (SELECT UNNEST(h.info, max_depth => 2)) AS exploded(leng, det);

-- Statement 66
SELECT id_column, name, age FROM test_table LATERAL VIEW INLINE(struc_column) explode_view AS name, age;

-- Statement 67
SELECT id_column, name, age FROM test_table CROSS JOIN UNNEST(struc_column) AS explode_view(name, age);

-- Statement 68
SELECT id_column, name, age FROM test_table CROSS JOIN LATERAL (SELECT UNNEST(struc_column, max_depth => 2)) AS explode_view(name, age);

-- Statement 69
SELECT ARRAY_AGG(x) FILTER (WHERE x = 5) FROM (SELECT 1 UNION ALL SELECT NULL) AS t(x);

-- Statement 70
SELECT ARRAY_AGG(x) FILTER(WHERE x = 5 AND NOT x IS NULL) FROM (SELECT 1 UNION ALL SELECT NULL) AS t(x);

-- Statement 71
SELECT COLLECT_LIST(x) FILTER(WHERE x = 5) FROM (SELECT 1 UNION ALL SELECT NULL) AS t(x);

-- Statement 72
SELECT ARRAY_AGG(1);

-- Statement 73
SELECT COLLECT_LIST(1);

-- Statement 74
SELECT ARRAY_AGG(DISTINCT STRUCT('a'));

-- Statement 75
SELECT ARRAY_AGG(DISTINCT {'col1': 'a'});

-- Statement 76
SELECT COLLECT_LIST(DISTINCT STRUCT('a' AS col1));

-- Statement 77
SELECT DATE_FORMAT(DATE '2020-01-01', 'EEEE') AS weekday;

-- Statement 78
SELECT DATE_FORMAT(CAST(CAST('2020-01-01' AS DATE) AS TIMESTAMP), '%W') AS weekday;

-- Statement 79
SELECT DATE_FORMAT(CAST('2020-01-01' AS DATE), 'EEEE') AS weekday;

-- Statement 80
SELECT TRY_ELEMENT_AT(MAP(1, 'a', 2, 'b'), 2);

-- Statement 81
SELECT MAP([1, 2], ['a', 'b'])[2];

-- Statement 82
SELECT (MAP([1, 2], ['a', 'b'])[2])[1];

-- Statement 83
SELECT SPLIT('123|789', '\\\\|');

-- Statement 84
SELECT STR_SPLIT_REGEX('123|789', '\\|');

-- Statement 85
SELECT REGEXP_SPLIT('123|789', '\\|');

-- Statement 86
WITH tbl AS (SELECT 1 AS id, 'eggy' AS name UNION ALL SELECT NULL AS id, 'jake' AS name) SELECT COUNT(DISTINCT id, name) AS cnt FROM tbl;

-- Statement 87
WITH tbl AS (SELECT 1 AS id, 'eggy' AS `name` UNION ALL SELECT NULL AS id, 'jake' AS `name`) SELECT COUNT(DISTINCT id, `name`) AS cnt FROM tbl;

-- Statement 88
WITH tbl AS (SELECT 1 AS id, 'eggy' AS name UNION ALL SELECT NULL AS id, 'jake' AS name) SELECT COUNT(DISTINCT CASE WHEN id IS NULL THEN NULL WHEN name IS NULL THEN NULL ELSE (id, name) END) AS cnt FROM tbl;

-- Statement 89
SELECT TO_UTC_TIMESTAMP('2016-08-31', 'Asia/Seoul');

-- Statement 90
SELECT DATETIME(TIMESTAMP(CAST('2016-08-31' AS DATETIME), 'Asia/Seoul'), 'UTC');

-- Statement 91
SELECT CAST('2016-08-31' AS TIMESTAMP) AT TIME ZONE 'Asia/Seoul' AT TIME ZONE 'UTC';

-- Statement 92
SELECT WITH_TIMEZONE(CAST('2016-08-31' AS TIMESTAMP), 'Asia/Seoul') AT TIME ZONE 'UTC';

-- Statement 93
SELECT CONVERT_TIMEZONE('Asia/Seoul', 'UTC', CAST('2016-08-31' AS TIMESTAMP));

-- Statement 94
SELECT TO_UTC_TIMESTAMP(CAST('2016-08-31' AS TIMESTAMP), 'Asia/Seoul');

-- Statement 95
SELECT FROM_UTC_TIMESTAMP('2016-08-31', 'Asia/Seoul');

-- Statement 96
SELECT AT_TIMEZONE(CAST('2016-08-31' AS TIMESTAMP), 'Asia/Seoul');

-- Statement 97
SELECT FROM_UTC_TIMESTAMP(CAST('2016-08-31' AS TIMESTAMP), 'Asia/Seoul');

-- Statement 98
SELECT SPLIT_TO_MAP('a:1,b:2,c:3', ',', ':');

-- Statement 99
SELECT DATEDIFF(MONTH, CAST('1996-10-30' AS TIMESTAMP), CAST('1997-02-28 10:30:00' AS TIMESTAMP));

-- Statement 100
SELECT DATEDIFF('month', CAST('1996-10-30' AS TIMESTAMPTZ), CAST('1997-02-28 10:30:00' AS TIMESTAMPTZ));

-- Statement 101
SELECT CAST(MONTHS_BETWEEN(CAST('1997-02-28 10:30:00' AS TIMESTAMP), CAST('1996-10-30' AS TIMESTAMP)) AS INT);

-- Statement 102
SELECT DATEDIFF(week, '2020-01-01', '2020-12-31');

-- Statement 103
SELECT DATE_DIFF(CAST('2020-12-31' AS DATE), CAST('2020-01-01' AS DATE), WEEK);

-- Statement 104
SELECT DATE_DIFF('WEEK', CAST('2020-01-01' AS DATE), CAST('2020-12-31' AS DATE));

-- Statement 105
SELECT CAST(DATEDIFF('2020-12-31', '2020-01-01') / 7 AS INT);

-- Statement 106
SELECT CAST(EXTRACT(days FROM (CAST(CAST('2020-12-31' AS DATE) AS TIMESTAMP) - CAST(CAST('2020-01-01' AS DATE) AS TIMESTAMP))) / 7 AS BIGINT);

-- Statement 107
SELECT DATEDIFF(WEEK, CAST('2020-01-01' AS DATE), CAST('2020-12-31' AS DATE));

-- Statement 108
SELECT DATEDIFF(WEEK, TO_DATE('2020-01-01'), TO_DATE('2020-12-31'));

-- Statement 109
SELECT MONTHS_BETWEEN('1997-02-28 10:30:00', '1996-10-30');

-- Statement 110
SELECT DATE_DIFF('MONTH', CAST('1996-10-30' AS DATE), CAST('1997-02-28 10:30:00' AS DATE)) + CASE WHEN DAY(CAST('1997-02-28 10:30:00' AS DATE)) = DAY(LAST_DAY(CAST('1997-02-28 10:30:00' AS DATE))) AND DAY(CAST('1996-10-30' AS DATE)) = DAY(LAST_DAY(CAST('1996-10-30' AS DATE))) THEN 0 ELSE (DAY(CAST('1997-02-28 10:30:00' AS DATE)) - DAY(CAST('1996-10-30' AS DATE))) / 31.0 END;

-- Statement 111
SELECT MONTHS_BETWEEN('1997-02-28 10:30:00', '1996-10-30', FALSE);

-- Statement 112
SELECT TO_TIMESTAMP('2016-12-31 00:12:00');

-- Statement 113
SELECT CAST('2016-12-31 00:12:00' AS TIMESTAMP);

-- Statement 114
SELECT TO_TIMESTAMP(x, 'zZ');

-- Statement 115
SELECT STR_TO_TIME(x, '%Z%z');

-- Statement 116
SELECT STRPTIME(x, '%Z%z');

-- Statement 117
SELECT TO_TIMESTAMP('2016-1-1', 'yyyy-M-d');

-- Statement 118
SELECT STRPTIME('2016-1-1', '%Y-%m-%d');

-- Statement 119
SELECT STR_TO_TIME('2016-1-1', '%Y-%-m-%-d');

-- Statement 120
SELECT STRPTIME('2016-1-1', '%Y-%-m-%-d');

-- Statement 121
SELECT TO_DATE(x, 'yyyy-M-d');

-- Statement 122
SELECT TO_TIMESTAMP('2016-12-31', 'yyyy-MM-dd');

-- Statement 123
SELECT STR_TO_TIME('2016-12-31', '%Y-%mstrict-%dstrict');

-- Statement 124
SELECT STRPTIME('2016-12-31', '%Y-%m-%d');

-- Statement 125
SELECT TO_TIMESTAMP('20161231', 'yyyyMMdd');

-- Statement 126
SELECT STRPTIME('20161231', '%Y%m%d');

-- Statement 127
SELECT DATE_FORMAT(x, 'yyyy-MM-dd');

-- Statement 128
SELECT TO_DATE(x, 'MM/dd/yyyy');

-- Statement 129
SELECT CAST(STR_TO_TIME(x, '%mstrict/%dstrict/%Y') AS DATE);

-- Statement 130
SELECT CAST(CAST(TRY_STRPTIME(x, '%m/%d/%Y') AS TIMESTAMP) AS DATE);

-- Statement 131
SELECT CAST(SAFE_CAST(x AS TIMESTAMP FORMAT 'MM/DD/YYYY') AS DATE);

-- Statement 132
SELECT UNIX_TIMESTAMP('2016-1-1', 'yyyy-M-d');

-- Statement 133
SELECT STR_TO_UNIX('2016-1-1', '%Y-%m-%d');

-- Statement 134
SELECT EPOCH(STRPTIME('2016-1-1', '%Y-%-m-%-d'));

-- Statement 135
SELECT UNIX_TIMESTAMP('2016-12-31', 'yyyy-MM-dd');

-- Statement 136
SELECT EPOCH(STRPTIME('2016-12-31', '%Y-%m-%d'));

-- Statement 137
SELECT TO_TIMESTAMP('2016-1-1 3:4:5', 'yyyy-M-d H:m:s');

-- Statement 138
SELECT STRPTIME('2016-1-1 3:4:5', '%Y-%m-%d %H:%M:%S');

-- Statement 139
SELECT STR_TO_TIME('2016-1-1 3:4:5', '%Y-%-m-%-d %-H:%-M:%-S');

-- Statement 140
SELECT STRPTIME('2016-1-1 3:4:5', '%Y-%-m-%-d %-H:%-M:%-S');

-- Statement 141
SELECT TO_TIMESTAMP('2016-12-31 03:04:05', 'yyyy-MM-dd HH:mm:ss');

-- Statement 142
SELECT STR_TO_TIME('2016-12-31 03:04:05', '%Y-%mstrict-%dstrict %Hstrict:%Mstrict:%Sstrict');

-- Statement 143
SELECT STRPTIME('2016-12-31 03:04:05', '%Y-%m-%d %H:%M:%S');

-- Statement 144
SELECT TO_TIMESTAMP('20161231030405', 'yyyyMMddHHmmss');

-- Statement 145
SELECT STRPTIME('20161231030405', '%Y%m%d%H%M%S');

-- Statement 146
SELECT TO_TIMESTAMP('3:4:5 PM', 'h:m:s a');

-- Statement 147
SELECT STRPTIME('3:4:5 PM', '%I:%M:%S %p');

-- Statement 148
SELECT DATE_FORMAT(x, 'yyyy-MM-dd HH:mm:ss');

-- Statement 149
SELECT RLIKE('John Doe', 'John.*');

-- Statement 150
SELECT REGEXP_CONTAINS('John Doe', 'John.*');

-- Statement 151
SELECT 'John Doe' RLIKE 'John.*';

-- Statement 152
SELECT 'John Doe' ~ 'John.*';

-- Statement 153
SELECT REGEXP_LIKE('John Doe', 'John.*');

-- Statement 154
SELECT * FROM ((VALUES 1));

-- Statement 155
SELECT * FROM (VALUES (1));

-- Statement 156
SELECT CAST(STRUCT('fooo') AS STRUCT<a: VARCHAR(2)>);

-- Statement 157
SELECT CAST(STRUCT('fooo' AS col1) AS STRUCT<a: STRING>);

-- Statement 158
SELECT CAST(123456 AS VARCHAR(3));

-- Statement 159
SELECT TRY_CAST(123456 AS TEXT);

-- Statement 160
SELECT TRY_CAST(123456 AS STRING);

-- Statement 161
SELECT CAST(123456 AS STRING);

-- Statement 162
SELECT TRY_CAST('a' AS INT);

-- Statement 163
SELECT CAST('a' AS INT);

-- Statement 164
SELECT piv.Q1 FROM (SELECT * FROM produce PIVOT(SUM(sales) FOR quarter IN ('Q1' AS `'Q1'`, 'Q2' AS `'Q2'`))) AS piv;

-- Statement 165
SELECT piv.Q1 FROM produce PIVOT(SUM(sales) FOR quarter IN ('Q1', 'Q2')) piv;

-- Statement 166
SELECT piv.Q1 FROM (SELECT * FROM (SELECT * FROM produce) PIVOT(SUM(sales) FOR quarter IN ('Q1' AS `'Q1'`, 'Q2' AS `'Q2'`))) AS piv;

-- Statement 167
SELECT piv.Q1 FROM (SELECT * FROM produce) PIVOT(SUM(sales) FOR quarter IN ('Q1', 'Q2')) piv;

-- Statement 168
SELECT * FROM produce PIVOT(SUM(produce.sales) FOR quarter IN ('Q1' AS `'Q1'`, 'Q2' AS `'Q2'`));

-- Statement 169
SELECT * FROM produce PIVOT (SUM(produce.sales) FOR produce.quarter IN ('Q1', 'Q2'));

-- Statement 170
SELECT * FROM produce AS p PIVOT(SUM(p.sales) AS sales FOR quarter IN ('Q1' AS Q1, 'Q2' AS Q1));

-- Statement 171
SELECT * FROM produce AS p PIVOT(SUM(p.sales) AS sales FOR p.quarter IN ('Q1' AS Q1, 'Q2' AS Q1));

-- Statement 172
SELECT DATEDIFF(MONTH, '2020-01-01', '2020-03-05');

-- Statement 173
SELECT CAST(MONTHS_BETWEEN('2020-03-05', '2020-01-01') AS INT);

-- Statement 174
SELECT DATE_DIFF('MONTH', CAST(CAST('2020-01-01' AS TIMESTAMP) AS DATE), CAST(CAST('2020-03-05' AS TIMESTAMP) AS DATE));

-- Statement 175
SELECT * FROM quarterly_sales PIVOT(SUM(amount) AS amount, 'dummy' AS bar FOR quarter IN ('2023_Q1'));

-- Statement 176
SELECT * FROM quarterly_sales PIVOT(SUM(amount) amount, 'dummy' bar FOR quarter IN ('2023_Q1'));

-- Statement 177
SELECT DATE_ADD(my_date_column, 1);

-- Statement 178
SELECT DATE_ADD(CAST(CAST(my_date_column AS DATETIME) AS DATE), INTERVAL 1 DAY);

-- Statement 179
SELECT fname, lname, age FROM person ORDER BY age DESC NULLS FIRST, fname ASC NULLS LAST, lname;

-- Statement 180
SELECT fname, lname, age FROM person ORDER BY age DESC NULLS FIRST, fname ASC, lname NULLS FIRST;

-- Statement 181
SELECT fname, lname, age FROM person ORDER BY age DESC, fname ASC, lname NULLS FIRST;

-- Statement 182
SELECT APPROX_COUNT_DISTINCT(a) FROM foo;

-- Statement 183
SELECT APPROX_DISTINCT(a) FROM foo;

-- Statement 184
SELECT LEFT(x, 2), RIGHT(x, 2);

-- Statement 185
SELECT SUBSTR(x, 1, 2), SUBSTR(x, LENGTH(x) - (2 - 1));

-- Statement 186
SELECT SUBSTRING(x, 1, 2), SUBSTRING(x, LENGTH(x) - (2 - 1));

-- Statement 187
SELECT SUBSTR('Spark' FROM 5 FOR 1);

-- Statement 188
SELECT SUBSTRING('Spark', 5, 1);

-- Statement 189
SELECT SUBSTR('Spark SQL', 5);

-- Statement 190
SELECT SUBSTRING('Spark SQL', 5);

-- Statement 191
SELECT SUBSTR(ENCODE('Spark SQL', 'utf-8'), 5);

-- Statement 192
SELECT SUBSTRING(ENCODE('Spark SQL', 'utf-8'), 5);

-- Statement 193
SELECT ARRAY_SORT(x);

-- Statement 194
SELECT SORT_ARRAY(x);

-- Statement 195
SELECT DATE_ADD(MONTH, 20, col);

-- Statement 196
SELECT TIMESTAMPADD(MONTH, 20, col);

-- Statement 197
SELECT DATE_ADD('MONTH', 20, col);

-- Statement 198
SELECT ANY_VALUE(col, true), FIRST(col, true), FIRST_VALUE(col, true) OVER ();

-- Statement 199
SELECT ANY_VALUE(col), ANY_VALUE(col), FIRST_VALUE(col IGNORE NULLS) OVER ();

-- Statement 200
SELECT STRUCT(1, 2);

-- Statement 201
SELECT STRUCT(1 AS col1, 2 AS col2);

-- Statement 202
SELECT CAST(ROW(1, 2) AS ROW(col1 INTEGER, col2 INTEGER));

-- Statement 203
SELECT {'col1': 1, 'col2': 2};

-- Statement 204
SELECT STRUCT(x, 1, y AS col3, STRUCT(5)) FROM t;

-- Statement 205
SELECT STRUCT(x AS x, 1 AS col2, y AS col3, STRUCT(5 AS col1) AS col4) FROM t;

-- Statement 206
SELECT {'x': x, 'col2': 1, 'col3': y, 'col4': {'col1': 5}} FROM t;

-- Statement 207
SELECT TIMESTAMPDIFF(MONTH, foo, bar);

-- Statement 208
SELECT CAST(col AS TIMESTAMP);

-- Statement 209
SELECT TRY_CAST(col AS TIMESTAMP);

-- Statement 210
SELECT TRY_CAST(col AS TIMESTAMPTZ);

-- Statement 211
SELECT * FROM {df};

-- Statement 212
SELECT * FROM {df} WHERE id > :foo;

-- Statement 213
SELECT ELT(2, 'foo', 'bar', 'baz') AS Result;

-- Statement 214
SELECT MAKE_INTERVAL(100, 11, 12, 13, 14, 14, 15);

-- Statement 215
SELECT name, GROUPING_ID() FROM customer GROUP BY ROLLUP (name);

-- Statement 216
SELECT MAKE_TIMESTAMP(2014, 12, 28, 6, 30, 45.887);

-- Statement 217
SELECT CURDATE();

-- Statement 218
SELECT CURRENT_DATE;

-- Statement 219
SELECT BIT_COUNT(0);

-- Statement 220
SELECT * FROM foo TIMESTAMP AS OF '2020-01-01 00:00:00' AS bar;

-- Statement 221
SELECT timestamp AS of FROM t;

-- Statement 222
SELECT version AS of FROM t;

-- Statement 223
WITH RECURSIVE t(n) AS (SELECT * FROM VALUES (1) AS _values) SELECT n FROM t;

-- Statement 224
SELECT named_struct('a', 1, 'b', 'x');

-- Statement 225
SELECT STRUCT(1 AS a, 'x' AS b);

-- Statement 226
SELECT a, LOGICAL_OR(b) FROM table GROUP BY a;

-- Statement 227
SELECT a, BOOL_OR(b) FROM table GROUP BY a;

-- Statement 228
SELECT TRANSFORM(x) USING 'x' AS (x INT) FROM t;

-- Statement 229
SELECT TRANSFORM(zip_code, name, age) USING 'cat' AS (a, b, c) FROM person WHERE zip_code > 94511;

-- Statement 230
SELECT TRANSFORM(zip_code, name, age) USING 'cat' AS (a STRING, b STRING, c STRING) FROM person WHERE zip_code > 94511;

-- Statement 231
SELECT TRANSFORM(name, age) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LINES TERMINATED BY '\\n' NULL DEFINED AS 'NULL' USING 'cat' AS (name_age STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY '@' LINES TERMINATED BY '\\n' NULL DEFINED AS 'NULL' FROM person;

-- Statement 232
SELECT TRANSFORM(zip_code, name, age) ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe' WITH SERDEPROPERTIES ('field.delim'='\\t') USING 'cat' AS (a STRING, b STRING, c STRING) ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe' WITH SERDEPROPERTIES ('field.delim'='\\t') FROM person WHERE zip_code > 94511;

-- Statement 233
SELECT TRANSFORM(zip_code, name, age) USING 'cat' FROM person WHERE zip_code > 94500;

-- Statement 234
INSERT OVERWRITE TABLE table WITH cte AS (SELECT cola FROM other_table) SELECT cola FROM cte;

-- Statement 235
WITH cte AS (SELECT cola FROM other_table) INSERT OVERWRITE TABLE table SELECT cola FROM cte;

-- Statement 236
SELECT EXPLODE(x) FROM tbl;

-- Statement 237
SELECT IF(pos = pos_2, col, NULL) AS col FROM tbl CROSS JOIN UNNEST(GENERATE_ARRAY(0, GREATEST(ARRAY_LENGTH(x)) - 1)) AS pos CROSS JOIN UNNEST(x) AS col WITH OFFSET AS pos_2 WHERE pos = pos_2 OR (pos > (ARRAY_LENGTH(x) - 1) AND pos_2 = (ARRAY_LENGTH(x) - 1));

-- Statement 238
SELECT IF(_u.pos = _u_2.pos_2, _u_2.col) AS col FROM tbl CROSS JOIN UNNEST(SEQUENCE(1, GREATEST(CARDINALITY(x)))) AS _u(pos) CROSS JOIN UNNEST(x) WITH ORDINALITY AS _u_2(col, pos_2) WHERE _u.pos = _u_2.pos_2 OR (_u.pos > CARDINALITY(x) AND _u_2.pos_2 = CARDINALITY(x));

-- Statement 239
SELECT EXPLODE(col) FROM _u;

-- Statement 240
SELECT IF(pos = pos_2, col_2, NULL) AS col_2 FROM _u CROSS JOIN UNNEST(GENERATE_ARRAY(0, GREATEST(ARRAY_LENGTH(col)) - 1)) AS pos CROSS JOIN UNNEST(col) AS col_2 WITH OFFSET AS pos_2 WHERE pos = pos_2 OR (pos > (ARRAY_LENGTH(col) - 1) AND pos_2 = (ARRAY_LENGTH(col) - 1));

-- Statement 241
SELECT IF(_u_2.pos = _u_3.pos_2, _u_3.col_2) AS col_2 FROM _u CROSS JOIN UNNEST(SEQUENCE(1, GREATEST(CARDINALITY(col)))) AS _u_2(pos) CROSS JOIN UNNEST(col) WITH ORDINALITY AS _u_3(col_2, pos_2) WHERE _u_2.pos = _u_3.pos_2 OR (_u_2.pos > CARDINALITY(col) AND _u_3.pos_2 = CARDINALITY(col));

-- Statement 242
SELECT EXPLODE(col) AS exploded FROM schema.tbl;

-- Statement 243
SELECT IF(_u.pos = _u_2.pos_2, _u_2.exploded) AS exploded FROM schema.tbl CROSS JOIN UNNEST(SEQUENCE(1, GREATEST(CARDINALITY(col)))) AS _u(pos) CROSS JOIN UNNEST(col) WITH ORDINALITY AS _u_2(exploded, pos_2) WHERE _u.pos = _u_2.pos_2 OR (_u.pos > CARDINALITY(col) AND _u_2.pos_2 = CARDINALITY(col));

-- Statement 244
SELECT EXPLODE(ARRAY(1, 2));

-- Statement 245
SELECT IF(pos = pos_2, col, NULL) AS col FROM UNNEST(GENERATE_ARRAY(0, GREATEST(ARRAY_LENGTH([1, 2])) - 1)) AS pos CROSS JOIN UNNEST([1, 2]) AS col WITH OFFSET AS pos_2 WHERE pos = pos_2 OR (pos > (ARRAY_LENGTH([1, 2]) - 1) AND pos_2 = (ARRAY_LENGTH([1, 2]) - 1));

-- Statement 246
SELECT IF(_u.pos = _u_2.pos_2, _u_2.col) AS col FROM UNNEST(SEQUENCE(1, GREATEST(CARDINALITY(ARRAY[1, 2])))) AS _u(pos) CROSS JOIN UNNEST(ARRAY[1, 2]) WITH ORDINALITY AS _u_2(col, pos_2) WHERE _u.pos = _u_2.pos_2 OR (_u.pos > CARDINALITY(ARRAY[1, 2]) AND _u_2.pos_2 = CARDINALITY(ARRAY[1, 2]));

-- Statement 247
SELECT POSEXPLODE(ARRAY(2, 3)) AS x;

-- Statement 248
SELECT IF(pos = pos_2, x, NULL) AS x, IF(pos = pos_2, pos_2, NULL) AS pos_2 FROM UNNEST(GENERATE_ARRAY(0, GREATEST(ARRAY_LENGTH([2, 3])) - 1)) AS pos CROSS JOIN UNNEST([2, 3]) AS x WITH OFFSET AS pos_2 WHERE pos = pos_2 OR (pos > (ARRAY_LENGTH([2, 3]) - 1) AND pos_2 = (ARRAY_LENGTH([2, 3]) - 1));

-- Statement 249
SELECT IF(_u.pos = _u_2.pos_2, _u_2.x) AS x, IF(_u.pos = _u_2.pos_2, _u_2.pos_2) AS pos_2 FROM UNNEST(SEQUENCE(1, GREATEST(CARDINALITY(ARRAY[2, 3])))) AS _u(pos) CROSS JOIN UNNEST(ARRAY[2, 3]) WITH ORDINALITY AS _u_2(x, pos_2) WHERE _u.pos = _u_2.pos_2 OR (_u.pos > CARDINALITY(ARRAY[2, 3]) AND _u_2.pos_2 = CARDINALITY(ARRAY[2, 3]));

-- Statement 250
SELECT POSEXPLODE(ARRAY('a'));

-- Statement 251
SELECT GENERATE_SUBSCRIPTS(['a'], 1) - 1 AS pos, UNNEST(['a']) AS col;

-- Statement 252
SELECT POSEXPLODE(x) AS (a, b);

-- Statement 253
SELECT IF(_u.pos = _u_2.a, _u_2.b) AS b, IF(_u.pos = _u_2.a, _u_2.a) AS a FROM UNNEST(SEQUENCE(1, GREATEST(CARDINALITY(x)))) AS _u(pos) CROSS JOIN UNNEST(x) WITH ORDINALITY AS _u_2(b, a) WHERE _u.pos = _u_2.a OR (_u.pos > CARDINALITY(x) AND _u_2.a = CARDINALITY(x));

-- Statement 254
SELECT GENERATE_SUBSCRIPTS(x, 1) - 1 AS a, UNNEST(x) AS b;

-- Statement 255
SELECT * FROM POSEXPLODE(ARRAY('a'));

-- Statement 256
SELECT * FROM (SELECT GENERATE_SUBSCRIPTS(['a'], 1) - 1 AS pos, UNNEST(['a']) AS col);

-- Statement 257
SELECT * FROM POSEXPLODE(ARRAY('a')) AS (a, b);

-- Statement 258
SELECT * FROM (SELECT GENERATE_SUBSCRIPTS(['a'], 1) - 1 AS a, UNNEST(['a']) AS b);

-- Statement 259
SELECT * FROM POSEXPLODE(ARRAY('a')) AS _t0(a, b);

-- Statement 260
SELECT POSEXPLODE(ARRAY(2, 3)), EXPLODE(ARRAY(4, 5, 6)) FROM tbl;

-- Statement 261
SELECT IF(pos = pos_2, col, NULL) AS col, IF(pos = pos_2, pos_2, NULL) AS pos_2, IF(pos = pos_3, col_2, NULL) AS col_2 FROM tbl CROSS JOIN UNNEST(GENERATE_ARRAY(0, GREATEST(ARRAY_LENGTH([2, 3]), ARRAY_LENGTH([4, 5, 6])) - 1)) AS pos CROSS JOIN UNNEST([2, 3]) AS col WITH OFFSET AS pos_2 CROSS JOIN UNNEST([4, 5, 6]) AS col_2 WITH OFFSET AS pos_3 WHERE (pos = pos_2 OR (pos > (ARRAY_LENGTH([2, 3]) - 1) AND pos_2 = (ARRAY_LENGTH([2, 3]) - 1))) AND (pos = pos_3 OR (pos > (ARRAY_LENGTH([4, 5, 6]) - 1) AND pos_3 = (ARRAY_LENGTH([4, 5, 6]) - 1)));

-- Statement 262
SELECT IF(_u.pos = _u_2.pos_2, _u_2.col) AS col, IF(_u.pos = _u_2.pos_2, _u_2.pos_2) AS pos_2, IF(_u.pos = _u_3.pos_3, _u_3.col_2) AS col_2 FROM tbl CROSS JOIN UNNEST(SEQUENCE(1, GREATEST(CARDINALITY(ARRAY[2, 3]), CARDINALITY(ARRAY[4, 5, 6])))) AS _u(pos) CROSS JOIN UNNEST(ARRAY[2, 3]) WITH ORDINALITY AS _u_2(col, pos_2) CROSS JOIN UNNEST(ARRAY[4, 5, 6]) WITH ORDINALITY AS _u_3(col_2, pos_3) WHERE (_u.pos = _u_2.pos_2 OR (_u.pos > CARDINALITY(ARRAY[2, 3]) AND _u_2.pos_2 = CARDINALITY(ARRAY[2, 3]))) AND (_u.pos = _u_3.pos_3 OR (_u.pos > CARDINALITY(ARRAY[4, 5, 6]) AND _u_3.pos_3 = CARDINALITY(ARRAY[4, 5, 6])));

-- Statement 263
SELECT col, pos, POSEXPLODE(ARRAY(2, 3)) FROM _u;

-- Statement 264
SELECT col, pos, IF(_u_2.pos_2 = _u_3.pos_3, _u_3.col_2) AS col_2, IF(_u_2.pos_2 = _u_3.pos_3, _u_3.pos_3) AS pos_3 FROM _u CROSS JOIN UNNEST(SEQUENCE(1, GREATEST(CARDINALITY(ARRAY[2, 3])))) AS _u_2(pos_2) CROSS JOIN UNNEST(ARRAY[2, 3]) WITH ORDINALITY AS _u_3(col_2, pos_3) WHERE _u_2.pos_2 = _u_3.pos_3 OR (_u_2.pos_2 > CARDINALITY(ARRAY[2, 3]) AND _u_3.pos_3 = CARDINALITY(ARRAY[2, 3]));

-- Statement 265
SELECT * FROM t;

-- Statement 266
SELECT * FROM db.table1 MINUS SELECT * FROM db.table2;

-- Statement 267
SELECT * FROM db.table1 EXCEPT SELECT * FROM db.table2;

-- Statement 268
WITH test_table AS (
  SELECT
    12345 AS id_column,
    ARRAY(
      STRUCT('John' AS name, 30 AS age),
      STRUCT('Mary' AS name, 20 AS age),
      STRUCT('Mike' AS name, 80 AS age),
      STRUCT('Dan' AS name, 50 AS age)
    ) AS struct_column
)

SELECT
    id_column,
    {db_prefix}new_column.name,
    {db_prefix}new_column.age
FROM test_table
LATERAL VIEW EXPLODE(struct_column) explode_view AS new_column;

-- Statement 269
WITH `test_table` AS (SELECT 12345 AS `id_column`, ARRAY(STRUCT('John' AS `name`, 30 AS `age`), STRUCT('Mary' AS `name`, 20 AS `age`), STRUCT('Mike' AS `name`, 80 AS `age`), STRUCT('Dan' AS `name`, 50 AS `age`)) AS `struct_column`) SELECT `test_table`.`id_column` AS `id_column`, `explode_view`.`new_column`.`name` AS `name`, `explode_view`.`new_column`.`age` AS `age` FROM `test_table` AS `test_table` LATERAL VIEW EXPLODE(`test_table`.`struct_column`) explode_view AS `new_column`;

-- Statement 270
WITH "test_table" AS (SELECT 12345 AS "id_column", ARRAY[CAST(ROW('John', 30) AS ROW("name" VARCHAR, "age" INTEGER)), CAST(ROW('Mary', 20) AS ROW("name" VARCHAR, "age" INTEGER)), CAST(ROW('Mike', 80) AS ROW("name" VARCHAR, "age" INTEGER)), CAST(ROW('Dan', 50) AS ROW("name" VARCHAR, "age" INTEGER))] AS "struct_column") SELECT "test_table"."id_column" AS "id_column", "explode_view"."name" AS "name", "explode_view"."age" AS "age" FROM "test_table" AS "test_table" CROSS JOIN UNNEST("test_table"."struct_column") AS "explode_view"("name", "age");

-- Statement 271
SELECT ARRAY_INSERT(ARRAY('a', 'b', 'c'), 1, 'z');

-- Statement 272
SELECT TRY_DIVIDE(a, b);

-- Statement 273
SELECT IFF(b <> 0, a / b, NULL);

-- Statement 274
SELECT CASE WHEN b <> 0 THEN a / b ELSE NULL END;

