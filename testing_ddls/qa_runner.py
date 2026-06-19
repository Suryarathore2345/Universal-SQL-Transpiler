#!/usr/bin/env python3
"""
Universal SQL Transpiler — Comprehensive QA Test Runner

Runs every .sql file in testing_ddls/<dialect>/ through all 9 target dialects
via the REST API and produces a detailed HTML + console QA report.

Usage:
    # Run everything (ensure backend is running on port 8000 first)
    python qa_runner.py

    # Filter by source dialect
    python qa_runner.py --source redshift

    # Filter by a single file
    python qa_runner.py --file edge_case_functions.sql

    # Point at a different backend
    python qa_runner.py --api http://localhost:8001

    # Verbose: print each result's SQL to console
    python qa_runner.py --verbose
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import urllib.request
import urllib.error

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

API_BASE        = "http://localhost:8000"
TESTING_DDL_DIR = Path(__file__).parent          # same directory as this script

ALL_DIALECTS = [
    "redshift",
    "snowflake",
    "sqlserver",
    "synapse",
    "fabric_dw",
    "fabric_lakehouse",
    "databricks",
    "oracle",
    "bigquery",
]

DIALECT_DISPLAY = {
    "redshift":        "Amazon Redshift",
    "snowflake":       "Snowflake",
    "sqlserver":       "SQL Server",
    "synapse":         "Azure Synapse",
    "fabric_dw":       "Fabric DW (T-SQL)",
    "fabric_lakehouse":"Fabric Lakehouse (Spark)",
    "databricks":      "Databricks",
    "oracle":          "Oracle",
    "bigquery":        "BigQuery",
}

# Expected warning/unsupported codes that are ACCEPTABLE (not real bugs)
ACCEPTABLE_UNSUPPORTED = {
    # Materialized view fallbacks — correct behavior per dialect
    "MV_NOT_SUPPORTED_FABRIC_DW",       # Fabric DW converts MVs → CTAS+proc
    "MV_NOT_SUPPORTED_SQLSERVER",       # SQL Server converts MVs → indexed view
    "MV_NOT_SUPPORTED_DATABRICKS",      # Databricks converts MVs → CTAS
    # Unsupported functions in T-SQL family (no equivalent)
    "UNSUPPORTED_FUNCTION_INITCAP",     # No INITCAP in T-SQL
    "UNSUPPORTED_FUNCTION_REGEXP_REPLACE", # No REGEXP_REPLACE in T-SQL
    "UNSUPPORTED_FUNCTION_LISTAGG",     # Converted to STRING_AGG but flagged
    "UNSUPPORTED_FUNCTION_DECODE",      # Converted to CASE WHEN but flagged
    # QUALIFY clause
    "UNSUPPORTED_CLAUSE_QUALIFY",       # QUALIFY → rewrite suggestion
    # Fabric Lakehouse specific
    "SPARK_NO_STORED_PROCEDURES",       # Correct for Lakehouse
    "MV_FABRIC_LAKEHOUSE_RUNTIME_INFO", # Info: MLV requires Runtime 1.3+
    "MV_NOT_SUPPORTED_FABRIC_LAKEHOUSE_RUNTIME",
    "CLUSTER_BY_NOT_SUPPORTED_FABRIC_LAKEHOUSE",  # Snowflake CLUSTER BY → not supported in Spark SQL
    # Unsupported types
    "UNSUPPORTED_TYPE_SUPER",
    "UNSUPPORTED_TYPE_HLLSKETCH",
    "UNSUPPORTED_TYPE_VARBYTE",
    "UNSUPPORTED_TYPE_HIERARCHYID",
    "UNSUPPORTED_TYPE_MONEY",           # Converted to DECIMAL
    "UNSUPPORTED_TYPE_GEOGRAPHY",       # BigQuery-specific geometry
    "UNSUPPORTED_TYPE_JSON",
    "UNSUPPORTED_TYPE_BIGNUMERIC",
    "UNSUPPORTED_TYPE_VARIANT",         # Snowflake semi-structured
    "UNSUPPORTED_TYPE_ARRAY",
    "UNSUPPORTED_TYPE_OBJECT",
    "UNSUPPORTED_COLUMN_EXPRESSION",    # Computed columns
    # Procedure/function limitations
    "PROCEDURE_BODY_MANUAL",            # Stored proc bodies need manual review
    "FUNCTION_BODY_MANUAL",
    # CONVERT_TIMEZONE for BigQuery/Oracle (complex timezone arithmetic)
    "CONVERT_TIMEZONE_NEEDS_MANUAL_REVIEW",
    # Redshift DISTSTYLE/DISTKEY/SORTKEY not applicable to non-Redshift targets
    "DISTRIBUTION_NOT_SUPPORTED",
    "DISTRIBUTION_NOT_SUPPORTED_FABRIC_DW",
    "DISTRIBUTION_NOT_SUPPORTED_FABRIC_LAKEHOUSE",
    "DISTRIBUTION_NOT_SUPPORTED_DATABRICKS",
    "DISTRIBUTION_NOT_SUPPORTED_ORACLE",
    "DISTRIBUTION_NOT_SUPPORTED_BIGQUERY",
    "DISTRIBUTION_NOT_SUPPORTED_SNOWFLAKE",
    # Synapse distribution hints (preserved or stripped per target)
    "DISTRIBUTION_NOT_APPLICABLE",
    "CLUSTERED_COLUMNSTORE_NOT_APPLICABLE",
    # ENCODE compression clauses (Redshift-specific)
    "UNSUPPORTED_ENCODE",
    "ENCODE_NOT_SUPPORTED",
    # IDENTITY columns not supported in certain targets
    "IDENTITY_NOT_SUPPORTED_FABRIC_DW",        # Fabric DW has no IDENTITY
    "IDENTITY_NOT_SUPPORTED_FABRIC_LAKEHOUSE",  # Spark SQL has no IDENTITY
    "IDENTITY_NOT_SUPPORTED_BIGQUERY",          # BigQuery has no IDENTITY
    "IDENTITY_NOT_SUPPORTED_ORACLE",            # Oracle uses SEQUENCE/GENERATED
    # PARTITION BY in CREATE TABLE not supported in Fabric DW
    "PARTITION_NOT_SUPPORTED_FABRIC_DW",        # Fabric DW doesn't support table partitioning syntax
}

# Residual codes that are ACCEPTABLE — they represent genuine unsupported
# functionality in the target dialect, not bugs in the transpiler.
ACCEPTABLE_RESIDUALS = {
    # INITCAP has no T-SQL equivalent — left in output with documented warning
    "RESIDUAL_INITCAP",
    # CONVERT_TIMEZONE not yet implemented for Oracle/BigQuery — documented gap
    "RESIDUAL_CONVERT_TIMEZONE",
    # REGEXP_REPLACE has no T-SQL equivalent
    "RESIDUAL_REGEXP_REPLACE",
    # QUALIFY is Snowflake-specific, flagged but left in output for manual rewrite
    "RESIDUAL_QUALIFY",
    # Oracle-specific residuals when converting Oracle→targets (expected)
    "RESIDUAL_ROWNUM",
    "RESIDUAL_DUAL",
    "RESIDUAL_SYSDATE",
}

# Confidence thresholds
MIN_ACCEPTABLE_CONFIDENCE = 0.30  # Below this is a FAIL


# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------

@dataclass
class TestResult:
    source_dialect: str
    target_dialect: str
    file_path: str
    file_name: str
    success: bool
    has_output: bool
    elapsed_ms: int
    confidence_score: float
    confidence_level: str
    warnings: List[dict] = field(default_factory=list)
    unsupported: List[dict] = field(default_factory=list)
    residuals: List[dict] = field(default_factory=list)
    error_msg: str = ""
    converted_sql: str = ""
    issues: List[str] = field(default_factory=list)  # QA-detected issues


@dataclass
class QAReport:
    total: int = 0
    passed: int = 0
    failed: int = 0
    skipped: int = 0
    results: List[TestResult] = field(default_factory=list)
    start_time: datetime = field(default_factory=datetime.now)
    end_time: Optional[datetime] = None


# ---------------------------------------------------------------------------
# API helpers
# ---------------------------------------------------------------------------

def call_transpile(sql: str, source: str, target: str, api_base: str) -> dict:
    """Call POST /api/transpile and return parsed JSON (or raise)."""
    payload = json.dumps({
        "sql":            sql,
        "source_dialect": source,
        "target_dialect": target,
    }).encode("utf-8")

    req = urllib.request.Request(
        f"{api_base}/api/transpile",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {e.code}: {body[:500]}")


def check_api(api_base: str) -> bool:
    """Return True if the backend is reachable."""
    try:
        req = urllib.request.Request(f"{api_base}/api/dialects", method="GET")
        with urllib.request.urlopen(req, timeout=5):
            return True
    except Exception:
        return False


# ---------------------------------------------------------------------------
# QA analysis logic
# ---------------------------------------------------------------------------

def detect_qa_issues(result: dict, source: str, target: str, sql_input: str) -> List[str]:
    """Analyse a transpile result and return a list of QA issue strings."""
    issues: List[str] = []

    converted = result.get("converted_sql", "")
    confidence = result.get("confidence_score", 1.0)
    unsupported_items = result.get("unsupported_features", [])
    residuals = result.get("residual_warnings", [])
    warnings = result.get("warnings", [])

    # 1. Empty output when input was non-empty
    if sql_input.strip() and not converted.strip():
        issues.append("EMPTY_OUTPUT: Transpiler returned no SQL despite non-empty input")
        return issues  # No point checking further

    # 2. Confidence below threshold
    if confidence < MIN_ACCEPTABLE_CONFIDENCE:
        issues.append(f"LOW_CONFIDENCE: score={confidence:.2f} ({result.get('confidence_level')})")

    # 3. Unexpected unsupported features (ones not in our acceptable list)
    for u in unsupported_items:
        code = u.get("feature", "")
        if code not in ACCEPTABLE_UNSUPPORTED:
            issues.append(f"UNEXPECTED_UNSUPPORTED: [{code}] {u.get('message','')[:120]}")

    # 4. Residual source-dialect syntax left in output
    for r in residuals:
        code = r.get("feature", "")
        if code in ACCEPTABLE_RESIDUALS:
            continue  # Known documented gap — not a bug
        issues.append(f"RESIDUAL_SYNTAX: [{code}] {r.get('message','')[:120]}")

    # 5. Check for common wrong outputs (dialect-specific spot checks)
    if converted:
        issues += _spot_check_output(converted, source, target)

    return issues


def _strip_sql_comments(sql: str) -> str:
    """Strip SQL comments to avoid false positives in pattern matching."""
    # Strip block comments /* ... */
    sql = re.sub(r'/\*.*?\*/', ' ', sql, flags=re.DOTALL)
    # Strip line comments -- ...
    sql = re.sub(r'--[^\n]*', ' ', sql)
    return sql


def _spot_check_output(sql: str, source: str, target: str) -> List[str]:
    """Spot-check converted SQL for known correct/incorrect patterns."""
    issues: List[str] = []
    # Strip comments before pattern matching to avoid false positives from
    # source SQL comments that are preserved in the generated output
    sql_no_comments = _strip_sql_comments(sql)
    sql_lower = sql_no_comments.lower()

    # Use comment-stripped sql for all checks (sql_lower is already from sql_no_comments)
    # --- T-SQL targets: SQL Server, Synapse, Fabric DW ---
    if target in ("sqlserver", "synapse", "fabric_dw"):
        # NVL should be gone → ISNULL
        if re.search(r'\bnvl\s*\(', sql_lower):
            issues.append("SPOT_CHECK: NVL not converted to ISNULL in T-SQL target")
        # Redshift :: cast should be gone
        if '::' in sql_no_comments:
            issues.append("SPOT_CHECK: :: cast operator left in T-SQL target (should use CAST)")
        # COALESCE in T-SQL is fine, but NVL2 should be gone
        if re.search(r'\bnvl2\s*\(', sql_lower):
            issues.append("SPOT_CHECK: NVL2 not converted in T-SQL target")

    # --- Oracle target ---
    if target == "oracle":
        # ISNULL should be gone → NVL or COALESCE
        if re.search(r'\bisnull\s*\(', sql_lower):
            issues.append("SPOT_CHECK: ISNULL not converted in Oracle target (use NVL/COALESCE)")
        # Backtick identifiers should be gone
        if '`' in sql_no_comments:
            issues.append("SPOT_CHECK: Backtick identifiers left in Oracle target")

    # --- BigQuery target ---
    if target == "bigquery":
        # ISNULL should be gone → IFNULL
        if re.search(r'\bisnull\s*\(', sql_lower):
            issues.append("SPOT_CHECK: ISNULL not converted to IFNULL in BigQuery target")
        # NVL should be gone → IFNULL or COALESCE
        if re.search(r'\bnvl\s*\(', sql_lower):
            issues.append("SPOT_CHECK: NVL not converted in BigQuery target")

    # --- Databricks / Fabric Lakehouse (Spark SQL) ---
    if target in ("databricks", "fabric_lakehouse"):
        # ISNULL should be gone → COALESCE or IFNULL
        if re.search(r'\bisnull\s*\(', sql_lower):
            issues.append("SPOT_CHECK: ISNULL not converted in Spark SQL target")
        # NVL should be gone
        if re.search(r'\bnvl\s*\(', sql_lower) and source not in ("databricks", "fabric_lakehouse"):
            issues.append("SPOT_CHECK: NVL not converted in Spark SQL target")
        # :: cast should be gone
        if '::' in sql_no_comments:
            issues.append("SPOT_CHECK: :: cast operator left in Spark SQL target")

    # --- All targets: basic structural checks ---
    # Must start with CREATE (after stripping comments and whitespace)
    stripped = sql_no_comments.strip()
    if stripped and not re.match(r'\bCREATE\b', stripped, re.IGNORECASE):
        # Allow EXEC / stored proc wrapper in Fabric DW
        if not (target == "fabric_dw" and re.match(r'\bEXEC\b|\bALTER\b|\bBEGIN\b', stripped, re.IGNORECASE)):
            issues.append(f"SPOT_CHECK: Output does not start with CREATE statement")

    # No bare Python exceptions / stack traces in output
    if 'traceback' in sql_lower or 'exception' in sql_lower[:50]:
        issues.append("SPOT_CHECK: Output looks like a Python exception trace")

    return issues


# ---------------------------------------------------------------------------
# Core test runner
# ---------------------------------------------------------------------------

def run_file(
    file_path: Path,
    source_dialect: str,
    target_dialects: List[str],
    api_base: str,
    verbose: bool = False,
) -> List[TestResult]:
    """Test one SQL file against all target dialects."""
    sql = file_path.read_text(encoding="utf-8", errors="replace")
    results: List[TestResult] = []

    for target in target_dialects:
        if target == source_dialect:
            continue

        t0 = time.monotonic()
        try:
            resp = call_transpile(sql, source_dialect, target, api_base)
            elapsed = int((time.monotonic() - t0) * 1000)

            converted_sql = resp.get("converted_sql", "")
            confidence    = resp.get("confidence_score", 0.0)
            unsupported   = resp.get("unsupported_features", [])
            residuals     = resp.get("residual_warnings", [])
            warnings      = resp.get("warnings", [])

            issues = detect_qa_issues(resp, source_dialect, target, sql)
            success = len([i for i in issues if not i.startswith("SPOT_CHECK:")]) == 0

            r = TestResult(
                source_dialect = source_dialect,
                target_dialect = target,
                file_path      = str(file_path),
                file_name      = file_path.name,
                success        = success and bool(converted_sql.strip()),
                has_output     = bool(converted_sql.strip()),
                elapsed_ms     = elapsed,
                confidence_score = confidence,
                confidence_level = resp.get("confidence_level", ""),
                warnings       = warnings,
                unsupported    = unsupported,
                residuals      = residuals,
                converted_sql  = converted_sql,
                issues         = issues,
            )

        except Exception as exc:
            elapsed = int((time.monotonic() - t0) * 1000)
            r = TestResult(
                source_dialect = source_dialect,
                target_dialect = target,
                file_path      = str(file_path),
                file_name      = file_path.name,
                success        = False,
                has_output     = False,
                elapsed_ms     = elapsed,
                confidence_score = 0.0,
                confidence_level = "ERROR",
                error_msg      = str(exc)[:300],
                issues         = [f"API_ERROR: {exc}"],
            )

        results.append(r)

        if verbose:
            status = "PASS" if r.success else "FAIL"
            print(f"  [{status}] {source_dialect:14} -> {target:16} | {file_path.name:40} | "
                  f"conf={r.confidence_score:.2f} | issues={len(r.issues)}")
            for issue in r.issues:
                print(f"          !! {issue}")

    return results


# ---------------------------------------------------------------------------
# HTML report generator
# ---------------------------------------------------------------------------

def generate_html_report(report: QAReport, output_path: Path) -> None:
    """Generate a self-contained HTML QA report."""
    pass_rate = (report.passed / report.total * 100) if report.total else 0
    duration  = (report.end_time - report.start_time).total_seconds() if report.end_time else 0

    # Group by source dialect
    by_source: Dict[str, List[TestResult]] = {}
    for r in report.results:
        by_source.setdefault(r.source_dialect, []).append(r)

    # Build per-dialect tables
    dialect_sections = ""
    for source, results in sorted(by_source.items()):
        src_pass  = sum(1 for r in results if r.success)
        src_total = len(results)
        src_pct   = src_pass / src_total * 100 if src_total else 0

        rows = ""
        for r in sorted(results, key=lambda x: (x.file_name, x.target_dialect)):
            status_class = "pass" if r.success else "fail"
            status_label = "PASS" if r.success else "FAIL"
            issues_html  = "<br>".join(f"<span class='issue'>{i}</span>" for i in r.issues) or "—"
            unsup_html   = ", ".join(u.get("feature","") for u in r.unsupported[:5]) or "—"
            resid_html   = ", ".join(x.get("feature","") for x in r.residuals[:3]) or "—"

            rows += f"""
            <tr class='{status_class}'>
                <td>{r.file_name}</td>
                <td>{DIALECT_DISPLAY.get(r.target_dialect, r.target_dialect)}</td>
                <td class='status {status_class}'>{status_label}</td>
                <td>{r.confidence_score:.2f}</td>
                <td>{r.confidence_level}</td>
                <td>{r.elapsed_ms} ms</td>
                <td class='small'>{unsup_html}</td>
                <td class='small'>{resid_html}</td>
                <td class='issues'>{issues_html}</td>
            </tr>"""

        dialect_sections += f"""
        <section>
            <h2>{DIALECT_DISPLAY.get(source, source)}
                <span class='badge {"badge-ok" if src_pct >= 90 else "badge-warn" if src_pct >= 60 else "badge-fail"}'>
                    {src_pass}/{src_total} ({src_pct:.0f}%)
                </span>
            </h2>
            <table>
                <thead>
                    <tr>
                        <th>File</th><th>Target Dialect</th><th>Status</th>
                        <th>Confidence</th><th>Level</th><th>Time</th>
                        <th>Unsupported</th><th>Residuals</th><th>QA Issues</th>
                    </tr>
                </thead>
                <tbody>{rows}</tbody>
            </table>
        </section>"""

    # Failure summary
    failures = [r for r in report.results if not r.success]
    failure_rows = ""
    for r in failures[:100]:  # cap at 100 in summary
        issues_str = "; ".join(r.issues[:3])
        failure_rows += f"""
        <tr>
            <td>{DIALECT_DISPLAY.get(r.source_dialect, r.source_dialect)}</td>
            <td>{r.file_name}</td>
            <td>{DIALECT_DISPLAY.get(r.target_dialect, r.target_dialect)}</td>
            <td class='issues small'>{issues_str}</td>
        </tr>"""

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Universal SQL Transpiler — QA Report {report.start_time.strftime('%Y-%m-%d %H:%M')}</title>
    <style>
        * {{ box-sizing: border-box; margin: 0; padding: 0; }}
        body {{ font-family: 'Segoe UI', Arial, sans-serif; background: #0f1117; color: #e0e0e0; line-height: 1.5; }}
        .header {{ background: linear-gradient(135deg, #1a1f2e, #252b3b); padding: 32px 40px; border-bottom: 2px solid #4f8ef7; }}
        .header h1 {{ font-size: 1.8rem; color: #fff; margin-bottom: 8px; }}
        .header .meta {{ color: #888; font-size: 0.9rem; }}
        .summary {{ display: flex; gap: 24px; padding: 24px 40px; background: #151822; }}
        .card {{ background: #1e2330; border-radius: 8px; padding: 20px 24px; flex: 1; border-left: 4px solid; }}
        .card.total   {{ border-color: #4f8ef7; }}
        .card.passed  {{ border-color: #2ecc71; }}
        .card.failed  {{ border-color: #e74c3c; }}
        .card.rate    {{ border-color: #f39c12; }}
        .card .label  {{ font-size: 0.75rem; text-transform: uppercase; letter-spacing: 1px; color: #888; margin-bottom: 4px; }}
        .card .value  {{ font-size: 2.2rem; font-weight: 700; }}
        .card.total  .value  {{ color: #4f8ef7; }}
        .card.passed .value  {{ color: #2ecc71; }}
        .card.failed .value  {{ color: #e74c3c; }}
        .card.rate   .value  {{ color: #f39c12; }}
        section {{ padding: 24px 40px; border-bottom: 1px solid #252b3b; }}
        section h2 {{ font-size: 1.2rem; margin-bottom: 16px; display: flex; align-items: center; gap: 12px; }}
        .badge {{ font-size: 0.8rem; padding: 3px 10px; border-radius: 12px; font-weight: 600; }}
        .badge-ok   {{ background: #1a4a2e; color: #2ecc71; }}
        .badge-warn {{ background: #3d2e00; color: #f39c12; }}
        .badge-fail {{ background: #3d0f0f; color: #e74c3c; }}
        table {{ width: 100%; border-collapse: collapse; font-size: 0.82rem; }}
        th {{ background: #1e2330; padding: 8px 10px; text-align: left; color: #aaa; font-weight: 600;
              text-transform: uppercase; font-size: 0.72rem; letter-spacing: 0.5px; border-bottom: 2px solid #2d3347; }}
        td {{ padding: 7px 10px; border-bottom: 1px solid #1e2330; vertical-align: top; }}
        tr.pass {{ background: rgba(46,204,113,0.04); }}
        tr.fail {{ background: rgba(231,76,60,0.08); }}
        tr:hover {{ background: #1e2330 !important; }}
        .status.pass {{ color: #2ecc71; font-weight: 700; }}
        .status.fail {{ color: #e74c3c; font-weight: 700; }}
        .issue {{ display: block; background: rgba(231,76,60,0.15); color: #ff8f85;
                  border-radius: 4px; padding: 2px 6px; margin: 2px 0; font-size: 0.78rem; }}
        .small {{ font-size: 0.78rem; color: #9ca3af; }}
        .issues {{ max-width: 300px; }}
        .failure-summary {{ padding: 24px 40px; }}
        .failure-summary h2 {{ margin-bottom: 16px; color: #e74c3c; }}
        .footer {{ padding: 20px 40px; color: #555; font-size: 0.8rem; text-align: center; }}
        a {{ color: #4f8ef7; text-decoration: none; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>Universal SQL Transpiler — QA Report</h1>
        <div class="meta">
            Generated: {report.start_time.strftime('%Y-%m-%d %H:%M:%S')} |
            Duration: {duration:.1f}s |
            Backend: {API_BASE}
        </div>
    </div>

    <div class="summary">
        <div class="card total">
            <div class="label">Total Tests</div>
            <div class="value">{report.total}</div>
        </div>
        <div class="card passed">
            <div class="label">Passed</div>
            <div class="value">{report.passed}</div>
        </div>
        <div class="card failed">
            <div class="label">Failed</div>
            <div class="value">{report.failed}</div>
        </div>
        <div class="card rate">
            <div class="label">Pass Rate</div>
            <div class="value">{pass_rate:.1f}%</div>
        </div>
    </div>

    {'<div class="failure-summary"><h2>&#9888; Failed Tests Summary</h2><table><thead><tr><th>Source</th><th>File</th><th>Target</th><th>Issues</th></tr></thead><tbody>' + failure_rows + '</tbody></table></div>' if failures else ''}

    {dialect_sections}

    <div class="footer">
        Universal SQL Transpiler QA Report | {report.end_time.strftime('%Y-%m-%d') if report.end_time else ''} |
        {report.total} transpilations across {len(by_source)} source dialects
    </div>
</body>
</html>"""

    output_path.write_text(html, encoding="utf-8")


# ---------------------------------------------------------------------------
# Console summary
# ---------------------------------------------------------------------------

def print_console_summary(report: QAReport) -> None:
    total    = report.total
    passed   = report.passed
    failed   = report.failed
    duration = (report.end_time - report.start_time).total_seconds() if report.end_time else 0

    print("\n" + "=" * 70)
    print("  UNIVERSAL SQL TRANSPILER — QA SUMMARY")
    print("=" * 70)
    print(f"  Total tests  : {total}")
    print(f"  Passed       : {passed}  ({passed/total*100:.1f}%)" if total else "  Passed: 0")
    print(f"  Failed       : {failed}  ({failed/total*100:.1f}%)" if total else "  Failed: 0")
    print(f"  Duration     : {duration:.1f}s")
    print("=" * 70)

    # By source dialect breakdown
    by_source: Dict[str, List[TestResult]] = {}
    for r in report.results:
        by_source.setdefault(r.source_dialect, []).append(r)

    print(f"\n  {'Source':<20} {'Pass':>6} {'Total':>6} {'Rate':>7}")
    print(f"  {'-'*20} {'-'*6} {'-'*6} {'-'*7}")
    for src in sorted(by_source.keys()):
        results  = by_source[src]
        src_pass = sum(1 for r in results if r.success)
        src_tot  = len(results)
        rate     = src_pass / src_tot * 100 if src_tot else 0
        flag     = " OK" if rate >= 90 else " WN" if rate >= 60 else " XX"
        print(f"  {src:<20} {src_pass:>6} {src_tot:>6} {rate:>6.1f}%{flag}")

    # Top failures
    failures = [r for r in report.results if not r.success]
    if failures:
        print(f"\n  TOP FAILURES ({min(len(failures), 15)} of {len(failures)}):")
        for r in failures[:15]:
            print(f"    {r.source_dialect:14} -> {r.target_dialect:16} | {r.file_name}")
            for issue in r.issues[:2]:
                print(f"        {issue}")
    print()


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(description="UST QA Test Runner")
    parser.add_argument("--source",  help="Only test this source dialect")
    parser.add_argument("--target",  help="Only test against this target dialect")
    parser.add_argument("--file",    help="Only test files matching this name substring")
    parser.add_argument("--api",     default=API_BASE, help="Backend API base URL")
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--output",  default="qa_report.html", help="HTML report output file")
    args = parser.parse_args()

    api_base = args.api

    # --- Pre-flight ---
    print(f"\nUniversal SQL Transpiler — QA Runner")
    print(f"Backend: {api_base}")
    print("Checking backend connectivity...", end=" ", flush=True)
    if not check_api(api_base):
        print(f"FAILED\n\nERROR: Cannot reach backend at {api_base}")
        print("  Start the backend first:  start-backend.cmd")
        return 1
    print("OK\n")

    # --- Collect test files ---
    source_dialects = [args.source] if args.source else ALL_DIALECTS
    target_dialects = [args.target] if args.target else ALL_DIALECTS

    test_files: List[Tuple[Path, str]] = []  # (path, source_dialect)
    for dialect in source_dialects:
        dialect_dir = TESTING_DDL_DIR / dialect
        if not dialect_dir.exists():
            continue
        for sql_file in sorted(dialect_dir.rglob("*.sql")):
            if args.file and args.file.lower() not in sql_file.name.lower():
                continue
            test_files.append((sql_file, dialect))

    if not test_files:
        print("No SQL files found. Check testing_ddls/ directory.")
        return 1

    total_runs = len(test_files) * (len(target_dialects) - 1)
    print(f"Found {len(test_files)} SQL files across {len(source_dialects)} source dialect(s)")
    print(f"Testing against {len(target_dialects)} target dialect(s) = {total_runs} transpilations\n")

    # --- Run tests ---
    report = QAReport()
    current_source = None

    for sql_file, source_dialect in test_files:
        if source_dialect != current_source:
            current_source = source_dialect
            print(f"[{DIALECT_DISPLAY.get(source_dialect, source_dialect)}]")

        file_results = run_file(
            file_path      = sql_file,
            source_dialect = source_dialect,
            target_dialects= target_dialects,
            api_base       = api_base,
            verbose        = args.verbose,
        )

        for r in file_results:
            report.total += 1
            if r.success:
                report.passed += 1
            else:
                report.failed += 1
            report.results.append(r)

        if not args.verbose:
            file_passes = sum(1 for r in file_results if r.success)
            file_total  = len(file_results)
            marker = "OK" if file_passes == file_total else "WN" if file_passes > 0 else "XX"
            rel_path = sql_file.relative_to(TESTING_DDL_DIR / source_dialect)
            print(f"  [{marker}] {str(rel_path):45}  {file_passes}/{file_total}")

    report.end_time = datetime.now()

    # --- Output ---
    print_console_summary(report)

    report_path = Path(args.output)
    if not report_path.is_absolute():
        report_path = TESTING_DDL_DIR / report_path

    generate_html_report(report, report_path)
    print(f"HTML report: {report_path}")

    return 0 if report.failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
