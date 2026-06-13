"""
Phase 3 tests — stored procedure and function transpilation across all 8 dialects.

Official doc refs used by tested generators/parsers:
  Redshift proc:   https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_PROCEDURE.html
  Snowflake proc:  https://docs.snowflake.com/en/sql-reference/sql/create-procedure
  SQL Server proc: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql
  Synapse proc:    https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql?view=azure-sqldw-latest
  Fabric DW proc:  https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql
  Databricks func: https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-sql-function.html
  Oracle proc:     https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-PROCEDURE.html
  BigQuery proc:   https://cloud.google.com/bigquery/docs/reference/standard-sql/data-definition-language#create_procedure
"""
import pytest

from app.transpiler import Transpiler


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def transpile(sql: str, src: str, tgt: str):
    result = Transpiler.convert(sql, src, tgt)
    return result.converted_sql, result.warnings, result.unsupported_features


def has_warning(warnings, feature_substr: str) -> bool:
    return any(feature_substr.lower() in w.feature.lower() for w in warnings)


# ---------------------------------------------------------------------------
# Redshift → Snowflake  (procedure)
# ---------------------------------------------------------------------------

REDSHIFT_PROC = """\
CREATE OR REPLACE PROCEDURE dbo.upsert_orders(
    IN p_order_id INTEGER,
    IN p_amount DECIMAL(18,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO orders(order_id, amount) VALUES (p_order_id, p_amount);
END;
$$;
"""


class TestRedshiftProc:
    def test_redshift_proc_to_snowflake(self):
        sql, warns, _ = transpile(REDSHIFT_PROC, "redshift", "snowflake")
        assert "CREATE" in sql and "PROCEDURE" in sql
        assert "$$" in sql or "$$" in sql
        assert has_warning(warns, "MANUAL_REVIEW") or has_warning(warns, "PROCEDURE")

    def test_redshift_proc_to_sqlserver(self):
        sql, warns, _ = transpile(REDSHIFT_PROC, "redshift", "sqlserver")
        assert "PROCEDURE" in sql
        assert "BEGIN" in sql
        assert "END" in sql

    def test_redshift_proc_to_oracle(self):
        sql, warns, _ = transpile(REDSHIFT_PROC, "redshift", "oracle")
        assert "PROCEDURE" in sql
        assert "AS" in sql or "BEGIN" in sql

    def test_redshift_proc_to_bigquery(self):
        sql, warns, _ = transpile(REDSHIFT_PROC, "redshift", "bigquery")
        assert "PROCEDURE" in sql
        assert "BEGIN" in sql
        assert "END" in sql

    def test_redshift_proc_to_databricks(self):
        sql, warns, unsupported = transpile(REDSHIFT_PROC, "redshift", "databricks")
        # Databricks has no stored procs — should emit a function stub with a warning
        assert "FUNCTION" in sql or "-- Databricks" in sql
        assert has_warning(unsupported + warns, "NOT_SUPPORTED") or has_warning(unsupported + warns, "DATABRICKS")


# ---------------------------------------------------------------------------
# Snowflake procedure
# ---------------------------------------------------------------------------

SNOWFLAKE_PROC = """\
CREATE OR REPLACE PROCEDURE mydb.myschema.proc_total(
    region_id INT
)
RETURNS VARIANT
LANGUAGE SQL
AS
$$
DECLARE
    total_sales FLOAT;
BEGIN
    SELECT SUM(amount) INTO total_sales FROM sales WHERE region = region_id;
    RETURN total_sales;
END;
$$;
"""


class TestSnowflakeProc:
    def test_snowflake_proc_to_redshift(self):
        sql, warns, _ = transpile(SNOWFLAKE_PROC, "snowflake", "redshift")
        assert "PROCEDURE" in sql
        assert "plpgsql" in sql.lower() or "$$" in sql

    def test_snowflake_proc_to_synapse(self):
        sql, warns, _ = transpile(SNOWFLAKE_PROC, "snowflake", "synapse")
        assert "PROCEDURE" in sql
        assert "BEGIN" in sql

    def test_snowflake_proc_to_fabric_dw(self):
        sql, warns, _ = transpile(SNOWFLAKE_PROC, "snowflake", "fabric_dw")
        assert "PROCEDURE" in sql
        assert "BEGIN" in sql


# ---------------------------------------------------------------------------
# SQL Server / Synapse / Fabric DW (T-SQL source)
# ---------------------------------------------------------------------------

SQLSERVER_PROC = """\
CREATE OR ALTER PROCEDURE dbo.UpdateInventory
    @product_id INT,
    @quantity INT = 0 OUTPUT
AS
BEGIN
    UPDATE Inventory SET qty = qty + @quantity WHERE product_id = @product_id;
END;
"""


class TestSQLServerProc:
    def test_sqlserver_proc_to_redshift(self):
        sql, warns, _ = transpile(SQLSERVER_PROC, "sqlserver", "redshift")
        assert "PROCEDURE" in sql
        assert "plpgsql" in sql.lower() or "$$" in sql

    def test_sqlserver_proc_to_snowflake(self):
        sql, warns, _ = transpile(SQLSERVER_PROC, "sqlserver", "snowflake")
        assert "PROCEDURE" in sql
        assert "$$" in sql

    def test_sqlserver_proc_to_oracle(self):
        sql, warns, _ = transpile(SQLSERVER_PROC, "sqlserver", "oracle")
        assert "PROCEDURE" in sql
        assert "AS" in sql or "BEGIN" in sql

    def test_sqlserver_proc_to_bigquery(self):
        sql, warns, _ = transpile(SQLSERVER_PROC, "sqlserver", "bigquery")
        assert "PROCEDURE" in sql
        assert "BEGIN" in sql

    def test_sqlserver_proc_roundtrip(self):
        sql, _, _ = transpile(SQLSERVER_PROC, "sqlserver", "sqlserver")
        assert "PROCEDURE" in sql
        assert "BEGIN" in sql and "END" in sql


# ---------------------------------------------------------------------------
# Oracle procedure
# ---------------------------------------------------------------------------

ORACLE_PROC = """\
CREATE OR REPLACE PROCEDURE hr.calculate_bonus(
    emp_id IN NUMBER,
    bonus_pct IN NUMBER DEFAULT 0.1,
    result OUT NUMBER
)
AS
BEGIN
    SELECT salary * bonus_pct INTO result
    FROM employees WHERE employee_id = emp_id;
END calculate_bonus;
"""


class TestOracleProc:
    def test_oracle_proc_to_redshift(self):
        sql, warns, _ = transpile(ORACLE_PROC, "oracle", "redshift")
        assert "PROCEDURE" in sql
        assert has_warning(warns, "MANUAL_REVIEW") or has_warning(warns, "PROCEDURE")

    def test_oracle_proc_to_snowflake(self):
        sql, warns, _ = transpile(ORACLE_PROC, "oracle", "snowflake")
        assert "PROCEDURE" in sql

    def test_oracle_proc_to_bigquery(self):
        sql, warns, _ = transpile(ORACLE_PROC, "oracle", "bigquery")
        assert "PROCEDURE" in sql
        assert "BEGIN" in sql

    def test_oracle_proc_roundtrip(self):
        sql, _, _ = transpile(ORACLE_PROC, "oracle", "oracle")
        assert "PROCEDURE" in sql
        assert "BEGIN" in sql


# ---------------------------------------------------------------------------
# BigQuery procedure
# ---------------------------------------------------------------------------

BIGQUERY_PROC = """\
CREATE OR REPLACE PROCEDURE myproject.mydataset.count_rows(
    IN table_name STRING,
    OUT row_count INT64
)
BEGIN
    SET row_count = (SELECT COUNT(*) FROM myproject.mydataset.orders);
END;
"""


class TestBigQueryProc:
    def test_bigquery_proc_to_redshift(self):
        sql, warns, _ = transpile(BIGQUERY_PROC, "bigquery", "redshift")
        assert "PROCEDURE" in sql

    def test_bigquery_proc_to_sqlserver(self):
        sql, warns, _ = transpile(BIGQUERY_PROC, "bigquery", "sqlserver")
        assert "PROCEDURE" in sql
        assert "BEGIN" in sql

    def test_bigquery_proc_roundtrip(self):
        sql, _, _ = transpile(BIGQUERY_PROC, "bigquery", "bigquery")
        assert "PROCEDURE" in sql
        assert "BEGIN" in sql
        assert "END" in sql


# ---------------------------------------------------------------------------
# Function tests
# ---------------------------------------------------------------------------

REDSHIFT_FUNC = """\
CREATE OR REPLACE FUNCTION public.f_get_tax(amount FLOAT)
RETURNS FLOAT
STABLE
AS $$
    return amount * 0.1
$$ LANGUAGE plpythonu;
"""

SNOWFLAKE_FUNC = """\
CREATE OR REPLACE FUNCTION analytics.compute_discount(price FLOAT, pct FLOAT)
RETURNS FLOAT
LANGUAGE SQL
AS
$$
    SELECT price * (1 - pct)
$$;
"""


class TestFunctions:
    def test_redshift_func_to_snowflake(self):
        sql, warns, _ = transpile(REDSHIFT_FUNC, "redshift", "snowflake")
        assert "FUNCTION" in sql
        assert "$$" in sql

    def test_redshift_func_to_bigquery(self):
        sql, warns, _ = transpile(REDSHIFT_FUNC, "redshift", "bigquery")
        assert "FUNCTION" in sql

    def test_redshift_func_to_databricks(self):
        sql, warns, _ = transpile(REDSHIFT_FUNC, "redshift", "databricks")
        assert "FUNCTION" in sql

    def test_redshift_func_to_oracle(self):
        sql, warns, _ = transpile(REDSHIFT_FUNC, "redshift", "oracle")
        assert "FUNCTION" in sql
        assert "RETURN" in sql

    def test_snowflake_func_to_redshift(self):
        sql, warns, _ = transpile(SNOWFLAKE_FUNC, "snowflake", "redshift")
        assert "FUNCTION" in sql
        assert "$$" in sql

    def test_snowflake_func_to_sqlserver(self):
        sql, warns, _ = transpile(SNOWFLAKE_FUNC, "snowflake", "sqlserver")
        assert "FUNCTION" in sql
        assert "RETURNS" in sql

    def test_snowflake_func_to_fabric_dw(self):
        sql, warns, _ = transpile(SNOWFLAKE_FUNC, "snowflake", "fabric_dw")
        assert "FUNCTION" in sql


# ---------------------------------------------------------------------------
# Cross-dialect N×N procedure matrix  (8×8 = 64 pairs, all non-empty)
# ---------------------------------------------------------------------------

PROC_SAMPLES = {
    "redshift": REDSHIFT_PROC,
    "snowflake": SNOWFLAKE_PROC,
    "sqlserver": SQLSERVER_PROC,
    "synapse": SQLSERVER_PROC,   # T-SQL syntax works for Synapse
    "fabric_dw": SQLSERVER_PROC, # T-SQL syntax works for Fabric DW
    "oracle": ORACLE_PROC,
    "bigquery": BIGQUERY_PROC,
    "databricks": REDSHIFT_PROC, # Databricks has no procs — reuse Redshift source
}

ALL_DIALECTS = list(PROC_SAMPLES.keys())


@pytest.mark.parametrize("src", ALL_DIALECTS)
@pytest.mark.parametrize("tgt", ALL_DIALECTS)
def test_proc_cross_dialect(src: str, tgt: str):
    """All 64 source→target pairs must produce non-empty output without crashing."""
    sql_input = PROC_SAMPLES[src]
    result = Transpiler.convert(sql_input, src, tgt)
    assert result.converted_sql, (
        f"Empty output for procedure {src} → {tgt}\n"
        f"Warnings: {[w.message for w in result.warnings]}"
    )
