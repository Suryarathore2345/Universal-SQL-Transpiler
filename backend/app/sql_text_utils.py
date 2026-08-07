"""
Shared, dialect-agnostic SQL text utilities.

This module exists to give the statement splitter a single home. Before
this, `dialects/base.py` and `query_transpiler.py` each maintained their
own independent copy — the DDL-path copy (here) was comment- and
dollar-quote-aware, but the query-path copy in `query_transpiler.py` only
tracked quotes. A semicolon inside a `--` line comment or `/* */` block
comment in a SELECT/DML script would be treated as a real statement
terminator by the weaker copy, silently splitting one statement into two
corrupted fragments (each then independently fed to sqlglot). Both call
sites now share this one implementation.
"""
from __future__ import annotations

import re
from typing import List, Optional


def split_statements(sql: str) -> List[str]:
    """
    Split a SQL script on `;` boundaries, aware of:
      - Single-quoted strings ('...')
      - Double-quoted identifiers ("...")
      - Line comments (--)
      - Block comments (/* ... */)
      - Dollar-quoted bodies ($$...$$, $tag$...$tag$)

    Dollar-quoting is used by Redshift, Snowflake, PostgreSQL, and Databricks
    to embed procedural bodies; any ; inside such a block must not split.
    """
    parts: List[str] = []
    current: List[str] = []
    in_single = False
    in_double = False
    in_line_comment = False
    in_block_comment = False
    dollar_tag: Optional[str] = None  # non-None while inside $tag$...$tag$
    i = 0
    while i < len(sql):
        ch = sql[i]
        nch = sql[i + 1] if i + 1 < len(sql) else ""

        # Inside a dollar-quoted block: scan for closing tag
        if dollar_tag is not None:
            closing = f"${dollar_tag}$"
            if sql[i:i + len(closing)] == closing:
                current.append(closing)
                i += len(closing)
                dollar_tag = None
                continue
            current.append(ch)
            i += 1
            continue

        # Detect start of dollar-quoting: $tag$ or $$ (tag may be empty)
        if (not in_single and not in_double and not in_line_comment
                and not in_block_comment and ch == "$"):
            m = re.match(r'\$(\w*)\$', sql[i:])
            if m:
                tag = m.group(1)
                current.append(m.group(0))
                i += len(m.group(0))
                dollar_tag = tag
                continue

        if in_line_comment:
            if ch == "\n":
                in_line_comment = False
            current.append(ch)
        elif in_block_comment:
            if ch == "*" and nch == "/":
                current.append("*/")
                i += 2
                in_block_comment = False
                continue
            current.append(ch)
        elif not in_single and not in_double and ch == "-" and nch == "-":
            in_line_comment = True
            current.append(ch)
        elif not in_single and not in_double and ch == "/" and nch == "*":
            in_block_comment = True
            current.append(ch)
        elif ch == "'" and not in_double:
            in_single = not in_single
            current.append(ch)
        elif ch == '"' and not in_single:
            in_double = not in_double
            current.append(ch)
        elif ch == ";" and not in_single and not in_double:
            parts.append("".join(current).strip())
            current = []
        else:
            current.append(ch)
        i += 1

    if "".join(current).strip():
        parts.append("".join(current).strip())
    return [p for p in parts if p]
