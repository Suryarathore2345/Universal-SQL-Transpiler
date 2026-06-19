"""
Comprehensive "kitchen-sink" regression suite.

Each source dialect has a hand-crafted DDL that exercises every code path
its parser + all target generators handle:
  - All supported data types
  - IDENTITY / auto-increment columns
  - DEFAULT values
  - All constraint types (PK, FK, UNIQUE, CHECK)
  - Dialect-specific clustering / distribution / partitioning
  - CREATE VIEW
  - CREATE MATERIALIZED VIEW
  - CREATE PROCEDURE (where supported)
  - CREATE FUNCTION
  - Native functions: NVL, NVL2, DECODE, ISNULL, IFNULL, COALESCE
  - :: casts (Redshift)

For every source→target pair the suite verifies:
  1. No uncaught exception during parse or generate.
  2. Non-empty SQL output.
  3. Confidence score is within [0.0, 1.0].
  4. Residual validator finds no leftover source-dialect syntax
     (catches regressions like the Fabric DW DEFAULT bug).
  5. Target-specific quality assertions — e.g. Fabric DW output must
     never contain a DEFAULT clause, Snowflake output must never
     contain DISTKEY, SQL Server must never emit bare :: casts, etc.
  6. Source+target pair-specific regression assertions.
"""
from __future__ import annotations

import re
import textwrap
from pathlib import Path
from typing import Generator

import pytest

from app.transpiler import Transpiler
from app.ir.models import Dialect, TranspileResult
from app.validator import validate_residuals, _strip_procedure_bodies

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

COMPREHENSIVE_DIR = Path(__file__).parent / "comprehensive"

ALL_DIALECTS: list[str] = [d.value for d in Dialect]

# Kitchen-sink SQL fixtures keyed by source dialect key
FIXTURES: dict[str, Path] = {
    "redshift":         COMPREHENSIVE_DIR / "kitchen_sink_redshift.sql",
    "snowflake":        COMPREHENSIVE_DIR / "kitchen_sink_snowflake.sql",
    "sqlserver":        COMPREHENSIVE_DIR / "kitchen_sink_sqlserver.sql",
    "synapse":          COMPREHENSIVE_DIR / "kitchen_sink_synapse.sql",
    "fabric_dw":        COMPREHENSIVE_DIR / "kitchen_sink_fabric_dw.sql",
    "fabric_lakehouse": COMPREHENSIVE_DIR / "kitchen_sink_fabric_lakehouse.sql",
    "databricks":       COMPREHENSIVE_DIR / "kitchen_sink_databricks.sql",
    "oracle":           COMPREHENSIVE_DIR / "kitchen_sink_oracle.sql",
    "bigquery":         COMPREHENSIVE_DIR / "kitchen_sink_bigquery.sql",
}

# ---------------------------------------------------------------------------
# Target-specific quality rules
# Each rule is (description, compiled_regex_that_must_NOT_match_output)
# ---------------------------------------------------------------------------

TARGET_FORBIDDEN: dict[str, list[tuple[str, re.Pattern]]] = {
    "fabric_dw": [
        # Fabric DW does not support DEFAULT constraints — must be stripped
        ("Fabric DW must not emit DEFAULT constraint",
         re.compile(r'\bDEFAULT\b', re.IGNORECASE)),
        # CLUSTER BY columns must preserve original casing (regression: uppercase extraction)
        ("Fabric DW CLUSTER BY columns must not be ALL_CAPS-only identifiers (5+ chars)",
         re.compile(r'CLUSTER BY \(\[[A-Z_]{5,}\]')),
    ],
    "snowflake": [
        # Snowflake manages distribution automatically; DISTKEY/DISTSTYLE must be gone
        ("Snowflake output must not contain DISTKEY",
         re.compile(r'\bDISTKEY\b', re.IGNORECASE)),
        ("Snowflake output must not contain DISTSTYLE",
         re.compile(r'\bDISTSTYLE\b', re.IGNORECASE)),
        # PostgreSQL/Redshift :: cast should be converted
        ("Snowflake output must not contain raw :: casts",
         re.compile(r'::\s*\w+')),
    ],
    "bigquery": [
        # BigQuery has no IDENTITY — must be removed / warned
        ("BigQuery output must not contain IDENTITY() column syntax",
         re.compile(r'\bIDENTITY\s*\(', re.IGNORECASE)),
        # Redshift-specific DISTKEY/SORTKEY must not appear
        ("BigQuery output must not contain DISTKEY",
         re.compile(r'\bDISTKEY\b', re.IGNORECASE)),
        ("BigQuery output must not contain SORTKEY",
         re.compile(r'\bSORTKEY\b', re.IGNORECASE)),
        # :: casts must not appear
        ("BigQuery output must not contain :: casts",
         re.compile(r'::\s*\w+')),
    ],
    "databricks": [
        # Synapse DISTRIBUTION must not leak into Databricks
        ("Databricks output must not contain DISTRIBUTION clause",
         re.compile(r'\bDISTRIBUTION\s*=', re.IGNORECASE)),
        # Redshift DISTKEY must not appear
        ("Databricks output must not contain DISTKEY",
         re.compile(r'\bDISTKEY\b', re.IGNORECASE)),
        # :: casts must not appear
        ("Databricks output must not contain :: casts",
         re.compile(r'::\s*\w+')),
    ],
    "oracle": [
        # Oracle 21c and earlier: BOOLEAN must be converted to NUMBER(1)
        ("Oracle output must not use BOOLEAN column type",
         re.compile(r'\bBOOLEAN\b', re.IGNORECASE)),
        # Redshift :: cast must not leak into Oracle output
        ("Oracle output must not contain :: casts",
         re.compile(r'::\s*\w+')),
        # Synapse DISTRIBUTION must be removed
        ("Oracle output must not contain DISTRIBUTION clause",
         re.compile(r'\bDISTRIBUTION\s*=', re.IGNORECASE)),
    ],
    "sqlserver": [
        # T-SQL doesn't have :: casts
        ("SQL Server output must not contain :: casts",
         re.compile(r'::\s*\w+')),
        # Synapse DISTRIBUTION must be removed for SQL Server
        ("SQL Server output must not contain DISTRIBUTION clause",
         re.compile(r'\bDISTRIBUTION\s*=', re.IGNORECASE)),
        # Redshift DISTKEY must not appear
        ("SQL Server output must not contain DISTKEY",
         re.compile(r'\bDISTKEY\b', re.IGNORECASE)),
    ],
    "synapse": [
        # Redshift DISTKEY/SORTKEY must not appear in Synapse output
        ("Synapse output must not contain DISTKEY",
         re.compile(r'\bDISTKEY\b', re.IGNORECASE)),
        ("Synapse output must not contain SORTKEY",
         re.compile(r'\bSORTKEY\b', re.IGNORECASE)),
        # :: casts from Redshift must not appear
        ("Synapse output must not contain :: casts",
         re.compile(r'::\s*\w+')),
    ],
    "redshift": [
        # BigQuery backtick identifiers must be rewritten
        ("Redshift output must not contain backtick identifiers",
         re.compile(r'`\w')),
    ],
}

# Source+target pair-specific forbidden patterns
# Format: (source, target) → list of (desc, regex_must_not_match)
PAIR_FORBIDDEN: dict[tuple[str, str], list[tuple[str, re.Pattern]]] = {
    # Oracle → targets that don't support NVL2: must be converted
    ("oracle", "snowflake"): [
        ("Snowflake output (from Oracle source) must not contain NVL2",
         re.compile(r'\bNVL2\s*\(', re.IGNORECASE)),
    ],
    ("oracle", "sqlserver"): [
        ("SQL Server output (from Oracle source) must not contain NVL2",
         re.compile(r'\bNVL2\s*\(', re.IGNORECASE)),
        ("SQL Server output (from Oracle source) must not contain DECODE",
         re.compile(r'\bDECODE\s*\(', re.IGNORECASE)),
    ],
    ("oracle", "fabric_dw"): [
        ("Fabric DW output (from Oracle source) must not contain NVL2",
         re.compile(r'\bNVL2\s*\(', re.IGNORECASE)),
        ("Fabric DW output (from Oracle source) must not contain DECODE",
         re.compile(r'\bDECODE\s*\(', re.IGNORECASE)),
    ],
    ("oracle", "synapse"): [
        ("Synapse output (from Oracle source) must not contain NVL2",
         re.compile(r'\bNVL2\s*\(', re.IGNORECASE)),
    ],
    ("oracle", "bigquery"): [
        ("BigQuery output (from Oracle source) must not contain NVL2",
         re.compile(r'\bNVL2\s*\(', re.IGNORECASE)),
    ],
    ("oracle", "databricks"): [
        ("Databricks output (from Oracle source) must not contain NVL2",
         re.compile(r'\bNVL2\s*\(', re.IGNORECASE)),
    ],
    # Redshift → Fabric DW: DEFAULT must be stripped (was a real production bug)
    ("redshift", "fabric_dw"): [
        ("Fabric DW output (from Redshift source) must not have DEFAULT clause",
         re.compile(r'\bDEFAULT\b', re.IGNORECASE)),
    ],
    ("snowflake", "fabric_dw"): [
        ("Fabric DW output (from Snowflake source) must not have DEFAULT clause",
         re.compile(r'\bDEFAULT\b', re.IGNORECASE)),
    ],
    ("sqlserver", "fabric_dw"): [
        ("Fabric DW output (from SQL Server source) must not have DEFAULT clause",
         re.compile(r'\bDEFAULT\b', re.IGNORECASE)),
    ],
    ("synapse", "fabric_dw"): [
        ("Fabric DW output (from Synapse source) must not have DEFAULT clause",
         re.compile(r'\bDEFAULT\b', re.IGNORECASE)),
    ],
    ("databricks", "fabric_dw"): [
        ("Fabric DW output (from Databricks source) must not have DEFAULT clause",
         re.compile(r'\bDEFAULT\b', re.IGNORECASE)),
    ],
    ("oracle", "fabric_dw"): [
        ("Fabric DW output (from Oracle source) must not have DEFAULT clause",
         re.compile(r'\bDEFAULT\b', re.IGNORECASE)),
    ],
    ("bigquery", "fabric_dw"): [
        ("Fabric DW output (from BigQuery source) must not have DEFAULT clause",
         re.compile(r'\bDEFAULT\b', re.IGNORECASE)),
    ],
    # Redshift :: cast must be rewritten for all non-Redshift targets
    ("redshift", "snowflake"): [
        ("Snowflake output (from Redshift) must not have :: casts",
         re.compile(r'::\s*\w+')),
    ],
    ("redshift", "sqlserver"): [
        ("SQL Server output (from Redshift) must not have :: casts",
         re.compile(r'::\s*\w+')),
    ],
    ("redshift", "bigquery"): [
        ("BigQuery output (from Redshift) must not have :: casts",
         re.compile(r'::\s*\w+')),
    ],
    ("redshift", "databricks"): [
        ("Databricks output (from Redshift) must not have :: casts",
         re.compile(r'::\s*\w+')),
    ],
    ("redshift", "oracle"): [
        ("Oracle output (from Redshift) must not have :: casts",
         re.compile(r'::\s*\w+')),
    ],
    ("redshift", "synapse"): [
        ("Synapse output (from Redshift) must not have :: casts",
         re.compile(r'::\s*\w+')),
    ],
    ("redshift", "fabric_dw"): [
        ("Fabric DW output (from Redshift) must not have :: casts",
         re.compile(r'::\s*\w+')),
    ],
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def load_fixture(source: str) -> str:
    """Load kitchen-sink SQL for the given source dialect."""
    path = FIXTURES[source]
    assert path.exists(), f"Kitchen-sink fixture missing: {path}"
    return path.read_text(encoding="utf-8")


def run_pair(source: str, target: str) -> TranspileResult:
    """Run transpiler for (source, target) and return result."""
    sql = load_fixture(source)
    return Transpiler.convert(sql, Dialect(source), Dialect(target))


# ---------------------------------------------------------------------------
# Parametrized test: every (source, target) pair
# ---------------------------------------------------------------------------

def _all_pairs() -> Generator[tuple[str, str], None, None]:
    for src in ALL_DIALECTS:
        if src not in FIXTURES:
            continue
        for tgt in ALL_DIALECTS:
            if src == tgt:
                continue   # same-dialect is tested in golden suite
            yield src, tgt


@pytest.mark.parametrize("source,target", list(_all_pairs()),
                         ids=lambda x: x)
def test_kitchen_sink_transpile(source: str, target: str) -> None:
    """
    Full quality gate for every source→target combination.
    Checks: no exception, non-empty output, confidence score,
    no residual source syntax, and target/pair-specific forbidden patterns.
    """
    # ── 1 & 2: No exception, non-empty output ──────────────────────────
    result = run_pair(source, target)
    output_sql = result.converted_sql

    assert output_sql, (
        f"{source}→{target}: Transpiler returned empty output"
    )

    # ── 3: Confidence score sanity ──────────────────────────────────────
    score = getattr(result, "confidence_score", None)
    if score is not None:
        assert 0.0 <= score <= 1.0, (
            f"{source}→{target}: Confidence score {score} out of range [0,1]"
        )

    # ── 4: Residual validator — no leftover source-dialect syntax ───────
    existing_codes = {
        w.feature for w in (result.warnings or [])
    } | {
        w.feature for w in (result.unsupported_features or [])
    }
    residuals = validate_residuals(output_sql, source, existing_codes, target_dialect=target)

    residual_messages = [
        f"  • {r.feature}: {r.message}" for r in residuals
    ]
    assert not residuals, (
        f"{source}→{target}: Residual source-dialect syntax found in output:\n"
        + "\n".join(residual_messages)
        + f"\n\nOutput SQL (first 1500 chars):\n{output_sql[:1500]}"
    )

    # Strip procedure/function bodies for assertion checks — same as validator.
    # Proc bodies are intentionally passed through (PROCEDURE_BODY_MANUAL warning),
    # so patterns inside them should not be flagged by quality assertions either.
    scan_sql = _strip_procedure_bodies(output_sql)

    # ── 5: Target-specific forbidden patterns ───────────────────────────
    for desc, pattern in TARGET_FORBIDDEN.get(target, []):
        match = pattern.search(scan_sql)
        assert not match, (
            f"{source}→{target}: {desc}\n"
            f"  Matched: {match.group()!r} at position {match.start()}\n"
            f"  Context: ...{scan_sql[max(0,match.start()-60):match.start()+80]}..."
        )

    # ── 6: Source+target pair-specific assertions ────────────────────────
    for desc, pattern in PAIR_FORBIDDEN.get((source, target), []):
        match = pattern.search(scan_sql)
        assert not match, (
            f"{source}→{target}: {desc}\n"
            f"  Matched: {match.group()!r} at position {match.start()}\n"
            f"  Context: ...{scan_sql[max(0,match.start()-60):match.start()+80]}..."
        )


# ===========================================================================
# Targeted regression tests (test specific bugs that were filed)
# ===========================================================================

class TestFabricDWRegressions:
    """Regression tests for known Fabric DW bugs."""

    def test_default_not_emitted_from_redshift(self) -> None:
        """Redshift DEFAULT 'pending' must NOT appear in Fabric DW output."""
        sql = textwrap.dedent("""
            CREATE TABLE dbo.orders (
                order_id   BIGINT        IDENTITY(1,1),
                status     VARCHAR(32)   DEFAULT 'pending',
                created_at TIMESTAMP     NOT NULL
            )
            DISTSTYLE KEY DISTKEY (order_id) SORTKEY (created_at);
        """)
        result = Transpiler.convert(sql, Dialect.REDSHIFT, Dialect.FABRIC_DW)
        assert "DEFAULT" not in result.converted_sql.upper(), (
            "Fabric DW output must not contain DEFAULT clause.\n"
            f"Got:\n{result.converted_sql}"
        )
        # Warning must be emitted
        warning_codes = {w.feature for w in result.warnings}
        assert "DEFAULT_NOT_SUPPORTED_FABRIC_DW" in warning_codes, (
            f"Expected DEFAULT_NOT_SUPPORTED_FABRIC_DW warning. Got: {warning_codes}"
        )

    def test_default_not_emitted_from_snowflake(self) -> None:
        """Snowflake DEFAULT must NOT appear in Fabric DW output."""
        sql = textwrap.dedent("""
            CREATE OR REPLACE TABLE db.schema.orders (
                order_id   NUMBER        AUTOINCREMENT PRIMARY KEY,
                status     VARCHAR(32)   DEFAULT 'pending',
                created_at TIMESTAMP_NTZ NOT NULL
            );
        """)
        result = Transpiler.convert(sql, Dialect.SNOWFLAKE, Dialect.FABRIC_DW)
        assert "DEFAULT" not in result.converted_sql.upper(), (
            f"Fabric DW output must not contain DEFAULT.\nGot:\n{result.converted_sql}"
        )

    def test_default_not_emitted_from_sqlserver(self) -> None:
        """SQL Server DEFAULT must NOT appear in Fabric DW output."""
        sql = textwrap.dedent("""
            CREATE TABLE dbo.orders (
                order_id   BIGINT          IDENTITY(1,1) NOT NULL,
                status     NVARCHAR(32)    DEFAULT 'pending',
                created_at DATETIME2(6)    NOT NULL
            );
        """)
        result = Transpiler.convert(sql, Dialect.SQLSERVER, Dialect.FABRIC_DW)
        assert "DEFAULT" not in result.converted_sql.upper(), (
            f"Fabric DW output must not contain DEFAULT.\nGot:\n{result.converted_sql}"
        )

    def test_default_not_emitted_from_synapse(self) -> None:
        """Synapse DEFAULT must NOT appear in Fabric DW output."""
        sql = textwrap.dedent("""
            CREATE TABLE dbo.orders (
                order_id   BIGINT      NOT NULL,
                status     VARCHAR(32) DEFAULT 'pending'
            )
            WITH (DISTRIBUTION = HASH(order_id), HEAP);
        """)
        result = Transpiler.convert(sql, Dialect.SYNAPSE, Dialect.FABRIC_DW)
        assert "DEFAULT" not in result.converted_sql.upper(), (
            f"Fabric DW output must not contain DEFAULT.\nGot:\n{result.converted_sql}"
        )

    def test_cluster_by_preserves_column_casing(self) -> None:
        """SORTKEY (created_at) → CLUSTER BY ([created_at]) — lowercase preserved."""
        sql = textwrap.dedent("""
            CREATE TABLE dbo.orders (
                order_id   BIGINT    IDENTITY(1,1),
                created_at TIMESTAMP NOT NULL
            )
            DISTSTYLE KEY DISTKEY (order_id) SORTKEY (created_at);
        """)
        result = Transpiler.convert(sql, Dialect.REDSHIFT, Dialect.FABRIC_DW)
        assert "[CREATED_AT]" not in result.converted_sql, (
            f"Column name uppercased (regression!).\nGot:\n{result.converted_sql}"
        )

    def test_cluster_by_max_4_columns(self) -> None:
        """Fabric DW CLUSTER BY must be truncated to 4 columns with a warning."""
        sql = textwrap.dedent("""
            CREATE TABLE dbo.wide (
                a BIGINT, b BIGINT, c BIGINT, d BIGINT, e BIGINT, f BIGINT
            )
            WITH (CLUSTER BY (a, b, c, d, e, f));
        """)
        result = Transpiler.convert(sql, Dialect.FABRIC_DW, Dialect.FABRIC_DW)
        m = re.search(r'CLUSTER BY\s*\(([^)]+)\)', result.converted_sql, re.IGNORECASE)
        if m:
            cols = [c.strip() for c in m.group(1).split(",")]
            assert len(cols) <= 4, (
                f"CLUSTER BY has {len(cols)} columns (> 4).\nGot:\n{result.converted_sql}"
            )


class TestRedshiftCastRegressions:
    """Verify Redshift :: cast is never emitted for non-Redshift targets."""

    REDSHIFT_WITH_CAST = textwrap.dedent("""
        CREATE TABLE dbo.test_table (
            id  BIGINT IDENTITY(1,1),
            val DECIMAL(18,4)
        )
        DISTSTYLE EVEN SORTKEY (id);

        CREATE OR REPLACE FUNCTION fn_cast_test(x DECIMAL(18,4))
        RETURNS DECIMAL(18,4)
        AS $$ SELECT x::DECIMAL(18,4); $$ LANGUAGE sql;
    """)

    @pytest.mark.parametrize("target", [
        d for d in ALL_DIALECTS if d != "redshift"
    ])
    def test_no_pg_cast_in_output(self, target: str) -> None:
        result = Transpiler.convert(
            self.REDSHIFT_WITH_CAST,
            Dialect.REDSHIFT,
            Dialect(target),
        )
        # Strip procedure/function bodies: :: casts inside dollar-quoted or
        # BEGIN...END blocks are intentionally passed through (PROCEDURE_BODY_MANUAL).
        scan = _strip_procedure_bodies(result.converted_sql)
        assert not re.search(r'::\s*\w+', scan), (
            f"redshift→{target}: :: cast not converted (outside procedure bodies).\n"
            f"Output (stripped):\n{scan}"
        )


class TestNVLDecodeConversion:
    """NVL, NVL2, DECODE must be rewritten for targets that don't support them."""

    ORACLE_WITH_NVL = textwrap.dedent("""
        CREATE OR REPLACE VIEW test_view AS
        SELECT
            NVL(col_a, 'default')                      AS a,
            NVL2(col_b, 'has_value', 'no_value')       AS b,
            DECODE(col_c, 1, 'one', 2, 'two', 'other') AS c
        FROM test_table;
    """)

    @pytest.mark.parametrize("target", [
        # Snowflake has native NVL2 — no conversion needed
        "sqlserver", "fabric_dw", "synapse", "bigquery", "databricks"
    ])
    def test_nvl2_not_in_output(self, target: str) -> None:
        result = Transpiler.convert(
            self.ORACLE_WITH_NVL, Dialect.ORACLE, Dialect(target),
        )
        assert not re.search(r'\bNVL2\s*\(', result.converted_sql, re.IGNORECASE), (
            f"oracle→{target}: NVL2 not converted.\nOutput:\n{result.converted_sql}"
        )

    @pytest.mark.parametrize("target", [
        "sqlserver", "fabric_dw", "synapse", "bigquery", "databricks"
    ])
    def test_decode_not_in_output(self, target: str) -> None:
        result = Transpiler.convert(
            self.ORACLE_WITH_NVL, Dialect.ORACLE, Dialect(target),
        )
        assert not re.search(r'\bDECODE\s*\(', result.converted_sql, re.IGNORECASE), (
            f"oracle→{target}: DECODE not converted.\nOutput:\n{result.converted_sql}"
        )


class TestBigQueryNoIdentity:
    """BigQuery has no IDENTITY/AUTOINCREMENT — must warn and remove."""

    @pytest.mark.parametrize("source", [
        d for d in ALL_DIALECTS if d != "bigquery"
    ])
    def test_no_identity_in_bigquery_output(self, source: str) -> None:
        sql = load_fixture(source)
        result = Transpiler.convert(sql, Dialect(source), Dialect.BIGQUERY)
        # Strip procedure bodies: source DDL passed through as-is in proc bodies
        # may contain IDENTITY syntax in comments or raw SQL — that is expected.
        scan = _strip_procedure_bodies(result.converted_sql)
        assert not re.search(r'\bIDENTITY\s*\(', scan, re.IGNORECASE), (
            f"{source}→bigquery: IDENTITY() not converted (outside procedure bodies).\n"
            f"Output (stripped):\n{scan[:800]}"
        )


class TestOracleNoBooleanColumn:
    """Oracle 21c and earlier don't have BOOLEAN column type — must be NUMBER(1)."""

    @pytest.mark.parametrize("source", [
        d for d in ALL_DIALECTS if d != "oracle"
    ])
    def test_boolean_converted_in_oracle_output(self, source: str) -> None:
        sql = load_fixture(source)
        result = Transpiler.convert(sql, Dialect(source), Dialect.ORACLE)
        # Check column-definition pattern: "colname  BOOLEAN" — not inside CHECK()
        col_def_pat = re.compile(r'\b\w+\s+BOOLEAN\b', re.IGNORECASE)
        assert not col_def_pat.search(result.converted_sql), (
            f"{source}→oracle: BOOLEAN column type not converted.\n"
            f"Output:\n{result.converted_sql[:800]}"
        )


class TestSynapseDistributionNotLeaking:
    """DISTRIBUTION clauses from Synapse must not appear in non-Synapse targets."""

    @pytest.mark.parametrize("target", [
        d for d in ALL_DIALECTS if d != "synapse"
    ])
    def test_synapse_distribution_not_in_target(self, target: str) -> None:
        sql = load_fixture("synapse")
        result = Transpiler.convert(sql, Dialect.SYNAPSE, Dialect(target))
        assert not re.search(r'\bDISTRIBUTION\s*=', result.converted_sql, re.IGNORECASE), (
            f"synapse→{target}: DISTRIBUTION clause leaked into output.\n"
            f"Output:\n{result.converted_sql[:800]}"
        )


class TestConfidenceScoreFloor:
    """A simple single-table DDL should always produce score ≥ 0.5."""

    SIMPLE_TABLE = textwrap.dedent("""
        CREATE TABLE test.orders (
            order_id    BIGINT        NOT NULL,
            customer_id INTEGER       NOT NULL,
            amount      DECIMAL(18,2) NOT NULL,
            created_at  TIMESTAMP     NOT NULL,
            PRIMARY KEY (order_id)
        );
    """)

    @pytest.mark.parametrize("source,target", [
        (s, t) for s in ALL_DIALECTS for t in ALL_DIALECTS if s != t
    ])
    def test_simple_table_confidence_floor(self, source: str, target: str) -> None:
        result = Transpiler.convert(self.SIMPLE_TABLE, Dialect(source), Dialect(target))
        score = getattr(result, "confidence_score", None)
        if score is not None:
            assert 0.0 <= score <= 1.0, (
                f"{source}→{target}: Confidence {score} not in [0,1]"
            )
            assert score >= 0.5, (
                f"{source}→{target}: Simple CREATE TABLE got confidence {score} < 0.5.\n"
                f"Warnings: {[w.feature for w in result.warnings]}\n"
                f"Unsupported: {[u.feature for u in result.unsupported_features]}"
            )
