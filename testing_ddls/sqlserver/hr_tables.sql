-- SQL Server: HR Domain Tables

CREATE TABLE hr.departments (
    department_id   INT NOT NULL IDENTITY(1,1),
    dept_code       NVARCHAR(20) NOT NULL,
    dept_name       NVARCHAR(100) NOT NULL,
    parent_dept_id  INT,
    cost_center     NVARCHAR(20),
    location        NVARCHAR(100),
    is_active       BIT NOT NULL DEFAULT 1,
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_departments PRIMARY KEY (department_id),
    CONSTRAINT UQ_dept_code UNIQUE (dept_code)
);

CREATE TABLE hr.job_grades (
    grade_id        INT NOT NULL IDENTITY(1,1),
    grade_code      NVARCHAR(10) NOT NULL,
    grade_name      NVARCHAR(100) NOT NULL,
    level_num       SMALLINT NOT NULL,
    min_salary      DECIMAL(12,2) NOT NULL,
    mid_salary      DECIMAL(12,2),
    max_salary      DECIMAL(12,2) NOT NULL,
    is_active       BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_job_grades PRIMARY KEY (grade_id),
    CONSTRAINT UQ_grade_code UNIQUE (grade_code)
);

CREATE TABLE hr.employees (
    employee_id     BIGINT NOT NULL IDENTITY(1,1),
    employee_number NVARCHAR(20) NOT NULL,
    first_name      NVARCHAR(100) NOT NULL,
    last_name       NVARCHAR(100) NOT NULL,
    middle_name     NVARCHAR(100),
    email           NVARCHAR(255) NOT NULL,
    phone           NVARCHAR(30),
    gender          NVARCHAR(10),
    date_of_birth   DATE,
    national_id     NVARCHAR(50),
    nationality     CHAR(2),
    department_id   INT,
    job_title       NVARCHAR(150),
    grade_id        INT,
    manager_id      BIGINT,
    employment_type NVARCHAR(30) NOT NULL DEFAULT 'FULL_TIME',
    hire_date       DATE NOT NULL,
    termination_date DATE,
    status          NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    work_location   NVARCHAR(100),
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_employees PRIMARY KEY (employee_id),
    CONSTRAINT UQ_employee_number UNIQUE (employee_number),
    CONSTRAINT UQ_employee_email UNIQUE (email),
    CONSTRAINT FK_employees_dept FOREIGN KEY (department_id) REFERENCES hr.departments(department_id),
    CONSTRAINT FK_employees_grade FOREIGN KEY (grade_id) REFERENCES hr.job_grades(grade_id)
);

CREATE TABLE hr.salaries (
    salary_id       BIGINT NOT NULL IDENTITY(1,1),
    employee_id     BIGINT NOT NULL,
    effective_date  DATE NOT NULL,
    end_date        DATE,
    base_salary     DECIMAL(14,2) NOT NULL,
    currency        CHAR(3) NOT NULL DEFAULT 'USD',
    pay_frequency   NVARCHAR(20) NOT NULL DEFAULT 'MONTHLY',
    change_reason   NVARCHAR(100),
    approved_by     BIGINT,
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_salaries PRIMARY KEY (salary_id),
    CONSTRAINT FK_salaries_employee FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id)
);

CREATE TABLE hr.leave_requests (
    leave_id        BIGINT NOT NULL IDENTITY(1,1),
    employee_id     BIGINT NOT NULL,
    leave_type      NVARCHAR(50) NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    days_requested  DECIMAL(4,1) NOT NULL,
    reason          NVARCHAR(MAX),
    status          NVARCHAR(20) NOT NULL DEFAULT 'PENDING',
    approved_by     BIGINT,
    approved_at     DATETIME2,
    comments        NVARCHAR(MAX),
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_leave_requests PRIMARY KEY (leave_id),
    CONSTRAINT FK_leave_employee FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id)
);

CREATE TABLE hr.payroll (
    payroll_id          BIGINT NOT NULL IDENTITY(1,1),
    employee_id         BIGINT NOT NULL,
    pay_period_start    DATE NOT NULL,
    pay_period_end      DATE NOT NULL,
    gross_pay           DECIMAL(14,2) NOT NULL,
    income_tax          DECIMAL(12,2) NOT NULL DEFAULT 0,
    social_security     DECIMAL(12,2) NOT NULL DEFAULT 0,
    health_insurance    DECIMAL(12,2) NOT NULL DEFAULT 0,
    retirement_contrib  DECIMAL(12,2) NOT NULL DEFAULT 0,
    other_deductions    DECIMAL(12,2) NOT NULL DEFAULT 0,
    net_pay             DECIMAL(14,2) NOT NULL,
    currency            CHAR(3) NOT NULL DEFAULT 'USD',
    status              NVARCHAR(20) NOT NULL DEFAULT 'PROCESSED',
    paid_at             DATETIME2,
    created_at          DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_payroll PRIMARY KEY (payroll_id),
    CONSTRAINT FK_payroll_employee FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id)
);

CREATE TABLE hr.performance_reviews (
    review_id       BIGINT NOT NULL IDENTITY(1,1),
    employee_id     BIGINT NOT NULL,
    reviewer_id     BIGINT NOT NULL,
    review_period   NVARCHAR(20) NOT NULL,
    review_type     NVARCHAR(30) NOT NULL,
    overall_rating  DECIMAL(3,1),
    goals_score     DECIMAL(3,1),
    competency_score DECIMAL(3,1),
    feedback        NVARCHAR(MAX),
    dev_plan        NVARCHAR(MAX),
    status          NVARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    submitted_at    DATETIME2,
    acknowledged_at DATETIME2,
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_reviews PRIMARY KEY (review_id)
);
