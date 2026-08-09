"""
Extract SQL statements from SQLGlot Python test fixture files.

Parses validate_identity(), validate_all(), transpile(), and other test method
calls to extract SQL strings. Classifies them as DDL or DML and writes to
separate files per dialect.
"""

import re
import os
import ast
from pathlib import Path

FIXTURES_DIR = Path(__file__).parent
OUTPUT_DIR = FIXTURES_DIR / "extracted"

# Map filenames to dialect labels
DIALECT_MAP = {
    "bigquery.py": "bigquery",
    "snowflake.py": "snowflake",
    "tsql.py": "tsql",
    "oracle.py": "oracle",
    "redshift.py": "redshift",
    "databricks.py": "databricks",
    "spark.py": "spark",
}

# Patterns that indicate DDL
DDL_PREFIXES = [
    "CREATE ", "ALTER ", "DROP ", "TRUNCATE ",
    "CREATE OR REPLACE ",
    "DECLARE ",
]

# Patterns that indicate DML
DML_PREFIXES = [
    "SELECT ", "INSERT ", "UPDATE ", "DELETE ", "MERGE ",
    "WITH ",  # CTEs are typically DML
    "COPY ",
    "EXPLAIN ",
]


def extract_python_strings(source: str) -> list[str]:
    """
    Extract all string literals from Python source code using regex.
    Handles both single-quoted, double-quoted, and triple-quoted strings.
    Returns strings that look like SQL statements.
    """
    strings = []

    # We'll use a state-machine approach to extract strings from the source.
    # This handles triple-quoted and single-quoted strings properly.
    i = 0
    n = len(source)

    while i < n:
        # Skip comments
        if source[i] == '#':
            # Find end of line
            end = source.find('\n', i)
            if end == -1:
                break
            i = end + 1
            continue

        # Check for triple-quoted strings first
        if source[i:i+3] in ('"""', "'''"):
            quote = source[i:i+3]
            start = i + 3
            end = source.find(quote, start)
            if end == -1:
                break
            s = source[start:end]
            strings.append(s)
            i = end + 3
            continue

        # Check for single/double quoted strings
        if source[i] in ('"', "'"):
            quote = source[i]
            start = i + 1
            j = start
            while j < n:
                if source[j] == '\\':
                    j += 2
                    continue
                if source[j] == quote:
                    break
                if source[j] == '\n':
                    # Unmatched quote at end of line - not a valid string
                    break
                j += 1
            if j < n and source[j] == quote:
                s = source[start:j]
                strings.append(s)
                i = j + 1
            else:
                i += 1
            continue

        i += 1

    return strings


def classify_sql(sql: str) -> str | None:
    """Classify a SQL string as 'ddl', 'dml', or None (skip)."""
    upper = sql.strip().upper()

    # Skip empty or very short strings
    if len(sql.strip()) < 5:
        return None

    # Skip strings that don't look like SQL
    # (e.g., error messages, format strings, file paths)
    if not any(upper.startswith(p) for p in DDL_PREFIXES + DML_PREFIXES):
        # Also check for some common SQL patterns that don't start with keywords
        # like function calls, expressions used in validate_all
        return None

    for p in DDL_PREFIXES:
        if upper.startswith(p):
            return "ddl"

    for p in DML_PREFIXES:
        if upper.startswith(p):
            return "dml"

    return None


def clean_sql(sql: str) -> str:
    """Clean up extracted SQL string."""
    # Remove leading/trailing whitespace
    sql = sql.strip()

    # Normalize line endings
    sql = sql.replace('\r\n', '\n')

    # Remove excessive indentation (common in triple-quoted strings)
    lines = sql.split('\n')
    if len(lines) > 1:
        # Find minimum indentation (ignoring empty lines)
        min_indent = float('inf')
        for line in lines[1:]:  # skip first line
            stripped = line.lstrip()
            if stripped:
                indent = len(line) - len(stripped)
                min_indent = min(min_indent, indent)

        if min_indent < float('inf') and min_indent > 0:
            cleaned_lines = [lines[0]]
            for line in lines[1:]:
                if line.strip():
                    cleaned_lines.append(line[min_indent:])
                else:
                    cleaned_lines.append('')
            sql = '\n'.join(cleaned_lines)

    return sql


def extract_from_file(filepath: Path) -> tuple[list[str], list[str]]:
    """
    Extract DDL and DML statements from a Python fixture file.
    Returns (ddl_list, dml_list).
    """
    source = filepath.read_text(encoding='utf-8')
    raw_strings = extract_python_strings(source)

    ddl_statements = []
    dml_statements = []
    seen = set()  # Deduplicate

    for s in raw_strings:
        cleaned = clean_sql(s)
        if not cleaned:
            continue

        # Deduplicate
        key = cleaned.upper().strip()
        if key in seen:
            continue

        category = classify_sql(cleaned)
        if category == "ddl":
            seen.add(key)
            ddl_statements.append(cleaned)
        elif category == "dml":
            seen.add(key)
            dml_statements.append(cleaned)

    return ddl_statements, dml_statements


def write_sql_file(filepath: Path, statements: list[str], dialect: str, category: str):
    """Write SQL statements to a file."""
    filepath.parent.mkdir(parents=True, exist_ok=True)

    header = f"-- SQLGlot {dialect} {category.upper()} statements\n"
    header += f"-- Extracted from {dialect}.py test fixtures\n"
    header += f"-- Total statements: {len(statements)}\n"
    header += f"-- {'=' * 60}\n\n"

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(header)
        for i, stmt in enumerate(statements, 1):
            f.write(f"-- Statement {i}\n")
            if not stmt.rstrip().endswith(';'):
                f.write(f"{stmt};\n\n")
            else:
                f.write(f"{stmt}\n\n")


def main():
    print("=" * 60)
    print("SQLGlot Fixture SQL Extractor")
    print("=" * 60)

    summary = []

    for filename, dialect in DIALECT_MAP.items():
        filepath = FIXTURES_DIR / filename
        if not filepath.exists():
            print(f"\nSkipping {filename} (not found)")
            continue

        print(f"\nProcessing {filename}...")
        ddl_stmts, dml_stmts = extract_from_file(filepath)

        # Write DDL file
        if ddl_stmts:
            ddl_path = OUTPUT_DIR / f"{dialect}_ddl.sql"
            write_sql_file(ddl_path, ddl_stmts, dialect, "ddl")
            print(f"  DDL: {len(ddl_stmts)} statements -> {ddl_path.name}")

        # Write DML file
        if dml_stmts:
            dml_path = OUTPUT_DIR / f"{dialect}_dml.sql"
            write_sql_file(dml_path, dml_stmts, dialect, "dml")
            print(f"  DML: {len(dml_stmts)} statements -> {dml_path.name}")

        summary.append((dialect, len(ddl_stmts), len(dml_stmts)))

    # Print summary
    print("\n" + "=" * 60)
    print(f"{'Dialect':<15} {'DDL':>6} {'DML':>6} {'Total':>7}")
    print("-" * 40)
    total_ddl = 0
    total_dml = 0
    for dialect, ddl_count, dml_count in summary:
        print(f"{dialect:<15} {ddl_count:>6} {dml_count:>6} {ddl_count + dml_count:>7}")
        total_ddl += ddl_count
        total_dml += dml_count
    print("-" * 40)
    print(f"{'TOTAL':<15} {total_ddl:>6} {total_dml:>6} {total_ddl + total_dml:>7}")
    print("=" * 60)
    print(f"\nOutput directory: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
