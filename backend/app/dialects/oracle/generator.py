"""
Oracle Database generator — converts IR to Oracle DDL.

Official docs used:
  CREATE TABLE:     https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html
  Data types:       https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Data-Types.html
  IDENTITY column:  https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html#GUID-F9CE0CC3-13AE-4744-A43C-EAC7A71AAAB6
  PARTITION BY:     https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html
  CREATE VIEW:      https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-VIEW.html
  CREATE MV:        https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-MATERIALIZED-VIEW.html

Notes:
  - Oracle DATE includes time component; ISO DATE (date only) → use TIMESTAMP(0) or DATE with note
  - VARCHAR2 preferred over VARCHAR in Oracle
  - GENERATED [ALWAYS|BY DEFAULT [ON NULL]] AS IDENTITY
  - PARTITION BY RANGE/LIST/HASH with INTERVAL clause for automatic partitioning
"""
from __future__ import annotations

from typing import List, Tuple

from app.dialects.base import DialectGenerator
from app.ir.models import (
    Dialect, DistributionStyle, GeneratedType, IRColumn, IRDocReference,
    IRFunction, IRMaterializedView, IRProcedure, IRTable, IRView, IRWarning,
    RefreshType, Warningseverity,
)


class OracleGenerator(DialectGenerator):
    """
    Generates Oracle Database DDL from IR.
    Uses double-quote quoting for identifiers.
    """

    dialect = Dialect.ORACLE

    def _quote_identifier(self, name: str) -> str:
        return f'"{name}"'

    def _qualified_name(self, obj) -> str:
        parts = []
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
            title="Oracle CREATE TABLE",
            url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html",
            platform="oracle",
            purpose="DDL generation reference",
        )]

        temp = "GLOBAL TEMPORARY " if table.is_temporary else ""
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

        for ck in table.check_constraints:
            ck_name = f"CONSTRAINT {self._quote_identifier(ck.name)} " if ck.name else ""
            lines.append(f"    {ck_name}CHECK ({ck.expression})")

        body = ",\n".join(lines)
        core_sql = f"CREATE {temp}TABLE {qname} (\n{body}\n)"
        if table.or_replace:
            # Oracle has no CREATE OR REPLACE TABLE. Use PL/SQL DROP + CREATE pattern.
            # Oracle 23c adds IF NOT EXISTS / CREATE OR REPLACE TABLE, but for
            # maximum compatibility we emit the traditional PL/SQL anonymous block.
            warnings.append(IRWarning(
                feature="CREATE_OR_REPLACE_TABLE_ORACLE",
                message=(
                    f"Oracle does not support CREATE OR REPLACE TABLE. "
                    f"Emitting PL/SQL anonymous block that drops the table if it exists, "
                    f"then recreates it. Requires EXECUTE IMMEDIATE privileges. "
                    f"Oracle 23c+ supports CREATE OR REPLACE TABLE natively."
                ),
                doc_url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html",
                severity=Warningseverity.WARNING,
                fallback_applied=True,
            ))
            sql = (
                f"BEGIN\n"
                f"  EXECUTE IMMEDIATE 'DROP TABLE {qname} PURGE';\n"
                f"EXCEPTION\n"
                f"  WHEN OTHERS THEN NULL;\n"
                f"END;\n"
                f"/\n"
                f"{core_sql}"
            )
        elif table.if_not_exists:
            # Oracle 23c+ supports CREATE TABLE IF NOT EXISTS natively.
            warnings.append(IRWarning(
                feature="IF_NOT_EXISTS_ORACLE_23C",
                message=(
                    "CREATE TABLE IF NOT EXISTS requires Oracle 23c or later. "
                    "For older Oracle versions, use a PL/SQL block with exception handling. "
                    "Emitting Oracle 23c syntax."
                ),
                doc_url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html",
                severity=Warningseverity.INFO,
                fallback_applied=False,
            ))
            sql = f"CREATE {temp}TABLE IF NOT EXISTS {qname} (\n{body}\n)"
        else:
            sql = core_sql

        # PARTITION BY
        if table.partition_by and table.partition_by.columns:
            part_sql = self._partition_clause(table)
            if part_sql:
                sql += f"\n{part_sql}"
                doc_refs.append(IRDocReference(
                    title="Oracle PARTITION BY",
                    url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html",
                    platform="oracle",
                    purpose="Partition clause generation",
                ))
        elif table.cluster_by and table.cluster_by.columns:
            # Snowflake/Databricks CLUSTER BY → Oracle PARTITION BY HASH (closest equivalent)
            warnings.append(IRWarning(
                feature="CLUSTER_BY_TO_PARTITION",
                message="Source CLUSTER BY converted to Oracle PARTITION BY HASH. "
                        "Oracle does not have a CLUSTER BY equivalent at table level. "
                        "PARTITION BY HASH distributes rows across partitions similarly to clustering.",
                doc_url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html",
                severity=Warningseverity.INFO,
                fallback_applied=True,
            ))
            cl_col = self._quote_identifier(table.cluster_by.columns[0])
            sql += f"\nPARTITION BY HASH ({cl_col}) PARTITIONS 8"

        elif table.sort_key and table.sort_key.columns:
            warnings.append(IRWarning(
                feature="SORTKEY_NOT_SUPPORTED_ORACLE",
                message="Oracle does not have a SORTKEY equivalent. "
                        "For sorted physical storage, consider Index Organized Tables (IOT) "
                        "or creating a B-tree index on the sort key columns.",
                doc_url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html",
                severity=Warningseverity.INFO,
                fallback_applied=False,
            ))

        # Distribution not applicable
        if table.distribution:
            warnings.append(IRWarning(
                feature="DISTRIBUTION_NOT_SUPPORTED_ORACLE",
                message="Oracle does not support DISTRIBUTION clauses. "
                        "Distribution is managed at the RAC or sharding infrastructure level.",
                doc_url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html",
                severity=Warningseverity.INFO,
                unsupported=True,
                fallback_applied=True,
            ))

        return sql + ";", warnings, doc_refs

    def _column_def(
        self, col: IRColumn
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        from app.ir.models import GenericType
        warnings: List[IRWarning] = []
        doc_refs: List[IRDocReference] = []

        type_str, w, d = self._type_to_sql(col.data_type)
        warnings.extend(w); doc_refs.extend(d)

        # Detect BOOLEAN → NUMBER(1) conversion so we can add a CHECK constraint
        # and emit the appropriate warning.
        # Docs: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Data-Types.html
        is_boolean_col = col.data_type.generic_type == GenericType.BOOLEAN
        if is_boolean_col:
            # type_str is already NUMBER(1) via type_mappings.yaml
            warnings.append(IRWarning(
                feature="NO_BOOLEAN",
                message=(
                    f"Column '{col.name}': Oracle 21c and earlier have no BOOLEAN type. "
                    f"Converted to NUMBER(1) CHECK ({col.name} IN (0,1)). "
                    f"Oracle 23c adds native BOOLEAN but most deployments are on 12c–19c."
                ),
                doc_url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Data-Types.html",
                severity=Warningseverity.WARNING,
            ))

        parts = [self._quote_identifier(col.name), type_str]

        if col.identity:
            gen = "ALWAYS" if col.identity.generated == GeneratedType.ALWAYS else "BY DEFAULT ON NULL"
            parts.append(
                f"GENERATED {gen} AS IDENTITY "
                f"(START WITH {col.identity.start} INCREMENT BY {col.identity.increment})"
            )
            doc_refs.append(IRDocReference(
                title="Oracle GENERATED AS IDENTITY",
                url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html#GUID-F9CE0CC3-13AE-4744-A43C-EAC7A71AAAB6",
                platform="oracle",
                purpose="Identity column generation",
            ))

        if not col.is_nullable:
            parts.append("NOT NULL")

        if col.default_value is not None:
            # Translate boolean default values to 0/1 for NUMBER(1)
            if is_boolean_col:
                dv = str(col.default_value).upper().strip()
                mapped_dv = "1" if dv in ("TRUE", "1", "YES") else "0"
                parts.append(f"DEFAULT {mapped_dv}")
            else:
                parts.append(f"DEFAULT {col.default_value}")

        # Add CHECK constraint for BOOLEAN → NUMBER(1) columns
        if is_boolean_col:
            col_q = self._quote_identifier(col.name)
            parts.append(f"CHECK ({col_q} IN (0, 1))")

        return " ".join(parts), warnings, doc_refs

    def _partition_clause(self, table: IRTable) -> str:
        p = table.partition_by
        if not p or not p.columns:
            return ""
        strategy = (p.strategy or "RANGE").upper()
        cols = ", ".join(self._quote_identifier(c) for c in p.columns)
        if strategy == "RANGE" and p.range_values:
            value_str = ", ".join(f"'{v}'" for v in p.range_values)
            return (
                f"PARTITION BY RANGE ({cols})\n"
                f"(\n"
                f"    PARTITION p_initial VALUES LESS THAN ({value_str}),\n"
                f"    PARTITION p_max VALUES LESS THAN (MAXVALUE)\n"
                f")"
            )
        elif strategy in ("HASH", "LIST"):
            return f"PARTITION BY {strategy} ({cols}) PARTITIONS 8"
        return f"PARTITION BY {strategy} ({cols})"

    # -------------------------------------------------------------------------
    # CREATE VIEW
    # -------------------------------------------------------------------------

    def generate_view(
        self, view: IRView
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="Oracle CREATE VIEW", url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-VIEW.html", platform="oracle", purpose="View generation")]
        or_replace = "OR REPLACE " if view.or_replace else ""
        qname = self._qualified_name(view)
        defn, warnings = self._apply_oracle_view_conversions(view.definition)
        return f"CREATE {or_replace}VIEW {qname} AS\n{defn};", warnings, doc_refs

    # -------------------------------------------------------------------------
    # CREATE MATERIALIZED VIEW
    # -------------------------------------------------------------------------

    def generate_materialized_view(
        self, mv: IRMaterializedView
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Oracle materialized view with REFRESH ON COMMIT or ON DEMAND.
        Docs: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-MATERIALIZED-VIEW.html
        """
        doc_refs = [IRDocReference(
            title="Oracle CREATE MATERIALIZED VIEW",
            url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-MATERIALIZED-VIEW.html",
            platform="oracle",
            purpose="MV generation reference",
        )]

        qname = self._qualified_name(mv)
        refresh_clause = "REFRESH ON COMMIT" if mv.auto_refresh else "REFRESH ON DEMAND"
        defn, conv_warnings = self._apply_oracle_view_conversions(mv.definition)

        sql = (
            f"CREATE MATERIALIZED VIEW {qname}\n"
            f"BUILD IMMEDIATE\n"
            f"{refresh_clause}\n"
            f"ENABLE QUERY REWRITE\n"
            f"AS\n"
            f"{defn};"
        )

        warnings = list(conv_warnings) + [IRWarning(
            feature="ORACLE_MV_QUERY_REWRITE",
            message="Oracle MV generated with ENABLE QUERY REWRITE — optimizer may automatically "
                    "rewrite queries to use this MV. "
                    "REFRESH ON COMMIT requires the base tables to have ENABLE ROW MOVEMENT. "
                    "Complex queries may only support ON DEMAND refresh.",
            doc_url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-MATERIALIZED-VIEW.html",
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
        Oracle PL/SQL stored procedure.
        Docs: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-PROCEDURE.html
        Syntax: CREATE [OR REPLACE] PROCEDURE name (params) AS BEGIN body END name;
        """
        from app.dialects.procedure_utils import format_param_oracle, format_body_comment
        doc_refs = [IRDocReference(
            title="Oracle CREATE PROCEDURE",
            url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-PROCEDURE.html",
            platform="oracle",
            purpose="Stored procedure generation",
        )]
        qname = self._qualified_name(proc)
        params_str = ",\n    ".join(format_param_oracle(p, self.mapper, self.dialect) for p in proc.parameters)
        or_replace = "OR REPLACE " if proc.or_replace else ""
        body_comment = format_body_comment(proc.language or "plsql", "oracle", proc.language)
        params_block = f"\n    {params_str}\n" if params_str else ""
        sql = (
            f"CREATE {or_replace}PROCEDURE {qname}({params_block})\nAS\nBEGIN\n"
            f"{body_comment}\n"
            f"{proc.body}\n"
            f"END {proc.name};"
        )
        return sql, [IRWarning(
            feature="PROCEDURE_MANUAL_REVIEW",
            message="Procedure body requires manual review for Oracle PL/SQL syntax. "
                    "Docs: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-PROCEDURE.html",
            severity=Warningseverity.WARNING,
        )], doc_refs

    def generate_function(
        self, func: IRFunction
    ) -> Tuple[str, List[IRWarning], List[IRDocReference]]:
        """
        Oracle PL/SQL function.
        Docs: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-FUNCTION.html
        Syntax: CREATE [OR REPLACE] FUNCTION name (params) RETURN type AS BEGIN body END name;
        """
        from app.dialects.procedure_utils import format_param_oracle, format_body_comment
        doc_refs = [IRDocReference(
            title="Oracle CREATE FUNCTION",
            url="https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-FUNCTION.html",
            platform="oracle",
            purpose="PL/SQL function generation",
        )]
        qname = self._qualified_name(func)
        params_str = ", ".join(format_param_oracle(p, self.mapper, self.dialect) for p in func.parameters)
        or_replace = "OR REPLACE " if func.or_replace else ""
        ret_type = "VARCHAR2(4000)"
        if func.return_type:
            ret_type, _, _ = self._type_to_sql(func.return_type)
        body_comment = format_body_comment(func.language or "plsql", "oracle", func.language)
        sql = (
            f"CREATE {or_replace}FUNCTION {qname}({params_str})\n"
            f"RETURN {ret_type}\n"
            f"AS\nBEGIN\n"
            f"{body_comment}\n"
            f"{func.body}\n"
            f"END {func.name};"
        )
        return sql, [IRWarning(
            feature="FUNCTION_MANUAL_REVIEW",
            message="Function body requires manual review for Oracle PL/SQL syntax. "
                    "Docs: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-FUNCTION.html",
            severity=Warningseverity.WARNING,
        )], doc_refs
