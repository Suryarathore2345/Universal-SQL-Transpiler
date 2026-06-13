"""
Post-conversion residual validator.

Scans the generated (target) SQL for leftover source-dialect syntax that
the generator may have missed.  Each residual found adds a WARNING to the
result and applies a confidence penalty of 5 % (floored at 0.30).

Pattern inspired by the Redshift-Fabric-Transpiler safety-net approach.
"""
from __future__ import annotations

import re
from typing import Dict, List, Tuple

from app.ir.models import IRWarning, Warningseverity


# ---------------------------------------------------------------------------
# Residual pattern registry
# Format:  rule_id, compiled_pattern, human-readable description
# ---------------------------------------------------------------------------

_RESIDUALS: Dict[str, List[Tuple[str, re.Pattern, str]]] = {
    "redshift": [
        ("RESIDUAL_DISTKEY",    re.compile(r'\bDISTKEY\b',    re.I), "DISTKEY not converted"),
        ("RESIDUAL_SORTKEY",    re.compile(r'\bSORTKEY\b',    re.I), "SORTKEY not converted"),
        ("RESIDUAL_DISTSTYLE",  re.compile(r'\bDISTSTYLE\b',  re.I), "DISTSTYLE not converted"),
        ("RESIDUAL_PG_CAST",    re.compile(r'::\s*\w+'),              "PostgreSQL :: cast not converted"),
        ("RESIDUAL_NVL",        re.compile(r'\bNVL\s*\(',     re.I), "NVL() not converted"),
        ("RESIDUAL_ILIKE",      re.compile(r'\bILIKE\b',      re.I), "ILIKE not converted"),
        ("RESIDUAL_SUPER",      re.compile(r'\bSUPER\b',      re.I), "SUPER type not converted"),
        ("RESIDUAL_ENCODE",     re.compile(r'\bENCODE\s+\w+', re.I), "ENCODE compression not converted"),
    ],
    "snowflake": [
        ("RESIDUAL_VARIANT",    re.compile(r'\bVARIANT\b',    re.I), "VARIANT type not converted"),
        ("RESIDUAL_FLATTEN",    re.compile(r'\bFLATTEN\s*\(', re.I), "FLATTEN not converted"),
        ("RESIDUAL_QUALIFY",    re.compile(r'\bQUALIFY\b',    re.I), "QUALIFY clause not converted"),
        ("RESIDUAL_CLUSTER_BY", re.compile(r'\bCLUSTER\s+BY\b', re.I), "CLUSTER BY not converted"),
        ("RESIDUAL_SEQUENCE",   re.compile(r'\.NEXTVAL\b',    re.I), ".NEXTVAL sequence not converted"),
    ],
    "oracle": [
        ("RESIDUAL_NUMBER",     re.compile(r'\bNUMBER\b',     re.I), "Oracle NUMBER type not converted"),
        ("RESIDUAL_VARCHAR2",   re.compile(r'\bVARCHAR2\b',   re.I), "VARCHAR2 not converted"),
        ("RESIDUAL_DECODE",     re.compile(r'\bDECODE\s*\(',  re.I), "DECODE() not converted"),
        ("RESIDUAL_ROWNUM",     re.compile(r'\bROWNUM\b',     re.I), "ROWNUM not converted"),
        ("RESIDUAL_SYSDATE",    re.compile(r'\bSYSDATE\b',    re.I), "SYSDATE not converted"),
        ("RESIDUAL_DUAL",       re.compile(r'\bFROM\s+DUAL\b',re.I), "FROM DUAL not converted"),
        ("RESIDUAL_NVL_ORA",    re.compile(r'\bNVL2?\s*\(',   re.I), "NVL/NVL2 not converted"),
    ],
    "sqlserver": [
        ("RESIDUAL_SELECT_TOP", re.compile(r'\bSELECT\s+TOP\b', re.I), "SELECT TOP not converted"),
        ("RESIDUAL_NOLOCK",     re.compile(r'\bNOLOCK\b',     re.I), "NOLOCK hint not converted"),
        ("RESIDUAL_GETDATE",    re.compile(r'\bGETDATE\s*\(\)', re.I), "GETDATE() not converted"),
        ("RESIDUAL_ISNULL_TSQL",re.compile(r'\bISNULL\s*\(',  re.I), "ISNULL() not converted"),
        ("RESIDUAL_LEN",        re.compile(r'\bLEN\s*\(',     re.I), "LEN() not converted"),
        ("RESIDUAL_CHARINDEX",  re.compile(r'\bCHARINDEX\s*\(', re.I), "CHARINDEX() not converted"),
    ],
    "synapse": [
        ("RESIDUAL_DIST_SYNAPSE", re.compile(r'\bDISTRIBUTION\s*=', re.I), "DISTRIBUTION clause not converted"),
        ("RESIDUAL_HEAP",         re.compile(r'\bWITH\s*\(\s*HEAP\b', re.I), "HEAP table not converted"),
        ("RESIDUAL_CCI",          re.compile(r'\bCLUSTERED\s+COLUMNSTORE\b', re.I), "CCI index not converted"),
    ],
    "fabric_dw": [
        ("RESIDUAL_DIST_FABRIC", re.compile(r'\bDISTRIBUTION\s*=', re.I), "DISTRIBUTION clause not converted"),
    ],
    "databricks": [
        ("RESIDUAL_DELTA",       re.compile(r'\bUSING\s+DELTA\b',   re.I), "USING DELTA not converted"),
        ("RESIDUAL_TBLPROPS",    re.compile(r'\bTBLPROPERTIES\b',   re.I), "TBLPROPERTIES not converted"),
        ("RESIDUAL_PARTITIONED", re.compile(r'\bPARTITIONED\s+BY\b',re.I), "PARTITIONED BY not converted"),
        ("RESIDUAL_LIQUID",      re.compile(r'\bCLUSTER\s+BY\b',    re.I), "CLUSTER BY (liquid) not converted"),
    ],
    "bigquery": [
        ("RESIDUAL_PARTITION_BQ",re.compile(r'\bPARTITION\s+BY\b',  re.I), "PARTITION BY not converted"),
        ("RESIDUAL_STRUCT_BQ",   re.compile(r'\bSTRUCT\s*<',        re.I), "STRUCT type not converted"),
        ("RESIDUAL_ARRAY_BQ",    re.compile(r'\bARRAY\s*<',         re.I), "ARRAY type not converted"),
        ("RESIDUAL_GENERATE_UUID", re.compile(r'\bGENERATE_UUID\s*\(\)', re.I), "GENERATE_UUID() not converted"),
    ],
}


def validate_residuals(
    generated_sql: str,
    source_dialect: str,
    existing_feature_codes: set,
) -> List[IRWarning]:
    """
    Check generated SQL for leftover source-dialect syntax.

    Args:
        generated_sql:          The output SQL text to scan.
        source_dialect:         The source dialect key (e.g. "redshift").
        existing_feature_codes: Feature codes already reported; prevents
                                duplicate warnings.

    Returns:
        List of new IRWarning objects for any residual patterns found.
    """
    patterns = _RESIDUALS.get(source_dialect, [])
    new_warnings: List[IRWarning] = []
    seen: set = set()

    for rule_id, pattern, description in patterns:
        if rule_id in existing_feature_codes or rule_id in seen:
            continue
        if pattern.search(generated_sql):
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
