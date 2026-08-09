"""
Shared utilities for CREATE TRIGGER parsing + generation.

Only SQL Server and Oracle have native CREATE TRIGGER DDL among the 9
target dialects (verified against Microsoft Learn / Oracle docs — see
app/ir/models.py::IRTrigger docstring). sqlglot does not AST-parse
CREATE TRIGGER in either dialect (it falls back to an opaque Command/
Block), so — like procedure_utils.py — everything here is regex-based
extraction from the raw SQL text, mirroring the existing procedure/
function extraction approach.
"""
from __future__ import annotations

import re
from typing import List, Optional, Tuple


def _strip_comments(sql: str) -> str:
    """
    Strip `--` line comments and `/* */` block comments.

    Without this, a comment sitting anywhere before the real trigger
    header (e.g. `-- Calls secure_dml before any DML on EMPLOYEES`) can be
    matched by the `\\bON\\s+...` table-extraction regex instead of the
    real `ON employees` clause, silently corrupting the extracted table
    name — comments are not code and must never be visible to these
    regexes (same rationale as validator.py's _strip_procedure_bodies).
    """
    sql = re.sub(r'/\*.*?\*/', ' ', sql, flags=re.DOTALL)
    sql = re.sub(r'--[^\n]*', ' ', sql)
    return sql


def _trigger_header(sql: str) -> str:
    """
    Return the comment-stripped SQL text before the trigger body's BEGIN
    keyword.

    All trigger header clauses (ON <table>, timing, events, FOR EACH ROW,
    WHEN, NOT FOR REPLICATION) appear before BEGIN in both dialects, so
    restricting extraction to this slice avoids false matches against
    identical keywords that may appear inside the trigger body itself.
    """
    sql = _strip_comments(sql)
    m = re.search(r'^(.*?)\bBEGIN\b', sql, re.IGNORECASE | re.DOTALL)
    return m.group(1) if m else sql


def extract_trigger_table(sql: str) -> Tuple[str, Optional[str]]:
    """
    Extract (table, schema) from the `ON <table>` clause in a CREATE
    TRIGGER header. Caller is responsible for excluding DDL-scoped
    triggers (`ON DATABASE` / `ON ALL SERVER`) before calling this.
    """
    header = _trigger_header(sql)
    m = re.search(
        r'\bON\s+([`"\[]?\w+[`"\]]?)(?:\s*\.\s*([`"\[]?\w+[`"\]]?))?',
        header, re.IGNORECASE,
    )
    if not m:
        return "unknown", None
    p1 = re.sub(r'[`"\[\]]', '', m.group(1))
    p2 = re.sub(r'[`"\[\]]', '', m.group(2)) if m.group(2) else None
    if p2:
        return p2, p1  # schema.table
    return p1, None


def extract_trigger_timing(sql: str) -> str:
    """Extract BEFORE/AFTER/INSTEAD_OF. Defaults to AFTER (both dialects' own default)."""
    header = _trigger_header(sql)
    m = re.search(r'\b(BEFORE|AFTER|INSTEAD\s+OF)\b', header, re.IGNORECASE)
    if not m:
        return "AFTER"
    return re.sub(r'\s+', '_', m.group(1).upper())


def extract_trigger_events(sql: str) -> List[str]:
    """
    Extract the INSERT/UPDATE/DELETE event list. Handles T-SQL's
    comma-separated form (`AFTER INSERT, UPDATE`) and Oracle's
    OR-separated form (`BEFORE INSERT OR UPDATE OR DELETE`).
    """
    header = _trigger_header(sql)
    m = re.search(
        r'\b(?:BEFORE|AFTER|INSTEAD\s+OF)\s+(.+?)\s*'
        r'(?:\bON\b|\bFOR\s+EACH\s+ROW\b|\bWHEN\b|\bAS\b|\bNOT\s+FOR\s+REPLICATION\b|$)',
        header, re.IGNORECASE | re.DOTALL,
    )
    if not m:
        return []
    events_str = re.sub(r'\bOF\b.*', '', m.group(1), flags=re.IGNORECASE | re.DOTALL)
    events: List[str] = []
    for tok in re.split(r'\bOR\b|,', events_str, flags=re.IGNORECASE):
        tok = tok.strip().upper()
        if tok in ("INSERT", "UPDATE", "DELETE"):
            events.append(tok)
    return events


def extract_update_of_columns(sql: str) -> List[str]:
    """Extract Oracle's `UPDATE OF col1, col2` column-specific firing list."""
    header = _trigger_header(sql)
    m = re.search(
        r'\bUPDATE\s+OF\s+([\w,\s]+?)(?:\bON\b|\bFOR\s+EACH\s+ROW\b|\bWHEN\b|\bAS\b|$)',
        header, re.IGNORECASE | re.DOTALL,
    )
    if not m:
        return []
    return [c.strip() for c in m.group(1).split(",") if c.strip()]


def extract_for_each_row(sql: str) -> bool:
    """True if the Oracle `FOR EACH ROW` clause is present (row-level trigger)."""
    return bool(re.search(r'\bFOR\s+EACH\s+ROW\b', _trigger_header(sql), re.IGNORECASE))


def extract_when_condition(sql: str) -> Optional[str]:
    """Extract Oracle's `WHEN (condition)` clause, nested-paren aware."""
    header = _trigger_header(sql)
    m = re.search(r'\bWHEN\s*\(([^)]*(?:\([^)]*\)[^)]*)*)\)', header, re.IGNORECASE | re.DOTALL)
    return m.group(1).strip() if m else None


def extract_not_for_replication(sql: str) -> bool:
    """True if SQL Server's `NOT FOR REPLICATION` option is present."""
    return bool(re.search(r'\bNOT\s+FOR\s+REPLICATION\b', _trigger_header(sql), re.IGNORECASE))


def extract_trigger_body_oracle(sql: str) -> str:
    """
    Extract an Oracle trigger body: BEGIN ... END [trigger_name];

    Unlike a procedure's `END;`, a trigger's closing END is conventionally
    followed by the trigger's own name before the semicolon — the generic
    extract_body_bigquery pattern (BEGIN...END;) does not account for that
    trailing identifier and fails to match, so this is trigger-specific.
    """
    m = re.search(r'\bBEGIN\b(.*)\bEND\b(?:\s+\w+)?\s*;?\s*$', sql, re.IGNORECASE | re.DOTALL)
    return m.group(1).strip() if m else ""
