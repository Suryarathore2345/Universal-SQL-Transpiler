-- SQLGlot oracle DDL statements
-- Extracted from oracle.py test fixtures
-- Total statements: 14
-- ============================================================

-- Statement 1
ALTER TABLE tbl_name DROP FOREIGN KEY fk_symbol;

-- Statement 2
CREATE GLOBAL TEMPORARY TABLE t AS SELECT * FROM orders;

-- Statement 3
CREATE PRIVATE TEMPORARY TABLE t AS SELECT * FROM orders;

-- Statement 4
ALTER TABLE Payments ADD Stock NUMBER NOT NULL;

-- Statement 5
ALTER TABLE Payments ADD (Stock NUMBER NOT NULL, dropid VARCHAR2(500) NOT NULL);

-- Statement 6
CREATE OR REPLACE FORCE VIEW foo1.foo2;

-- Statement 7 REMOVED: `CREATE VIEW view AS SELECT * FROM tbl WITH {restriction}{constraint_name};`
-- was not valid SQL to begin with — it is a literal, unfilled Python str.format()
-- template scraped verbatim from a parameterized sqlglot test (the {..} placeholders
-- were never substituted by the extraction script). Confirmed this input triggers a
-- genuine sqlglot library bug: under error_level=ErrorLevel.WARN, sqlglot's ambiguous-
-- "multiple WITH clauses" error-recovery path loops indefinitely instead of raising
-- (ErrorLevel.RAISE rejects the same input cleanly in <0.03s). UST now has a bounded
-- watchdog timeout around every sqlglot parse call (app/dialects/base.py) so this no
-- longer hangs the API — it fails fast with a clear timeout error instead — but the
-- statement itself is removed here since it was never a real SQL benchmark case.

-- Statement 8
CREATE OR REPLACE PROCEDURE query_emp(
    p_id     IN  VARCHAR2,
    p_name   OUT VARCHAR2,
    p_salary OUT NUMBER
) AS
BEGIN
    SELECT last_name, salary 
    INTO p_name, p_salary
    FROM employees
    WHERE employee_id = p_id;
END;

-- Statement 9
CREATE OR REPLACE PROCEDURE query_emp(p_id IN VARCHAR2, p_name OUT VARCHAR2, p_salary OUT NUMBER) AS BEGIN SELECT last_name, salary INTO p_name, p_salary FROM employees WHERE employee_id = p_id; END;

-- Statement 10
CREATE OR REPLACE PROCEDURE test_proc (
    a NUMBER,
    b IN NUMBER,
    c IN OUT NUMBER,
    d OUT NUMBER
) AS
BEGIN
    c := c + a + b;
    d := 42 + c;
END;

-- Statement 11
CREATE OR REPLACE PROCEDURE test_proc(a NUMBER, b IN NUMBER, c IN OUT NUMBER, d OUT NUMBER) AS BEGIN c := c + a + b; d := 42 + c; END;

-- Statement 12
CREATE TRIGGER check_salary BEFORE INSERT ON employees FOR EACH ROW BEGIN :NEW.status := 'PENDING' END;

-- Statement 13
CREATE TRIGGER audit_trigger AFTER UPDATE ON accounts FOR EACH ROW BEGIN INSERT INTO audit_log (user_id, old_balance, new_balance, changed_at) VALUES (:OLD.id, :OLD.balance, :NEW.balance, SYSDATE) END;

-- Statement 14
CREATE TRIGGER view_insert INSTEAD OF INSERT ON employee_view FOR EACH ROW BEGIN INSERT INTO employees (id, name, dept_id) VALUES (:NEW.id, :NEW.name, :NEW.dept_id) END;

