-- SQLGlot redshift DML statements
-- Extracted from redshift.py test fixtures
-- Total statements: 163
-- ============================================================

-- Statement 1
SELECT COSH(1.5);

-- Statement 2
SELECT SPLIT_TO_ARRAY('12,345,6789');

-- Statement 3
SELECT STRING_TO_ARRAY('12,345,6789', ',');

-- Statement 4
SELECT SPLIT_TO_ARRAY('12,345,6789', ',');

-- Statement 5
SELECT JSON_EXTRACT_PATH_TEXT('{ "farm": {"barn": { "color": "red", "feed stocked": true }}}', 'farm', 'barn', 'color');

-- Statement 6
SELECT JSON_EXTRACT_SCALAR('{ "farm": {"barn": { "color": "red", "feed stocked": true }}}', '$.farm.barn.color');

-- Statement 7
SELECT GET_JSON_OBJECT('{ "farm": {"barn": { "color": "red", "feed stocked": true }}}', '$.farm.barn.color');

-- Statement 8
SELECT '{ "farm": {"barn": { "color": "red", "feed stocked": true }}}' ->> '$.farm.barn.color';

-- Statement 9
SELECT LISTAGG(x, ',') WITHIN GROUP (ORDER BY y) FILTER (WHERE z > 0) FROM t;

-- Statement 10
SELECT LISTAGG(IFF(z > 0, x, NULL), ',') WITHIN GROUP (ORDER BY y) FROM t;

-- Statement 11
SELECT APPROXIMATE COUNT(DISTINCT y);

-- Statement 12
SELECT APPROX_COUNT_DISTINCT(y);

-- Statement 13
SELECT CAST('01:03:05.124' AS TIME(2) WITH TIME ZONE);

-- Statement 14
SELECT CAST('01:03:05.124' AS TIMETZ(2));

-- Statement 15
SELECT CAST('2020-02-02 01:03:05.124' AS TIMESTAMP(2) WITH TIME ZONE);

-- Statement 16
SELECT CAST('2020-02-02 01:03:05.124' AS TIMESTAMPTZ(2));

-- Statement 17
SELECT INTERVAL '5 DAYS';

-- Statement 18
SELECT INTERVAL '5' days;

-- Statement 19
SELECT ADD_MONTHS('2008-03-31', 1);

-- Statement 20
SELECT DATE_ADD(CAST('2008-03-31' AS DATETIME), INTERVAL 1 MONTH);

-- Statement 21
SELECT CAST('2008-03-31' AS TIMESTAMP) + INTERVAL 1 MONTH;

-- Statement 22
SELECT DATEADD(MONTH, 1, '2008-03-31');

-- Statement 23
SELECT DATE_ADD('MONTH', 1, CAST('2008-03-31' AS TIMESTAMP));

-- Statement 24
SELECT DATEADD(MONTH, 1, CAST('2008-03-31' AS DATETIME2));

-- Statement 25
SELECT STRTOL('abc', 16);

-- Statement 26
SELECT FROM_BASE('abc', 16);

-- Statement 27
SELECT SNAPSHOT, type;

-- Statement 28
SELECT "SNAPSHOT", "type";

-- Statement 29
SELECT SYSDATE;

-- Statement 30
SELECT CURRENT_TIMESTAMP();

-- Statement 31
SELECT CURRENT_TIMESTAMP;

-- Statement 32
SELECT DATE_PART(minute, timestamp '2023-01-04 04:05:06.789');

-- Statement 33
SELECT EXTRACT(minute FROM CAST('2023-01-04 04:05:06.789' AS TIMESTAMP));

-- Statement 34
SELECT DATE_PART(minute, CAST('2023-01-04 04:05:06.789' AS TIMESTAMP));

-- Statement 35
SELECT DATE_PART(month, date '20220502');

-- Statement 36
SELECT EXTRACT(month FROM CAST('20220502' AS DATE));

-- Statement 37
SELECT DATE_PART(month, CAST('20220502' AS DATE));

-- Statement 38
SELECT ST_AsEWKT(ST_GeomFromEWKT('SRID=4326;POINT(10 20)')::geography);

-- Statement 39
SELECT ST_ASEWKT(CAST(ST_GEOMFROMEWKT('SRID=4326;POINT(10 20)') AS GEOGRAPHY));

-- Statement 40
SELECT ST_AsEWKT(ST_GeogFromText('LINESTRING(110 40, 2 3, -10 80, -7 9)')::geometry);

-- Statement 41
SELECT ST_ASEWKT(CAST(ST_GEOGFROMTEXT('LINESTRING(110 40, 2 3, -10 80, -7 9)') AS GEOMETRY));

-- Statement 42
SELECT 'abc'::BINARY;

-- Statement 43
SELECT CAST('abc' AS VARBYTE);

-- Statement 44
SELECT 'abc'::CHARACTER;

-- Statement 45
SELECT CAST('abc' AS CHAR);

-- Statement 46
SELECT DISTINCT ON (a) a, b FROM x ORDER BY c DESC;

-- Statement 47
SELECT a, b FROM (SELECT a AS a, b AS b, ROW_NUMBER() OVER (PARTITION BY a ORDER BY c DESC NULLS FIRST) AS _row_number FROM x) AS _t WHERE _row_number = 1;

-- Statement 48
SELECT a, b FROM (SELECT a AS a, b AS b, ROW_NUMBER() OVER (PARTITION BY a ORDER BY CASE WHEN c IS NULL THEN 1 ELSE 0 END DESC, c DESC) AS _row_number FROM x) AS _t WHERE _row_number = 1;

-- Statement 49
SELECT a, b FROM (SELECT a AS a, b AS b, ROW_NUMBER() OVER (PARTITION BY a ORDER BY c DESC) AS _row_number FROM x) _t WHERE _row_number = 1;

-- Statement 50
SELECT a, b FROM (SELECT a AS a, b AS b, ROW_NUMBER() OVER (PARTITION BY a ORDER BY c DESC) AS _row_number FROM x) AS _t WHERE _row_number = 1;

-- Statement 51
SELECT DATEADD(month, 18, '2008-02-28');

-- Statement 52
SELECT DATE_ADD(CAST('2008-02-28' AS DATETIME), INTERVAL 18 MONTH);

-- Statement 53
SELECT CAST('2008-02-28' AS TIMESTAMP) + INTERVAL 18 MONTH;

-- Statement 54
SELECT ADD_MONTHS('2008-02-28', 18);

-- Statement 55
SELECT DATE_ADD('2008-02-28', INTERVAL 18 MONTH);

-- Statement 56
SELECT CAST('2008-02-28' AS TIMESTAMP) + INTERVAL '18 MONTH';

-- Statement 57
SELECT DATE_ADD('MONTH', 18, CAST('2008-02-28' AS TIMESTAMP));

-- Statement 58
SELECT DATEADD(MONTH, 18, CAST('2008-02-28' AS TIMESTAMP));

-- Statement 59
SELECT DATEADD(MONTH, 18, CAST('2008-02-28' AS DATETIME2));

-- Statement 60
SELECT DATE_ADD(MONTH, 18, '2008-02-28');

-- Statement 61
SELECT DATEDIFF(week, '2009-01-01', '2009-12-31');

-- Statement 62
SELECT DATE_DIFF(CAST('2009-12-31' AS DATETIME), CAST('2009-01-01' AS DATETIME), WEEK);

-- Statement 63
SELECT DATE_DIFF('WEEK', CAST('2009-01-01' AS TIMESTAMP), CAST('2009-12-31' AS TIMESTAMP));

-- Statement 64
SELECT CAST(DATEDIFF('2009-12-31', '2009-01-01') / 7 AS INT);

-- Statement 65
SELECT CAST(EXTRACT(days FROM (CAST('2009-12-31' AS TIMESTAMP) - CAST('2009-01-01' AS TIMESTAMP))) / 7 AS BIGINT);

-- Statement 66
SELECT EXTRACT(EPOCH FROM CURRENT_DATE);

-- Statement 67
SELECT DATE_PART(EPOCH, CURRENT_DATE);

-- Statement 68
SELECT VERSION();

-- Statement 69
SELECT TEXTLEN('hello world');

-- Statement 70
SELECT LENGTH('hello world');

-- Statement 71
SELECT GETBIT(FROM_HEX('4d'), 2);

-- Statement 72
SELECT EXP(1);

-- Statement 73
SELECT CAST(value AS FLOAT(8));

-- Statement 74
SELECT DATEADD(DAY, 1, 'today');

-- Statement 75
SELECT * FROM #x;

-- Statement 76
SELECT INTERVAL '5 DAY';

-- Statement 77
SELECT date_col - INTERVAL '30' FROM t;

-- Statement 78
SELECT date_col - INTERVAL '1' AS one_second_later;

-- Statement 79
SELECT date_col - INTERVAL '30' DAY FROM t;

-- Statement 80
SELECT date_col - INTERVAL '30 DAY' FROM t;

-- Statement 81
SELECT date_col - INTERVAL '1' HOUR AS one_hour_later;

-- Statement 82
SELECT date_col - INTERVAL '1 HOUR' AS one_hour_later;

-- Statement 83
SELECT APPROXIMATE AS y;

-- Statement 84
SELECT APPROXIMATE PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY totalprice);

-- Statement 85
COPY test_staging_tbl FROM 's3://your/bucket/prefix/here' IAM_ROLE default FORMAT AS AVRO 'auto';

-- Statement 86
COPY test_staging_tbl FROM 's3://your/bucket/prefix/here' IAM_ROLE default FORMAT AS JSON 's3://jsonpaths_file';

-- Statement 87
SELECT * FROM venue WHERE (venuecity, venuestate) IN (('Miami', 'FL'), ('Tampa', 'FL')) ORDER BY venueid;

-- Statement 88
SELECT tablename, "column" FROM pg_table_def WHERE "column" LIKE '%start\\\\_%' LIMIT 5;

-- Statement 89
SELECT JSON_EXTRACT_PATH_TEXT('{"f2":{"f3":1},"f4":{"f5":99,"f6":"star"}', 'f4', 'f6', TRUE);

-- Statement 90
SELECT CONCAT('abc', 'def');

-- Statement 91
SELECT 'abc' || 'def';

-- Statement 92
SELECT TOP 1 x FROM y;

-- Statement 93
SELECT x FROM y LIMIT 1;

-- Statement 94
SELECT DATE_DIFF('month', CAST('2020-02-29 00:00:00' AS TIMESTAMP), CAST('2020-03-02 00:00:00' AS TIMESTAMP));

-- Statement 95
SELECT DATEDIFF(MONTH, CAST('2020-02-29 00:00:00' AS TIMESTAMP), CAST('2020-03-02 00:00:00' AS TIMESTAMP));

-- Statement 96
SELECT * FROM x WHERE y = DATEADD('month', -1, DATE_TRUNC('month', (SELECT y FROM #temp_table)));

-- Statement 97
SELECT * FROM x WHERE y = DATEADD(MONTH, -1, DATE_TRUNC('MONTH', (SELECT y FROM #temp_table)));

-- Statement 98
SELECT 'a''b';

-- Statement 99
SELECT 'a\\'b';

-- Statement 100
SELECT DATEADD(HOUR, 0, CAST('2020-02-02 01:03:05.124' AS TIMESTAMP));

-- Statement 101
SELECT DATEDIFF(SECOND, '2020-02-02 00:00:00.000', '2020-02-02 01:03:05.124');

-- Statement 102
SELECT caldate + INTERVAL '1 SECOND' AS dateplus FROM date WHERE caldate = '12-31-2008';

-- Statement 103
SELECT COUNT(*) FROM event WHERE eventname LIKE '%Ring%' OR eventname LIKE '%Die%';

-- Statement 104
COPY customer FROM 's3://mybucket/customer' IAM_ROLE 'arn:aws:iam::0123456789012:role/MyRedshiftRole' REGION 'us-east-1' FORMAT orc;

-- Statement 105
COPY customer FROM 's3://mybucket/mydata' CREDENTIALS 'aws_iam_role=arn:aws:iam::<aws-account-id>:role/<role-name>;master_symmetric_key=<root-key>' emptyasnull blanksasnull timeformat 'YYYY-MM-DD HH:MI:SS';

-- Statement 106
SELECT DATEADD('day', ndays, caldate);

-- Statement 107
SELECT DATEADD(DAY, ndays, caldate);

-- Statement 108
SELECT DATE_ADD('day', 1, DATE('2023-01-01'));

-- Statement 109
SELECT DATEADD(DAY, 1, DATE('2023-01-01'));

-- Statement 110
SELECT attr AS attr, JSON_TYPEOF(val) AS value_type FROM customer_orders_lineitem AS c, UNPIVOT c.c_orders[0] WHERE c_custkey = 9451;

-- Statement 111
SELECT attr AS attr, JSON_TYPEOF(val) AS value_type FROM customer_orders_lineitem AS c, UNPIVOT c.c_orders AS val AT attr WHERE c_custkey = 9451;

-- Statement 112
SELECT JSON_PARSE('[]');

-- Statement 113
SELECT ARRAY(1, 2, 3);

-- Statement 114
SELECT ARRAY[1, 2, 3];

-- Statement 115
SELECT CONVERT_TIMEZONE('America/New_York', '2024-08-06 09:10:00.000');

-- Statement 116
SELECT CONVERT_TIMEZONE('UTC', 'America/New_York', '2024-08-06 09:10:00.000');

-- Statement 117
SELECT *, 4 AS col4 EXCLUDE (col2, col3) FROM (SELECT 1 AS col1, 2 AS col2, 3 AS col3);

-- Statement 118
SELECT * EXCLUDE (col2, col3) FROM (SELECT *, 4 AS col4 FROM (SELECT 1 AS col1, 2 AS col2, 3 AS col3));

-- Statement 119
SELECT *, 4 AS col4 EXCLUDE col2, col3 FROM (SELECT 1 AS col1, 2 AS col2, 3 AS col3);

-- Statement 120
SELECT col1, *, col2 EXCLUDE(col3) FROM (SELECT 1 AS col1, 2 AS col2, 3 AS col3);

-- Statement 121
SELECT col1, *, col2 EXCLUDE (col3) FROM (SELECT 1 AS col1, 2 AS col2, 3 AS col3);

-- Statement 122
SELECT * EXCLUDE (col3) FROM (SELECT col1, *, col2 FROM (SELECT 1 AS col1, 2 AS col2, 3 AS col3));

-- Statement 123
SELECT 1 EXCLUDE;

-- Statement 124
SELECT 1 AS EXCLUDE;

-- Statement 125
SELECT 1 EXCLUDE FROM t;

-- Statement 126
SELECT 1 AS EXCLUDE FROM t;

-- Statement 127
SELECT * FROM (SELECT 1 AS EXCLUDE) AS t;

-- Statement 128
SELECT 1 AS EXCLUDE, 2 AS foo;

-- Statement 129
SELECT * FROM (VALUES {', '.join('(' + v + ')' for v in values)});

-- Statement 130
SELECT * FROM ({' UNION ALL '.join('SELECT ' + v for v in values)});

-- Statement 131
SELECT * FROM (VALUES (1), (2));

-- Statement 132
INSERT INTO t (a) VALUES (1), (2), (3);

-- Statement 133
INSERT INTO t (a, b) VALUES (1, 2), (3, 4);

-- Statement 134
SELECT * FROM (SELECT 1, 2) AS t;

-- Statement 135
SELECT * FROM (VALUES (1, 2)) AS t;

-- Statement 136
SELECT * FROM (SELECT 1 AS id) AS t1 CROSS JOIN (SELECT 1 AS id) AS t2;

-- Statement 137
SELECT * FROM (VALUES (1)) AS t1(id) CROSS JOIN (VALUES (1)) AS t2(id);

-- Statement 138
SELECT a, b FROM (SELECT 1 AS a, 2 AS b) AS t;

-- Statement 139
SELECT a, b FROM (VALUES (1, 2)) AS t (a, b);

-- Statement 140
SELECT a, b FROM (SELECT 1 AS a, 2 AS b UNION ALL SELECT 3, 4) AS "t";

-- Statement 141
SELECT a, b FROM (VALUES (1, 2), (3, 4)) AS "t" (a, b);

-- Statement 142
SELECT a, b FROM (SELECT 1 AS a, 2 AS b UNION ALL SELECT 3, 4 UNION ALL SELECT 5, 6 UNION ALL SELECT 7, 8) AS t;

-- Statement 143
SELECT a, b FROM (VALUES (1, 2), (3, 4), (5, 6), (7, 8)) AS t (a, b);

-- Statement 144
INSERT INTO t (a, b) SELECT a, b FROM (SELECT 1 AS a, 2 AS b UNION ALL SELECT 3, 4) AS t;

-- Statement 145
INSERT INTO t(a, b) SELECT a, b FROM (VALUES (1, 2), (3, 4)) AS t (a, b);

-- Statement 146
select foo, bar from table_1 minus select foo, bar from table_2;

-- Statement 147
SELECT foo, bar FROM table_1 EXCEPT SELECT foo, bar FROM table_2;

-- Statement 148
SELECT c.*, o FROM bloo AS c, c.c_orders AS o;

-- Statement 149
SELECT c.*, o, l FROM bloo AS c, c.c_orders AS o, o.o_lineitems AS l;

-- Statement 150
SELECT * FROM t.t JOIN t.c1 ON c1.c2 = t.c3;

-- Statement 151
SELECT * FROM t AS t CROSS JOIN t.c1;

-- Statement 152
SELECT * FROM x AS a, a.b AS c, c.d.e AS f, f.g.h.i.j.k AS l;

-- Statement 153
select a.foo, b.bar, a.baz from a, b where a.baz = b.baz (+);

-- Statement 154
SELECT * FROM t FETCH FIRST 1 ROWS ONLY;

-- Statement 155
SELECT * FROM t LIMIT 1;

-- Statement 156
SELECT TO_TIMESTAMP('2023-01-01', 'YYYY-MM-DD');

-- Statement 157
SELECT LAG(x) IGNORE NULLS OVER (PARTITION BY y ORDER BY z);

-- Statement 158
SELECT LAG(x) RESPECT NULLS OVER (PARTITION BY y ORDER BY z);

-- Statement 159
SELECT LAG(x IGNORE NULLS) OVER (PARTITION BY y ORDER BY z);

-- Statement 160
SELECT LAG(x RESPECT NULLS) OVER (PARTITION BY y ORDER BY z);

-- Statement 161
SELECT REGEXP_SUBSTR(abc, 'pattern(group)', 2) FROM table;

-- Statement 162
SELECT REGEXP_SUBSTR(abc, 'pattern(group)', 2) FROM "table";

-- Statement 163
SELECT REGEXP_EXTRACT(SUBSTRING(abc, 2), 'pattern(group)') FROM "table";

