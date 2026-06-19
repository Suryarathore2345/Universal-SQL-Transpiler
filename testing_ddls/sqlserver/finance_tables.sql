-- SQL Server: Finance Domain Tables

CREATE TABLE finance.chart_of_accounts (
    account_code    NVARCHAR(20) NOT NULL,
    account_name    NVARCHAR(200) NOT NULL,
    account_type    NVARCHAR(50) NOT NULL,
    account_subtype NVARCHAR(50),
    parent_code     NVARCHAR(20),
    normal_balance  NVARCHAR(10) NOT NULL,
    is_active       BIT NOT NULL DEFAULT 1,
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_chart_of_accounts PRIMARY KEY (account_code)
);

CREATE TABLE finance.cost_centers (
    cost_center_id  INT NOT NULL IDENTITY(1,1),
    code            NVARCHAR(20) NOT NULL,
    name            NVARCHAR(200) NOT NULL,
    department      NVARCHAR(100),
    annual_budget   DECIMAL(16,2),
    is_active       BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_cost_centers PRIMARY KEY (cost_center_id),
    CONSTRAINT UQ_cost_center_code UNIQUE (code)
);

CREATE TABLE finance.journal_entries (
    entry_id        BIGINT NOT NULL IDENTITY(1,1),
    entry_number    NVARCHAR(50) NOT NULL,
    entry_date      DATE NOT NULL,
    period          NVARCHAR(7) NOT NULL,
    fiscal_year     INT NOT NULL,
    description     NVARCHAR(MAX),
    entry_type      NVARCHAR(30) NOT NULL,
    status          NVARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    reference_doc   NVARCHAR(100),
    cost_center_id  INT,
    created_by      NVARCHAR(100),
    posted_at       DATETIME2,
    posted_by       NVARCHAR(100),
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_journal_entries PRIMARY KEY (entry_id),
    CONSTRAINT UQ_entry_number UNIQUE (entry_number)
);

CREATE TABLE finance.journal_lines (
    line_id         BIGINT NOT NULL IDENTITY(1,1),
    entry_id        BIGINT NOT NULL,
    line_number     SMALLINT NOT NULL,
    account_code    NVARCHAR(20) NOT NULL,
    debit_amount    DECIMAL(18,4) NOT NULL DEFAULT 0.0000,
    credit_amount   DECIMAL(18,4) NOT NULL DEFAULT 0.0000,
    currency        CHAR(3) NOT NULL DEFAULT 'USD',
    fx_rate         DECIMAL(12,6) NOT NULL DEFAULT 1.000000,
    base_amount     DECIMAL(18,4),
    memo            NVARCHAR(500),
    CONSTRAINT PK_journal_lines PRIMARY KEY (line_id),
    CONSTRAINT FK_lines_entry FOREIGN KEY (entry_id) REFERENCES finance.journal_entries(entry_id),
    CONSTRAINT FK_lines_account FOREIGN KEY (account_code) REFERENCES finance.chart_of_accounts(account_code)
);

CREATE TABLE finance.budgets (
    budget_id       BIGINT NOT NULL IDENTITY(1,1),
    cost_center_id  INT NOT NULL,
    account_code    NVARCHAR(20) NOT NULL,
    fiscal_year     INT NOT NULL,
    period_month    TINYINT NOT NULL,
    budget_amount   DECIMAL(16,2) NOT NULL,
    revised_amount  DECIMAL(16,2),
    version         INT NOT NULL DEFAULT 1,
    approved_by     NVARCHAR(100),
    approved_at     DATETIME2,
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_budgets PRIMARY KEY (budget_id),
    CONSTRAINT FK_budget_cost_center FOREIGN KEY (cost_center_id) REFERENCES finance.cost_centers(cost_center_id)
);

CREATE TABLE finance.accounts_payable (
    ap_id           BIGINT NOT NULL IDENTITY(1,1),
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
    cost_center_id  INT,
    paid_at         DATETIME2,
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_accounts_payable PRIMARY KEY (ap_id)
);

CREATE TABLE finance.accounts_receivable (
    ar_id           BIGINT NOT NULL IDENTITY(1,1),
    customer_id     BIGINT NOT NULL,
    invoice_number  NVARCHAR(100) NOT NULL,
    invoice_date    DATE NOT NULL,
    due_date        DATE NOT NULL,
    amount          DECIMAL(16,2) NOT NULL,
    tax_amount      DECIMAL(14,2) NOT NULL DEFAULT 0,
    total_amount    DECIMAL(16,2) NOT NULL,
    amount_paid     DECIMAL(16,2) NOT NULL DEFAULT 0,
    currency        CHAR(3) NOT NULL DEFAULT 'USD',
    status          NVARCHAR(20) NOT NULL DEFAULT 'OPEN',
    paid_at         DATETIME2,
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_accounts_receivable PRIMARY KEY (ar_id),
    CONSTRAINT UQ_ar_invoice UNIQUE (invoice_number)
);
