"""
SQL Server T-SQL parser — converts SQL Server DDL to IR.

Official docs used:
  CREATE TABLE:   https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql
  Data types:     https://learn.microsoft.com/en-us/sql/t-sql/data-types/data-types-transact-sql
  IDENTITY:       https://learn.microsoft.com/en-us/sql/t-sql/functions/identity-function-transact-sql
  CREATE VIEW:    https://learn.microsoft.com/en-us/sql/t-sql/statements/create-view-transact-sql
  Indexed views:  https://learn.microsoft.com/en-us/sql/relational-databases/views/create-indexed-views
"""
from __future__ import annotations

import re
from typing import List, Optional, Tuple

import sqlglot
import sqlglot.expressions as exp

from app.dialects.base import DialectParser
from app.ir.models import (
    Dialect, GeneratedType, IRCheckConstraint, IRColumn, IRDataType, IRDDLObject,
    IRDocReference, IRForeignKey, IRFunction, IRIdentity, IRMaterializedView,
    IRPrimaryKey, IRProcedure, IRTable, IRUniqueConstraint, IRView, IRWarning,
    RefreshType, Warningseverity,
)


class SQLServerParser(DialectParser):
    """
    Parses SQL Server T-SQL DDL into IR using sqlglot.
    SQL Server dialect key: 'tsql'
    """

    dialect = Dialect.SQLSERVER
    _SQLGLOT_DIALECT = "tsql"

    def parse_statement(
        self, sql: str
    ) -> Tuple[Optional[IRDDLObject], List[IRWarning], List[IRDocReference]]:
        warnings: List[IRWarning] = []
        doc_refs: List[IRDocReference] = []

        try:
            parsed = sqlglot.parse_one(sql, dialect=self._SQLGLOT_DIALECT, error_level=sqlglot.ErrorLevel.WARN)
        except Exception as e:
            warnings.append(IRWarning(feature="PARSE_ERROR", message=str(e), severity=Warningseverity.ERROR))
            return None, warnings, doc_refs

        if parsed is None:
            return None, warnings, doc_refs

        if isinstance(parsed, exp.Create):
            kind = parsed.args.get("kind", "").upper()
            is_mv = any(isinstance(p, exp.MaterializedProperty) for p in parsed.find_all(exp.MaterializedProperty))
            if kind == "TABLE":
                r, w, d = self._parse_create_table(parsed, sql)
                return r, warnings + w, doc_refs + d
            elif is_mv:
                r, w, d = self._parse_create_mv(parsed, sql)
                return r, warnings + w, doc_refs + d
            elif kind == "VIEW":
                r, w, d = self._parse_create_view(parsed, sql)
                return r, warnings + w, doc_refs + d

            elif kind == "PROCEDURE":
                r, w, d = self._parse_proc_from_sql(sql, body_style="tsql")
                doc_refs.append(IRDocReference(title="SQL Server CREATE PROCEDURE", url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql", platform="sqlserver", purpose="Stored procedure"))
                return r, warnings + w, doc_refs + d
            elif kind == "FUNCTION":
                r, w, d = self._parse_func_from_sql(sql, body_style="tsql")
                doc_refs.append(IRDocReference(title="SQL Server CREATE FUNCTION", url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql", platform="sqlserver", purpose="Function"))
                return r, warnings + w, doc_refs + d

        if re.search(r'\bCREATE\b.*?\bPROCEDURE\b', sql, re.IGNORECASE | re.DOTALL):
            r, w, d = self._parse_proc_from_sql(sql, body_style="tsql")
            return r, warnings + w, d
        if re.search(r'\bCREATE\b.*?\bFUNCTION\b', sql, re.IGNORECASE | re.DOTALL):
            r, w, d = self._parse_func_from_sql(sql, body_style="tsql")
            return r, warnings + w, d

        warnings.append(IRWarning(feature="UNSUPPORTED_STATEMENT", message=f"Not yet supported: {type(parsed).__name__}", severity=Warningseverity.WARNING))
        return None, warnings, doc_refs

    def _parse_create_table(self, node: exp.Create, raw_sql: str) -> Tuple[Optional[IRTable], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="SQL Server CREATE TABLE", url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql", platform="sqlserver", purpose="CREATE TABLE syntax")]
        warnings: List[IRWarning] = []

        tbl = node.find(exp.Table)
        name = tbl.name if tbl else "unknown"
        schema = tbl.db if tbl else None
        db = tbl.catalog if tbl else None
        is_temp = bool(node.args.get("temporary")) or name.startswith("#")

        columns, pk, fks, uniques, checks = [], None, [], [], []
        schema_expr = node.args.get("this")
        if schema_expr and hasattr(schema_expr, "expressions"):
            for expr in schema_expr.expressions:
                if isinstance(expr, exp.ColumnDef):
                    col, w, d = self._parse_column_def(expr)
                    columns.append(col); warnings.extend(w); doc_refs.extend(d)
                elif isinstance(expr, exp.PrimaryKey):
                    pk = IRPrimaryKey(columns=[c.name for c in expr.expressions])
                elif isinstance(expr, exp.ForeignKey):
                    ref = expr.args.get("reference")
                    fks.append(IRForeignKey(
                        columns=[c.name for c in expr.expressions],
                        ref_table=getattr(ref.this, "name", None) or "unknown" if ref and ref.this else "unknown",
                        ref_schema=getattr(ref.this, "db", None) if ref and ref.this else None,
                        ref_columns=[c.name for c in ref.expressions] if ref else [],
                    ))
                elif isinstance(expr, exp.UniqueColumnConstraint):
                    uniques.append(IRUniqueConstraint(columns=[c.name for c in expr.expressions]))

        return IRTable(name=name, schema_name=schema or None, database_name=db or None, columns=columns, primary_key=pk, foreign_keys=fks, unique_constraints=uniques, check_constraints=checks, is_temporary=is_temp), warnings, doc_refs

    def _parse_column_def(self, col_def: exp.ColumnDef) -> Tuple[IRColumn, List[IRWarning], List[IRDocReference]]:
        warnings, doc_refs = [], []
        name = col_def.name
        type_node = col_def.args.get("kind")
        type_str = type_node.sql("tsql") if type_node else "NVARCHAR(255)"
        ir_type, w, d = self._parse_data_type(type_str)
        warnings.extend(w); doc_refs.extend(d)

        is_nullable, default_val, identity = True, None, None
        for constraint in col_def.constraints:
            c = constraint.kind if hasattr(constraint, "kind") else constraint
            if isinstance(c, exp.NotNullColumnConstraint): is_nullable = False
            elif isinstance(c, exp.DefaultColumnConstraint): default_val = c.this.sql() if c.this else None
            elif isinstance(c, exp.GeneratedAsIdentityColumnConstraint):
                doc_refs.append(IRDocReference(title="SQL Server IDENTITY", url="https://learn.microsoft.com/en-us/sql/t-sql/functions/identity-function-transact-sql", platform="sqlserver", purpose="IDENTITY column"))
                s = c.args.get("start"); inc = c.args.get("increment")
                start = int(str(s.this if hasattr(s, "this") else s)) if s else 1
                step = int(str(inc.this if hasattr(inc, "this") else inc)) if inc else 1
                identity = IRIdentity(start=start, increment=step)

        return IRColumn(name=name, data_type=ir_type, is_nullable=is_nullable, default_value=default_val, identity=identity), warnings, doc_refs

    def _parse_create_view(self, node: exp.Create, raw_sql: str) -> Tuple[Optional[IRView], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="SQL Server CREATE VIEW", url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-view-transact-sql", platform="sqlserver", purpose="CREATE VIEW")]
        vn = node.find(exp.Table)
        name = vn.name if vn else "unknown"
        query = node.args.get("expression") or node.args.get("this")
        definition = query.sql(dialect="tsql") if query else ""
        or_replace = bool(node.args.get("replace"))
        return IRView(name=name, schema_name=(vn.db if vn else None) or None, database_name=(vn.catalog if vn else None) or None, definition=definition, or_replace=or_replace), [], doc_refs

    def _parse_create_mv(self, node: exp.Create, raw_sql: str) -> Tuple[Optional[IRMaterializedView], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="SQL Server Indexed Views (MV equivalent)", url="https://learn.microsoft.com/en-us/sql/relational-databases/views/create-indexed-views", platform="sqlserver", purpose="MV equivalent reference")]
        mn = node.find(exp.Table)
        name = mn.name if mn else "unknown"
        query = node.args.get("expression") or node.args.get("this")
        definition = query.sql(dialect="tsql") if query else ""
        return IRMaterializedView(name=name, schema_name=(mn.db if mn else None) or None, definition=definition, refresh_type=RefreshType.MANUAL), [], doc_refs
