-- BigQuery: Marketing Attribution and Campaign Tables

CREATE OR REPLACE TABLE `analytics.marketing.campaigns` (
    campaign_id     INT64 NOT NULL,
    campaign_name   STRING NOT NULL,
    campaign_type   STRING NOT NULL,
    channel         STRING,
    platform        STRING,
    objective       STRING,
    budget_usd      NUMERIC,
    status          STRING DEFAULT 'DRAFT',
    start_date      DATE,
    end_date        DATE,
    target_audience STRUCT<
        age_min     INT64,
        age_max     INT64,
        genders     ARRAY<STRING>,
        countries   ARRAY<STRING>,
        interests   ARRAY<STRING>
    >,
    created_at      TIMESTAMP
);

CREATE OR REPLACE TABLE `analytics.marketing.ad_performance` (
    record_id       INT64 NOT NULL,
    campaign_id     INT64 NOT NULL,
    report_date     DATE NOT NULL,
    platform        STRING NOT NULL,
    ad_id           STRING,
    ad_name         STRING,
    placement       STRING,
    impressions     INT64 DEFAULT 0,
    reach           INT64 DEFAULT 0,
    clicks          INT64 DEFAULT 0,
    conversions     INT64 DEFAULT 0,
    video_views     INT64 DEFAULT 0,
    spend_usd       NUMERIC DEFAULT 0,
    revenue_usd     NUMERIC DEFAULT 0,
    cpm             FLOAT64,
    cpc             FLOAT64,
    ctr             FLOAT64,
    cvr             FLOAT64,
    roas            FLOAT64
)
PARTITION BY report_date
CLUSTER BY campaign_id, platform;

CREATE OR REPLACE TABLE `analytics.marketing.attribution` (
    conversion_id   STRING NOT NULL,
    user_id         INT64,
    anonymous_id    STRING,
    conversion_type STRING NOT NULL,
    conversion_value NUMERIC,
    currency        STRING DEFAULT 'USD',
    touchpoints     ARRAY<STRUCT<
        channel     STRING,
        campaign    STRING,
        medium      STRING,
        source      STRING,
        touched_at  TIMESTAMP,
        position    STRING
    >>,
    first_touch     STRUCT<
        channel     STRING,
        campaign    STRING,
        touched_at  TIMESTAMP
    >,
    last_touch      STRUCT<
        channel     STRING,
        campaign    STRING,
        touched_at  TIMESTAMP
    >,
    converted_at    TIMESTAMP NOT NULL,
    conversion_date DATE NOT NULL
)
PARTITION BY conversion_date
CLUSTER BY user_id, conversion_type;

CREATE OR REPLACE TABLE `analytics.marketing.email_metrics` (
    metric_id       INT64 NOT NULL,
    campaign_id     INT64 NOT NULL,
    send_date       DATE NOT NULL,
    recipient_email STRING,
    user_id         INT64,
    sent            BOOL DEFAULT FALSE,
    delivered       BOOL DEFAULT FALSE,
    opened          BOOL DEFAULT FALSE,
    clicked         BOOL DEFAULT FALSE,
    unsubscribed    BOOL DEFAULT FALSE,
    bounced         BOOL DEFAULT FALSE,
    open_count      INT64 DEFAULT 0,
    click_count     INT64 DEFAULT 0,
    first_opened_at TIMESTAMP,
    last_opened_at  TIMESTAMP
)
PARTITION BY send_date
CLUSTER BY campaign_id;

CREATE OR REPLACE TABLE `analytics.marketing.seo_rankings` (
    ranking_id      INT64 NOT NULL,
    keyword         STRING NOT NULL,
    url             STRING NOT NULL,
    position        INT64,
    impressions     INT64 DEFAULT 0,
    clicks          INT64 DEFAULT 0,
    ctr             FLOAT64,
    search_volume   INT64,
    difficulty      FLOAT64,
    country_code    STRING DEFAULT 'US',
    device          STRING DEFAULT 'DESKTOP',
    report_date     DATE NOT NULL
)
PARTITION BY report_date
CLUSTER BY keyword;
