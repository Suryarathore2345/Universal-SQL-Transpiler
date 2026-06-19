-- Snowflake: Data Warehouse Dimension Tables

CREATE OR REPLACE TABLE dwh.dim_date (
    date_key        INTEGER NOT NULL,
    full_date       DATE NOT NULL,
    day_of_week     SMALLINT NOT NULL,
    day_name        VARCHAR(10) NOT NULL,
    day_of_month    SMALLINT NOT NULL,
    day_of_year     SMALLINT NOT NULL,
    week_of_year    SMALLINT NOT NULL,
    week_start_date DATE NOT NULL,
    month_num       SMALLINT NOT NULL,
    month_name      VARCHAR(10) NOT NULL,
    quarter_num     SMALLINT NOT NULL,
    quarter_name    VARCHAR(6) NOT NULL,
    year_num        SMALLINT NOT NULL,
    fiscal_quarter  SMALLINT NOT NULL,
    fiscal_year     SMALLINT NOT NULL,
    is_weekend      BOOLEAN NOT NULL,
    is_holiday      BOOLEAN DEFAULT FALSE,
    holiday_name    VARCHAR(100),
    PRIMARY KEY (date_key)
);

CREATE OR REPLACE TABLE dwh.dim_time (
    time_key        INTEGER NOT NULL,
    full_time       TIME NOT NULL,
    hour_24         SMALLINT NOT NULL,
    hour_12         SMALLINT NOT NULL,
    am_pm           CHAR(2) NOT NULL,
    minute_of_hour  SMALLINT NOT NULL,
    second_of_minute SMALLINT NOT NULL,
    minute_of_day   SMALLINT NOT NULL,
    shift           VARCHAR(20),
    PRIMARY KEY (time_key)
);

CREATE OR REPLACE TABLE dwh.dim_customer (
    customer_key    BIGINT NOT NULL AUTOINCREMENT,
    customer_id     BIGINT NOT NULL,
    email           VARCHAR(255),
    full_name       VARCHAR(200),
    city            VARCHAR(100),
    state           VARCHAR(100),
    country_code    CHAR(2),
    loyalty_tier    VARCHAR(20),
    customer_segment VARCHAR(50),
    age_band        VARCHAR(20),
    effective_from  DATE NOT NULL,
    effective_to    DATE,
    is_current      BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (customer_key)
);

CREATE OR REPLACE TABLE dwh.dim_product (
    product_key     BIGINT NOT NULL AUTOINCREMENT,
    product_id      BIGINT NOT NULL,
    sku             VARCHAR(100),
    product_name    VARCHAR(255),
    brand           VARCHAR(100),
    category_l1     VARCHAR(150),
    category_l2     VARCHAR(150),
    category_l3     VARCHAR(150),
    unit_price      DECIMAL(12,2),
    cost_price      DECIMAL(12,2),
    is_digital      BOOLEAN,
    effective_from  DATE NOT NULL,
    effective_to    DATE,
    is_current      BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (product_key)
);

CREATE OR REPLACE TABLE dwh.dim_geography (
    geo_key         INTEGER NOT NULL AUTOINCREMENT,
    country_code    CHAR(2) NOT NULL,
    country_name    VARCHAR(100) NOT NULL,
    region          VARCHAR(100),
    sub_region      VARCHAR(100),
    state_province  VARCHAR(100),
    city            VARCHAR(100),
    postal_code     VARCHAR(20),
    timezone        VARCHAR(60),
    latitude        DECIMAL(10,7),
    longitude       DECIMAL(10,7),
    PRIMARY KEY (geo_key)
);

CREATE OR REPLACE TABLE dwh.dim_channel (
    channel_key     INTEGER NOT NULL AUTOINCREMENT,
    channel_code    VARCHAR(30) NOT NULL UNIQUE,
    channel_name    VARCHAR(100) NOT NULL,
    channel_group   VARCHAR(50),
    is_online       BOOLEAN DEFAULT TRUE,
    is_paid         BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (channel_key)
);

CREATE OR REPLACE TABLE dwh.dim_currency (
    currency_key    SMALLINT NOT NULL AUTOINCREMENT,
    currency_code   CHAR(3) NOT NULL UNIQUE,
    currency_name   VARCHAR(100) NOT NULL,
    symbol          VARCHAR(5),
    decimal_places  SMALLINT DEFAULT 2,
    PRIMARY KEY (currency_key)
);
