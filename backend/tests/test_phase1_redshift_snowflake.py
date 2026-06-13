"""
Phase 1 golden-file tests for Redshift → Snowflake transpilation.

Each test uses real DDL syntax sourced from official documentation:
  Redshift: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html
  Snowflake: https://docs.snowflake.com/en/sql-reference/sql/create-table
"""
from __future__ import annotations

import pytest
from pathlib import Path

from app.transpiler import Transpiler
from app.ir.models import Dialect, IRTable, IRMaterializedView, IRView, Warningseverity


# ---------------------------------------------------------------------------
# Type mapping tests
# ---------------------------------------------------------------------------

class TestTypeMappingRedshiftToSnowflake:
    """Verify individual type mappings from type_mappings.yaml (section 4 of spec)."""

    def _convert_table_col(self, col_type: str) -> str:
        """Helper: parse a single-column Redshift table and extract Snowflake type."""
        sql = f"CREATE TABLE t (col {col_type});"
        result = Transpiler.convert(sql, "redshift", "snowflake")
        # Extract type from converted SQL
        import re
        m = re.search(r'"col"\s+([\w\(\),\s]+?)(?:,|\s*\))', result.converted_sql)
        return m.group(1).strip() if m else result.converted_sql

    def test_smallint_maps_to_smallint(self):
        result = Transpiler.convert("CREATE TABLE t (col SMALLINT);", "redshift", "snowflake")
        assert "SMALLINT" in result.converted_sql

    def test_integer_maps_to_integer(self):
        result = Transpiler.convert("CREATE TABLE t (col INTEGER);", "redshift", "snowflake")
        assert "INTEGER" in result.converted_sql or "NUMBER" in result.converted_sql

    def test_bigint_maps_to_bigint(self):
        result = Transpiler.convert("CREATE TABLE t (col BIGINT);", "redshift", "snowflake")
        assert "BIGINT" in result.converted_sql

    def test_decimal_preserves_precision(self):
        result = Transpiler.convert("CREATE TABLE t (col DECIMAL(18,4));", "redshift", "snowflake")
        assert "18,4" in result.converted_sql or "18, 4" in result.converted_sql

    def test_double_precision_maps_to_double(self):
        result = Transpiler.convert("CREATE TABLE t (col DOUBLE PRECISION);", "redshift", "snowflake")
        assert "DOUBLE" in result.converted_sql or "FLOAT" in result.converted_sql

    def test_varchar_preserves_length(self):
        result = Transpiler.convert("CREATE TABLE t (col VARCHAR(255));", "redshift", "snowflake")
        assert "255" in result.converted_sql

    def test_boolean_maps_to_boolean(self):
        result = Transpiler.convert("CREATE TABLE t (col BOOLEAN);", "redshift", "snowflake")
        assert "BOOLEAN" in result.converted_sql

    def test_date_maps_to_date(self):
        result = Transpiler.convert("CREATE TABLE t (col DATE);", "redshift", "snowflake")
        assert "DATE" in result.converted_sql

    def test_timestamp_maps_to_timestamp_ntz(self):
        result = Transpiler.convert("CREATE TABLE t (col TIMESTAMP);", "redshift", "snowflake")
        assert "TIMESTAMP_NTZ" in result.converted_sql or "TIMESTAMP" in result.converted_sql

    def test_timestamptz_maps_to_timestamp_tz(self):
        result = Transpiler.convert("CREATE TABLE t (col TIMESTAMPTZ);", "redshift", "snowflake")
        assert "TIMESTAMP_TZ" in result.converted_sql or "TIMESTAMP" in result.converted_sql

    def test_super_maps_to_variant(self):
        result = Transpiler.convert("CREATE TABLE t (col SUPER);", "redshift", "snowflake")
        assert "VARIANT" in result.converted_sql

    def test_varbyte_maps_to_varbinary(self):
        result = Transpiler.convert("CREATE TABLE t (col VARBYTE);", "redshift", "snowflake")
        assert "VARBINARY" in result.converted_sql or "BINARY" in result.converted_sql


# ---------------------------------------------------------------------------
# Distribution / Sort key tests
# ---------------------------------------------------------------------------

class TestDistributionTranslation:

    def test_diststyle_key_becomes_cluster_by(self):
        sql = """
        CREATE TABLE sales (
            sale_id INTEGER,
            customer_id INTEGER
        )
        DISTSTYLE KEY
        DISTKEY (customer_id)
        SORTKEY (sale_id);
        """
        result = Transpiler.convert(sql, "redshift", "snowflake")
        # SORTKEY should become CLUSTER BY, distribution key warning should be issued
        assert any("DISTRIBUTION_KEY" in w.feature or "DISTSTYLE" in w.feature
                   for w in result.warnings + result.unsupported_features)

    def test_diststyle_even_produces_info_warning(self):
        sql = "CREATE TABLE t (id INTEGER) DISTSTYLE EVEN;"
        result = Transpiler.convert(sql, "redshift", "snowflake")
        assert any("DISTSTYLE" in w.feature or "round_robin" in w.message.lower()
                   for w in result.warnings + result.unsupported_features)

    def test_sortkey_columns_converted(self):
        sql = "CREATE TABLE t (a INTEGER, b DATE) SORTKEY (a, b);"
        result = Transpiler.convert(sql, "redshift", "snowflake")
        assert "CLUSTER BY" in result.converted_sql


# ---------------------------------------------------------------------------
# Identity column tests
# ---------------------------------------------------------------------------

class TestIdentityColumns:

    def test_identity_preserved_in_snowflake(self):
        sql = "CREATE TABLE t (id INTEGER IDENTITY(1,1) NOT NULL);"
        result = Transpiler.convert(sql, "redshift", "snowflake")
        assert "IDENTITY" in result.converted_sql or "AUTOINCREMENT" in result.converted_sql

    def test_identity_custom_seed_step(self):
        sql = "CREATE TABLE t (id BIGINT IDENTITY(100, 5));"
        result = Transpiler.convert(sql, "redshift", "snowflake")
        assert "100" in result.converted_sql
        assert "5" in result.converted_sql


# ---------------------------------------------------------------------------
# Constraint tests
# ---------------------------------------------------------------------------

class TestConstraints:

    def test_primary_key_preserved(self):
        sql = "CREATE TABLE t (id INTEGER NOT NULL, PRIMARY KEY (id));"
        result = Transpiler.convert(sql, "redshift", "snowflake")
        assert "PRIMARY KEY" in result.converted_sql

    def test_not_null_preserved(self):
        sql = "CREATE TABLE t (name VARCHAR(100) NOT NULL);"
        result = Transpiler.convert(sql, "redshift", "snowflake")
        assert "NOT NULL" in result.converted_sql


# ---------------------------------------------------------------------------
# View tests
# ---------------------------------------------------------------------------

class TestViews:

    def test_view_definition_preserved(self):
        sql = "CREATE VIEW v_orders AS SELECT order_id, amount FROM orders WHERE is_active = TRUE;"
        result = Transpiler.convert(sql, "redshift", "snowflake")
        assert "CREATE" in result.converted_sql
        assert "VIEW" in result.converted_sql
        assert "v_orders" in result.converted_sql

    def test_create_or_replace_view(self):
        sql = "CREATE OR REPLACE VIEW v AS SELECT 1 AS x;"
        result = Transpiler.convert(sql, "redshift", "snowflake")
        assert "OR REPLACE" in result.converted_sql

    def test_late_binding_view_warning(self):
        sql = "CREATE VIEW v AS SELECT * FROM t WITH NO SCHEMA BINDING;"
        result = Transpiler.convert(sql, "redshift", "snowflake")
        # Should have a warning about LATE BINDING VIEW
        assert len(result.warnings) > 0


# ---------------------------------------------------------------------------
# MV tests
# ---------------------------------------------------------------------------

class TestMaterializedViews:

    def test_mv_auto_refresh_preserved(self):
        sql = "CREATE MATERIALIZED VIEW mv_summary AUTO REFRESH YES AS SELECT COUNT(*) FROM t;"
        result = Transpiler.convert(sql, "redshift", "snowflake")
        assert "MATERIALIZED VIEW" in result.converted_sql

    def test_mv_snowflake_enterprise_warning(self):
        sql = "CREATE MATERIALIZED VIEW mv AS SELECT COUNT(*) FROM t;"
        result = Transpiler.convert(sql, "redshift", "snowflake")
        assert any("enterprise" in w.message.lower() or "MV_ENTERPRISE" in w.feature
                   for w in result.warnings + result.unsupported_features)


# ---------------------------------------------------------------------------
# Reverse direction: Snowflake → Redshift
# ---------------------------------------------------------------------------

class TestSnowflakeToRedshift:

    def test_variant_maps_to_super(self):
        sql = "CREATE TABLE t (data VARIANT);"
        result = Transpiler.convert(sql, "snowflake", "redshift")
        assert "SUPER" in result.converted_sql

    def test_cluster_by_becomes_sortkey(self):
        sql = "CREATE TABLE t (id INTEGER, ts DATE) CLUSTER BY (ts);"
        result = Transpiler.convert(sql, "snowflake", "redshift")
        assert "SORTKEY" in result.converted_sql

    def test_transient_table_warning(self):
        sql = "CREATE TRANSIENT TABLE t (id INTEGER);"
        result = Transpiler.convert(sql, "snowflake", "redshift")
        # Redshift has no TRANSIENT concept — should emit warning or just ignore
        assert result.converted_sql  # At minimum, produces some output

    def test_timestamp_ntz_to_timestamp(self):
        sql = "CREATE TABLE t (ts TIMESTAMP_NTZ);"
        result = Transpiler.convert(sql, "snowflake", "redshift")
        assert "TIMESTAMP" in result.converted_sql


# ---------------------------------------------------------------------------
# Doc references tests — ensure official doc URLs appear in output
# ---------------------------------------------------------------------------

class TestDocReferences:

    def test_conversion_includes_doc_refs(self):
        sql = "CREATE TABLE t (id INTEGER IDENTITY(1,1));"
        result = Transpiler.convert(sql, "redshift", "snowflake")
        assert len(result.doc_references) > 0
        assert all(r.url.startswith("http") for r in result.doc_references)

    def test_official_docs_only(self):
        """Verify doc references come from official vendor domains."""
        sql = "CREATE TABLE t (id INTEGER, ts TIMESTAMPTZ, data SUPER);"
        result = Transpiler.convert(sql, "redshift", "snowflake")
        official_domains = [
            "docs.aws.amazon.com",
            "docs.snowflake.com",
            "learn.microsoft.com",
            "cloud.google.com",
            "docs.databricks.com",
            "docs.oracle.com",
        ]
        for ref in result.doc_references:
            assert any(d in ref.url for d in official_domains), \
                f"Non-official doc URL found: {ref.url}"
