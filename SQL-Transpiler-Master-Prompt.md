# MASTER PROMPT — "Universal SQL DDL Transpiler" (UST)

> Copy everything below this line into your LLM (Claude / GPT / etc.) as the project brief. It is written to be handed over as-is, in one shot or in phases (see "Execution Phases" at the end).

---

## 1. PROJECT OVERVIEW

Build a **production-grade, full-stack web application** called **"Universal SQL Transpiler" (UST)** that converts SQL DDL/DML/procedural objects bidirectionally between the following 8 SQL dialects:

1. **Amazon Redshift SQL**
2. **Microsoft Fabric Data Warehouse (T-SQL / Fabric DW)**
3. **Azure Synapse Analytics SQL (Dedicated/Serverless SQL Pool)**
4. **Microsoft SQL Server (T-SQL)**
5. **Databricks (Spark SQL / Delta Lake)**
6. **Snowflake SQL**
7. **Oracle Database SQL/PLSQL**
8. **Google BigQuery (GoogleSQL)**

Every dialect must be convertible **to and from every other dialect** (56 directional pairs total, but you should build it as an **N×N matrix engine** using a common intermediate representation — NOT 56 hardcoded converters).

### Object types to support (full coverage — not just CREATE TABLE):
- `CREATE TABLE` (including all column types, constraints, partitioning, clustering, distribution keys, sort keys, identity/auto-increment, computed/generated columns, table properties)
- `CREATE VIEW` and `CREATE MATERIALIZED VIEW`
- `CREATE [OR REPLACE] PROCEDURE` / Stored Procedures
- `CREATE FUNCTION` (scalar, table-valued, UDFs, UDTFs)
- `CREATE INDEX` (including clustered/non-clustered, where supported)
- `CREATE SCHEMA / DATABASE`
- `ALTER TABLE` (add/drop/modify column, constraints)
- `CREATE SEQUENCE` / Identity equivalents
- Data types mapping (full type system mapping matrix per dialect)
- DML where structurally relevant (MERGE, INSERT...SELECT for view/proc bodies)
- Comments, table/column descriptions, tags/labels
- Grants/permissions translation (best-effort, flagged)

---

## 2. CORE ARCHITECTURE REQUIREMENTS

### 2.1 Approach — Intermediate Representation (IR), not regex
- Build a **canonical internal AST/IR** that represents SQL DDL objects in a dialect-agnostic schema (think: a normalized JSON schema describing tables, columns, types, constraints, partitioning, procedural logic blocks, control flow, etc.)
- Each dialect gets:
  - A **Parser** (dialect SQL → IR)
  - A **Generator/Emitter** (IR → dialect SQL)
- This gives N parsers + N generators = full N×N conversion instead of N² hand-written converters.
- Use **sqlglot** (open-source Python SQL transpiler library by Tobiko Data) as the base engine wherever possible — it already supports Redshift, Databricks/Spark, Snowflake, BigQuery, T-SQL (close to Fabric/Synapse), Oracle dialects. Extend it with:
  - Custom dialect classes for **Fabric Warehouse** and **Synapse** (subclass T-SQL with their specific limitations — e.g., Fabric DW doesn't support IDENTITY the same way, no clustered indexes other than columnstore, etc.)
  - Custom **type mapping tables** per the matrix in section 4
  - A **post-processing rules engine** for things sqlglot can't do natively (distribution/partitioning syntax, stored procedure control-flow translation, MV refresh syntax, identity/sequence handling)

### 2.2 Stored Procedure / Procedural Code Translation
This is the hardest part — each platform has different procedural dialects:
- Redshift: PL/pgSQL-based
- SQL Server / Synapse / Fabric: T-SQL (Fabric currently has **limited/no stored procedure support** — flag this explicitly, see section 5)
- Snowflake: Snowflake Scripting (SQL) or JavaScript/Python procs
- Databricks: SQL Scripting (newer) / Python-UDF based, no traditional stored procs historically
- Oracle: PL/SQL
- BigQuery: BigQuery Scripting (SQL procedural language)

**Requirement:** Build a separate **procedural-logic IR** covering: variable declarations, IF/ELSE, loops (WHILE/FOR/REPEAT), exception handling (TRY/CATCH vs EXCEPTION blocks), cursors, dynamic SQL, temp tables, transaction control (BEGIN/COMMIT/ROLLBACK).

**Where a target platform fundamentally lacks a feature (e.g., Databricks classic SQL had no cursors, Fabric DW has no stored procedures as of now)**, the tool must:
- Output the closest equivalent (e.g., convert to a notebook/Python function, or a parameterized SQL script, or Dataflow/pipeline-based alternative)
- Clearly **annotate with a warning comment block** in the output explaining the limitation and suggested workaround, with a link to the official doc describing the limitation

---

## 3. OFFICIAL DOCUMENTATION SOURCES — STRICT REQUIREMENT

**ALL syntax, type mappings, limitations, and behavior MUST be sourced and verified from official vendor documentation only.** Do not rely on blog posts, Stack Overflow, or third-party tutorials for syntax decisions. When uncertain or when docs are ambiguous/silent, **search docs.* / official sites further** rather than guessing, and cite the doc page in code comments/config where mappings are non-obvious.

Use these as the primary doc roots (search within these domains for the specific object types as you build each dialect module):

| Platform | Official Docs Root | Key sections to dig into |
|---|---|---|
| **Amazon Redshift** | https://docs.aws.amazon.com/redshift/latest/dg/ | SQL Reference → CREATE TABLE, CREATE VIEW, CREATE MATERIALIZED VIEW, stored procedures (CREATE PROCEDURE), data types, DISTSTYLE/DISTKEY/SORTKEY |
| **Microsoft Fabric DW** | https://learn.microsoft.com/en-us/fabric/data-warehouse/ | T-SQL surface area, "T-SQL differences" / "Fabric Data Warehouse limitations" pages, data types |
| **Azure Synapse Analytics** | https://learn.microsoft.com/en-us/azure/synapse-analytics/sql/ | CREATE TABLE (dedicated SQL pool), distribution, indexing, "SQL pool T-SQL differences from SQL Server" |
| **SQL Server** | https://learn.microsoft.com/en-us/sql/t-sql/ | CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, data types, control-of-flow language |
| **Databricks** | https://docs.databricks.com/en/sql/language-manual/ | CREATE TABLE, CREATE VIEW, CREATE MATERIALIZED VIEW, CREATE FUNCTION, SQL Scripting, Delta Lake DDL |
| **Snowflake** | https://docs.snowflake.com/en/sql-reference/ | CREATE TABLE, CREATE VIEW, CREATE MATERIALIZED VIEW, CREATE PROCEDURE, Snowflake Scripting, data types |
| **Oracle Database** | https://docs.oracle.com/en/database/oracle/oracle-database/ | SQL Language Reference (CREATE TABLE, VIEW, MATERIALIZED VIEW), PL/SQL Language Reference (CREATE PROCEDURE), Data Types |
| **Google BigQuery** | https://cloud.google.com/bigquery/docs/reference/standard-sql/ | Data Definition Language (CREATE TABLE/VIEW/MATERIALIZED VIEW/PROCEDURE/FUNCTION), Data types, Procedural language |

**Also reference sqlglot's own dialect implementations** as engineering reference (NOT as source of truth for syntax — always cross-check against the above): https://github.com/tobymao/sqlglot/tree/main/sqlglot/dialects

> ⚠️ **Instruction to the LLM building this:** Before implementing each conversion rule (especially for type mappings, partitioning/clustering, identity columns, MV refresh syntax, and procedural constructs), use web search to pull up the **current** official doc page for both source and target platform, and cite the URL in a code comment above the mapping rule. If a feature exists in source but has **no equivalent** in target, search the target's official "limitations" or "differences" page to confirm before deciding on a workaround.

---

## 4. TYPE MAPPING MATRIX (build as a structured config, not inline code)

Build a single source-of-truth file `type_mappings.yaml` (or JSON) structured as a matrix covering at minimum:

| Generic Type | Redshift | Fabric DW | Synapse | SQL Server | Databricks | Snowflake | Oracle | BigQuery |
|---|---|---|---|---|---|---|---|---|
| Tiny/Small Int | SMALLINT | smallint | smallint | smallint/tinyint | TINYINT/SMALLINT | NUMBER/SMALLINT | NUMBER(3/5) | INT64 |
| Integer | INTEGER | int | int | int | INT | NUMBER/INTEGER | NUMBER(10) | INT64 |
| Big Integer | BIGINT | bigint | bigint | bigint | BIGINT | NUMBER/BIGINT | NUMBER(19) | INT64 |
| Decimal/Numeric | DECIMAL(p,s) | decimal(p,s) | decimal(p,s) | decimal/numeric | DECIMAL(p,s) | NUMBER(p,s) | NUMBER(p,s) | NUMERIC/BIGNUMERIC |
| Float/Double | REAL/DOUBLE PRECISION | float/real | float/real | float/real | FLOAT/DOUBLE | FLOAT/DOUBLE | BINARY_DOUBLE/FLOAT | FLOAT64 |
| String (var) | VARCHAR(n) | varchar(n) | varchar(n) | varchar/nvarchar | STRING/VARCHAR | VARCHAR/STRING | VARCHAR2(n) | STRING |
| Text/CLOB | VARCHAR(65535)/TEXT | varchar(max) | varchar(max) | varchar(max)/text | STRING | TEXT/STRING | CLOB | STRING |
| Boolean | BOOLEAN | bit | bit | bit | BOOLEAN | BOOLEAN | NUMBER(1)/BOOLEAN(23c+) | BOOL |
| Date | DATE | date | date | date | DATE | DATE | DATE | DATE |
| Timestamp | TIMESTAMP/TIMESTAMPTZ | datetime2 | datetime2 | datetime2/datetimeoffset | TIMESTAMP/TIMESTAMP_NTZ | TIMESTAMP_NTZ/TIMESTAMP_TZ | TIMESTAMP/TIMESTAMP WITH TZ | TIMESTAMP/DATETIME |
| Binary | VARBYTE | varbinary | varbinary | varbinary | BINARY | BINARY | BLOB/RAW | BYTES |
| JSON/Semi-structured | SUPER | nvarchar(max)+JSON funcs | nvarchar(max) | nvarchar(max) | VARIANT/STRING (JSON funcs) | VARIANT | JSON (21c+)/CLOB | JSON |
| Array | SUPER (limited) | n/a (flag) | n/a (flag) | n/a (flag) | ARRAY<T> | ARRAY | VARRAY/nested table | ARRAY<T> |
| Struct/Object | SUPER | n/a (flag) | n/a (flag) | n/a (flag) | STRUCT<...> | OBJECT | OBJECT TYPE | STRUCT |
| GEOGRAPHY/GEOMETRY | GEOMETRY/GEOGRAPHY | n/a (flag) | n/a (flag) | geography/geometry | n/a (use lib) | GEOGRAPHY/GEOMETRY | SDO_GEOMETRY | GEOGRAPHY |

> The LLM building this must **search each platform's official "Data types" doc page** (linked in section 3) and produce the COMPLETE matrix — the above is a starting skeleton, not exhaustive. Pay special attention to: precision/scale limits, max VARCHAR lengths, timezone handling differences, semi-structured type equivalents (SUPER vs VARIANT vs STRUCT vs JSON), and identity/auto-increment mechanisms (IDENTITY(1,1) vs AUTOINCREMENT vs GENERATED ALWAYS AS IDENTITY vs sequences).

---

## 5. PLATFORM-SPECIFIC STRUCTURAL CONCEPTS TO HANDLE

For each of these, build explicit translation rules (source: official docs in section 3):

1. **Distribution & Sort Keys (Redshift)** ↔ **Distribution (Synapse/Fabric: HASH/ROUND_ROBIN/REPLICATE)** ↔ **Clustering/Partitioning (Databricks: PARTITIONED BY, CLUSTER BY; BigQuery: PARTITION BY/CLUSTER BY; Snowflake: CLUSTER BY)**
2. **Identity columns**: Redshift `IDENTITY(seed, step)` ↔ SQL Server/Fabric/Synapse `IDENTITY(seed,increment)` ↔ Databricks `GENERATED ALWAYS AS IDENTITY` ↔ Snowflake `AUTOINCREMENT`/`IDENTITY` ↔ Oracle `GENERATED ALWAYS AS IDENTITY` / sequences ↔ BigQuery (no native identity — flag + suggest `GENERATE_UUID()` or sequence table pattern)
3. **Materialized Views**: refresh semantics differ massively — Redshift (auto-refresh options), Databricks (refresh schedules), Snowflake (auto via cloud services, enterprise edition only — flag), BigQuery (refresh interval), Synapse/Fabric (**no native MV support** — flag and suggest standard view + scheduled table refresh pattern), Oracle (refresh ON COMMIT/ON DEMAND, fast/complete refresh)
4. **Stored Procedures / Scripting**: see section 2.2. **Fabric DW currently does not support stored procedures** — must search current Fabric docs to confirm latest status and produce appropriate fallback (e.g., convert to parameterized notebook/pipeline activity or T-SQL script template) with a clear warning + doc link.
5. **Temporary/Transient/External Tables**: map CREATE TEMP TABLE, Snowflake TRANSIENT tables, BigQuery temp tables (session-scoped), Databricks TEMPORARY VIEW, external tables (Redshift Spectrum, Synapse external tables, BigQuery external tables, Databricks external/unmanaged tables, Snowflake external tables) — each has different syntax for location/format.
6. **Case sensitivity & identifier quoting**: Snowflake (unquoted = uppercase), BigQuery/Databricks (case-insensitive but preserve), Oracle (unquoted = uppercase), SQL Server family (case-insensitive default) — must preserve original casing intent via quoting in output where needed.
7. **Schema/Database/Catalog hierarchy differences**: BigQuery (project.dataset.table), Databricks (catalog.schema.table — Unity Catalog 3-level), Snowflake (database.schema.table), SQL Server family (database.schema.table), Oracle (schema = user), Redshift (database.schema.table).
8. **Comments/descriptions**: COMMENT ON (Redshift/Snowflake/BigQuery/Databricks) vs sp_addextendedproperty (SQL Server/Synapse/Fabric) vs COMMENT ON (Oracle).

For each of the above, **the build process must search the relevant official doc pages, confirm current syntax (things change — e.g., Fabric DW is evolving rapidly in 2025-2026), and document the source URL** in the codebase (e.g., as a docstring or a `references.md` per dialect module).

---

## 6. TECH STACK (recommended — adjust if the LLM has a strong reason not to)

**Backend:**
- Python 3.11+, FastAPI
- `sqlglot` as the core parsing/transpilation engine (extend with custom dialects for Fabric/Synapse where needed)
- Pydantic models for the IR schema
- Modular structure: `/dialects/<platform>/parser.py`, `/dialects/<platform>/generator.py`, `/dialects/<platform>/type_map.yaml`, `/dialects/<platform>/limitations.md` (with doc citations)
- A `/rules_engine/` for post-processing transformations sqlglot can't natively do
- A `/proc_translator/` module for procedural code IR + translation
- REST API: `POST /api/convert` with `{source_dialect, target_dialect, sql, object_type}` → returns `{converted_sql, warnings[], unsupported_features[], doc_references[]}`
- Batch mode: accept a `.sql` file with multiple statements/objects, return a converted file + a JSON report of warnings per object

**Frontend:** (see section 7 for full UI spec)
- React + TypeScript + Vite
- TailwindCSS for styling
- Monaco Editor (the VS Code editor component) for both source and target SQL panes with syntax highlighting
- Framer Motion for smooth gradient/animation transitions

**Testing:**
- Golden-file test suite: for each (source dialect, object type) pair, store sample DDLs and expected IR + expected output for every target dialect
- Test against **real syntax examples taken directly from official docs** (use the CREATE TABLE/VIEW/PROCEDURE examples shown in each vendor's doc pages as golden inputs)

**Deployment:**
- Dockerized (separate containers for frontend/backend), docker-compose for local dev
- Optional: deployable to Azure/AWS/GCP — keep cloud-agnostic

---

## 7. FRONTEND UI/UX SPEC — "Dual-Platform Gradient" Design

This should feel premium, modern, like a mix of **Vercel's** clean aesthetic + **Linear's** smooth motion + a touch of **Stripe's** docs polish.

### 7.1 Core concept
- **Two dropdown/selector cards** at the top: "Source Platform" and "Target Platform", each showing the platform's **official logo** + name.
- The **page background gradient dynamically blends the brand colors of the selected source and target platforms** — e.g., Redshift (AWS orange/Redshift blue `#2E73B8`) → Databricks (`#FF3621` red/orange) creates a smooth diagonal gradient mesh transitioning between the two, animated subtly (slow drift, like a living gradient — use CSS `@property` animated gradients or a WebGL/Canvas shader via `react-three-fiber` or a simple animated `radial-gradient`/`conic-gradient` blend with Framer Motion `animate` on background-position).
- When either dropdown changes, the gradient **smoothly transitions** (CSS transition or Framer Motion `animate` over ~800ms) to the new color pair — no jarring jumps.
- Reference brand colors (pull official ones for accuracy):
  - Redshift: `#2E73B8` / AWS Squid Ink `#232F3E`
  - Databricks: `#FF3621` / dark `#1B3139`
  - Snowflake: `#29B5E8`
  - Oracle: `#F80000` / red
  - SQL Server: `#CC2927` / Microsoft red
  - Synapse: `#0078D4` (Azure blue family)
  - Fabric: `#1F8B5D` / Fabric's signature green-blue gradient (Fabric uses a multi-color gradient brand identity — `#1F8B5D` to `#36C2B4` to `#0078D4` roughly)
  - BigQuery: `#4285F4` / `#669DF6` (Google blue) with Google multicolor accents

> Instruct the LLM to **search each platform's official brand/press-kit page** for exact hex codes before finalizing the palette config (`brand_colors.json`).

### 7.2 Layout
```
┌──────────────────────────────────────────────────────────────┐
│   [Animated dual-brand gradient background, full viewport]    │
│                                                                  │
│   UNIVERSAL SQL TRANSPILER          [theme toggle: light/dark] │
│                                                                  │
│   ┌─────────────┐    ⇄ (animated swap icon)   ┌─────────────┐ │
│   │ FROM         │                              │ TO          │ │
│   │ [Logo] Redshift ▾ │                         │ [Logo] Databricks ▾│
│   └─────────────┘                              └─────────────┘ │
│                                                                  │
│   Object Type: ( ) Table ( ) View ( ) Materialized View         │
│                ( ) Stored Procedure ( ) Function ( ) Auto-detect│
│                                                                  │
│  ┌─────────────────────────┐   ┌─────────────────────────┐    │
│  │  SOURCE SQL (Monaco)     │   │  CONVERTED SQL (Monaco)  │    │
│  │  [paste / upload .sql]   │   │  [read-only, copy/download]│  │
│  │                          │ → │                          │    │
│  └─────────────────────────┘   └─────────────────────────┘    │
│                                                                  │
│  [Convert ▶]  [Upload File]  [Download .sql]  [Copy]            │
│                                                                  │
│  ⚠ WARNINGS / UNSUPPORTED FEATURES PANEL (collapsible)          │
│   - "MATERIALIZED VIEW auto-refresh not supported in Fabric DW. │
│      Falling back to standard VIEW. [Docs ↗]"                  │
│                                                                  │
│  📚 REFERENCED DOCS PANEL — links to official docs used for     │
│      this specific conversion's mapping decisions               │
└──────────────────────────────────────────────────────────────┘
```

### 7.3 Interaction details
- **Swap button (⇄)** between the two dropdowns: instantly swaps source ↔ target (and swaps the SQL panes' content if both have content), with a satisfying rotate animation.
- **Logos**: use official SVG logos for each platform (download from official brand resource pages — note licensing/usage guidelines per brand).
- **Gradient blending**: implement via a CSS custom property approach:
  ```css
  .bg-blend {
    background: linear-gradient(135deg, var(--source-color) 0%, var(--target-color) 100%);
    background-size: 200% 200%;
    animation: gradientDrift 15s ease infinite;
    transition: --source-color 0.8s, --target-color 0.8s;
  }
  ```
  (Use Framer Motion's `useMotionValue` + `animate()` to interpolate hex colors smoothly since raw CSS custom property color transitions need a polyfill or JS-driven interpolation — recommend `framer-motion`'s color interpolation or `chroma-js` for blending.)
- **Object type auto-detection**: parse the pasted SQL's leading keywords (`CREATE TABLE`, `CREATE VIEW`, `CREATE MATERIALIZED VIEW`, `CREATE PROCEDURE`, etc.) and auto-select the radio button.
- **Diff highlighting** (nice-to-have): show a side-by-side diff view toggle highlighting what changed structurally (type changes, removed/added clauses).
- **Dark mode**: default to dark mode (gradient looks better on dark background); light mode toggle available.
- **Responsive**: stacks vertically on mobile, side panes become tabs.
- **Micro-interactions**: button hover glows matching the gradient colors, subtle particle/mesh background animation (optional, keep performant — use CSS only or lightweight canvas, avoid heavy WebGL unless perf-tested).

### 7.4 Pages/Routes
- `/` — main converter (as above)
- `/docs` — explains supported features per dialect pair, links to official docs used
- `/limitations` — matrix of known unsupported feature combinations (e.g., Fabric stored procs, Snowflake MV enterprise-only)
- `/api-docs` — Swagger/OpenAPI docs for the backend (auto-generated by FastAPI)
- `/playground` — batch mode: upload a full `.sql` schema dump, get a converted file + report

---

## 8. OUTPUT QUALITY / WARNINGS SYSTEM

Every conversion response must include:
1. **`converted_sql`** — the translated DDL
2. **`warnings[]`** — list of objects: `{ feature, message, doc_url, severity: "info"|"warning"|"error" }`
3. **`unsupported_features[]`** — things that couldn't be translated 1:1, with the fallback approach taken
4. **`doc_references[]`** — official doc URLs consulted for this specific conversion's decisions (so users can verify)

Example warning:
```json
{
  "feature": "MATERIALIZED_VIEW_AUTO_REFRESH",
  "message": "Fabric Data Warehouse does not currently support materialized views. Converted to a standard VIEW. Consider a scheduled pipeline to materialize results into a table.",
  "doc_url": "https://learn.microsoft.com/en-us/fabric/data-warehouse/...",
  "severity": "warning"
}
```

---

## 8.5 NO-HYPOTHETICALS POLICY — REAL ALTERNATIVES ONLY

This is a hard rule, not a suggestion:

- **Never invent, assume, or hallucinate** a fallback/alternative for an unsupported feature. Every fallback strategy used in the tool (e.g., "MV not supported in Fabric DW → use X instead") must be based on a **real, documented, currently-supported mechanism** found in that platform's **official documentation**.
- For every unsupported-feature case, the build process must:
  1. **Confirm the limitation is real and current** — search the target platform's official docs (limitations/differences/known-issues pages) and cite the exact URL. Things change fast (especially Fabric DW), so re-verify rather than relying on memory/training data.
  2. **Search the target platform's official docs for the real recommended alternative/pattern** for that scenario (e.g., search Microsoft Fabric docs for "materialized view alternative", "incremental refresh pattern", "scheduled table refresh"). Use the alternative the vendor itself documents/recommends — not a generic guess.
  3. **Implement that real alternative as actual generated output** (working SQL/script/pipeline definition), not a placeholder comment saying "consider doing X". The output must be something the user can actually run.
  4. Attach the `doc_url` for both (a) the limitation and (b) the alternative pattern in the `warnings[]`/`doc_references[]` response.
  5. If, after thorough searching, **no documented alternative exists**, do NOT fabricate one. Instead, output the object as a clearly-marked **manual-action-required** stub with the exact official doc link where the user should check for updates, and set `"severity": "error"` with `"unsupported": true`.

**Example — Materialized View (Redshift/Snowflake/BigQuery/Databricks) → Fabric Warehouse:**
- Step 1: Search Microsoft Fabric Data Warehouse docs to confirm current MV support status (this changes over time — verify at build time, not from memory).
- Step 2: If unsupported, search Fabric docs for the officially documented pattern for materializing query results — e.g., **CREATE TABLE AS SELECT (CTAS)** combined with a **Fabric Data Pipeline / scheduled notebook** to periodically refresh the table (this is Microsoft's documented CTAS-based materialization pattern for Fabric DW). Cite the exact CTAS doc page and any pipeline-scheduling doc page.
- Step 3: Generate the **actual CTAS statement** translating the MV's defining query, plus (if the docs support it) a stub for the refresh pipeline/schedule definition (e.g., a Fabric pipeline JSON snippet or T-SQL stored procedure that re-runs the CTAS, per documented patterns).
- Step 4: Populate `warnings[]` with both doc URLs (limitation confirmation + CTAS/refresh pattern doc).

This same rigor applies to **every** flagged limitation across all 8 platforms (stored procedures in Fabric, MV refresh in Snowflake non-Enterprise, arrays/structs in Synapse/SQL Server, sequences in BigQuery, external tables, etc.) — each must go through this **verify → find real documented alternative → implement working output → cite sources** loop. Generic "you may consider..." advisory comments are NOT acceptable as the primary output; they may only supplement the real generated alternative.

---

## 9. EXECUTION PHASES (recommend building incrementally)

1. **Phase 1 — Foundation**: IR schema design (Pydantic models) + type mapping matrix (research all 8 platforms' data types from official docs) + sqlglot integration for the 2 easiest pairs (Redshift ↔ Snowflake, since sqlglot supports both well)
2. **Phase 2 — Core 8-dialect table/view/MV support**: extend custom dialects for Fabric/Synapse, build CREATE TABLE/VIEW/MV converters for all 8, with the rules engine for distribution/partitioning/identity
3. **Phase 3 — Procedural code (stored procs/functions)**: build the procedural IR, implement parsers/generators for each platform's procedural dialect, with fallback strategies for unsupported platforms
4. **Phase 4 — Backend API + warnings/doc-reference system**
5. **Phase 5 — Frontend**: build the gradient UI, Monaco integration, all pages
6. **Phase 6 — Testing**: golden-file tests using real examples copied from official docs for each (dialect, object type)
7. **Phase 7 — Docs site + limitations matrix + deployment**

---

## 10. FINAL INSTRUCTIONS TO THE BUILDING LLM

- **Strictly cite official docs** for every non-trivial syntax/mapping decision (links from section 3, plus deeper sub-pages you find via search).
- When official docs are unclear, **search further within the same official domain** before falling back to community sources — and if you must use a non-official source, mark that mapping as `"confidence": "unverified"` in the config so it's flagged for human review.
- Build incrementally per the phases above; after each phase, produce a short summary of what was implemented + which doc pages were used.
- Keep the IR schema extensible — new platforms or object types should be addable without rearchitecting.
- Prioritize **correctness with explicit warnings** over silent best-effort guesses — a clearly flagged "unsupported" beats a silently wrong conversion.
- For the frontend, prioritize the gradient/branding experience described in section 7 — this is a key differentiator of the product.

---

### Quick-reference doc links (also embedded above)
- Redshift SQL Reference: https://docs.aws.amazon.com/redshift/latest/dg/cm_chap_SQLCommandRef.html
- Fabric Data Warehouse docs: https://learn.microsoft.com/en-us/fabric/data-warehouse/
- Synapse Analytics SQL: https://learn.microsoft.com/en-us/azure/synapse-analytics/sql/overview-sql
- SQL Server T-SQL Reference: https://learn.microsoft.com/en-us/sql/t-sql/language-reference
- Databricks SQL Language Manual: https://docs.databricks.com/en/sql/language-manual/index.html
- Snowflake SQL Reference: https://docs.snowflake.com/en/sql-reference/sql-all
- Oracle SQL Language Reference: https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/
- Oracle PL/SQL Language Reference: https://docs.oracle.com/en/database/oracle/oracle-database/23/lnpls/
- BigQuery Standard SQL DDL: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language
- sqlglot (engineering reference): https://github.com/tobymao/sqlglot
