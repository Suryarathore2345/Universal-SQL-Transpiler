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
