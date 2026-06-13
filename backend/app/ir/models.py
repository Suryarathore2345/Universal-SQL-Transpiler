"""
Universal SQL Transpiler — Intermediate Representation (IR) models.

These Pydantic models form a dialect-agnostic representation of SQL DDL objects.
Every dialect's parser converts SQL → IR; every generator converts IR → SQL.
This gives N parsers + N generators = full N×N conversion.
"""
from __future__ import annotations

from enum import Enum
from typing import Any, Dict, List, Optional, Union
from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Enumerations
# ---------------------------------------------------------------------------

class Dialect(str, Enum):
    REDSHIFT = "redshift"
    FABRIC_DW = "fabric_dw"
    SYNAPSE = "synapse"
    SQLSERVER = "sqlserver"
    DATABRICKS = "databricks"
    SNOWFLAKE = "snowflake"
    ORACLE = "oracle"
    BIGQUERY = "bigquery"


class ObjectType(str, Enum):
    TABLE = "table"
    VIEW = "view"
    MATERIALIZED_VIEW = "materialized_view"
    PROCEDURE = "procedure"
    FUNCTION = "function"
    INDEX = "index"
    SCHEMA = "schema"
    DATABASE = "database"
    SEQUENCE = "sequence"
    ALTER_TABLE = "alter_table"


class GenericType(str, Enum):
    """
    Canonical type identifiers used in the IR. Each dialect maps its native
    types to/from these via type_mappings.yaml.
    """
    # Integers
    INT8 = "INT8"        # TINYINT — 1-byte (not in Redshift/Fabric)
    INT16 = "INT16"      # SMALLINT — 2-byte
    INT32 = "INT32"      # INT/INTEGER — 4-byte
    INT64 = "INT64"      # BIGINT — 8-byte

    # Exact numeric
    DECIMAL = "DECIMAL"  # DECIMAL/NUMERIC(p,s)

    # Floating point
    FLOAT32 = "FLOAT32"  # REAL / FLOAT4 — 4-byte IEEE
    FLOAT64 = "FLOAT64"  # FLOAT / DOUBLE PRECISION — 8-byte IEEE

    # String
    CHAR = "CHAR"        # Fixed-length character
    VARCHAR = "VARCHAR"  # Variable-length character, bounded (n)
    TEXT = "TEXT"        # Unbounded / max character (VARCHAR(MAX) / TEXT / CLOB)

    # Boolean
    BOOLEAN = "BOOLEAN"

    # Date & Time
    DATE = "DATE"
    TIME = "TIME"                        # Time without timezone
    TIME_TZ = "TIME_TZ"                  # Time with timezone
    TIMESTAMP = "TIMESTAMP"              # Timestamp without timezone
    TIMESTAMP_TZ = "TIMESTAMP_TZ"        # Timestamp with explicit timezone
    TIMESTAMP_LTZ = "TIMESTAMP_LTZ"      # Timestamp with local/session timezone
    INTERVAL_YM = "INTERVAL_YM"          # Interval year-to-month
    INTERVAL_DS = "INTERVAL_DS"          # Interval day-to-second

    # Binary
    BINARY = "BINARY"      # Fixed-length binary
    VARBINARY = "VARBINARY" # Variable-length binary
    BLOB = "BLOB"          # Binary large object

    # Semi-structured / JSON
    JSON = "JSON"       # Native JSON (BigQuery JSON, Oracle JSON 21c+)
    VARIANT = "VARIANT" # Snowflake VARIANT / Databricks VARIANT / Redshift SUPER
    XML = "XML"         # XML type (SQL Server/Oracle)

    # Complex / nested
    ARRAY = "ARRAY"   # ARRAY<T> — Databricks/BigQuery/Snowflake
    MAP = "MAP"       # MAP<K,V> — Databricks
    STRUCT = "STRUCT" # STRUCT<...> — Databricks/BigQuery/Snowflake OBJECT

    # Identifier
    UUID = "UUID"     # uniqueidentifier / UUID

    # Spatial
    GEOGRAPHY = "GEOGRAPHY"
    GEOMETRY = "GEOMETRY"

    # Special
    UNKNOWN = "UNKNOWN"  # Unmappable — flagged with warning


class ConstraintType(str, Enum):
    PRIMARY_KEY = "primary_key"
    FOREIGN_KEY = "foreign_key"
    UNIQUE = "unique"
    CHECK = "check"
    NOT_NULL = "not_null"
    DEFAULT = "default"


class DistributionStyle(str, Enum):
    HASH = "hash"           # DISTSTYLE KEY (Redshift) / DISTRIBUTION=HASH (Synapse/Fabric)
    ROUND_ROBIN = "round_robin"  # DISTSTYLE EVEN (Redshift) / ROUND_ROBIN
    REPLICATE = "replicate"      # DISTSTYLE ALL (Redshift) / REPLICATE
    AUTO = "auto"                # DISTSTYLE AUTO (Redshift)
    NONE = "none"


class IndexType(str, Enum):
    CLUSTERED_COLUMNSTORE = "clustered_columnstore"  # Synapse/Fabric default
    HEAP = "heap"
    CLUSTERED = "clustered"
    NONCLUSTERED = "nonclustered"
    BTREE = "btree"   # Oracle / Redshift
    BITMAP = "bitmap" # Oracle


class SortKeyType(str, Enum):
    COMPOUND = "compound"  # Redshift default
    INTERLEAVED = "interleaved"  # Redshift interleaved


class GeneratedType(str, Enum):
    ALWAYS = "always"
    BY_DEFAULT = "by_default"


class RefreshType(str, Enum):
    AUTO = "auto"
    MANUAL = "manual"
    ON_COMMIT = "on_commit"
    ON_DEMAND = "on_demand"
    SCHEDULED = "scheduled"


class Warningseverity(str, Enum):
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"


# ---------------------------------------------------------------------------
# Data Type IR
# ---------------------------------------------------------------------------

class IRDataType(BaseModel):
    """Canonical representation of a SQL data type."""
    generic_type: GenericType
    precision: Optional[int] = None       # For DECIMAL(p,s), TIMESTAMP(n), etc.
    scale: Optional[int] = None           # For DECIMAL(p,s)
    length: Optional[int] = None          # For VARCHAR(n), CHAR(n), BINARY(n)
    with_timezone: bool = False           # Redundant with TIMESTAMP_TZ but kept for clarity
    element_type: Optional["IRDataType"] = None  # For ARRAY<T>
    key_type: Optional["IRDataType"] = None      # For MAP<K,V>
    value_type: Optional["IRDataType"] = None    # For MAP<K,V>
    fields: Optional[List["IRStructField"]] = None  # For STRUCT<...>
    original_type_string: Optional[str] = None  # Raw original dialect type for reference


class IRStructField(BaseModel):
    name: str
    data_type: IRDataType
    is_nullable: bool = True


# ---------------------------------------------------------------------------
# Identity / Sequence
# ---------------------------------------------------------------------------

class IRIdentity(BaseModel):
    """
    Represents auto-increment / identity column semantics.

    Redshift: IDENTITY(seed, step)  — docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html
    SQL Server/Synapse/Fabric: IDENTITY(seed, increment)
    Snowflake: AUTOINCREMENT / IDENTITY(start, increment)
    Databricks: GENERATED ALWAYS AS IDENTITY [(START WITH n INCREMENT BY n)]
    Oracle: GENERATED [ALWAYS|BY DEFAULT [ON NULL]] AS IDENTITY [START WITH n INCREMENT BY n]
    BigQuery: No native identity — flag required; suggest ROW_NUMBER() or sequence table
    """
    generated: GeneratedType = GeneratedType.ALWAYS
    start: int = 1
    increment: int = 1
    # BigQuery / Fabric workaround flag
    requires_workaround: bool = False


# ---------------------------------------------------------------------------
# Column IR
# ---------------------------------------------------------------------------

class IRColumn(BaseModel):
    name: str
    data_type: IRDataType
    is_nullable: bool = True
    default_value: Optional[str] = None      # Raw SQL expression
    identity: Optional[IRIdentity] = None    # Auto-increment / identity
    is_generated: bool = False
    generated_expression: Optional[str] = None  # e.g., "(col_a + col_b)"
    generated_type: Optional[GeneratedType] = None
    collation: Optional[str] = None
    comment: Optional[str] = None
    tags: Dict[str, str] = Field(default_factory=dict)  # BigQuery / Snowflake column tags
    encoding: Optional[str] = None  # Redshift column encoding (e.g., AZ64, ZSTD)
    masking_policy: Optional[str] = None  # Snowflake masking policy


# ---------------------------------------------------------------------------
# Constraints
# ---------------------------------------------------------------------------

class IRPrimaryKey(BaseModel):
    name: Optional[str] = None
    columns: List[str] = Field(default_factory=list)
    clustered: bool = True  # SQL Server clustered vs non-clustered PK
    not_enforced: bool = False  # Redshift/Synapse/Fabric: constraint defined but not enforced


class IRForeignKey(BaseModel):
    name: Optional[str] = None
    columns: List[str]
    ref_table: str
    ref_schema: Optional[str] = None
    ref_columns: List[str]
    on_delete: Optional[str] = None  # CASCADE, SET NULL, RESTRICT
    on_update: Optional[str] = None
    not_enforced: bool = False


class IRUniqueConstraint(BaseModel):
    name: Optional[str] = None
    columns: List[str]
    not_enforced: bool = False


class IRCheckConstraint(BaseModel):
    name: Optional[str] = None
    expression: str


# ---------------------------------------------------------------------------
# Distribution & Partitioning
# ---------------------------------------------------------------------------

class IRDistribution(BaseModel):
    """
    Redshift DISTSTYLE / Synapse+Fabric DISTRIBUTION clause.
    Redshift docs: docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html#r_CREATE_TABLE_NEW-parameters-distkey
    Synapse docs: learn.microsoft.com/azure/synapse-analytics/sql/develop-tables-distribution
    Fabric docs: learn.microsoft.com/fabric/data-warehouse/tables
    """
    style: DistributionStyle = DistributionStyle.ROUND_ROBIN
    key_columns: List[str] = Field(default_factory=list)  # For HASH distribution


class IRSortKey(BaseModel):
    """
    Redshift SORTKEY.
    Redshift docs: docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html
    """
    sort_type: SortKeyType = SortKeyType.COMPOUND
    columns: List[str] = Field(default_factory=list)


class IRPartition(BaseModel):
    """
    Partition specification — covers multiple platform patterns:
    - BigQuery: PARTITION BY DATE(col) / RANGE PARTITION
    - Databricks: PARTITIONED BY (col1, col2)
    - Snowflake: (none — uses CLUSTER BY instead)
    - Oracle: PARTITION BY RANGE/LIST/HASH
    - Synapse: PARTITION(col RANGE LEFT|RIGHT FOR VALUES(...))
    BigQuery docs: cloud.google.com/bigquery/docs/partitioned-tables
    Databricks docs: docs.databricks.com/en/sql/language-manual/sql-ref-partition.html
    """
    partition_type: str = "list"  # list, range, hash, time_unit
    strategy: Optional[str] = None  # Normalized alias: RANGE, LIST, HASH, DATE — preferred over partition_type
    columns: List[str] = Field(default_factory=list)
    time_unit: Optional[str] = None   # DAY, MONTH, YEAR, HOUR (BigQuery time partitioning)
    expiration_days: Optional[int] = None  # BigQuery partition expiration
    range_start: Optional[str] = None
    range_end: Optional[str] = None
    range_interval: Optional[str] = None
    range_values: List[str] = Field(default_factory=list)  # Synapse / Oracle explicit partition values
    partition_properties: Dict[str, str] = Field(default_factory=dict)  # Dialect-specific extras (e.g. BigQuery partition expr, range_direction)


class IRClusterBy(BaseModel):
    """
    Clustering keys — Snowflake CLUSTER BY / BigQuery CLUSTER BY / Databricks CLUSTER BY.
    Snowflake docs: docs.snowflake.com/en/user-guide/tables-clustering-keys
    BigQuery docs: cloud.google.com/bigquery/docs/clustered-tables
    """
    columns: List[str] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Index IR
# ---------------------------------------------------------------------------

class IRIndex(BaseModel):
    name: Optional[str] = None
    index_type: IndexType = IndexType.NONCLUSTERED
    columns: List[str] = Field(default_factory=list)
    include_columns: List[str] = Field(default_factory=list)  # SQL Server INCLUDE(...)
    where_clause: Optional[str] = None  # Filtered index
    unique: bool = False
    is_primary: bool = False  # Whether this is the table's primary index


# ---------------------------------------------------------------------------
# Table IR
# ---------------------------------------------------------------------------

class IRTableProperties(BaseModel):
    """Platform-specific table properties that don't fit generic fields."""
    # Snowflake
    data_retention_days: Optional[int] = None    # TIME_TRAVEL_IN_DAYS
    copy_grants: bool = False
    is_transient: bool = False
    is_iceberg: bool = False
    # Databricks
    delta_properties: Dict[str, str] = Field(default_factory=dict)
    location: Optional[str] = None   # External table location
    file_format: Optional[str] = None
    # BigQuery
    friendly_name: Optional[str] = None
    expiration_timestamp: Optional[str] = None
    require_partition_filter: bool = False
    # Redshift
    backup: bool = True
    diststyle_auto: bool = False
    # Oracle
    tablespace: Optional[str] = None
    compress: bool = False


class IRTable(BaseModel):
    """Canonical representation of a CREATE TABLE statement."""
    name: str
    schema_name: Optional[str] = None
    database_name: Optional[str] = None   # Catalog in 3-level namespace
    columns: List[IRColumn] = Field(default_factory=list)
    primary_key: Optional[IRPrimaryKey] = None
    foreign_keys: List[IRForeignKey] = Field(default_factory=list)
    unique_constraints: List[IRUniqueConstraint] = Field(default_factory=list)
    check_constraints: List[IRCheckConstraint] = Field(default_factory=list)
    distribution: Optional[IRDistribution] = None
    sort_key: Optional[IRSortKey] = None
    partition_by: Optional[IRPartition] = None
    cluster_by: Optional[IRClusterBy] = None
    indexes: List[IRIndex] = Field(default_factory=list)
    is_temporary: bool = False
    is_external: bool = False
    table_properties: IRTableProperties = Field(default_factory=IRTableProperties)
    comment: Optional[str] = None
    tags: Dict[str, str] = Field(default_factory=dict)
    # For CREATE TABLE AS SELECT
    as_select: Optional[str] = None


# ---------------------------------------------------------------------------
# View / Materialized View IR
# ---------------------------------------------------------------------------

class IRView(BaseModel):
    """Canonical representation of a CREATE [OR REPLACE] VIEW statement."""
    name: str
    schema_name: Optional[str] = None
    database_name: Optional[str] = None
    columns: List[str] = Field(default_factory=list)  # Optional column aliases
    definition: str  # The SELECT query body
    or_replace: bool = False
    is_secure: bool = False       # Snowflake SECURE VIEW
    is_recursive: bool = False    # WITH RECURSIVE
    comment: Optional[str] = None
    tags: Dict[str, str] = Field(default_factory=dict)


class IRMaterializedView(BaseModel):
    """
    Canonical representation of a CREATE MATERIALIZED VIEW statement.

    Refresh semantics differ drastically:
    - Redshift: AUTO REFRESH YES/NO + incremental
    - Snowflake: auto via cloud services (Enterprise only)
    - BigQuery: ENABLE_REFRESH=true, REFRESH_INTERVAL_MINUTES
    - Databricks: SCHEDULE / REFRESH ON; supports streaming tables too
    - Oracle: REFRESH ON COMMIT/ON DEMAND, FAST/COMPLETE/FORCE
    - Synapse/Fabric: NOT SUPPORTED — fallback to CTAS + pipeline
    SQL Server: NOT SUPPORTED as native MV

    Doc refs are on each dialect generator.
    """
    name: str
    schema_name: Optional[str] = None
    database_name: Optional[str] = None
    columns: List[str] = Field(default_factory=list)
    definition: str  # The SELECT query body
    or_replace: bool = False
    # Refresh settings
    refresh_type: RefreshType = RefreshType.MANUAL
    refresh_interval_minutes: Optional[int] = None  # BigQuery
    auto_refresh: bool = False  # Redshift / Snowflake
    refresh_schedule: Optional[str] = None  # Databricks cron-like schedule
    # Oracle-specific
    oracle_refresh_method: Optional[str] = None  # FAST, COMPLETE, FORCE
    oracle_refresh_mode: Optional[str] = None    # ON COMMIT, ON DEMAND
    # Partitioning / clustering (same fields as table)
    partition_by: Optional[IRPartition] = None
    cluster_by: Optional[IRClusterBy] = None
    comment: Optional[str] = None
    tags: Dict[str, str] = Field(default_factory=dict)
    # Distribution for Synapse/Redshift MVs
    distribution: Optional[IRDistribution] = None


# ---------------------------------------------------------------------------
# Procedure / Function IR (stub for Phase 3 — structure defined here)
# ---------------------------------------------------------------------------

class IRParameter(BaseModel):
    name: str
    data_type: IRDataType
    mode: str = "IN"  # IN, OUT, INOUT
    default_value: Optional[str] = None


class IRProcedure(BaseModel):
    """Canonical representation of a stored procedure."""
    name: str
    schema_name: Optional[str] = None
    database_name: Optional[str] = None
    parameters: List[IRParameter] = Field(default_factory=list)
    language: Optional[str] = None  # SQL, PLPGSQL, JAVASCRIPT, PYTHON, etc.
    body: str  # Procedural body (unparsed for Phase 1; parsed in Phase 3)
    or_replace: bool = False
    comment: Optional[str] = None
    # Phase 3 will replace `body` with a structured procedural IR
    # For now, raw body text is carried through with warnings
    requires_manual_review: bool = True


class IRFunction(BaseModel):
    """Canonical representation of a scalar/table-valued/UDF function."""
    name: str
    schema_name: Optional[str] = None
    database_name: Optional[str] = None
    parameters: List[IRParameter] = Field(default_factory=list)
    return_type: Optional[IRDataType] = None
    is_table_valued: bool = False
    language: Optional[str] = None
    body: str
    or_replace: bool = False
    is_deterministic: Optional[bool] = None
    comment: Optional[str] = None
    requires_manual_review: bool = True


# ---------------------------------------------------------------------------
# Sequence IR
# ---------------------------------------------------------------------------

class IRSequence(BaseModel):
    """
    Canonical representation of a sequence / auto-increment object.
    BigQuery has no native sequence — generator will flag with a workaround.
    """
    name: str
    schema_name: Optional[str] = None
    database_name: Optional[str] = None
    start: int = 1
    increment: int = 1
    min_value: Optional[int] = None
    max_value: Optional[int] = None
    cycle: bool = False
    cache: Optional[int] = None
    comment: Optional[str] = None


# ---------------------------------------------------------------------------
# Schema / Database IR
# ---------------------------------------------------------------------------

class IRSchema(BaseModel):
    name: str
    database_name: Optional[str] = None
    authorization: Optional[str] = None
    comment: Optional[str] = None


# ---------------------------------------------------------------------------
# ALTER TABLE IR
# ---------------------------------------------------------------------------

class IRAlterAction(BaseModel):
    action: str  # ADD_COLUMN, DROP_COLUMN, RENAME_COLUMN, MODIFY_COLUMN, ADD_CONSTRAINT, DROP_CONSTRAINT
    column: Optional[IRColumn] = None
    column_name: Optional[str] = None        # For DROP/RENAME
    new_column_name: Optional[str] = None    # For RENAME
    constraint: Optional[Union[IRPrimaryKey, IRForeignKey, IRUniqueConstraint, IRCheckConstraint]] = None
    constraint_name: Optional[str] = None    # For DROP CONSTRAINT


class IRAlterTable(BaseModel):
    table_name: str
    schema_name: Optional[str] = None
    database_name: Optional[str] = None
    actions: List[IRAlterAction] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Top-level DDL statement union
# ---------------------------------------------------------------------------

IRDDLObject = Union[
    IRTable,
    IRView,
    IRMaterializedView,
    IRProcedure,
    IRFunction,
    IRSequence,
    IRSchema,
    IRAlterTable,
]


# ---------------------------------------------------------------------------
# Warning / Documentation system
# ---------------------------------------------------------------------------

class IRWarning(BaseModel):
    feature: str
    message: str
    doc_url: str = ""
    severity: Warningseverity = Warningseverity.WARNING
    fallback_applied: bool = False  # True when a real documented alternative was applied
    unsupported: bool = False       # True when no documented alternative exists


class IRDocReference(BaseModel):
    title: str
    url: str
    platform: str
    purpose: str = ""  # Why this doc was consulted


# ---------------------------------------------------------------------------
# Transpilation result
# ---------------------------------------------------------------------------

class TranspileResult(BaseModel):
    converted_sql: str
    source_dialect: Dialect
    target_dialect: Dialect
    object_type: ObjectType
    warnings: List[IRWarning] = Field(default_factory=list)
    unsupported_features: List[IRWarning] = Field(default_factory=list)
    doc_references: List[IRDocReference] = Field(default_factory=list)
    ir_snapshot: Optional[Dict[str, Any]] = None  # Serialized IR for debugging

    # Confidence scoring (Phase 8)
    # HIGH (1.0) → no issues; PARTIAL (0.65-0.99) → warnings exist;
    # MANUAL_REVIEW (0.50) → unsupported features require human intervention.
    confidence_score: float = 1.0
    confidence_level: str = "HIGH"  # "HIGH" | "PARTIAL" | "MANUAL_REVIEW"

    # Named pipeline audit trail — which rule IDs fired during generation
    applied_rules: List[str] = Field(default_factory=list)

    # Residual validator findings — leftover source-dialect syntax in output
    residual_warnings: List[IRWarning] = Field(default_factory=list)

    # Latency tracking (filled by the transpiler)
    elapsed_ms: int = 0


# Update forward refs
IRDataType.model_rebuild()
IRStructField.model_rebuild()
