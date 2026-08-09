"""
Databricks SQL (Delta Lake) generator — converts IR to Databricks DDL.

Official docs used:
  CREATE TABLE:   https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-table-using.html
  Delta table:    https://docs.databricks.com/en/delta/index.html
  Liquid cluster: https://docs.databricks.com/en/delta/clustering.html
  IDENTITY:       https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-table-using.html#generated-columns
  CREATE VIEW:    https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-view.html
  CREATE MV:      https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-materialized-view.html
"""
from __future__ import annotations

from typing import List, Tuple

from app.dialects.base import DialectGenerator
from app.ir.models import (
    Dialect, DistributionStyle, GenericType, IRColumn, IRDocReference,
    IRFunction, IRMaterializedView, IRProcedure, IRTable, IRTrigger, IRView,
    IRWarning, Warningseverity,
)


class DatabricksGenerator(DialectGenerator):
    """
    Generates Databricks SQL (Delta Lake) DDL from IR.
    Uses backtick quoting.
    """

    dialect = Dialect.DATABRICKS

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
            title="Databricks CREATE TABLE",
            url="https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-table-using.html",
            platform="databricks",
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
            # Databricks/Unity Catalog PRIMARY KEY constraints are
            # informational only by default — never validated against
            # actual data. NOT ENFORCED makes that explicit in the DDL
            # itself (matching the BigQuery generator's equivalent marker)
            # instead of silently implying enforcement that doesn't happen.
            pk_cols = ", ".join(self._quote_identifier(c) for c in table.primary_key.columns)
            lines.append(f"    PRIMARY KEY ({pk_cols}) NOT ENFORCED")
            warnings.append(IRWarning(
                feature="PRIMARY_KEY_NOT_ENFORCED_DATABRICKS",
                message="Databricks/Unity Catalog PRIMARY KEY constraints are informational "
                        "only and are never validated against actual data — duplicate values "
                        "are not rejected.",
                doc_url="https://docs.databricks.com/en/tables/constraints.html",
                severity=Warningseverity.INFO,
            ))

        body = ",\n".join(lines)
        if table.or_replace:
            sql = f"CREATE OR REPLACE {temp}{ext}TABLE {qname} (\n{body}\n)\nUSING DELTA"
        elif table.if_not_exists:
            sql = f"CREATE {temp}{ext}TABLE IF NOT EXISTS {qname} (\n{body}\n)\nUSING DELTA"
        else:
            sql = f"CREATE {temp}{ext}TABLE {qname} (\n{body}\n)\nUSING DELTA"

        if table.comment:
            sql += f"\nCOMMENT '{table.comment}'"

        # PARTITIONED BY and CLUSTER BY are mutually exclusive in Databricks
        # Prefer CLUSTER BY (liquid clustering) when both come from source; emit warning
        has_partition = bool(table.partition_by and table.partition_by.columns)
        has_cluster = bool(table.cluster_by and table.cluster_by.columns)
        has_sortkey = bool(table.sort_key and table.sort_key.columns)

        if has_cluster:
            cl_cols = ", ".join(self._quote_identifier(c) for c in table.cluster_by.columns)
            sql += f"\nCLUSTER BY ({cl_cols})"
            doc_refs.append(IRDocReference(
                title="Databricks Liquid Clustering",
                url="https://docs.databricks.com/en/delta/clustering.html",
                platform="databricks",
                purpose="CLUSTER BY (liquid clustering) generation",
            ))
            if has_partition:
                warnings.append(IRWarning(
                    feature="CLUSTER_BY_PARTITION_CONFLICT",
                    message="Source had both PARTITION and CLUSTER BY. In Databricks Delta, "
                            "CLUSTER BY (liquid clustering) and PARTITIONED BY are mutually exclusive. "
                            "Using CLUSTER BY only. If classic partitioning is needed, remove CLUSTER BY.",
                    doc_url="https://docs.databricks.com/en/delta/clustering.html",
                    severity=Warningseverity.WARNING,
                    fallback_applied=True,
                ))
        elif has_partition:
            pt_cols = ", ".join(self._quote_identifier(c) for c in table.partition_by.columns)
            sql += f"\nPARTITIONED BY ({pt_cols})"
        elif has_sortkey:
            # Redshift SORTKEY → liquid CLUSTER BY (best-effort mapping)
            cl_cols = ", ".join(self._quote_identifier(c) for c in table.sort_key.columns)
            sql += f"\nCLUSTER BY ({cl_cols})"
            warnings.append(IRWarning(
                feature="SORTKEY_TO_CLUSTER_BY",
                message="Redshift SORTKEY converted to Databricks CLUSTER BY (liquid clustering). "
                        "Semantics differ: Redshift sorts rows; Databricks collocates data in files for pruning.",
                doc_url="https://docs.databricks.com/en/delta/clustering.html",
                severity=Warningseverity.INFO,
                fallback_applied=True,
            ))

        # Distribution concepts have no direct mapping in Databricks
        if table.distribution:
            warnings.append(IRWarning(
                feature="DISTRIBUTION_NOT_SUPPORTED_DATABRICKS",
                message="Databricks Delta Lake does not support explicit DISTRIBUTION clauses. "
                        "Data distribution is managed automatically by Delta Lake. "
                        "Distribution setting dropped.",
                doc_url="https://docs.databricks.com/en/delta/index.html",
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

        parts = [self._quote_identifier(col.name), type_str]

        if col.identity:
            # Databricks GENERATED ALWAYS AS IDENTITY — BIGINT only. A
            # narrower type (INT32/INT16/INT8) is rejected by Databricks at
            # DDL execution time, so it must be widened to BIGINT here
            # rather than merely warned about — otherwise this method
            # returns DDL that is guaranteed to fail to deploy.
            if col.data_type.generic_type != GenericType.INT64:
                parts[1] = "BIGINT"
                warnings.append(IRWarning(
                    feature="IDENTITY_TYPE_DATABRICKS",
                    message="Databricks GENERATED ALWAYS AS IDENTITY requires BIGINT — "
                            f"the column's original type ({type_str}) has been widened to BIGINT.",
                    doc_url="https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-table-using.html#generated-columns",
                    severity=Warningseverity.WARNING,
                    fallback_applied=True,
                ))
            # Docs: https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-table-using.html#generated-columns
            parts.append(f"GENERATED ALWAYS AS IDENTITY (START WITH {col.identity.start} INCREMENT BY {col.identity.increment})")
            doc_refs.append(IRDocReference(
                title="Databricks GENERATED ALWAYS AS IDENTITY",
                url="https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-table-using.html#generated-columns",
                platform="databricks",
                purpose="Identity column generation",
            ))

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
        doc_refs = [IRDocReference(title="Databricks CREATE VIEW", url="https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-view.html", platform="databricks", purpose="View generation")]
        or_replace = "OR REPLACE " if view.or_replace else ""
        qname = self._qualified_name(view)
        defn, warnings = self._apply_databricks_view_conversions(view.definition)
        return f"CREATE {or_replace}VIEW {qname} AS\n{defn};", warnings, doc_refs

    # -------------------------------------------------------------------------
    # CREATE MATERIALIZED VIEW
    # -------------------------------------------------------------------------

    def generate_materialized_view(
        self, mv: IRMaterializedView
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Databricks CREATE MATERIALIZED VIEW (Unity Catalog).
        Docs: https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-materialized-view.html

        Supports SCHEDULE clause for refresh cadence.
        Requires Unity Catalog and serverless/pro SQL warehouse.
        """
        doc_refs = [IRDocReference(
            title="Databricks CREATE MATERIALIZED VIEW",
            url="https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-materialized-view.html",
            platform="databricks",
            purpose="MV generation reference",
        )]

        qname = self._qualified_name(mv)
        or_replace = "OR REPLACE " if getattr(mv, "or_replace", False) else ""
        defn, conv_warnings = self._apply_databricks_view_conversions(mv.definition)
        sql = f"CREATE {or_replace}MATERIALIZED VIEW {qname}"

        if mv.refresh_schedule:
            sql += f"\nSCHEDULE CRON '{mv.refresh_schedule}'"

        sql += f"\nAS\n{defn};"

        warnings = list(conv_warnings) + [IRWarning(
            feature="DATABRICKS_MV_UNITY_CATALOG",
            message="Databricks materialized views require Unity Catalog and a serverless or "
                    "pro SQL warehouse. "
                    "Refresh is triggered automatically on a schedule or manually via REFRESH MATERIALIZED VIEW.",
            doc_url="https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-materialized-view.html",
            severity=Warningseverity.INFO,
        )]

        return sql, warnings, doc_refs

    # -------------------------------------------------------------------------
    # CREATE PROCEDURE / FUNCTION
    # -------------------------------------------------------------------------

    def generate_procedure(
        self, proc: IRProcedure
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Databricks does NOT support stored procedures.
        Docs: https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-sql-function.html

        Fallback: emit as a SQL UDF with a prominent warning. The procedure body
        is preserved inside the UDF for manual conversion.
        """
        from app.dialects.procedure_utils import format_param_databricks, format_body_comment
        doc_refs = [IRDocReference(
            title="Databricks CREATE FUNCTION (no stored procedures)",
            url="https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-sql-function.html",
            platform="databricks",
            purpose="Procedure-to-function fallback reference",
        )]
        qname = self._qualified_name(proc)
        params_str = ", ".join(format_param_databricks(p, self.mapper, self.dialect) for p in proc.parameters)
        or_replace = "OR REPLACE " if proc.or_replace else ""
        body_comment = format_body_comment(proc.language or "unknown", "databricks", proc.language)
        sql = (
            f"-- Databricks does NOT support CREATE PROCEDURE.\n"
            f"-- Docs: https://docs.databricks.com/en/sql/language-manual/\n"
            f"-- Converted to a SQL UDF. Body requires significant manual adaptation.\n"
            f"CREATE {or_replace}FUNCTION {qname}({params_str})\n"
            f"RETURNS STRING\n"
            f"RETURN (\n"
            f"  -- {body_comment}\n"
            f"  -- Original body preserved below — NOT executable as-is:\n"
            f"  -- {proc.body.replace(chr(10), chr(10) + '  -- ')}\n"
            f"  NULL\n"
            f");"
        )
        return sql, [
            IRWarning(
                feature="PROCEDURE_NOT_SUPPORTED_DATABRICKS",
                message="Databricks does not support stored procedures. "
                        "The procedure has been converted to a SQL UDF stub. "
                        "Procedural logic (loops, cursors, IF/ELSE, PRINT) is not supported in SQL UDFs. "
                        "Consider refactoring as a Databricks Notebook or Python UDF. "
                        "Docs: https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-sql-function.html",
                severity=Warningseverity.WARNING,
                unsupported=True,
                fallback_applied=True,
            )
        ], doc_refs

    def generate_function(
        self, func: IRFunction
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Databricks SQL or Python UDF.
        Docs: https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-sql-function.html
        """
        from app.dialects.procedure_utils import format_param_databricks, format_body_comment
        doc_refs = [IRDocReference(
            title="Databricks CREATE FUNCTION",
            url="https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-sql-function.html",
            platform="databricks",
            purpose="UDF generation",
        )]
        qname = self._qualified_name(func)
        params_str = ", ".join(format_param_databricks(p, self.mapper, self.dialect) for p in func.parameters)
        or_replace = "OR REPLACE " if func.or_replace else ""
        ret_type = "STRING"
        if func.return_type:
            ret_type, _, _ = self._type_to_sql(func.return_type)
        body_comment = format_body_comment(func.language or "unknown", "databricks", func.language)
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
            message="UDF body requires manual review for Databricks SQL/Python function syntax. "
                    "Docs: https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-sql-function.html",
            severity=Warningseverity.WARNING,
        )], doc_refs

    def generate_trigger(
        self, trigger: IRTrigger
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Databricks SQL / Delta Lake has no CREATE TRIGGER statement — there
        is no synchronous row-level DML trigger concept. "Triggers" in
        Databricks refer to job/workflow triggers (table update, file
        arrival, schedule), an orchestration concept, not a DDL object.
        Docs: https://docs.databricks.com/aws/en/jobs/trigger-table-update
        """
        doc_refs = [IRDocReference(
            title="Databricks Jobs — trigger on table update (no native DML trigger)",
            url="https://docs.databricks.com/aws/en/jobs/trigger-table-update",
            platform="databricks",
            purpose="Trigger unsupported — nearest alternative reference",
        )]
        qname = self._qualified_name(trigger)
        sql = (
            f"-- Databricks does NOT support CREATE TRIGGER.\n"
            f"-- Docs: https://docs.databricks.com/aws/en/jobs/trigger-table-update\n"
            f"-- Nearest equivalent: a Databricks Job triggered on table update (or a\n"
            f"-- Delta Live Tables / CDC pipeline) — orchestration-level, not a\n"
            f"-- synchronous row-level trigger. Requires redesigning the logic below.\n"
            f"-- Original trigger '{qname}' ON {trigger.table_name} "
            f"({trigger.timing} {', '.join(trigger.events) or 'DML'}) preserved for reference:\n"
            f"-- {trigger.body.replace(chr(10), chr(10) + '-- ')}"
        )
        return sql, [IRWarning(
            feature="TRIGGER_NOT_SUPPORTED_DATABRICKS",
            message="Databricks has no CREATE TRIGGER statement or row-level trigger concept. "
                    "The nearest equivalent is a Job triggered on table update or a Delta Live "
                    "Tables/CDC pipeline — this requires a redesign, not a direct translation, "
                    "so only a documented stub was generated.",
            doc_url="https://docs.databricks.com/aws/en/jobs/trigger-table-update",
            severity=Warningseverity.WARNING,
            unsupported=True,
        )], doc_refs
