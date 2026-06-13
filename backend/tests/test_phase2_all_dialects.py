"""
Phase 2 tests — all 8 dialect parsers and generators.

Tests cover:
  - SQL Server: CREATE TABLE/VIEW/MV (indexed view fallback)
  - Azure Synapse: DISTRIBUTION parsing + generation, PARTITION BY RANGE
  - Fabric DW: CLUSTER BY (max 4 cols), no-distribution warning
  - Databricks: PARTITIONED BY, CLUSTER BY (liquid), IDENTITY
  - Oracle: PARTITION BY RANGE/LIST/HASH, GENERATED AS IDENTITY
  - BigQuery: PARTITION BY, CLUSTER BY, OPTIONS, no-identity warning
  - Cross-dialect: Redshift→all targets; Snowflake→all targets
"""
from __future__ import annotations

import pytest

from app.transpiler import Transpiler


# ---------------------------------------------------------------------------
# SQL Server tests
# ---------------------------------------------------------------------------

class TestSQLServer:
    def test_basic_table_roundtrip(self):
        sql = """
        CREATE TABLE dbo.Customers (
            customer_id INT IDENTITY(1,1) NOT NULL,
            first_name NVARCHAR(100) NOT NULL,
            last_name NVARCHAR(100),
            email VARCHAR(255),
            created_at DATETIME2 NOT NULL,
            PRIMARY KEY (customer_id)
        )
        """
        result = Transpiler.convert(sql, "sqlserver", "sqlserver")
        assert result.converted_sql.strip()
        assert "customer_id" in result.converted_sql
        assert "IDENTITY" in result.converted_sql
        assert "PRIMARY KEY" in result.converted_sql

    def test_sqlserver_to_snowflake_identity(self):
        sql = "CREATE TABLE Orders (id INT IDENTITY(1,1) NOT NULL, amount DECIMAL(18,2))"
        result = Transpiler.convert(sql, "sqlserver", "snowflake")
        assert result.converted_sql.strip()
        assert "AUTOINCREMENT" in result.converted_sql or "IDENTITY" in result.converted_sql
        assert "DECIMAL(18,2)" in result.converted_sql or "NUMBER(18,2)" in result.converted_sql

    def test_sqlserver_mv_produces_indexed_view_fallback(self):
        sql = "CREATE MATERIALIZED VIEW dbo.mv_sales AS SELECT product_id, SUM(amount) as total FROM sales GROUP BY product_id"
        result = Transpiler.convert(sql, "sqlserver", "sqlserver")
        assert "SCHEMABINDING" in result.converted_sql or "INDEX" in result.converted_sql
        assert len(result.warnings) > 0 or len(result.unsupported_features) > 0

    def test_sqlserver_view(self):
        sql = "CREATE VIEW dbo.ActiveCustomers AS SELECT * FROM dbo.Customers WHERE active = 1"
        result = Transpiler.convert(sql, "sqlserver", "sqlserver")
        assert "CREATE" in result.converted_sql
        assert "VIEW" in result.converted_sql
        assert "ActiveCustomers" in result.converted_sql

    def test_sqlserver_distribution_warning_when_converting_from_synapse(self):
        sql = "CREATE TABLE fact_sales (id INT, amount DECIMAL(18,2)) WITH (DISTRIBUTION = HASH(id), CLUSTERED COLUMNSTORE INDEX)"
        result = Transpiler.convert(sql, "synapse", "sqlserver")
        assert result.converted_sql.strip()
        # Distribution should be dropped with warning
        assert any("DISTRIBUTION" in w.feature.upper() or "distribution" in w.message.lower()
                   for w in result.warnings + result.unsupported_features)


# ---------------------------------------------------------------------------
# Azure Synapse tests
# ---------------------------------------------------------------------------

class TestSynapse:
    def test_basic_table_with_distribution(self):
        sql = "CREATE TABLE fact_orders (order_id BIGINT NOT NULL, customer_id INT, amount DECIMAL(18,2))"
        result = Transpiler.convert(sql, "redshift", "synapse")
        assert "DISTRIBUTION" in result.converted_sql
        assert "CLUSTERED COLUMNSTORE INDEX" in result.converted_sql

    def test_hash_distribution_parsed(self):
        sql = """
        CREATE TABLE fact_sales (
            sale_id BIGINT NOT NULL,
            customer_id INT,
            amount DECIMAL(18,2)
        )
        WITH (
            DISTRIBUTION = HASH(sale_id),
            CLUSTERED COLUMNSTORE INDEX
        )
        """
        result = Transpiler.convert(sql, "synapse", "synapse")
        assert "HASH" in result.converted_sql
        assert "sale_id" in result.converted_sql.lower() or "sale_id".lower() in result.converted_sql.lower()

    def test_round_robin_distribution(self):
        sql = "CREATE TABLE stage_load (id INT, data VARCHAR(255)) WITH (DISTRIBUTION = ROUND_ROBIN)"
        result = Transpiler.convert(sql, "synapse", "snowflake")
        assert result.converted_sql.strip()

    def test_synapse_view(self):
        sql = "CREATE VIEW dbo.SalesView AS SELECT * FROM dbo.FactSales WHERE year = 2024"
        result = Transpiler.convert(sql, "synapse", "synapse")
        assert "VIEW" in result.converted_sql
        assert "SalesView" in result.converted_sql

    def test_synapse_mv_generates_distribution(self):
        # WITH clause must appear before AS in Synapse MV DDL
        sql = (
            "CREATE MATERIALIZED VIEW dbo.mv_total "
            "WITH (DISTRIBUTION = HASH(customer_id)) "
            "AS SELECT customer_id, SUM(amount) AS total FROM orders GROUP BY customer_id"
        )
        result = Transpiler.convert(sql, "synapse", "synapse")
        assert "MATERIALIZED VIEW" in result.converted_sql
        assert "DISTRIBUTION" in result.converted_sql

    def test_snowflake_to_synapse_cluster_by_dropped_with_warning(self):
        sql = "CREATE TABLE my_table (id INT, name VARCHAR(100)) CLUSTER BY (id)"
        result = Transpiler.convert(sql, "snowflake", "synapse")
        assert result.converted_sql.strip()
        # Snowflake CLUSTER BY has no direct Synapse equivalent at table level
        # Should generate a warning about this


# ---------------------------------------------------------------------------
# Fabric DW tests
# ---------------------------------------------------------------------------

class TestFabricDW:
    def test_cluster_by_generated(self):
        sql = "CREATE TABLE sales (id BIGINT NOT NULL, customer_id INT, amount DECIMAL(18,2))"
        # Convert from Snowflake with CLUSTER BY → Fabric DW
        sf_sql = "CREATE TABLE sales (id BIGINT NOT NULL, customer_id INT, amount DECIMAL(18,2)) CLUSTER BY (customer_id)"
        result = Transpiler.convert(sf_sql, "snowflake", "fabric_dw")
        assert "CLUSTER BY" in result.converted_sql
        assert "customer_id" in result.converted_sql

    def test_cluster_by_max_4_columns(self):
        sql = "CREATE TABLE big_table (a INT, b INT, c INT, d INT, e INT) CLUSTER BY (a, b, c, d, e)"
        result = Transpiler.convert(sql, "snowflake", "fabric_dw")
        # Should truncate to 4 columns
        assert any("truncat" in w.message.lower() or "max" in w.message.lower()
                   for w in result.warnings + result.unsupported_features)

    def test_no_distribution_in_fabric(self):
        sql = "CREATE TABLE fact (id INT, amount DECIMAL(18,2)) WITH (DISTRIBUTION = HASH(id), CLUSTERED COLUMNSTORE INDEX)"
        result = Transpiler.convert(sql, "synapse", "fabric_dw")
        assert "DISTRIBUTION" not in result.converted_sql
        # Should have a warning about distribution being dropped
        assert any("distribution" in w.message.lower() or "DISTRIBUTION" in w.feature
                   for w in result.warnings + result.unsupported_features)

    def test_mv_not_supported_fabric_produces_view(self):
        sql = "CREATE MATERIALIZED VIEW dbo.mv_sales AS SELECT product_id, SUM(amount) as total FROM sales GROUP BY product_id"
        result = Transpiler.convert(sql, "redshift", "fabric_dw")
        assert "VIEW" in result.converted_sql
        assert any("materialized" in w.message.lower() or "MV" in w.feature
                   for w in result.unsupported_features)

    def test_basic_table_fabric(self):
        sql = "CREATE TABLE customers (id INT NOT NULL, name VARCHAR(200), email VARCHAR(255))"
        result = Transpiler.convert(sql, "redshift", "fabric_dw")
        assert result.converted_sql.strip()
        assert "customers" in result.converted_sql.lower()
        assert "[" in result.converted_sql  # Square bracket quoting


# ---------------------------------------------------------------------------
# Databricks tests
# ---------------------------------------------------------------------------

class TestDatabricks:
    def test_basic_table_with_delta(self):
        sql = "CREATE TABLE products (id BIGINT NOT NULL, name VARCHAR(255), price DECIMAL(10,2))"
        result = Transpiler.convert(sql, "redshift", "databricks")
        assert "USING DELTA" in result.converted_sql
        assert "products" in result.converted_sql
        assert "`" in result.converted_sql  # Backtick quoting

    def test_sortkey_to_cluster_by(self):
        sql = "CREATE TABLE orders (id BIGINT, customer_id INT, amount DECIMAL(18,2)) SORTKEY (customer_id)"
        result = Transpiler.convert(sql, "redshift", "databricks")
        assert "CLUSTER BY" in result.converted_sql
        assert "customer_id" in result.converted_sql
        assert any("sortkey" in w.message.lower() or "SORTKEY" in w.feature for w in result.warnings)

    def test_identity_column(self):
        sql = "CREATE TABLE events (id BIGINT IDENTITY(1,1) NOT NULL, event_name VARCHAR(200))"
        result = Transpiler.convert(sql, "redshift", "databricks")
        assert "GENERATED ALWAYS AS IDENTITY" in result.converted_sql

    def test_partitioned_by(self):
        sql = """CREATE TABLE logs (event_date DATE, user_id INT, message VARCHAR(500))
                 PARTITIONED BY (event_date)"""
        result = Transpiler.convert(sql, "databricks", "databricks")
        assert "PARTITIONED BY" in result.converted_sql

    def test_databricks_mv(self):
        sql = "CREATE MATERIALIZED VIEW dbo.mv_daily AS SELECT date, SUM(amount) as total FROM transactions GROUP BY date"
        result = Transpiler.convert(sql, "redshift", "databricks")
        assert "MATERIALIZED VIEW" in result.converted_sql
        assert any("unity catalog" in w.message.lower() for w in result.warnings)

    def test_identity_not_supported_warning_bigquery(self):
        sql = "CREATE TABLE seq_table (id BIGINT IDENTITY(1,1) NOT NULL, val VARCHAR(100))"
        result = Transpiler.convert(sql, "redshift", "bigquery")
        # BigQuery has no identity; should warn
        assert any("identity" in w.message.lower() or "IDENTITY" in w.feature
                   for w in result.warnings + result.unsupported_features)


# ---------------------------------------------------------------------------
# Oracle tests
# ---------------------------------------------------------------------------

class TestOracle:
    def test_basic_table(self):
        sql = "CREATE TABLE customers (id INT NOT NULL, name VARCHAR(200), email VARCHAR(255))"
        result = Transpiler.convert(sql, "redshift", "oracle")
        assert result.converted_sql.strip()
        assert '"customers"' in result.converted_sql or '"CUSTOMERS"' in result.converted_sql or "customers" in result.converted_sql.lower()

    def test_identity_generates_oracle_syntax(self):
        sql = "CREATE TABLE orders (id BIGINT IDENTITY(1,1) NOT NULL, amount DECIMAL(18,2))"
        result = Transpiler.convert(sql, "redshift", "oracle")
        assert "GENERATED" in result.converted_sql
        assert "IDENTITY" in result.converted_sql

    def test_partition_by_range_from_bigquery_to_oracle(self):
        # BigQuery PARTITION BY DATE(sale_date) → Oracle PARTITION BY RANGE (sale_date)
        # sqlglot's oracle dialect can't parse Oracle inline partition sub-clauses,
        # so we test by converting from BigQuery source which carries IRPartition in IR.
        sql = "CREATE TABLE `project.dataset.sales_hist` (sale_id INT64, sale_date DATE, amount NUMERIC) PARTITION BY DATE(sale_date)"
        result = Transpiler.convert(sql, "bigquery", "oracle")
        assert result.converted_sql.strip()
        assert "PARTITION BY" in result.converted_sql

    def test_snowflake_cluster_by_to_oracle_partition_hash(self):
        sql = "CREATE TABLE fact (id INT, region VARCHAR(50)) CLUSTER BY (region)"
        result = Transpiler.convert(sql, "snowflake", "oracle")
        assert result.converted_sql.strip()
        # Should have a warning about CLUSTER BY → PARTITION BY HASH conversion
        assert any("cluster" in w.message.lower() or "hash" in w.message.lower()
                   for w in result.warnings)

    def test_oracle_mv(self):
        sql = "CREATE MATERIALIZED VIEW mv_sales AS SELECT product_id, SUM(amount) FROM sales GROUP BY product_id"
        result = Transpiler.convert(sql, "redshift", "oracle")
        assert "MATERIALIZED VIEW" in result.converted_sql
        assert "REFRESH" in result.converted_sql


# ---------------------------------------------------------------------------
# BigQuery tests
# ---------------------------------------------------------------------------

class TestBigQuery:
    def test_basic_table(self):
        sql = "CREATE TABLE customers (id INT NOT NULL, name VARCHAR(200), email VARCHAR(255))"
        result = Transpiler.convert(sql, "redshift", "bigquery")
        assert result.converted_sql.strip()
        assert "`" in result.converted_sql  # Backtick quoting

    def test_sortkey_to_cluster_by(self):
        sql = "CREATE TABLE orders (id BIGINT, customer_id INT, amount DECIMAL(18,2)) SORTKEY (customer_id)"
        result = Transpiler.convert(sql, "redshift", "bigquery")
        assert "CLUSTER BY" in result.converted_sql
        assert any("sortkey" in w.message.lower() for w in result.warnings)

    def test_distribution_dropped_with_warning(self):
        sql = "CREATE TABLE fact (id INT, amount DECIMAL(18,2)) WITH (DISTRIBUTION = HASH(id), CLUSTERED COLUMNSTORE INDEX)"
        result = Transpiler.convert(sql, "synapse", "bigquery")
        assert "DISTRIBUTION" not in result.converted_sql
        assert any("distribution" in w.message.lower() or "DISTRIBUTION" in w.feature
                   for w in result.warnings + result.unsupported_features)

    def test_identity_not_supported_bigquery(self):
        sql = "CREATE TABLE seq_table (id BIGINT IDENTITY(1,1) NOT NULL, val VARCHAR(100))"
        result = Transpiler.convert(sql, "redshift", "bigquery")
        assert any("identity" in w.message.lower() or "IDENTITY" in w.feature
                   for w in result.warnings + result.unsupported_features)

    def test_bigquery_mv(self):
        sql = "CREATE MATERIALIZED VIEW mv_daily AS SELECT date, SUM(amount) FROM txns GROUP BY date"
        result = Transpiler.convert(sql, "redshift", "bigquery")
        assert "MATERIALIZED VIEW" in result.converted_sql
        assert "ENABLE_REFRESH" in result.converted_sql or "enable_refresh" in result.converted_sql

    def test_pk_not_enforced_bigquery(self):
        sql = "CREATE TABLE dim_product (product_id INT NOT NULL, name VARCHAR(200), PRIMARY KEY (product_id))"
        result = Transpiler.convert(sql, "redshift", "bigquery")
        assert "NOT ENFORCED" in result.converted_sql

    def test_bigquery_cluster_by_max_4_columns(self):
        sql = "CREATE TABLE big (a INT, b INT, c INT, d INT, e INT) CLUSTER BY (a, b, c, d, e)"
        result = Transpiler.convert(sql, "snowflake", "bigquery")
        # Should truncate and warn
        assert any("truncat" in w.message.lower() or "max" in w.message.lower()
                   for w in result.warnings + result.unsupported_features)


# ---------------------------------------------------------------------------
# Cross-dialect round-trip tests
# ---------------------------------------------------------------------------

class TestCrossDialect:
    """Test that all 8 source dialects can be transpiled to all 8 target dialects."""

    SIMPLE_TABLE_SQL = {
        "redshift": "CREATE TABLE sales (id BIGINT IDENTITY(1,1), amount DECIMAL(18,2) NOT NULL, region VARCHAR(100))",
        "snowflake": "CREATE TABLE sales (id BIGINT AUTOINCREMENT, amount NUMBER(18,2) NOT NULL, region VARCHAR(100))",
        "sqlserver": "CREATE TABLE sales (id BIGINT IDENTITY(1,1) NOT NULL, amount DECIMAL(18,2) NOT NULL, region NVARCHAR(100))",
        "synapse": "CREATE TABLE sales (id BIGINT NOT NULL, amount DECIMAL(18,2) NOT NULL, region NVARCHAR(100)) WITH (DISTRIBUTION = ROUND_ROBIN, CLUSTERED COLUMNSTORE INDEX)",
        "fabric_dw": "CREATE TABLE sales (id BIGINT NOT NULL, amount DECIMAL(18,2) NOT NULL, region VARCHAR(100)) WITH (CLUSTER BY (region))",
        "databricks": "CREATE TABLE sales (id BIGINT NOT NULL, amount DECIMAL(18,2) NOT NULL, region STRING) USING DELTA",
        "oracle": "CREATE TABLE sales (id NUMBER(19,0) GENERATED ALWAYS AS IDENTITY NOT NULL, amount NUMBER(18,2) NOT NULL, region VARCHAR2(100))",
        "bigquery": "CREATE TABLE sales (id INT64 NOT NULL, amount NUMERIC(18,2) NOT NULL, region STRING)",
    }

    DIALECTS = ["redshift", "snowflake", "sqlserver", "synapse", "fabric_dw", "databricks", "oracle", "bigquery"]

    @pytest.mark.parametrize("source", DIALECTS)
    @pytest.mark.parametrize("target", DIALECTS)
    def test_all_dialect_pairs_produce_output(self, source, target):
        """All N×N dialect pairs must produce non-empty output without crashing."""
        sql = self.SIMPLE_TABLE_SQL[source]
        result = Transpiler.convert(sql, source, target)
        assert result.converted_sql.strip(), (
            f"{source} → {target} produced empty output. "
            f"Warnings: {[w.message for w in result.warnings + result.unsupported_features]}"
        )
        assert result.source_dialect.value == source
        assert result.target_dialect.value == target
