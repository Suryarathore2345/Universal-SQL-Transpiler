<p align="center">
  <img src="frontend/public/logo.png" alt="UST — Universal SQL Transpiler" width="160" />
</p>

<h1 align="center">Universal SQL Transpiler</h1>
<p align="center"><strong>Write Once. Run Anywhere.</strong></p>

<p align="center">
  Convert SQL DDL — tables, views, materialized views, stored procedures, and functions —
  between cloud and enterprise database platforms through one universal engine.
</p>

<p align="center">
  <a href="https://ust-frontend.onrender.com"><strong>Try UST →</strong></a>
  &nbsp;·&nbsp;
  <a href="https://ust-backend-mgt0.onrender.com/api/docs"><strong>API Docs →</strong></a>
  &nbsp;·&nbsp;
  <a href="https://github.com/Suryarathore2345/Universal-SQL-Transpiler"><strong>GitHub →</strong></a>
</p>

<p align="center">
  <sub>Both links run on Render's free tier — the backend sleeps after ~15 min idle, so the first request after a quiet period takes ~30–50s to cold-start.</sub>
</p>

<br/>

<table align="center">
  <tr>
    <td align="center"><h3>9</h3>Platforms</td>
    <td align="center"><h3>81</h3>Conversion Paths</td>
    <td align="center"><h3>5</h3>SQL Object Types</td>
    <td align="center"><h3>4,002</h3>Tests</td>
  </tr>
</table>

---

## Table of Contents

1. [Supported Platforms](#supported-platforms)
2. [Why UST?](#why-ust)
3. [How It Works](#how-it-works)
4. [Conversion Example](#conversion-example)
5. [Architecture](#architecture)
6. [Supported Objects](#supported-objects)
7. [Conversion Matrix](#conversion-matrix)
8. [Warnings & Conversion Intelligence](#warnings--conversion-intelligence)
9. [API Reference](#api-reference)
10. [Quick Start](#quick-start)
11. [Testing](#testing)
12. [Project Structure](#project-structure)
13. [Contributing / License](#contributing--license)

---

## Supported Platforms

<p align="center">
  <img src="docs/images/ust_platform_ecosystem.png" alt="UST platform ecosystem — Redshift, Snowflake, SQL Server, Synapse, Fabric DW, Fabric Lakehouse, Databricks, Oracle, BigQuery" width="100%" />
</p>

**Amazon Redshift · Snowflake · Microsoft SQL Server · Azure Synapse Analytics · Microsoft Fabric Data Warehouse · Microsoft Fabric Lakehouse · Databricks (Delta Lake) · Oracle Database · Google BigQuery**

---

## Why UST?

| | |
|---|---|
| **Universal IR** | An Intermediate Representation means adding a dialect requires 1 parser + 1 generator — not N × N adapters. |
| **81 Conversion Paths** | A 9 × 9 source-to-target dialect matrix — any supported platform to any other. |
| **5 SQL Object Types** | `TABLE`, `VIEW`, `MATERIALIZED VIEW`, `PROCEDURE`, `FUNCTION`. |
| **Conversion Warnings** | Every changed, dropped, unsupported, or fallback feature is flagged — not silently papered over. |
| **Documentation References** | Vendor documentation links are attached to relevant conversion differences. |
| **Extensive Testing** | 4,002 tests, including 322 golden snapshot files, run on every push. |

---

## How It Works

<p align="center">
  <img src="docs/images/ust_conversion_flow.png" alt="UST conversion flow — select source dialect, write or paste DDL, select target dialect, convert" width="100%" />
</p>

Pick a source dialect, write or paste DDL into the Monaco-powered editor, pick a target dialect, and convert. UST parses the input, normalizes it into its intermediate representation, and generates target SQL along with any warnings and documentation references.

---

## Conversion Example

<p align="center">
  <img src="docs/images/ust_conversion_example.png" alt="Conversion example — Snowflake CREATE TABLE converted to Databricks, with type mapping applied" width="100%" />
</p>

---

## Architecture

```
SQL input → Source Parser → Intermediate Representation (IR) → Target Generator → SQL output + warnings + doc links
```

The IR layer is what keeps this tractable at 9 dialects: adding a new one requires **1 parser + 1 generator**, not N × N adapters.

<p align="center">
  <img src="docs/images/ust_architecture_high_level.png" alt="UST high-level architecture — SQL input, source parser, intermediate representation, target generator, output" width="100%" />
</p>

---

## Supported Objects

<p align="center">
  <img src="docs/images/ust_supported_objects.png" alt="Supported object types — Table, View, Materialized View, Procedure, Function" width="100%" />
</p>

### Object type support matrix

| Dialect | TABLE | VIEW | MAT. VIEW | PROCEDURE | FUNCTION |
|---|:---:|:---:|:---:|:---:|:---:|
| Redshift | ✅ | ✅ | ✅ | ✅ | ✅ |
| Snowflake | ✅ | ✅ | ✅ ¹ | ✅ | ✅ |
| SQL Server | ✅ | ✅ | ⚠️ ² | ✅ | ✅ |
| Synapse | ✅ | ✅ | ✅ | ✅ | ✅ |
| Fabric DW | ✅ | ✅ | ❌ ³ | ✅ | ✅ |
| Fabric Lakehouse | ✅ | ✅ | ✅ ⁵ | ❌ ⁶ | ✅ |
| Databricks | ✅ | ✅ | ✅ | ✅ ⁴ | ✅ |
| Oracle | ✅ | ✅ | ✅ | ✅ | ✅ |
| BigQuery | ✅ | ✅ | ✅ | ✅ | ✅ |

¹ Requires Enterprise Edition or higher.
² Converted to indexed view with `WITH SCHEMABINDING` — query may need adjustments.
³ Converted to a regular VIEW — no automatic refresh.
⁴ Requires Databricks Runtime 17.0+ and Unity Catalog (not supported with Hive Metastore).
⁵ Materialized Lake Views (MLV) require Fabric Runtime 1.3+.
⁶ No stored procedures on Spark SQL — converted to a SQL function stub; use a Fabric Notebook for real procedural logic.

---

## Conversion Matrix

UST supports 9 dialects, providing **81 possible source-to-target conversion paths**.

<p align="center">
  <img src="docs/images/ust_conversion_matrix_9x9.png" alt="9 by 9 dialect conversion matrix — every source dialect supports converting to every other target dialect" width="100%" />
</p>

---

## Warnings & Conversion Intelligence

UST does not pretend every conversion is identical — every changed, dropped, unsupported, or fallback feature surfaces as a warning with a severity level:

| Severity | Meaning |
|---|---|
| `INFO` | The conversion is complete and semantically equivalent; noted for awareness (e.g. a type mapping was applied). |
| `WARNING` | The output is usable but behaves differently, was approximated, or needs review before deploying. |
| `ERROR` | No safe automatic conversion exists — manual intervention is required. |

### Key per-target limitations

| Target | Limitation | Level |
|---|---|---|
| Snowflake | DISTKEY removed (managed automatically) | warn |
| Snowflake | Procedure bodies wrapped as-is — Snowflake Scripting differs | warn |
| SQL Server | MV → indexed view, SELECT must use two-part names | warn |
| Synapse | Every table needs explicit DISTRIBUTION | warn |
| Fabric DW | No materialized views | **error** |
| Databricks | Stored procedures require DBR 17.0+ and Unity Catalog | info |
| Databricks | CLUSTER BY and PARTITIONED BY are mutually exclusive | warn |
| Oracle | DATE type includes time component | info |
| BigQuery | No IDENTITY columns | warn |
| BigQuery | PK/FK are NOT ENFORCED | info |

Full limitations are returned by `GET /api/limitations` and shown in the UI's limitations panel.

---

## API Reference

The backend exposes endpoints under `/api`. Full interactive docs (request/response schemas, live "Try it out"): [ust-backend-mgt0.onrender.com/api/docs](https://ust-backend-mgt0.onrender.com/api/docs) (or `http://localhost:8000/api/docs` locally).

| Endpoint | Description |
|---|---|
| `POST /api/transpile` | Convert SQL from one dialect to another. Body: `sql`, `source_dialect`, `target_dialect`, optional `object_type` and `include_ir`. Returns converted SQL plus warnings, unsupported features, and doc references. |
| `GET /api/dialects` | List all supported dialects with display metadata. |
| `GET /api/limitations` | Known transpilation limitations for target dialects. Optional `?dialect=snowflake`. |
| `GET /api/health` | Liveness probe — `{ "status": "ok", "version": "1.0.0", "dialects_loaded": 9 }`. |

**Dialect keys**

| Key | Platform |
|---|---|
| `redshift` | Amazon Redshift |
| `snowflake` | Snowflake |
| `sqlserver` | Microsoft SQL Server |
| `synapse` | Azure Synapse Analytics |
| `fabric_dw` | Microsoft Fabric Data Warehouse |
| `fabric_lakehouse` | Microsoft Fabric Lakehouse |
| `databricks` | Databricks (Delta Lake) |
| `oracle` | Oracle Database |
| `bigquery` | Google BigQuery |

---

## Quick Start

### Prerequisites

| Tool | Minimum version | Notes |
|---|---|---|
| Python | 3.11 | 3.12 recommended |
| Node.js | 18 LTS | 20 LTS recommended |
| npm | 9+ | Bundled with Node.js |
| Docker + Compose | 24+ | Only needed for the Docker path |

### Docker (recommended)

No Python or Node.js required on the host.

```bash
cd universal-sql-transpiler
docker compose up --build
```

| URL | Service |
|---|---|
| http://localhost | Frontend UI |
| http://localhost:8000/api/docs | FastAPI interactive docs (Swagger) |
| http://localhost:8000/api/health | Health check |

To stop: `docker compose down`

### Local Development Setup

<details>
<summary><strong>Windows (PowerShell)</strong></summary>

Open PowerShell in the project root and run:

```powershell
.\setup.ps1
```

The script will:
1. Verify Python 3.11+ and Node.js 18+ are on `PATH`
2. Create `backend\.venv` and install all Python packages
3. Run `npm install` in `frontend/`
4. Run a smoke test to confirm the transpiler loads

After setup completes, start the two services in separate terminals:

**Terminal 1 — Backend**

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
uvicorn app.main:app --reload
```

**Terminal 2 — Frontend**

```powershell
cd frontend
npm run dev
```

Open **http://localhost:5173** in your browser.

</details>

<details>
<summary><strong>Linux / macOS (bash)</strong></summary>

```bash
bash setup.sh
```

The script performs the same steps as the Windows version.

After setup, start both services:

**Terminal 1 — Backend**

```bash
cd backend
source .venv/bin/activate
uvicorn app.main:app --reload
```

**Terminal 2 — Frontend**

```bash
cd frontend
npm run dev
```

Open **http://localhost:5173** in your browser.

</details>

<details>
<summary><strong>Manual steps</strong></summary>

```bash
# 1. Backend virtual environment
cd universal-sql-transpiler/backend
python -m venv .venv

# Activate (Linux/macOS)
source .venv/bin/activate
# Activate (Windows PowerShell)
# .\.venv\Scripts\Activate.ps1

pip install --upgrade pip
pip install -r requirements.txt

# 2. Frontend dependencies
cd ../frontend
npm install
```

</details>

---

## Testing

**4,002 tests · 322 golden snapshots · 9 dialects · 5 object types**

From the `backend/` directory with the virtual environment active:

```bash
# Run all 4,002 tests
pytest

# Run a specific test file
pytest tests/test_phase1_redshift_snowflake.py
pytest tests/test_phase2_all_dialects.py
pytest tests/test_phase3_procedures.py
pytest tests/test_phase4_api.py
pytest tests/test_phase6_golden.py

# Run golden-file tests with verbose diff output
pytest tests/test_phase6_golden.py -v

# Regenerate golden snapshots after an intentional generator change
pytest tests/test_phase6_golden.py --regen-golden
```

<details>
<summary><strong>Test counts by file</strong></summary>

| File | Tests | Covers |
|---|---|---|
| `test_phase1_redshift_snowflake.py` | 30 | Redshift ↔ Snowflake table/view/MV |
| `test_phase2_all_dialects.py` | 98 | All 9 dialects, tables + views + MVs |
| `test_phase3_procedures.py` | 91 | Stored procedures + functions |
| `test_phase4_api.py` | 95 | FastAPI endpoints, incl. validation error paths |
| `test_phase6_golden.py` | 640 | Golden-file snapshots (322 files × 2 checks) |
| `test_advanced_realworld.py` | 2,169 | Real-world DDL corpus, adversarial/edge cases |
| `test_comprehensive.py` | 192 | Broad cross-dialect coverage |
| `test_comprehensive_validation.py` | 185 | Output validation against target-dialect rules |
| `test_query_transpiler.py` | 48 | SELECT/DML (sqlglot-based query path) |
| `test_realworld.py` | 414 | Real-world DDL samples |
| `test_schema_and_create_or_replace.py` | 40 | Schema inference, `CREATE OR REPLACE` / `IF NOT EXISTS` |
| **Total** | **4,002** | |

</details>

---

## Project Structure

<details>
<summary><strong>Expand full tree</strong></summary>

```
universal-sql-transpiler/
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   ├── routes.py          # FastAPI endpoints
│   │   │   └── schemas.py         # Pydantic request/response models
│   │   ├── dialects/
│   │   │   ├── base.py            # BaseParser / BaseGenerator
│   │   │   ├── redshift/          # parser.py + generator.py + references.md
│   │   │   ├── snowflake/
│   │   │   ├── sqlserver/
│   │   │   ├── synapse/
│   │   │   ├── fabric_dw/
│   │   │   ├── fabric_lakehouse/
│   │   │   ├── databricks/
│   │   │   ├── oracle/
│   │   │   └── bigquery/
│   │   ├── ir/
│   │   │   └── models.py          # IRTable / IRView / IRProcedure / IRFunction
│   │   ├── sql_text_utils.py      # Shared statement splitter (DDL + query paths)
│   │   ├── limitations.py         # Static limitations registry
│   │   ├── validator.py           # Residual pattern scan + confidence scoring
│   │   ├── query_transpiler.py    # sqlglot-based SELECT/DML path
│   │   ├── transpiler.py          # Orchestrator: parser → IR → generator
│   │   └── main.py                # FastAPI app with lifespan + CORS
│   ├── tests/
│   │   ├── conftest.py            # --regen-golden flag
│   │   ├── golden/                # SQL snapshot files (see test counts above)
│   │   ├── golden_samples.py      # Canonical inputs (9 dialects × 5 types)
│   │   ├── test_phase1_redshift_snowflake.py
│   │   ├── test_phase2_all_dialects.py
│   │   ├── test_phase3_procedures.py
│   │   ├── test_phase4_api.py
│   │   ├── test_phase6_golden.py
│   │   ├── test_advanced_realworld.py
│   │   ├── test_comprehensive.py
│   │   ├── test_comprehensive_validation.py
│   │   ├── test_query_transpiler.py
│   │   ├── test_realworld.py
│   │   └── test_schema_and_create_or_replace.py
│   ├── Dockerfile
│   ├── .dockerignore
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── api/
│   │   │   └── transpiler.js      # fetch wrappers for all API calls
│   │   ├── components/
│   │   │   ├── ConfidenceBadge.jsx
│   │   │   ├── DialectLogo.jsx
│   │   │   ├── DialectSelector.jsx
│   │   │   ├── DocRefsPanel.jsx
│   │   │   ├── DownloadMenu.jsx
│   │   │   ├── LandingAnimation/  # Cinematic intro overlay
│   │   │   ├── LimitationsPanel.jsx
│   │   │   ├── ReportDashboard.jsx
│   │   │   ├── SchemaGenModal.jsx
│   │   │   ├── SqlEditor.jsx      # Monaco editor with ust-dark theme
│   │   │   ├── UploadButton.jsx
│   │   │   └── WarningsPanel.jsx
│   │   ├── styles/index.css       # Dark theme, CSS custom properties
│   │   └── App.jsx                # Main layout + state
│   ├── public/logo.png            # UST logo — favicon + header + intro
│   ├── nginx.conf                 # Serves dist/ and proxies /api → backend
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── vite.config.js
│   └── package.json
├── docs/images/                   # Architecture diagrams used in this README
├── .github/workflows/ci.yml       # Runs backend tests + frontend build on every push/PR
├── docker-compose.yml             # backend + frontend services
├── render.yaml                    # Render Blueprint (backend + frontend, free tier)
├── setup.ps1                      # Windows one-command setup
├── setup.sh                       # Linux/macOS one-command setup
├── LICENSE
├── CONTRIBUTING.md
├── .gitignore
└── README.md
```

</details>

---

## Contributing / License

Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) for local setup, project conventions, and how to submit a change.

Licensed under the [MIT License](LICENSE).
