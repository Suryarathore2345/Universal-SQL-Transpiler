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


_GO_BATCH_SEPARATOR = re.compile(r'^GO\s*(\d+)?$', re.IGNORECASE)
# SQL*Plus/SQLcl PL/SQL block terminator — a bare `/` on its own line ends a
# CREATE PROCEDURE/FUNCTION/TRIGGER/PACKAGE body (docs: SQL*Plus User's Guide,
# "Executing a PL/SQL Block"). Extremely common in exported Oracle DDL (e.g.
# oracle-samples/db-sample-schemas), and the same class of bug as GO: left
# unhandled, the bare "/" glues onto the front of the next statement.
_SLASH_BATCH_SEPARATOR = re.compile(r'^/$')

_WORD_CHAR = re.compile(r'[A-Za-z0-9_]')
_BLOCK_OPENERS = {"BEGIN", "CASE"}
_END_NOOP_SUFFIXES = {"IF", "LOOP", "WHILE"}  # "END IF"/"END LOOP"/"END WHILE" close an untracked opener


def split_statements(sql: str) -> List[str]:
    """
    Split a SQL script on `;` boundaries, aware of:
      - Single-quoted strings ('...')
      - Double-quoted identifiers ("...")
      - Line comments (--)
      - Block comments (/* ... */)
      - Dollar-quoted bodies ($$...$$, $tag$...$tag$)
      - BEGIN...END procedural block nesting (see below)

    Also splits on a bare `GO` batch separator on its own line — the
    SQL Server client-tool (SSMS/sqlcmd/SSDT) convention documented at
    https://learn.microsoft.com/en-us/sql/t-sql/language-elements/sql-server-utilities-statements-go
    GO is not part of the T-SQL language itself and is never valid inside
    a statement, so a script batch-separated by GO instead of/in addition
    to `;` (the overwhelmingly common form for any DDL exported from SSMS,
    sqlcmd, or an SSDT project — e.g. AdventureWorks, WideWorldImporters)
    previously left the literal text "GO\\n" glued onto the front of the
    next statement, which no dialect's grammar recognizes, silently
    dropping every statement after the first GO in the script.

    Also splits on a bare `/` on its own line — the SQL*Plus/SQLcl PL/SQL
    block terminator used throughout Oracle DDL exports (same failure mode
    as GO if left unhandled).

    Dollar-quoting is used by Redshift, Snowflake, PostgreSQL, and Databricks
    to embed procedural bodies; any ; or GO/`/`-line inside such a block
    must not split.

    BEGIN...END nesting: Oracle PL/SQL and T-SQL procedure/function/trigger
    bodies are NOT dollar-quoted — they use `CREATE PROCEDURE ... AS/IS
    BEGIN ... END;` with ordinary `;`-terminated statements INSIDE the body
    (e.g. `RAISE_APPLICATION_ERROR(...); END IF; END proc_name;`). Without
    depth tracking, the first internal `;` was treated as the end of the
    whole CREATE PROCEDURE statement, silently truncating the body at that
    point — everything after it (often including the real closing END)
    became orphaned fragments that failed to parse as anything meaningful.
    `BEGIN` and `CASE` each push a depth level; a bare `END` (or `END CASE`)
    pops one; `END IF`/`END LOOP`/`END WHILE` are no-ops (IF/LOOP/WHILE are
    intentionally not tracked as openers, since T-SQL's single-line
    `IF x BEGIN ... END` already pairs via BEGIN, and an expression-form
    `CASE WHEN x THEN y END` inside an ordinary SELECT/VIEW body pushes and
    pops symmetrically, so plain non-procedural statements are unaffected).
    A `;` only splits when depth is 0, so a `;` inside an open block is kept
    as part of the statement instead of prematurely ending it.
    """
    # Strip UTF-8 BOM (U+FEFF) characters. Windows tools (Visual Studio,
    # SSDT, Notepad) commonly save each .sql file WITH a leading BOM; when
    # several such files are concatenated into one script (e.g. exporting
    # a whole WideWorldImporters/AdventureWorks project), a BOM ends up
    # embedded mid-document, immediately before a later CREATE statement's
    # first keyword. sqlglot's tokenizer cannot recognize "﻿CREATE" as
    # the CREATE keyword and misparses the entire statement as a generic
    # Alias/Column expression — not a parse ERROR (so no warning is raised),
    # just silently wrong, producing empty output for an otherwise perfectly
    # valid CREATE TABLE/VIEW/PROCEDURE. Stripped everywhere, not just at
    # the start, since concatenated scripts carry one BOM per source file.
    sql = sql.replace('﻿', '')

    parts: List[str] = []
    current: List[str] = []
    line_buf: List[str] = []   # plain (non-quoted/non-comment) text since the last newline
    word_buf: List[str] = []   # plain word characters since the last non-word boundary
    block_stack: List[str] = []  # BEGIN/CASE nesting — depth = len(block_stack)
    pending_end = [False]      # True right after a completed "END" word, awaiting its suffix
    in_single = False
    in_double = False
    in_line_comment = False
    in_block_comment = False
    dollar_tag: Optional[str] = None  # non-None while inside $tag$...$tag$
    i = 0

    def resolve_word(word: str) -> None:
        """Update block_stack/pending_end for one completed plain-text word."""
        if not word:
            return
        upper = word.upper()
        if pending_end[0]:
            pending_end[0] = False
            if upper in _END_NOOP_SUFFIXES:
                return  # "END IF" / "END LOOP" / "END WHILE" — untracked opener, no-op
            if upper == "CASE":
                if block_stack:
                    block_stack.pop()
                return  # "END CASE" closes the CASE just popped
            # Any other word means the preceding "END" was bare (e.g.
            # "END proc_name" or "END" immediately before non-word text) —
            # it closes whatever block is currently open.
            if block_stack:
                block_stack.pop()
            # Fall through: `word` itself may also be a fresh keyword.
        if upper == "END":
            pending_end[0] = True
            return
        if upper in _BLOCK_OPENERS:
            block_stack.append(upper)

    def flush_pending_end() -> None:
        """Resolve a still-pending bare END (e.g. "END;" with no suffix word)."""
        if pending_end[0]:
            pending_end[0] = False
            if block_stack:
                block_stack.pop()

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

        is_plain = (not in_single and not in_double and not in_line_comment
                    and not in_block_comment)

        # Generic word-boundary detection — runs for every plain character
        # BEFORE the specific-purpose branches below, so BEGIN/CASE/END
        # tracking is correct no matter which character ends the word
        # (space, punctuation, newline, quote-start, comment-start, ...).
        if is_plain:
            if _WORD_CHAR.match(ch):
                word_buf.append(ch)
            elif word_buf:
                resolve_word("".join(word_buf))
                word_buf = []

        if ch == "\n" and is_plain:
            line_text = "".join(line_buf).strip()
            if _GO_BATCH_SEPARATOR.match(line_text) or _SLASH_BATCH_SEPARATOR.match(line_text):
                # Pop the batch-separator line's already-appended chars off
                # `current` (written there by the plain-text branch below)
                # and flush everything before it as a completed statement.
                if line_buf:
                    current = current[:-len(line_buf)]
                stmt = "".join(current).strip()
                if stmt:
                    parts.append(stmt)
                current = []
            else:
                current.append(ch)
            line_buf = []
            i += 1
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
            flush_pending_end()
            if block_stack:
                # Inside an open BEGIN/CASE block — this `;` terminates an
                # internal statement, not the whole CREATE PROCEDURE/
                # FUNCTION/TRIGGER statement. Keep it as body text.
                current.append(ch)
            else:
                parts.append("".join(current).strip())
                current = []
                line_buf = []
        else:
            current.append(ch)
            if is_plain:
                line_buf.append(ch)
        i += 1

    # Resolve any trailing word/pending-END state at end of input.
    if word_buf:
        resolve_word("".join(word_buf))
    flush_pending_end()

    # Trailing GO/`/` batch separator on the last line with no closing newline
    trailing_line = "".join(line_buf).strip()
    if line_buf and (_GO_BATCH_SEPARATOR.match(trailing_line) or _SLASH_BATCH_SEPARATOR.match(trailing_line)):
        current = current[:-len(line_buf)]

    if "".join(current).strip():
        parts.append("".join(current).strip())
    return [p for p in parts if p]
