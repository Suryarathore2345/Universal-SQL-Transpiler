"""
Redshift SQL generator — converts IR to Redshift DDL.

Official docs used:
  CREATE TABLE:  https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html
  DISTSTYLE:     https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html
  SORTKEY:       https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html
  IDENTITY:      https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html
  CREATE VIEW:   https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_VIEW.html
  CREATE MV:     https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_MATERIALIZED_VIEW.html
  CREATE PROC:   https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_PROCEDURE.html
  CREATE FUNC:   https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_FUNCTION.html
  Data types:    https://docs.aws.amazon.com/redshift/latest/dg/c_Supported_data_types.html
"""
from __future__ import annotations

from typing import List, Optional, Tuple

from app.dialects.base import DialectGenerator
from app.ir.models import (
    Dialect, DistributionStyle, GenericType, IRColumn, IRDocReference,
    IRFunction, IRMaterializedView, IRProcedure, IRTable, IRView, IRWarning,
    RefreshType, SortKeyType, Warningseverity,
)


class RedshiftGenerator(DialectGenerator):
    """
    Generates Redshift SQL DDL from IR.
    """

    dialect = Dialect.REDSHIFT

    # Redshift uses double-quote for identifiers
    def _quote_identifier(self, name: str) -> str:
        return f'"{name}"'

    # -------------------------------------------------------------------------
    # CREATE TABLE
    # -------------------------------------------------------------------------

    def generate_table(
        self, table: IRTable
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        warnings: List[IRWarning] = []
        doc_refs = [IRDocReference(
            title="Redshift CREATE TABLE",
            url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html",
            platform="redshift",
            purpose="DDL generation reference",
        )]

        temp = "TEMPORARY " if table.is_temporary else ""
        qname = self._qualified_name(table)
        lines = []

        # Column definitions
        for col in table.columns:
            col_sql, w, d = self._column_def(col)
            lines.append(f"    {col_sql}")
            warnings.extend(w)
            doc_refs.extend(d)

        # Table-level constraints
        if table.primary_key:
            pk_cols = ", ".join(self._quote_identifier(c) for c in table.primary_key.columns)
            pk_name = f"CONSTRAINT {table.primary_key.name} " if table.primary_key.name else ""
            lines.append(f"    {pk_name}PRIMARY KEY ({pk_cols})")

        for fk in table.foreign_keys:
            fk_sql = self._fk_clause(fk)
            lines.append(f"    {fk_sql}")

        for uq in table.unique_constraints:
            uq_cols = ", ".join(self._quote_identifier(c) for c in uq.columns)
            uq_name = f"CONSTRAINT {uq.name} " if uq.name else ""
            lines.append(f"    {uq_name}UNIQUE ({uq_cols})")

        body = ",\n".join(lines)
        sql = f"CREATE {temp}TABLE {qname} (\n{body}\n)"

        # Distribution
        dist_sql, w2, d2 = self._distribution_clause(table)
        warnings.extend(w2)
        doc_refs.extend(d2)
        if dist_sql:
            sql += f"\n{dist_sql}"

        # Sort key — from native Redshift SORTKEY
        if table.sort_key and table.sort_key.columns:
            prefix = "INTERLEAVED " if table.sort_key.sort_type == SortKeyType.INTERLEAVED else ""
            sk_cols = ", ".join(self._quote_identifier(c) for c in table.sort_key.columns)
            sql += f"\n{prefix}SORTKEY ({sk_cols})"
            doc_refs.append(IRDocReference(
                title="Redshift SORTKEY",
                url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html",
                platform="redshift",
                purpose="Sort key generation",
            ))
        # CLUSTER BY from Snowflake/BigQuery/Databricks → best-effort SORTKEY in Redshift
        elif table.cluster_by and table.cluster_by.columns:
            sk_cols = ", ".join(self._quote_identifier(c) for c in table.cluster_by.columns)
            sql += f"\nSORTKEY ({sk_cols})"
            warnings.append(IRWarning(
                feature="CLUSTER_BY_TO_SORTKEY",
                message=f"Snowflake/BigQuery CLUSTER BY converted to Redshift SORTKEY. "
                        f"Clustering semantics differ: Redshift SORTKEY affects physical sort order; "
                        f"Snowflake CLUSTER BY affects micro-partition pruning.",
                doc_url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html",
                severity=Warningseverity.INFO,
                fallback_applied=True,
            ))
            doc_refs.append(IRDocReference(
                title="Redshift SORTKEY",
                url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html",
                platform="redshift",
                purpose="CLUSTER BY → SORTKEY translation",
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

        # ENCODE — only emit if present in source
        if col.encoding:
            parts.append(f"ENCODE {col.encoding}")

        # IDENTITY
        if col.identity:
            # Redshift IDENTITY(seed, step)
            # Docs: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html
            parts.append(f"IDENTITY({col.identity.start},{col.identity.increment})")
            doc_refs.append(IRDocReference(
                title="Redshift IDENTITY",
                url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html",
                platform="redshift",
                purpose="Identity column generation",
            ))

        if not col.is_nullable:
            parts.append("NOT NULL")

        if col.default_value is not None:
            parts.append(f"DEFAULT {col.default_value}")

        return " ".join(parts), warnings, doc_refs

    def _fk_clause(self, fk) -> str:
        cols = ", ".join(self._quote_identifier(c) for c in fk.columns)
        ref_table = fk.ref_table
        if fk.ref_schema:
            ref_table = f"{fk.ref_schema}.{fk.ref_table}"
        ref_cols = ", ".join(self._quote_identifier(c) for c in fk.ref_columns)
        name = f"CONSTRAINT {fk.name} " if fk.name else ""
        return f"{name}FOREIGN KEY ({cols}) REFERENCES {ref_table} ({ref_cols})"

    def _distribution_clause(
        self, table: IRTable
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Generate DISTSTYLE clause.
        Redshift docs: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html
        """
        doc_refs = [IRDocReference(
            title="Redshift DISTSTYLE",
            url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html",
            platform="redshift",
            purpose="Distribution clause generation",
        )]

        if not table.distribution:
            return "", [], []

        dist = table.distribution
        if dist.style == DistributionStyle.HASH:
            if dist.key_columns:
                return f"DISTSTYLE KEY\nDISTKEY ({self._quote_identifier(dist.key_columns[0])})", [], doc_refs
            return "DISTSTYLE KEY", [], doc_refs
        elif dist.style == DistributionStyle.ROUND_ROBIN:
            return "DISTSTYLE EVEN", [], doc_refs
        elif dist.style == DistributionStyle.REPLICATE:
            return "DISTSTYLE ALL", [], doc_refs
        elif dist.style == DistributionStyle.AUTO:
            return "DISTSTYLE AUTO", [], doc_refs

        return "", [], []

    def _qualified_name(self, obj) -> str:
        parts = []
        if obj.database_name:
            parts.append(obj.database_name)
        if obj.schema_name:
            parts.append(obj.schema_name)
        parts.append(obj.name)
        return ".".join(parts)

    # -------------------------------------------------------------------------
    # CREATE VIEW
    # -------------------------------------------------------------------------

    def generate_view(
        self, view: IRView
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(
            title="Redshift CREATE VIEW",
            url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_VIEW.html",
            platform="redshift",
            purpose="View generation reference",
        )]

        or_replace = "OR REPLACE " if view.or_replace else ""
        qname = self._qualified_name(view)
        defn = view.definition
        defn = self._convert_backtick_identifiers(defn)   # `id` → "id"
        defn = self._convert_nvl2_to_case(defn)           # NVL2 → CASE WHEN
        defn = self._convert_isnull_to_nvl(defn)          # ISNULL → NVL
        defn = self._convert_decode_to_case(defn)         # DECODE native, but keep for safety
        sql = f"CREATE {or_replace}VIEW {qname} AS\n{defn};"
        return sql, [], doc_refs

    # -------------------------------------------------------------------------
    # CREATE MATERIALIZED VIEW
    # -------------------------------------------------------------------------

    def generate_materialized_view(
        self, mv: IRMaterializedView
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Redshift MV docs:
        https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_MATERIALIZED_VIEW.html

        AUTO REFRESH: https://docs.aws.amazon.com/redshift/latest/dg/materialized-view-refresh.html
        """
        doc_refs = [IRDocReference(
            title="Redshift CREATE MATERIALIZED VIEW",
            url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_MATERIALIZED_VIEW.html",
            platform="redshift",
            purpose="MV generation reference",
        )]

        qname = self._qualified_name(mv)
        clauses = []

        # Distribution
        if mv.distribution:
            dist_sql, _, d = self._distribution_clause_from_dist(mv.distribution)
            if dist_sql:
                clauses.append(dist_sql)
            doc_refs.extend(d)

        # AUTO REFRESH
        auto_refresh = "AUTO REFRESH YES" if mv.auto_refresh else "AUTO REFRESH NO"
        clauses.append(auto_refresh)

        defn = self._convert_backtick_identifiers(mv.definition)
        defn = self._convert_nvl2_to_case(defn)
        defn = self._convert_isnull_to_nvl(defn)

        clause_str = "\n".join(clauses)
        if clause_str:
            sql = f"CREATE MATERIALIZED VIEW {qname}\n{clause_str}\nAS\n{defn};"
        else:
            sql = f"CREATE MATERIALIZED VIEW {qname} AS\n{defn};"

        return sql, [], doc_refs

    # -------------------------------------------------------------------------
    # CREATE PROCEDURE  (Redshift PL/pgSQL)
    # Docs: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_PROCEDURE.html
    # -------------------------------------------------------------------------

    def generate_procedure(
        self, proc: IRProcedure
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        from app.dialects.procedure_utils import format_param_plpgsql, format_body_comment, MANUAL_REVIEW_COMMENT
        doc_refs = [IRDocReference(title="Redshift CREATE PROCEDURE", url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_PROCEDURE.html", platform="redshift", purpose="Stored procedure generation")]
        qname = self._qualified_name(proc)
        params_str = ",\n    ".join(format_param_plpgsql(p, self.mapper, self.dialect) for p in proc.parameters)
        or_replace = "OR REPLACE " if proc.or_replace else ""
        body_comment = format_body_comment(proc.language or "plpgsql", "redshift", proc.language)
        sql = (
            f"CREATE {or_replace}PROCEDURE {qname}(\n    {params_str}\n)\n"
            f"LANGUAGE plpgsql\n"
            f"AS $$\n"
            f"{body_comment}\n"
            f"{proc.body}\n"
            f"$$;"
        )
        return sql, [IRWarning(feature="PROCEDURE_MANUAL_REVIEW", message="Procedure body requires manual review for Redshift PL/pgSQL syntax. See: https://docs.aws.amazon.com/redshift/latest/dg/stored-procedure-overview.html", severity=Warningseverity.WARNING)], doc_refs

    def generate_function(
        self, func: IRFunction
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Redshift UDF: Python or SQL scalar UDF.
        Docs: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_FUNCTION.html
        """
        from app.dialects.procedure_utils import format_param_plpgsql, format_body_comment
        doc_refs = [IRDocReference(title="Redshift CREATE FUNCTION (UDF)", url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_FUNCTION.html", platform="redshift", purpose="UDF generation")]
        qname = self._qualified_name(func)
        params_str = ", ".join(format_param_plpgsql(p, self.mapper, self.dialect) for p in func.parameters)
        lang = func.language or "plpythonu"
        ret_type = "FLOAT"
        if func.return_type:
            ret_type, _, _ = self._type_to_sql(func.return_type)
        or_replace = "OR REPLACE " if func.or_replace else ""
        body_comment = format_body_comment(func.language or "unknown", "redshift", func.language)
        sql = (
            f"CREATE {or_replace}FUNCTION {qname}({params_str})\n"
            f"RETURNS {ret_type}\n"
            f"STABLE\n"
            f"AS $$\n"
            f"{body_comment}\n"
            f"{func.body}\n"
            f"$$ LANGUAGE {lang};"
        )
        return sql, [IRWarning(feature="FUNCTION_MANUAL_REVIEW", message="UDF body requires manual review. Redshift supports Python (plpythonu) and SQL UDFs.", severity=Warningseverity.WARNING)], doc_refs

    def _qualified_name(self, obj) -> str:
        parts = []
        if getattr(obj, "database_name", None): parts.append(obj.database_name)
        if getattr(obj, "schema_name", None): parts.append(obj.schema_name)
        parts.append(obj.name)
        return ".".join(parts)

    def _distribution_clause_from_dist(self, dist) -> Tuple[str, list, list]:
        doc_refs = [IRDocReference(
            title="Redshift DISTSTYLE",
            url="https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html",
            platform="redshift",
            purpose="Distribution clause",
        )]
        if dist.style == DistributionStyle.HASH and dist.key_columns:
            return f"DISTSTYLE KEY\nDISTKEY ({self._quote_identifier(dist.key_columns[0])})", [], doc_refs
        elif dist.style == DistributionStyle.ROUND_ROBIN:
            return "DISTSTYLE EVEN", [], doc_refs
        elif dist.style == DistributionStyle.REPLICATE:
            return "DISTSTYLE ALL", [], doc_refs
        return "", [], []
