-- SQLGlot snowflake DDL statements
-- Extracted from snowflake.py test fixtures
-- Total statements: 169
-- ============================================================

-- Statement 1
CREATE TABLE table1 CLUSTER BY (name1, name2, name3);

-- Statement 2
ALTER TABLE table1 CLUSTER BY (name);

-- Statement 3
ALTER TABLE authors ADD CONSTRAINT c1 UNIQUE (id, email);

-- Statement 4
CREATE TABLE foo (bar DOUBLE AUTOINCREMENT START 0 INCREMENT 1);

-- Statement 5
ALTER TABLE a SWAP WITH b;

-- Statement 6
CREATE TABLE foo (ID INT COMMENT $$some comment$$);

-- Statement 7
CREATE TABLE foo (ID INT COMMENT 'some comment');

-- Statement 8
CREATE OR REPLACE TEMPORARY TABLE x (y NUMBER IDENTITY(0, 1));

-- Statement 9
CREATE OR REPLACE TEMPORARY TABLE x (y DECIMAL(38, 0) AUTOINCREMENT START 0 INCREMENT 1);

-- Statement 10
CREATE TEMPORARY TABLE x (y NUMBER AUTOINCREMENT(0, 1));

-- Statement 11
CREATE TEMPORARY TABLE x (y DECIMAL(38, 0) AUTOINCREMENT START 0 INCREMENT 1);

-- Statement 12
CREATE OR REPLACE TABLE x (y NUMBER(38, 0) NOT NULL AUTOINCREMENT START 1 INCREMENT 1 ORDER);

-- Statement 13
CREATE OR REPLACE TABLE x (y DECIMAL(38, 0) NOT NULL AUTOINCREMENT START 1 INCREMENT 1 ORDER);

-- Statement 14
CREATE OR REPLACE TABLE x (y NUMBER(38, 0) NOT NULL AUTOINCREMENT START 1 INCREMENT 1 NOORDER);

-- Statement 15
CREATE OR REPLACE TABLE x (y DECIMAL(38, 0) NOT NULL AUTOINCREMENT START 1 INCREMENT 1 NOORDER);

-- Statement 16
CREATE TABLE x (y NUMBER IDENTITY START 0 INCREMENT 1);

-- Statement 17
CREATE TABLE x (y DECIMAL(38, 0) AUTOINCREMENT START 0 INCREMENT 1);

-- Statement 18
ALTER TABLE foo ADD COLUMN id INT identity(1, 1);

-- Statement 19
ALTER TABLE foo ADD id INT AUTOINCREMENT START 1 INCREMENT 1;

-- Statement 20
CREATE TABLE x (y INT AUTOINCREMENT START 10);

-- Statement 21
CREATE TABLE x (y INT AUTOINCREMENT INCREMENT 2);

-- Statement 22
CREATE TABLE x (y INT AUTOINCREMENT ORDER);

-- Statement 23
CREATE TABLE x (y INT AUTOINCREMENT NOORDER);

-- Statement 24
CREATE TABLE x (y INT AUTOINCREMENT START 10 NOORDER);

-- Statement 25
CREATE TABLE x (y INT AUTOINCREMENT INCREMENT 2 ORDER);

-- Statement 26
CREATE TABLE x (y INT AUTOINCREMENT INCREMENT 2 START 10);

-- Statement 27
CREATE TABLE x (y INT AUTOINCREMENT START 10 INCREMENT 2);

-- Statement 28
CREATE TABLE x (y INT AUTOINCREMENT(0, 1) ORDER);

-- Statement 29
CREATE TABLE x (y INT AUTOINCREMENT START 0 INCREMENT 1 ORDER);

-- Statement 30
CREATE TABLE c (pk BIGINT AUTOINCREMENT START 10);

-- Statement 31
CREATE TABLE c (pk BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 10));

-- Statement 32
CREATE TABLE c (pk BIGINT AUTOINCREMENT INCREMENT -1);

-- Statement 33
CREATE TABLE c (pk BIGINT GENERATED ALWAYS AS IDENTITY (INCREMENT BY -1));

-- Statement 34
CREATE TABLE test_table (id NUMERIC NOT NULL AUTOINCREMENT);

-- Statement 35
CREATE TABLE test_table (id DECIMAL(38, 0) NOT NULL);

-- Statement 36
CREATE TABLE test_table (id DECIMAL(38, 0) NOT NULL AUTOINCREMENT);

-- Statement 37
CREATE TABLE t (id INT PRIMARY KEY AUTOINCREMENT);

-- Statement 38
ALTER TABLE foo ADD col1 VARCHAR(512), col2 VARCHAR(512);

-- Statement 39
ALTER TABLE foo ADD col1 VARCHAR NOT NULL TAG (key1='value_1'), col2 VARCHAR NOT NULL TAG (key2='value_2');

-- Statement 40
ALTER TABLE foo ADD IF NOT EXISTS col1 INT, col2 INT;

-- Statement 41
ALTER TABLE foo ADD IF NOT EXISTS col1 INT, IF NOT EXISTS col2 INT;

-- Statement 42
ALTER TABLE foo ADD col1 INT, IF NOT EXISTS col2 INT;

-- Statement 43
ALTER TABLE IF EXISTS foo ADD IF NOT EXISTS col1 INT;

-- Statement 44
CREATE SCHEMA restored_schema CLONE my_schema AT (OFFSET => -3600);

-- Statement 45
CREATE TABLE restored_table CLONE my_table AT (TIMESTAMP => CAST('Sat, 09 May 2015 01:01:00 +0300' AS TIMESTAMPTZ));

-- Statement 46
CREATE DATABASE restored_db CLONE my_db BEFORE (STATEMENT => '8e5d0ca9-005e-44e6-b858-a8f5b37c5726');

-- Statement 47
CREATE TABLE t (id INT {constraint_prefix}MASKING POLICY p.q.r);

-- Statement 48
CREATE TABLE t (id INT MASKING POLICY p.q.r);

-- Statement 49
CREATE TABLE t (id INT {constraint_prefix}MASKING POLICY p USING (c1, c2, c3));

-- Statement 50
CREATE TABLE t (id INT MASKING POLICY p USING (c1, c2, c3));

-- Statement 51
CREATE TABLE t (id INT {constraint_prefix}PROJECTION POLICY p.q.r);

-- Statement 52
CREATE TABLE t (id INT PROJECTION POLICY p.q.r);

-- Statement 53
CREATE TABLE t (id INT {constraint_prefix}TAG (key1='value_1', key2='value_2'));

-- Statement 54
CREATE TABLE t (id INT TAG (key1='value_1', key2='value_2'));

-- Statement 55
CREATE OR REPLACE TABLE foo COPY GRANTS USING TEMPLATE (SELECT 1);

-- Statement 56
CREATE SECURE VIEW table1 AS (SELECT a FROM table2);

-- Statement 57
CREATE OR REPLACE VIEW foo (uid) COPY GRANTS AS (SELECT 1);

-- Statement 58
CREATE TABLE geospatial_table (id INT, g GEOGRAPHY);

-- Statement 59
CREATE TABLE t (id INT) CHANGE_TRACKING=TRUE;

-- Statement 60
CREATE TABLE t CHANGE_TRACKING=TRUE DATA_RETENTION_TIME_IN_DAYS=1 (id INT);

-- Statement 61
CREATE TABLE t (id INT) CHANGE_TRACKING=TRUE DATA_RETENTION_TIME_IN_DAYS=1;

-- Statement 62
CREATE MATERIALIZED VIEW a COMMENT='...' AS SELECT 1 FROM x;

-- Statement 63
CREATE DATABASE mytestdb_clone CLONE mytestdb;

-- Statement 64
CREATE SCHEMA mytestschema_clone CLONE testschema;

-- Statement 65
CREATE TABLE IDENTIFIER('foo') (COLUMN1 VARCHAR, COLUMN2 VARCHAR);

-- Statement 66
CREATE TABLE IDENTIFIER($foo) (col1 VARCHAR, col2 VARCHAR);

-- Statement 67
CREATE TAG cost_center ALLOWED_VALUES 'a', 'b';

-- Statement 68
CREATE WAREHOUSE x;

-- Statement 69
CREATE STREAMLIT x;

-- Statement 70
CREATE TEMPORARY STAGE stage1 FILE_FORMAT=(TYPE=PARQUET);

-- Statement 71
CREATE STAGE stage1 FILE_FORMAT='format1';

-- Statement 72
CREATE STAGE stage1 FILE_FORMAT=(FORMAT_NAME='format1');

-- Statement 73
CREATE STAGE stage1 FILE_FORMAT=(FORMAT_NAME=stage1.format1);

-- Statement 74
CREATE STAGE stage1 FILE_FORMAT=(FORMAT_NAME='stage1.format1');

-- Statement 75
CREATE STAGE stage1 FILE_FORMAT=schema1.format1;

-- Statement 76
CREATE STAGE stage1 FILE_FORMAT=(FORMAT_NAME=schema1.format1);

-- Statement 77
CREATE STAGE stage1 FILE_FORMAT=123;

-- Statement 78
CREATE STAGE s1 URL='s3://bucket-123' FILE_FORMAT=(TYPE='JSON') CREDENTIALS=(aws_key_id='test' aws_secret_key='test');

-- Statement 79
CREATE OR REPLACE TAG IF NOT EXISTS cost_center COMMENT='cost_center tag';

-- Statement 80
CREATE TEMPORARY FILE FORMAT fileformat1 TYPE=PARQUET COMPRESSION=auto;

-- Statement 81
CREATE DYNAMIC TABLE product (pre_tax_profit, taxes, after_tax_profit) TARGET_LAG='20 minutes' WAREHOUSE=mywh AS SELECT revenue - cost, (revenue - cost) * tax_rate, (revenue - cost) * (1.0 - tax_rate) FROM staging_table;

-- Statement 82
CREATE DYNAMIC TABLE dt TARGET_LAG='1 minute' WAREHOUSE=my_wh (id) AS SELECT * FROM bla;

-- Statement 83
CREATE DYNAMIC TABLE dt (id) TARGET_LAG='1 minute' WAREHOUSE=my_wh AS SELECT * FROM bla;

-- Statement 84
ALTER TABLE db_name.schmaName.tblName ADD COLUMN_1 VARCHAR NOT NULL TAG (key1='value_1');

-- Statement 85
DROP FUNCTION my_udf (OBJECT(city VARCHAR, zipcode DECIMAL(38, 0), val ARRAY(BOOLEAN)));

-- Statement 86
CREATE TABLE orders_clone_restore CLONE orders AT (TIMESTAMP => TO_TIMESTAMP_TZ('04/05/2013 01:02:03', 'mm/dd/yyyy hh24:mi:ss'));

-- Statement 87
CREATE TABLE orders_clone_restore CLONE orders BEFORE (STATEMENT => '8e5d0ca9-005e-44e6-b858-a8f5b37c5726');

-- Statement 88
CREATE SCHEMA mytestschema_clone_restore CLONE testschema BEFORE (TIMESTAMP => TO_TIMESTAMP(40 * 365 * 86400));

-- Statement 89
CREATE OR REPLACE TABLE EXAMPLE_DB.DEMO.USERS (ID DECIMAL(38, 0) NOT NULL, PRIMARY KEY (ID), FOREIGN KEY (CITY_CODE) REFERENCES EXAMPLE_DB.DEMO.CITIES (CITY_CODE));

-- Statement 90
CREATE ICEBERG TABLE my_iceberg_table (amount ARRAY(INT)) CATALOG='SNOWFLAKE' EXTERNAL_VOLUME='my_external_volume' BASE_LOCATION='my/relative/path/from/extvol';

-- Statement 91
CREATE OR REPLACE FUNCTION ibis_udfs.public.object_values("obj" OBJECT) RETURNS ARRAY LANGUAGE JAVASCRIPT RETURNS NULL ON NULL INPUT AS ' return Object.values(obj) ';

-- Statement 92
CREATE OR REPLACE FUNCTION ibis_udfs.public.object_values("obj" OBJECT) RETURNS ARRAY LANGUAGE JAVASCRIPT STRICT AS ' return Object.values(obj) ';

-- Statement 93
CREATE OR REPLACE TABLE TEST (SOME_REF DECIMAL(38, 0) NOT NULL FOREIGN KEY REFERENCES SOME_OTHER_TABLE (ID));

-- Statement 94
CREATE OR REPLACE FUNCTION my_udf(location OBJECT(city VARCHAR, zipcode DECIMAL(38, 0), val ARRAY(BOOLEAN))) RETURNS VARCHAR AS $$ SELECT 'foo' $$;

-- Statement 95
CREATE OR REPLACE FUNCTION my_udf(location OBJECT(city VARCHAR, zipcode DECIMAL(38, 0), val ARRAY(BOOLEAN))) RETURNS VARCHAR AS ' SELECT \\'foo\\' ';

-- Statement 96
CREATE OR REPLACE FUNCTION my_udtf(foo BOOLEAN) RETURNS TABLE(col1 ARRAY(INT)) AS $$ WITH t AS (SELECT CAST([1, 2, 3] AS ARRAY(INT)) AS c) SELECT c FROM t $$;

-- Statement 97
CREATE OR REPLACE FUNCTION my_udtf(foo BOOLEAN) RETURNS TABLE (col1 ARRAY(INT)) AS ' WITH t AS (SELECT CAST([1, 2, 3] AS ARRAY(INT)) AS c) SELECT c FROM t ';

-- Statement 98
CREATE SEQUENCE seq1 WITH START=1, INCREMENT=1 ORDER;

-- Statement 99
CREATE SEQUENCE seq1 START WITH 1 INCREMENT BY 1 ORDER;

-- Statement 100
CREATE SEQUENCE seq1 WITH START=1 INCREMENT=1 ORDER;

-- Statement 101
create external table et2(
col1 date as (parse_json(metadata$external_table_partition):COL1::date),
col2 varchar as (parse_json(metadata$external_table_partition):COL2::varchar),
col3 number as (parse_json(metadata$external_table_partition):COL3::number))
partition by (col1,col2,col3)
location=@s2/logs/
partition_type = user_specified
file_format = (type = parquet compression = gzip binary_as_text = false);

-- Statement 102
CREATE EXTERNAL TABLE et2 (col1 DATE AS (CAST(GET_PATH(PARSE_JSON(metadata$external_table_partition), 'COL1') AS DATE)), col2 VARCHAR AS (CAST(GET_PATH(PARSE_JSON(metadata$external_table_partition), 'COL2') AS VARCHAR)), col3 DECIMAL(38, 0) AS (CAST(GET_PATH(PARSE_JSON(metadata$external_table_partition), 'COL3') AS DECIMAL(38, 0)))) PARTITION BY (col1, col2, col3) LOCATION=@s2/logs/ partition_type=user_specified FILE_FORMAT=(type=parquet compression=gzip binary_as_text=FALSE);

-- Statement 103
CREATE TABLE orders_clone CLONE orders;

-- Statement 104
CREATE OR REPLACE TRANSIENT TABLE a (id INT);

-- Statement 105
CREATE OR REPLACE TABLE a (id INT);

-- Statement 106
CREATE TABLE a (b INT);

-- Statement 107
CREATE MULTISET TABLE a (b INT);

-- Statement 108
CREATE TABLE a TAG (key1='value_1', key2='value_2');

-- Statement 109
CREATE TABLE a TAG (key1='value_1');

-- Statement 110
CREATE TABLE a WITH TAG (key1='value_1');

-- Statement 111
ALTER COLUMN {action} NOT NULL;

-- Statement 112
ALTER TABLE a ALTER COLUMN my_column {action} NOT NULL;

-- Statement 113
ALTER TABLE a MODIFY COLUMN my_column {action} NOT NULL;

-- Statement 114
CREATE FUNCTION a(x DATE, y BIGINT) RETURNS ARRAY LANGUAGE JAVASCRIPT AS $$ SELECT 1 $$;

-- Statement 115
CREATE FUNCTION a(x DATE, y BIGINT) RETURNS ARRAY LANGUAGE JAVASCRIPT AS ' SELECT 1 ';

-- Statement 116
CREATE FUNCTION a() RETURNS TABLE (b INT) AS 'SELECT 1';

-- Statement 117
CREATE TABLE FUNCTION a() RETURNS TABLE <b INT64> AS SELECT 1;

-- Statement 118
CREATE FUNCTION a() RETURNS INT IMMUTABLE AS 'SELECT 1';

-- Statement 119
CREATE FUNCTION a(x DOUBLE) RETURNS DOUBLE LANGUAGE SQL CALLED ON NULL INPUT AS ' x * 2 ';

-- Statement 120
CREATE OR REPLACE FUNCTION repro_fn() RETURNS INT LANGUAGE PYTHON HANDLER = 'fn' RUNTIME_VERSION='3.11' PACKAGES=() AS '\\ndef fn():\\n    return 1\\n';

-- Statement 121
CREATE PROCEDURE a.b.c(x INT, y VARIANT) RETURNS OBJECT EXECUTE AS CALLER AS 'BEGIN SELECT 1; END;';

-- Statement 122
CREATE TABLE t ({cols});

-- Statement 123
ALTER ICEBERG TABLE t RENAME TO x;

-- Statement 124
ALTER ICEBERG VIEW v RENAME TO x;

-- Statement 125
ALTER TABLE t RENAME TO x;

-- Statement 126
DROP ICEBERG TABLE t;

-- Statement 127
DROP ICEBERG TABLE IF EXISTS t;

-- Statement 128
DROP ICEBERG TABLE t RESTRICT;

-- Statement 129
DROP ICEBERG TABLE IF EXISTS t RESTRICT;

-- Statement 130
CREATE STORAGE INTEGRATION s3_int
TYPE=EXTERNAL_STAGE
STORAGE_PROVIDER='S3'
STORAGE_AWS_ROLE_ARN='arn:aws:iam::001234567890:role/myrole'
ENABLED=TRUE
STORAGE_ALLOWED_LOCATIONS=('s3://mybucket1/path1/', 's3://mybucket2/path2/');

-- Statement 131
CREATE TABLE t (x DECFLOAT);

-- Statement 132
CREATE TABLE t (x DECIMAL(38, 5));

-- Statement 133
ALTER TABLE tbl SET DATA_RETENTION_TIME_IN_DAYS=1;

-- Statement 134
ALTER TABLE tbl SET DEFAULT_DDL_COLLATION='test';

-- Statement 135
ALTER TABLE foo SET COMMENT='bar';

-- Statement 136
ALTER TABLE foo SET CHANGE_TRACKING=FALSE;

-- Statement 137
ALTER TABLE table1 SET TAG foo.bar = 'baz';

-- Statement 138
ALTER TABLE IF EXISTS foo SET TAG a = 'a', b = 'b', c = 'c';

-- Statement 139
ALTER TABLE tbl SET STAGE_FILE_FORMAT = (TYPE=CSV FIELD_DELIMITER='|' NULL_IF=('') FIELD_OPTIONALLY_ENCLOSED_BY='"' TIMESTAMP_FORMAT='TZHTZM YYYY-MM-DD HH24:MI:SS.FF9' DATE_FORMAT='TZHTZM YYYY-MM-DD HH24:MI:SS.FF9' BINARY_FORMAT=BASE64);

-- Statement 140
ALTER TABLE tbl SET STAGE_COPY_OPTIONS = (ON_ERROR=SKIP_FILE SIZE_LIMIT=5 PURGE=TRUE MATCH_BY_COLUMN_NAME=CASE_SENSITIVE);

-- Statement 141
ALTER TABLE foo UNSET TAG a, b, c;

-- Statement 142
ALTER TABLE foo UNSET DATA_RETENTION_TIME_IN_DAYS, CHANGE_TRACKING;

-- Statement 143
ALTER SESSION SET autocommit = FALSE, QUERY_TAG = 'qtag', JSON_INDENT = 1;

-- Statement 144
ALTER SESSION UNSET autocommit, QUERY_TAG;

-- Statement 145
CREATE TABLE t (col1 INT PRIMARY KEY {option}, col2 INT UNIQUE {option}, col3 INT NOT NULL FOREIGN KEY REFERENCES other_t (id) {option});

-- Statement 146
CREATE TABLE t (col1 INT, col2 INT, col3 INT, PRIMARY KEY (col1) {option}, UNIQUE (col1, col2) {option}, FOREIGN KEY (col3) REFERENCES other_t (id) {option});

-- Statement 147
CREATE OR REPLACE VIEW FOO (A, B) COPY GRANTS AS SELECT A, B FROM TBL;

-- Statement 148
CREATE OR REPLACE MATERIALIZED VIEW FOO COPY GRANTS (A, B) AS SELECT A, B FROM TBL;

-- Statement 149
CREATE OR REPLACE MATERIALIZED VIEW FOO COPY GRANTS (A, B) COMMENT='foo' TAG (a='b') AS SELECT A, B FROM TBL;

-- Statement 150
CREATE OR REPLACE VIEW FOO (A, B) AS SELECT A, B FROM TBL;

-- Statement 151
CREATE OR REPLACE MATERIALIZED VIEW FOO (A, B) AS SELECT A, B FROM TBL;

-- Statement 152
CREATE VIEW v (c) CHANGE_TRACKING=TRUE AS SELECT 1 AS c;

-- Statement 153
CREATE VIEW my_view CHANGE_TRACKING=TRUE (id) AS SELECT * FROM my_table;

-- Statement 154
CREATE VIEW my_view (id) CHANGE_TRACKING=TRUE AS SELECT * FROM my_table;

-- Statement 155
CREATE VIEW v WITH ROW ACCESS POLICY mypolicy ON (col1) AS SELECT col1 FROM t1;

-- Statement 156
CREATE OR REPLACE VIEW v WITH ROW ACCESS POLICY db.schema.mypolicy ON (col1, col2) AS SELECT col1, col2 FROM t1;

-- Statement 157
CREATE VIEW v (COL1 COMMENT 'description') WITH ROW ACCESS POLICY db.schema.policy ON (COL1) COMMENT='some comment' AS (SELECT a FROM t1 LEFT JOIN t2 ON t1.id = t2.id);

-- Statement 158
CREATE VIEW v ROW ACCESS POLICY p ON (c) AS SELECT c FROM t;

-- Statement 159
CREATE VIEW v WITH ROW ACCESS POLICY p ON (c) AS SELECT c FROM t;

-- Statement 160
CREATE TABLE t (c INT) ROW ACCESS POLICY p ON (c);

-- Statement 161
CREATE TABLE t (c INT) WITH ROW ACCESS POLICY p ON (c);

-- Statement 162
CREATE VIEW v WITH ROW ACCESS POLICY p AS SELECT 1;

-- Statement 163
CREATE VIEW v WITH ROW ACCESS POLICY #unknown_policy AS SELECT 1;

-- Statement 164
CREATE VIEW "v" WITH ROW ACCESS POLICY #unknown_policy AS SELECT 1;

-- Statement 165
CREATE SEQUENCE seq  START=5 comment = 'foo' INCREMENT=10;

-- Statement 166
CREATE SEQUENCE seq COMMENT='foo' START WITH 5 INCREMENT BY 10;

-- Statement 167
CREATE SEQUENCE seq WITH START=1 INCREMENT=1;

-- Statement 168
CREATE SEQUENCE seq START WITH 1 INCREMENT BY 1;

-- Statement 169
ALTER SESSION SET autocommit = FALSE;

