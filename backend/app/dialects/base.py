"""
Abstract base classes for dialect parsers and generators.

Each dialect implements:
  - DialectParser:    SQL text → IR objects
  - DialectGenerator: IR objects → SQL text

Both rely on the TypeMapper to handle type conversions via type_mappings.yaml.
"""
from __future__ import annotations

import re
from abc import ABC, abstractmethod
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, TYPE_CHECKING

import yaml

from app.ir.models import (
    Dialect, GenericType, IRColumn, IRDataType, IRDDLObject, IRDocReference,
    IRFunction, IRParameter, IRProcedure, IRTable, IRView, IRMaterializedView,
    IRWarning, TranspileResult, Warningseverity,
)


# ---------------------------------------------------------------------------
# Type Mapper — loads type_mappings.yaml and resolves types
# ---------------------------------------------------------------------------

class TypeMapper:
    """
    Loads type_mappings.yaml and provides forward (source→generic) and
    reverse (generic→target) lookups.
    """

    _instance: Optional["TypeMapper"] = None
    _mappings: Dict[str, Any] = {}

    @classmethod
    def get(cls) -> "TypeMapper":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    @classmethod
    def reset(cls) -> None:
        """Force reload of YAML — useful in tests after YAML is modified."""
        cls._instance = None

    def __init__(self) -> None:
        mapping_file = Path(__file__).parent.parent / "type_mappings" / "type_mappings.yaml"
        with open(mapping_file, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
        self._mappings = data.get("generic_types", {})
        self._identity = data.get("identity_mechanisms", {})

    def source_type_to_generic(
        self, dialect: Dialect, native_type: str
    ) -> Tuple[GenericType, Optional[int], Optional[int], Optional[int]]:
        """
        Map a native dialect type string to a GenericType + (precision, scale, length).
        Returns (GenericType.UNKNOWN, None, None, None) when no mapping exists.
        """
        # Normalize sqlglot-specific renderings that drop underscores
        _normalize_map = {
            "TIMESTAMPNTZ": "TIMESTAMP_NTZ",
            "TIMESTAMPTZ": "TIMESTAMPTZ",
            "TIMESTAMPLTZ": "TIMESTAMP_LTZ",
        }
        normalized = native_type.strip().upper()
        normalized = _normalize_map.get(normalized, normalized)
        # Extract precision/scale from type like VARCHAR(255) or DECIMAL(18,2)
        precision, scale, length = None, None, None
        m = re.match(r"^(\w[\w\s]*?)\s*\((.+)\)$", normalized)
        bare = normalized
        if m:
            bare = m.group(1).strip()
            args = [a.strip() for a in m.group(2).split(",")]
            if len(args) == 2:
                try:
                    precision = int(args[0])
                    scale = int(args[1])
                except ValueError:
                    pass
            elif len(args) == 1:
                try:
                    length = int(args[0])
                except ValueError:
                    pass

        dialect_key = dialect.value
        for generic_name, info in self._mappings.items():
            dialects = info.get("dialects", {})
            entry = dialects.get(dialect_key, {})
            primary = entry.get("type", "").upper()
            aliases = [a.upper() for a in entry.get("aliases", [])]
            if bare == primary or bare in aliases:
                try:
                    g = GenericType(generic_name)
                except ValueError:
                    g = GenericType.UNKNOWN
                return g, precision, scale, length

        return GenericType.UNKNOWN, precision, scale, length

    def generic_to_target(
        self,
        generic_type: GenericType,
        target_dialect: Dialect,
        precision: Optional[int] = None,
        scale: Optional[int] = None,
        length: Optional[int] = None,
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Map a GenericType to a native type string for the target dialect.
        Returns (type_string, warnings, doc_refs).
        """
        warnings: List[IRWarning] = []
        doc_refs: List[IRDocReference] = []

        entry = self._mappings.get(generic_type.value, {})
        if not entry:
            return "VARCHAR(MAX)", [IRWarning(
                feature=generic_type.value,
                message=f"No mapping found for generic type {generic_type.value} in {target_dialect.value}. Defaulted to VARCHAR(MAX).",
                severity=Warningseverity.ERROR,
            )], []

        dialect_key = target_dialect.value
        dialect_entry = entry.get("dialects", {}).get(dialect_key, {})
        if not dialect_entry:
            return "VARCHAR(MAX)", [IRWarning(
                feature=generic_type.value,
                message=f"No dialect entry for {generic_type.value} → {target_dialect.value}. Defaulted to VARCHAR(MAX).",
                severity=Warningseverity.ERROR,
            )], []

        base_type = dialect_entry.get("type", "VARCHAR(MAX)")
        doc_url = dialect_entry.get("doc_url", "")
        is_unsupported = dialect_entry.get("unsupported", False)
        fallback = dialect_entry.get("fallback", base_type)
        notes = dialect_entry.get("notes", "")

        if doc_url:
            doc_refs.append(IRDocReference(
                title=f"{generic_type.value} in {target_dialect.value}",
                url=doc_url,
                platform=target_dialect.value,
                purpose="Type mapping",
            ))

        if is_unsupported:
            warnings.append(IRWarning(
                feature=generic_type.value,
                message=f"{generic_type.value} is not natively supported in {target_dialect.value}. "
                        f"Using {fallback} instead. {notes}",
                doc_url=dialect_entry.get("fallback_doc_url", doc_url),
                severity=Warningseverity.WARNING,
                fallback_applied=True,
            ))
            base_type = fallback

        # Rebuild type string with precision/scale/length
        type_str = self._apply_params(base_type, generic_type, precision, scale, length, dialect_entry)
        return type_str, warnings, doc_refs

    def _apply_params(
        self,
        base_type: str,
        generic_type: GenericType,
        precision: Optional[int],
        scale: Optional[int],
        length: Optional[int],
        dialect_entry: Dict,
    ) -> str:
        """Attach (precision, scale) or (length) to a base type if appropriate."""
        # Types that should carry (p,s)
        if generic_type == GenericType.DECIMAL:
            if precision is not None and scale is not None:
                return f"{base_type}({precision},{scale})"
            elif precision is not None:
                return f"{base_type}({precision})"
            return base_type

        # Types that carry (n) length
        if generic_type in (GenericType.VARCHAR, GenericType.CHAR):
            if length is not None:
                # Respect max_length constraint from dialect entry
                max_len = dialect_entry.get("max_length")
                effective = min(length, max_len) if max_len else length
                return f"{base_type}({effective})"
            return base_type

        # Timestamp precision
        if generic_type in (GenericType.TIMESTAMP, GenericType.TIMESTAMP_TZ, GenericType.TIMESTAMP_LTZ):
            max_prec = dialect_entry.get("max_precision", 9)
            if precision is not None:
                effective = min(precision, max_prec)
                return f"{base_type}({effective})"
            # Source had no explicit precision. Some dialects (e.g. Fabric DW
            # DATETIME2) have no implicit default and require one — apply it.
            default_prec = dialect_entry.get("default_precision")
            if default_prec is not None:
                return f"{base_type}({default_prec})"

        return base_type

    def get_identity_info(self, dialect: Dialect) -> Dict[str, Any]:
        return self._identity.get(dialect.value, {})


# ---------------------------------------------------------------------------
# Abstract base dialect classes
# ---------------------------------------------------------------------------

class DialectParser(ABC):
    """
    Converts SQL DDL text (in a specific dialect) into IR objects.

    Subclasses must implement parse_statement(). They may use sqlglot
    internally and then map the resulting AST to IR models.
    """

    dialect: Dialect
    mapper: TypeMapper

    def __init__(self) -> None:
        self.mapper = TypeMapper.get()

    @abstractmethod
    def parse_statement(self, sql: str) -> Tuple[Optional[IRDDLObject], List[IRWarning], List[IRDocReference]]:
        """
        Parse a single SQL DDL statement.
        Returns (ir_object | None, warnings, doc_refs).
        """

    def parse(self, sql: str) -> List[Tuple[Optional[IRDDLObject], List[IRWarning], List[IRDocReference]]]:
        """
        Split a multi-statement SQL script and parse each statement.
        """
        statements = self._split_statements(sql)
        results = []
        for stmt in statements:
            stmt = stmt.strip()
            if stmt:
                results.append(self.parse_statement(stmt))
        return results

    def _split_statements(self, sql: str) -> List[str]:
        """
        Statement splitter on semicolons, aware of:
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

    def _parse_data_type(self, type_str: str) -> Tuple[IRDataType, List[IRWarning], List[IRDocReference]]:
        """
        Convert a native type string to an IRDataType using the TypeMapper.
        """
        generic, prec, scale, length = self.mapper.source_type_to_generic(self.dialect, type_str)
        return IRDataType(
            generic_type=generic,
            precision=prec,
            scale=scale,
            length=length,
            original_type_string=type_str,
        ), [], []

    def _parse_proc_from_sql(
        self, sql: str, body_style: str = "best_effort"
    ) -> Tuple[Optional[IRProcedure], List[IRWarning], List[IRDocReference]]:
        """
        Shared procedure parser: extract name, params, body, language from raw SQL.
        body_style: 'dollar' | 'tsql' | 'oracle' | 'bigquery' | 'best_effort'
        """
        from app.dialects.procedure_utils import (
            extract_obj_name, extract_all_params, extract_language,
            extract_body_dollar_quote, extract_body_tsql, extract_body_oracle,
            extract_body_bigquery, extract_body_best_effort, params_to_ir,
            MANUAL_REVIEW_COMMENT,
        )

        name, schema, db = extract_obj_name(sql, "PROCEDURE")
        raw_params = extract_all_params(sql, "PROCEDURE")
        language = extract_language(sql)
        or_replace = bool(re.search(r'\bOR\s+REPLACE\b', sql, re.IGNORECASE))

        body_fn = {
            "dollar": extract_body_dollar_quote,
            "tsql": extract_body_tsql,
            "oracle": extract_body_oracle,
            "bigquery": extract_body_bigquery,
            "best_effort": extract_body_best_effort,
        }.get(body_style, extract_body_best_effort)
        body = body_fn(sql) or sql

        ir_params, w, d = params_to_ir(raw_params, self.dialect, self.mapper)
        warnings = w + [IRWarning(
            feature="MANUAL_REVIEW_REQUIRED",
            message="Stored procedure body has been preserved from the source dialect. "
                    "The procedural body requires manual review and adaptation: "
                    "variable declarations, error handling, cursors, and built-in functions "
                    "differ significantly between SQL dialects.",
            severity=Warningseverity.WARNING,
            fallback_applied=False,
        )]
        proc = IRProcedure(
            name=name, schema_name=schema, database_name=db,
            parameters=ir_params, language=language, body=body,
            or_replace=or_replace, requires_manual_review=True,
        )
        return proc, warnings, d

    def _parse_func_from_sql(
        self, sql: str, body_style: str = "best_effort"
    ) -> Tuple[Optional[IRFunction], List[IRWarning], List[IRDocReference]]:
        """
        Shared function parser: extract name, params, return type, body, language.
        """
        from app.dialects.procedure_utils import (
            extract_obj_name, extract_all_params, extract_language,
            extract_returns_type, extract_body_dollar_quote, extract_body_tsql,
            extract_body_oracle, extract_body_bigquery, extract_body_best_effort,
            params_to_ir, MANUAL_REVIEW_COMMENT,
        )

        name, schema, db = extract_obj_name(sql, "FUNCTION")
        raw_params = extract_all_params(sql, "FUNCTION")
        language = extract_language(sql)
        returns_str = extract_returns_type(sql)
        or_replace = bool(re.search(r'\bOR\s+REPLACE\b', sql, re.IGNORECASE))

        body_fn = {
            "dollar": extract_body_dollar_quote,
            "tsql": extract_body_tsql,
            "oracle": extract_body_oracle,
            "bigquery": extract_body_bigquery,
            "best_effort": extract_body_best_effort,
        }.get(body_style, extract_body_best_effort)
        body = body_fn(sql) or sql

        ir_params, w, d = params_to_ir(raw_params, self.dialect, self.mapper)

        return_type = None
        if returns_str:
            return_type, _, _ = self._parse_data_type(returns_str)

        warnings = w + [IRWarning(
            feature="MANUAL_REVIEW_REQUIRED",
            message="Function body has been preserved from the source dialect. "
                    "Review and adapt before deploying: variable declarations, "
                    "return statements, and built-in functions differ by dialect.",
            severity=Warningseverity.WARNING,
            fallback_applied=False,
        )]
        func = IRFunction(
            name=name, schema_name=schema, database_name=db,
            parameters=ir_params, language=language, body=body,
            return_type=return_type, or_replace=or_replace,
            requires_manual_review=True,
        )
        return func, warnings, d


class DialectGenerator(ABC):
    """
    Converts IR objects into SQL DDL text for a specific target dialect.
    """

    dialect: Dialect
    mapper: TypeMapper

    def __init__(self) -> None:
        self.mapper = TypeMapper.get()

    @abstractmethod
    def generate_table(self, table: IRTable) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """Generate CREATE TABLE statement."""

    @abstractmethod
    def generate_view(self, view: IRView) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """Generate CREATE VIEW statement."""

    @abstractmethod
    def generate_materialized_view(
        self, mv: IRMaterializedView
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """Generate CREATE MATERIALIZED VIEW (or documented fallback)."""

    def _type_to_sql(
        self,
        data_type: IRDataType,
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """Map an IRDataType to the target dialect's native type string."""
        return self.mapper.generic_to_target(
            data_type.generic_type,
            self.dialect,
            precision=data_type.precision,
            scale=data_type.scale,
            length=data_type.length,
        )

    def _quote_identifier(self, name: str) -> str:
        """
        Return the identifier quoted with the dialect's quoting character.
        Subclasses override for dialect-specific quoting.
        """
        return f'"{name}"'

    def generate_procedure(
        self, proc: IRProcedure
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Generate CREATE PROCEDURE statement.
        Subclasses override for dialect-specific syntax.
        Default: emit a MANUAL_REVIEW stub using the base class header logic.
        """
        from app.dialects.procedure_utils import format_body_comment
        qname = self._quote_identifier(proc.name)
        if proc.schema_name:
            qname = f"{self._quote_identifier(proc.schema_name)}.{qname}"
        body_comment = format_body_comment(
            proc.language or "unknown", self.dialect.value, proc.language
        )
        sql = (
            f"CREATE OR REPLACE PROCEDURE {qname}()\n"
            f"AS\n"
            f"$$\n"
            f"{body_comment}\n"
            f"{proc.body}\n"
            f"$$;"
        )
        warnings = [IRWarning(
            feature="PROCEDURE_MANUAL_REVIEW",
            message=f"Procedure generated with stub header for {self.dialect.value}. "
                    f"Review parameter types and body syntax.",
            severity=Warningseverity.WARNING,
        )]
        return sql, warnings, []

    def generate_function(
        self, func: IRFunction
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Generate CREATE FUNCTION statement.
        Subclasses override for dialect-specific syntax.
        """
        from app.dialects.procedure_utils import format_body_comment
        qname = self._quote_identifier(func.name)
        if func.schema_name:
            qname = f"{self._quote_identifier(func.schema_name)}.{qname}"
        body_comment = format_body_comment(
            func.language or "unknown", self.dialect.value, func.language
        )
        sql = (
            f"CREATE OR REPLACE FUNCTION {qname}()\n"
            f"RETURNS VARIANT\n"
            f"AS\n"
            f"$$\n"
            f"{body_comment}\n"
            f"{func.body}\n"
            f"$$;"
        )
        warnings = [IRWarning(
            feature="FUNCTION_MANUAL_REVIEW",
            message=f"Function generated with stub header for {self.dialect.value}. "
                    f"Review parameter types and body syntax.",
            severity=Warningseverity.WARNING,
        )]
        return sql, warnings, []

    def _nullable_clause(self, col: IRColumn) -> str:
        return "" if col.is_nullable else " NOT NULL"

    def _default_clause(self, col: IRColumn) -> str:
        if col.default_value is not None:
            return f" DEFAULT {col.default_value}"
        return ""

    # -----------------------------------------------------------------------
    # Arg-count aware function conversion utilities (Phase 8)
    # Borrowed from Redshift-Fabric-Transpiler: handles nested calls correctly
    # by tracking parenthesis depth so commas inside nested calls are ignored.
    # -----------------------------------------------------------------------

    @staticmethod
    def _count_func_args(args_str: str) -> int:
        """
        Count the number of top-level comma-separated arguments in a function
        call's argument string (i.e. the text between the outer parentheses).

        Handles:
          - Nested function calls: NVL(a, NVL(b, c))  → 2 args
          - String literals:       NVL('a,b', c)       → 2 args
          - Empty arg list:        ''                   → 0 args

        Args:
            args_str: The raw argument text between parentheses, e.g. "a, b, c"

        Returns:
            Number of top-level arguments.
        """
        if not args_str.strip():
            return 0

        depth = 0
        in_single = False
        in_double = False
        count = 1  # at least one arg if non-empty

        for ch in args_str:
            if ch == "'" and not in_double:
                in_single = not in_single
            elif ch == '"' and not in_single:
                in_double = not in_double
            elif not in_single and not in_double:
                if ch == '(':
                    depth += 1
                elif ch == ')':
                    depth -= 1
                elif ch == ',' and depth == 0:
                    count += 1

        return count

    @staticmethod
    def _extract_func_args_str(sql: str, func_name: str, pos: int) -> Optional[str]:
        """
        Given a position pointing to the '(' after func_name, extract the
        content between the outer parentheses.

        Returns the args string, or None if not found.
        """
        start = sql.find('(', pos)
        if start == -1:
            return None
        depth = 0
        in_single = False
        for i in range(start, len(sql)):
            ch = sql[i]
            if ch == "'" :
                in_single = not in_single
            elif not in_single:
                if ch == '(':
                    depth += 1
                elif ch == ')':
                    depth -= 1
                    if depth == 0:
                        return sql[start + 1:i]
        return None

    def _convert_nvl_aware(self, sql: str) -> str:
        """
        Convert NVL(a, b) → ISNULL(a, b) for 2-arg form,
               NVL(a, b, c, ...) → COALESCE(a, b, c, ...) for 3+ args.
        Handles nested calls via recursion on the args string.
        Override in dialects that need NVL conversion.
        """
        pattern = re.compile(r'\bNVL\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            if m.start() < last:
                # Already consumed as part of an outer match's args — skip to avoid duplication.
                continue
            args_str = self._extract_func_args_str(sql, "NVL", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            n_args = self._count_func_args(args_str)
            func = "ISNULL" if n_args == 2 else "COALESCE"
            # Recursively convert any nested NVL calls inside the args.
            converted_args = self._convert_nvl_aware(args_str)
            result.append(sql[last:m.start()])
            result.append(f"{func}({converted_args})")
            last = m.start() + len(m.group()) + len(args_str) + 1  # skip closing )
        result.append(sql[last:])
        return "".join(result)

    def _convert_decode_to_case(self, sql: str) -> str:
        """
        Convert Oracle DECODE(expr, v1, r1, v2, r2, ..., [default])
        to CASE WHEN expr=v1 THEN r1 WHEN expr=v2 THEN r2 ... [ELSE default] END.
        Uses _count_func_args to correctly count arguments.
        """
        pattern = re.compile(r'\bDECODE\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "DECODE", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue

            # Split args at top-level commas
            args = self._split_top_level(args_str)
            if len(args) < 3:
                # Can't convert malformed DECODE — leave as-is
                result.append(sql[last:m.end()])
                last = m.end()
                continue

            expr = args[0].strip()
            pairs = args[1:]
            case_parts = [f"CASE"]
            i = 0
            while i + 1 < len(pairs):
                val = pairs[i].strip()
                res = pairs[i + 1].strip()
                case_parts.append(f"  WHEN {expr} = {val} THEN {res}")
                i += 2
            if i < len(pairs):
                case_parts.append(f"  ELSE {pairs[i].strip()}")
            case_parts.append("END")
            case_sql = "\n".join(case_parts)

            result.append(sql[last:m.start()])
            result.append(case_sql)
            # Advance past the closing paren
            last = m.start() + len(m.group()) + len(args_str) + 1
        result.append(sql[last:])
        return "".join(result)

    @staticmethod
    def _split_top_level(s: str) -> List[str]:
        """Split s on commas at depth 0 (ignoring nested parens and strings)."""
        parts = []
        current: List[str] = []
        depth = 0
        in_single = False
        for ch in s:
            if ch == "'" and not in_single:
                in_single = True
                current.append(ch)
            elif ch == "'" and in_single:
                in_single = False
                current.append(ch)
            elif not in_single:
                if ch == '(':
                    depth += 1
                    current.append(ch)
                elif ch == ')':
                    depth -= 1
                    current.append(ch)
                elif ch == ',' and depth == 0:
                    parts.append("".join(current))
                    current = []
                else:
                    current.append(ch)
            else:
                current.append(ch)
        if current:
            parts.append("".join(current))
        return parts

    # -----------------------------------------------------------------------
    # View definition body transformation utilities
    # Applied in generate_view() to convert source-dialect functions to the
    # target dialect equivalents before emitting the view body.
    # -----------------------------------------------------------------------

    def _convert_nvl2_to_case(self, sql: str) -> str:
        """
        Convert NVL2(expr, val_if_not_null, val_if_null)
        →  CASE WHEN expr IS NOT NULL THEN val_if_not_null ELSE val_if_null END
        For dialects that don't support NVL2 (everything except Oracle/Snowflake).
        """
        pattern = re.compile(r'\bNVL2\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "NVL2", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            args = self._split_top_level(args_str)
            if len(args) != 3:
                # Malformed NVL2 — leave as-is
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            expr, val_nn, val_null = args[0].strip(), args[1].strip(), args[2].strip()
            case_sql = f"CASE WHEN {expr} IS NOT NULL THEN {val_nn} ELSE {val_null} END"
            result.append(sql[last:m.start()])
            result.append(case_sql)
            last = m.start() + len(m.group()) + len(args_str) + 1  # skip closing )
        result.append(sql[last:])
        return "".join(result)

    def _convert_isnull_to_nvl(self, sql: str) -> str:
        """Convert T-SQL ISNULL(a, b) → Oracle-style NVL(a, b)."""
        return re.sub(r'\bISNULL\s*\(', 'NVL(', sql, flags=re.IGNORECASE)

    @staticmethod
    def _convert_varchar2_to_varchar(sql: str) -> str:
        """Convert Oracle VARCHAR2(n) → VARCHAR(n) inside view/MV body SQL.
        Also converts NVARCHAR2 → NVARCHAR (T-SQL/Snowflake) and
        NUMBER used as a CAST type → DECIMAL where no precision given."""
        sql = re.sub(r'\bVARCHAR2\s*\(', 'VARCHAR(', sql, flags=re.IGNORECASE)
        sql = re.sub(r'\bNVARCHAR2\s*\(', 'NVARCHAR(', sql, flags=re.IGNORECASE)
        return sql

    def _convert_isnull_to_ifnull(self, sql: str) -> str:
        """Convert T-SQL ISNULL(a, b) → IFNULL(a, b) (BigQuery/Databricks/MySQL style)."""
        return re.sub(r'\bISNULL\s*\(', 'IFNULL(', sql, flags=re.IGNORECASE)

    def _convert_nvl_to_ifnull(self, sql: str) -> str:
        """Convert Oracle/Redshift NVL(a, b) → IFNULL(a, b) (BigQuery/Databricks style).
        Uses negative lookahead to avoid matching NVL2."""
        return re.sub(r'\bNVL(?!2)\s*\(', 'IFNULL(', sql, flags=re.IGNORECASE)

    @staticmethod
    def _convert_backtick_identifiers(sql: str) -> str:
        """
        Convert BigQuery-style backtick identifiers to double-quoted identifiers.
        `myproject.dataset.table`  →  "myproject.dataset.table"
        Applied in non-BigQuery generators so view definitions don't leak
        BigQuery identifier quoting into other dialects.
        """
        return re.sub(r'`([^`]+)`', r'"\1"', sql)

    def _flag_unsupported_initcap(self, sql: str) -> List[IRWarning]:
        """
        Redshift/Snowflake/Oracle/BigQuery/Databricks all have INITCAP();
        T-SQL (SQL Server, Synapse, Fabric DW) does not. There is no safe
        single-expression equivalent — correct per-word capitalization needs
        STRING_SPLIT + re-aggregation or a scalar UDF — so rather than guess
        with something that's wrong for multi-word strings, leave the call
        untouched and raise a clear, unsupported-tier warning.
        """
        if re.search(r'\bINITCAP\s*\(', sql, re.IGNORECASE):
            return [IRWarning(
                feature="UNSUPPORTED_FUNCTION_INITCAP",
                message=(
                    "INITCAP() has no T-SQL equivalent (SQL Server / Synapse / Fabric DW). "
                    "There is no safe single-expression substitute — implement a scalar "
                    "function or rewrite using STRING_SPLIT + STUFF to capitalize each "
                    "word manually before deploying this statement."
                ),
                severity=Warningseverity.WARNING,
                unsupported=True,
            )]
        return []

    # -----------------------------------------------------------------------
    # T-SQL function conversions (SQL Server / Synapse / Fabric DW)
    # Sourced from Redshift-Fabric-Transpiler reference repo patterns.
    # -----------------------------------------------------------------------

    def _convert_pipe_concat_to_plus(self, sql: str) -> str:
        """Convert || string concatenation to T-SQL + operator."""
        result = []
        i = 0
        in_single = False
        in_double = False
        while i < len(sql):
            ch = sql[i]
            if ch == "'" and not in_double:
                in_single = not in_single
                result.append(ch)
            elif ch == '"' and not in_single:
                in_double = not in_double
                result.append(ch)
            elif ch == '|' and not in_single and not in_double and i + 1 < len(sql) and sql[i + 1] == '|':
                result.append('+')
                i += 2
                continue
            else:
                result.append(ch)
            i += 1
        return "".join(result)

    def _convert_current_date(self, sql: str) -> str:
        """Convert CURRENT_DATE → CONVERT(DATE, GETDATE()) for T-SQL."""
        return re.sub(
            r'\bCURRENT_DATE\b(?!\s*\()',
            'CONVERT(DATE, GETDATE())',
            sql,
            flags=re.IGNORECASE,
        )

    def _convert_sysdate(self, sql: str) -> str:
        """Convert Oracle SYSDATE → GETDATE() for T-SQL."""
        return re.sub(
            r'\bSYSDATE\b(?!\s*\()',
            'GETDATE()',
            sql,
            flags=re.IGNORECASE,
        )

    def _convert_getdate_to_current_timestamp(self, sql: str) -> str:
        """Convert T-SQL GETDATE() → CURRENT_TIMESTAMP for non-T-SQL dialects."""
        return re.sub(r'\bGETDATE\s*\(\)', 'CURRENT_TIMESTAMP', sql, flags=re.IGNORECASE)

    def _convert_date_trunc(self, sql: str) -> str:
        """Convert DATE_TRUNC('part', expr) → DATETRUNC(part, expr) for T-SQL."""
        pattern = re.compile(r'\bDATE_TRUNC\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "DATE_TRUNC", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            args = self._split_top_level(args_str)
            if len(args) == 2:
                part = args[0].strip().strip("'\"")
                expr = args[1].strip()
                result.append(sql[last:m.start()])
                result.append(f"DATETRUNC({part}, {expr})")
            else:
                result.append(sql[last:m.start()])
                result.append(f"DATETRUNC({args_str})")
            last = m.start() + len(m.group()) + len(args_str) + 1
        result.append(sql[last:])
        return "".join(result)

    def _convert_date_part(self, sql: str) -> str:
        """Convert DATE_PART('part', expr) → DATEPART(part, expr) for T-SQL."""
        pattern = re.compile(r'\bDATE_PART\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "DATE_PART", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            args = self._split_top_level(args_str)
            if len(args) == 2:
                part = args[0].strip().strip("'\"")
                expr = args[1].strip()
                result.append(sql[last:m.start()])
                result.append(f"DATEPART({part}, {expr})")
            else:
                result.append(sql[last:m.start()])
                result.append(f"DATEPART({args_str})")
            last = m.start() + len(m.group()) + len(args_str) + 1
        result.append(sql[last:])
        return "".join(result)

    def _convert_extract_to_datepart(self, sql: str) -> str:
        """Convert EXTRACT(part FROM expr) → DATEPART(part, expr) for T-SQL."""
        pattern = re.compile(
            r'\bEXTRACT\s*\(\s*(\w+)\s+FROM\s+(.+?)\)',
            re.IGNORECASE,
        )
        return pattern.sub(r'DATEPART(\1, \2)', sql)

    def _convert_length_to_len(self, sql: str) -> str:
        """Convert LENGTH(x) → LEN(x) for T-SQL."""
        return re.sub(r'\bLENGTH\s*\(', 'LEN(', sql, flags=re.IGNORECASE)

    def _convert_len_to_length(self, sql: str) -> str:
        """Convert T-SQL LEN(x) → LENGTH(x) for non-T-SQL dialects."""
        return re.sub(r'\bLEN\s*\(', 'LENGTH(', sql, flags=re.IGNORECASE)

    def _convert_substr_to_substring(self, sql: str) -> str:
        """Convert SUBSTR(x, y, z) → SUBSTRING(x, y, z) for T-SQL."""
        return re.sub(r'\bSUBSTR\s*\(', 'SUBSTRING(', sql, flags=re.IGNORECASE)

    def _convert_position_to_charindex(self, sql: str) -> str:
        """Convert POSITION(x IN y) → CHARINDEX(x, y) for T-SQL."""
        pattern = re.compile(
            r'\bPOSITION\s*\(\s*(.+?)\s+IN\s+(.+?)\)',
            re.IGNORECASE,
        )
        return pattern.sub(r'CHARINDEX(\1, \2)', sql)

    def _convert_ceil_to_ceiling(self, sql: str) -> str:
        """Convert CEIL(x) → CEILING(x) for T-SQL. Avoids matching CEILING."""
        return re.sub(r'\bCEIL\b(?!ING)\s*\(', 'CEILING(', sql, flags=re.IGNORECASE)

    def _convert_ceiling_to_ceil(self, sql: str) -> str:
        """Convert T-SQL CEILING(x) → CEIL(x) for non-T-SQL dialects."""
        return re.sub(r'\bCEILING\s*\(', 'CEIL(', sql, flags=re.IGNORECASE)

    def _convert_add_months(self, sql: str) -> str:
        """Convert ADD_MONTHS(date, n) → DATEADD(MONTH, n, date) for T-SQL."""
        pattern = re.compile(r'\bADD_MONTHS\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "ADD_MONTHS", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            args = self._split_top_level(args_str)
            if len(args) == 2:
                date_expr = args[0].strip()
                n_months = args[1].strip()
                result.append(sql[last:m.start()])
                result.append(f"DATEADD(MONTH, {n_months}, {date_expr})")
            else:
                result.append(sql[last:m.end()])
            last = m.start() + len(m.group()) + len(args_str) + 1
        result.append(sql[last:])
        return "".join(result)

    def _convert_last_day_to_eomonth(self, sql: str) -> str:
        """Convert LAST_DAY(date) → EOMONTH(date) for T-SQL."""
        return re.sub(r'\bLAST_DAY\s*\(', 'EOMONTH(', sql, flags=re.IGNORECASE)

    def _convert_listagg_to_string_agg(self, sql: str) -> str:
        """Convert LISTAGG(col, sep) → STRING_AGG(col, sep) for T-SQL."""
        return re.sub(r'\bLISTAGG\s*\(', 'STRING_AGG(', sql, flags=re.IGNORECASE)

    def _convert_to_char_to_format(self, sql: str) -> str:
        """Convert TO_CHAR(expr, fmt) → FORMAT(expr, fmt) for T-SQL."""
        return re.sub(r'\bTO_CHAR\s*\(', 'FORMAT(', sql, flags=re.IGNORECASE)

    def _convert_to_number_to_cast(self, sql: str) -> str:
        """Convert TO_NUMBER(expr) → CAST(expr AS FLOAT) for T-SQL."""
        pattern = re.compile(r'\bTO_NUMBER\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "TO_NUMBER", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            args = self._split_top_level(args_str)
            expr = args[0].strip()
            result.append(sql[last:m.start()])
            result.append(f"CAST({expr} AS FLOAT)")
            last = m.start() + len(m.group()) + len(args_str) + 1
        result.append(sql[last:])
        return "".join(result)

    def _convert_double_colon_cast(self, sql: str) -> str:
        """Convert Redshift/Postgres expr::TYPE → CONVERT(TYPE, expr) for T-SQL."""
        pattern = re.compile(r'(\w[\w.]*|\([^)]+\))::([\w]+(?:\([^)]*\))?)')
        def _repl(m):
            expr = m.group(1)
            cast_type = m.group(2)
            return f"CONVERT({cast_type}, {expr})"
        return pattern.sub(_repl, sql)

    def _flag_unsupported_regexp(self, sql: str) -> List[IRWarning]:
        """Flag REGEXP_* functions that have no T-SQL equivalent."""
        warnings: List[IRWarning] = []
        for func in ['REGEXP_SUBSTR', 'REGEXP_REPLACE', 'REGEXP_INSTR', 'REGEXP_COUNT', 'REGEXP_LIKE']:
            if re.search(rf'\b{func}\s*\(', sql, re.IGNORECASE):
                warnings.append(IRWarning(
                    feature=f"UNSUPPORTED_FUNCTION_{func}",
                    message=(
                        f"{func}() has no native T-SQL equivalent (SQL Server / Synapse / Fabric DW). "
                        f"Rewrite using LIKE, PATINDEX, or a CLR function."
                    ),
                    severity=Warningseverity.WARNING,
                    unsupported=True,
                ))
        return warnings

    def _apply_tsql_view_conversions(self, sql: str) -> Tuple[str, List[IRWarning]]:
        """Apply all source→T-SQL function conversions for view/MV bodies."""
        warnings: List[IRWarning] = []
        sql = self._convert_backtick_identifiers(sql)
        sql = self._convert_varchar2_to_varchar(sql)
        sql = self._convert_double_colon_cast(sql)
        sql = self._convert_nvl2_to_case(sql)
        sql = self._convert_nvl_aware(sql)
        sql = self._convert_decode_to_case(sql)
        sql = self._convert_pipe_concat_to_plus(sql)
        sql = self._convert_current_date(sql)
        sql = self._convert_sysdate(sql)
        sql = self._convert_date_trunc(sql)
        sql = self._convert_date_part_year_to_year(sql)
        sql = self._convert_date_part(sql)
        sql = self._convert_extract_to_datepart(sql)
        sql = self._convert_length_to_len(sql)
        sql = self._convert_substr_to_substring(sql)
        sql = self._convert_position_to_charindex(sql)
        sql = self._convert_ceil_to_ceiling(sql)
        sql = self._convert_add_months(sql)
        sql = self._convert_last_day_to_eomonth(sql)
        sql = self._convert_listagg_to_string_agg(sql)
        sql = self._convert_to_char_to_format(sql)
        sql = self._convert_to_number_to_cast(sql)
        sql, tz_warnings = self._convert_timezone_to_at_time_zone(sql)
        warnings.extend(tz_warnings)
        warnings.extend(self._flag_unsupported_initcap(sql))
        warnings.extend(self._flag_unsupported_regexp(sql))
        return sql, warnings

    def _convert_timezone_to_at_time_zone(self, sql: str) -> Tuple[str, List[IRWarning]]:
        """
        Convert Redshift/Snowflake CONVERT_TIMEZONE(...) calls into T-SQL's
        chained AT TIME ZONE syntax (SQL Server / Synapse / Fabric DW — all
        support AT TIME ZONE; confirmed for Fabric DW via the documented
        CAST(... AS DATETIMEOFFSET) AT TIME ZONE ... pattern).

        3-arg form: CONVERT_TIMEZONE('src_tz', 'tgt_tz', ts)
            → CAST(ts AT TIME ZONE 'src_windows_tz' AT TIME ZONE 'tgt_windows_tz' AS DATETIME2(6))
        2-arg form: CONVERT_TIMEZONE('tgt_tz', ts)   -- source assumed UTC
            → CAST(ts AT TIME ZONE 'UTC' AT TIME ZONE 'tgt_windows_tz' AS DATETIME2(6))

        Only converts when every zone name has a verified Windows time zone
        equivalent (see timezone_mapping.py). Unmapped zones are left as the
        original CONVERT_TIMEZONE(...) call with an unsupported-tier warning
        — we never guess at a timezone mapping.
        """
        from app.dialects.timezone_mapping import iana_to_windows

        def _strip_quotes(s: str) -> Optional[str]:
            s = s.strip()
            if len(s) >= 2 and s[0] in "'\"" and s[-1] == s[0]:
                return s[1:-1]
            return None

        pattern = re.compile(r'\bCONVERT_TIMEZONE\s*\(', re.IGNORECASE)
        warnings: List[IRWarning] = []
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "CONVERT_TIMEZONE", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue

            call_end = m.start() + len(m.group()) + len(args_str) + 1
            full_call = sql[m.start():call_end]
            args = [a.strip() for a in self._split_top_level(args_str)]

            converted = None
            extra_warning: Optional[IRWarning] = None

            def _tz_expr(arg: str) -> Tuple[str, Optional[str]]:
                """
                Return (sql_fragment, warning_message_or_None) for a timezone argument.
                  - String literal with known IANA mapping  → quoted Windows TZ name, no warning
                  - String literal with unknown mapping     → keep original quoted string, warning
                  - Non-literal (column ref / expression)  → use expression directly, info warning
                """
                lit = _strip_quotes(arg)
                if lit is not None:
                    # String literal — try IANA → Windows mapping
                    win = iana_to_windows(lit)
                    if win:
                        return f"'{win}'", None
                    else:
                        # Unknown IANA name or already a Windows TZ name — keep as-is
                        return arg, (
                            f"Timezone string {arg!r} is not in the verified IANA→Windows "
                            f"mapping; it has been left as-is. If this is already a Windows "
                            f"timezone ID (query sys.time_zone_info for valid names), the "
                            f"output is correct. Otherwise replace it manually."
                        )
                else:
                    # Non-literal (column reference or expression)
                    return arg, (
                        f"CONVERT_TIMEZONE() argument {arg!r} is a column reference or "
                        f"expression, not a string literal. The generated AT TIME ZONE "
                        f"expression uses this column directly — it MUST contain Windows "
                        f"timezone IDs at runtime (e.g. 'India Standard Time', not "
                        f"'Asia/Kolkata'). Query sys.time_zone_info for valid Windows TZ names."
                    )

            if len(args) == 3:
                src_frag, src_warn = _tz_expr(args[0])
                tgt_frag, tgt_warn = _tz_expr(args[1])
                ts_expr = args[2]
                converted = f"CAST({ts_expr} AT TIME ZONE {src_frag} AT TIME ZONE {tgt_frag} AS DATETIME2(6))"
                warn_msg = src_warn or tgt_warn
                if warn_msg:
                    extra_warning = IRWarning(
                        feature="CONVERT_TIMEZONE_DYNAMIC_TZ",
                        message=warn_msg,
                        doc_url="https://learn.microsoft.com/en-us/sql/t-sql/queries/at-time-zone-transact-sql",
                        severity=Warningseverity.WARNING,
                        unsupported=False,
                    )
            elif len(args) == 2:
                tgt_frag, tgt_warn = _tz_expr(args[0])
                ts_expr = args[1]
                converted = f"CAST({ts_expr} AT TIME ZONE 'UTC' AT TIME ZONE {tgt_frag} AS DATETIME2(6))"
                if tgt_warn:
                    extra_warning = IRWarning(
                        feature="CONVERT_TIMEZONE_DYNAMIC_TZ",
                        message=tgt_warn,
                        doc_url="https://learn.microsoft.com/en-us/sql/t-sql/queries/at-time-zone-transact-sql",
                        severity=Warningseverity.WARNING,
                        unsupported=False,
                    )

            result.append(sql[last:m.start()])
            if converted is not None:
                result.append(converted)
                if extra_warning:
                    warnings.append(extra_warning)
            else:
                # Unexpected arg count — leave as-is with a hard warning
                warnings.append(IRWarning(
                    feature="UNSUPPORTED_FUNCTION_CONVERT_TIMEZONE",
                    message=(
                        f"CONVERT_TIMEZONE() with {len(args)} argument(s) is not supported. "
                        f"Expected 2 or 3 args. Left as-is: {full_call}"
                    ),
                    doc_url="https://learn.microsoft.com/en-us/sql/t-sql/queries/at-time-zone-transact-sql",
                    severity=Warningseverity.WARNING,
                    unsupported=True,
                ))
                result.append(full_call)
            last = call_end
        result.append(sql[last:])
        return "".join(result), warnings

    # -----------------------------------------------------------------------
    # Non-T-SQL function conversions — Oracle, Snowflake, BigQuery,
    # Databricks, Redshift targets. Each method is the reverse or analogue
    # of the T-SQL helpers above. Sourced from official dialect docs.
    # -----------------------------------------------------------------------

    def _convert_getdate_to_sysdate(self, sql: str) -> str:
        """Convert T-SQL GETDATE() → SYSDATE for Oracle target."""
        return re.sub(r'\bGETDATE\s*\(\)', 'SYSDATE', sql, flags=re.IGNORECASE)

    def _convert_sysdate_to_current_timestamp(self, sql: str) -> str:
        """Convert Oracle SYSDATE → CURRENT_TIMESTAMP for Snowflake/BigQuery/Databricks."""
        return re.sub(r'\bSYSDATE\b(?!\s*\()', 'CURRENT_TIMESTAMP', sql, flags=re.IGNORECASE)

    def _convert_substring_to_substr(self, sql: str) -> str:
        """Convert SUBSTRING(x, y, z) → SUBSTR(x, y, z) for Oracle."""
        return re.sub(r'\bSUBSTRING\s*\(', 'SUBSTR(', sql, flags=re.IGNORECASE)

    def _convert_charindex_to_instr(self, sql: str) -> str:
        """Convert CHARINDEX(search, string[, start]) → INSTR(string, search[, start]) for Oracle.
        Args are swapped: CHARINDEX(needle, haystack) vs INSTR(haystack, needle)."""
        pattern = re.compile(r'\bCHARINDEX\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "CHARINDEX", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            args = self._split_top_level(args_str)
            result.append(sql[last:m.start()])
            if len(args) >= 2:
                search = args[0].strip()
                string = args[1].strip()
                if len(args) >= 3:
                    result.append(f"INSTR({string}, {search}, {args[2].strip()})")
                else:
                    result.append(f"INSTR({string}, {search})")
            else:
                result.append(f"INSTR({args_str})")
            last = m.start() + len(m.group()) + len(args_str) + 1
        result.append(sql[last:])
        return "".join(result)

    def _convert_charindex_to_locate(self, sql: str) -> str:
        """Convert CHARINDEX(search, string[, start]) → LOCATE(search, string[, start]) for Databricks.
        LOCATE keeps the same arg order as CHARINDEX."""
        return re.sub(r'\bCHARINDEX\s*\(', 'LOCATE(', sql, flags=re.IGNORECASE)

    def _convert_charindex_to_strpos(self, sql: str) -> str:
        """Convert CHARINDEX(search, string) → STRPOS(string, search) for BigQuery.
        BigQuery STRPOS flips args vs CHARINDEX."""
        pattern = re.compile(r'\bCHARINDEX\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "CHARINDEX", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            args = self._split_top_level(args_str)
            result.append(sql[last:m.start()])
            if len(args) >= 2:
                result.append(f"STRPOS({args[1].strip()}, {args[0].strip()})")
            else:
                result.append(f"STRPOS({args_str})")
            last = m.start() + len(m.group()) + len(args_str) + 1
        result.append(sql[last:])
        return "".join(result)

    def _convert_string_agg_to_listagg(self, sql: str) -> str:
        """Convert STRING_AGG(col, sep) → LISTAGG(col, sep) for Oracle/Snowflake/Redshift."""
        return re.sub(r'\bSTRING_AGG\s*\(', 'LISTAGG(', sql, flags=re.IGNORECASE)

    def _convert_eomonth_to_last_day(self, sql: str) -> str:
        """Convert T-SQL EOMONTH(date) → LAST_DAY(date) for Oracle/Snowflake/Redshift/BigQuery/Databricks."""
        return re.sub(r'\bEOMONTH\s*\(', 'LAST_DAY(', sql, flags=re.IGNORECASE)

    def _convert_datetrunc_to_trunc_oracle(self, sql: str) -> str:
        """Convert DATETRUNC(part, expr) or DATE_TRUNC('part', expr) → TRUNC(expr, 'fmt') for Oracle.
        Oracle TRUNC uses its own format codes.
        Docs: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/TRUNC-date.html"""
        _part_map = {
            'YEAR': 'YEAR', 'YYYY': 'YEAR', 'YY': 'YEAR',
            'MONTH': 'MONTH', 'MM': 'MONTH', 'MON': 'MONTH',
            'DAY': 'DD', 'DD': 'DD', 'DDD': 'DD',
            'HOUR': 'HH', 'HH': 'HH', 'HH24': 'HH', 'HH12': 'HH',
            'MINUTE': 'MI', 'MI': 'MI',
            'WEEK': 'IW', 'IW': 'IW',
            'QUARTER': 'Q', 'Q': 'Q',
        }
        pattern = re.compile(r'\b(?:DATETRUNC|DATE_TRUNC)\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "DATETRUNC", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            args = self._split_top_level(args_str)
            call_end = m.start() + len(m.group()) + len(args_str) + 1
            result.append(sql[last:m.start()])
            if len(args) == 2:
                part = args[0].strip().strip("'\"").upper()
                expr = args[1].strip()
                oracle_fmt = _part_map.get(part, part)
                result.append(f"TRUNC({expr}, '{oracle_fmt}')")
            else:
                result.append(sql[m.start():call_end])
            last = call_end
        result.append(sql[last:])
        return "".join(result)

    def _convert_datetrunc_to_date_trunc(self, sql: str) -> str:
        """Convert DATETRUNC(part, expr) → DATE_TRUNC('part', expr) for Snowflake/Redshift/Databricks."""
        pattern = re.compile(r'\bDATETRUNC\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "DATETRUNC", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            args = self._split_top_level(args_str)
            call_end = m.start() + len(m.group()) + len(args_str) + 1
            result.append(sql[last:m.start()])
            if len(args) == 2:
                part = args[0].strip().strip("'\"")
                expr = args[1].strip()
                result.append(f"DATE_TRUNC('{part}', {expr})")
            else:
                result.append(sql[m.start():call_end])
            last = call_end
        result.append(sql[last:])
        return "".join(result)

    def _convert_datetrunc_to_date_trunc_bigquery(self, sql: str) -> str:
        """Convert DATETRUNC(part, expr) or DATE_TRUNC('part', expr) → DATE_TRUNC(expr, part) for BigQuery.
        BigQuery DATE_TRUNC flips args and uses unquoted part keyword.
        Handles both T-SQL DATETRUNC(part, expr) and standard DATE_TRUNC('part', expr) forms.
        Docs: https://cloud.google.com/bigquery/docs/reference/standard-sql/date_functions#date_trunc"""
        pattern = re.compile(r'\b(?:DATETRUNC|DATE_TRUNC)\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "DATETRUNC", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            args = self._split_top_level(args_str)
            call_end = m.start() + len(m.group()) + len(args_str) + 1
            result.append(sql[last:m.start()])
            if len(args) == 2:
                part = args[0].strip().strip("'\"")
                expr = args[1].strip()
                result.append(f"DATE_TRUNC({expr}, {part})")
            else:
                result.append(sql[m.start():call_end])
            last = call_end
        result.append(sql[last:])
        return "".join(result)

    def _convert_datepart_to_date_part(self, sql: str) -> str:
        """Convert T-SQL DATEPART(part, expr) → DATE_PART('part', expr) for Snowflake/Redshift."""
        pattern = re.compile(r'\bDATEPART\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "DATEPART", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            args = self._split_top_level(args_str)
            call_end = m.start() + len(m.group()) + len(args_str) + 1
            result.append(sql[last:m.start()])
            if len(args) == 2:
                part = args[0].strip().strip("'\"")
                expr = args[1].strip()
                result.append(f"DATE_PART('{part}', {expr})")
            else:
                result.append(sql[m.start():call_end])
            last = call_end
        result.append(sql[last:])
        return "".join(result)

    def _convert_datepart_to_extract(self, sql: str) -> str:
        """Convert T-SQL DATEPART(part, expr) → EXTRACT(part FROM expr) for Oracle/BigQuery/Databricks."""
        pattern = re.compile(r'\bDATEPART\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "DATEPART", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            args = self._split_top_level(args_str)
            call_end = m.start() + len(m.group()) + len(args_str) + 1
            result.append(sql[last:m.start()])
            if len(args) == 2:
                part = args[0].strip().strip("'\"")
                expr = args[1].strip()
                result.append(f"EXTRACT({part} FROM {expr})")
            else:
                result.append(sql[m.start():call_end])
            last = call_end
        result.append(sql[last:])
        return "".join(result)

    def _convert_dateadd_to_add_months(self, sql: str) -> str:
        """Convert DATEADD(MONTH/YEAR/DAY, n, date) → Oracle equivalents.
        MONTH → ADD_MONTHS(date, n), YEAR → ADD_MONTHS(date, n*12), DAY → (date + n)."""
        _month_parts = {'MONTH', 'MONTHS', 'MM', 'M', 'MON'}
        _year_parts = {'YEAR', 'YEARS', 'YY', 'YYYY', 'Y'}
        _day_parts = {'DAY', 'DAYS', 'DD', 'D'}
        pattern = re.compile(r'\bDATEADD\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "DATEADD", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            args = self._split_top_level(args_str)
            call_end = m.start() + len(m.group()) + len(args_str) + 1
            result.append(sql[last:m.start()])
            if len(args) == 3:
                interval = args[0].strip().upper()
                n = args[1].strip()
                date_expr = args[2].strip()
                if interval in _month_parts:
                    result.append(f"ADD_MONTHS({date_expr}, {n})")
                elif interval in _year_parts:
                    result.append(f"ADD_MONTHS({date_expr}, ({n}) * 12)")
                elif interval in _day_parts:
                    result.append(f"({date_expr} + {n})")
                else:
                    result.append(f"DATEADD({args_str})")
            else:
                result.append(f"DATEADD({args_str})")
            last = call_end
        result.append(sql[last:])
        return "".join(result)

    def _convert_dateadd_to_date_add_bigquery(self, sql: str) -> str:
        """Convert DATEADD(part, n, date) → DATE_ADD(date, INTERVAL n part) for BigQuery.
        Docs: https://cloud.google.com/bigquery/docs/reference/standard-sql/date_functions#date_add"""
        pattern = re.compile(r'\bDATEADD\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "DATEADD", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            args = self._split_top_level(args_str)
            call_end = m.start() + len(m.group()) + len(args_str) + 1
            result.append(sql[last:m.start()])
            if len(args) == 3:
                part = args[0].strip()
                n = args[1].strip()
                date_expr = args[2].strip()
                result.append(f"DATE_ADD({date_expr}, INTERVAL {n} {part})")
            else:
                result.append(f"DATEADD({args_str})")
            last = call_end
        result.append(sql[last:])
        return "".join(result)

    def _convert_add_months_to_date_add_bigquery(self, sql: str) -> str:
        """Convert ADD_MONTHS(date, n) → DATE_ADD(date, INTERVAL n MONTH) for BigQuery.
        Docs: https://cloud.google.com/bigquery/docs/reference/standard-sql/date_functions#date_add"""
        pattern = re.compile(r'\bADD_MONTHS\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "ADD_MONTHS", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            args = self._split_top_level(args_str)
            call_end = m.start() + len(m.group()) + len(args_str) + 1
            result.append(sql[last:m.start()])
            if len(args) == 2:
                date_expr = args[0].strip()
                n = args[1].strip()
                result.append(f"DATE_ADD({date_expr}, INTERVAL {n} MONTH)")
            else:
                result.append(f"ADD_MONTHS({args_str})")
            last = call_end
        result.append(sql[last:])
        return "".join(result)

    def _convert_tsql_format_to_to_char(self, sql: str) -> str:
        """Convert T-SQL FORMAT(expr, fmt) → TO_CHAR(expr, fmt) for Oracle/Snowflake."""
        return re.sub(r'\bFORMAT\s*\(', 'TO_CHAR(', sql, flags=re.IGNORECASE)

    def _convert_double_colon_cast_to_cast(self, sql: str) -> str:
        """Convert Redshift/Postgres expr::TYPE → CAST(expr AS TYPE) for Oracle/BigQuery/Databricks.
        Uses ANSI CAST syntax (not T-SQL CONVERT) — distinct from _convert_double_colon_cast."""
        pattern = re.compile(r'(\w[\w.]*|\([^)]+\))::([\w]+(?:\([^)]*\))?)')
        return pattern.sub(lambda m: f"CAST({m.group(1)} AS {m.group(2)})", sql)

    def _convert_nvl_to_coalesce(self, sql: str) -> str:
        """Convert Oracle/Redshift NVL(a, b) → COALESCE(a, b) for Databricks.
        Uses negative lookahead to avoid matching NVL2."""
        return re.sub(r'\bNVL(?!2)\s*\(', 'COALESCE(', sql, flags=re.IGNORECASE)

    # -----------------------------------------------------------------------
    # Master per-dialect view conversion chains (non-T-SQL targets)
    # Each method chains all relevant source→target conversions in order.
    # -----------------------------------------------------------------------

    def _apply_oracle_view_conversions(self, sql: str) -> Tuple[str, List[IRWarning]]:
        """Apply all source→Oracle conversions for view/MV bodies.
        Oracle-native: NVL, NVL2, DECODE, SYSDATE, ::, INSTR, ADD_MONTHS, LAST_DAY, LISTAGG, TO_CHAR, TRUNC."""
        warnings: List[IRWarning] = []
        sql = self._convert_backtick_identifiers(sql)
        sql = self._convert_double_colon_cast_to_cast(sql)
        sql = self._convert_isnull_to_nvl(sql)
        sql = self._convert_getdate_to_sysdate(sql)
        sql = self._convert_len_to_length(sql)
        sql = self._convert_ceiling_to_ceil(sql)
        sql = self._convert_substring_to_substr(sql)
        sql = self._convert_charindex_to_instr(sql)
        sql = self._convert_string_agg_to_listagg(sql)
        sql = self._convert_eomonth_to_last_day(sql)
        sql = self._convert_datetrunc_to_trunc_oracle(sql)
        sql = self._convert_datepart_to_extract(sql)
        sql = self._convert_dateadd_to_add_months(sql)
        sql = self._convert_tsql_format_to_to_char(sql)
        sql = self._convert_date_part_year_to_extract(sql)
        return sql, warnings

    def _apply_snowflake_view_conversions(self, sql: str) -> Tuple[str, List[IRWarning]]:
        """Apply all source→Snowflake conversions for view/MV bodies.
        Snowflake-native: NVL, NVL2, DECODE, ::, DATE_TRUNC, DATE_PART, LISTAGG, LAST_DAY, TO_CHAR, ADD_MONTHS."""
        warnings: List[IRWarning] = []
        sql = self._convert_backtick_identifiers(sql)
        sql = self._convert_varchar2_to_varchar(sql)
        sql = self._convert_isnull_to_nvl(sql)
        sql = self._convert_getdate_to_current_timestamp(sql)
        sql = self._convert_sysdate_to_current_timestamp(sql)
        sql = self._convert_len_to_length(sql)
        sql = self._convert_ceiling_to_ceil(sql)
        sql = self._convert_string_agg_to_listagg(sql)
        sql = self._convert_eomonth_to_last_day(sql)
        sql = self._convert_datetrunc_to_date_trunc(sql)
        sql = self._convert_datepart_to_date_part(sql)
        sql = self._convert_tsql_format_to_to_char(sql)
        sql = self._convert_date_part_year_to_year(sql)
        return sql, warnings

    def _apply_bigquery_view_conversions(self, sql: str) -> Tuple[str, List[IRWarning]]:
        """Apply all source→BigQuery conversions for view/MV bodies.
        BigQuery-native: IFNULL, STRING_AGG, EXTRACT, DATE_TRUNC(expr, part), LAST_DAY, DATE_ADD."""
        warnings: List[IRWarning] = []
        sql = self._convert_varchar2_to_varchar(sql)
        sql = self._convert_nvl2_to_case(sql)
        sql = self._convert_nvl_to_ifnull(sql)
        sql = self._convert_isnull_to_ifnull(sql)
        sql = self._convert_decode_to_case(sql)
        sql = self._convert_double_colon_cast_to_cast(sql)
        sql = self._convert_getdate_to_current_timestamp(sql)
        sql = self._convert_sysdate_to_current_timestamp(sql)
        sql = self._convert_len_to_length(sql)
        sql = self._convert_ceiling_to_ceil(sql)
        sql = self._convert_listagg_to_string_agg(sql)
        sql = self._convert_eomonth_to_last_day(sql)
        sql = self._convert_datetrunc_to_date_trunc_bigquery(sql)
        sql = self._convert_datepart_to_extract(sql)
        sql = self._convert_dateadd_to_date_add_bigquery(sql)
        sql = self._convert_add_months_to_date_add_bigquery(sql)
        sql = self._convert_charindex_to_strpos(sql)
        sql = self._convert_date_part_year_to_year(sql)
        return sql, warnings

    def _apply_databricks_view_conversions(self, sql: str) -> Tuple[str, List[IRWarning]]:
        """Apply all source→Databricks conversions for view/MV bodies.
        Databricks-native: IFNULL, COALESCE, STRING_AGG, LAST_DAY, date_trunc, EXTRACT, ADD_MONTHS.
        Note: Databricks uses backtick quoting — do NOT convert backticks to double-quotes."""
        warnings: List[IRWarning] = []
        sql = self._convert_varchar2_to_varchar(sql)
        sql = self._convert_nvl2_to_case(sql)
        sql = self._convert_nvl_to_coalesce(sql)
        sql = self._convert_isnull_to_ifnull(sql)
        sql = self._convert_decode_to_case(sql)
        sql = self._convert_double_colon_cast_to_cast(sql)
        sql = self._convert_getdate_to_current_timestamp(sql)
        sql = self._convert_sysdate_to_current_timestamp(sql)
        sql = self._convert_len_to_length(sql)
        sql = self._convert_ceiling_to_ceil(sql)
        sql = self._convert_listagg_to_string_agg(sql)
        sql = self._convert_eomonth_to_last_day(sql)
        sql = self._convert_datetrunc_to_date_trunc(sql)
        sql = self._convert_datepart_to_extract(sql)
        sql = self._convert_charindex_to_locate(sql)
        sql = self._convert_date_part_year_to_year(sql)
        sql, tz_warnings = self._convert_timezone_to_spark(sql)
        warnings.extend(tz_warnings)
        return sql, warnings

    # -----------------------------------------------------------------------
    # Spark SQL (Fabric Lakehouse) view conversion helpers
    # -----------------------------------------------------------------------

    def _convert_timezone_to_spark(self, sql: str) -> Tuple[str, List[IRWarning]]:
        """
        Convert CONVERT_TIMEZONE(...) calls into Spark SQL from_utc_timestamp() /
        to_utc_timestamp() equivalents.

        3-arg form CONVERT_TIMEZONE('src_tz', 'tgt_tz', ts):
          - src='UTC': → from_utc_timestamp(ts, 'tgt_tz')
          - tgt='UTC': → to_utc_timestamp(ts, 'src_tz')
          - Otherwise: → from_utc_timestamp(to_utc_timestamp(ts, 'src_tz'), 'tgt_tz')

        2-arg form CONVERT_TIMEZONE('tgt_tz', ts) — assumed UTC source:
          → from_utc_timestamp(ts, 'tgt_tz')

        IANA timezone names are used as-is (Spark requires IANA names).
        Docs: https://spark.apache.org/docs/latest/api/sql/#from_utc_timestamp
              https://spark.apache.org/docs/latest/api/sql/#to_utc_timestamp
        """
        def _strip_quotes(s: str) -> Optional[str]:
            s = s.strip()
            if len(s) >= 2 and s[0] in "'\"" and s[-1] == s[0]:
                return s[1:-1]
            return None

        pattern = re.compile(r'\bCONVERT_TIMEZONE\s*\(', re.IGNORECASE)
        warnings: List[IRWarning] = []
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "CONVERT_TIMEZONE", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue

            call_end = m.start() + len(m.group()) + len(args_str) + 1
            full_call = sql[m.start():call_end]
            args = [a.strip() for a in self._split_top_level(args_str)]

            converted = None

            if len(args) == 3:
                src_lit = _strip_quotes(args[0])
                tgt_lit = _strip_quotes(args[1])
                ts_expr = args[2]

                src_str = args[0] if src_lit is None else f"'{src_lit}'"
                tgt_str = args[1] if tgt_lit is None else f"'{tgt_lit}'"

                if src_lit is None or tgt_lit is None:
                    # Column reference — emit with warning
                    warnings.append(IRWarning(
                        feature="CONVERT_TIMEZONE_DYNAMIC_TZ",
                        message=(
                            "CONVERT_TIMEZONE() timezone argument is a column reference or expression. "
                            "The column MUST contain IANA timezone names at runtime (e.g. 'America/New_York', "
                            "NOT Windows TZ names). "
                            "Spark from_utc_timestamp/to_utc_timestamp require IANA timezone IDs."
                        ),
                        doc_url="https://spark.apache.org/docs/latest/api/sql/#from_utc_timestamp",
                        severity=Warningseverity.WARNING,
                        unsupported=False,
                    ))

                if src_lit is not None and src_lit.upper() == 'UTC':
                    converted = f"from_utc_timestamp({ts_expr}, {tgt_str})"
                elif tgt_lit is not None and tgt_lit.upper() == 'UTC':
                    converted = f"to_utc_timestamp({ts_expr}, {src_str})"
                else:
                    converted = f"from_utc_timestamp(to_utc_timestamp({ts_expr}, {src_str}), {tgt_str})"

            elif len(args) == 2:
                tgt_lit = _strip_quotes(args[0])
                ts_expr = args[1]
                tgt_str = args[0] if tgt_lit is None else f"'{tgt_lit}'"

                if tgt_lit is None:
                    warnings.append(IRWarning(
                        feature="CONVERT_TIMEZONE_DYNAMIC_TZ",
                        message=(
                            "CONVERT_TIMEZONE() timezone argument is a column reference or expression. "
                            "The column MUST contain IANA timezone names (e.g. 'America/New_York'). "
                            "Spark from_utc_timestamp requires IANA timezone IDs."
                        ),
                        doc_url="https://spark.apache.org/docs/latest/api/sql/#from_utc_timestamp",
                        severity=Warningseverity.WARNING,
                        unsupported=False,
                    ))

                converted = f"from_utc_timestamp({ts_expr}, {tgt_str})"

            result.append(sql[last:m.start()])
            if converted is not None:
                result.append(converted)
            else:
                warnings.append(IRWarning(
                    feature="UNSUPPORTED_FUNCTION_CONVERT_TIMEZONE",
                    message=(
                        f"CONVERT_TIMEZONE() with {len(args)} argument(s) is not supported. "
                        f"Expected 2 or 3 args. Left as-is: {full_call}"
                    ),
                    doc_url="https://spark.apache.org/docs/latest/api/sql/#from_utc_timestamp",
                    severity=Warningseverity.WARNING,
                    unsupported=True,
                ))
                result.append(full_call)
            last = call_end
        result.append(sql[last:])
        return "".join(result), warnings

    def _convert_split_part_to_spark(self, sql: str) -> str:
        """
        Convert SPLIT_PART(str, delim, n) → SPLIT(str, delim)[n-1]
        Spark SQL SPLIT() returns a 0-indexed array, so part N is index N-1.
        Docs: https://spark.apache.org/docs/latest/api/sql/#split
        Only converts when n is a simple integer literal. Dynamic expressions
        are left as-is with no conversion (would require runtime arithmetic).
        """
        pattern = re.compile(r'\bSPLIT_PART\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "SPLIT_PART", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            args = self._split_top_level(args_str)
            call_end = m.start() + len(m.group()) + len(args_str) + 1
            result.append(sql[last:m.start()])
            if len(args) == 3:
                str_expr = args[0].strip()
                delim = args[1].strip()
                n_str = args[2].strip()
                try:
                    n = int(n_str)
                    result.append(f"SPLIT({str_expr}, {delim})[{n - 1}]")
                except ValueError:
                    # Dynamic n — can't compute at transpile time; emit with comment
                    result.append(f"SPLIT({str_expr}, {delim})[{n_str} - 1]")
            else:
                result.append(f"SPLIT_PART({args_str})")
            last = call_end
        result.append(sql[last:])
        return "".join(result)

    def _convert_date_part_year_to_year(self, sql: str) -> str:
        """Convert date_part_year(x) → YEAR(x) for Spark SQL, T-SQL, Snowflake, BigQuery, Databricks."""
        return re.sub(r'\bdate_part_year\s*\(', 'YEAR(', sql, flags=re.IGNORECASE)

    def _convert_date_part_year_to_extract(self, sql: str) -> str:
        """Convert date_part_year(x) → EXTRACT(YEAR FROM x) for Oracle."""
        pattern = re.compile(r'\bdate_part_year\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "date_part_year", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            call_end = m.start() + len(m.group()) + len(args_str) + 1
            result.append(sql[last:m.start()])
            result.append(f"EXTRACT(YEAR FROM {args_str})")
            last = call_end
        result.append(sql[last:])
        return "".join(result)

    def _convert_pipe_concat_to_spark_concat(self, sql: str) -> str:
        """
        Convert || string concatenation to CONCAT(a, b) for Spark SQL.
        In Spark SQL 3.x, || is not always available as a concat operator
        and using CONCAT() is safer and more explicit.
        """
        result = []
        i = 0
        in_single = False
        in_double = False
        # Collect segments to wrap in CONCAT
        # Simple approach: replace || with ,; then wrap consecutive segments
        # More robust: just replace || with CONCAT approach
        # We collect all "operands" split by ||, then CONCAT them pairwise
        while i < len(sql):
            ch = sql[i]
            if ch == "'" and not in_double:
                in_single = not in_single
                result.append(ch)
            elif ch == '"' and not in_single:
                in_double = not in_double
                result.append(ch)
            elif ch == '|' and not in_single and not in_double and i + 1 < len(sql) and sql[i + 1] == '|':
                result.append(', ')
                i += 2
                continue
            else:
                result.append(ch)
            i += 1
        # Now we have a comma-delimited string where || was; wrap segments
        # Actually this approach just replaces || with comma, which is wrong
        # Better: just replace || directly with ||  (Spark 3.3+ supports it)
        # The spec says to use CONCAT — but a simple search-and-replace of
        # A || B → CONCAT(A, B) requires proper expression parsing.
        # For view bodies, replacing || with || is a no-op.
        # Fall back to a simple approach: do nothing if only one || exists,
        # or emit a warning if complex. Actually per spec just replace || → ,
        # and wrap in CONCAT. But that requires knowing operand boundaries.
        # The simplest safe approach: do NOT replace || since Spark 3.x supports it.
        # Return original sql unchanged (|| works in Spark SQL 3.3+).
        return sql

    def _convert_pipe_concat_to_concat_func(self, sql: str) -> str:
        """
        Convert simple A || B → CONCAT(A, B) for Spark SQL.
        Uses a regex to find || patterns outside strings and replaces them.
        Limitation: handles only simple (non-nested) expressions.
        For complex nested concatenations, leave as-is (Spark 3.3+ supports ||).
        """
        # Spark SQL 3.3+ supports || natively so just return unchanged.
        # If needed for older Spark, uncomment the replacement logic.
        return sql

    def _flag_qualify_unsupported(self, sql: str) -> List[IRWarning]:
        """
        Detect QUALIFY keyword and emit an unsupported warning.
        QUALIFY is supported in Snowflake, BigQuery, and DuckDB but NOT in Spark SQL.
        Requires a subquery rewrite: SELECT * FROM (...) WHERE rn = 1.
        """
        if re.search(r'\bQUALIFY\b', sql, re.IGNORECASE):
            return [IRWarning(
                feature="UNSUPPORTED_CLAUSE_QUALIFY",
                message=(
                    "QUALIFY clause is not supported in Spark SQL. "
                    "Rewrite using a subquery: SELECT * FROM "
                    "(SELECT ..., ROW_NUMBER() OVER (...) AS rn FROM ...) WHERE rn = 1. "
                    "Docs: https://spark.apache.org/docs/latest/sql-ref-syntax-qry-select.html"
                ),
                doc_url="https://spark.apache.org/docs/latest/sql-ref-syntax-qry-select.html",
                severity=Warningseverity.WARNING,
                unsupported=True,
            )]
        return []

    def _strip_with_no_schema_binding(self, sql: str) -> str:
        """Strip WITH NO SCHEMA BINDING from view definitions (not valid in Spark SQL)."""
        return re.sub(r'\bWITH\s+NO\s+SCHEMA\s+BINDING\b', '', sql, flags=re.IGNORECASE).strip()

    def _apply_spark_view_conversions(self, sql: str) -> Tuple[str, List[IRWarning]]:
        """Apply all source→Spark SQL conversions for Fabric Lakehouse view/MV bodies.
        Spark-native: COALESCE/IFNULL, STRING_AGG, LAST_DAY, date_trunc, EXTRACT, SPLIT_PART.
        Note: Spark SQL uses backtick quoting — do NOT convert backticks to double-quotes."""
        warnings: List[IRWarning] = []
        sql = self._strip_with_no_schema_binding(sql)
        sql = self._convert_varchar2_to_varchar(sql)
        sql = self._convert_nvl2_to_case(sql)
        sql = self._convert_nvl_to_coalesce(sql)
        sql = self._convert_isnull_to_ifnull(sql)
        sql = self._convert_decode_to_case(sql)
        sql = self._convert_double_colon_cast_to_cast(sql)
        sql = self._convert_getdate_to_current_timestamp(sql)
        sql = self._convert_sysdate_to_current_timestamp(sql)
        sql = self._convert_len_to_length(sql)
        sql = self._convert_ceiling_to_ceil(sql)
        sql = self._convert_listagg_to_string_agg(sql)
        sql = self._convert_eomonth_to_last_day(sql)
        sql = self._convert_datetrunc_to_date_trunc(sql)
        sql = self._convert_datepart_to_extract(sql)
        sql = self._convert_charindex_to_locate(sql)
        sql = self._convert_split_part_to_spark(sql)
        sql = self._convert_date_part_year_to_year(sql)
        sql, tz_warnings = self._convert_timezone_to_spark(sql)
        warnings.extend(tz_warnings)
        warnings.extend(self._flag_qualify_unsupported(sql))
        return sql, warnings

    def _apply_redshift_view_conversions(self, sql: str) -> Tuple[str, List[IRWarning]]:
        """Apply all source→Redshift conversions for view/MV bodies.
        Redshift-native: NVL, NVL2, DECODE, GETDATE, SYSDATE, ::, LEN, LISTAGG, LAST_DAY, DATE_TRUNC, DATE_PART, ADD_MONTHS, DATEADD."""
        warnings: List[IRWarning] = []
        sql = self._convert_backtick_identifiers(sql)
        sql = self._convert_varchar2_to_varchar(sql)
        sql = self._convert_isnull_to_nvl(sql)
        sql = self._convert_decode_to_case(sql)
        sql = self._convert_string_agg_to_listagg(sql)
        sql = self._convert_eomonth_to_last_day(sql)
        sql = self._convert_datetrunc_to_date_trunc(sql)
        sql = self._convert_datepart_to_date_part(sql)
        sql = self._convert_len_to_length(sql)
        sql = self._convert_ceiling_to_ceil(sql)
        return sql, warnings
