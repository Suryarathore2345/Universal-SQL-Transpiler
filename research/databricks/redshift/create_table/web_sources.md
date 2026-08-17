# Redshift CREATE TABLE Web Sources

This index tracks the public sources used for the Redshift table corpus in `redshift_create_tables_consolidated.sql` under the `create_table` folder.

| Source | URL | Feature coverage | Example(s) included |
|---|---|---|---|
| Amazon Redshift docs | https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html | identity, default identity, defaults, temp tables, `#` temp naming | `venue_ident`, `tempevent`, `t1`, `categorydef`, `#newtable` |
| Amazon Redshift docs | https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_examples.html | distribution, sort keys, interleaved sort keys, default create-table patterns | `sales`, `customer_interleaved`, `cities`, `venue`, `myevent`, `t1`, `t2`, `t3`, `t4` |
| Amazon Redshift docs | https://docs.aws.amazon.com/redshift/latest/dg/r_SHOW_TABLE.html | `COLLATE`, `SUPER` | `public.foo` |
| Amazon Redshift docs | https://docs.aws.amazon.com/redshift/latest/dg/c_Distribution_examples.html | distkey/diststyle examples | reference source for `DISTSTYLE` patterns |
| aws-samples/getting-started-with-amazon-redshift-data-api | https://github.com/aws-samples/getting-started-with-amazon-redshift-data-api/blob/main/use-cases/etl-orchestration-with-step-functions/scripts/sp_statements.sql | `DISTSTYLE ALL`, `DISTKEY`, `PRIMARY KEY`, `ENCODE`, `BACKUP NO` | `public.customer`, `public.customer_address`, `public.date_dim`, `public.stg_customer_address` |
| aws-samples/amazon-redshift-query-patterns-and-optimizations | https://github.com/aws-samples/amazon-redshift-query-patterns-and-optimizations/blob/master/sql_scripts/schema_setup.sql | `DISTSTYLE KEY`, `DISTKEY`, `SORTKEY`, `DEFAULT`, `IDENTITY` | `my_schema.cost` |
| snowplow/snowplow | https://github.com/snowplow/snowplow/blob/master/4-storage/redshift-storage/sql/atomic-def.sql | event-fact-table pattern, `DISTSTYLE KEY`, `DISTKEY`, `SORTKEY`, constraints | `atomic.events` |
| awslabs/amazon-redshift-utils issue 333 | https://github.com/awslabs/amazon-redshift-utils/issues/333 | `DISTSTYLE EVEN`, `SORTKEY`, `ENCODE RAW` | `public.appsclub_user_clicks` |
| aws/amazon-redshift-python-driver issue 82 | https://github.com/aws/amazon-redshift-python-driver/issues/82 | temporary table, `DISTSTYLE KEY`, `DISTKEY`, `SORTKEY` | `_tmp` |
| aws-samples/amazon-eks-autonomous-driving-data-service README | https://github.com/aws-samples/amazon-eks-autonomous-driving-data-service/blob/master/README.md | `DISTSTYLE ALL`, `PRIMARY KEY`, `ENCODE` | `schema_name.vehicle`, `schema_name.sensor` |
| aws-samples/amazon-eks-autonomous-driving-data-service scripts | https://github.com/aws-samples/amazon-eks-autonomous-driving-data-service/blob/master/scripts/a2d2_etl_steps.sh | `DISTSTYLE AUTO`, `FOREIGN KEY`, `PRIMARY KEY`, `SORTKEY`, mixed numeric types | `a2d2.drive_data`, `a2d2.bus_data` |
| dbeaver/dbeaver issue 13218 | https://github.com/dbeaver/dbeaver/issues/13218 | `BPCHAR`, `ENCODE`, `DISTSTYLE AUTO` | `testzz` |
| dbeaver/dbeaver issue 13544 | https://github.com/dbeaver/dbeaver/issues/13544 | broad scalar type coverage, `DISTSTYLE AUTO` | `test_all_types` |
| sqlfluff/sqlfluff issue 5592 | https://github.com/sqlfluff/sqlfluff/issues/5592 | composite `UNIQUE`, composite `FOREIGN KEY` | `public.t1`, `public.t2` |
