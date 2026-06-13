"""
Static limitations registry for the Universal SQL Transpiler.

Each entry describes a known constraint that applies when a specific dialect
is the TARGET of transpilation.  The data is served via GET /api/limitations
and displayed in the frontend limitations panel.

level:
  "info"  — behaviour difference; output is valid but semantics may differ
  "warn"  — feature silently dropped or structurally modified
  "error" — feature cannot be automatically translated; manual work required

All doc_url values point to official vendor documentation only.
"""
from __future__ import annotations

from typing import TypedDict


class LimitationEntry(TypedDict):
    feature: str
    level: str          # "info" | "warn" | "error"
    description: str
    doc_url: str


# ---------------------------------------------------------------------------
# Per-dialect limitation lists  (keyed by target dialect)
# ---------------------------------------------------------------------------

_LIMITATIONS: dict[str, list[LimitationEntry]] = {
    "redshift": [
        {
            "feature": "PROCEDURE_BODY_MANUAL",
            "level": "warn",
            "description": (
                "Stored procedure bodies are wrapped in a plpgsql dollar-quoted block as-is. "
                "PL/pgSQL-specific syntax (cursors, RAISE, PERFORM) must be verified manually."
            ),
            "doc_url": "https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_PROCEDURE.html",
        },
        {
            "feature": "IDENTITY_SEED_STEP",
            "level": "info",
            "description": (
                "Redshift IDENTITY requires explicit (seed, step) arguments, e.g. IDENTITY(1,1). "
                "Auto-increment columns from other dialects are mapped to IDENTITY(1,1) by default."
            ),
            "doc_url": "https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html",
        },
        {
            "feature": "NO_CHECK_CONSTRAINTS",
            "level": "info",
            "description": (
                "Redshift parses but does NOT enforce CHECK constraints. "
                "They are preserved in the DDL for documentation only."
            ),
            "doc_url": "https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html",
        },
    ],

    "snowflake": [
        {
            "feature": "DISTKEY_REMOVED",
            "level": "warn",
            "description": (
                "Redshift DISTKEY/DISTSTYLE clauses are removed. "
                "Snowflake manages data distribution automatically; "
                "use CLUSTER BY for query optimization if needed."
            ),
            "doc_url": "https://docs.snowflake.com/en/user-guide/tables-clustering-keys",
        },
        {
            "feature": "SORTKEY_TO_CLUSTER_BY",
            "level": "info",
            "description": (
                "Redshift SORTKEY is converted to CLUSTER BY. "
                "Snowflake clustering uses micro-partition pruning, not sort order — "
                "semantics differ and should be validated."
            ),
            "doc_url": "https://docs.snowflake.com/en/user-guide/tables-clustering-keys",
        },
        {
            "feature": "MV_ENTERPRISE_EDITION",
            "level": "info",
            "description": (
                "CREATE MATERIALIZED VIEW requires Snowflake Enterprise Edition or higher."
            ),
            "doc_url": "https://docs.snowflake.com/en/sql-reference/sql/create-materialized-view",
        },
        {
            "feature": "PROCEDURE_BODY_MANUAL",
            "level": "warn",
            "description": (
                "Procedure bodies are wrapped in a dollar-quoted block as-is. "
                "Snowflake Scripting syntax differs from T-SQL and PL/SQL — "
                "manual adaptation is required for non-trivial bodies."
            ),
            "doc_url": "https://docs.snowflake.com/en/developer-guide/snowflake-scripting/index",
        },
    ],

    "sqlserver": [
        {
            "feature": "MV_AS_INDEXED_VIEW",
            "level": "warn",
            "description": (
                "SQL Server has no native materialized views. "
                "Translated to an indexed view with WITH SCHEMABINDING. "
                "The SELECT must reference fully-qualified two-part table names; "
                "GROUP BY aggregations may require additional adjustments."
            ),
            "doc_url": (
                "https://learn.microsoft.com/en-us/sql/relational-databases/views/"
                "create-indexed-views?view=sql-server-ver16"
            ),
        },
        {
            "feature": "DISTRIBUTION_REMOVED",
            "level": "info",
            "description": (
                "Synapse DISTRIBUTION / CLUSTERED COLUMNSTORE INDEX table options "
                "are not supported in SQL Server and are removed."
            ),
            "doc_url": (
                "https://learn.microsoft.com/en-us/sql/t-sql/statements/"
                "create-table-transact-sql?view=sql-server-ver16"
            ),
        },
        {
            "feature": "NO_OR_REPLACE",
            "level": "info",
            "description": (
                "SQL Server uses CREATE OR ALTER (procedures/functions) or "
                "DROP-then-CREATE for tables and views. "
                "CREATE OR REPLACE from other dialects is rewritten accordingly."
            ),
            "doc_url": (
                "https://learn.microsoft.com/en-us/sql/t-sql/statements/"
                "create-procedure-transact-sql?view=sql-server-ver16"
            ),
        },
    ],

    "synapse": [
        {
            "feature": "DISTRIBUTION_REQUIRED",
            "level": "warn",
            "description": (
                "Every Synapse table should have an explicit DISTRIBUTION clause "
                "(HASH, ROUND_ROBIN, or REPLICATE). "
                "Tables without one default to ROUND_ROBIN — validate before deploying."
            ),
            "doc_url": (
                "https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/"
                "sql-data-warehouse-tables-distribute"
            ),
        },
        {
            "feature": "NO_FOREIGN_KEYS",
            "level": "info",
            "description": (
                "Synapse Analytics does not enforce FOREIGN KEY constraints. "
                "They are retained in the DDL as NOT ENFORCED documentation only."
            ),
            "doc_url": (
                "https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/"
                "sql-data-warehouse-table-constraints"
            ),
        },
        {
            "feature": "MV_DISTRIBUTION_REQUIRED",
            "level": "warn",
            "description": (
                "Synapse MATERIALIZED VIEW requires a WITH (DISTRIBUTION = ...) clause. "
                "A default ROUND_ROBIN distribution is added when the source has none."
            ),
            "doc_url": (
                "https://learn.microsoft.com/en-us/sql/t-sql/statements/"
                "create-materialized-view-as-select-transact-sql?view=azure-sqldw-latest"
            ),
        },
    ],

    "fabric_dw": [
        {
            "feature": "NO_MATERIALIZED_VIEWS",
            "level": "error",
            "description": (
                "Microsoft Fabric Data Warehouse does not support CREATE MATERIALIZED VIEW. "
                "Materialized views are converted to regular CREATE VIEW with a warning. "
                "Refresh logic must be implemented externally (e.g., Fabric Pipelines)."
            ),
            "doc_url": (
                "https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area"
            ),
        },
        {
            "feature": "CLUSTER_BY_MAX_4",
            "level": "info",
            "description": (
                "Fabric DW CLUSTER BY supports a maximum of 4 columns. "
                "Excess columns beyond the first 4 are dropped with a warning."
            ),
            "doc_url": (
                "https://learn.microsoft.com/en-us/sql/t-sql/statements/"
                "create-table-azure-sql-data-warehouse?view=fabric"
            ),
        },
        {
            "feature": "NO_DISTRIBUTION",
            "level": "info",
            "description": (
                "Fabric DW does not expose DISTRIBUTION options — "
                "DISTRIBUTION clauses from Synapse sources are removed."
            ),
            "doc_url": (
                "https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area"
            ),
        },
    ],

    "databricks": [
        {
            "feature": "NO_STORED_PROCEDURES",
            "level": "error",
            "description": (
                "Databricks SQL does not support CREATE PROCEDURE. "
                "Stored procedures are converted to a SQL UDF stub that requires "
                "significant manual adaptation. "
                "Consider using Databricks Notebooks or Python UDFs for procedural logic."
            ),
            "doc_url": (
                "https://docs.databricks.com/en/sql/language-manual/"
                "sql-ref-syntax-ddl-create-sql-function.html"
            ),
        },
        {
            "feature": "CLUSTER_BY_VS_PARTITION",
            "level": "warn",
            "description": (
                "Delta Lake CLUSTER BY (liquid clustering) and PARTITIONED BY are "
                "mutually exclusive. When both are present in the source, "
                "PARTITIONED BY takes precedence and CLUSTER BY is dropped."
            ),
            "doc_url": "https://docs.databricks.com/en/delta/clustering.html",
        },
        {
            "feature": "IDENTITY_GENERATED_ALWAYS",
            "level": "info",
            "description": (
                "Databricks uses GENERATED ALWAYS AS IDENTITY with no explicit seed/step. "
                "IDENTITY(seed, step) from other dialects is converted to GENERATED ALWAYS AS IDENTITY."
            ),
            "doc_url": (
                "https://docs.databricks.com/en/sql/language-manual/"
                "sql-ref-syntax-ddl-create-table-using.html"
            ),
        },
    ],

    "oracle": [
        {
            "feature": "DATE_INCLUDES_TIME",
            "level": "info",
            "description": (
                "Oracle DATE stores both date and time components (unlike SQL standard DATE). "
                "Use TIMESTAMP(0) for date-only semantics when migrating from other platforms."
            ),
            "doc_url": (
                "https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/"
                "Data-Types.html#GUID-1F4B3F77-ED0F-43C3-9D31-9D18B54B5B49"
            ),
        },
        {
            "feature": "NO_BOOLEAN",
            "level": "warn",
            "description": (
                "Oracle 21c and earlier have no BOOLEAN type. "
                "BOOLEAN columns are converted to NUMBER(1) CHECK (col IN (0,1))."
            ),
            "doc_url": (
                "https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/"
                "Data-Types.html"
            ),
        },
        {
            "feature": "PROCEDURE_BODY_MANUAL",
            "level": "warn",
            "description": (
                "Procedure bodies are wrapped in PL/SQL BEGIN…END as-is. "
                "Variable declarations, exception handlers, and cursor syntax "
                "differ from T-SQL and plpgsql — manual review required."
            ),
            "doc_url": (
                "https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/"
                "CREATE-PROCEDURE.html"
            ),
        },
        {
            "feature": "FUNCTION_RETURN_KEYWORD",
            "level": "info",
            "description": (
                "Oracle uses RETURN (not RETURNS) in function signatures. "
                "RETURNS from other dialects is automatically rewritten to RETURN."
            ),
            "doc_url": (
                "https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/"
                "CREATE-FUNCTION.html"
            ),
        },
    ],

    "bigquery": [
        {
            "feature": "NO_IDENTITY",
            "level": "warn",
            "description": (
                "BigQuery has no IDENTITY / AUTOINCREMENT columns. "
                "Auto-generated keys must be produced by the application "
                "or via GENERATE_UUID() / sequences in your pipeline."
            ),
            "doc_url": (
                "https://cloud.google.com/bigquery/docs/reference/standard-sql/"
                "data-definition-language#column_schema"
            ),
        },
        {
            "feature": "PK_FK_NOT_ENFORCED",
            "level": "info",
            "description": (
                "BigQuery PRIMARY KEY and FOREIGN KEY constraints are informational only "
                "(NOT ENFORCED). Referential integrity is not checked at write time."
            ),
            "doc_url": (
                "https://cloud.google.com/bigquery/docs/reference/standard-sql/"
                "data-definition-language#column_schema"
            ),
        },
        {
            "feature": "CLUSTER_BY_MAX_4",
            "level": "info",
            "description": (
                "BigQuery CLUSTER BY supports a maximum of 4 columns. "
                "Excess columns beyond the first 4 are silently dropped."
            ),
            "doc_url": "https://cloud.google.com/bigquery/docs/clustered-tables",
        },
        {
            "feature": "PROCEDURE_BODY_MANUAL",
            "level": "warn",
            "description": (
                "Procedure bodies are wrapped in BigQuery Scripting BEGIN…END as-is. "
                "Variable declarations and control flow differ from T-SQL / PL/SQL — "
                "manual adaptation is required."
            ),
            "doc_url": (
                "https://cloud.google.com/bigquery/docs/reference/standard-sql/"
                "scripting"
            ),
        },
    ],
}


# ---------------------------------------------------------------------------
# Public accessor
# ---------------------------------------------------------------------------

def get_limitations(dialect: str | None = None) -> dict[str, list[LimitationEntry]]:
    """Return limitations for a single dialect, or all dialects if dialect is None."""
    if dialect is None:
        return _LIMITATIONS
    key = dialect.lower()
    if key not in _LIMITATIONS:
        return {}
    return {key: _LIMITATIONS[key]}
