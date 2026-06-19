"""
Real-world testing suite for the Universal SQL Transpiler.

Covers four categories:
  1. Never-crash guarantee  — every real DDL file in testing_ddls/ must return
                              a structured TranspileResult, never raise an exception.
  2. Column-name invariant  — CREATE TABLE output must contain every source column name.
  3. TPC-H benchmark schema — industry-standard 8-table benchmark transpiled to all 9
                              targets, verifying structural correctness end-to-end.
  4. Round-trip IR fidelity — transpile A→B→A and check table/column names survive.
"""
from __future__ import annotations

import re
from pathlib import Path
from typing import List, Tuple

import pytest

from app.transpiler import Transpiler

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

TESTING_DDLS_ROOT = Path(__file__).parent.parent.parent.parent / "testing_ddls"

ALL_DIALECTS = [
    "redshift", "snowflake", "sqlserver", "synapse",
    "fabric_dw", "fabric_lakehouse", "databricks", "oracle", "bigquery",
]

# Map folder name → dialect key
FOLDER_TO_DIALECT = {
    "redshift":        "redshift",
    "snowflake":       "snowflake",
    "sqlserver":       "sqlserver",
    "synapse":         "synapse",
    "fabric_dw":       "fabric_dw",
    "fabric_lakehouse":"fabric_lakehouse",
    "databricks":      "databricks",
    "oracle":          "oracle",
    "bigquery":        "bigquery",
}


def _collect_ddl_files() -> List[Tuple[str, str, Path]]:
    """Return (dialect_key, file_label, path) for every .sql file in testing_ddls/."""
    entries = []
    if not TESTING_DDLS_ROOT.exists():
        return entries
    for folder, dialect in FOLDER_TO_DIALECT.items():
        dialect_dir = TESTING_DDLS_ROOT / folder
        if not dialect_dir.exists():
            continue
        for sql_file in sorted(dialect_dir.rglob("*.sql")):
            label = sql_file.relative_to(TESTING_DDLS_ROOT).as_posix()
            entries.append((dialect, label, sql_file))
    return entries


def _extract_create_table_columns(sql: str) -> List[str]:
    """
    Heuristic: pull top-level column names from the first CREATE TABLE block.
    Returns lowercased identifiers. Skips constraint lines and nested
    STRUCT<...> / ARRAY<...> field definitions.
    """
    # Strip block comments
    sql = re.sub(r'/\*.*?\*/', '', sql, flags=re.DOTALL)
    # Find the column body between the first '(' after CREATE TABLE and matching ')'
    m = re.search(r'CREATE\s+(?:OR\s+REPLACE\s+)?(?:TEMPORARY\s+)?TABLE\s+[^\(]+\(', sql, re.I)
    if not m:
        return []
    body_start = m.end()
    depth = 1
    pos = body_start
    while pos < len(sql) and depth > 0:
        if sql[pos] == '(':
            depth += 1
        elif sql[pos] == ')':
            depth -= 1
        pos += 1
    body = sql[body_start:pos - 1]

    columns = []
    angle_depth = 0   # track STRUCT<...> / ARRAY<...> nesting
    for line in body.splitlines():
        stripped = line.strip().rstrip(',')
        if not stripped:
            continue
        # Track angle-bracket depth for STRUCT<...> / ARRAY<...>
        angle_depth += stripped.count('<') - stripped.count('>')
        # If we're inside a nested type definition (angle_depth > 0 before this line)
        # or this line is just a closing '>', skip it
        if angle_depth > 0 or stripped == '>':
            continue
        # Skip constraint lines
        if re.match(
            r'(PRIMARY\s+KEY|FOREIGN\s+KEY|UNIQUE|CHECK|CONSTRAINT|INDEX)', stripped, re.I
        ):
            continue
        # First token is the column name — strip quoting chars
        tok = stripped.split()[0] if stripped.split() else ''
        tok = re.sub(r'[`\[\]"\']', '', tok).lower()
        if tok and re.match(r'^[a-z_][a-z0-9_]*$', tok):
            columns.append(tok)
    return columns


DDL_FILES = _collect_ddl_files()


# ---------------------------------------------------------------------------
# 1. Never-crash guarantee
# ---------------------------------------------------------------------------

class TestNeverCrash:
    """
    Every real DDL file must be handled gracefully — the transpiler must
    return a TranspileResult, never raise a Python exception.

    Tests a subset of targets per source to keep the matrix manageable:
    each source file is transpiled to 3 representative targets.
    """

    _TARGET_SAMPLE = {
        "redshift":        ["snowflake", "fabric_dw",  "bigquery"],
        "snowflake":       ["redshift",  "databricks",  "sqlserver"],
        "sqlserver":       ["snowflake", "fabric_dw",   "oracle"],
        "synapse":         ["snowflake", "databricks",  "bigquery"],
        "fabric_dw":       ["snowflake", "redshift",    "databricks"],
        "fabric_lakehouse":["snowflake", "bigquery",    "sqlserver"],
        "databricks":      ["snowflake", "redshift",    "fabric_lakehouse"],
        "oracle":          ["snowflake", "redshift",    "databricks"],
        "bigquery":        ["snowflake", "redshift",    "sqlserver"],
    }

    @pytest.mark.parametrize("dialect,label,path", DDL_FILES, ids=[x[1] for x in DDL_FILES])
    def test_no_exception(self, dialect: str, label: str, path: Path):
        """Transpiling any real DDL file must not raise a Python exception."""
        sql = path.read_text(encoding="utf-8", errors="replace")
        targets = self._TARGET_SAMPLE.get(dialect, ["snowflake", "redshift", "bigquery"])
        for target in targets:
            try:
                result = Transpiler.convert(sql, dialect, target)
                # Must return something — even an empty result is acceptable
                assert result is not None, f"{label} → {target}: returned None"
            except Exception as exc:  # noqa: BLE001
                pytest.fail(
                    f"Transpiler raised an exception for {label} → {target}:\n"
                    f"{type(exc).__name__}: {exc}"
                )


# ---------------------------------------------------------------------------
# 2. Column-name invariant for CREATE TABLE files
# ---------------------------------------------------------------------------

# Only include files that are known TABLE DDL (not views/MVs)
TABLE_DDL_FILES = [
    (d, lbl, p)
    for d, lbl, p in DDL_FILES
    if "table" in lbl.lower() and "view" not in lbl.lower()
]


class TestColumnNameInvariant:
    """
    After transpiling a CREATE TABLE, every source column name should appear
    verbatim (case-insensitive) in the output SQL.

    This catches cases where the transpiler silently drops columns.
    """

    @pytest.mark.parametrize("dialect,label,path", TABLE_DDL_FILES,
                             ids=[x[1] for x in TABLE_DDL_FILES])
    def test_columns_preserved_to_snowflake(self, dialect: str, label: str, path: Path):
        sql = path.read_text(encoding="utf-8", errors="replace")
        source_cols = _extract_create_table_columns(sql)
        if not source_cols:
            pytest.skip(f"No CREATE TABLE columns extracted from {label}")

        result = Transpiler.convert(sql, dialect, "snowflake")
        if not result.converted_sql:
            pytest.skip(f"No output produced for {label} → snowflake")

        out_lower = result.converted_sql.lower()
        missing = [c for c in source_cols if c not in out_lower]
        assert not missing, (
            f"{label} → snowflake: {len(missing)}/{len(source_cols)} columns missing "
            f"from output: {missing[:5]}"
        )

    @pytest.mark.parametrize("dialect,label,path", TABLE_DDL_FILES,
                             ids=[x[1] for x in TABLE_DDL_FILES])
    def test_columns_preserved_to_sqlserver(self, dialect: str, label: str, path: Path):
        sql = path.read_text(encoding="utf-8", errors="replace")
        source_cols = _extract_create_table_columns(sql)
        if not source_cols:
            pytest.skip(f"No CREATE TABLE columns extracted from {label}")

        result = Transpiler.convert(sql, dialect, "sqlserver")
        if not result.converted_sql:
            pytest.skip(f"No output produced for {label} → sqlserver")

        out_lower = result.converted_sql.lower()
        missing = [c for c in source_cols if c not in out_lower]
        assert not missing, (
            f"{label} → sqlserver: {len(missing)}/{len(source_cols)} columns missing "
            f"from output: {missing[:5]}"
        )


# ---------------------------------------------------------------------------
# 3. TPC-H Benchmark Schema (industry standard, 8 tables)
# ---------------------------------------------------------------------------

# TPC-H tables written in Snowflake dialect — the industry standard OLAP benchmark.
# Source: TPC-H specification v3.0.1 (tpc.org/tpch)
TPCH_SNOWFLAKE = """
CREATE OR REPLACE TABLE tpch.region (
    r_regionkey  NUMBER(10,0)  NOT NULL,
    r_name       CHAR(25)      NOT NULL,
    r_comment    VARCHAR(152),
    PRIMARY KEY (r_regionkey)
);

CREATE OR REPLACE TABLE tpch.nation (
    n_nationkey  NUMBER(10,0)  NOT NULL,
    n_name       CHAR(25)      NOT NULL,
    n_regionkey  NUMBER(10,0)  NOT NULL,
    n_comment    VARCHAR(152),
    PRIMARY KEY (n_nationkey),
    FOREIGN KEY (n_regionkey) REFERENCES tpch.region (r_regionkey)
);

CREATE OR REPLACE TABLE tpch.supplier (
    s_suppkey    NUMBER(10,0)  NOT NULL,
    s_name       CHAR(25)      NOT NULL,
    s_address    VARCHAR(40)   NOT NULL,
    s_nationkey  NUMBER(10,0)  NOT NULL,
    s_phone      CHAR(15)      NOT NULL,
    s_acctbal    NUMBER(15,2)  NOT NULL,
    s_comment    VARCHAR(101),
    PRIMARY KEY (s_suppkey),
    FOREIGN KEY (s_nationkey) REFERENCES tpch.nation (n_nationkey)
);

CREATE OR REPLACE TABLE tpch.part (
    p_partkey    NUMBER(10,0)  NOT NULL,
    p_name       VARCHAR(55)   NOT NULL,
    p_mfgr       CHAR(25)      NOT NULL,
    p_brand      CHAR(10)      NOT NULL,
    p_type       VARCHAR(25)   NOT NULL,
    p_size       NUMBER(10,0)  NOT NULL,
    p_container  CHAR(10)      NOT NULL,
    p_retailprice NUMBER(15,2) NOT NULL,
    p_comment    VARCHAR(23),
    PRIMARY KEY (p_partkey)
);

CREATE OR REPLACE TABLE tpch.partsupp (
    ps_partkey     NUMBER(10,0)  NOT NULL,
    ps_suppkey     NUMBER(10,0)  NOT NULL,
    ps_availqty    NUMBER(10,0)  NOT NULL,
    ps_supplycost  NUMBER(15,2)  NOT NULL,
    ps_comment     VARCHAR(199),
    PRIMARY KEY (ps_partkey, ps_suppkey)
);

CREATE OR REPLACE TABLE tpch.customer (
    c_custkey    NUMBER(10,0)  NOT NULL,
    c_name       VARCHAR(25)   NOT NULL,
    c_address    VARCHAR(40)   NOT NULL,
    c_nationkey  NUMBER(10,0)  NOT NULL,
    c_phone      CHAR(15)      NOT NULL,
    c_acctbal    NUMBER(15,2)  NOT NULL,
    c_mktsegment CHAR(10),
    c_comment    VARCHAR(117),
    PRIMARY KEY (c_custkey)
);

CREATE OR REPLACE TABLE tpch.orders (
    o_orderkey      NUMBER(10,0)  NOT NULL,
    o_custkey       NUMBER(10,0)  NOT NULL,
    o_orderstatus   CHAR(1)       NOT NULL,
    o_totalprice    NUMBER(15,2)  NOT NULL,
    o_orderdate     DATE          NOT NULL,
    o_orderpriority CHAR(15)      NOT NULL,
    o_clerk         CHAR(15)      NOT NULL,
    o_shippriority  NUMBER(10,0)  NOT NULL,
    o_comment       VARCHAR(79),
    PRIMARY KEY (o_orderkey),
    FOREIGN KEY (o_custkey) REFERENCES tpch.customer (c_custkey)
);

CREATE OR REPLACE TABLE tpch.lineitem (
    l_orderkey       NUMBER(10,0)  NOT NULL,
    l_partkey        NUMBER(10,0)  NOT NULL,
    l_suppkey        NUMBER(10,0)  NOT NULL,
    l_linenumber     NUMBER(10,0)  NOT NULL,
    l_quantity       NUMBER(15,2)  NOT NULL,
    l_extendedprice  NUMBER(15,2)  NOT NULL,
    l_discount       NUMBER(15,2)  NOT NULL,
    l_tax            NUMBER(15,2)  NOT NULL,
    l_returnflag     CHAR(1)       NOT NULL,
    l_linestatus     CHAR(1)       NOT NULL,
    l_shipdate       DATE          NOT NULL,
    l_commitdate     DATE          NOT NULL,
    l_receiptdate    DATE          NOT NULL,
    l_shipinstruct   CHAR(25)      NOT NULL,
    l_shipmode       CHAR(10)      NOT NULL,
    l_comment        VARCHAR(44),
    PRIMARY KEY (l_orderkey, l_linenumber)
);
"""

# Key column names that must survive transpilation in TPC-H
TPCH_SENTINEL_COLUMNS = [
    "r_regionkey", "r_name",
    "n_nationkey", "n_regionkey",
    "s_suppkey", "s_nationkey", "s_acctbal",
    "p_partkey", "p_retailprice",
    "c_custkey", "c_nationkey", "c_acctbal",
    "o_orderkey", "o_custkey", "o_totalprice", "o_orderdate",
    "l_orderkey", "l_extendedprice", "l_discount", "l_shipdate",
]


class TestTPCHBenchmark:
    """
    TPC-H (8 tables, 61 columns) transpiled to all 9 targets.
    Industry-standard OLAP schema stress-tests type mapping, FK handling,
    and composite PKs across the full dialect matrix.
    """

    @pytest.mark.parametrize("target", ALL_DIALECTS)
    def test_tpch_no_crash(self, target: str):
        """TPC-H 8-table schema must transpile without exception to every target."""
        result = Transpiler.convert(TPCH_SNOWFLAKE, "snowflake", target)
        assert result is not None
        assert result.converted_sql, f"Empty output for TPC-H → {target}"

    @pytest.mark.parametrize("target", ALL_DIALECTS)
    def test_tpch_all_tables_present(self, target: str):
        """All 8 TPC-H table names must appear in the output for every target."""
        result = Transpiler.convert(TPCH_SNOWFLAKE, "snowflake", target)
        out = result.converted_sql.lower()
        tables = ["region", "nation", "supplier", "part", "partsupp",
                  "customer", "orders", "lineitem"]
        missing = [t for t in tables if t not in out]
        assert not missing, f"TPC-H → {target}: missing tables: {missing}"

    @pytest.mark.parametrize("target", ALL_DIALECTS)
    def test_tpch_sentinel_columns_present(self, target: str):
        """Key TPC-H column names must appear in every target output."""
        result = Transpiler.convert(TPCH_SNOWFLAKE, "snowflake", target)
        out = result.converted_sql.lower()
        missing = [c for c in TPCH_SENTINEL_COLUMNS if c not in out]
        assert not missing, (
            f"TPC-H → {target}: {len(missing)} sentinel columns missing: {missing[:5]}"
        )

    @pytest.mark.parametrize("target", ALL_DIALECTS)
    def test_tpch_has_create_table(self, target: str):
        """Output must contain 8 CREATE TABLE statements."""
        result = Transpiler.convert(TPCH_SNOWFLAKE, "snowflake", target)
        count = len(re.findall(r'CREATE\s+(?:OR\s+REPLACE\s+)?TABLE', result.converted_sql, re.I))
        assert count == 8, (
            f"TPC-H → {target}: expected 8 CREATE TABLE statements, got {count}"
        )

    def test_tpch_redshift_uses_drop_for_or_replace(self):
        """Redshift target must use DROP TABLE IF EXISTS for each OR REPLACE table."""
        result = Transpiler.convert(TPCH_SNOWFLAKE, "snowflake", "redshift")
        drops = len(re.findall(r'DROP TABLE IF EXISTS', result.converted_sql, re.I))
        assert drops == 8, f"Expected 8 DROP TABLE IF EXISTS for Redshift, got {drops}"

    def test_tpch_oracle_has_plsql_blocks(self):
        """Oracle target must emit PL/SQL anonymous blocks for OR REPLACE."""
        result = Transpiler.convert(TPCH_SNOWFLAKE, "snowflake", "oracle")
        executes = len(re.findall(r'EXECUTE IMMEDIATE', result.converted_sql, re.I))
        assert executes == 8, f"Expected 8 EXECUTE IMMEDIATE blocks for Oracle, got {executes}"

    def test_tpch_sqlserver_uses_go_separator(self):
        """SQL Server target must use GO to separate DROP from CREATE."""
        result = Transpiler.convert(TPCH_SNOWFLAKE, "snowflake", "sqlserver")
        assert "GO" in result.converted_sql

    def test_tpch_databricks_uses_delta(self):
        """Databricks target must use USING DELTA for every table."""
        result = Transpiler.convert(TPCH_SNOWFLAKE, "snowflake", "databricks")
        delta_count = len(re.findall(r'USING DELTA', result.converted_sql, re.I))
        assert delta_count == 8, f"Expected 8 USING DELTA clauses, got {delta_count}"


# ---------------------------------------------------------------------------
# 4. Round-trip IR fidelity (A → B → A)
# ---------------------------------------------------------------------------

# Hand-picked representative DDLs that cover diverse type/feature combinations
ROUND_TRIP_CASES = [
    ("redshift", """
        CREATE TABLE analytics.fact_sales (
            sale_id     BIGINT        NOT NULL,
            product_id  INTEGER       NOT NULL,
            region      VARCHAR(50)   NOT NULL,
            sale_amount DECIMAL(15,2) NOT NULL,
            sale_date   DATE          NOT NULL,
            created_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            is_returned BOOLEAN       DEFAULT FALSE,
            PRIMARY KEY (sale_id)
        )
        DISTKEY(product_id)
        SORTKEY(sale_date);
    """),
    ("snowflake", """
        CREATE OR REPLACE TABLE warehouse.dim_product (
            product_id   NUMBER(10,0)  NOT NULL,
            product_name VARCHAR(200)  NOT NULL,
            category     VARCHAR(100),
            price        NUMBER(10,2)  NOT NULL,
            is_active    BOOLEAN       DEFAULT TRUE,
            created_at   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
            PRIMARY KEY (product_id)
        );
    """),
    ("sqlserver", """
        CREATE TABLE dbo.dim_date (
            date_key       INT           NOT NULL,
            full_date      DATE          NOT NULL,
            year           SMALLINT      NOT NULL,
            quarter        TINYINT       NOT NULL,
            month          TINYINT       NOT NULL,
            day_of_week    TINYINT       NOT NULL,
            is_weekend     BIT           NOT NULL DEFAULT 0,
            fiscal_year    SMALLINT,
            PRIMARY KEY (date_key)
        );
    """),
    ("bigquery", """
        CREATE OR REPLACE TABLE `project.dataset.events` (
            event_id     INT64         NOT NULL,
            user_id      INT64         NOT NULL,
            event_type   STRING        NOT NULL,
            event_ts     TIMESTAMP     NOT NULL,
            properties   JSON,
            session_id   STRING,
            PRIMARY KEY (event_id) NOT ENFORCED
        );
    """),
]


class TestRoundTripFidelity:
    """
    Transpile A → B then B → A. The final output should contain all original
    column names and the table name, proving the IR faithfully encodes and
    re-encodes semantics across the round-trip.
    """

    @pytest.mark.parametrize("source,sql", ROUND_TRIP_CASES,
                             ids=[x[0] for x in ROUND_TRIP_CASES])
    def test_redshift_roundtrip(self, source: str, sql: str):
        """A → Redshift → A: column names preserved."""
        self._check_roundtrip(sql, source, "redshift")

    @pytest.mark.parametrize("source,sql", ROUND_TRIP_CASES,
                             ids=[x[0] for x in ROUND_TRIP_CASES])
    def test_snowflake_roundtrip(self, source: str, sql: str):
        """A → Snowflake → A: column names preserved."""
        self._check_roundtrip(sql, source, "snowflake")

    @pytest.mark.parametrize("source,sql", ROUND_TRIP_CASES,
                             ids=[x[0] for x in ROUND_TRIP_CASES])
    def test_databricks_roundtrip(self, source: str, sql: str):
        """A → Databricks → A: column names preserved."""
        self._check_roundtrip(sql, source, "databricks")

    def _check_roundtrip(self, original_sql: str, source: str, intermediate: str):
        source_cols = _extract_create_table_columns(original_sql)
        if not source_cols:
            pytest.skip("No columns extracted from source SQL")

        # Forward: source → intermediate
        mid = Transpiler.convert(original_sql, source, intermediate)
        assert mid.converted_sql, f"Empty output for {source} → {intermediate}"

        # Backward: intermediate → source
        back = Transpiler.convert(mid.converted_sql, intermediate, source)
        assert back.converted_sql, f"Empty output for {intermediate} → {source}"

        out_lower = back.converted_sql.lower()
        missing = [c for c in source_cols if c not in out_lower]
        assert not missing, (
            f"Round-trip {source}→{intermediate}→{source}: "
            f"{len(missing)}/{len(source_cols)} columns lost: {missing}"
        )


# ---------------------------------------------------------------------------
# 5. Crash-resistance with malformed / edge-case SQL
# ---------------------------------------------------------------------------

EDGE_CASE_SQLS = [
    ("empty_string",           ""),
    ("whitespace_only",        "   \n\t  "),
    ("comment_only",           "-- just a comment\n"),
    ("select_not_ddl",         "SELECT * FROM foo WHERE id = 1;"),
    ("truncated_create",       "CREATE TABLE"),
    ("no_columns",             "CREATE TABLE foo ();"),
    ("deeply_nested_parens",   "CREATE TABLE t (a INT CHECK ((((a > 0))));"),
    ("unicode_identifiers",    "CREATE TABLE résumé (prénom VARCHAR(50), âge INT);"),
    ("very_long_identifier",   f"CREATE TABLE {'x' * 200} (id INT NOT NULL);"),
    ("multiple_statements",    "CREATE TABLE a (id INT); CREATE TABLE b (id INT); CREATE TABLE c (id INT);"),
]


class TestEdgeCases:
    """
    Malformed and edge-case SQL inputs must never crash the transpiler.
    They may return empty output or error warnings but must not raise exceptions.
    """

    @pytest.mark.parametrize("label,sql", EDGE_CASE_SQLS, ids=[x[0] for x in EDGE_CASE_SQLS])
    @pytest.mark.parametrize("target", ["snowflake", "sqlserver", "databricks"])
    def test_no_exception_on_edge_input(self, label: str, sql: str, target: str):
        try:
            result = Transpiler.convert(sql, "redshift", target)
            assert result is not None
        except Exception as exc:  # noqa: BLE001
            pytest.fail(
                f"Edge case '{label}' → {target} raised {type(exc).__name__}: {exc}"
            )
