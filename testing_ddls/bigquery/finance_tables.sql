-- BigQuery: Finance Domain Tables

CREATE OR REPLACE TABLE `analytics.finance.transactions` (
    transaction_id  STRING NOT NULL,
    account_id      INT64 NOT NULL,
    transaction_type STRING NOT NULL,
    amount          NUMERIC NOT NULL,
    currency        STRING NOT NULL DEFAULT 'USD',
    fx_rate         FLOAT64 DEFAULT 1.0,
    amount_usd      NUMERIC,
    category        STRING,
    sub_category    STRING,
    description     STRING,
    merchant        STRUCT<
        name        STRING,
        category    STRING,
        country     STRING,
        mcc_code    STRING
    >,
    reference_id    STRING,
    status          STRING DEFAULT 'COMPLETED',
    transaction_at  TIMESTAMP NOT NULL,
    transaction_date DATE NOT NULL
)
PARTITION BY transaction_date
CLUSTER BY account_id, transaction_type;

CREATE OR REPLACE TABLE `analytics.finance.gl_entries` (
    entry_id        INT64 NOT NULL,
    entry_number    STRING NOT NULL,
    entry_date      DATE NOT NULL,
    period          STRING NOT NULL,
    fiscal_year     INT64 NOT NULL,
    account_code    STRING NOT NULL,
    account_name    STRING,
    cost_center     STRING,
    debit_amount    NUMERIC DEFAULT 0,
    credit_amount   NUMERIC DEFAULT 0,
    currency        STRING DEFAULT 'USD',
    fx_rate         FLOAT64 DEFAULT 1.0,
    base_amount     NUMERIC,
    description     STRING,
    reference_doc   STRING,
    posted_at       TIMESTAMP,
    created_at      TIMESTAMP
)
PARTITION BY entry_date
CLUSTER BY account_code, period;

CREATE OR REPLACE TABLE `analytics.finance.budget_vs_actual` (
    bva_id          INT64 NOT NULL,
    fiscal_year     INT64 NOT NULL,
    period_month    INT64 NOT NULL,
    cost_center     STRING NOT NULL,
    account_code    STRING NOT NULL,
    account_name    STRING,
    budget_amount   NUMERIC,
    actual_amount   NUMERIC,
    variance        NUMERIC,
    variance_pct    FLOAT64,
    report_date     DATE NOT NULL
)
PARTITION BY report_date
CLUSTER BY fiscal_year, cost_center;

CREATE OR REPLACE TABLE `analytics.finance.revenue_recognition` (
    recognition_id  INT64 NOT NULL,
    contract_id     INT64 NOT NULL,
    customer_id     INT64,
    revenue_type    STRING NOT NULL,
    total_amount    NUMERIC NOT NULL,
    currency        STRING DEFAULT 'USD',
    recognition_schedule ARRAY<STRUCT<
        period_date DATE,
        amount      NUMERIC,
        recognized  BOOL
    >>,
    performance_obligation STRING,
    start_date      DATE NOT NULL,
    end_date        DATE,
    created_at      TIMESTAMP
);

CREATE OR REPLACE TABLE `analytics.finance.cash_flow` (
    cf_id           INT64 NOT NULL,
    report_date     DATE NOT NULL,
    period          STRING NOT NULL,
    category        STRING NOT NULL,
    sub_category    STRING,
    inflow          NUMERIC DEFAULT 0,
    outflow         NUMERIC DEFAULT 0,
    net_flow        NUMERIC,
    currency        STRING DEFAULT 'USD',
    notes           STRING
)
PARTITION BY report_date;
