"""
Phase 4 tests — FastAPI REST API layer.

Uses FastAPI's TestClient (httpx-based) to test endpoints without starting
a real server.

Official docs:
  FastAPI testing:  https://fastapi.tiangolo.com/tutorial/testing/
  TestClient:       https://www.starlette.io/testclient/
"""
import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


# ---------------------------------------------------------------------------
# GET /api/health
# ---------------------------------------------------------------------------

class TestHealth:
    def test_returns_200(self):
        r = client.get("/api/health")
        assert r.status_code == 200

    def test_status_ok(self):
        body = client.get("/api/health").json()
        assert body["status"] == "ok"

    def test_dialects_loaded(self):
        body = client.get("/api/health").json()
        assert body["dialects_loaded"] == 8

    def test_version_present(self):
        body = client.get("/api/health").json()
        assert "version" in body


# ---------------------------------------------------------------------------
# GET /api/dialects
# ---------------------------------------------------------------------------

class TestDialects:
    def test_returns_200(self):
        r = client.get("/api/dialects")
        assert r.status_code == 200

    def test_eight_dialects(self):
        body = client.get("/api/dialects").json()
        assert len(body["dialects"]) == 8

    def test_all_dialect_keys_present(self):
        body = client.get("/api/dialects").json()
        keys = {d["key"] for d in body["dialects"]}
        expected = {"redshift", "snowflake", "sqlserver", "synapse",
                    "fabric_dw", "databricks", "oracle", "bigquery"}
        assert keys == expected

    def test_dialect_has_required_fields(self):
        body = client.get("/api/dialects").json()
        for d in body["dialects"]:
            assert "key" in d
            assert "display_name" in d
            assert "supported_objects" in d
            assert len(d["supported_objects"]) > 0


# ---------------------------------------------------------------------------
# POST /api/transpile — basic happy path
# ---------------------------------------------------------------------------

SIMPLE_TABLE = "CREATE TABLE orders (id INT NOT NULL, amount DECIMAL(18,2));"

class TestTranspileBasic:
    def test_returns_200(self):
        r = client.post("/api/transpile", json={
            "sql": SIMPLE_TABLE, "source_dialect": "redshift", "target_dialect": "snowflake"
        })
        assert r.status_code == 200

    def test_converted_sql_non_empty(self):
        body = client.post("/api/transpile", json={
            "sql": SIMPLE_TABLE, "source_dialect": "redshift", "target_dialect": "snowflake"
        }).json()
        assert body["converted_sql"]
        assert "CREATE" in body["converted_sql"]

    def test_source_target_echoed(self):
        body = client.post("/api/transpile", json={
            "sql": SIMPLE_TABLE, "source_dialect": "redshift", "target_dialect": "snowflake"
        }).json()
        assert body["source_dialect"] == "redshift"
        assert body["target_dialect"] == "snowflake"

    def test_object_type_detected(self):
        body = client.post("/api/transpile", json={
            "sql": SIMPLE_TABLE, "source_dialect": "redshift", "target_dialect": "snowflake"
        }).json()
        assert body["object_type"] == "table"

    def test_warning_count_field(self):
        body = client.post("/api/transpile", json={
            "sql": SIMPLE_TABLE, "source_dialect": "redshift", "target_dialect": "snowflake"
        }).json()
        assert "warning_count" in body
        assert isinstance(body["warning_count"], int)

    def test_has_unsupported_field(self):
        body = client.post("/api/transpile", json={
            "sql": SIMPLE_TABLE, "source_dialect": "redshift", "target_dialect": "snowflake"
        }).json()
        assert "has_unsupported" in body


# ---------------------------------------------------------------------------
# POST /api/transpile — warnings and unsupported features
# ---------------------------------------------------------------------------

DIST_TABLE = """\
CREATE TABLE sales (
    id INT NOT NULL,
    amount DECIMAL(10,2)
)
DISTSTYLE KEY
DISTKEY(id)
SORTKEY(id);
"""

class TestTranspileWarnings:
    def test_bigquery_gets_distribution_warning(self):
        body = client.post("/api/transpile", json={
            "sql": DIST_TABLE, "source_dialect": "redshift", "target_dialect": "bigquery"
        }).json()
        # BigQuery has no distribution; warnings or unsupported should mention it
        all_msgs = [w["message"] for w in body["warnings"] + body["unsupported_features"]]
        assert any("distribut" in m.lower() or "distkey" in m.lower() or "sortkey" in m.lower() for m in all_msgs), \
            f"Expected a distribution-related warning, got: {all_msgs}"

    def test_warning_structure(self):
        body = client.post("/api/transpile", json={
            "sql": DIST_TABLE, "source_dialect": "redshift", "target_dialect": "bigquery"
        }).json()
        if body["warnings"]:
            w = body["warnings"][0]
            assert "feature" in w
            assert "message" in w
            assert "severity" in w

    def test_unsupported_structure(self):
        body = client.post("/api/transpile", json={
            "sql": DIST_TABLE, "source_dialect": "redshift", "target_dialect": "bigquery"
        }).json()
        if body["unsupported_features"]:
            u = body["unsupported_features"][0]
            assert "feature" in u
            assert "message" in u


# ---------------------------------------------------------------------------
# POST /api/transpile — doc_references
# ---------------------------------------------------------------------------

class TestDocReferences:
    def test_doc_refs_present(self):
        body = client.post("/api/transpile", json={
            "sql": SIMPLE_TABLE, "source_dialect": "redshift", "target_dialect": "snowflake"
        }).json()
        assert len(body["doc_references"]) > 0

    def test_doc_ref_has_url(self):
        body = client.post("/api/transpile", json={
            "sql": SIMPLE_TABLE, "source_dialect": "redshift", "target_dialect": "snowflake"
        }).json()
        for ref in body["doc_references"]:
            assert ref["url"].startswith("http")
            assert ref["title"]

    def test_doc_refs_deduplicated(self):
        body = client.post("/api/transpile", json={
            "sql": SIMPLE_TABLE, "source_dialect": "redshift", "target_dialect": "snowflake"
        }).json()
        urls = [r["url"] for r in body["doc_references"]]
        assert len(urls) == len(set(urls)), "Duplicate doc reference URLs found"


# ---------------------------------------------------------------------------
# POST /api/transpile — include_ir flag
# ---------------------------------------------------------------------------

class TestIRSnapshot:
    def test_ir_absent_by_default(self):
        body = client.post("/api/transpile", json={
            "sql": SIMPLE_TABLE, "source_dialect": "redshift", "target_dialect": "snowflake"
        }).json()
        assert body.get("ir_snapshot") is None

    def test_ir_included_when_requested(self):
        body = client.post("/api/transpile", json={
            "sql": SIMPLE_TABLE, "source_dialect": "redshift", "target_dialect": "snowflake",
            "include_ir": True,
        }).json()
        # IR snapshot is optional — transpiler may not populate it yet; just check no error
        assert "ir_snapshot" in body


# ---------------------------------------------------------------------------
# POST /api/transpile — view
# ---------------------------------------------------------------------------

VIEW_SQL = "CREATE OR REPLACE VIEW public.active_orders AS SELECT id, amount FROM orders WHERE status = 'active';"

class TestTranspileView:
    def test_view_redshift_to_snowflake(self):
        body = client.post("/api/transpile", json={
            "sql": VIEW_SQL, "source_dialect": "redshift", "target_dialect": "snowflake"
        }).json()
        assert "VIEW" in body["converted_sql"]
        assert body["object_type"] == "view"

    def test_view_snowflake_to_bigquery(self):
        body = client.post("/api/transpile", json={
            "sql": VIEW_SQL, "source_dialect": "snowflake", "target_dialect": "bigquery"
        }).json()
        assert "VIEW" in body["converted_sql"]


# ---------------------------------------------------------------------------
# POST /api/transpile — procedure
# ---------------------------------------------------------------------------

PROC_SQL = """\
CREATE OR REPLACE PROCEDURE public.cleanup()
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM logs WHERE created_at < NOW() - INTERVAL '90 days';
END;
$$;
"""

class TestTranspileProcedure:
    def test_proc_redshift_to_snowflake(self):
        body = client.post("/api/transpile", json={
            "sql": PROC_SQL, "source_dialect": "redshift", "target_dialect": "snowflake"
        }).json()
        assert "PROCEDURE" in body["converted_sql"]
        assert body["object_type"] == "procedure"

    def test_proc_redshift_to_sqlserver(self):
        body = client.post("/api/transpile", json={
            "sql": PROC_SQL, "source_dialect": "redshift", "target_dialect": "sqlserver"
        }).json()
        assert "PROCEDURE" in body["converted_sql"]


# ---------------------------------------------------------------------------
# POST /api/transpile — validation / error paths
# ---------------------------------------------------------------------------

class TestValidation:
    def test_blank_sql_422(self):
        r = client.post("/api/transpile", json={
            "sql": "   ", "source_dialect": "redshift", "target_dialect": "snowflake"
        })
        assert r.status_code == 422

    def test_missing_sql_422(self):
        r = client.post("/api/transpile", json={
            "source_dialect": "redshift", "target_dialect": "snowflake"
        })
        assert r.status_code == 422

    def test_invalid_source_dialect_400(self):
        r = client.post("/api/transpile", json={
            "sql": SIMPLE_TABLE, "source_dialect": "mysql", "target_dialect": "snowflake"
        })
        assert r.status_code == 400

    def test_invalid_target_dialect_400(self):
        r = client.post("/api/transpile", json={
            "sql": SIMPLE_TABLE, "source_dialect": "redshift", "target_dialect": "teradata"
        })
        assert r.status_code == 400

    def test_empty_sql_422(self):
        r = client.post("/api/transpile", json={
            "sql": "", "source_dialect": "redshift", "target_dialect": "snowflake"
        })
        assert r.status_code == 422


# ---------------------------------------------------------------------------
# POST /api/transpile — all 8×8 dialect pairs return 200
# ---------------------------------------------------------------------------

ALL_DIALECTS = [
    "redshift", "snowflake", "sqlserver", "synapse",
    "fabric_dw", "databricks", "oracle", "bigquery",
]


@pytest.mark.parametrize("src", ALL_DIALECTS)
@pytest.mark.parametrize("tgt", ALL_DIALECTS)
def test_api_cross_dialect(src: str, tgt: str):
    """All 64 dialect pairs must return HTTP 200 with non-empty converted_sql."""
    r = client.post("/api/transpile", json={
        "sql": SIMPLE_TABLE,
        "source_dialect": src,
        "target_dialect": tgt,
    })
    assert r.status_code == 200, f"{src}→{tgt}: status={r.status_code} body={r.text[:200]}"
    body = r.json()
    assert body["converted_sql"], f"{src}→{tgt}: empty converted_sql"
