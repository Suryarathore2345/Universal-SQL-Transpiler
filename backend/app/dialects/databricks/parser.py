"""
Databricks SQL (Delta Lake) parser — converts Databricks DDL to IR.

Official docs used:
  CREATE TABLE:   https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-table-using.html
  Delta table:    https://docs.databricks.com/en/delta/index.html
  Liquid cluster: https://docs.databricks.com/en/delta/clustering.html
  IDENTITY:       https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-table-using.html#generated-columns
  CREATE VIEW:    https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-view.html
  CREATE MV:      https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-materialized-view.html

Key Databricks DDL facts:
  - Default table format is Delta (USING DELTA)
  - PARTITIONED BY (cols) — classic partitioning, cannot combine with CLUSTER BY
  - CLUSTER BY (cols) — liquid clustering (Delta only), cannot combine with PARTITIONED BY
  - GENERATED ALWAYS AS IDENTITY — Delta only, BIGINT only
  - LOCATION for external tables
  - TBLPROPERTIES for table properties
  - COMMENT at table level
"""
from __future__ import annotations

import re
from typing import List, Optional, Tuple

import sqlglot
import sqlglot.expressions as exp

from app.dialects.base import DialectParser, run_with_timeout
from app.ir.models import (
    Dialect, GeneratedType, IRCheckConstraint, IRClusterBy, IRColumn,
    IRDataType, IRDDLObject, IRDocReference, IRForeignKey, IRFunction,
    IRIdentity, IRMaterializedView, IRPartition, IRPrimaryKey, IRProcedure,
    IRTable, IRUniqueConstraint, IRView, IRWarning, RefreshType, Warningseverity,
)


class DatabricksParser(DialectParser):
    """
    Parses Databricks SQL DDL into IR using sqlglot spark dialect + custom regex.
    """

    dialect = Dialect.DATABRICKS
    _SQLGLOT_DIALECT = "spark"

    def parse_statement(
        self, sql: str
    ) -> Tuple[Optional[IRDDLObject], List[IRWarning], List[IRDocReference]]:
        warnings: List[IRWarning] = []
        doc_refs: List[IRDocReference] = []

        try:
            parsed = run_with_timeout(sqlglot.parse_one, sql, dialect=self._SQLGLOT_DIALECT, error_level=sqlglot.ErrorLevel.WARN)
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

            elif kind == "FUNCTION":
                r, w, d = self._parse_func_from_sql(sql, body_style="dollar")
                doc_refs.append(IRDocReference(title="Databricks CREATE FUNCTION", url="https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-sql-function.html", platform="databricks", purpose="SQL/Python UDF"))
                return r, warnings + w, doc_refs + d

        if re.search(r'\bCREATE\b.*?\bFUNCTION\b', sql, re.IGNORECASE | re.DOTALL):
            r, w, d = self._parse_func_from_sql(sql, body_style="dollar")
            return r, warnings + w, d
        # Databricks CREATE PROCEDURE (DBR 17.0+, Unity Catalog): body is a
        # BEGIN ... END compound statement, not dollar-quoted.
        if re.search(r'\bCREATE\b.*?\bPROCEDURE\b', sql, re.IGNORECASE | re.DOTALL):
            r, w, d = self._parse_proc_from_sql(sql, body_style="databricks")
            return r, warnings + w, d

        warnings.append(IRWarning(feature="UNSUPPORTED_STATEMENT", message=f"Not supported: {type(parsed).__name__}", severity=Warningseverity.WARNING))
        return None, warnings, doc_refs

    def _parse_create_table(self, node: exp.Create, raw_sql: str) -> Tuple[Optional[IRTable], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="Databricks CREATE TABLE", url="https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-table-using.html", platform="databricks", purpose="CREATE TABLE syntax")]
        warnings: List[IRWarning] = []

        tbl = node.find(exp.Table)
        name = tbl.name if tbl else "unknown"
        schema = (tbl.db if tbl else None) or None
        db = (tbl.catalog if tbl else None) or None

        is_temp = bool(node.args.get("temporary"))
        or_replace = bool(node.args.get("replace"))
        if_not_exists = bool(node.args.get("exists"))
        is_external = "EXTERNAL" in raw_sql.upper()

        columns, pk, fks, uniques, checks = [], None, [], [], []
        inline_pk_cols: List[str] = []
        schema_expr = node.args.get("this")
        if schema_expr and hasattr(schema_expr, "expressions"):
            for expr in schema_expr.expressions:
                if isinstance(expr, exp.ColumnDef):
                    col, w, d = self._parse_column_def(expr)
                    columns.append(col); warnings.extend(w); doc_refs.extend(d)
                    # Inline column-level PRIMARY KEY (e.g. `id BIGINT
                    # PRIMARY KEY`) is a separate constraint kind from the
                    # table-level `PRIMARY KEY (col, ...)` clause handled
                    # below — without this check it was silently dropped.
                    if any(
                        isinstance(c.kind if hasattr(c, "kind") else c, exp.PrimaryKeyColumnConstraint)
                        for c in expr.constraints
                    ):
                        inline_pk_cols.append(col.name)
                elif isinstance(expr, exp.PrimaryKey):
                    pk = IRPrimaryKey(columns=[c.name for c in expr.expressions])
                elif isinstance(expr, exp.Constraint):
                    cname = expr.name
                    for sub in expr.expressions:
                        if isinstance(sub, exp.PrimaryKey):
                            pk = IRPrimaryKey(name=cname, columns=[c.name for c in sub.expressions])
                        elif isinstance(sub, exp.ForeignKey):
                            ref = sub.args.get("reference")
                            ref_tbl = "unknown"
                            ref_sch = None
                            ref_cols: list = []
                            if ref and ref.this:
                                rthis = ref.this
                                ref_tbl = getattr(rthis.this, "name", None) or getattr(rthis, "name", None) or "unknown"
                                ref_sch = getattr(rthis.this, "db", None) if hasattr(rthis, "this") else None
                                ref_cols = [c.name for c in getattr(rthis, "expressions", [])]
                            fks.append(IRForeignKey(name=cname, columns=[c.name for c in sub.expressions], ref_table=ref_tbl, ref_schema=ref_sch, ref_columns=ref_cols))
                        elif isinstance(sub, exp.UniqueColumnConstraint):
                            ucols = [c.name for c in sub.expressions] if sub.expressions else []
                            if not ucols and sub.this and hasattr(sub.this, "expressions"):
                                ucols = [c.name for c in sub.this.expressions]
                            uniques.append(IRUniqueConstraint(name=cname, columns=ucols))
                        elif isinstance(sub, (exp.Check, exp.CheckColumnConstraint)):
                            checks.append(IRCheckConstraint(name=cname, expression=sub.this.sql() if sub.this else ""))

        if pk is None and inline_pk_cols:
            pk = IRPrimaryKey(columns=inline_pk_cols)

        cluster_by = self._extract_cluster_by(raw_sql)
        partition_by = self._extract_partition(raw_sql)
        comment = self._extract_comment(raw_sql)

        return IRTable(
            name=name, schema_name=schema, database_name=db,
            columns=columns, primary_key=pk, foreign_keys=fks,
            unique_constraints=uniques, check_constraints=checks,
            cluster_by=cluster_by, partition_by=partition_by,
            is_temporary=is_temp, is_external=is_external, comment=comment,
            or_replace=or_replace, if_not_exists=if_not_exists,
        ), warnings, doc_refs

    def _parse_column_def(self, col_def: exp.ColumnDef) -> Tuple[IRColumn, List[IRWarning], List[IRDocReference]]:
        warnings, doc_refs = [], []
        name = col_def.name
        type_node = col_def.args.get("kind")
        type_str = type_node.sql("spark") if type_node else "STRING"
        ir_type, w, d = self._parse_data_type(type_str)
        warnings.extend(w); doc_refs.extend(d)

        is_nullable, default_val, identity, comment = True, None, None, None
        for constraint in col_def.constraints:
            c = constraint.kind if hasattr(constraint, "kind") else constraint
            if isinstance(c, exp.NotNullColumnConstraint): is_nullable = False
            elif isinstance(c, exp.DefaultColumnConstraint): default_val = c.this.sql() if c.this else None
            elif isinstance(c, exp.GeneratedAsIdentityColumnConstraint):
                doc_refs.append(IRDocReference(
                    title="Databricks GENERATED ALWAYS AS IDENTITY",
                    url="https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-table-using.html#generated-columns",
                    platform="databricks", purpose="Identity column"
                ))
                s = c.args.get("start"); inc = c.args.get("increment")
                start = int(str(s.this if hasattr(s, "this") else s)) if s else 1
                step = int(str(inc.this if hasattr(inc, "this") else inc)) if inc else 1
                identity = IRIdentity(start=start, increment=step)
            elif isinstance(c, exp.CommentColumnConstraint):
                comment = c.this.name if c.this else None

        return IRColumn(name=name, data_type=ir_type, is_nullable=is_nullable, default_value=default_val, identity=identity, comment=comment), warnings, doc_refs

    def _extract_cluster_by(self, sql: str) -> Optional[IRClusterBy]:
        """
        Liquid clustering: CLUSTER BY (col1, col2)
        Docs: https://docs.databricks.com/en/delta/clustering.html
        Cannot be combined with PARTITIONED BY.
        """
        m = re.search(r"\bCLUSTER\s+BY\s*\(([^)]+)\)", sql, re.IGNORECASE)
        if m:
            cols = [c.strip().strip("`").strip('"') for c in m.group(1).split(",")]
            return IRClusterBy(columns=cols)
        return None

    def _extract_partition(self, sql: str) -> Optional[IRPartition]:
        """
        Classic partitioning: PARTITIONED BY (col1, col2)
        Docs: https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-table-using.html
        """
        m = re.search(r"\bPARTITIONED\s+BY\s*\(([^)]+)\)", sql, re.IGNORECASE)
        if m:
            cols = [c.strip().strip("`").strip('"') for c in m.group(1).split(",")]
            return IRPartition(columns=cols, strategy="LIST")
        return None

    def _extract_comment(self, sql: str) -> Optional[str]:
        m = re.search(r"\bCOMMENT\s+'([^']+)'", sql, re.IGNORECASE)
        return m.group(1) if m else None

    def _parse_create_view(self, node: exp.Create, raw_sql: str) -> Tuple[Optional[IRView], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="Databricks CREATE VIEW", url="https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-view.html", platform="databricks", purpose="CREATE VIEW")]
        vn = node.find(exp.Table)
        name = vn.name if vn else "unknown"
        query = node.args.get("expression") or node.args.get("this")
        definition = query.sql(dialect="spark") if query else ""
        return IRView(name=name, schema_name=(vn.db if vn else None) or None, definition=definition, or_replace=bool(node.args.get("replace"))), [], doc_refs

    def _parse_create_mv(self, node: exp.Create, raw_sql: str) -> Tuple[Optional[IRMaterializedView], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="Databricks CREATE MATERIALIZED VIEW", url="https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-materialized-view.html", platform="databricks", purpose="CREATE MV")]
        mn = node.find(exp.Table)
        name = mn.name if mn else "unknown"
        query = node.args.get("expression") or node.args.get("this")
        definition = query.sql(dialect="spark") if query else ""
        schedule = self._extract_refresh_schedule(raw_sql)
        return IRMaterializedView(name=name, schema_name=(mn.db if mn else None) or None, definition=definition, refresh_type=RefreshType.AUTO, auto_refresh=True, refresh_schedule=schedule), [], doc_refs

    def _extract_refresh_schedule(self, sql: str) -> Optional[str]:
        m = re.search(r"SCHEDULE\s+(?:CRON\s+)?'([^']+)'", sql, re.IGNORECASE)
        return m.group(1) if m else None
