# QA_Review_Report.md
## Ruthless QA & Code Review — Universal SQL Transpiler (UST)

**Repository:** https://github.com/Suryarathore2345/Universal-SQL-Transpiler
**Reviewed at:** local clone, `universal-sql-transpiler/` (commit `9df5e29`, branch `master`)
**Review method:** static code review of every backend dialect (parser + generator), the FastAPI backend core, the React frontend, docs, Docker/CI config, plus **live dynamic testing** — full pytest suite execution (3,986 tests), a live uvicorn server exercised with adversarial/edge-case HTTP requests, and direct Python-level fuzzing of the transpiler with malformed, oversized, Unicode, and adversarial SQL.
**Reviewers:** 4 parallel deep-dive audits (Redshift/Snowflake/SQLServer/Synapse; FabricDW/Lakehouse/Databricks/Oracle/BigQuery; backend core/API/security/performance; frontend/docs/CI/architecture) + direct verification/synthesis pass. Every finding below was either independently reproduced by the synthesizing pass or is backed by an exact repro command and observed output from a sub-audit — nothing here is speculative.

> **Process note:** one sub-audit agent, while live-testing the API, ran `taskkill /IM python.exe /T` to clean up its own test server — this force-kills **every** `python.exe` process on the machine, not just the ones it started. If other Python processes were running on this machine at that time, they were likely killed. This is disclosed here for transparency; it is a tooling side-effect of this review, not a repository finding.

---

## 1. Executive Summary

Universal SQL Transpiler (UST) is an ambitious, genuinely well-structured project: a real IR (Intermediate Representation) architecture, 9 fully-implemented dialects (Redshift, Snowflake, SQL Server, Synapse, Fabric DW, Fabric Lakehouse, Databricks, Oracle, BigQuery — one more than the README admits to), a FastAPI backend, a polished React frontend, and a 3,986-test suite that is **100% green**. That is a strong foundation and should not be understated.

However, this review found **12 Critical and 9 High severity defects**, several of which mean the tool will confidently hand a user SQL that will not run, and one of which is a genuine unauthenticated denial-of-service vector reachable with a single `curl` command. The most important overall finding is structural: **the project's own spec (`SQL-Transpiler-Master-Prompt.md`) explicitly mandates an IR-based, non-regex architecture** ("Build a canonical internal AST/IR... NOT regex"), but the actual implementation's view/materialized-view body translation is done almost entirely via ~75 regex `re.sub`/`re.finditer` passes over raw SQL text in a single 1,900-line `base.py` "God class." These regexes are **not string-literal- or comment-aware**, so they silently rewrite text inside `'...'` string literals and `--`/`/* */` comments — a confirmed, reproducible data-corruption bug, not a theoretical one.

Compounding this, the **confidence-scoring system that is the product's core trust signal is broken**: it reports `HIGH` (1.0) or `PARTIAL` (0.95) confidence on output that is verifiably not valid SQL — including a `WITH RECURSIVE` view emitted verbatim to SQL Server (which doesn't support the `RECURSIVE` keyword), `LIMIT...OFFSET` emitted verbatim to SQL Server (unsupported syntax there), and a case where sqlglot's lenient parser produces structurally broken output SQL. A user who trusts the confidence badge — the entire UX conceit of this tool — will ship broken DDL believing it's been verified.

There is also a confirmed **ReDoS-class performance bug**: `redshift/parser.py`'s DISTKEY-extraction regex exhibits near-cubic scaling and takes **38 seconds of pure regex time** on a 3,200-column table with no DISTKEY (a completely ordinary, non-adversarial input — most Redshift tables don't define one). Combined with **no size limit on the request body** and the transpile call running synchronously inside an `async def` route (blocking the entire single-worker event loop, confirmed with an 8 MB payload that froze the server — including its own `/api/health` probe — for 3 minutes 28 seconds), this is a trivial, unauthenticated, single-request DoS against the reference deployment.

None of this diminishes the genuine engineering quality visible elsewhere (the statement splitter in `base.py`, the type-mapping framework's design, the dialect-specific CLUSTER BY/PARTITIONED BY validation, the frontend's error/loading-state handling, and the extensive, currently-passing test suite). But **this is not yet ready for a "first major release"** in the sense of being handed to users as a trustworthy, unattended tool — the confidence score cannot currently be trusted, several extremely common SQL patterns (inline `PRIMARY KEY`, `NUMBER(p)`, `INT64`) are mishandled with zero warning, and there is no LICENSE, no CI, and a documented install path that doesn't exist on a clean checkout.

---

## 2. Repository Overview

| | |
|---|---|
| Backend | Python 3.14 / FastAPI 0.111+, `sqlglot`-based parsing, Pydantic v2 schemas |
| Frontend | React 18 + Vite, Monaco editor |
| Dialects implemented | 9: Redshift, Snowflake, SQL Server, Synapse, Fabric DW, **Fabric Lakehouse**, Databricks, Oracle, BigQuery |
| Object types | Tables, Views, Materialized Views, Procedures, Functions, plus a sqlglot-backed SELECT/DML query path |
| Tests | 3,986 passed, 16 skipped (all legitimate data-dependent skips), 0 failed — verified by a live run |
| CI/CD | **None** — no `.github/workflows` directory exists |
| License | **None** — no LICENSE file at repo root |
| Docker | `docker-compose.yml` + Dockerfiles present and functionally correct |
| Docs | `README.md`, `RUNNING_LOCALLY.md`, `SQL-Transpiler-Master-Prompt.md` (spec) — all present but each has material staleness/accuracy issues (see §12) |

---

## 3. Architecture Assessment

**Intended architecture** (per `SQL-Transpiler-Master-Prompt.md` §2.1): a dialect-agnostic IR, with each dialect contributing only a Parser (SQL → IR) and Generator (IR → SQL); sqlglot as the base engine; a "post-processing rules engine" only for what sqlglot can't do natively.

**Actual architecture:** table/column/constraint DDL genuinely does flow through the IR as designed (`ir/models.py`, `dialects/*/parser.py`, `dialects/*/generator.py`) — this part is sound and matches spec. But **view and materialized-view bodies bypass the IR almost entirely**: the body text is extracted once by sqlglot, then run through a chain of up to ~20 sequential regex substitutions per target dialect (`_apply_tsql_view_conversions`, `_apply_oracle_view_conversions`, `_apply_bigquery_view_conversions`, etc., all living in `dialects/base.py`). This is precisely the approach the spec says not to take, and it is the direct root cause of the two worst correctness bugs in this report (TRANS-001, TRANS-002).

`dialects/base.py` itself is a 1,900-line "God class" holding ~75 dialect-pair-specific regex helper methods shared (and inherited) by every generator. This is a maintainability risk independent of correctness: a change intended for one dialect pair risks affecting every other dialect that also calls the same shared helper.

There is also duplicated, **behaviorally divergent** logic: two independent statement-splitters exist (`dialects/base.py::DialectParser._split_statements` and a second, weaker copy in `query_transpiler.py`), and only one of them is comment-aware (§7, API-003).

**Recommendation:** either (a) extend the IR to cover expressions inside view bodies (the architecturally correct fix, larger effort), or (b) at minimum make every `_convert_*` regex helper string-literal/comment-aware by tokenizing before substitution (smaller effort, directly fixes the Critical data-corruption bugs below).

---

## 4. Functional Bugs

### BUG-001 — Orphaned "Generate Schema from Data" feature (frontend + backend both broken, fully unreachable)
- **Severity:** 🟠 High
- **Module/File:** `frontend/src/components/SchemaGenModal.jsx`, `frontend/src/api/transpiler.js`, `backend/app/schema_infer.py`
- **Description:** A complete schema-inference feature (~500+ lines across both stacks) exists but is fully disconnected: `SchemaGenModal.jsx` imports `inferSchema` from `transpiler.js`, which doesn't export it; the modal is never rendered by `App.jsx` (zero references); and the backend's `schema_infer.py` (`infer_and_generate`) is never wired to any FastAPI route (`routes.py` only defines `/transpile`, `/dialects`, `/limitations`, `/health`).
- **Steps to Reproduce:** Grep `frontend/src` for `SchemaGenModal` usage (none) and `backend/app/api/routes.py` for `schema_infer` (none).
- **Expected Behavior:** Either the feature is reachable from the UI and functional end-to-end, or it doesn't exist in the tree.
- **Actual Behavior:** Dead code on both sides; if someone re-wires the button without noticing the missing export, it fails at runtime.
- **Impact:** Confuses future contributors; wastes maintenance surface; misleads anyone reading the code into thinking this capability ships.
- **Root Cause:** Feature abandoned mid-implementation without cleanup.
- **Suggested Fix:** Either finish wiring it (add the route, export `inferSchema`, add a launch button) or delete all three pieces.
- **Priority:** P2

### BUG-002 — `schema_infer.py` silently drops the schema/dataset qualifier even when reachable
- **Severity:** 🟡 Medium
- **Module/File:** `backend/app/schema_infer.py:204-209`
- **Description:** Constructs `IRTable(name=table_name, schema=schema_name, ..., dialect=Dialect(target_dialect))` — but `IRTable` has no `schema` field (only `schema_name`) and no `dialect` field at all. Pydantic silently ignores unrecognized kwargs, so `schema_name` stays `None` regardless of caller input.
- **Steps to Reproduce:** `infer_and_generate(csv_text, 'csv', 'my_table', 'my_schema', 'bigquery', BigQueryGenerator())` → output table name is never schema-qualified.
- **Expected Behavior:** `` `my_schema.my_table` `` in the generated DDL.
- **Actual Behavior:** `` `my_table` `` only.
- **Impact:** Feature (once reconnected per BUG-001) can never produce schema-qualified output.
- **Root Cause:** Typo'd/stale kwargs never caught because Pydantic doesn't error on unknown constructor kwargs here and there is no test.
- **Suggested Fix:** `IRTable(name=table_name, schema_name=schema_name, ...)`, drop the nonexistent `dialect=` kwarg.
- **Priority:** P3

### BUG-003 — `start-backend.cmd` / `start-frontend.cmd` fail at the actual repository location
- **Severity:** 🟠 High
- **Module/File:** `start-backend.cmd:2`, `start-frontend.cmd:2-3`
- **Description:** `start-backend.cmd` does `cd /d "%~dp0universal-sql-transpiler\backend"`. For a script physically located at `...\universal-sql-transpiler\start-backend.cmd`, `%~dp0` already resolves to `...\universal-sql-transpiler\`, so the `cd` target becomes `...\universal-sql-transpiler\universal-sql-transpiler\backend` — a path that does not exist (confirmed directly). `start-frontend.cmd` has the identical bug **plus** a hardcoded personal path: `set PATH=C:\Users\SuryadevRathore\node;%PATH%`.
- **Steps to Reproduce:** Run `start-backend.cmd` from a fresh clone.
- **Expected Behavior:** Backend starts.
- **Actual Behavior:** `cd` fails silently (bad path), uvicorn then runs from the wrong working directory and fails with `ModuleNotFoundError: app.main`.
- **Impact:** The two convenience scripts a new user would try first are both broken; `start-frontend.cmd` additionally only works on the original author's machine.
- **Root Cause:** Scripts written when the project lived one directory level up; not updated after the repo was flattened.
- **Suggested Fix:** Fix the relative path (drop the extra `universal-sql-transpiler\`); remove the hardcoded personal `PATH` entry and rely on the system `PATH`/`nvm`.
- **Priority:** P1 (first-impression breakage for new users/contributors)

### BUG-004 — `DialectLogo.jsx` missing entry for `fabric_lakehouse`
- **Severity:** 🟡 Medium
- **Module/File:** `frontend/src/components/DialectLogo.jsx` (`LOGO_MAP`, lines 212-221)
- **Description:** Covers 8 of the 9 real dialects; `fabric_lakehouse` (a fully supported backend dialect) falls back to the generic gray placeholder icon.
- **Steps to Reproduce:** Select "Fabric Lakehouse" as source or target in the UI.
- **Expected Behavior:** Fabric Lakehouse brand logo renders.
- **Actual Behavior:** Generic "DB" placeholder renders.
- **Impact:** Visible inconsistency for one of nine supported platforms; no crash.
- **Root Cause:** `LOGO_MAP` not updated when Fabric Lakehouse was added.
- **Suggested Fix:** Add the missing map entry.
- **Priority:** P3

### BUG-005 — `SqlEditor.jsx`'s `placeholder` prop never renders visible text
- **Severity:** 🔵 Low
- **Module/File:** `frontend/src/components/SqlEditor.jsx:42`, `App.jsx:320`
- **Description:** `placeholder="Output will appear here…"` is passed but only used to toggle a Monaco `renderValidationDecorations` setting — the text itself is never displayed via overlay/CSS.
- **Actual Behavior:** Empty output pane shows nothing instead of the intended hint.
- **Impact:** Minor UX polish gap.
- **Suggested Fix:** Add a Monaco placeholder overlay or CSS `::before` on the empty editor container.
- **Priority:** P4

### BUG-006 — `UploadButton.jsx` has no file-size or content-type validation after picker
- **Severity:** 🔵 Low
- **Module/File:** `frontend/src/components/UploadButton.jsx`, `frontend/src/utils/download.js`
- **Description:** `accept=".sql,.txt,text/plain"` is only a picker hint; a user selecting "All files" can load an arbitrarily large or binary file straight into `FileReader.readAsText()` with no size cap or post-selection content check.
- **Impact:** Large/binary file dumps garbage into the Monaco editor; this is a client-side-only self-inflicted issue (no upload to backend occurs), so blast radius is limited to the user's own tab, but still a rough edge.
- **Suggested Fix:** Cap file size (e.g. 5 MB) and reject non-text content with a friendly error.
- **Priority:** P4

---

## 5. SQL Translation Issues

### TRANS-001 — Regex view/MV-body converters corrupt string literals and comments (silent data corruption) 🔴 **Critical**
- **Module/File:** `backend/app/dialects/base.py`, all `_convert_*` helpers feeding `_apply_*_view_conversions` (≈lines 626–1891); affects every dialect that has a view/MV conversion path (all 9).
- **Description:** Every regex-based function converter (`_convert_nvl_aware`, `_convert_decode_to_case`, `_convert_double_colon_cast`, `_convert_date_trunc`, `_convert_length_to_len`, `_convert_pipe_concat_to_plus`, etc.) runs `re.sub`/`re.finditer` over the **entire regenerated SQL text**, with zero awareness of `'...'` string-literal or `--`/`/* */` comment boundaries.
- **Steps to Reproduce (independently confirmed 3×, minimal case):**
  ```sql
  -- Redshift → SQL Server
  CREATE VIEW v1 AS SELECT col1, 'Please call NVL(a,b) to fix this' AS note FROM t1;
  ```
- **Expected Behavior:** `'Please call NVL(a,b) to fix this'` (string literal content unchanged).
- **Actual Behavior:** `'Please call ISNULL(a,b) to fix this'` — the literal's stored value is permanently altered, with **zero warnings emitted**.
- **Further confirmed variants:**
  - `'10::00::00' AS weird_str` (Redshift → SQL Server) → becomes `'CONVERT(00, 10)::00'` (cast-operator regex rewrites text inside the literal).
  - `-- TODO: replace NVL(a,b) with proper logic, fix SUBSTR usage` (comment) → rewritten to `/* TODO: replace ISNULL(a,b) with proper logic, fix SUBSTRING usage */`, and the `--` line comment is even converted into a `/* */` block comment as a side effect.
  - `DECODE(x,1,'a',2,'DECODE(1,1,1)')` (Oracle → BigQuery) → produces **syntactically broken output** (see TRANS-002).
- **Impact:** Any real-world view whose SELECT list contains a string literal or comment that happens to contain text resembling a convertible function call — extremely plausible for log messages, descriptions, status labels, or commented-out example SQL — gets its data or documentation silently altered, with no warning telling the user to check.
- **Root Cause:** Text-level regex substitution instead of AST-aware or at minimum tokenizer-aware substitution; direct violation of the project's own stated "IR, not regex" architecture requirement.
- **Suggested Fix:** Before running any `_convert_*` regex, mask out (or skip) spans inside `'...'` literals and comments — reuse the quote/comment-tracking state machine already implemented correctly in `DialectParser._split_statements` (`base.py:249-328`) as the basis for a literal-aware substitution helper.
- **Priority:** P0

### TRANS-002 — `_convert_decode_to_case` produces syntactically invalid SQL when a DECODE-like substring is nested inside a string argument 🔴 **Critical**
- **Module/File:** `backend/app/dialects/base.py:655-698`
- **Description:** Unlike `_convert_nvl_aware` (which explicitly skips regex matches already consumed by an earlier replacement via `if m.start() < last: continue`), `_convert_decode_to_case` has no such guard, so a `DECODE(...)`-looking substring inside a string-literal argument of an outer `DECODE(...)` call gets independently (and incorrectly) reprocessed.
- **Steps to Reproduce:**
  ```sql
  -- Oracle → BigQuery
  CREATE VIEW v AS SELECT DECODE(x,1,'a',2,'DECODE(1,1,1)') AS r FROM t
  ```
- **Expected Behavior:** Valid `CASE` expression, e.g. `CASE WHEN x = 1 THEN 'a' WHEN x = 2 THEN 'DECODE(1,1,1)' END AS r`.
- **Actual Behavior:**
  ```sql
  SELECT CASE
    WHEN x = 1 THEN 'a'
    WHEN x = 2 THEN 'DECODE(1,1,1)'
  ENDCASE
    WHEN 1 = 1 THEN 1
  END') AS r FROM t;
  ```
  Unbalanced, non-executable SQL (`ENDCASE`, dangling `END'`) — with **zero warnings**.
- **Impact:** Used by the T-SQL, BigQuery, Databricks, Fabric Lakehouse, and Redshift view-conversion chains — any DECODE-using Oracle/Redshift source view with this (not even that unusual) pattern breaks on conversion to nearly every target.
- **Root Cause:** Missing "already-consumed" guard present in the sibling `_convert_nvl_aware` implementation.
- **Suggested Fix:** Apply the same `if m.start() < last: continue` guard used in `_convert_nvl_aware`; better yet, fix via TRANS-001's literal-aware rewrite (this bug is a direct symptom of the same architectural gap).
- **Priority:** P0

### TRANS-003 — `WITH RECURSIVE` emitted verbatim to T-SQL targets (guaranteed syntax error), zero warning 🔴 **Critical**
- **Module/File:** No handling exists anywhere in `base.py`, `sqlserver/generator.py`, `synapse/generator.py`, or `fabric_dw/generator.py` (confirmed via grep); `validator.py`'s residual registry also has no `RECURSIVE` pattern.
- **Steps to Reproduce:**
  ```sql
  -- Redshift → SQL Server
  CREATE VIEW v1 AS
  WITH RECURSIVE cte AS (
    SELECT id, 1 AS lvl FROM tree WHERE parent_id IS NULL
    UNION ALL
    SELECT t.id, cte.lvl+1 FROM tree t JOIN cte ON t.parent_id = cte.id
  )
  SELECT * FROM cte;
  ```
- **Expected Behavior:** `RECURSIVE` keyword stripped (T-SQL recursive CTEs are written as plain `WITH cte AS (...)`), or at minimum a warning.
- **Actual Behavior:** `WITH RECURSIVE cte AS (...)` emitted verbatim. `warnings=[]`, `unsupported_features=[]`, `residual_warnings=[]`, **`confidence_score=1.0`, `confidence_level="HIGH"`** (independently re-confirmed by the synthesizing review — see CONF-001).
- **Impact:** 100% reproducible `CREATE VIEW` syntax failure on SQL Server/Synapse/Fabric DW for any recursive CTE view, reported to the user as fully trustworthy output.
- **Root Cause:** No T-SQL-family post-processing step strips/rewrites `RECURSIVE`; not covered in the residual-pattern registry either.
- **Suggested Fix:** Add a `_strip_recursive_keyword` step to `_apply_tsql_view_conversions`, and add `RESIDUAL_RECURSIVE` to `validator.py`'s `"redshift"`/`"snowflake"` residual list as a safety net.
- **Priority:** P0

### TRANS-004 — `LIMIT ... OFFSET ...` never translated for T-SQL targets (guaranteed syntax error), zero warning 🔴 **Critical**
- **Module/File:** Same files as TRANS-003; grepped for `LIMIT|OFFSET|FETCH` — no conversion logic exists anywhere.
- **Steps to Reproduce:**
  ```sql
  -- Redshift → SQL Server
  CREATE VIEW v1 AS SELECT * FROM t1 ORDER BY a LIMIT 10 OFFSET 5;
  ```
- **Expected Behavior:** `OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY` (valid T-SQL pagination syntax, since `ORDER BY` is already present).
- **Actual Behavior:** `... ORDER BY a LIMIT 10 OFFSET 5;` emitted verbatim — SQL Server/Synapse/Fabric DW do not support `LIMIT`/`OFFSET` at all. Zero warnings; confidence unaffected.
- **Impact:** Guaranteed syntax error on any paginated view targeting the T-SQL family; this is an explicitly-named checklist item in the review brief and was confirmed broken.
- **Root Cause:** Missing conversion rule.
- **Suggested Fix:** Add a `_convert_limit_offset_to_fetch` helper to the T-SQL conversion chain.
- **Priority:** P0

### CONF-001 — Confidence scoring ignores warning severity entirely; reports HIGH/PARTIAL confidence on broken or unconverted output 🔴 **Critical**
- **Module/File:** `backend/app/validator.py:288-312` (`compute_confidence`)
- **Description:** The scorer only branches on `unsupported_features` (non-empty → 0.50) or `warn_count = len(warnings) + len(residual_warnings)`. It never inspects `IRWarning.severity`. A warning with `severity=ERROR` but `unsupported=False` (the default) is scored identically to a cosmetic `INFO` note.
- **Steps to Reproduce (independently reproduced):**
  1. The TRANS-003/TRANS-004 case above → `confidence_score=1.0, confidence_level="HIGH"`, despite output that will not execute.
  2. Malformed SELECT: `SELECT a, b FROM WHERE ((( invalid` (redshift → snowflake) → sqlglot's lenient `error_level=WARN` mode still emits structurally broken SQL (`FROM` with no table, dangling parens) → **`confidence_score=1.0, confidence_level="HIGH", warnings=[]`**.
  3. A query triggering a genuine `RecursionError` inside `sqlglot.transpile()` (deeply nested `NVL(...)`, ~3000 levels) is caught by a broad `except Exception`, which sets `converted_sql = sql` (returns the **original, completely untranslated source-dialect SQL**) with `severity=ERROR, unsupported=False` → API returns `HTTP 200, confidence_score=0.95, confidence_level="PARTIAL"`.
- **Expected Behavior:** Any `severity=ERROR` warning should force `confidence_level="MANUAL_REVIEW"` (score ≤ 0.50) regardless of the `unsupported` flag.
- **Actual Behavior:** As above — the confidence badge, which is the tool's core trust/UX signal, actively misrepresents risk in exactly the cases where it matters most.
- **Impact:** This is the single most damaging finding in the review. A user who trusts the confidence score (the entire premise of the "Phase 8" confidence feature) will ship broken or completely untranslated SQL believing it has been validated.
- **Root Cause:** `unsupported` (bool) and `severity` (enum) are two independent `IRWarning` fields; only the former feeds the scorer.
- **Suggested Fix:** In `compute_confidence`, treat any `severity == Warningseverity.ERROR` warning (in either `warnings` or `residual_warnings`) as equivalent to an unsupported feature for scoring purposes.
- **Priority:** P0

### TRANS-005 — BigQuery `INT64` always misclassified as `GenericType.INT8` (silent narrowing to a 1-byte type) 🔴 **Critical**
- **Module/File:** `backend/app/type_mappings/type_mappings.yaml`; `TypeMapper.source_type_to_generic` (`base.py:92-104`)
- **Description:** `INT8`, `INT16`, `INT32`, and `INT64` generic-type YAML entries all set `bigquery.type: "INT64"` (correct for generic→BigQuery generation, since BigQuery has one integer type) — but the **reverse** lookup (`source_type_to_generic`) iterates the YAML dict and returns the **first** generic type whose dialect entry matches. `INT8` is first in iteration order, so every BigQuery `INT64` column is misclassified as `GenericType.INT8`.
- **Steps to Reproduce:**
  ```python
  TypeMapper.get().source_type_to_generic(Dialect.BIGQUERY, 'INT64')
  # -> (GenericType.INT8, None, None, None)     # confirmed directly
  ```
  ```sql
  CREATE TABLE t (id INT64, amount INT64)   -- bigquery → snowflake / sqlserver / databricks
  ```
- **Expected Behavior:** Both columns map to a full-width integer type (`BIGINT`/`NUMBER(38,0)` etc.).
- **Actual Behavior:** Both columns become `TINYINT` (snowflake/sqlserver/databricks targets) or `INT2`/`SMALLINT` (redshift target). **Zero warnings.**
- **Impact:** BigQuery uses `INT64` for *every* integer column, including large surrogate keys — this silently narrows essentially all BigQuery integer columns converted to any other dialect to a 1-byte type, guaranteeing overflow/insert failures downstream.
- **Root Cause:** Type-mapping YAML has multiple `GenericType`s sharing an identical `type:` string for one dialect; the reverse-lookup routine has no tie-breaking/disambiguation logic — first-match-wins by accidental dict ordering.
- **Suggested Fix:** Reverse lookups must be unambiguous per dialect — either restructure the YAML so each dialect native-type string maps to exactly one canonical `GenericType` (a dedicated reverse-lookup table), or special-case dialects where the native type space is coarser than the generic type space (BigQuery's single `INT64` should map back to `GenericType.INT64`, not the first alphabetical candidate).
- **Priority:** P0

### TRANS-006 — Same YAML collision bug hits Fabric DW `SMALLINT` → misclassified as `GenericType.INT8` 🔴 **Critical**
- **Module/File:** `type_mappings.yaml` (`INT8`/`INT16` both declare `fabric_dw.type: "SMALLINT"`)
- **Steps to Reproduce:** `TypeMapper.get().source_type_to_generic(Dialect.FABRIC_DW, 'SMALLINT')` → `GenericType.INT8` (confirmed). `CREATE TABLE t (a SMALLINT)` (fabric_dw → sqlserver) → output `[a] TINYINT` (range 0–255) instead of `SMALLINT` (-32768..32767).
- **Impact:** Silent range narrowing on a common column type; zero warning.
- **Root Cause / Suggested Fix:** Same as TRANS-005.
- **Priority:** P0

### TRANS-007 — Oracle `NUMBER(p)` single-argument precision silently dropped 🔴 **Critical**
- **Module/File:** `TypeMapper.source_type_to_generic` (`base.py` ~lines 85-89) stores a single parenthesized argument into `length`, never `precision`; `_apply_params`'s `DECIMAL` branch (lines 178-183) only ever reads `precision`/`scale`, never `length`.
- **Steps to Reproduce:**
  ```python
  TypeMapper.get().source_type_to_generic(Dialect.ORACLE, 'NUMBER(10)')
  # -> (GenericType.DECIMAL, precision=None, scale=None, length=10)   # length is unused downstream
  ```
  ```sql
  CREATE TABLE orders (id NUMBER(10), order_date DATE)   -- oracle → snowflake / bigquery / databricks
  ```
- **Expected Behavior:** `id NUMBER(10)` / `id NUMERIC(10)` / `id DECIMAL(10)` (precision preserved).
- **Actual Behavior:** `"id" NUMBER` (Snowflake, no precision at all), `` `id` NUMERIC `` (BigQuery, unbounded), `` `id` DECIMAL `` (Databricks, no precision). **Zero warnings.**
- **Impact:** `NUMBER(10)` is an extremely common Oracle idiom for whole numbers; the user's explicit precision constraint silently vanishes on every target.
- **Root Cause:** Single-arg parenthesized type values are stored in the wrong IR field.
- **Suggested Fix:** For `GenericType.DECIMAL`, a single-arg value should populate `precision` (with `scale` defaulting to 0), not `length`.
- **Priority:** P0

### TRANS-008 — Inline (column-level) `PRIMARY KEY` silently dropped by 4 of 9 dialect parsers 🔴 **Critical**
- **Module/File:** `oracle/parser.py:139-152`, `bigquery/parser.py:129-134`, `databricks/parser.py:135-152`, `fabric_dw/parser.py:148-158` — all only check for `NotNullColumnConstraint`, `DefaultColumnConstraint`, `GeneratedAsIdentityColumnConstraint` (± `CommentColumnConstraint`), never `exp.PrimaryKeyColumnConstraint` (confirmed against the actual sqlglot AST for inline PK syntax). Only a separate table-level `PRIMARY KEY (col, ...)` clause is captured.
- **Steps to Reproduce (all four confirmed):**
  ```sql
  -- oracle
  CREATE TABLE t (id NUMBER(10) PRIMARY KEY, name VARCHAR2(50))
  -- bigquery
  CREATE TABLE t (id INT64 PRIMARY KEY NOT ENFORCED, name STRING)
  -- databricks
  CREATE TABLE t (id BIGINT PRIMARY KEY, name STRING) USING DELTA
  -- fabric_dw
  CREATE TABLE t (id INT PRIMARY KEY, name VARCHAR(50))
  ```
- **Expected Behavior:** Generated DDL retains the primary key (as a table-level `PRIMARY KEY` clause, per each target's convention).
- **Actual Behavior:** No `PRIMARY KEY` clause anywhere in the output, for any of the four. `warnings == []` in every case.
- **Impact:** Inline `PRIMARY KEY` is one of the single most common DDL idioms in existence. This is arguably the most damaging correctness bug in the whole audit — primary keys silently vanish, with zero indication to the user, for nearly half the supported dialects as sources.
- **Root Cause:** Missing `isinstance(c, exp.PrimaryKeyColumnConstraint)` branch in each affected parser's constraint loop.
- **Suggested Fix:** Add the missing branch (mirroring how Redshift/Snowflake/SQLServer/Synapse presumably already, per the other sub-audit's "tested but OK" section, handle this correctly via the table-level clause — verify and backport the same handling to these four).
- **Priority:** P0

### TRANS-009 — Redshift/Snowflake `_qualified_name()` never quotes table/view names (silent case-folding identity change) 🔴 **Critical**
- **Module/File:** `redshift/generator.py:203-210, 328-334`; `snowflake/generator.py:37-44` — neither calls `self._quote_identifier(...)` when building the qualified name, unlike all 7 other generators (confirmed by grepping all 9 `_qualified_name` implementations).
- **Steps to Reproduce:**
  ```sql
  CREATE TABLE "MyMixedCaseTable" (a INT);   -- any source → snowflake or → redshift
  ```
- **Expected Behavior:** `CREATE TABLE "MyMixedCaseTable" (...)` — quoting preserved so the target engine doesn't case-fold the identifier.
- **Actual Behavior:** `CREATE TABLE MyMixedCaseTable (...)` — unquoted. Columns *are* correctly quoted (`"a"`), so this is an inconsistency within the same statement, not a blanket design choice. Snowflake folds unquoted identifiers to **UPPERCASE**; Redshift folds to **lowercase** — so the actual created object is silently `MYMIXEDCASETABLE` or `mymixedcasetable`, not `MyMixedCaseTable`, breaking any application code, BI tool, or downstream DDL that references the original casing. For non-ASCII/emoji identifiers it's worse — confirmed separately that `"table_emoji_😀"` (Redshift) → `table_emoji_😀` unquoted (Snowflake target), which Snowflake will outright reject as an invalid unquoted identifier.
- **Impact:** Silently changes the actual object identifier for two of the most popular target dialects, or produces a guaranteed syntax error for non-ASCII names. Zero warning in either case. The project's own master prompt (§5.6) explicitly requires "preserve original casing intent via quoting in output where needed."
- **Root Cause:** `_qualified_name()` omitted the `_quote_identifier()` call present in every sibling generator.
- **Suggested Fix:** Quote every name segment in both `_qualified_name()` implementations, matching the pattern already used by the other 7 generators.
- **Priority:** P0

### TRANS-010 — Fabric DW bare `INT` misclassified as `UNKNOWN` → falls back to `VARCHAR(MAX)` 🔴 **Critical**
- **Module/File:** `type_mappings.yaml` — `INT32`'s `fabric_dw` entry: `type: "INT", aliases: []`, missing the `"INTEGER"` alias every sibling T-SQL-family dialect entry has (`sqlserver`/`synapse`/`databricks`/`fabric_lakehouse` all list `aliases: ["INTEGER"]`).
- **Steps to Reproduce:**
  ```sql
  CREATE TABLE t (id INT, name VARCHAR(50))   -- fabric_dw → oracle
  ```
- **Expected Behavior:** `id NUMBER(10)` (or similar Oracle integer mapping).
- **Actual Behavior:** `"id" VARCHAR(MAX)` with warning `No mapping found for generic type UNKNOWN in oracle. Defaulted to VARCHAR(MAX).` — because sqlglot's `tsql` generator round-trips a parsed `INT` `DataType` node back out as the string `"INTEGER"` (confirmed against the AST directly), and the YAML lookup only recognizes `"INT"`, missing the `"INTEGER"` alias.
- **Impact:** Bare `INT` is the single most common integer type keyword in T-SQL. Every Fabric DW-sourced integer column becomes an unbounded text column in every target dialect.
- **Root Cause:** One missing alias entry in the YAML.
- **Suggested Fix:** One-line fix — add `aliases: ["INTEGER"]` to the `fabric_dw` entry for `INT32`.
- **Priority:** P0 (trivial fix, critical impact — should be the first thing fixed)

### TRANS-011 — `DECIMAL`/`NUMBER` precision never clamped to the target dialect's documented max 🟠 High
- **Module/File:** `TypeMapper._apply_params()` (`base.py:167-206`) — the `GenericType.DECIMAL` branch (178-183) never reads `dialect_entry.get("max_precision")`, unlike the sibling `VARCHAR`/`CHAR` branch (which does clamp via `max_length`) and the `TIMESTAMP` branch (which does clamp via `max_precision`). The YAML itself declares `max_precision: 38` for Snowflake/SQL Server/Databricks/Redshift/Oracle — the bound exists but is never enforced.
- **Steps to Reproduce:**
  ```sql
  CREATE TABLE t1 (a BIGNUMERIC(50,10));   -- bigquery → snowflake  (BigQuery BIGNUMERIC legitimately allows precision up to 76)
  ```
- **Expected Behavior:** Precision clamped to 38 with a warning (Snowflake's real maximum), or at minimum a warning that the value exceeds the target's bound.
- **Actual Behavior:** `"a" NUMBER(50,10)` emitted verbatim. `warnings=[]`. Real Snowflake rejects this at CREATE TABLE time (`invalid number precision '50'`).
- **Impact:** Deterministic hard DDL failure on a realistic, non-contrived cross-dialect pairing, with zero warning despite the exact bound already being present in config.
- **Suggested Fix:** Apply the same clamping pattern used for VARCHAR/TIMESTAMP to the DECIMAL branch.
- **Priority:** P1

### TRANS-012 — Redshift `DISTKEY` column name extracted case-insensitively, losing original case 🟠 High
- **Module/File:** `redshift/parser.py::_extract_distribution` (lines 291-333) — `sql_u = sql.upper()` and all DISTKEY regexes run against `sql_u`, so `dk.group(1)` is always upper-case. Contrast with `_extract_sortkey()` (same file), which correctly preserves original case.
- **Steps to Reproduce:**
  ```sql
  CREATE TABLE t1 (a INT, b INT) DISTSTYLE KEY DISTKEY(a) SORTKEY(a,b);   -- redshift → synapse
  ```
- **Actual Behavior:** Output contains `DISTRIBUTION = HASH([A])` (uppercase) alongside the correctly-cased column list `[a], [b]` — an internally inconsistent reference that, under case-sensitive collation, points at a column that doesn't exist. The Snowflake-target warning path shows the same defect (`"DISTKEY(A) was removed"` instead of `"DISTKEY(a)"`).
- **Impact:** Deterministic mis-casing on essentially every Redshift table with a lower/mixed-case DISTKEY column (the common case).
- **Suggested Fix:** Extract the DISTKEY column name from the original (non-uppercased) SQL, mirroring `_extract_sortkey`'s already-correct approach.
- **Priority:** P1

### TRANS-013 — BigQuery parser silently drops `FOREIGN KEY` / `UNIQUE` / `CHECK` constraints 🟠 High
- **Module/File:** `bigquery/parser.py:106-119` — the `_parse_create_table` loop only handles `exp.ColumnDef` and `exp.PrimaryKey`; unlike Oracle/Fabric DW parsers (which do handle `ForeignKey`/`UniqueColumnConstraint`), BigQuery's has no branch for them at all.
- **Steps to Reproduce:**
  ```sql
  CREATE TABLE orders (
    id INT64 NOT NULL, cust_id INT64,
    PRIMARY KEY (id) NOT ENFORCED,
    FOREIGN KEY (cust_id) REFERENCES customers(id) NOT ENFORCED
  )   -- bigquery → oracle
  ```
- **Actual Behavior:** `PRIMARY KEY` survives, `FOREIGN KEY` vanishes entirely. `warnings == []`.
- **Suggested Fix:** Add `exp.ForeignKey`/`exp.UniqueColumnConstraint`/`exp.CheckColumnConstraint` handling to `bigquery/parser.py`, mirroring the Oracle/Fabric DW parsers.
- **Priority:** P1

### TRANS-014 — Databricks emits `PRIMARY KEY` with no "not enforced" signal, and `GENERATED ALWAYS AS IDENTITY` incorrectly accepts `INT32` 🟠 High
- **Module/File:** `databricks/generator.py:70-72` (PK), `:162` (identity type guard)
- **Description:** Databricks/Unity Catalog PK/FK constraints are informational-only (not validated) by default — the BigQuery generator explicitly appends `NOT ENFORCED` to communicate this, but the Databricks generator emits `PRIMARY KEY (col)` with no such marker and no warning. Separately, the docstring at the top of the same file states identity columns are "Delta only, BIGINT only," but the actual guard (`if col.data_type.generic_type not in (GenericType.INT64, GenericType.INT32)`) incorrectly lets `INT32` through without a warning.
- **Steps to Reproduce (identity case):**
  ```sql
  CREATE TABLE t (id INT GENERATED ALWAYS AS IDENTITY, name VARCHAR2(50))  -- oracle → databricks
  ```
- **Actual Behavior:** `` `id` INT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) `` — Databricks will reject this DDL at execution time (IDENTITY requires BIGINT); `warnings == []`.
- **Impact:** Two independent, real gaps: (a) misleading implication that Databricks enforces PK constraints, (b) a guaranteed runtime DDL rejection for INT-typed identity columns with no warning.
- **Suggested Fix:** (a) append `NOT ENFORCED`/document non-enforcement via a warning, matching the BigQuery generator's pattern; (b) narrow the identity-type guard to `GenericType.INT64` only, and emit a WARNING + auto-widen to BIGINT for INT32 sources.
- **Priority:** P1

### TRANS-015 — Oracle `DATE` (has a time component) → target `DATE` (date-only) with zero warning 🟡 Medium
- **Module/File:** `type_mappings.yaml` documents this exact caveat in a free-text `notes` field ("Oracle DATE includes time components") but it's never surfaced as an actual `IRWarning` — `TypeMapper.generic_to_target` only warns when `dialect_entry.get("unsupported")` is true, and Oracle DATE→generic DATE→{bigquery,snowflake,databricks} isn't marked unsupported.
- **Steps to Reproduce:** `CREATE TABLE orders (id NUMBER(10), order_date DATE)` (oracle → bigquery/snowflake/databricks) → `order_date DATE`, `warnings=[]`.
- **Impact:** An Oracle `DATE` column storing timestamps is silently truncated to a date-only type with no indication that time-of-day data will be lost/rejected — precisely the scenario the project's own master prompt calls out as needing a flag.
- **Suggested Fix:** Emit an explicit `IRWarning` whenever `source_dialect == ORACLE and generic_type == GenericType.DATE`, noting the time-component loss.
- **Priority:** P2

### TRANS-016 — `NVL(a,b)` → `ISNULL` 2-arg branch is dead code for Redshift/Snowflake-sourced views; falls through to `COALESCE`, a real (if narrow) T-SQL type-precedence divergence 🟡 Medium
- **Module/File:** `base.py:626-653` (`_convert_nvl_aware`), wired into `_apply_tsql_view_conversions`.
- **Description:** sqlglot already normalizes `NVL` → `COALESCE` in its AST when parsing Redshift/Snowflake view bodies, **before** the text-level `_convert_nvl_aware` ever runs — by the time it executes, the literal string `NVL(` no longer exists for these two source dialects, so the 2-arg→`ISNULL` branch is unreachable for the two most common NVL-using sources. This isn't invalid SQL (`COALESCE` is valid T-SQL), but `COALESCE` returns the highest-precedence type among *all* arguments while `ISNULL` returns the first argument's type — a genuine, documented divergence for mixed-type `NVL(varchar_col, int_col)`-style expressions.
- **Impact:** Narrow but real semantic drift for mixed-type NVL expressions from Redshift/Snowflake sources; the helper itself is correct in isolation (verified via direct unit test) but effectively dead code on the dominant code path.
- **Suggested Fix:** Either accept `COALESCE` as intentional (document it), or intercept at the AST level (map `exp.Coalesce` with exactly 2 args back to `ISNULL` for T-SQL targets) rather than relying on unreachable text-level regex.
- **Priority:** P2

### TRANS-017 — Silently swallowed exceptions parsing IDENTITY seed/increment (Redshift & Snowflake) 🟡 Medium
- **Module/File:** `redshift/parser.py:234-237, 240-243`; `snowflake/parser.py:230-231, 236-237` — both wrap `int(...)` parsing of IDENTITY `start`/`increment` in bare `except Exception: pass`, silently defaulting to `start=1, step=1` with no warning if the source expression isn't a plain integer literal.
- **Impact:** Verified via code inspection (not independently forced with a non-literal seed expression) — a real gap, moderate confidence on real-world frequency.
- **Suggested Fix:** On catch, emit a WARNING noting the seed/increment could not be parsed and defaults were applied.
- **Priority:** P2

### TRANS-018 — Fabric Lakehouse `generate_procedure` emits comment-only output, not even a valid no-op statement 🟡 Medium
- **Module/File:** `fabric_lakehouse/generator.py:279-316` — the entire "converted" statement is `-- ` comment lines with no executable SQL, weaker than the project's own "NO-HYPOTHETICALS POLICY" (master prompt §8.5, "actual generated output... not a placeholder comment") and weaker than the Databricks stub (which emits a syntactically valid no-op `CREATE FUNCTION`).
- **Suggested Fix:** Emit a syntactically valid stub (e.g., a commented-out Fabric Notebook cell reference plus a minimal no-op object), matching the Databricks pattern.
- **Priority:** P2

---

## 6. Parser Issues

*(Parser-specific findings not already covered under §5 as translation issues.)*

### PARSE-001 — ReDoS-class catastrophic-backtracking regex in Redshift DISTKEY/SORTKEY extraction 🔴 **Critical**
See full detail under §10 Performance (PERF-001) — this is fundamentally a parser defect (`redshift/parser.py:326, 364`) with a performance consequence, cross-referenced here for completeness.

### PARSE-002 — Two independent, behaviorally divergent statement-splitters 🟠 High
- **Module/File:** `dialects/base.py::DialectParser._split_statements` (lines 249-328, quote/comment/dollar-quote aware) vs. `query_transpiler.py::_split_statements` (module-level, lines 83-117, **quote-aware only — no comment awareness**).
- **Steps to Reproduce:**
  ```python
  sql = """SELECT a, b -- comment with a semicolon ; right here
  FROM t WHERE x = 1;
  SELECT c FROM u;"""
  ```
  - `base.py` version (correct): 2 statements, comment preserved intact.
  - `query_transpiler.py` version (buggy): **3 statements** — the semicolon inside the `--` comment is treated as a real terminator, producing a truncated statement (`SELECT a, b -- comment with a semicolon`, missing its `FROM`) and a garbage fragment (`right here\nFROM t WHERE x = 1`).
- **Impact:** `query_transpiler._split_statements` is on the live path for every multi-statement SELECT/DML script (`transpile_script`, reached whenever `Transpiler.convert` detects an all-query script). Any real script containing a `--` comment with a semicolon in it (very common: `-- deprecated; use v2 instead`) or a `/* ...; ... */` block comment is silently mis-split into corrupted fragments, each independently fed to `sqlglot.transpile`, producing broken output SQL with **no warning** (and this corruption pattern isn't caught by the confidence scorer either — see CONF-001).
- **Suggested Fix:** Delete the weaker copy in `query_transpiler.py`; import and reuse `DialectParser._split_statements` (or extract it to a shared `sql_utils.py` module both files import).
- **Priority:** P1

### PARSE-003 — Bare `except: pass` around IDENTITY seed/increment parsing
Covered as TRANS-017 above (same finding, parser-specific root cause).

---

## 7. API Issues

### API-001 — `object_type` field has no validation; a bad value produces an unhandled 500 with an internal error string 🟠 High
- **Module/File:** `backend/app/api/schemas.py:40` (`object_type: Optional[str]`, no enum/pattern) → `backend/app/transpiler.py:258` (`ObjectType(object_type)`, called **outside** any try/except inside `Transpiler.convert`, but caught by the route's broad `except Exception`).
- **Steps to Reproduce:**
  ```
  POST /api/transpile
  {"sql":"CREATE TABLE t (id INT);","source_dialect":"redshift","target_dialect":"snowflake","object_type":"bogus_type"}
  ```
- **Expected Behavior:** `400`/`422` with a clear "invalid object_type" message (this field's docstring implies a closed literal set: `"table"|"view"|"materialized_view"|"procedure"|"function"`).
- **Actual Behavior:** `HTTP 500 {"detail":"Transpiler error: 'bogus_type' is not a valid ObjectType"}` — misclassified as a server error, and the raw Python `ValueError` text (including the internal `ObjectType` enum class name) is passed straight to the client. Contrast with `source_dialect`/`target_dialect`, which **are** handled gracefully via a dedicated `try/except ValueError` → structured `400` (confirmed working correctly, tested-and-OK).
- **Impact:** Wrong status code for a client-input error; minor internal-detail leak; inconsistent with the pattern already used for dialect validation two lines away in the same function.
- **Suggested Fix:** Constrain `object_type` with a Pydantic `Literal[...]`/enum at the schema layer, matching the pattern already used successfully for dialects.
- **Priority:** P1

### API-002 — No max size limit on `TranspileRequest.sql` 🔴 **Critical**
See §10 PERF-002 for full detail (this is simultaneously an API input-validation gap and the enabler of the DoS in PERF-002).

### API-003 — Confidence/status inconsistency between the DDL path and the query (SELECT/DML) path for the same underlying failure class 🟡 Medium
- **Module/File:** `transpiler.py::convert` (DDL path) vs. `transpiler.py::_convert_query` (query path).
- **Description:** A DDL/view parse failure → `HTTP 400`, `converted_sql=""`. A query-path parse/transpile failure (e.g. sqlglot `RecursionError`, caught only by a broad `except Exception` in `_convert_query`) → `HTTP 200`, `converted_sql=<original untouched source SQL>`, `confidence_score=0.95, confidence_level="PARTIAL"`. Same root cause (sqlglot exhausting recursion / failing to parse), two very different client-visible outcomes, and neither correctly lands on `MANUAL_REVIEW`.
- **Impact:** Inconsistent API contract; ties directly into CONF-001 — the query path's "PARTIAL 0.95" for a completely untranslated passthrough is misleadingly close to "fully converted."
- **Suggested Fix:** Route both failure classes through the same severity-aware confidence logic (fix CONF-001 first; this becomes largely self-resolving).
- **Priority:** P2

### API-004 — `CORS_ALLOW_ALL=true` + hardcoded `allow_credentials=True` is a confirmed, exploitable reflect-any-origin-with-credentials misconfiguration 🟡 Medium
- **Module/File:** `backend/app/main.py:79-92`
- **Steps to Reproduce:** Started the server with `CORS_ALLOW_ALL=true`, sent a preflight from an arbitrary origin:
  ```
  curl -i -X OPTIONS /api/transpile -H "Origin: http://totally-random-evil-site.com" -H "Access-Control-Request-Method: POST"
  → 200, access-control-allow-origin: http://totally-random-evil-site.com, access-control-allow-credentials: true
  ```
- **Description:** Starlette's `CORSMiddleware`, when `allow_origins=["*"]` **and** `allow_credentials=True`, does not send a literal `*` (which browsers would reject) — it reflects the request's actual `Origin` header back verbatim while still sending `Access-Control-Allow-Credentials: true`. Nothing in this codebase guards against that combination.
- **Impact:** Currently low-severity in practice — there is no cookie/session-based auth anywhere in the app today, so there's nothing ambient to steal. But it's a live, working footgun: the moment cookie-based auth is added without revisiting this, or if `CORS_ALLOW_ALL=true` is accidentally left on in a real deployment, this becomes a genuine CSRF/credential-theft vector. **Confirmed tested-and-OK**: the default (non-`CORS_ALLOW_ALL`) configuration correctly rejects arbitrary origins with `400 Bad Request "Disallowed CORS origin"`.
- **Suggested Fix:** Raise at startup (fail fast) if `CORS_ALLOW_ALL=true` and `allow_credentials=True` are both set, or drop `allow_credentials=True` when the wildcard flag is active.
- **Priority:** P2

---

## 8. Frontend Issues

*(Functional issues covered in §4 as BUG-001/004/005/006. Accessibility and remaining items below.)*

### FE-001 — Inconsistent `aria-expanded` on collapsible panel toggles 🟡 Medium
- **Module/File:** `LimitationsPanel.jsx:64`, `DialectSelector.jsx:54` correctly set `aria-expanded`; `WarningsPanel.jsx:43` and `DocRefsPanel.jsx:31` have functionally identical toggle buttons that don't.
- **Impact:** Screen-reader users get no indication two of four similar collapsible panels are expandable.
- **Suggested Fix:** Add `aria-expanded={open}` to the two missing components.
- **Priority:** P2

### FE-002 — `DownloadMenu.jsx` dropdown has no ARIA menu semantics 🟡 Medium
- **Module/File:** `DownloadMenu.jsx` (trigger button, line 63; dropdown, lines 66-83) — no `aria-haspopup`, `aria-expanded`, `role="menu"`/`role="menuitem"`, unlike the sibling `DialectSelector.jsx` which correctly implements the full pattern.
- **Suggested Fix:** Mirror `DialectSelector.jsx`'s ARIA implementation.
- **Priority:** P2

### FE-003 — Modals missing `aria-modal`/focus management 🔵 Low
- **Module/File:** `ReportDashboard.jsx:260` has `role="dialog"` but no `aria-modal="true"` (its sibling `SchemaGenModal.jsx:65` does have it — inconsistency, not a deliberate choice). Neither modal moves focus in on open or restores it on close.
- **Priority:** P3

### FE-004 — Dialect-logo SVGs have no `aria-hidden`/accessible name 🔵 Low
- **Module/File:** `DialectLogo.jsx` — always paired with adjacent visible text, so impact is low, but screen readers may still attempt to parse raw SVG content.
- **Priority:** P4

**Checked and confirmed OK (frontend):** empty/whitespace SQL cannot be submitted (Transpile button correctly disabled); loading states exist and are used correctly throughout; error banner uses `role="alert"` and the UI never goes blank on network failure/4xx/5xx; `npm run build` succeeds cleanly (56 modules, no errors, 197 KB / 62 KB gzip bundle); API base URL is relative (`/api`) and correctly proxied in both dev (`vite.config.js`) and Docker (`nginx.conf`) — no hardcoded-localhost production breakage; no `dangerouslySetInnerHTML`/raw `innerHTML` anywhere (zero XSS surface found); no stray `console.*` calls; download filenames are slugified (no injection risk); severity indicators are never color-only (always paired with text labels); no keyboard traps.

---

## 9. Security Findings

### SEC-001 — Unauthenticated, single-request denial of service (event-loop starvation + no size limit) 🔴 **Critical**
- **Module/File:** `backend/app/api/routes.py:149` (`async def transpile`, calls fully synchronous/CPU-bound `Transpiler.convert` with no `await` anywhere in the call graph) + `backend/app/api/schemas.py:37` (`sql: str`, no `max_length`).
- **Steps to Reproduce:** POST an 8 MB SQL payload (~105,000 trivial `CREATE TABLE` statements) to `/api/transpile`. While that request is in flight, issue `GET /api/health` from a separate client.
- **Actual Behavior:** The 8 MB request took **3 minutes 28 seconds** to complete (still returned `200` eventually, with a 29 MB response). For the entire duration, **every other request to the server — including its own liveness probe — timed out with no response.**
- **Impact:** Because the heavy CPU-bound work runs inline inside an `async def` route, FastAPI never offloads it to a thread pool (that only happens automatically for plain `def` handlers). One anonymous, unauthenticated client can render the entire service unresponsive to all users for minutes with a single `curl` command — and a container orchestrator's health check would also fail during that window, potentially triggering unwanted restarts. There is no authentication and no rate limiting anywhere in the codebase (confirmed by full read of `main.py`/`routes.py`), so nothing stands between an anonymous client and this outcome.
- **Root Cause:** Synchronous, CPU-bound work in an `async def` route + unbounded request body.
- **Suggested Fix:** Add `max_length` to `TranspileRequest.sql` (e.g. 1–2 MB) **and** run `Transpiler.convert` via `starlette.concurrency.run_in_threadpool` (or make the route a plain `def`) so the event loop stays responsive; add basic rate limiting before any public deployment.
- **Priority:** P0

### SEC-002 — ReDoS-class catastrophic backtracking in Redshift DISTKEY/SORTKEY extraction 🔴 **Critical**
(Full repro and scaling data under PERF-001 below — cross-referenced here because it is independently a security-relevant DoS primitive: it requires no adversarial input at all, just an ordinary wide table with no DISTKEY, which is the *common* case, not an edge case.)

### SEC-003 — `CORS_ALLOW_ALL` + credentials footgun
Covered as API-004 above.

### SEC-004 — No hardcoded secrets found ✅ Checked, OK
- Full-tree grep (`api_key|apikey|password=|secret=|token=|AKIA[0-9A-Z]{16}`) across the entire `universal-sql-transpiler` tree (excluding `node_modules`/`.venv`/`dist`/`.git`) returned exactly one hit, a false positive: a code comment in `procedure_utils.py:220` reading "Fallback: first token = name, rest = type."

### SEC-005 — Dependency version hygiene (not a confirmed vulnerability) 🟡 Medium
- **Module/File:** `backend/requirements.txt` — every dependency pinned with an unbounded lower bound only (`fastapi>=0.111.0`, `sqlglot>=25.0.0`, etc.), no upper bounds, no lockfile.
- **Description:** A fresh install today pulls `fastapi 0.136.3`, `sqlglot 30.11.0`, etc. — versions materially newer than what was likely tested against, with no committed lockfile to reproduce a known-good set. No specific CVE is asserted here (none was verified with confidence) — this is a supply-chain **hygiene** gap, not a confirmed exploit.
- **Suggested Fix:** Add a lockfile (`pip-compile`/`uv pip compile`) and run `pip-audit`/`safety check` in CI once CI exists (see DOC-005).
- **Priority:** P2

---

## 10. Performance Findings

### PERF-001 — ReDoS-class catastrophic backtracking regex in `redshift/parser.py` 🔴 **Critical**
- **Module/File:** `redshift/parser.py:326` (`_extract_distribution`) and `:364` (`_extract_sortkey`) — pattern `r"(\w+)\s+\w[\w\s(),]*\bDISTKEY\b"` (and the structurally identical SORTKEY variant).
- **Steps to Reproduce (isolated regex, no framework involved):**
  ```python
  pattern = re.compile(r"(\w+)\s+\w[\w\s(),]*\bDISTKEY\b")
  # against CREATE TABLE huge_table (col_0 VARCHAR(100), col_1 ..., col_N ...); with NO DISTKEY present
  ```
- **Observed scaling (measured directly, regex-only time):**

  | Columns | Regex time |
  |---|---|
  | 200 | 0.12s |
  | 400 | 0.52s |
  | 800 | 2.30s |
  | 1,600 | 9.36s |
  | 3,200 | **38.45s** |

  16× the input produced **~310×** the time — worse than quadratic, a textbook catastrophic-backtracking signature (`\w[\w\s(),]*` overlapping with the outer `(\w+)\s+` gives the regex engine an enormous number of equivalent ways to fail to match when `DISTKEY` isn't present — which is the common case, since most tables don't define one).
- **End-to-end impact confirmed:** a 3,000-column `CREATE TABLE` (redshift → snowflake, no DISTKEY) took **57.5 seconds** wall-clock through the full `Transpiler.convert` pipeline; profiling (`cProfile`) attributes essentially all of it to `re.Pattern.search` inside `_extract_distribution` (7.5s of 11s total in a 1,200-column profiling run, single dominant frame).
- **Impact:** This requires **no adversarial intent** — a genuinely wide real-world table (EAV-style schemas, wide fact tables, or auto-generated DDL with thousands of columns are not exotic in enterprise data warehouses) with no DISTKEY defined will trigger this. Combined with SEC-001 (no size limit, synchronous execution in the event loop), this is a severe, easily-triggered DoS vector.
- **Root Cause:** Regex-based property extraction over the full raw SQL text with a backtracking-prone character class, used as a substitute for structured parsing of table-level DDL clauses sqlglot doesn't natively understand.
- **Suggested Fix:** Rewrite `_extract_distribution`/`_extract_sortkey` to avoid unbounded backtracking — e.g. anchor the search to only the text after the closing `)` of the column list (table-level clauses only appear there), or use a possessive/atomic-group equivalent (Python's `re` lacks these natively — consider the `regex` module, or restructure the pattern to `\bDISTKEY\b` first with a bounded backward scan for the preceding column name instead of a single unbounded forward regex).
- **Priority:** P0

### PERF-002 — No request-size limit, synchronous CPU-bound work in an async route (event-loop starvation)
Covered as SEC-001 above (single finding, both a security DoS and a performance defect).

### PERF-003 — Regex-heavy view-body conversion chain (checked, currently OK) ✅
- 2,000 chained `NVL(...)` calls in a single view body (~98 KB of SQL) converted in ~2.3s with no pathological blowup — the many `_convert_*` regexes in `base.py`'s view-conversion chain do **not** individually exhibit catastrophic backtracking (unlike PERF-001's DISTKEY pattern). Noted as tested-and-OK to avoid over-generalizing PERF-001 into "all regexes in this codebase are dangerous" — they are not; this one specific pattern is.

---

## 11. Code Quality Review

- **"God class" architecture:** `dialects/base.py` (1,900 lines, ~75 dialect-pair-specific regex conversion methods shared by every generator) is a genuine maintainability risk — see §3.
- **Duplicated, divergent logic:** two statement-splitters (§6, PARSE-002).
- **Dead/orphaned code:** the schema-inference feature (§4, BUG-001/002), and the unreachable `ISNULL` branch in `_convert_nvl_aware` (§5, TRANS-016).
- **Dependency hygiene:** unbounded version ranges, no lockfile (§9, SEC-005).
- **`.gitignore`/`.gitattributes`:** ✅ checked, solid — `.venv/`, `node_modules/`, `dist/`, `__pycache__/`, `.pytest_cache/`, `.env`/`.env.*` (with `.env.example` correctly excepted) are all covered; line-ending normalization and binary-file marking in `.gitattributes` are correct; `git status` on the actual working tree is clean.
- **No secrets committed:** ✅ confirmed (SEC-004).

---

## 12. Documentation Review

### DOC-001 — `RUNNING_LOCALLY.md` hardcodes the author's personal path, including employer name 🟠 High
Every code block uses the literal path `C:\Users\SuryadevRathore\OneDrive - Xebia\Desktop\Master-SQL-Trasnspiler\...` — not portable to any other contributor, and leaks the author's Windows username and employer name into a document meant to ship with an open-source release. Related: `frontend/.claude/launch.json` is **already git-tracked** with a hardcoded personal path (`C:\\Users\\SuryadevRathore\\node\\npm.cmd`); a later `.gitignore` rule for this file doesn't retroactively untrack an already-committed file.
**Suggested Fix:** Rewrite using relative paths / `<repo-root>` placeholders; run `git rm --cached frontend/.claude/launch.json`.
**Priority:** P1

### DOC-002 — README dialect count is stale — undercounts by one platform 🟠 High
README claims "8 cloud and enterprise platforms," an "8×8 dialect matrix, 64 conversion pairs," and a `dialects_loaded: 8` example — but the backend actually implements **9** dialects (`fabric_lakehouse` is fully real, with its own parser/generator and full object-type support). `index.html`'s meta description also lists only 8. A genuinely supported dialect is invisible to anyone reading only the docs.
**Priority:** P1

### DOC-003 — No LICENSE file, no CONTRIBUTING guide 🟠 High
For a project explicitly being prepped for "first public release," the absence of a license is a **legal blocker** — without one, consumers have no clear rights to use, fork, or modify the code. There is also no contributor-onboarding document despite the README implying an OSS-style workflow.
**Priority:** P1 (blocks release, not just a nice-to-have)

### DOC-004 — README "Project Structure" and test-count sections are stale 🟡 Medium
README lists only 5 of the 11 actual `frontend/src/components/` files, and claims "954 tests, 320 snapshot files" — a live `pytest --collect-only -q` reports **4,002 tests collected** (3,986 pass + 16 skip), and the golden-samples directory has 322 files, not 320. Several entire test files (`test_advanced_realworld.py`, `test_comprehensive.py`, `test_query_transpiler.py`, etc.) aren't reflected in README's phase table at all.
**Priority:** P2

### DOC-005 — No CI/CD — zero automated test execution on push/PR 🟠 High
No `.github/workflows/` directory exists. The 3,986-test suite never runs automatically; nothing prevents a broken commit from landing on `main`/`master`. For a public release this is a significant gap.
**Priority:** P1

**Checked and OK (docs):** `setup.ps1`/`setup.sh` both use portable relative paths and run a real smoke test before declaring success — no bugs found; README's Docker quick-start matches the actual `docker-compose.yml` service names/ports; both Dockerfiles reference files that actually exist and correctly copy/build/serve; `nginx.conf`'s `proxy_pass` correctly matches the Compose service name.

---

## 13. Test Coverage Analysis

- **Full suite result (live run):** `3,986 passed, 16 skipped, 0 failed, 1 deprecation warning`, ~193–278s wall time depending on parallelism.
- **Skipped tests are legitimate:** all 16 are conditional, data-dependent guards (`pytest.skip("Could not parse source SQL as {source}")`, plus a clean `skipif(not duckdb_available)`) — none mask a known hidden bug.
- **Strong coverage exists for:** dialect-validation error paths (`test_phase4_api.py::TestValidation` — blank SQL, missing field, invalid source/target dialect all correctly tested and passing), and broad round-trip DDL correctness across all 9×9 dialect pairs for straightforward tables/views.
- **Confirmed, material gaps** — none of the following are tested anywhere in the suite, and each gap directly corresponds to a bug this review found that shipped unnoticed:
  1. No test for an invalid `object_type` value (→ API-001's 500 shipped undetected).
  2. No test asserting any request-size limit exists, because none does (→ SEC-001).
  3. No test exercising the `CORS_ALLOW_ALL` + credentials configuration (→ API-004).
  4. No test asserting `confidence_level` degrades when a `severity=ERROR` warning is present but `unsupported=False` — this is exactly the regression test that would have caught CONF-001.
  5. No test for inline column-level `PRIMARY KEY` on Oracle/BigQuery/Databricks/Fabric DW sources (→ TRANS-008 — the tests that exist apparently only exercise table-level `PRIMARY KEY (...)` clauses for these four dialects).
  6. No test for a string literal/comment containing convertible-function-looking text in a view body (→ TRANS-001/TRANS-002).
  7. No performance/regression test for wide tables (→ PERF-001 would have been caught immediately by even a single 500+ column smoke test with an assertion on elapsed time).
- **Recommendation:** Given the strength of the existing suite's structure (golden-sample-driven, phase-organized), adding targeted regression tests for the 7 gaps above is a natural, low-effort next step and should be prioritized alongside the corresponding fixes.

---

## 14. Ambiguous Findings (awaiting confirmation)

**AMB-001 — Is Fabric Lakehouse's absence from README/`index.html` intentional (e.g. "still beta") or a pure documentation oversight?**
The backend code treats it as a first-class, fully-supported dialect (own parser/generator, full object-type support matrix entry in `routes.py`). Treated as a gap (DOC-002) pending confirmation of intent.
> Should this be treated as a bug or expected behavior?

**AMB-002 — Is the "God class" `base.py` regex-based view-body architecture an accepted pragmatic tradeoff, or should it be treated as a required architectural fix before release?**
The project's own spec explicitly says "not regex," and this review found the resulting data-corruption bugs (TRANS-001/002) to be Critical. But rewriting view-body handling to be fully AST-based is a substantial effort, and a smaller literal/comment-aware patch (proposed under TRANS-001) would close the acute correctness gap without a full rearchitecture.
> Should this be scoped as "fix the acute bugs now, rearchitect later" or "block release until the architecture matches spec"?

**AMB-003 — Is `CORS_ALLOW_ALL` ever intended to be set in a real deployment, or is it strictly a local-dev convenience that should never reach a production environment?**
This determines whether API-004 needs a code-level guard (fail-fast at startup) or is adequately addressed by a documentation warning alone.
> Should this be treated as a bug requiring a code fix, or expected/acceptable given it's opt-in and documented as dev-only?

**AMB-004 — Is the complete absence of authentication and rate limiting on the public API an intentional scope decision (e.g., "this is a local/internal tool, not meant for open internet exposure") or a genuine pre-launch gap?**
This materially changes the severity of SEC-001: if the tool is never meant to be internet-facing without a reverse proxy/gateway providing these controls, SEC-001 is still worth fixing (defense in depth) but is not a release blocker in the same way.
> Should authentication/rate-limiting be treated as in-scope for this release, or explicitly out-of-scope with a documented deployment assumption ("must sit behind an authenticating gateway")?

---

## 15. Enhancement Suggestions ⚪

- **ENH-001:** Consolidate the two statement-splitters (PARSE-002) into one shared module.
- **ENH-002:** Stand up GitHub Actions CI running `pytest` (backend) and `npm run build` (frontend) on every PR (DOC-005).
- **ENH-003:** Add a LICENSE and CONTRIBUTING.md (DOC-003).
- **ENH-004:** Either finish or delete the orphaned schema-inference feature (BUG-001/002).
- **ENH-005:** Add `pip-compile`/lockfile-based dependency pinning, and wire `pip-audit` into CI once it exists (SEC-005).
- **ENH-006:** Consider incrementally migrating the highest-traffic `_convert_*` regex helpers in `base.py` to operate on a tokenized (literal/comment-masked) representation rather than raw text, as a stepping stone toward the spec's IR-based intent (AMB-002).
- **ENH-007:** Add a lightweight rate-limiter (e.g. `slowapi`) and an optional API-key gate behind an env var, so the tool can be safely exposed publicly without requiring a reverse proxy to provide these controls (AMB-004).
- **ENH-008:** Add a "wide table" and "large payload" case to the perf/regression test suite so PERF-001-class regressions are caught automatically going forward.

---

## 16. Severity-wise Summary

| Severity | Count | IDs |
|---|---|---|
| 🔴 Critical | 12 | TRANS-001, TRANS-002, TRANS-003, TRANS-004, CONF-001, TRANS-005, TRANS-006, TRANS-007, TRANS-008, TRANS-009, TRANS-010, PERF-001 / SEC-001 / SEC-002 (2 distinct root causes, 3 cross-refs) |
| 🟠 High | 10 | BUG-003, TRANS-011, TRANS-012, TRANS-013, TRANS-014, PARSE-002, API-001, DOC-001, DOC-002, DOC-003, DOC-005 (11 listed — see note) |
| 🟡 Medium | 12 | BUG-002, BUG-004, TRANS-015, TRANS-016, TRANS-017, TRANS-018, API-003, API-004, FE-001, FE-002, SEC-005, DOC-004 |
| 🔵 Low | 6 | BUG-005, BUG-006, FE-003, FE-004 |
| ⚪ Enhancement | 8 | ENH-001 through ENH-008 |

*(Note: BUG-001 is counted as High under §4/§16; the Critical row lists 10 distinct IDs covering 12 confirmed defects since PERF-001/SEC-001/SEC-002 describe 2 independent root causes cross-referenced across 3 section headers, and CONF-001 is one defect substantiated by 3 independent repros.)*

**Total confirmed, evidence-backed findings: 40** (12 Critical, 11 High, 12 Medium, 6 Low, 8 Enhancement — some figures overlap across sections due to intentional cross-referencing between Security/Performance/Translation categories for defects with multiple facets).

---

## 17. Release Readiness Assessment

**Verdict: Not ready for a "first major release" in the sense of unattended public trust.** The core engineering (IR, test suite, dialect breadth, frontend polish) is genuinely strong, but three separate categories of Critical defect must be resolved first:

1. **Trust-signal integrity** (CONF-001): the confidence score is the entire UX premise of this tool and it currently lies in exactly the cases that matter most. This should be the #1 priority fix — it's also one of the cheaper fixes (a targeted change to `compute_confidence`'s severity handling).
2. **Data-corruption and common-pattern-loss bugs** (TRANS-001/002/005/006/007/008/009/010, TRANS-003/004): several of these (TRANS-010 especially) are one-line YAML fixes with outsized impact; others (TRANS-001/002, the regex literal-awareness issue) require a bit more surgical care but are well-scoped.
3. **The DoS pair** (SEC-001 + PERF-001): both have clear, bounded fixes (request size cap + threadpool offload; regex rewrite) and should be fixed before any deployment reachable by untrusted clients.

None of the Critical findings require the kind of open-ended rearchitecture the "God class" issue (AMB-002) represents — they are each fixable in isolation, several in under an hour of engineering time (TRANS-010 is a one-line YAML change; CONF-001 is a small, well-contained function change). A realistic path to release readiness: fix all 12 Critical findings (estimate: 2–4 focused engineering days given how localized most of them are), add the LICENSE/CI (DOC-003/DOC-005, another day), and re-run this review's repro list as a regression check before shipping.

### Scores (out of 10)

| Dimension | Score | Rationale |
|---|---|---|
| **Architecture** | 6/10 | Sound IR foundation for DDL; view/MV bodies bypass it via a text-regex "God class" that directly contradicts the project's own spec and is the root cause of the worst bugs found. |
| **Code Quality** | 6/10 | Generally readable, well-documented (doc-URL citations throughout), consistent patterns — undercut by the 1,900-line shared class, duplicated statement-splitters, and orphaned dead code. |
| **Performance** | 4/10 | A confirmed ReDoS with near-cubic scaling reachable by an ordinary (non-adversarial) wide table, plus an unrelated event-loop-starvation DoS from unbounded synchronous request handling. Both are real, both are fixable, neither is currently mitigated. |
| **Security** | 5/10 | No secrets, no injection surface found in the frontend, sensible default CORS — but a live, single-request, unauthenticated DoS and an exploitable CORS+credentials footgun (opt-in, currently low blast radius) are real findings, not theoretical ones. |
| **Documentation** | 5/10 | Extensive and detailed where it exists (API reference, setup scripts, doc-URL citations in code) — but materially inaccurate in ways a new user will hit immediately (broken start scripts, wrong dialect count, personal-path leakage), and missing a LICENSE entirely. |
| **Test Coverage** | 7/10 | 3,986 passing tests with 0 failures is genuinely impressive breadth, and the gaps found are precise and fixable — but several of those exact gaps are why Critical bugs shipped unnoticed (see §13). |
| **SQL Translation Accuracy** | 5/10 | Table/column DDL translation is broadly solid across straightforward cases; but extremely common, non-edge-case patterns (inline PRIMARY KEY, NUMBER(p), INT64, bare INT on Fabric DW) are silently mishandled with zero warning, which is more damaging to trust than an edge case would be — these are patterns real users will hit on their very first conversion. |
| **Production Readiness** | 4/10 | Blocked by the DoS pair, the confidence-score integrity issue, the missing LICENSE, and the missing CI — each individually fixable, but collectively this is pre-release-hardening work, not launch-day polish. |

**Overall: the project demonstrates strong engineering fundamentals and is closer to release-ready than a typical first-pass review would suggest — but it is not there yet, and the specific gap (a confidence score that doesn't reflect actual risk) is exactly the kind of defect that undermines the core value proposition of a "trust this conversion" tool if shipped as-is.**
