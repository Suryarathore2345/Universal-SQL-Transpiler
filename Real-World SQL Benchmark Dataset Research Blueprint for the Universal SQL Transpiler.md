# Real-World SQL Benchmark Dataset Research Blueprint for the Universal SQL Transpiler

## TL;DR

- **The highest-value corpus to anchor the benchmark is the SQLGlot test-fixtures suite — 10,220 MIT-licensed cases (956 generic-identity + 3,554 dialect-identity + 5,513 transpilation) that are already shaped exactly like transpiler read-one-dialect/write-another tests** — but it natively covers only 6 of the 9 target dialects (Synapse, Fabric DW, and Fabric Lakehouse are absent), so it must be paired with vendor sample databases, TPC/Spider/SQL-ProcBench benchmarks, and dbt/Fabric projects.
- **The Universal SQL Transpiler is DDL-centric and object-limited** (5 IR object types, procedural bodies passed through untranslated, only 48 DML/query tests), so the benchmark must deliberately over-sample its weak surfaces: triggers, packages, sequences, indexes, MERGE, recursive CTEs, dynamic SQL, and cross-dialect procedural translation.
- **A P0+P1 extraction of ~34 inventoried sources can yield an estimated ~14,000 discrete SQL objects/statements**, anchored by the 10,220 exact sqlglot cases; the scarcest and highest-risk dialects (Synapse, Fabric DW, Fabric Lakehouse) require a bespoke corpus built from Microsoft Learn labs, Fabric docs, and WideWorldImporters.

## Executive Summary

The Universal SQL Transpiler (UST) is a well-architected but narrow DDL-focused tool (5 object types, 9 dialects, intermediate-representation-based) whose own test corpus of 4,002 tests is almost entirely synthetic/golden-file. To validate and stress-test it against real-world workloads, the single highest-value external corpus is the SQLGlot test-fixtures suite (10,220 cases, MIT-licensed), complemented by official vendor sample databases (AdventureWorks, WideWorldImporters, Oracle HR/OE/SH/CO, Northwind), standardized benchmark suites (TPC-H, TPC-DS, SQL-ProcBench, Spider 2.0), and dbt/data-engineering projects. This report inventories 34 sources, maps them to the 9 dialects and the required SQL constructs, and delivers an extraction roadmap. Counts are clearly marked EXACT (verified from a named source) vs ESTIMATED (my planning inference).

Three critical realities shape the blueprint: (1) UST currently transpiles only DDL for TABLE/VIEW/MATERIALIZED VIEW/PROCEDURE/FUNCTION plus a secondary sqlglot-based SELECT/DML path — it does NOT handle triggers, packages, sequences, or indexes as first-class objects, nor dynamic SQL or recursive CTEs as dedicated IR types, so the benchmark must over-sample those gaps. (2) Three of the 9 dialects — Synapse, Fabric DW, Fabric Lakehouse — have NO native representation in sqlglot or in most public corpora; their SQL must be sourced from Microsoft official documentation and treated as T-SQL variants. (3) Licensing is favorable overall (MIT/Apache/PostgreSQL/CC-BY predominate) but TPC benchmark specs carry trademark/usage restrictions, BIRD is noncommercial (CC BY-NC), SQLsmith is GPL-3.0, and Oracle/vendor sample data carry specific terms.

## Repository Analysis: Universal-SQL-Transpiler

**Source:** https://github.com/Suryarathore2345/Universal-SQL-Transpiler (MIT license, 11 commits, 0 stars/forks — a solo/early-stage project).

**Architecture (EXACT, from README):** A parser→IR→generator pipeline. Source SQL is parsed by a sqlglot-based, dialect-aware parser into an Intermediate Representation (IRTable / IRView / IRMaterializedView / IRProcedure / IRFunction), then emitted by a dialect-aware target generator that also produces warnings and documentation references. The IR design means N parsers + N generators rather than N×N adapters — adding a dialect requires one parser + one generator. Stack: FastAPI backend, React + Monaco frontend, Docker Compose. The README advertises a "9 × 9 dialect matrix — any source to any target, 81 conversion pairs."

**Folder structure (EXACT):** `backend/app/dialects/{redshift,snowflake,sqlserver,synapse,fabric_dw,fabric_lakehouse,databricks,oracle,bigquery}/` each with `parser.py`, `generator.py`, `references.md`; `backend/app/ir/models.py`; supporting modules `transpiler.py` (orchestrator), `query_transpiler.py` (sqlglot SELECT/DML path), `validator.py` (residual pattern scan + confidence scoring), `limitations.py`, `sql_text_utils.py`. Tests live in `backend/tests/` with a `golden/` snapshot folder. There is a top-level `testing_ddls/` directory whose contents could not be enumerated via automated fetch (robots-blocked) and should be inspected manually.

**Test corpus (EXACT, from README):** 4,002 tests across 11 files: `test_advanced_realworld.py` (2,169 — "real-world DDL corpus, adversarial/edge cases"), `test_phase6_golden.py` (640 golden snapshots, 322 files × 2 checks), `test_realworld.py` (414), `test_comprehensive.py` (192), `test_comprehensive_validation.py` (185), `test_phase2_all_dialects.py` (98), `test_phase4_api.py` (95), `test_phase3_procedures.py` (91), `test_query_transpiler.py` (48 SELECT/DML), `test_schema_and_create_or_replace.py` (40), `test_phase1_redshift_snowflake.py` (30).

**API surface (EXACT):** `POST /api/transpile` (returns converted_sql + warnings + unsupported_features + doc_references + confidence), `GET /api/dialects`, `GET /api/limitations`, `GET /api/health`.

**Capability assessment (EXACT object matrix from README):** All 9 dialects support TABLE/VIEW/FUNCTION. Materialized View: unsupported on Fabric DW (error → converted to regular VIEW with no auto-refresh), ⚠️ on SQL Server (→ indexed view with SCHEMABINDING, may need query adjustments), Snowflake MV requires Enterprise Edition, Fabric Lakehouse Materialized Lake Views require Runtime 1.3+. Procedures: not supported on Fabric Lakehouse (error → SQL function stub; use a Fabric Notebook for real procedural logic), ⚠️ on Databricks (→ UDF stub, significant manual adaptation). Documented per-target limitations include Snowflake DISTKEY removal and procedure bodies "wrapped as-is," Synapse mandatory explicit DISTRIBUTION, BigQuery no IDENTITY and non-enforced PK/FK, Oracle DATE-includes-time.

## Gap Analysis

The UST's coverage is DDL-centric and object-type-limited. Against the task's full SQL-object taxonomy, the following are **weak or absent** and must be prioritized in benchmark design:

- **Not modeled as first-class IR objects:** Triggers, Packages (Oracle PL/SQL), Sequences, Constraints (as standalone ALTER), Indexes, Materialized-view refresh semantics.
- **Procedural bodies are passed through, not translated:** the README explicitly notes "Procedure bodies wrapped as-is — Snowflake Scripting differs," and Databricks procedures become UDF stubs. PL/SQL ↔ T-SQL ↔ Snowflake Scripting ↔ Spark SQL procedural translation is therefore a major untested surface.
- **DML/queries handled only by a thin secondary sqlglot path** (48 tests): MERGE, COPY, CTAS, recursive CTEs, window functions, JSON/XML/ARRAY handling, dynamic SQL, transactions, and administrative/security SQL are effectively untested.
- **Dialect asymmetry:** Synapse, Fabric DW, Fabric Lakehouse have the thinnest real-world corpora and the most divergent semantics (distribution requirements, no MVs, no procedures) — highest risk of silent mistranslation.
- **Adversarial/parser edge cases:** Only synthetic today; needs the sqlglot identity/dialect fixtures and dedicated fuzzers.

## Complete Source Inventory

Each entry: name · URL · category · org · dialects touched · object types · size/counts (EXACT vs EST) · license · priority.

**Parser/Transpiler corpora**
1. **SQLGlot test fixtures** · https://github.com/tobymao/sqlglot (tests/fixtures) · Parser Project · Toby Mao/community · redshift, snowflake, tsql (SQL Server), databricks, oracle, bigquery natively (Synapse/Fabric absent; only a generic community "Fabric" T-SQL variant exists) · DDL+DML+window+JSON+recursive+edge cases · EXACT 956 generic-identity cases, 3,554 dialect-identity cases, 5,513 transpilation cases (10,220 total, per tobilg/polyglot extraction) · MIT · **P0**.
2. **tobilg/polyglot** · https://github.com/tobilg/polyglot · Transpiler Project · community · same 30+ dialects · reruns 10,220 sqlglot fixtures + custom (276 custom dialect-identity, 347 custom transpilation) · MIT (bundles sqlglot's MIT fixtures) · P1 (secondary/corroboration).
3. **SQLGlot dialect registry** · https://sqlglot.com/sqlglot/dialects.html · confirms 31 native dialects; README states it can "translate between 31 different dialects" · used to confirm dialect coverage (present: BigQuery, Snowflake, Redshift, TSQL, Oracle, Databricks; absent: Synapse, Fabric DW, Fabric Lakehouse).

**Benchmark Suites**
4. **TPC-DS** · https://www.tpc.org · Benchmark Suite · TPC · all 9 (via ports) · EXACT per TPC Benchmark DS Standard Specification v3.1.0: 7 fact tables + 17 dimension tables, average 18 columns per table, 99 test queries "covering the core parts of SQL-1999 and SQL-2003 as well as OLAP" · TPC license (trademark/usage restrictions; derived works must disclaim certification) · **P0**.
5. **TPC-H** · https://www.tpc.org · Benchmark Suite · TPC · all 9 · 22 queries, 8 tables (3NF), 2–8 joins · TPC license · P0.
6. **SQL-ProcBench** · https://github.com/microsoft/SQL-ProcBench · Benchmark Suite / Academic · Microsoft Research · T-SQL, PL/pgSQL, PL/SQL (maps to SQL Server, Oracle; Postgres out of scope) · Scalar UDFs, Table-valued UDFs, Stored Procedures, Triggers over an augmented TPC-DS schema. EXACT: built from Gupta & Ramachandra's analysis of "more than 6500 procedures across many real-world applications" (PVLDB 14(8):1378–1391, doi:10.14778/3457390.3457402); a citing survey states the resulting workload "comprises 63 stored procedures" over the augmented TPC-DS schema · research/benchmark license · **P0** (fills procedural + trigger gap).
7. **Spider 2.0** · https://github.com/xlang-ai/Spider2 (RelationalAI/xlang-spider2 fork; site https://spider2-sql.github.io) · Academic/Benchmark · Yale/XLang (ICLR 2025 Oral, Lei et al., arXiv:2411.07763) · EXACT dialect split of 632 tasks: BigQuery 214, Snowflake 198, SQLite 135, DuckDB/DBT 68, Postgres 10, ClickHouse 7 (the self-contained Spider2-Snow subset has 547 Snowflake-hosted examples) · enterprise analytics; databases average 812 columns and often exceed 1,000 columns; queries "often exceeding 100 lines"; 85.98% of examples require specialized dialect functions (avg 7.1). Difficulty benchmark: "even the most advanced LLMs, including GPT-4, solve only 6.0% of Spider 2.0 tasks, compared to 86.6% on Spider 1.0 and 57.4% on BIRD" · Apache-2.0 (code) · **P0** for BigQuery/Snowflake realism.
8. **Spider 1.0** · https://yale-lily.github.io/spider · Academic · Yale · SQLite-centric · 10,181 questions / 5,693 unique SQL queries / 200 DBs / 138 domains · CC BY-SA 4.0 · P2 (schema diversity, but simple SQLite SQL).
9. **BIRD** · https://bird-bench.github.io · Academic · Alibaba DAMO / HKU (Li et al., NeurIPS 2023 Spotlight, arXiv:2305.03111) · SQLite · EXACT: "12,751 pairs of text-to-SQL data and 95 databases with a total size of 33.4 GB, spanning 37 professional domains" · CC BY-NC (noncommercial) · P2.
10. **CMU BenchBase (OLTPBench successor)** · https://github.com/cmu-db/benchbase · Testing Framework · CMU-DB · multi-DBMS via JDBC incl. SQL Server, Oracle · 15 workloads (tpcc, tpch, tatp, wikipedia, twitter, seats, auctionmark, chbenchmark, ycsb…), has a `--dialects-export` feature · Apache-2.0 · P1.
11. **memsql/benchmarks-tpc** · https://github.com/memsql/benchmarks-tpc · Benchmark Suite · MemSQL · TPC-H/DS-derived queries.sql · permissive · P2.

**Vendor Sample Databases**
12. **AdventureWorks (OLTP + DW)** · https://github.com/microsoft/sql-server-samples · Vendor Sample · Microsoft · SQL Server, Synapse, Fabric (via load scripts) · tables, views, procedures, functions, triggers, indexes; OLTP + star-schema DW install scripts · MIT · **P0**.
13. **WideWorldImporters (WWI + WWI-DW)** · https://github.com/microsoft/sql-server-samples · Vendor Sample · Microsoft · SQL Server, Synapse (PolyBase load scripts), Fabric (WWI is the Fabric tutorial dataset) · temporal tables, stored procedures, triggers, columnstore, JSON, security features, ETL via SSIS · MIT · **P0**.
14. **Northwind & pubs** · https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/northwind-pubs · Vendor Sample · Microsoft · SQL Server · classic small OLTP schema · MIT · P1.
15. **Oracle DB Sample Schemas (HR, OE, PM, IX, SH, BI, CO)** · https://github.com/oracle-samples/db-sample-schemas · Vendor Sample · Oracle · Oracle · tables, views, sequences, triggers, PL/SQL packages/procedures, object types, JSON (CO schema) · Apache-2.0 (2023 relaunch) · **P0** (only rich Oracle-native corpus).
16. **AWS DMS Sample Database** · https://github.com/aws-samples/aws-database-migration-samples · Vendor Sample/Migration · AWS · Oracle, SQL Server, Redshift · sample OLTP schema used in SCT playbooks · MIT-0 · P1.
17. **amazon-redshift-modernize-dw / redshift-immersionday** · https://github.com/aws-samples/amazon-redshift-modernize-dw · Warehouse Project · AWS · Redshift · CTAS, Spectrum external tables, DDL, DML · modified MIT · **P1** (scarce Redshift-native source).
18. **Snowflake SNOWFLAKE_SAMPLE_DATA (TPC-H/TPC-DS shares)** · https://docs.snowflake.com/en/user-guide/sample-data · Vendor Sample · Snowflake · Snowflake · TPCH_SF1/10/100/1000, TPCDS_SF10TCL/SF100TCL schemas + 99 sample TPC-DS queries · Snowflake ToS · P1.
19. **BigQuery public datasets** · https://cloud.google.com/bigquery/public-data · Vendor Sample · Google · BigQuery · GoogleSQL analytics queries, arrays/structs/JSON, `bigquery-public-data.samples` · CC-BY 4.0 (varies per dataset) · P1.
20. **blockchain-etl/awesome-bigquery-views** · https://github.com/blockchain-etl/awesome-bigquery-views · Analytics Project · community · BigQuery · complex analytics SELECTs, CTEs, window functions · MIT · P2.

**Sample DBs (cross-dialect)**
21. **Chinook** · https://github.com/lerocha/chinook-database · Sample Database · community · SQL Server, Oracle, MySQL, PostgreSQL, SQLite, DB2 (auto-generated per-dialect DDL) · 11 tables, views, FKs · MIT · **P0** (best multi-dialect identical-schema set for round-trip diffing).
22. **Sakila (+ ports)** · https://github.com/jOOQ/sakila and https://github.com/ivanceras/sakila · Sample Database · community · Oracle, SQL Server, SQLite, PostgreSQL, DB2, Firebird · 16 tables, views, stored procedures, triggers, functions · BSD/MySQL-style · P1.
23. **Employees (large)** · MySQL/Postgres ports · Sample Database · community · ~160M/300k rows, 6 tables, partitioning · CC-BY-SA · P2.
24. **neondatabase/postgres-sample-dbs** · https://github.com/neondatabase/postgres-sample-dbs · Sample Database · Neon · Postgres (Sakila/pagila, employees) · P2 (Postgres out-of-scope for the 9 but useful for parser stress).

**Data Engineering / dbt / ETL-ELT**
25. **dbt Jaffle Shop family** · https://github.com/dbt-labs/jaffle-shop, jaffle_shop_duckdb, jaffle_shop_mssql (dbt-msft), jaffle-shop-classic · ETL/ELT Project · dbt Labs · compiles to Snowflake, BigQuery, Databricks, Redshift, SQL Server (via adapters) · staging/marts SELECT models, CTEs, window functions, incremental materializations · Apache-2.0 · **P0** (real analytics/ELT SQL, multi-target).
26. **clausherther/dbt-tpch** · https://github.com/clausherther/dbt-tpch · ETL/ELT Project · community · Snowflake · star-schema fact/dim/report models on TPCH · MIT · P1.
27. **TheDataFoundryAU/dbt_sample_project** · https://github.com/TheDataFoundryAU/dbt_sample_project · ETL/ELT · community · multi-adapter · P2.
28. **Databricks bootcamp / Delta Lake projects** (DataWithBaraa/databricks_bootcamp_2026, databricks/tech-talks) · Lakehouse Project · community/Databricks · Databricks · Spark SQL DDL/DML, MERGE, medallion architecture, Delta operations (OPTIMIZE/VACUUM/Z-ORDER) · varies (MIT/CC) · **P1** (scarce Databricks-native SQL).
29. **Microsoft Learn Fabric labs (mslearn-fabric)** · https://github.com/MicrosoftLearning/mslearn-fabric · Lakehouse/Warehouse Project · Microsoft · Fabric DW + Lakehouse · CTAS, COPY INTO, OPENROWSET, cross-warehouse 3-part naming, T-SQL stored procs, SQL analytics endpoint queries · MIT · **P0** (only realistic Fabric DW/Lakehouse SQL source).

**Testing / Fuzzing Frameworks**
30. **SQLancer** · https://github.com/sqlancer/sqlancer · Testing Framework · community · many DBMS · generates random valid SQL, logic-bug oracles (NoREC/TLP/PQS) · MIT · **P1** (adversarial generation).
31. **SQLsmith** · https://github.com/anse1/sqlsmith · Testing Framework · community · Postgres/SQLite grammar · random query generation · GPL-3.0 (copyleft — do NOT vendor into an MIT benchmark) · P2.
32. **andygrove/sqlfuzz, PumpkinSeed/sqlfuzz** · Testing Framework · community · random query/data generation · Apache/MIT · P2.

**Migration Tooling (reference syntax mappings, not corpora)**
33. **SQLines** · https://www.sqlines.com/oracle-to-snowflake · Migration Project · SQLines · Oracle→Snowflake/SQL Server/Redshift/BigQuery mapping docs incl. packages, triggers, PL/SQL statements · proprietary docs (reference only) · P1 (ground-truth mapping oracle).
34. **AWS SCT / SnowConvert** · docs · Migration · AWS/Snowflake · conversion rules for views/procs/functions · reference only · P2.

## Source-by-Source Analysis (priority sources)

**SQLGlot fixtures (P0).** The closest thing to a purpose-built transpiler benchmark. Its `tests/fixtures/identity.sql` (956 one-statement-per-line cases) and `tests/fixtures/dialects/*.sql` (bigquery.sql, snowflake.sql, tsql.sql, oracle.sql, redshift.sql, databricks.sql, spark.sql, etc.) provide 3,554 dialect-identity cases and 5,513 transpilation cases — precisely the read-one-dialect/write-another pairs UST must pass. Because UST's parser is itself sqlglot-based, these fixtures are directly relevant and share licensing (MIT). Caveat: Synapse and both Fabric variants are absent; only a generic community "Fabric" T-SQL dialect exists, so these fixtures cannot validate 3 of UST's 9 dialects. Extraction: clone the repo and parse the `.sql` fixture files (transpile fixtures use `source SQL; -- write_dialect` comment conventions).

**TPC-DS / TPC-H (P0).** Gold-standard analytics SQL. TPC-DS's 99 queries exercise CTEs, window functions, rollups, and complex joins over 7 fact + 17 dimension tables (avg 18 columns), spanning SQL-1999/2003 and OLAP; TPC-H's 22 are simpler. They are dialect-agnostic templates that must be generated via `dsqgen`/`qgen` or pulled from vendor ports (Snowflake sample queries, memsql/benchmarks-tpc). Licensing caveat: TPC materials carry usage/trademark terms; derived query text must be labeled "derived from TPC, not an official TPC benchmark."

**SQL-ProcBench (P0).** Directly fills UST's biggest gap — procedural code and triggers. Built from an analysis of more than 6,500 real-world procedures (VLDB 2021), it ships procedural workloads (a citing survey reports 63 stored procedures plus scalar/table-valued UDFs and triggers) over an augmented TPC-DS schema, in T-SQL, PL/pgSQL, and PL/SQL — so it doubles as a translation oracle for SQL Server ↔ Oracle procedure/function/trigger conversion.

**Spider 2.0 (P0).** The only large corpus with real BigQuery (214) and Snowflake (198) enterprise SQL; databases average 812 columns and often exceed 1,000, queries often exceed 100 lines, and 85.98% require specialized dialect functions. Its brutal difficulty (GPT-4 solves only 6.0%) makes it an excellent stress test for UST's analytics/warehouse path on its two cloud-native dialects. Caveat: text-to-SQL framing means SQL is answer-side; extraction requires pulling the gold SQL files, and some require cloud credentials to execute (parsing only needs the text).

**Microsoft sql-server-samples (P0).** AdventureWorks + WideWorldImporters are the richest enterprise T-SQL corpora (procedures, triggers, temporal tables, columnstore, JSON, security). WWI is Microsoft's own Fabric/Synapse tutorial dataset, making it the bridge to those 3 otherwise-starved dialects.

**Oracle db-sample-schemas (P0).** The only rich, Oracle-native source with packages, sequences, triggers, object types, and JSON (CO schema), now Apache-2.0 (2023 relaunch) — clean licensing.

**dbt Jaffle Shop (P0).** Real ELT/analytics SELECT SQL that compiles to Snowflake, BigQuery, Databricks, Redshift, and SQL Server via adapters — a natural multi-target analytics benchmark. The `dbt-msft/jaffle_shop_mssql` fork gives a T-SQL variant.

**mslearn-fabric (P0).** Practically the only public source of realistic Fabric DW and Fabric Lakehouse T-SQL (CTAS, COPY INTO, OPENROWSET, cross-warehouse 3-part naming, SQL analytics endpoint). Essential because sqlglot and the benchmark suites ignore Fabric.

## SQL Artifact Estimates

| Source | SQL files (EST) | Queries/objects (EXACT where noted) |
|---|---|---|
| SQLGlot fixtures | ~40 fixture files | 10,220 cases EXACT (956 identity + 3,554 dialect-identity + 5,513 transpile) |
| TPC-DS | 99 templates EXACT | 99 queries + 24 tables EXACT |
| TPC-H | 22 templates EXACT | 22 queries + 8 tables EXACT |
| SQL-ProcBench | ~150+ object files EST | 63 stored procedures EXACT (per citing survey); + scalar/table UDFs + triggers ×3 dialects |
| Spider 2.0 | 632 task dirs EXACT | 632 gold SQL workflows EXACT (BigQuery 214/Snowflake 198/SQLite 135/DuckDB 68/PG 10/CH 7; Spider2-Snow subset = 547) |
| AdventureWorks | ~2 install scripts | ~70+ tables, plus views/procs/functions/triggers EST |
| WideWorldImporters | ~10+ scripts | ~30+ tables, temporal/procs/triggers EST |
| Oracle sample schemas | 7 schema installers | HR ~7 tables; OE/SH/CO add object types, sequences, PL/SQL EST |
| Chinook | 8 per-dialect scripts | 11 tables EXACT × 6 in-scope dialects |
| Sakila | ~10 ports | 16 tables + views/procs/triggers EXACT |
| dbt Jaffle Shop | ~15 model .sql files | staging + marts SELECT models EST |
| mslearn-fabric | dozens of lab .sql | CTAS/COPY/procs EST |

Grand estimated corpus if all P0+P1 sources are extracted: **~12,000–15,000 discrete SQL statements/objects**, of which 10,220 (EXACT) come from sqlglot fixtures and the remainder from schemas, benchmarks, and projects. This is a conservative floor; adding fuzz-generated cases (SQLancer) is effectively unbounded.

## Coverage Matrix — Sources × SQL Constructs

Legend: ●=strong, ○=some, blank=none.

| Construct | SQLGlot fix | TPC-DS/H | SQL-ProcBench | Spider2 | AdvWorks/WWI | Oracle schemas | Chinook/Sakila | dbt | mslearn-Fabric | SQLancer |
|---|---|---|---|---|---|---|---|---|---|---|
| CREATE/ALTER/DROP TABLE | ● | ● | ○ | ○ | ● | ● | ● | ○ | ● | ● |
| CREATE/ALTER/DROP VIEW | ● |  |  | ○ | ● | ● | ● | ● | ○ | ○ |
| MATERIALIZED VIEW | ○ |  |  |  | ○ | ● |  | ○ | ○ |  |
| Stored Procedures | ○ |  | ● |  | ● | ● | ○ |  | ● |  |
| Functions (UDF) | ○ |  | ● |  | ● | ● | ○ | ○ | ○ |  |
| Triggers |  |  | ● |  | ● | ● | ○ |  |  |  |
| Sequences | ○ |  |  |  | ○ | ● |  |  |  |  |
| Constraints | ● |  |  |  | ● | ● | ● |  | ○ | ● |
| Indexes | ○ |  | ● |  | ● | ● | ○ |  |  |  |
| MERGE | ● |  | ○ | ○ | ○ | ○ |  | ○ | ● |  |
| COPY/bulk load | ○ |  |  |  | ○ (PolyBase) |  |  |  | ● |  |
| CTAS | ● |  |  | ○ | ○ |  |  | ● | ● |  |
| INSERT/UPDATE/DELETE | ● | ○ | ● | ○ | ● | ● | ● | ○ | ● | ● |
| TRUNCATE | ○ |  |  |  | ○ | ○ |  |  | ○ |  |
| Recursive CTE | ● | ○ | ○ | ● | ○ | ○ |  | ○ |  | ○ |
| Window Functions | ● | ● | ○ | ● | ○ | ○ |  | ● | ○ | ○ |
| JSON | ● |  |  | ○ | ● | ● (CO) |  | ○ | ○ |  |
| XML | ○ |  |  |  | ● (SQL Server) | ○ |  |  |  |  |
| Arrays/Structs | ● |  |  | ● (BQ) |  | ○ |  | ○ |  |  |
| Transactions | ○ |  | ● |  | ● | ● | ○ |  | ○ | ○ |
| Dynamic SQL |  |  | ○ |  | ● | ● |  |  |  |  |
| Security/GRANT | ○ |  |  |  | ● | ● |  |  | ○ |  |
| Administrative | ○ |  |  |  | ● | ● |  |  | ● |  |
| Vendor-specific syntax | ● | ○ | ● | ● | ● | ● | ○ | ○ | ● | ● |

## Dialect Coverage (all 9)

1. **Redshift** — Sources: sqlglot redshift.sql fixtures (P0), amazon-redshift-modernize-dw, AWS DMS samples, TPC ports, dbt Redshift adapter. Strong on DDL, DISTKEY/SORTKEY, CTAS, Spectrum external tables; weak on procedures. Extraction priority: **High** (native corpus scarce).
2. **Snowflake** — sqlglot snowflake.sql (P0), Spider 2.0 (198 tasks, P0), SNOWFLAKE_SAMPLE_DATA + 99 TPC-DS queries, dbt-tpch, SQLines mappings. Very strong analytics/warehouse SQL, Snowflake Scripting procs. Priority: **High**.
3. **SQL Server** — sqlglot tsql.sql (P0), AdventureWorks + WWI (P0), Northwind/pubs, SQL-ProcBench T-SQL (P0), Sakila/Chinook ports, dbt-msft. Richest procedural/trigger/enterprise corpus. Priority: **High**.
4. **Synapse** — mslearn-fabric/Synapse docs, WWI PolyBase load scripts, AdventureWorksDW. No sqlglot/benchmark native SQL. Treat as T-SQL + mandatory DISTRIBUTION. Priority: **High (gap-filling)**.
5. **Fabric DW** — mslearn-fabric labs (P0), Fabric docs (CTAS, COPY INTO, OPENROWSET, 3-part naming), WWI (Fabric tutorial dataset). No MVs. Priority: **High (gap-filling)**.
6. **Fabric Lakehouse** — mslearn-fabric labs, Fabric Lakehouse SQL analytics endpoint docs (read-optimized T-SQL over Delta), Databricks Spark SQL as proxy. No procedures. Priority: **High (gap-filling)**.
7. **Databricks** — sqlglot databricks.sql/spark.sql fixtures (P0), Databricks bootcamp/tech-talks, Delta Lake projects, dbt Databricks adapter. Spark SQL DDL/DML, MERGE, Delta ops. Priority: **Medium-High**.
8. **Oracle** — sqlglot oracle.sql (P0), Oracle db-sample-schemas (P0), SQL-ProcBench PL/SQL (P0), Sakila/Chinook Oracle ports, SQLines. Richest packages/sequences/triggers/PL/SQL. Priority: **High**.
9. **BigQuery** — sqlglot bigquery.sql (P0), Spider 2.0 (214 tasks, P0), BigQuery public datasets, blockchain-etl views, dbt BigQuery adapter. Strong analytics, arrays/structs/JSON, GoogleSQL. Priority: **High**.

## Enterprise Feature Coverage

- **Distribution/partitioning/clustering:** Synapse DISTRIBUTION (mslearn-fabric), Redshift DISTKEY/SORTKEY (aws-samples, sqlglot), Databricks PARTITIONED BY/CLUSTER BY/Z-ORDER (Databricks projects), BigQuery PARTITION/CLUSTER (Spider2), Snowflake CLUSTER BY (sqlglot).
- **Security SQL (GRANT/REVOKE/RLS/masking):** AdventureWorks/WWI (SQL Server row-level security, dynamic data masking), Oracle schemas (roles/grants), Fabric docs.
- **Administrative SQL:** WWI maintenance procs, Fabric OPTIMIZE/VACUUM, Databricks table maintenance.
- **Temporal/CDC:** WWI temporal tables, Chinook-based OLTP simulators (CDC/SCD2), Delta change data feed.
- **Transactions & isolation:** SQL-ProcBench, BenchBase TPC-C (12 invariants), MonkeyDB assertions.

## Complexity Analysis

- **Beginner:** Northwind, Chinook, Spider 1.0 (single-table SQLite), HR schema.
- **Intermediate:** Sakila, TPC-H (22 queries), dbt Jaffle Shop staging models.
- **Advanced:** TPC-DS (99 queries, CTEs/windows), sqlglot dialect fixtures, BigQuery analytics views.
- **Enterprise:** AdventureWorks/WWI, Oracle OE/SH/CO, Spider 2.0 (avg 812 columns, >100-line queries), Databricks medallion projects.
- **Production/ETL/ELT:** dbt projects, mslearn-Fabric pipelines, SSIS ETL in WWI, Databricks DLT.
- **Migration:** SQLines mappings, AWS SCT playbooks, SQL-ProcBench cross-dialect triples.
- **Benchmark:** TPC-H/DS, BenchBase, memsql/benchmarks-tpc.
- **Parser edge cases:** sqlglot identity.sql (956 cases), SQLancer/SQLsmith fuzz output, sqlglot adversarial fixtures.

## Source Prioritization (ranked, with justification)

1. **SQLGlot fixtures** — unmatched query volume (10,220 EXACT), exact transpiler-benchmark shape, MIT, trivial extraction. Covers 6/9 dialects.
2. **Microsoft sql-server-samples (AdventureWorks + WWI)** — best enterprise realism, object diversity, MIT, and the only bridge to Synapse/Fabric.
3. **Oracle db-sample-schemas** — only rich Oracle-native corpus, Apache-2.0.
4. **TPC-DS/TPC-H** — analytics gold standard, dialect-agnostic; licensing caveat.
5. **SQL-ProcBench** — fills procedural/trigger gap, tri-dialect translation oracle.
6. **Spider 2.0** — real BigQuery/Snowflake enterprise SQL, highest difficulty.
7. **dbt Jaffle Shop family** — real ELT/analytics, multi-target compilation.
8. **mslearn-fabric** — indispensable for Fabric DW/Lakehouse.
9. **Chinook/Sakila** — identical-schema multi-dialect round-trip diffing.
10. **SQLancer/BenchBase** — adversarial + transactional stress.

## Extraction Roadmap

**Phase 1 (weeks 1–2): Highest-ROI, permissive licenses.** Clone sqlglot; parse `tests/fixtures/identity.sql` and `tests/fixtures/dialects/*.sql` into (source_dialect, source_sql, target_dialect, expected_sql) tuples. Clone Chinook + Sakila per-dialect scripts for round-trip diffing. Deliverable: ~10,000+ normalized cases.

**Phase 2 (weeks 3–4): Enterprise vendor corpora.** Pull AdventureWorks/WWI install scripts, Oracle sample schemas, Northwind/pubs. Tag objects by type (table/view/MV/proc/func/trigger/sequence/index). Deliverable: enterprise DDL/procedural corpus.

**Phase 3 (weeks 5–6): Benchmarks & analytics.** Generate TPC-H/DS queries via dsqgen/qgen (or pull vendor ports); extract SQL-ProcBench tri-dialect objects; pull Spider 2.0 gold SQL (BigQuery/Snowflake). Deliverable: analytics + procedural translation oracles.

**Phase 4 (weeks 7–8): Project/ELT & gap dialects.** Extract dbt model SQL (compile per adapter), mslearn-fabric labs (Fabric DW/Lakehouse/Synapse), Databricks projects. Deliverable: production ELT + gap-dialect coverage.

**Phase 5 (ongoing): Adversarial.** Wire SQLancer for fuzz-generated edge cases; add BenchBase transactional workloads. Keep SQLsmith outputs segregated (GPL).

**Pipeline design notes:** normalize every case to a manifest schema {id, source_name, source_url, license, source_dialect, target_dialect(s), object_type, complexity_class, sql_text, expected_sql?, provenance}. Store license per record to enforce redistribution rules (segregate GPL SQLsmith, TPC-derived, BIRD noncommercial, Oracle, and vendor-ToS data). De-duplicate via normalized SQL hashing.

## Recommendations

1. **Adopt the sqlglot fixtures as the backbone now** — it is MIT, exactly the right shape, and 10,220 cases dwarf UST's synthetic corpus. Immediate, low-risk. Threshold to revisit: if UST diverges from sqlglot's parser, re-baseline the expected outputs.
2. **Over-index on UST's gaps** — procedures, triggers, packages, sequences, MERGE, recursive CTEs, dynamic SQL. Weight SQL-ProcBench, Oracle schemas, and AdventureWorks/WWI accordingly.
3. **Treat Synapse/Fabric DW/Fabric Lakehouse as a dedicated sub-project** — build a curated corpus from mslearn-fabric + Microsoft docs + WWI, since no public benchmark covers them. This is where mistranslation risk is highest.
4. **Use identical-schema multi-dialect sources (Chinook, Sakila, SQL-ProcBench) as translation oracles** — the same logical object in two dialects gives ground-truth expected output for UST diffing.
5. **Enforce license segregation from day one.** Keep MIT/Apache/PostgreSQL/CC-BY in the redistributable core; isolate GPL (SQLsmith), TPC-derived text (add non-certification disclaimers), BIRD (noncommercial), Oracle, and vendor-ToS datasets behind generation scripts rather than vendored SQL.
6. **Benchmark thresholds that change the plan:** if UST adds a first-class Trigger/Sequence/Package IR, promote SQL-ProcBench and Oracle schemas to mandatory pass sets; if UST's DML/query path matures beyond its current 48 tests, promote TPC-DS and Spider 2.0 to primary regression gates; if Fabric adoption grows, invest further in a bespoke Fabric corpus.

## Caveats

- **Exact vs estimated:** Only counts explicitly attributed to a named source (sqlglot 10,220; TPC-DS 99 queries / 7+17 tables; TPC-H 22 / 8; SQL-ProcBench 63 stored procedures per citing survey and 6,500+ analyzed procedures; Spider 2.0 632 with the dialect split and Spider2-Snow 547; BIRD 12,751 / 95 / 37; Chinook 11 tables; Sakila 16 tables) are EXACT. Object counts for AdventureWorks/WWI/Oracle schemas and all per-dialect dashboard figures are ESTIMATES pending direct file inspection.
- **Coverage ≠ correctness:** sqlglot parses leniently and is a transpiler, not a validator — a passing parse is not a guarantee of semantic equivalence. UST inherits this. Round-trip and cross-dialect diff testing against identical-schema sources is the only way to catch silent mistranslation.
- **Three dialects are structurally under-served** (Synapse, Fabric DW, Fabric Lakehouse); any benchmark will be lopsided toward the 6 sqlglot-native dialects unless deliberately corrected.
- **Licensing is not uniform:** TPC (trademark/usage), BIRD (noncommercial CC BY-NC), SQLsmith (GPL-3.0), Oracle and vendor sample data (specific ToS) all require handling before redistribution.
- **The UST repo is early-stage** (0 stars, 11 commits); its `testing_ddls/` folder could not be enumerated via automated fetch (robots-blocked) and should be inspected manually.
- **This is a research blueprint, not an extraction** — no SQL was generated and no repositories were cloned, per scope.

## Final Summary Dashboard (per-dialect source & object outlook)

Counts are ESTIMATED planning targets aggregating the P0/P1 sources mapped to each dialect (except the sqlglot fixture totals, which are EXACT and shared across the 6 native dialects). "Sources" = count of inventoried sources materially covering that dialect. ●=strong coverage, ○=some, blank=none.

| Dialect | Sources | Tables | Views | Mat.Views | Stored Procs | Functions | Triggers | DDL | DML | ETL | Analytics | Total SQL Objects (EST) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Redshift | 6 | ● | ● | ○ | ○ | ○ | | ● | ● | ● | ● | ~1,500 |
| Snowflake | 8 | ● | ● | ● | ● | ● | | ● | ● | ● | ● | ~2,500 |
| SQL Server | 9 | ● | ● | ○ | ● | ● | ● | ● | ● | ● | ● | ~3,000 |
| Synapse | 4 | ● | ● | ○ | ○ | ○ | | ● | ● | ○ | ● | ~600 |
| Fabric DW | 3 | ● | ● | | ○ | ○ | | ● | ● | ● | ● | ~400 |
| Fabric Lakehouse | 3 | ● | ● | ○ | | ○ | | ● | ● | ● | ● | ~350 |
| Databricks | 5 | ● | ● | ● | ○ | ● | | ● | ● | ● | ● | ~1,200 |
| Oracle | 6 | ● | ● | ● | ● | ● | ● | ● | ● | ○ | ● | ~2,500 |
| BigQuery | 6 | ● | ● | ● | ○ | ● | | ● | ● | ● | ● | ~2,000 |
| **Grand total** | **~34 unique sources** | | | | | | | | | | | **~14,000 SQL objects/statements (EST); 10,220 EXACT from sqlglot fixtures** |

**Grand totals across all dialects (EST planning figures):** ~34 unique inventoried sources; on the order of 14,000 discrete SQL objects/statements achievable from P0+P1 extraction, anchored by the 10,220 EXACT sqlglot fixture cases, several hundred enterprise procedural/trigger objects (SQL-ProcBench's 63 stored procedures + UDFs + triggers ×3 dialects, plus AdventureWorks/WWI and Oracle packages/triggers/sequences), ~750 analytics queries (TPC-DS 99 + TPC-H 22 + Spider 2.0 632 + dbt models), and the remainder in schema DDL across the sample databases. The SQL Server, Snowflake, and Oracle dialects are the best-served; Synapse, Fabric DW, and Fabric Lakehouse are the scarcest and demand a purpose-built corpus from Microsoft Learn labs, Fabric documentation, and WideWorldImporters.