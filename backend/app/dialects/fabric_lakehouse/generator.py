"""
Microsoft Fabric Lakehouse (Spark SQL / Delta Lake) generator.

Official docs used:
  Spark SQL CREATE TABLE:
    https://spark.apache.org/docs/latest/sql-ref-syntax-ddl-create-table-datasource.html
  Delta Lake:
    https://docs.delta.io/latest/delta-intro.html
  Fabric Lakehouse:
    https://learn.microsoft.com/en-us/fabric/data-engineering/lakehouse-overview
  Materialized Lake Views (MLV):
    https://learn.microsoft.com/en-us/fabric/data-engineering/materialized-lake-view-overview
  Spark SQL CREATE VIEW:
    https://spark.apache.org/docs/latest/sql-ref-syntax-ddl-create-view.html
  Spark SQL CREATE FUNCTION:
    https://spark.apache.org/docs/latest/sql-ref-syntax-ddl-create-function.html

Key Fabric Lakehouse generator facts (verified June 2026):
  - Uses backtick quoting: `name`
  - Tables always emit USING DELTA (Delta Lake is the default format)
  - PARTITIONED BY (cols) supported
  - CLUSTER BY (liquid clustering) NOT supported in Fabric Lakehouse Spark SQL;
    emit warning suggesting PARTITIONED BY instead
  - DISTRIBUTION not applicable; drop with warning
  - IDENTITY columns: not supported in Spark SQL DDL; emit warning, use BIGINT
  - No stored procedures: emit warning to use Fabric Notebook
  - Materialized Lake Views: CREATE OR REPLACE MATERIALIZED LAKE VIEW
    Requires Fabric Runtime 1.3+
"""
from __future__ import annotations

from typing import List, Tuple

from app.dialects.base import DialectGenerator
from app.ir.models import (
    Dialect, GenericType, IRColumn, IRDocReference, IRFunction,
    IRMaterializedView, IRProcedure, IRTable, IRTrigger, IRView, IRWarning,
    Warningseverity,
)


class FabricLakehouseGenerator(DialectGenerator):
    """
    Generates Fabric Lakehouse Spark SQL DDL from IR.
    Uses backtick quoting.
    """

    dialect = Dialect.FABRIC_LAKEHOUSE

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
            title="Spark SQL CREATE TABLE (Delta)",
            url="https://spark.apache.org/docs/latest/sql-ref-syntax-ddl-create-table-datasource.html",
            platform="fabric_lakehouse",
            purpose="DDL generation reference",
        )]

        temp = "TEMPORARY " if table.is_temporary else ""
        ext = "EXTERNAL " if table.is_external else ""
        qname = self._qualified_name(table)
        lines = []

        for col in table.columns:
            col_sql, w, d = self._column_def(col)
            lines.append(f"    {col_sql}")
            warnings.extend(w)
            doc_refs.extend(d)

        if table.primary_key:
            pk_cols = ", ".join(self._quote_identifier(c) for c in table.primary_key.columns)
            lines.append(f"    PRIMARY KEY ({pk_cols})")

        body = ",\n".join(lines)
        if table.or_replace:
            sql = f"CREATE OR REPLACE {temp}{ext}TABLE {qname} (\n{body}\n)\nUSING DELTA"
        elif table.if_not_exists:
            sql = f"CREATE {temp}{ext}TABLE IF NOT EXISTS {qname} (\n{body}\n)\nUSING DELTA"
        else:
            sql = f"CREATE {temp}{ext}TABLE {qname} (\n{body}\n)\nUSING DELTA"

        if table.comment:
            sql += f"\nCOMMENT '{table.comment}'"

        has_partition = bool(table.partition_by and table.partition_by.columns)
        has_cluster = bool(table.cluster_by and table.cluster_by.columns)
        has_sortkey = bool(table.sort_key and table.sort_key.columns)

        # CLUSTER BY: not supported in Fabric Lakehouse — suggest PARTITIONED BY
        if has_cluster:
            warnings.append(IRWarning(
                feature="CLUSTER_BY_NOT_SUPPORTED_FABRIC_LAKEHOUSE",
                message=(
                    "CLUSTER BY (Databricks liquid clustering) is not supported in "
                    "Microsoft Fabric Lakehouse Spark SQL. "
                    "Consider using PARTITIONED BY for physical data organization. "
                    "CLUSTER BY has been dropped."
                ),
                doc_url="https://learn.microsoft.com/en-us/fabric/data-engineering/lakehouse-overview",
                severity=Warningseverity.WARNING,
                unsupported=True,
                fallback_applied=False,
            ))
            # Fall through to partition if available
            if has_partition:
                pt_cols = ", ".join(self._quote_identifier(c) for c in table.partition_by.columns)
                sql += f"\nPARTITIONED BY ({pt_cols})"
        elif has_partition:
            pt_cols = ", ".join(self._quote_identifier(c) for c in table.partition_by.columns)
            sql += f"\nPARTITIONED BY ({pt_cols})"
        elif has_sortkey:
            # Redshift SORTKEY → PARTITIONED BY (best-effort mapping)
            pt_cols = ", ".join(self._quote_identifier(c) for c in table.sort_key.columns)
            sql += f"\nPARTITIONED BY ({pt_cols})"
            warnings.append(IRWarning(
                feature="SORTKEY_TO_PARTITIONED_BY",
                message=(
                    "Redshift SORTKEY converted to Fabric Lakehouse PARTITIONED BY. "
                    "Semantics differ: Redshift sorts rows; Spark PARTITIONED BY creates "
                    "physical directory partitions. Validate partition strategy."
                ),
                doc_url="https://spark.apache.org/docs/latest/sql-ref-syntax-ddl-create-table-datasource.html",
                severity=Warningseverity.INFO,
                fallback_applied=True,
            ))

        # Distribution: not applicable in Spark/Delta
        if table.distribution:
            warnings.append(IRWarning(
                feature="DISTRIBUTION_NOT_SUPPORTED_FABRIC_LAKEHOUSE",
                message=(
                    "DISTRIBUTION clauses are not applicable to Fabric Lakehouse / Spark SQL. "
                    "Delta Lake manages data distribution automatically. "
                    "DISTRIBUTION setting dropped."
                ),
                doc_url="https://learn.microsoft.com/en-us/fabric/data-engineering/lakehouse-overview",
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
        warnings.extend(w)
        doc_refs.extend(d)

        parts = [self._quote_identifier(col.name), type_str]

        # IDENTITY: not supported in Spark SQL DDL
        if col.identity:
            warnings.append(IRWarning(
                feature="IDENTITY_NOT_SUPPORTED_FABRIC_LAKEHOUSE",
                message=(
                    f"Column '{col.name}': IDENTITY({col.identity.start},{col.identity.increment}) "
                    f"is NOT supported in Spark SQL (Fabric Lakehouse) DDL. "
                    f"Spark SQL has no IDENTITY / GENERATED ALWAYS AS IDENTITY for tables. "
                    f"Use a Fabric Notebook to generate surrogate keys (e.g., monotonically_increasing_id() "
                    f"or uuid()), or compute keys during ingestion. "
                    f"Column emitted as BIGINT without IDENTITY."
                ),
                doc_url="https://spark.apache.org/docs/latest/sql-ref-syntax-ddl-create-table-datasource.html",
                severity=Warningseverity.WARNING,
                fallback_applied=True,
                unsupported=True,
            ))
            # Override type to BIGINT if it was an int type
            if col.data_type.generic_type in (
                GenericType.INT32, GenericType.INT64, GenericType.INT16, GenericType.INT8
            ):
                parts[1] = "BIGINT"

        if not col.is_nullable:
            parts.append("NOT NULL")

        if col.default_value is not None:
            parts.append(f"DEFAULT {col.default_value}")

        if col.comment:
            parts.append(f"COMMENT '{col.comment}'")

        return " ".join(parts), warnings, doc_refs

    # -------------------------------------------------------------------------
    # CREATE VIEW
    # -------------------------------------------------------------------------

    def generate_view(
        self, view: IRView
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(
            title="Spark SQL CREATE VIEW",
            url="https://spark.apache.org/docs/latest/sql-ref-syntax-ddl-create-view.html",
            platform="fabric_lakehouse",
            purpose="View generation",
        )]
        or_replace = "OR REPLACE " if view.or_replace else ""
        qname = self._qualified_name(view)
        defn, warnings = self._apply_spark_view_conversions(view.definition)
        return f"CREATE {or_replace}VIEW {qname} AS\n{defn};", warnings, doc_refs

    # -------------------------------------------------------------------------
    # CREATE MATERIALIZED LAKE VIEW
    # -------------------------------------------------------------------------

    def generate_materialized_view(
        self, mv: IRMaterializedView
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Fabric Lakehouse Materialized Lake Views (MLV) — native syntax.
        Syntax: CREATE OR REPLACE MATERIALIZED LAKE VIEW schema.view AS <SELECT>
        Requires: Fabric Runtime 1.3+
        Docs: https://learn.microsoft.com/en-us/fabric/data-engineering/materialized-lake-view-overview

        Key facts (verified June 2026):
          - MLVs are automatically refreshed by the Fabric runtime
          - They do NOT support SCHEDULE/CRON syntax (unlike Databricks MVs)
          - Runtime 1.3+ required (GA'd in 2025)
          - The SELECT body must be a valid Spark SQL query
        """
        doc_refs = [IRDocReference(
            title="Fabric Lakehouse Materialized Lake View",
            url="https://learn.microsoft.com/en-us/fabric/data-engineering/materialized-lake-view-overview",
            platform="fabric_lakehouse",
            purpose="MLV generation reference",
        )]

        qname = self._qualified_name(mv)
        or_replace = "OR REPLACE " if getattr(mv, "or_replace", False) else ""
        defn, conv_warnings = self._apply_spark_view_conversions(mv.definition)

        sql = (
            f"CREATE {or_replace}MATERIALIZED LAKE VIEW {qname} AS\n"
            f"{defn};"
        )

        warnings = list(conv_warnings) + [IRWarning(
            feature="FABRIC_LAKEHOUSE_MLV_RUNTIME",
            message=(
                "Fabric Lakehouse Materialized Lake Views (MLV) require Fabric Runtime 1.3+. "
                "MLVs are automatically refreshed by the Fabric runtime. "
                "Ensure your Lakehouse is on Runtime 1.3 or newer before deploying. "
                "Docs: https://learn.microsoft.com/en-us/fabric/data-engineering/materialized-lake-view-overview"
            ),
            doc_url="https://learn.microsoft.com/en-us/fabric/data-engineering/materialized-lake-view-overview",
            severity=Warningseverity.INFO,
        )]

        return sql, warnings, doc_refs

    # -------------------------------------------------------------------------
    # CREATE PROCEDURE — not supported
    # -------------------------------------------------------------------------

    def generate_procedure(
        self, proc: IRProcedure
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Spark SQL (Fabric Lakehouse) does NOT support stored procedures.
        Docs: https://learn.microsoft.com/en-us/fabric/data-engineering/author-notebook-python

        Fallback: emit as a syntactically valid, executable no-op SQL
        function stub (matching the Databricks generator's equivalent
        fallback — both are Spark SQL) rather than a comment-only block.
        A comment-only "statement" is not valid SQL at all and cannot be
        deployed/tested even as a harmless placeholder; a real CREATE
        FUNCTION at least gives the user something that runs while they
        migrate the logic to a Fabric Notebook.
        """
        from app.dialects.procedure_utils import format_param_databricks, format_body_comment
        doc_refs = [IRDocReference(
            title="Fabric Lakehouse — no stored procedures (use Notebooks)",
            url="https://learn.microsoft.com/en-us/fabric/data-engineering/author-notebook-python",
            platform="fabric_lakehouse",
            purpose="Procedure-to-notebook migration reference",
        )]
        qname = self._qualified_name(proc)
        params_str = ", ".join(format_param_databricks(p, self.mapper, self.dialect) for p in proc.parameters)
        or_replace = "OR REPLACE " if proc.or_replace else ""
        body_comment = format_body_comment(proc.language or "unknown", "fabric_lakehouse", proc.language)
        sql = (
            f"-- Fabric Lakehouse / Spark SQL does NOT support CREATE PROCEDURE.\n"
            f"-- Docs: https://learn.microsoft.com/en-us/fabric/data-engineering/author-notebook-python\n"
            f"-- Migration: Convert this procedure to a Fabric Notebook (Python/PySpark).\n"
            f"CREATE {or_replace}FUNCTION {qname}({params_str})\n"
            f"RETURNS STRING\n"
            f"RETURN (\n"
            f"  -- {body_comment}\n"
            f"  -- Original body preserved below — NOT executable as-is:\n"
            f"  -- {proc.body.replace(chr(10), chr(10) + '  -- ')}\n"
            f"  NULL\n"
            f");"
        )
        return sql, [IRWarning(
            feature="PROCEDURE_NOT_SUPPORTED_FABRIC_LAKEHOUSE",
            message=(
                "Spark SQL (Fabric Lakehouse) does not support stored procedures. "
                "Convert the procedure logic to a Fabric Notebook using PySpark or Python. "
                "The original body has been preserved as SQL comments. "
                "Docs: https://learn.microsoft.com/en-us/fabric/data-engineering/author-notebook-python"
            ),
            doc_url="https://learn.microsoft.com/en-us/fabric/data-engineering/author-notebook-python",
            severity=Warningseverity.WARNING,
            unsupported=True,
            fallback_applied=True,
        )], doc_refs

    # -------------------------------------------------------------------------
    # CREATE FUNCTION
    # -------------------------------------------------------------------------

    def generate_function(
        self, func: IRFunction
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Spark SQL UDF.
        Docs: https://spark.apache.org/docs/latest/sql-ref-syntax-ddl-create-function.html
        """
        from app.dialects.procedure_utils import format_param_databricks, format_body_comment
        doc_refs = [IRDocReference(
            title="Spark SQL CREATE FUNCTION",
            url="https://spark.apache.org/docs/latest/sql-ref-syntax-ddl-create-function.html",
            platform="fabric_lakehouse",
            purpose="UDF generation",
        )]
        qname = self._qualified_name(func)
        params_str = ", ".join(
            format_param_databricks(p, self.mapper, self.dialect) for p in func.parameters
        )
        or_replace = "OR REPLACE " if func.or_replace else ""
        ret_type = "STRING"
        if func.return_type:
            ret_type, _, _ = self._type_to_sql(func.return_type)
        body_comment = format_body_comment(func.language or "unknown", "fabric_lakehouse", func.language)
        lang = (func.language or "SQL").upper()

        if lang in ("PYTHON", "PLPYTHON3U", "PLPYTHONU"):
            sql = (
                f"CREATE {or_replace}FUNCTION {qname}({params_str})\n"
                f"RETURNS {ret_type}\n"
                f"LANGUAGE PYTHON\n"
                f"AS $$\n"
                f"{body_comment}\n"
                f"{func.body}\n"
                f"$$;"
            )
        else:
            sql = (
                f"CREATE {or_replace}FUNCTION {qname}({params_str})\n"
                f"RETURNS {ret_type}\n"
                f"RETURN (\n"
                f"  {body_comment}\n"
                f"  {func.body}\n"
                f");"
            )
        return sql, [IRWarning(
            feature="FUNCTION_MANUAL_REVIEW",
            message=(
                "UDF body requires manual review for Spark SQL / Fabric Lakehouse function syntax. "
                "Docs: https://spark.apache.org/docs/latest/sql-ref-syntax-ddl-create-function.html"
            ),
            severity=Warningseverity.WARNING,
        )], doc_refs

    def generate_trigger(
        self, trigger: IRTrigger
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Fabric Lakehouse (Spark SQL on Delta Lake) has no CREATE TRIGGER
        statement or row-level DML trigger concept.
        Docs: https://spark.apache.org/docs/latest/sql-ref-syntax-ddl.html
        """
        doc_refs = [IRDocReference(
            title="Spark SQL DDL Statements (no CREATE TRIGGER)",
            url="https://spark.apache.org/docs/latest/sql-ref-syntax-ddl.html",
            platform="fabric_lakehouse",
            purpose="Trigger unsupported reference",
        )]
        qname = self._qualified_name(trigger)
        sql = (
            f"-- Fabric Lakehouse (Spark SQL / Delta Lake) does NOT support CREATE TRIGGER.\n"
            f"-- Docs: https://spark.apache.org/docs/latest/sql-ref-syntax-ddl.html\n"
            f"-- No in-database equivalent exists; consider a Delta Live Tables/CDC pipeline.\n"
            f"-- Original trigger '{qname}' ON {trigger.table_name} "
            f"({trigger.timing} {', '.join(trigger.events) or 'DML'}) preserved for reference:\n"
            f"-- {trigger.body.replace(chr(10), chr(10) + '-- ')}"
        )
        return sql, [IRWarning(
            feature="TRIGGER_NOT_SUPPORTED_FABRIC_LAKEHOUSE",
            message="Fabric Lakehouse (Spark SQL) has no CREATE TRIGGER statement or "
                    "row-level trigger concept. Consider a Delta Live Tables/CDC pipeline.",
            doc_url="https://spark.apache.org/docs/latest/sql-ref-syntax-ddl.html",
            severity=Warningseverity.WARNING,
            unsupported=True,
        )], doc_refs
