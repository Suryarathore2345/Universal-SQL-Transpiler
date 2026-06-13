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
            if precision is not None:
                # Fabric DW max precision is 6
                max_prec = dialect_entry.get("max_precision", 9)
                effective = min(precision, max_prec)
                return f"{base_type}({effective})"

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
        Handles nested calls correctly via _count_func_args.
        Override in dialects that need NVL conversion.
        """
        pattern = re.compile(r'\bNVL\s*\(', re.IGNORECASE)
        result = []
        last = 0
        for m in pattern.finditer(sql):
            args_str = self._extract_func_args_str(sql, "NVL", m.start())
            if args_str is None:
                result.append(sql[last:m.end()])
                last = m.end()
                continue
            n_args = self._count_func_args(args_str)
            func = "ISNULL" if n_args == 2 else "COALESCE"
            result.append(sql[last:m.start()])
            result.append(f"{func}({args_str})")
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
