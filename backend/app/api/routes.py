"""
FastAPI route definitions for the Universal SQL Transpiler.

Endpoints:
  POST /api/transpile   — convert SQL from source dialect to target dialect
  GET  /api/dialects    — list supported dialects with display metadata
  GET  /api/health      — liveness / readiness probe

Official FastAPI docs: https://fastapi.tiangolo.com/tutorial/
"""
from __future__ import annotations

import logging
import time
import uuid
from typing import Any

from fastapi import APIRouter, HTTPException, Request, status
from fastapi.responses import JSONResponse

from app.api.schemas import (
    DialectCapabilities, DialectLimitations, DialectsResponse, ErrorResponse,
    HealthResponse, LimitationItem, LimitationsResponse,
    TranspileRequest, TranspileResponse,
)
from app.limitations import get_limitations
from app.transpiler import Transpiler

logger = logging.getLogger(__name__)

router = APIRouter()

# ---------------------------------------------------------------------------
# Dialect metadata catalogue
# Docs for each platform are linked in the parser/generator files.
# ---------------------------------------------------------------------------

_DIALECT_META: list[dict[str, Any]] = [
    {
        "key": "redshift",
        "display_name": "Amazon Redshift",
        "short_name": "Redshift",
        "logo_key": "redshift",
        "vendor": "Amazon Web Services",
        "supported_objects": ["table", "view", "materialized_view", "procedure", "function"],
        "notes": "DISTSTYLE/DISTKEY and SORTKEY are Redshift-specific table optimizations.",
    },
    {
        "key": "snowflake",
        "display_name": "Snowflake",
        "short_name": "Snowflake",
        "logo_key": "snowflake",
        "vendor": "Snowflake Inc.",
        "supported_objects": ["table", "view", "materialized_view", "procedure", "function"],
        "notes": "Materialized views require Enterprise Edition or higher.",
    },
    {
        "key": "sqlserver",
        "display_name": "Microsoft SQL Server",
        "short_name": "SQL Server",
        "logo_key": "sqlserver",
        "vendor": "Microsoft",
        "supported_objects": ["table", "view", "materialized_view", "procedure", "function"],
        "notes": "Materialized views are implemented as indexed views (WITH SCHEMABINDING).",
    },
    {
        "key": "synapse",
        "display_name": "Azure Synapse Analytics",
        "short_name": "Synapse",
        "logo_key": "synapse",
        "vendor": "Microsoft",
        "supported_objects": ["table", "view", "materialized_view", "procedure", "function"],
        "notes": "DISTRIBUTION clause is required for materialized views.",
    },
    {
        "key": "fabric_dw",
        "display_name": "Microsoft Fabric Data Warehouse",
        "short_name": "Fabric DW",
        "logo_key": "fabric_dw",
        "vendor": "Microsoft",
        "supported_objects": ["table", "view", "procedure", "function"],
        "notes": "Materialized views are not supported. CLUSTER BY supports up to 4 columns.",
    },
    {
        "key": "databricks",
        "display_name": "Databricks (Delta Lake)",
        "short_name": "Databricks",
        "logo_key": "databricks",
        "vendor": "Databricks",
        "supported_objects": ["table", "view", "materialized_view", "function"],
        "notes": "No stored procedures — procedures are converted to SQL UDF stubs. "
                 "CLUSTER BY (liquid clustering) and PARTITIONED BY are mutually exclusive.",
    },
    {
        "key": "oracle",
        "display_name": "Oracle Database",
        "short_name": "Oracle",
        "logo_key": "oracle",
        "vendor": "Oracle Corporation",
        "supported_objects": ["table", "view", "materialized_view", "procedure", "function"],
        "notes": "Oracle DATE includes a time component. NUMBER(p,s) is used for all numeric types.",
    },
    {
        "key": "bigquery",
        "display_name": "Google BigQuery",
        "short_name": "BigQuery",
        "logo_key": "bigquery",
        "vendor": "Google Cloud",
        "supported_objects": ["table", "view", "materialized_view", "procedure", "function"],
        "notes": "No IDENTITY — use GENERATE_UUID(). PK/FK are informational (NOT ENFORCED). "
                 "CLUSTER BY supports up to 4 columns.",
    },
]


# ---------------------------------------------------------------------------
# POST /api/transpile
# ---------------------------------------------------------------------------

@router.post(
    "/transpile",
    response_model=TranspileResponse,
    summary="Transpile SQL between dialects",
    description=(
        "Convert a SQL DDL statement (or multi-statement script) from the "
        "source dialect to the target dialect. Returns the converted SQL "
        "together with warnings, unsupported-feature flags, and links to "
        "the official documentation pages that informed each decision."
    ),
    responses={
        400: {"model": ErrorResponse, "description": "Invalid input"},
        422: {"description": "Validation error"},
        500: {"model": ErrorResponse, "description": "Internal transpiler error"},
    },
)
async def transpile(request: TranspileRequest) -> TranspileResponse:
    request_id = str(uuid.uuid4())[:8]
    t0 = time.monotonic()

    try:
        result = Transpiler.convert(
            sql=request.sql,
            source_dialect=request.source_dialect,
            target_dialect=request.target_dialect,
            object_type=request.object_type,
        )
    except Exception as exc:
        logger.exception("Transpiler error [%s]: %s", request_id, exc)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Transpiler error: {exc}",
        )

    # An error in dialect resolution is represented as a warning with severity=ERROR
    error_warnings = [w for w in result.warnings if w.severity.value == "error"]
    if error_warnings and not result.converted_sql:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error_warnings[0].message,
        )

    elapsed_ms = int((time.monotonic() - t0) * 1000)
    logger.info(
        "transpile [%s] %s→%s  %dms  warnings=%d  unsupported=%d",
        request_id,
        request.source_dialect,
        request.target_dialect,
        elapsed_ms,
        len(result.warnings),
        len(result.unsupported_features),
    )

    return TranspileResponse.from_transpile_result(result, include_ir=request.include_ir)


# ---------------------------------------------------------------------------
# GET /api/dialects
# ---------------------------------------------------------------------------

@router.get(
    "/dialects",
    response_model=DialectsResponse,
    summary="List supported dialects",
    description="Returns all supported SQL dialects with display metadata and capability flags.",
)
async def list_dialects() -> DialectsResponse:
    supported_keys = set(Transpiler.supported_dialects())
    dialects = [
        DialectCapabilities(**m)
        for m in _DIALECT_META
        if m["key"] in supported_keys
    ]
    return DialectsResponse(dialects=dialects)


# ---------------------------------------------------------------------------
# GET /api/limitations
# ---------------------------------------------------------------------------

@router.get(
    "/limitations",
    response_model=LimitationsResponse,
    summary="Known transpilation limitations",
    description=(
        "Returns the static limitations registry for all target dialects "
        "(or a single dialect if the `dialect` query parameter is supplied). "
        "Each entry describes a known constraint that applies when generating "
        "SQL for that platform."
    ),
)
async def list_limitations(dialect: str | None = None) -> LimitationsResponse:
    raw = get_limitations(dialect)
    result = [
        DialectLimitations(
            dialect=d,
            limitations=[
                LimitationItem(
                    feature=lim["feature"],
                    level=lim["level"],
                    description=lim["description"],
                    doc_url=lim.get("doc_url", ""),
                )
                for lim in lims
            ],
        )
        for d, lims in raw.items()
    ]
    return LimitationsResponse(dialects=result)


# ---------------------------------------------------------------------------
# GET /api/health
# ---------------------------------------------------------------------------

@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Health check",
    description="Liveness probe — verifies the transpiler loaded cleanly.",
)
async def health() -> HealthResponse:
    dialects_loaded = len(Transpiler.supported_dialects())
    return HealthResponse(
        status="ok",
        version="1.0.0",
        dialects_loaded=dialects_loaded,
    )
