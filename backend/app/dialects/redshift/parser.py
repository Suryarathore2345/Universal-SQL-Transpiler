"""
Redshift SQL parser — converts Redshift DDL to IR.

Official docs used:
  CREATE TABLE: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html
  Data types:   https://docs.aws.amazon.com/redshift/latest/dg/c_Supported_data_types.html
  DISTSTYLE:    https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html#r_CREATE_TABLE_NEW-parameters-distkey
  SORTKEY:      https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html#r_CREATE_TABLE_NEW-parameters-sortkey
  CREATE VIEW:  https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_VIEW.html
  CREATE MV:    https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_MATERIALIZED_VIEW.html
  IDENTITY:     https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html
"""
from __future__ import annotations

import re
from typing import Dict, List, Optional, Tuple

import sqlglot
import sqlglot.expressions as exp

from app.dialects.base import DialectParser
from app.ir.models import (
    Dialect, DistributionStyle, GenericType, IRAlterTable, IRCheckConstraint,
    IRClusterBy, IRColumn, IRDataType, IRDDLObject, IRDistribution,
    IRForeignKey, IRIdentity, IRMaterializedView, IRPrimaryKey, IRSortKey,
    IRTable, IRUniqueConstraint, IRView, IRWarning, IRDocReference,
    RefreshType, SortKeyType, Warningseverity, GeneratedType, IRProcedure, IRFunction,
)


class RedshiftParser(DialectParser):
    """
    Parses Redshift SQL DDL into IR using sqlglot + custom post-processing
    for Redshift-specific constructs (DISTSTYLE, SORTKEY, IDENTITY, SUPER, etc.).
    """

    dialect = Dialect.REDSHIFT

    # Redshift uses sqlglot dialect "redshift"
    _SQLGLOT_DIALECT = "redshift"

    def parse_statement(
        self, sql: str
    ) -> Tuple[Optional[IRDDLObject], List[IRWarning], List[IRDocReference]]:
        warnings: List[IRWarning] = []
        doc_refs: List[IRDocReference] = []

        # Detect statement type from leading keywords
        sql_upper = sql.strip().upper()

        try:
            parsed = sqlglot.parse_one(sql, dialect=self._SQLGLOT_DIALECT, error_level=sqlglot.ErrorLevel.WARN)
        except Exception as e:
            warnings.append(IRWarning(
                feature="PARSE_ERROR",
                message=f"sqlglot could not parse statement: {e}",
                severity=Warningseverity.ERROR,
            ))
            return None, warnings, doc_refs

        if parsed is None:
            return None, warnings, doc_refs

        if isinstance(parsed, exp.Create):
            kind = parsed.args.get("kind", "").upper()
            # sqlglot represents CREATE MATERIALIZED VIEW as kind="VIEW" + MaterializedProperty
            is_mv = (
                kind == "MATERIALIZED VIEW"
                or any(isinstance(p, exp.MaterializedProperty)
                       for p in (parsed.find_all(exp.MaterializedProperty)))
            )
            if kind == "TABLE":
                result, w, d = self._parse_create_table(parsed, sql)
                return result, warnings + w, doc_refs + d
            elif is_mv:
                result, w, d = self._parse_create_mv(parsed, sql)
                return result, warnings + w, doc_refs + d
            elif kind == "VIEW":
                result, w, d = self._parse_create_view(parsed, sql)
                return result, warnings + w, doc_refs + d
            elif kind == "PROCEDURE":
                r, w, d = self._parse_proc_from_sql(sql, body_style="dollar")
                doc_refs.append(IRDocReference(title="Redshift CREATE PROCEDURE", url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_PROCEDURE.html", platform="redshift", purpose="Stored procedure"))
                return r, warnings + w, doc_refs + d
            elif kind == "FUNCTION":
                r, w, d = self._parse_func_from_sql(sql, body_style="dollar")
                doc_refs.append(IRDocReference(title="Redshift CREATE FUNCTION", url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_FUNCTION.html", platform="redshift", purpose="UDF"))
                return r, warnings + w, doc_refs + d

        # sqlglot fell back to Command — try regex-based detection
        if isinstance(parsed, exp.Command) or True:
            sql_u = sql.strip().upper()
            if re.search(r'\bCREATE\b.*?\bPROCEDURE\b', sql, re.IGNORECASE | re.DOTALL):
                r, w, d = self._parse_proc_from_sql(sql, body_style="dollar")
                return r, warnings + w, d
            if re.search(r'\bCREATE\b.*?\bFUNCTION\b', sql, re.IGNORECASE | re.DOTALL):
                r, w, d = self._parse_func_from_sql(sql, body_style="dollar")
                return r, warnings + w, d

        warnings.append(IRWarning(
            feature="UNSUPPORTED_STATEMENT",
            message=f"Statement type not yet supported: {type(parsed).__name__}",
            severity=Warningseverity.WARNING,
        ))
        return None, warnings, doc_refs

    # -------------------------------------------------------------------------
    # CREATE TABLE
    # -------------------------------------------------------------------------

    def _parse_create_table(
        self, node: exp.Create, raw_sql: str
    ) -> Tuple[Optional[IRTable], List[IRWarning], List[IRDocReference]]:
        warnings: List[IRWarning] = []
        doc_refs = [IRDocReference(
            title="Redshift CREATE TABLE",
            url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html",
            platform="redshift",
            purpose="CREATE TABLE syntax reference",
        )]

        table_node = node.find(exp.Table)
        table_name = table_node.name if table_node else "unknown"
        schema_name = table_node.db if table_node else None
        db_name = table_node.catalog if table_node else None

        is_temp = bool(node.args.get("temporary"))

        columns: List[IRColumn] = []
        pk: Optional[IRPrimaryKey] = None
        fks: List[IRForeignKey] = []
        uniques: List[IRUniqueConstraint] = []
        checks: List[IRCheckConstraint] = []

        schema_expr = node.args.get("this")
        if schema_expr and hasattr(schema_expr, "expressions"):
            for expr in schema_expr.expressions:
                if isinstance(expr, exp.ColumnDef):
                    col, w, d = self._parse_column_def(expr)
                    columns.append(col)
                    warnings.extend(w)
                    doc_refs.extend(d)
                elif isinstance(expr, exp.PrimaryKey):
                    pk = IRPrimaryKey(
                        columns=[c.name for c in expr.expressions],
                        not_enforced=True,  # Redshift PKs are not enforced
                    )
                elif isinstance(expr, exp.ForeignKey):
                    fks.append(self._parse_fk(expr))
                elif isinstance(expr, exp.UniqueColumnConstraint):
                    uniques.append(IRUniqueConstraint(
                        columns=[c.name for c in expr.expressions],
                        not_enforced=True,
                    ))
                elif isinstance(expr, exp.CheckColumnConstraint):
                    checks.append(IRCheckConstraint(expression=expr.this.sql()))

        # Parse Redshift-specific properties from raw SQL (sqlglot doesn't fully parse these)
        distribution, w1, d1 = self._extract_distribution(raw_sql)
        sort_key, w2, d2 = self._extract_sortkey(raw_sql)
        warnings.extend(w1 + w2)
        doc_refs.extend(d1 + d2)

        table = IRTable(
            name=table_name,
            schema_name=schema_name or None,
            database_name=db_name or None,
            columns=columns,
            primary_key=pk,
            foreign_keys=fks,
            unique_constraints=uniques,
            check_constraints=checks,
            is_temporary=is_temp,
            distribution=distribution,
            sort_key=sort_key,
        )
        return table, warnings, doc_refs

    def _parse_column_def(
        self, col_def: exp.ColumnDef
    ) -> Tuple[IRColumn, List[IRWarning], List[IRDocReference]]:
        warnings: List[IRWarning] = []
        doc_refs: List[IRDocReference] = []

        name = col_def.name
        type_node = col_def.args.get("kind")
        type_str = type_node.sql("redshift") if type_node else "VARCHAR"

        ir_type, w, d = self._parse_data_type(type_str)
        warnings.extend(w)
        doc_refs.extend(d)

        is_nullable = True
        default_val = None
        identity: Optional[IRIdentity] = None
        encoding = None
        comment = None

        for constraint in col_def.constraints:
            c = constraint.kind if hasattr(constraint, "kind") else constraint
            if isinstance(c, exp.NotNullColumnConstraint):
                is_nullable = False
            elif isinstance(c, exp.DefaultColumnConstraint):
                default_val = c.this.sql() if c.this else None
            elif isinstance(c, exp.GeneratedAsIdentityColumnConstraint):
                # IDENTITY(seed, step) — Redshift docs:
                # https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html
                doc_refs.append(IRDocReference(
                    title="Redshift IDENTITY column",
                    url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html",
                    platform="redshift",
                    purpose="IDENTITY(seed, step) syntax",
                ))
                start = 1
                step = 1
                s = c.args.get("start")
                if s is not None:
                    try:
                        start = int(str(s.this if hasattr(s, "this") else s))
                    except Exception:
                        pass
                inc = c.args.get("increment")
                if inc is not None:
                    try:
                        step = int(str(inc.this if hasattr(inc, "this") else inc))
                    except Exception:
                        pass
                identity = IRIdentity(start=start, increment=step)
            elif isinstance(constraint, exp.ColumnConstraint) and hasattr(constraint, "kind"):
                kind_sql = constraint.sql("redshift").upper()
                if "ENCODE" in kind_sql:
                    enc_match = re.search(r"ENCODE\s+(\w+)", kind_sql)
                    if enc_match:
                        encoding = enc_match.group(1)

        return IRColumn(
            name=name,
            data_type=ir_type,
            is_nullable=is_nullable,
            default_value=default_val,
            identity=identity,
            encoding=encoding,
            comment=comment,
        ), warnings, doc_refs

    def _parse_fk(self, fk_node: exp.ForeignKey) -> IRForeignKey:
        cols = [c.name for c in fk_node.expressions]
        ref = fk_node.args.get("reference")
        ref_this = ref.this if ref else None

        # ref.this can be a Table, Schema, or Column node depending on how
        # sqlglot parses the reference.  Use .name for the table name and
        # .db (only on Table) for the schema — guard against missing attrs.
        if ref_this is not None:
            ref_table = getattr(ref_this, "name", None) or "unknown"
            ref_schema = getattr(ref_this, "db", None) or None
        else:
            ref_table = "unknown"
            ref_schema = None

        ref_cols = [c.name for c in ref.expressions] if ref else []
        return IRForeignKey(
            columns=cols,
            ref_table=ref_table,
            ref_schema=ref_schema,
            ref_columns=ref_cols,
            not_enforced=True,  # Redshift FK constraints are not enforced
        )

    # -------------------------------------------------------------------------
    # Redshift-specific clause extraction (regex fallback for what sqlglot misses)
    # Docs: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html
    # -------------------------------------------------------------------------

    def _extract_distribution(
        self, sql: str
    ) -> Tuple[Optional[IRDistribution], List[IRWarning], List[IRDocReference]]:
        """
        Extract DISTSTYLE / DISTKEY from Redshift DDL.
        Redshift docs: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html
        """
        sql_u = sql.upper()
        doc_refs = [IRDocReference(
            title="Redshift DISTSTYLE/DISTKEY",
            url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html",
            platform="redshift",
            purpose="Distribution key extraction",
        )]

        # DISTSTYLE KEY / EVEN / ALL / AUTO
        m = re.search(r"DISTSTYLE\s+(KEY|EVEN|ALL|AUTO)", sql_u)
        if m:
            style_map = {
                "KEY": DistributionStyle.HASH,
                "EVEN": DistributionStyle.ROUND_ROBIN,
                "ALL": DistributionStyle.REPLICATE,
                "AUTO": DistributionStyle.AUTO,
            }
            style = style_map.get(m.group(1), DistributionStyle.ROUND_ROBIN)
            key_cols = []
            # DISTKEY(col) or column-level DISTKEY
            dk = re.search(r"DISTKEY\s*\(\s*(\w+)\s*\)", sql_u)
            if not dk:
                dk = re.search(r"(\w+)\s+\w+.*?DISTKEY", sql_u)
            if dk:
                key_cols = [dk.group(1)]
            return IRDistribution(style=style, key_columns=key_cols), [], doc_refs

        # Inline DISTKEY on column
        dk = re.search(r"(\w+)\s+\w[\w\s(),]*\bDISTKEY\b", sql_u)
        if dk:
            return IRDistribution(
                style=DistributionStyle.HASH,
                key_columns=[dk.group(1)],
            ), [], doc_refs

        return None, [], []

    def _extract_sortkey(
        self, sql: str
    ) -> Tuple[Optional[IRSortKey], List[IRWarning], List[IRDocReference]]:
        """
        Extract SORTKEY / INTERLEAVED SORTKEY from Redshift DDL.
        Column names are preserved in their original case (not uppercased).

        Redshift docs: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html
        """
        doc_refs = [IRDocReference(
            title="Redshift SORTKEY",
            url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html",
            platform="redshift",
            purpose="Sort key extraction",
        )]

        # Detect INTERLEAVED from original SQL (case-insensitive check)
        interleaved = bool(re.search(r'\bINTERLEAVED\b', sql, re.IGNORECASE))
        sort_type = SortKeyType.INTERLEAVED if interleaved else SortKeyType.COMPOUND

        # Match compound/table-level SORTKEY (col1, col2, ...) — use original case
        m = re.search(r"(?:INTERLEAVED\s+)?SORTKEY\s*\(([^)]+)\)", sql, re.IGNORECASE)
        if m:
            # Preserve original column name casing from source SQL
            cols = [c.strip() for c in m.group(1).split(",")]
            return IRSortKey(sort_type=sort_type, columns=cols), [], doc_refs

        # Column-level SORTKEY: "col_name <type> ... SORTKEY"
        # Match the column name before its type definition (not uppercased)
        m2 = re.search(r"^\s*(\w+)\s+\w[\w\s(),]*\bSORTKEY\b", sql, re.IGNORECASE | re.MULTILINE)
        if m2:
            return IRSortKey(sort_type=sort_type, columns=[m2.group(1)]), [], doc_refs

        return None, [], []

    # -------------------------------------------------------------------------
    # CREATE VIEW
    # -------------------------------------------------------------------------

    def _parse_create_view(
        self, node: exp.Create, raw_sql: str
    ) -> Tuple[Optional[IRView], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(
            title="Redshift CREATE VIEW",
            url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_VIEW.html",
            platform="redshift",
            purpose="CREATE VIEW syntax reference",
        )]

        view_name_node = node.find(exp.Table)
        name = view_name_node.name if view_name_node else "unknown"
        schema = view_name_node.db if view_name_node else None
        db = view_name_node.catalog if view_name_node else None
        or_replace = bool(node.args.get("replace"))

        # Extract SELECT body
        query = node.args.get("expression") or node.args.get("this")
        definition = query.sql(dialect="redshift") if query else ""

        # Redshift LATE BINDING VIEW — syntax: WITH NO SCHEMA BINDING
        # Docs: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_VIEW.html
        warnings = []
        if "NO SCHEMA BINDING" in raw_sql.upper() or "LATE BINDING" in raw_sql.upper():
            warnings.append(IRWarning(
                feature="LATE_BINDING_VIEW",
                message="Redshift LATE BINDING VIEW has no direct equivalent in other platforms. "
                        "The view definition is preserved; late-binding semantics will not apply.",
                doc_url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_VIEW.html",
                severity=Warningseverity.WARNING,
            ))

        view = IRView(
            name=name,
            schema_name=schema or None,
            database_name=db or None,
            definition=definition,
            or_replace=or_replace,
        )
        return view, warnings, doc_refs

    # -------------------------------------------------------------------------
    # CREATE MATERIALIZED VIEW
    # -------------------------------------------------------------------------

    def _parse_create_mv(
        self, node: exp.Create, raw_sql: str
    ) -> Tuple[Optional[IRMaterializedView], List[IRWarning], List[IRDocReference]]:
        """
        Redshift MV docs:
        https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_MATERIALIZED_VIEW.html
        """
        doc_refs = [IRDocReference(
            title="Redshift CREATE MATERIALIZED VIEW",
            url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_MATERIALIZED_VIEW.html",
            platform="redshift",
            purpose="MV syntax reference",
        )]

        mv_name_node = node.find(exp.Table)
        name = mv_name_node.name if mv_name_node else "unknown"
        schema = mv_name_node.db if mv_name_node else None

        query = node.args.get("expression") or node.args.get("this")
        definition = query.sql(dialect="redshift") if query else ""

        # AUTO REFRESH YES/NO — Redshift docs
        auto_refresh = bool(re.search(r"AUTO\s+REFRESH\s+YES", raw_sql.upper()))
        refresh_type = RefreshType.AUTO if auto_refresh else RefreshType.MANUAL

        distribution, w, d = self._extract_distribution(raw_sql)
        sort_key, w2, d2 = self._extract_sortkey(raw_sql)

        mv = IRMaterializedView(
            name=name,
            schema_name=schema or None,
            definition=definition,
            refresh_type=refresh_type,
            auto_refresh=auto_refresh,
            distribution=distribution,
        )
        return mv, w + w2, doc_refs + d + d2
