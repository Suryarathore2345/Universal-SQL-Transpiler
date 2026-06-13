"""
Shared utilities for stored procedure and function parsing + generation.

All official doc references are in each dialect's references.md file.
This module provides dialect-agnostic helpers used by all 8 dialect
parsers and generators for Phase 3 procedural code support.
"""
from __future__ import annotations

import re
from typing import Any, Dict, List, Optional, Tuple

from app.ir.models import (
    Dialect, GenericType, IRDataType, IRDocReference, IRParameter,
    IRWarning, Warningseverity,
)


# ---------------------------------------------------------------------------
# Name extraction
# ---------------------------------------------------------------------------

def extract_obj_name(sql: str, keyword: str = "PROCEDURE") -> Tuple[str, Optional[str], Optional[str]]:
    """
    Extract (name, schema, database) from CREATE PROCEDURE/FUNCTION name_here.
    Handles backtick, double-quote, square-bracket quoting and dotted names.
    """
    pattern = rf'\b{keyword}\b\s+([`"\[]?[\w.`"\[\]]+[`"\]]?)'
    m = re.search(pattern, sql, re.IGNORECASE)
    if not m:
        return "unknown", None, None

    raw = m.group(1).strip()
    # Strip all quoting characters to get the dotted name
    clean = re.sub(r'[`"\[\]]', '', raw)
    parts = clean.split('.')
    if len(parts) >= 3:
        return parts[-1], parts[-2], parts[-3]
    if len(parts) == 2:
        return parts[1], parts[0], None
    return parts[0], None, None


# ---------------------------------------------------------------------------
# Body extraction
# ---------------------------------------------------------------------------

def extract_body_dollar_quote(sql: str) -> str:
    """
    Extract body from Redshift/Snowflake/Databricks dollar-quoted block: $$ ... $$ or $body$ ... $body$.
    """
    m = re.search(r'\$(\w*)\$(.*?)\$\1\$', sql, re.DOTALL)
    return m.group(2).strip() if m else ""


def extract_body_tsql(sql: str) -> str:
    """
    Extract T-SQL body: everything after AS (optionally wrapped in BEGIN...END).
    SQL Server, Synapse, Fabric DW.
    """
    # Find AS keyword at end of param list (not AS in column definitions)
    m = re.search(r'\bAS\b\s*(BEGIN\b.*)$', sql, re.IGNORECASE | re.DOTALL)
    if m:
        return m.group(1).strip()
    # AS without BEGIN
    m = re.search(r'\bAS\b\s*\n(.*?)$', sql, re.IGNORECASE | re.DOTALL)
    if m:
        return m.group(1).strip()
    return ""


def extract_body_oracle(sql: str) -> str:
    """
    Extract Oracle PL/SQL body: everything after AS/IS keyword.
    Includes the BEGIN ... END <name>; wrapper.
    """
    m = re.search(r'\b(?:AS|IS)\b\s*(BEGIN\b.*)', sql, re.IGNORECASE | re.DOTALL)
    if m:
        return m.group(1).strip()
    return ""


def extract_body_bigquery(sql: str) -> str:
    """
    Extract BigQuery body: BEGIN ... END block.
    """
    m = re.search(r'\bBEGIN\b(.*)\bEND\b\s*;?\s*$', sql, re.IGNORECASE | re.DOTALL)
    return m.group(1).strip() if m else ""


def extract_body_best_effort(sql: str) -> str:
    """
    Try all body extraction strategies, return first non-empty match.
    """
    body = extract_body_dollar_quote(sql)
    if body:
        return body
    body = extract_body_tsql(sql)
    if body:
        return body
    body = extract_body_oracle(sql)
    if body:
        return body
    body = extract_body_bigquery(sql)
    if body:
        return body
    # Last resort: everything after the param list
    m = re.search(r'\)\s*(.*?)$', sql, re.DOTALL)
    return m.group(1).strip() if m else sql


def extract_language(sql: str) -> Optional[str]:
    """
    Extract LANGUAGE clause from CREATE PROCEDURE/FUNCTION.
    """
    m = re.search(r'\bLANGUAGE\s+(\w+)', sql, re.IGNORECASE)
    return m.group(1).upper() if m else None


def extract_returns_type(sql: str) -> Optional[str]:
    """
    Extract RETURNS type from CREATE FUNCTION statement.
    """
    m = re.search(r'\bRETURNS\b\s+([\w\(\),\s]+?)(?:\s+LANGUAGE|\s+AS|\s+BEGIN|\s+CALLED|$)', sql, re.IGNORECASE)
    return m.group(1).strip() if m else None


# ---------------------------------------------------------------------------
# Parameter extraction
# ---------------------------------------------------------------------------

def extract_params_str(sql: str, keyword: str = "PROCEDURE") -> str:
    """
    Extract the raw parameter string from CREATE PROCEDURE/FUNCTION ( ... ).
    Returns empty string if no params found.
    """
    # Find procedure/function name and then grab the parameter list
    m = re.search(
        rf'\b{keyword}\b\s+[^\(]+\(([^)]*(?:\([^)]*\)[^)]*)*)\)',
        sql, re.IGNORECASE | re.DOTALL
    )
    return m.group(1).strip() if m else ""


def split_params(params_str: str) -> List[str]:
    """
    Split parameter string on commas, respecting nested parentheses
    (e.g., DECIMAL(18,2) should not split on the inner comma).
    """
    parts = []
    depth = 0
    current: List[str] = []
    for ch in params_str:
        if ch == '(':
            depth += 1
            current.append(ch)
        elif ch == ')':
            depth -= 1
            current.append(ch)
        elif ch == ',' and depth == 0:
            parts.append(''.join(current).strip())
            current = []
        else:
            current.append(ch)
    if current:
        parts.append(''.join(current).strip())
    return [p for p in parts if p]


def parse_single_param(param_str: str) -> Optional[Dict[str, Any]]:
    """
    Parse a single parameter string into a dict: {name, type_str, mode, default}.
    Handles T-SQL (@name TYPE [OUTPUT]), PL/pgSQL (IN name TYPE), Oracle (name IN TYPE),
    Snowflake (name TYPE), BigQuery (IN name TYPE).
    """
    p = param_str.strip()
    if not p:
        return None

    # T-SQL: @name TYPE [= default] [OUTPUT|OUT|READONLY]
    m = re.match(r'^@(\w+)\s+([\w\(\), ]+?)(?:\s*=\s*(.+?))?(?:\s+(OUTPUT|OUT|READONLY))?\s*$', p, re.IGNORECASE)
    if m:
        return {
            'name': m.group(1),
            'type_str': m.group(2).strip(),
            'mode': 'OUT' if m.group(4) and 'OUT' in m.group(4).upper() else 'IN',
            'default': (m.group(3) or "").strip() or None,
        }

    # PL/pgSQL / BigQuery: [IN|OUT|INOUT] name TYPE [DEFAULT|= default]
    m = re.match(
        r'^(IN\s+OUT|INOUT|IN|OUT)?\s*(\w+)\s+([\w\(\), ]+?)(?:\s+(?:DEFAULT|:=|=)\s*(.+))?\s*$',
        p, re.IGNORECASE
    )
    if m:
        raw_mode = (m.group(1) or 'IN').strip().upper().replace(' ', '_')
        mode = 'INOUT' if raw_mode in ('IN_OUT', 'INOUT') else raw_mode
        return {
            'name': m.group(2),
            'type_str': m.group(3).strip(),
            'mode': mode,
            'default': (m.group(4) or "").strip() or None,
        }

    # Oracle: name [IN|OUT|IN OUT] TYPE [DEFAULT default]
    m = re.match(
        r'^(\w+)\s+(IN\s+OUT|INOUT|IN|OUT)?\s*([\w\(\), ]+?)(?:\s+DEFAULT\s+(.+))?\s*$',
        p, re.IGNORECASE
    )
    if m:
        raw_mode = (m.group(2) or 'IN').strip().upper().replace(' ', '_')
        mode = 'INOUT' if raw_mode in ('IN_OUT', 'INOUT') else raw_mode
        return {
            'name': m.group(1),
            'type_str': m.group(3).strip(),
            'mode': mode,
            'default': (m.group(4) or "").strip() or None,
        }

    # Fallback: first token = name, rest = type
    tokens = p.split(None, 1)
    if len(tokens) == 2:
        return {
            'name': tokens[0].lstrip('@'),
            'type_str': tokens[1].strip(),
            'mode': 'IN',
            'default': None,
        }

    return None


def extract_all_params(sql: str, keyword: str = "PROCEDURE") -> List[Dict[str, Any]]:
    """
    Extract all parameters from CREATE PROCEDURE/FUNCTION.
    Returns list of param dicts: {name, type_str, mode, default}.
    """
    params_str = extract_params_str(sql, keyword)
    if not params_str:
        return []
    parts = split_params(params_str)
    result = []
    for part in parts:
        p = parse_single_param(part)
        if p:
            result.append(p)
    return result


# ---------------------------------------------------------------------------
# IR conversion
# ---------------------------------------------------------------------------

def params_to_ir(
    raw_params: List[Dict[str, Any]],
    source_dialect: Dialect,
    mapper,
) -> Tuple[List[IRParameter], List[IRWarning], List[IRDocReference]]:
    """
    Convert raw param dicts to IRParameter list, translating types via TypeMapper.
    """
    ir_params: List[IRParameter] = []
    warnings: List[IRWarning] = []
    doc_refs: List[IRDocReference] = []

    for p in raw_params:
        generic, prec, scale, length = mapper.source_type_to_generic(source_dialect, p['type_str'])
        if generic == GenericType.UNKNOWN:
            warnings.append(IRWarning(
                feature=f"UNKNOWN_PARAM_TYPE_{p['name'].upper()}",
                message=f"Parameter '{p['name']}' has unknown type '{p['type_str']}' in {source_dialect.value}. "
                        f"Type preserved as-is; manual review required.",
                severity=Warningseverity.WARNING,
            ))
        ir_dt = IRDataType(
            generic_type=generic,
            precision=prec,
            scale=scale,
            length=length,
            original_type_string=p['type_str'],
        )
        ir_params.append(IRParameter(
            name=p['name'],
            data_type=ir_dt,
            mode=p.get('mode', 'IN'),
            default_value=p.get('default'),
        ))

    return ir_params, warnings, doc_refs


# ---------------------------------------------------------------------------
# Generation helpers
# ---------------------------------------------------------------------------

MANUAL_REVIEW_COMMENT = """\
-- ============================================================
-- MANUAL REVIEW REQUIRED
-- The procedural body has been preserved from the source dialect.
-- Review and adapt the following before deploying:
--   1. Variable declaration syntax
--   2. Exception/error handling
--   3. Cursor syntax
--   4. Transaction control
--   5. Dialect-specific built-in functions
-- ============================================================"""


def format_body_comment(source_dialect: str, target_dialect: str, source_lang: Optional[str]) -> str:
    lang_note = f" (source language: {source_lang})" if source_lang else ""
    return (
        f"-- Translated from {source_dialect}{lang_note} → {target_dialect}\n"
        f"{MANUAL_REVIEW_COMMENT}"
    )


def format_param_tsql(p: IRParameter, mapper, target_dialect: Dialect) -> str:
    """Format a single parameter as T-SQL: @name TYPE [= default] [OUTPUT]"""
    type_str, _, _ = mapper.generic_to_target(p.data_type.generic_type, target_dialect, p.data_type.precision, p.data_type.scale, p.data_type.length)
    out = "OUTPUT" if p.mode == 'OUT' else ""
    default = f" = {p.default_value}" if p.default_value else ""
    parts = [f"@{p.name}", type_str]
    if default:
        parts.append(default.strip())
    if out:
        parts.append(out)
    return " ".join(parts)


def format_param_plpgsql(p: IRParameter, mapper, target_dialect: Dialect) -> str:
    """Format a single parameter as PL/pgSQL: [IN|OUT|INOUT] name TYPE [DEFAULT default]"""
    type_str, _, _ = mapper.generic_to_target(p.data_type.generic_type, target_dialect, p.data_type.precision, p.data_type.scale, p.data_type.length)
    mode = p.mode if p.mode in ('IN', 'OUT', 'INOUT') else 'IN'
    default = f" DEFAULT {p.default_value}" if p.default_value else ""
    return f"{mode} {p.name} {type_str}{default}"


def format_param_oracle(p: IRParameter, mapper, target_dialect: Dialect) -> str:
    """Format a single parameter as Oracle PL/SQL: name [IN|OUT|IN OUT] TYPE [DEFAULT default]"""
    type_str, _, _ = mapper.generic_to_target(p.data_type.generic_type, target_dialect, p.data_type.precision, p.data_type.scale, p.data_type.length)
    mode = p.mode if p.mode in ('IN', 'OUT') else 'IN OUT' if p.mode == 'INOUT' else 'IN'
    default = f" DEFAULT {p.default_value}" if p.default_value else ""
    return f"{p.name} {mode} {type_str}{default}"


def format_param_snowflake(p: IRParameter, mapper, target_dialect: Dialect) -> str:
    """Format a single parameter as Snowflake: name TYPE"""
    type_str, _, _ = mapper.generic_to_target(p.data_type.generic_type, target_dialect, p.data_type.precision, p.data_type.scale, p.data_type.length)
    return f"{p.name} {type_str}"


def format_param_bigquery(p: IRParameter, mapper, target_dialect: Dialect) -> str:
    """Format as BigQuery: [IN|OUT|INOUT] name TYPE"""
    type_str, _, _ = mapper.generic_to_target(p.data_type.generic_type, target_dialect, p.data_type.precision, p.data_type.scale, p.data_type.length)
    mode = p.mode if p.mode in ('IN', 'OUT', 'INOUT') else 'IN'
    return f"{mode} {p.name} {type_str}"


def format_param_databricks(p: IRParameter, mapper, target_dialect: Dialect) -> str:
    """Format as Databricks Python UDF: name TYPE"""
    type_str, _, _ = mapper.generic_to_target(p.data_type.generic_type, target_dialect, p.data_type.precision, p.data_type.scale, p.data_type.length)
    return f"{p.name} {type_str}"
