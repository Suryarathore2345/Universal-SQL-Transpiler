"""
Oracle Database parser — converts Oracle DDL to IR.

Official docs used:
  CREATE TABLE:     https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html
  Data types:       https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Data-Types.html
  IDENTITY column:  https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html#GUID-F9CE0CC3-13AE-4744-A43C-EAC7A71AAAB6
  PARTITION BY:     https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html#GUID-F9CE0CC3-13AE-4744-A43C-EAC7A71AAAB6
  CREATE VIEW:      https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-VIEW.html
  CREATE MV:        https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-MATERIALIZED-VIEW.html

Key Oracle DDL facts:
  - NUMBER(p, s) for all numeric types (no INT alias behavior in stored form)
  - VARCHAR2(n) — preferred over VARCHAR (Oracle note: use VARCHAR2)
  - DATE includes time (not just date) — different from SQL standard
  - GENERATED [ALWAYS|BY DEFAULT [ON NULL]] AS IDENTITY [START WITH n INCREMENT BY n]
  - PARTITION BY RANGE | LIST | HASH | COMPOSITE
  - Identifiers case-insensitive unless double-quoted
  - GLOBAL TEMPORARY TABLE | PRIVATE TEMPORARY TABLE
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


class OracleParser(DialectParser):
    """
    Parses Oracle Database DDL into IR using sqlglot oracle dialect + custom regex.
    """

    dialect = Dialect.ORACLE
    _SQLGLOT_DIALECT = "oracle"

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

            elif kind == "PROCEDURE":
                r, w, d = self._parse_proc_from_sql(sql, body_style="oracle")
                doc_refs.append(IRDocReference(title="Oracle CREATE PROCEDURE", url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-PROCEDURE.html", platform="oracle", purpose="Stored procedure"))
                return r, warnings + w, doc_refs + d
            elif kind == "FUNCTION":
                r, w, d = self._parse_func_from_sql(sql, body_style="oracle")
                doc_refs.append(IRDocReference(title="Oracle CREATE FUNCTION", url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-FUNCTION.html", platform="oracle", purpose="PL/SQL function"))
                return r, warnings + w, doc_refs + d

        if re.search(r'\bCREATE\b.*?\bPROCEDURE\b', sql, re.IGNORECASE | re.DOTALL):
            r, w, d = self._parse_proc_from_sql(sql, body_style="oracle")
            return r, warnings + w, d
        if re.search(r'\bCREATE\b.*?\bFUNCTION\b', sql, re.IGNORECASE | re.DOTALL):
            r, w, d = self._parse_func_from_sql(sql, body_style="oracle")
            return r, warnings + w, d

        warnings.append(IRWarning(feature="UNSUPPORTED_STATEMENT", message=f"Not supported: {type(parsed).__name__}", severity=Warningseverity.WARNING))
        return None, warnings, doc_refs

    def _parse_create_table(self, node: exp.Create, raw_sql: str) -> Tuple[Optional[IRTable], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="Oracle CREATE TABLE", url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html", platform="oracle", purpose="CREATE TABLE syntax")]
        warnings: List[IRWarning] = []

        tbl = node.find(exp.Table)
        name = tbl.name if tbl else "unknown"
        schema = (tbl.db if tbl else None) or None
        db = (tbl.catalog if tbl else None) or None
        is_temp = "GLOBAL TEMPORARY" in raw_sql.upper() or "PRIVATE TEMPORARY" in raw_sql.upper()
        or_replace = bool(node.args.get("replace"))
        if_not_exists = bool(node.args.get("exists"))

        columns, pk, fks, uniques, checks = [], None, [], [], []
        inline_pk_cols: List[str] = []
        schema_expr = node.args.get("this")
        if schema_expr and hasattr(schema_expr, "expressions"):
            for expr in schema_expr.expressions:
                if isinstance(expr, exp.ColumnDef):
                    col, w, d = self._parse_column_def(expr)
                    columns.append(col); warnings.extend(w); doc_refs.extend(d)
                    # Inline column-level PRIMARY KEY (e.g. `id NUMBER(10)
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
                elif isinstance(expr, exp.Check):
                    checks.append(IRCheckConstraint(expression=expr.this.sql() if expr.this else ""))
                elif isinstance(expr, exp.Constraint):
                    cname = expr.name
                    for sub in expr.expressions:
                        if isinstance(sub, exp.PrimaryKey):
                            pk = IRPrimaryKey(name=cname, columns=[c.name for c in sub.expressions])
                        elif isinstance(sub, exp.ForeignKey):
                            ref = sub.args.get("reference")
                            ref_tbl = "unknown"
                            ref_sch = None
                            ref_cols: List[str] = []
                            if ref and ref.this:
                                rthis = ref.this
                                ref_tbl = getattr(rthis.this, "name", None) or getattr(rthis, "name", None) or "unknown"
                                ref_sch = getattr(rthis.this, "db", None) if hasattr(rthis, "this") else None
                                ref_cols = [c.name for c in getattr(rthis, "expressions", [])]
                            fks.append(IRForeignKey(
                                name=cname,
                                columns=[c.name for c in sub.expressions],
                                ref_table=ref_tbl, ref_schema=ref_sch, ref_columns=ref_cols,
                            ))
                        elif isinstance(sub, exp.UniqueColumnConstraint):
                            ucols = [c.name for c in sub.expressions] if sub.expressions else []
                            if not ucols and sub.this:
                                ucols = [c.name for c in sub.this.expressions] if hasattr(sub.this, "expressions") else []
                            uniques.append(IRUniqueConstraint(name=cname, columns=ucols))
                        elif isinstance(sub, (exp.Check, exp.CheckColumnConstraint)):
                            checks.append(IRCheckConstraint(name=cname, expression=sub.this.sql() if sub.this else ""))

        if pk is None and inline_pk_cols:
            pk = IRPrimaryKey(columns=inline_pk_cols)

        partition_by = self._extract_partition(raw_sql)

        return IRTable(name=name, schema_name=schema, database_name=db, columns=columns, primary_key=pk, foreign_keys=fks, unique_constraints=uniques, check_constraints=checks, partition_by=partition_by, is_temporary=is_temp, or_replace=or_replace, if_not_exists=if_not_exists), warnings, doc_refs

    def _parse_column_def(self, col_def: exp.ColumnDef) -> Tuple[IRColumn, List[IRWarning], List[IRDocReference]]:
        warnings, doc_refs = [], []
        name = col_def.name
        type_node = col_def.args.get("kind")
        type_str = type_node.sql("oracle") if type_node else "VARCHAR2(255)"
        ir_type, w, d = self._parse_data_type(type_str)
        warnings.extend(w); doc_refs.extend(d)

        # Oracle DATE stores a full timestamp (year through second) — unlike
        # the ANSI/most-other-dialect DATE type, which is date-only. Every
        # non-Oracle target's DATE type will silently truncate the time
        # component with no error, so this must be flagged explicitly;
        # nothing else in the pipeline knows this column originated from an
        # Oracle DATE by the time generation happens.
        if type_str.strip().upper() == "DATE":
            warnings.append(IRWarning(
                feature="ORACLE_DATE_HAS_TIME_COMPONENT",
                message=(
                    f"Column '{name}' is Oracle DATE, which stores a full timestamp "
                    "(including hour/minute/second) — not date-only as in most other "
                    "dialects. If the target's DATE type is date-only, the time "
                    "component will be silently dropped. Consider mapping to a "
                    "TIMESTAMP type on the target if time-of-day data matters."
                ),
                doc_url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Data-Types.html",
                severity=Warningseverity.WARNING,
            ))

        is_nullable, default_val, identity = True, None, None
        for constraint in col_def.constraints:
            c = constraint.kind if hasattr(constraint, "kind") else constraint
            if isinstance(c, exp.NotNullColumnConstraint): is_nullable = False
            elif isinstance(c, exp.DefaultColumnConstraint): default_val = c.this.sql() if c.this else None
            elif isinstance(c, exp.GeneratedAsIdentityColumnConstraint):
                doc_refs.append(IRDocReference(title="Oracle GENERATED AS IDENTITY", url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html#GUID-F9CE0CC3-13AE-4744-A43C-EAC7A71AAAB6", platform="oracle", purpose="Identity column"))
                s = c.args.get("start"); inc = c.args.get("increment")
                start = int(str(s.this if hasattr(s, "this") else s)) if s else 1
                step = int(str(inc.this if hasattr(inc, "this") else inc)) if inc else 1
                always_node = c.args.get("always")
                gen_type = GeneratedType.ALWAYS if always_node else GeneratedType.BY_DEFAULT
                identity = IRIdentity(generated=gen_type, start=start, increment=step)

        return IRColumn(name=name, data_type=ir_type, is_nullable=is_nullable, default_value=default_val, identity=identity), warnings, doc_refs

    def _extract_partition(self, sql: str) -> Optional[IRPartition]:
        """
        Extract PARTITION BY RANGE|LIST|HASH.
        Docs: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html
        """
        m = re.search(r"PARTITION\s+BY\s+(RANGE|LIST|HASH)\s*\(([^)]+)\)", sql, re.IGNORECASE)
        if m:
            strategy = m.group(1).upper()
            cols = [c.strip().strip('"') for c in m.group(2).split(",")]
            return IRPartition(columns=cols, strategy=strategy)
        return None

    def _parse_create_view(self, node: exp.Create, raw_sql: str) -> Tuple[Optional[IRView], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="Oracle CREATE VIEW", url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-VIEW.html", platform="oracle", purpose="CREATE VIEW")]
        vn = node.find(exp.Table)
        name = vn.name if vn else "unknown"
        query = node.args.get("expression") or node.args.get("this")
        definition = query.sql(dialect="oracle") if query else ""
        or_replace = bool(node.args.get("replace"))
        return IRView(name=name, schema_name=(vn.db if vn else None) or None, definition=definition, or_replace=or_replace), [], doc_refs

    def _parse_create_mv(self, node: exp.Create, raw_sql: str) -> Tuple[Optional[IRMaterializedView], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="Oracle CREATE MATERIALIZED VIEW", url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-MATERIALIZED-VIEW.html", platform="oracle", purpose="CREATE MV")]
        mn = node.find(exp.Table)
        name = mn.name if mn else "unknown"
        query = node.args.get("expression") or node.args.get("this")
        definition = query.sql(dialect="oracle") if query else ""
        # Detect REFRESH ON COMMIT vs ON DEMAND
        refresh_type = RefreshType.AUTO if "ON COMMIT" in raw_sql.upper() else RefreshType.MANUAL
        return IRMaterializedView(name=name, schema_name=(mn.db if mn else None) or None, definition=definition, refresh_type=refresh_type, auto_refresh=(refresh_type == RefreshType.AUTO)), [], doc_refs
