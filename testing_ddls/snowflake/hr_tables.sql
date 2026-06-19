-- Snowflake: Human Resources Domain Tables

CREATE OR REPLACE TABLE hr.departments (
    department_id   INTEGER NOT NULL AUTOINCREMENT,
    dept_code       VARCHAR(20) NOT NULL UNIQUE,
    dept_name       VARCHAR(100) NOT NULL,
    parent_dept_id  INTEGER,
    head_employee_id BIGINT,
    cost_center     VARCHAR(20),
    location        VARCHAR(100),
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (department_id)
);

CREATE OR REPLACE TABLE hr.job_grades (
    grade_id        INTEGER NOT NULL AUTOINCREMENT,
    grade_code      VARCHAR(10) NOT NULL UNIQUE,
    grade_name      VARCHAR(100) NOT NULL,
    level_num       SMALLINT NOT NULL,
    min_salary      DECIMAL(12,2) NOT NULL,
    mid_salary      DECIMAL(12,2),
    max_salary      DECIMAL(12,2) NOT NULL,
    is_active       BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (grade_id)
);

CREATE OR REPLACE TABLE hr.employees (
    employee_id     BIGINT NOT NULL AUTOINCREMENT,
    employee_number VARCHAR(20) NOT NULL UNIQUE,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    middle_name     VARCHAR(100),
    email           VARCHAR(255) NOT NULL UNIQUE,
    phone           VARCHAR(30),
    gender          VARCHAR(10),
    date_of_birth   DATE,
    national_id     VARCHAR(50),
    nationality     CHAR(2),
    department_id   INTEGER,
    job_title       VARCHAR(150),
    grade_id        INTEGER,
    manager_id      BIGINT,
    employment_type VARCHAR(30) DEFAULT 'FULL_TIME',
    hire_date       DATE NOT NULL,
    termination_date DATE,
    status          VARCHAR(20) DEFAULT 'ACTIVE',
    work_location   VARCHAR(100),
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (employee_id),
    FOREIGN KEY (department_id) REFERENCES hr.departments(department_id),
    FOREIGN KEY (grade_id) REFERENCES hr.job_grades(grade_id)
);

CREATE OR REPLACE TABLE hr.salaries (
    salary_id       BIGINT NOT NULL AUTOINCREMENT,
    employee_id     BIGINT NOT NULL,
    effective_date  DATE NOT NULL,
    end_date        DATE,
    base_salary     DECIMAL(14,2) NOT NULL,
    currency        CHAR(3) DEFAULT 'USD',
    pay_frequency   VARCHAR(20) DEFAULT 'MONTHLY',
    change_reason   VARCHAR(100),
    approved_by     BIGINT,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (salary_id),
    FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id)
);

CREATE OR REPLACE TABLE hr.leave_requests (
    leave_id        BIGINT NOT NULL AUTOINCREMENT,
    employee_id     BIGINT NOT NULL,
    leave_type      VARCHAR(50) NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    days_requested  DECIMAL(4,1) NOT NULL,
    reason          TEXT,
    status          VARCHAR(20) DEFAULT 'PENDING',
    approved_by     BIGINT,
    approved_at     TIMESTAMP_NTZ,
    comments        TEXT,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (leave_id),
    FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id)
);

CREATE OR REPLACE TABLE hr.performance_reviews (
    review_id       BIGINT NOT NULL AUTOINCREMENT,
    employee_id     BIGINT NOT NULL,
    reviewer_id     BIGINT NOT NULL,
    review_period   VARCHAR(20) NOT NULL,
    review_type     VARCHAR(30) NOT NULL,
    overall_rating  DECIMAL(3,1),
    goals_score     DECIMAL(3,1),
    competency_score DECIMAL(3,1),
    feedback        TEXT,
    dev_plan        TEXT,
    status          VARCHAR(20) DEFAULT 'DRAFT',
    submitted_at    TIMESTAMP_NTZ,
    acknowledged_at TIMESTAMP_NTZ,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (review_id),
    FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id)
);

CREATE OR REPLACE TABLE hr.training_records (
    training_id     BIGINT NOT NULL AUTOINCREMENT,
    employee_id     BIGINT NOT NULL,
    course_name     VARCHAR(255) NOT NULL,
    provider        VARCHAR(200),
    training_type   VARCHAR(50),
    start_date      DATE,
    end_date        DATE,
    hours           DECIMAL(6,2),
    cost            DECIMAL(10,2),
    currency        CHAR(3) DEFAULT 'USD',
    status          VARCHAR(20) DEFAULT 'ENROLLED',
    score           DECIMAL(5,2),
    certificate_url VARCHAR(500),
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (training_id),
    FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id)
);
