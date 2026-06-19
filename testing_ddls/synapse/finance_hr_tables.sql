-- Azure Synapse Analytics: Finance and HR Tables

CREATE TABLE finance.journal_entries (
    entry_id        BIGINT NOT NULL,
    entry_number    NVARCHAR(50) NOT NULL,
    entry_date      DATE NOT NULL,
    period          NVARCHAR(7) NOT NULL,
    fiscal_year     INT NOT NULL,
    description     NVARCHAR(2000),
    entry_type      NVARCHAR(30) NOT NULL,
    status          NVARCHAR(20) NOT NULL DEFAULT 'POSTED',
    cost_center     NVARCHAR(20),
    created_by      NVARCHAR(100),
    posted_at       DATETIME2
)
WITH (
    DISTRIBUTION = HASH(entry_id),
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE finance.journal_lines (
    line_id         BIGINT NOT NULL,
    entry_id        BIGINT NOT NULL,
    line_number     SMALLINT NOT NULL,
    account_code    NVARCHAR(20) NOT NULL,
    debit_amount    DECIMAL(18,4) NOT NULL DEFAULT 0.0000,
    credit_amount   DECIMAL(18,4) NOT NULL DEFAULT 0.0000,
    currency        CHAR(3) NOT NULL DEFAULT 'USD',
    fx_rate         DECIMAL(12,6) NOT NULL DEFAULT 1.000000,
    base_amount     DECIMAL(18,4),
    memo            NVARCHAR(500)
)
WITH (
    DISTRIBUTION = HASH(entry_id),
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE finance.budget_actuals (
    ba_id           BIGINT NOT NULL,
    fiscal_year     INT NOT NULL,
    period_month    TINYINT NOT NULL,
    cost_center     NVARCHAR(20) NOT NULL,
    account_code    NVARCHAR(20) NOT NULL,
    budget_amount   DECIMAL(16,2) NOT NULL DEFAULT 0,
    actual_amount   DECIMAL(16,2) NOT NULL DEFAULT 0,
    variance        DECIMAL(16,2),
    variance_pct    DECIMAL(8,4),
    loaded_at       DATETIME2 NOT NULL DEFAULT GETDATE()
)
WITH (
    DISTRIBUTION = HASH(cost_center),
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE hr.employees (
    employee_id     BIGINT NOT NULL,
    employee_number NVARCHAR(20) NOT NULL,
    full_name       NVARCHAR(200) NOT NULL,
    email           NVARCHAR(255) NOT NULL,
    department      NVARCHAR(100),
    job_title       NVARCHAR(150),
    grade_code      NVARCHAR(10),
    manager_id      BIGINT,
    hire_date       DATE NOT NULL,
    termination_date DATE,
    status          NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    location        NVARCHAR(100),
    base_salary     DECIMAL(14,2),
    currency        CHAR(3) DEFAULT 'USD',
    updated_at      DATETIME2 NOT NULL DEFAULT GETDATE()
)
WITH (
    DISTRIBUTION = REPLICATE,
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE hr.payroll_summary (
    payroll_id      BIGINT NOT NULL,
    employee_id     BIGINT NOT NULL,
    pay_period_start DATE NOT NULL,
    pay_period_end  DATE NOT NULL,
    gross_pay       DECIMAL(14,2) NOT NULL,
    total_deductions DECIMAL(12,2) NOT NULL DEFAULT 0,
    net_pay         DECIMAL(14,2) NOT NULL,
    currency        CHAR(3) NOT NULL DEFAULT 'USD',
    status          NVARCHAR(20) NOT NULL DEFAULT 'PROCESSED',
    paid_at         DATETIME2
)
WITH (
    DISTRIBUTION = HASH(employee_id),
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE hr.headcount_monthly (
    snapshot_month  DATE NOT NULL,
    department      NVARCHAR(100) NOT NULL,
    location        NVARCHAR(100),
    employment_type NVARCHAR(30),
    headcount       INT NOT NULL DEFAULT 0,
    new_hires       INT NOT NULL DEFAULT 0,
    terminations    INT NOT NULL DEFAULT 0,
    total_salary    DECIMAL(16,2),
    avg_salary      DECIMAL(14,2)
)
WITH (
    DISTRIBUTION = HASH(department),
    CLUSTERED COLUMNSTORE INDEX
);
