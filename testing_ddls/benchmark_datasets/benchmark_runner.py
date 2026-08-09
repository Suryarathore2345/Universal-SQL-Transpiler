#!/usr/bin/env python3
"""
Benchmark Dataset Test Runner for the Universal SQL Transpiler.

Maps each benchmark SQL file to its correct source dialect, runs transpilation
to all other dialects, and generates a comprehensive HTML report.

Usage:
    python benchmark_runner.py [--api http://localhost:8000] [--verbose]
"""
from __future__ import annotations

import json
import os
import re
import sys
import time
import urllib.request
import urllib.error
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

API_BASE = "http://127.0.0.1:8000"

def set_api_base(url: str) -> None:
    global API_BASE
    API_BASE = url

ALL_DIALECTS = [
    "redshift", "snowflake", "sqlserver", "synapse",
    "fabric_dw", "fabric_lakehouse", "databricks", "oracle", "bigquery",
]

# Map each benchmark file to its source dialect
FILE_DIALECT_MAP: Dict[str, str] = {
    # Chinook
    "chinook/chinook_oracle.sql": "oracle",
    "chinook/chinook_sqlserver.sql": "sqlserver",
    # Oracle sample schemas
    "oracle_sample_schemas/hr_tables.sql": "oracle",
    "oracle_sample_schemas/hr_views.sql": "oracle",
    "oracle_sample_schemas/hr_procedures.sql": "oracle",
    "oracle_sample_schemas/co_tables.sql": "oracle",
    "oracle_sample_schemas/oe_tables.sql": "oracle",
    "oracle_sample_schemas/oe_views.sql": "oracle",
    "oracle_sample_schemas/oe_object_types.sql": "oracle",
    "oracle_sample_schemas/sh_tables.sql": "oracle",
    # AdventureWorks (SQL Server)
    "adventureworks/adventureworks_tables.sql": "sqlserver",
    "adventureworks/adventureworks_views.sql": "sqlserver",
    "adventureworks/adventureworks_procedures.sql": "sqlserver",
    "adventureworks/adventureworks_functions.sql": "sqlserver",
    "adventureworks/adventureworks_triggers.sql": "sqlserver",
    "adventureworks/adventureworks_types.sql": "sqlserver",
    "adventureworks/adventureworks_dw_tables.sql": "sqlserver",
    "adventureworks/adventureworks_dw_views.sql": "sqlserver",
    "adventureworks/adventureworks_dw_functions.sql": "sqlserver",
    # WideWorldImporters (SQL Server)
    "wideworldimporters/wwi_tables.sql": "sqlserver",
    "wideworldimporters/wwi_views.sql": "sqlserver",
    "wideworldimporters/wwi_procedures.sql": "sqlserver",
    "wideworldimporters/wwi_functions.sql": "sqlserver",
    "wideworldimporters/wwi_dw_tables.sql": "sqlserver",
    "wideworldimporters/wwi_dw_procedures.sql": "sqlserver",
    "wideworldimporters/wwi_dw_functions.sql": "sqlserver",
    # BigQuery
    "bigquery_public/bigquery_analytics_tables.sql": "bigquery",
    # Databricks
    "databricks_samples/databricks_delta_tables.sql": "databricks",
    # Redshift
    "redshift_samples/redshift_warehouse_tables.sql": "redshift",
    # mslearn-fabric
    "mslearn_fabric/fabric_dw_tables.sql": "fabric_dw",
    "mslearn_fabric/fabric_dw_views.sql": "fabric_dw",
    "mslearn_fabric/fabric_dw_procedures.sql": "fabric_dw",
    "mslearn_fabric/fabric_dw_dim_load.sql": "fabric_dw",
    "mslearn_fabric/fabric_lakehouse_views.sql": "fabric_lakehouse",
    # TPC-H (ANSI SQL, test as sqlserver)
    "tpc_h/tpch_schema.sql": "sqlserver",
    # TPC-DS (ANSI SQL, test as sqlserver)
    "tpc_ds/tpcds_schema.sql": "sqlserver",
    # SQLGlot extracted DDL
    "sqlglot_fixtures/extracted/bigquery_ddl.sql": "bigquery",
    "sqlglot_fixtures/extracted/snowflake_ddl.sql": "snowflake",
    "sqlglot_fixtures/extracted/tsql_ddl.sql": "sqlserver",
    "sqlglot_fixtures/extracted/oracle_ddl.sql": "oracle",
    "sqlglot_fixtures/extracted/redshift_ddl.sql": "redshift",
    "sqlglot_fixtures/extracted/databricks_ddl.sql": "databricks",
    "sqlglot_fixtures/extracted/spark_ddl.sql": "databricks",
}


@dataclass
class BenchmarkResult:
    source: str
    file_name: str
    source_dialect: str
    target_dialect: str
    success: bool
    confidence: float
    elapsed_ms: int
    issues: List[str] = field(default_factory=list)
    error: str = ""
    converted_sql_preview: str = ""


def call_transpile(sql: str, source: str, target: str) -> dict:
    payload = json.dumps({
        "sql": sql, "source_dialect": source, "target_dialect": target,
    }).encode("utf-8")
    req = urllib.request.Request(
        f"{API_BASE}/api/transpile", data=payload,
        headers={"Content-Type": "application/json"}, method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {e.code}: {body[:500]}")


def split_sql_objects(sql: str) -> List[str]:
    """Split multi-statement SQL into individual CREATE/ALTER statements."""
    stmts = []
    current = []
    in_dollar = False
    in_single = False
    in_block = False

    for line in sql.split('\n'):
        stripped = line.strip()
        if stripped.startswith('--') and not current:
            continue

        # Track dollar quoting
        if '$$' in line:
            in_dollar = not in_dollar

        current.append(line)

        if not in_dollar and not in_block:
            if stripped.endswith(';') or stripped == '/':
                stmt = '\n'.join(current).strip()
                if stmt and stmt != '/':
                    if stmt.endswith('/'):
                        stmt = stmt[:-1].strip()
                    stmts.append(stmt)
                current = []

    if current:
        stmt = '\n'.join(current).strip()
        if stmt:
            stmts.append(stmt)

    return stmts


def detect_issues(resp: dict, source: str, target: str) -> List[str]:
    issues = []
    converted = resp.get("converted_sql", "")
    confidence = resp.get("confidence_score", 0)

    if not converted.strip():
        issues.append("EMPTY_OUTPUT")
        return issues

    if confidence < 0.3:
        issues.append(f"LOW_CONFIDENCE({confidence:.2f})")

    sql_lower = converted.lower()
    sql_nocomments = re.sub(r'/\*.*?\*/', ' ', converted, flags=re.DOTALL)
    sql_nocomments = re.sub(r'--[^\n]*', ' ', sql_nocomments)
    sql_nc_lower = sql_nocomments.lower()

    if target in ("sqlserver", "synapse", "fabric_dw"):
        if re.search(r'\bnvl\s*\(', sql_nc_lower):
            issues.append("NVL_NOT_CONVERTED")
        if '::' in sql_nocomments:
            issues.append("DOUBLE_COLON_CAST_LEFT")

    if target == "oracle":
        if re.search(r'\bisnull\s*\(', sql_nc_lower):
            issues.append("ISNULL_NOT_CONVERTED")
        if '`' in sql_nocomments:
            issues.append("BACKTICK_IN_ORACLE")

    if target == "bigquery":
        if re.search(r'\bisnull\s*\(', sql_nc_lower):
            issues.append("ISNULL_NOT_CONVERTED")

    if 'traceback' in sql_lower[:200]:
        issues.append("PYTHON_EXCEPTION_IN_OUTPUT")

    return issues


def run_benchmark(verbose: bool = False) -> List[BenchmarkResult]:
    base_dir = Path(__file__).parent
    results = []

    for rel_path, source_dialect in sorted(FILE_DIALECT_MAP.items()):
        file_path = base_dir / rel_path.replace("/", os.sep)
        if not file_path.exists():
            print(f"  [SKIP] {rel_path} - file not found")
            continue

        sql = file_path.read_text(encoding="utf-8", errors="replace")
        if len(sql) > 200_000:
            sql = sql[:200_000]

        source_name = rel_path.split("/")[0]
        file_name = file_path.name

        for target in ALL_DIALECTS:
            if target == source_dialect:
                continue

            t0 = time.monotonic()
            try:
                resp = call_transpile(sql, source_dialect, target)
                elapsed = int((time.monotonic() - t0) * 1000)
                confidence = resp.get("confidence_score", 0)
                converted = resp.get("converted_sql", "")
                issues = detect_issues(resp, source_dialect, target)

                r = BenchmarkResult(
                    source=source_name, file_name=file_name,
                    source_dialect=source_dialect, target_dialect=target,
                    success=len(issues) == 0 and bool(converted.strip()),
                    confidence=confidence, elapsed_ms=elapsed,
                    issues=issues,
                    converted_sql_preview=converted[:200] if converted else "",
                )
            except Exception as exc:
                elapsed = int((time.monotonic() - t0) * 1000)
                r = BenchmarkResult(
                    source=source_name, file_name=file_name,
                    source_dialect=source_dialect, target_dialect=target,
                    success=False, confidence=0, elapsed_ms=elapsed,
                    issues=[f"API_ERROR"], error=str(exc)[:300],
                )

            results.append(r)

            if verbose:
                status = "PASS" if r.success else "FAIL"
                print(f"  [{status}] {source_dialect:14} -> {target:16} | {file_name:45} | conf={r.confidence:.2f}")
                for iss in r.issues:
                    print(f"           !! {iss}")
            else:
                pass

        if not verbose:
            file_results = [r for r in results if r.file_name == file_name]
            passed = sum(1 for r in file_results if r.success)
            total = len(file_results)
            marker = "OK" if passed == total else "WN" if passed > 0 else "XX"
            print(f"  [{marker}] {rel_path:55} {passed}/{total}")

    return results


def generate_report(results: List[BenchmarkResult], output_path: Path) -> None:
    total = len(results)
    passed = sum(1 for r in results if r.success)
    failed = total - passed
    rate = passed / total * 100 if total else 0

    by_source = {}
    for r in results:
        by_source.setdefault(r.source, []).append(r)

    by_dialect = {}
    for r in results:
        by_dialect.setdefault(r.source_dialect, []).append(r)

    # Per-dialect summary
    dialect_rows = ""
    for d in ALL_DIALECTS:
        dr = by_dialect.get(d, [])
        dp = sum(1 for r in dr if r.success)
        dt = len(dr)
        dpct = dp / dt * 100 if dt else 0
        badge = "badge-ok" if dpct >= 90 else "badge-warn" if dpct >= 60 else "badge-fail"
        dialect_rows += f'<tr><td>{d}</td><td>{dp}/{dt}</td><td><span class="badge {badge}">{dpct:.0f}%</span></td></tr>\n'

    # Issue breakdown
    issue_counts: Dict[str, int] = {}
    for r in results:
        for iss in r.issues:
            cat = iss.split("(")[0] if "(" in iss else iss
            issue_counts[cat] = issue_counts.get(cat, 0) + 1

    issue_rows = ""
    for iss, cnt in sorted(issue_counts.items(), key=lambda x: -x[1]):
        issue_rows += f'<tr><td>{iss}</td><td>{cnt}</td></tr>\n'

    # Failure details
    failures = [r for r in results if not r.success]
    fail_rows = ""
    for r in failures[:200]:
        iss_str = "; ".join(r.issues[:3])
        err = f" | {r.error[:100]}" if r.error else ""
        fail_rows += f'<tr><td>{r.source}</td><td>{r.file_name}</td><td>{r.source_dialect}</td><td>{r.target_dialect}</td><td>{r.confidence:.2f}</td><td class="issues">{iss_str}{err}</td></tr>\n'

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>UST Benchmark Report — {datetime.now().strftime('%Y-%m-%d %H:%M')}</title>
<style>
* {{ box-sizing: border-box; margin: 0; padding: 0; }}
body {{ font-family: 'Segoe UI', Arial, sans-serif; background: #0f1117; color: #e0e0e0; line-height: 1.5; }}
.header {{ background: linear-gradient(135deg, #1a1f2e, #252b3b); padding: 32px 40px; border-bottom: 2px solid #4f8ef7; }}
.header h1 {{ font-size: 1.8rem; color: #fff; margin-bottom: 8px; }}
.header .meta {{ color: #888; font-size: 0.9rem; }}
.summary {{ display: flex; gap: 24px; padding: 24px 40px; background: #151822; flex-wrap: wrap; }}
.card {{ background: #1e2330; border-radius: 8px; padding: 20px 24px; flex: 1; min-width: 150px; border-left: 4px solid; }}
.card.total {{ border-color: #4f8ef7; }} .card.passed {{ border-color: #2ecc71; }}
.card.failed {{ border-color: #e74c3c; }} .card.rate {{ border-color: #f39c12; }}
.card .label {{ font-size: 0.75rem; text-transform: uppercase; letter-spacing: 1px; color: #888; margin-bottom: 4px; }}
.card .value {{ font-size: 2.2rem; font-weight: 700; }}
.card.total .value {{ color: #4f8ef7; }} .card.passed .value {{ color: #2ecc71; }}
.card.failed .value {{ color: #e74c3c; }} .card.rate .value {{ color: #f39c12; }}
section {{ padding: 24px 40px; border-bottom: 1px solid #252b3b; }}
h2 {{ font-size: 1.2rem; margin-bottom: 16px; }}
table {{ width: 100%; border-collapse: collapse; font-size: 0.82rem; }}
th {{ background: #1e2330; padding: 8px 10px; text-align: left; color: #aaa; font-weight: 600; text-transform: uppercase; font-size: 0.72rem; border-bottom: 2px solid #2d3347; }}
td {{ padding: 7px 10px; border-bottom: 1px solid #1e2330; vertical-align: top; }}
tr:hover {{ background: #1e2330; }}
.badge {{ font-size: 0.8rem; padding: 3px 10px; border-radius: 12px; font-weight: 600; }}
.badge-ok {{ background: #1a4a2e; color: #2ecc71; }} .badge-warn {{ background: #3d2e00; color: #f39c12; }}
.badge-fail {{ background: #3d0f0f; color: #e74c3c; }}
.issues {{ color: #ff8f85; font-size: 0.78rem; max-width: 400px; }}
.footer {{ padding: 20px 40px; color: #555; font-size: 0.8rem; text-align: center; }}
</style>
</head>
<body>
<div class="header">
    <h1>Universal SQL Transpiler — Benchmark Report</h1>
    <div class="meta">Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} | Sources: {len(FILE_DIALECT_MAP)} files | Transpilations: {total}</div>
</div>
<div class="summary">
    <div class="card total"><div class="label">Total</div><div class="value">{total}</div></div>
    <div class="card passed"><div class="label">Passed</div><div class="value">{passed}</div></div>
    <div class="card failed"><div class="label">Failed</div><div class="value">{failed}</div></div>
    <div class="card rate"><div class="label">Pass Rate</div><div class="value">{rate:.1f}%</div></div>
</div>
<section>
    <h2>Per Source Dialect</h2>
    <table><thead><tr><th>Source Dialect</th><th>Pass/Total</th><th>Rate</th></tr></thead>
    <tbody>{dialect_rows}</tbody></table>
</section>
<section>
    <h2>Issue Breakdown</h2>
    <table><thead><tr><th>Issue Type</th><th>Count</th></tr></thead>
    <tbody>{issue_rows}</tbody></table>
</section>
{'<section><h2>Failed Tests (' + str(len(failures)) + ')</h2><table><thead><tr><th>Source</th><th>File</th><th>From</th><th>To</th><th>Conf</th><th>Issues</th></tr></thead><tbody>' + fail_rows + '</tbody></table></section>' if failures else ''}
<div class="footer">UST Benchmark Report | {len(FILE_DIALECT_MAP)} source files, {total} transpilations across {len(by_source)} sources</div>
</body></html>"""

    output_path.write_text(html, encoding="utf-8")


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--api", default=API_BASE)
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--output", default="benchmark_report.html")
    args = parser.parse_args()

    set_api_base(args.api)

    # Check backend
    try:
        urllib.request.urlopen(f"{API_BASE}/api/health", timeout=5)
    except Exception:
        print(f"ERROR: Backend not reachable at {API_BASE}")
        return 1

    print(f"\nUST Benchmark Runner")
    print(f"Backend: {API_BASE}")
    print(f"Files: {len(FILE_DIALECT_MAP)}")
    print(f"Transpilations: {len(FILE_DIALECT_MAP) * 8}\n")

    results = run_benchmark(verbose=args.verbose)

    total = len(results)
    passed = sum(1 for r in results if r.success)
    rate = passed / total * 100 if total else 0

    print(f"\n{'='*60}")
    print(f"  BENCHMARK RESULTS")
    print(f"{'='*60}")
    print(f"  Total: {total}  |  Passed: {passed}  |  Failed: {total-passed}  |  Rate: {rate:.1f}%")
    print(f"{'='*60}\n")

    output_path = Path(__file__).parent / args.output
    generate_report(results, output_path)
    print(f"Report: {output_path}")

    return 0 if rate >= 80 else 1


if __name__ == "__main__":
    sys.exit(main())
