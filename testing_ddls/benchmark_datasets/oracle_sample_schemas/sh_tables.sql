-- ============================================================================
-- Oracle SH (Sales History) Schema - Tables, Views, Materialized Views
-- Source: oracle-samples/db-sample-schemas (MIT License)
-- Schema Version: 21 | Release: 06-DEC-2022 | Requires: Oracle 19c+
-- Star schema data warehouse design with partitioned fact tables
-- ============================================================================

-- ============================================================================
-- DIMENSION TABLES
-- ============================================================================

CREATE TABLE countries
(
   country_id             NUMBER         NOT NULL,
   country_iso_code       CHAR(2)        NOT NULL,
   country_name           VARCHAR2(40)   NOT NULL,
   country_subregion      VARCHAR2(30)   NOT NULL,
   country_subregion_id   NUMBER         NOT NULL,
   country_region         VARCHAR2(20)   NOT NULL,
   country_region_id      NUMBER         NOT NULL,
   country_total          VARCHAR2(11)   NOT NULL,
   country_total_id       NUMBER         NOT NULL,
   CONSTRAINT countries_pk
      PRIMARY KEY (country_id)
);

-- ----------------------------------------------------------------------------

CREATE TABLE customers
(
   cust_id                  NUMBER         NOT NULL,
   cust_first_name          VARCHAR2(20)   NOT NULL,
   cust_last_name           VARCHAR2(40)   NOT NULL,
   cust_gender              CHAR(1)        NOT NULL,
   cust_year_of_birth       NUMBER(4)      NOT NULL,
   cust_marital_status      VARCHAR2(20),
   cust_street_address      VARCHAR2(40)   NOT NULL,
   cust_postal_code         VARCHAR2(10)   NOT NULL,
   cust_city                VARCHAR2(30)   NOT NULL,
   cust_city_id             NUMBER         NOT NULL,
   cust_state_province      VARCHAR2(40)   NOT NULL,
   cust_state_province_id   NUMBER         NOT NULL,
   country_id               NUMBER         NOT NULL,
   cust_main_phone_number   VARCHAR2(25)   NOT NULL,
   cust_income_level        VARCHAR2(30),
   cust_credit_limit        NUMBER,
   cust_email               VARCHAR2(50),
   cust_total               VARCHAR2(14)   NOT NULL,
   cust_total_id            NUMBER         NOT NULL,
   cust_src_id              NUMBER,
   cust_eff_from            DATE,
   cust_eff_to              DATE,
   cust_valid               VARCHAR2(1),
   CONSTRAINT customers_pk
      PRIMARY KEY (cust_id),
   CONSTRAINT customers_country_fk
      FOREIGN KEY (country_id) REFERENCES countries (country_id)
);

-- ----------------------------------------------------------------------------

CREATE TABLE promotions
(
   promo_id               NUMBER(6)      NOT NULL,
   promo_name             VARCHAR2(30)   NOT NULL,
   promo_subcategory      VARCHAR2(30)   NOT NULL,
   promo_subcategory_id   NUMBER         NOT NULL,
   promo_category         VARCHAR2(30)   NOT NULL,
   promo_category_id      NUMBER         NOT NULL,
   promo_cost             NUMBER(10,2)   NOT NULL,
   promo_begin_date       DATE           NOT NULL,
   promo_end_date         DATE           NOT NULL,
   promo_total            VARCHAR2(15)   NOT NULL,
   promo_total_id         NUMBER         NOT NULL,
   CONSTRAINT promo_pk
      PRIMARY KEY (promo_id)
);

-- ----------------------------------------------------------------------------

CREATE TABLE products
(
   prod_id                 NUMBER(6)        NOT NULL,
   prod_name               VARCHAR2(50)     NOT NULL,
   prod_desc               VARCHAR2(4000)   NOT NULL,
   prod_subcategory        VARCHAR2(50)     NOT NULL,
   prod_subcategory_id     NUMBER           NOT NULL,
   prod_subcategory_desc   VARCHAR2(2000)   NOT NULL,
   prod_category           VARCHAR2(50)     NOT NULL,
   prod_category_id        NUMBER           NOT NULL,
   prod_category_desc      VARCHAR2(2000)   NOT NULL,
   prod_weight_class       NUMBER(3)        NOT NULL,
   prod_unit_of_measure    VARCHAR2(20),
   prod_pack_size          VARCHAR2(30)     NOT NULL,
   supplier_id             NUMBER(6)        NOT NULL,
   prod_status             VARCHAR2(20)     NOT NULL,
   prod_list_price         NUMBER(8,2)      NOT NULL,
   prod_min_price          NUMBER(8,2)      NOT NULL,
   prod_total              VARCHAR2(13)     NOT NULL,
   prod_total_id           NUMBER           NOT NULL,
   prod_src_id             NUMBER,
   prod_eff_from           DATE,
   prod_eff_to             DATE,
   prod_valid              VARCHAR2(1),
   CONSTRAINT products_pk
      PRIMARY KEY (prod_id)
);

-- ----------------------------------------------------------------------------

CREATE TABLE times
(
   time_id                   DATE          NOT NULL,
   day_name                  VARCHAR2(9)   NOT NULL,
   day_number_in_week        NUMBER(1)     NOT NULL,
   day_number_in_month       NUMBER(2)     NOT NULL,
   calendar_week_number      NUMBER(2)     NOT NULL,
   fiscal_week_number        NUMBER(2)     NOT NULL,
   week_ending_day           DATE          NOT NULL,
   week_ending_day_id        NUMBER        NOT NULL,
   calendar_month_number     NUMBER(2)     NOT NULL,
   fiscal_month_number       NUMBER(2)     NOT NULL,
   calendar_month_desc       VARCHAR2(8)   NOT NULL,
   calendar_month_id         NUMBER        NOT NULL,
   fiscal_month_desc         VARCHAR2(8)   NOT NULL,
   fiscal_month_id           NUMBER        NOT NULL,
   days_in_cal_month         NUMBER        NOT NULL,
   days_in_fis_month         NUMBER        NOT NULL,
   end_of_cal_month          DATE          NOT NULL,
   end_of_fis_month          DATE          NOT NULL,
   calendar_month_name       VARCHAR2(9)   NOT NULL,
   fiscal_month_name         VARCHAR2(9)   NOT NULL,
   calendar_quarter_desc     CHAR(7)       NOT NULL,
   calendar_quarter_id       NUMBER        NOT NULL,
   fiscal_quarter_desc       CHAR(7)       NOT NULL,
   fiscal_quarter_id         NUMBER        NOT NULL,
   days_in_cal_quarter       NUMBER        NOT NULL,
   days_in_fis_quarter       NUMBER        NOT NULL,
   end_of_cal_quarter        DATE          NOT NULL,
   end_of_fis_quarter        DATE          NOT NULL,
   calendar_quarter_number   NUMBER(1)     NOT NULL,
   fiscal_quarter_number     NUMBER(1)     NOT NULL,
   calendar_year             NUMBER(4)     NOT NULL,
   calendar_year_id          NUMBER        NOT NULL,
   fiscal_year               NUMBER(4)     NOT NULL,
   fiscal_year_id            NUMBER        NOT NULL,
   days_in_cal_year          NUMBER        NOT NULL,
   days_in_fis_year          NUMBER        NOT NULL,
   end_of_cal_year           DATE          NOT NULL,
   end_of_fis_year           DATE          NOT NULL,
   CONSTRAINT times_pk
      PRIMARY KEY (time_id)
);

-- ----------------------------------------------------------------------------

CREATE TABLE channels
(
   channel_id         NUMBER         NOT NULL,
   channel_desc       VARCHAR2(20)   NOT NULL,
   channel_class      VARCHAR2(20)   NOT NULL,
   channel_class_id   NUMBER         NOT NULL,
   channel_total      VARCHAR2(13)   NOT NULL,
   channel_total_id   NUMBER         NOT NULL,
   CONSTRAINT channels_pk
      PRIMARY KEY (channel_id)
);

-- ============================================================================
-- FACT TABLES (Partitioned)
-- ============================================================================

-- Partitioned by time_id using range partitioning
CREATE TABLE sales
(
   prod_id         NUMBER(6)      NOT NULL,
   cust_id         NUMBER         NOT NULL,
   time_id         DATE           NOT NULL,
   channel_id      NUMBER(1)      NOT NULL,
   promo_id        NUMBER(6)      NOT NULL,
   quantity_sold   NUMBER(3)      NOT NULL,
   amount_sold     NUMBER(10,2)   NOT NULL,
   CONSTRAINT sales_promo_fk
      FOREIGN KEY (promo_id)   REFERENCES promotions (promo_id),
   CONSTRAINT sales_customer_fk
      FOREIGN KEY (cust_id)    REFERENCES customers (cust_id),
   CONSTRAINT sales_product_fk
      FOREIGN KEY (prod_id)    REFERENCES products (prod_id),
   CONSTRAINT sales_channel_fk
      FOREIGN KEY (channel_id) REFERENCES channels (channel_id),
   CONSTRAINT sales_time_fk
      FOREIGN KEY (time_id) REFERENCES times (time_id)
)
 PARTITION BY RANGE (time_id)
 (
    PARTITION SALES_2018 VALUES LESS THAN
       (TO_DATE('2019-01-01','YYYY-MM-DD','NLS_DATE_LANGUAGE = American')),
    PARTITION SALES_H1_2019 VALUES LESS THAN
       (TO_DATE('2019-07-01','YYYY-MM-DD','NLS_DATE_LANGUAGE = American')),
    PARTITION SALES_H2_2019 VALUES LESS THAN
       (TO_DATE('2020-01-01','YYYY-MM-DD','NLS_DATE_LANGUAGE = American')),
    PARTITION SALES_Q1_2020 VALUES LESS THAN
       (TO_DATE('2020-04-01','YYYY-MM-DD','NLS_DATE_LANGUAGE = American')),
    PARTITION SALES_Q2_2020 VALUES LESS THAN
       (TO_DATE('2020-07-01','YYYY-MM-DD','NLS_DATE_LANGUAGE = American')),
    PARTITION SALES_Q3_2020 VALUES LESS THAN
       (TO_DATE('2020-10-01','YYYY-MM-DD','NLS_DATE_LANGUAGE = American')),
    PARTITION SALES_Q4_2020 VALUES LESS THAN
       (TO_DATE('2021-01-01','YYYY-MM-DD','NLS_DATE_LANGUAGE = American')),
    PARTITION SALES_Q1_2021 VALUES LESS THAN
       (TO_DATE('2021-04-01','YYYY-MM-DD','NLS_DATE_LANGUAGE = American')),
    PARTITION SALES_Q2_2021 VALUES LESS THAN
       (TO_DATE('2021-07-01','YYYY-MM-DD','NLS_DATE_LANGUAGE = American')),
    PARTITION SALES_Q3_2021 VALUES LESS THAN
       (TO_DATE('2021-10-01','YYYY-MM-DD','NLS_DATE_LANGUAGE = American')),
    PARTITION SALES_Q4_2021 VALUES LESS THAN
       (TO_DATE('2022-01-01','YYYY-MM-DD','NLS_DATE_LANGUAGE = American')),
    PARTITION SALES_Q1_2022 VALUES LESS THAN
       (TO_DATE('2022-04-01','YYYY-MM-DD','NLS_DATE_LANGUAGE = American')),
    PARTITION SALES_Q2_2022 VALUES LESS THAN
       (TO_DATE('2022-07-01','YYYY-MM-DD','NLS_DATE_LANGUAGE = American')),
    PARTITION SALES_Q3_2022 VALUES LESS THAN
       (TO_DATE('2022-10-01','YYYY-MM-DD','NLS_DATE_LANGUAGE = American')),
    PARTITION SALES_Q4_2022 VALUES LESS THAN
       (TO_DATE('2023-01-01','YYYY-MM-DD','NLS_DATE_LANGUAGE = American'))
 )
;

-- ----------------------------------------------------------------------------

-- Partitioned costs table with COMPRESS on partitions
CREATE TABLE costs
(
   prod_id      NUMBER         NOT NULL,
   time_id      DATE           NOT NULL,
   promo_id     NUMBER         NOT NULL,
   channel_id   NUMBER         NOT NULL,
   unit_cost    NUMBER(10,2)   NOT NULL,
   unit_price   NUMBER(10,2)   NOT NULL,
   CONSTRAINT costs_promo_fk
      FOREIGN KEY (promo_id)   REFERENCES promotions (promo_id),
   CONSTRAINT costs_product_fk
      FOREIGN KEY (prod_id)    REFERENCES products (prod_id),
   CONSTRAINT costs_time_fk
      FOREIGN KEY (time_id)    REFERENCES times (time_id),
   CONSTRAINT costs_channel_fk
      FOREIGN KEY (channel_id) REFERENCES channels (channel_id)
)
 PARTITION BY RANGE (time_id)
  (
    PARTITION COSTS_Q1_2019 VALUES LESS THAN
       (TO_DATE('2019-04-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN')) COMPRESS,
    PARTITION COSTS_Q2_2019 VALUES LESS THAN
       (TO_DATE('2019-07-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN')) COMPRESS,
    PARTITION COSTS_Q3_2019 VALUES LESS THAN
       (TO_DATE('2019-10-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN')) COMPRESS,
    PARTITION COSTS_Q4_2019 VALUES LESS THAN
       (TO_DATE('2020-01-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN')) COMPRESS,
    PARTITION COSTS_Q1_2020 VALUES LESS THAN
       (TO_DATE('2020-04-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN')) COMPRESS,
    PARTITION COSTS_Q2_2020 VALUES LESS THAN
       (TO_DATE('2020-07-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN')) COMPRESS,
    PARTITION COSTS_Q3_2020 VALUES LESS THAN
       (TO_DATE('2020-10-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN')) COMPRESS,
    PARTITION COSTS_Q4_2020 VALUES LESS THAN
       (TO_DATE('2021-01-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN')) COMPRESS,
    PARTITION COSTS_Q1_2021 VALUES LESS THAN
       (TO_DATE('2021-04-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN')) COMPRESS,
    PARTITION COSTS_Q2_2021 VALUES LESS THAN
       (TO_DATE('2021-07-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN')) COMPRESS,
    PARTITION COSTS_Q3_2021 VALUES LESS THAN
       (TO_DATE('2021-10-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN')) COMPRESS,
    PARTITION COSTS_Q4_2021 VALUES LESS THAN
       (TO_DATE('2022-01-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN')) COMPRESS,
    PARTITION COSTS_Q1_2022 VALUES LESS THAN
       (TO_DATE('2022-04-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN')) COMPRESS,
    PARTITION COSTS_Q2_2022 VALUES LESS THAN
       (TO_DATE('2022-07-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN')) COMPRESS,
    PARTITION COSTS_Q3_2022 VALUES LESS THAN
       (TO_DATE('2022-10-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN')) COMPRESS,
    PARTITION COSTS_Q4_2022 VALUES LESS THAN
       (TO_DATE('2023-01-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN')) COMPRESS,
    PARTITION COSTS_Q1_2023 VALUES LESS THAN
       (TO_DATE('2023-04-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN')) COMPRESS,
    PARTITION COSTS_Q2_2023 VALUES LESS THAN
       (TO_DATE('2023-07-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN')) COMPRESS,
    PARTITION COSTS_Q3_2023 VALUES LESS THAN
       (TO_DATE('2023-10-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN')) COMPRESS,
    PARTITION COSTS_Q4_2023 VALUES LESS THAN
       (TO_DATE('2024-01-01','YYYY-MM-DD','NLS_CALENDAR=GREGORIAN'))
  )
;

-- ----------------------------------------------------------------------------

CREATE TABLE supplementary_demographics
(
   cust_id                   NUMBER           NOT NULL,
   education                 VARCHAR2(21),
   occupation                VARCHAR2(21),
   household_size            VARCHAR2(21),
   yrs_residence             NUMBER,
   affinity_card             NUMBER(10),
   cricket                   NUMBER(10),
   baseball                  NUMBER(10),
   tennis                    NUMBER(10),
   soccer                    NUMBER(10),
   golf                      NUMBER(10),
   unknown                   NUMBER(10),
   misc                      NUMBER(10),
   comments                  VARCHAR2(4000),
   CONSTRAINT supp_demo_pk
      PRIMARY KEY (cust_id)
);

-- ============================================================================
-- VIEWS
-- ============================================================================

-- View: profits
-- Joins sales with costs to compute total cost
CREATE OR REPLACE VIEW profits
 AS SELECT
  s.channel_id,
  s.cust_id,
  s.prod_id,
  s.promo_id,
  s.time_id,
  c.unit_cost,
  c.unit_price,
  s.amount_sold,
  s.quantity_sold,
  c.unit_cost * s.quantity_sold TOTAL_COST
 FROM
  costs c, sales s
 WHERE c.prod_id = s.prod_id
   AND c.time_id = s.time_id
   AND c.channel_id = s.channel_id
   AND c.promo_id = s.promo_id;

-- ============================================================================
-- MATERIALIZED VIEWS
-- ============================================================================

CREATE MATERIALIZED VIEW cal_month_sales_mv
   ENABLE QUERY REWRITE
   AS
   SELECT   t.calendar_month_desc,
            SUM(s.amount_sold) AS dollars
   FROM     sh.sales s,
            sh.times t
   WHERE    s.time_id = t.time_id
   GROUP BY t.calendar_month_desc;

CREATE MATERIALIZED VIEW fweek_pscat_sales_mv
   ENABLE QUERY REWRITE
   AS
   SELECT   t.week_ending_day,
            p.prod_subcategory,
            SUM(s.amount_sold) AS dollars,
            s.channel_id,
            s.promo_id
   FROM     sh.sales s,
            sh.times t,
            sh.products p
   WHERE    s.time_id = t.time_id
      AND   s.prod_id = p.prod_id
   GROUP BY t.week_ending_day,
            p.prod_subcategory,
            s.channel_id,
            s.promo_id;
