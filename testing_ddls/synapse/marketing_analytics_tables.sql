-- Azure Synapse Analytics: Marketing & Analytics Tables

CREATE TABLE marketing.campaigns (
    campaign_id     BIGINT NOT NULL,
    campaign_name   NVARCHAR(255) NOT NULL,
    campaign_type   NVARCHAR(50) NOT NULL,
    channel         NVARCHAR(50),
    platform        NVARCHAR(50),
    objective       NVARCHAR(100),
    budget          DECIMAL(14,2),
    spent           DECIMAL(14,2) NOT NULL DEFAULT 0,
    status          NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    start_date      DATE,
    end_date        DATE,
    owner           NVARCHAR(100),
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE()
)
WITH (
    DISTRIBUTION = REPLICATE,
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE marketing.ad_performance_daily (
    record_id       BIGINT NOT NULL,
    report_date     DATE NOT NULL,
    campaign_id     BIGINT NOT NULL,
    platform        NVARCHAR(50) NOT NULL,
    ad_group_name   NVARCHAR(255),
    ad_name         NVARCHAR(255),
    country_code    CHAR(2),
    device_type     NVARCHAR(20),
    impressions     BIGINT NOT NULL DEFAULT 0,
    clicks          BIGINT NOT NULL DEFAULT 0,
    conversions     INT NOT NULL DEFAULT 0,
    spend_usd       DECIMAL(14,2) NOT NULL DEFAULT 0,
    revenue_usd     DECIMAL(14,2) NOT NULL DEFAULT 0,
    cpm             DECIMAL(10,4),
    cpc             DECIMAL(10,4),
    ctr             DECIMAL(8,6),
    cvr             DECIMAL(8,6),
    roas            DECIMAL(10,4)
)
WITH (
    DISTRIBUTION = HASH(campaign_id),
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE analytics.web_sessions (
    session_id      NVARCHAR(100) NOT NULL,
    user_id         BIGINT,
    session_date    DATE NOT NULL,
    channel         NVARCHAR(50),
    utm_source      NVARCHAR(100),
    utm_medium      NVARCHAR(100),
    utm_campaign    NVARCHAR(100),
    landing_page    NVARCHAR(500),
    device_type     NVARCHAR(30),
    browser         NVARCHAR(50),
    country_code    CHAR(2),
    pages_viewed    INT NOT NULL DEFAULT 0,
    duration_sec    INT NOT NULL DEFAULT 0,
    is_bounce       BIT NOT NULL DEFAULT 0,
    converted       BIT NOT NULL DEFAULT 0,
    conversion_value DECIMAL(12,2),
    session_start   DATETIME2 NOT NULL
)
WITH (
    DISTRIBUTION = HASH(user_id),
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE analytics.funnel_events (
    event_id        BIGINT NOT NULL,
    funnel_name     NVARCHAR(100) NOT NULL,
    user_id         BIGINT,
    session_id      NVARCHAR(100),
    step_number     INT NOT NULL,
    step_name       NVARCHAR(100) NOT NULL,
    completed       BIT NOT NULL DEFAULT 0,
    occurred_at     DATETIME2 NOT NULL,
    event_date      DATE NOT NULL
)
WITH (
    DISTRIBUTION = HASH(user_id),
    CLUSTERED COLUMNSTORE INDEX
);

CREATE TABLE analytics.customer_segments (
    segment_id      BIGINT NOT NULL,
    customer_id     BIGINT NOT NULL,
    segment_name    NVARCHAR(100) NOT NULL,
    segment_group   NVARCHAR(50),
    rfm_score       DECIMAL(5,2),
    churn_risk      DECIMAL(5,4),
    clv_predicted   DECIMAL(12,2),
    assigned_at     DATE NOT NULL,
    expires_at      DATE,
    is_current      BIT NOT NULL DEFAULT 1,
    loaded_at       DATETIME2 NOT NULL DEFAULT GETDATE()
)
WITH (
    DISTRIBUTION = HASH(customer_id),
    CLUSTERED COLUMNSTORE INDEX
);
