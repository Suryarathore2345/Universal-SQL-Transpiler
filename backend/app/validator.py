"""
Post-conversion residual validator.

Scans the generated (target) SQL for leftover source-dialect syntax that
the generator may have missed.  Each residual found adds a WARNING to the
result and applies a confidence penalty of 5 % (floored at 0.30).

Pattern inspired by the Redshift-Fabric-Transpiler safety-net approach.

Key design decisions:
  1. Procedure/function BODIES are intentionally passed through as-is with a
     PROCEDURE_BODY_MANUAL warning — strip them before scanning so their
     content doesn't produce false-positive residual warnings.
  2. Some source-dialect patterns are also valid syntax in certain target
     dialects (e.g. CLUSTER BY from Snowflake is valid in Fabric DW / BigQuery
     / Databricks).  skip_for_targets lets us suppress those false positives.
"""
from __future__ import annotations

import re
from typing import Dict, List, Optional, Set, Tuple

from app.ir.models import IRWarning, Warningseverity


# ---------------------------------------------------------------------------
# Procedure/function body stripping
# Removes content between $$ ... $$ (PostgreSQL / Snowflake dollar-quoting)
# and between AS BEGIN ... END; (T-SQL / BigQuery Scripting) so that
# intentionally-passed-through bodies don't trigger residual warnings.
# ---------------------------------------------------------------------------

_DOLLAR_QUOTE  = re.compile(r'\$\$.*?\$\$', re.DOTALL)
_BEGIN_END     = re.compile(r'\bBEGIN\b.*?\bEND\b\s*;', re.DOTALL | re.IGNORECASE)
_RETURN_CLAUSE = re.compile(r'\bRETURN\b[^;]+;', re.DOTALL | re.IGNORECASE)
# BigQuery / SQL functions wrapped in  AS (\n   ...\n);
_AS_PAREN_BODY = re.compile(r'\bAS\s*\(\n[\s\S]*?\n\s*\)\s*;', re.MULTILINE)
# Block comments /* ... */ — strip to avoid false positives when sqlglot preserves
# source SQL comments (e.g. "/* NVL / NVL2 */") in the generated view body.
_BLOCK_COMMENTS = re.compile(r'/\*.*?\*/', re.DOTALL)
# JavaScript / raw triple-quote strings  r"""..."""
_JS_TRIPLE     = re.compile(r'r""".*?"""', re.DOTALL)
# SQL line comments (-- ...) — strip to avoid false positives from commented-out
# source code (e.g. Oracle procedure bodies emitted as comment lines in Spark/Databricks)
_LINE_COMMENTS = re.compile(r'--[^\n]*')


def _strip_procedure_bodies(sql: str) -> str:
    """
    Remove procedure/function body content before residual scanning.

    Strips the following body formats so that intentionally-passed-through
    content doesn't trigger false-positive residual warnings:
      1. $$...$$          — PostgreSQL / Snowflake dollar-quoting
      2. BEGIN...END;     — T-SQL / BigQuery Scripting / PL/SQL
      3. AS (\\n...\\n);  — BigQuery SQL UDF format
      4. r\"\"\"...\"\"\"  — BigQuery JavaScript UDF
      5. RETURN expr;     — short Oracle/SQL function bodies
      6. -- line comments — strip to avoid false positives from commented-out
                           source code (e.g. Oracle bodies in Spark/Databricks generators)
    """
    # 1. Dollar-quoted blocks: $$ ... $$
    sql = _DOLLAR_QUOTE.sub(' ', sql)
    # 2. T-SQL / BigQuery Scripting: BEGIN ... END;
    sql = _BEGIN_END.sub(' ', sql)
    # 3. BigQuery SQL UDF: AS ( ... );   (must run after BEGIN...END so nested
    #    AS clauses inside procedures are already stripped)
    sql = _AS_PAREN_BODY.sub('AS ();', sql)
    # 4. BigQuery JavaScript UDF: r"""..."""
    sql = _JS_TRIPLE.sub(' ', sql)
    # 5. PL/SQL short RETURN expr; (Oracle inline functions)
    sql = _RETURN_CLAUSE.sub(' ', sql)
    # 6. Strip block comments (/* ... */) to avoid false positives when sqlglot
    #    preserves source SQL comments (e.g. "/* NVL / NVL2 */", "/* :: */")
    #    in the generated view body.  Run before line-comment stripping so
    #    the regex doesn't see partial block-comment text after line breaks.
    sql = _BLOCK_COMMENTS.sub(' ', sql)
    # 7. Strip line comments (-- ...) to avoid false positives from source code
    #    preserved as SQL comments in the output (e.g. procedure fallbacks)
    sql = _LINE_COMMENTS.sub(' ', sql)
    return sql


# ---------------------------------------------------------------------------
# Residual pattern registry
# Each entry: (rule_id, pattern, description, skip_for_targets)
#   skip_for_targets — set of target-dialect keys where this pattern is
#                      VALID syntax and must not be flagged as a residual.
# ---------------------------------------------------------------------------

_RESIDUALS: Dict[str, List[Tuple[str, re.Pattern, str, Set[str]]]] = {
    "redshift": [
        ("RESIDUAL_DISTKEY",    re.compile(r'\bDISTKEY\b',    re.I),
         "DISTKEY not converted",                 set()),
        ("RESIDUAL_SORTKEY",    re.compile(r'\bSORTKEY\b',    re.I),
         "SORTKEY not converted",                 set()),
        ("RESIDUAL_DISTSTYLE",  re.compile(r'\bDISTSTYLE\b',  re.I),
         "DISTSTYLE not converted",               set()),
        ("RESIDUAL_PG_CAST",    re.compile(r'::\s*\w+'),
         "PostgreSQL :: cast not converted",
         # Snowflake natively supports :: cast syntax — do not flag as residual
         {"snowflake"}),
        ("RESIDUAL_NVL",        re.compile(r'\bNVL\s*\(',     re.I),
         "NVL() not converted",
         # NVL is also valid in Oracle, Snowflake, Databricks, and Fabric Lakehouse (Spark coalesces it)
         {"oracle", "redshift", "snowflake", "databricks", "fabric_lakehouse"}),
        ("RESIDUAL_ILIKE",      re.compile(r'\bILIKE\b',      re.I),
         "ILIKE not converted",
         # ILIKE is also valid in Snowflake
         {"snowflake"}),
        ("RESIDUAL_SUPER",      re.compile(r'\bSUPER\b',      re.I),
         "SUPER type not converted",              set()),
        ("RESIDUAL_ENCODE",     re.compile(r'\bENCODE\s+\w+', re.I),
         "ENCODE compression not converted",      set()),
        ("RESIDUAL_INITCAP",    re.compile(r'\bINITCAP\s*\(', re.I),
         "INITCAP() not converted — no T-SQL equivalent",
         # INITCAP is natively supported everywhere except the T-SQL family
         {"redshift", "oracle", "snowflake", "bigquery", "databricks", "fabric_lakehouse"}),
        ("RESIDUAL_CONVERT_TIMEZONE", re.compile(r'\bCONVERT_TIMEZONE\s*\(', re.I),
         "CONVERT_TIMEZONE() not converted",
         # Redshift and Snowflake have a native CONVERT_TIMEZONE function.
         # Databricks and Fabric Lakehouse convert it to from_utc_timestamp().
         {"redshift", "snowflake", "databricks", "fabric_lakehouse"}),
    ],
    "snowflake": [
        ("RESIDUAL_VARIANT",    re.compile(r'\bVARIANT\b',    re.I),
         "VARIANT type not converted",
         # VARIANT is also supported in Databricks Runtime 15.2+
         {"databricks"}),
        ("RESIDUAL_FLATTEN",    re.compile(r'\bFLATTEN\s*\(', re.I),
         "FLATTEN not converted",                 set()),
        ("RESIDUAL_QUALIFY",    re.compile(r'\bQUALIFY\b',    re.I),
         "QUALIFY clause not converted",          set()),
        ("RESIDUAL_CLUSTER_BY", re.compile(r'\bCLUSTER\s+BY\b', re.I),
         "CLUSTER BY not converted",
         # CLUSTER BY is valid in Fabric DW, BigQuery, Databricks, and Fabric Lakehouse (warned but emitted)
         {"fabric_dw", "bigquery", "databricks", "snowflake", "fabric_lakehouse"}),
        ("RESIDUAL_SEQUENCE",   re.compile(r'\.NEXTVAL\b',    re.I),
         ".NEXTVAL sequence not converted",       set()),
    ],
    "oracle": [
        ("RESIDUAL_NUMBER",     re.compile(r'\bNUMBER\b',     re.I),
         "Oracle NUMBER type not converted",
         # NUMBER is valid in Snowflake and Synapse (as NUMERIC alias)
         {"snowflake", "oracle"}),
        ("RESIDUAL_VARCHAR2",   re.compile(r'\bVARCHAR2\b',   re.I),
         "VARCHAR2 not converted",                {"oracle"}),
        ("RESIDUAL_DECODE",     re.compile(r'\bDECODE\s*\(',  re.I),
         "DECODE() not converted",
         # DECODE is valid in Redshift, Oracle, and Snowflake
         {"redshift", "oracle", "snowflake"}),
        ("RESIDUAL_ROWNUM",     re.compile(r'\bROWNUM\b',     re.I),
         "ROWNUM not converted",                  set()),
        ("RESIDUAL_SYSDATE",    re.compile(r'\bSYSDATE\b',    re.I),
         "SYSDATE not converted",                 {"oracle"}),
        ("RESIDUAL_DUAL",       re.compile(r'\bFROM\s+DUAL\b',re.I),
         "FROM DUAL not converted",               {"oracle"}),
        # NVL (not NVL2): valid in Oracle, Redshift, Snowflake, Databricks
        ("RESIDUAL_NVL_ORA",    re.compile(r'\bNVL(?!2)\s*\(', re.I),
         "NVL() not converted",
         {"redshift", "oracle", "snowflake", "databricks"}),
        # NVL2: only valid in Oracle and Snowflake
        ("RESIDUAL_NVL2_ORA",   re.compile(r'\bNVL2\s*\(',   re.I),
         "NVL2() not converted",
         {"oracle", "snowflake"}),
    ],
    "sqlserver": [
        ("RESIDUAL_SELECT_TOP", re.compile(r'\bSELECT\s+TOP\b', re.I),
         "SELECT TOP not converted",              set()),
        ("RESIDUAL_NOLOCK",     re.compile(r'\bNOLOCK\b',     re.I),
         "NOLOCK hint not converted",             set()),
        ("RESIDUAL_GETDATE",    re.compile(r'\bGETDATE\s*\(\)', re.I),
         "GETDATE() not converted",
         # GETDATE() is also valid in Synapse, Fabric DW (T-SQL family), and Redshift
         {"sqlserver", "synapse", "fabric_dw", "redshift"}),
        ("RESIDUAL_ISNULL_TSQL",re.compile(r'\bISNULL\s*\(',  re.I),
         "ISNULL() not converted",
         # ISNULL is valid in SQL Server, Synapse, Fabric DW (T-SQL family)
         {"sqlserver", "synapse", "fabric_dw"}),
        ("RESIDUAL_LEN",        re.compile(r'\bLEN\s*\(',     re.I),
         "LEN() not converted",
         {"sqlserver", "synapse", "fabric_dw"}),
        ("RESIDUAL_CHARINDEX",  re.compile(r'\bCHARINDEX\s*\(', re.I),
         "CHARINDEX() not converted",
         {"sqlserver", "synapse", "fabric_dw"}),
    ],
    "synapse": [
        ("RESIDUAL_DIST_SYNAPSE", re.compile(r'\bDISTRIBUTION\s*=', re.I),
         "DISTRIBUTION clause not converted",     {"synapse"}),
        ("RESIDUAL_HEAP",         re.compile(r'\bWITH\s*\(\s*HEAP\b', re.I),
         "HEAP table not converted",              {"synapse"}),
        ("RESIDUAL_CCI",          re.compile(r'\bCLUSTERED\s+COLUMNSTORE\b', re.I),
         "CCI index not converted",               {"synapse"}),
    ],
    "fabric_dw": [
        ("RESIDUAL_DIST_FABRIC", re.compile(r'\bDISTRIBUTION\s*=', re.I),
         "DISTRIBUTION clause not converted",     {"fabric_dw", "synapse"}),
        ("RESIDUAL_CLUSTER_BY_FABRIC", re.compile(r'\bCLUSTER\s+BY\b', re.I),
         "CLUSTER BY not converted",
         # CLUSTER BY is valid in Fabric DW itself, BigQuery, Databricks, Snowflake
         {"fabric_dw", "bigquery", "databricks", "snowflake"}),
    ],
    "databricks": [
        ("RESIDUAL_DELTA",       re.compile(r'\bUSING\s+DELTA\b',   re.I),
         "USING DELTA not converted",
         # USING DELTA is also valid in Fabric Lakehouse (Delta Lake tables)
         {"databricks", "fabric_lakehouse"}),
        ("RESIDUAL_TBLPROPS",    re.compile(r'\bTBLPROPERTIES\b',   re.I),
         "TBLPROPERTIES not converted",           {"databricks"}),
        ("RESIDUAL_PARTITIONED", re.compile(r'\bPARTITIONED\s+BY\b',re.I),
         "PARTITIONED BY not converted",
         # PARTITIONED BY is also valid in Fabric Lakehouse Spark SQL
         {"databricks", "fabric_lakehouse"}),
        ("RESIDUAL_LIQUID",      re.compile(r'\bCLUSTER\s+BY\b',    re.I),
         "CLUSTER BY (liquid) not converted",
         # CLUSTER BY is valid in Fabric DW, BigQuery, Snowflake
         {"fabric_dw", "bigquery", "snowflake", "databricks"}),
    ],
    "bigquery": [
        ("RESIDUAL_PARTITION_BQ",re.compile(r'\bPARTITION\s+BY\b',  re.I),
         "PARTITION BY not converted",
         # PARTITION BY is valid in Oracle, Synapse, Databricks, BigQuery itself
         {"oracle", "synapse", "databricks", "bigquery"}),
        ("RESIDUAL_STRUCT_BQ",   re.compile(r'\bSTRUCT\s*<',        re.I),
         "STRUCT type not converted",             {"bigquery"}),
        ("RESIDUAL_ARRAY_BQ",    re.compile(r'\bARRAY\s*<',         re.I),
         "ARRAY type not converted",              {"bigquery", "databricks"}),
        ("RESIDUAL_GENERATE_UUID", re.compile(r'\bGENERATE_UUID\s*\(\)', re.I),
         "GENERATE_UUID() not converted",         {"bigquery"}),
    ],
}


def validate_residuals(
    generated_sql: str,
    source_dialect: str,
    existing_feature_codes: Set[str],
    target_dialect: Optional[str] = None,
) -> List[IRWarning]:
    """
    Check generated SQL for leftover source-dialect syntax.

    Args:
        generated_sql:          The output SQL text to scan.
        source_dialect:         The source dialect key (e.g. "redshift").
        existing_feature_codes: Feature codes already reported; prevents
                                duplicate warnings.
        target_dialect:         The target dialect key; used to suppress
                                patterns that are valid in the target.

    Returns:
        List of new IRWarning objects for any residual patterns found.
    """
    patterns = _RESIDUALS.get(source_dialect, [])
    if not patterns:
        return []

    # Strip procedure/function bodies before scanning to avoid false positives
    # on NVL, ::, DECODE etc. that are legitimately passed through as-is.
    scan_sql = _strip_procedure_bodies(generated_sql)

    tgt = (target_dialect or "").lower()
    new_warnings: List[IRWarning] = []
    seen: Set[str] = set()

    for rule_id, pattern, description, skip_for_targets in patterns:
        if rule_id in existing_feature_codes or rule_id in seen:
            continue
        # Skip if this pattern is valid syntax in the target dialect
        if tgt and tgt in skip_for_targets:
            continue
        if pattern.search(scan_sql):
            seen.add(rule_id)
            new_warnings.append(IRWarning(
                feature=rule_id,
                message=(
                    f"Residual source-dialect syntax detected: {description}. "
                    f"Please review and correct this manually in the output SQL."
                ),
                severity=Warningseverity.WARNING,
                fallback_applied=False,
                unsupported=False,
            ))

    return new_warnings


def compute_confidence(
    warnings: List[IRWarning],
    unsupported_features: List[IRWarning],
    residual_warnings: List[IRWarning],
) -> Tuple[float, str]:
    """
    Compute a confidence score for the transpilation result.

    Tiers (matching official Redshift-Fabric-Transpiler calibration):
      MANUAL_REVIEW  → 0.50  (any unsupported / blocker feature)
      PARTIAL        → max(0.65, 1.0 - n*0.05)  where n = warn + residual count
      HIGH           → 1.00  (no warnings of any kind)

    Returns:
        (score: float, level: str)
    """
    if unsupported_features:
        return 0.50, "MANUAL_REVIEW"

    warn_count = len(warnings) + len(residual_warnings)
    if warn_count > 0:
        score = max(0.65, 1.0 - warn_count * 0.05)
        return round(score, 2), "PARTIAL"

    return 1.00, "HIGH"
