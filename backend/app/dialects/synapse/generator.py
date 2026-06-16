"""
Azure Synapse Analytics dedicated SQL pool generator.

Official docs used:
  CREATE TABLE:   https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-azure-sql-data-warehouse?view=azure-sqldw-latest
  DISTRIBUTION:   https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-tables-distribute
  CREATE MV:      https://learn.microsoft.com/en-us/sql/t-sql/statements/create-materialized-view-as-select-transact-sql?view=azure-sqldw-latest
"""
from __future__ import annotations

from typing import List, Optional, Tuple

from app.dialects.base import DialectGenerator
from app.ir.models import (
    Dialect, DistributionStyle, IRColumn, IRDocReference, IRFunction,
    IRMaterializedView, IRProcedure, IRTable, IRView, IRWarning, SortKeyType,
    Warningseverity,
)


class SynapseGenerator(DialectGenerator):
    """
    Generates Azure Synapse Analytics dedicated SQL DDL from IR.
    Uses [square bracket] quoting (T-SQL convention).
    """

    dialect = Dialect.SYNAPSE

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
            title="Synapse CREATE TABLE",
            url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-azure-sql-data-warehouse?view=azure-sqldw-latest",
            platform="synapse",
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
            lines.append(f"    {pk_name}PRIMARY KEY NONCLUSTERED ({pk_cols}) NOT ENFORCED")

        for fk in table.foreign_keys:
            cols = ", ".join(self._quote_identifier(c) for c in fk.columns)
            ref_q = self._quote_identifier(fk.ref_table)
            if fk.ref_schema:
                ref_q = f"{self._quote_identifier(fk.ref_schema)}.{ref_q}"
            ref_cols = ", ".join(self._quote_identifier(c) for c in fk.ref_columns)
            fk_name = f"CONSTRAINT {self._quote_identifier(fk.name)} " if fk.name else ""
            lines.append(f"    {fk_name}FOREIGN KEY ({cols}) REFERENCES {ref_q} ({ref_cols}) NOT ENFORCED")

        for uq in table.unique_constraints:
            uq_cols = ", ".join(self._quote_identifier(c) for c in uq.columns)
            uq_name = f"CONSTRAINT {self._quote_identifier(uq.name)} " if uq.name else ""
            lines.append(f"    {uq_name}UNIQUE NONCLUSTERED ({uq_cols}) NOT ENFORCED")

        body = ",\n".join(lines)
        sql = f"CREATE TABLE {qname} (\n{body}\n)"

        # WITH clause: distribution + index + partition
        with_clauses = []

        dist_clause, w2, d2 = self._distribution_clause(table)
        warnings.extend(w2); doc_refs.extend(d2)
        if dist_clause:
            with_clauses.append(dist_clause)
        else:
            with_clauses.append("DISTRIBUTION = ROUND_ROBIN")

        # Default index: CLUSTERED COLUMNSTORE INDEX for large tables
        with_clauses.append("CLUSTERED COLUMNSTORE INDEX")
        doc_refs.append(IRDocReference(
            title="Synapse CLUSTERED COLUMNSTORE INDEX",
            url="https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-tables-index",
            platform="synapse",
            purpose="Default table index",
        ))

        # Partition
        if table.partition_by and table.partition_by.columns:
            part_sql = self._partition_clause(table)
            if part_sql:
                with_clauses.append(part_sql)

        sql += f"\nWITH\n(\n    " + ",\n    ".join(with_clauses) + "\n)"

        # SORTKEY / CLUSTER BY → informational warning
        if table.sort_key or table.cluster_by:
            warnings.append(IRWarning(
                feature="SORT_CLUSTER_NOT_SUPPORTED",
                message="Synapse dedicated SQL pool does not support SORTKEY or CLUSTER BY. "
                        "Data is sorted within distributions by the CLUSTERED COLUMNSTORE INDEX. "
                        "Use PARTITION to control physical data organization.",
                doc_url="https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-tables-index",
                severity=Warningseverity.INFO,
                fallback_applied=False,
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
            doc_refs.append(IRDocReference(
                title="Synapse IDENTITY",
                url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-azure-sql-data-warehouse?view=azure-sqldw-latest",
                platform="synapse",
                purpose="Identity column",
            ))

        if not col.is_nullable:
            parts.append("NOT NULL")

        if col.default_value is not None:
            parts.append(f"DEFAULT {col.default_value}")

        return " ".join(parts), warnings, doc_refs

    def _distribution_clause(
        self, table: IRTable
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(
            title="Synapse DISTRIBUTION",
            url="https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-tables-distribute",
            platform="synapse",
            purpose="Distribution clause",
        )]
        if not table.distribution:
            return "", [], []
        dist = table.distribution
        if dist.style == DistributionStyle.HASH and dist.key_columns:
            return f"DISTRIBUTION = HASH({self._quote_identifier(dist.key_columns[0])})", [], doc_refs
        elif dist.style == DistributionStyle.ROUND_ROBIN:
            return "DISTRIBUTION = ROUND_ROBIN", [], doc_refs
        elif dist.style == DistributionStyle.REPLICATE:
            return "DISTRIBUTION = REPLICATE", [], doc_refs
        return "", [], []

    def _partition_clause(self, table: IRTable) -> str:
        p = table.partition_by
        if not p or not p.columns:
            return ""
        col = self._quote_identifier(p.columns[0])
        direction = (p.partition_properties or {}).get("range_direction", "RIGHT")
        values = ", ".join(f"'{v}'" for v in (p.range_values or []))
        return f"PARTITION ({col} RANGE {direction} FOR VALUES ({values}))"

    # -------------------------------------------------------------------------
    # CREATE VIEW
    # -------------------------------------------------------------------------

    def generate_view(
        self, view: IRView
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="Synapse CREATE VIEW", url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-view-transact-sql", platform="synapse", purpose="View generation")]
        or_replace = "OR ALTER " if view.or_replace else ""
        qname = self._qualified_name(view)
        defn = view.definition
        defn = self._convert_backtick_identifiers(defn)
        defn = self._convert_nvl2_to_case(defn)
        defn = self._convert_nvl_aware(defn)        # NVL → ISNULL
        defn = self._convert_decode_to_case(defn)
        return f"CREATE {or_replace}VIEW {qname} AS\n{defn};", [], doc_refs

    # -------------------------------------------------------------------------
    # CREATE MATERIALIZED VIEW
    # -------------------------------------------------------------------------

    def generate_materialized_view(
        self, mv: IRMaterializedView
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Synapse dedicated SQL pool supports CREATE MATERIALIZED VIEW AS SELECT with distribution.
        Docs: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-materialized-view-as-select-transact-sql?view=azure-sqldw-latest

        Limitations (from docs):
        - Requires a DISTRIBUTION clause
        - No PARTITION supported in MV
        - Automatically refreshed on base table DML
        """
        doc_refs = [IRDocReference(
            title="Synapse CREATE MATERIALIZED VIEW AS SELECT",
            url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-materialized-view-as-select-transact-sql?view=azure-sqldw-latest",
            platform="synapse",
            purpose="MV generation reference",
        )]
        warnings: List[IRWarning] = []

        qname = self._qualified_name(mv)
        dist_clause = "DISTRIBUTION = ROUND_ROBIN"
        if mv.distribution:
            d = mv.distribution
            if d.style == DistributionStyle.HASH and d.key_columns:
                dist_clause = f"DISTRIBUTION = HASH({self._quote_identifier(d.key_columns[0])})"
            elif d.style == DistributionStyle.REPLICATE:
                dist_clause = "DISTRIBUTION = REPLICATE"

        sql = f"CREATE MATERIALIZED VIEW {qname}\nWITH ({dist_clause})\nAS\n{mv.definition};"

        warnings.append(IRWarning(
            feature="SYNAPSE_MV_AUTO_REFRESH",
            message="Synapse materialized views are automatically refreshed on DML to base tables. "
                    "Manual REFRESH is not required. MV queries may be rewritten to use the MV "
                    "automatically by the optimizer.",
            doc_url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-materialized-view-as-select-transact-sql?view=azure-sqldw-latest",
            severity=Warningseverity.INFO,
        ))
        return sql, warnings, doc_refs

    # -------------------------------------------------------------------------
    # CREATE PROCEDURE / FUNCTION
    # -------------------------------------------------------------------------

    def generate_procedure(
        self, proc: IRProcedure
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Synapse dedicated SQL pool stored procedure (T-SQL).
        Docs: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql?view=azure-sqldw-latest
        """
        from app.dialects.procedure_utils import format_param_tsql, format_body_comment
        doc_refs = [IRDocReference(
            title="Synapse CREATE PROCEDURE",
            url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql?view=azure-sqldw-latest",
            platform="synapse",
            purpose="Stored procedure generation",
        )]
        qname = self._qualified_name(proc)
        params_str = ",\n    ".join(format_param_tsql(p, self.mapper, self.dialect) for p in proc.parameters)
        or_replace = "OR ALTER " if proc.or_replace else ""
        body_comment = format_body_comment(proc.language or "tsql", "synapse", proc.language)
        params_block = f"\n    {params_str}" if params_str else ""
        sql = (
            f"CREATE {or_replace}PROCEDURE {qname}({params_block}\n)\nAS\nBEGIN\n"
            f"{body_comment}\n"
            f"{proc.body}\n"
            f"END;"
        )
        return sql, [IRWarning(
            feature="PROCEDURE_MANUAL_REVIEW",
            message="Procedure body requires manual review for Synapse T-SQL syntax. "
                    "Docs: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql?view=azure-sqldw-latest",
            severity=Warningseverity.WARNING,
        )], doc_refs

    def generate_function(
        self, func: IRFunction
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Synapse dedicated SQL pool scalar function.
        Docs: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql
        """
        from app.dialects.procedure_utils import format_param_tsql, format_body_comment
        doc_refs = [IRDocReference(
            title="Synapse CREATE FUNCTION",
            url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql",
            platform="synapse",
            purpose="Scalar function generation",
        )]
        qname = self._qualified_name(func)
        params_str = ", ".join(format_param_tsql(p, self.mapper, self.dialect) for p in func.parameters)
        or_replace = "OR ALTER " if func.or_replace else ""
        ret_type = "NVARCHAR(MAX)"
        if func.return_type:
            ret_type, _, _ = self._type_to_sql(func.return_type)
        body_comment = format_body_comment(func.language or "tsql", "synapse", func.language)
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
            message="Function body requires manual review for Synapse T-SQL syntax.",
            severity=Warningseverity.WARNING,
        )], doc_refs
