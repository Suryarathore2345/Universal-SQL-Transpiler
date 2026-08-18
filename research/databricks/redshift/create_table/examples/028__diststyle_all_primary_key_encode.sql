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
