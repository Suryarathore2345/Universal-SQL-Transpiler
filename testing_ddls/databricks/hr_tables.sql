-- Databricks: HR Domain Tables (Unity Catalog style)

CREATE OR REPLACE TABLE hr.employees (
    employee_id     BIGINT NOT NULL,
    employee_number STRING NOT NULL,
    first_name      STRING NOT NULL,
    last_name       STRING NOT NULL,
    email           STRING NOT NULL,
    phone           STRING,
    gender          STRING,
    date_of_birth   DATE,
    nationality     STRING,
    department_id   INTEGER,
    department_name STRING,
    job_title       STRING,
    grade_code      STRING,
    manager_id      BIGINT,
    employment_type STRING DEFAULT 'FULL_TIME',
    hire_date       DATE NOT NULL,
    termination_date DATE,
    status          STRING DEFAULT 'ACTIVE',
    work_location   STRING,
    base_salary     DECIMAL(14,2),
    currency        STRING DEFAULT 'USD',
    _updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
TBLPROPERTIES (
    'delta.enableChangeDataFeed' = 'true',
    'domain' = 'hr'
);

CREATE OR REPLACE TABLE hr.payroll_runs (
    payroll_run_id  BIGINT NOT NULL AUTOINCREMENT,
    run_date        DATE NOT NULL,
    pay_period_start DATE NOT NULL,
    pay_period_end  DATE NOT NULL,
    employee_id     BIGINT NOT NULL,
    gross_pay       DECIMAL(14,2) NOT NULL,
    income_tax      DECIMAL(12,2) DEFAULT 0,
    social_security DECIMAL(12,2) DEFAULT 0,
    health_insurance DECIMAL(12,2) DEFAULT 0,
    retirement_401k DECIMAL(12,2) DEFAULT 0,
    other_deductions DECIMAL(12,2) DEFAULT 0,
    net_pay         DECIMAL(14,2) NOT NULL,
    currency        STRING DEFAULT 'USD',
    status          STRING DEFAULT 'PAID',
    paid_at         TIMESTAMP,
    _ingest_ts      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
PARTITIONED BY (run_date)
TBLPROPERTIES ('domain' = 'hr');

CREATE OR REPLACE TABLE hr.org_hierarchy (
    hierarchy_date  DATE NOT NULL,
    employee_id     BIGINT NOT NULL,
    manager_id      BIGINT,
    level_1         STRING,
    level_2         STRING,
    level_3         STRING,
    level_4         STRING,
    level_5         STRING,
    depth           INTEGER,
    is_leaf         BOOLEAN DEFAULT TRUE,
    is_manager      BOOLEAN DEFAULT FALSE,
    direct_reports  INTEGER DEFAULT 0,
    total_reports   INTEGER DEFAULT 0,
    _updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
PARTITIONED BY (hierarchy_date)
TBLPROPERTIES ('domain' = 'hr');

CREATE OR REPLACE TABLE hr.leave_balances (
    balance_id      BIGINT NOT NULL AUTOINCREMENT,
    employee_id     BIGINT NOT NULL,
    leave_type      STRING NOT NULL,
    balance_year    INTEGER NOT NULL,
    accrued         DECIMAL(6,2) DEFAULT 0,
    used            DECIMAL(6,2) DEFAULT 0,
    pending         DECIMAL(6,2) DEFAULT 0,
    available       DECIMAL(6,2) DEFAULT 0,
    carried_forward DECIMAL(6,2) DEFAULT 0,
    _updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
TBLPROPERTIES ('domain' = 'hr');

CREATE OR REPLACE TABLE hr.training_catalog (
    course_id       BIGINT NOT NULL AUTOINCREMENT,
    course_code     STRING NOT NULL,
    course_name     STRING NOT NULL,
    category        STRING,
    delivery_method STRING DEFAULT 'ONLINE',
    duration_hours  DECIMAL(6,2),
    provider        STRING,
    cost_per_seat   DECIMAL(10,2),
    is_mandatory    BOOLEAN DEFAULT FALSE,
    skills          ARRAY<STRING>,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
TBLPROPERTIES ('domain' = 'hr');
