"""
Universal SQL Transpiler — FastAPI application entry point.

Run locally:
    uvicorn app.main:app --reload --port 8000

Docker:
    CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

Official FastAPI docs: https://fastapi.tiangolo.com/
Official CORS docs:    https://fastapi.tiangolo.com/tutorial/cors/
"""
from __future__ import annotations

import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import router

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(name)s  %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Lifespan — warm up dialect registry on startup
# Docs: https://fastapi.tiangolo.com/advanced/events/#lifespan
# ---------------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    from app.transpiler import Transpiler
    n = len(Transpiler.supported_dialects())
    logger.info("UST started — %d dialects loaded", n)
    yield
    logger.info("UST shutting down")


# ---------------------------------------------------------------------------
# FastAPI app
# ---------------------------------------------------------------------------

app = FastAPI(
    lifespan=lifespan,
    title="Universal SQL Transpiler",
    description=(
        "Convert SQL DDL statements (tables, views, materialized views, "
        "stored procedures, and functions) between Amazon Redshift, "
        "Snowflake, Microsoft SQL Server, Azure Synapse Analytics, "
        "Microsoft Fabric Data Warehouse, Databricks, Oracle, and Google BigQuery."
    ),
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json",
)

# ---------------------------------------------------------------------------
# CORS — allow the React dev server (localhost:3000 / 5173) and any origin
# in development.  In production, set CORS_ORIGINS env var to restrict.
# Docs: https://fastapi.tiangolo.com/tutorial/cors/
# ---------------------------------------------------------------------------

_raw_origins = os.getenv(
    "CORS_ORIGINS",
    "http://localhost:3000,http://localhost:5173,http://127.0.0.1:3000,http://127.0.0.1:5173",
)
_allow_all = os.getenv("CORS_ALLOW_ALL", "false").lower() == "true"

if _allow_all:
    _origins = ["*"]
else:
    _origins = [o.strip() for o in _raw_origins.split(",") if o.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization", "X-Request-ID"],
)

# ---------------------------------------------------------------------------
# API router — all endpoints under /api
# ---------------------------------------------------------------------------

app.include_router(router, prefix="/api")
