-- SQL Server: Marketing Domain Tables

CREATE TABLE marketing.campaigns (
    campaign_id     BIGINT NOT NULL IDENTITY(1,1),
    campaign_name   NVARCHAR(255) NOT NULL,
    campaign_type   NVARCHAR(50) NOT NULL,
    channel         NVARCHAR(50),
    objective       NVARCHAR(100),
    status          NVARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    start_date      DATE,
    end_date        DATE,
    budget          DECIMAL(14,2),
    spent           DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    owner           NVARCHAR(100),
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_campaigns PRIMARY KEY (campaign_id)
);

CREATE TABLE marketing.leads (
    lead_id         BIGINT NOT NULL IDENTITY(1,1),
    email           NVARCHAR(255) NOT NULL,
    first_name      NVARCHAR(100),
    last_name       NVARCHAR(100),
    company         NVARCHAR(200),
    job_title       NVARCHAR(150),
    phone           NVARCHAR(30),
    country_code    CHAR(2),
    source          NVARCHAR(100),
    campaign_id     BIGINT,
    lead_score      INT NOT NULL DEFAULT 0,
    status          NVARCHAR(30) NOT NULL DEFAULT 'NEW',
    assigned_to     NVARCHAR(100),
    converted_at    DATETIME2,
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_leads PRIMARY KEY (lead_id),
    CONSTRAINT FK_leads_campaign FOREIGN KEY (campaign_id) REFERENCES marketing.campaigns(campaign_id)
);

CREATE TABLE marketing.email_campaigns (
    email_campaign_id BIGINT NOT NULL IDENTITY(1,1),
    campaign_id     BIGINT,
    subject_line    NVARCHAR(500) NOT NULL,
    preheader       NVARCHAR(300),
    from_name       NVARCHAR(100),
    from_email      NVARCHAR(255),
    recipient_count INT NOT NULL DEFAULT 0,
    sent_at         DATETIME2,
    status          NVARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_email_campaigns PRIMARY KEY (email_campaign_id)
);

CREATE TABLE marketing.email_events (
    event_id        BIGINT NOT NULL IDENTITY(1,1),
    email_campaign_id BIGINT NOT NULL,
    customer_id     BIGINT,
    email           NVARCHAR(255) NOT NULL,
    event_type      NVARCHAR(30) NOT NULL,
    occurred_at     DATETIME2 NOT NULL,
    link_url        NVARCHAR(1000),
    CONSTRAINT PK_email_events PRIMARY KEY (event_id),
    CONSTRAINT FK_email_events_campaign FOREIGN KEY (email_campaign_id) REFERENCES marketing.email_campaigns(email_campaign_id)
);

CREATE TABLE marketing.ad_performance (
    perf_id         BIGINT NOT NULL IDENTITY(1,1),
    campaign_id     BIGINT NOT NULL,
    report_date     DATE NOT NULL,
    platform        NVARCHAR(50) NOT NULL,
    ad_name         NVARCHAR(255),
    impressions     BIGINT NOT NULL DEFAULT 0,
    clicks          BIGINT NOT NULL DEFAULT 0,
    conversions     INT NOT NULL DEFAULT 0,
    spend           DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    revenue         DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    cpm             DECIMAL(10,4),
    cpc             DECIMAL(10,4),
    ctr             DECIMAL(8,6),
    roas            DECIMAL(10,4),
    CONSTRAINT PK_ad_performance PRIMARY KEY (perf_id)
);
