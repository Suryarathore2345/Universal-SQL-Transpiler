"""
Tests for SELECT / DML transpilation via QueryTranspiler.

These tests verify that:
  1. Statement type detection works correctly
  2. sqlglot-based transpilation produces correct output for key patterns
  3. Per-dialect post-processing applies (NULLS FIRST/LAST stripping, etc.)
  4. Semantic warnings are generated for unsupported constructs
  5. The main Transpiler.convert() routes queries correctly
"""
import pytest
import re

from app.query_transpiler import (
    detect_statement_type,
    is_query_statement,
    transpile_query,
    transpile_script,
    _split_statements,
)
from app.ir.models import ObjectType
from app.transpiler import Transpiler


# ---------------------------------------------------------------------------
# detect_statement_type
# ---------------------------------------------------------------------------

class TestDetectStatementType:
    def test_select(self):
        assert detect_statement_type("SELECT id FROM users") == ObjectType.SELECT_QUERY

    def test_select_with_cte(self):
        sql = "WITH cte AS (SELECT 1 AS n) SELECT * FROM cte"
        assert detect_statement_type(sql) == ObjectType.SELECT_QUERY

    def test_with_leading_comment(self):
        sql = "-- get users\nSELECT * FROM users"
        assert detect_statement_type(sql) == ObjectType.SELECT_QUERY

    def test_insert(self):
        assert detect_statement_type("INSERT INTO t (a) VALUES (1)") == ObjectType.INSERT

    def test_update(self):
        assert detect_statement_type("UPDATE users SET name = 'x' WHERE id = 1") == ObjectType.UPDATE

    def test_delete(self):
        assert detect_statement_type("DELETE FROM users WHERE id = 1") == ObjectType.DELETE

    def test_merge(self):
        sql = "MERGE INTO target USING source ON target.id = source.id WHEN MATCHED THEN UPDATE SET name = source.name"
        assert detect_statement_type(sql) == ObjectType.MERGE

    def test_ddl_returns_none(self):
        assert detect_statement_type("CREATE TABLE foo (id INT)") is None

    def test_alter_returns_none(self):
        assert detect_statement_type("ALTER TABLE foo ADD COLUMN bar INT") is None

    def test_block_comment_stripped(self):
        sql = "/* get data */ SELECT * FROM t"
        assert detect_statement_type(sql) == ObjectType.SELECT_QUERY


# ---------------------------------------------------------------------------
# is_query_statement
# ---------------------------------------------------------------------------

class TestIsQueryStatement:
    def test_single_select(self):
        assert is_query_statement("SELECT 1") is True

    def test_single_ddl(self):
        assert is_query_statement("CREATE TABLE t (id INT)") is False

    def test_all_queries_script(self):
        sql = "SELECT 1; INSERT INTO t VALUES (2); DELETE FROM t WHERE id = 3"
        assert is_query_statement(sql) is True


# ---------------------------------------------------------------------------
# _split_statements
# ---------------------------------------------------------------------------

class TestSplitStatements:
    def test_single_statement(self):
        parts = _split_statements("SELECT 1")
        assert len(parts) == 1

    def test_multiple_statements(self):
        sql = "SELECT 1; SELECT 2; SELECT 3"
        parts = _split_statements(sql)
        assert len(parts) == 3

    def test_semicolon_inside_string_not_split(self):
        sql = "SELECT 'a;b' AS val"
        parts = _split_statements(sql)
        assert len(parts) == 1

    def test_trailing_semicolon(self):
        parts = _split_statements("SELECT 1;")
        assert len(parts) == 1
        assert "SELECT 1" in parts[0]


# ---------------------------------------------------------------------------
# transpile_query — core transformations
# ---------------------------------------------------------------------------

class TestTranspileQuery:
    """Test sqlglot-powered transformations between key dialect pairs."""

    def test_redshift_to_snowflake_date_trunc(self):
        sql = "SELECT DATE_TRUNC('month', created_at) FROM orders"
        out, warns, _ = transpile_query(sql, "redshift", "snowflake")
        assert "DATE_TRUNC" in out.upper()
        assert "MONTH" in out.upper()

    def test_tsql_top_to_snowflake_limit(self):
        sql = "SELECT TOP 10 id, name FROM users ORDER BY id"
        out, warns, _ = transpile_query(sql, "sqlserver", "snowflake")
        assert "LIMIT" in out.upper()
        assert "TOP" not in out.upper()

    def test_oracle_nvl_to_coalesce(self):
        sql = "SELECT NVL(email, 'unknown') FROM customers"
        out, warns, _ = transpile_query(sql, "oracle", "databricks")
        assert "COALESCE" in out.upper()

    def test_tsql_getdate_to_current_timestamp(self):
        sql = "SELECT GETDATE() AS now"
        out, warns, _ = transpile_query(sql, "sqlserver", "bigquery")
        assert "GETDATE" not in out.upper()

    def test_tsql_isnull_to_coalesce_snowflake(self):
        sql = "SELECT ISNULL(name, 'N/A') AS safe_name FROM users"
        out, warns, _ = transpile_query(sql, "sqlserver", "snowflake")
        assert "ISNULL" not in out.upper()
        assert "COALESCE" in out.upper() or "NVL" in out.upper()

    def test_redshift_listagg_to_bigquery_string_agg(self):
        sql = "SELECT LISTAGG(product_name, ', ') WITHIN GROUP (ORDER BY product_name) FROM products"
        out, warns, _ = transpile_query(sql, "redshift", "bigquery")
        assert "STRING_AGG" in out.upper() or "LISTAGG" not in out.upper()

    def test_redshift_to_bigquery_insert(self):
        sql = "INSERT INTO target_table (id, name) SELECT id, name FROM source_table"
        out, warns, _ = transpile_query(sql, "redshift", "bigquery")
        assert "INSERT" in out.upper()
        assert "SELECT" in out.upper()

    def test_nulls_first_stripped_for_tsql(self):
        sql = "SELECT id FROM t ORDER BY id ASC NULLS FIRST"
        out, warns, _ = transpile_query(sql, "snowflake", "sqlserver")
        assert "NULLS" not in out.upper()

    def test_nulls_last_stripped_for_tsql(self):
        sql = "SELECT id FROM t ORDER BY id DESC NULLS LAST"
        out, warns, _ = transpile_query(sql, "snowflake", "synapse")
        assert "NULLS" not in out.upper()

    def test_true_false_replaced_for_tsql(self):
        sql = "SELECT * FROM t WHERE is_active = TRUE"
        out, warns, _ = transpile_query(sql, "snowflake", "sqlserver")
        assert "TRUE" not in out

    def test_ilike_replaced_for_oracle(self):
        sql = "SELECT * FROM users WHERE email ILIKE '%@example.com'"
        out, warns, _ = transpile_query(sql, "snowflake", "oracle")
        assert "ILIKE" not in out.upper()
        assert "LIKE" in out.upper()

    def test_returns_warnings_list(self):
        sql = "SELECT * FROM t"
        out, warns, refs = transpile_query(sql, "redshift", "snowflake")
        assert isinstance(warns, list)
        assert isinstance(refs, list)

    def test_qualify_warning_for_tsql(self):
        sql = "SELECT id, name FROM t QUALIFY ROW_NUMBER() OVER (PARTITION BY name ORDER BY id) = 1"
        out, warns, _ = transpile_query(sql, "snowflake", "sqlserver")
        feature_codes = {w.feature for w in warns}
        assert "QUALIFY_REWRITE_NEEDED" in feature_codes or "QUALIFY_CLAUSE" in feature_codes

    def test_qualify_no_warning_for_snowflake(self):
        sql = "SELECT id, name FROM t QUALIFY ROW_NUMBER() OVER (PARTITION BY name ORDER BY id) = 1"
        # Snowflake→BigQuery — BigQuery supports QUALIFY
        out, warns, _ = transpile_query(sql, "snowflake", "bigquery")
        feature_codes = {w.feature for w in warns}
        assert "QUALIFY_REWRITE_NEEDED" not in feature_codes

    def test_same_dialect_passthrough(self):
        sql = "SELECT id, name FROM users WHERE id > 10"
        out, warns, _ = transpile_query(sql, "redshift", "redshift")
        # Should come back syntactically equivalent (may be reformatted by sqlglot)
        assert "SELECT" in out.upper()
        assert "FROM" in out.upper()

    def test_cte_select(self):
        sql = """
        WITH monthly AS (
            SELECT DATE_TRUNC('month', order_date) AS month, SUM(total) AS revenue
            FROM orders
            GROUP BY 1
        )
        SELECT month, revenue FROM monthly ORDER BY month
        """
        out, warns, _ = transpile_query(sql, "redshift", "snowflake")
        assert "WITH" in out.upper()
        assert "SELECT" in out.upper()

    def test_datediff_redshift_to_bigquery(self):
        sql = "SELECT DATEDIFF(day, start_date, end_date) AS days_diff FROM projects"
        out, warns, _ = transpile_query(sql, "redshift", "bigquery")
        # BigQuery uses DATE_DIFF with reversed arg order
        assert "DATE_DIFF" in out.upper() or "TIMESTAMP_DIFF" in out.upper() or "DATEDIFF" not in out.upper()

    def test_update_statement(self):
        sql = "UPDATE customers SET status = 'active' WHERE last_order_date > '2024-01-01'"
        out, warns, _ = transpile_query(sql, "redshift", "snowflake")
        assert "UPDATE" in out.upper()
        assert "SET" in out.upper()

    def test_delete_statement(self):
        sql = "DELETE FROM sessions WHERE created_at < '2024-01-01'"
        out, warns, _ = transpile_query(sql, "snowflake", "bigquery")
        assert "DELETE" in out.upper()

    def test_merge_statement(self):
        sql = """
        MERGE INTO target t
        USING source s ON t.id = s.id
        WHEN MATCHED THEN UPDATE SET t.name = s.name
        WHEN NOT MATCHED THEN INSERT (id, name) VALUES (s.id, s.name)
        """
        out, warns, _ = transpile_query(sql, "sqlserver", "databricks")
        assert "MERGE" in out.upper()
        assert "WHEN MATCHED" in out.upper()


# ---------------------------------------------------------------------------
# transpile_script — multi-statement
# ---------------------------------------------------------------------------

class TestTranspileScript:
    def test_two_selects(self):
        sql = "SELECT 1 AS a; SELECT 2 AS b"
        out, warns, refs = transpile_script(sql, "redshift", "snowflake")
        assert out.count("SELECT") == 2

    def test_deduplicates_doc_refs(self):
        sql = "SELECT 1; SELECT 2; SELECT 3"
        out, warns, refs = transpile_script(sql, "redshift", "bigquery")
        urls = [r.url for r in refs]
        assert len(urls) == len(set(urls))


# ---------------------------------------------------------------------------
# Integration — Transpiler.convert() routes queries correctly
# ---------------------------------------------------------------------------

class TestTranspilerConvertRouting:
    def test_select_routes_to_query_transpiler(self):
        sql = "SELECT id, name FROM users WHERE active = TRUE"
        result = Transpiler.convert(sql, "snowflake", "sqlserver")
        assert result.object_type == ObjectType.SELECT_QUERY
        assert "SELECT" in result.converted_sql.upper()

    def test_insert_routes_to_query_transpiler(self):
        sql = "INSERT INTO archive SELECT * FROM orders WHERE status = 'closed'"
        result = Transpiler.convert(sql, "redshift", "bigquery")
        assert result.object_type == ObjectType.INSERT

    def test_delete_routes_to_query_transpiler(self):
        sql = "DELETE FROM temp_table WHERE created_at < '2023-01-01'"
        result = Transpiler.convert(sql, "snowflake", "databricks")
        assert result.object_type == ObjectType.DELETE

    def test_update_routes_to_query_transpiler(self):
        sql = "UPDATE products SET price = price * 1.1 WHERE category = 'Electronics'"
        result = Transpiler.convert(sql, "sqlserver", "snowflake")
        assert result.object_type == ObjectType.UPDATE

    def test_ddl_does_not_route_to_query_transpiler(self):
        sql = "CREATE TABLE test_table (id INT, name VARCHAR(100))"
        result = Transpiler.convert(sql, "redshift", "snowflake")
        # Should be TABLE, not a query type
        assert result.object_type == ObjectType.TABLE

    def test_result_has_correct_fields(self):
        sql = "SELECT COUNT(*) AS total FROM orders"
        result = Transpiler.convert(sql, "redshift", "snowflake")
        assert result.converted_sql
        assert result.source_dialect.value == "redshift"
        assert result.target_dialect.value == "snowflake"
        assert isinstance(result.warnings, list)
        assert isinstance(result.doc_references, list)
        assert result.elapsed_ms >= 0
        assert result.confidence_score > 0

    def test_window_function_select(self):
        sql = """
        SELECT
            customer_id,
            order_date,
            SUM(total) OVER (PARTITION BY customer_id ORDER BY order_date) AS running_total
        FROM orders
        """
        result = Transpiler.convert(sql, "redshift", "bigquery")
        assert "OVER" in result.converted_sql.upper()
        assert result.object_type == ObjectType.SELECT_QUERY

    def test_redshift_to_snowflake_full_query(self):
        sql = """
        SELECT
            c.customer_id,
            c.email,
            COUNT(o.order_id) AS order_count,
            SUM(o.total_amount) AS lifetime_value,
            MAX(o.order_date) AS last_order_date,
            DATEDIFF(day, MAX(o.order_date), CURRENT_DATE) AS days_since_last_order
        FROM customers c
        LEFT JOIN orders o ON c.customer_id = o.customer_id
        WHERE c.status = 'active'
        GROUP BY c.customer_id, c.email
        HAVING COUNT(o.order_id) > 0
        ORDER BY lifetime_value DESC
        LIMIT 100
        """
        result = Transpiler.convert(sql, "redshift", "snowflake")
        assert result.object_type == ObjectType.SELECT_QUERY
        assert "SELECT" in result.converted_sql.upper()
        assert "FROM" in result.converted_sql.upper()
        assert "GROUP BY" in result.converted_sql.upper()

    def test_tsql_to_oracle_select(self):
        sql = "SELECT TOP 5 id, name FROM users ORDER BY created_at DESC"
        result = Transpiler.convert(sql, "sqlserver", "oracle")
        assert result.object_type == ObjectType.SELECT_QUERY
        # Oracle should use FETCH FIRST or ROWNUM approach
        out = result.converted_sql.upper()
        # TOP keyword should not survive
        assert "SELECT TOP" not in out
