# Universal SQL Transpiler (UST)

Convert SQL DDL — tables, views, materialized views, stored procedures, and functions — between **8 cloud and enterprise platforms** with a single click.

Supported platforms: **Amazon Redshift · Snowflake · Microsoft SQL Server · Azure Synapse · Microsoft Fabric DW · Databricks · Oracle · BigQuery**

---

## Table of Contents

1. [Features](#features)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Quick Start — Docker](#quick-start--docker)
5. [Local Development Setup](#local-development-setup)
   - [Windows (PowerShell)](#windows-powershell)
   - [Linux / macOS (bash)](#linux--macos-bash)
   - [Manual steps](#manual-steps)
6. [Running Tests](#running-tests)
7. [API Reference](#api-reference)
8. [Supported Objects & Known Limitations](#supported-objects--known-limitations)
9. [Project Structure](#project-structure)

---

## Features

- **8 × 8 dialect matrix** — any source to any target, 64 conversion pairs
- **5 object types** — `TABLE`, `VIEW`, `MATERIALIZED VIEW`, `PROCEDURE`, `FUNCTION`
- **Intermediate Representation (IR)** — N parsers + N generators; no combinatorial code
- **Warnings & doc references** — every dropped or changed feature links to the official vendor documentation
- **Limitations panel** — per-dialect list of known gaps shown in the UI before you even convert
- **REST API** — FastAPI backend with auto-generated OpenAPI docs
- **Monaco editor** — VS Code–quality SQL editing with a custom dark theme
- **Golden-file regression tests** — 954 tests, 320 snapshot files

---

## Architecture

```
SQL input
    │
    ▼
[Source Parser]          — sqlglot-based, dialect-aware
    │
    ▼
[Intermediate Representation (IR)]
    IRTable / IRView / IRMaterializedView / IRProcedure / IRFunction
    │
    ▼
[Target Generator]       — dialect-aware, emits DDL + warnings + doc refs
    │
    ▼
SQL output  +  warnings  +  documentation links
```

The IR layer means adding a new dialect requires only 1 parser + 1 generator, not N×N adapters.

---

## Prerequisites

| Tool | Minimum version | Notes |
|---|---|---|
| Python | 3.11 | 3.12 recommended |
| Node.js | 18 LTS | 20 LTS recommended |
| npm | 9+ | Bundled with Node.js |
| Docker + Compose | 24+ | Only needed for the Docker path |

---

## Quick Start — Docker

The simplest way to run the full stack. No Python or Node.js required on the host.

```bash
# Clone / unzip the project, then:
cd universal-sql-transpiler

docker compose up --build
```

| URL | Service |
|---|---|
| http://localhost | Frontend UI |
| http://localhost:8000/api/docs | FastAPI interactive docs (Swagger) |
| http://localhost:8000/api/health | Health check |

To stop:

```bash
docker compose down
```

---

## Local Development Setup

### Windows (PowerShell)

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

---

### Linux / macOS (bash)

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

---

### Manual Steps

If you prefer not to use the setup scripts:

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

---

## Running Tests

From the `backend/` directory with the virtual environment active:

```bash
# Run all 954 tests
pytest

# Run a specific phase
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

**Test counts by phase**

| Phase | Tests | Covers |
|---|---|---|
| 1 | 30 | Redshift ↔ Snowflake table/view/MV |
| 2 | 98 | All 8 dialects, tables + views + MVs |
| 3 | 91 | Stored procedures + functions, 8×8 matrix |
| 4 | 95 | FastAPI endpoints, HTTP 8×8 matrix |
| 6 | 640 | Golden-file snapshots (320 pairs × 2 checks) |
| **Total** | **954** | |

---

## API Reference

The backend exposes three endpoints under `/api`. Interactive docs are available at `http://localhost:8000/api/docs`.

### `POST /api/transpile`

Convert SQL from one dialect to another.

**Request body**

```json
{
  "sql": "CREATE TABLE ...",
  "source_dialect": "redshift",
  "target_dialect": "snowflake",
  "object_type": null,
  "include_ir": false
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `sql` | string | Yes | Raw SQL DDL (one or more statements) |
| `source_dialect` | string | Yes | Source platform key (see dialect keys below) |
| `target_dialect` | string | Yes | Target platform key |
| `object_type` | string | No | Type hint: `table`, `view`, `materialized_view`, `procedure`, `function` |
| `include_ir` | boolean | No | Include serialized IR snapshot for debugging |

**Response**

```json
{
  "converted_sql": "CREATE OR REPLACE TABLE ...",
  "source_dialect": "redshift",
  "target_dialect": "snowflake",
  "object_type": "table",
  "warnings": [
    {
      "feature": "SORTKEY_TO_CLUSTER_BY",
      "message": "Redshift SORTKEY converted to CLUSTER BY ...",
      "severity": "info",
      "doc_url": "https://docs.snowflake.com/...",
      "fallback_applied": true
    }
  ],
  "unsupported_features": [],
  "doc_references": [...],
  "warning_count": 1,
  "has_unsupported": false
}
```

### `GET /api/dialects`

List all supported dialects with display metadata.

### `GET /api/limitations`

Return known transpilation limitations for target dialects.

Optional query parameter: `?dialect=snowflake`

### `GET /api/health`

Liveness probe. Returns `{ "status": "ok", "version": "1.0.0", "dialects_loaded": 8 }`.

**Dialect keys**

| Key | Platform |
|---|---|
| `redshift` | Amazon Redshift |
| `snowflake` | Snowflake |
| `sqlserver` | Microsoft SQL Server |
| `synapse` | Azure Synapse Analytics |
| `fabric_dw` | Microsoft Fabric Data Warehouse |
| `databricks` | Databricks (Delta Lake) |
| `oracle` | Oracle Database |
| `bigquery` | Google BigQuery |

---

## Supported Objects & Known Limitations

### Object type support matrix

| Dialect | TABLE | VIEW | MAT. VIEW | PROCEDURE | FUNCTION |
|---|:---:|:---:|:---:|:---:|:---:|
| Redshift | ✅ | ✅ | ✅ | ✅ | ✅ |
| Snowflake | ✅ | ✅ | ✅ ¹ | ✅ | ✅ |
| SQL Server | ✅ | ✅ | ⚠️ ² | ✅ | ✅ |
| Synapse | ✅ | ✅ | ✅ | ✅ | ✅ |
| Fabric DW | ✅ | ✅ | ❌ ³ | ✅ | ✅ |
| Databricks | ✅ | ✅ | ✅ | ⚠️ ⁴ | ✅ |
| Oracle | ✅ | ✅ | ✅ | ✅ | ✅ |
| BigQuery | ✅ | ✅ | ✅ | ✅ | ✅ |

¹ Requires Enterprise Edition or higher.  
² Converted to indexed view with `WITH SCHEMABINDING` — query may need adjustments.  
³ Converted to a regular VIEW — no automatic refresh.  
⁴ Converted to a SQL UDF stub — significant manual adaptation required.

### Key per-target limitations

| Target | Limitation | Level |
|---|---|---|
| Snowflake | DISTKEY removed (managed automatically) | warn |
| Snowflake | Procedure bodies wrapped as-is — Snowflake Scripting differs | warn |
| SQL Server | MV → indexed view, SELECT must use two-part names | warn |
| Synapse | Every table needs explicit DISTRIBUTION | warn |
| Fabric DW | No materialized views | **error** |
| Databricks | No stored procedures → UDF stub | **error** |
| Databricks | CLUSTER BY and PARTITIONED BY are mutually exclusive | warn |
| Oracle | DATE type includes time component | info |
| BigQuery | No IDENTITY columns | warn |
| BigQuery | PK/FK are NOT ENFORCED | info |

Full limitations are returned by `GET /api/limitations` and shown in the UI's limitations panel.

---

## Project Structure

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
│   │   │   ├── databricks/
│   │   │   ├── oracle/
│   │   │   └── bigquery/
│   │   ├── ir/
│   │   │   └── models.py          # IRTable / IRView / IRProcedure / IRFunction
│   │   ├── limitations.py         # Static limitations registry (27 entries)
│   │   ├── transpiler.py          # Orchestrator: parser → IR → generator
│   │   └── main.py                # FastAPI app with lifespan + CORS
│   ├── tests/
│   │   ├── conftest.py            # --regen-golden flag
│   │   ├── golden/                # 320 SQL snapshot files
│   │   ├── golden_samples.py      # Canonical inputs (8 dialects × 5 types)
│   │   ├── test_phase1_redshift_snowflake.py
│   │   ├── test_phase2_all_dialects.py
│   │   ├── test_phase3_procedures.py
│   │   ├── test_phase4_api.py
│   │   └── test_phase6_golden.py
│   ├── Dockerfile
│   ├── .dockerignore
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── api/
│   │   │   └── transpiler.js      # fetch wrappers for all API calls
│   │   ├── components/
│   │   │   ├── DialectSelector.jsx
│   │   │   ├── DocRefsPanel.jsx
│   │   │   ├── LimitationsPanel.jsx
│   │   │   ├── SqlEditor.jsx      # Monaco editor with ust-dark theme
│   │   │   └── WarningsPanel.jsx
│   │   ├── styles/index.css       # Dark theme, CSS custom properties
│   │   └── App.jsx                # Main layout + state
│   ├── nginx.conf                 # Serves dist/ and proxies /api → backend
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── vite.config.js
│   └── package.json
├── docker-compose.yml             # backend + frontend services
├── setup.ps1                      # Windows one-command setup
├── setup.sh                       # Linux/macOS one-command setup
├── .gitignore
└── README.md
```
