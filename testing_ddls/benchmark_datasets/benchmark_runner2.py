#!/usr/bin/env python3
"""
Fast benchmark runner v2 — flushes progress immediately, shorter per-request
timeout, and writes results incrementally to a JSONL file so progress is
visible even if the process is killed mid-run.
"""
from __future__ import annotations
import json
import os
import re
import sys
import time
import urllib.request
import urllib.error
from pathlib import Path

API_BASE = "http://127.0.0.1:8000"
REQUEST_TIMEOUT = 25  # seconds — if a single conversion takes longer, something is wrong

ALL_DIALECTS = [
    "redshift", "snowflake", "sqlserver", "synapse",
    "fabric_dw", "fabric_lakehouse", "databricks", "oracle", "bigquery",
]

FILE_DIALECT_MAP = {
    "chinook/chinook_oracle.sql": "oracle",
    "chinook/chinook_sqlserver.sql": "sqlserver",
    "oracle_sample_schemas/hr_tables.sql": "oracle",
    "oracle_sample_schemas/hr_views.sql": "oracle",
    "oracle_sample_schemas/hr_procedures.sql": "oracle",
    "oracle_sample_schemas/co_tables.sql": "oracle",
    "oracle_sample_schemas/oe_tables.sql": "oracle",
    "oracle_sample_schemas/oe_views.sql": "oracle",
    "oracle_sample_schemas/oe_object_types.sql": "oracle",
    "oracle_sample_schemas/sh_tables.sql": "oracle",
    "adventureworks/adventureworks_tables.sql": "sqlserver",
    "adventureworks/adventureworks_views.sql": "sqlserver",
    "adventureworks/adventureworks_procedures.sql": "sqlserver",
    "adventureworks/adventureworks_functions.sql": "sqlserver",
    "adventureworks/adventureworks_triggers.sql": "sqlserver",
    "adventureworks/adventureworks_types.sql": "sqlserver",
    "adventureworks/adventureworks_dw_tables.sql": "sqlserver",
    "adventureworks/adventureworks_dw_views.sql": "sqlserver",
    "adventureworks/adventureworks_dw_functions.sql": "sqlserver",
    "wideworldimporters/wwi_tables.sql": "sqlserver",
    "wideworldimporters/wwi_views.sql": "sqlserver",
    "wideworldimporters/wwi_procedures.sql": "sqlserver",
    "wideworldimporters/wwi_functions.sql": "sqlserver",
    "wideworldimporters/wwi_dw_tables.sql": "sqlserver",
    "wideworldimporters/wwi_dw_procedures.sql": "sqlserver",
    "wideworldimporters/wwi_dw_functions.sql": "sqlserver",
    "bigquery_public/bigquery_analytics_tables.sql": "bigquery",
    "databricks_samples/databricks_delta_tables.sql": "databricks",
    "redshift_samples/redshift_warehouse_tables.sql": "redshift",
    "mslearn_fabric/fabric_dw_tables.sql": "fabric_dw",
    "mslearn_fabric/fabric_dw_views.sql": "fabric_dw",
    "mslearn_fabric/fabric_dw_procedures.sql": "fabric_dw",
    "mslearn_fabric/fabric_dw_dim_load.sql": "fabric_dw",
    "mslearn_fabric/fabric_lakehouse_views.sql": "fabric_lakehouse",
    "tpc_h/tpch_schema.sql": "sqlserver",
    "tpc_ds/tpcds_schema.sql": "sqlserver",
    "sqlglot_fixtures/extracted/bigquery_ddl.sql": "bigquery",
    "sqlglot_fixtures/extracted/snowflake_ddl.sql": "snowflake",
    "sqlglot_fixtures/extracted/tsql_ddl.sql": "sqlserver",
    "sqlglot_fixtures/extracted/oracle_ddl.sql": "oracle",
    "sqlglot_fixtures/extracted/redshift_ddl.sql": "redshift",
    "sqlglot_fixtures/extracted/databricks_ddl.sql": "databricks",
    "sqlglot_fixtures/extracted/spark_ddl.sql": "databricks",
}


def call_transpile(sql, source, target):
    payload = json.dumps({"sql": sql, "source_dialect": source, "target_dialect": target}).encode("utf-8")
    req = urllib.request.Request(
        f"{API_BASE}/api/transpile", data=payload,
        headers={"Content-Type": "application/json"}, method="POST",
    )
    with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as resp:
        return json.loads(resp.read().decode("utf-8"))


def _strip_procedure_bodies(sql):
    """Mirror app.validator._strip_procedure_bodies: procedure/function bodies
    are intentionally passed through untranslated, so spot-checks must not
    flag source-dialect syntax that only appears inside them."""
    sql = re.sub(r'\$\$.*?\$\$', ' ', sql, flags=re.DOTALL)
    sql = re.sub(r'\bBEGIN\b.*?\bEND\b\s*;', ' ', sql, flags=re.DOTALL | re.IGNORECASE)
    sql = re.sub(r'\bAS\s*\(\n[\s\S]*?\n\s*\)\s*;', 'AS ();', sql, flags=re.MULTILINE)
    sql = re.sub(r'r""".*?"""', ' ', sql, flags=re.DOTALL)
    sql = re.sub(r'\bRETURN\b[^;]+;', ' ', sql, flags=re.DOTALL | re.IGNORECASE)
    return sql


def detect_issues(resp, source, target):
    issues = []
    converted = resp.get("converted_sql", "")
    confidence = resp.get("confidence_score", 0)
    if not converted.strip():
        issues.append("EMPTY_OUTPUT")
        return issues
    if confidence < 0.3:
        issues.append(f"LOW_CONFIDENCE({confidence:.2f})")
    sql_nc = _strip_procedure_bodies(converted)
    sql_nc = re.sub(r'/\*.*?\*/', ' ', sql_nc, flags=re.DOTALL)
    sql_nc = re.sub(r'--[^\n]*', ' ', sql_nc)
    sql_nc_l = sql_nc.lower()
    if target in ("sqlserver", "synapse", "fabric_dw"):
        if re.search(r'\bnvl\s*\(', sql_nc_l):
            issues.append("NVL_NOT_CONVERTED")
        if '::' in sql_nc:
            issues.append("DOUBLE_COLON_CAST_LEFT")
    if target == "oracle":
        if re.search(r'\bisnull\s*\(', sql_nc_l):
            issues.append("ISNULL_NOT_CONVERTED")
        if '`' in sql_nc:
            issues.append("BACKTICK_IN_ORACLE")
    if target == "bigquery":
        if re.search(r'\bisnull\s*\(', sql_nc_l):
            issues.append("ISNULL_NOT_CONVERTED")
    return issues


def main():
    base_dir = Path(__file__).parent
    out_path = base_dir / "benchmark_results.jsonl"
    log_path = base_dir / "benchmark_progress.log"

    total_pairs = sum(len(ALL_DIALECTS) - 1 for _ in FILE_DIALECT_MAP)
    done = 0
    t_start = time.monotonic()

    with open(out_path, "w", encoding="utf-8") as out_f, open(log_path, "w", encoding="utf-8") as log_f:
        def log(msg):
            print(msg, flush=True)
            log_f.write(msg + "\n")
            log_f.flush()

        log(f"Starting benchmark: {len(FILE_DIALECT_MAP)} files x up to {len(ALL_DIALECTS)-1} targets = {total_pairs} pairs")
        log(f"Per-request timeout: {REQUEST_TIMEOUT}s\n")

        for rel_path, source_dialect in sorted(FILE_DIALECT_MAP.items()):
            file_path = base_dir / rel_path.replace("/", os.sep)
            if not file_path.exists():
                log(f"[SKIP] {rel_path} - not found")
                continue
            sql = file_path.read_text(encoding="utf-8", errors="replace")
            source_name = rel_path.split("/")[0]
            file_name = file_path.name

            file_pass, file_total = 0, 0
            for target in ALL_DIALECTS:
                if target == source_dialect:
                    continue
                file_total += 1
                done += 1
                t0 = time.monotonic()
                record = {"source": source_name, "file": file_name, "from": source_dialect, "to": target}
                try:
                    resp = call_transpile(sql, source_dialect, target)
                    elapsed = time.monotonic() - t0
                    issues = detect_issues(resp, source_dialect, target)
                    success = len(issues) == 0 and bool(resp.get("converted_sql", "").strip())
                    record.update({
                        "success": success, "confidence": resp.get("confidence_score", 0),
                        "elapsed_s": round(elapsed, 2), "issues": issues,
                    })
                    if success:
                        file_pass += 1
                except Exception as exc:
                    elapsed = time.monotonic() - t0
                    record.update({"success": False, "confidence": 0, "elapsed_s": round(elapsed, 2),
                                   "issues": ["API_ERROR"], "error": str(exc)[:200]})
                    if elapsed >= REQUEST_TIMEOUT - 1:
                        log(f"  !!! TIMEOUT/SLOW: {rel_path} {source_dialect}->{target} took {elapsed:.1f}s")

                out_f.write(json.dumps(record) + "\n")
                out_f.flush()

                pct = done / total_pairs * 100
                elapsed_total = time.monotonic() - t_start
                if record["elapsed_s"] > 3:
                    log(f"  [{done}/{total_pairs} {pct:.0f}%] SLOW {record['elapsed_s']}s: {rel_path} {source_dialect}->{target}")

            marker = "OK" if file_pass == file_total else "WN" if file_pass > 0 else "XX"
            log(f"[{marker}] {rel_path:55} {file_pass}/{file_total}  (total elapsed {time.monotonic()-t_start:.0f}s)")

        total_elapsed = time.monotonic() - t_start
        log(f"\nDone. Total elapsed: {total_elapsed:.1f}s ({total_elapsed/60:.1f} min)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
