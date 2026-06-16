"""
Microsoft Fabric Data Warehouse (DW) T-SQL generator.

Official docs used:
  CREATE TABLE:     https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-azure-sql-data-warehouse?view=fabric
  T-SQL surface:    https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area
  Data types:       https://learn.microsoft.com/en-us/sql/t-sql/data-types/data-types-transact-sql
  Constraints:      https://learn.microsoft.com/en-us/fabric/data-warehouse/table-constraints

Fabric DW NOT supported (verified June 2026 against T-SQL surface area page):
  - Materialized views
  - DISTRIBUTION clause (no Synapse-style HASH/ROUND_ROBIN/REPLICATE)
  - DEFAULT constraints on columns (not in Fabric DW T-SQL surface area)
  - CHECK constraints
  - Computed/generated columns
  - tinyint, money, datetime, datetimeoffset, nchar, nvarchar, text, image, xml, geography, geometry
  - Triggers, recursive CTEs, sequences

NOT ENFORCED (defined but not validated at runtime):
  - PRIMARY KEY, UNIQUE, FOREIGN KEY

Ref: https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area
"""
from __future__ import annotations

from typing import List, Tuple

from app.dialects.base import DialectGenerator
from app.ir.models import (
    Dialect, DistributionStyle, IRColumn, IRDocReference, IRFunction,
    IRMaterializedView, IRProcedure, IRTable, IRView, IRWarning, Warningseverity,
)


class FabricDWGenerator(DialectGenerator):
    """
    Generates Fabric DW T-SQL DDL from IR.
    Uses [square bracket] quoting.
    """

    dialect = Dialect.FABRIC_DW

    # Max columns in CLUSTER BY per official docs
    _CLUSTER_BY_MAX = 4

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
            title="Fabric DW CREATE TABLE",
            url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-azure-sql-data-warehouse?view=fabric",
            platform="fabric_dw",
            purpose="DDL generation reference",
        )]

        qname = self._qualified_name(table)
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
        sql = f"CREATE TABLE {qname} (\n{body}\n)"

        # Fabric DW WITH clause: only CLUSTER BY, no DISTRIBUTION
        cluster_cols = None
        if table.cluster_by and table.cluster_by.columns:
            cluster_cols = table.cluster_by.columns
        elif table.sort_key and table.sort_key.columns:
            cluster_cols = table.sort_key.columns
            warnings.append(IRWarning(
                feature="SORTKEY_TO_CLUSTER_BY",
                message="Redshift SORTKEY converted to Fabric DW CLUSTER BY. "
                        "Semantics differ: Redshift SORTKEY affects physical row sort order; "
                        "Fabric DW CLUSTER BY affects Delta Parquet file organization. "
                        "Maximum 4 columns supported.",
                doc_url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-azure-sql-data-warehouse?view=fabric",
                severity=Warningseverity.INFO,
                fallback_applied=True,
            ))

        if cluster_cols:
            cols = cluster_cols[:self._CLUSTER_BY_MAX]
            if len(cluster_cols) > self._CLUSTER_BY_MAX:
                warnings.append(IRWarning(
                    feature="CLUSTER_BY_TRUNCATED",
                    message=f"Fabric DW CLUSTER BY supports max {self._CLUSTER_BY_MAX} columns. "
                            f"Truncated from {len(cluster_cols)} to {self._CLUSTER_BY_MAX} columns.",
                    doc_url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-azure-sql-data-warehouse?view=fabric",
                    severity=Warningseverity.WARNING,
                    fallback_applied=True,
                ))
            cl_cols_str = ", ".join(self._quote_identifier(c) for c in cols)
            sql += f"\nWITH (CLUSTER BY ({cl_cols_str}))"
            doc_refs.append(IRDocReference(
                title="Fabric DW CLUSTER BY",
                url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-azure-sql-data-warehouse?view=fabric",
                platform="fabric_dw",
                purpose="CLUSTER BY generation",
            ))

        # Fabric DW has no DISTRIBUTION — warn if source had one
        if table.distribution:
            warnings.append(IRWarning(
                feature="DISTRIBUTION_NOT_SUPPORTED_FABRIC_DW",
                message="Fabric DW does not support DISTRIBUTION clauses (unlike Azure Synapse). "
                        "Data distribution is managed automatically via Delta Parquet. "
                        "DISTRIBUTION setting dropped.",
                doc_url="https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area",
                severity=Warningseverity.INFO,
                unsupported=True,
                fallback_applied=True,
            ))
            doc_refs.append(IRDocReference(
                title="Fabric DW T-SQL Surface Area",
                url="https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area",
                platform="fabric_dw",
                purpose="Surface area reference for unsupported features",
            ))

        # Partition BY not supported in Fabric DW CREATE TABLE
        if table.partition_by and table.partition_by.columns:
            warnings.append(IRWarning(
                feature="PARTITION_NOT_SUPPORTED_FABRIC_DW",
                message="Fabric DW does not support PARTITION BY in CREATE TABLE syntax. "
                        "Partitioning is handled automatically by Delta Parquet storage.",
                doc_url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-azure-sql-data-warehouse?view=fabric",
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
            parts.append(f"IDENTITY({col.identity.start},{col.identity.increment})")

        if not col.is_nullable:
            parts.append("NOT NULL")

        # Fabric DW does NOT support DEFAULT constraints.
        # Ref: https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area
        # Ref: https://learn.microsoft.com/en-us/fabric/data-warehouse/table-constraints
        # The DEFAULT value is dropped and a warning is emitted.
        if col.default_value is not None:
            warnings.append(IRWarning(
                feature="DEFAULT_NOT_SUPPORTED_FABRIC_DW",
                message=(
                    f"Column '{col.name}': DEFAULT {col.default_value!r} is NOT supported "
                    f"in Microsoft Fabric Data Warehouse. "
                    f"DEFAULT constraints are not part of the Fabric DW T-SQL surface area. "
                    f"The DEFAULT value has been removed. "
                    f"Apply default logic in your application, ELT pipeline, or a Fabric Notebook."
                ),
                doc_url="https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area",
                severity=Warningseverity.WARNING,
                fallback_applied=False,
            ))
            doc_refs.append(IRDocReference(
                title="Fabric DW T-SQL Surface Area — unsupported constraints",
                url="https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area",
                platform="fabric_dw",
                purpose="DEFAULT constraint is not supported in Fabric DW",
            ))
            # DEFAULT is intentionally NOT added to parts — Fabric DW rejects it

        return " ".join(parts), warnings, doc_refs

    # -------------------------------------------------------------------------
    # CREATE VIEW
    # -------------------------------------------------------------------------

    def generate_view(
        self, view: IRView
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="Fabric DW CREATE VIEW", url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-view-transact-sql", platform="fabric_dw", purpose="View generation")]
        or_replace = "OR ALTER " if view.or_replace else ""
        qname = self._qualified_name(view)
        defn = view.definition
        defn = self._convert_backtick_identifiers(defn)
        defn = self._convert_nvl2_to_case(defn)
        defn = self._convert_nvl_aware(defn)        # NVL → ISNULL
        defn = self._convert_decode_to_case(defn)
        return f"CREATE {or_replace}VIEW {qname} AS\n{defn};", [], doc_refs

    # -------------------------------------------------------------------------
    # CREATE MATERIALIZED VIEW  →  NOT SUPPORTED in Fabric DW
    # -------------------------------------------------------------------------

    def generate_materialized_view(
        self, mv: IRMaterializedView
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Fabric DW does NOT support CREATE MATERIALIZED VIEW (verified June 2026).
        Docs: https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area

        Fallback: generate a standard view with a CTAS comment for manual refresh.
        This is the documented workaround pattern.
        """
        doc_refs = [IRDocReference(
            title="Fabric DW T-SQL Surface Area",
            url="https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area",
            platform="fabric_dw",
            purpose="Materialized view unsupported reference",
        )]

        qname = self._qualified_name(mv)
        sql = (
            f"-- Fabric DW does NOT support CREATE MATERIALIZED VIEW.\n"
            f"-- Docs: https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area\n"
            f"-- Option 1: Create a standard VIEW (no pre-computation)\n"
            f"CREATE VIEW {qname} AS\n"
            f"{mv.definition};\n"
            f"\n"
            f"-- Option 2: Materialize via CTAS (run manually or on a schedule)\n"
            f"-- CREATE TABLE {qname}_snapshot AS\n"
            f"-- SELECT * FROM ({mv.definition}) AS src;"
        )

        warnings = [IRWarning(
            feature="MV_NOT_SUPPORTED_FABRIC_DW",
            message="Fabric DW does not support CREATE MATERIALIZED VIEW. "
                    "Converted to a standard VIEW. "
                    "For pre-computed results, use CTAS to a table and refresh on a schedule "
                    "via Fabric Data Pipeline or Notebook.",
            doc_url="https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area",
            severity=Warningseverity.WARNING,
            unsupported=True,
            fallback_applied=True,
        )]

        return sql, warnings, doc_refs

    # -------------------------------------------------------------------------
    # CREATE PROCEDURE / FUNCTION
    # -------------------------------------------------------------------------

    def generate_procedure(
        self, proc: IRProcedure
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Fabric DW stored procedure (T-SQL). Supported as of June 2026.
        Docs: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql
        """
        from app.dialects.procedure_utils import format_param_tsql, format_body_comment
        doc_refs = [IRDocReference(
            title="Fabric DW CREATE PROCEDURE",
            url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql",
            platform="fabric_dw",
            purpose="Stored procedure generation",
        )]
        qname = self._qualified_name(proc)
        params_str = ",\n    ".join(format_param_tsql(p, self.mapper, self.dialect) for p in proc.parameters)
        or_replace = "OR ALTER " if proc.or_replace else ""
        body_comment = format_body_comment(proc.language or "tsql", "fabric_dw", proc.language)
        params_block = f"\n    {params_str}" if params_str else ""
        sql = (
            f"CREATE {or_replace}PROCEDURE {qname}({params_block}\n)\nAS\nBEGIN\n"
            f"{body_comment}\n"
            f"{proc.body}\n"
            f"END;"
        )
        return sql, [IRWarning(
            feature="PROCEDURE_MANUAL_REVIEW",
            message="Procedure body requires manual review for Fabric DW T-SQL syntax. "
                    "Docs: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql",
            severity=Warningseverity.WARNING,
        )], doc_refs

    def generate_function(
        self, func: IRFunction
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Fabric DW scalar function (T-SQL).
        Docs: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql
        """
        from app.dialects.procedure_utils import format_param_tsql, format_body_comment
        doc_refs = [IRDocReference(
            title="Fabric DW CREATE FUNCTION",
            url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql",
            platform="fabric_dw",
            purpose="Scalar function generation",
        )]
        qname = self._qualified_name(func)
        params_str = ", ".join(format_param_tsql(p, self.mapper, self.dialect) for p in func.parameters)
        or_replace = "OR ALTER " if func.or_replace else ""
        ret_type = "NVARCHAR(MAX)"
        if func.return_type:
            ret_type, _, _ = self._type_to_sql(func.return_type)
        body_comment = format_body_comment(func.language or "tsql", "fabric_dw", func.language)
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
            message="Function body requires manual review for Fabric DW T-SQL syntax.",
            severity=Warningseverity.WARNING,
        )], doc_refs
