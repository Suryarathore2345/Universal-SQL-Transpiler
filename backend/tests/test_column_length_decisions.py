"""
Tests for the opt-in column-length-decisions feature:
  - Databricks/BigQuery/Fabric Lakehouse bare STRING must reverse-classify as
    GenericType.TEXT (not VARCHAR/CHAR with length=None), fixing invalid
    length-less DDL (e.g. "VARCHAR" with no length) on Fabric DW/Synapse/
    Redshift/SQL Server targets.
  - TranspileResult.length_decisions surfaces unresolved defaults per column.
  - Transpiler.convert(column_overrides=...) and default_text_length let a
    caller pick a length instead of the dialect default, with zero change in
    behavior when neither is supplied.
"""
from __future__ import annotations

from app.dialects.base import TypeMapper
from app.ir.models import Dialect, GenericType
from app.transpiler import Transpiler


def _mapper() -> TypeMapper:
    TypeMapper.reset()
    return TypeMapper.get()


class TestReverseClassification:
    def test_databricks_bare_string_is_text(self):
        g, _, _, length = _mapper().source_type_to_generic(Dialect.DATABRICKS, "STRING")
        assert g == GenericType.TEXT
        assert length is None

    def test_databricks_explicit_varchar_length_still_varchar(self):
        g, _, _, length = _mapper().source_type_to_generic(Dialect.DATABRICKS, "VARCHAR(50)")
        assert g == GenericType.VARCHAR
        assert length == 50

    def test_bigquery_bare_string_is_text(self):
        g, _, _, _ = _mapper().source_type_to_generic(Dialect.BIGQUERY, "STRING")
        assert g == GenericType.TEXT

    def test_fabric_lakehouse_bare_string_is_text(self):
        g, _, _, _ = _mapper().source_type_to_generic(Dialect.FABRIC_LAKEHOUSE, "STRING")
        assert g == GenericType.TEXT

    def test_fabric_lakehouse_explicit_char_length_still_char(self):
        g, _, _, length = _mapper().source_type_to_generic(Dialect.FABRIC_LAKEHOUSE, "CHAR(10)")
        assert g == GenericType.CHAR
        assert length == 10

    def test_snowflake_bare_varchar_unaffected(self):
        """Snowflake's own VARCHAR/TEXT alias overlap must not regress."""
        g, _, _, length = _mapper().source_type_to_generic(Dialect.SNOWFLAKE, "VARCHAR")
        assert g == GenericType.VARCHAR
        assert length is None


class TestTextTargetGeneration:
    def test_fabric_dw_default_8000_not_max(self):
        type_str, _, _ = _mapper().generic_to_target(GenericType.TEXT, Dialect.FABRIC_DW)
        assert type_str == "VARCHAR(8000)"

    def test_synapse_default_8000_not_max(self):
        type_str, _, _ = _mapper().generic_to_target(GenericType.TEXT, Dialect.SYNAPSE)
        assert type_str == "VARCHAR(8000)"

    def test_fabric_dw_explicit_length_overrides_default(self):
        type_str, _, _ = _mapper().generic_to_target(GenericType.TEXT, Dialect.FABRIC_DW, length=500)
        assert type_str == "VARCHAR(500)"

    def test_fabric_dw_length_clamped_to_max(self):
        type_str, _, _ = _mapper().generic_to_target(GenericType.TEXT, Dialect.FABRIC_DW, length=99999)
        assert type_str == "VARCHAR(8000)"

    def test_redshift_default_65535(self):
        type_str, _, _ = _mapper().generic_to_target(GenericType.TEXT, Dialect.REDSHIFT)
        assert type_str == "VARCHAR(65535)"

    def test_oracle_clob_unaffected_by_length(self):
        """Oracle CLOB has no length concept — must not become length_configurable."""
        type_str, _, _ = _mapper().generic_to_target(GenericType.TEXT, Dialect.ORACLE, length=500)
        assert type_str == "CLOB"

    def test_databricks_string_unaffected_by_length(self):
        type_str, _, _ = _mapper().generic_to_target(GenericType.TEXT, Dialect.DATABRICKS, length=500)
        assert type_str == "STRING"


class TestLengthDecisionsApi:
    SQL = "CREATE TABLE orders (status STRING, notes STRING);"

    def test_no_decisions_for_unbounded_target(self):
        result = Transpiler.convert(self.SQL, "databricks", "snowflake")
        assert result.length_decisions == []
        assert "TEXT" in result.converted_sql

    def test_decisions_surfaced_for_fabric_dw(self):
        result = Transpiler.convert(self.SQL, "databricks", "fabric_dw")
        assert len(result.length_decisions) == 2
        cols = {d.column for d in result.length_decisions}
        assert cols == {"status", "notes"}
        for d in result.length_decisions:
            assert d.applied_default == 8000
            assert d.max_length == 8000
            assert "VARCHAR(8000)" in result.converted_sql

    def test_column_override_applied_and_removes_decision(self):
        result = Transpiler.convert(
            self.SQL, "databricks", "fabric_dw",
            column_overrides=[{"table": "orders", "column": "status", "length": 100}],
        )
        assert "[status] VARCHAR(100)" in result.converted_sql
        assert "[notes] VARCHAR(8000)" in result.converted_sql
        remaining = {d.column for d in result.length_decisions}
        assert remaining == {"notes"}

    def test_default_text_length_applies_to_all_unmatched(self):
        result = Transpiler.convert(self.SQL, "databricks", "fabric_dw", default_text_length=250)
        assert "[status] VARCHAR(250)" in result.converted_sql
        assert "[notes] VARCHAR(250)" in result.converted_sql
        assert result.length_decisions == []

    def test_override_takes_precedence_over_default_text_length(self):
        result = Transpiler.convert(
            self.SQL, "databricks", "fabric_dw",
            column_overrides=[{"table": "orders", "column": "status", "length": 100}],
            default_text_length=250,
        )
        assert "[status] VARCHAR(100)" in result.converted_sql
        assert "[notes] VARCHAR(250)" in result.converted_sql

    def test_omitting_both_is_backward_compatible(self):
        """No overrides at all → identical to pre-feature default behavior."""
        result = Transpiler.convert(self.SQL, "databricks", "fabric_dw")
        assert "[status] VARCHAR(8000)" in result.converted_sql
        assert "[notes] VARCHAR(8000)" in result.converted_sql
