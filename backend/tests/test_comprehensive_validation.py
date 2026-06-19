"""
Comprehensive end-to-end validation of all dialect conversion paths.

Validates:
 - Function conversions for every source → target pair
 - Type mappings for every dialect
 - MV patterns per target
 - Edge cases: nested functions, NULL handling, date arithmetic, casting, concat

Official docs referenced inline per assertion.
Note on source selection:
  - Some parsers normalize functions at parse time (e.g., Redshift NVL→COALESCE).
  - Tests that need NVL preserved use Oracle as the source, where NVL stays in the IR.
  - Similarly, :: cast is parsed into CAST() by most parsers, so CAST form is the expected output.
"""
from __future__ import annotations

import pytest
from app.transpiler import Transpiler


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------

def _sql(src: str, tgt: str, stmt: str) -> str:
    """Transpile a single-statement SQL and return the result string."""
    result = Transpiler.convert(stmt, src, tgt)
    return result.converted_sql


def _all_warnings(result) -> list:
    """Return all warnings from both warnings and unsupported_features."""
    return list(result.warnings) + list(result.unsupported_features)


# ===========================================================================
# 1. FUNCTION CONVERSION MATRIX
#    For each target dialect we test that common source-dialect functions
#    are rewritten correctly, based on official documentation.
# ===========================================================================

# ---------------------------------------------------------------------------
# 1a. T-SQL targets: SQL Server, Synapse, Fabric DW
#     Ref: https://learn.microsoft.com/en-us/sql/t-sql/functions/functions
# ---------------------------------------------------------------------------

TSQL_TARGETS = ["sqlserver", "synapse", "fabric_dw"]

@pytest.mark.parametrize("tgt", TSQL_TARGETS)
def test_tsql_nvl_to_isnull(tgt):
    """Oracle NVL(a,b) → ISNULL(a,b) for T-SQL. Source: oracle (keeps NVL in IR).
    Ref: https://learn.microsoft.com/en-us/sql/t-sql/functions/isnull-transact-sql"""
    sql = "CREATE OR REPLACE VIEW s.v AS SELECT NVL(col, 0) AS x FROM t;"
    out = _sql("oracle", tgt, sql)
    assert "ISNULL(col, 0)" in out, f"[{tgt}] Expected ISNULL: {out}"
    assert "NVL(" not in out.upper(), f"[{tgt}] NVL should be gone: {out}"


@pytest.mark.parametrize("tgt", TSQL_TARGETS)
def test_tsql_decode_to_case(tgt):
    """Oracle DECODE(expr, v1, r1, v2, r2, def) → CASE WHEN.
    Ref: https://learn.microsoft.com/en-us/sql/t-sql/language-elements/case-transact-sql"""
    sql = "CREATE OR REPLACE VIEW s.v AS SELECT DECODE(status, 'A', 'Active', 'I', 'Inactive', 'Unknown') AS s FROM t;"
    out = _sql("oracle", tgt, sql)
    assert "CASE" in out.upper()
    assert "WHEN status = 'A' THEN 'Active'" in out
    assert "WHEN status = 'I' THEN 'Inactive'" in out
    assert "ELSE 'Unknown'" in out
    assert "DECODE(" not in out.upper()


@pytest.mark.parametrize("tgt", TSQL_TARGETS)
def test_tsql_date_trunc_to_datetrunc(tgt):
    """DATE_TRUNC('month', col) → DATETRUNC(MONTH, col) for T-SQL (case preserved from input).
    Ref: https://learn.microsoft.com/en-us/sql/t-sql/functions/datetrunc-transact-sql"""
    sql = "CREATE VIEW s.v AS SELECT DATE_TRUNC('month', created_at) AS m FROM t;"
    out = _sql("redshift", tgt, sql)
    assert "DATETRUNC(" in out.upper(), f"[{tgt}] Expected DATETRUNC: {out}"
    assert "created_at" in out


@pytest.mark.parametrize("tgt", TSQL_TARGETS)
def test_tsql_date_part_to_datepart(tgt):
    """DATE_PART('year', col) → DATEPART(year, col) for T-SQL.
    Ref: https://learn.microsoft.com/en-us/sql/t-sql/functions/datepart-transact-sql"""
    sql = "CREATE VIEW s.v AS SELECT DATE_PART('year', created_at) AS y FROM t;"
    out = _sql("redshift", tgt, sql)
    assert "DATEPART(year, created_at)" in out, f"[{tgt}] Expected DATEPART: {out}"


@pytest.mark.parametrize("tgt", TSQL_TARGETS)
def test_tsql_extract_to_datepart(tgt):
    """EXTRACT(MONTH FROM col) → DATEPART(MONTH, col) for T-SQL."""
    sql = "CREATE VIEW s.v AS SELECT EXTRACT(MONTH FROM created_at) AS m FROM t;"
    out = _sql("redshift", tgt, sql)
    assert "DATEPART(MONTH, created_at)" in out, f"[{tgt}] Expected DATEPART from EXTRACT: {out}"


@pytest.mark.parametrize("tgt", TSQL_TARGETS)
def test_tsql_length_to_len(tgt):
    """LENGTH(x) → LEN(x) for T-SQL.
    Ref: https://learn.microsoft.com/en-us/sql/t-sql/functions/len-transact-sql"""
    sql = "CREATE VIEW s.v AS SELECT LENGTH(name) AS n FROM t;"
    out = _sql("redshift", tgt, sql)
    assert "LEN(name)" in out, f"[{tgt}] Expected LEN: {out}"
    assert "LENGTH(" not in out, f"[{tgt}] LENGTH should be gone: {out}"


@pytest.mark.parametrize("tgt", TSQL_TARGETS)
def test_tsql_substr_to_substring(tgt):
    """SUBSTR(x,y,z) → SUBSTRING form for T-SQL. ANSI SUBSTRING(FROM…FOR) is also valid.
    Ref: https://learn.microsoft.com/en-us/sql/t-sql/functions/substring-transact-sql"""
    sql = "CREATE VIEW s.v AS SELECT SUBSTR(name, 1, 3) AS s FROM t;"
    out = _sql("redshift", tgt, sql)
    # SUBSTRING in any valid T-SQL form (comma or ANSI FROM/FOR)
    assert "SUBSTRING" in out.upper(), f"[{tgt}] Expected SUBSTRING: {out}"
    assert "SUBSTR(" not in out, f"[{tgt}] SUBSTR should be gone: {out}"


@pytest.mark.parametrize("tgt", TSQL_TARGETS)
def test_tsql_ceil_to_ceiling(tgt):
    """CEIL(x) → CEILING(x) for T-SQL.
    Ref: https://learn.microsoft.com/en-us/sql/t-sql/functions/ceiling-transact-sql"""
    sql = "CREATE VIEW s.v AS SELECT CEIL(amount) AS c FROM t;"
    out = _sql("redshift", tgt, sql)
    assert "CEILING(amount)" in out, f"[{tgt}] Expected CEILING: {out}"


@pytest.mark.parametrize("tgt", TSQL_TARGETS)
def test_tsql_add_months_to_dateadd(tgt):
    """Oracle ADD_MONTHS(date, n) → DATEADD(MONTH, n, date) for T-SQL.
    Ref: https://learn.microsoft.com/en-us/sql/t-sql/functions/dateadd-transact-sql"""
    sql = "CREATE OR REPLACE VIEW s.v AS SELECT ADD_MONTHS(created_at, 3) AS x FROM t;"
    out = _sql("oracle", tgt, sql)
    assert "DATEADD(MONTH, 3, created_at)" in out, f"[{tgt}] Expected DATEADD: {out}"
    assert "ADD_MONTHS(" not in out.upper()


@pytest.mark.parametrize("tgt", TSQL_TARGETS)
def test_tsql_last_day_to_eomonth(tgt):
    """LAST_DAY(date) → EOMONTH(date) for T-SQL.
    Ref: https://learn.microsoft.com/en-us/sql/t-sql/functions/eomonth-transact-sql"""
    sql = "CREATE OR REPLACE VIEW s.v AS SELECT LAST_DAY(created_at) AS x FROM t;"
    out = _sql("oracle", tgt, sql)
    assert "EOMONTH(created_at)" in out, f"[{tgt}] Expected EOMONTH: {out}"
    assert "LAST_DAY(" not in out.upper()


@pytest.mark.parametrize("tgt", TSQL_TARGETS)
def test_tsql_listagg_to_string_agg(tgt):
    """LISTAGG(col, sep) → STRING_AGG(col, sep) for T-SQL.
    Ref: https://learn.microsoft.com/en-us/sql/t-sql/functions/string-agg-transact-sql"""
    sql = "CREATE VIEW s.v AS SELECT LISTAGG(name, ', ') AS x FROM t;"
    out = _sql("redshift", tgt, sql)
    assert "STRING_AGG(name, ', ')" in out, f"[{tgt}] Expected STRING_AGG: {out}"


@pytest.mark.parametrize("tgt", TSQL_TARGETS)
def test_tsql_position_to_charindex(tgt):
    """POSITION(x IN y) → CHARINDEX(x, y) for T-SQL.
    Ref: https://learn.microsoft.com/en-us/sql/t-sql/functions/charindex-transact-sql"""
    sql = "CREATE VIEW s.v AS SELECT POSITION('@' IN email) AS x FROM t;"
    out = _sql("redshift", tgt, sql)
    assert "CHARINDEX('@', email)" in out, f"[{tgt}] Expected CHARINDEX: {out}"


@pytest.mark.parametrize("tgt", TSQL_TARGETS)
def test_tsql_to_char_to_format(tgt):
    """Oracle TO_CHAR(dt, fmt) → FORMAT(dt, fmt) for T-SQL.
    Ref: https://learn.microsoft.com/en-us/sql/t-sql/functions/format-transact-sql"""
    sql = "CREATE OR REPLACE VIEW s.v AS SELECT TO_CHAR(created_at, 'YYYY-MM') AS x FROM t;"
    out = _sql("oracle", tgt, sql)
    assert "FORMAT(created_at," in out, f"[{tgt}] Expected FORMAT: {out}"
    assert "YYYY-MM" in out


@pytest.mark.parametrize("tgt", TSQL_TARGETS)
def test_tsql_to_number_to_cast_float(tgt):
    """TO_NUMBER(expr) → CAST(expr AS FLOAT) for T-SQL."""
    sql = "CREATE OR REPLACE VIEW s.v AS SELECT TO_NUMBER(price_str) AS x FROM t;"
    out = _sql("oracle", tgt, sql)
    assert "CAST(price_str AS FLOAT)" in out, f"[{tgt}] Expected CAST AS FLOAT: {out}"


@pytest.mark.parametrize("tgt", TSQL_TARGETS)
def test_tsql_double_colon_cast(tgt):
    """Redshift ::TYPE is normalized to CAST(expr AS TYPE) at parse time.
    T-SQL CAST is ANSI standard and fully equivalent.
    Ref: https://learn.microsoft.com/en-us/sql/t-sql/functions/cast-and-convert-transact-sql"""
    sql = "CREATE VIEW s.v AS SELECT amount::DECIMAL AS x FROM t;"
    out = _sql("redshift", tgt, sql)
    # Parser normalizes ::DECIMAL to CAST(amount AS DECIMAL) — accept CAST or CONVERT
    assert "CAST(amount AS DECIMAL)" in out or "CONVERT(DECIMAL, amount)" in out, \
        f"[{tgt}] Expected CAST or CONVERT: {out}"


@pytest.mark.parametrize("tgt", TSQL_TARGETS)
def test_tsql_sysdate_to_getdate(tgt):
    """Oracle SYSDATE → GETDATE() for T-SQL.
    Ref: https://learn.microsoft.com/en-us/sql/t-sql/functions/getdate-transact-sql"""
    sql = "CREATE OR REPLACE VIEW s.v AS SELECT SYSDATE AS ts FROM t;"
    out = _sql("oracle", tgt, sql)
    assert "GETDATE()" in out, f"[{tgt}] Expected GETDATE: {out}"
    assert "SYSDATE" not in out.upper()


@pytest.mark.parametrize("tgt", TSQL_TARGETS)
def test_tsql_current_date_to_convert(tgt):
    """CURRENT_DATE → CONVERT(DATE, GETDATE()) for T-SQL.
    Ref: https://learn.microsoft.com/en-us/sql/t-sql/functions/getdate-transact-sql"""
    sql = "CREATE VIEW s.v AS SELECT CURRENT_DATE AS d FROM t;"
    out = _sql("redshift", tgt, sql)
    assert "CONVERT(DATE, GETDATE())" in out, f"[{tgt}] Expected CONVERT(DATE,GETDATE()): {out}"


@pytest.mark.parametrize("tgt", TSQL_TARGETS)
def test_tsql_pipe_concat_to_plus(tgt):
    """|| string concat → + for T-SQL.
    Ref: https://learn.microsoft.com/en-us/sql/t-sql/language-elements/string-concatenation-transact-sql"""
    sql = "CREATE VIEW s.v AS SELECT first_name || ' ' || last_name AS full_name FROM t;"
    out = _sql("redshift", tgt, sql)
    assert "+" in out, f"[{tgt}] Expected + concatenation: {out}"
    assert "||" not in out, f"[{tgt}] || should be gone: {out}"


@pytest.mark.parametrize("tgt", TSQL_TARGETS)
def test_tsql_nvl2_to_case(tgt):
    """NVL2(expr, nn_val, null_val) → CASE WHEN expr IS NOT NULL THEN nn_val ELSE null_val END."""
    sql = "CREATE OR REPLACE VIEW s.v AS SELECT NVL2(col, 'has value', 'no value') AS x FROM t;"
    out = _sql("oracle", tgt, sql)
    assert "CASE WHEN col IS NOT NULL THEN 'has value' ELSE 'no value' END" in out
    assert "NVL2(" not in out.upper()


# ---------------------------------------------------------------------------
# 1b. Oracle target
#     Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Functions.html
# ---------------------------------------------------------------------------

class TestOracleConversions:
    def test_isnull_to_nvl(self):
        """T-SQL ISNULL → Oracle NVL.
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/NVL.html"""
        sql = "CREATE VIEW s.v AS SELECT ISNULL(col, 0) AS x FROM t;"
        out = _sql("sqlserver", "oracle", sql)
        assert "NVL(col, 0)" in out
        assert "ISNULL(" not in out.upper()

    def test_getdate_to_sysdate(self):
        """T-SQL GETDATE() → Oracle SYSDATE.
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/SYSDATE.html"""
        sql = "CREATE VIEW s.v AS SELECT GETDATE() AS ts FROM t;"
        out = _sql("sqlserver", "oracle", sql)
        assert "SYSDATE" in out
        assert "GETDATE" not in out.upper()

    def test_len_to_length(self):
        """T-SQL LEN → Oracle LENGTH.
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/LENGTH.html"""
        sql = "CREATE VIEW s.v AS SELECT LEN(name) AS n FROM t;"
        out = _sql("sqlserver", "oracle", sql)
        assert "LENGTH(name)" in out

    def test_ceiling_to_ceil(self):
        """T-SQL CEILING → Oracle CEIL.
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CEIL.html"""
        sql = "CREATE VIEW s.v AS SELECT CEILING(amount) AS c FROM t;"
        out = _sql("sqlserver", "oracle", sql)
        assert "CEIL(amount)" in out
        assert "CEILING(" not in out

    def test_substring_to_substr(self):
        """T-SQL SUBSTRING → Oracle SUBSTR.
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/SUBSTR.html"""
        sql = "CREATE VIEW s.v AS SELECT SUBSTRING(name, 1, 3) AS s FROM t;"
        out = _sql("sqlserver", "oracle", sql)
        assert "SUBSTR(name, 1, 3)" in out
        assert "SUBSTRING(" not in out.upper()

    def test_charindex_to_instr_arg_swap(self):
        """CHARINDEX(needle, haystack) → INSTR(haystack, needle) — args swapped.
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/INSTR.html"""
        sql = "CREATE VIEW s.v AS SELECT CHARINDEX('@', email) AS pos FROM t;"
        out = _sql("sqlserver", "oracle", sql)
        assert "INSTR(email, '@')" in out
        assert "CHARINDEX(" not in out.upper()

    def test_string_agg_to_listagg(self):
        """T-SQL STRING_AGG → Oracle LISTAGG.
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/LISTAGG.html"""
        sql = "CREATE VIEW s.v AS SELECT STRING_AGG(name, ', ') AS x FROM t;"
        out = _sql("sqlserver", "oracle", sql)
        assert "LISTAGG(name, ', ')" in out
        assert "STRING_AGG(" not in out.upper()

    def test_eomonth_to_last_day(self):
        """T-SQL EOMONTH → Oracle LAST_DAY.
        Oracle LAST_DAY requires DATE — generator may wrap arg in CAST(AS DATE).
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/LAST_DAY.html"""
        sql = "CREATE VIEW s.v AS SELECT EOMONTH(created_at) AS x FROM t;"
        out = _sql("sqlserver", "oracle", sql)
        assert "LAST_DAY(" in out, f"Expected LAST_DAY: {out}"
        assert "EOMONTH(" not in out.upper()

    def test_datetrunc_to_oracle_trunc(self):
        """DATETRUNC(DAY, col) → Oracle TRUNC(col, 'DD').
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/TRUNC-date.html"""
        sql = "CREATE VIEW s.v AS SELECT DATE_TRUNC('day', created_at) AS d FROM t;"
        out = _sql("redshift", "oracle", sql)
        assert "TRUNC(created_at, 'DD')" in out

    def test_datetrunc_month_to_oracle(self):
        """DATETRUNC(MONTH, col) → Oracle TRUNC(col, 'MONTH')."""
        sql = "CREATE VIEW s.v AS SELECT DATE_TRUNC('month', created_at) AS m FROM t;"
        out = _sql("redshift", "oracle", sql)
        assert "TRUNC(created_at, 'MONTH')" in out

    def test_datepart_to_extract(self):
        """T-SQL DATEPART(year, col) → EXTRACT(year FROM col).
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/EXTRACT-datetime.html"""
        sql = "CREATE VIEW s.v AS SELECT DATEPART(year, created_at) AS y FROM t;"
        out = _sql("sqlserver", "oracle", sql)
        assert "EXTRACT(year FROM created_at)" in out
        assert "DATEPART(" not in out.upper()

    def test_dateadd_month_to_add_months(self):
        """DATEADD(MONTH, n, d) → ADD_MONTHS(d, n) for Oracle.
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/ADD_MONTHS.html"""
        sql = "CREATE VIEW s.v AS SELECT DATEADD(MONTH, 3, created_at) AS x FROM t;"
        out = _sql("sqlserver", "oracle", sql)
        assert "ADD_MONTHS(created_at, 3)" in out
        assert "DATEADD(" not in out.upper()

    def test_dateadd_year_to_add_months(self):
        """DATEADD(YEAR, 2, d) → ADD_MONTHS(d, 2*12) for Oracle."""
        sql = "CREATE VIEW s.v AS SELECT DATEADD(YEAR, 2, created_at) AS x FROM t;"
        out = _sql("sqlserver", "oracle", sql)
        assert "ADD_MONTHS(created_at, (2) * 12)" in out

    def test_dateadd_day_to_plus(self):
        """DATEADD(DAY, n, d) → (d + n) for Oracle."""
        sql = "CREATE VIEW s.v AS SELECT DATEADD(DAY, 7, created_at) AS x FROM t;"
        out = _sql("sqlserver", "oracle", sql)
        assert "(created_at + 7)" in out

    def test_format_to_to_char(self):
        """FORMAT(dt, fmt) → TO_CHAR(dt, fmt) for Oracle.
        sqlglot may lowercase the format string literal — compare case-insensitively.
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/TO_CHAR-datetime.html"""
        sql = "CREATE VIEW s.v AS SELECT FORMAT(created_at, 'YYYY-MM') AS x FROM t;"
        out = _sql("sqlserver", "oracle", sql)
        assert "TO_CHAR(created_at," in out, f"Expected TO_CHAR: {out}"
        assert "YYYY-MM" in out.upper()

    def test_double_colon_to_cast(self):
        """Redshift ::TYPE → normalized at parse time; Oracle uses CAST.
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CAST.html"""
        sql = "CREATE VIEW s.v AS SELECT amount::INTEGER AS x FROM t;"
        out = _sql("redshift", "oracle", sql)
        assert "CAST(amount AS INTEGER)" in out

    def test_nvl2_native_oracle(self):
        """NVL2 is Oracle-native — stays as NVL2 in oracle→oracle.
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/NVL2.html"""
        sql = "CREATE OR REPLACE VIEW s.v AS SELECT NVL2(col, 'a', 'b') AS x FROM t;"
        out = _sql("oracle", "oracle", sql)
        assert "NVL2(col, 'a', 'b')" in out

    def test_decode_native_oracle(self):
        """DECODE is Oracle-native — stays as DECODE in oracle→oracle."""
        sql = "CREATE OR REPLACE VIEW s.v AS SELECT DECODE(status, 1, 'A', 'B') AS x FROM t;"
        out = _sql("oracle", "oracle", sql)
        assert "DECODE(" in out


# ---------------------------------------------------------------------------
# 1c. Snowflake target
#     Ref: https://docs.snowflake.com/en/sql-reference/functions-all
# ---------------------------------------------------------------------------

class TestSnowflakeConversions:
    def test_isnull_to_nvl(self):
        """T-SQL ISNULL → Snowflake NVL.
        Ref: https://docs.snowflake.com/en/sql-reference/functions/nvl"""
        sql = "CREATE VIEW s.v AS SELECT ISNULL(col, 0) AS x FROM t;"
        out = _sql("sqlserver", "snowflake", sql)
        assert "NVL(col, 0)" in out

    def test_getdate_to_current_timestamp(self):
        """GETDATE() → CURRENT_TIMESTAMP for Snowflake.
        Ref: https://docs.snowflake.com/en/sql-reference/functions/current_timestamp"""
        sql = "CREATE VIEW s.v AS SELECT GETDATE() AS ts FROM t;"
        out = _sql("sqlserver", "snowflake", sql)
        assert "CURRENT_TIMESTAMP" in out
        assert "GETDATE" not in out.upper()

    def test_sysdate_to_current_timestamp(self):
        """Oracle SYSDATE → CURRENT_TIMESTAMP for Snowflake."""
        sql = "CREATE OR REPLACE VIEW s.v AS SELECT SYSDATE AS ts FROM t;"
        out = _sql("oracle", "snowflake", sql)
        assert "CURRENT_TIMESTAMP" in out
        assert "SYSDATE" not in out.upper()

    def test_len_to_length(self):
        """LEN → LENGTH for Snowflake.
        Ref: https://docs.snowflake.com/en/sql-reference/functions/length"""
        sql = "CREATE VIEW s.v AS SELECT LEN(name) AS n FROM t;"
        out = _sql("sqlserver", "snowflake", sql)
        assert "LENGTH(name)" in out

    def test_ceiling_to_ceil(self):
        """CEILING → CEIL for Snowflake.
        Ref: https://docs.snowflake.com/en/sql-reference/functions/ceil"""
        sql = "CREATE VIEW s.v AS SELECT CEILING(amount) AS c FROM t;"
        out = _sql("sqlserver", "snowflake", sql)
        assert "CEIL(amount)" in out
        assert "CEILING(" not in out

    def test_string_agg_to_listagg(self):
        """STRING_AGG → LISTAGG for Snowflake.
        Ref: https://docs.snowflake.com/en/sql-reference/functions/listagg"""
        sql = "CREATE VIEW s.v AS SELECT STRING_AGG(name, ',') AS x FROM t;"
        out = _sql("sqlserver", "snowflake", sql)
        assert "LISTAGG(name, ',')" in out

    def test_eomonth_to_last_day(self):
        """EOMONTH → LAST_DAY for Snowflake. May wrap arg in CAST(AS DATE).
        Ref: https://docs.snowflake.com/en/sql-reference/functions/last_day"""
        sql = "CREATE VIEW s.v AS SELECT EOMONTH(created_at) AS x FROM t;"
        out = _sql("sqlserver", "snowflake", sql)
        assert "LAST_DAY(" in out, f"Expected LAST_DAY: {out}"
        assert "EOMONTH(" not in out.upper()

    def test_datetrunc_to_date_trunc_quoted(self):
        """DATETRUNC(MONTH, col) → DATE_TRUNC('MONTH', col) for Snowflake.
        Ref: https://docs.snowflake.com/en/sql-reference/functions/date_trunc"""
        sql = "CREATE VIEW s.v AS SELECT DATETRUNC(MONTH, created_at) AS m FROM t;"
        out = _sql("sqlserver", "snowflake", sql)
        assert "DATE_TRUNC('MONTH', created_at)" in out

    def test_datepart_to_date_part_quoted(self):
        """DATEPART(year, col) → DATE_PART('year', col) for Snowflake.
        Ref: https://docs.snowflake.com/en/sql-reference/functions/date_part"""
        sql = "CREATE VIEW s.v AS SELECT DATEPART(year, created_at) AS y FROM t;"
        out = _sql("sqlserver", "snowflake", sql)
        assert "DATE_PART('year', created_at)" in out

    def test_format_to_to_char(self):
        """FORMAT → TO_CHAR for Snowflake.
        sqlglot may lowercase the format string literal — compare case-insensitively.
        Ref: https://docs.snowflake.com/en/sql-reference/functions/to_char"""
        sql = "CREATE VIEW s.v AS SELECT FORMAT(created_at, 'YYYY-MM') AS x FROM t;"
        out = _sql("sqlserver", "snowflake", sql)
        assert "TO_CHAR(created_at," in out, f"Expected TO_CHAR: {out}"
        assert "YYYY-MM" in out.upper()

    def test_backtick_to_double_quote(self):
        """BigQuery backtick identifiers → double-quote for Snowflake."""
        sql = "CREATE OR REPLACE VIEW `my_dataset.my_view` AS SELECT `col` FROM `my_dataset.tbl`;"
        out = _sql("bigquery", "snowflake", sql)
        assert "`" not in out
        assert '"' in out

    def test_double_colon_native_snowflake(self):
        """Snowflake ::TYPE cast — parser normalizes to CAST form. CAST is valid in Snowflake.
        Ref: https://docs.snowflake.com/en/sql-reference/functions/cast"""
        sql = "CREATE OR REPLACE VIEW s.v AS SELECT amount::FLOAT AS x FROM t;"
        out = _sql("snowflake", "snowflake", sql)
        # Snowflake parser normalizes ::FLOAT → CAST(AS DOUBLE) — CAST is valid in Snowflake
        assert "FLOAT" in out or "DOUBLE" in out or "CAST" in out

    def test_nvl_native_snowflake(self):
        """NVL in Snowflake source — parser may normalize to COALESCE. Both are valid in Snowflake.
        Ref: https://docs.snowflake.com/en/sql-reference/functions/coalesce"""
        sql = "CREATE OR REPLACE VIEW s.v AS SELECT NVL(col, 0) AS x FROM t;"
        out = _sql("snowflake", "snowflake", sql)
        # Snowflake parser normalizes NVL → COALESCE at parse time. COALESCE is valid in Snowflake.
        assert "NVL(col, 0)" in out or "COALESCE(col, 0)" in out


# ---------------------------------------------------------------------------
# 1d. BigQuery target
#     Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/functions-and-operators
# ---------------------------------------------------------------------------

class TestBigQueryConversions:
    def test_nvl_oracle_to_ifnull(self):
        """Oracle NVL(a,b) → IFNULL(a,b) for BigQuery (Oracle keeps NVL in IR).
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/conditional_expressions#ifnull"""
        sql = "CREATE OR REPLACE VIEW s.v AS SELECT NVL(col, 0) AS x FROM t;"
        out = _sql("oracle", "bigquery", sql)
        assert "IFNULL(col, 0)" in out

    def test_isnull_to_ifnull(self):
        """T-SQL ISNULL → IFNULL for BigQuery."""
        sql = "CREATE VIEW s.v AS SELECT ISNULL(col, 0) AS x FROM t;"
        out = _sql("sqlserver", "bigquery", sql)
        assert "IFNULL(col, 0)" in out

    def test_nvl2_to_case(self):
        """NVL2 → CASE WHEN for BigQuery (BigQuery has no NVL2)."""
        sql = "CREATE OR REPLACE VIEW s.v AS SELECT NVL2(col, 'a', 'b') AS x FROM t;"
        out = _sql("oracle", "bigquery", sql)
        assert "CASE WHEN col IS NOT NULL THEN 'a' ELSE 'b' END" in out

    def test_decode_to_case(self):
        """DECODE → CASE WHEN for BigQuery (no DECODE in BigQuery)."""
        sql = "CREATE OR REPLACE VIEW s.v AS SELECT DECODE(x, 1, 'one', 'other') AS y FROM t;"
        out = _sql("oracle", "bigquery", sql)
        assert "CASE" in out.upper()
        assert "DECODE(" not in out.upper()

    def test_getdate_to_current_timestamp(self):
        """GETDATE() → CURRENT_TIMESTAMP for BigQuery.
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/timestamp_functions#current_timestamp"""
        sql = "CREATE VIEW s.v AS SELECT GETDATE() AS ts FROM t;"
        out = _sql("sqlserver", "bigquery", sql)
        assert "CURRENT_TIMESTAMP" in out

    def test_sysdate_to_current_timestamp(self):
        """Oracle SYSDATE → CURRENT_TIMESTAMP for BigQuery."""
        sql = "CREATE OR REPLACE VIEW s.v AS SELECT SYSDATE AS ts FROM t;"
        out = _sql("oracle", "bigquery", sql)
        assert "CURRENT_TIMESTAMP" in out

    def test_len_to_length(self):
        """LEN → LENGTH for BigQuery.
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/string_functions#length"""
        sql = "CREATE VIEW s.v AS SELECT LEN(name) AS n FROM t;"
        out = _sql("sqlserver", "bigquery", sql)
        assert "LENGTH(name)" in out

    def test_ceiling_to_ceil(self):
        """CEILING → CEIL for BigQuery.
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/mathematical_functions#ceil"""
        sql = "CREATE VIEW s.v AS SELECT CEILING(amount) AS c FROM t;"
        out = _sql("sqlserver", "bigquery", sql)
        assert "CEIL(amount)" in out

    def test_listagg_to_string_agg(self):
        """LISTAGG → STRING_AGG for BigQuery.
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/aggregate_functions#string_agg"""
        sql = "CREATE VIEW s.v AS SELECT LISTAGG(name, ',') AS x FROM t;"
        out = _sql("redshift", "bigquery", sql)
        assert "STRING_AGG(name, ',')" in out
        assert "LISTAGG(" not in out.upper()

    def test_eomonth_to_last_day(self):
        """EOMONTH → LAST_DAY for BigQuery. May wrap arg in CAST(AS DATE).
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/date_functions#last_day"""
        sql = "CREATE VIEW s.v AS SELECT EOMONTH(created_at) AS x FROM t;"
        out = _sql("sqlserver", "bigquery", sql)
        assert "LAST_DAY(" in out, f"Expected LAST_DAY: {out}"
        assert "EOMONTH(" not in out.upper()

    def test_datetrunc_to_date_trunc_bq(self):
        """DATETRUNC(DAY, expr) → DATE_TRUNC(expr, DAY) for BigQuery — args FLIPPED, part unquoted.
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/date_functions#date_trunc"""
        sql = "CREATE VIEW s.v AS SELECT DATETRUNC(DAY, created_at) AS d FROM t;"
        out = _sql("sqlserver", "bigquery", sql)
        assert "DATE_TRUNC(created_at, DAY)" in out

    def test_date_trunc_std_to_bq(self):
        """Standard DATE_TRUNC('day', expr) → DATE_TRUNC(expr, DAY) for BigQuery.
        Part keyword may be uppercase or lowercase but always unquoted."""
        sql = "CREATE VIEW s.v AS SELECT DATE_TRUNC('day', created_at) AS d FROM t;"
        out = _sql("redshift", "bigquery", sql)
        assert "DATE_TRUNC(created_at," in out, f"Expected DATE_TRUNC(created_at,...): {out}"
        assert "DAY" in out.upper(), f"Expected DAY in output: {out}"

    def test_datepart_to_extract(self):
        """DATEPART(year, col) → EXTRACT(year FROM col) for BigQuery.
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/date_functions#extract"""
        sql = "CREATE VIEW s.v AS SELECT DATEPART(year, created_at) AS y FROM t;"
        out = _sql("sqlserver", "bigquery", sql)
        assert "EXTRACT(year FROM created_at)" in out

    def test_dateadd_to_date_add(self):
        """DATEADD(MONTH, n, d) → DATE_ADD(d, INTERVAL n MONTH) for BigQuery.
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/date_functions#date_add"""
        sql = "CREATE VIEW s.v AS SELECT DATEADD(MONTH, 3, created_at) AS x FROM t;"
        out = _sql("sqlserver", "bigquery", sql)
        assert "DATE_ADD(created_at, INTERVAL 3 MONTH)" in out

    def test_add_months_to_date_add(self):
        """Oracle ADD_MONTHS(d, n) → DATE_ADD(d, INTERVAL n MONTH) for BigQuery."""
        sql = "CREATE OR REPLACE VIEW s.v AS SELECT ADD_MONTHS(created_at, 6) AS x FROM t;"
        out = _sql("oracle", "bigquery", sql)
        assert "DATE_ADD(created_at, INTERVAL 6 MONTH)" in out

    def test_charindex_to_strpos(self):
        """CHARINDEX(needle, haystack) → STRPOS(haystack, needle) for BigQuery.
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/string_functions#strpos"""
        sql = "CREATE VIEW s.v AS SELECT CHARINDEX('@', email) AS pos FROM t;"
        out = _sql("sqlserver", "bigquery", sql)
        assert "STRPOS(email, '@')" in out

    def test_double_colon_to_cast(self):
        """Redshift ::TYPE parsed to CAST at parse time — BigQuery uses CAST.
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/conversion_functions#cast"""
        sql = "CREATE VIEW s.v AS SELECT amount::INTEGER AS x FROM t;"
        out = _sql("redshift", "bigquery", sql)
        assert "CAST(amount AS" in out
        assert "CONVERT(" not in out.upper()

    def test_coalesce_valid_in_bigquery(self):
        """Redshift source normalizes NVL→COALESCE at parse time; COALESCE valid in BigQuery.
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/conditional_expressions#coalesce"""
        sql = "CREATE VIEW s.v AS SELECT NVL(col, 0) AS x FROM t;"
        out = _sql("redshift", "bigquery", sql)
        # Redshift parser normalizes NVL → COALESCE; BigQuery accepts COALESCE
        assert "COALESCE(col, 0)" in out or "IFNULL(col, 0)" in out


# ---------------------------------------------------------------------------
# 1e. Databricks target
#     Ref: https://docs.databricks.com/en/sql/language-manual/sql-ref-functions-builtin.html
# ---------------------------------------------------------------------------

class TestDatabricksConversions:
    def test_nvl_oracle_to_coalesce(self):
        """Oracle NVL(a,b) → COALESCE(a,b) for Databricks.
        Ref: https://docs.databricks.com/en/sql/language-manual/functions/coalesce.html"""
        sql = "CREATE OR REPLACE VIEW s.v AS SELECT NVL(col, 0) AS x FROM t;"
        out = _sql("oracle", "databricks", sql)
        assert "COALESCE(col, 0)" in out

    def test_isnull_to_ifnull(self):
        """ISNULL → IFNULL for Databricks.
        Ref: https://docs.databricks.com/en/sql/language-manual/functions/ifnull.html"""
        sql = "CREATE VIEW s.v AS SELECT ISNULL(col, 0) AS x FROM t;"
        out = _sql("sqlserver", "databricks", sql)
        assert "IFNULL(col, 0)" in out

    def test_nvl2_to_case(self):
        """NVL2 → CASE WHEN for Databricks."""
        sql = "CREATE OR REPLACE VIEW s.v AS SELECT NVL2(col, 'a', 'b') AS x FROM t;"
        out = _sql("oracle", "databricks", sql)
        assert "CASE WHEN col IS NOT NULL THEN 'a' ELSE 'b' END" in out

    def test_decode_to_case(self):
        """DECODE → CASE for Databricks.
        Ref: https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-qry-select-case.html"""
        sql = "CREATE OR REPLACE VIEW s.v AS SELECT DECODE(x, 1, 'one', 'other') AS y FROM t;"
        out = _sql("oracle", "databricks", sql)
        assert "CASE" in out.upper()
        assert "DECODE(" not in out.upper()

    def test_getdate_to_current_timestamp(self):
        """GETDATE() → CURRENT_TIMESTAMP for Databricks.
        Ref: https://docs.databricks.com/en/sql/language-manual/functions/current_timestamp.html"""
        sql = "CREATE VIEW s.v AS SELECT GETDATE() AS ts FROM t;"
        out = _sql("sqlserver", "databricks", sql)
        assert "CURRENT_TIMESTAMP" in out

    def test_sysdate_to_current_timestamp(self):
        """Oracle SYSDATE → CURRENT_TIMESTAMP for Databricks."""
        sql = "CREATE OR REPLACE VIEW s.v AS SELECT SYSDATE AS ts FROM t;"
        out = _sql("oracle", "databricks", sql)
        assert "CURRENT_TIMESTAMP" in out

    def test_len_to_length(self):
        """LEN → LENGTH for Databricks.
        Ref: https://docs.databricks.com/en/sql/language-manual/functions/length.html"""
        sql = "CREATE VIEW s.v AS SELECT LEN(name) AS n FROM t;"
        out = _sql("sqlserver", "databricks", sql)
        assert "LENGTH(name)" in out

    def test_ceiling_to_ceil(self):
        """CEILING → CEIL for Databricks.
        Ref: https://docs.databricks.com/en/sql/language-manual/functions/ceil.html"""
        sql = "CREATE VIEW s.v AS SELECT CEILING(amount) AS c FROM t;"
        out = _sql("sqlserver", "databricks", sql)
        assert "CEIL(amount)" in out

    def test_listagg_to_string_agg(self):
        """LISTAGG → STRING_AGG for Databricks.
        Ref: https://docs.databricks.com/en/sql/language-manual/functions/string_agg.html"""
        sql = "CREATE VIEW s.v AS SELECT LISTAGG(name, ',') AS x FROM t;"
        out = _sql("redshift", "databricks", sql)
        assert "STRING_AGG(name, ',')" in out

    def test_eomonth_to_last_day(self):
        """EOMONTH → LAST_DAY for Databricks. May wrap in CAST(AS DATE).
        Ref: https://docs.databricks.com/en/sql/language-manual/functions/last_day.html"""
        sql = "CREATE VIEW s.v AS SELECT EOMONTH(created_at) AS x FROM t;"
        out = _sql("sqlserver", "databricks", sql)
        assert "LAST_DAY(" in out, f"Expected LAST_DAY: {out}"
        assert "EOMONTH(" not in out.upper()

    def test_datetrunc_to_date_trunc_quoted(self):
        """DATETRUNC(MONTH, col) → DATE_TRUNC('MONTH', col) for Databricks.
        Ref: https://docs.databricks.com/en/sql/language-manual/functions/date_trunc.html"""
        sql = "CREATE VIEW s.v AS SELECT DATETRUNC(MONTH, created_at) AS m FROM t;"
        out = _sql("sqlserver", "databricks", sql)
        assert "DATE_TRUNC('MONTH', created_at)" in out

    def test_datepart_to_extract(self):
        """DATEPART(year, col) → EXTRACT(year FROM col) for Databricks.
        Ref: https://docs.databricks.com/en/sql/language-manual/functions/extract.html"""
        sql = "CREATE VIEW s.v AS SELECT DATEPART(year, created_at) AS y FROM t;"
        out = _sql("sqlserver", "databricks", sql)
        assert "EXTRACT(year FROM created_at)" in out

    def test_charindex_to_locate(self):
        """CHARINDEX(needle, haystack) → LOCATE(needle, haystack) for Databricks.
        Ref: https://docs.databricks.com/en/sql/language-manual/functions/locate.html"""
        sql = "CREATE VIEW s.v AS SELECT CHARINDEX('@', email) AS pos FROM t;"
        out = _sql("sqlserver", "databricks", sql)
        assert "LOCATE('@', email)" in out

    def test_double_colon_to_cast(self):
        """::TYPE → CAST(AS TYPE) for Databricks.
        Ref: https://docs.databricks.com/en/sql/language-manual/functions/cast.html"""
        sql = "CREATE VIEW s.v AS SELECT amount::DECIMAL AS x FROM t;"
        out = _sql("redshift", "databricks", sql)
        assert "CAST(amount AS DECIMAL)" in out


# ---------------------------------------------------------------------------
# 1f. Redshift target
#     Ref: https://docs.aws.amazon.com/redshift/latest/dg/r_Functions_list.html
# ---------------------------------------------------------------------------

class TestRedshiftConversions:
    def test_isnull_to_nvl(self):
        """T-SQL ISNULL → NVL for Redshift.
        Ref: https://docs.aws.amazon.com/redshift/latest/dg/r_NVL_function.html"""
        sql = "CREATE VIEW s.v AS SELECT ISNULL(col, 0) AS x FROM t;"
        out = _sql("sqlserver", "redshift", sql)
        assert "NVL(col, 0)" in out

    def test_string_agg_to_listagg(self):
        """STRING_AGG → LISTAGG for Redshift.
        Ref: https://docs.aws.amazon.com/redshift/latest/dg/r_LISTAGG.html"""
        sql = "CREATE VIEW s.v AS SELECT STRING_AGG(name, ',') AS x FROM t;"
        out = _sql("sqlserver", "redshift", sql)
        assert "LISTAGG(name, ',')" in out

    def test_eomonth_to_last_day(self):
        """EOMONTH → LAST_DAY for Redshift. May wrap arg in CAST(AS DATE).
        Ref: https://docs.aws.amazon.com/redshift/latest/dg/r_LAST_DAY.html"""
        sql = "CREATE VIEW s.v AS SELECT EOMONTH(created_at) AS x FROM t;"
        out = _sql("sqlserver", "redshift", sql)
        assert "LAST_DAY(" in out, f"Expected LAST_DAY: {out}"
        assert "EOMONTH(" not in out.upper()

    def test_datetrunc_to_date_trunc(self):
        """DATETRUNC(MONTH, col) → DATE_TRUNC('MONTH', col) for Redshift.
        Ref: https://docs.aws.amazon.com/redshift/latest/dg/r_DATE_TRUNC.html"""
        sql = "CREATE VIEW s.v AS SELECT DATETRUNC(MONTH, created_at) AS m FROM t;"
        out = _sql("sqlserver", "redshift", sql)
        assert "DATE_TRUNC('MONTH', created_at)" in out

    def test_datepart_to_date_part(self):
        """DATEPART(year, col) → DATE_PART('year', col) for Redshift.
        Ref: https://docs.aws.amazon.com/redshift/latest/dg/r_DATE_PART_function.html"""
        sql = "CREATE VIEW s.v AS SELECT DATEPART(year, created_at) AS y FROM t;"
        out = _sql("sqlserver", "redshift", sql)
        assert "DATE_PART('year', created_at)" in out

    def test_len_to_length(self):
        """LEN → LENGTH for Redshift.
        Ref: https://docs.aws.amazon.com/redshift/latest/dg/r_LEN.html"""
        sql = "CREATE VIEW s.v AS SELECT LEN(name) AS n FROM t;"
        out = _sql("sqlserver", "redshift", sql)
        assert "LENGTH(name)" in out

    def test_ceiling_to_ceil(self):
        """CEILING → CEIL for Redshift.
        Ref: https://docs.aws.amazon.com/redshift/latest/dg/r_CEILING_FLOOR.html"""
        sql = "CREATE VIEW s.v AS SELECT CEILING(amount) AS c FROM t;"
        out = _sql("sqlserver", "redshift", sql)
        assert "CEIL(amount)" in out

    def test_backtick_to_double_quote(self):
        """BigQuery backtick identifiers → double-quote for Redshift."""
        sql = "CREATE OR REPLACE VIEW `ds.my_view` AS SELECT `col` FROM `ds.tbl`;"
        out = _sql("bigquery", "redshift", sql)
        assert "`" not in out


# ===========================================================================
# 2. TYPE MAPPING VALIDATION
# ===========================================================================

class TestTypeMappings:

    # BOOLEAN
    def test_boolean_to_oracle_number1(self):
        """BOOLEAN → Oracle NUMBER(1). Oracle 21c and earlier have no native BOOLEAN.
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Data-Types.html"""
        sql = "CREATE TABLE s.t (flag BOOLEAN NOT NULL);"
        out = _sql("redshift", "oracle", sql)
        assert "NUMBER(1)" in out

    def test_boolean_to_bigquery_bool(self):
        """BOOLEAN → BOOL in BigQuery.
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types#boolean_type"""
        sql = "CREATE TABLE s.t (flag BOOLEAN NOT NULL);"
        out = _sql("redshift", "bigquery", sql)
        assert "BOOL" in out

    def test_boolean_to_tsql_bit(self):
        """BOOLEAN → BIT in T-SQL.
        Ref: https://learn.microsoft.com/en-us/sql/t-sql/data-types/bit-transact-sql"""
        sql = "CREATE TABLE s.t (flag BOOLEAN NOT NULL);"
        out = _sql("redshift", "sqlserver", sql)
        assert "BIT" in out

    # TEXT / CLOB
    def test_text_to_oracle_clob(self):
        """Redshift TEXT → Oracle CLOB.
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Data-Types.html"""
        sql = "CREATE TABLE s.t (body TEXT);"
        out = _sql("redshift", "oracle", sql)
        assert "CLOB" in out, f"Expected CLOB for TEXT->Oracle: {out}"

    def test_text_to_bigquery_string(self):
        """TEXT → STRING in BigQuery.
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types#string_type"""
        sql = "CREATE TABLE s.t (body TEXT);"
        out = _sql("redshift", "bigquery", sql)
        assert "STRING" in out

    def test_text_to_tsql_varchar_max(self):
        """Redshift TEXT → VARCHAR(MAX) in T-SQL (TEXT/NTEXT are deprecated in SQL Server).
        Ref: https://learn.microsoft.com/en-us/sql/t-sql/data-types/char-and-varchar-transact-sql"""
        sql = "CREATE TABLE s.t (body TEXT);"
        out = _sql("redshift", "sqlserver", sql)
        assert "VARCHAR(MAX)" in out, f"Expected VARCHAR(MAX) for TEXT->SQL Server: {out}"

    # BIGINT
    def test_bigint_to_oracle_number(self):
        """BIGINT → NUMBER(19) in Oracle.
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Data-Types.html"""
        sql = "CREATE TABLE s.t (id BIGINT NOT NULL);"
        out = _sql("redshift", "oracle", sql)
        assert "NUMBER(19)" in out

    def test_bigint_to_bigquery_int64(self):
        """BIGINT → INT64 in BigQuery.
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types#integer_types"""
        sql = "CREATE TABLE s.t (id BIGINT NOT NULL);"
        out = _sql("redshift", "bigquery", sql)
        assert "INT64" in out

    def test_bigint_to_databricks_bigint(self):
        """BIGINT stays BIGINT in Databricks.
        Ref: https://docs.databricks.com/en/sql/language-manual/data-types/bigint-type.html"""
        sql = "CREATE TABLE s.t (id BIGINT NOT NULL);"
        out = _sql("redshift", "databricks", sql)
        assert "BIGINT" in out

    # DECIMAL / NUMERIC
    def test_decimal_to_snowflake_number(self):
        """DECIMAL(18,2) → NUMBER(18,2) in Snowflake.
        Ref: https://docs.snowflake.com/en/sql-reference/data-types-numeric#number"""
        sql = "CREATE TABLE s.t (amt DECIMAL(18,2) NOT NULL);"
        out = _sql("redshift", "snowflake", sql)
        assert "NUMBER(18,2)" in out

    def test_decimal_to_oracle_number(self):
        """DECIMAL(18,2) → NUMBER(18,2) in Oracle."""
        sql = "CREATE TABLE s.t (amt DECIMAL(18,2) NOT NULL);"
        out = _sql("redshift", "oracle", sql)
        assert "NUMBER(18,2)" in out

    def test_decimal_to_bigquery_numeric(self):
        """DECIMAL(18,2) → NUMERIC(18,2) in BigQuery.
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types#numeric_types"""
        sql = "CREATE TABLE s.t (amt DECIMAL(18,2) NOT NULL);"
        out = _sql("redshift", "bigquery", sql)
        assert "NUMERIC(18,2)" in out

    # TIMESTAMP
    def test_timestamp_to_sqlserver_datetime2(self):
        """TIMESTAMP → DATETIME2(6) in SQL Server.
        Ref: https://learn.microsoft.com/en-us/sql/t-sql/data-types/datetime2-transact-sql"""
        sql = "CREATE TABLE s.t (ts TIMESTAMP NOT NULL);"
        out = _sql("redshift", "sqlserver", sql)
        assert "DATETIME2" in out

    def test_timestamp_to_oracle_timestamp(self):
        """TIMESTAMP stays TIMESTAMP in Oracle."""
        sql = "CREATE TABLE s.t (ts TIMESTAMP NOT NULL);"
        out = _sql("redshift", "oracle", sql)
        assert "TIMESTAMP" in out

    def test_timestamp_to_bigquery_datetime(self):
        """TIMESTAMP (no-tz) → DATETIME in BigQuery.
        BigQuery DATETIME is timezone-agnostic (timezone-naive), matching SQL TIMESTAMP behavior.
        BigQuery TIMESTAMP is always UTC-normalized (timezone-aware).
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types#datetime_type"""
        sql = "CREATE TABLE s.t (ts TIMESTAMP NOT NULL);"
        out = _sql("redshift", "bigquery", sql)
        assert "DATETIME" in out

    # VARCHAR
    def test_varchar_to_oracle_varchar2(self):
        """VARCHAR → VARCHAR2 in Oracle.
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Data-Types.html"""
        sql = "CREATE TABLE s.t (name VARCHAR(100) NOT NULL);"
        out = _sql("redshift", "oracle", sql)
        assert "VARCHAR2(100)" in out

    def test_nvarchar_to_oracle_varchar2(self):
        """NVARCHAR → VARCHAR2 in Oracle."""
        sql = "CREATE TABLE s.t (name NVARCHAR(100) NOT NULL);"
        out = _sql("sqlserver", "oracle", sql)
        assert "VARCHAR2" in out

    def test_varchar_to_bigquery_string(self):
        """VARCHAR → STRING in BigQuery.
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types#string_type"""
        sql = "CREATE TABLE s.t (name VARCHAR(100));"
        out = _sql("redshift", "bigquery", sql)
        assert "STRING" in out

    def test_string_to_redshift_varchar(self):
        """Databricks STRING → VARCHAR in Redshift.
        Ref: https://docs.aws.amazon.com/redshift/latest/dg/r_Character_types.html"""
        sql = "CREATE OR REPLACE TABLE s.t (name STRING);"
        out = _sql("databricks", "redshift", sql)
        assert "VARCHAR" in out

    # IDENTITY columns
    def test_identity_fabric_dw_no_identity(self):
        """Fabric DW does NOT support IDENTITY — must be dropped.
        Ref: https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area"""
        sql = "CREATE TABLE dbo.t (id INT IDENTITY(1,1) NOT NULL);"
        out = _sql("sqlserver", "fabric_dw", sql)
        assert "IDENTITY" not in out.upper(), f"Fabric DW should not emit IDENTITY: {out}"

    def test_identity_sqlserver_kept(self):
        """SQL Server keeps IDENTITY(start, step).
        Ref: https://learn.microsoft.com/en-us/sql/t-sql/functions/identity-function-transact-sql"""
        sql = "CREATE TABLE dbo.t (id BIGINT IDENTITY(1,1) NOT NULL);"
        out = _sql("sqlserver", "sqlserver", sql)
        assert "IDENTITY(1,1)" in out

    def test_identity_oracle_generated(self):
        """Identity → GENERATED BY DEFAULT ON NULL AS IDENTITY in Oracle.
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html"""
        sql = "CREATE TABLE dbo.t (id BIGINT IDENTITY(1,1) NOT NULL);"
        out = _sql("sqlserver", "oracle", sql)
        assert "GENERATED" in out.upper() and "IDENTITY" in out.upper()

    def test_identity_databricks_generated(self):
        """Identity → GENERATED ALWAYS AS IDENTITY in Databricks.
        Ref: https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-table-using.html"""
        sql = "CREATE TABLE s.t (id BIGINT IDENTITY(1,1) NOT NULL);"
        out = _sql("sqlserver", "databricks", sql)
        assert "GENERATED ALWAYS AS IDENTITY" in out

    def test_identity_bigquery_no_native(self):
        """BigQuery has no IDENTITY — should not emit IDENTITY syntax.
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language"""
        sql = "CREATE TABLE dbo.t (id BIGINT IDENTITY(1,1) NOT NULL);"
        out = _sql("sqlserver", "bigquery", sql)
        assert "IDENTITY" not in out

    # SUPER / VARIANT / JSON
    def test_super_to_snowflake_variant(self):
        """Redshift SUPER → VARIANT in Snowflake.
        Ref: https://docs.snowflake.com/en/sql-reference/data-types-semistructured"""
        sql = "CREATE TABLE s.t (payload SUPER);"
        out = _sql("redshift", "snowflake", sql)
        assert "VARIANT" in out

    def test_variant_to_bigquery_json(self):
        """Snowflake VARIANT → JSON or STRING in BigQuery (JSON available since BigQuery GA 2022)."""
        sql = "CREATE OR REPLACE TABLE s.t (payload VARIANT);"
        out = _sql("snowflake", "bigquery", sql)
        assert "JSON" in out or "STRING" in out


# ===========================================================================
# 3. MV PATTERN VALIDATION PER TARGET
# ===========================================================================

class TestMVPatterns:

    def test_fabric_dw_mv_is_ctas_plus_proc(self):
        """Fabric DW: MV → CTAS table + usp_refresh_ stored procedure.
        Fabric DW has no native CREATE MATERIALIZED VIEW syntax.
        Ref: https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area"""
        sql = "CREATE MATERIALIZED VIEW analytics.mv_test AS SELECT COUNT(*) AS n FROM analytics.t;"
        out = _sql("redshift", "fabric_dw", sql)
        assert "CREATE TABLE" in out
        assert "CREATE OR ALTER PROCEDURE" in out
        assert "usp_refresh_mv_test" in out.lower()
        assert "sp_rename" in out.lower()
        # Fabric DW must NOT emit a CREATE MATERIALIZED VIEW SQL statement.
        # The comment may say "does NOT support CREATE MATERIALIZED VIEW" — check only non-comment lines.
        non_comment_lines = [l for l in out.splitlines() if not l.strip().startswith("--")]
        assert not any("CREATE MATERIALIZED VIEW" in l for l in non_comment_lines), \
            f"Fabric DW must not have CREATE MATERIALIZED VIEW in SQL statements: {out}"

    def test_sqlserver_mv_is_indexed_view(self):
        """SQL Server: MV → CREATE VIEW WITH SCHEMABINDING + CREATE UNIQUE CLUSTERED INDEX.
        Ref: https://learn.microsoft.com/en-us/sql/relational-databases/views/create-indexed-views"""
        sql = "CREATE MATERIALIZED VIEW s.mv_test AS SELECT SUM(amount) AS total FROM s.t GROUP BY 1;"
        out = _sql("redshift", "sqlserver", sql)
        assert "WITH SCHEMABINDING" in out
        assert "CREATE UNIQUE CLUSTERED INDEX" in out

    def test_synapse_mv_native(self):
        """Synapse: Native CREATE MATERIALIZED VIEW AS SELECT with DISTRIBUTION.
        Ref: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-materialized-view-as-select-transact-sql"""
        sql = "CREATE MATERIALIZED VIEW s.mv_test AS SELECT SUM(amount) AS total FROM s.t GROUP BY 1;"
        out = _sql("redshift", "synapse", sql)
        assert "CREATE MATERIALIZED VIEW" in out
        assert "DISTRIBUTION" in out

    def test_oracle_mv_build_refresh(self):
        """Oracle: CREATE MATERIALIZED VIEW with BUILD IMMEDIATE and ENABLE QUERY REWRITE.
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-MATERIALIZED-VIEW.html"""
        sql = "CREATE MATERIALIZED VIEW s.mv_test AS SELECT SUM(amount) AS total FROM s.t GROUP BY 1;"
        out = _sql("redshift", "oracle", sql)
        assert "BUILD IMMEDIATE" in out
        assert "ENABLE QUERY REWRITE" in out
        assert "REFRESH ON" in out

    def test_snowflake_mv_native(self):
        """Snowflake: Native CREATE MATERIALIZED VIEW.
        Ref: https://docs.snowflake.com/en/sql-reference/sql/create-materialized-view"""
        sql = "CREATE MATERIALIZED VIEW analytics.mv_test AS SELECT SUM(amount) AS total FROM analytics.t GROUP BY 1;"
        out = _sql("redshift", "snowflake", sql)
        assert "CREATE MATERIALIZED VIEW" in out
        assert "BUILD IMMEDIATE" not in out

    def test_bigquery_mv_options(self):
        """BigQuery: CREATE MATERIALIZED VIEW with OPTIONS(enable_refresh, refresh_interval_minutes).
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_materialized_view_statement"""
        sql = "CREATE MATERIALIZED VIEW analytics.mv_test AS SELECT SUM(amount) AS total FROM analytics.t GROUP BY 1;"
        out = _sql("redshift", "bigquery", sql)
        assert "CREATE MATERIALIZED VIEW" in out
        assert "OPTIONS(" in out
        assert "enable_refresh" in out

    def test_databricks_mv_unity_catalog(self):
        """Databricks: CREATE MATERIALIZED VIEW (requires Unity Catalog).
        Ref: https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-materialized-view.html"""
        sql = "CREATE MATERIALIZED VIEW analytics.mv_test AS SELECT SUM(amount) AS total FROM analytics.t GROUP BY 1;"
        out = _sql("redshift", "databricks", sql)
        assert "CREATE MATERIALIZED VIEW" in out

    def test_redshift_mv_auto_refresh(self):
        """Redshift: CREATE MATERIALIZED VIEW with AUTO REFRESH.
        Ref: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_MATERIALIZED_VIEW.html"""
        sql = "CREATE MATERIALIZED VIEW analytics.mv_test AS SELECT SUM(amount) AS total FROM analytics.t GROUP BY 1;"
        out = _sql("redshift", "redshift", sql)
        assert "CREATE MATERIALIZED VIEW" in out
        assert "AUTO REFRESH" in out

    def test_oracle_mv_function_conversion(self):
        """Oracle MV body: T-SQL functions must be converted in MV body."""
        sql = "CREATE MATERIALIZED VIEW s.mv AS SELECT GETDATE() AS ts, ISNULL(col,0) AS c FROM t GROUP BY 1;"
        out = _sql("sqlserver", "oracle", sql)
        assert "SYSDATE" in out, f"GETDATE should be SYSDATE in Oracle MV: {out}"
        assert "NVL(" in out, f"ISNULL should be NVL in Oracle MV: {out}"


# ===========================================================================
# 4. DISTRIBUTION / SORT / CLUSTERING
# ===========================================================================

class TestDistributionClauses:
    def test_redshift_distkey_to_synapse_hash(self):
        """Redshift DISTKEY → Synapse DISTRIBUTION = HASH.
        Ref: https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-tables-distribute"""
        sql = """CREATE TABLE analytics.orders (id BIGINT NOT NULL, customer_id INTEGER NOT NULL)
DISTSTYLE KEY DISTKEY (customer_id) SORTKEY (id);"""
        out = _sql("redshift", "synapse", sql)
        assert "DISTRIBUTION = HASH" in out

    def test_redshift_distkey_to_fabric_no_distribution(self):
        """Redshift DISTKEY → Fabric DW drops DISTRIBUTION (not supported in Fabric DW).
        Fabric DW uses Delta Parquet for automatic distribution.
        Ref: https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area"""
        sql = """CREATE TABLE analytics.orders (id BIGINT NOT NULL, customer_id INTEGER NOT NULL)
DISTSTYLE KEY DISTKEY (customer_id);"""
        result = Transpiler.convert(sql, "redshift", "fabric_dw")
        out = result.converted_sql
        # Fabric DW silently drops DISTRIBUTION and emits an unsupported warning
        assert "DISTRIBUTION" not in out
        unsup = [w.feature for w in result.unsupported_features]
        assert any("DISTRIBUTION" in code for code in unsup)

    def test_snowflake_cluster_by_preserved(self):
        """Snowflake CLUSTER BY is preserved for Snowflake→Snowflake.
        Ref: https://docs.snowflake.com/en/user-guide/tables-clustering-keys"""
        sql = """CREATE OR REPLACE TABLE analytics.orders (id BIGINT, created_at TIMESTAMP)
CLUSTER BY (created_at);"""
        out = _sql("snowflake", "snowflake", sql)
        assert "CLUSTER BY" in out

    def test_sortkey_to_bigquery_cluster_by(self):
        """Redshift SORTKEY → BigQuery CLUSTER BY.
        Ref: https://cloud.google.com/bigquery/docs/clustered-tables"""
        sql = """CREATE TABLE analytics.orders (id BIGINT NOT NULL, created_at TIMESTAMP NOT NULL)
SORTKEY (created_at);"""
        out = _sql("redshift", "bigquery", sql)
        assert "CLUSTER BY" in out


# ===========================================================================
# 5. PROCEDURE / FUNCTION GENERATION
# ===========================================================================

class TestProcedures:
    def test_oracle_proc_format(self):
        """Oracle procedures use AS BEGIN...END name; syntax.
        Ref: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-PROCEDURE.html"""
        sql = "CREATE OR REPLACE PROCEDURE s.myproc(p IN NUMBER) AS BEGIN NULL; END myproc;"
        out = _sql("oracle", "oracle", sql)
        assert "AS" in out
        assert "BEGIN" in out
        assert "END" in out

    def test_databricks_proc_to_function(self):
        """Databricks has no stored procedures — converts to SQL UDF stub.
        Ref: https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-sql-function.html"""
        sql = "CREATE OR REPLACE PROCEDURE s.myproc(p_id INTEGER) LANGUAGE plpgsql AS $$ BEGIN NULL; END; $$;"
        out = _sql("redshift", "databricks", sql)
        assert "CREATE" in out and "FUNCTION" in out
        assert "-- Databricks does NOT support CREATE PROCEDURE" in out

    def test_bigquery_proc_begin_end(self):
        """BigQuery procedures use BEGIN...END.
        Ref: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_procedure"""
        sql = "CREATE OR REPLACE PROCEDURE s.myproc(IN p_id INT64) BEGIN SELECT 1; END;"
        out = _sql("bigquery", "bigquery", sql)
        assert "BEGIN" in out
        assert "END" in out

    def test_tsql_proc_or_alter(self):
        """SQL Server uses CREATE OR ALTER PROCEDURE.
        Ref: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql"""
        sql = "CREATE OR REPLACE PROCEDURE s.myproc(p_id INTEGER) LANGUAGE plpgsql AS $$ BEGIN NULL; END; $$;"
        out = _sql("redshift", "sqlserver", sql)
        assert "CREATE OR ALTER PROCEDURE" in out


# ===========================================================================
# 6. EDGE CASES — nested functions, NULL safety, string literals
# ===========================================================================

class TestEdgeCases:
    def test_nested_nvl_oracle_to_isnull(self):
        """Nested NVL(a, NVL(b, c)) → ISNULL(a, ISNULL(b, c)) for T-SQL — Oracle source keeps NVL."""
        sql = "CREATE OR REPLACE VIEW s.v AS SELECT NVL(a, NVL(b, 0)) AS x FROM t;"
        out = _sql("oracle", "sqlserver", sql)
        assert "ISNULL(a, ISNULL(b, 0))" in out

    def test_nested_coalesce_valid_in_tsql(self):
        """Redshift NVL normalizes to COALESCE at parse time — nested COALESCE is valid in T-SQL."""
        sql = "CREATE VIEW s.v AS SELECT NVL(a, NVL(b, 0)) AS x FROM t;"
        out = _sql("redshift", "sqlserver", sql)
        # COALESCE(a, COALESCE(b, 0)) is valid T-SQL
        assert "COALESCE(" in out

    def test_nvl_three_arg_to_coalesce(self):
        """NVL with 3+ args → COALESCE for T-SQL targets (oracle source)."""
        sql = "CREATE OR REPLACE VIEW s.v AS SELECT NVL(a, b, c) AS x FROM t;"
        out = _sql("oracle", "sqlserver", sql)
        assert "COALESCE(a, b, c)" in out

    def test_string_literal_not_converted(self):
        """String literals containing function names must NOT be converted."""
        sql = "CREATE VIEW s.v AS SELECT 'ISNULL is T-SQL' AS note, ISNULL(col, 0) AS c FROM t;"
        out = _sql("sqlserver", "oracle", sql)
        assert "'ISNULL is T-SQL'" in out
        assert "NVL(col, 0)" in out

    def test_ceil_not_matched_in_ceiling(self):
        """CEIL→CEILING conversion must NOT double-convert CEILING to CEILINGLING."""
        sql = "CREATE VIEW s.v AS SELECT CEILING(x) AS a, CEIL(y) AS b FROM t;"
        out = _sql("redshift", "sqlserver", sql)
        assert "CEILING(x)" in out
        assert "CEILING(y)" in out
        assert "CEILINGLING" not in out

    def test_len_not_matched_in_length(self):
        """LEN→LENGTH conversion must NOT produce LENGTHLENGTH."""
        sql = "CREATE VIEW s.v AS SELECT LENGTH(a) AS x, LEN(b) AS y FROM t;"
        out = _sql("redshift", "sqlserver", sql)
        assert "LENGTHLENGTH" not in out
        assert "LENLENGTH" not in out

    def test_charindex_to_instr_three_args(self):
        """CHARINDEX(needle, haystack, start) → INSTR(haystack, needle, start) for Oracle."""
        sql = "CREATE VIEW s.v AS SELECT CHARINDEX('@', email, 5) AS pos FROM t;"
        out = _sql("sqlserver", "oracle", sql)
        assert "INSTR(email, '@', 5)" in out

    def test_all_source_dialects_to_all_targets_nocrash(self):
        """Smoke test: all 8×8 combinations must not throw an exception."""
        sources = ["redshift", "snowflake", "sqlserver", "synapse", "fabric_dw", "databricks", "oracle", "bigquery"]
        targets = sources[:]
        view_sql = {
            "redshift": "CREATE OR REPLACE VIEW s.v AS SELECT NVL(a, 0) AS x FROM t;",
            "snowflake": "CREATE OR REPLACE VIEW s.v AS SELECT NVL(a, 0) AS x FROM t;",
            "sqlserver": "CREATE VIEW s.v AS SELECT ISNULL(a, 0) AS x FROM t;",
            "synapse": "CREATE VIEW s.v AS SELECT ISNULL(a, 0) AS x FROM t;",
            "fabric_dw": "CREATE VIEW s.v AS SELECT ISNULL(a, 0) AS x FROM t;",
            "databricks": "CREATE OR REPLACE VIEW s.v AS SELECT COALESCE(a, 0) AS x FROM t;",
            "oracle": "CREATE OR REPLACE VIEW s.v AS SELECT NVL(a, 0) AS x FROM t;",
            "bigquery": "CREATE OR REPLACE VIEW `s.v` AS SELECT IFNULL(a, 0) AS x FROM `s.t`;",
        }
        for src in sources:
            for tgt in targets:
                result = Transpiler.convert(view_sql[src], src, tgt)
                assert result.converted_sql.strip(), f"{src}→{tgt} returned empty output"


# ===========================================================================
# 7. WARNINGS EMITTED FOR UNSUPPORTED FEATURES
# ===========================================================================

class TestWarningsEmitted:
    def test_initcap_warning_in_tsql(self):
        """INITCAP() must emit an unsupported warning for T-SQL targets.
        Ref: No T-SQL INITCAP equivalent."""
        sql = "CREATE OR REPLACE VIEW s.v AS SELECT INITCAP(name) AS n FROM t;"
        result = Transpiler.convert(sql, "oracle", "sqlserver")
        all_codes = [w.feature for w in _all_warnings(result)]
        assert any("INITCAP" in code for code in all_codes), f"Expected INITCAP warning: {all_codes}"

    def test_regexp_warning_in_tsql(self):
        """REGEXP_REPLACE must emit an unsupported warning for T-SQL targets."""
        sql = "CREATE VIEW s.v AS SELECT REGEXP_REPLACE(name, '[0-9]', '') AS n FROM t;"
        result = Transpiler.convert(sql, "redshift", "sqlserver")
        all_codes = [w.feature for w in _all_warnings(result)]
        assert any("REGEXP" in code for code in all_codes), f"Expected REGEXP warning: {all_codes}"

    def test_fabric_dw_mv_warning(self):
        """Fabric DW MV conversion must emit an unsupported_feature warning."""
        sql = "CREATE MATERIALIZED VIEW s.mv AS SELECT COUNT(*) AS n FROM t;"
        result = Transpiler.convert(sql, "redshift", "fabric_dw")
        all_codes = [w.feature for w in _all_warnings(result)]
        assert any("MV" in code or "MATERIALIZED" in code for code in all_codes), \
            f"Expected MV warning: {all_codes}"

    def test_sqlserver_mv_warning(self):
        """SQL Server MV → indexed view must emit a warning or produce SCHEMABINDING."""
        sql = "CREATE MATERIALIZED VIEW s.mv AS SELECT COUNT(*) AS n FROM t;"
        result = Transpiler.convert(sql, "redshift", "sqlserver")
        all_codes = [w.feature for w in _all_warnings(result)]
        out = result.converted_sql
        has_warning = any("MV" in code or "INDEXED" in code or "SCHEMABINDING" in code for code in all_codes)
        has_comment = "SCHEMABINDING" in out or "indexed view" in out.lower()
        assert has_warning or has_comment, f"Expected MV advisory for SQL Server: {all_codes}"

    def test_fabric_dw_no_identity_warning(self):
        """Fabric DW should warn (unsupported_features) when IDENTITY is dropped."""
        sql = "CREATE TABLE dbo.t (id BIGINT IDENTITY(1,1) NOT NULL);"
        result = Transpiler.convert(sql, "sqlserver", "fabric_dw")
        all_codes = [w.feature for w in _all_warnings(result)]
        assert any("IDENTITY" in code for code in all_codes), \
            f"Expected IDENTITY warning: {all_codes}"

    def test_bigquery_mv_limitations_warning(self):
        """BigQuery MV must warn about query limitations."""
        sql = "CREATE MATERIALIZED VIEW analytics.mv AS SELECT SUM(amount) AS total FROM analytics.t GROUP BY 1;"
        result = Transpiler.convert(sql, "redshift", "bigquery")
        all_codes = [w.feature for w in _all_warnings(result)]
        assert any("BIGQUERY" in code or "MV" in code for code in all_codes), \
            f"Expected BigQuery MV warning: {all_codes}"
