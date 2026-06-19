"""
Dynamic schema inference: detect column types from CSV or JSON data and
produce a CREATE TABLE DDL via the transpiler's generator pipeline.

Supported input formats:
  CSV  — first row = headers, subsequent rows = sample data
  JSON — array of objects; keys become column names
"""
from __future__ import annotations

import csv
import io
import json
import re
from datetime import datetime
from typing import Dict, List, Optional, Tuple

from app.dialects.base import DialectGenerator
from app.ir.models import (
    Dialect, GenericType, IRColumn, IRDataType, IRTable,
)


# ---------------------------------------------------------------------------
# Type-detection helpers
# ---------------------------------------------------------------------------

_DATE_PATTERNS = [
    re.compile(r'^\d{4}-\d{2}-\d{2}$'),                     # YYYY-MM-DD
    re.compile(r'^\d{2}/\d{2}/\d{4}$'),                     # MM/DD/YYYY
    re.compile(r'^\d{2}-\d{2}-\d{4}$'),                     # DD-MM-YYYY
]
_TS_PATTERNS = [
    re.compile(r'^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}'), # YYYY-MM-DD HH:MM:SS
]
# Word-only booleans (not numeric) — prevents 0/1 columns from matching before int check
_BOOL_WORDS = {'true', 'false', 'yes', 'no', 't', 'f', 'y', 'n'}
# Numeric-compatible booleans (only if ALL values are strictly 0 or 1)
_BOOL_NUMERIC = {'0', '1'}


def _infer_type(values: List[str]) -> IRDataType:
    """
    Infer a GenericType from a list of string values (already stripped of blanks).
    Precision cascade: BOOLEAN > INT64 > FLOAT64 > DATE > TIMESTAMP > VARCHAR.
    """
    non_null = [v.strip() for v in values if v.strip()]
    if not non_null:
        return IRDataType(generic_type=GenericType.TEXT)

    lower = [v.lower() for v in non_null]

    # BOOLEAN (word form: true/false/yes/no — must not be purely numeric)
    if all(v in _BOOL_WORDS for v in lower):
        return IRDataType(generic_type=GenericType.BOOLEAN)
    # BOOLEAN (strict 0/1 only — only when column has a mix of 0 and 1 and nothing else)
    if all(v in _BOOL_NUMERIC for v in lower) and {'0', '1'}.issubset(set(lower)):
        return IRDataType(generic_type=GenericType.BOOLEAN)

    # INTEGER
    try:
        for v in non_null:
            int(v.replace(',', ''))
        return IRDataType(generic_type=GenericType.INT64)
    except ValueError:
        pass

    # FLOAT
    try:
        for v in non_null:
            float(v.replace(',', ''))
        return IRDataType(generic_type=GenericType.FLOAT64)
    except ValueError:
        pass

    # DATE
    if all(any(p.match(v) for p in _DATE_PATTERNS) for v in non_null[:50]):
        return IRDataType(generic_type=GenericType.DATE)

    # TIMESTAMP
    if all(any(p.match(v) for p in _TS_PATTERNS) for v in non_null[:50]):
        return IRDataType(generic_type=GenericType.TIMESTAMP)

    # VARCHAR — size = next power of 2 above max observed length, capped at 4000
    max_len = max(len(v) for v in non_null)
    varchar_len = min(max(max_len * 2, 64), 4000)
    return IRDataType(generic_type=GenericType.VARCHAR, length=varchar_len)


def _sanitize_column_name(name: str) -> str:
    """Strip/replace characters that are illegal in column names across all dialects."""
    name = name.strip()
    name = re.sub(r'[^A-Za-z0-9_]', '_', name)
    if name and name[0].isdigit():
        name = f'col_{name}'
    return name or 'col_unknown'


# ---------------------------------------------------------------------------
# Parse CSV
# ---------------------------------------------------------------------------

def parse_csv(text: str) -> Tuple[List[str], List[List[str]]]:
    """Return (headers, data_rows) from a CSV string."""
    reader = csv.reader(io.StringIO(text.strip()))
    rows = list(reader)
    if not rows:
        raise ValueError("CSV input is empty")
    headers = [_sanitize_column_name(h) for h in rows[0]]
    data = rows[1:]
    return headers, data


# ---------------------------------------------------------------------------
# Parse JSON array
# ---------------------------------------------------------------------------

def parse_json(text: str) -> Tuple[List[str], List[List[str]]]:
    """Return (headers, data_rows) from a JSON array-of-objects string."""
    try:
        data = json.loads(text.strip())
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid JSON: {e}")
    if not isinstance(data, list):
        raise ValueError("JSON input must be an array of objects")
    if not data:
        raise ValueError("JSON array is empty")
    # Collect all keys in order of first appearance
    seen: Dict[str, int] = {}
    for row in data:
        if not isinstance(row, dict):
            raise ValueError("Each JSON element must be an object")
        for k in row:
            if k not in seen:
                seen[k] = len(seen)
    headers = [_sanitize_column_name(k) for k in seen]
    original_keys = list(seen.keys())
    data_rows = [[str(row.get(k, '')) for k in original_keys] for row in data]
    return headers, data_rows


# ---------------------------------------------------------------------------
# Public API: infer schema and generate DDL
# ---------------------------------------------------------------------------

def infer_and_generate(
    raw_input: str,
    fmt: str,
    table_name: str,
    schema_name: Optional[str],
    target_dialect: str,
    generator: DialectGenerator,
    sample_rows: int = 200,
) -> str:
    """
    Parse `raw_input` (CSV or JSON), infer column types, build an IRTable,
    then emit CREATE TABLE DDL via `generator`.

    Args:
        raw_input:      Raw CSV or JSON text
        fmt:            "csv" or "json"
        table_name:     Target table name (user-supplied)
        schema_name:    Optional schema/dataset prefix
        target_dialect: Dialect key string (for IRTable.dialect)
        generator:      The DialectGenerator for the target dialect
        sample_rows:    How many data rows to sample for type inference

    Returns:
        CREATE TABLE SQL string
    """
    fmt = fmt.lower()
    if fmt == "csv":
        headers, data_rows = parse_csv(raw_input)
    elif fmt == "json":
        headers, data_rows = parse_json(raw_input)
    else:
        raise ValueError(f"Unsupported format: {fmt!r}. Use 'csv' or 'json'.")

    if not headers:
        raise ValueError("No column headers found in input")

    # Transpose: columns[i] = list of string values for header i
    n_cols = len(headers)
    sample = data_rows[:sample_rows]
    columns_data: List[List[str]] = [[] for _ in range(n_cols)]
    for row in sample:
        for i in range(n_cols):
            columns_data[i].append(row[i] if i < len(row) else '')

    # Build IRColumn list
    ir_columns = [
        IRColumn(
            name=headers[i],
            data_type=_infer_type(columns_data[i]),
            is_nullable=True,
        )
        for i in range(n_cols)
    ]

    # Sanitize table/schema name
    table_name = _sanitize_column_name(table_name) if table_name.strip() else 'inferred_table'
    schema_name = _sanitize_column_name(schema_name) if schema_name and schema_name.strip() else None

    ir_table = IRTable(
        name=table_name,
        schema=schema_name,
        columns=ir_columns,
        dialect=Dialect(target_dialect),
    )

    ddl, _warnings, _refs = generator.generate_table(ir_table)
    return ddl
