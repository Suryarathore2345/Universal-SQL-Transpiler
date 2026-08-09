-- SQLGlot bigquery DDL statements
-- Extracted from bigquery.py test fixtures
-- Total statements: 55
-- ============================================================

-- Statement 1
CREATE OR REPLACE TABLE `a.b.c` CLONE `a.b.d`;

-- Statement 2
CREATE SCHEMA x DEFAULT COLLATE 'en';

-- Statement 3
CREATE TABLE x (y INT64) DEFAULT COLLATE 'en';

-- Statement 4
CREATE TABLE t CLUSTER BY col1, col2;

-- Statement 5
CREATE TABLE x (a STRUCT<values ARRAY<INT64>>);

-- Statement 6
CREATE TABLE x (a STRUCT<b STRING OPTIONS (description='b')>);

-- Statement 7
ALTER TABLE foo DROP PRIMARY KEY IF EXISTS;

-- Statement 8
CREATE TABLE x (a STRING OPTIONS (description='x')) OPTIONS (table_expiration_days=1);

-- Statement 9
CREATE TABLE IF NOT EXISTS foo AS SELECT * FROM bla EXCEPT DISTINCT (SELECT * FROM bar) LIMIT 0;

-- Statement 10
CREATE OR REPLACE VIEW test (tenant_id OPTIONS (description='Test description on table creation')) AS SELECT 1 AS tenant_id, 1 AS customer_id;

-- Statement 11
CREATE VIEW `d.v` OPTIONS (expiration_timestamp=TIMESTAMP '2020-01-02T04:05:06.007Z') AS SELECT 1 AS c;

-- Statement 12
CREATE VIEW `d.v` OPTIONS (expiration_timestamp=CAST('2020-01-02T04:05:06.007Z' AS TIMESTAMP)) AS SELECT 1 AS c;

-- Statement 13
CREATE TEMPORARY FUNCTION FOO()
RETURNS STRING
LANGUAGE js AS
'return "Hello world!"';

-- Statement 14
CREATE OR REPLACE TABLE `a.b.c` COPY `a.b.d`;

-- Statement 15
CREATE OR REPLACE TABLE "a"."b"."c" CLONE "a"."b"."d";

-- Statement 16
CREATE TEMP TABLE foo AS SELECT 1;

-- Statement 17
CREATE TEMPORARY TABLE foo AS SELECT 1;

-- Statement 18
CREATE TABLE db.example_table (col_a struct<struct_col_a:int, struct_col_b:string>);

-- Statement 19
CREATE TABLE db.example_table (col_a STRUCT<struct_col_a INT64, struct_col_b STRING>);

-- Statement 20
CREATE TABLE db.example_table (col_a STRUCT(struct_col_a INT, struct_col_b TEXT));

-- Statement 21
CREATE TABLE db.example_table (col_a ROW(struct_col_a INTEGER, struct_col_b VARCHAR));

-- Statement 22
CREATE TABLE db.example_table (col_a STRUCT<struct_col_a: INT, struct_col_b: STRING>);

-- Statement 23
CREATE TABLE db.example_table (col_a STRUCT<struct_col_a INT64, struct_col_b STRUCT<nested_col_a STRING, nested_col_b STRING>>);

-- Statement 24
CREATE TABLE db.example_table (col_a STRUCT(struct_col_a BIGINT, struct_col_b STRUCT(nested_col_a TEXT, nested_col_b TEXT)));

-- Statement 25
CREATE TABLE db.example_table (col_a ROW(struct_col_a BIGINT, struct_col_b ROW(nested_col_a VARCHAR, nested_col_b VARCHAR)));

-- Statement 26
CREATE TABLE db.example_table (col_a STRUCT<struct_col_a: BIGINT, struct_col_b: STRUCT<nested_col_a: STRING, nested_col_b: STRING>>);

-- Statement 27
CREATE TABLE db.example_table (x int) PARTITION BY x cluster by x;

-- Statement 28
CREATE TABLE db.example_table (x INT64) PARTITION BY x CLUSTER BY x;

-- Statement 29
CREATE TEMPORARY FUNCTION a(x FLOAT64, y FLOAT64) RETURNS FLOAT64 NOT DETERMINISTIC LANGUAGE js AS 'return x*y;';

-- Statement 30
CREATE TEMPORARY FUNCTION udf(x ANY TYPE) AS (x);

-- Statement 31
CREATE TEMPORARY FUNCTION a(x FLOAT64, y FLOAT64) AS ((x + 4) / y);

-- Statement 32
CREATE TABLE FUNCTION a(x INT64) RETURNS TABLE <q STRING, r INT64> AS SELECT s, t;

-- Statement 33
CREATE TEMPORARY FUNCTION string_length_0(strings ARRAY<STRING>) RETURNS FLOAT64 LANGUAGE js AS """'use strict'; function string_length(strings) { return _.sum(_.map(strings, ((x) => x.length))); } return string_length(strings);""" OPTIONS (library=['gs://ibis-testing-libraries/lodash.min.js']);

-- Statement 34
CREATE TEMPORARY FUNCTION string_length_0(strings ARRAY<STRING>) RETURNS FLOAT64 LANGUAGE js OPTIONS (library=['gs://ibis-testing-libraries/lodash.min.js']) AS '\\'use strict\\'; function string_length(strings) { return _.sum(_.map(strings, ((x) => x.length))); } return string_length(strings);';

-- Statement 35
CREATE TABLE test (a NUMERIC(10, 2));

-- Statement 36
CREATE OR REPLACE MODEL foo OPTIONS (model_type='linear_reg') AS SELECT bla FROM foo WHERE cond;

-- Statement 37
CREATE OR REPLACE MODEL m
TRANSFORM(
  ML.FEATURE_CROSS(STRUCT(f1, f2)) AS cross_f,
  ML.QUANTILE_BUCKETIZE(f3) OVER () AS buckets,
  label_col
)
OPTIONS (
  model_type='linear_reg',
  input_label_cols=['label_col']
) AS
SELECT
  *
FROM t;

-- Statement 38
CREATE MODEL project_id.mydataset.mymodel
INPUT(
  f1 INT64,
  f2 FLOAT64,
  f3 STRING,
  f4 ARRAY<INT64>
)
OUTPUT(
  out1 INT64,
  out2 INT64
)
REMOTE WITH CONNECTION myproject.us.test_connection
OPTIONS (
  ENDPOINT='https://us-central1-aiplatform.googleapis.com/v1/projects/myproject/locations/us-central1/endpoints/1234'
);

-- Statement 39
ALTER TABLE db.t1 RENAME TO db.t2;

-- Statement 40
ALTER TABLE db.t1 RENAME TO t2;

-- Statement 41
DECLARE X INT64;

-- Statement 42
DECLARE X INT64 DEFAULT 1;

-- Statement 43
DECLARE X FLOAT64 DEFAULT 0.9;

-- Statement 44
DECLARE X INT64 DEFAULT (SELECT MAX(col) FROM foo);

-- Statement 45
DECLARE X, Y, Z INT64;

-- Statement 46
DECLARE X, Y, Z INT64 DEFAULT 42;

-- Statement 47
DECLARE X, Y, Z INT64 DEFAULT (SELECT 42);

-- Statement 48
DECLARE START_DATE DATE DEFAULT CURRENT_DATE - 1;

-- Statement 49
DECLARE TS TIMESTAMP DEFAULT CURRENT_TIMESTAMP() - INTERVAL '1' HOUR;

-- Statement 50
DECLARE x {type_}(20, 4);

-- Statement 51
DECLARE x BIGNUMERIC(20, 4);

-- Statement 52
DECLARE x DECIMAL(20, 4);

-- Statement 53
DECLARE x {type_}(76, 38);

-- Statement 54
DECLARE x BIGNUMERIC(76, 38);

-- Statement 55
DECLARE x DECIMAL(38, 38);

