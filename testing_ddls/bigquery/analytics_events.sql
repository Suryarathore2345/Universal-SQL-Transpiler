-- BigQuery: Web & App Analytics Event Tables

CREATE OR REPLACE TABLE `analytics.events.page_views` (
    event_id        STRING NOT NULL,
    session_id      STRING NOT NULL,
    user_id         INT64,
    anonymous_id    STRING,
    page_url        STRING NOT NULL,
    page_title      STRING,
    referrer        STRING,
    utm_params      STRUCT<
        source      STRING,
        medium      STRING,
        campaign    STRING,
        term        STRING,
        content     STRING
    >,
    device          STRUCT<
        type        STRING,
        brand       STRING,
        browser     STRING,
        os          STRING,
        screen_res  STRING
    >,
    geo             STRUCT<
        country     STRING,
        region      STRING,
        city        STRING,
        timezone    STRING
    >,
    time_on_page_sec INT64,
    scroll_depth_pct FLOAT64,
    occurred_at     TIMESTAMP NOT NULL
)
PARTITION BY DATE(occurred_at)
CLUSTER BY user_id, session_id
OPTIONS (
    partition_expiration_days = 730,
    require_partition_filter = TRUE,
    description = 'Page view events from web tracking'
);

CREATE OR REPLACE TABLE `analytics.events.user_actions` (
    event_id        STRING NOT NULL,
    event_name      STRING NOT NULL,
    event_category  STRING,
    session_id      STRING,
    user_id         INT64,
    anonymous_id    STRING,
    properties      JSON,
    revenue         NUMERIC,
    currency        STRING,
    page_url        STRING,
    occurred_at     TIMESTAMP NOT NULL
)
PARTITION BY DATE(occurred_at)
CLUSTER BY event_name, user_id;

CREATE OR REPLACE TABLE `analytics.events.sessions` (
    session_id      STRING NOT NULL,
    user_id         INT64,
    anonymous_id    STRING NOT NULL,
    channel         STRING,
    utm_source      STRING,
    utm_medium      STRING,
    utm_campaign    STRING,
    landing_page    STRING,
    exit_page       STRING,
    device_type     STRING,
    browser         STRING,
    country_code    STRING,
    city            STRING,
    is_bounce       BOOL DEFAULT FALSE,
    page_count      INT64 DEFAULT 0,
    event_count     INT64 DEFAULT 0,
    duration_sec    INT64 DEFAULT 0,
    converted       BOOL DEFAULT FALSE,
    conversion_value NUMERIC,
    session_start   TIMESTAMP NOT NULL,
    session_end     TIMESTAMP
)
PARTITION BY DATE(session_start)
CLUSTER BY user_id, channel;

CREATE OR REPLACE TABLE `analytics.events.funnel_steps` (
    funnel_id       STRING NOT NULL,
    funnel_name     STRING NOT NULL,
    user_id         INT64,
    session_id      STRING,
    step_number     INT64 NOT NULL,
    step_name       STRING NOT NULL,
    reached_at      TIMESTAMP NOT NULL,
    completed       BOOL DEFAULT FALSE,
    drop_off        BOOL DEFAULT FALSE,
    time_to_next_sec INT64,
    event_date      DATE NOT NULL
)
PARTITION BY event_date
CLUSTER BY funnel_name, user_id;
