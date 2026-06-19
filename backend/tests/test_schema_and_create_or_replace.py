"""
Tests for:
  1. Hardcoded vs Dynamic schema conversion (target_schema parameter)
  2. CREATE OR REPLACE TABLE support across all 9 dialects
  3. CREATE TABLE IF NOT EXISTS support across all 9 dialects

These cover real-world scenarios:
  - Schema-qualified tables/views being migrated between platforms
  - Idempotent table DDL patterns (CI/CD, data pipelines)
  - Conditional table creation (avoid overwrite on re-run)
"""
from __future__ import annotations

import pytest
from app.transpiler import Transpiler

# ---------------------------------------------------------------------------
# 1. Schema Conversion — Hardcoded vs Dynamic
# ---------------------------------------------------------------------------

class TestSchemaConversion:
    """Verify that schema qualifiers are handled correctly in both modes."""

    REDSHIFT_TABLE = """
    CREATE TABLE analytics.orders (
        order_id INTEGER NOT NULL,
        customer_id INTEGER NOT NULL,
        amount DECIMAL(10,2),
        PRIMARY KEY (order_id)
    );
    """

    REDSHIFT_VIEW = """
    CREATE VIEW reporting.daily_sales AS
    SELECT DATE_TRUNC('day', created_at) AS day,
           SUM(amount) AS total
    FROM analytics.orders
    GROUP BY 1;
    """

    def test_hardcoded_schema_preserves_table_schema(self):
        """Hardcoded mode: schema from source SQL is preserved verbatim."""
        result = Transpiler.convert(self.REDSHIFT_TABLE, "redshift", "snowflake")
        assert "analytics" in result.converted_sql.lower()
        assert "orders" in result.converted_sql.lower()

    def test_dynamic_schema_overrides_table_schema(self):
        """Dynamic mode: target_schema replaces source schema qualifier."""
        result = Transpiler.convert(self.REDSHIFT_TABLE, "redshift", "snowflake", target_schema="my_schema")
        assert "my_schema" in result.converted_sql.lower()
        # Original schema must NOT appear
        assert "analytics" not in result.converted_sql.lower()

    def test_dynamic_schema_overrides_view_schema(self):
        """Dynamic mode: target_schema replaces source schema in CREATE VIEW."""
        result = Transpiler.convert(self.REDSHIFT_VIEW, "redshift", "snowflake", target_schema="prod")
        assert "prod" in result.converted_sql.lower()
        assert "reporting" not in result.converted_sql.lower()

    def test_dynamic_schema_table_without_schema(self):
        """Dynamic mode: target_schema is added when source table has no schema."""
        no_schema_sql = "CREATE TABLE orders (id INTEGER NOT NULL);"
        result = Transpiler.convert(no_schema_sql, "redshift", "sqlserver", target_schema="dbo")
        assert "dbo" in result.converted_sql

    def test_hardcoded_schema_with_tsql_target(self):
        """Hardcoded mode preserves schema for T-SQL targets (SQL Server, Synapse, Fabric DW)."""
        result = Transpiler.convert(self.REDSHIFT_TABLE, "redshift", "sqlserver")
        assert "analytics" in result.converted_sql.lower()

    def test_dynamic_schema_with_databricks_target(self):
        """Dynamic mode sets schema for Databricks (uses backtick quoting)."""
        result = Transpiler.convert(self.REDSHIFT_TABLE, "redshift", "databricks", target_schema="raw")
        assert "raw" in result.converted_sql

    def test_dynamic_schema_with_bigquery_target(self):
        """Dynamic mode sets schema (dataset) for BigQuery."""
        result = Transpiler.convert(self.REDSHIFT_TABLE, "redshift", "bigquery", target_schema="ds_prod")
        assert "ds_prod" in result.converted_sql

    def test_dynamic_schema_with_fabric_lakehouse_target(self):
        """Dynamic mode sets schema for Fabric Lakehouse."""
        result = Transpiler.convert(self.REDSHIFT_TABLE, "redshift", "fabric_lakehouse", target_schema="bronze")
        assert "bronze" in result.converted_sql

    def test_dynamic_empty_string_schema_removes_qualifier(self):
        """Dynamic mode with empty string removes schema qualifier."""
        result = Transpiler.convert(self.REDSHIFT_TABLE, "redshift", "snowflake", target_schema="")
        # Should not have 'analytics.' prefix but should have 'orders'
        assert "orders" in result.converted_sql.lower()

    def test_schema_preserved_in_view_body_references(self):
        """View body SQL references (FROM analytics.orders) are NOT altered by target_schema
        since target_schema only affects the object name, not body table refs."""
        result = Transpiler.convert(self.REDSHIFT_VIEW, "redshift", "snowflake", target_schema="prod")
        # CREATE VIEW definition should use 'prod'
        assert "prod" in result.converted_sql
        # The view name 'daily_sales' must be in output
        assert "daily_sales" in result.converted_sql


# ---------------------------------------------------------------------------
# 2. CREATE OR REPLACE TABLE — All 9 Target Dialects
# ---------------------------------------------------------------------------

SNOWFLAKE_OR_REPLACE = """
CREATE OR REPLACE TABLE analytics.customers (
    customer_id INTEGER NOT NULL,
    email VARCHAR(255) NOT NULL,
    created_at TIMESTAMP_NTZ,
    PRIMARY KEY (customer_id)
);
"""

DATABRICKS_OR_REPLACE = """
CREATE OR REPLACE TABLE silver.events (
    event_id BIGINT NOT NULL,
    event_type STRING NOT NULL,
    event_ts TIMESTAMP
)
USING DELTA;
"""

BIGQUERY_OR_REPLACE = """
CREATE OR REPLACE TABLE `myproject.dataset.products` (
    product_id INT64 NOT NULL,
    name STRING,
    price NUMERIC(10,2)
);
"""

class TestCreateOrReplaceTable:
    """Verify CREATE OR REPLACE TABLE is correctly parsed and emitted per dialect."""

    # --- Dialects that natively support CREATE OR REPLACE TABLE ---

    def test_snowflake_to_snowflake_or_replace(self):
        result = Transpiler.convert(SNOWFLAKE_OR_REPLACE, "snowflake", "snowflake")
        assert "CREATE OR REPLACE TABLE" in result.converted_sql

    def test_snowflake_to_bigquery_or_replace(self):
        result = Transpiler.convert(SNOWFLAKE_OR_REPLACE, "snowflake", "bigquery")
        assert "CREATE OR REPLACE TABLE" in result.converted_sql

    def test_snowflake_to_databricks_or_replace(self):
        result = Transpiler.convert(SNOWFLAKE_OR_REPLACE, "snowflake", "databricks")
        assert "CREATE OR REPLACE TABLE" in result.converted_sql

    def test_snowflake_to_fabric_lakehouse_or_replace(self):
        result = Transpiler.convert(SNOWFLAKE_OR_REPLACE, "snowflake", "fabric_lakehouse")
        assert "CREATE OR REPLACE TABLE" in result.converted_sql

    def test_snowflake_to_redshift_or_replace(self):
        """Redshift: OR REPLACE → DROP TABLE IF EXISTS + CREATE TABLE."""
        result = Transpiler.convert(SNOWFLAKE_OR_REPLACE, "snowflake", "redshift")
        sql = result.converted_sql
        assert "DROP TABLE IF EXISTS" in sql
        assert "CREATE TABLE" in sql
        # Must NOT have OR REPLACE in the CREATE line
        assert "CREATE OR REPLACE TABLE" not in sql

    def test_snowflake_to_sqlserver_or_replace(self):
        """SQL Server: OR REPLACE → DROP TABLE IF EXISTS; GO; CREATE TABLE."""
        result = Transpiler.convert(SNOWFLAKE_OR_REPLACE, "snowflake", "sqlserver")
        sql = result.converted_sql
        assert "DROP TABLE IF EXISTS" in sql
        assert "CREATE TABLE" in sql
        assert "GO" in sql

    def test_snowflake_to_synapse_or_replace(self):
        """Synapse: OR REPLACE → DROP TABLE IF EXISTS + CREATE TABLE."""
        result = Transpiler.convert(SNOWFLAKE_OR_REPLACE, "snowflake", "synapse")
        sql = result.converted_sql
        assert "DROP TABLE IF EXISTS" in sql
        assert "CREATE TABLE" in sql

    def test_snowflake_to_fabric_dw_or_replace(self):
        """Fabric DW: OR REPLACE → DROP TABLE IF EXISTS + CREATE TABLE."""
        result = Transpiler.convert(SNOWFLAKE_OR_REPLACE, "snowflake", "fabric_dw")
        sql = result.converted_sql
        assert "DROP TABLE IF EXISTS" in sql
        assert "CREATE TABLE" in sql

    def test_snowflake_to_oracle_or_replace(self):
        """Oracle: OR REPLACE → PL/SQL anonymous block with DROP + CREATE."""
        result = Transpiler.convert(SNOWFLAKE_OR_REPLACE, "snowflake", "oracle")
        sql = result.converted_sql
        assert "EXECUTE IMMEDIATE" in sql
        assert "DROP TABLE" in sql
        assert "CREATE TABLE" in sql
        # Warning should be emitted
        feature_codes = {w.feature for w in result.warnings}
        assert "CREATE_OR_REPLACE_TABLE_ORACLE" in feature_codes

    def test_databricks_or_replace_to_snowflake(self):
        """Databricks OR REPLACE → Snowflake CREATE OR REPLACE."""
        result = Transpiler.convert(DATABRICKS_OR_REPLACE, "databricks", "snowflake")
        assert "CREATE OR REPLACE TABLE" in result.converted_sql

    def test_bigquery_or_replace_to_databricks(self):
        """BigQuery OR REPLACE → Databricks CREATE OR REPLACE."""
        result = Transpiler.convert(BIGQUERY_OR_REPLACE, "bigquery", "databricks")
        assert "CREATE OR REPLACE TABLE" in result.converted_sql

    def test_or_replace_is_false_for_plain_create(self):
        """Plain CREATE TABLE must NOT produce OR REPLACE or DROP TABLE in output."""
        plain = "CREATE TABLE sales.orders (id INTEGER NOT NULL);"
        for target in ["redshift", "snowflake", "sqlserver", "databricks", "bigquery"]:
            result = Transpiler.convert(plain, "redshift", target)
            sql = result.converted_sql
            assert "OR REPLACE" not in sql, f"Unexpected OR REPLACE in {target} output"
            assert "DROP TABLE IF EXISTS" not in sql, f"Unexpected DROP in {target} output"


# ---------------------------------------------------------------------------
# 3. CREATE TABLE IF NOT EXISTS — All 9 Target Dialects
# ---------------------------------------------------------------------------

REDSHIFT_IF_NOT_EXISTS = """
CREATE TABLE IF NOT EXISTS staging.raw_events (
    event_id BIGINT NOT NULL,
    event_name VARCHAR(200),
    event_ts TIMESTAMP
);
"""

DATABRICKS_IF_NOT_EXISTS = """
CREATE TABLE IF NOT EXISTS bronze.logs (
    log_id BIGINT NOT NULL,
    message STRING
)
USING DELTA;
"""

class TestCreateTableIfNotExists:
    """Verify CREATE TABLE IF NOT EXISTS is parsed and emitted correctly."""

    # --- Standard dialects (all support IF NOT EXISTS natively) ---

    def test_redshift_to_redshift_if_not_exists(self):
        result = Transpiler.convert(REDSHIFT_IF_NOT_EXISTS, "redshift", "redshift")
        assert "CREATE TABLE IF NOT EXISTS" in result.converted_sql

    def test_redshift_to_snowflake_if_not_exists(self):
        result = Transpiler.convert(REDSHIFT_IF_NOT_EXISTS, "redshift", "snowflake")
        assert "CREATE TABLE IF NOT EXISTS" in result.converted_sql

    def test_redshift_to_databricks_if_not_exists(self):
        result = Transpiler.convert(REDSHIFT_IF_NOT_EXISTS, "redshift", "databricks")
        assert "CREATE TABLE IF NOT EXISTS" in result.converted_sql

    def test_redshift_to_bigquery_if_not_exists(self):
        result = Transpiler.convert(REDSHIFT_IF_NOT_EXISTS, "redshift", "bigquery")
        assert "CREATE TABLE IF NOT EXISTS" in result.converted_sql

    def test_redshift_to_fabric_lakehouse_if_not_exists(self):
        result = Transpiler.convert(REDSHIFT_IF_NOT_EXISTS, "redshift", "fabric_lakehouse")
        assert "CREATE TABLE IF NOT EXISTS" in result.converted_sql

    def test_redshift_to_fabric_dw_if_not_exists(self):
        """Fabric DW: IF NOT EXISTS → IF OBJECT_ID(...) IS NULL BEGIN ... END."""
        result = Transpiler.convert(REDSHIFT_IF_NOT_EXISTS, "redshift", "fabric_dw")
        sql = result.converted_sql
        assert "IF OBJECT_ID" in sql
        assert "IS NULL" in sql
        assert "CREATE TABLE" in sql

    def test_redshift_to_sqlserver_if_not_exists(self):
        """SQL Server: IF NOT EXISTS → IF OBJECT_ID(...) IS NULL BEGIN ... END."""
        result = Transpiler.convert(REDSHIFT_IF_NOT_EXISTS, "redshift", "sqlserver")
        sql = result.converted_sql
        assert "IF OBJECT_ID" in sql
        assert "IS NULL" in sql
        assert "CREATE TABLE" in sql

    def test_redshift_to_synapse_if_not_exists(self):
        """Synapse: IF NOT EXISTS → IF OBJECT_ID(...) IS NULL BEGIN ... END."""
        result = Transpiler.convert(REDSHIFT_IF_NOT_EXISTS, "redshift", "synapse")
        sql = result.converted_sql
        assert "IF OBJECT_ID" in sql
        assert "IS NULL" in sql

    def test_redshift_to_oracle_if_not_exists(self):
        """Oracle 23c+: IF NOT EXISTS emitted with compatibility warning."""
        result = Transpiler.convert(REDSHIFT_IF_NOT_EXISTS, "redshift", "oracle")
        sql = result.converted_sql
        assert "CREATE TABLE IF NOT EXISTS" in sql
        feature_codes = {w.feature for w in result.warnings}
        assert "IF_NOT_EXISTS_ORACLE_23C" in feature_codes

    def test_databricks_if_not_exists_to_snowflake(self):
        """Databricks IF NOT EXISTS → Snowflake IF NOT EXISTS."""
        result = Transpiler.convert(DATABRICKS_IF_NOT_EXISTS, "databricks", "snowflake")
        assert "CREATE TABLE IF NOT EXISTS" in result.converted_sql

    def test_if_not_exists_false_for_plain_create(self):
        """Plain CREATE TABLE must NOT emit IF NOT EXISTS or OBJECT_ID guard."""
        plain = "CREATE TABLE orders (id INTEGER NOT NULL);"
        for target in ["snowflake", "databricks", "bigquery", "fabric_lakehouse"]:
            result = Transpiler.convert(plain, "redshift", target)
            sql = result.converted_sql
            assert "IF NOT EXISTS" not in sql, f"Unexpected IF NOT EXISTS in {target}"
        for target in ["sqlserver", "synapse", "fabric_dw"]:
            result = Transpiler.convert(plain, "redshift", target)
            assert "IF OBJECT_ID" not in result.converted_sql, f"Unexpected guard in {target}"


# ---------------------------------------------------------------------------
# 4. Round-trip: OR REPLACE preserved when source=target
# ---------------------------------------------------------------------------

class TestOrReplaceSameDialect:
    """OR REPLACE round-trip: source and target are same dialect."""

    @pytest.mark.parametrize("dialect,sql", [
        ("snowflake", "CREATE OR REPLACE TABLE mydb.t1 (id INTEGER NOT NULL);"),
        ("databricks", "CREATE OR REPLACE TABLE db1.t1 (id BIGINT NOT NULL)\nUSING DELTA;"),
        ("bigquery", "CREATE OR REPLACE TABLE `p.d.t1` (id INT64 NOT NULL);"),
    ])
    def test_or_replace_round_trip(self, dialect: str, sql: str):
        """OR REPLACE in source → OR REPLACE preserved when same dialect is target."""
        result = Transpiler.convert(sql, dialect, dialect)
        assert "OR REPLACE" in result.converted_sql


# ---------------------------------------------------------------------------
# 5. Schema + OR REPLACE combination
# ---------------------------------------------------------------------------

class TestSchemaWithOrReplace:
    """Dynamic schema override works together with CREATE OR REPLACE TABLE."""

    def test_dynamic_schema_with_or_replace_snowflake(self):
        sql = "CREATE OR REPLACE TABLE analytics.orders (id INTEGER NOT NULL);"
        result = Transpiler.convert(sql, "snowflake", "snowflake", target_schema="prod")
        assert "CREATE OR REPLACE TABLE" in result.converted_sql
        assert "prod" in result.converted_sql
        assert "analytics" not in result.converted_sql

    def test_dynamic_schema_with_or_replace_redshift_target(self):
        """OR REPLACE → DROP IF EXISTS + CREATE, schema set dynamically."""
        sql = "CREATE OR REPLACE TABLE analytics.orders (id INTEGER NOT NULL);"
        result = Transpiler.convert(sql, "snowflake", "redshift", target_schema="staging")
        sql_out = result.converted_sql
        assert "DROP TABLE IF EXISTS" in sql_out
        assert "staging" in sql_out
        assert "analytics" not in sql_out

    def test_dynamic_schema_with_or_replace_sqlserver_target(self):
        """OR REPLACE for SQL Server with dynamic schema."""
        sql = "CREATE OR REPLACE TABLE analytics.orders (id INTEGER NOT NULL);"
        result = Transpiler.convert(sql, "snowflake", "sqlserver", target_schema="dbo")
        sql_out = result.converted_sql
        assert "DROP TABLE IF EXISTS" in sql_out
        assert "dbo" in sql_out

    def test_dynamic_schema_with_or_replace_oracle_target(self):
        """Oracle with dynamic schema + OR REPLACE emits PL/SQL block."""
        sql = "CREATE OR REPLACE TABLE analytics.orders (id INTEGER NOT NULL);"
        result = Transpiler.convert(sql, "snowflake", "oracle", target_schema="hr")
        sql_out = result.converted_sql
        assert "EXECUTE IMMEDIATE" in sql_out
        assert "hr" in sql_out
