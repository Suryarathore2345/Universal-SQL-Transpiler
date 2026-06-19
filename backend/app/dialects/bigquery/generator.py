"""
BigQuery (GoogleSQL) generator — converts IR to BigQuery DDL.

Official docs used:
  CREATE TABLE:   https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_table_statement
  Data types:     https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types
  PARTITION BY:   https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#partition_expression
  CLUSTER BY:     https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#clustering_column_list
  OPTIONS:        https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#table_option_list
  CREATE VIEW:    https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_view_statement
  CREATE MV:      https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_materialized_view_statement
"""
from __future__ import annotations

from typing import List, Tuple

from app.dialects.base import DialectGenerator
from app.ir.models import (
    Dialect, DistributionStyle, IRColumn, IRDocReference, IRFunction,
    IRMaterializedView, IRProcedure, IRTable, IRView, IRWarning, SortKeyType,
    Warningseverity,
)


class BigQueryGenerator(DialectGenerator):
    """
    Generates BigQuery (GoogleSQL) DDL from IR.
    Uses backtick quoting: `project.dataset.table`.
    """

    dialect = Dialect.BIGQUERY

    # Max columns in CLUSTER BY per BigQuery docs
    _CLUSTER_BY_MAX = 4

    def _quote_identifier(self, name: str) -> str:
        return f"`{name}`"

    def _qualified_name(self, obj) -> str:
        parts = []
        if getattr(obj, "database_name", None):
            parts.append(self._quote_identifier(obj.database_name))
        if getattr(obj, "schema_name", None):
            parts.append(self._quote_identifier(obj.schema_name))
        parts.append(self._quote_identifier(obj.name))
        return ".".join(parts)

    # -------------------------------------------------------------------------
    # CREATE TABLE
    # -------------------------------------------------------------------------

    def generate_table(
        self, table: IRTable
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        warnings: List[IRWarning] = []
        doc_refs = [IRDocReference(
            title="BigQuery CREATE TABLE",
            url="https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_table_statement",
            platform="bigquery",
            purpose="DDL generation reference",
        )]

        qname = self._qualified_name(table)
        lines = []

        for col in table.columns:
            col_sql, w, d = self._column_def(col)
            lines.append(f"  {col_sql}")
            warnings.extend(w)
            doc_refs.extend(d)

        # BigQuery PKs/FKs are informational (NOT ENFORCED) as of 2024
        if table.primary_key:
            pk_cols = ", ".join(self._quote_identifier(c) for c in table.primary_key.columns)
            lines.append(f"  PRIMARY KEY ({pk_cols}) NOT ENFORCED")

        for fk in table.foreign_keys:
            cols = ", ".join(self._quote_identifier(c) for c in fk.columns)
            ref_q = self._quote_identifier(fk.ref_table)
            if fk.ref_schema:
                ref_q = f"{self._quote_identifier(fk.ref_schema)}.{ref_q}"
            ref_cols = ", ".join(self._quote_identifier(c) for c in fk.ref_columns)
            lines.append(f"  FOREIGN KEY ({cols}) REFERENCES {ref_q} ({ref_cols}) NOT ENFORCED")

        body = ",\n".join(lines)
        if table.or_replace:
            sql = f"CREATE OR REPLACE TABLE {qname} (\n{body}\n)"
        elif table.if_not_exists:
            sql = f"CREATE TABLE IF NOT EXISTS {qname} (\n{body}\n)"
        else:
            sql = f"CREATE TABLE {qname} (\n{body}\n)"

        # PARTITION BY
        partition_expr = self._partition_clause(table, warnings, doc_refs)
        if partition_expr:
            sql += f"\nPARTITION BY {partition_expr}"
            doc_refs.append(IRDocReference(
                title="BigQuery PARTITION BY",
                url="https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#partition_expression",
                platform="bigquery",
                purpose="Partition clause generation",
            ))

        # CLUSTER BY (max 4 columns)
        cluster_cols = None
        if table.cluster_by and table.cluster_by.columns:
            cluster_cols = table.cluster_by.columns
        elif table.sort_key and table.sort_key.columns:
            cluster_cols = table.sort_key.columns
            warnings.append(IRWarning(
                feature="SORTKEY_TO_CLUSTER_BY",
                message="Redshift SORTKEY converted to BigQuery CLUSTER BY. "
                        "BigQuery clustering improves query performance by collocating related data. "
                        "Maximum 4 columns.",
                doc_url="https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#clustering_column_list",
                severity=Warningseverity.INFO,
                fallback_applied=True,
            ))

        if cluster_cols:
            cols = cluster_cols[:self._CLUSTER_BY_MAX]
            if len(cluster_cols) > self._CLUSTER_BY_MAX:
                warnings.append(IRWarning(
                    feature="CLUSTER_BY_TRUNCATED",
                    message=f"BigQuery CLUSTER BY supports max {self._CLUSTER_BY_MAX} columns. "
                            f"Truncated from {len(cluster_cols)} to {self._CLUSTER_BY_MAX}.",
                    doc_url="https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#clustering_column_list",
                    severity=Warningseverity.WARNING,
                    fallback_applied=True,
                ))
            cl_cols_str = ", ".join(self._quote_identifier(c) for c in cols)
            sql += f"\nCLUSTER BY {cl_cols_str}"
            doc_refs.append(IRDocReference(
                title="BigQuery CLUSTER BY",
                url="https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#clustering_column_list",
                platform="bigquery",
                purpose="Cluster clause generation",
            ))

        # Distribution is not supported in BigQuery
        if table.distribution:
            warnings.append(IRWarning(
                feature="DISTRIBUTION_NOT_SUPPORTED_BIGQUERY",
                message="BigQuery does not support explicit DISTRIBUTION clauses. "
                        "Data distribution is managed automatically by BigQuery's storage engine (Capacitor). "
                        "Distribution setting dropped.",
                doc_url="https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_table_statement",
                severity=Warningseverity.INFO,
                unsupported=True,
                fallback_applied=True,
            ))

        return sql + ";", warnings, doc_refs

    def _column_def(
        self, col: IRColumn
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        warnings: List[IRWarning] = []
        doc_refs: List[IRDocReference] = []

        type_str, w, d = self._type_to_sql(col.data_type)
        warnings.extend(w); doc_refs.extend(d)

        nullable = "" if col.is_nullable else " NOT NULL"
        parts = [f"{self._quote_identifier(col.name)} {type_str}{nullable}"]

        # BigQuery has no native IDENTITY. Document the workaround.
        if col.identity:
            warnings.append(IRWarning(
                feature="IDENTITY_NOT_SUPPORTED_BIGQUERY",
                message=f"BigQuery does not support IDENTITY / AUTOINCREMENT columns. "
                        f"For a surrogate key, use GENERATE_UUID() as a DEFAULT expression for STRING, "
                        f"or ROW_NUMBER() OVER() in queries for INT64. "
                        f"Column '{col.name}' converted to INT64 without auto-increment.",
                doc_url="https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_table_statement",
                severity=Warningseverity.WARNING,
                unsupported=True,
                fallback_applied=True,
            ))

        if col.default_value is not None:
            parts[0] += f" DEFAULT {col.default_value}"

        return parts[0], warnings, doc_refs

    def _partition_clause(
        self, table: IRTable, warnings: list, doc_refs: list
    ) -> str:
        """
        Generate PARTITION BY expression.
        If source had a DATE/TIMESTAMP column partition, use DATE() wrapper.
        If source had SORTKEY, no partition mapping (not the same concept).
        """
        if table.partition_by and table.partition_by.columns:
            p = table.partition_by
            bq_expr = (p.partition_properties or {}).get("bq_partition_expr")
            if bq_expr:
                return bq_expr
            if p.columns:
                col = self._quote_identifier(p.columns[0])
                strategy = (p.strategy or "DATE").upper()
                if strategy in ("DATE", "TIMESTAMP"):
                    return f"DATE({col})"
                elif strategy == "RANGE":
                    return col
                return col
        return ""

    # -------------------------------------------------------------------------
    # CREATE VIEW
    # -------------------------------------------------------------------------

    def generate_view(
        self, view: IRView
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="BigQuery CREATE VIEW", url="https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_view_statement", platform="bigquery", purpose="View generation")]
        or_replace = "OR REPLACE " if view.or_replace else ""
        qname = self._qualified_name(view)
        defn, warnings = self._apply_bigquery_view_conversions(view.definition)
        return f"CREATE {or_replace}VIEW {qname} AS\n{defn};", warnings, doc_refs

    # -------------------------------------------------------------------------
    # CREATE MATERIALIZED VIEW
    # -------------------------------------------------------------------------

    def generate_materialized_view(
        self, mv: IRMaterializedView
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        BigQuery CREATE MATERIALIZED VIEW.
        Docs: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_materialized_view_statement

        Options: ENABLE_REFRESH, REFRESH_INTERVAL_MINUTES.
        Limitations: Only SELECT with simple aggregations; no subqueries, no UNION.
        """
        doc_refs = [IRDocReference(
            title="BigQuery CREATE MATERIALIZED VIEW",
            url="https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_materialized_view_statement",
            platform="bigquery",
            purpose="MV generation reference",
        )]

        qname = self._qualified_name(mv)
        or_replace = "OR REPLACE " if getattr(mv, "or_replace", False) else ""

        enable_refresh = "TRUE" if mv.auto_refresh else "FALSE"
        interval = mv.refresh_interval_minutes or 60
        options_str = (
            f"OPTIONS(\n"
            f"  enable_refresh = {enable_refresh},\n"
            f"  refresh_interval_minutes = {interval}\n"
            f")"
        )

        defn, conv_warnings = self._apply_bigquery_view_conversions(mv.definition)
        sql = (
            f"CREATE {or_replace}MATERIALIZED VIEW {qname}\n"
            f"{options_str}\n"
            f"AS\n"
            f"{defn};"
        )
        warnings = list(conv_warnings) + [IRWarning(
            feature="BIGQUERY_MV_LIMITATIONS",
            message="BigQuery materialized views support only simple SELECT queries "
                    "(aggregation without subqueries, UNION, or JOIN to MVs). "
                    "Complex queries from the source may not be supported. "
                    "Verify the query definition satisfies BigQuery MV constraints.",
            doc_url="https://cloud.google.com/bigquery/docs/materialized-views-intro#limitations",
            severity=Warningseverity.WARNING,
        )]


        return sql, warnings, doc_refs

    # -------------------------------------------------------------------------
    # CREATE PROCEDURE / FUNCTION
    # -------------------------------------------------------------------------

    def generate_procedure(
        self, proc: IRProcedure
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        BigQuery scripting procedure.
        Docs: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_procedure
        Syntax: CREATE [OR REPLACE] PROCEDURE dataset.name (params) BEGIN body END;
        """
        from app.dialects.procedure_utils import format_param_bigquery, format_body_comment
        doc_refs = [IRDocReference(
            title="BigQuery CREATE PROCEDURE",
            url="https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_procedure",
            platform="bigquery",
            purpose="Scripting procedure generation",
        )]
        qname = self._qualified_name(proc)
        params_str = ",\n    ".join(format_param_bigquery(p, self.mapper, self.dialect) for p in proc.parameters)
        or_replace = "OR REPLACE " if proc.or_replace else ""
        body_comment = format_body_comment(proc.language or "sql", "bigquery", proc.language)
        params_block = f"\n    {params_str}\n" if params_str else ""
        sql = (
            f"CREATE {or_replace}PROCEDURE {qname}({params_block})\nBEGIN\n"
            f"{body_comment}\n"
            f"{proc.body}\n"
            f"END;"
        )
        return sql, [IRWarning(
            feature="PROCEDURE_MANUAL_REVIEW",
            message="Procedure body requires manual review for BigQuery scripting syntax. "
                    "Docs: https://cloud.google.com/bigquery/docs/reference/standard-sql/scripting",
            severity=Warningseverity.WARNING,
        )], doc_refs

    def generate_function(
        self, func: IRFunction
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        BigQuery scalar or TVF UDF.
        Docs: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_function_statement
        Supports SQL and JavaScript UDFs.
        """
        from app.dialects.procedure_utils import format_param_bigquery, format_body_comment
        doc_refs = [IRDocReference(
            title="BigQuery CREATE FUNCTION",
            url="https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_function_statement",
            platform="bigquery",
            purpose="UDF generation",
        )]
        qname = self._qualified_name(func)
        params_str = ", ".join(format_param_bigquery(p, self.mapper, self.dialect) for p in func.parameters)
        or_replace = "OR REPLACE " if func.or_replace else ""
        ret_type = "ANY TYPE"
        if func.return_type:
            ret_type, _, _ = self._type_to_sql(func.return_type)
        body_comment = format_body_comment(func.language or "sql", "bigquery", func.language)
        lang = (func.language or "SQL").upper()
        if lang in ("JAVASCRIPT", "JS"):
            sql = (
                f"CREATE {or_replace}FUNCTION {qname}({params_str})\n"
                f"RETURNS {ret_type}\n"
                f"LANGUAGE js\n"
                f"AS r\"\"\"\n"
                f"{body_comment}\n"
                f"{func.body}\n"
                f"\"\"\";"
            )
        else:
            sql = (
                f"CREATE {or_replace}FUNCTION {qname}({params_str})\n"
                f"RETURNS {ret_type}\n"
                f"AS (\n"
                f"  {body_comment}\n"
                f"  {func.body}\n"
                f");"
            )
        return sql, [IRWarning(
            feature="FUNCTION_MANUAL_REVIEW",
            message="UDF body requires manual review for BigQuery SQL/JavaScript function syntax. "
                    "Docs: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_function_statement",
            severity=Warningseverity.WARNING,
        )], doc_refs
