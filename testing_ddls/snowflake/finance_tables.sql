-- Snowflake: Finance Domain Tables

CREATE OR REPLACE TABLE finance.chart_of_accounts (
    account_code    VARCHAR(20) NOT NULL,
    account_name    VARCHAR(200) NOT NULL,
    account_type    VARCHAR(50) NOT NULL,
    account_subtype VARCHAR(50),
    parent_code     VARCHAR(20),
    normal_balance  VARCHAR(10) NOT NULL,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (account_code)
);

CREATE OR REPLACE TABLE finance.cost_centers (
    cost_center_id  INTEGER NOT NULL AUTOINCREMENT,
    code            VARCHAR(20) NOT NULL UNIQUE,
    name            VARCHAR(200) NOT NULL,
    department      VARCHAR(100),
    manager_id      BIGINT,
    budget_year     INTEGER,
    annual_budget   DECIMAL(16,2),
    is_active       BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (cost_center_id)
);

CREATE OR REPLACE TABLE finance.journal_entries (
    entry_id        BIGINT NOT NULL AUTOINCREMENT,
    entry_number    VARCHAR(50) NOT NULL UNIQUE,
    entry_date      DATE NOT NULL,
    period          VARCHAR(7) NOT NULL,
    description     TEXT,
    entry_type      VARCHAR(30) NOT NULL,
    status          VARCHAR(20) DEFAULT 'DRAFT',
    reference_doc   VARCHAR(100),
    cost_center_id  INTEGER,
    created_by      VARCHAR(100),
    posted_at       TIMESTAMP_NTZ,
    posted_by       VARCHAR(100),
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (entry_id)
);

CREATE OR REPLACE TABLE finance.journal_lines (
    line_id         BIGINT NOT NULL AUTOINCREMENT,
    entry_id        BIGINT NOT NULL,
    line_number     SMALLINT NOT NULL,
    account_code    VARCHAR(20) NOT NULL,
    debit_amount    DECIMAL(18,4) DEFAULT 0.0000,
    credit_amount   DECIMAL(18,4) DEFAULT 0.0000,
    currency        CHAR(3) DEFAULT 'USD',
    fx_rate         DECIMAL(12,6) DEFAULT 1.000000,
    base_amount     DECIMAL(18,4),
    memo            VARCHAR(500),
    PRIMARY KEY (line_id),
    FOREIGN KEY (entry_id) REFERENCES finance.journal_entries(entry_id),
    FOREIGN KEY (account_code) REFERENCES finance.chart_of_accounts(account_code)
);

CREATE OR REPLACE TABLE finance.budgets (
    budget_id       BIGINT NOT NULL AUTOINCREMENT,
    cost_center_id  INTEGER NOT NULL,
    account_code    VARCHAR(20) NOT NULL,
    fiscal_year     INTEGER NOT NULL,
    period_month    SMALLINT NOT NULL,
    budget_amount   DECIMAL(16,2) NOT NULL,
    revised_amount  DECIMAL(16,2),
    version         INTEGER DEFAULT 1,
    approved_by     VARCHAR(100),
    approved_at     TIMESTAMP_NTZ,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (budget_id)
);

CREATE OR REPLACE TABLE finance.vendors (
    vendor_id       INTEGER NOT NULL AUTOINCREMENT,
    vendor_code     VARCHAR(30) NOT NULL UNIQUE,
    vendor_name     VARCHAR(255) NOT NULL,
    tax_id          VARCHAR(50),
    payment_terms   VARCHAR(30) DEFAULT 'NET30',
    currency        CHAR(3) DEFAULT 'USD',
    bank_account    VARCHAR(100),
    bank_routing    VARCHAR(50),
    contact_name    VARCHAR(200),
    contact_email   VARCHAR(255),
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (vendor_id)
);

CREATE OR REPLACE TABLE finance.accounts_payable (
    ap_id           BIGINT NOT NULL AUTOINCREMENT,
    vendor_id       INTEGER NOT NULL,
    invoice_number  VARCHAR(100) NOT NULL,
    invoice_date    DATE NOT NULL,
    due_date        DATE NOT NULL,
    amount          DECIMAL(16,2) NOT NULL,
    amount_paid     DECIMAL(16,2) DEFAULT 0.00,
    currency        CHAR(3) DEFAULT 'USD',
    status          VARCHAR(20) DEFAULT 'OPEN',
    account_code    VARCHAR(20),
    cost_center_id  INTEGER,
    paid_at         TIMESTAMP_NTZ,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (ap_id),
    FOREIGN KEY (vendor_id) REFERENCES finance.vendors(vendor_id)
);

CREATE OR REPLACE TABLE finance.fx_rates (
    rate_id         BIGINT NOT NULL AUTOINCREMENT,
    from_currency   CHAR(3) NOT NULL,
    to_currency     CHAR(3) NOT NULL,
    rate_date       DATE NOT NULL,
    rate            DECIMAL(16,8) NOT NULL,
    source          VARCHAR(50),
    PRIMARY KEY (rate_id)
);
