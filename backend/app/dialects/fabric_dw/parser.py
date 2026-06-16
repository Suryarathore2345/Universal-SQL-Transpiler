"""
Microsoft Fabric Data Warehouse (DW) T-SQL parser.

Official docs used:
  CREATE TABLE:     https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-azure-sql-data-warehouse?view=fabric
  T-SQL surface:    https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area
  Data types:       https://learn.microsoft.com/en-us/sql/t-sql/data-types/data-types-transact-sql
  CREATE VIEW:      https://learn.microsoft.com/en-us/sql/t-sql/statements/create-view-transact-sql
  Stored procs:     https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql

Key Fabric DW facts (verified June 2026):
  - Supports: views, stored procedures, functions
  - NOT supported: materialized views, triggers, xml, recursive CTEs
  - CREATE TABLE WITH (CLUSTER BY (col1[,...col4])) — max 4 columns
  - NO DISTRIBUTION clause (unlike Synapse)
  - NO INDEX clause (data stored as Delta Parquet automatically)
  - Supported types: datetime2, date, time, float, real, decimal, numeric,
    bigint, int, smallint, bit, varchar(n|MAX), char(n), varbinary, uniqueidentifier
  - NOT supported types: tinyint, money, datetime, datetimeoffset, nchar, nvarchar,
    text, image, json, xml, geography, geometry
"""
from __future__ import annotations

import re
from typing import List, Optional, Tuple

import sqlglot
import sqlglot.expressions as exp

from app.dialects.base import DialectParser
from app.ir.models import (
    Dialect, IRCheckConstraint, IRClusterBy, IRColumn, IRDataType, IRDDLObject,
    IRDocReference, IRForeignKey, IRFunction, IRIdentity, IRMaterializedView,
    IRPrimaryKey, IRProcedure, IRTable, IRUniqueConstraint, IRView, IRWarning,
    RefreshType, Warningseverity,
)


class FabricDWParser(DialectParser):
    """
    Parses Fabric DW T-SQL DDL into IR.
    Fabric DW uses tsql dialect; CLUSTER BY is extracted via regex.
    """

    dialect = Dialect.FABRIC_DW
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
                warnings.append(IRWarning(
                    feature="MV_NOT_SUPPORTED_FABRIC_DW",
                    message="Fabric DW does not support CREATE MATERIALIZED VIEW. "
                            "Parsed as a standard view. "
                            "Docs: https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area",
                    doc_url="https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area",
                    severity=Warningseverity.WARNING,
                    unsupported=True,
                ))
                r, w, d = self._parse_create_view(parsed, sql)
                return r, warnings + w, doc_refs + d
            elif kind == "VIEW":
                r, w, d = self._parse_create_view(parsed, sql)
                return r, warnings + w, doc_refs + d

            elif kind == "PROCEDURE":
                # Fabric DW supports stored procedures (verified June 2026)
                r, w, d = self._parse_proc_from_sql(sql, body_style="tsql")
                doc_refs.append(IRDocReference(title="Fabric DW CREATE PROCEDURE", url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql", platform="fabric_dw", purpose="Stored procedure"))
                return r, warnings + w, doc_refs + d
            elif kind == "FUNCTION":
                r, w, d = self._parse_func_from_sql(sql, body_style="tsql")
                return r, warnings + w, doc_refs + d

        if re.search(r'\bCREATE\b.*?\bPROCEDURE\b', sql, re.IGNORECASE | re.DOTALL):
            r, w, d = self._parse_proc_from_sql(sql, body_style="tsql")
            return r, warnings + w, d
        if re.search(r'\bCREATE\b.*?\bFUNCTION\b', sql, re.IGNORECASE | re.DOTALL):
            r, w, d = self._parse_func_from_sql(sql, body_style="tsql")
            return r, warnings + w, d

        warnings.append(IRWarning(feature="UNSUPPORTED_STATEMENT", message=f"Not supported: {type(parsed).__name__}", severity=Warningseverity.WARNING))
        return None, warnings, doc_refs

    def _parse_create_table(self, node: exp.Create, raw_sql: str) -> Tuple[Optional[IRTable], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="Fabric DW CREATE TABLE", url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-azure-sql-data-warehouse?view=fabric", platform="fabric_dw", purpose="CREATE TABLE syntax")]
        warnings: List[IRWarning] = []

        tbl = node.find(exp.Table)
        name = tbl.name if tbl else "unknown"
        schema = (tbl.db if tbl else None) or None
        db = (tbl.catalog if tbl else None) or None

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
                    ref_this = ref.this if ref else None
                    fks.append(IRForeignKey(
                        columns=[c.name for c in expr.expressions],
                        ref_table=getattr(ref_this, "name", None) or "unknown" if ref_this else "unknown",
                        ref_schema=getattr(ref_this, "db", None) if ref_this else None,
                        ref_columns=[c.name for c in ref.expressions] if ref else [],
                    ))
                elif isinstance(expr, exp.UniqueColumnConstraint):
                    uniques.append(IRUniqueConstraint(columns=[c.name for c in expr.expressions]))

        cluster_by = self._extract_cluster_by(raw_sql)
        return IRTable(name=name, schema_name=schema, database_name=db, columns=columns, primary_key=pk, foreign_keys=fks, unique_constraints=uniques, check_constraints=checks, cluster_by=cluster_by), warnings, doc_refs

    def _parse_column_def(self, col_def: exp.ColumnDef) -> Tuple[IRColumn, List[IRWarning], List[IRDocReference]]:
        warnings, doc_refs = [], []
        name = col_def.name
        type_node = col_def.args.get("kind")
        type_str = type_node.sql("tsql") if type_node else "VARCHAR(255)"
        ir_type, w, d = self._parse_data_type(type_str)
        warnings.extend(w); doc_refs.extend(d)

        is_nullable, default_val, identity = True, None, None
        for constraint in col_def.constraints:
            c = constraint.kind if hasattr(constraint, "kind") else constraint
            if isinstance(c, exp.NotNullColumnConstraint): is_nullable = False
            elif isinstance(c, exp.DefaultColumnConstraint): default_val = c.this.sql() if c.this else None
            elif isinstance(c, exp.GeneratedAsIdentityColumnConstraint):
                s = c.args.get("start"); inc = c.args.get("increment")
                start = int(str(s.this if hasattr(s, "this") else s)) if s else 1
                step = int(str(inc.this if hasattr(inc, "this") else inc)) if inc else 1
                identity = IRIdentity(start=start, increment=step)

        return IRColumn(name=name, data_type=ir_type, is_nullable=is_nullable, default_value=default_val, identity=identity), warnings, doc_refs

    def _extract_cluster_by(self, sql: str) -> Optional[IRClusterBy]:
        """
        Extract Fabric DW CLUSTER BY clause.
        Syntax: WITH (CLUSTER BY (col1[,...col4]))
        Docs: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-azure-sql-data-warehouse?view=fabric
        """
        m = re.search(r"CLUSTER\s+BY\s*\(\s*([^)]+)\s*\)", sql, re.IGNORECASE)
        if m:
            cols = [c.strip().strip('"').strip("[]") for c in m.group(1).split(",")]
            return IRClusterBy(columns=cols[:4])  # max 4 columns per docs
        return None

    def _parse_create_view(self, node: exp.Create, raw_sql: str) -> Tuple[Optional[IRView], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="Fabric DW CREATE VIEW", url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-view-transact-sql", platform="fabric_dw", purpose="CREATE VIEW")]
        vn = node.find(exp.Table)
        name = vn.name if vn else "unknown"
        query = node.args.get("expression") or node.args.get("this")
        definition = query.sql(dialect="tsql") if query else ""
        return IRView(name=name, schema_name=(vn.db if vn else None) or None, definition=definition, or_replace=bool(node.args.get("replace"))), [], doc_refs
