"""
BigQuery (GoogleSQL) parser — converts BigQuery DDL to IR.

Official docs used:
  CREATE TABLE:   https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_table_statement
  Data types:     https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types
  PARTITION BY:   https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#partition_expression
  CLUSTER BY:     https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#clustering_column_list
  OPTIONS:        https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#table_option_list
  CREATE VIEW:    https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_view_statement
  CREATE MV:      https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_materialized_view_statement

Key BigQuery facts:
  - Identifiers: `project.dataset.table` — backtick-quoted
  - PARTITION BY: date_column | TIMESTAMP_TRUNC(col, granularity) | RANGE_BUCKET(col, GENERATE_ARRAY(...))
  - CLUSTER BY: up to 4 columns
  - OPTIONS: expiration_timestamp, require_partition_filter, friendly_name, description
  - No native IDENTITY/SEQUENCE — use GENERATE_UUID() for GUIDs or ROW_NUMBER() OVER()
  - MV: CREATE MATERIALIZED VIEW with ENABLE_REFRESH, REFRESH_INTERVAL_MINUTES OPTIONS
  - No NOT ENFORCED constraints (unlike Synapse) — FK/PK are informational only
"""
from __future__ import annotations

import re
from typing import List, Optional, Tuple

import sqlglot
import sqlglot.expressions as exp

from app.dialects.base import DialectParser
from app.ir.models import (
    Dialect, IRCheckConstraint, IRClusterBy, IRColumn, IRDataType, IRDDLObject,
    IRDocReference, IRForeignKey, IRFunction, IRMaterializedView, IRPartition,
    IRPrimaryKey, IRProcedure, IRTable, IRUniqueConstraint, IRView, IRWarning,
    RefreshType, Warningseverity,
)


class BigQueryParser(DialectParser):
    """
    Parses BigQuery (GoogleSQL) DDL into IR using sqlglot bigquery dialect + custom regex.
    """

    dialect = Dialect.BIGQUERY
    _SQLGLOT_DIALECT = "bigquery"

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
                r, w, d = self._parse_proc_from_sql(sql, body_style="bigquery")
                doc_refs.append(IRDocReference(title="BigQuery CREATE PROCEDURE", url="https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_procedure", platform="bigquery", purpose="Scripting procedure"))
                return r, warnings + w, doc_refs + d
            elif kind == "FUNCTION":
                r, w, d = self._parse_func_from_sql(sql, body_style="best_effort")
                doc_refs.append(IRDocReference(title="BigQuery CREATE FUNCTION", url="https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_function_statement", platform="bigquery", purpose="UDF"))
                return r, warnings + w, doc_refs + d

        if re.search(r'\bCREATE\b.*?\bPROCEDURE\b', sql, re.IGNORECASE | re.DOTALL):
            r, w, d = self._parse_proc_from_sql(sql, body_style="bigquery")
            return r, warnings + w, d
        if re.search(r'\bCREATE\b.*?\bFUNCTION\b', sql, re.IGNORECASE | re.DOTALL):
            r, w, d = self._parse_func_from_sql(sql, body_style="best_effort")
            return r, warnings + w, d

        warnings.append(IRWarning(feature="UNSUPPORTED_STATEMENT", message=f"Not supported: {type(parsed).__name__}", severity=Warningseverity.WARNING))
        return None, warnings, doc_refs

    def _parse_create_table(self, node: exp.Create, raw_sql: str) -> Tuple[Optional[IRTable], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="BigQuery CREATE TABLE", url="https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_table_statement", platform="bigquery", purpose="CREATE TABLE syntax")]
        warnings: List[IRWarning] = []

        tbl = node.find(exp.Table)
        name = tbl.name if tbl else "unknown"
        schema = (tbl.db if tbl else None) or None
        db = (tbl.catalog if tbl else None) or None

        or_replace = bool(node.args.get("replace"))
        if_not_exists = bool(node.args.get("exists"))

        columns, pk, fks, uniques, checks = [], None, [], [], []
        schema_expr = node.args.get("this")
        if schema_expr and hasattr(schema_expr, "expressions"):
            for expr in schema_expr.expressions:
                if isinstance(expr, exp.ColumnDef):
                    col, w, d = self._parse_column_def(expr)
                    columns.append(col); warnings.extend(w); doc_refs.extend(d)
                elif isinstance(expr, exp.PrimaryKey):
                    pk = IRPrimaryKey(columns=[c.name for c in expr.expressions])

        cluster_by = self._extract_cluster_by(raw_sql)
        partition_by = self._extract_partition(raw_sql)

        return IRTable(name=name, schema_name=schema, database_name=db, columns=columns, primary_key=pk, foreign_keys=fks, unique_constraints=uniques, check_constraints=checks, cluster_by=cluster_by, partition_by=partition_by, or_replace=or_replace, if_not_exists=if_not_exists), warnings, doc_refs

    def _parse_column_def(self, col_def: exp.ColumnDef) -> Tuple[IRColumn, List[IRWarning], List[IRDocReference]]:
        warnings, doc_refs = [], []
        name = col_def.name
        type_node = col_def.args.get("kind")
        type_str = type_node.sql("bigquery") if type_node else "STRING"
        ir_type, w, d = self._parse_data_type(type_str)
        warnings.extend(w); doc_refs.extend(d)

        is_nullable, default_val = True, None
        for constraint in col_def.constraints:
            c = constraint.kind if hasattr(constraint, "kind") else constraint
            if isinstance(c, exp.NotNullColumnConstraint): is_nullable = False
            elif isinstance(c, exp.DefaultColumnConstraint): default_val = c.this.sql() if c.this else None

        return IRColumn(name=name, data_type=ir_type, is_nullable=is_nullable, default_value=default_val), warnings, doc_refs

    def _extract_cluster_by(self, sql: str) -> Optional[IRClusterBy]:
        """
        Extract CLUSTER BY clause — up to 4 columns.
        Docs: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#clustering_column_list
        """
        m = re.search(r"\bCLUSTER\s+BY\s+((?:`[^`]+`|\w+)(?:\s*,\s*(?:`[^`]+`|\w+))*)", sql, re.IGNORECASE)
        if m:
            cols = [c.strip().strip("`") for c in m.group(1).split(",")]
            return IRClusterBy(columns=cols[:4])
        return None

    def _extract_partition(self, sql: str) -> Optional[IRPartition]:
        """
        Extract PARTITION BY — date column, TIMESTAMP_TRUNC, RANGE_BUCKET.
        Docs: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#partition_expression
        """
        m = re.search(r"\bPARTITION\s+BY\s+(.+?)(?:\s+CLUSTER|\s+OPTIONS|\s+AS\s+SELECT|;|$)", sql, re.IGNORECASE | re.DOTALL)
        if m:
            expr = m.group(1).strip()
            # Simple column reference
            simple = re.match(r"^(?:`([^`]+)`|(\w+))$", expr)
            if simple:
                col = simple.group(1) or simple.group(2)
                return IRPartition(columns=[col], strategy="DATE", partition_properties={"bq_partition_expr": expr})
            # Extract column from function call
            fn_m = re.match(r"(?:DATE|TIMESTAMP_TRUNC|DATE_TRUNC)\s*\(\s*`?(\w+)`?", expr, re.IGNORECASE)
            if fn_m:
                return IRPartition(columns=[fn_m.group(1)], strategy="DATE", partition_properties={"bq_partition_expr": expr})
            return IRPartition(columns=[], strategy="RANGE", partition_properties={"bq_partition_expr": expr})
        return None

    def _parse_create_view(self, node: exp.Create, raw_sql: str) -> Tuple[Optional[IRView], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="BigQuery CREATE VIEW", url="https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_view_statement", platform="bigquery", purpose="CREATE VIEW")]
        vn = node.find(exp.Table)
        name = vn.name if vn else "unknown"
        query = node.args.get("expression") or node.args.get("this")
        definition = query.sql(dialect="bigquery") if query else ""
        return IRView(name=name, schema_name=(vn.db if vn else None) or None, database_name=(vn.catalog if vn else None) or None, definition=definition, or_replace=bool(node.args.get("replace"))), [], doc_refs

    def _parse_create_mv(self, node: exp.Create, raw_sql: str) -> Tuple[Optional[IRMaterializedView], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="BigQuery CREATE MATERIALIZED VIEW", url="https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_materialized_view_statement", platform="bigquery", purpose="CREATE MV")]
        mn = node.find(exp.Table)
        name = mn.name if mn else "unknown"
        query = node.args.get("expression") or node.args.get("this")
        definition = query.sql(dialect="bigquery") if query else ""
        # Extract ENABLE_REFRESH / REFRESH_INTERVAL_MINUTES from OPTIONS clause
        enable_refresh = "ENABLE_REFRESH=TRUE" in raw_sql.upper().replace(" ", "")
        interval_m = re.search(r"REFRESH_INTERVAL_MINUTES\s*=\s*(\d+)", raw_sql, re.IGNORECASE)
        refresh_interval = int(interval_m.group(1)) if interval_m else None
        return IRMaterializedView(name=name, schema_name=(mn.db if mn else None) or None, database_name=(mn.catalog if mn else None) or None, definition=definition, refresh_type=RefreshType.AUTO if enable_refresh else RefreshType.MANUAL, auto_refresh=enable_refresh, refresh_interval_minutes=refresh_interval), [], doc_refs
