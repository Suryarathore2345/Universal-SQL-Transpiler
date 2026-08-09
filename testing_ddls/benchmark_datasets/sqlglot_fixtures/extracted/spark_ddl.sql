-- SQLGlot spark DDL statements
-- Extracted from spark.py test fixtures
-- Total statements: 60
-- ============================================================

-- Statement 1
DROP NAMESPACE my_catalog.my_namespace;

-- Statement 2
CREATE NAMESPACE my_catalog.my_namespace;

-- Statement 3
CREATE TABLE foo AS WITH t AS (SELECT 1 AS col) SELECT col FROM t;

-- Statement 4
CREATE TEMPORARY VIEW test AS SELECT 1;

-- Statement 5
CREATE TABLE foo (col VARCHAR(50));

-- Statement 6
CREATE TABLE foo (col STRUCT<struct_col_a: VARCHAR((50))>);

-- Statement 7
CREATE TABLE foo (col STRING) CLUSTERED BY (col) INTO 10 BUCKETS;

-- Statement 8
CREATE TABLE foo (col STRING) CLUSTERED BY (col) SORTED BY (col) INTO 10 BUCKETS;

-- Statement 9
TRUNCATE TABLE t1 PARTITION(age = 10, name = 'test', address);

-- Statement 10
CREATE TABLE db.example_table (col_a struct<struct_col_a:int, struct_col_b:string>);

-- Statement 11
CREATE TABLE db.example_table (col_a STRUCT(struct_col_a INT, struct_col_b TEXT));

-- Statement 12
CREATE TABLE db.example_table (col_a ROW(struct_col_a INTEGER, struct_col_b VARCHAR));

-- Statement 13
CREATE TABLE db.example_table (col_a STRUCT<struct_col_a: INT, struct_col_b: STRING>);

-- Statement 14
CREATE TABLE db.example_table (col_a struct<struct_col_a:int, struct_col_b:struct<nested_col_a:string, nested_col_b:string>>);

-- Statement 15
CREATE TABLE db.example_table (col_a STRUCT<struct_col_a INT64, struct_col_b STRUCT<nested_col_a STRING, nested_col_b STRING>>);

-- Statement 16
CREATE TABLE db.example_table (col_a STRUCT(struct_col_a INT, struct_col_b STRUCT(nested_col_a TEXT, nested_col_b TEXT)));

-- Statement 17
CREATE TABLE db.example_table (col_a ROW(struct_col_a INTEGER, struct_col_b ROW(nested_col_a VARCHAR, nested_col_b VARCHAR)));

-- Statement 18
CREATE TABLE db.example_table (col_a STRUCT<struct_col_a: INT, struct_col_b: STRUCT<nested_col_a: STRING, nested_col_b: STRING>>);

-- Statement 19
CREATE TABLE db.example_table (col_a array<int>, col_b array<array<int>>);

-- Statement 20
CREATE TABLE db.example_table (col_a ARRAY<INT64>, col_b ARRAY<ARRAY<INT64>>);

-- Statement 21
CREATE TABLE db.example_table (col_a INT[], col_b INT[][]);

-- Statement 22
CREATE TABLE db.example_table (col_a ARRAY(INTEGER), col_b ARRAY(ARRAY(INTEGER)));

-- Statement 23
CREATE TABLE db.example_table (col_a ARRAY, col_b ARRAY);

-- Statement 24
CREATE TABLE x USING ICEBERG PARTITIONED BY (MONTHS(y)) LOCATION 's3://z';

-- Statement 25
CREATE TABLE x;

-- Statement 26
CREATE TABLE x WITH (format='ICEBERG', PARTITIONED_BY=ARRAY['MONTHS(y)']);

-- Statement 27
CREATE TABLE x STORED AS ICEBERG PARTITIONED BY (MONTHS(y)) LOCATION 's3://z';

-- Statement 28
CREATE TABLE test STORED AS PARQUET AS SELECT 1;

-- Statement 29
CREATE TABLE test AS SELECT 1;

-- Statement 30
CREATE TABLE test WITH (format='PARQUET') AS SELECT 1;

-- Statement 31
CREATE TABLE blah (col_a INT) COMMENT "Test comment: blah" PARTITIONED BY (date STRING) USING ICEBERG TBLPROPERTIES('x' = '1');

-- Statement 32
CREATE TABLE blah (
  col_a INT
);

-- Statement 33
CREATE TABLE blah (
  col_a INTEGER,
  date VARCHAR
)
COMMENT 'Test comment: blah'
WITH (
  PARTITIONED_BY=ARRAY['date'],
  format='ICEBERG',
  x='1'
);

-- Statement 34
CREATE TABLE blah (
  col_a INT
)
COMMENT 'Test comment: blah'
PARTITIONED BY (
  date STRING
)
STORED AS ICEBERG
TBLPROPERTIES (
  'x'='1'
);

-- Statement 35
CREATE TABLE blah (
  col_a INT,
  date STRING
)
COMMENT 'Test comment: blah'
PARTITIONED BY (
  date
)
USING ICEBERG
TBLPROPERTIES (
  'x'='1'
);

-- Statement 36
ALTER TABLE StudentInfo ADD COLUMNS (LastName STRING, DOB TIMESTAMP);

-- Statement 37
ALTER TABLE db.example ALTER COLUMN col_a TYPE BIGINT;

-- Statement 38
ALTER TABLE db.example CHANGE COLUMN col_a col_a BIGINT;

-- Statement 39
ALTER TABLE db.example RENAME COLUMN col_a TO col_b;

-- Statement 40
ALTER TABLE StudentInfo DROP COLUMNS (LastName, DOB);

-- Statement 41
ALTER VIEW StudentInfoView AS SELECT * FROM StudentInfo;

-- Statement 42
ALTER VIEW StudentInfoView AS SELECT LastName FROM StudentInfo;

-- Statement 43
ALTER VIEW StudentInfoView RENAME TO StudentInfoViewRenamed;

-- Statement 44
ALTER VIEW StudentInfoView SET TBLPROPERTIES ('key1'='val1', 'key2'='val2');

-- Statement 45
ALTER VIEW StudentInfoView UNSET TBLPROPERTIES ('key1', 'key2');

-- Statement 46
ALTER TABLE foo ADD PARTITION(event = 'click');

-- Statement 47
ALTER TABLE foo ADD IF NOT EXISTS PARTITION(event = 'click');

-- Statement 48
CREATE VIEW emp_v WITH SCHEMA {schema_binding} AS SELECT * FROM emp;

-- Statement 49
DECLARE VAR x INT;

-- Statement 50
DECLARE x INT;

-- Statement 51
DECLARE VARIABLE myvar INT DEFAULT 5;

-- Statement 52
DECLARE myvar INT = 5;

-- Statement 53
DECLARE x, y, z INT DEFAULT 1;

-- Statement 54
DECLARE x, y, z INT = 1;

-- Statement 55
DECLARE x INT = 5;

-- Statement 56
DECLARE five = 5;

-- Statement 57
DECLARE OR REPLACE five = 55;

-- Statement 58
DECLARE VARIABLE size DEFAULT 6;

-- Statement 59
DECLARE size = 6;

-- Statement 60
DECLARE some_var STRING;

