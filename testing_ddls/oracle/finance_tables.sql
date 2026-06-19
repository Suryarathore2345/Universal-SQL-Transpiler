-- Oracle: Finance Domain Tables

CREATE TABLE finance.chart_of_accounts (
    account_code    VARCHAR2(20) NOT NULL,
    account_name    VARCHAR2(200) NOT NULL,
    account_type    VARCHAR2(50) NOT NULL,
    account_subtype VARCHAR2(50),
    parent_code     VARCHAR2(20),
    normal_balance  VARCHAR2(10) NOT NULL,
    is_active       NUMBER(1) DEFAULT 1,
    created_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_coa PRIMARY KEY (account_code)
);

CREATE TABLE finance.cost_centers (
    cost_center_id  NUMBER(10) NOT NULL,
    code            VARCHAR2(20) NOT NULL,
    name            VARCHAR2(200) NOT NULL,
    department      VARCHAR2(100),
    annual_budget   NUMBER(16,2),
    is_active       NUMBER(1) DEFAULT 1,
    CONSTRAINT pk_cost_centers PRIMARY KEY (cost_center_id),
    CONSTRAINT uq_cc_code UNIQUE (code)
);

CREATE TABLE finance.journal_entries (
    entry_id        NUMBER(19) NOT NULL,
    entry_number    VARCHAR2(50) NOT NULL,
    entry_date      DATE NOT NULL,
    period          VARCHAR2(7) NOT NULL,
    fiscal_year     NUMBER(4) NOT NULL,
    description     CLOB,
    entry_type      VARCHAR2(30) NOT NULL,
    status          VARCHAR2(20) DEFAULT 'DRAFT',
    reference_doc   VARCHAR2(100),
    cost_center_id  NUMBER(10),
    created_by      VARCHAR2(100),
    posted_at       TIMESTAMP,
    posted_by       VARCHAR2(100),
    created_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_journal_entries PRIMARY KEY (entry_id),
    CONSTRAINT uq_entry_number UNIQUE (entry_number)
);

CREATE TABLE finance.journal_lines (
    line_id         NUMBER(19) NOT NULL,
    entry_id        NUMBER(19) NOT NULL,
    line_number     NUMBER(5) NOT NULL,
    account_code    VARCHAR2(20) NOT NULL,
    debit_amount    NUMBER(18,4) DEFAULT 0,
    credit_amount   NUMBER(18,4) DEFAULT 0,
    currency        CHAR(3) DEFAULT 'USD',
    fx_rate         NUMBER(12,6) DEFAULT 1,
    base_amount     NUMBER(18,4),
    memo            VARCHAR2(500),
    CONSTRAINT pk_journal_lines PRIMARY KEY (line_id),
    CONSTRAINT fk_jl_entry FOREIGN KEY (entry_id) REFERENCES finance.journal_entries(entry_id),
    CONSTRAINT fk_jl_account FOREIGN KEY (account_code) REFERENCES finance.chart_of_accounts(account_code)
);

CREATE TABLE finance.budgets (
    budget_id       NUMBER(19) NOT NULL,
    cost_center_id  NUMBER(10) NOT NULL,
    account_code    VARCHAR2(20) NOT NULL,
    fiscal_year     NUMBER(4) NOT NULL,
    period_month    NUMBER(2) NOT NULL,
    budget_amount   NUMBER(16,2) NOT NULL,
    revised_amount  NUMBER(16,2),
    version         NUMBER(3) DEFAULT 1,
    approved_by     VARCHAR2(100),
    approved_at     TIMESTAMP,
    created_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_budgets PRIMARY KEY (budget_id),
    CONSTRAINT fk_budget_cc FOREIGN KEY (cost_center_id) REFERENCES finance.cost_centers(cost_center_id)
);

CREATE TABLE finance.vendors (
    vendor_id       NUMBER(10) NOT NULL,
    vendor_code     VARCHAR2(30) NOT NULL,
    vendor_name     VARCHAR2(255) NOT NULL,
    tax_id          VARCHAR2(50),
    payment_terms   VARCHAR2(30) DEFAULT 'NET30',
    currency        CHAR(3) DEFAULT 'USD',
    contact_name    VARCHAR2(200),
    contact_email   VARCHAR2(255),
    is_active       NUMBER(1) DEFAULT 1,
    created_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_vendors PRIMARY KEY (vendor_id),
    CONSTRAINT uq_vendor_code UNIQUE (vendor_code)
);

CREATE TABLE finance.accounts_payable (
    ap_id           NUMBER(19) NOT NULL,
    vendor_id       NUMBER(10) NOT NULL,
    invoice_number  VARCHAR2(100) NOT NULL,
    invoice_date    DATE NOT NULL,
    due_date        DATE NOT NULL,
    amount          NUMBER(16,2) NOT NULL,
    amount_paid     NUMBER(16,2) DEFAULT 0,
    currency        CHAR(3) DEFAULT 'USD',
    status          VARCHAR2(20) DEFAULT 'OPEN',
    account_code    VARCHAR2(20),
    cost_center_id  NUMBER(10),
    paid_at         TIMESTAMP,
    created_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_ap PRIMARY KEY (ap_id),
    CONSTRAINT fk_ap_vendor FOREIGN KEY (vendor_id) REFERENCES finance.vendors(vendor_id)
);
