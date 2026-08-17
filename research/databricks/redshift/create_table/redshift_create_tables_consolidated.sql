-- UST research corpus: real-world Redshift CREATE TABLE examples
-- Phase: Redshift CREATE TABLE -> Databricks (research only; not yet converted)
-- Notes:
--   - Each example is taken from a public web source.
--   - SQL is kept close to the source form and not rewritten for Databricks.
--   - Metadata is included so the examples can be traced back quickly.

-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: IDENTITY + PRIMARY KEY
-- DESCRIPTION: Example table with an identity column and primary key.
CREATE TABLE venue_ident(
  venueid bigint identity(0, 1),
  venuename varchar(100),
  venuecity varchar(30),
  venuestate char(2),
  venueseats integer,
  primary key(venueid)
);

-- SOURCE: aws-samples/getting-started-with-amazon-redshift-data-api
-- URL: https://github.com/aws-samples/getting-started-with-amazon-redshift-data-api/blob/main/use-cases/etl-orchestration-with-step-functions/scripts/sp_statements.sql
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DISTSTYLE ALL + PRIMARY KEY + ENCODE
-- DESCRIPTION: Dimension-table pattern commonly used in ETL setups.
CREATE TABLE IF NOT EXISTS public.customer
(
  c_customer_sk int4 not null encode az64,
  c_customer_id char(16) not null encode zstd,
  c_current_addr_sk int4 encode az64,
  c_first_name char(20) encode zstd,
  c_last_name char(30) encode zstd,
  primary key (c_customer_sk)
)
DISTSTYLE ALL;

-- SOURCE: aws-samples/getting-started-with-amazon-redshift-data-api
-- URL: https://github.com/aws-samples/getting-started-with-amazon-redshift-data-api/blob/main/use-cases/etl-orchestration-with-step-functions/scripts/sp_statements.sql
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DISTKEY + PRIMARY KEY + ENCODE
-- DESCRIPTION: Staging-table style DDL with distribution key and compression.
CREATE TABLE IF NOT EXISTS public.customer_address
(
  ca_address_sk int4 not null encode az64,
  ca_address_id char(16) not null encode zstd,
  ca_state char(2) encode zstd,
  ca_zip char(10) encode zstd,
  ca_country varchar(20) encode zstd,
  primary key (ca_address_id)
)
DISTKEY(ca_address_id);

-- SOURCE: aws-samples/getting-started-with-amazon-redshift-data-api
-- URL: https://github.com/aws-samples/getting-started-with-amazon-redshift-data-api/blob/main/use-cases/etl-orchestration-with-step-functions/scripts/sp_statements.sql
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DISTSTYLE ALL + PRIMARY KEY + ENCODE
-- DESCRIPTION: Date dimension example with a small replicated table.
CREATE TABLE IF NOT EXISTS public.date_dim
(
  d_date_sk integer not null encode az64,
  d_date_id char(16) not null encode zstd,
  d_date date encode az64,
  d_day_name char(9) encode zstd,
  primary key (d_date_sk)
)
DISTSTYLE ALL;

-- SOURCE: aws-redshift/redshift_query_commands.txt
-- URL: https://github.com/Ratnesh-181998/aws-redshift/blob/main/redshift_query_commands.txt
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: ENCODE + DISTSTYLE KEY + DISTKEY + SORTKEY
-- DESCRIPTION: Fact-style table with explicit dist/sort optimization.
CREATE TABLE sales_data_mart.sales_raw (
  id INT ENCODE lzo,
  date DATE ENCODE bytedict,
  product VARCHAR(255) ENCODE lzo,
  quantity INT ENCODE delta,
  revenue DECIMAL(10,2) ENCODE delta
)
DISTSTYLE KEY
DISTKEY (date)
SORTKEY (date, product);

-- SOURCE: aws-samples/amazon-redshift-query-patterns-and-optimizations
-- URL: https://github.com/aws-samples/amazon-redshift-query-patterns-and-optimizations/blob/master/sql_scripts/schema_setup.sql
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: IDENTITY + PRIMARY KEY + DISTKEY + SORTKEY + ENCODE
-- DESCRIPTION: Common warehouse fact table shape with an identity key.
CREATE TABLE IF NOT EXISTS my_schema.cost
(
  recid BIGINT NOT NULL ENCODE az64,
  amount_per_year NUMERIC(38,4) ENCODE az64,
  insert_dts TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT getdate() ENCODE az64,
  PRIMARY KEY (recid)
)
DISTSTYLE KEY
DISTKEY (recid)
SORTKEY (recid);

-- SOURCE: snowplow/snowplow redshift storage definition
-- URL: https://github.com/snowplow/snowplow/blob/master/4-storage/redshift-storage/sql/atomic-def.sql
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: IDENTITY + PRIMARY KEY + DISTSTYLE KEY + DISTKEY + SORTKEY + COMMENT
-- DESCRIPTION: Large event fact table with column encodings and warehouse tuning.
CREATE TABLE atomic.events (
  event_id BIGINT IDENTITY(1,1),
  collector_tstamp TIMESTAMP ENCODE ZSTD,
  event_fingerprint VARCHAR(128) ENCODE ZSTD,
  true_tstamp TIMESTAMP ENCODE ZSTD,
  CONSTRAINT event_id_0110_pk PRIMARY KEY(event_id)
)
DISTSTYLE KEY
DISTKEY (event_id)
SORTKEY (collector_tstamp);

-- SOURCE: awslabs/amazon-redshift-utils issue example
-- URL: https://github.com/awslabs/amazon-redshift-utils/issues/333
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DISTSTYLE EVEN + SORTKEY + ENCODE RAW
-- DESCRIPTION: Wide event table pattern with many compressed columns.
CREATE TABLE IF NOT EXISTS public.appsclub_user_clicks(
  log_source VARCHAR(20) ENCODE RAW,
  time_stamp TIMESTAMP WITHOUT TIME ZONE ENCODE RAW,
  user_id VARCHAR(128) ENCODE RAW,
  ecid VARCHAR(10) ENCODE RAW,
  opx_user_id VARCHAR(20) ENCODE RAW,
  opx_site_id VARCHAR(20) ENCODE RAW,
  "operator" VARCHAR(20) ENCODE RAW,
  country_code VARCHAR(2) ENCODE RAW,
  platform VARCHAR(64) ENCODE RAW,
  platform_version VARCHAR(64) ENCODE RAW,
  device_make VARCHAR(96) ENCODE RAW,
  device_model VARCHAR(96) ENCODE RAW,
  network_connection VARCHAR(20) ENCODE RAW,
  browser VARCHAR(64) ENCODE RAW,
  browser_version VARCHAR(64) ENCODE RAW,
  utm_source VARCHAR(40) ENCODE RAW,
  utm_campaign VARCHAR(40) ENCODE RAW,
  utm_content VARCHAR(40) ENCODE RAW,
  distr_source VARCHAR(10) ENCODE RAW,
  subscription_status VARCHAR(20) ENCODE RAW,
  visit_id VARCHAR(20) ENCODE RAW,
  clicked_content VARCHAR(255) ENCODE RAW,
  date_created TIMESTAMP WITHOUT TIME ZONE ENCODE RAW,
  opx_site_name VARCHAR(64) ENCODE RAW,
  ip_address VARCHAR(45) ENCODE lzo
)
DISTSTYLE EVEN
SORTKEY (opx_site_id, time_stamp);

-- SOURCE: amazon-redshift-python-driver issue example
-- URL: https://github.com/aws/amazon-redshift-python-driver/issues/82
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: TEMPORARY TABLE + DISTKEY + SORTKEY
-- DESCRIPTION: Multi-statement temp-table pattern used in scripts.
CREATE TEMPORARY TABLE _tmp (
  key char(32) DISTKEY,
  payload varchar(256)
)
DISTSTYLE KEY
SORTKEY(key);

-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DISTKEY + COMPOUND SORTKEY + PK/FK + ENCODE
-- DESCRIPTION: Canonical warehouse SALES table with compression and relational constraints.
CREATE TABLE sales(
  salesid integer not null,
  listid integer not null,
  sellerid integer not null,
  buyerid integer not null,
  eventid integer not null encode mostly16,
  dateid smallint not null,
  qtysold smallint not null encode mostly8,
  pricepaid decimal(8,2) encode delta32k,
  commission decimal(8,2) encode delta32k,
  saletime timestamp,
  primary key(salesid),
  foreign key(listid) references listing(listid),
  foreign key(sellerid) references users(userid)
)
distkey(listid)
sortkey(listid, sellerid);

-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: INTERLEAVED SORTKEY + DISTSTYLE ALL
-- DESCRIPTION: Interleaved sort example used for customer-style lookup patterns.
CREATE TABLE customer_interleaved (
  c_custkey integer not null,
  c_name varchar(25) not null,
  c_address varchar(25) not null,
  c_city varchar(10) not null,
  c_nation varchar(15) not null,
  c_region varchar(12) not null,
  c_phone varchar(15) not null,
  c_mktsegment varchar(10) not null
)
diststyle all
interleaved sortkey (c_custkey, c_city, c_mktsegment);

-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: IF NOT EXISTS
-- DESCRIPTION: Basic create-if-missing warehouse table.
CREATE TABLE IF NOT EXISTS cities(
  cityid integer not null,
  city varchar(100) not null,
  state char(2) not null
);

-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: ALL DISTRIBUTION
-- DESCRIPTION: Small replicated dimension table.
CREATE TABLE venue(
  venueid smallint not null,
  venuename varchar(100),
  venuecity varchar(30),
  venuestate char(2),
  venueseats integer,
  primary key(venueid)
)
diststyle all;

-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: EVEN DISTRIBUTION
-- DESCRIPTION: Evenly distributed table with no explicit sort key.
CREATE TABLE myevent(
  eventid int,
  eventname varchar(200),
  eventcity varchar(30)
)
diststyle even;

-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: TEMP TABLE + LIKE
-- DESCRIPTION: Temporary table inheriting structure from an existing table.
CREATE TEMP TABLE tempevent(like event);

-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DEFAULT IDENTITY
-- DESCRIPTION: Redshift default identity example with override-able identity column.
CREATE TABLE t1(
  hist_id BIGINT IDENTITY NOT NULL,
  base_id BIGINT GENERATED BY DEFAULT AS IDENTITY NOT NULL,
  business_key varchar(10),
  some_field varchar(10)
);

-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DEFAULT VALUES
-- DESCRIPTION: Table showing default literal values for every column.
CREATE TABLE categorydef(
  catid smallint not null default 0,
  catgroup varchar(10) default 'Special',
  catname varchar(10) default 'Other',
  catdesc varchar(50) default 'Special events',
  primary key(catid)
);

-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DISTKEY + SORTKEY OPTIONS
-- DESCRIPTION: Column-level distkey and sortkey syntax variants.
CREATE TABLE t1(col1 int distkey, col2 int) diststyle key;

-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DISTKEY + SORTKEY OPTIONS
-- DESCRIPTION: Same column declared as both distkey and sortkey.
CREATE TABLE t2(col1 int distkey sortkey, col2 int);

-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: SORTKEY + DISTSTYLE ALL
-- DESCRIPTION: Sortkey declared at column level with ALL distribution.
CREATE TABLE t3(col1 int, col2 int sortkey) diststyle all;

-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: BASIC CREATE TABLE
-- DESCRIPTION: Minimal create-table example from the Redshift docs page.
CREATE TABLE t1(c0 int, c1 varchar);

-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: ENCODE AUTO + EXPLICIT ENCODE
-- DESCRIPTION: Explicit encoding seeds that Redshift may later optimize automatically.
CREATE TABLE t4(c0 int encode delta, c1 varchar encode lzo) encode auto;

-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_SHOW_TABLE.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: COLLATE + SUPER
-- DESCRIPTION: Case-insensitive collation example with SUPER type.
CREATE TABLE public.foo (
  a CHAR,
  b VARCHAR(10) COLLATE CASE_INSENSITIVE,
  c SUPER COLLATE CASE_INSENSITIVE
);

-- SOURCE: GitHub issue / real-world parsing example
-- URL: https://github.com/sqlfluff/sqlfluff/issues/5592
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: COMPOSITE UNIQUE + COMPOSITE FOREIGN KEY
-- DESCRIPTION: Redshift table constraints with multi-column FK syntax.
CREATE TABLE public.t1 (c1 int, c2 int, unique (c1, c2));

-- SOURCE: GitHub issue / real-world parsing example
-- URL: https://github.com/sqlfluff/sqlfluff/issues/5592
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: COMPOSITE FOREIGN KEY
-- DESCRIPTION: Composite foreign key referencing a composite unique key.
CREATE TABLE public.t2
(
  c1 int,
  c2 int,
  foreign key (c1, c2) references public.t1 (c1, c2)
);

-- SOURCE: Amazon Redshift docs
-- URL: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: TEMP TABLE NAME PREFIX
-- DESCRIPTION: Temporary table naming using the # prefix.
CREATE TABLE #newtable (id int);

-- SOURCE: aws-samples/amazon-eks-autonomous-driving-data-service README
-- URL: https://github.com/aws-samples/amazon-eks-autonomous-driving-data-service/blob/master/README.md
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DISTSTYLE ALL + PRIMARY KEY + ENCODE
-- DESCRIPTION: Vehicle dimension table from an autonomous-driving reference architecture.
CREATE TABLE IF NOT EXISTS schema_name.vehicle
(
  vehicleid VARCHAR(255) NOT NULL ENCODE lzo,
  description VARCHAR(255) ENCODE lzo,
  PRIMARY KEY (vehicleid)
)
DISTSTYLE ALL;

-- SOURCE: aws-samples/amazon-eks-autonomous-driving-data-service README
-- URL: https://github.com/aws-samples/amazon-eks-autonomous-driving-data-service/blob/master/README.md
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DISTSTYLE ALL + PRIMARY KEY + ENCODE
-- DESCRIPTION: Sensor dimension table from the same Redshift deployment example.
CREATE TABLE IF NOT EXISTS schema_name.sensor
(
  sensorid VARCHAR(255) NOT NULL ENCODE lzo,
  description VARCHAR(255) ENCODE lzo,
  PRIMARY KEY (sensorid)
)
DISTSTYLE ALL;

-- SOURCE: aws-samples/amazon-eks-autonomous-driving-data-service scripts
-- URL: https://github.com/aws-samples/amazon-eks-autonomous-driving-data-service/blob/master/scripts/a2d2_etl_steps.sh
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DISTSTYLE AUTO + PRIMARY KEY + FOREIGN KEY + SORTKEY + ENCODE
-- DESCRIPTION: High-volume fact table with foreign keys and auto distribution.
CREATE TABLE IF NOT EXISTS a2d2.drive_data (
  vehicle_id varchar(255) encode Text255 not NULL,
  scene_id varchar(255) encode Text255 not NULL,
  sensor_id varchar(255) encode Text255 not NULL,
  data_ts BIGINT not NULL sortkey,
  s3_bucket VARCHAR(255) encode lzo NOT NULL,
  s3_key varchar(255) encode lzo NOT NULL,
  primary key(vehicle_id, scene_id, sensor_id, data_ts),
  FOREIGN KEY(vehicle_id) references a2d2.vehicle(vehicleid),
  FOREIGN KEY(sensor_id) references a2d2.sensor(sensorid)
) DISTSTYLE AUTO;

-- SOURCE: aws-samples/amazon-eks-autonomous-driving-data-service scripts
-- URL: https://github.com/aws-samples/amazon-eks-autonomous-driving-data-service/blob/master/scripts/a2d2_etl_steps.sh
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: DISTSTYLE AUTO + PRIMARY KEY + FOREIGN KEY + SORTKEY + ENCODE
-- DESCRIPTION: Wide telemetry fact table with many numeric types.
CREATE TABLE IF NOT EXISTS a2d2.bus_data (
  vehicle_id varchar(255) encode Text255 not NULL,
  scene_id varchar(255) encode Text255 not NULL,
  data_ts BIGINT not NULL sortkey,
  acceleration_x FLOAT4 not NULL,
  acceleration_y FLOAT4 not NULL,
  acceleration_z FLOAT4 not NULL,
  accelerator_pedal FLOAT4 not NULL,
  accelerator_pedal_gradient_sign SMALLINT not NULL,
  angular_velocity_omega_x FLOAT4 not NULL,
  angular_velocity_omega_y FLOAT4 not NULL,
  angular_velocity_omega_z FLOAT4 not NULL,
  brake_pressure FLOAT4 not NULL,
  distance_pulse_front_left FLOAT4 not NULL,
  distance_pulse_front_right FLOAT4 not NULL,
  distance_pulse_rear_left FLOAT4 not NULL,
  distance_pulse_rear_right FLOAT4 not NULL,
  latitude_degree FLOAT4 not NULL,
  latitude_direction SMALLINT not NULL,
  longitude_degree FLOAT4 not NULL,
  longitude_direction SMALLINT not NULL,
  pitch_angle FLOAT4 not NULL,
  roll_angle FLOAT4 not NULL,
  steering_angle_calculated FLOAT4 not NULL,
  steering_angle_calculated_sign SMALLINT not NULL,
  vehicle_speed FLOAT4 not NULL,
  primary key(vehicle_id, scene_id, data_ts),
  FOREIGN KEY(vehicle_id) references a2d2.vehicle(vehicleid)
) DISTSTYLE AUTO;

-- SOURCE: dbeaver/dbeaver issue example
-- URL: https://github.com/dbeaver/dbeaver/issues/13218
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: BPCHAR + ENCODE + DISTSTYLE AUTO
-- DESCRIPTION: Real-world driver/export issue exposing a Redshift-specific type and auto distribution.
CREATE TABLE IF NOT EXISTS testzz(Column1 BPCHAR ENCODE lzo) DISTSTYLE AUTO;

-- SOURCE: dbeaver/dbeaver issue example
-- URL: https://github.com/dbeaver/dbeaver/issues/13544
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: MULTI-TYPE COVERAGE + ENCODE + DISTSTYLE AUTO
-- DESCRIPTION: Real-world table covering a broad set of Redshift scalar types.
CREATE TABLE IF NOT EXISTS test_all_types
(
  c1 SMALLINT ENCODE az64,
  c2 INTEGER ENCODE az64,
  c3 BIGINT ENCODE az64,
  c4 NUMERIC(18,0) ENCODE az64,
  c5 REAL ENCODE RAW,
  c6 DOUBLE PRECISION ENCODE RAW,
  c7 BOOLEAN ENCODE RAW,
  c8 CHAR(1) ENCODE lzo,
  c9 VARCHAR(256) ENCODE lzo,
  c10 DATE ENCODE az64,
  c11 TIMESTAMP WITHOUT TIME ZONE ENCODE az64,
  c12 TIMESTAMP WITH TIME ZONE ENCODE az64,
  c15 TIME WITHOUT TIME ZONE ENCODE az64,
  c16 TIME WITH TIME ZONE ENCODE az64,
  "-c10" VARCHAR(10) ENCODE lzo
)
DISTSTYLE AUTO;
