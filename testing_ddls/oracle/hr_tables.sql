-- Oracle: HR Domain Tables (extends existing HR schema)

CREATE TABLE hr.departments (
    department_id   NUMBER(10) NOT NULL,
    dept_code       VARCHAR2(20) NOT NULL,
    dept_name       VARCHAR2(100) NOT NULL,
    parent_dept_id  NUMBER(10),
    head_emp_id     NUMBER(19),
    cost_center     VARCHAR2(20),
    location        VARCHAR2(100),
    is_active       NUMBER(1) DEFAULT 1,
    created_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_departments PRIMARY KEY (department_id),
    CONSTRAINT uq_dept_code UNIQUE (dept_code)
);

CREATE TABLE hr.employees (
    employee_id     NUMBER(19) NOT NULL,
    employee_number VARCHAR2(20) NOT NULL,
    first_name      VARCHAR2(100) NOT NULL,
    last_name       VARCHAR2(100) NOT NULL,
    middle_name     VARCHAR2(100),
    email           VARCHAR2(255) NOT NULL,
    phone           VARCHAR2(30),
    gender          VARCHAR2(10),
    date_of_birth   DATE,
    national_id     VARCHAR2(50),
    nationality     CHAR(2),
    department_id   NUMBER(10),
    job_title       VARCHAR2(150),
    grade_code      VARCHAR2(10),
    manager_id      NUMBER(19),
    employment_type VARCHAR2(30) DEFAULT 'FULL_TIME',
    hire_date       DATE NOT NULL,
    termination_date DATE,
    status          VARCHAR2(20) DEFAULT 'ACTIVE',
    work_location   VARCHAR2(100),
    created_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    updated_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_employees PRIMARY KEY (employee_id),
    CONSTRAINT uq_emp_number UNIQUE (employee_number),
    CONSTRAINT uq_emp_email UNIQUE (email),
    CONSTRAINT fk_emp_dept FOREIGN KEY (department_id) REFERENCES hr.departments(department_id)
);

CREATE TABLE hr.salaries (
    salary_id       NUMBER(19) NOT NULL,
    employee_id     NUMBER(19) NOT NULL,
    effective_date  DATE NOT NULL,
    end_date        DATE,
    base_salary     NUMBER(14,2) NOT NULL,
    currency        CHAR(3) DEFAULT 'USD',
    pay_frequency   VARCHAR2(20) DEFAULT 'MONTHLY',
    change_reason   VARCHAR2(100),
    approved_by     NUMBER(19),
    created_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_salaries PRIMARY KEY (salary_id),
    CONSTRAINT fk_sal_emp FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id)
);

CREATE TABLE hr.payroll_runs (
    payroll_run_id      NUMBER(19) NOT NULL,
    run_date            DATE NOT NULL,
    pay_period_start    DATE NOT NULL,
    pay_period_end      DATE NOT NULL,
    employee_id         NUMBER(19) NOT NULL,
    gross_pay           NUMBER(14,2) NOT NULL,
    income_tax          NUMBER(12,2) DEFAULT 0,
    social_security     NUMBER(12,2) DEFAULT 0,
    health_insurance    NUMBER(12,2) DEFAULT 0,
    pension_contrib     NUMBER(12,2) DEFAULT 0,
    other_deductions    NUMBER(12,2) DEFAULT 0,
    net_pay             NUMBER(14,2) NOT NULL,
    currency            CHAR(3) DEFAULT 'USD',
    status              VARCHAR2(20) DEFAULT 'PAID',
    paid_at             TIMESTAMP,
    CONSTRAINT pk_payroll_runs PRIMARY KEY (payroll_run_id),
    CONSTRAINT fk_pr_emp FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id)
);

CREATE TABLE hr.leave_requests (
    leave_id        NUMBER(19) NOT NULL,
    employee_id     NUMBER(19) NOT NULL,
    leave_type      VARCHAR2(50) NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    days_requested  NUMBER(4,1) NOT NULL,
    reason          CLOB,
    status          VARCHAR2(20) DEFAULT 'PENDING',
    approved_by     NUMBER(19),
    approved_at     TIMESTAMP,
    comments        CLOB,
    created_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_leave PRIMARY KEY (leave_id),
    CONSTRAINT fk_leave_emp FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id)
);

CREATE TABLE hr.performance_reviews (
    review_id       NUMBER(19) NOT NULL,
    employee_id     NUMBER(19) NOT NULL,
    reviewer_id     NUMBER(19) NOT NULL,
    review_period   VARCHAR2(20) NOT NULL,
    review_type     VARCHAR2(30) NOT NULL,
    overall_rating  NUMBER(3,1),
    goals_score     NUMBER(3,1),
    competency_score NUMBER(3,1),
    feedback        CLOB,
    dev_plan        CLOB,
    status          VARCHAR2(20) DEFAULT 'DRAFT',
    submitted_at    TIMESTAMP,
    acknowledged_at TIMESTAMP,
    created_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_perf_reviews PRIMARY KEY (review_id)
);
