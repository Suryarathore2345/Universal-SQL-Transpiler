"""
Azure Synapse Analytics dedicated SQL pool parser.

Official docs used:
  CREATE TABLE:   https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-azure-sql-data-warehouse?view=azure-sqldw-latest
  DISTRIBUTION:   https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-tables-distribute
  Data types:     https://learn.microsoft.com/en-us/sql/t-sql/data-types/data-types-transact-sql
  CREATE VIEW:    https://learn.microsoft.com/en-us/sql/t-sql/statements/create-view-transact-sql
"""
from __future__ import annotations

import re
from typing import List, Optional, Tuple

import sqlglot
import sqlglot.expressions as exp

from app.dialects.base import DialectParser
from app.ir.models import (
    Dialect, DistributionStyle, IRCheckConstraint, IRColumn, IRDataType,
    IRDDLObject, IRDistribution, IRDocReference, IRForeignKey, IRFunction,
    IRIdentity, IRMaterializedView, IRPartition, IRPrimaryKey, IRProcedure,
    IRTable, IRUniqueConstraint, IRView, IRWarning, RefreshType, Warningseverity,
)


class SynapseParser(DialectParser):
    """
    Parses Azure Synapse Analytics dedicated SQL pool DDL into IR.
    Uses tsql dialect for sqlglot; distribution/partition via regex.

    Key Synapse DDL differences from standard T-SQL:
    - WITH (DISTRIBUTION = HASH(col) | ROUND_ROBIN | REPLICATE)
    - WITH (CLUSTERED COLUMNSTORE INDEX | HEAP | CLUSTERED INDEX(cols))
    - WITH (PARTITION(col RANGE LEFT|RIGHT FOR VALUES(...)))
    - PRIMARY KEY / UNIQUE must be NONCLUSTERED NOT ENFORCED
    """

    dialect = Dialect.SYNAPSE
    _SQLGLOT_DIALECT = "tsql"

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
                r, w, d = self._parse_proc_from_sql(sql, body_style="tsql")
                doc_refs.append(IRDocReference(title="Synapse CREATE PROCEDURE", url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql?view=azure-sqldw-latest", platform="synapse", purpose="Stored procedure"))
                return r, warnings + w, doc_refs + d
            elif kind == "FUNCTION":
                r, w, d = self._parse_func_from_sql(sql, body_style="tsql")
                return r, warnings + w, doc_refs + d

        if re.search(r'\bCREATE\b.*?\bPROCEDURE\b', sql, re.IGNORECASE | re.DOTALL):
            r, w, d = self._parse_proc_from_sql(sql, body_style="tsql")
            return r, warnings + w, d
        if re.search(r'\bCREATE\b.*?\bFUNCTION\b', sql, re.IGNORECASE | re.DOTALL):
            r, w, d = self._parse_func_from_sql(sql, body_style="tsql")
            return r, warnings + w, d

        warnings.append(IRWarning(feature="UNSUPPORTED_STATEMENT", message=f"Not supported: {type(parsed).__name__}", severity=Warningseverity.WARNING))
        return None, warnings, doc_refs

    def _parse_create_table(self, node: exp.Create, raw_sql: str) -> Tuple[Optional[IRTable], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="Synapse CREATE TABLE", url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-azure-sql-data-warehouse?view=azure-sqldw-latest", platform="synapse", purpose="CREATE TABLE syntax")]
        warnings: List[IRWarning] = []

        tbl = node.find(exp.Table)
        name = tbl.name if tbl else "unknown"
        schema = (tbl.db if tbl else None) or None
        db = (tbl.catalog if tbl else None) or None

        columns, pk, fks, uniques, checks = [], None, [], [], []
        schema_expr = node.args.get("this")
        if schema_expr and hasattr(schema_expr, "expressions"):
            for expr in schema_expr.expressions:
                if isinstance(expr, exp.ColumnDef):
                    col, w, d = self._parse_column_def(expr)
                    columns.append(col); warnings.extend(w); doc_refs.extend(d)
                elif isinstance(expr, exp.PrimaryKey):
                    pk = IRPrimaryKey(columns=[c.name for c in expr.expressions])
                elif isinstance(expr, exp.ForeignKey):
                    ref = expr.args.get("reference")
                    fks.append(IRForeignKey(columns=[c.name for c in expr.expressions], ref_table=ref.this.name if ref and ref.this else "unknown", ref_schema=(ref.this.db if ref and ref.this else None) or None, ref_columns=[c.name for c in ref.expressions] if ref else []))
                elif isinstance(expr, exp.UniqueColumnConstraint):
                    uniques.append(IRUniqueConstraint(columns=[c.name for c in expr.expressions]))

        distribution = self._extract_distribution(raw_sql)
        partition = self._extract_partition(raw_sql)

        return IRTable(name=name, schema_name=schema, database_name=db, columns=columns, primary_key=pk, foreign_keys=fks, unique_constraints=uniques, check_constraints=checks, distribution=distribution, partition_by=partition), warnings, doc_refs

    def _parse_column_def(self, col_def: exp.ColumnDef) -> Tuple[IRColumn, List[IRWarning], List[IRDocReference]]:
        warnings, doc_refs = [], []
        name = col_def.name
        type_node = col_def.args.get("kind")
        type_str = type_node.sql("tsql") if type_node else "NVARCHAR(255)"
        ir_type, w, d = self._parse_data_type(type_str)
        warnings.extend(w); doc_refs.extend(d)

        is_nullable, default_val, identity = True, None, None
        for constraint in col_def.constraints:
            c = constraint.kind if hasattr(constraint, "kind") else constraint
            if isinstance(c, exp.NotNullColumnConstraint): is_nullable = False
            elif isinstance(c, exp.DefaultColumnConstraint): default_val = c.this.sql() if c.this else None
            elif isinstance(c, exp.GeneratedAsIdentityColumnConstraint):
                s = c.args.get("start"); inc = c.args.get("increment")
                start = int(str(s.this if hasattr(s, "this") else s)) if s else 1
                step = int(str(inc.this if hasattr(inc, "this") else inc)) if inc else 1
                identity = IRIdentity(start=start, increment=step)

        return IRColumn(name=name, data_type=ir_type, is_nullable=is_nullable, default_value=default_val, identity=identity), warnings, doc_refs

    def _extract_distribution(self, sql: str) -> Optional[IRDistribution]:
        """
        Extract DISTRIBUTION clause.
        Docs: https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-tables-distribute
        """
        sql_u = sql.upper()
        m_hash = re.search(r"DISTRIBUTION\s*=\s*HASH\s*\(\s*([^\)]+)\s*\)", sql_u)
        if m_hash:
            col = m_hash.group(1).strip().strip('"').strip("[]").strip()
            # Find original-case column name
            m_orig = re.search(r"DISTRIBUTION\s*=\s*HASH\s*\(\s*([^\)]+)\s*\)", sql, re.IGNORECASE)
            col_orig = m_orig.group(1).strip().strip('"').strip("[]").strip() if m_orig else col
            return IRDistribution(style=DistributionStyle.HASH, key_columns=[col_orig])
        if "DISTRIBUTION" in sql_u and "ROUND_ROBIN" in sql_u:
            return IRDistribution(style=DistributionStyle.ROUND_ROBIN)
        if "DISTRIBUTION" in sql_u and "REPLICATE" in sql_u:
            return IRDistribution(style=DistributionStyle.REPLICATE)
        return None

    def _extract_partition(self, sql: str) -> Optional[IRPartition]:
        """
        Extract PARTITION clause.
        Syntax: PARTITION(col RANGE LEFT|RIGHT FOR VALUES(v1, v2, ...))
        Docs: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-azure-sql-data-warehouse?view=azure-sqldw-latest
        """
        m = re.search(
            r"PARTITION\s*\(\s*(\w+)\s+RANGE\s+(LEFT|RIGHT)\s+FOR\s+VALUES\s*\(([^)]*)\)",
            sql, re.IGNORECASE
        )
        if m:
            col, direction, values_str = m.group(1), m.group(2).upper(), m.group(3)
            values = [v.strip().strip("'\"") for v in values_str.split(",") if v.strip()]
            return IRPartition(
                columns=[col],
                strategy="RANGE",
                range_values=values,
                partition_properties={"range_direction": direction},
            )
        return None

    def _parse_create_view(self, node: exp.Create, raw_sql: str) -> Tuple[Optional[IRView], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="Synapse CREATE VIEW", url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-view-transact-sql", platform="synapse", purpose="CREATE VIEW")]
        vn = node.find(exp.Table)
        name = vn.name if vn else "unknown"
        query = node.args.get("expression") or node.args.get("this")
        definition = query.sql(dialect="tsql") if query else ""
        return IRView(name=name, schema_name=(vn.db if vn else None) or None, definition=definition, or_replace=bool(node.args.get("replace"))), [], doc_refs

    def _parse_create_mv(self, node: exp.Create, raw_sql: str) -> Tuple[Optional[IRMaterializedView], List[IRWarning], List[IRDocReference]]:
        doc_refs = [IRDocReference(title="Synapse MV reference", url="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-materialized-view-as-select-transact-sql?view=azure-sqldw-latest", platform="synapse", purpose="MV syntax")]
        mn = node.find(exp.Table)
        name = mn.name if mn else "unknown"
        query = node.args.get("expression") or node.args.get("this")
        definition = query.sql(dialect="tsql") if query else ""
        dist = self._extract_distribution(raw_sql)
        return IRMaterializedView(name=name, schema_name=(mn.db if mn else None) or None, definition=definition, distribution=dist, refresh_type=RefreshType.AUTO, auto_refresh=True), [], doc_refs
