-- SQLGlot snowflake DML statements
-- Extracted from snowflake.py test fixtures
-- Total statements: 1419
-- ============================================================

-- Statement 1
WITH t AS (SELECT PARSE_JSON('{"level1": {"level2": {"level3": "value"}}}') AS data) SELECT data:     level1  : level2 : level3::VARIANT FROM t;

-- Statement 2
WITH t AS (SELECT PARSE_JSON('{"level1": {"level2": {"level3": "value"}}}') AS data) SELECT CAST(GET_PATH(data, 'level1.level2.level3') AS VARIANT) FROM t;

-- Statement 3
SELECT * FROM x ASOF JOIN y OFFSET MATCH_CONDITION (x.a > y.a);

-- Statement 4
SELECT * FROM x ASOF JOIN y AS OFFSET MATCH_CONDITION (x.a > y.a);

-- Statement 5
SELECT * FROM x ASOF JOIN y LIMIT MATCH_CONDITION (x.a > y.a);

-- Statement 6
SELECT * FROM x ASOF JOIN y AS LIMIT MATCH_CONDITION (x.a > y.a);

-- Statement 7
SELECT session;

-- Statement 8
SELECT DATE_PART(EPOCH_MILLISECOND, CURRENT_TIMESTAMP()) AS a;

-- Statement 9
SELECT GET(a, b);

-- Statement 10
SELECT HASH_AGG(a, b, c, d);

-- Statement 11
SELECT GREATEST(1, 2, 3, NULL);

-- Statement 12
SELECT GREATEST_IGNORE_NULLS(1, 2, 3, NULL);

-- Statement 13
SELECT LEAST(5, NULL, 7, 3);

-- Statement 14
SELECT LEAST_IGNORE_NULLS(5, NULL, 7, 3);

-- Statement 15
SELECT MAX(x);

-- Statement 16
SELECT COUNT(x);

-- Statement 17
SELECT MIN(amount);

-- Statement 18
SELECT MODE(x);

-- Statement 19
SELECT MODE(status) OVER (PARTITION BY region) FROM orders;

-- Statement 20
SELECT MODE(x) FROM t;

-- Statement 21
SELECT MODE() WITHIN GROUP (ORDER BY x) FROM t;

-- Statement 22
SELECT TAN(x);

-- Statement 23
SELECT COS(x);

-- Statement 24
SELECT SINH(1.5);

-- Statement 25
SELECT MOD(x, y);

-- Statement 26
SELECT x % y;

-- Statement 27
SELECT ROUND(x);

-- Statement 28
SELECT ROUND(123.456, -1);

-- Statement 29
SELECT ROUND(123.456, 2, 'HALF_AWAY_FROM_ZERO');

-- Statement 30
SELECT FLOOR(x);

-- Statement 31
SELECT FLOOR(135.135, 1);

-- Statement 32
SELECT FLOOR(x, -1);

-- Statement 33
SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY salary) FROM employees;

-- Statement 34
SELECT TRY_PARSE_JSON('{"x: 1}');

-- Statement 35
SELECT PARSE_JSON('{"x: 1}');

-- Statement 36
SELECT APPROX_TOP_K(col) FROM t;

-- Statement 37
SELECT APPROX_TOP_K(col, 1) FROM t;

-- Statement 38
SELECT APPROX_TOP_K(category, 3) FROM t;

-- Statement 39
SELECT MINHASH(5, col);

-- Statement 40
SELECT MINHASH(5, col1, col2);

-- Statement 41
SELECT MINHASH(5, *);

-- Statement 42
SELECT MINHASH_COMBINE(minhash_col);

-- Statement 43
SELECT APPROXIMATE_SIMILARITY(minhash_col);

-- Statement 44
SELECT APPROXIMATE_JACCARD_INDEX(minhash_col);

-- Statement 45
SELECT APPROX_PERCENTILE_ACCUMULATE(col);

-- Statement 46
SELECT APPROX_PERCENTILE_ESTIMATE(state, 0.5);

-- Statement 47
SELECT APPROX_TOP_K_ACCUMULATE(col, 10);

-- Statement 48
SELECT APPROX_TOP_K_COMBINE(state, 2);

-- Statement 49
SELECT APPROX_TOP_K_COMBINE(state);

-- Statement 50
SELECT APPROX_TOP_K_ESTIMATE(state_column, 4);

-- Statement 51
SELECT APPROX_TOP_K_ESTIMATE(state_column);

-- Statement 52
SELECT APPROX_PERCENTILE_COMBINE(state_column);

-- Statement 53
SELECT EQUAL_NULL(1, 2);

-- Statement 54
SELECT EXP(1);

-- Statement 55
SELECT FACTORIAL(5);

-- Statement 56
SELECT BIT_LENGTH('abc');

-- Statement 57
SELECT BIT_LENGTH(x'A1B2');

-- Statement 58
SELECT BITMAP_BIT_POSITION(10);

-- Statement 59
SELECT (CASE WHEN 10 > 0 THEN 10 - 1 ELSE ABS(10) END) % 32768;

-- Statement 60
SELECT BITMAP_BUCKET_NUMBER(32769);

-- Statement 61
SELECT BITMAP_CONSTRUCT_AGG(value);

-- Statement 62
SELECT BITMAP_CONSTRUCT_AGG(v) FROM t;

-- Statement 63
SELECT (SELECT CASE WHEN l IS NULL OR LENGTH(l) = 0 THEN NULL WHEN LENGTH(l) <> LENGTH(LIST_FILTER(l, __v -> __v BETWEEN 0 AND 32767)) THEN NULL WHEN LENGTH(l) < 5 THEN UNHEX(PRINTF('%04X', LENGTH(l)) || h || REPEAT('00', GREATEST(0, 4 - LENGTH(l)) * 2)) ELSE UNHEX('08000000000000000000' || h) END FROM (SELECT l, COALESCE(LIST_REDUCE(LIST_TRANSFORM(l, __x -> PRINTF('%02X%02X', CAST(__x AS INT) & 255, (CAST(__x AS INT) >> 8) & 255)), (__a, __b) -> __a || __b, ''), '') AS h FROM (SELECT LIST_SORT(LIST_DISTINCT(LIST(v) FILTER(WHERE NOT v IS NULL))) AS l))) FROM t;

-- Statement 64
SELECT BITMAP_COUNT(BITMAP_CONSTRUCT_AGG(value)) FROM TABLE(FLATTEN(INPUT => ARRAY_CONSTRUCT(1, 2, 3, 5)));

-- Statement 65
SELECT BITMAP_COUNT(BITMAP_CONSTRUCT_AGG(value)) FROM TABLE(FLATTEN(INPUT => [1, 2, 3, 5]));

-- Statement 66
SELECT ARRAY_MAX([1, 2, 3]);

-- Statement 67
SELECT LIST_MAX([1, 2, 3]);

-- Statement 68
SELECT ARRAY_MIN([1, 2, 3]);

-- Statement 69
SELECT LIST_MIN([1, 2, 3]);

-- Statement 70
SELECT BOOLAND(1, -2);

-- Statement 71
SELECT BOOLXOR(2, 0);

-- Statement 72
SELECT BOOLOR(1, 0);

-- Statement 73
SELECT TO_BOOLEAN('true');

-- Statement 74
SELECT TO_BOOLEAN(1);

-- Statement 75
SELECT TO_VARIANT(123);

-- Statement 76
SELECT IS_NULL_VALUE(GET_PATH(payload, 'field'));

-- Statement 77
SELECT RTRIMMED_LENGTH(' ABCD ');

-- Statement 78
SELECT HEX_DECODE_STRING('48656C6C6F');

-- Statement 79
SELECT HEX_ENCODE('Hello World');

-- Statement 80
SELECT HEX_ENCODE('Hello World', 1);

-- Statement 81
SELECT HEX_ENCODE('Hello World', 0);

-- Statement 82
SELECT IFNULL(col1, col2);

-- Statement 83
SELECT COALESCE(col1, col2);

-- Statement 84
SELECT NEXT_DAY('2025-10-15', 'FRIDAY');

-- Statement 85
SELECT NVL2(col1, col2, col3);

-- Statement 86
SELECT NVL(col1, col2);

-- Statement 87
SELECT CHR(8364);

-- Statement 88
SELECT CHECK_JSON(x);

-- Statement 89
SELECT CASE WHEN x IS NULL OR x = '' OR JSON_VALID(x) THEN NULL ELSE 'Invalid JSON' END;

-- Statement 90
SELECT CHECK_JSON(\'{"key": "value"}\');

-- Statement 91
SELECT CHECK_XML('<root><key attribute=\"attr\">value</key></root>');

-- Statement 92
SELECT CHECK_XML('<root><key attribute=\"attr\">value</key></root>', TRUE);

-- Statement 93
SELECT COMPRESS('Hello World', 'ZLIB');

-- Statement 94
SELECT DECOMPRESS_BINARY('compressed_data', 'SNAPPY');

-- Statement 95
SELECT DECOMPRESS_STRING('compressed_data', 'ZSTD');

-- Statement 96
SELECT LPAD('Hello', 10, '*');

-- Statement 97
SELECT LPAD(tbl.bin_col, 10);

-- Statement 98
SELECT RPAD('Hello', 10, '*');

-- Statement 99
SELECT RPAD(tbl.bin_col, 10);

-- Statement 100
SELECT RPAD('test', 10, 'ab');

-- Statement 101
SELECT RPAD('data', 8);

-- Statement 102
SELECT RPAD('data', 8, ' ');

-- Statement 103
SELECT RPAD('exact', 5, '*');

-- Statement 104
SELECT RPAD(TO_BINARY('Hi', 'UTF8'), 10, TO_BINARY('_', 'UTF8'));

-- Statement 105
SELECT ENCODE('Hi') || REPEAT(ENCODE('_'), GREATEST(0, 10 - OCTET_LENGTH(ENCODE('Hi'))));

-- Statement 106
SELECT SOUNDEX(column_name);

-- Statement 107
SELECT SOUNDEX_P123(column_name);

-- Statement 108
SELECT ABS(x);

-- Statement 109
SELECT ASIN(0.5);

-- Statement 110
SELECT ASINH(0.5);

-- Statement 111
SELECT ATAN(0.5);

-- Statement 112
SELECT ATAN2(0.5, 0.3);

-- Statement 113
SELECT ATANH(0.5);

-- Statement 114
SELECT CBRT(27.0);

-- Statement 115
SELECT POW(2, 3);

-- Statement 116
SELECT POWER(2, 3);

-- Statement 117
SELECT POW(2.5, 3.0);

-- Statement 118
SELECT POWER(2.5, 3.0);

-- Statement 119
SELECT SQUARE(2.5);

-- Statement 120
SELECT POWER(2.5, 2);

-- Statement 121
SELECT SIGN(x);

-- Statement 122
SELECT COSH(1.5);

-- Statement 123
SELECT TANH(0.5);

-- Statement 124
SELECT TRANSLATE(column_name, 'abc', '123');

-- Statement 125
SELECT UNICODE(column_name);

-- Statement 126
SELECT WIDTH_BUCKET(col, 0, 100, 10);

-- Statement 127
SELECT SPLIT_PART('11.22.33', '.', 2);

-- Statement 128
SELECT CASE WHEN '.' = '' THEN (CASE WHEN (CASE WHEN 2 = 0 THEN 1 ELSE 2 END) = 1 OR (CASE WHEN 2 = 0 THEN 1 ELSE 2 END) = -1 THEN '11.22.33' ELSE '' END) ELSE SPLIT_PART('11.22.33', '.', (CASE WHEN 2 = 0 THEN 1 ELSE 2 END)) END;

-- Statement 129
SELECT SPLIT('127.0.0.1', '.');

-- Statement 130
SELECT CASE WHEN '.' IS NULL THEN NULL WHEN '.' = '' THEN ['127.0.0.1'] ELSE STR_SPLIT('127.0.0.1', '.') END;

-- Statement 131
SELECT PI();

-- Statement 132
SELECT DEGREES(PI() / 3);

-- Statement 133
SELECT DEGREES(1);

-- Statement 134
SELECT RADIANS(180);

-- Statement 135
SELECT REGR_VALX(y, x);

-- Statement 136
SELECT CASE WHEN y IS NULL THEN CAST(NULL AS DOUBLE) ELSE x END;

-- Statement 137
SELECT REGR_VALY(y, x);

-- Statement 138
SELECT CASE WHEN x IS NULL THEN CAST(NULL AS DOUBLE) ELSE y END;

-- Statement 139
SELECT REGR_AVGX(y, x);

-- Statement 140
SELECT REGR_AVGY(y, x);

-- Statement 141
SELECT REGR_COUNT(y, x);

-- Statement 142
SELECT REGR_INTERCEPT(y, x);

-- Statement 143
SELECT REGR_R2(y, x);

-- Statement 144
SELECT REGR_SXX(y, x);

-- Statement 145
SELECT REGR_SXY(y, x);

-- Statement 146
SELECT REGR_SYY(y, x);

-- Statement 147
SELECT REGR_SLOPE(y, x);

-- Statement 148
SELECT IS_ARRAY(PARSE_JSON('[1,2,3]'));

-- Statement 149
SELECT JSON_TYPE(JSON('[1,2,3]')) = 'ARRAY';

-- Statement 150
SELECT IFF(x > 5, 10, 20);

-- Statement 151
SELECT CASE WHEN x > 5 THEN 10 ELSE 20 END;

-- Statement 152
SELECT IFF(col IS NULL, 0, col);

-- Statement 153
SELECT CASE WHEN col IS NULL THEN 0 ELSE col END;

-- Statement 154
SELECT VAR_SAMP(x);

-- Statement 155
SELECT VARIANCE(x);

-- Statement 156
SELECT GREATEST(1, 2);

-- Statement 157
SELECT CASE WHEN 1 IS NULL OR 2 IS NULL THEN NULL ELSE GREATEST(1, 2) END;

-- Statement 158
SELECT GREATEST_IGNORE_NULLS(1, 2);

-- Statement 159
SELECT LEAST(1, 2);

-- Statement 160
SELECT CASE WHEN 1 IS NULL OR 2 IS NULL THEN NULL ELSE LEAST(1, 2) END;

-- Statement 161
SELECT LEAST_IGNORE_NULLS(1, 2);

-- Statement 162
SELECT VAR_POP(x);

-- Statement 163
SELECT VARIANCE_POP(x);

-- Statement 164
SELECT SKEW(a);

-- Statement 165
SELECT SKEWNESS(a);

-- Statement 166
SELECT RANDOM();

-- Statement 167
SELECT CAST(-9.223372036854776E+18 + RANDOM() * (9.223372036854776e+18 - -9.223372036854776E+18) AS BIGINT);

-- Statement 168
SELECT RANDOM(123);

-- Statement 169
SELECT RANDSTR(123, 456);

-- Statement 170
SELECT RANDSTR(123, RANDOM());

-- Statement 171
SELECT NORMAL(0, 1, RANDOM());

-- Statement 172
SELECT RANDSTR(10, 123);

-- Statement 173
SELECT (SELECT LISTAGG(SUBSTRING('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz', 1 + CAST(FLOOR(random_value * 62) AS INT), 1), '') FROM (SELECT (ABS(HASH(i + 123)) % 1000) / 1000.0 AS random_value FROM RANGE(10) AS t(i)));

-- Statement 174
SELECT RANDSTR(10, RANDOM(123));

-- Statement 175
SELECT RANDSTR(10, RANDOM());

-- Statement 176
SELECT (SELECT LISTAGG(SUBSTRING('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz', 1 + CAST(FLOOR(random_value * 62) AS INT), 1), '') FROM (SELECT (ABS(HASH(i + CAST(-9.223372036854776E+18 + RANDOM() * (9.223372036854776e+18 - -9.223372036854776E+18) AS BIGINT))) % 1000) / 1000.0 AS random_value FROM RANGE(10) AS t(i)));

-- Statement 177
SELECT BOOLNOT(0);

-- Statement 178
SELECT NOT (ROUND(0, 0));

-- Statement 179
SELECT ZIPF(1, 10, 1234);

-- Statement 180
SELECT (WITH rand AS (SELECT (ABS(HASH(1234)) % 1000000) / 1000000.0 AS r), weights AS (SELECT i, 1.0 / POWER(i, 1) AS w FROM RANGE(1, 10 + 1) AS t(i)), cdf AS (SELECT i, SUM(w) OVER (ORDER BY i NULLS FIRST) / SUM(w) OVER () AS p FROM weights) SELECT MIN(i) FROM cdf WHERE p >= (SELECT r FROM rand));

-- Statement 181
SELECT ZIPF(2, 100, RANDOM());

-- Statement 182
SELECT (WITH rand AS (SELECT RANDOM() AS r), weights AS (SELECT i, 1.0 / POWER(i, 2) AS w FROM RANGE(1, 100 + 1) AS t(i)), cdf AS (SELECT i, SUM(w) OVER (ORDER BY i NULLS FIRST) / SUM(w) OVER () AS p FROM weights) SELECT MIN(i) FROM cdf WHERE p >= (SELECT r FROM rand));

-- Statement 183
SELECT GROUPING_ID(a, b) AS g_id FROM x GROUP BY ROLLUP (a, b);

-- Statement 184
SELECT XMLGET(object_col, 'level2');

-- Statement 185
SELECT XMLGET(object_col, 'level3', 1);

-- Statement 186
SELECT {*} FROM my_table;

-- Statement 187
SELECT {my_table.*} FROM my_table;

-- Statement 188
SELECT {* ILIKE 'col1%'} FROM my_table;

-- Statement 189
SELECT {* EXCLUDE (col1)} FROM my_table;

-- Statement 190
SELECT {* EXCLUDE (col1, col2)} FROM my_table;

-- Statement 191
SELECT a, b, COUNT(*) FROM x GROUP BY ALL LIMIT 100;

-- Statement 192
INSERT INTO test VALUES (x'48FAF43B0AFCEF9B63EE3A93EE2AC2');

-- Statement 193
SELECT STAR(tbl, exclude := [foo]);

-- Statement 194
SELECT CAST([1, 2, 3] AS VECTOR(FLOAT, 3));

-- Statement 195
SELECT VECTOR_COSINE_SIMILARITY(a, b);

-- Statement 196
SELECT VECTOR_INNER_PRODUCT(a, b);

-- Statement 197
SELECT VECTOR_L1_DISTANCE(a, b);

-- Statement 198
SELECT VECTOR_L2_DISTANCE(a, b);

-- Statement 199
SELECT CONNECT_BY_ROOT test AS test_column_alias;

-- Statement 200
SELECT number;

-- Statement 201
SELECT rename, replace;

-- Statement 202
SELECT TIMEADD(HOUR, 2, CAST('09:05:03' AS TIME));

-- Statement 203
SELECT CAST(OBJECT_CONSTRUCT('a', 1) AS MAP(VARCHAR, INT));

-- Statement 204
SELECT MAP_CAT(CAST(col AS MAP(VARCHAR, VARCHAR)), CAST(col AS MAP(VARCHAR, VARCHAR)));

-- Statement 205
SELECT MAP_CAT(CAST(m1 AS MAP(VARCHAR, INT)), CAST(m2 AS MAP(VARCHAR, INT)));

-- Statement 206
SELECT CASE WHEN CAST(m1 AS MAP(TEXT, INT)) IS NULL OR CAST(m2 AS MAP(TEXT, INT)) IS NULL THEN NULL ELSE MAP_FROM_ENTRIES(LIST_FILTER(LIST_TRANSFORM(LIST_DISTINCT(LIST_CONCAT(MAP_KEYS(CAST(m1 AS MAP(TEXT, INT))), MAP_KEYS(CAST(m2 AS MAP(TEXT, INT))))), __k -> STRUCT_PACK(key := __k, value := COALESCE(CAST(m2 AS MAP(TEXT, INT))[__k], CAST(m1 AS MAP(TEXT, INT))[__k]))), __x -> NOT __x.value IS NULL)) END;

-- Statement 207
SELECT MAP_CAT(CAST(OBJECT_CONSTRUCT() AS MAP(VARCHAR, INT)), CAST(OBJECT_CONSTRUCT('a', 1) AS MAP(VARCHAR, INT)));

-- Statement 208
SELECT CASE WHEN CAST(MAP() AS MAP(TEXT, INT)) IS NULL OR CAST({'a': 1} AS MAP(TEXT, INT)) IS NULL THEN NULL ELSE MAP_FROM_ENTRIES(LIST_FILTER(LIST_TRANSFORM(LIST_DISTINCT(LIST_CONCAT(MAP_KEYS(CAST(MAP() AS MAP(TEXT, INT))), MAP_KEYS(CAST({'a': 1} AS MAP(TEXT, INT))))), __k -> STRUCT_PACK(key := __k, value := COALESCE(CAST({'a': 1} AS MAP(TEXT, INT))[__k], CAST(MAP() AS MAP(TEXT, INT))[__k]))), __x -> NOT __x.value IS NULL)) END;

-- Statement 209
SELECT MAP_CONTAINS_KEY('k1', CAST(col AS MAP(VARCHAR, VARCHAR)));

-- Statement 210
SELECT MAP_DELETE(CAST(col AS MAP(VARCHAR, VARCHAR)), 'k1');

-- Statement 211
SELECT MAP_INSERT(CAST(col AS MAP(VARCHAR, VARCHAR)), 'b', '2');

-- Statement 212
SELECT MAP_KEYS(CAST(col AS MAP(VARCHAR, VARCHAR)));

-- Statement 213
SELECT MAP_PICK(CAST(col AS MAP(VARCHAR, VARCHAR)), 'a', 'c');

-- Statement 214
SELECT MAP_SIZE(CAST(col AS MAP(VARCHAR, VARCHAR)));

-- Statement 215
SELECT CAST(OBJECT_CONSTRUCT('a', 1) AS OBJECT(a CHAR NOT NULL));

-- Statement 216
SELECT CAST([1, 2, 3] AS ARRAY(INT));

-- Statement 217
SELECT CAST(obj AS OBJECT(x CHAR) RENAME FIELDS);

-- Statement 218
SELECT CAST(obj AS OBJECT(x CHAR, y VARCHAR) ADD FIELDS);

-- Statement 219
SELECT TO_TIMESTAMP(123.4);

-- Statement 220
SELECT TO_TIMESTAMP(x) FROM t;

-- Statement 221
SELECT TO_TIMESTAMP_NTZ(x) FROM t;

-- Statement 222
SELECT TO_TIMESTAMP_LTZ(x) FROM t;

-- Statement 223
SELECT TO_TIMESTAMP_TZ(x) FROM t;

-- Statement 224
SELECT TIMESTAMP_FROM_PARTS(2024, 5, 9, 14, 30, 45);

-- Statement 225
SELECT TIMESTAMP_FROM_PARTS(2024, 5, 9, 14, 30, 45, 123);

-- Statement 226
SELECT TIMESTAMP_LTZ_FROM_PARTS(2013, 4, 5, 12, 00, 00);

-- Statement 227
SELECT TIMESTAMP_TZ_FROM_PARTS(2013, 4, 5, 12, 00, 00);

-- Statement 228
SELECT TIMESTAMP_TZ_FROM_PARTS(2013, 4, 5, 12, 00, 00, 0, 'America/Los_Angeles');

-- Statement 229
SELECT TIMESTAMP_FROM_PARTS(CAST('2024-05-09' AS DATE), CAST('14:30:45' AS TIME));

-- Statement 230
SELECT TIMESTAMP_NTZ_FROM_PARTS(TO_DATE('2013-04-05'), TO_TIME('12:00:00'));

-- Statement 231
SELECT TIMESTAMP_FROM_PARTS(CAST('2013-04-05' AS DATE), CAST('12:00:00' AS TIME));

-- Statement 232
SELECT TIMESTAMP_NTZ_FROM_PARTS(2013, 4, 5, 12, 00, 00, 987654321);

-- Statement 233
SELECT TIMESTAMP_FROM_PARTS(2013, 4, 5, 12, 00, 00, 987654321);

-- Statement 234
SELECT DATE_FROM_PARTS(1977, 8, 7);

-- Statement 235
SELECT GET_PATH(v, 'attr[0].name') FROM vartab;

-- Statement 236
SELECT TO_ARRAY(CAST(x AS ARRAY));

-- Statement 237
SELECT TO_ARRAY(CAST(['test'] AS VARIANT));

-- Statement 238
SELECT ARRAY_UNIQUE_AGG(x);

-- Statement 239
SELECT ARRAY_UNIQUE_AGG(col) FROM t;

-- Statement 240
SELECT LIST(DISTINCT col) FILTER(WHERE NOT col IS NULL) FROM t;

-- Statement 241
SELECT ARRAY_UNIQUE_AGG(col) OVER (PARTITION BY grp) FROM t;

-- Statement 242
SELECT LIST(DISTINCT col) FILTER(WHERE NOT col IS NULL) OVER (PARTITION BY grp) FROM t;

-- Statement 243
SELECT ARRAY_AGG(col) FROM t;

-- Statement 244
SELECT ARRAY_AGG(col) FILTER(WHERE col IS NOT NULL) FROM t;

-- Statement 245
SELECT ARRAY_DISTINCT(col);

-- Statement 246
SELECT CASE WHEN ARRAY_LENGTH(col) <> LIST_COUNT(col) THEN LIST_APPEND(LIST_DISTINCT(LIST_FILTER(col, _u -> NOT _u IS NULL)), NULL) ELSE LIST_DISTINCT(col) END;

-- Statement 247
SELECT ARRAY_APPEND([1, 2, 3], 4);

-- Statement 248
SELECT ARRAY_CAT([1, 2], [3, 4]);

-- Statement 249
SELECT ARRAY_PREPEND([2, 3, 4], 1);

-- Statement 250
SELECT ARRAY_REMOVE([1, 2, 3], 2);

-- Statement 251
SELECT ARRAYS_ZIP([1, 2, 3]);

-- Statement 252
SELECT ARRAYS_ZIP([1, 2, 3], ['a', 'b', 'c'], [10, 20, 30]);

-- Statement 253
SELECT AI_AGG(review, 'Summarize the reviews');

-- Statement 254
SELECT AI_SUMMARIZE_AGG(review);

-- Statement 255
SELECT AI_CLASSIFY('text', ['travel', 'cooking']);

-- Statement 256
SELECT OBJECT_CONSTRUCT();

-- Statement 257
SELECT CURRENT_ACCOUNT();

-- Statement 258
SELECT CURRENT_ACCOUNT_NAME();

-- Statement 259
SELECT CURRENT_AVAILABLE_ROLES();

-- Statement 260
SELECT CURRENT_CLIENT();

-- Statement 261
SELECT CURRENT_IP_ADDRESS();

-- Statement 262
SELECT CURRENT_DATABASE();

-- Statement 263
SELECT CURRENT_SCHEMAS();

-- Statement 264
SELECT CURRENT_SECONDARY_ROLES();

-- Statement 265
SELECT CURRENT_SESSION();

-- Statement 266
SELECT CURRENT_STATEMENT();

-- Statement 267
SELECT CURRENT_VERSION();

-- Statement 268
SELECT CURRENT_TRANSACTION();

-- Statement 269
SELECT CURRENT_WAREHOUSE();

-- Statement 270
SELECT CURRENT_ORGANIZATION_USER();

-- Statement 271
SELECT CURRENT_REGION();

-- Statement 272
SELECT CURRENT_ROLE();

-- Statement 273
SELECT CURRENT_ROLE_TYPE();

-- Statement 274
SELECT DAY(CURRENT_TIMESTAMP());

-- Statement 275
SELECT DAYOFMONTH(CURRENT_TIMESTAMP());

-- Statement 276
SELECT DAYOFYEAR(CURRENT_TIMESTAMP());

-- Statement 277
SELECT MONTH(CURRENT_TIMESTAMP());

-- Statement 278
SELECT QUARTER(CURRENT_TIMESTAMP());

-- Statement 279
SELECT WEEK(CURRENT_TIMESTAMP());

-- Statement 280
SELECT WEEKISO(CURRENT_TIMESTAMP());

-- Statement 281
SELECT YEAR(CURRENT_TIMESTAMP());

-- Statement 282
SELECT YEAROFWEEK(CURRENT_TIMESTAMP());

-- Statement 283
SELECT YEAROFWEEKISO(CURRENT_TIMESTAMP());

-- Statement 284
SELECT DAYOFWEEKISO('2024-01-15'::DATE);

-- Statement 285
SELECT DAYOFWEEKISO(CAST('2024-01-15' AS DATE));

-- Statement 286
SELECT ISODOW(CAST('2024-01-15' AS DATE));

-- Statement 287
SELECT YEAROFWEEK('2024-12-31'::DATE);

-- Statement 288
SELECT YEAROFWEEK(CAST('2024-12-31' AS DATE));

-- Statement 289
SELECT EXTRACT(ISOYEAR FROM CAST('2024-12-31' AS DATE));

-- Statement 290
SELECT YEAROFWEEKISO('2024-12-31'::DATE);

-- Statement 291
SELECT YEAROFWEEKISO(CAST('2024-12-31' AS DATE));

-- Statement 292
SELECT WEEKISO('2024-01-15'::DATE);

-- Statement 293
SELECT WEEKISO(CAST('2024-01-15' AS DATE));

-- Statement 294
SELECT WEEKOFYEAR(CAST('2024-01-15' AS DATE));

-- Statement 295
SELECT SUM(amount) FROM mytable GROUP BY ALL;

-- Statement 296
SELECT STDDEV(x);

-- Statement 297
SELECT STDDEV(x) OVER (PARTITION BY 1);

-- Statement 298
SELECT STDDEV_POP(x);

-- Statement 299
SELECT STDDEV_POP(x) OVER (PARTITION BY 1);

-- Statement 300
SELECT STDDEV_SAMP(x);

-- Statement 301
SELECT STDDEV_SAMP(x) OVER (PARTITION BY 1);

-- Statement 302
SELECT KURTOSIS(x);

-- Statement 303
SELECT KURTOSIS(x) OVER (PARTITION BY 1);

-- Statement 304
WITH x AS (SELECT 1 AS foo) SELECT foo FROM IDENTIFIER('x');

-- Statement 305
WITH x AS (SELECT 1 AS foo) SELECT IDENTIFIER('foo') FROM x;

-- Statement 306
SELECT IDENTIFIER($my_function_name)();

-- Statement 307
SELECT IDENTIFIER('speed_of_light')();

-- Statement 308
SELECT IDENTIFIER('my_func')(1, 2);

-- Statement 309
SELECT CAST('2021-01-01' AS DATE) + INTERVAL '1 DAY';

-- Statement 310
SELECT HLL(*);

-- Statement 311
SELECT HLL(a);

-- Statement 312
SELECT HLL(DISTINCT t.a);

-- Statement 313
SELECT HLL(a, b, c);

-- Statement 314
SELECT HLL(DISTINCT a, b, c);

-- Statement 315
SELECT REGEXP_LIKE(a, b, c);

-- Statement 316
SELECT CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', col);

-- Statement 317
SELECT CURRENT_ORGANIZATION_NAME();

-- Statement 318
SELECT MATCH_CONDITION;

-- Statement 319
SELECT OBJECT_AGG(key, value) FROM tbl;

-- Statement 320
SELECT TO_CHAR(CAST('12:05:05' AS TIME));

-- Statement 321
SELECT TRIM(COALESCE(TO_CHAR(CAST(c AS TIME)), '')) FROM t;

-- Statement 322
SELECT GET_PATH(PARSE_JSON(foo), 'bar');

-- Statement 323
SELECT PARSE_IP('192.168.1.1', 'INET');

-- Statement 324
SELECT PARSE_IP('192.168.1.1', 'INET', 0);

-- Statement 325
SELECT GET_PATH(foo, 'bar');

-- Statement 326
SELECT a, exclude, b FROM xxx;

-- Statement 327
SELECT ARRAY_SORT(x, TRUE, FALSE);

-- Statement 328
SELECT ARRAY_SORT(x);

-- Statement 329
SELECT LIST_SORT(x);

-- Statement 330
SELECT ARRAY_SORT(x, FALSE);

-- Statement 331
SELECT LIST_SORT(x, 'DESC', 'NULLS FIRST');

-- Statement 332
SELECT ARRAY_SORT(x, foo, TRUE);

-- Statement 333
SELECT LIST_SORT(x, foo, 'NULLS FIRST');

-- Statement 334
SELECT BOOLXOR_AGG(col) FROM tbl;

-- Statement 335
SELECT PERCENTILE_DISC(0.9) WITHIN GROUP (ORDER BY col) OVER (PARTITION BY category);

-- Statement 336
SELECT DATEADD(DAY, -7, DATEADD(t.m, 1, CAST('2023-01-03' AS DATE))) FROM (SELECT 'month' AS m) AS t;

-- Statement 337
SELECT STRTOK('a$b/cg', '$/.');

-- Statement 338
SELECT STRTOK('a$b/cg', '$/.', 1);

-- Statement 339
SELECT CASE WHEN '$/.' = '' AND 'a$b/cg' = '' THEN NULL WHEN '$/.' = '' AND 1 = 1 THEN 'a$b/cg' WHEN '$/.' = '' THEN NULL WHEN 1 < 0 THEN NULL WHEN 'a$b/cg' IS NULL OR '$/.' IS NULL OR 1 IS NULL THEN NULL ELSE LIST_FILTER(REGEXP_SPLIT_TO_ARRAY('a$b/cg', CASE WHEN '$/.' = '' THEN '' ELSE '[' || REGEXP_REPLACE('$/.', '([\[\]^.\-*+?(){}|$\\])', '\\\1', 'g') || ']' END), x -> NOT x = '')[1] END;

-- Statement 340
SELECT STRTOK('ab');

-- Statement 341
SELECT STRTOK('ab', ' ', 1);

-- Statement 342
SELECT CASE WHEN ' ' = '' AND 'ab' = '' THEN NULL WHEN ' ' = '' AND 1 = 1 THEN 'ab' WHEN ' ' = '' THEN NULL WHEN 1 < 0 THEN NULL WHEN 'ab' IS NULL OR ' ' IS NULL OR 1 IS NULL THEN NULL ELSE LIST_FILTER(REGEXP_SPLIT_TO_ARRAY('ab', CASE WHEN ' ' = '' THEN '' ELSE '[' || REGEXP_REPLACE(' ', '([\[\]^.\-*+?(){}|$\\])', '\\\1', 'g') || ']' END), x -> NOT x = '')[1] END;

-- Statement 343
SELECT FILE_URL FROM DIRECTORY(@mystage) WHERE SIZE > 100000;

-- Statement 344
SELECT AI_CLASSIFY('text', ['travel', 'cooking'], OBJECT_CONSTRUCT('output_mode', 'multi'));

-- Statement 345
SELECT * FROM table AT (TIMESTAMP => '2024-07-24') UNPIVOT(a FOR b IN (c)) AS pivot_table;

-- Statement 346
SELECT * FROM quarterly_sales PIVOT(SUM(amount) FOR quarter IN ('2023_Q1', '2023_Q2', '2023_Q3', '2023_Q4', '2024_Q1') DEFAULT ON NULL (0)) ORDER BY empid;

-- Statement 347
SELECT * FROM quarterly_sales PIVOT(SUM(amount) FOR quarter IN (SELECT DISTINCT quarter FROM ad_campaign_types_by_quarter WHERE television = TRUE ORDER BY quarter)) ORDER BY empid;

-- Statement 348
SELECT * FROM quarterly_sales PIVOT(SUM(amount) FOR quarter IN (ANY ORDER BY quarter)) ORDER BY empid;

-- Statement 349
SELECT * FROM quarterly_sales PIVOT(SUM(amount) FOR quarter IN (ANY)) ORDER BY empid;

-- Statement 350
MERGE INTO my_db AS ids USING (SELECT new_id FROM my_model WHERE NOT col IS NULL) AS new_ids ON ids.type = new_ids.type AND ids.source = new_ids.source WHEN NOT MATCHED THEN INSERT VALUES (new_ids.new_id);

-- Statement 351
INSERT OVERWRITE TABLE t SELECT 1;

-- Statement 352
INSERT OVERWRITE INTO t SELECT 1;

-- Statement 353
SELECT * FROM DATA AS DATA_L ASOF JOIN DATA AS DATA_R MATCH_CONDITION (DATA_L.VAL > DATA_R.VAL) ON DATA_L.ID = DATA_R.ID;

-- Statement 354
SELECT TO_TIMESTAMP('2025-01-16T14:45:30.123+0500', 'yyyy-mm-DDThh24:mi:ss.ff9tzhtzm');

-- Statement 355
SELECT * REPLACE (CAST(col AS TEXT) AS scol) FROM t;

-- Statement 356
SELECT * REPLACE (CAST(col AS VARCHAR) AS scol) FROM t;

-- Statement 357
SELECT 1 put;

-- Statement 358
SELECT 1 AS put;

-- Statement 359
SELECT 1 get;

-- Statement 360
SELECT 1 AS get;

-- Statement 361
WITH t (SELECT 1 AS c) SELECT c FROM t;

-- Statement 362
WITH t AS (SELECT 1 AS c) SELECT c FROM t;

-- Statement 363
SELECT * FROM s WHERE c NOT IN (1, 2, 3);

-- Statement 364
SELECT * FROM s WHERE NOT c IN (1, 2, 3);

-- Statement 365
SELECT * FROM s WHERE c NOT IN (SELECT * FROM t);

-- Statement 366
SELECT * FROM s WHERE c <> ALL (SELECT * FROM t);

-- Statement 367
SELECT * FROM t1 INNER JOIN t2 USING (t1.col);

-- Statement 368
SELECT * FROM t1 INNER JOIN t2 USING (col);

-- Statement 369
SELECT a:from::STRING, a:from || ' test';

-- Statement 370
SELECT CAST(GET_PATH(a, 'from') AS VARCHAR), GET_PATH(a, 'from') || ' test';

-- Statement 371
SELECT a:select;

-- Statement 372
SELECT GET_PATH(a, 'select');

-- Statement 373
SELECT GET_PATH(PARSE_JSON('{"y": [{"z": 1}]}'), 'y[0]:z');

-- Statement 374
SELECT GET_PATH(PARSE_JSON('{"y": [{"z": 1}]}'), 'y[0].z');

-- Statement 375
SELECT p FROM t WHERE p:val NOT IN ('2');

-- Statement 376
SELECT p FROM t WHERE NOT GET_PATH(p, 'val') IN ('2');

-- Statement 377
SELECT PARSE_JSON('{"x": "hello"}'):x LIKE 'hello';

-- Statement 378
SELECT GET_PATH(PARSE_JSON('{"x": "hello"}'), 'x') LIKE 'hello';

-- Statement 379
SELECT data:x LIKE 'hello' FROM some_table;

-- Statement 380
SELECT GET_PATH(data, 'x') LIKE 'hello' FROM some_table;

-- Statement 381
SELECT SUM({ fn CONVERT(123, SQL_DOUBLE) });

-- Statement 382
SELECT SUM(CAST(123 AS DOUBLE));

-- Statement 383
SELECT SUM({ fn CONVERT(123, SQL_VARCHAR) });

-- Statement 384
SELECT SUM(CAST(123 AS VARCHAR));

-- Statement 385
SELECT TIMESTAMPFROMPARTS(d, t);

-- Statement 386
SELECT TIMESTAMP_FROM_PARTS(d, t);

-- Statement 387
SELECT v:attr[0].name FROM vartab;

-- Statement 388
SELECT v:"fruit" FROM vartab;

-- Statement 389
SELECT GET_PATH(v, 'fruit') FROM vartab;

-- Statement 390
SELECT PARSE_JSON('{"food":{"fruit":"banana"}}'):food.fruit::VARCHAR;

-- Statement 391
SELECT CAST(GET_PATH(PARSE_JSON('{"food":{"fruit":"banana"}}'), 'food.fruit') AS VARCHAR);

-- Statement 392
SELECT * FROM t, UNNEST(x) WITH ORDINALITY;

-- Statement 393
SELECT * FROM t, TABLE(FLATTEN(INPUT => x)) AS _t0(seq, key, path, index, value, this);

-- Statement 394
SELECT state, city, SUM(retail_price * quantity) AS gross_revenue FROM sales GROUP BY ALL;

-- Statement 395
SELECT * FROM foo window;

-- Statement 396
SELECT * FROM foo AS window;

-- Statement 397
SELECT RLIKE(a, $$regular expression with \ characters: \d{2}-\d{3}-\d{4}$$, 'i') FROM log_source;

-- Statement 398
SELECT REGEXP_LIKE(a, 'regular expression with \\ characters: \\d{2}-\\d{3}-\\d{4}', 'i') FROM log_source;

-- Statement 399
SELECT $$a ' \ \t \x21 z $ $$;

-- Statement 400
SELECT 'a \' \\ \\t \\x21 z $ ';

-- Statement 401
SELECT $$a\$b$$;

-- Statement 402
SELECT 'a\\$b';

-- Statement 403
SELECT $$a\$$;

-- Statement 404
SELECT 'a\\';

-- Statement 405
SELECT {'test': 'best'}::VARIANT;

-- Statement 406
SELECT CAST(OBJECT_CONSTRUCT('test', 'best') AS VARIANT);

-- Statement 407
SELECT {fn DAYNAME('2022-5-13')};

-- Statement 408
SELECT DAYNAME('2022-5-13');

-- Statement 409
SELECT {fn LOG(5)};

-- Statement 410
SELECT LN(5);

-- Statement 411
SELECT {fn CEILING(5.3)};

-- Statement 412
SELECT CEIL(5.3);

-- Statement 413
SELECT CEIL(3.14);

-- Statement 414
SELECT CEIL(3.14, 1);

-- Statement 415
SELECT DAYOFWEEK('2016-01-02T23:39:20.123-07:00'::TIMESTAMP);

-- Statement 416
SELECT DAYOFWEEK(CAST('2016-01-02T23:39:20.123-07:00' AS TIMESTAMP));

-- Statement 417
SELECT * FROM xxx WHERE col ilike '%Don''t%';

-- Statement 418
SELECT * FROM xxx WHERE col ILIKE '%Don\\'t%';

-- Statement 419
SELECT * EXCLUDE a, b FROM xxx;

-- Statement 420
SELECT * EXCLUDE (a), b FROM xxx;

-- Statement 421
SELECT * RENAME a AS b, c AS d FROM xxx;

-- Statement 422
SELECT * RENAME (a AS b), c AS d FROM xxx;

-- Statement 423
SELECT * FROM xxx, yyy, zzz,;

-- Statement 424
SELECT * FROM xxx, yyy, zzz;

-- Statement 425
SELECT * FROM xxx, yyy, zzz, WHERE foo = bar;

-- Statement 426
SELECT * FROM xxx, yyy, zzz WHERE foo = bar;

-- Statement 427
SELECT LTRIM(RTRIM(col)) FROM t1;

-- Statement 428
SELECT value['x'] AS x FROM TABLE(FLATTEN(INPUT => [OBJECT_CONSTRUCT('x', 'x')])) AS _t0(seq, key, path, index, value, this);

-- Statement 429
SELECT x FROM UNNEST([STRUCT('x' AS x)]);

-- Statement 430
SELECT value['x'] AS x, value['y'] AS y, value['z'] AS z FROM TABLE(FLATTEN(INPUT => [OBJECT_CONSTRUCT('x', 1, 'y', 2, 'z', 3)])) AS _t0(seq, key, path, index, value, this);

-- Statement 431
SELECT x, y, z FROM UNNEST([STRUCT(1 AS x, 2 AS y, 3 AS z)]);

-- Statement 432
SELECT u1['x'] AS x, u2['y'] AS y FROM TABLE(FLATTEN(INPUT => [OBJECT_CONSTRUCT('x', 1)])) AS _t0(seq, key, path, index, u1, this) CROSS JOIN TABLE(FLATTEN(INPUT => [OBJECT_CONSTRUCT('y', 2)])) AS _t1(seq, key, path, index, u2, this);

-- Statement 433
SELECT u1.x, u2.y FROM UNNEST([STRUCT(1 AS x)]) AS u1, UNNEST([STRUCT(2 AS y)]) AS u2;

-- Statement 434
SELECT t.id, value['name'] AS name, value['age'] AS age FROM t CROSS JOIN TABLE(FLATTEN(INPUT => [OBJECT_CONSTRUCT('name', 'John', 'age', 30)])) AS _t0(seq, key, path, index, value, this);

-- Statement 435
SELECT t.id, name, age FROM t, UNNEST([STRUCT('John' AS name, 30 AS age)]);

-- Statement 436
SELECT value FROM TABLE(FLATTEN(INPUT => [OBJECT_CONSTRUCT('x', 1)])) AS _t0(seq, key, path, index, value, this);

-- Statement 437
SELECT value FROM UNNEST([STRUCT(1 AS x)]) AS value;

-- Statement 438
SELECT t.col1, value['field1'] AS field1, other_col, value['field2'] AS field2 FROM t CROSS JOIN TABLE(FLATTEN(INPUT => [OBJECT_CONSTRUCT('field1', 'a', 'field2', 'b')])) AS _t0(seq, key, path, index, value, this);

-- Statement 439
SELECT t.col1, field1, other_col, field2 FROM t, UNNEST([STRUCT('a' AS field1, 'b' AS field2)]);

-- Statement 440
SELECT * FROM (SELECT value['x'] AS x FROM TABLE(FLATTEN(INPUT => [OBJECT_CONSTRUCT('x', 'value')])) AS _t0(seq, key, path, index, value, this));

-- Statement 441
SELECT * FROM (SELECT x FROM UNNEST([STRUCT('value' AS x)]));

-- Statement 442
SELECT value FROM TABLE(FLATTEN(INPUT => [1, 2, 3])) AS _t0(seq, key, path, index, value, this);

-- Statement 443
SELECT value FROM UNNEST([1, 2, 3]) AS value;

-- Statement 444
SELECT * FROM t1 AS t1 CROSS JOIN t2 AS t2 LEFT JOIN t3 AS t3 ON t1.a = t3.i;

-- Statement 445
SELECT * FROM t1 AS t1, t2 AS t2 LEFT JOIN t3 AS t3 ON t1.a = t3.i;

-- Statement 446
SELECT value['x'] AS x, yval, zval FROM TABLE(FLATTEN(INPUT => [OBJECT_CONSTRUCT('x', 'x', 'y', ['y1', 'y2', 'y3'], 'z', ['z1', 'z2', 'z3'])])) AS _t0(seq, key, path, index, value, this) CROSS JOIN TABLE(FLATTEN(INPUT => value['y'])) AS _t1(seq, key, path, index, yval, this) CROSS JOIN TABLE(FLATTEN(INPUT => value['z'])) AS _t2(seq, key, path, index, zval, this);

-- Statement 447
SELECT x, yval, zval FROM UNNEST([STRUCT('x' AS x, ['y1', 'y2', 'y3'] AS y, ['z1', 'z2', 'z3'] AS z)]), UNNEST(y) AS yval, UNNEST(z) AS zval;

-- Statement 448
SELECT _u['foo'] AS foo, bar, baz FROM TABLE(FLATTEN(INPUT => [OBJECT_CONSTRUCT('foo', 'x', 'bars', ['y', 'z'], 'bazs', ['w'])])) AS _t0(seq, key, path, index, _u, this) CROSS JOIN TABLE(FLATTEN(INPUT => _u['bars'])) AS _t1(seq, key, path, index, bar, this) CROSS JOIN TABLE(FLATTEN(INPUT => _u['bazs'])) AS _t2(seq, key, path, index, baz, this);

-- Statement 449
SELECT _u.foo, bar, baz FROM UNNEST([struct('x' AS foo, ['y', 'z'] AS bars, ['w'] AS bazs)]) AS _u, UNNEST(_u.bars) AS bar, UNNEST(_u.bazs) AS baz;

-- Statement 450
SELECT _u, _u['foo'] AS foo, _u['bar'] AS bar FROM TABLE(FLATTEN(INPUT => [OBJECT_CONSTRUCT('foo', 'x', 'bar', 'y')])) AS _t0(seq, key, path, index, _u, this);

-- Statement 451
select _u, _u.foo, _u.bar from unnest([struct('x' as foo, 'y' AS bar)]) as _u;

-- Statement 452
SELECT _u['foo'][0].bar FROM TABLE(FLATTEN(INPUT => [OBJECT_CONSTRUCT('foo', [OBJECT_CONSTRUCT('bar', 1)])])) AS _t0(seq, key, path, index, _u, this);

-- Statement 453
select _u.foo[0].bar from unnest([struct([struct(1 as bar)] as foo)]) as _u;

-- Statement 454
SELECT ARRAYS_OVERLAP(col1, col2);

-- Statement 455
SELECT (col1 && col2) OR (ARRAY_LENGTH(col1) <> LIST_COUNT(col1) AND ARRAY_LENGTH(col2) <> LIST_COUNT(col2));

-- Statement 456
SELECT ARRAY_INTERSECTION([1, 2], [2, 3]);

-- Statement 457
SELECT ARRAY_INTERSECT([1, 2], [2, 3]);

-- Statement 458
SELECT CASE WHEN [1, 2] IS NULL OR [2, 3] IS NULL THEN NULL ELSE LIST_TRANSFORM(LIST_FILTER(LIST_ZIP([1, 2], GENERATE_SERIES(1, LENGTH([1, 2]))), pair -> (LENGTH(LIST_FILTER([1, 2][1:pair[2]], e -> e IS NOT DISTINCT FROM pair[1])) <= LENGTH(LIST_FILTER([2, 3], e -> e IS NOT DISTINCT FROM pair[1])))), pair -> pair[1]) END;

-- Statement 459
SELECT TO_TIMESTAMP('2025-01-16 14:45:30.123', 'yyyy-mm-DD hh24:mi:ss.ff6');

-- Statement 460
SELECT STR_TO_TIME('2025-01-16 14:45:30.123', '%Y-%m-%d %H:%M:%S.%f');

-- Statement 461
SELECT TIME_FROM_PARTS(12, 34, 56);

-- Statement 462
SELECT MAKE_TIME(12, 34, 56);

-- Statement 463
SELECT TIME_FROM_PARTS(12, 34, 56, 987654321);

-- Statement 464
SELECT CAST('00:00:00' AS TIME) + INTERVAL ((12 * 3600) + (34 * 60) + 56 + (987654321 / 1000000000.0)) SECOND;

-- Statement 465
SELECT TIME_FROM_PARTS(0, 100, 0);

-- Statement 466
SELECT CAST('00:00:00' AS TIME) + INTERVAL ((0 * 3600) + (100 * 60) + 0) SECOND;

-- Statement 467
SELECT TIMESTAMPNTZFROMPARTS(2013, 4, 5, 12, 00, 00);

-- Statement 468
SELECT TIMESTAMP_FROM_PARTS(2013, 4, 5, 12, 00, 00);

-- Statement 469
SELECT MAKE_TIMESTAMP(2013, 4, 5, 12, 00, 00);

-- Statement 470
SELECT TIMESTAMP_NTZ_FROM_PARTS(2013, 4, 5, 12, 00, 00);

-- Statement 471
SELECT TIMESTAMP_FROM_PARTS(TO_DATE('2023-06-15'), TO_TIME('14:30:45'));

-- Statement 472
SELECT CAST('2023-06-15' AS DATE) + CAST('14:30:45' AS TIME);

-- Statement 473
SELECT TIMESTAMP_FROM_PARTS(CAST('2023-06-15' AS DATE), CAST('14:30:45' AS TIME));

-- Statement 474
SELECT TIMESTAMP_NTZ_FROM_PARTS(TO_DATE('2023-06-15'), TO_TIME('14:30:45'));

-- Statement 475
SELECT TIMESTAMP_LTZ_FROM_PARTS(2023, 6, 15, 14, 30, 45);

-- Statement 476
SELECT CAST(MAKE_TIMESTAMP(2023, 6, 15, 14, 30, 45) AS TIMESTAMPTZ);

-- Statement 477
SELECT TIMESTAMP_TZ_FROM_PARTS(2023, 6, 15, 14, 30, 45, 0, 'America/Los_Angeles');

-- Statement 478
SELECT MAKE_TIMESTAMP(2023, 6, 15, 14, 30, 45) AT TIME ZONE 'America/Los_Angeles';

-- Statement 479
WITH vartab(v) AS (select parse_json('[{"attr": [{"name": "banana"}]}]')) SELECT GET_PATH(v, '[0].attr[0].name') FROM vartab;

-- Statement 480
WITH vartab AS (SELECT PARSE_JSON('[{"attr": [{"name": "banana"}]}]') AS v) SELECT JSON_EXTRACT(v, '$[0].attr[0].name') FROM vartab;

-- Statement 481
WITH vartab(v) AS (SELECT JSON('[{"attr": [{"name": "banana"}]}]')) SELECT v -> '$[0].attr[0].name' FROM vartab;

-- Statement 482
WITH vartab(v) AS (SELECT '[{"attr": [{"name": "banana"}]}]') SELECT JSON_EXTRACT(v, '$[0].attr[0].name') FROM vartab;

-- Statement 483
WITH vartab(v) AS (SELECT JSON_PARSE('[{"attr": [{"name": "banana"}]}]')) SELECT JSON_EXTRACT(v, '$[0].attr[0].name') FROM vartab;

-- Statement 484
WITH vartab(v) AS (SELECT '[{"attr": [{"name": "banana"}]}]') SELECT ISNULL(JSON_QUERY(v, '$[0].attr[0].name'), JSON_VALUE(v, '$[0].attr[0].name')) FROM vartab;

-- Statement 485
WITH vartab(v) AS (select parse_json('{"attr": [{"name": "banana"}]}')) SELECT GET_PATH(v, 'attr[0].name') FROM vartab;

-- Statement 486
WITH vartab AS (SELECT PARSE_JSON('{"attr": [{"name": "banana"}]}') AS v) SELECT JSON_EXTRACT(v, '$.attr[0].name') FROM vartab;

-- Statement 487
WITH vartab(v) AS (SELECT JSON('{"attr": [{"name": "banana"}]}')) SELECT v -> '$.attr[0].name' FROM vartab;

-- Statement 488
WITH vartab(v) AS (SELECT '{"attr": [{"name": "banana"}]}') SELECT JSON_EXTRACT(v, '$.attr[0].name') FROM vartab;

-- Statement 489
WITH vartab(v) AS (SELECT JSON_PARSE('{"attr": [{"name": "banana"}]}')) SELECT JSON_EXTRACT(v, '$.attr[0].name') FROM vartab;

-- Statement 490
WITH vartab(v) AS (SELECT '{"attr": [{"name": "banana"}]}') SELECT ISNULL(JSON_QUERY(v, '$.attr[0].name'), JSON_VALUE(v, '$.attr[0].name')) FROM vartab;

-- Statement 491
SELECT PARSE_JSON('{"fruit":"banana"}'):fruit;

-- Statement 492
SELECT JSON_EXTRACT(PARSE_JSON('{"fruit":"banana"}'), '$.fruit');

-- Statement 493
SELECT JSON('{"fruit":"banana"}') -> '$.fruit';

-- Statement 494
SELECT JSON_EXTRACT('{"fruit":"banana"}', '$.fruit');

-- Statement 495
SELECT JSON_EXTRACT(JSON_PARSE('{"fruit":"banana"}'), '$.fruit');

-- Statement 496
SELECT GET_PATH(PARSE_JSON('{"fruit":"banana"}'), 'fruit');

-- Statement 497
SELECT GET_JSON_OBJECT('{"fruit":"banana"}', '$.fruit');

-- Statement 498
SELECT ISNULL(JSON_QUERY('{"fruit":"banana"}', '$.fruit'), JSON_VALUE('{"fruit":"banana"}', '$.fruit'));

-- Statement 499
SELECT TO_ARRAY(['test']);

-- Statement 500
SELECT ARRAY('test');

-- Statement 501
WITH t(x, "value") AS (SELECT [1, 2, 3], 1) SELECT IFF(_u.pos = _u_2.pos_2, _u_2."value", NULL) AS "value" FROM t CROSS JOIN TABLE(FLATTEN(INPUT => ARRAY_GENERATE_RANGE(0, (GREATEST(ARRAY_SIZE(t.x)) - 1) + 1))) AS _u(seq, key, path, index, pos, this) CROSS JOIN TABLE(FLATTEN(INPUT => t.x)) AS _u_2(seq, key, path, pos_2, "value", this) WHERE _u.pos = _u_2.pos_2 OR (_u.pos > (ARRAY_SIZE(t.x) - 1) AND _u_2.pos_2 = (ARRAY_SIZE(t.x) - 1));

-- Statement 502
WITH t(x, "value") AS (SELECT [1,2,3], 1) SELECT UNNEST(t.x) AS "value" FROM t;

-- Statement 503
SELECT { 'Manitoba': 'Winnipeg', 'foo': 'bar' } AS province_capital;

-- Statement 504
SELECT {'Manitoba': 'Winnipeg', 'foo': 'bar'} AS province_capital;

-- Statement 505
SELECT OBJECT_CONSTRUCT('Manitoba', 'Winnipeg', 'foo', 'bar') AS province_capital;

-- Statement 506
SELECT STRUCT('Winnipeg' AS Manitoba, 'bar' AS foo) AS province_capital;

-- Statement 507
SELECT COLLATE('B', 'und:ci');

-- Statement 508
SELECT To_BOOLEAN('T');

-- Statement 509
SELECT CASE WHEN UPPER(CAST('T' AS TEXT)) = 'ON' THEN TRUE WHEN UPPER(CAST('T' AS TEXT)) = 'OFF' THEN FALSE WHEN ISNAN(TRY_CAST('T' AS REAL)) OR ISINF(TRY_CAST('T' AS REAL)) THEN ERROR('TO_BOOLEAN: Non-numeric values NaN and INF are not supported') ELSE CAST('T' AS BOOLEAN) END;

-- Statement 510
SELECT id FROM t START WITH (parent_id IS NULL) CONNECT BY PRIOR id = parent_id;

-- Statement 511
SELECT id FROM t START WITH (x) CONNECT BY PRIOR id = parent_id;

-- Statement 512
SELECT * FROM x START WITH a = b CONNECT BY c = PRIOR d;

-- Statement 513
SELECT INSERT(a, 0, 0, 'b');

-- Statement 514
SELECT STUFF(a, 0, 0, 'b');

-- Statement 515
SELECT ARRAY_GENERATE_RANGE(-5, -25, -10);

-- Statement 516
SELECT RANGE(-5, -25, -10);

-- Statement 517
SELECT ARRAY_GENERATE_RANGE(5, 1, -1);

-- Statement 518
SELECT RANGE(5, 1, -1);

-- Statement 519
SELECT DATE_PART('year', TIMESTAMP '2020-01-01');

-- Statement 520
SELECT EXTRACT(year FROM CAST('2020-01-01' AS TIMESTAMP));

-- Statement 521
SELECT DATE_PART('year', CAST('2020-01-01' AS TIMESTAMP));

-- Statement 522
SELECT * FROM (VALUES (0) foo(bar));

-- Statement 523
SELECT * FROM (VALUES (0)) AS foo(bar);

-- Statement 524
SELECT i, p, o FROM qt QUALIFY ROW_NUMBER() OVER (PARTITION BY p ORDER BY o) = 1;

-- Statement 525
SELECT i, p, o FROM qt QUALIFY ROW_NUMBER() OVER (PARTITION BY p ORDER BY o NULLS LAST) = 1;

-- Statement 526
SELECT i, p, o FROM (SELECT i, p, o, ROW_NUMBER() OVER (PARTITION BY p ORDER BY o NULLS LAST) AS _w FROM qt) AS _t WHERE _w = 1;

-- Statement 527
SELECT i, p, o FROM (SELECT i, p, o, ROW_NUMBER() OVER (PARTITION BY p ORDER BY o) AS _w FROM qt) AS _t WHERE _w = 1;

-- Statement 528
SELECT NTH_VALUE(a, 2) FROM t;

-- Statement 529
SELECT NTH_VALUE(is_deleted, 2) FROM FIRST IGNORE NULLS OVER (PARTITION BY id) AS nth_is_deleted FROM my_table;

-- Statement 530
SELECT NTH_VALUE(is_deleted, 2 IGNORE NULLS) OVER (PARTITION BY id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS nth_is_deleted FROM my_table;

-- Statement 531
SELECT NTH_VALUE(is_deleted, 2) FROM LAST RESPECT NULLS OVER (PARTITION BY id) AS nth_is_deleted FROM my_table;

-- Statement 532
SELECT NTH_VALUE(is_deleted, 2 RESPECT NULLS) OVER (PARTITION BY id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS nth_is_deleted FROM my_table;

-- Statement 533
SELECT NTH_VALUE(is_deleted, 2) OVER (PARTITION BY id) AS nth_is_deleted FROM my_table;

-- Statement 534
SELECT NTH_VALUE(is_deleted, 2) OVER (PARTITION BY id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS nth_is_deleted FROM my_table;

-- Statement 535
SELECT NTH_VALUE(is_deleted, 2) OVER (PARTITION BY id ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS nth_is_deleted FROM my_table;

-- Statement 536
SELECT {func}(is_deleted){options} OVER (PARTITION BY id) AS nth_is_deleted FROM my_table;

-- Statement 537
SELECT {func}(is_deleted{options}) OVER (PARTITION BY id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS nth_is_deleted FROM my_table;

-- Statement 538
SELECT {func}(is_deleted){options} OVER (PARTITION BY id ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS nth_is_deleted FROM my_table;

-- Statement 539
SELECT {func}(is_deleted{options}) OVER (PARTITION BY id ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS nth_is_deleted FROM my_table;

-- Statement 540
SELECT LEAD(is_deleted, 2, -10) RESPECT NULLS OVER (PARTITION BY id) AS nth_is_deleted FROM my_table;

-- Statement 541
SELECT LEAD(is_deleted, 2, -10 RESPECT NULLS) OVER (PARTITION BY id) AS nth_is_deleted FROM my_table;

-- Statement 542
SELECT LEAD(is_deleted, 2) OVER (PARTITION BY id) AS nth_is_deleted FROM my_table;

-- Statement 543
SELECT LAG(amount) OVER (ORDER BY seq) AS basic_lag;

-- Statement 544
SELECT LAG(amount, 2) IGNORE NULLS OVER (PARTITION BY category ORDER BY seq) AS lag_offset_ignore_nulls;

-- Statement 545
SELECT LAG(amount, 2 IGNORE NULLS) OVER (PARTITION BY category ORDER BY seq) AS lag_offset_ignore_nulls;

-- Statement 546
SELECT LAG(amount, 2, -777) RESPECT NULLS OVER (PARTITION BY category ORDER BY seq ASC) AS lag_full_ignore_nulls;

-- Statement 547
SELECT LAG(amount, 2, -777 RESPECT NULLS) OVER (PARTITION BY category ORDER BY seq ASC) AS lag_full_ignore_nulls;

-- Statement 548
SELECT BOOLOR_AGG(c1), BOOLOR_AGG(c2) FROM test;

-- Statement 549
SELECT LOGICAL_OR(c1), LOGICAL_OR(c2) FROM test;

-- Statement 550
SELECT BOOL_OR(CAST(c1 AS BOOLEAN)), BOOL_OR(CAST(c2 AS BOOLEAN)) FROM test;

-- Statement 551
SELECT MAX(c1), MAX(c2) FROM test;

-- Statement 552
SELECT BOOL_OR(c1), BOOL_OR(c2) FROM test;

-- Statement 553
SELECT BOOLAND_AGG(c1), BOOLAND_AGG(c2) FROM test;

-- Statement 554
SELECT LOGICAL_AND(c1), LOGICAL_AND(c2) FROM test;

-- Statement 555
SELECT BOOL_AND(CAST(c1 AS BOOLEAN)), BOOL_AND(CAST(c2 AS BOOLEAN)) FROM test;

-- Statement 556
SELECT MIN(c1), MIN(c2) FROM test;

-- Statement 557
SELECT BOOL_AND(c1), BOOL_AND(c2) FROM test;

-- Statement 558
SELECT BOOLXOR_AGG(c1) FROM test;

-- Statement 559
SELECT COUNT_IF(CAST(c1 AS BOOLEAN)) = 1 FROM test;

-- Statement 560
SELECT COUNT_IF(x > 1) FROM t;

-- Statement 561
SELECT COUNT_IF((x > 1) IS TRUE) FROM t;

-- Statement 562
SELECT SUM(CASE WHEN x > 1 THEN 1 ELSE 0 END) FROM t;

-- Statement 563
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY x){suffix};

-- Statement 564
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY x NULLS LAST){suffix};

-- Statement 565
SELECT QUANTILE_CONT(x, 0.5 ORDER BY x){suffix};

-- Statement 566
SELECT {func}(y, x){suffix};

-- Statement 567
SELECT * EXCLUDE (a, b) REPLACE (c AS d, E AS F) FROM xxx;

-- Statement 568
SELECT PARSE_JSON('{"a": {"b c": "foo"}}'):a:"b c";

-- Statement 569
SELECT JSON('{"a": {"b c": "foo"}}') -> '$.a."b c"';

-- Statement 570
SELECT JSON_EXTRACT('{"a": {"b c": "foo"}}', '$.a."b c"');

-- Statement 571
SELECT GET_PATH(PARSE_JSON('{"a": {"b c": "foo"}}'), 'a["b c"]');

-- Statement 572
SELECT a FROM test WHERE a = 1 GROUP BY a HAVING a = 2 QUALIFY z ORDER BY a LIMIT 10;

-- Statement 573
SELECT a FROM test WHERE a = 1 GROUP BY a HAVING a = 2 QUALIFY z ORDER BY a NULLS LAST LIMIT 10;

-- Statement 574
SELECT a FROM test AS t QUALIFY ROW_NUMBER() OVER (PARTITION BY a ORDER BY Z) = 1;

-- Statement 575
SELECT a FROM test AS t QUALIFY ROW_NUMBER() OVER (PARTITION BY a ORDER BY Z NULLS LAST) = 1;

-- Statement 576
SELECT TO_TIMESTAMP(col, 'DD-MM-YYYY HH12:MI:SS') FROM t;

-- Statement 577
SELECT PARSE_TIMESTAMP('%d-%m-%Y %I:%M:%S', col) FROM t;

-- Statement 578
SELECT STRPTIME(col, '%d-%m-%Y %I:%M:%S') FROM t;

-- Statement 579
SELECT TO_TIMESTAMP(col, 'd-M-yyyy h:m:s') FROM t;

-- Statement 580
SELECT TO_TIMESTAMP(1659981729);

-- Statement 581
SELECT TIMESTAMP_SECONDS(1659981729);

-- Statement 582
SELECT CAST(FROM_UNIXTIME(1659981729) AS TIMESTAMP);

-- Statement 583
SELECT (TIMESTAMP 'epoch' + 1659981729 * INTERVAL '1 SECOND');

-- Statement 584
SELECT TO_TIMESTAMP(1659981729000, 3);

-- Statement 585
SELECT TIMESTAMP_MILLIS(1659981729000);

-- Statement 586
SELECT (TIMESTAMP 'epoch' + (1659981729000 / POWER(10, 3)) * INTERVAL '1 SECOND');

-- Statement 587
SELECT TO_TIMESTAMP(16599817290000, 4);

-- Statement 588
SELECT TIMESTAMP_SECONDS(CAST(16599817290000 / POWER(10, 4) AS INT64));

-- Statement 589
SELECT TIMESTAMP_SECONDS(16599817290000 / POWER(10, 4));

-- Statement 590
SELECT (TIMESTAMP 'epoch' + (16599817290000 / POWER(10, 4)) * INTERVAL '1 SECOND');

-- Statement 591
SELECT TO_TIMESTAMP('1659981729');

-- Statement 592
SELECT CAST(FROM_UNIXTIME('1659981729') AS TIMESTAMP);

-- Statement 593
SELECT TO_TIMESTAMP(1659981729000000000, 9);

-- Statement 594
SELECT TIMESTAMP_SECONDS(CAST(1659981729000000000 / POWER(10, 9) AS INT64));

-- Statement 595
SELECT TO_TIMESTAMP(1659981729000000000 / POWER(10, 9)) AT TIME ZONE 'UTC';

-- Statement 596
SELECT FROM_UNIXTIME(CAST(1659981729000000000 AS DOUBLE) / POW(10, 9));

-- Statement 597
SELECT TIMESTAMP_SECONDS(1659981729000000000 / POWER(10, 9));

-- Statement 598
SELECT (TIMESTAMP 'epoch' + (1659981729000000000 / POWER(10, 9)) * INTERVAL '1 SECOND');

-- Statement 599
SELECT TO_TIMESTAMP('2013-04-05 01:02:03');

-- Statement 600
SELECT CAST('2013-04-05 01:02:03' AS DATETIME);

-- Statement 601
SELECT CAST('2013-04-05 01:02:03' AS TIMESTAMP);

-- Statement 602
SELECT TO_TIMESTAMP('04/05/2013 01:02:03', 'mm/DD/yyyy hh24:mi:ss');

-- Statement 603
SELECT PARSE_TIMESTAMP('%m/%d/%Y %H:%M:%S', '04/05/2013 01:02:03');

-- Statement 604
SELECT STRPTIME('04/05/2013 01:02:03', '%m/%d/%Y %H:%M:%S');

-- Statement 605
SELECT PARSE_TIMESTAMP('%m/%d/%Y %T', '04/05/2013 01:02:03');

-- Statement 606
SELECT TO_TIMESTAMP('04/05/2013 01:02:03', 'M/d/yyyy H:m:s');

-- Statement 607
SELECT IFF(TRUE, 'true', 'false');

-- Statement 608
SELECT IF(TRUE, 'true', 'false');

-- Statement 609
SELECT fname, lname, age FROM person ORDER BY age DESC NULLS FIRST, fname ASC NULLS LAST, lname;

-- Statement 610
SELECT fname, lname, age FROM person ORDER BY age DESC NULLS FIRST, fname ASC, lname;

-- Statement 611
SELECT fname, lname, age FROM person ORDER BY age DESC, fname ASC, lname;

-- Statement 612
SELECT fname, lname, age FROM person ORDER BY age DESC NULLS FIRST, fname ASC NULLS LAST, lname NULLS LAST;

-- Statement 613
SELECT ARRAY_AGG(DISTINCT a);

-- Statement 614
SELECT COLLECT_LIST(DISTINCT a);

-- Statement 615
SELECT ARRAY_AGG(DISTINCT a) FILTER(WHERE a IS NOT NULL);

-- Statement 616
SELECT ARRAY_AGG(col) WITHIN GROUP (ORDER BY sort_col);

-- Statement 617
SELECT ARRAY_AGG(col ORDER BY sort_col) FILTER(WHERE col IS NOT NULL);

-- Statement 618
SELECT ARRAY_AGG(DISTINCT col) WITHIN GROUP (ORDER BY col DESC);

-- Statement 619
SELECT ARRAY_AGG(DISTINCT col ORDER BY col DESC NULLS FIRST) FILTER(WHERE col IS NOT NULL);

-- Statement 620
SELECT ARRAY_TO_STRING(x, '');

-- Statement 621
SELECT ARRAY_JOIN(x, '');

-- Statement 622
SELECT CASE WHEN '' IS NULL THEN NULL ELSE ARRAY_TO_STRING(LIST_TRANSFORM(x, x -> COALESCE(CAST(x AS TEXT), '')), '') END;

-- Statement 623
SELECT ARRAY_TO_STRING(x, NULL);

-- Statement 624
SELECT CASE WHEN NULL IS NULL THEN NULL ELSE ARRAY_TO_STRING(LIST_TRANSFORM(x, x -> COALESCE(CAST(x AS TEXT), '')), NULL) END;

-- Statement 625
SELECT ARRAY_TO_STRING([], ',');

-- Statement 626
SELECT CASE WHEN ',' IS NULL THEN NULL ELSE ARRAY_TO_STRING(LIST_TRANSFORM([], x -> COALESCE(CAST(x AS TEXT), '')), ',') END;

-- Statement 627
SELECT * FROM a INTERSECT ALL SELECT * FROM b;

-- Statement 628
SELECT * FROM a EXCEPT ALL SELECT * FROM b;

-- Statement 629
SELECT ARRAY_UNION_AGG(a);

-- Statement 630
SELECT $$a$$;

-- Statement 631
SELECT 'a';

-- Statement 632
SELECT a RLIKE b;

-- Statement 633
SELECT REGEXP_FULL_MATCH(a, b);

-- Statement 634
SELECT REGEXP_LIKE(a, b);

-- Statement 635
SELECT a NOT RLIKE b;

-- Statement 636
SELECT NOT REGEXP_FULL_MATCH(a, b);

-- Statement 637
SELECT NOT a RLIKE b;

-- Statement 638
SELECT NOT REGEXP_LIKE(a, b);

-- Statement 639
SELECT RLIKE(a, b);

-- Statement 640
SELECT RLIKE(a, b, 'i');

-- Statement 641
SELECT REGEXP_FULL_MATCH(a, b, 'i');

-- Statement 642
SELECT REGEXP_LIKE(a, b, 'i');

-- Statement 643
SELECT a FROM test pivot;

-- Statement 644
SELECT a FROM test AS pivot;

-- Statement 645
SELECT a FROM test unpivot;

-- Statement 646
SELECT a FROM test AS unpivot;

-- Statement 647
SELECT ((ROUND(1, 0)) AND (ROUND(-2, 0)));

-- Statement 648
SELECT ((ROUND(1, 0)) OR (ROUND(0, 0)));

-- Statement 649
SELECT BOOLXOR(2, 0.3);

-- Statement 650
SELECT (ROUND(2, 0) AND (NOT ROUND(0.3, 0))) OR ((NOT ROUND(2, 0)) AND ROUND(0.3, 0));

-- Statement 651
SELECT APPROX_PERCENTILE(a, 0.5) FROM t;

-- Statement 652
SELECT APPROX_PERCENTILE(a, 1, 0.5, 0.001) FROM t;

-- Statement 653
SELECT OBJECT_INSERT(OBJECT_INSERT(OBJECT_INSERT(OBJECT_CONSTRUCT('key5', 'value5'), 'key1', 5), 'key2', 2.2), 'key3', 'value3');

-- Statement 654
SELECT STRUCT_INSERT(STRUCT_INSERT(STRUCT_INSERT({'key5': 'value5'}, key1 := 5), key2 := 2.2), key3 := 'value3');

-- Statement 655
SELECT OBJECT_INSERT(OBJECT_INSERT(OBJECT_INSERT(OBJECT_CONSTRUCT(), 'key1', 5), 'key2', 2.2), 'key3', 'value3');

-- Statement 656
SELECT STRUCT_INSERT(STRUCT_INSERT(STRUCT_PACK(key1 := 5), key2 := 2.2), key3 := 'value3');

-- Statement 657
SELECT ARRAY_CONSTRUCT('foo')::VARIANT[0];

-- Statement 658
SELECT CAST(['foo'] AS VARIANT)[0];

-- Statement 659
SELECT CONVERT_TIMEZONE('America/New_York', '2024-08-06 09:10:00.000');

-- Statement 660
SELECT CONVERT_TIMEZONE('America/Los_Angeles', 'America/New_York', '2024-08-06 09:10:00.000');

-- Statement 661
SELECT CONVERT_TZ('2024-08-06 09:10:00.000', 'America/Los_Angeles', 'America/New_York');

-- Statement 662
SELECT CAST('2024-08-06 09:10:00.000' AS TIMESTAMP) AT TIME ZONE 'America/Los_Angeles' AT TIME ZONE 'America/New_York';

-- Statement 663
SELECT UUID_STRING(), UUID_STRING('fe971b24-9572-4005-b22f-351e9c09274d', 'foo');

-- Statement 664
SELECT TRY_TO_TIMESTAMP('2024-01-15 12:30:00.000');

-- Statement 665
SELECT TRY_CAST('2024-01-15 12:30:00.000' AS TIMESTAMP);

-- Statement 666
SELECT TRY_TO_TIMESTAMP('invalid');

-- Statement 667
SELECT TRY_CAST('invalid' AS TIMESTAMP);

-- Statement 668
SELECT TRY_TO_TIMESTAMP('04/05/2013 01:02:03', 'mm/DD/yyyy hh24:mi:ss');

-- Statement 669
SELECT CAST(TRY_STRPTIME('04/05/2013 01:02:03', '%m/%d/%Y %H:%M:%S') AS TIMESTAMP);

-- Statement 670
SELECT BITNOT(a);

-- Statement 671
SELECT BIT_NOT(a);

-- Statement 672
SELECT BITNOT(-1);

-- Statement 673
SELECT ~(-1);

-- Statement 674
SELECT BITAND(a, b);

-- Statement 675
SELECT BITAND(a, b, 'LEFT');

-- Statement 676
SELECT BIT_AND(a, b);

-- Statement 677
SELECT BIT_AND(a, b, 'LEFT');

-- Statement 678
SELECT BITOR(a, b);

-- Statement 679
SELECT BITOR(a, b, 'LEFT');

-- Statement 680
SELECT BIT_OR(a, b);

-- Statement 681
SELECT BIT_OR(a, b, 'RIGHT');

-- Statement 682
SELECT BITOR(a, b, 'RIGHT');

-- Statement 683
SELECT BITXOR(a, b);

-- Statement 684
SELECT BITXOR(a, b, 'LEFT');

-- Statement 685
SELECT BIT_XOR(a, b);

-- Statement 686
SELECT BIT_XOR(a, b, 'LEFT');

-- Statement 687
SELECT BITOR(BITSHIFTLEFT(5, 16), BITSHIFTLEFT(3, 8));

-- Statement 688
SELECT (CAST(5 AS INT128) << 16) | (CAST(3 AS INT128) << 8);

-- Statement 689
SELECT BITAND(BITSHIFTLEFT(255, 4), BITSHIFTLEFT(15, 2));

-- Statement 690
SELECT (CAST(255 AS INT128) << 4) & (CAST(15 AS INT128) << 2);

-- Statement 691
SELECT BITSHIFTLEFT(255, 4);

-- Statement 692
SELECT CAST(255 AS INT128) << 4;

-- Statement 693
SELECT BITSHIFTRIGHT(255, 4);

-- Statement 694
SELECT CAST(255 AS INT128) >> 4;

-- Statement 695
SELECT BITSHIFTLEFT(X'002A'::BINARY, 1);

-- Statement 696
SELECT BITSHIFTLEFT(CAST(x'002A' AS BINARY), 1);

-- Statement 697
SELECT CAST(CAST(CAST(UNHEX('002A') AS BLOB) AS BIT) << 1 AS BLOB);

-- Statement 698
SELECT BITSHIFTRIGHT(X'002A'::BINARY, 1);

-- Statement 699
SELECT BITSHIFTRIGHT(CAST(x'002A' AS BINARY), 1);

-- Statement 700
SELECT CAST(CAST(CAST(UNHEX('002A') AS BLOB) AS BIT) >> 1 AS BLOB);

-- Statement 701
SELECT HEX_DECODE_BINARY('65');

-- Statement 702
SELECT FROM_HEX('65');

-- Statement 703
SELECT UNHEX('65');

-- Statement 704
SELECT id, PRIOR name AS parent_name, name FROM tree CONNECT BY NOCYCLE PRIOR id = parent_id;

-- Statement 705
SELECT CAST(1 AS DOUBLE), CAST(1 AS DOUBLE);

-- Statement 706
SELECT CAST(1 AS BIGDECIMAL), CAST(1 AS BIGNUMERIC);

-- Statement 707
SELECT DATE_PART(WEEKISO, CAST('2013-12-25' AS DATE));

-- Statement 708
SELECT EXTRACT(ISOWEEK FROM CAST('2013-12-25' AS DATE));

-- Statement 709
SELECT CAST(STRFTIME(CAST('2013-12-25' AS DATE), '%V') AS INT);

-- Statement 710
SELECT DATE_PART(YEAROFWEEK, CAST('2026-01-06' AS DATE));

-- Statement 711
SELECT CAST(STRFTIME(CAST('2026-01-06' AS DATE), '%G') AS INT);

-- Statement 712
SELECT DATE_PART(YEAROFWEEKISO, CAST('2026-01-06' AS DATE));

-- Statement 713
SELECT DATE_PART(NANOSECOND, CAST('2026-01-06 11:45:00.123456789' AS TIMESTAMPNTZ));

-- Statement 714
SELECT CAST(STRFTIME(CAST(CAST('2026-01-06 11:45:00.123456789' AS TIMESTAMP) AS TIMESTAMP_NS), '%n') AS BIGINT);

-- Statement 715
SELECT EXTRACT(YEAR FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP_NTZ));

-- Statement 716
SELECT DATE_PART(YEAR, CAST('2026-01-06 11:45:00' AS TIMESTAMPNTZ));

-- Statement 717
SELECT EXTRACT(YEAR FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP));

-- Statement 718
SELECT EXTRACT(QUARTER FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP_NTZ));

-- Statement 719
SELECT DATE_PART(QUARTER, CAST('2026-01-06 11:45:00' AS TIMESTAMPNTZ));

-- Statement 720
SELECT EXTRACT(QUARTER FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP));

-- Statement 721
SELECT EXTRACT(MONTH FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP_NTZ));

-- Statement 722
SELECT DATE_PART(MONTH, CAST('2026-01-06 11:45:00' AS TIMESTAMPNTZ));

-- Statement 723
SELECT EXTRACT(MONTH FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP));

-- Statement 724
SELECT EXTRACT(WEEK FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP_NTZ));

-- Statement 725
SELECT DATE_PART(WEEK, CAST('2026-01-06 11:45:00' AS TIMESTAMPNTZ));

-- Statement 726
SELECT EXTRACT(WEEK FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP));

-- Statement 727
SELECT EXTRACT(WEEKISO FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP_NTZ));

-- Statement 728
SELECT DATE_PART(WEEKISO, CAST('2026-01-06 11:45:00' AS TIMESTAMPNTZ));

-- Statement 729
SELECT CAST(STRFTIME(CAST('2026-01-06 11:45:00' AS TIMESTAMP), '%V') AS INT);

-- Statement 730
SELECT EXTRACT(DAY FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP_NTZ));

-- Statement 731
SELECT DATE_PART(DAY, CAST('2026-01-06 11:45:00' AS TIMESTAMPNTZ));

-- Statement 732
SELECT EXTRACT(DAY FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP));

-- Statement 733
SELECT EXTRACT(DAYOFMONTH FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP_NTZ));

-- Statement 734
SELECT EXTRACT(DAYOFWEEK FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP_NTZ));

-- Statement 735
SELECT DATE_PART(DAYOFWEEK, CAST('2026-01-06 11:45:00' AS TIMESTAMPNTZ));

-- Statement 736
SELECT EXTRACT(DAYOFWEEK FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP));

-- Statement 737
SELECT EXTRACT(DAYOFWEEKISO FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP_NTZ));

-- Statement 738
SELECT DATE_PART(DAYOFWEEKISO, CAST('2026-01-06 11:45:00' AS TIMESTAMPNTZ));

-- Statement 739
SELECT EXTRACT(ISODOW FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP));

-- Statement 740
SELECT EXTRACT(DAYOFYEAR FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP_NTZ));

-- Statement 741
SELECT DATE_PART(DAYOFYEAR, CAST('2026-01-06 11:45:00' AS TIMESTAMPNTZ));

-- Statement 742
SELECT EXTRACT(DAYOFYEAR FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP));

-- Statement 743
SELECT EXTRACT(YEAROFWEEK FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP_NTZ));

-- Statement 744
SELECT DATE_PART(YEAROFWEEK, CAST('2026-01-06 11:45:00' AS TIMESTAMPNTZ));

-- Statement 745
SELECT CAST(STRFTIME(CAST('2026-01-06 11:45:00' AS TIMESTAMP), '%G') AS INT);

-- Statement 746
SELECT EXTRACT(YEAROFWEEKISO FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP_NTZ));

-- Statement 747
SELECT DATE_PART(YEAROFWEEKISO, CAST('2026-01-06 11:45:00' AS TIMESTAMPNTZ));

-- Statement 748
SELECT EXTRACT(HOUR FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP_NTZ));

-- Statement 749
SELECT DATE_PART(HOUR, CAST('2026-01-06 11:45:00' AS TIMESTAMPNTZ));

-- Statement 750
SELECT EXTRACT(HOUR FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP));

-- Statement 751
SELECT EXTRACT(MINUTE FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP_NTZ));

-- Statement 752
SELECT DATE_PART(MINUTE, CAST('2026-01-06 11:45:00' AS TIMESTAMPNTZ));

-- Statement 753
SELECT EXTRACT(MINUTE FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP));

-- Statement 754
SELECT EXTRACT(SECOND FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP_NTZ));

-- Statement 755
SELECT DATE_PART(SECOND, CAST('2026-01-06 11:45:00' AS TIMESTAMPNTZ));

-- Statement 756
SELECT EXTRACT(SECOND FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP));

-- Statement 757
SELECT EXTRACT(NANOSECOND FROM CAST('2026-01-06 11:45:00.123456789' AS TIMESTAMP_NTZ));

-- Statement 758
SELECT EXTRACT(EPOCH_SECOND FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP_NTZ));

-- Statement 759
SELECT DATE_PART(EPOCH_SECOND, CAST('2026-01-06 11:45:00' AS TIMESTAMPNTZ));

-- Statement 760
SELECT CAST(EPOCH(CAST('2026-01-06 11:45:00' AS TIMESTAMP)) AS BIGINT);

-- Statement 761
SELECT EXTRACT(EPOCH_MILLISECOND FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP_NTZ));

-- Statement 762
SELECT DATE_PART(EPOCH_MILLISECOND, CAST('2026-01-06 11:45:00' AS TIMESTAMPNTZ));

-- Statement 763
SELECT EPOCH_MS(CAST('2026-01-06 11:45:00' AS TIMESTAMP));

-- Statement 764
SELECT EXTRACT(EPOCH_MICROSECOND FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP_NTZ));

-- Statement 765
SELECT DATE_PART(EPOCH_MICROSECOND, CAST('2026-01-06 11:45:00' AS TIMESTAMPNTZ));

-- Statement 766
SELECT EPOCH_US(CAST('2026-01-06 11:45:00' AS TIMESTAMP));

-- Statement 767
SELECT EXTRACT(EPOCH_NANOSECOND FROM CAST('2026-01-06 11:45:00' AS TIMESTAMP_NTZ));

-- Statement 768
SELECT DATE_PART(EPOCH_NANOSECOND, CAST('2026-01-06 11:45:00' AS TIMESTAMPNTZ));

-- Statement 769
SELECT EPOCH_NS(CAST('2026-01-06 11:45:00' AS TIMESTAMP));

-- Statement 770
SELECT EXTRACT(YEAR FROM CAST('2026-01-06' AS DATE));

-- Statement 771
SELECT DATE_PART(YEAR, CAST('2026-01-06' AS DATE));

-- Statement 772
SELECT EXTRACT(QUARTER FROM CAST('2026-01-06' AS DATE));

-- Statement 773
SELECT DATE_PART(QUARTER, CAST('2026-01-06' AS DATE));

-- Statement 774
SELECT EXTRACT(MONTH FROM CAST('2026-01-06' AS DATE));

-- Statement 775
SELECT DATE_PART(MONTH, CAST('2026-01-06' AS DATE));

-- Statement 776
SELECT EXTRACT(WEEK FROM CAST('2026-01-06' AS DATE));

-- Statement 777
SELECT DATE_PART(WEEK, CAST('2026-01-06' AS DATE));

-- Statement 778
SELECT EXTRACT(WEEKISO FROM CAST('2026-01-06' AS DATE));

-- Statement 779
SELECT DATE_PART(WEEKISO, CAST('2026-01-06' AS DATE));

-- Statement 780
SELECT CAST(STRFTIME(CAST('2026-01-06' AS DATE), '%V') AS INT);

-- Statement 781
SELECT EXTRACT(DAY FROM CAST('2026-01-06' AS DATE));

-- Statement 782
SELECT DATE_PART(DAY, CAST('2026-01-06' AS DATE));

-- Statement 783
SELECT EXTRACT(DAYOFMONTH FROM CAST('2026-01-06' AS DATE));

-- Statement 784
SELECT EXTRACT(DAYOFWEEK FROM CAST('2026-01-06' AS DATE));

-- Statement 785
SELECT DATE_PART(DAYOFWEEK, CAST('2026-01-06' AS DATE));

-- Statement 786
SELECT EXTRACT(DAYOFWEEKISO FROM CAST('2026-01-06' AS DATE));

-- Statement 787
SELECT DATE_PART(DAYOFWEEKISO, CAST('2026-01-06' AS DATE));

-- Statement 788
SELECT EXTRACT(ISODOW FROM CAST('2026-01-06' AS DATE));

-- Statement 789
SELECT EXTRACT(DAYOFYEAR FROM CAST('2026-01-06' AS DATE));

-- Statement 790
SELECT DATE_PART(DAYOFYEAR, CAST('2026-01-06' AS DATE));

-- Statement 791
SELECT EXTRACT(YEAROFWEEK FROM CAST('2026-01-06' AS DATE));

-- Statement 792
SELECT EXTRACT(YEAROFWEEKISO FROM CAST('2026-01-06' AS DATE));

-- Statement 793
SELECT EXTRACT(HOUR FROM CAST('11:45:00.123456789' AS TIME));

-- Statement 794
SELECT DATE_PART(HOUR, CAST('11:45:00.123456789' AS TIME));

-- Statement 795
SELECT EXTRACT(MINUTE FROM CAST('11:45:00.123456789' AS TIME));

-- Statement 796
SELECT DATE_PART(MINUTE, CAST('11:45:00.123456789' AS TIME));

-- Statement 797
SELECT EXTRACT(SECOND FROM CAST('11:45:00.123456789' AS TIME));

-- Statement 798
SELECT DATE_PART(SECOND, CAST('11:45:00.123456789' AS TIME));

-- Statement 799
SELECT ST_MAKEPOINT(10, 20);

-- Statement 800
SELECT ST_POINT(10, 20);

-- Statement 801
SELECT ST_DISTANCE(a, b);

-- Statement 802
SELECT ST_DISTANCE_SPHERE(ST_X(a), ST_Y(a), ST_X(b), ST_Y(b));

-- Statement 803
SELECT DATE_PART(DAYOFWEEKISO, foo);

-- Statement 804
SELECT DATE_PART(WEEKDAY_ISO, foo);

-- Statement 805
SELECT EXTRACT(ISODOW FROM foo);

-- Statement 806
SELECT DATE_PART(DAYOFWEEK_ISO, foo);

-- Statement 807
SELECT ADD_MONTHS('2023-01-31', 1);

-- Statement 808
SELECT CASE WHEN LAST_DAY(CAST('2023-01-31' AS TIMESTAMP)) = CAST('2023-01-31' AS TIMESTAMP) THEN LAST_DAY(CAST('2023-01-31' AS TIMESTAMP) + INTERVAL 1 MONTH) ELSE CAST('2023-01-31' AS TIMESTAMP) + INTERVAL 1 MONTH END;

-- Statement 809
SELECT ADD_MONTHS('2023-01-31'::date, 1);

-- Statement 810
SELECT CAST(CASE WHEN LAST_DAY(CAST('2023-01-31' AS DATE)) = CAST('2023-01-31' AS DATE) THEN LAST_DAY(CAST('2023-01-31' AS DATE) + INTERVAL 1 MONTH) ELSE CAST('2023-01-31' AS DATE) + INTERVAL 1 MONTH END AS DATE);

-- Statement 811
SELECT ADD_MONTHS(CAST('2023-01-31' AS DATE), 1);

-- Statement 812
SELECT ADD_MONTHS('2023-01-31'::timestamptz, 1);

-- Statement 813
SELECT CAST(CASE WHEN LAST_DAY(CAST('2023-01-31' AS TIMESTAMPTZ)) = CAST('2023-01-31' AS TIMESTAMPTZ) THEN LAST_DAY(CAST('2023-01-31' AS TIMESTAMPTZ) + INTERVAL 1 MONTH) ELSE CAST('2023-01-31' AS TIMESTAMPTZ) + INTERVAL 1 MONTH END AS TIMESTAMPTZ);

-- Statement 814
SELECT ADD_MONTHS(CAST('2023-01-31' AS TIMESTAMPTZ), 1);

-- Statement 815
SELECT ADD_MONTHS('2016-05-15'::DATE, 2.7);

-- Statement 816
SELECT CAST(CASE WHEN LAST_DAY(CAST('2016-05-15' AS DATE)) = CAST('2016-05-15' AS DATE) THEN LAST_DAY(CAST('2016-05-15' AS DATE) + TO_MONTHS(CAST(ROUND(2.7) AS INT))) ELSE CAST('2016-05-15' AS DATE) + TO_MONTHS(CAST(ROUND(2.7) AS INT)) END AS DATE);

-- Statement 817
SELECT ADD_MONTHS(CAST('2016-05-15' AS DATE), 2.7);

-- Statement 818
SELECT ADD_MONTHS('2016-05-15'::DATE, -2.3);

-- Statement 819
SELECT CAST(CASE WHEN LAST_DAY(CAST('2016-05-15' AS DATE)) = CAST('2016-05-15' AS DATE) THEN LAST_DAY(CAST('2016-05-15' AS DATE) + TO_MONTHS(CAST(ROUND(-2.3) AS INT))) ELSE CAST('2016-05-15' AS DATE) + TO_MONTHS(CAST(ROUND(-2.3) AS INT)) END AS DATE);

-- Statement 820
SELECT ADD_MONTHS(CAST('2016-05-15' AS DATE), -2.3);

-- Statement 821
SELECT ADD_MONTHS('2016-05-15'::DATE, 3.2::DECIMAL(10,2));

-- Statement 822
SELECT CAST(CASE WHEN LAST_DAY(CAST('2016-05-15' AS DATE)) = CAST('2016-05-15' AS DATE) THEN LAST_DAY(CAST('2016-05-15' AS DATE) + TO_MONTHS(CAST(ROUND(CAST(3.2 AS DECIMAL(10, 2))) AS INT))) ELSE CAST('2016-05-15' AS DATE) + TO_MONTHS(CAST(ROUND(CAST(3.2 AS DECIMAL(10, 2))) AS INT)) END AS DATE);

-- Statement 823
SELECT ADD_MONTHS(CAST('2016-05-15' AS DATE), CAST(3.2 AS DECIMAL(10, 2)));

-- Statement 824
SELECT ADD_MONTHS('2016-02-29'::DATE, 1);

-- Statement 825
SELECT CAST(CASE WHEN LAST_DAY(CAST('2016-02-29' AS DATE)) = CAST('2016-02-29' AS DATE) THEN LAST_DAY(CAST('2016-02-29' AS DATE) + INTERVAL 1 MONTH) ELSE CAST('2016-02-29' AS DATE) + INTERVAL 1 MONTH END AS DATE);

-- Statement 826
SELECT ADD_MONTHS(CAST('2016-02-29' AS DATE), 1);

-- Statement 827
SELECT ADD_MONTHS('2016-05-31'::DATE, 1);

-- Statement 828
SELECT CAST(CASE WHEN LAST_DAY(CAST('2016-05-31' AS DATE)) = CAST('2016-05-31' AS DATE) THEN LAST_DAY(CAST('2016-05-31' AS DATE) + INTERVAL 1 MONTH) ELSE CAST('2016-05-31' AS DATE) + INTERVAL 1 MONTH END AS DATE);

-- Statement 829
SELECT ADD_MONTHS(CAST('2016-05-31' AS DATE), 1);

-- Statement 830
SELECT ADD_MONTHS('2016-05-31'::DATE, -1);

-- Statement 831
SELECT CAST(CASE WHEN LAST_DAY(CAST('2016-05-31' AS DATE)) = CAST('2016-05-31' AS DATE) THEN LAST_DAY(CAST('2016-05-31' AS DATE) + INTERVAL (-1) MONTH) ELSE CAST('2016-05-31' AS DATE) + INTERVAL (-1) MONTH END AS DATE);

-- Statement 832
SELECT ADD_MONTHS(CAST('2016-05-31' AS DATE), -1);

-- Statement 833
SELECT ADD_MONTHS('2016-05-15'::DATE, 1);

-- Statement 834
SELECT CAST(CASE WHEN LAST_DAY(CAST('2016-05-15' AS DATE)) = CAST('2016-05-15' AS DATE) THEN LAST_DAY(CAST('2016-05-15' AS DATE) + INTERVAL 1 MONTH) ELSE CAST('2016-05-15' AS DATE) + INTERVAL 1 MONTH END AS DATE);

-- Statement 835
SELECT ADD_MONTHS(CAST('2016-05-15' AS DATE), 1);

-- Statement 836
SELECT ADD_MONTHS(NULL::DATE, 2);

-- Statement 837
SELECT CAST(CASE WHEN LAST_DAY(CAST(NULL AS DATE)) = CAST(NULL AS DATE) THEN LAST_DAY(CAST(NULL AS DATE) + INTERVAL 2 MONTH) ELSE CAST(NULL AS DATE) + INTERVAL 2 MONTH END AS DATE);

-- Statement 838
SELECT ADD_MONTHS(CAST(NULL AS DATE), 2);

-- Statement 839
SELECT ADD_MONTHS('2016-05-15'::DATE, NULL);

-- Statement 840
SELECT CAST(CASE WHEN LAST_DAY(CAST('2016-05-15' AS DATE)) = CAST('2016-05-15' AS DATE) THEN LAST_DAY(CAST('2016-05-15' AS DATE) + INTERVAL (NULL) MONTH) ELSE CAST('2016-05-15' AS DATE) + INTERVAL (NULL) MONTH END AS DATE);

-- Statement 841
SELECT ADD_MONTHS(CAST('2016-05-15' AS DATE), NULL);

-- Statement 842
SELECT ADD_MONTHS('2016-05-15'::DATE, 0);

-- Statement 843
SELECT CAST(CASE WHEN LAST_DAY(CAST('2016-05-15' AS DATE)) = CAST('2016-05-15' AS DATE) THEN LAST_DAY(CAST('2016-05-15' AS DATE) + INTERVAL 0 MONTH) ELSE CAST('2016-05-15' AS DATE) + INTERVAL 0 MONTH END AS DATE);

-- Statement 844
SELECT ADD_MONTHS(CAST('2016-05-15' AS DATE), 0);

-- Statement 845
SELECT HOUR(CAST('08:50:57' AS TIME));

-- Statement 846
SELECT MINUTE(CAST('08:50:57' AS TIME));

-- Statement 847
SELECT SECOND(CAST('08:50:57' AS TIME));

-- Statement 848
SELECT HOUR(CAST('2024-05-09 08:50:57' AS TIMESTAMP));

-- Statement 849
SELECT MONTHNAME(CAST('2024-05-09' AS DATE));

-- Statement 850
SELECT DAYNAME(TO_DATE('2025-01-15'));

-- Statement 851
SELECT STRFTIME(CAST('2025-01-15' AS DATE), '%a');

-- Statement 852
SELECT DAYNAME(CAST('2025-01-15' AS DATE));

-- Statement 853
SELECT DAYNAME(TO_TIMESTAMP('2025-02-28 10:30:45'));

-- Statement 854
SELECT STRFTIME(CAST('2025-02-28 10:30:45' AS TIMESTAMP), '%a');

-- Statement 855
SELECT DAYNAME(CAST('2025-02-28 10:30:45' AS TIMESTAMP));

-- Statement 856
SELECT MONTHNAME(TO_DATE('2025-01-15'));

-- Statement 857
SELECT STRFTIME(CAST('2025-01-15' AS DATE), '%b');

-- Statement 858
SELECT MONTHNAME(CAST('2025-01-15' AS DATE));

-- Statement 859
SELECT MONTHNAME(TO_TIMESTAMP('2025-02-28 10:30:45'));

-- Statement 860
SELECT STRFTIME(CAST('2025-02-28 10:30:45' AS TIMESTAMP), '%b');

-- Statement 861
SELECT MONTHNAME(CAST('2025-02-28 10:30:45' AS TIMESTAMP));

-- Statement 862
SELECT PREVIOUS_DAY(CAST('2024-05-09' AS DATE), 'MONDAY');

-- Statement 863
SELECT TIME_FROM_PARTS(14, 30, 45);

-- Statement 864
SELECT TIME_FROM_PARTS(14, 30, 45, 123);

-- Statement 865
SELECT MONTHS_BETWEEN(CAST('2019-03-15' AS DATE), CAST('2019-02-15' AS DATE));

-- Statement 866
SELECT MONTHS_BETWEEN(CAST('2019-03-01 02:00:00' AS TIMESTAMP), CAST('2019-02-15 01:00:00' AS TIMESTAMP));

-- Statement 867
SELECT TIME_SLICE(CAST('2024-05-09 08:50:57.891' AS TIMESTAMP), 15, 'MINUTE');

-- Statement 868
SELECT TIME_SLICE(CAST('2024-05-09' AS DATE), 1, 'DAY');

-- Statement 869
SELECT TIME_SLICE(CAST('2024-05-09 08:50:57.891' AS TIMESTAMP), 1, 'HOUR', 'start');

-- Statement 870
SELECT TIME_SLICE(TIMESTAMP '2024-03-15 14:37:42', 1, 'HOUR');

-- Statement 871
SELECT TIME_SLICE(CAST('2024-03-15 14:37:42' AS TIMESTAMP), 1, 'HOUR');

-- Statement 872
SELECT TIME_BUCKET(INTERVAL 1 HOUR, CAST('2024-03-15 14:37:42' AS TIMESTAMP));

-- Statement 873
SELECT TIME_SLICE(TIMESTAMP '2024-03-15 14:37:42', 1, 'HOUR', 'END');

-- Statement 874
SELECT TIME_SLICE(CAST('2024-03-15 14:37:42' AS TIMESTAMP), 1, 'HOUR', 'END');

-- Statement 875
SELECT TIME_BUCKET(INTERVAL 1 HOUR, CAST('2024-03-15 14:37:42' AS TIMESTAMP)) + INTERVAL 1 HOUR;

-- Statement 876
SELECT TIME_SLICE(DATE '2024-03-15', 1, 'DAY');

-- Statement 877
SELECT TIME_SLICE(CAST('2024-03-15' AS DATE), 1, 'DAY');

-- Statement 878
SELECT TIME_BUCKET(INTERVAL 1 DAY, CAST('2024-03-15' AS DATE));

-- Statement 879
SELECT TIME_SLICE(DATE '2024-03-15', 1, 'DAY', 'END');

-- Statement 880
SELECT TIME_SLICE(CAST('2024-03-15' AS DATE), 1, 'DAY', 'END');

-- Statement 881
SELECT CAST(TIME_BUCKET(INTERVAL 1 DAY, CAST('2024-03-15' AS DATE)) + INTERVAL 1 DAY AS DATE);

-- Statement 882
SELECT TIME_SLICE(TIMESTAMP '2024-03-15 14:37:42', 15, 'MINUTE');

-- Statement 883
SELECT TIME_SLICE(CAST('2024-03-15 14:37:42' AS TIMESTAMP), 15, 'MINUTE');

-- Statement 884
SELECT TIME_BUCKET(INTERVAL 15 MINUTE, CAST('2024-03-15 14:37:42' AS TIMESTAMP));

-- Statement 885
SELECT TIME_SLICE(TIMESTAMP '2024-03-15 14:37:42', 1, 'QUARTER');

-- Statement 886
SELECT TIME_SLICE(CAST('2024-03-15 14:37:42' AS TIMESTAMP), 1, 'QUARTER');

-- Statement 887
SELECT TIME_BUCKET(INTERVAL 1 QUARTER, CAST('2024-03-15 14:37:42' AS TIMESTAMP));

-- Statement 888
SELECT TIME_SLICE(DATE '2024-03-15', 1, 'WEEK', 'END');

-- Statement 889
SELECT TIME_SLICE(CAST('2024-03-15' AS DATE), 1, 'WEEK', 'END');

-- Statement 890
SELECT CAST(TIME_BUCKET(INTERVAL 1 WEEK, CAST('2024-03-15' AS DATE)) + INTERVAL 1 WEEK AS DATE);

-- Statement 891
SELECT * FROM t1 {join} JOIN t2;

-- Statement 892
SELECT * FROM t1, t2;

-- Statement 893
SELECT * EXCLUDE foo RENAME bar AS baz FROM tbl;

-- Statement 894
SELECT * EXCLUDE (foo) RENAME (bar AS baz) FROM tbl;

-- Statement 895
WITH foo AS (SELECT [1] AS arr_1) SELECT (SELECT unnested_arr FROM TABLE(FLATTEN(INPUT => arr_1)) AS _t0(seq, key, path, index, unnested_arr, this)) AS f FROM foo;

-- Statement 896
WITH foo AS (SELECT [1] AS arr_1) SELECT (SELECT unnested_arr FROM UNNEST(arr_1) AS unnested_arr) AS f FROM foo;

-- Statement 897
SELECT LIKE(col, 'pattern');

-- Statement 898
SELECT col LIKE 'pattern';

-- Statement 899
SELECT ILIKE(col, 'pattern');

-- Statement 900
SELECT col ILIKE 'pattern';

-- Statement 901
SELECT LIKE(col, 'pattern', '\\\\');

-- Statement 902
SELECT col LIKE 'pattern' ESCAPE '\\\\';

-- Statement 903
SELECT ILIKE(col, 'pattern', '\\\\');

-- Statement 904
SELECT col ILIKE 'pattern' ESCAPE '\\\\';

-- Statement 905
SELECT LIKE(col, 'pattern', '!');

-- Statement 906
SELECT col LIKE 'pattern' ESCAPE '!';

-- Statement 907
SELECT ILIKE(col, 'pattern', '!');

-- Statement 908
SELECT col ILIKE 'pattern' ESCAPE '!';

-- Statement 909
SELECT BASE64_ENCODE('Hello World');

-- Statement 910
SELECT TO_BASE64(ENCODE('Hello World'));

-- Statement 911
SELECT BASE64_ENCODE(x);

-- Statement 912
SELECT TO_BASE64(x);

-- Statement 913
SELECT BASE64_ENCODE(x, 76);

-- Statement 914
SELECT RTRIM(REGEXP_REPLACE(TO_BASE64(x), '(.{76})', '\\1' || CHR(10), 'g'), CHR(10));

-- Statement 915
SELECT BASE64_ENCODE(x, 76, '+/=');

-- Statement 916
SELECT BASE64_DECODE_STRING('U25vd2ZsYWtl');

-- Statement 917
SELECT DECODE(FROM_BASE64('U25vd2ZsYWtl'));

-- Statement 918
SELECT BASE64_DECODE_STRING('U25vd2ZsYWtl', '-_+');

-- Statement 919
SELECT DECODE(FROM_BASE64(REPLACE(REPLACE(REPLACE('U25vd2ZsYWtl', '-', '+'), '_', '/'), '+', '=')));

-- Statement 920
SELECT BASE64_DECODE_BINARY(x);

-- Statement 921
SELECT FROM_BASE64(x);

-- Statement 922
SELECT BASE64_DECODE_BINARY(x, '-_+');

-- Statement 923
SELECT FROM_BASE64(REPLACE(REPLACE(REPLACE(x, '-', '+'), '_', '/'), '+', '='));

-- Statement 924
SELECT TRY_HEX_DECODE_BINARY('48656C6C6F');

-- Statement 925
SELECT TRY_HEX_DECODE_STRING('48656C6C6F');

-- Statement 926
SELECT ARRAY_CONTAINS(CAST('1' AS VARIANT), ['1']);

-- Statement 927
SELECT CONTAINS(ARRAY['1'], '1');

-- Statement 928
SELECT ARRAY_CONTAINS(CAST(CAST('2020-10-10' AS DATE) AS VARIANT), [CAST('2020-10-10' AS DATE)]);

-- Statement 929
SELECT CONTAINS(ARRAY[DATE '2020-10-10'], DATE '2020-10-10');

-- Statement 930
SELECT ARRAY_CONTAINS(1, [1]);

-- Statement 931
SELECT ARRAY_CONTAINS(x, [1, NULL, 3]);

-- Statement 932
SELECT CASE WHEN x IS NULL THEN NULLIF(ARRAY_LENGTH([1, NULL, 3]) <> LIST_COUNT([1, NULL, 3]), FALSE) ELSE ARRAY_CONTAINS([1, NULL, 3], x) END;

-- Statement 933
SELECT ARRAY_DISTINCT(['A', 'B', 'A']);

-- Statement 934
SELECT ARRAY_DISTINCT(['A', NULL, 'B', NULL]);

-- Statement 935
SELECT CASE WHEN ARRAY_LENGTH(['A', NULL, 'B', NULL]) <> LIST_COUNT(['A', NULL, 'B', NULL]) THEN LIST_APPEND(LIST_DISTINCT(LIST_FILTER(['A', NULL, 'B', NULL], _u -> NOT _u IS NULL)), NULL) ELSE LIST_DISTINCT(['A', NULL, 'B', NULL]) END;

-- Statement 936
SELECT ARRAY_DISTINCT([1, 2, 2, 3, 1]);

-- Statement 937
SELECT CASE WHEN ARRAY_LENGTH([1, 2, 2, 3, 1]) <> LIST_COUNT([1, 2, 2, 3, 1]) THEN LIST_APPEND(LIST_DISTINCT(LIST_FILTER([1, 2, 2, 3, 1], _u -> NOT _u IS NULL)), NULL) ELSE LIST_DISTINCT([1, 2, 2, 3, 1]) END;

-- Statement 938
SELECT x'ABCD';

-- Statement 939
SELECT UNHEX('ABCD');

-- Statement 940
SELECT CURRENT_TIME(4);

-- Statement 941
SELECT LOCALTIME;

-- Statement 942
SELECT CURRENT_TIME;

-- Statement 943
SELECT DATE_FROM_PARTS(2026, 1, 100);

-- Statement 944
SELECT CAST(MAKE_DATE(2026, 1, 1) + INTERVAL (1 - 1) MONTH + INTERVAL (100 - 1) DAY AS DATE);

-- Statement 945
SELECT DATE_FROM_PARTS(2026, 14, 32);

-- Statement 946
SELECT CAST(MAKE_DATE(2026, 1, 1) + INTERVAL (14 - 1) MONTH + INTERVAL (32 - 1) DAY AS DATE);

-- Statement 947
SELECT DATE_FROM_PARTS(2026, 0, 0);

-- Statement 948
SELECT CAST(MAKE_DATE(2026, 1, 1) + INTERVAL (0 - 1) MONTH + INTERVAL (0 - 1) DAY AS DATE);

-- Statement 949
SELECT DATE_FROM_PARTS(2026, -14, -32);

-- Statement 950
SELECT CAST(MAKE_DATE(2026, 1, 1) + INTERVAL (-14 - 1) MONTH + INTERVAL (-32 - 1) DAY AS DATE);

-- Statement 951
SELECT DATE_FROM_PARTS(2024, 1, 60);

-- Statement 952
SELECT CAST(MAKE_DATE(2024, 1, 1) + INTERVAL (1 - 1) MONTH + INTERVAL (60 - 1) DAY AS DATE);

-- Statement 953
SELECT DATE_FROM_PARTS(2026, NULL, 100);

-- Statement 954
SELECT CAST(MAKE_DATE(2026, 1, 1) + INTERVAL (NULL - 1) MONTH + INTERVAL (100 - 1) DAY AS DATE);

-- Statement 955
SELECT DATE_FROM_PARTS(2024 + 2, 1 + 2, 2 + 3);

-- Statement 956
SELECT CAST(MAKE_DATE(2024 + 2, 1, 1) + INTERVAL ((1 + 2) - 1) MONTH + INTERVAL ((2 + 3) - 1) DAY AS DATE);

-- Statement 957
SELECT DATE_FROM_PARTS(year, month, date);

-- Statement 958
SELECT CAST(MAKE_DATE(year, 1, 1) + INTERVAL (month - 1) MONTH + INTERVAL (date - 1) DAY AS DATE);

-- Statement 959
SELECT VERSION();

-- Statement 960
SELECT CURRENT_SCHEMA();

-- Statement 961
SELECT 1 WHERE 'abc' ILIKE ANY('%a%');

-- Statement 962
SELECT 1 WHERE 'abc' ILIKE '%a%';

-- Statement 963
SELECT 1 WHERE 'abc' LIKE ALL ('%a%');

-- Statement 964
SELECT 1 WHERE 'abc' LIKE '%a%';

-- Statement 965
SELECT 'he%lo' LIKE ANY ('he#%lo', 'hello') ESCAPE '#';

-- Statement 966
SELECT 'he%lo' LIKE 'he#%lo' ESCAPE '#' OR 'he%lo' LIKE 'hello' ESCAPE '#';

-- Statement 967
SELECT 'he%lo' LIKE ALL ('he#%lo', 'he#%lo2') ESCAPE '#';

-- Statement 968
SELECT 'he%lo' LIKE 'he#%lo' ESCAPE '#' AND 'he%lo' LIKE 'he#%lo2' ESCAPE '#';

-- Statement 969
SELECT 'he%lo' ILIKE ANY ('he#%lo', 'hello') ESCAPE '#';

-- Statement 970
SELECT 'he%lo' ILIKE 'he#%lo' ESCAPE '#' OR 'he%lo' ILIKE 'hello' ESCAPE '#';

-- Statement 971
SELECT 1 WHERE 'he%lo' LIKE ANY ('he#%lo', 'hello') ESCAPE '#' AND x = 1;

-- Statement 972
SELECT 1 WHERE ('he%lo' LIKE 'he#%lo' ESCAPE '#' OR 'he%lo' LIKE 'hello' ESCAPE '#') AND x = 1;

-- Statement 973
SELECT 1 WHERE 'he%lo' LIKE ALL ('he#%lo', 'he#%lo2') ESCAPE '#' OR x = 1;

-- Statement 974
SELECT 1 WHERE ('he%lo' LIKE 'he#%lo' ESCAPE '#' AND 'he%lo' LIKE 'he#%lo2' ESCAPE '#') OR x = 1;

-- Statement 975
SELECT * FROM t UNPIVOT(a FOR b IN (c, d)) UNPIVOT(e FOR f IN (g, h));

-- Statement 976
SELECT * FROM t PIVOT(SUM(v) FOR c IN ('a' AS a)) UNPIVOT(x FOR y IN (a));

-- Statement 977
SELECT * FROM t PIVOT(SUM(val) FOR cat {pivot});

-- Statement 978
SELECT FIRST_VALUE(TABLE1.COLUMN1) OVER (PARTITION BY RANDOM_COLUMN1, RANDOM_COLUMN2 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS MY_ALIAS FROM TABLE1;

-- Statement 979
SELECT FIRST_VALUE(TABLE1.COLUMN1) OVER (PARTITION BY RANDOM_COLUMN1, RANDOM_COLUMN2) AS MY_ALIAS FROM TABLE1;

-- Statement 980
SELECT FIRST_VALUE(TABLE1.COLUMN1 RESPECT NULLS) OVER (PARTITION BY RANDOM_COLUMN1, RANDOM_COLUMN2 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS MY_ALIAS FROM TABLE1;

-- Statement 981
SELECT FIRST_VALUE(TABLE1.COLUMN1) RESPECT NULLS OVER (PARTITION BY RANDOM_COLUMN1, RANDOM_COLUMN2) AS MY_ALIAS FROM TABLE1;

-- Statement 982
SELECT FIRST_VALUE(TABLE1.COLUMN1) RESPECT NULLS OVER (PARTITION BY RANDOM_COLUMN1, RANDOM_COLUMN2 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS MY_ALIAS FROM TABLE1;

-- Statement 983
SELECT FIRST_VALUE(TABLE1.COLUMN1 IGNORE NULLS) OVER (PARTITION BY RANDOM_COLUMN1, RANDOM_COLUMN2 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS MY_ALIAS FROM TABLE1;

-- Statement 984
SELECT FIRST_VALUE(TABLE1.COLUMN1) IGNORE NULLS OVER (PARTITION BY RANDOM_COLUMN1, RANDOM_COLUMN2) AS MY_ALIAS FROM TABLE1;

-- Statement 985
SELECT FIRST_VALUE(TABLE1.COLUMN1) IGNORE NULLS OVER (PARTITION BY RANDOM_COLUMN1, RANDOM_COLUMN2 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS MY_ALIAS FROM TABLE1;

-- Statement 986
SELECT * FROM foo WHERE 'str' IN (SELECT value FROM TABLE(FLATTEN(INPUT => vals)) AS _u(seq, key, path, index, value, this));

-- Statement 987
SELECT * FROM foo WHERE 'str' IN UNNEST(vals);

-- Statement 988
SELECT * FROM @foo;

-- Statement 989
SELECT * FROM @"mystage";

-- Statement 990
SELECT * FROM @"myschema"."mystage"/file.gz;

-- Statement 991
SELECT * FROM @"my_DB"."schEMA1".mystage/file.gz;

-- Statement 992
SELECT metadata$filename FROM @s1/;

-- Statement 993
SELECT * FROM @~;

-- Statement 994
SELECT * FROM @~/some/path/to/file.csv;

-- Statement 995
SELECT * FROM @mystage;

-- Statement 996
SELECT * FROM '@mystage';

-- Statement 997
SELECT * FROM @namespace.mystage/path/to/file.json.gz;

-- Statement 998
SELECT * FROM @namespace.%table_name/path/to/file.json.gz;

-- Statement 999
SELECT $1, $2, metadata$filename FROM @mystage (PATTERN => '.*data-100.*');

-- Statement 1000
SELECT * FROM '@external/location' (FILE_FORMAT => 'path.to.csv');

-- Statement 1001
SELECT * FROM (SELECT a FROM @foo);

-- Statement 1002
SELECT * FROM (SELECT * FROM '@external/location' (FILE_FORMAT => 'path.to.csv'));

-- Statement 1003
SELECT * FROM @foo/bar (FILE_FORMAT => ds_sandbox.test.my_csv_format, PATTERN => 'test') AS bla;

-- Statement 1004
SELECT t.$1, t.$2 FROM @mystage1 (FILE_FORMAT => 'myformat', PATTERN => '.*data.*[.]csv.gz') AS t;

-- Statement 1005
SELECT parse_json($1):a.b FROM @mystage2/data1.json.gz;

-- Statement 1006
SELECT GET_PATH(PARSE_JSON($1), 'a.b') FROM @mystage2/data1.json.gz;

-- Statement 1007
SELECT * FROM @mystage t (c1);

-- Statement 1008
SELECT * FROM @mystage AS t(c1);

-- Statement 1009
SELECT * FROM @foo/bar (PATTERN => 'test', FILE_FORMAT => ds_sandbox.test.my_csv_format) AS bla;

-- Statement 1010
SELECT * FROM @test.public.thing/location/somefile.csv( FILE_FORMAT => 'fmt' );

-- Statement 1011
SELECT * FROM @test.public.thing/location/somefile.csv (FILE_FORMAT => 'fmt');

-- Statement 1012
SELECT * FROM testtable TABLESAMPLE BERNOULLI (20.3);

-- Statement 1013
SELECT * FROM testtable TABLESAMPLE SYSTEM (3) SEED (82);

-- Statement 1014
SELECT a FROM test PIVOT(SUM(x) FOR y IN ('z', 'q')) AS x TABLESAMPLE BERNOULLI (0.1);

-- Statement 1015
SELECT i, j FROM table1 AS t1 INNER JOIN table2 AS t2 TABLESAMPLE BERNOULLI (50) WHERE t2.j = t1.i;

-- Statement 1016
SELECT * FROM (SELECT * FROM t1 JOIN t2 ON t1.a = t2.c) TABLESAMPLE BERNOULLI (1);

-- Statement 1017
SELECT * FROM testtable TABLESAMPLE (10 ROWS);

-- Statement 1018
SELECT * FROM testtable TABLESAMPLE BERNOULLI (10 ROWS);

-- Statement 1019
SELECT * FROM testtable TABLESAMPLE (100);

-- Statement 1020
SELECT * FROM testtable TABLESAMPLE BERNOULLI (100);

-- Statement 1021
SELECT * FROM testtable SAMPLE (10);

-- Statement 1022
SELECT * FROM testtable TABLESAMPLE BERNOULLI (10);

-- Statement 1023
SELECT * FROM testtable SAMPLE ROW (0);

-- Statement 1024
SELECT * FROM testtable TABLESAMPLE ROW (0);

-- Statement 1025
SELECT a FROM test SAMPLE BLOCK (0.5) SEED (42);

-- Statement 1026
SELECT a FROM test TABLESAMPLE BLOCK (0.5) SEED (42);

-- Statement 1027
SELECT user_id, value FROM table_name SAMPLE BERNOULLI ($s) SEED (0);

-- Statement 1028
SELECT user_id, value FROM table_name TABLESAMPLE BERNOULLI ($s) SEED (0);

-- Statement 1029
SELECT * FROM example TABLESAMPLE BERNOULLI (3) SEED (82);

-- Statement 1030
SELECT * FROM example TABLESAMPLE BERNOULLI (3 PERCENT) REPEATABLE (82);

-- Statement 1031
SELECT * FROM example TABLESAMPLE (3 PERCENT) REPEATABLE (82);

-- Statement 1032
SELECT * FROM test AS _tmp TABLESAMPLE (5);

-- Statement 1033
SELECT * FROM test AS _tmp TABLESAMPLE BERNOULLI (5);

-- Statement 1034
SELECT i, j
FROM
     table1 AS t1 SAMPLE (25)     -- 25% of rows in table1
         INNER JOIN
     table2 AS t2 SAMPLE (50)     -- 50% of rows in table2
WHERE t2.j = t1.i;

-- Statement 1035
SELECT i, j FROM table1 AS t1 TABLESAMPLE BERNOULLI (25) /* 25% of rows in table1 */ INNER JOIN table2 AS t2 TABLESAMPLE BERNOULLI (50) /* 50% of rows in table2 */ WHERE t2.j = t1.i;

-- Statement 1036
SELECT * FROM testtable SAMPLE BLOCK (0.012) REPEATABLE (99992);

-- Statement 1037
SELECT * FROM testtable TABLESAMPLE BLOCK (0.012) SEED (99992);

-- Statement 1038
SELECT * FROM (SELECT * FROM t1 join t2 on t1.a = t2.c) SAMPLE (1);

-- Statement 1039
SELECT * FROM (SELECT * FROM t1 JOIN t2 ON t1.a = t2.c) TABLESAMPLE (1 PERCENT);

-- Statement 1040
SELECT CAST('12:00:00' AS TIME);

-- Statement 1041
SELECT DATE_PART(month, a);

-- Statement 1042
SELECT DATE_PART(year FROM CAST('2024-04-08' AS DATE));

-- Statement 1043
SELECT DATE_PART(year, CAST('2024-04-08' AS DATE));

-- Statement 1044
SELECT DATE_PART('month' FROM CAST('2024-04-08' AS DATE));

-- Statement 1045
SELECT DATE_PART('month', CAST('2024-04-08' AS DATE));

-- Statement 1046
SELECT DATE_PART(day FROM a);

-- Statement 1047
SELECT DATE_PART(day, a);

-- Statement 1048
SELECT a::TIMESTAMP_LTZ(9);

-- Statement 1049
SELECT CAST(a AS TIMESTAMPLTZ(9));

-- Statement 1050
SELECT a::TIMESTAMPLTZ;

-- Statement 1051
SELECT CAST(a AS TIMESTAMPLTZ);

-- Statement 1052
SELECT a::TIMESTAMP WITH LOCAL TIME ZONE;

-- Statement 1053
SELECT EXTRACT('month', a);

-- Statement 1054
SELECT DATE_PART('month', a);

-- Statement 1055
SELECT DATE_PART(month, a::DATETIME);

-- Statement 1056
SELECT DATE_PART(month, CAST(a AS DATETIME));

-- Statement 1057
SELECT DATE_PART(epoch_second, foo) as ddate from table_name;

-- Statement 1058
SELECT CAST(EPOCH(foo) AS BIGINT) AS ddate FROM table_name;

-- Statement 1059
SELECT TO_UNIXTIME(CAST(foo AS TIMESTAMP)) AS ddate FROM table_name;

-- Statement 1060
SELECT DATE_PART(epoch_milliseconds, foo) as ddate from table_name;

-- Statement 1061
SELECT DATE_PART(EPOCH_MILLISECOND, foo) AS ddate FROM table_name;

-- Statement 1062
SELECT EPOCH_MS(foo) AS ddate FROM table_name;

-- Statement 1063
SELECT TO_UNIXTIME(CAST(foo AS TIMESTAMP)) * 1000 AS ddate FROM table_name;

-- Statement 1064
SELECT TO_TIME(x) FROM t;

-- Statement 1065
SELECT TO_TIME('12:05:00');

-- Statement 1066
SELECT CAST('12:05:00' AS TIME);

-- Statement 1067
SELECT TO_TIME('2024-01-15 14:30:00'::TIMESTAMP);

-- Statement 1068
SELECT TIME(CAST('2024-01-15 14:30:00' AS DATETIME));

-- Statement 1069
SELECT TO_TIME(CAST('2024-01-15 14:30:00' AS TIMESTAMP));

-- Statement 1070
SELECT CAST(CAST('2024-01-15 14:30:00' AS TIMESTAMP) AS TIME);

-- Statement 1071
SELECT TO_TIME(CONVERT_TIMEZONE('UTC', 'US/Pacific', '2024-08-06 09:10:00.000')) AS pst_time;

-- Statement 1072
SELECT CAST(CAST('2024-08-06 09:10:00.000' AS TIMESTAMP) AT TIME ZONE 'UTC' AT TIME ZONE 'US/Pacific' AS TIME) AS pst_time;

-- Statement 1073
SELECT TO_TIME('11.15.00', 'hh24.mi.ss');

-- Statement 1074
SELECT CAST(STRPTIME('11.15.00', '%H.%M.%S') AS TIME);

-- Statement 1075
SELECT TO_TIME('093000', 'HH24MISS');

-- Statement 1076
SELECT CAST(STRPTIME('093000', '%H%M%S') AS TIME);

-- Statement 1077
SELECT TRY_TO_TIME('093000', 'HH24MISS');

-- Statement 1078
SELECT TRY_CAST(TRY_STRPTIME('093000', '%H%M%S') AS TIME);

-- Statement 1079
SELECT TRY_TO_TIME('11.15.00');

-- Statement 1080
SELECT TRY_CAST('11.15.00' AS TIME);

-- Statement 1081
SELECT TRY_TO_TIME('11.15.00', 'hh24.mi.ss');

-- Statement 1082
SELECT TRY_CAST(TRY_STRPTIME('11.15.00', '%H.%M.%S') AS TIME);

-- Statement 1083
SELECT TO_DATE('2019-02-28') + INTERVAL '1 day, 1 year';

-- Statement 1084
SELECT CAST('2019-02-28' AS DATE) + INTERVAL '1 day, 1 year';

-- Statement 1085
SELECT CAST(a AS VARIANT);

-- Statement 1086
SELECT CAST(a AS ARRAY);

-- Statement 1087
SELECT a::VARIANT;

-- Statement 1088
SELECT CAST(a AS SQL_VARIANT);

-- Statement 1089
SELECT a::OBJECT;

-- Statement 1090
SELECT CAST(a AS OBJECT);

-- Statement 1091
SELECT NEXT_DAY(CAST('2024-01-01' AS DATE), 'Monday');

-- Statement 1092
SELECT CAST(CAST('2024-01-01' AS DATE) + INTERVAL ((((1 - ISODOW(CAST('2024-01-01' AS DATE))) + 6) % 7) + 1) DAY AS DATE);

-- Statement 1093
SELECT NEXT_DAY(CAST('2024-01-05' AS DATE), 'Friday');

-- Statement 1094
SELECT CAST(CAST('2024-01-05' AS DATE) + INTERVAL ((((5 - ISODOW(CAST('2024-01-05' AS DATE))) + 6) % 7) + 1) DAY AS DATE);

-- Statement 1095
SELECT NEXT_DAY(CAST('2024-01-05' AS DATE), 'WE');

-- Statement 1096
SELECT CAST(CAST('2024-01-05' AS DATE) + INTERVAL ((((3 - ISODOW(CAST('2024-01-05' AS DATE))) + 6) % 7) + 1) DAY AS DATE);

-- Statement 1097
SELECT NEXT_DAY(CAST('2024-01-01 10:30:45' AS TIMESTAMP), 'Friday');

-- Statement 1098
SELECT CAST(CAST('2024-01-01 10:30:45' AS TIMESTAMP) + INTERVAL ((((5 - ISODOW(CAST('2024-01-01 10:30:45' AS TIMESTAMP))) + 6) % 7) + 1) DAY AS DATE);

-- Statement 1099
SELECT NEXT_DAY(CAST('2024-01-01' AS DATE), day_column);

-- Statement 1100
SELECT CAST(CAST('2024-01-01' AS DATE) + INTERVAL ((((CASE WHEN STARTS_WITH(UPPER(day_column), 'MO') THEN 1 WHEN STARTS_WITH(UPPER(day_column), 'TU') THEN 2 WHEN STARTS_WITH(UPPER(day_column), 'WE') THEN 3 WHEN STARTS_WITH(UPPER(day_column), 'TH') THEN 4 WHEN STARTS_WITH(UPPER(day_column), 'FR') THEN 5 WHEN STARTS_WITH(UPPER(day_column), 'SA') THEN 6 WHEN STARTS_WITH(UPPER(day_column), 'SU') THEN 7 END - ISODOW(CAST('2024-01-01' AS DATE))) + 6) % 7) + 1) DAY AS DATE);

-- Statement 1101
SELECT PREVIOUS_DAY(DATE '2024-01-15', 'Monday');

-- Statement 1102
SELECT CAST(CAST('2024-01-15' AS DATE) - INTERVAL ((((ISODOW(CAST('2024-01-15' AS DATE)) - 1) + 6) % 7) + 1) DAY AS DATE);

-- Statement 1103
SELECT PREVIOUS_DAY(CAST('2024-01-15' AS DATE), 'Monday');

-- Statement 1104
SELECT PREVIOUS_DAY(DATE '2024-01-15', 'Fr');

-- Statement 1105
SELECT CAST(CAST('2024-01-15' AS DATE) - INTERVAL ((((ISODOW(CAST('2024-01-15' AS DATE)) - 5) + 6) % 7) + 1) DAY AS DATE);

-- Statement 1106
SELECT PREVIOUS_DAY(CAST('2024-01-15' AS DATE), 'Fr');

-- Statement 1107
SELECT PREVIOUS_DAY(TIMESTAMP '2024-01-15 10:30:45', 'Monday');

-- Statement 1108
SELECT CAST(CAST('2024-01-15 10:30:45' AS TIMESTAMP) - INTERVAL ((((ISODOW(CAST('2024-01-15 10:30:45' AS TIMESTAMP)) - 1) + 6) % 7) + 1) DAY AS DATE);

-- Statement 1109
SELECT PREVIOUS_DAY(CAST('2024-01-15 10:30:45' AS TIMESTAMP), 'Monday');

-- Statement 1110
SELECT PREVIOUS_DAY(DATE '2024-01-15', day_column);

-- Statement 1111
SELECT CAST(CAST('2024-01-15' AS DATE) - INTERVAL ((((ISODOW(CAST('2024-01-15' AS DATE)) - CASE WHEN STARTS_WITH(UPPER(day_column), 'MO') THEN 1 WHEN STARTS_WITH(UPPER(day_column), 'TU') THEN 2 WHEN STARTS_WITH(UPPER(day_column), 'WE') THEN 3 WHEN STARTS_WITH(UPPER(day_column), 'TH') THEN 4 WHEN STARTS_WITH(UPPER(day_column), 'FR') THEN 5 WHEN STARTS_WITH(UPPER(day_column), 'SA') THEN 6 WHEN STARTS_WITH(UPPER(day_column), 'SU') THEN 7 END) + 6) % 7) + 1) DAY AS DATE);

-- Statement 1112
SELECT PREVIOUS_DAY(CAST('2024-01-15' AS DATE), day_column);

-- Statement 1113
SELECT * FROM my_table AT (STATEMENT => $query_id_var);

-- Statement 1114
SELECT * FROM my_table AT (OFFSET => -60 * 5);

-- Statement 1115
SELECT * FROM my_table BEFORE (STATEMENT => $query_id_var);

-- Statement 1116
SELECT * FROM my_table BEFORE (OFFSET => -60 * 5);

-- Statement 1117
SELECT * FROM my_table AT (TIMESTAMP => TO_TIMESTAMP(1432669154242, 3));

-- Statement 1118
SELECT * FROM my_table AT (OFFSET => -60 * 5) AS T WHERE T.flag = 'valid';

-- Statement 1119
SELECT * FROM my_table AT (STATEMENT => '8e5d0ca9-005e-44e6-b858-a8f5b37c5726');

-- Statement 1120
SELECT * FROM my_table BEFORE (STATEMENT => '8e5d0ca9-005e-44e6-b858-a8f5b37c5726');

-- Statement 1121
SELECT * FROM my_table AT (TIMESTAMP => 'Fri, 01 May 2015 16:20:00 -0700'::timestamp);

-- Statement 1122
SELECT * FROM my_table AT (TIMESTAMP => CAST('Fri, 01 May 2015 16:20:00 -0700' AS TIMESTAMP));

-- Statement 1123
SELECT * FROM my_table AT(TIMESTAMP => 'Fri, 01 May 2015 16:20:00 -0700'::timestamp_tz);

-- Statement 1124
SELECT * FROM my_table AT (TIMESTAMP => CAST('Fri, 01 May 2015 16:20:00 -0700' AS TIMESTAMPTZ));

-- Statement 1125
SELECT * FROM my_table BEFORE (TIMESTAMP => 'Fri, 01 May 2015 16:20:00 -0700'::timestamp_tz);

-- Statement 1126
SELECT * FROM my_table BEFORE (TIMESTAMP => CAST('Fri, 01 May 2015 16:20:00 -0700' AS TIMESTAMPTZ));

-- Statement 1127
SELECT oldt.* , newt.*
FROM my_table BEFORE(STATEMENT => '8e5d0ca9-005e-44e6-b858-a8f5b37c5726') AS oldt
FULL OUTER JOIN my_table AT(STATEMENT => '8e5d0ca9-005e-44e6-b858-a8f5b37c5726') AS newt
ON oldt.id = newt.id
WHERE oldt.id IS NULL OR newt.id IS NULL;

-- Statement 1128
SELECT oldt.*, newt.* FROM my_table BEFORE (STATEMENT => '8e5d0ca9-005e-44e6-b858-a8f5b37c5726') AS oldt FULL OUTER JOIN my_table AT (STATEMENT => '8e5d0ca9-005e-44e6-b858-a8f5b37c5726') AS newt ON oldt.id = newt.id WHERE oldt.id IS NULL OR newt.id IS NULL;

-- Statement 1129
SELECT * FROM foo {historical_data_prefix}{schema_suffix};

-- Statement 1130
SELECT * FROM foo AS {historical_data_prefix}{schema_suffix};

-- Statement 1131
SELECT * FROM TABLE('MYTABLE');

-- Statement 1132
SELECT * FROM TABLE($MYVAR);

-- Statement 1133
SELECT * FROM TABLE(?);

-- Statement 1134
SELECT * FROM TABLE(:BINDING);

-- Statement 1135
SELECT * FROM TABLE($MYVAR) WHERE COL1 = 10;

-- Statement 1136
SELECT * FROM TABLE('t1') AS f;

-- Statement 1137
SELECT * FROM (TABLE('t1') CROSS JOIN TABLE('t2'));

-- Statement 1138
SELECT * FROM TABLE('t1'), LATERAL (SELECT * FROM t2);

-- Statement 1139
SELECT * FROM TABLE('t1') UNION ALL SELECT * FROM TABLE('t2');

-- Statement 1140
SELECT * FROM TABLE('t1') TABLESAMPLE BERNOULLI (20.3);

-- Statement 1141
SELECT * FROM TABLE('MYDB."MYSCHEMA"."MYTABLE"');

-- Statement 1142
SELECT * FROM TABLE($$MYDB. "MYSCHEMA"."MYTABLE"$$);

-- Statement 1143
SELECT * FROM TABLE('MYDB. "MYSCHEMA"."MYTABLE"');

-- Statement 1144
SELECT value FROM TABLE(FLATTEN(input => SELECT PARSE_JSON('[1, 2]')));

-- Statement 1145
SELECT * FROM TABLE(FLATTEN(input => parse_json('[1, ,77]'))) f;

-- Statement 1146
SELECT * FROM TABLE(FLATTEN(input => PARSE_JSON('[1, ,77]'))) AS f;

-- Statement 1147
SELECT * FROM TABLE(FLATTEN(input => parse_json('{"a":1, "b":[77,88]}'), outer => true)) f;

-- Statement 1148
SELECT * FROM TABLE(FLATTEN(input => PARSE_JSON('{"a":1, "b":[77,88]}'), outer => TRUE)) AS f;

-- Statement 1149
SELECT * FROM TABLE(FLATTEN(input => parse_json('{"a":1, "b":[77,88]}'), path => 'b')) f;

-- Statement 1150
SELECT * FROM TABLE(FLATTEN(input => PARSE_JSON('{"a":1, "b":[77,88]}'), path => 'b')) AS f;

-- Statement 1151
SELECT * FROM TABLE(FLATTEN(input => parse_json('[]'))) f;

-- Statement 1152
SELECT * FROM TABLE(FLATTEN(input => PARSE_JSON('[]'))) AS f;

-- Statement 1153
SELECT * FROM TABLE(FLATTEN(input => parse_json('[]'), outer => true)) f;

-- Statement 1154
SELECT * FROM TABLE(FLATTEN(input => PARSE_JSON('[]'), outer => TRUE)) AS f;

-- Statement 1155
SELECT * FROM TABLE(FLATTEN(input => parse_json('{"a":1, "b":[77,88], "c": {"d":"X"}}'))) f;

-- Statement 1156
SELECT * FROM TABLE(FLATTEN(input => PARSE_JSON('{"a":1, "b":[77,88], "c": {"d":"X"}}'))) AS f;

-- Statement 1157
SELECT * FROM TABLE(FLATTEN(input => parse_json('{"a":1, "b":[77,88], "c": {"d":"X"}}'), recursive => true)) f;

-- Statement 1158
SELECT * FROM TABLE(FLATTEN(input => PARSE_JSON('{"a":1, "b":[77,88], "c": {"d":"X"}}'), recursive => TRUE)) AS f;

-- Statement 1159
SELECT * FROM TABLE(FLATTEN(input => parse_json('{"a":1, "b":[77,88], "c": {"d":"X"}}'), recursive => true, mode => 'object')) f;

-- Statement 1160
SELECT * FROM TABLE(FLATTEN(input => PARSE_JSON('{"a":1, "b":[77,88], "c": {"d":"X"}}'), recursive => TRUE, mode => 'object')) AS f;

-- Statement 1161
SELECT id as "ID",
  f.value AS "Contact",
  f1.value:type AS "Type",
  f1.value:content AS "Details"
FROM persons p,
  lateral flatten(input => p.c, path => 'contact') f,
  lateral flatten(input => f.value:business) f1;

-- Statement 1162
SELECT id as "ID",
  value AS "Contact"
FROM persons p,
  lateral flatten(input => p.c, path => 'contact');

-- Statement 1163
SELECT 1 EXCEPT SELECT 1;

-- Statement 1164
SELECT 1 MINUS SELECT 1;

-- Statement 1165
SELECT * FROM (SELECT OBJECT_CONSTRUCT('a', 1));

-- Statement 1166
SELECT "c0", "c1" FROM (VALUES (1, 2), (3, 4)) AS "t0"("c0", "c1");

-- Statement 1167
SELECT `c0`, `c1` FROM (VALUES (1, 2), (3, 4)) AS `t0`(`c0`, `c1`);

-- Statement 1168
SELECT $1 AS "_1" FROM VALUES ('a'), ('b');

-- Statement 1169
SELECT $1 AS "_1" FROM (VALUES ('a'), ('b'));

-- Statement 1170
SELECT ${1} AS `_1` FROM VALUES ('a'), ('b');

-- Statement 1171
SELECT * FROM (SELECT OBJECT_CONSTRUCT('a', 1) AS x) AS t;

-- Statement 1172
SELECT * FROM (VALUES ({'a': 1})) AS t(x);

-- Statement 1173
SELECT * FROM (SELECT OBJECT_CONSTRUCT('a', 1) AS x UNION ALL SELECT OBJECT_CONSTRUCT('a', 2)) AS t;

-- Statement 1174
SELECT * FROM (VALUES ({'a': 1}), ({'a': 2})) AS t(x);

-- Statement 1175
SELECT {token} FROM t;

-- Statement 1176
SELECT 1 AS {token};

-- Statement 1177
SELECT SEARCH((play, line), 'dream');

-- Statement 1178
SELECT SEARCH(line, 'king', ANALYZER => 'UNICODE_ANALYZER');

-- Statement 1179
SELECT SEARCH(character, 'king queen', SEARCH_MODE => 'AND');

-- Statement 1180
SELECT SEARCH(line, 'king', ANALYZER => 'UNICODE_ANALYZER', SEARCH_MODE => 'OR');

-- Statement 1181
SELECT SEARCH(line, 'king');

-- Statement 1182
SELECT SEARCH(line, 'king', SEARCH_MODE => 'AND', ANALYZER => 'PATTERN_ANALYZER');

-- Statement 1183
SELECT SEARCH(line, 'king', ANALYZER => 'PATTERN_ANALYZER', SEARCH_MODE => 'AND');

-- Statement 1184
SELECT SEARCH_IP(col, '192.168.0.0');

-- Statement 1185
SELECT REGEXP_COUNT('hello world', 'l ');

-- Statement 1186
SELECT REGEXP_COUNT('hello world', 'l', 1);

-- Statement 1187
SELECT REGEXP_COUNT('hello world', 'l', 1, 'i');

-- Statement 1188
SELECT REGEXP_COUNT('hello', 'l');

-- Statement 1189
SELECT CASE WHEN 'l' = '' THEN 0 ELSE LENGTH(REGEXP_EXTRACT_ALL('hello', 'l')) END;

-- Statement 1190
SELECT REGEXP_COUNT('hello world', 'l', 7);

-- Statement 1191
SELECT CASE WHEN 'l' = '' THEN 0 ELSE LENGTH(REGEXP_EXTRACT_ALL(SUBSTRING('hello world', 7), 'l')) END;

-- Statement 1192
SELECT REGEXP_COUNT('Hello World', 'L', 1, 'im');

-- Statement 1193
SELECT CASE WHEN '(?im)' || 'L' = '' THEN 0 ELSE LENGTH(REGEXP_EXTRACT_ALL(SUBSTRING('Hello World', 1), '(?im)' || 'L')) END;

-- Statement 1194
SELECT REGEXP_COUNT(subject, pattern);

-- Statement 1195
SELECT CASE WHEN pattern = '' THEN 0 ELSE LENGTH(REGEXP_EXTRACT_ALL(subject, pattern)) END;

-- Statement 1196
SELECT REGEXP_INSTR('abc', 'a');

-- Statement 1197
SELECT REGEXP_INSTR('abc', 'a', 1, 1, 0, 'i');

-- Statement 1198
SELECT REGEXP_INSTR(subject, pattern);

-- Statement 1199
SELECT CASE WHEN subject IS NULL OR pattern IS NULL THEN NULL WHEN pattern = '' THEN 0 WHEN LENGTH(REGEXP_EXTRACT_ALL(subject, pattern)) < 1 THEN 0 ELSE 1 + COALESCE(LIST_SUM(LIST_TRANSFORM(STRING_SPLIT_REGEX(subject, pattern)[1:1], x -> LENGTH(x))), 0) + COALESCE(LIST_SUM(LIST_TRANSFORM(REGEXP_EXTRACT_ALL(subject, pattern)[1:1 - 1], x -> LENGTH(x))), 0) + 0 END;

-- Statement 1200
SELECT REGEXP_INSTR(subject, pattern, 5);

-- Statement 1201
SELECT CASE WHEN subject IS NULL OR pattern IS NULL OR 5 IS NULL THEN NULL WHEN pattern = '' THEN 0 WHEN LENGTH(REGEXP_EXTRACT_ALL(SUBSTRING(subject, 5), pattern)) < 1 THEN 0 ELSE 1 + COALESCE(LIST_SUM(LIST_TRANSFORM(STRING_SPLIT_REGEX(SUBSTRING(subject, 5), pattern)[1:1], x -> LENGTH(x))), 0) + COALESCE(LIST_SUM(LIST_TRANSFORM(REGEXP_EXTRACT_ALL(SUBSTRING(subject, 5), pattern)[1:1 - 1], x -> LENGTH(x))), 0) + 5 - 1 END;

-- Statement 1202
SELECT REGEXP_INSTR(subject, pattern, 1, 2);

-- Statement 1203
SELECT CASE WHEN subject IS NULL OR pattern IS NULL OR 1 IS NULL OR 2 IS NULL THEN NULL WHEN pattern = '' THEN 0 WHEN LENGTH(REGEXP_EXTRACT_ALL(subject, pattern)) < 2 THEN 0 ELSE 1 + COALESCE(LIST_SUM(LIST_TRANSFORM(STRING_SPLIT_REGEX(subject, pattern)[1:2], x -> LENGTH(x))), 0) + COALESCE(LIST_SUM(LIST_TRANSFORM(REGEXP_EXTRACT_ALL(subject, pattern)[1:2 - 1], x -> LENGTH(x))), 0) + 0 END;

-- Statement 1204
SELECT REGEXP_INSTR(subject, pattern, 1, 1, 0, 'im');

-- Statement 1205
SELECT CASE WHEN subject IS NULL OR pattern IS NULL OR 1 IS NULL OR 1 IS NULL OR 0 IS NULL OR 'im' IS NULL THEN NULL WHEN '(?im)' || pattern = '' THEN 0 WHEN LENGTH(REGEXP_EXTRACT_ALL(subject, '(?im)' || pattern)) < 1 THEN 0 ELSE 1 + COALESCE(LIST_SUM(LIST_TRANSFORM(STRING_SPLIT_REGEX(subject, '(?im)' || pattern)[1:1], x -> LENGTH(x))), 0) + COALESCE(LIST_SUM(LIST_TRANSFORM(REGEXP_EXTRACT_ALL(subject, '(?im)' || pattern)[1:1 - 1], x -> LENGTH(x))), 0) + 0 END;

-- Statement 1206
SELECT TRY_CAST(x AS DOUBLE);

-- Statement 1207
SELECT TRY_CAST(FOO() AS TEXT);

-- Statement 1208
SELECT TRY_CAST(FOO() AS VARCHAR);

-- Statement 1209
SELECT CAST(t.x AS STRING) FROM t;

-- Statement 1210
SELECT {func}(t.x AS VARCHAR) FROM t;

-- Statement 1211
SELECT TRY_PARSE_JSON(x);

-- Statement 1212
SELECT CASE WHEN JSON_VALID(x) THEN CAST(x AS JSON) ELSE NULL END;

-- Statement 1213
SELECT CAST(1.5 AS DECFLOAT);

-- Statement 1214
SELECT CAST(1.5 AS DECIMAL(38, 5));

-- Statement 1215
COPY INTO test (c1) FROM (SELECT $1.c1 FROM @mystage);

-- Statement 1216
COPY INTO temp FROM @random_stage/path/ FILE_FORMAT = (TYPE=CSV FIELD_DELIMITER='|' NULL_IF=('str1', 'str2') FIELD_OPTIONALLY_ENCLOSED_BY='"' TIMESTAMP_FORMAT='TZHTZM YYYY-MM-DD HH24:MI:SS.FF9' DATE_FORMAT='TZHTZM YYYY-MM-DD HH24:MI:SS.FF9' BINARY_FORMAT=BASE64) VALIDATION_MODE = 'RETURN_3_ROWS';

-- Statement 1217
COPY INTO load1 FROM @%load1/data1/ CREDENTIALS = (AWS_KEY_ID='id' AWS_SECRET_KEY='key' AWS_TOKEN='token') FILES = ('test1.csv', 'test2.csv') FORCE = TRUE;

-- Statement 1218
COPY INTO mytable FROM 'azure://myaccount.blob.core.windows.net/mycontainer/data/files' CREDENTIALS = (AZURE_SAS_TOKEN='token') ENCRYPTION = (TYPE='AZURE_CSE' MASTER_KEY='kPx...') FILE_FORMAT = (FORMAT_NAME=my_csv_format);

-- Statement 1219
COPY INTO mytable (col1, col2) FROM 's3://mybucket/data/files' STORAGE_INTEGRATION = "storage" ENCRYPTION = (TYPE='NONE' MASTER_KEY='key') FILES = ('file1', 'file2') PATTERN = 'pattern' FILE_FORMAT = (FORMAT_NAME=my_csv_format NULL_IF=('')) PARSE_HEADER = TRUE;

-- Statement 1220
COPY INTO @my_stage/result/data FROM (SELECT * FROM orderstiny) FILE_FORMAT = (TYPE='csv');

-- Statement 1221
COPY INTO mytable FILE_FORMAT = (TYPE='csv');

-- Statement 1222
COPY INTO MY_DATABASE.MY_SCHEMA.MY_TABLE FROM @MY_DATABASE.MY_SCHEMA.MY_STAGE/my_path FILE_FORMAT = (FORMAT_NAME=MY_DATABASE.MY_SCHEMA.MY_FILE_FORMAT);

-- Statement 1223
COPY INTO 's3://example/data.csv'
FROM EXTRA.EXAMPLE.TABLE
CREDENTIALS = ()
FILE_FORMAT = (TYPE = CSV COMPRESSION = NONE NULL_IF = ('') FIELD_OPTIONALLY_ENCLOSED_BY = '"')
HEADER = TRUE
OVERWRITE = TRUE
SINGLE = TRUE;

-- Statement 1224
COPY INTO 's3://example/data.csv'
FROM EXTRA.EXAMPLE.TABLE
CREDENTIALS = () WITH (
  FILE_FORMAT = (TYPE=CSV COMPRESSION=NONE NULL_IF=(
    ''
  ) FIELD_OPTIONALLY_ENCLOSED_BY='"'),
  HEADER TRUE,
  OVERWRITE TRUE,
  SINGLE TRUE
);

-- Statement 1225
COPY INTO 's3://example/data.csv'
FROM EXTRA.EXAMPLE.TABLE
CREDENTIALS = ()
FILE_FORMAT = (TYPE=CSV COMPRESSION=NONE NULL_IF=(
  ''
) FIELD_OPTIONALLY_ENCLOSED_BY='"')
HEADER = TRUE
OVERWRITE = TRUE
SINGLE = TRUE;

-- Statement 1226
COPY INTO 's3://example/data.csv'
FROM EXTRA.EXAMPLE.TABLE
STORAGE_INTEGRATION = S3_INTEGRATION
FILE_FORMAT = (TYPE=CSV COMPRESSION=NONE NULL_IF=('') FIELD_OPTIONALLY_ENCLOSED_BY='"')
HEADER = TRUE
OVERWRITE = TRUE
SINGLE = TRUE;

-- Statement 1227
COPY INTO 's3://example/data.csv' FROM EXTRA.EXAMPLE.TABLE STORAGE_INTEGRATION = S3_INTEGRATION WITH (FILE_FORMAT = (TYPE=CSV COMPRESSION=NONE NULL_IF=('') FIELD_OPTIONALLY_ENCLOSED_BY='"'), HEADER TRUE, OVERWRITE TRUE, SINGLE TRUE);

-- Statement 1228
COPY INTO 's3://example/data.csv' FROM EXTRA.EXAMPLE.TABLE STORAGE_INTEGRATION = S3_INTEGRATION FILE_FORMAT = (TYPE=CSV COMPRESSION=NONE NULL_IF=('') FIELD_OPTIONALLY_ENCLOSED_BY='"') HEADER = TRUE OVERWRITE = TRUE SINGLE = TRUE;

-- Statement 1229
COPY INTO 's3://example/contacts.csv' FROM db.tbl STORAGE_INTEGRATION = PROD_S3_SIDETRADE_INTEGRATION FILE_FORMAT = (FORMAT_NAME=my_csv_format TYPE=CSV COMPRESSION=NONE NULL_IF=('') FIELD_OPTIONALLY_ENCLOSED_BY='"') MATCH_BY_COLUMN_NAME = CASE_SENSITIVE OVERWRITE = TRUE SINGLE = TRUE INCLUDE_METADATA = (col1 = METADATA$START_SCAN_TIME);

-- Statement 1230
COPY INTO 's3://example/contacts.csv' FROM "db"."tbl" STORAGE_INTEGRATION = "PROD_S3_SIDETRADE_INTEGRATION" FILE_FORMAT = (FORMAT_NAME="my_csv_format" TYPE=CSV COMPRESSION=NONE NULL_IF=('') FIELD_OPTIONALLY_ENCLOSED_BY='"') MATCH_BY_COLUMN_NAME = CASE_SENSITIVE OVERWRITE = TRUE SINGLE = TRUE INCLUDE_METADATA = ("col1" = "METADATA$START_SCAN_TIME");

-- Statement 1231
SELECT $1;

-- Statement 1232
SELECT $1.elem;

-- Statement 1233
SELECT $1:a.b;

-- Statement 1234
SELECT GET_PATH($1, 'a.b');

-- Statement 1235
SELECT t.$23:a.b;

-- Statement 1236
SELECT GET_PATH(t.$23, 'a.b');

-- Statement 1237
SELECT t.$17:a[0].b[0].c;

-- Statement 1238
SELECT GET_PATH(t.$17, 'a[0].b[0].c');

-- Statement 1239
WITH t AS (SELECT PARSE_JSON('{"a": [1, 2]}') AS v), s AS (SELECT 1 AS x) SELECT t.v:a[s.x] FROM t, s;

-- Statement 1240
WITH t AS (SELECT PARSE_JSON('{"a": [1, 2]}') AS v), s AS (SELECT 1 AS x) SELECT GET_PATH(t.v, 'a')[s.x] FROM t, s;

-- Statement 1241
WITH t AS (SELECT JSON('{"a": [1, 2]}') AS v), s AS (SELECT 1 AS x) SELECT (t.v -> '$.a')[s.x] FROM t, s;

-- Statement 1242
WITH t AS (SELECT PARSE_JSON('{"c": [{"r": 1}]}') AS v), s AS (SELECT 0 AS x) SELECT t.v:c[s.x]:r FROM t, s;

-- Statement 1243
WITH t AS (SELECT PARSE_JSON('{"c": [{"r": 1}]}') AS v), s AS (SELECT 0 AS x) SELECT GET_PATH(GET_PATH(t.v, 'c')[s.x], 'r') FROM t, s;

-- Statement 1244
WITH t AS (SELECT JSON('{"c": [{"r": 1}]}') AS v), s AS (SELECT 0 AS x) SELECT (t.v -> '$.c')[s.x] -> '$.r' FROM t, s;

-- Statement 1245
WITH t AS (SELECT PARSE_JSON('{"c": [{"r": {"d": 1}}]}') AS v), s AS (SELECT 0 AS x) SELECT t.v:c[s.x]:r:d::varchar FROM t, s;

-- Statement 1246
WITH t AS (SELECT PARSE_JSON('{"c": [{"r": {"d": 1}}]}') AS v), s AS (SELECT 0 AS x) SELECT CAST(GET_PATH(GET_PATH(t.v, 'c')[s.x], 'r.d') AS VARCHAR) FROM t, s;

-- Statement 1247
WITH t AS (SELECT JSON('{"c": [{"r": {"d": 1}}]}') AS v), s AS (SELECT 0 AS x) SELECT CAST((t.v -> '$.c')[s.x] -> '$.r.d' AS TEXT) FROM t, s;

-- Statement 1248
WITH t AS (SELECT PARSE_JSON('{"a": {"b": [1, 2]}}') AS v), s AS (SELECT 1 AS x) SELECT t.v:a:b[s.x] FROM t, s;

-- Statement 1249
WITH t AS (SELECT PARSE_JSON('{"a": {"b": [1, 2]}}') AS v), s AS (SELECT 1 AS x) SELECT GET_PATH(t.v, 'a.b')[s.x] FROM t, s;

-- Statement 1250
WITH t AS (SELECT JSON('{"a": {"b": [1, 2]}}') AS v), s AS (SELECT 1 AS x) SELECT (t.v -> '$.a.b')[s.x] FROM t, s;

-- Statement 1251
WITH t AS (SELECT PARSE_JSON('{"c": [{"r": 1}]}') AS v), s AS (SELECT 0 AS x) SELECT t.v:c[s.x].r FROM t, s;

-- Statement 1252
WITH t AS (SELECT PARSE_JSON('{"c": [{"r": {"d": 1}}]}') AS v), s AS (SELECT 0 AS x) SELECT t.v:c[s.x].r.d FROM t, s;

-- Statement 1253
WITH t AS (SELECT PARSE_JSON('{"c": [{"r": {"d": 1}}]}') AS v), s AS (SELECT 0 AS x) SELECT GET_PATH(GET_PATH(t.v, 'c')[s.x], 'r.d') FROM t, s;

-- Statement 1254
WITH t AS (SELECT JSON('{"c": [{"r": {"d": 1}}]}') AS v), s AS (SELECT 0 AS x) SELECT (t.v -> '$.c')[s.x] -> '$.r.d' FROM t, s;

-- Statement 1255
WITH t AS (SELECT PARSE_JSON('{"c": [{"r": {"d": {"e": 1}}}]}') AS v), s AS (SELECT 0 AS x) SELECT t.v:c[s.x].r.d.e FROM t, s;

-- Statement 1256
WITH t AS (SELECT PARSE_JSON('{"c": [{"r": {"d": {"e": 1}}}]}') AS v), s AS (SELECT 0 AS x) SELECT GET_PATH(GET_PATH(t.v, 'c')[s.x], 'r.d.e') FROM t, s;

-- Statement 1257
WITH t AS (SELECT JSON('{"c": [{"r": {"d": {"e": 1}}}]}') AS v), s AS (SELECT 0 AS x) SELECT (t.v -> '$.c')[s.x] -> '$.r.d.e' FROM t, s;

-- Statement 1258
WITH t AS (SELECT PARSE_JSON('{"a": {"b": [{"r": {"d": 1}}]}}') AS v), s AS (SELECT 0 AS x) SELECT t.v:a.b[s.x].r.d FROM t, s;

-- Statement 1259
WITH t AS (SELECT PARSE_JSON('{"a": {"b": [{"r": {"d": 1}}]}}') AS v), s AS (SELECT 0 AS x) SELECT GET_PATH(GET_PATH(t.v, 'a.b')[s.x], 'r.d') FROM t, s;

-- Statement 1260
WITH t AS (SELECT JSON('{"a": {"b": [{"r": {"d": 1}}]}}') AS v), s AS (SELECT 0 AS x) SELECT (t.v -> '$.a.b')[s.x] -> '$.r.d' FROM t, s;

-- Statement 1261
WITH t AS (SELECT PARSE_JSON('{"a": {"b": [{"r": {"d": [10, 20, 30]}}]}}') AS v), s AS (SELECT 0 AS x, 2 AS y) SELECT t.v:a.b[s.x].r.d[s.y] FROM t, s;

-- Statement 1262
WITH t AS (SELECT PARSE_JSON('{"a": {"b": [{"r": {"d": [10, 20, 30]}}]}}') AS v), s AS (SELECT 0 AS x, 2 AS y) SELECT GET_PATH(GET_PATH(t.v, 'a.b')[s.x], 'r.d')[s.y] FROM t, s;

-- Statement 1263
WITH t AS (SELECT JSON('{"a": {"b": [{"r": {"d": [10, 20, 30]}}]}}') AS v), s AS (SELECT 0 AS x, 2 AS y) SELECT ((t.v -> '$.a.b')[s.x] -> '$.r.d')[s.y] FROM t, s;

-- Statement 1264
SELECT col:"customer's department";

-- Statement 1265
SELECT GET_PATH(col, '["customer\\'s department"]');

-- Statement 1266
SELECT JSON_EXTRACT_PATH(col, 'customer''s department');

-- Statement 1267
SELECT C1 FROM t1 CHANGES (INFORMATION => APPEND_ONLY) AT (STREAM => 's1') END (TIMESTAMP => $ts2);

-- Statement 1268
SELECT C1 FROM t1 CHANGES (INFORMATION => APPEND_ONLY) BEFORE (STATEMENT => 'STMT_ID') END (TIMESTAMP => $ts2);

-- Statement 1269
SELECT 1 FROM some_table CHANGES (INFORMATION => APPEND_ONLY) AT (TIMESTAMP => TO_TIMESTAMP_TZ('2024-07-01 00:00:00+00:00')) END (TIMESTAMP => TO_TIMESTAMP_TZ('2024-07-01 14:28:59.999999+00:00'));

-- Statement 1270
SELECT 1 FROM some_table CHANGES (INFORMATION => APPEND_ONLY) AT (TIMESTAMP => CAST('2024-07-01 00:00:00+00:00' AS TIMESTAMPTZ)) END (TIMESTAMP => CAST('2024-07-01 14:28:59.999999+00:00' AS TIMESTAMPTZ));

-- Statement 1271
SELECT * FROM TABLE(db.schema.FUNC(a) OVER ());

-- Statement 1272
SELECT 1 ORDER BY 1 LIMIT NULL OFFSET 0;

-- Statement 1273
SELECT 1 ORDER BY 1 OFFSET 0;

-- Statement 1274
SELECT LISTAGG({distinct}col, '|SEPARATOR|') WITHIN GROUP (ORDER BY col2) FROM t;

-- Statement 1275
SELECT LISTAGG({distinct}col, '|SEPARATOR|' ORDER BY col2) FROM t;

-- Statement 1276
SELECT :1;

-- Statement 1277
SELECT :1, :2;

-- Statement 1278
SELECT :1 + :2;

-- Statement 1279
SELECT MAX_BY(a, b) FROM t;

-- Statement 1280
SELECT ARG_MAX(a, b) FROM t;

-- Statement 1281
SELECT MIN_BY(a, b) FROM t;

-- Statement 1282
SELECT ARG_MIN(a, b) FROM t;

-- Statement 1283
SELECT * FROM SEMANTIC_VIEW(tbl{metrics_str}{dimensions_str}{fact_str}{where_str}) ORDER BY foo;

-- Statement 1284
SELECT * FROM SEMANTIC_VIEW(tbl{dimensions_str}{fact_str}{metrics_str}{where_str});

-- Statement 1285
SELECT * FROM SEMANTIC_VIEW(tbl{metrics_str}{dimensions_str}{fact_str}{where_str});

-- Statement 1286
SELECT * FROM SEMANTIC_VIEW(foo METRICS a.b, a.c DIMENSIONS a.b, a.c WHERE a.b > '1995-01-01');

-- Statement 1287
SELECT col1, col2, metric1 FROM SEMANTIC_VIEW(mydb.myschema.my_semantic_view METRICS metric1 DIMENSIONS col1, DATE_TRUNC('MONTH', timestamp_col) AS col2) ORDER BY col1, col2 DESC;

-- Statement 1288
SELECT GET([4, 5, 6], 1);

-- Statement 1289
SELECT [4, 5, 6][2];

-- Statement 1290
SELECT GET(col::MAP(INTEGER, VARCHAR), 1);

-- Statement 1291
SELECT GET(CAST(col AS MAP(INT, VARCHAR)), 1);

-- Statement 1292
SELECT CAST(col AS MAP(INT, TEXT))[1];

-- Statement 1293
SELECT GET(v, 'field');

-- Statement 1294
SELECT v -> '$.field';

-- Statement 1295
SELECT model!mladmin;

-- Statement 1296
SELECT model!PREDICT(1);

-- Statement 1297
SELECT m!PREDICT(INPUT_DATA => {*}) AS p FROM tbl;

-- Statement 1298
SELECT m!PREDICT(INPUT_DATA => {tbl.*}) AS p FROM tbl;

-- Statement 1299
SELECT * FROM TABLE(model_trained_with_labeled_data!DETECT_ANOMALIES(INPUT_DATA => TABLE(view_with_data_to_analyze), TIMESTAMP_COLNAME => 'date', TARGET_COLNAME => 'sales', CONFIG_OBJECT => OBJECT_CONSTRUCT('prediction_interval', 0.99)));

-- Statement 1300
SELECT ROUND(2.25) AS value;

-- Statement 1301
SELECT ROUND(2.25, 1) AS value;

-- Statement 1302
SELECT ROUND(EXPR => 2.25, SCALE => 1) AS value;

-- Statement 1303
SELECT ROUND(SCALE => 1, EXPR => 2.25) AS value;

-- Statement 1304
SELECT ROUND(2.25, 1, 'HALF_AWAY_FROM_ZERO') AS value;

-- Statement 1305
SELECT ROUND(EXPR => 2.25, SCALE => 1, ROUNDING_MODE => 'HALF_AWAY_FROM_ZERO') AS value;

-- Statement 1306
SELECT ROUND(2.25, 1, 'HALF_TO_EVEN') AS value;

-- Statement 1307
SELECT ROUND_EVEN(2.25, 1) AS value;

-- Statement 1308
SELECT ROUND(ROUNDING_MODE => 'HALF_TO_EVEN', EXPR => 2.25, SCALE => 1) AS value;

-- Statement 1309
SELECT ROUND(SCALE => 1, EXPR => 2.25, , ROUNDING_MODE => 'HALF_TO_EVEN') AS value;

-- Statement 1310
SELECT ROUND(EXPR => 2.25, SCALE => 1, ROUNDING_MODE => 'HALF_TO_EVEN') AS value;

-- Statement 1311
SELECT ROUND(2.256, 1.8) AS value;

-- Statement 1312
SELECT ROUND(2.256, CAST(1.8 AS INT)) AS value;

-- Statement 1313
SELECT ROUND(2.256, CAST(1.8 AS DECIMAL(38, 0))) AS value;

-- Statement 1314
SELECT ROUND(2.256, CAST(CAST(1.8 AS DECIMAL(38, 0)) AS INT)) AS value;

-- Statement 1315
SELECT GETBIT(11, 1);

-- Statement 1316
SELECT BITOR(x'FF', x'0F');

-- Statement 1317
SELECT CAST(CAST(UNHEX('FF') AS BIT) | CAST(UNHEX('0F') AS BIT) AS BLOB);

-- Statement 1318
SELECT BITAND(x'FF', x'0F');

-- Statement 1319
SELECT CAST(CAST(UNHEX('FF') AS BIT) & CAST(UNHEX('0F') AS BIT) AS BLOB);

-- Statement 1320
SELECT BITXOR(x'FF', x'0F');

-- Statement 1321
SELECT CAST(XOR(CAST(UNHEX('FF') AS BIT), CAST(UNHEX('0F') AS BIT)) AS BLOB);

-- Statement 1322
SELECT BITNOT(x'FF');

-- Statement 1323
SELECT CAST(~CAST(UNHEX('FF') AS BIT) AS BLOB);

-- Statement 1324
select a, B from DUAL;

-- Statement 1325
SELECT a, "B" FROM DUAL;

-- Statement 1326
SELECT FLOOR(1.753, 2);

-- Statement 1327
SELECT ROUND(FLOOR(1.753 * POWER(10, 2)) / POWER(10, 2), 2);

-- Statement 1328
SELECT FLOOR(123.45, -1);

-- Statement 1329
SELECT ROUND(FLOOR(123.45 * POWER(10, -1)) / POWER(10, -1), -1);

-- Statement 1330
SELECT FLOOR(a + b, 2);

-- Statement 1331
SELECT ROUND(FLOOR((a + b) * POWER(10, 2)) / POWER(10, 2), 2);

-- Statement 1332
SELECT FLOOR(1.234, 1.5);

-- Statement 1333
SELECT ROUND(FLOOR(1.234 * POWER(10, CAST(1.5 AS INT))) / POWER(10, CAST(1.5 AS INT)), CAST(1.5 AS INT));

-- Statement 1334
SELECT SEQ1() FROM test;

-- Statement 1335
SELECT (ROW_NUMBER() OVER (ORDER BY 1 NULLS FIRST) - 1) % 256 FROM test;

-- Statement 1336
SELECT SEQ1(0) FROM test;

-- Statement 1337
SELECT SEQ1(1) FROM test;

-- Statement 1338
SELECT (CASE WHEN (ROW_NUMBER() OVER (ORDER BY 1 NULLS FIRST) - 1) % 256 >= 128 THEN (ROW_NUMBER() OVER (ORDER BY 1 NULLS FIRST) - 1) % 256 - 256 ELSE (ROW_NUMBER() OVER (ORDER BY 1 NULLS FIRST) - 1) % 256 END) FROM test;

-- Statement 1339
SELECT SEQ2() FROM test;

-- Statement 1340
SELECT (ROW_NUMBER() OVER (ORDER BY 1 NULLS FIRST) - 1) % 65536 FROM test;

-- Statement 1341
SELECT SEQ2(0) FROM test;

-- Statement 1342
SELECT SEQ2(1) FROM test;

-- Statement 1343
SELECT (CASE WHEN (ROW_NUMBER() OVER (ORDER BY 1 NULLS FIRST) - 1) % 65536 >= 32768 THEN (ROW_NUMBER() OVER (ORDER BY 1 NULLS FIRST) - 1) % 65536 - 65536 ELSE (ROW_NUMBER() OVER (ORDER BY 1 NULLS FIRST) - 1) % 65536 END) FROM test;

-- Statement 1344
SELECT SEQ4() FROM test;

-- Statement 1345
SELECT (ROW_NUMBER() OVER (ORDER BY 1 NULLS FIRST) - 1) % 4294967296 FROM test;

-- Statement 1346
SELECT SEQ4(0) FROM test;

-- Statement 1347
SELECT SEQ4(1) FROM test;

-- Statement 1348
SELECT (CASE WHEN (ROW_NUMBER() OVER (ORDER BY 1 NULLS FIRST) - 1) % 4294967296 >= 2147483648 THEN (ROW_NUMBER() OVER (ORDER BY 1 NULLS FIRST) - 1) % 4294967296 - 4294967296 ELSE (ROW_NUMBER() OVER (ORDER BY 1 NULLS FIRST) - 1) % 4294967296 END) FROM test;

-- Statement 1349
SELECT SEQ8() FROM test;

-- Statement 1350
SELECT (ROW_NUMBER() OVER (ORDER BY 1 NULLS FIRST) - 1) % 18446744073709551616 FROM test;

-- Statement 1351
SELECT SEQ8(0) FROM test;

-- Statement 1352
SELECT SEQ8(1) FROM test;

-- Statement 1353
SELECT (CASE WHEN (ROW_NUMBER() OVER (ORDER BY 1 NULLS FIRST) - 1) % 18446744073709551616 >= 9223372036854775808 THEN (ROW_NUMBER() OVER (ORDER BY 1 NULLS FIRST) - 1) % 18446744073709551616 - 18446744073709551616 ELSE (ROW_NUMBER() OVER (ORDER BY 1 NULLS FIRST) - 1) % 18446744073709551616 END) FROM test;

-- Statement 1354
SELECT 1 FROM TABLE(GENERATOR(ROWCOUNT => 10));

-- Statement 1355
SELECT 1 FROM TABLE(GENERATOR(TIMELIMIT => 5));

-- Statement 1356
SELECT 1 FROM TABLE(GENERATOR(ROWCOUNT => 10, TIMELIMIT => 5));

-- Statement 1357
SELECT 1 FROM TABLE(GENERATOR(10));

-- Statement 1358
SELECT 1 FROM TABLE(GENERATOR(10, 5));

-- Statement 1359
SELECT 1 FROM TABLE(GENERATOR(ROWCOUNT => 5));

-- Statement 1360
SELECT 1 FROM RANGE(5);

-- Statement 1361
SELECT SEQ8() FROM TABLE(GENERATOR(ROWCOUNT => 5));

-- Statement 1362
SELECT range % 18446744073709551616 FROM RANGE(5);

-- Statement 1363
SELECT * FROM (TABLE(GENERATOR(ROWCOUNT => 5)) JOIN other ON 1 = 1);

-- Statement 1364
SELECT * FROM (RANGE(5) JOIN other ON 1 = 1);

-- Statement 1365
SELECT CEIL(1.753, 2);

-- Statement 1366
SELECT ROUND(CEIL(1.753 * POWER(10, 2)) / POWER(10, 2), 2);

-- Statement 1367
SELECT CEIL(123.45, -1);

-- Statement 1368
SELECT ROUND(CEIL(123.45 * POWER(10, -1)) / POWER(10, -1), -1);

-- Statement 1369
SELECT CEIL(a + b, 2);

-- Statement 1370
SELECT ROUND(CEIL((a + b) * POWER(10, 2)) / POWER(10, 2), 2);

-- Statement 1371
SELECT CEIL(1.234, 1.5);

-- Statement 1372
SELECT ROUND(CEIL(1.234 * POWER(10, CAST(1.5 AS INT))) / POWER(10, CAST(1.5 AS INT)), CAST(1.5 AS INT));

-- Statement 1373
SELECT CORR(a, b);

-- Statement 1374
SELECT CASE WHEN ISNAN(CORR(a, b)) THEN NULL ELSE CORR(a, b) END;

-- Statement 1375
SELECT CORR(a, b) OVER (PARTITION BY c);

-- Statement 1376
SELECT CASE WHEN ISNAN(CORR(a, b) OVER (PARTITION BY c)) THEN NULL ELSE CORR(a, b) OVER (PARTITION BY c) END;

-- Statement 1377
SELECT CORR(a, b) FILTER(WHERE c > 0);

-- Statement 1378
SELECT CASE WHEN ISNAN(CORR(a, b) FILTER(WHERE c > 0)) THEN NULL ELSE CORR(a, b) FILTER(WHERE c > 0) END;

-- Statement 1379
SELECT CORR(a, b) FILTER(WHERE c > 0) OVER (PARTITION BY d);

-- Statement 1380
SELECT CASE WHEN ISNAN(CORR(a, b) FILTER(WHERE c > 0) OVER (PARTITION BY d)) THEN NULL ELSE CORR(a, b) FILTER(WHERE c > 0) OVER (PARTITION BY d) END;

-- Statement 1381
UPDATE test SET t = 1 FROM t1;

-- Statement 1382
UPDATE test SET t = 1 FROM t2 JOIN t3 ON t2.id = t3.id;

-- Statement 1383
UPDATE test SET t = 1 FROM (SELECT id FROM test2) AS t2 JOIN test3 AS t3 ON t2.id = t3.id;

-- Statement 1384
UPDATE sometesttable u FROM (SELECT 5195 AS new_count, '01bee1e5-0000-d31e-0000-e80ef02b9f27' query_id ) b SET qry_hash_count = new_count WHERE u.sample_query_id  = b.query_id;

-- Statement 1385
UPDATE sometesttable AS u SET qry_hash_count = new_count FROM (SELECT 5195 AS new_count, '01bee1e5-0000-d31e-0000-e80ef02b9f27' AS query_id) AS b WHERE u.sample_query_id = b.query_id;

-- Statement 1386
SELECT BITSHIFTLEFT(X'FF', 4);

-- Statement 1387
SELECT CAST(CAST(UNHEX('FF') AS BIT) << 4 AS BLOB);

-- Statement 1388
SELECT BITSHIFTRIGHT(X'FF', 4);

-- Statement 1389
SELECT CAST(CAST(UNHEX('FF') AS BIT) >> 4 AS BLOB);

-- Statement 1390
SELECT ARRAY_FLATTEN([['a', 'b'], ['c', 'd', 'e']]);

-- Statement 1391
SELECT FLATTEN([['a', 'b'], ['c', 'd', 'e']]);

-- Statement 1392
SELECT ARRAY_FLATTEN([[[1, 2], [3]], [[4], [5]]]);

-- Statement 1393
SELECT FLATTEN([[[1, 2], [3]], [[4], [5]]]);

-- Statement 1394
SELECT ARRAY_FLATTEN([[1, NULL, 3], [4]]);

-- Statement 1395
SELECT FLATTEN([[1, NULL, 3], [4]]);

-- Statement 1396
SELECT ARRAY_FLATTEN([[]]);

-- Statement 1397
SELECT FLATTEN([[]]);

-- Statement 1398
SELECT ARRAY_EXCEPT([1, 2, 3], [2]);

-- Statement 1399
SELECT CASE WHEN [1, 2, 3] IS NULL OR [2] IS NULL THEN NULL ELSE LIST_TRANSFORM(LIST_FILTER(LIST_ZIP([1, 2, 3], GENERATE_SERIES(1, LENGTH([1, 2, 3]))), pair -> (LENGTH(LIST_FILTER([1, 2, 3][1:pair[2]], e -> e IS NOT DISTINCT FROM pair[1])) > LENGTH(LIST_FILTER([2], e -> e IS NOT DISTINCT FROM pair[1])))), pair -> pair[1]) END;

-- Statement 1400
SELECT ARRAY_POSITION(2, ARRAY_CONSTRUCT(1, 2, 3));

-- Statement 1401
SELECT ARRAY_POSITION(2, [1, 2, 3]);

-- Statement 1402
SELECT ARRAY_POSITION([1, 2, 3], 2) - 1;

-- Statement 1403
SELECT SPACE(5);

-- Statement 1404
SELECT REPEAT(' ', 5);

-- Statement 1405
SELECT REPEAT(' ', CAST(5 AS BIGINT));

-- Statement 1406
SELECT SPACE(3.7);

-- Statement 1407
SELECT REPEAT(' ', 3.7);

-- Statement 1408
SELECT REPEAT(' ', CAST(3.7 AS BIGINT));

-- Statement 1409
SELECT SPACE(NULL);

-- Statement 1410
SELECT REPEAT(' ', NULL);

-- Statement 1411
SELECT REPEAT(' ', CAST(NULL AS BIGINT));

-- Statement 1412
SELECT CHARINDEX('sub', 'testsubstring', -1);

-- Statement 1413
SELECT CASE WHEN STRPOS(SUBSTRING('testsubstring', CASE WHEN -1 <= 0 THEN 1 ELSE -1 END), 'sub') = 0 THEN 0 ELSE STRPOS(SUBSTRING('testsubstring', CASE WHEN -1 <= 0 THEN 1 ELSE -1 END), 'sub') + CASE WHEN -1 <= 0 THEN 1 ELSE -1 END - 1 END;

-- Statement 1414
SELECT CHARINDEX('sub', 'testsubstring', p);

-- Statement 1415
SELECT CASE WHEN STRPOS(SUBSTRING('testsubstring', CASE WHEN p <= 0 THEN 1 ELSE p END), 'sub') = 0 THEN 0 ELSE STRPOS(SUBSTRING('testsubstring', CASE WHEN p <= 0 THEN 1 ELSE p END), 'sub') + CASE WHEN p <= 0 THEN 1 ELSE p END - 1 END;

-- Statement 1416
SELECT * FROM a CROSS DIRECTED JOIN b USING (id);

-- Statement 1417
SELECT * FROM a INNER DIRECTED JOIN b USING (id);

-- Statement 1418
SELECT * FROM a NATURAL INNER DIRECTED JOIN b USING (id);

-- Statement 1419
SELECT * FROM a {prefix} JOIN b USING (id);

