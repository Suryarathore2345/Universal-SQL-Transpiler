-- Snowflake: SaaS Metrics Domain Tables

CREATE OR REPLACE TABLE saas.accounts (
    account_id      BIGINT NOT NULL AUTOINCREMENT,
    account_name    VARCHAR(255) NOT NULL,
    account_slug    VARCHAR(100) NOT NULL UNIQUE,
    plan_id         INTEGER,
    plan_name       VARCHAR(50),
    billing_email   VARCHAR(255),
    company_size    VARCHAR(30),
    industry        VARCHAR(100),
    mrr             DECIMAL(12,2) DEFAULT 0.00,
    arr             DECIMAL(14,2) DEFAULT 0.00,
    trial_starts_at TIMESTAMP_NTZ,
    trial_ends_at   TIMESTAMP_NTZ,
    converted_at    TIMESTAMP_NTZ,
    churned_at      TIMESTAMP_NTZ,
    status          VARCHAR(20) DEFAULT 'TRIAL',
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (account_id)
);

CREATE OR REPLACE TABLE saas.users (
    user_id         BIGINT NOT NULL AUTOINCREMENT,
    account_id      BIGINT NOT NULL,
    email           VARCHAR(255) NOT NULL,
    display_name    VARCHAR(200),
    role            VARCHAR(50) DEFAULT 'MEMBER',
    is_owner        BOOLEAN DEFAULT FALSE,
    last_login_at   TIMESTAMP_NTZ,
    login_count     INTEGER DEFAULT 0,
    invited_at      TIMESTAMP_NTZ,
    activated_at    TIMESTAMP_NTZ,
    deactivated_at  TIMESTAMP_NTZ,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (user_id),
    FOREIGN KEY (account_id) REFERENCES saas.accounts(account_id)
);

CREATE OR REPLACE TABLE saas.plans (
    plan_id         INTEGER NOT NULL AUTOINCREMENT,
    plan_name       VARCHAR(50) NOT NULL,
    billing_cycle   VARCHAR(20) DEFAULT 'MONTHLY',
    monthly_price   DECIMAL(10,2) NOT NULL,
    annual_price    DECIMAL(10,2),
    max_users       INTEGER,
    max_projects    INTEGER,
    max_storage_gb  INTEGER,
    features        VARIANT,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (plan_id)
);

CREATE OR REPLACE TABLE saas.subscriptions (
    subscription_id BIGINT NOT NULL AUTOINCREMENT,
    account_id      BIGINT NOT NULL,
    plan_id         INTEGER NOT NULL,
    status          VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    billing_cycle   VARCHAR(20) NOT NULL,
    amount          DECIMAL(12,2) NOT NULL,
    currency        CHAR(3) DEFAULT 'USD',
    current_period_start    TIMESTAMP_NTZ NOT NULL,
    current_period_end      TIMESTAMP_NTZ NOT NULL,
    cancel_at_period_end    BOOLEAN DEFAULT FALSE,
    cancelled_at    TIMESTAMP_NTZ,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (subscription_id),
    FOREIGN KEY (account_id) REFERENCES saas.accounts(account_id),
    FOREIGN KEY (plan_id) REFERENCES saas.plans(plan_id)
);

CREATE OR REPLACE TABLE saas.invoices (
    invoice_id      BIGINT NOT NULL AUTOINCREMENT,
    account_id      BIGINT NOT NULL,
    subscription_id BIGINT,
    invoice_number  VARCHAR(50) NOT NULL UNIQUE,
    status          VARCHAR(20) DEFAULT 'OPEN',
    amount_due      DECIMAL(12,2) NOT NULL,
    amount_paid     DECIMAL(12,2) DEFAULT 0.00,
    currency        CHAR(3) DEFAULT 'USD',
    due_date        DATE,
    paid_at         TIMESTAMP_NTZ,
    period_start    DATE,
    period_end      DATE,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (invoice_id),
    FOREIGN KEY (account_id) REFERENCES saas.accounts(account_id)
);

CREATE OR REPLACE TABLE saas.events (
    event_id        VARCHAR(36) NOT NULL DEFAULT UUID_STRING(),
    account_id      BIGINT NOT NULL,
    user_id         BIGINT,
    session_id      VARCHAR(100),
    event_name      VARCHAR(200) NOT NULL,
    event_category  VARCHAR(100),
    page_url        VARCHAR(1000),
    referrer        VARCHAR(1000),
    properties      VARIANT,
    ip_address      VARCHAR(45),
    user_agent      TEXT,
    occurred_at     TIMESTAMP_NTZ NOT NULL,
    ingested_at     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (event_id)
);

CREATE OR REPLACE TABLE saas.feature_usage (
    usage_id        BIGINT NOT NULL AUTOINCREMENT,
    account_id      BIGINT NOT NULL,
    user_id         BIGINT,
    feature_key     VARCHAR(100) NOT NULL,
    usage_date      DATE NOT NULL,
    usage_count     INTEGER DEFAULT 0,
    duration_sec    INTEGER DEFAULT 0,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (usage_id)
);

CREATE OR REPLACE TABLE saas.support_tickets (
    ticket_id       BIGINT NOT NULL AUTOINCREMENT,
    account_id      BIGINT NOT NULL,
    user_id         BIGINT,
    subject         VARCHAR(500) NOT NULL,
    description     TEXT,
    priority        VARCHAR(20) DEFAULT 'NORMAL',
    status          VARCHAR(30) DEFAULT 'OPEN',
    category        VARCHAR(100),
    assigned_to     VARCHAR(100),
    first_response_at   TIMESTAMP_NTZ,
    resolved_at         TIMESTAMP_NTZ,
    csat_score          SMALLINT,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (ticket_id)
);
