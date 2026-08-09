-- ============================================================================
-- Oracle HR (Human Resources) Schema - Procedures and Triggers
-- Source: oracle-samples/db-sample-schemas (MIT License)
-- Schema Version: 21 | Release: 03-FEB-2022 | Requires: Oracle 19c+
-- ============================================================================

-- ============================================================================
-- PROCEDURES
-- ============================================================================

-- Procedure: secure_dml
-- Validates that DML operations occur only during business hours (Mon-Fri 08:00-18:00)
CREATE OR REPLACE PROCEDURE secure_dml
IS
BEGIN
  IF TO_CHAR (SYSDATE, 'HH24:MI') NOT BETWEEN '08:00' AND '18:00'
        OR TO_CHAR (SYSDATE, 'DY') IN ('SAT', 'SUN') THEN
	RAISE_APPLICATION_ERROR (-20205,
		'You may only make changes during normal office hours');
  END IF;
END secure_dml;
/

-- Procedure: add_job_history
-- Inserts a row into the JOB_HISTORY table
CREATE OR REPLACE PROCEDURE add_job_history
  (  p_emp_id          job_history.employee_id%type
   , p_start_date      job_history.start_date%type
   , p_end_date        job_history.end_date%type
   , p_job_id          job_history.job_id%type
   , p_department_id   job_history.department_id%type
   )
IS
BEGIN
  INSERT INTO job_history (employee_id, start_date, end_date,
                           job_id, department_id)
    VALUES(p_emp_id, p_start_date, p_end_date, p_job_id, p_department_id);
END add_job_history;
/

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger: secure_employees (statement-level, BEFORE)
-- Calls secure_dml before any DML on EMPLOYEES
CREATE OR REPLACE TRIGGER secure_employees
  BEFORE INSERT OR UPDATE OR DELETE ON employees
BEGIN
  secure_dml;
END secure_employees;
/

ALTER TRIGGER secure_employees DISABLE;

-- Trigger: update_job_history (row-level, AFTER UPDATE)
-- Automatically records job history when job_id or department_id changes
CREATE OR REPLACE TRIGGER update_job_history
  AFTER UPDATE OF job_id, department_id ON employees
  FOR EACH ROW
BEGIN
  add_job_history(:old.employee_id, :old.hire_date, sysdate,
                  :old.job_id, :old.department_id);
END;
/
