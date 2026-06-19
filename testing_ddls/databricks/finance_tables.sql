-- Databricks: Finance Domain Tables

CREATE OR REPLACE TABLE finance.accounts (
    account_id      BIGINT NOT NULL,
    account_code    STRING NOT NULL,
    account_name    STRING NOT NULL,
    account_type    STRING NOT NULL,
    account_subtype STRING,
    parent_code     STRING,
    currency        STRING DEFAULT 'USD',
    is_active       BOOLEAN DEFAULT TRUE,
    _updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
TBLPROPERTIES ('domain' = 'finance');

CREATE OR REPLACE TABLE finance.journal_entries (
    entry_id        BIGINT NOT NULL,
    entry_number    STRING NOT NULL,
    entry_date      DATE NOT NULL,
    period          STRING NOT NULL,
    fiscal_year     INTEGER NOT NULL,
    description     STRING,
    entry_type      STRING NOT NULL,
    status          STRING DEFAULT 'POSTED',
    reference_doc   STRING,
    cost_center     STRING,
    created_by      STRING,
    posted_at       TIMESTAMP,
    _ingest_ts      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
PARTITIONED BY (entry_date)
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'domain' = 'finance'
);

CREATE OR REPLACE TABLE finance.journal_lines (
    line_id         BIGINT NOT NULL,
    entry_id        BIGINT NOT NULL,
    line_number     INTEGER NOT NULL,
    account_code    STRING NOT NULL,
    debit_amount    DECIMAL(18,4) DEFAULT 0.0000,
    credit_amount   DECIMAL(18,4) DEFAULT 0.0000,
    currency        STRING DEFAULT 'USD',
    fx_rate         DECIMAL(12,6) DEFAULT 1.000000,
    base_amount     DECIMAL(18,4),
    memo            STRING,
    entry_date      DATE
)
USING DELTA
PARTITIONED BY (entry_date)
TBLPROPERTIES ('domain' = 'finance');

CREATE OR REPLACE TABLE finance.budget_lines (
    budget_line_id  BIGINT NOT NULL AUTOINCREMENT,
    fiscal_year     INTEGER NOT NULL,
    period_month    INTEGER NOT NULL,
    cost_center     STRING NOT NULL,
    account_code    STRING NOT NULL,
    budget_amount   DECIMAL(16,2) NOT NULL,
    revised_amount  DECIMAL(16,2),
    version         INTEGER DEFAULT 1,
    scenario        STRING DEFAULT 'BASE',
    _updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
TBLPROPERTIES ('domain' = 'finance');

CREATE OR REPLACE TABLE finance.vendor_invoices (
    invoice_id      BIGINT NOT NULL,
    vendor_id       INTEGER NOT NULL,
    vendor_name     STRING,
    invoice_number  STRING NOT NULL,
    invoice_date    DATE NOT NULL,
    due_date        DATE,
    amount          DECIMAL(16,2) NOT NULL,
    tax_amount      DECIMAL(14,2) DEFAULT 0,
    total_amount    DECIMAL(16,2) NOT NULL,
    currency        STRING DEFAULT 'USD',
    account_code    STRING,
    cost_center     STRING,
    status          STRING DEFAULT 'OPEN',
    paid_at         TIMESTAMP,
    _ingest_ts      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
USING DELTA
PARTITIONED BY (invoice_date)
TBLPROPERTIES ('domain' = 'finance');
