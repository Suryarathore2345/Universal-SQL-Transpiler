-- Oracle HR Sample Schema - Views and complex SQL patterns
-- Tests: Oracle-specific syntax, WITH READ ONLY, old-style joins, functions

CREATE OR REPLACE VIEW hr.emp_details_view (
    employee_id, job_id, manager_id, department_id, location_id, country_id,
    first_name, last_name, salary, commission_pct,
    department_name, job_title, city, state_province, country_name, region_name
) AS
SELECT
    e.employee_id,
    e.job_id,
    e.manager_id,
    e.department_id,
    d.location_id,
    l.country_id,
    e.first_name,
    e.last_name,
    e.salary,
    e.commission_pct,
    d.department_name,
    j.job_title,
    l.city,
    l.state_province,
    c.country_name,
    r.region_name
FROM
    hr.employees e,
    hr.departments d,
    hr.jobs j,
    hr.locations l,
    hr.countries c,
    hr.regions r
WHERE e.department_id = d.department_id
  AND d.location_id   = l.location_id
  AND l.country_id    = c.country_id
  AND c.region_id     = r.region_id
  AND j.job_id        = e.job_id
WITH READ ONLY;

-- View using DECODE (Oracle-specific), NVL, SUBSTR, TO_CHAR
CREATE OR REPLACE VIEW hr.employee_salary_grade AS
SELECT
    e.employee_id,
    e.first_name || ' ' || e.last_name AS full_name,
    e.salary,
    NVL(e.commission_pct, 0)           AS commission_pct,
    e.salary * (1 + NVL(e.commission_pct, 0)) AS total_compensation,
    DECODE(
        TRUNC(e.salary / 5000),
        0, 'Grade A',
        1, 'Grade B',
        2, 'Grade C',
        'Grade D'
    ) AS salary_grade,
    TO_CHAR(e.hire_date, 'YYYY-MM-DD') AS hire_date_str,
    SUBSTR(e.email, 1, INSTR(e.email, '@') - 1) AS email_username,
    TRUNC(MONTHS_BETWEEN(SYSDATE, e.hire_date) / 12) AS years_employed,
    d.department_name
FROM hr.employees e
JOIN hr.departments d ON e.department_id = d.department_id;

-- View with window functions and CASE WHEN
CREATE OR REPLACE VIEW hr.department_salary_ranking AS
SELECT
    e.department_id,
    d.department_name,
    e.employee_id,
    e.last_name,
    e.salary,
    RANK() OVER (PARTITION BY e.department_id ORDER BY e.salary DESC) AS salary_rank,
    DENSE_RANK() OVER (PARTITION BY e.department_id ORDER BY e.salary DESC) AS dense_salary_rank,
    ROW_NUMBER() OVER (PARTITION BY e.department_id ORDER BY e.hire_date) AS hire_order,
    AVG(e.salary) OVER (PARTITION BY e.department_id) AS dept_avg_salary,
    SUM(e.salary) OVER (PARTITION BY e.department_id) AS dept_total_salary,
    LAG(e.salary)  OVER (PARTITION BY e.department_id ORDER BY e.salary)  AS prev_salary,
    LEAD(e.salary) OVER (PARTITION BY e.department_id ORDER BY e.salary)  AS next_salary,
    CASE
        WHEN e.salary > AVG(e.salary) OVER (PARTITION BY e.department_id) THEN 'Above Average'
        WHEN e.salary < AVG(e.salary) OVER (PARTITION BY e.department_id) THEN 'Below Average'
        ELSE 'Average'
    END AS salary_category
FROM hr.employees e
JOIN hr.departments d ON e.department_id = d.department_id;

-- View with EXTRACT, COALESCE, CAST
CREATE OR REPLACE VIEW hr.employee_tenure_view AS
SELECT
    employee_id,
    first_name,
    last_name,
    hire_date,
    EXTRACT(YEAR FROM hire_date)  AS hire_year,
    EXTRACT(MONTH FROM hire_date) AS hire_month,
    COALESCE(CAST(commission_pct AS VARCHAR2(10)), 'N/A') AS commission_display,
    CASE
        WHEN hire_date < DATE '2000-01-01' THEN 'Pre-2000'
        WHEN hire_date < DATE '2010-01-01' THEN '2000s'
        ELSE 'Recent'
    END AS hire_era,
    UPPER(job_id) AS job_id_upper
FROM hr.employees;
