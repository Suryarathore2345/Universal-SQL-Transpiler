-- Redshift edge-case DDL: function conversions
-- Tests every function our transpiler handles for all targets

CREATE OR REPLACE VIEW reporting.edge_case_functions AS
SELECT
    -- NVL / NVL2
    NVL(salary, 0)                                    AS salary_nvl,
    NVL2(commission_pct, salary * commission_pct, 0)  AS commission_earned,

    -- COALESCE (standard, should pass through mostly intact)
    COALESCE(manager_id, department_id, 0)            AS mgr_or_dept,

    -- Date functions
    DATEADD(day, 30, hire_date)                       AS trial_end_date,
    DATEDIFF(month, hire_date, GETDATE())              AS months_employed,
    TRUNC(hire_date, 'month')                         AS hire_month_start,
    DATE_PART('year', hire_date)                      AS hire_year,
    date_part_year(hire_date)                         AS hire_year_v2,

    -- String functions
    SPLIT_PART(email, '@', 1)                         AS email_user,
    SPLIT_PART(email, '@', 2)                         AS email_domain,
    INITCAP(first_name)                               AS first_name_proper,
    REGEXP_REPLACE(phone, '[^0-9]', '')               AS phone_digits,
    LISTAGG(department_id, ',') WITHIN GROUP (ORDER BY department_id) AS dept_list,

    -- Casting (Redshift :: shorthand)
    salary::VARCHAR                                   AS salary_str,
    hire_date::TIMESTAMP                              AS hire_ts,
    employee_id::BIGINT                               AS emp_id_big,
    commission_pct::DECIMAL(5,2)                      AS commission_dec,

    -- CONVERT_TIMEZONE
    CONVERT_TIMEZONE('UTC', 'America/New_York', hire_date::TIMESTAMP) AS hire_date_et,

    -- Window functions
    ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS dept_rank,
    RANK()       OVER (PARTITION BY department_id ORDER BY salary DESC) AS dept_dense_rank,
    LAG(salary)  OVER (PARTITION BY department_id ORDER BY hire_date)   AS prev_salary,
    LEAD(salary) OVER (PARTITION BY department_id ORDER BY hire_date)   AS next_salary,
    SUM(salary)  OVER (PARTITION BY department_id)                      AS dept_total,
    AVG(salary)  OVER (PARTITION BY department_id)                      AS dept_avg,

    -- CASE WHEN
    CASE
        WHEN salary > 10000 THEN 'Senior'
        WHEN salary > 5000  THEN 'Mid'
        ELSE 'Junior'
    END AS seniority_band,

    -- NULLIF
    NULLIF(commission_pct, 0) AS commission_or_null,

    -- DECODE (Redshift-specific, similar to Oracle)
    DECODE(job_id,
        'SA_REP',  'Sales',
        'IT_PROG', 'Engineering',
        'Other'
    ) AS department_group

FROM hr.employees;

-- MV with distkey/sortkey (Redshift-specific)
CREATE MATERIALIZED VIEW reporting.mv_dept_salary_stats
DISTKEY (department_id)
SORTKEY (department_id, salary_band)
AS
SELECT
    department_id,
    CASE
        WHEN AVG(salary) > 10000 THEN 'High'
        WHEN AVG(salary) > 5000  THEN 'Medium'
        ELSE 'Low'
    END AS salary_band,
    COUNT(*)    AS headcount,
    AVG(salary) AS avg_salary,
    MAX(salary) AS max_salary,
    MIN(salary) AS min_salary,
    SUM(salary) AS total_payroll
FROM hr.employees
GROUP BY department_id,
    CASE
        WHEN AVG(salary) > 10000 THEN 'High'
        WHEN AVG(salary) > 5000  THEN 'Medium'
        ELSE 'Low'
    END;
