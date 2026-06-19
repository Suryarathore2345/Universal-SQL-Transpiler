-- Snowflake: Marketing Domain Tables

CREATE OR REPLACE TABLE marketing.campaigns (
    campaign_id     BIGINT NOT NULL AUTOINCREMENT,
    campaign_name   VARCHAR(255) NOT NULL,
    campaign_type   VARCHAR(50) NOT NULL,
    channel         VARCHAR(50),
    objective       VARCHAR(100),
    status          VARCHAR(20) DEFAULT 'DRAFT',
    start_date      DATE,
    end_date        DATE,
    budget          DECIMAL(14,2),
    spent           DECIMAL(14,2) DEFAULT 0.00,
    currency        CHAR(3) DEFAULT 'USD',
    target_audience VARCHAR(200),
    owner           VARCHAR(100),
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (campaign_id)
);

CREATE OR REPLACE TABLE marketing.ad_groups (
    ad_group_id     BIGINT NOT NULL AUTOINCREMENT,
    campaign_id     BIGINT NOT NULL,
    ad_group_name   VARCHAR(255) NOT NULL,
    platform        VARCHAR(50) NOT NULL,
    platform_id     VARCHAR(100),
    daily_budget    DECIMAL(12,2),
    bid_strategy    VARCHAR(50),
    status          VARCHAR(20) DEFAULT 'ACTIVE',
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (ad_group_id),
    FOREIGN KEY (campaign_id) REFERENCES marketing.campaigns(campaign_id)
);

CREATE OR REPLACE TABLE marketing.ad_performance (
    perf_id         BIGINT NOT NULL AUTOINCREMENT,
    ad_group_id     BIGINT NOT NULL,
    campaign_id     BIGINT NOT NULL,
    report_date     DATE NOT NULL,
    platform        VARCHAR(50) NOT NULL,
    impressions     BIGINT DEFAULT 0,
    clicks          BIGINT DEFAULT 0,
    conversions     INTEGER DEFAULT 0,
    spend           DECIMAL(12,2) DEFAULT 0.00,
    revenue         DECIMAL(14,2) DEFAULT 0.00,
    cpm             DECIMAL(10,4),
    cpc             DECIMAL(10,4),
    ctr             DECIMAL(8,6),
    conversion_rate DECIMAL(8,6),
    roas            DECIMAL(10,4),
    PRIMARY KEY (perf_id)
);

CREATE OR REPLACE TABLE marketing.email_campaigns (
    email_campaign_id   BIGINT NOT NULL AUTOINCREMENT,
    campaign_id         BIGINT,
    subject_line        VARCHAR(500) NOT NULL,
    preheader           VARCHAR(300),
    from_name           VARCHAR(100),
    from_email          VARCHAR(255),
    template_id         INTEGER,
    audience_segment    VARCHAR(200),
    recipient_count     INTEGER DEFAULT 0,
    sent_at             TIMESTAMP_NTZ,
    status              VARCHAR(20) DEFAULT 'DRAFT',
    PRIMARY KEY (email_campaign_id)
);

CREATE OR REPLACE TABLE marketing.email_events (
    event_id        BIGINT NOT NULL AUTOINCREMENT,
    email_campaign_id BIGINT NOT NULL,
    customer_id     BIGINT,
    email           VARCHAR(255) NOT NULL,
    event_type      VARCHAR(30) NOT NULL,
    occurred_at     TIMESTAMP_NTZ NOT NULL,
    ip_address      VARCHAR(45),
    user_agent      TEXT,
    link_url        VARCHAR(1000),
    PRIMARY KEY (event_id)
);

CREATE OR REPLACE TABLE marketing.utm_tracking (
    utm_id          BIGINT NOT NULL AUTOINCREMENT,
    session_id      VARCHAR(100) NOT NULL,
    customer_id     BIGINT,
    utm_source      VARCHAR(100),
    utm_medium      VARCHAR(100),
    utm_campaign    VARCHAR(100),
    utm_term        VARCHAR(200),
    utm_content     VARCHAR(200),
    landing_url     VARCHAR(1000),
    referrer        VARCHAR(1000),
    first_seen_at   TIMESTAMP_NTZ NOT NULL,
    PRIMARY KEY (utm_id)
);

CREATE OR REPLACE TABLE marketing.leads (
    lead_id         BIGINT NOT NULL AUTOINCREMENT,
    email           VARCHAR(255) NOT NULL,
    first_name      VARCHAR(100),
    last_name       VARCHAR(100),
    company         VARCHAR(200),
    job_title       VARCHAR(150),
    phone           VARCHAR(30),
    country_code    CHAR(2),
    source          VARCHAR(100),
    campaign_id     BIGINT,
    lead_score      INTEGER DEFAULT 0,
    status          VARCHAR(30) DEFAULT 'NEW',
    assigned_to     VARCHAR(100),
    converted_at    TIMESTAMP_NTZ,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (lead_id)
);
