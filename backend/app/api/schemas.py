"""
Request / response Pydantic v2 schemas for the FastAPI REST layer.

These schemas are the public API contract — kept deliberately flat so the
React frontend can consume them without unpacking nested IR details.

Official FastAPI docs: https://fastapi.tiangolo.com/tutorial/body/
Official Pydantic v2 docs: https://docs.pydantic.dev/latest/
"""
from __future__ import annotations

from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field, field_validator


# ---------------------------------------------------------------------------
# Request
# ---------------------------------------------------------------------------

class TranspileRequest(BaseModel):
    """
    POST /api/transpile  request body.

    sql:             Raw SQL text (one or more DDL statements).
    source_dialect:  Source platform key (e.g. "redshift").
    target_dialect:  Target platform key (e.g. "snowflake").
    object_type:     Optional type hint — "table"|"view"|"materialized_view"|
                     "procedure"|"function". Omit to auto-detect.
    include_ir:      If true, the response includes the serialized IR snapshot
                     (useful for debugging / the dev panel).
    """

    sql: str = Field(..., min_length=1, description="SQL DDL to transpile")
    source_dialect: str = Field(..., description="Source dialect key")
    target_dialect: str = Field(..., description="Target dialect key")
    object_type: Optional[str] = Field(None, description="Optional object type hint")
    include_ir: bool = Field(False, description="Include IR snapshot in response")

    @field_validator("sql")
    @classmethod
    def sql_not_blank(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("sql must not be blank")
        return v


# ---------------------------------------------------------------------------
# Response sub-models
# ---------------------------------------------------------------------------

class WarningDetail(BaseModel):
    feature: str
    message: str
    doc_url: str = ""
    severity: str
    fallback_applied: bool = False


class UnsupportedFeatureDetail(BaseModel):
    feature: str
    message: str
    doc_url: str = ""
    severity: str


class DocReferenceDetail(BaseModel):
    title: str
    url: str
    platform: str
    purpose: str = ""


# ---------------------------------------------------------------------------
# Main transpile response
# ---------------------------------------------------------------------------

class ResidualWarningDetail(BaseModel):
    """A residual source-dialect pattern found in the generated output."""
    feature: str
    message: str
    severity: str = "warning"


class TranspileResponse(BaseModel):
    """
    POST /api/transpile  response body.
    """
    converted_sql: str
    source_dialect: str
    target_dialect: str
    object_type: str
    warnings: List[WarningDetail] = Field(default_factory=list)
    unsupported_features: List[UnsupportedFeatureDetail] = Field(default_factory=list)
    doc_references: List[DocReferenceDetail] = Field(default_factory=list)
    ir_snapshot: Optional[Dict[str, Any]] = None

    # Computed convenience fields for the frontend
    warning_count: int = 0
    has_unsupported: bool = False

    # Phase 8 — confidence scoring
    # HIGH (1.00): clean conversion; PARTIAL (0.65–0.99): warnings present;
    # MANUAL_REVIEW (0.50): unsupported features require human intervention.
    confidence_score: float = 1.0
    confidence_level: str = "HIGH"   # "HIGH" | "PARTIAL" | "MANUAL_REVIEW"

    # Phase 8 — residual validator findings
    residual_warnings: List[ResidualWarningDetail] = Field(default_factory=list)
    residual_count: int = 0

    # Phase 8 — latency
    elapsed_ms: int = 0

    @classmethod
    def from_transpile_result(cls, result, include_ir: bool = False) -> "TranspileResponse":
        warnings = [
            WarningDetail(
                feature=w.feature,
                message=w.message,
                doc_url=w.doc_url,
                severity=w.severity.value if hasattr(w.severity, "value") else str(w.severity),
                fallback_applied=w.fallback_applied,
            )
            for w in result.warnings
        ]
        unsupported = [
            UnsupportedFeatureDetail(
                feature=w.feature,
                message=w.message,
                doc_url=w.doc_url,
                severity=w.severity.value if hasattr(w.severity, "value") else str(w.severity),
            )
            for w in result.unsupported_features
        ]
        doc_refs = [
            DocReferenceDetail(
                title=d.title,
                url=d.url,
                platform=d.platform,
                purpose=d.purpose,
            )
            for d in result.doc_references
        ]
        residuals = [
            ResidualWarningDetail(
                feature=w.feature,
                message=w.message,
                severity=w.severity.value if hasattr(w.severity, "value") else str(w.severity),
            )
            for w in getattr(result, "residual_warnings", [])
        ]
        ir_snapshot = result.ir_snapshot if include_ir else None

        return cls(
            converted_sql=result.converted_sql,
            source_dialect=result.source_dialect.value,
            target_dialect=result.target_dialect.value,
            object_type=result.object_type.value,
            warnings=warnings,
            unsupported_features=unsupported,
            doc_references=doc_refs,
            ir_snapshot=ir_snapshot,
            warning_count=len(warnings),
            has_unsupported=len(unsupported) > 0,
            confidence_score=getattr(result, "confidence_score", 1.0),
            confidence_level=getattr(result, "confidence_level", "HIGH"),
            residual_warnings=residuals,
            residual_count=len(residuals),
            elapsed_ms=getattr(result, "elapsed_ms", 0),
        )


# ---------------------------------------------------------------------------
# Dialect catalogue
# ---------------------------------------------------------------------------

class DialectCapabilities(BaseModel):
    key: str
    display_name: str
    short_name: str
    logo_key: str  # Used by frontend to pick the right logo image
    vendor: str
    supported_objects: List[str]  # ["table", "view", "materialized_view", ...]
    notes: str = ""


class DialectsResponse(BaseModel):
    dialects: List[DialectCapabilities]


# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------

class HealthResponse(BaseModel):
    status: str
    version: str
    dialects_loaded: int


# ---------------------------------------------------------------------------
# Error response (returned on 4xx)
# ---------------------------------------------------------------------------

class ErrorResponse(BaseModel):
    error: str
    detail: Optional[str] = None
    request_id: Optional[str] = None


# ---------------------------------------------------------------------------
# Limitations matrix
# ---------------------------------------------------------------------------

class LimitationItem(BaseModel):
    feature: str
    level: str          # "info" | "warn" | "error"
    description: str
    doc_url: str = ""
    sql_keywords: List[str] = Field(default_factory=list)
    """Frontend uses this to hide the limitation when none of the keywords appear in source SQL."""


class DialectLimitations(BaseModel):
    dialect: str
    limitations: List[LimitationItem]


class LimitationsResponse(BaseModel):
    dialects: List[DialectLimitations]
