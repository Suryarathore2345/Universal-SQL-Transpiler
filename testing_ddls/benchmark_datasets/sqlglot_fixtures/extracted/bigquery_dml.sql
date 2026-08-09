-- SQLGlot bigquery DML statements
-- Extracted from bigquery.py test fixtures
-- Total statements: 797
-- ============================================================

-- Statement 1
SELECT SHA512('foo');

-- Statement 2
SELECT SHA512(TO_UTF8('foo'));

-- Statement 3
SELECT 'foo' 'bar';

-- Statement 4
SELECT CONCAT('foo', 'bar');

-- Statement 5
SELECT 'foo'/* c */'bar';

-- Statement 6
SELECT CONCAT('foo' /* c */, 'bar');

-- Statement 7
SELECT * FROM `domain.com:project-id.mydataset.mytable`;

-- Statement 8
SELECT * FROM `domain.com:project-id.region-us.INFORMATION_SCHEMA`.JOBS;

-- Statement 9
SELECT * FROM `domain.com:project-id.region-us.INFORMATION_SCHEMA.JOBS` AS JOBS;

-- Statement 10
SELECT * FROM `domain.com:project-id.region-us.INFORMATION_SCHEMA.JOBS`;

-- Statement 11
SELECT * FROM `domain.com:project-id.region-us.INFORMATION_SCHEMA.JOBS` AS `domain.com:project-id.region-us.INFORMATION_SCHEMA.JOBS`;

-- Statement 12
SELECT * FROM `a.b.com:project-id.mydataset.mytable`;

-- Statement 13
SELECT * FROM `a.b.com:project-id.region-us.INFORMATION_SCHEMA.JOBS`;

-- Statement 14
SELECT * FROM `a.b.com:project-id.region-us.INFORMATION_SCHEMA.JOBS` AS `a.b.com:project-id.region-us.INFORMATION_SCHEMA.JOBS`;

-- Statement 15
SELECT * FROM x-0.y;

-- Statement 16
SELECT `db.t`.`c` FROM `db.t`;

-- Statement 17
SELECT `p.d.t`.`c`.`f` FROM `p.d.t`;

-- Statement 18
SELECT `p.d.UdF`(data) FROM `p.d.t`;

-- Statement 19
SELECT EXP(1);

-- Statement 20
SELECT ARRAY_CONCAT([1]);

-- Statement 21
SELECT * FROM READ_CSV('bla.csv');

-- Statement 22
SELECT jsondoc['some_key'];

-- Statement 23
SELECT `p.d.UdF`(data).* FROM `p.d.t`;

-- Statement 24
SELECT * FROM `my-project.my-dataset.my-table`;

-- Statement 25
SELECT x, 1 AS y GROUP BY 1 ORDER BY 1;

-- Statement 26
SELECT * FROM x.*;

-- Statement 27
SELECT * FROM x.y*;

-- Statement 28
SELECT SEARCH(data_to_search, 'search_query');

-- Statement 29
SELECT SEARCH(data_to_search, 'search_query', json_scope => 'JSON_KEYS_AND_VALUES');

-- Statement 30
SELECT SEARCH(data_to_search, 'search_query', analyzer => 'PATTERN_ANALYZER');

-- Statement 31
SELECT SEARCH(data_to_search, 'search_query', analyzer_options => 'analyzer_options_values');

-- Statement 32
SELECT SEARCH(data_to_search, 'search_query', json_scope => 'JSON_VALUES', analyzer => 'LOG_ANALYZER');

-- Statement 33
SELECT SEARCH(data_to_search, 'search_query', analyzer => 'PATTERN_ANALYZER', analyzer_options => 'options');

-- Statement 34
SELECT * FROM dataset.my_table TABLESAMPLE SYSTEM (10 PERCENT);

-- Statement 35
SELECT '\n\r\a\v\f\t';

-- Statement 36
SELECT * FROM tbl FOR SYSTEM_TIME AS OF z;

-- Statement 37
SELECT * FROM tbl FOR SYSTEM TIME AS OF z;

-- Statement 38
SELECT PARSE_TIMESTAMP('%c', 'Thu Dec 25 07:30:00 2008', 'UTC');

-- Statement 39
SELECT ANY_VALUE(fruit HAVING MAX sold) FROM fruits;

-- Statement 40
SELECT ANY_VALUE(fruit HAVING MIN sold) FROM fruits;

-- Statement 41
SELECT ANY_VALUE(fruit HAVING MAX sold) FROM Store;

-- Statement 42
SELECT ARG_MAX_NULL(fruit, sold) FROM Store;

-- Statement 43
SELECT ANY_VALUE(fruit HAVING MIN sold) FROM Store;

-- Statement 44
SELECT ARG_MIN_NULL(fruit, sold) FROM Store;

-- Statement 45
SELECT category, ANY_VALUE(product HAVING MAX price), ANY_VALUE(product HAVING MIN cost), ANY_VALUE(supplier) FROM products GROUP BY category;

-- Statement 46
SELECT category, ARG_MAX_NULL(product, price), ARG_MIN_NULL(product, cost), ANY_VALUE(supplier) FROM products GROUP BY category;

-- Statement 47
WITH data AS (SELECT "A" AS fruit, 20 AS sold UNION ALL SELECT NULL AS fruit, 25 AS sold) SELECT ANY_VALUE(fruit HAVING MAX sold) FROM data;

-- Statement 48
WITH data AS (SELECT 'A' AS fruit, 20 AS sold UNION ALL SELECT NULL AS fruit, 25 AS sold) SELECT ARG_MAX_NULL(fruit, sold) FROM data;

-- Statement 49
SELECT `project-id`.udfs.func(call.dir);

-- Statement 50
SELECT CAST(CURRENT_DATE AS STRING FORMAT 'DAY') AS current_day;

-- Statement 51
SELECT foo IN UNNEST(bar) AS bla;

-- Statement 52
SELECT * FROM x-0.a;

-- Statement 53
SELECT * FROM pivot CROSS JOIN foo;

-- Statement 54
SELECT * FROM a-b-c.mydataset.mytable;

-- Statement 55
SELECT * FROM abc-def-ghi;

-- Statement 56
SELECT * FROM a-b-c;

-- Statement 57
SELECT * FROM my-table;

-- Statement 58
SELECT * FROM my-project.mydataset.mytable;

-- Statement 59
SELECT * FROM pro-ject_id.c.d CROSS JOIN foo-bar;

-- Statement 60
SELECT * FROM foo.bar.25;

-- Statement 61
SELECT * FROM foo.bar.`25`;

-- Statement 62
SELECT * FROM foo.bar.25_;

-- Statement 63
SELECT * FROM foo.bar.`25_`;

-- Statement 64
SELECT * FROM foo.bar.25x a;

-- Statement 65
SELECT * FROM foo.bar.`25x` AS a;

-- Statement 66
SELECT * FROM foo.bar.25ab c;

-- Statement 67
SELECT * FROM foo.bar.`25ab` AS c;

-- Statement 68
SELECT DATE_TRUNC(DATE '2015-06-15', ISOYEAR);

-- Statement 69
SELECT DATE_TRUNC(CAST('2015-06-15' AS DATE), ISOYEAR);

-- Statement 70
SELECT DATE_TRUNC('ISOYEAR', CAST('2015-06-15' AS DATE));

-- Statement 71
SELECT b'abc';

-- Statement 72
SELECT AS STRUCT 1 AS a, 2 AS b;

-- Statement 73
SELECT DISTINCT AS STRUCT 1 AS a, 2 AS b;

-- Statement 74
SELECT AS VALUE STRUCT(1 AS a, 2 AS b);

-- Statement 75
SELECT * FROM q UNPIVOT(values FOR quarter IN (b, c));

-- Statement 76
SELECT MAKE_INTERVAL(100, 11, 1, 12, 30, 10);

-- Statement 77
SELECT y + 1 FROM x GROUP BY y + 1 ORDER BY 1;

-- Statement 78
SELECT TIMESTAMP_SECONDS(2) AS t;

-- Statement 79
SELECT TIMESTAMP_MILLIS(2) AS t;

-- Statement 80
UPDATE x SET y = NULL;

-- Statement 81
SELECT COUNT(x RESPECT NULLS);

-- Statement 82
SELECT LAST_VALUE(x IGNORE NULLS) OVER y AS x;

-- Statement 83
SELECT ARRAY((SELECT AS STRUCT 1 AS a, 2 AS b));

-- Statement 84
SELECT ARRAY((SELECT AS STRUCT 1 AS a, 2 AS b) LIMIT 10);

-- Statement 85
SELECT * FROM x WHERE x.y >= (SELECT MAX(a) FROM b-c) - 20;

-- Statement 86
WITH t AS (SELECT '{"x-y": "z"}' AS c) SELECT JSON_EXTRACT(c, '$.x-y') FROM t;

-- Statement 87
SELECT FORMAT_TIMESTAMP('%F %T', CURRENT_TIMESTAMP(), 'Europe/Berlin') AS ts;

-- Statement 88
SELECT cars, apples FROM some_table PIVOT(SUM(total_counts) FOR products IN ('general.cars' AS cars, 'food.apples' AS apples));

-- Statement 89
MERGE INTO dataset.NewArrivals USING (SELECT * FROM UNNEST([('microwave', 10, 'warehouse #1'), ('dryer', 30, 'warehouse #1'), ('oven', 20, 'warehouse #2')])) ON FALSE WHEN NOT MATCHED THEN INSERT ROW WHEN NOT MATCHED BY SOURCE THEN DELETE;

-- Statement 90
SELECT * FROM test QUALIFY a IS DISTINCT FROM b WINDOW c AS (PARTITION BY d);

-- Statement 91
SELECT * FROM (SELECT * FROM `t`) AS a UNPIVOT((c) FOR c_name IN (v1, v2));

-- Statement 92
SELECT ROW() OVER (y ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) FROM x WINDOW y AS (PARTITION BY CATEGORY);

-- Statement 93
SELECT item, purchases, LAST_VALUE(item) OVER (item_window ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS most_popular FROM Produce WINDOW item_window AS (ORDER BY purchases);

-- Statement 94
SELECT LAST_VALUE(a IGNORE NULLS) OVER y FROM x WINDOW y AS (PARTITION BY CATEGORY);

-- Statement 95
SELECT * FROM foo AS t0 FOR SYSTEM_TIME AS OF '2026-02-12T23:22:21.743416+00:00';

-- Statement 96
SELECT b"\\x0a$'x'00";

-- Statement 97
SELECT b'\\x0a$\\'x\\'00';

-- Statement 98
SELECT * FROM t1, t2;

-- Statement 99
SELECT * FROM t1 CROSS JOIN t2;

-- Statement 100
SELECT r"\\t";

-- Statement 101
SELECT '\\\\t';

-- Statement 102
SELECT * FROM `proj.dataset.INFORMATION_SCHEMA.SOME_VIEW`;

-- Statement 103
SELECT * FROM `proj.dataset.INFORMATION_SCHEMA.SOME_VIEW` AS `proj.dataset.INFORMATION_SCHEMA.SOME_VIEW`;

-- Statement 104
SELECT * FROM region_or_dataset.INFORMATION_SCHEMA.TABLES;

-- Statement 105
SELECT * FROM region_or_dataset.`INFORMATION_SCHEMA.TABLES` AS TABLES;

-- Statement 106
SELECT * FROM region_or_dataset.INFORMATION_SCHEMA.TABLES AS some_name;

-- Statement 107
SELECT * FROM region_or_dataset.`INFORMATION_SCHEMA.TABLES` AS some_name;

-- Statement 108
SELECT * FROM proj.region_or_dataset.INFORMATION_SCHEMA.TABLES;

-- Statement 109
SELECT * FROM proj.region_or_dataset.`INFORMATION_SCHEMA.TABLES` AS TABLES;

-- Statement 110
SELECT ARRAY(SELECT AS STRUCT 1 a, 2 b);

-- Statement 111
SELECT ARRAY(SELECT AS STRUCT 1 AS a, 2 AS b);

-- Statement 112
select array_contains([1, 2, 3], 1);

-- Statement 113
SELECT EXISTS(SELECT 1 FROM UNNEST([1, 2, 3]) AS _col WHERE _col = 1);

-- Statement 114
SELECT SPLIT(foo);

-- Statement 115
SELECT SPLIT(foo, ',');

-- Statement 116
SELECT 1 AS hash;

-- Statement 117
SELECT 1 AS `hash`;

-- Statement 118
SELECT 1 AS at;

-- Statement 119
SELECT 1 AS `at`;

-- Statement 120
SELECT """ends with \\"word\\"""";

-- Statement 121
SELECT 'ends with \"word\"';

-- Statement 122
SELECT '''ends with \\'word\\'''';

-- Statement 123
SELECT 'ends with \\'word\\'';

-- Statement 124
SELECT """a\\"b""";

-- Statement 125
SELECT 'a\"b';

-- Statement 126
SELECT r"""ends with \\"""";

-- Statement 127
SELECT 'ends with \\\\\"';

-- Statement 128
SELECT r"""a\\"b""";

-- Statement 129
SELECT 'a\\\\\"b';

-- Statement 130
SELECT a overlaps;

-- Statement 131
SELECT a AS overlaps;

-- Statement 132
SELECT y + 1 z FROM x GROUP BY y + 1 ORDER BY z;

-- Statement 133
SELECT y + 1 AS z FROM x GROUP BY z ORDER BY z;

-- Statement 134
SELECT y + 1 z FROM x GROUP BY y + 1;

-- Statement 135
SELECT y + 1 AS z FROM x GROUP BY y + 1;

-- Statement 136
SELECT JSON '"foo"' AS json_data;

-- Statement 137
SELECT PARSE_JSON('"foo"') AS json_data;

-- Statement 138
SELECT * FROM (SELECT a, b, c FROM test) PIVOT(SUM(b) d, COUNT(*) e FOR c IN ('x', 'y'));

-- Statement 139
SELECT * FROM (SELECT a, b, c FROM test) PIVOT(SUM(b) AS d, COUNT(*) AS e FOR c IN ('x', 'y'));

-- Statement 140
SELECT CAST(1 AS BYTEINT);

-- Statement 141
SELECT CAST(1 AS INT64);

-- Statement 142
SELECT TRUE IS TRUE;

-- Statement 143
SELECT TRUE;

-- Statement 144
SELECT REPEAT(' ', 2);

-- Statement 145
SELECT SPACE(2);

-- Statement 146
SELECT purchases, LAST_VALUE(item) OVER item_window AS most_popular FROM Produce WINDOW item_window AS (PARTITION BY purchases ORDER BY purchases ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING);

-- Statement 147
SELECT purchases, LAST_VALUE(item) OVER item_window AS most_popular FROM Produce WINDOW item_window AS (PARTITION BY purchases ORDER BY purchases NULLS FIRST ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING);

-- Statement 148
SELECT purchases, LAST_VALUE(item) OVER (PARTITION BY purchases ORDER BY purchases NULLS FIRST ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS most_popular FROM Produce;

-- Statement 149
SELECT DATE(2024, 1, 15);

-- Statement 150
SELECT MAKE_DATE(2024, 1, 15);

-- Statement 151
SELECT STRUCT(1, 2, 3), STRUCT(), STRUCT('abc'), STRUCT(1, t.str_col), STRUCT(1 as a, 'abc' AS b), STRUCT(str_col AS abc);

-- Statement 152
SELECT {'_0': 1, '_1': 2, '_2': 3}, {}, {'_0': 'abc'}, {'_0': 1, 'str_col': t.str_col}, {'a': 1, 'b': 'abc'}, {'abc': str_col};

-- Statement 153
SELECT STRUCT(1, 2, 3), STRUCT(), STRUCT('abc'), STRUCT(1, t.str_col), STRUCT(1, 'abc'), STRUCT(str_col);

-- Statement 154
SELECT OBJECT_CONSTRUCT('_0', 1, '_1', 2, '_2', 3), OBJECT_CONSTRUCT(), OBJECT_CONSTRUCT('_0', 'abc'), OBJECT_CONSTRUCT('_0', 1, '_1', t.str_col), OBJECT_CONSTRUCT('a', 1, 'b', 'abc'), OBJECT_CONSTRUCT('abc', str_col);

-- Statement 155
SELECT ROW(1, 2, 3), ROW(), ROW('abc'), ROW(1, t.str_col), CAST(ROW(1, 'abc') AS ROW(a INTEGER, b VARCHAR)), ROW(str_col);

-- Statement 156
SELECT DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY);

-- Statement 157
SELECT DATE_SUB(CURRENT_DATE, INTERVAL '2' DAY);

-- Statement 158
SELECT DATE_ADD(CURRENT_DATE, -2);

-- Statement 159
SELECT DATE_SUB(DATE '2008-12-25', INTERVAL 5 DAY);

-- Statement 160
SELECT DATE_SUB(CAST('2008-12-25' AS DATE), INTERVAL '5' DAY);

-- Statement 161
SELECT CAST('2008-12-25' AS DATE) - INTERVAL '5' DAY;

-- Statement 162
SELECT DATEADD(DAY, '5' * -1, CAST('2008-12-25' AS DATE));

-- Statement 163
SELECT t.c1, h.c2, s.c3 FROM t1 AS t, UNNEST(t.t2) AS h, UNNEST(h.t3) AS s;

-- Statement 164
SELECT t.c1, h.c2, s.c3 FROM t1 AS t CROSS JOIN UNNEST(t.t2) AS h CROSS JOIN UNNEST(h.t3) AS s;

-- Statement 165
SELECT t.c1, h.c2, s.c3 FROM t1 AS t CROSS JOIN UNNEST(t.t2) AS _t0(h) CROSS JOIN UNNEST(h.t3) AS _t1(s);

-- Statement 166
SELECT results FROM Coordinates, Coordinates.position AS results;

-- Statement 167
SELECT results FROM Coordinates CROSS JOIN UNNEST(Coordinates.position) AS results;

-- Statement 168
SELECT results FROM Coordinates CROSS JOIN UNNEST(Coordinates.position) AS _t0(results);

-- Statement 169
SELECT results FROM Coordinates, `Coordinates.position` AS results;

-- Statement 170
SELECT results FROM Coordinates CROSS JOIN `Coordinates.position` AS results;

-- Statement 171
SELECT results FROM Coordinates CROSS JOIN "Coordinates"."position" AS results;

-- Statement 172
SELECT results FROM Coordinates AS c, UNNEST(c.position) AS results;

-- Statement 173
SELECT results FROM Coordinates AS c, UNNEST(c.position) AS _t(results);

-- Statement 174
SELECT results FROM Coordinates AS c, c.position AS results;

-- Statement 175
SELECT results FROM Coordinates AS c CROSS JOIN UNNEST(c.position) AS results;

-- Statement 176
SELECT results FROM Coordinates AS c CROSS JOIN UNNEST(c.position) AS _t0(results);

-- Statement 177
SELECT results FROM Coordinates AS c CROSS JOIN c.position AS results;

-- Statement 178
SELECT TIMESTAMP('2008-12-25 15:30:00', 'America/Los_Angeles');

-- Statement 179
SELECT CAST('2008-12-25 15:30:00' AS TIMESTAMP) AT TIME ZONE 'America/Los_Angeles';

-- Statement 180
SELECT CONVERT_TIMEZONE('America/Los_Angeles', CAST('2008-12-25 15:30:00' AS TIMESTAMP));

-- Statement 181
SELECT SUM(x IGNORE NULLS) AS x;

-- Statement 182
SELECT SUM(x) IGNORE NULLS AS x;

-- Statement 183
SELECT SUM(x) AS x;

-- Statement 184
SELECT SUM(x RESPECT NULLS) AS x;

-- Statement 185
SELECT SUM(x) RESPECT NULLS AS x;

-- Statement 186
SELECT PERCENTILE_CONT(x, 0.5 RESPECT NULLS) OVER ();

-- Statement 187
SELECT QUANTILE_CONT(x, 0.5) OVER ();

-- Statement 188
SELECT PERCENTILE_CONT(x, 0.5) RESPECT NULLS OVER ();

-- Statement 189
SELECT ARRAY_AGG(DISTINCT x IGNORE NULLS ORDER BY x LIMIT 10) AS x;

-- Statement 190
SELECT COLLECT_LIST(DISTINCT x ORDER BY x LIMIT 10) IGNORE NULLS AS x;

-- Statement 191
SELECT ARRAY_AGG(x IGNORE NULLS) AS x;

-- Statement 192
SELECT ARRAY_AGG(x) FILTER(WHERE x IS NOT NULL) AS x;

-- Statement 193
SELECT ARRAY_AGG(DISTINCT x IGNORE NULLS ORDER BY x) AS x;

-- Statement 194
SELECT ARRAY_AGG(DISTINCT x ORDER BY x NULLS FIRST) FILTER(WHERE x IS NOT NULL) AS x;

-- Statement 195
SELECT COLLECT_LIST(DISTINCT x) IGNORE NULLS AS x;

-- Statement 196
SELECT * FROM Produce UNPIVOT((first_half_sales, second_half_sales) FOR semesters IN ((Q1, Q2) AS 'semester_1', (Q3, Q4) AS 'semester_2'));

-- Statement 197
SELECT * FROM Produce UNPIVOT((first_half_sales, second_half_sales) FOR semesters IN ((Q1, Q2) AS semester_1, (Q3, Q4) AS semester_2));

-- Statement 198
SELECT * FROM Produce UNPIVOT((first_half_sales, second_half_sales) FOR semesters IN ((Q1, Q2) AS 1, (Q3, Q4) AS 2));

-- Statement 199
SELECT * FROM Produce UNPIVOT((first_half_sales, second_half_sales) FOR semesters IN ((Q1, Q2) AS `1`, (Q3, Q4) AS `2`));

-- Statement 200
SELECT UNIX_DATE(DATE '2008-12-25');

-- Statement 201
SELECT UNIX_DATE(CAST('2008-12-25' AS DATE));

-- Statement 202
SELECT DATE_DIFF('DAY', CAST('1970-01-01' AS DATE), CAST('2008-12-25' AS DATE));

-- Statement 203
SELECT LAST_DAY(CAST('2008-11-25' AS DATE), MONTH);

-- Statement 204
SELECT LAST_DAY(CAST('2008-11-25' AS DATE), MONS);

-- Statement 205
SELECT LAST_DAY(CAST('2008-11-25' AS DATE));

-- Statement 206
SELECT LAST_DAY(CAST('2008-11-25' AS Nullable(DATE)));

-- Statement 207
SELECT CAST(DATE_TRUNC('MONTH', CAST('2008-11-25' AS DATE)) + INTERVAL '1 MONTH' - INTERVAL '1 DAY' AS DATE);

-- Statement 208
SELECT LAST_DAY_OF_MONTH(CAST('2008-11-25' AS DATE));

-- Statement 209
SELECT EOMONTH(CAST('2008-11-25' AS DATE));

-- Statement 210
SELECT LAST_DAY(CAST('2008-11-25' AS DATE), QUARTER);

-- Statement 211
SELECT TIME(15, 30, 00);

-- Statement 212
SELECT MAKE_TIME(15, 30, 00);

-- Statement 213
SELECT MAKETIME(15, 30, 00);

-- Statement 214
SELECT TIME_FROM_PARTS(15, 30, 00);

-- Statement 215
SELECT TIMEFROMPARTS(15, 30, 00, 0, 0);

-- Statement 216
SELECT TIME('2008-12-25 15:30:00');

-- Statement 217
SELECT CAST('2008-12-25 15:30:00' AS TIME);

-- Statement 218
SELECT CAST('2008-12-25 15:30:00' AS TIMESTAMP);

-- Statement 219
SELECT COUNTIF(x);

-- Statement 220
SELECT COUNT_IF(x);

-- Statement 221
SELECT TIMESTAMP_DIFF(TIMESTAMP_SECONDS(60), TIMESTAMP_SECONDS(0), minute);

-- Statement 222
SELECT TIMESTAMPDIFF(MINUTE, CAST(FROM_UNIXTIME(0) AS TIMESTAMP), CAST(FROM_UNIXTIME(60) AS TIMESTAMP));

-- Statement 223
SELECT DATE_DIFF('MINUTE', TO_TIMESTAMP(0), TO_TIMESTAMP(60));

-- Statement 224
SELECT DATE_DIFF('MINUTE', FROM_UNIXTIME(0), FROM_UNIXTIME(60));

-- Statement 225
SELECT TIMESTAMPDIFF(MINUTE, TO_TIMESTAMP(0), TO_TIMESTAMP(60));

-- Statement 226
SELECT TIMESTAMP_MICROS(x);

-- Statement 227
SELECT MAKE_TIMESTAMP(x);

-- Statement 228
SELECT TO_TIMESTAMP(x, 6);

-- Statement 229
SELECT * FROM t WHERE EXISTS(SELECT * FROM unnest(nums) AS x WHERE x > 1);

-- Statement 230
SELECT * FROM t WHERE EXISTS(SELECT * FROM UNNEST(nums) AS _t0(x) WHERE x > 1);

-- Statement 231
SELECT '\\n';

-- Statement 232
SELECT '''\n''';

-- Statement 233
SELECT '\n';

-- Statement 234
SELECT TRIM(CAST('***apple***' AS BYTES), CAST('*' AS BYTES)) AS result;

-- Statement 235
SELECT CAST(TRIM(CAST(CAST('***apple***' AS BLOB) AS TEXT), CAST(CAST('*' AS BLOB) AS TEXT)) AS BLOB) AS result;

-- Statement 236
SELECT TRIM('***apple***', '*') AS result;

-- Statement 237
SELECT DATETIME_DIFF('2023-01-01T00:00:00', '2023-01-01T05:00:00', MILLISECOND);

-- Statement 238
SELECT TIMESTAMPDIFF(MILLISECOND, '2023-01-01T05:00:00', '2023-01-01T00:00:00');

-- Statement 239
SELECT DATE_DIFF('MILLISECOND', CAST('2023-01-01T05:00:00' AS TIMESTAMP), CAST('2023-01-01T00:00:00' AS TIMESTAMP));

-- Statement 240
SELECT DATETIME_DIFF(DATETIME '2021-02-01 00:00:00', DATETIME '2021-01-31 00:00:00', MONTH);

-- Statement 241
SELECT DATETIME_DIFF(CAST('2021-02-01 00:00:00' AS DATETIME), CAST('2021-01-31 00:00:00' AS DATETIME), MONTH);

-- Statement 242
SELECT DATE_DIFF('MONTH', DATE_TRUNC('MONTH', CAST('2021-01-31 00:00:00' AS TIMESTAMP)), DATE_TRUNC('MONTH', CAST('2021-02-01 00:00:00' AS TIMESTAMP)));

-- Statement 243
SELECT DATETIME_DIFF(DATETIME '2017-10-15 00:00:00', DATETIME '2017-10-14 00:00:00', WEEK);

-- Statement 244
SELECT DATETIME_DIFF(CAST('2017-10-15 00:00:00' AS DATETIME), CAST('2017-10-14 00:00:00' AS DATETIME), WEEK);

-- Statement 245
SELECT DATE_DIFF('WEEK', DATE_TRUNC('WEEK', CAST('2017-10-14 00:00:00' AS TIMESTAMP) + INTERVAL '1' DAY), DATE_TRUNC('WEEK', CAST('2017-10-15 00:00:00' AS TIMESTAMP) + INTERVAL '1' DAY));

-- Statement 246
SELECT DATETIME_ADD('2023-01-01T00:00:00', INTERVAL 1 MILLISECOND);

-- Statement 247
SELECT DATETIME_ADD('2023-01-01T00:00:00', INTERVAL '1' MILLISECOND);

-- Statement 248
SELECT TIMESTAMPADD(MILLISECOND, '1', '2023-01-01T00:00:00');

-- Statement 249
SELECT CAST('2023-01-01T00:00:00' AS TIMESTAMP) + INTERVAL '1' MILLISECOND;

-- Statement 250
SELECT '2023-01-01T00:00:00' + INTERVAL '1' MILLISECOND;

-- Statement 251
SELECT DATETIME_SUB('2023-01-01T00:00:00', INTERVAL 1 MILLISECOND);

-- Statement 252
SELECT DATETIME_SUB('2023-01-01T00:00:00', INTERVAL '1' MILLISECOND);

-- Statement 253
SELECT TIMESTAMPADD(MILLISECOND, '1' * -1, '2023-01-01T00:00:00');

-- Statement 254
SELECT CAST('2023-01-01T00:00:00' AS TIMESTAMP) - INTERVAL '1' MILLISECOND;

-- Statement 255
SELECT '2023-01-01T00:00:00' - INTERVAL '1' MILLISECOND;

-- Statement 256
SELECT DATETIME_TRUNC('2023-01-01T01:01:01', HOUR);

-- Statement 257
SELECT DATE_TRUNC('HOUR', '2023-01-01T01:01:01');

-- Statement 258
SELECT DATE_TRUNC('HOUR', CAST('2023-01-01T01:01:01' AS TIMESTAMP));

-- Statement 259
SELECT TIMESTAMP_ADD(TIMESTAMP "2008-12-25 15:30:00+00", INTERVAL 10 MINUTE);

-- Statement 260
SELECT TIMESTAMP_ADD(CAST('2008-12-25 15:30:00+00' AS TIMESTAMP), INTERVAL '10' MINUTE);

-- Statement 261
SELECT DATE_ADD(MINUTE, '10', CAST('2008-12-25 15:30:00+00' AS TIMESTAMP));

-- Statement 262
SELECT CAST('2008-12-25 15:30:00+00' AS TIMESTAMPTZ) + INTERVAL '10' MINUTE;

-- Statement 263
SELECT DATE_ADD(TIMESTAMP('2008-12-25 15:30:00+00'), INTERVAL '10' MINUTE);

-- Statement 264
SELECT TIMESTAMPADD(MINUTE, '10', CAST('2008-12-25 15:30:00+00' AS TIMESTAMPTZ));

-- Statement 265
SELECT TIMESTAMP_SUB(TIMESTAMP "2008-12-25 15:30:00+00", INTERVAL 10 MINUTE);

-- Statement 266
SELECT TIMESTAMP_SUB(CAST('2008-12-25 15:30:00+00' AS TIMESTAMP), INTERVAL '10' MINUTE);

-- Statement 267
SELECT CAST('2008-12-25 15:30:00+00' AS TIMESTAMPTZ) - INTERVAL '10' MINUTE;

-- Statement 268
SELECT DATE_SUB(TIMESTAMP('2008-12-25 15:30:00+00'), INTERVAL '10' MINUTE);

-- Statement 269
SELECT TIMESTAMPADD(MINUTE, '10' * -1, CAST('2008-12-25 15:30:00+00' AS TIMESTAMPTZ));

-- Statement 270
SELECT CAST('2008-12-25 15:30:00+00' AS TIMESTAMP) - INTERVAL '10' MINUTE;

-- Statement 271
SELECT TIMESTAMP_SUB(TIMESTAMP "2008-12-25 15:30:00+00", INTERVAL col MINUTE);

-- Statement 272
SELECT TIMESTAMP_SUB(CAST('2008-12-25 15:30:00+00' AS TIMESTAMP), INTERVAL col MINUTE);

-- Statement 273
SELECT TIMESTAMPADD(MINUTE, col * -1, CAST('2008-12-25 15:30:00+00' AS TIMESTAMPTZ));

-- Statement 274
SELECT TIME_ADD(CAST('09:05:03' AS TIME), INTERVAL 2 HOUR);

-- Statement 275
SELECT TIME_ADD(CAST('09:05:03' AS TIME), INTERVAL '2' HOUR);

-- Statement 276
SELECT CAST('09:05:03' AS TIME) + INTERVAL '2' HOUR;

-- Statement 277
SELECT TIME_SUB(CAST('09:05:03' AS TIME), INTERVAL 2 HOUR);

-- Statement 278
SELECT TIME_SUB(CAST('09:05:03' AS TIME), INTERVAL '2' HOUR);

-- Statement 279
SELECT CAST('09:05:03' AS TIME) - INTERVAL '2' HOUR;

-- Statement 280
SELECT TO_HEX(MD5(some_string));

-- Statement 281
SELECT MD5(some_string);

-- Statement 282
SELECT LOWER(HEX(MD5(some_string)));

-- Statement 283
SELECT LOWER(TO_HEX(MD5(some_string)));

-- Statement 284
SELECT CAST('20201225' AS TIMESTAMP FORMAT 'YYYYMMDD' AT TIME ZONE 'America/New_York');

-- Statement 285
SELECT PARSE_TIMESTAMP('%Y%m%d', '20201225', 'America/New_York');

-- Statement 286
SELECT CAST('20201225' AS TIMESTAMP FORMAT 'YYYYMMDD');

-- Statement 287
SELECT PARSE_TIMESTAMP('%Y%m%d', '20201225');

-- Statement 288
SELECT CAST(TIMESTAMP '2008-12-25 00:00:00+00:00' AS STRING FORMAT 'YYYY-MM-DD HH24:MI:SS TZH:TZM') AS date_time_to_string;

-- Statement 289
SELECT CAST(CAST('2008-12-25 00:00:00+00:00' AS TIMESTAMP) AS STRING FORMAT 'YYYY-MM-DD HH24:MI:SS TZH:TZM') AS date_time_to_string;

-- Statement 290
SELECT CAST(TIMESTAMP '2008-12-25 00:00:00+00:00' AS STRING FORMAT 'YYYY-MM-DD HH24:MI:SS TZH:TZM' AT TIME ZONE 'Asia/Kolkata') AS date_time_to_string;

-- Statement 291
SELECT CAST(CAST('2008-12-25 00:00:00+00:00' AS TIMESTAMP) AS STRING FORMAT 'YYYY-MM-DD HH24:MI:SS TZH:TZM' AT TIME ZONE 'Asia/Kolkata') AS date_time_to_string;

-- Statement 292
WITH cte AS (SELECT [1, 2, 3] AS arr) SELECT IF(pos = pos_2, col, NULL) AS col FROM cte CROSS JOIN UNNEST(GENERATE_ARRAY(0, GREATEST(ARRAY_LENGTH(arr)) - 1)) AS pos CROSS JOIN UNNEST(arr) AS col WITH OFFSET AS pos_2 WHERE pos = pos_2 OR (pos > (ARRAY_LENGTH(arr) - 1) AND pos_2 = (ARRAY_LENGTH(arr) - 1));

-- Statement 293
WITH cte AS (SELECT ARRAY(1, 2, 3) AS arr) SELECT EXPLODE(arr) FROM cte;

-- Statement 294
SELECT IF(pos = pos_2, col, NULL) AS col FROM UNNEST(GENERATE_ARRAY(0, GREATEST(ARRAY_LENGTH(IF(ARRAY_LENGTH(COALESCE([], [])) = 0, [[][SAFE_ORDINAL(0)]], []))) - 1)) AS pos CROSS JOIN UNNEST(IF(ARRAY_LENGTH(COALESCE([], [])) = 0, [[][SAFE_ORDINAL(0)]], [])) AS col WITH OFFSET AS pos_2 WHERE pos = pos_2 OR (pos > (ARRAY_LENGTH(IF(ARRAY_LENGTH(COALESCE([], [])) = 0, [[][SAFE_ORDINAL(0)]], [])) - 1) AND pos_2 = (ARRAY_LENGTH(IF(ARRAY_LENGTH(COALESCE([], [])) = 0, [[][SAFE_ORDINAL(0)]], [])) - 1));

-- Statement 295
select explode_outer([]);

-- Statement 296
SELECT IF(pos = pos_2, col, NULL) AS col, IF(pos = pos_2, pos_2, NULL) AS pos_2 FROM UNNEST(GENERATE_ARRAY(0, GREATEST(ARRAY_LENGTH(IF(ARRAY_LENGTH(COALESCE([], [])) = 0, [[][SAFE_ORDINAL(0)]], []))) - 1)) AS pos CROSS JOIN UNNEST(IF(ARRAY_LENGTH(COALESCE([], [])) = 0, [[][SAFE_ORDINAL(0)]], [])) AS col WITH OFFSET AS pos_2 WHERE pos = pos_2 OR (pos > (ARRAY_LENGTH(IF(ARRAY_LENGTH(COALESCE([], [])) = 0, [[][SAFE_ORDINAL(0)]], [])) - 1) AND pos_2 = (ARRAY_LENGTH(IF(ARRAY_LENGTH(COALESCE([], [])) = 0, [[][SAFE_ORDINAL(0)]], [])) - 1));

-- Statement 297
select posexplode_outer([]);

-- Statement 298
SELECT AS STRUCT ARRAY(SELECT AS STRUCT 1 AS b FROM x) AS y FROM z;

-- Statement 299
SELECT {'y': ARRAY(SELECT {'b': 1} FROM x)} FROM z;

-- Statement 300
SELECT CAST(STRUCT(1) AS STRUCT<INT64>);

-- Statement 301
SELECT CAST(OBJECT_CONSTRUCT('_0', 1) AS OBJECT);

-- Statement 302
SELECT * FROM UNNEST(['7', '14']) AS x;

-- Statement 303
SELECT * FROM UNNEST(ARRAY('7', '14')) AS (x);

-- Statement 304
SELECT * FROM UNNEST(ARRAY['7', '14']) AS _t0(x);

-- Statement 305
SELECT * FROM EXPLODE(ARRAY('7', '14')) AS _t0(x);

-- Statement 306
SELECT ARRAY(SELECT x FROM UNNEST([0, 1]) AS x);

-- Statement 307
SELECT ARRAY(SELECT DISTINCT x FROM UNNEST(some_numbers) AS x) AS unique_numbers;

-- Statement 308
SELECT ARRAY(SELECT * FROM foo JOIN bla ON x = y);

-- Statement 309
DELETE db.example_table WHERE x = 1;

-- Statement 310
DELETE FROM db.example_table WHERE x = 1;

-- Statement 311
DELETE db.example_table tb WHERE tb.x = 1;

-- Statement 312
DELETE db.example_table AS tb WHERE tb.x = 1;

-- Statement 313
DELETE FROM db.example_table tb WHERE tb.x = 1;

-- Statement 314
DELETE FROM db.example_table AS tb WHERE tb.x = 1;

-- Statement 315
DELETE FROM db.example_table AS tb WHERE example_table.x = 1;

-- Statement 316
DELETE FROM db.example_table WHERE example_table.x = 1;

-- Statement 317
DELETE FROM db.t1 AS t1 WHERE NOT t1.c IN (SELECT db.t2.c FROM db.t2);

-- Statement 318
DELETE FROM db.t1 WHERE NOT c IN (SELECT c FROM db.t2);

-- Statement 319
SELECT * FROM a WHERE b IN UNNEST([1, 2, 3]);

-- Statement 320
SELECT * FROM a WHERE CASE WHEN [1, 2, 3] IS NULL OR ARRAY_LENGTH([1, 2, 3]) = 0 THEN FALSE WHEN ARRAY_CONTAINS([1, 2, 3], b) THEN TRUE WHEN b IS NULL OR ARRAY_LENGTH([1, 2, 3]) <> LIST_COUNT([1, 2, 3]) THEN NULL ELSE FALSE END;

-- Statement 321
SELECT * FROM a WHERE b IN (SELECT UNNEST(ARRAY[1, 2, 3]));

-- Statement 322
SELECT * FROM a WHERE b IN (SELECT EXPLODE(ARRAY(1, 2, 3)));

-- Statement 323
SELECT * FROM a WHERE b NOT IN UNNEST([1, 2, 3]);

-- Statement 324
SELECT * FROM a WHERE NOT b IN UNNEST([1, 2, 3]);

-- Statement 325
SELECT * FROM a WHERE NOT CASE WHEN [1, 2, 3] IS NULL OR ARRAY_LENGTH([1, 2, 3]) = 0 THEN FALSE WHEN ARRAY_CONTAINS([1, 2, 3], b) THEN TRUE WHEN b IS NULL OR ARRAY_LENGTH([1, 2, 3]) <> LIST_COUNT([1, 2, 3]) THEN NULL ELSE FALSE END;

-- Statement 326
SELECT a FROM test WHERE a = 1 GROUP BY a HAVING a = 2 QUALIFY z ORDER BY a LIMIT 10;

-- Statement 327
SELECT a FROM test WHERE a = 1 GROUP BY a HAVING a = 2 QUALIFY z ORDER BY a NULLS FIRST LIMIT 10;

-- Statement 328
SELECT cola, colb FROM UNNEST([STRUCT(1 AS cola, 'test' AS colb)]) AS tab;

-- Statement 329
SELECT cola, colb FROM (VALUES (1, 'test')) AS tab(cola, colb);

-- Statement 330
SELECT cola, colb FROM VALUES (1, 'test') AS tab(cola, colb);

-- Statement 331
SELECT * FROM UNNEST([STRUCT(1 AS _c0)]) AS t1;

-- Statement 332
SELECT * FROM (VALUES (1)) AS t1;

-- Statement 333
SELECT * FROM UNNEST([STRUCT(1 AS id)]) AS t1 CROSS JOIN UNNEST([STRUCT(1 AS id)]) AS t2;

-- Statement 334
SELECT * FROM (VALUES (1)) AS t1(id) CROSS JOIN (VALUES (1)) AS t2(id);

-- Statement 335
SELECT * FROM UNNEST([1]) WITH OFFSET;

-- Statement 336
SELECT * FROM UNNEST([1]) WITH OFFSET AS offset;

-- Statement 337
SELECT * FROM UNNEST([1]) WITH OFFSET y;

-- Statement 338
SELECT * FROM UNNEST([1]) WITH OFFSET AS y;

-- Statement 339
SELECT MOD(x, 10);

-- Statement 340
SELECT x % 10;

-- Statement 341
SELECT CAST(x AS DATETIME);

-- Statement 342
SELECT CAST(x AS TIMESTAMP);

-- Statement 343
SELECT TIME(foo, 'America/Los_Angeles');

-- Statement 344
SELECT CAST(CAST(foo AS TIMESTAMPTZ) AT TIME ZONE 'America/Los_Angeles' AS TIME);

-- Statement 345
SELECT DATETIME('2020-01-01');

-- Statement 346
SELECT CAST('2020-01-01' AS TIMESTAMP);

-- Statement 347
SELECT DATETIME('2020-01-01', TIME '23:59:59');

-- Statement 348
SELECT CAST(CAST('2020-01-01' AS DATE) + CAST('23:59:59' AS TIME) AS TIMESTAMP);

-- Statement 349
SELECT DATETIME('2020-01-01', CAST('23:59:59' AS TIME));

-- Statement 350
SELECT DATETIME('2020-01-01', 'America/Los_Angeles');

-- Statement 351
SELECT CAST(CAST('2020-01-01' AS TIMESTAMPTZ) AT TIME ZONE 'America/Los_Angeles' AS TIMESTAMP);

-- Statement 352
SELECT LENGTH(foo);

-- Statement 353
SELECT CASE TYPEOF(foo) WHEN 'BLOB' THEN OCTET_LENGTH(CAST(foo AS BLOB)) ELSE LENGTH(CAST(foo AS TEXT)) END;

-- Statement 354
SELECT TIME_DIFF('12:00:00', '12:30:00', MINUTE);

-- Statement 355
SELECT DATE_DIFF('MINUTE', CAST('12:30:00' AS TIME), CAST('12:00:00' AS TIME));

-- Statement 356
SELECT GENERATE_TIMESTAMP_ARRAY('2016-10-05 00:00:00', '2016-10-07 00:00:00', INTERVAL '1' DAY);

-- Statement 357
SELECT GENERATE_SERIES(CAST('2016-10-05 00:00:00' AS TIMESTAMP), CAST('2016-10-07 00:00:00' AS TIMESTAMP), INTERVAL '1' DAY);

-- Statement 358
SELECT PARSE_DATE('%A %b %e %Y', 'Thursday Dec 25 2008');

-- Statement 359
SELECT CAST(STRPTIME('1970 ' || 'Thursday Dec 25 2008', '%Y ' || '%A %b %-d %Y') AS DATE);

-- Statement 360
SELECT PARSE_DATE('%Y%m%d', '20081225');

-- Statement 361
SELECT CAST(STRPTIME('1970 ' || '20081225', '%Y ' || '%Y%m%d') AS DATE);

-- Statement 362
SELECT DATE('20081225', 'yyyymmDD');

-- Statement 363
SELECT PARSE_DATE('%m-%d', '12-25');

-- Statement 364
SELECT CAST(STRPTIME('1970 ' || '12-25', '%Y ' || '%m-%d') AS DATE);

-- Statement 365
SELECT PARSE_TIMESTAMP('%m-%d %H:%M:%S', '12-25 07:30:00');

-- Statement 366
SELECT PARSE_TIMESTAMP('%m-%d %T', '12-25 07:30:00');

-- Statement 367
SELECT STRPTIME('1970 ' || '12-25 07:30:00', '%Y ' || '%m-%d %H:%M:%S');

-- Statement 368
SELECT ARRAY_TO_STRING(['cake', 'pie', NULL], '--') AS text;

-- Statement 369
SELECT ARRAY_TO_STRING(['cake', 'pie', NULL], '--', 'MISSING') AS text;

-- Statement 370
SELECT ARRAY_TO_STRING(LIST_TRANSFORM(['cake', 'pie', NULL], x -> COALESCE(x, 'MISSING')), '--') AS text;

-- Statement 371
SELECT * FROM a-b c;

-- Statement 372
SELECT * FROM a-b AS c;

-- Statement 373
SELECT JSON_VALUE_ARRAY('{"arr": [1, "a"]}', '$.arr');

-- Statement 374
SELECT CAST('{"arr": [1, "a"]}' -> '$.arr' AS TEXT[]);

-- Statement 375
SELECT TRANSFORM(GET_PATH(PARSE_JSON('{"arr": [1, "a"]}'), 'arr'), x -> CAST(x AS VARCHAR));

-- Statement 376
SELECT INSTR('foo@example.com', '@');

-- Statement 377
SELECT STRPOS('foo@example.com', '@');

-- Statement 378
SELECT CHARINDEX('@', 'foo@example.com');

-- Statement 379
SELECT ts + MAKE_INTERVAL(1, 2, minute => 5, day => 3);

-- Statement 380
SELECT ts + MAKE_INTERVAL(1, 2, day => 3, minute => 5);

-- Statement 381
SELECT ts + INTERVAL '1 year 2 month 5 minute 3 day';

-- Statement 382
SELECT ts + INTERVAL '1 year, 2 month, 5 minute, 3 day';

-- Statement 383
SELECT INT64(JSON_QUERY(JSON '{"key": 2000}', '$.key'));

-- Statement 384
SELECT INT64(JSON_QUERY(PARSE_JSON('{"key": 2000}'), '$.key'));

-- Statement 385
SELECT CAST(JSON('{"key": 2000}') -> '$.key' AS BIGINT);

-- Statement 386
SELECT CAST(GET_PATH(PARSE_JSON('{"key": 2000}'), 'key') AS BIGINT);

-- Statement 387
SELECT * FROM t1, UNNEST(`t1`) AS `col`;

-- Statement 388
SELECT * FROM t1, UNNEST("t1") "t1" ("col");

-- Statement 389
SELECT * FROM t1 CROSS JOIN UNNEST(`t1`) AS `col`;

-- Statement 390
SELECT * FROM t1 CROSS JOIN "t1" AS "col";

-- Statement 391
SELECT * FROM t, UNNEST(`t2`.`t3`) AS `col`;

-- Statement 392
SELECT * FROM t, UNNEST("t1"."t2"."t3") "t1" ("col");

-- Statement 393
SELECT * FROM t CROSS JOIN UNNEST(`t2`.`t3`) AS `col`;

-- Statement 394
SELECT * FROM t CROSS JOIN "t2"."t3" AS "col";

-- Statement 395
SELECT * FROM t1, UNNEST(`t1`.`t2`.`t3`.`t4`) AS `col`;

-- Statement 396
SELECT * FROM t1, UNNEST("t1"."t2"."t3"."t4") "t3" ("col");

-- Statement 397
SELECT * FROM t1 CROSS JOIN UNNEST(`t1`.`t2`.`t3`.`t4`) AS `col`;

-- Statement 398
SELECT * FROM t1 CROSS JOIN "t1"."t2"."t3"."t4" AS "col";

-- Statement 399
SELECT CAST(col AS STRUCT<fld1 STRUCT<fld2 INT>>).fld1.fld2;

-- Statement 400
SELECT CAST(col AS STRUCT<fld1 STRUCT<fld2 INT64>>).fld1.fld2;

-- Statement 401
SELECT CAST(col AS OBJECT(fld1 OBJECT(fld2 INT))):fld1.fld2;

-- Statement 402
SELECT PARSE_DATETIME('%a %b %e %I:%M:%S %Y', 'Thu Dec 25 07:30:00 2008');

-- Statement 403
SELECT PARSE_DATETIME('%F %T', '2023-01-15 14:30:00');

-- Statement 404
SELECT PARSE_DATETIME('2023-01-15 14:30:00', '%Y-%m-%d %H:%M:%S');

-- Statement 405
SELECT STRPTIME('1970 ' || '2023-01-15 14:30:00', '%Y ' || '%Y-%m-%d %H:%M:%S');

-- Statement 406
SELECT TRANSLATE(MODEL, 'in', 't') FROM (SELECT 'input' AS MODEL);

-- Statement 407
SELECT GRANT FROM (SELECT 'input' AS GRANT);

-- Statement 408
SELECT 0xA;

-- Statement 409
SELECT 10;

-- Statement 410
SELECT ARRAY_CONCAT_AGG(arr) FROM (SELECT [1, 2] AS arr) AS t;

-- Statement 411
SELECT ARRAY_FLATTEN(ARRAY_AGG(arr)) FROM (SELECT [1, 2] AS arr) AS t;

-- Statement 412
SELECT FLATTEN(ARRAY_AGG(arr) FILTER(WHERE NOT arr IS NULL)) FROM (SELECT [1, 2] AS arr) AS t;

-- Statement 413
SELECT ARRAY_CONCAT_AGG(arr ORDER BY y) FROM (SELECT [1, 2] AS arr, 1 AS y) AS t;

-- Statement 414
SELECT FLATTEN(ARRAY_AGG(arr ORDER BY y NULLS FIRST) FILTER(WHERE NOT arr IS NULL)) FROM (SELECT [1, 2] AS arr, 1 AS y) AS t;

-- Statement 415
SELECT ARRAY_CONCAT_AGG(arr LIMIT 2) FROM (SELECT [1, 2] AS arr) AS t;

-- Statement 416
SELECT ARRAY_CONCAT_AGG(arr ORDER BY y DESC LIMIT 2) FROM (SELECT [1, 2] AS arr, 1 AS y) AS t;

-- Statement 417
SELECT * FROM a LEFT JOIN b ON a.key = b.key AND a.val IN UNNEST(b.arr);

-- Statement 418
SELECT * FROM a LEFT JOIN b ON a.key = b.key AND CASE WHEN b.arr IS NULL OR ARRAY_LENGTH(b.arr) = 0 THEN FALSE WHEN ARRAY_CONTAINS(b.arr, a.val) THEN TRUE WHEN a.val IS NULL OR ARRAY_LENGTH(b.arr) <> LIST_COUNT(b.arr) THEN NULL ELSE FALSE END;

-- Statement 419
SELECT b'\x61';

-- Statement 420
SELECT CAST(e'\x61' AS BLOB);

-- Statement 421
SELECT CAST(e'\x61' AS BYTEA);

-- Statement 422
SELECT b'a';

-- Statement 423
SELECT CAST(e'a' AS BLOB);

-- Statement 424
SELECT CAST(e'a' AS BYTEA);

-- Statement 425
SELECT GENERATE_UUID();

-- Statement 426
SELECT CAST(UUID() AS TEXT);

-- Statement 427
SELECT CAST(UUID() AS STRING);

-- Statement 428
SELECT CAST(UUID() AS VARCHAR);

-- Statement 429
SELECT UUID_STRING();

-- Statement 430
SELECT REPLACE('apple pie', 'pie', 'cobbler') AS result;

-- Statement 431
SELECT REPLACE(CAST('apple pie' AS BYTES), CAST('pie' AS BYTES), CAST('cobbler' AS BYTES)) AS result;

-- Statement 432
SELECT CAST(REPLACE(CAST(CAST('apple pie' AS BLOB) AS TEXT), CAST(CAST('pie' AS BLOB) AS TEXT), CAST(CAST('cobbler' AS BLOB) AS TEXT)) AS BLOB) AS result;

-- Statement 433
WITH sample AS (SELECT * FROM UNNEST([TIMESTAMP '2024-03-15 14:35:46', TIMESTAMP '2024-03-16 01:12:03']) AS ts) SELECT ts, TIMESTAMP_TRUNC(ts, DAY, 'America/New_York') AS truncated_ts FROM sample;

-- Statement 434
WITH sample AS (SELECT * FROM UNNEST([CAST('2024-03-15 14:35:46' AS TIMESTAMP), CAST('2024-03-16 01:12:03' AS TIMESTAMP)]) AS ts) SELECT ts, TIMESTAMP_TRUNC(ts, DAY, 'America/New_York') AS truncated_ts FROM sample;

-- Statement 435
WITH sample AS (SELECT * FROM UNNEST([CAST('2024-03-15 14:35:46' AS TIMESTAMPTZ), CAST('2024-03-16 01:12:03' AS TIMESTAMPTZ)]) AS _t0(ts)) SELECT ts, DATE_TRUNC('DAY', ts AT TIME ZONE 'America/New_York') AT TIME ZONE 'America/New_York' AS truncated_ts FROM sample;

-- Statement 436
WITH sample AS (SELECT ts FROM UNNEST([TIMESTAMP '2024-03-15 14:35:46', TIMESTAMP '2024-03-16 01:12:03']) AS ts) SELECT ts, TIMESTAMP_TRUNC(ts, DAY) AS truncated_ts FROM sample;

-- Statement 437
WITH sample AS (SELECT ts FROM UNNEST([CAST('2024-03-15 14:35:46' AS TIMESTAMP), CAST('2024-03-16 01:12:03' AS TIMESTAMP)]) AS ts) SELECT ts, TIMESTAMP_TRUNC(ts, DAY) AS truncated_ts FROM sample;

-- Statement 438
WITH sample AS (SELECT ts FROM UNNEST([CAST('2024-03-15 14:35:46' AS TIMESTAMPTZ), CAST('2024-03-16 01:12:03' AS TIMESTAMPTZ)]) AS _t0(ts)) SELECT ts, DATE_TRUNC('DAY', ts) AS truncated_ts FROM sample;

-- Statement 439
WITH sample AS (SELECT * FROM UNNEST([TIMESTAMP '2024-03-15 14:35:46', TIMESTAMP '2024-03-16 01:12:03']) AS ts) SELECT ts, TIMESTAMP_TRUNC(ts, MINUTE, 'America/New_York') AS truncated_ts FROM sample;

-- Statement 440
WITH sample AS (SELECT * FROM UNNEST([CAST('2024-03-15 14:35:46' AS TIMESTAMP), CAST('2024-03-16 01:12:03' AS TIMESTAMP)]) AS ts) SELECT ts, TIMESTAMP_TRUNC(ts, MINUTE, 'America/New_York') AS truncated_ts FROM sample;

-- Statement 441
WITH sample AS (SELECT * FROM UNNEST([CAST('2024-03-15 14:35:46' AS TIMESTAMPTZ), CAST('2024-03-16 01:12:03' AS TIMESTAMPTZ)]) AS _t0(ts)) SELECT ts, DATE_TRUNC('MINUTE', ts) AS truncated_ts FROM sample;

-- Statement 442
WITH sample AS (SELECT * FROM UNNEST([TIMESTAMP '2024-03-15 14:35:46', TIMESTAMP '2024-03-16 01:12:03']) AS ts) SELECT ts, TIMESTAMP_TRUNC(ts, MINUTE) AS truncated_ts FROM sample;

-- Statement 443
WITH sample AS (SELECT * FROM UNNEST([CAST('2024-03-15 14:35:46' AS TIMESTAMP), CAST('2024-03-16 01:12:03' AS TIMESTAMP)]) AS ts) SELECT ts, TIMESTAMP_TRUNC(ts, MINUTE) AS truncated_ts FROM sample;

-- Statement 444
SELECT GREATEST(1, NULL, 3);

-- Statement 445
SELECT CASE WHEN 1 IS NULL OR NULL IS NULL OR 3 IS NULL THEN NULL ELSE GREATEST(1, NULL, 3) END;

-- Statement 446
SELECT LEAST(1, NULL, 3);

-- Statement 447
SELECT CASE WHEN 1 IS NULL OR NULL IS NULL OR 3 IS NULL THEN NULL ELSE LEAST(1, NULL, 3) END;

-- Statement 448
SELECT 'foo''bar';

-- Statement 449
SELECT * FROM a - b.c.d2;

-- Statement 450
SELECT * FROM a INTERSECT ALL SELECT * FROM b;

-- Statement 451
SELECT * FROM a EXCEPT ALL SELECT * FROM b;

-- Statement 452
SELECT * FROM UNNEST(x) AS x(y);

-- Statement 453
WITH cte(c) AS (SELECT * FROM t) SELECT * FROM cte;

-- Statement 454
WITH cte AS (SELECT * FROM t) SELECT * FROM cte;

-- Statement 455
SELECT * FROM t AS t(c1, c2);

-- Statement 456
SELECT * FROM t AS t;

-- Statement 457
SELECT a[1], b[OFFSET(1)], c[ORDINAL(1)], d[SAFE_OFFSET(1)], e[SAFE_ORDINAL(1)];

-- Statement 458
SELECT a[2], b[2], c[1], d[2], e[1];

-- Statement 459
SELECT a[2], b[2], c[1], ELEMENT_AT(d, 2), ELEMENT_AT(e, 1);

-- Statement 460
WITH foo AS (SELECT [1, 2, 3] AS array_col) SELECT array_col[offset] FROM foo CROSS JOIN UNNEST(array_col) WITH OFFSET AS offset;

-- Statement 461
SELECT NOT deterministic FROM t;

-- Statement 462
INSERT INTO test (cola, colb) VALUES (CAST(7 AS STRING(10)), CAST(14 AS STRING(10)));

-- Statement 463
INSERT INTO test (cola, colb) VALUES (CAST(7 AS STRING), CAST(14 AS STRING));

-- Statement 464
SELECT CAST(1 AS NUMERIC(10, 2));

-- Statement 465
SELECT CAST(1 AS NUMERIC);

-- Statement 466
SELECT CAST('1' AS STRING(10)) UNION ALL SELECT CAST('2' AS STRING(10));

-- Statement 467
SELECT CAST('1' AS STRING) UNION ALL SELECT CAST('2' AS STRING);

-- Statement 468
SELECT cola FROM (SELECT CAST('1' AS STRING(10)) AS cola UNION ALL SELECT CAST('2' AS STRING(10)) AS cola);

-- Statement 469
SELECT cola FROM (SELECT CAST('1' AS STRING) AS cola UNION ALL SELECT CAST('2' AS STRING) AS cola);

-- Statement 470
SELECT * FROM GAP_FILL(TABLE device_data, ts_column => 'time', bucket_width => INTERVAL '1' MINUTE, value_columns => [('signal', 'locf')]) ORDER BY time;

-- Statement 471
SELECT a, b, c, d, e FROM GAP_FILL(TABLE foo, ts_column => 'b', partitioning_columns => ['a'], value_columns => [('c', 'bar'), ('d', 'baz'), ('e', 'bla')], bucket_width => INTERVAL '1' DAY);

-- Statement 472
SELECT * FROM GAP_FILL(TABLE device_data, ts_column => 'time', bucket_width => INTERVAL '1' MINUTE, value_columns => [('signal', 'linear')], ignore_null_values => FALSE) ORDER BY time;

-- Statement 473
SELECT * FROM GAP_FILL(TABLE device_data, ts_column => 'time', bucket_width => INTERVAL '1' MINUTE) ORDER BY time;

-- Statement 474
SELECT * FROM GAP_FILL(TABLE device_data, ts_column => 'time', bucket_width => INTERVAL '1' MINUTE, value_columns => [('signal', 'null')], origin => CAST('2023-11-01 09:30:01' AS DATETIME)) ORDER BY time;

-- Statement 475
SELECT * FROM ML.PREDICT(MODEL mydataset.mymodel, (SELECT label, column1, column2 FROM mydataset.mytable));

-- Statement 476
SELECT label, predicted_label1, predicted_label AS predicted_label2 FROM ML.PREDICT(MODEL mydataset.mymodel2, (SELECT * EXCEPT (predicted_label), predicted_label AS predicted_label1 FROM ML.PREDICT(MODEL mydataset.mymodel1, TABLE mydataset.mytable)));

-- Statement 477
SELECT * FROM ML.PREDICT(MODEL mydataset.mymodel, (SELECT custom_label, column1, column2 FROM mydataset.mytable), STRUCT(0.55 AS threshold));

-- Statement 478
SELECT COSH(1.5);

-- Statement 479
SELECT * FROM ML.PREDICT(MODEL `my_project`.my_dataset.my_model, (SELECT * FROM input_data));

-- Statement 480
SELECT * FROM ML.PREDICT(MODEL my_dataset.vision_model, (SELECT uri, ML.RESIZE_IMAGE(ML.DECODE_IMAGE(data), 480, 480, FALSE) AS input FROM my_dataset.object_table));

-- Statement 481
SELECT * FROM ML.PREDICT(MODEL my_dataset.vision_model, (SELECT uri, ML.CONVERT_COLOR_SPACE(ML.RESIZE_IMAGE(ML.DECODE_IMAGE(data), 224, 280, TRUE), 'YIQ') AS input FROM my_dataset.object_table WHERE content_type = 'image/jpeg'));

-- Statement 482
SELECT * FROM ML.FEATURES_AT_TIME((SELECT 1), num_rows => 1);

-- Statement 483
SELECT * FROM ML.FEATURES_AT_TIME(TABLE mydataset.feature_table, time => '2022-06-11 10:00:00+00', num_rows => 1, ignore_feature_nulls => TRUE);

-- Statement 484
SELECT * FROM VECTOR_SEARCH(TABLE mydataset.base_table, 'column_to_search', TABLE mydataset.query_table, 'query_column_to_search', top_k => 2, distance_type => 'cosine', options => '{\"fraction_lists_to_search\":0.15}');

-- Statement 485
SELECT * FROM VECTOR_SEARCH(TABLE mydataset.base_table, 'column_to_search', TABLE mydataset.query_table, query_column_to_search => 'query_column_to_search', top_k => 2, distance_type => 'cosine', options => '{\"fraction_lists_to_search\":0.15}');

-- Statement 486
SELECT * FROM VECTOR_SEARCH((SELECT * FROM mydataset.base_table), 'column_to_search', (SELECT * FROM mydataset.query_table), 'query_column_to_search');

-- Statement 487
SELECT * FROM VECTOR_SEARCH(TABLE mydataset.base_table, 'column_to_search', TABLE mydataset.query_table);

-- Statement 488
SELECT * FROM ML.TRANSLATE(MODEL `mydataset.mytranslatemodel`, TABLE `mydataset.mybqtable`, STRUCT('translate_text' AS translate_mode, 'zh-CN' AS target_language_code));

-- Statement 489
SELECT * FROM ML.TRANSLATE(MODEL `mydataset.mymodel`, (SELECT comment AS text_content FROM mydataset.mytable), STRUCT('translate_text' AS translate_mode, 'en' AS target_language_code));

-- Statement 490
SELECT * FROM ML.FORECAST(MODEL `mydataset.mymodel`, STRUCT(2 AS horizon));

-- Statement 491
SELECT * FROM ML.FORECAST(MODEL `mydataset.mymodel`, TABLE `mydataset.mybqtable`, STRUCT(2 AS horizon, 4 AS confidence_level));

-- Statement 492
SELECT * FROM ML.FORECAST(MODEL `mydataset.mymodel`, (SELECT * FROM mydataset.query_table), STRUCT());

-- Statement 493
SELECT * FROM AI.FORECAST(TABLE citibike_trips, data_col => 'num_trips', timestamp_col => 'date', horizon => 30);

-- Statement 494
SELECT * FROM AI.FORECAST((SELECT * FROM citibike_trips), data_col => 'num_trips', timestamp_col => 'date', horizon => 30);

-- Statement 495
SELECT * FROM ML.{name}(MODEL mydataset.mymodel, (SELECT label, column1, column2 FROM mydataset.mytable));

-- Statement 496
SELECT * FROM ML.{name}(MODEL mydataset.mymodel, TABLE mydataset.mytable, STRUCT(TRUE AS flatten_json_output));

-- Statement 497
SELECT * FROM ML.GENERATE_TEXT(MODEL `mydataset.gemini_model`, TABLE `mydataset.prompt_table`, STRUCT(0.15 AS temperature));

-- Statement 498
SELECT * FROM AI.GENERATE_TEXT(MODEL `mydataset.gemini_model`, TABLE `mydataset.prompt_table`, STRUCT(0.15 AS temperature));

-- Statement 499
SELECT * FROM AI.GENERATE_TABLE(MODEL `mydataset.gemini_model`, (SELECT 'Q' AS prompt), STRUCT('name STRING' AS output_schema));

-- Statement 500
SELECT AI.GENERATE_BOOL(MODEL `mydataset.gemini_model`, 'Is sky blue?');

-- Statement 501
SELECT AI.EMBED('hello');

-- Statement 502
SELECT AI.SIMILARITY('a', 'b');

-- Statement 503
SELECT AI.GENERATE('Write a haiku');

-- Statement 504
MERGE dataset.Inventory T
USING dataset.NewArrivals S ON FALSE
WHEN NOT MATCHED BY TARGET AND product LIKE '%a%'
THEN DELETE
WHEN NOT MATCHED BY SOURCE AND product LIKE '%b%'
THEN DELETE;

-- Statement 505
MERGE INTO dataset.Inventory AS T USING dataset.NewArrivals AS S ON FALSE WHEN NOT MATCHED AND product LIKE '%a%' THEN DELETE WHEN NOT MATCHED BY SOURCE AND product LIKE '%b%' THEN DELETE;

-- Statement 506
MERGE INTO dataset.Inventory AS T USING dataset.NewArrivals AS S ON FALSE WHEN NOT MATCHED AND product LIKE '%a%' THEN DELETE WHEN NOT MATCHED AND product LIKE '%b%' THEN DELETE;

-- Statement 507
WITH cte(foo) AS (SELECT * FROM tbl) SELECT foo FROM cte;

-- Statement 508
WITH cte AS (SELECT 1 AS foo) SELECT foo FROM cte;

-- Statement 509
WITH cte(foo) AS (SELECT 1) SELECT foo FROM cte;

-- Statement 510
WITH cte(foo) AS (SELECT 1 AS bar) SELECT foo FROM cte;

-- Statement 511
WITH cte AS (SELECT 1 AS bar) SELECT bar FROM cte;

-- Statement 512
WITH cte AS (SELECT 1 AS foo, 2) SELECT foo FROM cte;

-- Statement 513
WITH cte(foo) AS (SELECT 1, 2) SELECT foo FROM cte;

-- Statement 514
WITH cte AS (SELECT 1 AS foo UNION ALL SELECT 2) SELECT foo FROM cte;

-- Statement 515
WITH cte(foo) AS (SELECT 1 UNION ALL SELECT 2) SELECT foo FROM cte;

-- Statement 516
SELECT JSON_OBJECT() AS json_data;

-- Statement 517
SELECT JSON_OBJECT('foo', 10, 'bar', TRUE) AS json_data;

-- Statement 518
SELECT JSON_OBJECT('foo', 10, 'bar', ['a', 'b']) AS json_data;

-- Statement 519
SELECT JSON_OBJECT('a', 10, 'a', 'foo') AS json_data;

-- Statement 520
SELECT JSON_OBJECT(['a', 'b'], [10, NULL]) AS json_data;

-- Statement 521
SELECT JSON_OBJECT('a', 10, 'b', NULL) AS json_data;

-- Statement 522
SELECT JSON_OBJECT(['a', 'b'], [JSON '10', JSON '"foo"']) AS json_data;

-- Statement 523
SELECT JSON_OBJECT('a', PARSE_JSON('10'), 'b', PARSE_JSON('"foo"')) AS json_data;

-- Statement 524
SELECT JSON_OBJECT(['a', 'b'], [STRUCT(10 AS id, 'Red' AS color), STRUCT(20 AS id, 'Blue' AS color)]) AS json_data;

-- Statement 525
SELECT JSON_OBJECT('a', STRUCT(10 AS id, 'Red' AS color), 'b', STRUCT(20 AS id, 'Blue' AS color)) AS json_data;

-- Statement 526
SELECT JSON_OBJECT(['a', 'b'], [TO_JSON(10), TO_JSON(['foo', 'bar'])]) AS json_data;

-- Statement 527
SELECT JSON_OBJECT('a', TO_JSON(10), 'b', TO_JSON(['foo', 'bar'])) AS json_data;

-- Statement 528
SELECT JSON_OBJECT('a', 1, 'b') AS json_data;

-- Statement 529
SELECT MOD((SELECT 1), 2);

-- Statement 530
SELECT STRUCT<ARRAY<STRING>>(["2023-01-17"]);

-- Statement 531
SELECT CAST(STRUCT(['2023-01-17']) AS STRUCT<ARRAY<STRING>>);

-- Statement 532
SELECT STRUCT<STRING>((SELECT 'foo')).*;

-- Statement 533
SELECT CAST(STRUCT((SELECT 'foo')) AS STRUCT<STRING>).*;

-- Statement 534
SELECT ARRAY<FLOAT64>[1, 2, 3];

-- Statement 535
SELECT CAST([1, 2, 3] AS DOUBLE[]);

-- Statement 536
SELECT * FROM UNNEST(ARRAY<STRUCT<x INT64>>[]);

-- Statement 537
SELECT * FROM (SELECT UNNEST(CAST([] AS STRUCT(x BIGINT)[]), max_depth => 2));

-- Statement 538
SELECT * FROM UNNEST(ARRAY<STRUCT<device_id INT64, time DATETIME, signal INT64, state STRING>>[STRUCT(1, DATETIME '2023-11-01 09:34:01', 74, 'INACTIVE'),STRUCT(4, DATETIME '2023-11-01 09:38:01', 80, 'ACTIVE')]);

-- Statement 539
SELECT * FROM UNNEST(ARRAY<STRUCT<device_id INT64, time DATETIME, signal INT64, state STRING>>[STRUCT(1, CAST('2023-11-01 09:34:01' AS DATETIME), 74, 'INACTIVE'), STRUCT(4, CAST('2023-11-01 09:38:01' AS DATETIME), 80, 'ACTIVE')]);

-- Statement 540
SELECT * FROM (SELECT UNNEST(CAST([ROW(1, CAST('2023-11-01 09:34:01' AS TIMESTAMP), 74, 'INACTIVE'), ROW(4, CAST('2023-11-01 09:38:01' AS TIMESTAMP), 80, 'ACTIVE')] AS STRUCT(device_id BIGINT, time TIMESTAMP, signal BIGINT, state TEXT)[]), max_depth => 2));

-- Statement 541
SELECT STRUCT<a INT64, b STRUCT<c STRING>>(1, STRUCT('c_str'));

-- Statement 542
SELECT CAST(STRUCT(1, STRUCT('c_str')) AS STRUCT<a INT64, b STRUCT<c STRING>>);

-- Statement 543
SELECT CAST(ROW(1, ROW('c_str')) AS STRUCT(a BIGINT, b STRUCT(c TEXT)));

-- Statement 544
SELECT MAX_BY(name, score) FROM table1;

-- Statement 545
SELECT ARG_MAX(name, score) FROM table1;

-- Statement 546
SELECT MIN_BY(product, price) FROM table1;

-- Statement 547
SELECT ARG_MIN(product, price) FROM table1;

-- Statement 548
SELECT name, laps FROM UNNEST([STRUCT('Rudisha' AS name, [23.4, 26.3, 26.4, 26.1] AS laps), STRUCT('Makhloufi' AS name, [24.5, 25.4, 26.6, 26.1] AS laps)]);

-- Statement 549
SELECT name, laps FROM (SELECT UNNEST([{'name': 'Rudisha', 'laps': [23.4, 26.3, 26.4, 26.1]}, {'name': 'Makhloufi', 'laps': [24.5, 25.4, 26.6, 26.1]}], max_depth => 2));

-- Statement 550
WITH Races AS (SELECT '800M' AS race) SELECT race, name, laps FROM Races AS r CROSS JOIN UNNEST([STRUCT('Rudisha' AS name, [23.4, 26.3, 26.4, 26.1] AS laps)]);

-- Statement 551
WITH Races AS (SELECT '800M' AS race) SELECT race, name, laps FROM Races AS r CROSS JOIN (SELECT UNNEST([{'name': 'Rudisha', 'laps': [23.4, 26.3, 26.4, 26.1]}], max_depth => 2));

-- Statement 552
SELECT participant FROM UNNEST([STRUCT('Rudisha' AS name, [23.4, 26.3, 26.4, 26.1] AS laps)]) AS participant;

-- Statement 553
SELECT participant FROM (SELECT UNNEST([{'name': 'Rudisha', 'laps': [23.4, 26.3, 26.4, 26.1]}], max_depth => 2)) AS participant;

-- Statement 554
WITH Races AS (SELECT '800M' AS race) SELECT race, participant FROM Races AS r CROSS JOIN UNNEST([STRUCT('Rudisha' AS name, [23.4, 26.3, 26.4, 26.1] AS laps)]) AS participant;

-- Statement 555
WITH Races AS (SELECT '800M' AS race) SELECT race, participant FROM Races AS r CROSS JOIN (SELECT UNNEST([{'name': 'Rudisha', 'laps': [23.4, 26.3, 26.4, 26.1]}], max_depth => 2)) AS participant;

-- Statement 556
SELECT * FROM UNNEST([STRUCT('Alice' AS name, STRUCT(85 AS math, 90 AS english) AS scores), STRUCT('Bob' AS name, STRUCT(92 AS math, 88 AS english) AS scores)]);

-- Statement 557
SELECT * FROM (SELECT UNNEST([{'name': 'Alice', 'scores': {'math': 85, 'english': 90}}, {'name': 'Bob', 'scores': {'math': 92, 'english': 88}}], max_depth => 2));

-- Statement 558
SELECT * FROM TABLE(FLATTEN(INPUT => [OBJECT_CONSTRUCT('name', 'Alice', 'scores', OBJECT_CONSTRUCT('math', 85, 'english', 90)), OBJECT_CONSTRUCT('name', 'Bob', 'scores', OBJECT_CONSTRUCT('math', 92, 'english', 88))])) AS _t0(seq, key, path, index, value, this);

-- Statement 559
SELECT * FROM UNNEST(ARRAY[CAST(ROW('Alice', CAST(ROW(85, 90) AS ROW(math INTEGER, english INTEGER))) AS ROW(name VARCHAR, scores ROW(math INTEGER, english INTEGER))), CAST(ROW('Bob', CAST(ROW(92, 88) AS ROW(math INTEGER, english INTEGER))) AS ROW(name VARCHAR, scores ROW(math INTEGER, english INTEGER)))]);

-- Statement 560
SELECT * FROM EXPLODE(ARRAY(STRUCT('Alice' AS name, STRUCT(85 AS math, 90 AS english) AS scores), STRUCT('Bob' AS name, STRUCT(92 AS math, 88 AS english) AS scores)));

-- Statement 561
SELECT * FROM EXPLODE(ARRAY(STRUCT('Alice', STRUCT(85, 90)), STRUCT('Bob', STRUCT(92, 88))));

-- Statement 562
SELECT * FROM UNNEST([STRUCT('Alice' AS name, 85 AS score), STRUCT('Bob', 92), STRUCT('Diana', 95)]);

-- Statement 563
SELECT * FROM (SELECT UNNEST([{'name': 'Alice', 'score': 85}, {'name': 'Bob', 'score': 92}, {'name': 'Diana', 'score': 95}], max_depth => 2));

-- Statement 564
SELECT * FROM TABLE(FLATTEN(INPUT => [OBJECT_CONSTRUCT('name', 'Alice', 'score', 85), OBJECT_CONSTRUCT('name', 'Bob', 'score', 92), OBJECT_CONSTRUCT('name', 'Diana', 'score', 95)])) AS _t0(seq, key, path, index, value, this);

-- Statement 565
SELECT * FROM UNNEST(ARRAY[CAST(ROW('Alice', 85) AS ROW(name VARCHAR, score INTEGER)), CAST(ROW('Bob', 92) AS ROW(name VARCHAR, score INTEGER)), CAST(ROW('Diana', 95) AS ROW(name VARCHAR, score INTEGER))]);

-- Statement 566
SELECT * FROM EXPLODE(ARRAY(STRUCT('Alice' AS name, 85 AS score), STRUCT('Bob' AS name, 92 AS score), STRUCT('Diana' AS name, 95 AS score)));

-- Statement 567
SELECT * FROM EXPLODE(ARRAY(STRUCT('Alice', 85), STRUCT('Bob', 92), STRUCT('Diana', 95)));

-- Statement 568
SELECT {type} {value};

-- Statement 569
SELECT CAST({value} AS {type});

-- Statement 570
SELECT RANGE(CAST('2022-12-01' AS DATE), CAST('2022-12-31' AS DATE));

-- Statement 571
SELECT RANGE(NULL, CAST('2022-12-31' AS DATE));

-- Statement 572
SELECT RANGE(CAST('2022-10-01 14:53:27' AS DATETIME), CAST('2022-10-01 16:00:00' AS DATETIME));

-- Statement 573
SELECT RANGE(CAST('2022-10-01 14:53:27 America/Los_Angeles' AS TIMESTAMP), CAST('2022-10-01 16:00:00 America/Los_Angeles' AS TIMESTAMP));

-- Statement 574
SELECT color, ARRAY_AGG(id ORDER BY id {sort_order}) AS ids FROM colors GROUP BY 1;

-- Statement 575
SELECT color, ARRAY_AGG(id ORDER BY id {sort_order} {null_order}) AS ids FROM colors GROUP BY 1;

-- Statement 576
SELECT SUM(f1) OVER (ORDER BY f2 {sort_order}) FROM t;

-- Statement 577
SELECT SUM(f1) OVER (ORDER BY f2 {sort_order} {null_order}) FROM t;

-- Statement 578
WITH t AS (SELECT 1 AS id, 2 AS col1) SELECT {func_call} OVER (PARTITION BY id ORDER BY col1 {sort_order} {null_order} ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) FROM t;

-- Statement 579
WITH t AS (SELECT 1 AS id, 2 AS col1) SELECT {func_call} OVER (PARTITION BY id ORDER BY col1 {sort_order} {null_order}) FROM t;

-- Statement 580
SELECT JSON_QUERY('{"class": {"students": []}}', '$.class');

-- Statement 581
SELECT '{"class": {"students": []}}' -> '$.class';

-- Statement 582
SELECT GET_PATH(PARSE_JSON('{"class": {"students": []}}'), 'class');

-- Statement 583
SELECT JSON_QUERY(foo, '$.class');

-- Statement 584
SELECT GET_PATH(PARSE_JSON(foo), 'class');

-- Statement 585
SELECT {func}('5');

-- Statement 586
SELECT {func}('5', '$');

-- Statement 587
SELECT JSON_VALUE('5', '$') ->> '$';

-- Statement 588
SELECT {func}('{{"name": "Jakob", "age": "6"}}', '$.age');

-- Statement 589
SELECT JSON_VALUE('{"name": "Jakob", "age": "6"}', '$.age') ->> '$';

-- Statement 590
SELECT JSON_EXTRACT_PATH_TEXT('{"name": "Jakob", "age": "6"}', 'age');

-- Statement 591
SELECT {func}('{{"fruits": [1, "oranges"]}}', '$.fruits');

-- Statement 592
SELECT CAST('{"fruits": [1, "oranges"]}' -> '$.fruits' AS JSON[]);

-- Statement 593
SELECT TRANSFORM(GET_PATH(PARSE_JSON('{"fruits": [1, "oranges"]}'), 'fruits'), x -> PARSE_JSON(TO_JSON(x)));

-- Statement 594
SELECT UNIX_SECONDS('2008-12-25 15:30:00+00');

-- Statement 595
SELECT CAST(EPOCH(CAST('2008-12-25 15:30:00+00' AS TIMESTAMPTZ)) AS BIGINT);

-- Statement 596
SELECT TIMESTAMPDIFF(SECONDS, CAST('1970-01-01 00:00:00+00' AS TIMESTAMPTZ), '2008-12-25 15:30:00+00');

-- Statement 597
SELECT UNIX_MICROS('2008-12-25 15:30:00+00');

-- Statement 598
SELECT EPOCH_US(CAST('2008-12-25 15:30:00+00' AS TIMESTAMPTZ));

-- Statement 599
SELECT UNIX_MICROS(TIMESTAMP '2008-12-25 15:30:00+00');

-- Statement 600
SELECT UNIX_MICROS(CAST('2008-12-25 15:30:00+00' AS TIMESTAMP));

-- Statement 601
SELECT UNIX_MILLIS('2008-12-25 15:30:00+00');

-- Statement 602
SELECT EPOCH_MS(CAST('2008-12-25 15:30:00+00' AS TIMESTAMPTZ));

-- Statement 603
SELECT UNIX_MILLIS(TIMESTAMP '2008-12-25 15:30:00+00');

-- Statement 604
SELECT UNIX_MILLIS(CAST('2008-12-25 15:30:00+00' AS TIMESTAMP));

-- Statement 605
SELECT REGEXP_EXTRACT(abc, 'pattern(group)') FROM table;

-- Statement 606
SELECT REGEXP_EXTRACT(abc, 'pattern(group)', 1) FROM "table";

-- Statement 607
SELECT REGEXP_EXTRACT(abc, 'pattern(group)', 1) FROM table;

-- Statement 608
SELECT REGEXP_EXTRACT(abc, 'pattern(group)', 2) FROM table;

-- Statement 609
SELECT REGEXP_EXTRACT(NULLIF(SUBSTRING(abc, 2), ''), 'pattern(group)', 1) FROM "table";

-- Statement 610
SELECT REGEXP_EXTRACT(abc, 'pattern(group)', 1, 1) FROM table;

-- Statement 611
SELECT REGEXP_EXTRACT(abc, 'pattern(group)', 2, 3) FROM table;

-- Statement 612
SELECT ARRAY_EXTRACT(REGEXP_EXTRACT_ALL(NULLIF(SUBSTRING(abc, 2), ''), 'pattern(group)', 1), 3) FROM "table";

-- Statement 613
SELECT FORMAT_DATE('%Y%m%d', '2023-12-25');

-- Statement 614
SELECT STRFTIME(CAST('2023-12-25' AS DATE), '%Y%m%d');

-- Statement 615
SELECT FORMAT_DATETIME('%Y%m%d %H:%M:%S', DATETIME '2023-12-25 15:30:00');

-- Statement 616
SELECT FORMAT_DATETIME('%Y%m%d %T', CAST('2023-12-25 15:30:00' AS DATETIME));

-- Statement 617
SELECT STRFTIME(CAST('2023-12-25 15:30:00' AS TIMESTAMP), '%Y%m%d %H:%M:%S');

-- Statement 618
SELECT FORMAT_DATETIME('%x', '2023-12-25 15:30:00');

-- Statement 619
SELECT FORMAT_DATETIME('%D', '2023-12-25 15:30:00');

-- Statement 620
SELECT STRFTIME(CAST('2023-12-25 15:30:00' AS TIMESTAMP), '%m/%d/%y');

-- Statement 621
SELECT FORMAT_DATETIME('%F %T', DATETIME '2023-10-15 14:30:45');

-- Statement 622
SELECT FORMAT_DATETIME('%F %T', CAST('2023-10-15 14:30:45' AS DATETIME));

-- Statement 623
SELECT STRFTIME(CAST('2023-10-15 14:30:45' AS TIMESTAMP), '%Y-%m-%d %H:%M:%S');

-- Statement 624
SELECT FORMAT_DATETIME('%c', DATETIME '2008-12-25 15:30:00');

-- Statement 625
SELECT FORMAT_DATETIME('%c', CAST('2008-12-25 15:30:00' AS DATETIME));

-- Statement 626
SELECT STRFTIME(CAST('2008-12-25 15:30:00' AS TIMESTAMP), '%a %b %-d %H:%M:%S %Y');

-- Statement 627
SELECT FORMAT_DATETIME('%Y-%m-%e', DATETIME '2020-09-09 10:15:30');

-- Statement 628
SELECT FORMAT_DATETIME('%Y-%m-%e', CAST('2020-09-09 10:15:30' AS DATETIME));

-- Statement 629
SELECT STRFTIME(CAST('2020-09-09 10:15:30' AS TIMESTAMP), '%Y-%m-%-d');

-- Statement 630
SELECT FORMAT_TIMESTAMP("%b-%d-%Y", TIMESTAMP "2050-12-25 15:30:55+00");

-- Statement 631
SELECT FORMAT_TIMESTAMP('%b-%d-%Y', CAST('2050-12-25 15:30:55+00' AS TIMESTAMP));

-- Statement 632
SELECT STRFTIME(CAST(CAST('2050-12-25 15:30:55+00' AS TIMESTAMPTZ) AS TIMESTAMP), '%b-%d-%Y');

-- Statement 633
SELECT TO_CHAR(CAST(CAST('2050-12-25 15:30:55+00' AS TIMESTAMPTZ) AS TIMESTAMP), 'mon-DD-yyyy');

-- Statement 634
SELECT CAST('2026-03-24' AS STRING FORMAT ('YYYY'));

-- Statement 635
SELECT CAST('2026-03-24' AS STRING FORMAT 'YYYY');

-- Statement 636
SELECT CAST(date AS STRING FORMAT ('YYYY')) FROM (SELECT DATE('2026-03-24') AS date);

-- Statement 637
SELECT CAST(date AS STRING FORMAT 'YYYY') FROM (SELECT DATE('2026-03-24') AS date);

-- Statement 638
SELECT CAST(date AS STRING FORMAT ('YYYY-MM-DD'));

-- Statement 639
SELECT CAST(date AS STRING FORMAT 'YYYY-MM-DD');

-- Statement 640
SELECT CAST(timestamp AS STRING FORMAT ('YYYY-MM-DD') AT TIME ZONE 'UTC');

-- Statement 641
SELECT CAST(timestamp AS STRING FORMAT 'YYYY-MM-DD' AT TIME ZONE 'UTC');

-- Statement 642
SELECT CAST(date AS TIMESTAMP FORMAT ('YYYY-MM-DD HH24:MI:SS'));

-- Statement 643
SELECT PARSE_TIMESTAMP('%F %T', date);

-- Statement 644
SELECT a, GROUP_CONCAT(b) FROM table GROUP BY a;

-- Statement 645
SELECT a, STRING_AGG(b) FROM table GROUP BY a;

-- Statement 646
SELECT 1 AS foo INNER UNION ALL SELECT 3 AS foo, 4 AS bar;

-- Statement 647
SELECT 1 AS foo{side}{kind} UNION ALL{name} SELECT 3 AS foo, 4 AS bar;

-- Statement 648
SELECT 1 AS x UNION ALL CORRESPONDING SELECT 2 AS x;

-- Statement 649
SELECT 1 AS x INNER UNION ALL BY NAME SELECT 2 AS x;

-- Statement 650
SELECT 1 AS x UNION ALL CORRESPONDING BY (foo, bar) SELECT 2 AS x;

-- Statement 651
SELECT 1 AS x INNER UNION ALL BY NAME ON (foo, bar) SELECT 2 AS x;

-- Statement 652
SELECT 1 AS x LEFT UNION ALL CORRESPONDING SELECT 2 AS x;

-- Statement 653
SELECT 1 AS x LEFT UNION ALL BY NAME SELECT 2 AS x;

-- Statement 654
SELECT 1 AS x UNION ALL STRICT CORRESPONDING SELECT 2 AS x;

-- Statement 655
SELECT 1 AS x UNION ALL BY NAME SELECT 2 AS x;

-- Statement 656
SELECT 1 AS x UNION ALL STRICT CORRESPONDING BY (foo, bar) SELECT 2 AS x;

-- Statement 657
SELECT 1 AS x UNION ALL BY NAME ON (foo, bar) SELECT 2 AS x;

-- Statement 658
SELECT * FROM UNNEST(x) WITH OFFSET EXCEPT DISTINCT SELECT * FROM UNNEST(y) WITH OFFSET;

-- Statement 659
SELECT * FROM UNNEST(x) WITH OFFSET AS offset EXCEPT DISTINCT SELECT * FROM UNNEST(y) WITH OFFSET AS offset;

-- Statement 660
SELECT * FROM t1, UNNEST([1, 2]) AS hit WITH OFFSET {join_ops} JOIN foo;

-- Statement 661
SELECT * FROM t1 CROSS JOIN UNNEST([1, 2]) AS hit WITH OFFSET AS offset {join_ops} JOIN foo;

-- Statement 662
SELECT a, b FROM test_schema.test_table_a UNION ALL SELECT c, d FROM test_catalog.test_schema.test_table_b;

-- Statement 663
SELECT a, b FROM region.INFORMATION_SCHEMA.COLUMNS;

-- Statement 664
SELECT `a` FROM `test_schema`.`test_table_a`;

-- Statement 665
SELECT a, b FROM `region.INFORMATION_SCHEMA.COLUMNS`;

-- Statement 666
SELECT * FROM p.d.t;

-- Statement 667
SELECT * FROM `P`.`D`.`T` AS `T`;

-- Statement 668
SELECT ARRAY_AGG({distinct}x ORDER BY x);

-- Statement 669
SELECT ARRAY_AGG({distinct}x) WITHIN GROUP (ORDER BY x NULLS FIRST);

-- Statement 670
SELECT ARRAY_AGG(x{nulls} ORDER BY col1 ASC, col2 DESC);

-- Statement 671
SELECT ARRAY_AGG(x) WITHIN GROUP (ORDER BY col1 ASC NULLS FIRST, col2 DESC NULLS LAST);

-- Statement 672
WITH x AS ( SELECT 1 AS id), test_cte AS ( SELECT ARRAY_CONCAT(( SELECT id FROM x WHERE FALSE)) AS result ) SELECT * FROM test_cte;

-- Statement 673
WITH x AS (SELECT 1 AS id), test_cte AS (SELECT ARRAY_CAT((SELECT id FROM x WHERE FALSE), []) AS result) SELECT * FROM test_cte;

-- Statement 674
SELECT ARRAY(SELECT AS STRUCT x1 AS x1, x2 AS x2 FROM t) AS array_col;

-- Statement 675
SELECT (SELECT ARRAY_AGG(OBJECT_CONSTRUCT('x1', x1, 'x2', x2)) FROM t) AS array_col;

-- Statement 676
WITH t1 AS (SELECT ARRAY(SELECT AS STRUCT x1 AS alias_x1, x2 /* test */ FROM t2) AS array_col) SELECT array_col[0].alias_x1, array_col[0].x2 FROM t1;

-- Statement 677
WITH t1 AS (SELECT (SELECT ARRAY_AGG(OBJECT_CONSTRUCT('alias_x1', x1, 'x2', x2 /* test */)) FROM t2) AS array_col) SELECT array_col[0].alias_x1, array_col[0].x2 FROM t1;

-- Statement 678
WITH t1 AS (SELECT ARRAY(SELECT AS STRUCT 1 AS a, 2 AS b) AS array_col) SELECT array_col[0].a, array_col[0].b FROM t1;

-- Statement 679
WITH t1 AS (SELECT (SELECT ARRAY_AGG(OBJECT_CONSTRUCT('a', 1, 'b', 2))) AS array_col) SELECT array_col[0].a, array_col[0].b FROM t1;

-- Statement 680
WITH t1 AS (SELECT ARRAY(SELECT AS STRUCT x1 AS alias_x1, x2 /* test */ FROM t2 WHERE x2 = 4) AS array_col) SELECT array_col[0].alias_x1, array_col[0].x2 FROM t1;

-- Statement 681
WITH t1 AS (SELECT (SELECT ARRAY_AGG(OBJECT_CONSTRUCT('alias_x1', x1, 'x2', x2 /* test */)) FROM t2 WHERE x2 = 4) AS array_col) SELECT array_col[0].alias_x1, array_col[0].x2 FROM t1;

-- Statement 682
SELECT * FROM tbl CROSS JOIN UNNEST(col) AS ref WITH OFFSET {offset};

-- Statement 683
SELECT * FROM tbl CROSS JOIN UNNEST(col) AS ref WITH OFFSET AS {alias};

-- Statement 684
SELECT * FROM tbl LATERAL VIEW POSEXPLODE(col) AS {alias}, ref;

-- Statement 685
SELECT GENERATE_DATE_ARRAY('2016-10-05', '2016-10-08');

-- Statement 686
SELECT GENERATE_DATE_ARRAY('2016-10-05', '2016-10-08', INTERVAL '1' DAY);

-- Statement 687
SELECT CAST(GENERATE_SERIES(CAST('2016-10-05' AS DATE), CAST('2016-10-08' AS DATE), INTERVAL '1' DAY) AS DATE[]);

-- Statement 688
SELECT GENERATE_DATE_ARRAY('2016-10-05', '2016-10-08', INTERVAL '1' MONTH);

-- Statement 689
SELECT CAST(GENERATE_SERIES(CAST('2016-10-05' AS DATE), CAST('2016-10-08' AS DATE), INTERVAL '1' MONTH) AS DATE[]);

-- Statement 690
SELECT id, mnth FROM t CROSS JOIN UNNEST(GENERATE_DATE_ARRAY(start_month, DATE_TRUNC(CURRENT_DATE, MONTH), INTERVAL '1' MONTH)) AS mnth;

-- Statement 691
SELECT id, mnth FROM t CROSS JOIN UNNEST(CAST(GENERATE_SERIES(start_month, DATE_TRUNC('MONTH', CURRENT_DATE), INTERVAL '1' MONTH) AS DATE[])) AS _t0(mnth);

-- Statement 692
SELECT id, DATEADD(MONTH, CAST(mnth AS INT), CAST(start_month AS DATE)) AS mnth FROM t, LATERAL FLATTEN(INPUT => ARRAY_GENERATE_RANGE(0, DATEDIFF(MONTH, start_month, DATE_TRUNC('MONTH', CURRENT_DATE)) + 1)) AS _t0(seq, key, path, index, mnth, this);

-- Statement 693
SELECT id, mnth AS a_mnth FROM t CROSS JOIN UNNEST(GENERATE_DATE_ARRAY(start_month, DATE_TRUNC(CURRENT_DATE, MONTH), INTERVAL '1' MONTH)) AS mnth;

-- Statement 694
SELECT id, mnth AS a_mnth FROM t CROSS JOIN UNNEST(CAST(GENERATE_SERIES(start_month, DATE_TRUNC('MONTH', CURRENT_DATE), INTERVAL '1' MONTH) AS DATE[])) AS _t0(mnth);

-- Statement 695
SELECT id, DATEADD(MONTH, CAST(mnth AS INT), CAST(start_month AS DATE)) AS a_mnth FROM t, LATERAL FLATTEN(INPUT => ARRAY_GENERATE_RANGE(0, DATEDIFF(MONTH, start_month, DATE_TRUNC('MONTH', CURRENT_DATE)) + 1)) AS _t0(seq, key, path, index, mnth, this);

-- Statement 696
SELECT id, mnth + 1 AS a_mnth FROM t CROSS JOIN UNNEST(GENERATE_DATE_ARRAY(start_month, DATE_TRUNC(CURRENT_DATE, MONTH), INTERVAL '1' MONTH)) AS mnth;

-- Statement 697
SELECT id, mnth + 1 AS a_mnth FROM t CROSS JOIN UNNEST(CAST(GENERATE_SERIES(start_month, DATE_TRUNC('MONTH', CURRENT_DATE), INTERVAL '1' MONTH) AS DATE[])) AS _t0(mnth);

-- Statement 698
SELECT id, DATEADD(MONTH, CAST(mnth AS INT), CAST(start_month AS DATE)) + 1 AS a_mnth FROM t, LATERAL FLATTEN(INPUT => ARRAY_GENERATE_RANGE(0, DATEDIFF(MONTH, start_month, DATE_TRUNC('MONTH', CURRENT_DATE)) + 1)) AS _t0(seq, key, path, index, mnth, this);

-- Statement 699
SELECT LAST_DAY(DATE '2008-11-10', WEEK(SUNDAY));

-- Statement 700
SELECT LAST_DAY(CAST('2008-11-10' AS DATE), WEEK);

-- Statement 701
SELECT CAST(CAST('2008-11-10' AS DATE) + INTERVAL ((13 - EXTRACT(DAYOFWEEK FROM CAST('2008-11-10' AS DATE))) % 7) DAY AS DATE);

-- Statement 702
SELECT LAST_DAY(DATE '2008-11-10', WEEK);

-- Statement 703
SELECT LAST_DAY(DATE '2008-11-10', WEEK(MONDAY));

-- Statement 704
SELECT LAST_DAY(CAST('2008-11-10' AS DATE), WEEK(MONDAY));

-- Statement 705
SELECT CAST(CAST('2008-11-10' AS DATE) + INTERVAL ((7 - EXTRACT(DAYOFWEEK FROM CAST('2008-11-10' AS DATE))) % 7) DAY AS DATE);

-- Statement 706
SELECT LAST_DAY(DATE '2008-11-10', ISOWEEK);

-- Statement 707
SELECT LAST_DAY(CAST('2008-11-10' AS DATE), ISOWEEK);

-- Statement 708
SELECT DATE_TRUNC(d, WEEK(SUNDAY));

-- Statement 709
SELECT DATE_TRUNC(d, WEEK);

-- Statement 710
SELECT TIMESTAMP_TRUNC(ts, WEEK(SUNDAY));

-- Statement 711
SELECT TIMESTAMP_TRUNC(ts, WEEK);

-- Statement 712
SELECT DATE_TRUNC('WEEK', ts + INTERVAL '1' DAY) + INTERVAL '-1' DAY;

-- Statement 713
SELECT DATETIME_TRUNC(dt, WEEK(SUNDAY));

-- Statement 714
SELECT DATETIME_TRUNC(dt, WEEK);

-- Statement 715
SELECT DATE_TRUNC('WEEK', CAST(dt AS TIMESTAMP) + INTERVAL '1' DAY) + INTERVAL '-1' DAY;

-- Statement 716
SELECT DATE_DIFF(d1, d2, WEEK(SUNDAY));

-- Statement 717
SELECT DATE_DIFF(d1, d2, WEEK);

-- Statement 718
SELECT DATEDIFF(WEEK, d2, d1);

-- Statement 719
SELECT LAST_DAY(d, WEEK(SUNDAY));

-- Statement 720
SELECT LAST_DAY(d, WEEK);

-- Statement 721
SELECT EXTRACT(WEEK(THURSDAY) FROM d);

-- Statement 722
SELECT DATE_TRUNC(DATE '2008-11-10', WEEK(SUNDAY));

-- Statement 723
SELECT DATE_TRUNC(CAST('2008-11-10' AS DATE), WEEK);

-- Statement 724
SELECT CAST(DATE_TRUNC('WEEK', CAST('2008-11-10' AS DATE) + INTERVAL '1' DAY) + INTERVAL '-1' DAY AS DATE);

-- Statement 725
SELECT DATE_TRUNC(DATE '2008-11-10', ISOWEEK);

-- Statement 726
SELECT DATE_TRUNC(CAST('2008-11-10' AS DATE), ISOWEEK);

-- Statement 727
SELECT DATE_TRUNC('WEEK', CAST('2008-11-10' AS DATE));

-- Statement 728
SELECT DATE_TRUNC(DATE '2008-11-10', WEEK);

-- Statement 729
SELECT TIMESTAMP_TRUNC(TIMESTAMP '2008-11-10 14:30:00', WEEK);

-- Statement 730
SELECT TIMESTAMP_TRUNC(CAST('2008-11-10 14:30:00' AS TIMESTAMP), WEEK);

-- Statement 731
SELECT DATE_TRUNC('WEEK', CAST('2008-11-10 14:30:00' AS TIMESTAMPTZ) + INTERVAL '1' DAY) + INTERVAL '-1' DAY;

-- Statement 732
SELECT TIMESTAMP_TRUNC(TIMESTAMP '2008-11-10 14:30:00', WEEK(SUNDAY));

-- Statement 733
SELECT DATETIME_TRUNC(DATETIME '2008-11-10 14:30:00', WEEK);

-- Statement 734
SELECT DATETIME_TRUNC(CAST('2008-11-10 14:30:00' AS DATETIME), WEEK);

-- Statement 735
SELECT DATE_TRUNC('WEEK', CAST(CAST('2008-11-10 14:30:00' AS TIMESTAMP) AS TIMESTAMP) + INTERVAL '1' DAY) + INTERVAL '-1' DAY;

-- Statement 736
SELECT DATETIME_TRUNC(DATETIME '2008-11-10 14:30:00', WEEK(SUNDAY));

-- Statement 737
SELECT TIMESTAMP_TRUNC(TIMESTAMP '2008-11-10 14:30:00+00', WEEK, 'America/New_York');

-- Statement 738
SELECT TIMESTAMP_TRUNC(CAST('2008-11-10 14:30:00+00' AS TIMESTAMP), WEEK, 'America/New_York');

-- Statement 739
SELECT (DATE_TRUNC('WEEK', CAST('2008-11-10 14:30:00+00' AS TIMESTAMPTZ) AT TIME ZONE 'America/New_York' + INTERVAL '1' DAY) + INTERVAL '-1' DAY) AT TIME ZONE 'America/New_York';

-- Statement 740
SELECT TIMESTAMP_TRUNC(TIMESTAMP '2008-11-10 14:30:00+00', WEEK(SUNDAY), 'America/New_York');

-- Statement 741
SELECT DATE_TRUNC(date, WEEK({day}));

-- Statement 742
SELECT DATE_TRUNC(date, {bq_unit});

-- Statement 743
SELECT {duckdb_sql};

-- Statement 744
SELECT DATE_DIFF('2024-06-15', '2024-01-08', WEEK(MONDAY));

-- Statement 745
SELECT DATE_DIFF('WEEK', DATE_TRUNC('WEEK', CAST('2024-01-08' AS DATE)), DATE_TRUNC('WEEK', CAST('2024-06-15' AS DATE)));

-- Statement 746
SELECT DATE_DIFF('2026-01-15', '2024-01-08', WEEK(SUNDAY));

-- Statement 747
SELECT DATE_DIFF('2026-01-15', '2024-01-08', WEEK);

-- Statement 748
SELECT DATE_DIFF('WEEK', DATE_TRUNC('WEEK', CAST('2024-01-08' AS DATE) + INTERVAL '1' DAY), DATE_TRUNC('WEEK', CAST('2026-01-15' AS DATE) + INTERVAL '1' DAY));

-- Statement 749
SELECT DATE_DIFF('2024-01-15', '2022-04-28', WEEK(SATURDAY));

-- Statement 750
SELECT DATE_DIFF('WEEK', DATE_TRUNC('WEEK', CAST('2022-04-28' AS DATE) + INTERVAL '-5' DAY), DATE_TRUNC('WEEK', CAST('2024-01-15' AS DATE) + INTERVAL '-5' DAY));

-- Statement 751
SELECT DATE_DIFF('2024-01-15', '2024-01-08', WEEK);

-- Statement 752
SELECT DATE_DIFF('WEEK', DATE_TRUNC('WEEK', CAST('2024-01-08' AS DATE) + INTERVAL '1' DAY), DATE_TRUNC('WEEK', CAST('2024-01-15' AS DATE) + INTERVAL '1' DAY));

-- Statement 753
SELECT DATE_DIFF('2024-01-07', '2024-01-06', WEEK);

-- Statement 754
SELECT DATE_DIFF('WEEK', DATE_TRUNC('WEEK', CAST('2024-01-06' AS DATE) + INTERVAL '1' DAY), DATE_TRUNC('WEEK', CAST('2024-01-07' AS DATE) + INTERVAL '1' DAY));

-- Statement 755
SELECT DATE_DIFF('2024-01-15', '2024-01-08', ISOWEEK);

-- Statement 756
SELECT DATE_DIFF('WEEK', DATE_TRUNC('WEEK', CAST('2024-01-08' AS DATE)), DATE_TRUNC('WEEK', CAST('2024-01-15' AS DATE)));

-- Statement 757
SELECT DATE_DIFF(DATE '2024-09-15', DATE '2024-01-08', WEEK(MONDAY));

-- Statement 758
SELECT DATE_DIFF(CAST('2024-09-15' AS DATE), CAST('2024-01-08' AS DATE), WEEK(MONDAY));

-- Statement 759
SELECT DATE_DIFF('WEEK', DATE_TRUNC('WEEK', CAST('2024-01-08' AS DATE)), DATE_TRUNC('WEEK', CAST('2024-09-15' AS DATE)));

-- Statement 760
SELECT DATE_DIFF(DATE '2024-01-01', DATE '2024-01-15', WEEK(SUNDAY));

-- Statement 761
SELECT DATE_DIFF(CAST('2024-01-01' AS DATE), CAST('2024-01-15' AS DATE), WEEK);

-- Statement 762
SELECT DATE_DIFF('WEEK', DATE_TRUNC('WEEK', CAST('2024-01-15' AS DATE) + INTERVAL '1' DAY), DATE_TRUNC('WEEK', CAST('2024-01-01' AS DATE) + INTERVAL '1' DAY));

-- Statement 763
SELECT DATE_DIFF(DATE '2023-05-01', DATE '2024-01-15', ISOWEEK);

-- Statement 764
SELECT DATE_DIFF(CAST('2023-05-01' AS DATE), CAST('2024-01-15' AS DATE), ISOWEEK);

-- Statement 765
SELECT DATE_DIFF('WEEK', DATE_TRUNC('WEEK', CAST('2024-01-15' AS DATE)), DATE_TRUNC('WEEK', CAST('2023-05-01' AS DATE)));

-- Statement 766
SELECT DATE_DIFF(DATE '2024-01-01', DATE '2024-01-15', DAY);

-- Statement 767
SELECT DATE_DIFF(CAST('2024-01-01' AS DATE), CAST('2024-01-15' AS DATE), DAY);

-- Statement 768
SELECT DATE_DIFF('DAY', CAST('2024-01-15' AS DATE), CAST('2024-01-01' AS DATE));

-- Statement 769
SELECT 1 & 1;

-- Statement 770
SELECT BITAND(1, 1);

-- Statement 771
SELECT ~1;

-- Statement 772
SELECT BITNOT(1);

-- Statement 773
SELECT TO_HEX(SHA1('abc'));

-- Statement 774
SELECT TO_CHAR(SHA1_BINARY('abc'));

-- Statement 775
SELECT MD5('abc');

-- Statement 776
SELECT MD5_BINARY('abc');

-- Statement 777
SELECT TO_JSON_STRING(STRUCT('Alice' AS name)) AS json_data;

-- Statement 778
SELECT TO_JSON(OBJECT_CONSTRUCT('name', 'Alice')) AS json_data;

-- Statement 779
SELECT CONCAT('T.P.', ' ', 'Bar') AS author;

-- Statement 780
SELECT 'T.P.' || ' ' || 'Bar' AS author;

-- Statement 781
SELECT col FROM t WHERE _PARTITIONTIME BETWEEN a AND b;

-- Statement 782
SELECT `t`.`col` AS `col` FROM `t` AS `t` WHERE `_partitiontime` BETWEEN `t`.`a` AND `t`.`b`;

-- Statement 783
SELECT _DBT_MAX_PARTITION FROM t;

-- Statement 784
SELECT ROUND(2.25) AS value;

-- Statement 785
SELECT ROUND(2.25, 1) AS value;

-- Statement 786
SELECT ROUND(NUMERIC '2.25', 1, 'ROUND_HALF_AWAY_FROM_ZERO') AS value;

-- Statement 787
SELECT ROUND(CAST('2.25' AS NUMERIC), 1, 'ROUND_HALF_AWAY_FROM_ZERO') AS value;

-- Statement 788
SELECT ROUND(CAST('2.25' AS DECIMAL), 1) AS value;

-- Statement 789
SELECT ROUND(NUMERIC '2.25', 1, 'ROUND_HALF_EVEN') AS value;

-- Statement 790
SELECT ROUND(CAST('2.25' AS NUMERIC), 1, 'ROUND_HALF_EVEN') AS value;

-- Statement 791
SELECT ROUND_EVEN(CAST('2.25' AS DECIMAL), 1) AS value;

-- Statement 792
SELECT {type_} '1';

-- Statement 793
SELECT CAST('1' AS BIGNUMERIC);

-- Statement 794
SELECT CAST('1' AS DECIMAL(38, 5));

-- Statement 795
SELECT CAST(1 AS {type_});

-- Statement 796
SELECT CAST(1 AS BIGNUMERIC);

-- Statement 797
SELECT CAST(1 AS DECIMAL(38, 5));

