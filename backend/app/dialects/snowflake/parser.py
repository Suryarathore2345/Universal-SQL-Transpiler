"""
Snowflake SQL parser — converts Snowflake DDL to IR.

Official docs used:
  CREATE TABLE:        https://docs.snowflake.com/en/sql-reference/sql/create-table
  Data types:          https://docs.snowflake.com/en/sql-reference/intro-summary-data-types
  AUTOINCREMENT:       https://docs.snowflake.com/en/sql-reference/sql/create-table
  CLUSTER BY:          https://docs.snowflake.com/en/user-guide/tables-clustering-keys
  CREATE VIEW:         https://docs.snowflake.com/en/sql-reference/sql/create-view
  CREATE MV:           https://docs.snowflake.com/en/sql-reference/sql/create-materialized-view
  TRANSIENT TABLE:     https://docs.snowflake.com/en/user-guide/tables-temp-transient
  SECURE VIEW:         https://docs.snowflake.com/en/user-guide/views-secure
"""
from __future__ import annotations

import re
from typing import List, Optional, Tuple

import sqlglot
import sqlglot.expressions as exp

from app.dialects.base import DialectParser
from app.ir.models import (
    Dialect, GeneratedType, IRCheckConstraint, IRClusterBy, IRColumn,
    IRDataType, IRDDLObject, IRDocReference, IRForeignKey, IRFunction,
    IRIdentity, IRMaterializedView, IRPrimaryKey, IRProcedure, IRTable,
    IRTableProperties, IRUniqueConstraint, IRView, IRWarning, RefreshType,
    Warningseverity,
)


class SnowflakeParser(DialectParser):
    """
    Parses Snowflake SQL DDL into IR using sqlglot + custom post-processing
    for Snowflake-specific constructs (CLUSTER BY, TRANSIENT, AUTOINCREMENT, SECURE, etc.).
    """

    dialect = Dialect.SNOWFLAKE
    _SQLGLOT_DIALECT = "snowflake"

    def parse_statement(
        self, sql: str
    ) -> Tuple[Optional[IRDDLObject], List[IRWarning], List[IRDocReference]]:
        warnings: List[IRWarning] = []
        doc_refs: List[IRDocReference] = []
        sql_u = sql.strip().upper()

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
            is_mv = (
                kind == "MATERIALIZED VIEW"
                or any(isinstance(p, exp.MaterializedProperty)
                       for p in parsed.find_all(exp.MaterializedProperty))
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
                doc_refs.append(IRDocReference(title="Snowflake CREATE PROCEDURE", url="https://docs.snowflake.com/en/sql-reference/sql/create-procedure", platform="snowflake", purpose="Stored procedure"))
                return r, warnings + w, doc_refs + d
            elif kind == "FUNCTION":
                r, w, d = self._parse_func_from_sql(sql, body_style="dollar")
                doc_refs.append(IRDocReference(title="Snowflake CREATE FUNCTION", url="https://docs.snowflake.com/en/sql-reference/sql/create-function", platform="snowflake", purpose="UDF"))
                return r, warnings + w, doc_refs + d

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
            title="Snowflake CREATE TABLE",
            url="https://docs.snowflake.com/en/sql-reference/sql/create-table",
            platform="snowflake",
            purpose="CREATE TABLE syntax reference",
        )]

        table_node = node.find(exp.Table)
        name = table_node.name if table_node else "unknown"
        schema = table_node.db if table_node else None
        db = table_node.catalog if table_node else None

        # Snowflake-specific: TEMPORARY, TRANSIENT
        is_temp = bool(node.args.get("temporary"))
        is_transient = "TRANSIENT" in raw_sql.upper()

        if is_transient:
            doc_refs.append(IRDocReference(
                title="Snowflake TRANSIENT TABLE",
                url="https://docs.snowflake.com/en/user-guide/tables-temp-transient",
                platform="snowflake",
                purpose="TRANSIENT table concept",
            ))

        columns: List[IRColumn] = []
        pk: Optional[IRPrimaryKey] = None
        fks = []
        uniques = []
        checks = []

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
                    )
                elif isinstance(expr, exp.ForeignKey):
                    fks.append(self._parse_fk(expr))
                elif isinstance(expr, exp.UniqueColumnConstraint):
                    uniques.append(IRUniqueConstraint(
                        columns=[c.name for c in expr.expressions],
                    ))
                elif isinstance(expr, exp.CheckColumnConstraint):
                    checks.append(IRCheckConstraint(expression=expr.this.sql()))

        # CLUSTER BY
        cluster_by = self._extract_cluster_by(raw_sql)

        props = IRTableProperties(is_transient=is_transient)
        # DATA_RETENTION_TIME_IN_DAYS
        m = re.search(r"DATA_RETENTION_TIME_IN_DAYS\s*=\s*(\d+)", raw_sql, re.IGNORECASE)
        if m:
            props.data_retention_days = int(m.group(1))

        table = IRTable(
            name=name,
            schema_name=schema or None,
            database_name=db or None,
            columns=columns,
            primary_key=pk,
            foreign_keys=fks,
            unique_constraints=uniques,
            check_constraints=checks,
            is_temporary=is_temp,
            cluster_by=cluster_by,
            table_properties=props,
        )
        return table, warnings, doc_refs

    def _parse_column_def(
        self, col_def: exp.ColumnDef
    ) -> Tuple[IRColumn, List[IRWarning], List[IRDocReference]]:
        warnings: List[IRWarning] = []
        doc_refs: List[IRDocReference] = []

        name = col_def.name
        type_node = col_def.args.get("kind")
        type_str = type_node.sql("snowflake") if type_node else "VARCHAR"

        ir_type, w, d = self._parse_data_type(type_str)
        warnings.extend(w)
        doc_refs.extend(d)

        is_nullable = True
        default_val = None
        identity: Optional[IRIdentity] = None
        comment = None
        masking_policy = None

        for constraint in col_def.constraints:
            c = constraint.kind if hasattr(constraint, "kind") else constraint
            if isinstance(c, exp.NotNullColumnConstraint):
                is_nullable = False
            elif isinstance(c, exp.DefaultColumnConstraint):
                default_val = c.this.sql() if c.this else None
            elif isinstance(c, exp.GeneratedAsIdentityColumnConstraint):
                # Snowflake AUTOINCREMENT / IDENTITY
                # Docs: https://docs.snowflake.com/en/sql-reference/sql/create-table
                doc_refs.append(IRDocReference(
                    title="Snowflake AUTOINCREMENT/IDENTITY",
                    url="https://docs.snowflake.com/en/sql-reference/sql/create-table",
                    platform="snowflake",
                    purpose="Identity column parsing",
                ))
                start = 1
                step = 1
                always = GeneratedType.BY_DEFAULT
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
                identity = IRIdentity(generated=always, start=start, increment=step)
            elif isinstance(c, exp.CommentColumnConstraint):
                comment = c.this.name if c.this else None

        return IRColumn(
            name=name,
            data_type=ir_type,
            is_nullable=is_nullable,
            default_value=default_val,
            identity=identity,
            comment=comment,
            masking_policy=masking_policy,
        ), warnings, doc_refs

    def _parse_fk(self, fk_node: exp.ForeignKey) -> IRForeignKey:
        cols = [c.name for c in fk_node.expressions]
        ref = fk_node.args.get("reference")
        ref_table = ref.this.name if ref and ref.this else "unknown"
        ref_schema = ref.this.db if ref and ref.this else None
        ref_cols = [c.name for c in ref.expressions] if ref else []
        return IRForeignKey(
            columns=cols,
            ref_table=ref_table,
            ref_schema=ref_schema or None,
            ref_columns=ref_cols,
        )

    def _extract_cluster_by(self, sql: str) -> Optional[IRClusterBy]:
        """
        Extract CLUSTER BY from Snowflake DDL.
        Docs: https://docs.snowflake.com/en/user-guide/tables-clustering-keys
        """
        m = re.search(r"CLUSTER\s+BY\s*\(([^)]+)\)", sql, re.IGNORECASE)
        if m:
            cols = [c.strip().strip('"') for c in m.group(1).split(",")]
            return IRClusterBy(columns=cols)
        return None

    # -------------------------------------------------------------------------
    # CREATE VIEW
    # -------------------------------------------------------------------------

    def _parse_create_view(
        self, node: exp.Create, raw_sql: str
    ) -> Tuple[Optional[IRView], List[IRWarning], List[IRDocReference]]:
        """
        Snowflake VIEW docs: https://docs.snowflake.com/en/sql-reference/sql/create-view
        SECURE VIEW docs: https://docs.snowflake.com/en/user-guide/views-secure
        """
        doc_refs = [IRDocReference(
            title="Snowflake CREATE VIEW",
            url="https://docs.snowflake.com/en/sql-reference/sql/create-view",
            platform="snowflake",
            purpose="CREATE VIEW syntax reference",
        )]

        view_node = node.find(exp.Table)
        name = view_node.name if view_node else "unknown"
        schema = view_node.db if view_node else None
        db = view_node.catalog if view_node else None
        or_replace = bool(node.args.get("replace"))
        is_secure = bool(re.search(r"\bSECURE\b", raw_sql, re.IGNORECASE))

        query = node.args.get("expression") or node.args.get("this")
        definition = query.sql(dialect="snowflake") if query else ""

        warnings = []
        if is_secure:
            warnings.append(IRWarning(
                feature="SECURE_VIEW",
                message="Snowflake SECURE VIEW prevents query optimization details from being exposed. "
                        "This security attribute has no equivalent in other platforms. View definition is preserved.",
                doc_url="https://docs.snowflake.com/en/user-guide/views-secure",
                severity=Warningseverity.INFO,
            ))
            doc_refs.append(IRDocReference(
                title="Snowflake SECURE VIEW",
                url="https://docs.snowflake.com/en/user-guide/views-secure",
                platform="snowflake",
                purpose="SECURE VIEW concept",
            ))

        view = IRView(
            name=name,
            schema_name=schema or None,
            database_name=db or None,
            definition=definition,
            or_replace=or_replace,
            is_secure=is_secure,
        )
        return view, warnings, doc_refs

    # -------------------------------------------------------------------------
    # CREATE MATERIALIZED VIEW
    # -------------------------------------------------------------------------

    def _parse_create_mv(
        self, node: exp.Create, raw_sql: str
    ) -> Tuple[Optional[IRMaterializedView], List[IRWarning], List[IRDocReference]]:
        """
        Snowflake MV docs:
        https://docs.snowflake.com/en/sql-reference/sql/create-materialized-view
        Limitation: MVs require Enterprise Edition.
        """
        doc_refs = [IRDocReference(
            title="Snowflake CREATE MATERIALIZED VIEW",
            url="https://docs.snowflake.com/en/sql-reference/sql/create-materialized-view",
            platform="snowflake",
            purpose="MV syntax reference",
        )]

        mv_node = node.find(exp.Table)
        name = mv_node.name if mv_node else "unknown"
        schema = mv_node.db if mv_node else None

        query = node.args.get("expression") or node.args.get("this")
        definition = query.sql(dialect="snowflake") if query else ""

        cluster_by = self._extract_cluster_by(raw_sql)

        mv = IRMaterializedView(
            name=name,
            schema_name=schema or None,
            definition=definition,
            refresh_type=RefreshType.AUTO,
            auto_refresh=True,
            cluster_by=cluster_by,
        )
        return mv, [], doc_refs
