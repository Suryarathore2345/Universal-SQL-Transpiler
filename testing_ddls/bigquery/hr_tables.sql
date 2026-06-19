-- BigQuery: HR Domain Tables

CREATE OR REPLACE TABLE `analytics.hr.employees` (
    employee_id     INT64 NOT NULL,
    employee_number STRING NOT NULL,
    personal_info   STRUCT<
        first_name  STRING,
        last_name   STRING,
        email       STRING,
        phone       STRING,
        dob         DATE,
        gender      STRING,
        nationality STRING
    >,
    work_info       STRUCT<
        department  STRING,
        job_title   STRING,
        grade       STRING,
        manager_id  INT64,
        location    STRING,
        hire_date   DATE,
        employment_type STRING
    >,
    compensation    STRUCT<
        base_salary NUMERIC,
        currency    STRING,
        bonus_target NUMERIC
    >,
    status          STRING DEFAULT 'ACTIVE',
    termination_date DATE,
    created_at      TIMESTAMP,
    updated_at      TIMESTAMP
);

CREATE OR REPLACE TABLE `analytics.hr.payroll` (
    payroll_id      INT64 NOT NULL,
    employee_id     INT64 NOT NULL,
    pay_period_start DATE NOT NULL,
    pay_period_end   DATE NOT NULL,
    earnings        ARRAY<STRUCT<
        type        STRING,
        description STRING,
        amount      NUMERIC,
        hours       FLOAT64
    >>,
    deductions      ARRAY<STRUCT<
        type        STRING,
        description STRING,
        amount      NUMERIC
    >>,
    gross_pay       NUMERIC NOT NULL,
    total_deductions NUMERIC NOT NULL,
    net_pay         NUMERIC NOT NULL,
    currency        STRING DEFAULT 'USD',
    status          STRING DEFAULT 'PROCESSED',
    paid_at         TIMESTAMP,
    pay_date        DATE NOT NULL
)
PARTITION BY pay_date
CLUSTER BY employee_id;

CREATE OR REPLACE TABLE `analytics.hr.performance_reviews` (
    review_id       INT64 NOT NULL,
    employee_id     INT64 NOT NULL,
    reviewer_id     INT64 NOT NULL,
    review_type     STRING NOT NULL,
    review_period   STRING NOT NULL,
    goal_scores     ARRAY<STRUCT<
        goal_id     INT64,
        goal_desc   STRING,
        target      FLOAT64,
        actual      FLOAT64,
        score       FLOAT64,
        weight      FLOAT64
    >>,
    competency_scores ARRAY<STRUCT<
        competency  STRING,
        score       FLOAT64
    >>,
    overall_rating  FLOAT64,
    feedback        STRING,
    dev_areas       ARRAY<STRING>,
    status          STRING DEFAULT 'DRAFT',
    submitted_at    TIMESTAMP,
    review_date     DATE
)
PARTITION BY review_date;

CREATE OR REPLACE TABLE `analytics.hr.headcount_snapshot` (
    snapshot_id     INT64 NOT NULL,
    snapshot_date   DATE NOT NULL,
    department      STRING NOT NULL,
    job_grade       STRING,
    location        STRING,
    employment_type STRING,
    headcount       INT64 NOT NULL,
    new_hires       INT64 DEFAULT 0,
    terminations    INT64 DEFAULT 0,
    total_payroll   NUMERIC,
    avg_tenure_days FLOAT64
)
PARTITION BY snapshot_date
CLUSTER BY department;
