-- SQLGlot oracle DML statements
-- Extracted from oracle.py test fixtures
-- Total statements: 152
-- ============================================================

-- Statement 1
SELECT CONNECT_BY_ROOT x y;

-- Statement 2
SELECT CONNECT_BY_ROOT x AS y;

-- Statement 3
SELECT BITMAP_BUCKET_NUMBER(32769);

-- Statement 4
SELECT BITMAP_CONSTRUCT_AGG(value);

-- Statement 5
SELECT SYSTIMESTAMP AT TIME ZONE 'UTC';

-- Statement 6
SELECT x FROM t WHERE cond FOR UPDATE;

-- Statement 7
SELECT JSON_OBJECT(k1: v1 FORMAT JSON, k2: v2 FORMAT JSON);

-- Statement 8
SELECT JSON_OBJECT('name': first_name || ' ' || last_name) FROM t;

-- Statement 9
SELECT * FROM TABLE(foo);

-- Statement 10
SELECT a$x#b;

-- Statement 11
SELECT :OBJECT;

-- Statement 12
SELECT * FROM t FOR UPDATE;

-- Statement 13
SELECT * FROM t FOR UPDATE WAIT 5;

-- Statement 14
SELECT * FROM t FOR UPDATE NOWAIT;

-- Statement 15
SELECT * FROM t FOR UPDATE SKIP LOCKED;

-- Statement 16
SELECT * FROM t FOR UPDATE OF s.t.c, s.t.v;

-- Statement 17
SELECT * FROM t FOR UPDATE OF s.t.c, s.t.v NOWAIT;

-- Statement 18
SELECT * FROM t FOR UPDATE OF s.t.c, s.t.v SKIP LOCKED;

-- Statement 19
SELECT STANDARD_HASH('hello');

-- Statement 20
SELECT STANDARD_HASH('hello', 'MD5');

-- Statement 21
SELECT * FROM table_name@dblink_name.database_link_domain;

-- Statement 22
SELECT * FROM table_name SAMPLE (25) s;

-- Statement 23
SELECT COUNT(*) * 10 FROM orders SAMPLE (10) SEED (1);

-- Statement 24
SELECT * FROM V$SESSION;

-- Statement 25
SELECT TO_DATE('January 15, 1989, 11:00 A.M.');

-- Statement 26
SELECT INSTR(haystack, needle);

-- Statement 27
SELECT fred FROM barney WHERE dino ^= 'wilma';

-- Statement 28
SELECT fred FROM barney WHERE dino <> 'wilma';

-- Statement 29
SELECT (TIMESTAMP '2025-12-30 20:00:00' - TIMESTAMP '2025-12-29 14:30:00') DAY TO SECOND;

-- Statement 30
SELECT (TO_TIMESTAMP('2025-12-30 20:00:00', 'YYYY-MM-DD HH24:MI:SS.FF6') - TO_TIMESTAMP('2025-12-29 14:30:00', 'YYYY-MM-DD HH24:MI:SS.FF6')) DAY TO SECOND;

-- Statement 31
SELECT (SYSTIMESTAMP - order_date) DAY(9) TO SECOND FROM orders;

-- Statement 32
SELECT (SYSTIMESTAMP - order_date) DAY(9) TO SECOND(3) FROM orders;

-- Statement 33
SELECT * FROM consumer LEFT JOIN groceries ON consumer.groceries_id = consumer.id PIVOT(MAX(type_id) FOR consumer_type IN (1, 2, 3, 4));

-- Statement 34
SELECT * FROM test UNPIVOT INCLUDE NULLS (value FOR Description IN (col AS 'PREFIX ' || CHR(38) || ' SUFFIX'));

-- Statement 35
SELECT * FROM sales UNPIVOT(q FOR p IN (q1 AS 'Prod1', q2 AS 'Prod2'));

-- Statement 36
SELECT * FROM sales UNPIVOT(q FOR p IN (q1 AS 1, q2 AS 2));

-- Statement 37
SELECT last_name, employee_id, manager_id, LEVEL FROM employees START WITH employee_id = 100 CONNECT BY PRIOR employee_id = manager_id ORDER SIBLINGS BY last_name;

-- Statement 38
SELECT JSON_ARRAYAGG(JSON_OBJECT('RNK': RNK, 'RATING_CODE': RATING_CODE, 'DATE_VALUE': DATE_VALUE, 'AGENT_ID': AGENT_ID RETURNING CLOB) RETURNING CLOB) AS JSON_DATA FROM tablename;

-- Statement 39
SELECT JSON_ARRAY(FOO() FORMAT JSON, BAR() NULL ON NULL RETURNING CLOB STRICT);

-- Statement 40
SELECT JSON_ARRAYAGG(FOO() FORMAT JSON ORDER BY bar NULL ON NULL RETURNING CLOB STRICT);

-- Statement 41
SELECT COUNT(1) INTO V_Temp FROM TABLE(CAST(somelist AS data_list)) WHERE col LIKE '%contact';

-- Statement 42
SELECT * FROM t WHERE c LIKE (:v);

-- Statement 43
SELECT department_id INTO v_department_id FROM departments FETCH FIRST 1 ROWS ONLY;

-- Statement 44
SELECT department_id BULK COLLECT INTO v_department_ids FROM departments;

-- Statement 45
SELECT department_id, department_name BULK COLLECT INTO v_department_ids, v_department_names FROM departments;

-- Statement 46
SELECT MIN(column_name) KEEP (DENSE_RANK FIRST ORDER BY column_name DESC) FROM table_name;

-- Statement 47
SELECT CAST('January 15, 1989, 11:00 A.M.' AS DATE DEFAULT NULL ON CONVERSION ERROR, 'Month dd, YYYY, HH:MI A.M.') FROM DUAL;

-- Statement 48
SELECT TO_DATE('January 15, 1989, 11:00 A.M.', 'Month dd, YYYY, HH12:MI A.M.') FROM DUAL;

-- Statement 49
SELECT TRUNC(SYSDATE);

-- Statement 50
SELECT TRUNC(SYSDATE, 'DD');

-- Statement 51
SELECT JSON_OBJECT(KEY 'key1' IS emp.column1, KEY 'key2' IS emp.column1) "emp_key" FROM emp;

-- Statement 52
SELECT JSON_OBJECT('key1': emp.column1, 'key2': emp.column1) AS "emp_key" FROM emp;

-- Statement 53
SELECT JSON_OBJECTAGG(KEY department_name VALUE department_id) FROM dep WHERE id <= 30;

-- Statement 54
SELECT JSON_OBJECTAGG(department_name: department_id) FROM dep WHERE id <= 30;

-- Statement 55
SELECT last_name, department_id, salary, MIN(salary) KEEP (DENSE_RANK FIRST ORDER BY commission_pct);

-- Statement 56
SELECT UNIQUE col1, col2 FROM table;

-- Statement 57
SELECT DISTINCT col1, col2 FROM table;

-- Statement 58
SELECT * FROM T ORDER BY I OFFSET NVL(:variable1, 10) ROWS FETCH NEXT NVL(:variable2, 10) ROWS ONLY;

-- Statement 59
SELECT * FROM t SAMPLE (.25);

-- Statement 60
SELECT * FROM t SAMPLE (0.25);

-- Statement 61
SELECT TO_CHAR(-100, 'L99', 'NL_CURRENCY = '' AusDollars '' ');

-- Statement 62
SELECT * FROM t START WITH col CONNECT BY NOCYCLE PRIOR col1 = col2;

-- Statement 63
SELECT id FROM t START WITH (parent_id IS NULL) CONNECT BY PRIOR id = parent_id;

-- Statement 64
SELECT id FROM t START WITH (x) CONNECT BY PRIOR id = parent_id;

-- Statement 65
SELECT DBMS_RANDOM.VALUE();

-- Statement 66
SELECT DBMS_RANDOM.VALUE;

-- Statement 67
SELECT RANDOM();

-- Statement 68
SELECT TRIM('|' FROM '||Hello ||| world||');

-- Statement 69
SELECT TRIM(BOTH '|' FROM '||Hello ||| world||');

-- Statement 70
SELECT department_id, department_name INTO v_department_id, v_department_name FROM departments FETCH FIRST 1 ROWS ONLY;

-- Statement 71
SELECT * FROM test WHERE MOD(col1, 4) = 3;

-- Statement 72
SELECT * FROM test WHERE col1 % 4 = 3;

-- Statement 73
SELECT CAST(NULL AS VARCHAR2(2328 CHAR)) AS COL1;

-- Statement 74
SELECT CAST(NULL AS VARCHAR(2328)) AS COL1;

-- Statement 75
SELECT CAST(NULL AS VARCHAR2(2328 BYTE)) AS COL1;

-- Statement 76
SELECT TO_TIMESTAMP('2024-12-12 12:12:12.000000', 'YYYY-MM-DD HH24:MI:SS.FF6');

-- Statement 77
SELECT STRPTIME('2024-12-12 12:12:12.000000', '%Y-%m-%d %H:%M:%S.%f');

-- Statement 78
SELECT TO_DATE('2024-12-12', 'YYYY-MM-DD');

-- Statement 79
SELECT CAST(STRPTIME('2024-12-12', '%Y-%m-%d') AS DATE);

-- Statement 80
SELECT * FROM t ORDER BY a ASC NULLS LAST, b ASC NULLS FIRST, c DESC NULLS LAST, d DESC NULLS FIRST;

-- Statement 81
SELECT * FROM t ORDER BY a ASC, b ASC NULLS FIRST, c DESC NULLS LAST, d DESC;

-- Statement 82
SELECT /*+ ORDERED */* FROM tbl;

-- Statement 83
SELECT /*+ ORDERED */ * FROM tbl;

-- Statement 84
SELECT /* test */ /*+ ORDERED */* FROM tbl;

-- Statement 85
SELECT /*+ ORDERED */*/* test */ FROM tbl;

-- Statement 86
SELECT /*+ ORDERED */ * /* test */ FROM tbl;

-- Statement 87
SELECT * FROM t FETCH FIRST 10 ROWS ONLY;

-- Statement 88
SELECT * FROM t ORDER BY (SELECT NULL) OFFSET 0 ROWS FETCH FIRST 10 ROWS ONLY;

-- Statement 89
SELECT TO_TIMESTAMP('05 Dec 2000 10:00 AM', 'DD Mon YYYY HH12:MI AM');

-- Statement 90
SELECT TO_TIMESTAMP('05 Dec 2000 10:00 PM', 'DD Mon YYYY HH12:MI PM');

-- Statement 91
SELECT TO_TIMESTAMP('05 Dec 2000 10:00 A.M.', 'DD Mon YYYY HH12:MI A.M.');

-- Statement 92
SELECT TO_TIMESTAMP('05 Dec 2000 10:00 P.M.', 'DD Mon YYYY HH12:MI P.M.');

-- Statement 93
SELECT CUME_DIST(15, 0.05) WITHIN GROUP (ORDER BY col1, col2) FROM t;

-- Statement 94
SELECT DENSE_RANK(15, 0.05) WITHIN GROUP (ORDER BY col1, col2) FROM t;

-- Statement 95
SELECT RANK(15, 0.05) WITHIN GROUP (ORDER BY col1, col2) FROM t;

-- Statement 96
SELECT PERCENT_RANK(15, 0.05) WITHIN GROUP (ORDER BY col1, col2) FROM t;

-- Statement 97
SELECT * FROM t UNPIVOT(revenue FOR month IN (t.jan, t.feb)) AS u;

-- Statement 98
SELECT * FROM t UNPIVOT(revenue FOR month IN (jan, feb)) u;

-- Statement 99
SELECT * FROM t PIVOT(SUM(t.val) FOR t.cat IN ('a' AS a)) AS p;

-- Statement 100
SELECT * FROM t PIVOT(SUM(t.val) FOR cat IN ('a' AS a)) p;

-- Statement 101
SELECT * FROM t UNPIVOT(revenue FOR month IN (jan, feb));

-- Statement 102
SELECT "T"."ID" AS "ID", "T"."MONTH" AS "MONTH", "T"."REVENUE" AS "REVENUE";

-- Statement 103
SELECT e1.x, e2.x FROM e e1, e e2 WHERE e1.y (+) = e2.y;

-- Statement 104
SELECT e1.x, e2.x FROM e e1, e e2 WHERE e1.y = e2.y (+);

-- Statement 105
SELECT e1.x, e2.x FROM e AS e1, e AS e2 WHERE e1.y = e2.y;

-- Statement 106
SELECT /*+ USE_NL(A B) */ A.COL_TEST FROM TABLE_A A, TABLE_B B;

-- Statement 107
SELECT /*+ INDEX(v.j jhist_employee_ix (employee_id start_date)) */ * FROM v;

-- Statement 108
SELECT /*+ USE_NL(A B C) */ A.COL_TEST FROM TABLE_A A, TABLE_B B, TABLE_C C;

-- Statement 109
SELECT /*+ NO_INDEX(employees emp_empid) */ employee_id FROM employees WHERE employee_id > 200;

-- Statement 110
SELECT /*+ NO_INDEX_FFS(items item_order_ix) */ order_id FROM order_items items;

-- Statement 111
SELECT /*+ LEADING(e j) */ * FROM employees e, departments d, job_history j WHERE e.department_id = d.department_id AND e.hire_date = j.start_date;

-- Statement 112
INSERT /*+ APPEND */ INTO IAP_TBL (id, col1) VALUES (2, 'test2');

-- Statement 113
INSERT /*+ APPEND_VALUES */ INTO dest_table VALUES (i, 'Value');

-- Statement 114
INSERT /*+ APPEND(d) */ INTO dest d VALUES (i, 'Value');

-- Statement 115
INSERT /*+ APPEND(d) */ INTO dest d (i, value) SELECT 1, 'value' FROM dual;

-- Statement 116
SELECT /*+ LEADING(departments employees) USE_NL(employees) */ * FROM employees JOIN departments ON employees.department_id = departments.department_id;

-- Statement 117
SELECT /*+ LEADING(departments employees)
  USE_NL(employees) */
  *
FROM employees
JOIN departments
  ON employees.department_id = departments.department_id;

-- Statement 118
SELECT /*+ USE_NL(bbbbbbbbbbbbbbbbbbbbbbbb) LEADING(aaaaaaaaaaaaaaaaaaaaaaaa bbbbbbbbbbbbbbbbbbbbbbbb cccccccccccccccccccccccc dddddddddddddddddddddddd) INDEX(cccccccccccccccccccccccc) */ * FROM aaaaaaaaaaaaaaaaaaaaaaaa JOIN bbbbbbbbbbbbbbbbbbbbbbbb ON aaaaaaaaaaaaaaaaaaaaaaaa.id = bbbbbbbbbbbbbbbbbbbbbbbb.a_id JOIN cccccccccccccccccccccccc ON bbbbbbbbbbbbbbbbbbbbbbbb.id = cccccccccccccccccccccccc.b_id JOIN dddddddddddddddddddddddd ON cccccccccccccccccccccccc.id = dddddddddddddddddddddddd.c_id;

-- Statement 119
SELECT /*+ USE_NL(bbbbbbbbbbbbbbbbbbbbbbbb)
  LEADING(
    aaaaaaaaaaaaaaaaaaaaaaaa
    bbbbbbbbbbbbbbbbbbbbbbbb
    cccccccccccccccccccccccc
    dddddddddddddddddddddddd
  )
  INDEX(cccccccccccccccccccccccc) */
  *
FROM aaaaaaaaaaaaaaaaaaaaaaaa
JOIN bbbbbbbbbbbbbbbbbbbbbbbb
  ON aaaaaaaaaaaaaaaaaaaaaaaa.id = bbbbbbbbbbbbbbbbbbbbbbbb.a_id
JOIN cccccccccccccccccccccccc
  ON bbbbbbbbbbbbbbbbbbbbbbbb.id = cccccccccccccccccccccccc.b_id
JOIN dddddddddddddddddddddddd
  ON cccccccccccccccccccccccc.id = dddddddddddddddddddddddd.c_id;

-- Statement 120
SELECT /*+ LEADING(departments employees) USE_NL(employees) select where group by is order by */ * FROM employees JOIN departments ON employees.department_id = departments.department_id;

-- Statement 121
SELECT /*+ LEADING(departments employees) USE_NL(employees) select where group by is order by */
  *
FROM employees
JOIN departments
  ON employees.department_id = departments.department_id;

-- Statement 122
SELECT /*+ LEADING(departments, employees) */ * FROM employees JOIN departments ON employees.department_id = departments.department_id;

-- Statement 123
SELECT /*+ LEADING(departments select) */ * FROM employees JOIN departments ON employees.department_id = departments.department_id;

-- Statement 124
SELECT x.* FROM example t, XMLTABLE(XMLNAMESPACES(DEFAULT 'http://example.com/default', 'http://example.com/ns1' AS \"ns1\"), '/root/data' PASSING t.xml COLUMNS id NUMBER PATH '@id', value VARCHAR2(100) PATH 'ns1:value/text()') x;

-- Statement 125
SELECT warehouse_name warehouse,
warehouse2."Water", warehouse2."Rail"
FROM warehouses,
XMLTABLE('/Warehouse'
   PASSING warehouses.warehouse_spec
   COLUMNS
      "Water" varchar2(6) PATH 'WaterAccess',
      "Rail" varchar2(6) PATH 'RailAccess')
   warehouse2;

-- Statement 126
SELECT table_name, column_name, data_default FROM xmltable('ROWSET/ROW'
passing dbms_xmlgen.getxmltype('SELECT table_name, column_name, data_default FROM user_tab_columns')
columns table_name      VARCHAR2(128)   PATH '*[1]'
        , column_name   VARCHAR2(128)   PATH '*[2]'
        , data_default  VARCHAR2(2000)  PATH '*[3]'
        );

-- Statement 127
SELECT * FROM JSON_TABLE(foo FORMAT JSON, 'bla' ERROR ON ERROR NULL ON EMPTY COLUMNS(foo PATH 'bar'));

-- Statement 128
SELECT * FROM JSON_TABLE(foo FORMAT JSON, 'bla' ERROR ON ERROR NULL ON EMPTY COLUMNS foo PATH 'bar');

-- Statement 129
SELECT * FROM JSON_TABLE(my_doc, '$.data[*]' COLUMNS(NAME VARCHAR2(200) PATH '$.name', DATA CLOB FORMAT JSON PATH '$.data')) j;

-- Statement 130
SELECT last_name "Employee",
LEVEL, SYS_CONNECT_BY_PATH(last_name, '/') "Path"
FROM employees
WHERE level <= 3 AND department_id = 80;

-- Statement 131
SELECT * FROM tbl WITH {restriction}{constraint_name};

-- Statement 132
SELECT * FROM tbl WITH;

-- Statement 133
SELECT * FROM tbl WITH READ;

-- Statement 134
SELECT * FROM tbl WITH GRANT OPTION;

-- Statement 135
SELECT * FROM t WITH x AS (SELECT 1) SELECT * FROM x;

-- Statement 136
INSERT ALL;

-- Statement 137
SELECT id, description FROM source_tab;

-- Statement 138
SELECT *;

-- Statement 139
SELECT id, description;

-- Statement 140
INSERT FIRST;

-- Statement 141
SELECT salary FROM employees;

-- Statement 142
SELECT * FROM t WHERE JSON_EXISTS(name{format_json}, '$[1].middle'{passing}{on_cond});

-- Statement 143
SELECT id, PRIOR name AS parent_name, name FROM tree CONNECT BY NOCYCLE PRIOR id = parent_id;

-- Statement 144
SELECT LISTAGG(last_name, '; ' ON OVERFLOW TRUNCATE '...' WITH COUNT);

-- Statement 145
SELECT LISTAGG(last_name, '; ' ON OVERFLOW ERROR);

-- Statement 146
MERGE INTO target tgt USING (SELECT id, col1 FROM source_tbl) src ON tgt.id = src.id;

-- Statement 147
MERGE INTO target AS tgt USING (SELECT id, col1 FROM source_tbl) AS src ON tgt.id = src.id;

-- Statement 148
MERGE INTO my_table USING (SELECT * FROM something) source_table ON my_table.id = source_table.id WHEN MATCHED THEN UPDATE SET my_table.col1 = source_table.col1 WHEN NOT MATCHED THEN INSERT (my_table.id, my_table.col1) VALUES (source_table.id, source_table.col1);

-- Statement 149
WITH t AS (SELECT 1 AS COL) SELECT col, ROWID FROM t WHERE ROWNUM = 1;

-- Statement 150
WITH "T" AS (SELECT 1 AS "COL") SELECT "T"."COL" AS "COL", ROWID AS "ROWID" FROM "T" "T" WHERE ROWNUM = 1;

-- Statement 151
SELECT CHR(187 USING NCHAR_CS);

-- Statement 152
SELECT CHR(187);

