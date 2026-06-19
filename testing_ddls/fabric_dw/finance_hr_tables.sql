-- Microsoft Fabric Data Warehouse: Finance and HR Tables

CREATE TABLE finance.general_ledger (
    gl_id           BIGINT NOT NULL,
    entry_date      DATE NOT NULL,
    period          NVARCHAR(7) NOT NULL,
    fiscal_year     INT NOT NULL,
    account_code    NVARCHAR(20) NOT NULL,
    account_name    NVARCHAR(200),
    cost_center     NVARCHAR(20),
    debit_amount    DECIMAL(18,4) NOT NULL DEFAULT 0.0000,
    credit_amount   DECIMAL(18,4) NOT NULL DEFAULT 0.0000,
    currency        CHAR(3) NOT NULL DEFAULT 'USD',
    fx_rate         DECIMAL(12,6) NOT NULL DEFAULT 1.000000,
    base_amount     DECIMAL(18,4),
    description     NVARCHAR(500),
    reference_doc   NVARCHAR(100),
    posted_at       DATETIME2,
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE()
);

CREATE TABLE finance.budget_vs_actual (
    bva_id          BIGINT NOT NULL,
    fiscal_year     INT NOT NULL,
    period_month    TINYINT NOT NULL,
    cost_center     NVARCHAR(20) NOT NULL,
    account_code    NVARCHAR(20) NOT NULL,
    account_name    NVARCHAR(200),
    budget_amount   DECIMAL(16,2) NOT NULL DEFAULT 0,
    actual_amount   DECIMAL(16,2) NOT NULL DEFAULT 0,
    variance        DECIMAL(16,2),
    variance_pct    DECIMAL(8,4),
    loaded_at       DATETIME2 NOT NULL DEFAULT GETDATE()
);

CREATE TABLE finance.vendor_invoices (
    invoice_id      BIGINT NOT NULL,
    vendor_name     NVARCHAR(255) NOT NULL,
    invoice_number  NVARCHAR(100) NOT NULL,
    invoice_date    DATE NOT NULL,
    due_date        DATE NOT NULL,
    amount          DECIMAL(16,2) NOT NULL,
    tax_amount      DECIMAL(14,2) NOT NULL DEFAULT 0,
    total_amount    DECIMAL(16,2) NOT NULL,
    currency        CHAR(3) NOT NULL DEFAULT 'USD',
    status          NVARCHAR(20) NOT NULL DEFAULT 'OPEN',
    account_code    NVARCHAR(20),
    cost_center     NVARCHAR(20),
    paid_at         DATETIME2,
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE()
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
);

CREATE TABLE hr.leave_summary (
    leave_summary_id BIGINT NOT NULL,
    employee_id     BIGINT NOT NULL,
    leave_year      INT NOT NULL,
    leave_type      NVARCHAR(50) NOT NULL,
    entitled_days   DECIMAL(5,1) NOT NULL DEFAULT 0,
    used_days       DECIMAL(5,1) NOT NULL DEFAULT 0,
    pending_days    DECIMAL(5,1) NOT NULL DEFAULT 0,
    available_days  DECIMAL(5,1) NOT NULL DEFAULT 0,
    updated_at      DATETIME2 NOT NULL DEFAULT GETDATE()
);

CREATE TABLE hr.recruitment_pipeline (
    req_id          BIGINT NOT NULL,
    job_title       NVARCHAR(150) NOT NULL,
    department      NVARCHAR(100),
    location        NVARCHAR(100),
    hiring_manager  NVARCHAR(200),
    status          NVARCHAR(30) NOT NULL DEFAULT 'OPEN',
    applicants      INT NOT NULL DEFAULT 0,
    interviewed     INT NOT NULL DEFAULT 0,
    offered         INT NOT NULL DEFAULT 0,
    hired           INT NOT NULL DEFAULT 0,
    opened_at       DATE NOT NULL,
    closed_at       DATE,
    time_to_fill_days INT
);
