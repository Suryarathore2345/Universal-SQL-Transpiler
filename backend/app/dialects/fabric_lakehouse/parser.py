"""
Microsoft Fabric Lakehouse (Spark SQL / Delta Lake) parser.

Official docs used:
  Spark SQL:         https://spark.apache.org/docs/latest/sql-ref-syntax.html
  Fabric Lakehouse:  https://learn.microsoft.com/en-us/fabric/data-engineering/lakehouse-overview
  Delta Lake:        https://docs.delta.io/latest/delta-intro.html
  Materialized Lake Views:
                     https://learn.microsoft.com/en-us/fabric/data-engineering/materialized-lake-view-overview

Key Fabric Lakehouse / Spark SQL facts (verified June 2026):
  - Default table format is Delta (USING DELTA)
  - PARTITIONED BY (cols) — classic partitioning
  - CLUSTER BY (cols) — liquid clustering (Databricks-style); NOT supported in Fabric Lakehouse Spark SQL
    (use PARTITIONED BY instead)
  - CREATE [OR REPLACE] MATERIALIZED LAKE VIEW — Fabric Lakehouse-specific syntax
    (sqlglot does not know "LAKE VIEW"; preprocess to strip "LAKE" for parsing)
  - No stored procedures in Spark SQL; use Python notebooks instead
  - Functions supported as SQL UDFs or Python UDFs
  - COMMENT at table level
  - USING DELTA clause (standard in Fabric Lakehouse Delta tables)
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
    IRIdentity, IRMaterializedView, IRPartition, IRPrimaryKey, IRProcedure,
    IRTable, IRUniqueConstraint, IRView, IRWarning, RefreshType, Warningseverity,
)


class FabricLakehouseParser(DialectParser):
    """
    Parses Fabric Lakehouse Spark SQL DDL into IR.
    Uses sqlglot spark2 dialect + custom regex for Fabric-specific extensions.
    """

    dialect = Dialect.FABRIC_LAKEHOUSE
    _SQLGLOT_DIALECT = "spark2"

    def _preprocess_sql(self, sql: str) -> Tuple[str, bool]:
        """
        Preprocess Fabric Lakehouse-specific SQL that sqlglot doesn't understand.

        Returns (preprocessed_sql, is_materialized_lake_view).

        MATERIALIZED LAKE VIEW:
          Fabric Lakehouse uses 'CREATE [OR REPLACE] MATERIALIZED LAKE VIEW schema.view AS ...'
          Strip 'LAKE' so sqlglot sees 'CREATE MATERIALIZED VIEW' which it can parse.
          Ref: https://learn.microsoft.com/en-us/fabric/data-engineering/materialized-lake-view-overview
        """
        is_mlv = bool(re.search(
            r'\bCREATE\b.*?\bMATERIALIZED\s+LAKE\s+VIEW\b',
            sql, re.IGNORECASE | re.DOTALL
        ))
        if is_mlv:
            sql = re.sub(
                r'\bMATERIALIZED\s+LAKE\s+VIEW\b',
                'MATERIALIZED VIEW',
                sql,
                flags=re.IGNORECASE,
            )

        # Strip USING DELTA — sqlglot may not need it; strip to simplify parsing
        sql = re.sub(r'\bUSING\s+DELTA\b', '', sql, flags=re.IGNORECASE)

        return sql, is_mlv

    def parse_statement(
        self, sql: str
    ) -> Tuple[Optional[IRDDLObject], List[IRWarning], List[IRDocReference]]:
        warnings: List[IRWarning] = []
        doc_refs: List[IRDocReference] = []

        preprocessed_sql, is_mlv = self._preprocess_sql(sql)

        try:
            parsed = sqlglot.parse_one(
                preprocessed_sql,
                dialect=self._SQLGLOT_DIALECT,
                error_level=sqlglot.ErrorLevel.WARN,
            )
        except Exception as e:
            warnings.append(IRWarning(
                feature="PARSE_ERROR",
                message=str(e),
                severity=Warningseverity.ERROR,
            ))
            return None, warnings, doc_refs

        if parsed is None:
            return None, warnings, doc_refs

        if isinstance(parsed, exp.Create):
            kind = parsed.args.get("kind", "").upper()
            is_mv_node = any(
                isinstance(p, exp.MaterializedProperty)
                for p in parsed.find_all(exp.MaterializedProperty)
            )

            if kind == "TABLE":
                r, w, d = self._parse_create_table(parsed, sql)
                return r, warnings + w, doc_refs + d

            elif is_mv_node or is_mlv:
                r, w, d = self._parse_create_mv(parsed, sql, is_mlv=is_mlv)
                return r, warnings + w, doc_refs + d

            elif kind == "VIEW":
                r, w, d = self._parse_create_view(parsed, sql)
                return r, warnings + w, doc_refs + d

            elif kind == "FUNCTION":
                r, w, d = self._parse_func_from_sql(sql, body_style="dollar")
                doc_refs.append(IRDocReference(
                    title="Spark SQL CREATE FUNCTION",
                    url="https://spark.apache.org/docs/latest/sql-ref-syntax-ddl-create-function.html",
                    platform="fabric_lakehouse",
                    purpose="SQL/Python UDF",
                ))
                return r, warnings + w, doc_refs + d

        # Regex fallbacks
        if re.search(r'\bCREATE\b.*?\bFUNCTION\b', sql, re.IGNORECASE | re.DOTALL):
            r, w, d = self._parse_func_from_sql(sql, body_style="dollar")
            return r, warnings + w, d

        # Spark SQL has no stored procedures — treat PROCEDURE as a warning + function stub
        if re.search(r'\bCREATE\b.*?\bPROCEDURE\b', sql, re.IGNORECASE | re.DOTALL):
            warnings.append(IRWarning(
                feature="PROCEDURE_NOT_SUPPORTED_FABRIC_LAKEHOUSE",
                message=(
                    "Spark SQL (Fabric Lakehouse) does not support CREATE PROCEDURE. "
                    "Use a Fabric Notebook or Python-based orchestration instead. "
                    "Docs: https://learn.microsoft.com/en-us/fabric/data-engineering/author-notebook-python"
                ),
                doc_url="https://learn.microsoft.com/en-us/fabric/data-engineering/author-notebook-python",
                severity=Warningseverity.WARNING,
                unsupported=True,
            ))
            r, w, d = self._parse_proc_from_sql(sql, body_style="best_effort")
            return r, warnings + w, d

        warnings.append(IRWarning(
            feature="UNSUPPORTED_STATEMENT",
            message=f"Not supported: {type(parsed).__name__}",
            severity=Warningseverity.WARNING,
        ))
        return None, warnings, doc_refs

    def _parse_create_table(
        self, node: exp.Create, raw_sql: str
    ) -> Tuple[Optional[IRTable], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(
            title="Spark SQL CREATE TABLE",
            url="https://spark.apache.org/docs/latest/sql-ref-syntax-ddl-create-table-datasource.html",
            platform="fabric_lakehouse",
            purpose="CREATE TABLE syntax",
        )]
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
        schema_expr = node.args.get("this")
        if schema_expr and hasattr(schema_expr, "expressions"):
            for expr in schema_expr.expressions:
                if isinstance(expr, exp.ColumnDef):
                    col, w, d = self._parse_column_def(expr)
                    columns.append(col)
                    warnings.extend(w)
                    doc_refs.extend(d)
                elif isinstance(expr, exp.PrimaryKey):
                    pk = IRPrimaryKey(columns=[c.name for c in expr.expressions])

        partition_by = self._extract_partition(raw_sql)
        cluster_by = self._extract_cluster_by(raw_sql)
        comment = self._extract_comment(raw_sql)

        return IRTable(
            name=name, schema_name=schema, database_name=db,
            columns=columns, primary_key=pk, foreign_keys=fks,
            unique_constraints=uniques, check_constraints=checks,
            partition_by=partition_by, cluster_by=cluster_by,
            is_temporary=is_temp, is_external=is_external, comment=comment,
            or_replace=or_replace, if_not_exists=if_not_exists,
        ), warnings, doc_refs

    def _parse_column_def(
        self, col_def: exp.ColumnDef
    ) -> Tuple[IRColumn, List[IRWarning], List[IRDocReference]]:
        warnings, doc_refs = [], []
        name = col_def.name
        type_node = col_def.args.get("kind")
        type_str = type_node.sql("spark2") if type_node else "STRING"
        ir_type, w, d = self._parse_data_type(type_str)
        warnings.extend(w)
        doc_refs.extend(d)

        is_nullable, default_val, identity, comment = True, None, None, None
        for constraint in col_def.constraints:
            c = constraint.kind if hasattr(constraint, "kind") else constraint
            if isinstance(c, exp.NotNullColumnConstraint):
                is_nullable = False
            elif isinstance(c, exp.DefaultColumnConstraint):
                default_val = c.this.sql() if c.this else None
            elif isinstance(c, exp.GeneratedAsIdentityColumnConstraint):
                s = c.args.get("start")
                inc = c.args.get("increment")
                start = int(str(s.this if hasattr(s, "this") else s)) if s else 1
                step = int(str(inc.this if hasattr(inc, "this") else inc)) if inc else 1
                identity = IRIdentity(start=start, increment=step)
            elif isinstance(c, exp.CommentColumnConstraint):
                comment = c.this.name if c.this else None

        return IRColumn(
            name=name, data_type=ir_type, is_nullable=is_nullable,
            default_value=default_val, identity=identity, comment=comment,
        ), warnings, doc_refs

    def _extract_partition(self, sql: str) -> Optional[IRPartition]:
        """
        Extract PARTITIONED BY (col1, col2)
        Docs: https://spark.apache.org/docs/latest/sql-ref-syntax-ddl-create-table-datasource.html
        """
        m = re.search(r"\bPARTITIONED\s+BY\s*\(([^)]+)\)", sql, re.IGNORECASE)
        if m:
            cols = [c.strip().strip("`").strip('"') for c in m.group(1).split(",")]
            return IRPartition(columns=cols, strategy="LIST")
        return None

    def _extract_cluster_by(self, sql: str) -> Optional[IRClusterBy]:
        """
        Fabric Lakehouse does not support CLUSTER BY (liquid clustering from Databricks).
        Extract it and emit a warning at generation time.
        Docs: https://learn.microsoft.com/en-us/fabric/data-engineering/lakehouse-overview
        """
        m = re.search(r"\bCLUSTER\s+BY\s*\(([^)]+)\)", sql, re.IGNORECASE)
        if m:
            cols = [c.strip().strip("`").strip('"') for c in m.group(1).split(",")]
            return IRClusterBy(columns=cols)
        return None

    def _extract_comment(self, sql: str) -> Optional[str]:
        m = re.search(r"\bCOMMENT\s+'([^']+)'", sql, re.IGNORECASE)
        return m.group(1) if m else None

    def _parse_create_view(
        self, node: exp.Create, raw_sql: str
    ) -> Tuple[Optional[IRView], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(
            title="Spark SQL CREATE VIEW",
            url="https://spark.apache.org/docs/latest/sql-ref-syntax-ddl-create-view.html",
            platform="fabric_lakehouse",
            purpose="CREATE VIEW",
        )]
        vn = node.find(exp.Table)
        name = vn.name if vn else "unknown"
        query = node.args.get("expression") or node.args.get("this")
        definition = query.sql(dialect="spark2") if query else ""
        return IRView(
            name=name,
            schema_name=(vn.db if vn else None) or None,
            definition=definition,
            or_replace=bool(node.args.get("replace")),
        ), [], doc_refs

    def _parse_create_mv(
        self, node: exp.Create, raw_sql: str, is_mlv: bool = False
    ) -> Tuple[Optional[IRMaterializedView], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(
            title="Fabric Lakehouse Materialized Lake View",
            url="https://learn.microsoft.com/en-us/fabric/data-engineering/materialized-lake-view-overview",
            platform="fabric_lakehouse",
            purpose="CREATE MATERIALIZED LAKE VIEW",
        )]
        mn = node.find(exp.Table)
        name = mn.name if mn else "unknown"
        query = node.args.get("expression") or node.args.get("this")
        definition = query.sql(dialect="spark2") if query else ""
        return IRMaterializedView(
            name=name,
            schema_name=(mn.db if mn else None) or None,
            definition=definition,
            or_replace=bool(node.args.get("replace")),
            refresh_type=RefreshType.AUTO,
            auto_refresh=True,
        ), [], doc_refs
