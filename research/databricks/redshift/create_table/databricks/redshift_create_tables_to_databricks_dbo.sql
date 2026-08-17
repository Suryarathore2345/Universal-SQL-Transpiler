CREATE TABLE `dbo`.`venue_ident` (
    `venueid` BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 0 INCREMENT BY 1),
    `venuename` STRING(100),
    `venuecity` STRING(30),
    `venuestate` CHAR(2),
    `venueseats` INT,
    PRIMARY KEY (`venueid`) NOT ENFORCED
)
USING DELTA;

CREATE TABLE IF NOT EXISTS `dbo`.`customer` (
    `c_customer_sk` INT NOT NULL,
    `c_customer_id` CHAR(16) NOT NULL,
    `c_current_addr_sk` INT,
    `c_first_name` CHAR(20),
    `c_last_name` CHAR(30),
    PRIMARY KEY (`c_customer_sk`) NOT ENFORCED
)
USING DELTA;

CREATE TABLE IF NOT EXISTS `dbo`.`customer_address` (
    `ca_address_sk` INT NOT NULL,
    `ca_address_id` CHAR(16) NOT NULL,
    `ca_state` CHAR(2),
    `ca_zip` CHAR(10),
    `ca_country` STRING(20),
    PRIMARY KEY (`ca_address_id`) NOT ENFORCED
)
USING DELTA;

CREATE TABLE IF NOT EXISTS `dbo`.`date_dim` (
    `d_date_sk` INT NOT NULL,
    `d_date_id` CHAR(16) NOT NULL,
    `d_date` DATE,
    `d_day_name` CHAR(9),
    PRIMARY KEY (`d_date_sk`) NOT ENFORCED
)
USING DELTA;

CREATE TABLE `dbo`.`sales_raw` (
    `id` INT,
    `date` DATE,
    `product` STRING(255),
    `quantity` INT,
    `revenue` DECIMAL(10,2)
)
USING DELTA
CLUSTER BY (`date`, `product`);

CREATE TABLE IF NOT EXISTS `dbo`.`cost` (
    `recid` BIGINT NOT NULL,
    `amount_per_year` DECIMAL(38,4),
    `insert_dts` TIMESTAMP_NTZ NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (`recid`) NOT ENFORCED
)
USING DELTA
CLUSTER BY (`recid`);

CREATE TABLE `dbo`.`events` (
    `event_id` BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
    `collector_tstamp` TIMESTAMP_NTZ,
    `event_fingerprint` STRING(128),
    `true_tstamp` TIMESTAMP_NTZ,
    PRIMARY KEY (`event_id`) NOT ENFORCED
)
USING DELTA
CLUSTER BY (`collector_tstamp`);

CREATE TABLE IF NOT EXISTS `dbo`.`appsclub_user_clicks` (
    `log_source` STRING(20),
    `time_stamp` TIMESTAMP_NTZ,
    `user_id` STRING(128),
    `ecid` STRING(10),
    `opx_user_id` STRING(20),
    `opx_site_id` STRING(20),
    `operator` STRING(20),
    `country_code` STRING(2),
    `platform` STRING(64),
    `platform_version` STRING(64),
    `device_make` STRING(96),
    `device_model` STRING(96),
    `network_connection` STRING(20),
    `browser` STRING(64),
    `browser_version` STRING(64),
    `utm_source` STRING(40),
    `utm_campaign` STRING(40),
    `utm_content` STRING(40),
    `distr_source` STRING(10),
    `subscription_status` STRING(20),
    `visit_id` STRING(20),
    `clicked_content` STRING(255),
    `date_created` TIMESTAMP_NTZ,
    `opx_site_name` STRING(64),
    `ip_address` STRING(45)
)
USING DELTA
CLUSTER BY (`opx_site_id`, `time_stamp`);

CREATE TABLE `dbo`.`sales` (
    `salesid` INT NOT NULL,
    `listid` INT NOT NULL,
    `sellerid` INT NOT NULL,
    `buyerid` INT NOT NULL,
    `eventid` INT NOT NULL,
    `dateid` SMALLINT NOT NULL,
    `qtysold` SMALLINT NOT NULL,
    `pricepaid` DECIMAL(8,2),
    `commission` DECIMAL(8,2),
    `saletime` TIMESTAMP_NTZ,
    PRIMARY KEY (`salesid`) NOT ENFORCED
)
USING DELTA
CLUSTER BY (`listid`, `sellerid`);

CREATE TABLE IF NOT EXISTS `dbo`.`cities` (
    `cityid` INT NOT NULL,
    `city` STRING(100) NOT NULL,
    `state` CHAR(2) NOT NULL
)
USING DELTA;

CREATE TABLE `dbo`.`venue` (
    `venueid` SMALLINT NOT NULL,
    `venuename` STRING(100),
    `venuecity` STRING(30),
    `venuestate` CHAR(2),
    `venueseats` INT,
    PRIMARY KEY (`venueid`) NOT ENFORCED
)
USING DELTA;

CREATE TABLE `dbo`.`myevent` (
    `eventid` INT,
    `eventname` STRING(200),
    `eventcity` STRING(30)
)
USING DELTA;

CREATE TABLE `dbo`.`tempevent` (

)
USING DELTA;

CREATE TABLE `dbo`.`t1` (
    `hist_id` BIGINT NOT NULL,
    `base_id` BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) NOT NULL,
    `business_key` STRING(10),
    `some_field` STRING(10)
)
USING DELTA;

CREATE TABLE `dbo`.`categorydef` (
    `catid` SMALLINT NOT NULL DEFAULT 0,
    `catgroup` STRING(10) DEFAULT 'Special',
    `catname` STRING(10) DEFAULT 'Other',
    `catdesc` STRING(50) DEFAULT 'Special events',
    PRIMARY KEY (`catid`) NOT ENFORCED
)
USING DELTA;

CREATE TABLE `dbo`.`t3` (
    `col1` INT,
    `col2` INT
)
USING DELTA;

CREATE TABLE `dbo`.`t1` (
    `c0` INT,
    `c1` STRING
)
USING DELTA;

CREATE TABLE `dbo`.`foo` (
    `a` CHAR,
    `b` STRING(10),
    `c` VARIANT
)
USING DELTA;

CREATE TABLE `dbo`.`t1` (
    `c1` INT,
    `c2` INT
)
USING DELTA;

CREATE TABLE `dbo`.`t2` (
    `c1` INT,
    `c2` INT
)
USING DELTA;

CREATE TABLE `dbo`.`#newtable` (
    `id` INT
)
USING DELTA;

CREATE TABLE IF NOT EXISTS `dbo`.`vehicle` (
    `vehicleid` STRING(255) NOT NULL,
    `description` STRING(255),
    PRIMARY KEY (`vehicleid`) NOT ENFORCED
)
USING DELTA;

CREATE TABLE IF NOT EXISTS `dbo`.`sensor` (
    `sensorid` STRING(255) NOT NULL,
    `description` STRING(255),
    PRIMARY KEY (`sensorid`) NOT ENFORCED
)
USING DELTA;

CREATE TABLE IF NOT EXISTS `dbo`.`testzz` (
    `Column1` CHAR
)
USING DELTA;

CREATE TABLE IF NOT EXISTS `dbo`.`test_all_types` (
    `c1` SMALLINT,
    `c2` INT,
    `c3` BIGINT,
    `c4` DECIMAL(18,0),
    `c5` DOUBLE,
    `c6` DOUBLE,
    `c7` BOOLEAN,
    `c8` CHAR(1),
    `c9` STRING(256),
    `c10` DATE,
    `c11` TIMESTAMP_NTZ,
    `c12` TIMESTAMP,
    `c15` STRING,
    `c16` STRING,
    `-c10` STRING(10)
)
USING DELTA;