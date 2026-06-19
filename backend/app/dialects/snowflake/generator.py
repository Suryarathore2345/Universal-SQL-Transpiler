"""
Snowflake SQL generator — converts IR to Snowflake DDL.

Official docs used:
  CREATE TABLE:  https://docs.snowflake.com/en/sql-reference/sql/create-table
  CLUSTER BY:    https://docs.snowflake.com/en/user-guide/tables-clustering-keys
  AUTOINCREMENT: https://docs.snowflake.com/en/sql-reference/sql/create-table
  CREATE VIEW:   https://docs.snowflake.com/en/sql-reference/sql/create-view
  CREATE MV:     https://docs.snowflake.com/en/sql-reference/sql/create-materialized-view
  Data types:    https://docs.snowflake.com/en/sql-reference/intro-summary-data-types

MV limitation (Enterprise Edition only):
  https://docs.snowflake.com/en/user-guide/views-materialized#limitations-on-creating-materialized-views
"""
from __future__ import annotations

from typing import List, Tuple

from app.dialects.base import DialectGenerator
from app.ir.models import (
    Dialect, DistributionStyle, GenericType, IRColumn, IRDocReference,
    IRFunction, IRMaterializedView, IRProcedure, IRTable, IRView, IRWarning,
    RefreshType, Warningseverity,
)


class SnowflakeGenerator(DialectGenerator):
    """
    Generates Snowflake SQL DDL from IR.
    """

    dialect = Dialect.SNOWFLAKE

    def _quote_identifier(self, name: str) -> str:
        return f'"{name}"'

    def _qualified_name(self, obj) -> str:
        parts = []
        if obj.database_name:
            parts.append(obj.database_name)
        if obj.schema_name:
            parts.append(obj.schema_name)
        parts.append(obj.name)
        return ".".join(parts)

    # -------------------------------------------------------------------------
    # CREATE TABLE
    # -------------------------------------------------------------------------

    def generate_table(
        self, table: IRTable
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        warnings: List[IRWarning] = []
        doc_refs = [IRDocReference(
            title="Snowflake CREATE TABLE",
            url="https://docs.snowflake.com/en/sql-reference/sql/create-table",
            platform="snowflake",
            purpose="DDL generation reference",
        )]

        # Snowflake keyword prefix for table type
        prefix = ""
        if table.table_properties.is_transient:
            prefix = "TRANSIENT "
        elif table.is_temporary:
            prefix = "TEMPORARY "

        qname = self._qualified_name(table)
        lines = []

        for col in table.columns:
            col_sql, w, d = self._column_def(col)
            lines.append(f"    {col_sql}")
            warnings.extend(w)
            doc_refs.extend(d)

        # Constraints
        if table.primary_key:
            pk_cols = ", ".join(self._quote_identifier(c) for c in table.primary_key.columns)
            pk_name = f"CONSTRAINT {table.primary_key.name} " if table.primary_key.name else ""
            lines.append(f"    {pk_name}PRIMARY KEY ({pk_cols})")

        for fk in table.foreign_keys:
            lines.append(f"    {self._fk_clause(fk)}")

        for uq in table.unique_constraints:
            uq_cols = ", ".join(self._quote_identifier(c) for c in uq.columns)
            uq_name = f"CONSTRAINT {uq.name} " if uq.name else ""
            lines.append(f"    {uq_name}UNIQUE ({uq_cols})")

        body = ",\n".join(lines)
        if table.or_replace:
            sql = f"CREATE OR REPLACE {prefix}TABLE {qname} (\n{body}\n)"
        elif table.if_not_exists:
            sql = f"CREATE {prefix}TABLE IF NOT EXISTS {qname} (\n{body}\n)"
        else:
            sql = f"CREATE {prefix}TABLE {qname} (\n{body}\n)"

        # Warn about Redshift/Synapse distribution → no equivalent in Snowflake
        if table.distribution:
            dist = table.distribution
            if dist.style == DistributionStyle.HASH:
                warnings.append(IRWarning(
                    feature="DISTRIBUTION_KEY",
                    message=f"Snowflake does not support explicit distribution keys. "
                            f"DISTKEY({', '.join(dist.key_columns)}) was removed. "
                            f"Snowflake manages data distribution automatically. "
                            f"Use CLUSTER BY for query optimization if needed.",
                    doc_url="https://docs.snowflake.com/en/user-guide/tables-clustering-keys",
                    severity=Warningseverity.INFO,
                    fallback_applied=True,
                ))
            elif dist.style == DistributionStyle.ROUND_ROBIN:
                warnings.append(IRWarning(
                    feature="DISTSTYLE_EVEN",
                    message="Snowflake does not support DISTSTYLE EVEN. "
                            "Data is distributed automatically by Snowflake.",
                    doc_url="https://docs.snowflake.com/en/sql-reference/sql/create-table",
                    severity=Warningseverity.INFO,
                ))

        # CLUSTER BY
        if table.cluster_by and table.cluster_by.columns:
            cluster_cols = ", ".join(self._quote_identifier(c) for c in table.cluster_by.columns)
            sql += f"\nCLUSTER BY ({cluster_cols})"
            doc_refs.append(IRDocReference(
                title="Snowflake CLUSTER BY",
                url="https://docs.snowflake.com/en/user-guide/tables-clustering-keys",
                platform="snowflake",
                purpose="Clustering key generation",
            ))

        # Warn about Redshift SORTKEY → suggest CLUSTER BY
        if table.sort_key and table.sort_key.columns and not table.cluster_by:
            sk_cols = ", ".join(self._quote_identifier(c) for c in table.sort_key.columns)
            sql += f"\nCLUSTER BY ({sk_cols})"
            warnings.append(IRWarning(
                feature="SORTKEY_TO_CLUSTER_BY",
                message=f"Redshift SORTKEY({', '.join(table.sort_key.columns)}) converted to "
                        f"Snowflake CLUSTER BY ({', '.join(table.sort_key.columns)}). "
                        f"Snowflake clustering works differently — automatic micro-partition pruning.",
                doc_url="https://docs.snowflake.com/en/user-guide/tables-clustering-keys",
                severity=Warningseverity.INFO,
                fallback_applied=True,
            ))

        # DATA_RETENTION_TIME_IN_DAYS
        if table.table_properties.data_retention_days is not None:
            sql += f"\nDATA_RETENTION_TIME_IN_DAYS = {table.table_properties.data_retention_days}"

        # Comment
        if table.comment:
            sql += f"\nCOMMENT = '{table.comment}'"

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

        # AUTOINCREMENT / IDENTITY
        if col.identity:
            # Snowflake: AUTOINCREMENT (START WITH n INCREMENT BY n) or IDENTITY(n,n)
            # Docs: https://docs.snowflake.com/en/sql-reference/sql/create-table
            parts.append(
                f"IDENTITY({col.identity.start},{col.identity.increment})"
            )
            doc_refs.append(IRDocReference(
                title="Snowflake IDENTITY/AUTOINCREMENT",
                url="https://docs.snowflake.com/en/sql-reference/sql/create-table",
                platform="snowflake",
                purpose="Identity column generation",
            ))

        if not col.is_nullable:
            parts.append("NOT NULL")

        if col.default_value is not None:
            parts.append(f"DEFAULT {col.default_value}")

        if col.comment:
            comment_escaped = col.comment.replace("'", "''")
            parts.append(f"COMMENT '{comment_escaped}'")

        return " ".join(parts), warnings, doc_refs

    # -------------------------------------------------------------------------
    # CREATE PROCEDURE / FUNCTION
    # -------------------------------------------------------------------------

    def generate_procedure(
        self, proc: IRProcedure
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Snowflake stored procedure using Snowflake Scripting (SQL).
        Docs: https://docs.snowflake.com/en/sql-reference/sql/create-procedure
        Supported languages: SQL, JavaScript, Python, Java, Scala.
        """
        from app.dialects.procedure_utils import format_param_snowflake, format_body_comment
        doc_refs = [IRDocReference(
            title="Snowflake CREATE PROCEDURE",
            url="https://docs.snowflake.com/en/sql-reference/sql/create-procedure",
            platform="snowflake",
            purpose="Stored procedure generation",
        )]
        qname = self._qualified_name(proc)
        params_str = ", ".join(format_param_snowflake(p, self.mapper, self.dialect) for p in proc.parameters)
        or_replace = "OR REPLACE " if proc.or_replace else ""
        body_comment = format_body_comment(proc.language or "unknown", "snowflake", proc.language)
        lang = (proc.language or "SQL").upper()
        sql = (
            f"CREATE {or_replace}PROCEDURE {qname}({params_str})\n"
            f"RETURNS VARIANT\n"
            f"LANGUAGE {lang}\n"
            f"AS\n"
            f"$$\n"
            f"{body_comment}\n"
            f"{proc.body}\n"
            f"$$;"
        )
        return sql, [IRWarning(
            feature="PROCEDURE_MANUAL_REVIEW",
            message="Procedure body requires manual review. "
                    "Snowflake Scripting SQL dialect differs from PL/pgSQL, T-SQL, and PL/SQL. "
                    "Docs: https://docs.snowflake.com/en/developer-guide/snowflake-scripting/index",
            severity=Warningseverity.WARNING,
        )], doc_refs

    def generate_function(
        self, func: IRFunction
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Snowflake UDF — SQL, JavaScript, Python, Java, or Scala.
        Docs: https://docs.snowflake.com/en/sql-reference/sql/create-function
        """
        from app.dialects.procedure_utils import format_param_snowflake, format_body_comment
        doc_refs = [IRDocReference(
            title="Snowflake CREATE FUNCTION (UDF)",
            url="https://docs.snowflake.com/en/sql-reference/sql/create-function",
            platform="snowflake",
            purpose="UDF generation",
        )]
        qname = self._qualified_name(func)
        params_str = ", ".join(format_param_snowflake(p, self.mapper, self.dialect) for p in func.parameters)
        or_replace = "OR REPLACE " if func.or_replace else ""
        lang = (func.language or "SQL").upper()
        ret_type = "VARIANT"
        if func.return_type:
            ret_type, _, _ = self._type_to_sql(func.return_type)
        body_comment = format_body_comment(func.language or "unknown", "snowflake", func.language)
        sql = (
            f"CREATE {or_replace}FUNCTION {qname}({params_str})\n"
            f"RETURNS {ret_type}\n"
            f"LANGUAGE {lang}\n"
            f"AS\n"
            f"$$\n"
            f"{body_comment}\n"
            f"{func.body}\n"
            f"$$;"
        )
        return sql, [IRWarning(
            feature="FUNCTION_MANUAL_REVIEW",
            message="UDF body requires manual review for Snowflake syntax. "
                    "Docs: https://docs.snowflake.com/en/sql-reference/sql/create-function",
            severity=Warningseverity.WARNING,
        )], doc_refs

    def _fk_clause(self, fk) -> str:
        cols = ", ".join(self._quote_identifier(c) for c in fk.columns)
        ref_table = fk.ref_table
        if fk.ref_schema:
            ref_table = f"{fk.ref_schema}.{fk.ref_table}"
        ref_cols = ", ".join(self._quote_identifier(c) for c in fk.ref_columns)
        name = f"CONSTRAINT {fk.name} " if fk.name else ""
        return f"{name}FOREIGN KEY ({cols}) REFERENCES {ref_table} ({ref_cols})"

    # -------------------------------------------------------------------------
    # CREATE VIEW
    # -------------------------------------------------------------------------

    def generate_view(
        self, view: IRView
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(
            title="Snowflake CREATE VIEW",
            url="https://docs.snowflake.com/en/sql-reference/sql/create-view",
            platform="snowflake",
            purpose="View generation reference",
        )]

        or_replace = "OR REPLACE " if view.or_replace else ""
        secure = "SECURE " if view.is_secure else ""
        qname = self._qualified_name(view)
        defn, warnings = self._apply_snowflake_view_conversions(view.definition)
        sql = f"CREATE {or_replace}{secure}VIEW {qname} AS\n{defn};"
        return sql, warnings, doc_refs

    # -------------------------------------------------------------------------
    # CREATE MATERIALIZED VIEW
    # -------------------------------------------------------------------------

    def generate_materialized_view(
        self, mv: IRMaterializedView
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Snowflake MV docs:
        https://docs.snowflake.com/en/sql-reference/sql/create-materialized-view

        LIMITATION: Materialized views in Snowflake require Enterprise Edition (or higher).
        Automatic refresh is managed by Snowflake's cloud services layer.
        Docs on limitation: https://docs.snowflake.com/en/user-guide/views-materialized#limitations-on-creating-materialized-views
        """
        doc_refs = [
            IRDocReference(
                title="Snowflake CREATE MATERIALIZED VIEW",
                url="https://docs.snowflake.com/en/sql-reference/sql/create-materialized-view",
                platform="snowflake",
                purpose="MV generation reference",
            ),
            IRDocReference(
                title="Snowflake MV Limitations",
                url="https://docs.snowflake.com/en/user-guide/views-materialized#limitations-on-creating-materialized-views",
                platform="snowflake",
                purpose="Enterprise Edition requirement",
            ),
        ]

        warnings = [IRWarning(
            feature="MV_ENTERPRISE_EDITION",
            message="Snowflake MATERIALIZED VIEW requires Enterprise Edition (or higher). "
                    "Refresh is managed automatically by Snowflake's cloud services layer — "
                    "no manual refresh command is needed. If your account is not Enterprise, "
                    "convert this to a standard VIEW or a DYNAMIC TABLE (Business Critical+).",
            doc_url="https://docs.snowflake.com/en/user-guide/views-materialized#limitations-on-creating-materialized-views",
            severity=Warningseverity.WARNING,
        )]

        qname = self._qualified_name(mv)
        clauses = []

        # CLUSTER BY
        if mv.cluster_by and mv.cluster_by.columns:
            cluster_cols = ", ".join(self._quote_identifier(c) for c in mv.cluster_by.columns)
            clauses.append(f"CLUSTER BY ({cluster_cols})")

        defn, conv_warnings = self._apply_snowflake_view_conversions(mv.definition)
        warnings.extend(conv_warnings)

        clause_str = "\n".join(clauses)
        if clause_str:
            sql = f"CREATE MATERIALIZED VIEW {qname}\n{clause_str}\nAS\n{defn};"
        else:
            sql = f"CREATE MATERIALIZED VIEW {qname} AS\n{defn};"

        return sql, warnings, doc_refs
