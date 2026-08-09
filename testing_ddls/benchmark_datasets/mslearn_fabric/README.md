## mslearn-fabric benchmark dataset

**Source:** https://github.com/MicrosoftLearning/mslearn-fabric
**License:** MIT
**Extracted:** 2026-08-07

### Files

| File | Objects | Key Constructs |
|------|---------|---------------|
| fabric_dw_tables.sql | 26 CREATE TABLE, 9 ALTER TABLE | PRIMARY KEY NONCLUSTERED NOT ENFORCED, FOREIGN KEY NOT ENFORCED, BIGINT IDENTITY, MASKED WITH, multi-schema (staging/dim/fact/gold), SCD Type 2 columns |
| fabric_dw_views.sql | 5 CREATE VIEW, 1 CREATE ROLE | Cross-warehouse 3-part naming, GRANT/role-based access |
| fabric_dw_procedures.sql | 3 CREATE PROCEDURE | CREATE OR ALTER PROCEDURE, parameterized procedures, DELETE+INSERT refresh, cross-warehouse ETL |
| fabric_dw_security.sql | 4 objects | Dynamic Data Masking, Row-Level Security (SECURITY POLICY), Column-Level Security (DENY on column), SCHEMABINDING |
| fabric_dw_queries.sql | ~30 queries | Window functions (ROW_NUMBER, SUM OVER, LAG), CTEs, SCD Type 2 updates, queryinsights DMVs, INFORMATION_SCHEMA |
| fabric_dw_dim_load.sql | 4 INSERT...SELECT | Surrogate key lookups, SCD Type 2 initial load, GETDATE() |
| fabric_lakehouse_views.sql | 3 queries | SQL analytics endpoint, dbo schema for Delta tables, medallion architecture |
| fabric_kql_queries.sql | 7 queries | T-SQL against KQL database, CASE NULL handling, streaming data |

### Fabric/Synapse-specific constructs found

- **PRIMARY KEY NONCLUSTERED ... NOT ENFORCED** - Fabric DW informational constraints
- **FOREIGN KEY ... NOT ENFORCED** - Fabric DW informational foreign keys
- **BIGINT IDENTITY** - Fabric DW surrogate key generation
- **MASKED WITH (FUNCTION = ...)** - Dynamic Data Masking
- **CREATE SECURITY POLICY ... ADD FILTER PREDICATE** - Row-Level Security
- **Cross-warehouse 3-part naming** - `[lakehouse_name].[dbo].[table]`
- **queryinsights.*** - Fabric-specific monitoring views
- **CREATE OR ALTER PROCEDURE** - Fabric DW procedure syntax
- **Multi-schema design** - staging/dim/fact/gold layered architecture
- **SQL analytics endpoint queries** - Read-only T-SQL against Lakehouse Delta tables

### Not found in this source

- DISTRIBUTION = HASH/ROUND_ROBIN/REPLICATE (Azure Synapse dedicated SQL pool only)
- COPY INTO statements
- OPENROWSET / external tables
- These constructs are specific to Azure Synapse Analytics dedicated SQL pools, not Microsoft Fabric
