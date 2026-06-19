"""
SQL Server T-SQL generator — converts IR to SQL Server DDL.

Official docs used:
  CREATE TABLE:   https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql
  IDENTITY:       https://learn.microsoft.com/en-us/sql/t-sql/functions/identity-function-transact-sql
  CREATE VIEW:    https://learn.microsoft.com/en-us/sql/t-sql/statements/create-view-transact-sql
  Indexed views:  https://learn.microsoft.com/en-us/sql/relational-databases/views/create-indexed-views
  Data types:     https://learn.microsoft.com/en-us/sql/t-sql/data-types/data-types-transact-sql
"""
from __future__ import annotations

from typing import List, Tuple

from app.dialects.base import DialectGenerator
from app.ir.models import (
    Dialect, DistributionStyle, IRColumn, IRDocReference, IRFunction,
    IRMaterializedView, IRProcedure, IRTable, IRView, IRWarning, SortKeyType,
    Warningseverity,
)


class SQLServerGenerator(DialectGenerator):
    """
    Generates SQL Server T-SQL DDL from IR.
    SQL Server uses [square bracket] quoting.
    """

    dialect = Dialect.SQLSERVER

    def _quote_identifier(self, name: str) -> str:
        return f"[{name}]"

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
            title="SQL Server CREATE TABLE",
            url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql",
            platform="sqlserver",
            purpose="DDL generation reference",
        )]

        temp = "#" if table.is_temporary else ""
        qname = self._qualified_name(table)
        if table.is_temporary:
            qname = f"[#{table.name}]"

        lines = []

        for col in table.columns:
            col_sql, w, d = self._column_def(col)
            lines.append(f"    {col_sql}")
            warnings.extend(w)
            doc_refs.extend(d)

        if table.primary_key:
            pk_cols = ", ".join(self._quote_identifier(c) for c in table.primary_key.columns)
            pk_name = f"CONSTRAINT {self._quote_identifier(table.primary_key.name)} " if table.primary_key.name else ""
            lines.append(f"    {pk_name}PRIMARY KEY ({pk_cols})")

        for fk in table.foreign_keys:
            cols = ", ".join(self._quote_identifier(c) for c in fk.columns)
            ref_q = self._quote_identifier(fk.ref_table)
            if fk.ref_schema:
                ref_q = f"{self._quote_identifier(fk.ref_schema)}.{ref_q}"
            ref_cols = ", ".join(self._quote_identifier(c) for c in fk.ref_columns)
            fk_name = f"CONSTRAINT {self._quote_identifier(fk.name)} " if fk.name else ""
            lines.append(f"    {fk_name}FOREIGN KEY ({cols}) REFERENCES {ref_q} ({ref_cols})")

        for uq in table.unique_constraints:
            uq_cols = ", ".join(self._quote_identifier(c) for c in uq.columns)
            uq_name = f"CONSTRAINT {self._quote_identifier(uq.name)} " if uq.name else ""
            lines.append(f"    {uq_name}UNIQUE ({uq_cols})")

        body = ",\n".join(lines)
        core_sql = f"CREATE TABLE {qname} (\n{body}\n);"
        if table.or_replace:
            sql = f"DROP TABLE IF EXISTS {qname};\nGO\n{core_sql}"
        elif table.if_not_exists:
            sql = (
                f"IF OBJECT_ID(N'{qname}', N'U') IS NULL\nBEGIN\n"
                f"    {core_sql.replace(chr(10), chr(10) + '    ')}\nEND;"
            )
        else:
            sql = core_sql

        # Distribution concepts have no equivalent in SQL Server
        if table.distribution:
            warnings.append(IRWarning(
                feature="DISTRIBUTION_NOT_SUPPORTED",
                message="SQL Server does not support DISTRIBUTION clauses. "
                        "Data distribution is handled at the infrastructure level. "
                        "Distribution setting has been dropped.",
                doc_url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql",
                severity=Warningseverity.WARNING,
                unsupported=True,
                fallback_applied=True,
            ))

        # SORTKEY / CLUSTER BY not applicable in SQL Server
        if table.sort_key or table.cluster_by:
            warnings.append(IRWarning(
                feature="SORT_CLUSTER_NOT_SUPPORTED",
                message="SQL Server does not have SORTKEY or CLUSTER BY at the table level. "
                        "Consider creating a clustered index after table creation for similar performance.",
                doc_url="https://learn.microsoft.com/en-us/sql/relational-databases/indexes/clustered-and-nonclustered-indexes-described",
                severity=Warningseverity.INFO,
                fallback_applied=False,
            ))

        return sql, warnings, doc_refs

    # -------------------------------------------------------------------------
    # CREATE PROCEDURE / FUNCTION
    # -------------------------------------------------------------------------

    def generate_procedure(
        self, proc: IRProcedure
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        SQL Server T-SQL stored procedure.
        Docs: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql
        """
        from app.dialects.procedure_utils import format_param_tsql, format_body_comment
        doc_refs = [IRDocReference(
            title="SQL Server CREATE PROCEDURE",
            url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql",
            platform="sqlserver",
            purpose="Stored procedure generation",
        )]
        qname = self._qualified_name(proc)
        params_str = ",\n    ".join(format_param_tsql(p, self.mapper, self.dialect) for p in proc.parameters)
        or_replace = "OR ALTER " if proc.or_replace else ""
        body_comment = format_body_comment(proc.language or "tsql", "sqlserver", proc.language)
        params_block = f"\n    {params_str}" if params_str else ""
        sql = (
            f"CREATE {or_replace}PROCEDURE {qname}({params_block}\n)\nAS\nBEGIN\n"
            f"{body_comment}\n"
            f"{proc.body}\n"
            f"END;"
        )
        return sql, [IRWarning(
            feature="PROCEDURE_MANUAL_REVIEW",
            message="Procedure body requires manual review for T-SQL syntax. "
                    "Docs: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql",
            severity=Warningseverity.WARNING,
        )], doc_refs

    def generate_function(
        self, func: IRFunction
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        SQL Server T-SQL scalar function.
        Docs: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql
        """
        from app.dialects.procedure_utils import format_param_tsql, format_body_comment
        doc_refs = [IRDocReference(
            title="SQL Server CREATE FUNCTION",
            url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql",
            platform="sqlserver",
            purpose="Scalar function generation",
        )]
        qname = self._qualified_name(func)
        params_str = ", ".join(format_param_tsql(p, self.mapper, self.dialect) for p in func.parameters)
        or_replace = "OR ALTER " if func.or_replace else ""
        ret_type = "NVARCHAR(MAX)"
        if func.return_type:
            ret_type, _, _ = self._type_to_sql(func.return_type)
        body_comment = format_body_comment(func.language or "tsql", "sqlserver", func.language)
        sql = (
            f"CREATE {or_replace}FUNCTION {qname}({params_str})\n"
            f"RETURNS {ret_type}\n"
            f"AS\nBEGIN\n"
            f"{body_comment}\n"
            f"{func.body}\n"
            f"END;"
        )
        return sql, [IRWarning(
            feature="FUNCTION_MANUAL_REVIEW",
            message="Function body requires manual review for T-SQL scalar function syntax. "
                    "Docs: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql",
            severity=Warningseverity.WARNING,
        )], doc_refs

    def _column_def(
        self, col: IRColumn
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        warnings: List[IRWarning] = []
        doc_refs: List[IRDocReference] = []

        type_str, w, d = self._type_to_sql(col.data_type)
        warnings.extend(w)
        doc_refs.extend(d)

        parts = [self._quote_identifier(col.name), type_str]

        if col.identity:
            parts.append(f"IDENTITY({col.identity.start},{col.identity.increment})")
            doc_refs.append(IRDocReference(
                title="SQL Server IDENTITY",
                url="https://learn.microsoft.com/en-us/sql/t-sql/functions/identity-function-transact-sql",
                platform="sqlserver",
                purpose="Identity column generation",
            ))

        if not col.is_nullable:
            parts.append("NOT NULL")

        if col.default_value is not None:
            parts.append(f"DEFAULT {col.default_value}")

        return " ".join(parts), warnings, doc_refs

    # -------------------------------------------------------------------------
    # CREATE VIEW
    # -------------------------------------------------------------------------

    def generate_view(
        self, view: IRView
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(
            title="SQL Server CREATE VIEW",
            url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-view-transact-sql",
            platform="sqlserver",
            purpose="View generation reference",
        )]
        or_replace = "OR ALTER " if view.or_replace else ""
        qname = self._qualified_name(view)
        defn, warnings = self._apply_tsql_view_conversions(view.definition)
        sql = f"CREATE {or_replace}VIEW {qname} AS\n{defn};"
        return sql, warnings, doc_refs

    # -------------------------------------------------------------------------
    # CREATE MATERIALIZED VIEW  →  Indexed View (documented SQL Server pattern)
    # -------------------------------------------------------------------------

    def generate_materialized_view(
        self, mv: IRMaterializedView
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        SQL Server does not have a native CREATE MATERIALIZED VIEW statement.
        The documented equivalent is an indexed view:
          1. CREATE VIEW ... WITH SCHEMABINDING
          2. CREATE UNIQUE CLUSTERED INDEX ON the view

        Docs: https://learn.microsoft.com/en-us/sql/relational-databases/views/create-indexed-views
        """
        doc_refs = [IRDocReference(
            title="SQL Server Indexed Views (MV equivalent)",
            url="https://learn.microsoft.com/en-us/sql/relational-databases/views/create-indexed-views",
            platform="sqlserver",
            purpose="Materialized view fallback reference",
        )]

        qname = self._qualified_name(mv)
        view_name = self._quote_identifier(mv.name)
        schema = self._quote_identifier(mv.schema_name) if mv.schema_name else "dbo"
        idx_name = self._quote_identifier(f"IX_{mv.name}_clustered")

        defn, conv_warnings = self._apply_tsql_view_conversions(mv.definition)

        sql = (
            f"-- SQL Server does not support CREATE MATERIALIZED VIEW.\n"
            f"-- Documented equivalent: indexed view with SCHEMABINDING.\n"
            f"-- Docs: https://learn.microsoft.com/en-us/sql/relational-databases/views/create-indexed-views\n"
            f"CREATE VIEW {qname} WITH SCHEMABINDING AS\n"
            f"{defn};\n"
            f"GO\n"
            f"-- Create unique clustered index to materialize the view\n"
            f"CREATE UNIQUE CLUSTERED INDEX {idx_name}\n"
            f"    ON {schema}.{view_name} (<unique_key_column>);"
        )

        warnings = list(conv_warnings)
        warnings += [IRWarning(
            feature="MV_NOT_SUPPORTED_SQLSERVER",
            message="SQL Server does not support CREATE MATERIALIZED VIEW natively. "
                    "Converted to an indexed view (CREATE VIEW WITH SCHEMABINDING + "
                    "CREATE UNIQUE CLUSTERED INDEX). "
                    "Replace <unique_key_column> with the actual key column. "
                    "Indexed views have limitations: no DISTINCT, no subqueries, no outer joins, "
                    "no TOP, no UNION.",
            doc_url="https://learn.microsoft.com/en-us/sql/relational-databases/views/create-indexed-views",
            severity=Warningseverity.WARNING,
            unsupported=True,
            fallback_applied=True,
        )]

        return sql, warnings, doc_refs
