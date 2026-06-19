"""
Query Transpiler — converts SELECT / DML statements between dialects using sqlglot.

Architecture:
  1. Detect statement type (SELECT, INSERT, UPDATE, DELETE, MERGE, CTE)
  2. sqlglot.transpile(sql, read=src_dialect, write=tgt_dialect)
  3. Per-dialect post-processing for quirks sqlglot misses or gets wrong
  4. Generate semantic warnings (QUALIFY unsupported, BOOLEAN→NUMBER, etc.)
  5. Return (output_sql, warnings, doc_refs)
"""
from __future__ import annotations

import re
from typing import List, Optional, Tuple

import sqlglot
from sqlglot import errors as sqlglot_errors

from app.ir.models import IRDocReference, IRWarning, ObjectType, Warningseverity

# ---------------------------------------------------------------------------
# Dialect mapping: our dialect keys → sqlglot read/write names
# ---------------------------------------------------------------------------

_SQLGLOT_DIALECT_MAP: dict[str, str] = {
    "redshift":       "redshift",
    "snowflake":      "snowflake",
    "sqlserver":      "tsql",
    "synapse":        "tsql",
    "fabric_dw":      "tsql",
    "fabric_lakehouse": "spark",
    "databricks":     "databricks",
    "oracle":         "oracle",
    "bigquery":       "bigquery",
}

# T-SQL family (all share the same sqlglot dialect)
_TSQL_DIALECTS = {"sqlserver", "synapse", "fabric_dw"}
# Spark family
_SPARK_DIALECTS = {"fabric_lakehouse", "databricks"}

# ---------------------------------------------------------------------------
# Statement-type detection
# ---------------------------------------------------------------------------

# Strip block and line comments, then match leading keyword
_COMMENT_RE   = re.compile(r'/\*.*?\*/', re.DOTALL)
_LINE_COMM_RE = re.compile(r'--[^\n]*')

_LEADING_KEYWORD_PATTERNS: list[tuple[re.Pattern, ObjectType]] = [
    (re.compile(r'^\s*WITH\b',    re.IGNORECASE), ObjectType.SELECT_QUERY),
    (re.compile(r'^\s*SELECT\b',  re.IGNORECASE), ObjectType.SELECT_QUERY),
    (re.compile(r'^\s*INSERT\b',  re.IGNORECASE), ObjectType.INSERT),
    (re.compile(r'^\s*UPDATE\b',  re.IGNORECASE), ObjectType.UPDATE),
    (re.compile(r'^\s*DELETE\b',  re.IGNORECASE), ObjectType.DELETE),
    (re.compile(r'^\s*MERGE\b',   re.IGNORECASE), ObjectType.MERGE),
]


def detect_statement_type(sql: str) -> Optional[ObjectType]:
    """Return DML/SELECT ObjectType if sql is a query statement, else None."""
    stripped = _COMMENT_RE.sub('', sql)
    stripped = _LINE_COMM_RE.sub('', stripped)
    for pattern, obj_type in _LEADING_KEYWORD_PATTERNS:
        if pattern.match(stripped):
            return obj_type
    return None


def is_query_statement(sql: str) -> bool:
    """Return True if ANY statement in sql is SELECT/DML."""
    return any(
        detect_statement_type(s) is not None
        for s in _split_statements(sql)
        if s.strip()
    )


# ---------------------------------------------------------------------------
# Statement splitter (respects single-quoted strings, avoids false `;` splits)
# ---------------------------------------------------------------------------

def _split_statements(sql: str) -> list[str]:
    """Split sql on `;` boundaries, ignoring semicolons inside string literals."""
    statements: list[str] = []
    current: list[str] = []
    in_single = False
    in_double = False
    i = 0
    n = len(sql)

    while i < n:
        ch = sql[i]
        # Toggle string delimiters
        if ch == "'" and not in_double:
            # Escaped quote ('')
            if in_single and i + 1 < n and sql[i + 1] == "'":
                current.append("''")
                i += 2
                continue
            in_single = not in_single
        elif ch == '"' and not in_single:
            in_double = not in_double

        if ch == ';' and not in_single and not in_double:
            stmt = ''.join(current).strip()
            if stmt:
                statements.append(stmt)
            current = []
        else:
            current.append(ch)
        i += 1

    last = ''.join(current).strip()
    if last:
        statements.append(last)
    return statements


# ---------------------------------------------------------------------------
# Per-dialect post-processing rules applied AFTER sqlglot transpilation
# ---------------------------------------------------------------------------

def _post_process(sql: str, target_dialect: str) -> tuple[str, list[str]]:
    """
    Apply target-dialect fixups that sqlglot doesn't handle.
    Returns (fixed_sql, list_of_applied_fix_names).
    """
    applied: list[str] = []

    if target_dialect in _TSQL_DIALECTS:
        sql, a = _post_tsql(sql)
        applied.extend(a)

    elif target_dialect == "oracle":
        sql, a = _post_oracle(sql)
        applied.extend(a)

    elif target_dialect == "bigquery":
        sql, a = _post_bigquery(sql)
        applied.extend(a)

    elif target_dialect in _SPARK_DIALECTS:
        sql, a = _post_spark(sql)
        applied.extend(a)

    elif target_dialect == "snowflake":
        sql, a = _post_snowflake(sql)
        applied.extend(a)

    elif target_dialect == "redshift":
        sql, a = _post_redshift(sql)
        applied.extend(a)

    return sql, applied


def _post_tsql(sql: str) -> tuple[str, list[str]]:
    """T-SQL: SQL Server / Synapse / Fabric DW fixups."""
    applied: list[str] = []

    # NULLS FIRST / NULLS LAST → not supported in T-SQL (strip them)
    if re.search(r'\bNULLS\s+(FIRST|LAST)\b', sql, re.IGNORECASE):
        sql = re.sub(r'\s*NULLS\s+(FIRST|LAST)\b', '', sql, flags=re.IGNORECASE)
        applied.append("strip_nulls_ordering")

    # QUALIFY clause → wrap as subquery (sqlglot may pass it through raw)
    # e.g. SELECT ... FROM t QUALIFY ROW_NUMBER() OVER (...) = 1
    # → SELECT * FROM (SELECT ..., ROW_NUMBER() OVER (...) AS _rn FROM t) WHERE _rn = 1
    # This is complex; we flag it with a warning instead of rewriting
    # (actual rewrite done in warning generation)

    # BOOLEAN literals TRUE/FALSE → 1/0 for older compatibility
    # T-SQL supports BIT but TRUE/FALSE as standalone literals can cause issues
    sql = re.sub(r'\bTRUE\b',  '1', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bFALSE\b', '0', sql, flags=re.IGNORECASE)
    applied.append("bool_to_bit")

    # LIMIT n → already handled by sqlglot (TOP n), but clean any residuals
    if re.search(r'\bLIMIT\b', sql, re.IGNORECASE) and not re.search(r'\bFETCH\b', sql, re.IGNORECASE):
        m = re.search(r'\bLIMIT\s+(\d+)', sql, re.IGNORECASE)
        if m:
            n = m.group(1)
            sql = re.sub(r'\s+LIMIT\s+\d+', '', sql, flags=re.IGNORECASE)
            # Inject TOP n after SELECT
            sql = re.sub(r'\bSELECT\b', f'SELECT TOP {n}', sql, count=1, flags=re.IGNORECASE)
            applied.append("limit_to_top")

    # ILIKE → T-SQL doesn't support; use LIKE (T-SQL is case-insensitive by default)
    if re.search(r'\bILIKE\b', sql, re.IGNORECASE):
        sql = re.sub(r'\bILIKE\b', 'LIKE', sql, flags=re.IGNORECASE)
        applied.append("ilike_to_like")

    # :: cast operator → CAST(...) for T-SQL
    # e.g. column::VARCHAR → CAST(column AS VARCHAR)
    sql = _replace_cast_operator(sql)
    if '::' not in sql:
        applied.append("cast_operator")

    return sql, applied


def _post_oracle(sql: str) -> tuple[str, list[str]]:
    """Oracle fixups."""
    applied: list[str] = []

    # NULLS FIRST/LAST → Oracle supports but only for non-default (LAST for ASC, FIRST for DESC)
    # Leave them — Oracle supports both natively

    # BOOLEAN literals → Oracle 23c+ supports BOOLEAN; for compatibility use 1/0
    # We'll leave for now and warn instead

    # LIMIT n → sqlglot converts to FETCH FIRST n ROWS ONLY, but verify
    if re.search(r'\bLIMIT\s+\d+', sql, re.IGNORECASE) and not re.search(r'\bFETCH\s+FIRST\b', sql, re.IGNORECASE):
        m = re.search(r'\bLIMIT\s+(\d+)', sql, re.IGNORECASE)
        if m:
            n = m.group(1)
            sql = re.sub(r'\s+LIMIT\s+\d+', f' FETCH FIRST {n} ROWS ONLY', sql, flags=re.IGNORECASE)
            applied.append("limit_to_fetch_first")

    # ILIKE → Oracle uses LIKE with UPPER() or NLS settings; convert to UPPER(col) LIKE UPPER(?)
    # This is complex — just replace with LIKE and warn
    if re.search(r'\bILIKE\b', sql, re.IGNORECASE):
        sql = re.sub(r'\bILIKE\b', 'LIKE', sql, flags=re.IGNORECASE)
        applied.append("ilike_to_like")

    # :: cast operator
    sql = _replace_cast_operator(sql)

    # CURRENT_TIMESTAMP() with parens → SYSTIMESTAMP in Oracle
    sql = re.sub(r'\bCURRENT_TIMESTAMP\s*\(\s*\)', 'SYSTIMESTAMP', sql, flags=re.IGNORECASE)

    # CURRENT_DATE() with parens → TRUNC(SYSDATE)
    sql = re.sub(r'\bCURRENT_DATE\s*\(\s*\)', 'TRUNC(SYSDATE)', sql, flags=re.IGNORECASE)

    return sql, applied


def _post_bigquery(sql: str) -> tuple[str, list[str]]:
    """BigQuery fixups."""
    applied: list[str] = []

    # ILIKE → LIKE (BQ is case-sensitive but no ILIKE; use REGEXP_CONTAINS or LOWER)
    if re.search(r'\bILIKE\b', sql, re.IGNORECASE):
        sql = re.sub(r'\bILIKE\b', 'LIKE', sql, flags=re.IGNORECASE)
        applied.append("ilike_to_like")

    # :: cast operator
    sql = _replace_cast_operator(sql)

    # NULLS FIRST/LAST → BQ supports NULLS FIRST/LAST, keep them
    return sql, applied


def _post_spark(sql: str) -> tuple[str, list[str]]:
    """Spark SQL (Databricks / Fabric Lakehouse) fixups."""
    applied: list[str] = []

    # NULLS FIRST/LAST → supported in Spark, keep
    # :: cast operator
    sql = _replace_cast_operator(sql)

    # ILIKE → Spark 3.3+ supports ILIKE; keep for Databricks, flag for Fabric Lakehouse
    return sql, applied


def _post_snowflake(sql: str) -> tuple[str, list[str]]:
    """Snowflake fixups."""
    applied: list[str] = []

    # :: cast operator is valid in Snowflake — leave it!
    # NULLS FIRST/LAST — supported in Snowflake, keep

    # CURRENT_TIMESTAMP() with parens → Snowflake prefers without parens as function ref
    # but CURRENT_TIMESTAMP() is also valid — keep as-is

    return sql, applied


def _post_redshift(sql: str) -> tuple[str, list[str]]:
    """Redshift fixups."""
    applied: list[str] = []

    # QUALIFY clause → not supported in Redshift; needs subquery rewrite
    # FETCH FIRST n ROWS ONLY → LIMIT n in Redshift
    if re.search(r'\bFETCH\s+FIRST\s+(\d+)\s+ROWS\s+ONLY\b', sql, re.IGNORECASE):
        m = re.search(r'\bFETCH\s+FIRST\s+(\d+)\s+ROWS\s+ONLY\b', sql, re.IGNORECASE)
        if m:
            n = m.group(1)
            sql = re.sub(r'\s*FETCH\s+FIRST\s+\d+\s+ROWS\s+ONLY\b', f' LIMIT {n}', sql, flags=re.IGNORECASE)
            applied.append("fetch_first_to_limit")

    # NULLS FIRST/LAST → Redshift doesn't support; strip
    if re.search(r'\bNULLS\s+(FIRST|LAST)\b', sql, re.IGNORECASE):
        sql = re.sub(r'\s*NULLS\s+(FIRST|LAST)\b', '', sql, flags=re.IGNORECASE)
        applied.append("strip_nulls_ordering")

    # :: is valid in Redshift (PostgreSQL heritage) — keep
    return sql, applied


def _replace_cast_operator(sql: str) -> str:
    """Replace PostgreSQL :: cast operator with CAST(expr AS type)."""
    # Match patterns like: column::TYPE or expression::TYPE(n)
    # This is tricky with complex expressions; handle simple cases
    pattern = re.compile(r'(\w+)\s*::\s*([A-Z_]+(?:\([^)]*\))?)', re.IGNORECASE)
    return pattern.sub(r'CAST(\1 AS \2)', sql)


# ---------------------------------------------------------------------------
# Warning generation — semantic differences the user should know about
# ---------------------------------------------------------------------------

_QUALIFY_DIALECTS_THAT_SUPPORT = {"snowflake", "bigquery", "databricks", "fabric_lakehouse"}

_FUNCTION_WARNINGS: list[tuple[re.Pattern, str, str, set]] = [
    # (source_pattern, feature_code, message, unsupported_in_targets)
    (
        re.compile(r'\bAPPROX_COUNT_DISTINCT\b|\bHLL\b', re.IGNORECASE),
        "APPROX_COUNT_DISTINCT",
        "Approximate distinct count (HLL) is supported in Redshift/Snowflake/BigQuery but "
        "not natively in Oracle or T-SQL. Replaced with COUNT(DISTINCT ...) which is exact.",
        {"sqlserver", "synapse", "fabric_dw", "oracle"},
    ),
    (
        re.compile(r'\bQUALIFY\b', re.IGNORECASE),
        "QUALIFY_CLAUSE",
        "QUALIFY is not supported in Oracle, SQL Server, Synapse, Fabric DW, or Redshift. "
        "Rewrite as a subquery: SELECT * FROM (SELECT ..., ROW_NUMBER() OVER (...) AS _rn) WHERE _rn = 1",
        {"oracle", "sqlserver", "synapse", "fabric_dw", "redshift"},
    ),
    (
        re.compile(r'\bMATCH_RECOGNIZE\b', re.IGNORECASE),
        "MATCH_RECOGNIZE",
        "MATCH_RECOGNIZE (pattern matching) is only supported in Oracle and some newer engines. "
        "Requires manual rewrite for other dialects.",
        {"redshift", "snowflake", "bigquery", "databricks", "sqlserver", "synapse", "fabric_dw", "fabric_lakehouse"},
    ),
    (
        re.compile(r'\bPIVOT\s*\(', re.IGNORECASE),
        "PIVOT_OPERATOR",
        "PIVOT syntax varies between dialects. SQL Server/Synapse use PIVOT(...) FOR ... IN (...). "
        "BigQuery/Snowflake use PIVOT(agg FOR col IN (vals)). Redshift has no PIVOT — use CASE WHEN.",
        {"redshift", "bigquery"},
    ),
    (
        re.compile(r'\bCONNECT\s+BY\b', re.IGNORECASE),
        "CONNECT_BY",
        "Oracle CONNECT BY hierarchical query must be rewritten as a recursive CTE "
        "(WITH RECURSIVE ... AS (...)) for other dialects.",
        {"redshift", "snowflake", "bigquery", "databricks", "sqlserver", "synapse", "fabric_dw", "fabric_lakehouse"},
    ),
    (
        re.compile(r'\bSTART\s+WITH\b', re.IGNORECASE),
        "CONNECT_BY_START_WITH",
        "Oracle START WITH is part of CONNECT BY hierarchical queries. Rewrite as recursive CTE.",
        {"redshift", "snowflake", "bigquery", "databricks", "sqlserver", "synapse", "fabric_dw", "fabric_lakehouse"},
    ),
    (
        re.compile(r'\bGROUPS?\s+BY\s+ROLLUP\b|\bROLLUP\s*\(', re.IGNORECASE),
        "ROLLUP",
        "ROLLUP is supported in most dialects but syntax varies slightly. Verify generated output.",
        set(),
    ),
    (
        re.compile(r'\bGROUPS?\s+BY\s+CUBE\b|\bCUBE\s*\(', re.IGNORECASE),
        "CUBE",
        "CUBE is not supported in Redshift. Use ROLLUP or UNION ALL to simulate.",
        {"redshift"},
    ),
    (
        re.compile(r'\bFLATTEN\s*\(', re.IGNORECASE),
        "FLATTEN_FUNCTION",
        "Snowflake FLATTEN() for array/variant expansion. In BigQuery use UNNEST(); "
        "in Spark/Databricks use EXPLODE().",
        {"bigquery", "databricks", "fabric_lakehouse", "oracle", "sqlserver", "synapse", "fabric_dw", "redshift"},
    ),
    (
        re.compile(r'\bEXPLODE\s*\(', re.IGNORECASE),
        "EXPLODE_FUNCTION",
        "Spark/Databricks EXPLODE() for array expansion. In BigQuery use UNNEST(); "
        "in Snowflake use FLATTEN().",
        {"bigquery", "snowflake", "oracle", "sqlserver", "synapse", "fabric_dw", "redshift"},
    ),
    (
        re.compile(r'\bSAMPLE\s*\(|\bTABLESAMPLE\b', re.IGNORECASE),
        "TABLESAMPLE",
        "TABLESAMPLE syntax varies: Snowflake (SAMPLE), BigQuery (TABLESAMPLE), "
        "T-SQL (TABLESAMPLE). Oracle and Redshift differ. Verify generated output.",
        set(),
    ),
    (
        re.compile(r'\bGET_PATH\b|\bJSON_EXTRACT_PATH_TEXT\b', re.IGNORECASE),
        "SEMI_STRUCTURED_ACCESS",
        "Semi-structured data access (VARIANT/SUPER) is dialect-specific. "
        "Snowflake: colon notation or GET_PATH(). Redshift: JSON_EXTRACT_PATH_TEXT(). "
        "BigQuery: JSON_VALUE(). Manual review required.",
        {"oracle", "sqlserver", "synapse", "fabric_dw"},
    ),
]

_FUNCTION_CONVERSIONS_NOTED: list[tuple[re.Pattern, str, str]] = [
    (re.compile(r'\bNVL\s*\(', re.IGNORECASE),         "NVL", "NVL → COALESCE (or ISNULL in T-SQL)"),
    (re.compile(r'\bIFF\s*\(', re.IGNORECASE),          "IFF", "IFF → CASE WHEN ... THEN ... ELSE ... END"),
    (re.compile(r'\bNVL2\s*\(', re.IGNORECASE),         "NVL2", "NVL2 → CASE WHEN x IS NOT NULL THEN a ELSE b END"),
    (re.compile(r'\bDECODE\s*\(', re.IGNORECASE),       "DECODE", "DECODE → CASE WHEN expressions"),
    (re.compile(r'\bLISTAGG\s*\(', re.IGNORECASE),      "LISTAGG", "LISTAGG → STRING_AGG (T-SQL/BQ) or GROUP_CONCAT (MySQL)"),
    (re.compile(r'\bZEROIFNULL\s*\(', re.IGNORECASE),   "ZEROIFNULL", "ZEROIFNULL → COALESCE(x, 0)"),
    (re.compile(r'\bNULLIFZERO\s*\(', re.IGNORECASE),   "NULLIFZERO", "NULLIFZERO → NULLIF(x, 0)"),
    (re.compile(r'\bGETDATE\s*\(\s*\)', re.IGNORECASE), "GETDATE", "GETDATE() → CURRENT_TIMESTAMP"),
    (re.compile(r'\bSYSDATE\b', re.IGNORECASE),          "SYSDATE", "SYSDATE → CURRENT_TIMESTAMP / SYSTIMESTAMP"),
    (re.compile(r'\bDATEADD\s*\(', re.IGNORECASE),      "DATEADD", "DATEADD → DATEADD/DATE_ADD/INTERVAL depending on dialect"),
    (re.compile(r'\bDATEDIFF\s*\(', re.IGNORECASE),     "DATEDIFF", "DATEDIFF → DATEDIFF/DATE_DIFF/TIMESTAMPDIFF depending on dialect"),
    (re.compile(r'\bDATE_TRUNC\s*\(', re.IGNORECASE),   "DATE_TRUNC", "DATE_TRUNC → TRUNC (Oracle) / DATE_TRUNC (standard)"),
    (re.compile(r'\bTO_CHAR\s*\(', re.IGNORECASE),      "TO_CHAR", "TO_CHAR → FORMAT / TO_VARCHAR / CAST(... AS VARCHAR)"),
    (re.compile(r'\bTRY_CAST\s*\(', re.IGNORECASE),     "TRY_CAST", "TRY_CAST → TRY_CAST (T-SQL/Snowflake) / SAFE_CAST (BigQuery)"),
    (re.compile(r'\bSAFE_CAST\s*\(', re.IGNORECASE),    "SAFE_CAST", "SAFE_CAST → SAFE_CAST (BigQuery) / TRY_CAST (T-SQL/Snowflake)"),
    (re.compile(r'\bARRAY_AGG\s*\(', re.IGNORECASE),    "ARRAY_AGG", "ARRAY_AGG → ARRAY_AGG (BQ/Snowflake) / COLLECT_LIST (Spark) / STRING_AGG as text"),
    (re.compile(r'\bCOLLECT_LIST\s*\(|\bCOLLECT_SET\s*\(', re.IGNORECASE), "COLLECT_LIST", "Spark COLLECT_LIST/SET → ARRAY_AGG in other dialects"),
]


def _generate_warnings(
    source_sql: str,
    output_sql: str,
    source_dialect: str,
    target_dialect: str,
    sqlglot_errors_list: list[str],
) -> list[IRWarning]:
    """Generate semantic warnings for the query translation."""
    warnings: list[IRWarning] = []

    # 1. sqlglot parse/transpile errors
    for err in sqlglot_errors_list:
        warnings.append(IRWarning(
            feature="SQLGLOT_PARSE_WARNING",
            message=f"sqlglot parse hint: {err}",
            severity=Warningseverity.INFO,
            fallback_applied=True,
        ))

    # 2. Unsupported constructs for the target dialect
    for pattern, code, msg, unsupported_targets in _FUNCTION_WARNINGS:
        if pattern.search(source_sql) and target_dialect in unsupported_targets:
            warnings.append(IRWarning(
                feature=code,
                message=msg,
                severity=Warningseverity.WARNING,
                unsupported=(target_dialect in unsupported_targets),
            ))

    # 3. Function conversion notes (informational)
    for pattern, code, msg in _FUNCTION_CONVERSIONS_NOTED:
        if pattern.search(source_sql):
            warnings.append(IRWarning(
                feature=f"FN_{code}",
                message=msg,
                severity=Warningseverity.INFO,
                fallback_applied=True,
            ))

    # 4. QUALIFY specifically — needs subquery rewrite hint
    if re.search(r'\bQUALIFY\b', source_sql, re.IGNORECASE):
        if target_dialect not in _QUALIFY_DIALECTS_THAT_SUPPORT:
            warnings.append(IRWarning(
                feature="QUALIFY_REWRITE_NEEDED",
                message=(
                    f"QUALIFY is not supported in {target_dialect}. "
                    "Rewrite pattern: SELECT * FROM (\n"
                    "  SELECT ..., ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...) AS _rn\n"
                    "  FROM table\n"
                    ") sub WHERE sub._rn = 1"
                ),
                severity=Warningseverity.WARNING,
                unsupported=True,
            ))

    # 5. BOOLEAN literals in T-SQL targets
    if target_dialect in _TSQL_DIALECTS:
        if re.search(r'\bTRUE\b|\bFALSE\b', source_sql, re.IGNORECASE):
            warnings.append(IRWarning(
                feature="BOOL_LITERALS_TSQL",
                message="TRUE/FALSE literals replaced with 1/0 for T-SQL compatibility (BIT type).",
                severity=Warningseverity.INFO,
                fallback_applied=True,
            ))

    # 6. ILIKE in non-supporting targets
    if re.search(r'\bILIKE\b', source_sql, re.IGNORECASE):
        if target_dialect in {"oracle", "sqlserver", "synapse", "fabric_dw", "redshift", "bigquery"}:
            warnings.append(IRWarning(
                feature="ILIKE_NOT_SUPPORTED",
                message=f"ILIKE replaced with LIKE in {target_dialect}. "
                        "Case-sensitivity behavior may differ — consider wrapping with LOWER()/UPPER().",
                severity=Warningseverity.WARNING,
                fallback_applied=True,
            ))

    # 7. MERGE statement warnings
    if re.search(r'^\s*MERGE\b', source_sql, re.IGNORECASE):
        if target_dialect in {"bigquery"}:
            warnings.append(IRWarning(
                feature="MERGE_BIGQUERY",
                message="BigQuery MERGE requires a full table scan on the target. "
                        "Ensure the USING clause identifies rows uniquely.",
                severity=Warningseverity.INFO,
            ))
        if target_dialect in {"databricks", "fabric_lakehouse"}:
            warnings.append(IRWarning(
                feature="MERGE_DELTA",
                message="Spark/Delta MERGE INTO syntax: use MERGE INTO target USING source ON ... "
                        "WHEN MATCHED THEN UPDATE/DELETE WHEN NOT MATCHED THEN INSERT.",
                severity=Warningseverity.INFO,
                fallback_applied=True,
            ))

    return warnings


# ---------------------------------------------------------------------------
# Doc references per target dialect for queries
# ---------------------------------------------------------------------------

_QUERY_DOC_REFS: dict[str, list[IRDocReference]] = {
    "bigquery": [
        IRDocReference(
            title="BigQuery DML reference",
            url="https://cloud.google.com/bigquery/docs/reference/standard-sql/dml-syntax",
            platform="BigQuery",
            purpose="DML (INSERT, UPDATE, DELETE, MERGE) syntax reference",
        ),
        IRDocReference(
            title="BigQuery query syntax",
            url="https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax",
            platform="BigQuery",
            purpose="SELECT query syntax including QUALIFY, PIVOT, STRUCT",
        ),
    ],
    "snowflake": [
        IRDocReference(
            title="Snowflake DML reference",
            url="https://docs.snowflake.com/en/sql-reference-commands-dml",
            platform="Snowflake",
            purpose="INSERT, UPDATE, DELETE, MERGE syntax reference",
        ),
    ],
    "redshift": [
        IRDocReference(
            title="Amazon Redshift SQL commands",
            url="https://docs.aws.amazon.com/redshift/latest/dg/c_SQL_commands.html",
            platform="Redshift",
            purpose="Redshift-specific SQL functions and DML",
        ),
    ],
    "sqlserver": [
        IRDocReference(
            title="T-SQL DML reference",
            url="https://learn.microsoft.com/en-us/sql/t-sql/statements/statements",
            platform="SQL Server",
            purpose="T-SQL INSERT, UPDATE, DELETE, MERGE syntax",
        ),
    ],
    "databricks": [
        IRDocReference(
            title="Databricks SQL reference",
            url="https://docs.databricks.com/en/sql/language-manual/index.html",
            platform="Databricks",
            purpose="Delta Lake DML and Spark SQL functions",
        ),
    ],
    "oracle": [
        IRDocReference(
            title="Oracle SQL reference",
            url="https://docs.oracle.com/en/database/oracle/oracle-database/21/sqlrf/index.html",
            platform="Oracle",
            purpose="Oracle SQL functions and DML syntax",
        ),
    ],
}


# ---------------------------------------------------------------------------
# Main public function
# ---------------------------------------------------------------------------

def transpile_query(
    sql: str,
    source_dialect: str,
    target_dialect: str,
) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
    """
    Transpile a SELECT / DML SQL statement between dialects.

    Args:
        sql:            A single SQL statement (SELECT, INSERT, UPDATE, DELETE, MERGE, WITH...)
        source_dialect: Our dialect key (e.g. "redshift")
        target_dialect: Our dialect key (e.g. "snowflake")

    Returns:
        (transpiled_sql, warnings, doc_refs)
    """
    src_sg = _SQLGLOT_DIALECT_MAP.get(source_dialect, source_dialect)
    tgt_sg = _SQLGLOT_DIALECT_MAP.get(target_dialect, target_dialect)

    # Run sqlglot transpilation, collecting parse errors as warnings
    sg_error_msgs: list[str] = []
    try:
        transpiled_list = sqlglot.transpile(
            sql,
            read=src_sg,
            write=tgt_sg,
            pretty=True,
            error_level=sqlglot_errors.ErrorLevel.WARN,
        )
        transpiled = '\n'.join(transpiled_list) if transpiled_list else sql
    except sqlglot_errors.SqlglotError as e:
        sg_error_msgs.append(str(e))
        transpiled = sql  # passthrough on failure

    # Post-process for target-dialect quirks
    transpiled, _ = _post_process(transpiled, target_dialect)

    # Generate semantic warnings
    warnings = _generate_warnings(sql, transpiled, source_dialect, target_dialect, sg_error_msgs)

    # Doc references
    doc_refs = _QUERY_DOC_REFS.get(target_dialect, [])

    return transpiled, warnings, doc_refs


def transpile_script(
    sql: str,
    source_dialect: str,
    target_dialect: str,
) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
    """
    Transpile a multi-statement SQL script containing only SELECT/DML statements.
    Used when ALL statements in the script are queries (no DDL mixing).

    Returns:
        (transpiled_sql, warnings, doc_refs)
    """
    statements = _split_statements(sql)
    output_parts: list[str] = []
    all_warnings: list[IRWarning] = []
    all_refs: list[IRDocReference] = []
    seen_ref_urls: set[str] = set()

    for stmt in statements:
        if not stmt.strip():
            continue
        out, warns, refs = transpile_query(stmt, source_dialect, target_dialect)
        output_parts.append(out)
        all_warnings.extend(warns)
        for ref in refs:
            if ref.url not in seen_ref_urls:
                seen_ref_urls.add(ref.url)
                all_refs.append(ref)

    return ';\n\n'.join(output_parts), all_warnings, all_refs
