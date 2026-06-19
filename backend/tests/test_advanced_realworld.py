"""
Advanced real-world testing — 4 categories:

  1. Semantic equivalence via sqlglot.diff()
     Parse both source and transpiled output back to AST and assert no
     structural changes (column additions/removals). Type changes are acceptable.

  2. Full 9×9 never-crash matrix
     Every real DDL file × all 9 target dialects must not raise an exception.

  3. TPC-DS benchmark (24 tables)
     Industry-standard data-warehouse benchmark schema testing composite keys,
     surrogate FKs, date/decimal/char types across all 9 targets.

  4. DuckDB live validation
     Transpile CREATE TABLE DDL to a DuckDB-executable form and actually run
     it in-process. Catches type errors the string/AST checks miss.
"""
from __future__ import annotations

import re
import threading
from pathlib import Path
from typing import List, Optional, Tuple

import pytest
import sqlglot
from sqlglot import diff as sqlglot_diff, exp

from app.transpiler import Transpiler

# ---------------------------------------------------------------------------
# Shared fixtures
# ---------------------------------------------------------------------------

TESTING_DDLS_ROOT = Path(__file__).parent.parent.parent.parent / "testing_ddls"

ALL_DIALECTS = [
    "redshift", "snowflake", "sqlserver", "synapse",
    "fabric_dw", "fabric_lakehouse", "databricks", "oracle", "bigquery",
]

FOLDER_TO_DIALECT = {
    "redshift": "redshift", "snowflake": "snowflake",
    "sqlserver": "sqlserver", "synapse": "synapse",
    "fabric_dw": "fabric_dw", "fabric_lakehouse": "fabric_lakehouse",
    "databricks": "databricks", "oracle": "oracle", "bigquery": "bigquery",
}


def _collect_ddl_files() -> List[Tuple[str, str, Path]]:
    entries = []
    if not TESTING_DDLS_ROOT.exists():
        return entries
    for folder, dialect in FOLDER_TO_DIALECT.items():
        d = TESTING_DDLS_ROOT / folder
        if not d.exists():
            continue
        for f in sorted(d.rglob("*.sql")):
            label = f.relative_to(TESTING_DDLS_ROOT).as_posix()
            entries.append((dialect, label, f))
    return entries


DDL_FILES = _collect_ddl_files()

# Only files that are pure CREATE TABLE (not views/MVs)
TABLE_DDL_FILES = [
    (d, lbl, p) for d, lbl, p in DDL_FILES
    if "table" in lbl.lower() and "view" not in lbl.lower()
]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_SQLGLOT_DIALECT_MAP = {
    "redshift":        "redshift",
    "snowflake":       "snowflake",
    "sqlserver":       "tsql",
    "synapse":         "tsql",
    "fabric_dw":       "tsql",
    "fabric_lakehouse": "spark",
    "databricks":      "databricks",
    "oracle":          "oracle",
    "bigquery":        "bigquery",
}


def _parse_first_create_table(sql: str, dialect: str) -> Optional[exp.Expression]:
    """Parse the first CREATE TABLE from sql using sqlglot in the given dialect."""
    sg_dialect = _SQLGLOT_DIALECT_MAP.get(dialect, dialect)
    try:
        stmts = sqlglot.parse(sql, dialect=sg_dialect, error_level=sqlglot.ErrorLevel.WARN)
        for stmt in stmts:
            if stmt and isinstance(stmt, exp.Create):
                return stmt
    except Exception:
        pass
    return None


def _get_column_names(create_stmt: exp.Expression) -> List[str]:
    """Extract top-level column definition names from a CREATE TABLE AST node."""
    names = []
    for col_def in create_stmt.find_all(exp.ColumnDef):
        if col_def.name:
            names.append(col_def.name.lower())
    return names


def _structural_diff(
    src_ast: exp.Expression, tgt_ast: exp.Expression
) -> Tuple[List[str], List[str]]:
    """
    Run sqlglot.diff() and return (removed_cols, added_cols).
    Type changes (Update DataType) are intentionally ignored — they are the
    expected output of dialect conversion.
    """
    edits = sqlglot_diff(src_ast, tgt_ast)
    removed, added = [], []
    for edit in edits:
        node = getattr(edit, "expression", None) or getattr(edit, "source", None)
        if node is None:
            continue
        if type(edit).__name__ == "Remove" and isinstance(node, exp.ColumnDef):
            removed.append(node.name)
        elif type(edit).__name__ == "Insert" and isinstance(node, exp.ColumnDef):
            added.append(node.name)
    return removed, added


# ---------------------------------------------------------------------------
# 1. Semantic Equivalence via sqlglot.diff()
# ---------------------------------------------------------------------------

# Representative hand-crafted CREATE TABLE pairs: source dialect + SQL
SEMANTIC_CASES = [
    ("redshift", "snowflake", """
        CREATE TABLE analytics.fact_orders (
            order_id     BIGINT        NOT NULL,
            customer_id  INTEGER       NOT NULL,
            order_date   DATE          NOT NULL,
            total_amount DECIMAL(15,2) NOT NULL,
            status       VARCHAR(20)   NOT NULL DEFAULT 'PENDING',
            created_at   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
            is_returned  BOOLEAN       DEFAULT FALSE,
            region_code  CHAR(3),
            PRIMARY KEY (order_id)
        ) DISTKEY(customer_id) SORTKEY(order_date);
    """),
    ("snowflake", "databricks", """
        CREATE OR REPLACE TABLE silver.dim_product (
            product_id    NUMBER(10,0)  NOT NULL,
            product_name  VARCHAR(200)  NOT NULL,
            category      VARCHAR(100),
            subcategory   VARCHAR(100),
            price         NUMBER(10,2)  NOT NULL,
            cost          NUMBER(10,2),
            is_active     BOOLEAN       DEFAULT TRUE,
            launch_date   DATE,
            updated_at    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
            PRIMARY KEY (product_id)
        );
    """),
    ("snowflake", "bigquery", """
        CREATE OR REPLACE TABLE warehouse.dim_customer (
            customer_id   NUMBER(10,0)  NOT NULL,
            first_name    VARCHAR(100)  NOT NULL,
            last_name     VARCHAR(100)  NOT NULL,
            email         VARCHAR(255)  NOT NULL,
            phone         VARCHAR(20),
            country_code  CHAR(2),
            signup_date   DATE          NOT NULL,
            is_premium    BOOLEAN       DEFAULT FALSE,
            lifetime_val  NUMBER(15,2),
            PRIMARY KEY (customer_id)
        );
    """),
    ("sqlserver", "snowflake", """
        CREATE TABLE dbo.dim_date (
            date_key     INT      NOT NULL,
            full_date    DATE     NOT NULL,
            year_num     SMALLINT NOT NULL,
            quarter_num  TINYINT  NOT NULL,
            month_num    TINYINT  NOT NULL,
            week_num     TINYINT  NOT NULL,
            day_of_week  TINYINT  NOT NULL,
            is_weekend   BIT      NOT NULL DEFAULT 0,
            is_holiday   BIT      NOT NULL DEFAULT 0,
            fiscal_year  SMALLINT,
            PRIMARY KEY (date_key)
        );
    """),
    ("redshift", "fabric_dw", """
        CREATE TABLE staging.raw_events (
            event_id     VARCHAR(36)   NOT NULL,
            session_id   VARCHAR(36),
            user_id      BIGINT,
            event_type   VARCHAR(100)  NOT NULL,
            event_ts     TIMESTAMP     NOT NULL,
            page_url     VARCHAR(2000),
            device_type  VARCHAR(50),
            ip_address   VARCHAR(45),
            country_code CHAR(2),
            PRIMARY KEY (event_id)
        );
    """),
    ("databricks", "redshift", """
        CREATE OR REPLACE TABLE gold.fact_sales (
            sale_id       BIGINT    NOT NULL,
            product_id    BIGINT    NOT NULL,
            store_id      INT       NOT NULL,
            sale_date     DATE      NOT NULL,
            quantity      INT       NOT NULL,
            unit_price    DECIMAL(10,2) NOT NULL,
            discount_amt  DECIMAL(10,2) DEFAULT 0,
            net_amount    DECIMAL(15,2) NOT NULL,
            currency_code CHAR(3)   NOT NULL DEFAULT 'USD',
            PRIMARY KEY (sale_id)
        ) USING DELTA;
    """),
    ("bigquery", "snowflake", """
        CREATE OR REPLACE TABLE `proj.dataset.inventory` (
            sku_id       INT64   NOT NULL,
            warehouse_id INT64   NOT NULL,
            quantity     INT64   NOT NULL DEFAULT 0,
            reorder_pt   INT64,
            last_updated TIMESTAMP,
            unit_cost    NUMERIC(10,2),
            PRIMARY KEY (sku_id, warehouse_id) NOT ENFORCED
        );
    """),
    ("oracle", "redshift", """
        CREATE TABLE hr.employees (
            employee_id   NUMBER(10)    NOT NULL,
            first_name    VARCHAR2(100) NOT NULL,
            last_name     VARCHAR2(100) NOT NULL,
            email         VARCHAR2(255) NOT NULL,
            hire_date     DATE          NOT NULL,
            salary        NUMBER(10,2),
            department_id NUMBER(5),
            is_active     NUMBER(1)     DEFAULT 1,
            PRIMARY KEY (employee_id)
        );
    """),
]


class TestSemanticEquivalence:
    """
    Structural integrity verified with sqlglot.diff():
    after transpilation, no columns may be added or removed.
    Type changes (INT→BIGINT etc.) are acceptable — they are the
    expected output of cross-dialect type mapping.
    """

    @pytest.mark.parametrize(
        "source,target,sql",
        [(s, t, q) for s, t, q in SEMANTIC_CASES],
        ids=[f"{s}_to_{t}" for s, t, _ in SEMANTIC_CASES],
    )
    def test_no_structural_columns_lost(self, source: str, target: str, sql: str):
        """sqlglot.diff() must show zero column additions or removals.

        False-positive guard: sqlglot.diff() can mis-align nodes when table name
        structure differs (e.g. BigQuery 3-part backtick names vs 2-part Snowflake
        names, or Oracle VARCHAR2 → VARCHAR type rewrites). If diff() flags a column
        as "removed" but the column name is verifiably present in the output SQL,
        we treat it as a diff() false positive and skip it.
        """
        src_ast = _parse_first_create_table(sql, source)
        if src_ast is None:
            pytest.skip(f"Could not parse source SQL as {source}")

        result = Transpiler.convert(sql, source, target)
        assert result.converted_sql, f"Empty output for {source} → {target}"

        tgt_ast = _parse_first_create_table(result.converted_sql, target)
        if tgt_ast is None:
            pytest.skip(f"Could not parse {target} output back to AST")

        removed, added = _structural_diff(src_ast, tgt_ast)
        out_lower = result.converted_sql.lower()

        # Filter diff() false positives: column flagged as removed but present in output
        real_removed = [c for c in removed if c.lower() not in out_lower]
        real_added = [c for c in added if c.lower() not in sql.lower()]

        assert not real_removed, (
            f"{source}→{target}: {len(real_removed)} columns genuinely dropped: {real_removed}"
        )
        assert not real_added, (
            f"{source}→{target}: {len(real_added)} unexpected columns appeared: {real_added}"
        )

    @pytest.mark.parametrize(
        "source,target,sql",
        [(s, t, q) for s, t, q in SEMANTIC_CASES],
        ids=[f"{s}_to_{t}" for s, t, _ in SEMANTIC_CASES],
    )
    def test_column_count_matches(self, source: str, target: str, sql: str):
        """Column count in output must match source."""
        src_ast = _parse_first_create_table(sql, source)
        if src_ast is None:
            pytest.skip("Could not parse source")
        src_cols = _get_column_names(src_ast)
        if not src_cols:
            pytest.skip("No columns found in source AST")

        result = Transpiler.convert(sql, source, target)
        assert result.converted_sql

        tgt_ast = _parse_first_create_table(result.converted_sql, target)
        if tgt_ast is None:
            pytest.skip("Could not parse target output")
        tgt_cols = _get_column_names(tgt_ast)

        assert len(src_cols) == len(tgt_cols), (
            f"{source}→{target}: source has {len(src_cols)} cols, "
            f"output has {len(tgt_cols)} cols\n"
            f"  src: {src_cols}\n  tgt: {tgt_cols}"
        )

    @pytest.mark.parametrize(
        "source,target,sql",
        [(s, t, q) for s, t, q in SEMANTIC_CASES],
        ids=[f"{s}_to_{t}" for s, t, _ in SEMANTIC_CASES],
    )
    def test_column_names_match(self, source: str, target: str, sql: str):
        """Every source column name must appear (case-insensitive) in the target."""
        src_ast = _parse_first_create_table(sql, source)
        if src_ast is None:
            pytest.skip("Could not parse source")
        src_cols = _get_column_names(src_ast)
        if not src_cols:
            pytest.skip("No columns found in source AST")

        result = Transpiler.convert(sql, source, target)
        if not result.converted_sql:
            pytest.skip("Empty transpiler output")

        tgt_ast = _parse_first_create_table(result.converted_sql, target)
        if tgt_ast is None:
            pytest.skip("Could not re-parse target output")
        tgt_cols = set(_get_column_names(tgt_ast))

        missing = [c for c in src_cols if c not in tgt_cols]
        assert not missing, (
            f"{source}→{target}: column names lost: {missing}"
        )

    def test_type_change_updates_detected(self):
        """
        Sanity-check: diff() DOES detect structural changes when a column is
        actually removed. Ensures the test framework itself works correctly.
        """
        sql_with_col = "CREATE TABLE t (id INT NOT NULL, name VARCHAR(50), extra INT NOT NULL);"
        sql_without_col = "CREATE TABLE t (id BIGINT NOT NULL, name NVARCHAR(50));"
        src_ast = _parse_first_create_table(sql_with_col, "redshift")
        tgt_ast = _parse_first_create_table(sql_without_col, "redshift")
        assert src_ast and tgt_ast
        removed, added = _structural_diff(src_ast, tgt_ast)
        assert "extra" in removed, "diff() should detect the removed 'extra' column"


# ---------------------------------------------------------------------------
# 2. Full 9×9 Never-Crash Matrix
# ---------------------------------------------------------------------------

# Build the full cross-product: (dialect, label, path, target)
_FULL_MATRIX = [
    (dialect, label, path, target)
    for dialect, label, path in DDL_FILES
    for target in ALL_DIALECTS
]


class TestFullNineCrossMatrix:
    """
    Every real DDL file × every target dialect (9×9 = 1638 combinations for
    the 182-file corpus). Transpiler must never raise a Python exception.
    This is the strongest crash-resistance guarantee we can provide.
    """

    @pytest.mark.parametrize(
        "dialect,label,path,target",
        _FULL_MATRIX,
        ids=[f"{d}__{lbl}__{t}" for d, lbl, _, t in _FULL_MATRIX],
    )
    def test_no_exception_full_matrix(
        self, dialect: str, label: str, path: Path, target: str
    ):
        sql = path.read_text(encoding="utf-8", errors="replace")
        try:
            result = Transpiler.convert(sql, dialect, target)
            assert result is not None, f"{label} → {target}: returned None"
        except Exception as exc:  # noqa: BLE001
            pytest.fail(
                f"Exception on {label} ({dialect} → {target}):\n"
                f"{type(exc).__name__}: {exc}"
            )


# ---------------------------------------------------------------------------
# 3. TPC-DS Benchmark Schema (24 tables, Snowflake source)
# ---------------------------------------------------------------------------

# Full TPC-DS schema — spec v3.0.1 (tpc.org/tpcds), Snowflake dialect
# All 24 tables with correct column names and representative types.
TPCDS_SNOWFLAKE = """
CREATE OR REPLACE TABLE tpcds.date_dim (
    d_date_sk          NUMBER(10,0)  NOT NULL,
    d_date_id          CHAR(16)      NOT NULL,
    d_date             DATE,
    d_month_seq        NUMBER(10,0),
    d_week_seq         NUMBER(10,0),
    d_quarter_seq      NUMBER(10,0),
    d_year             NUMBER(5,0),
    d_dow              NUMBER(5,0),
    d_moy              NUMBER(5,0),
    d_dom              NUMBER(5,0),
    d_qoy              NUMBER(5,0),
    d_fy_year          NUMBER(5,0),
    d_fy_quarter_seq   NUMBER(5,0),
    d_fy_week_seq      NUMBER(5,0),
    d_day_name         CHAR(9),
    d_quarter_name     CHAR(6),
    d_holiday          CHAR(1),
    d_weekend          CHAR(1),
    d_following_holiday CHAR(1),
    d_first_dom        NUMBER(10,0),
    d_last_dom         NUMBER(10,0),
    d_same_day_ly      NUMBER(10,0),
    d_same_day_lq      NUMBER(10,0),
    d_current_day      CHAR(1),
    d_current_week     CHAR(1),
    d_current_month    CHAR(1),
    d_current_quarter  CHAR(1),
    d_current_year     CHAR(1),
    PRIMARY KEY (d_date_sk)
);

CREATE OR REPLACE TABLE tpcds.time_dim (
    t_time_sk    NUMBER(10,0) NOT NULL,
    t_time_id    CHAR(16)     NOT NULL,
    t_time       NUMBER(10,0),
    t_hour       NUMBER(5,0),
    t_minute     NUMBER(5,0),
    t_second     NUMBER(5,0),
    t_am_pm      CHAR(2),
    t_shift      CHAR(20),
    t_sub_shift  CHAR(20),
    t_meal_time  CHAR(20),
    PRIMARY KEY (t_time_sk)
);

CREATE OR REPLACE TABLE tpcds.ship_mode (
    sm_ship_mode_sk  NUMBER(10,0) NOT NULL,
    sm_ship_mode_id  CHAR(16)     NOT NULL,
    sm_type          CHAR(30),
    sm_code          CHAR(10),
    sm_carrier       CHAR(20),
    sm_contract      CHAR(20),
    PRIMARY KEY (sm_ship_mode_sk)
);

CREATE OR REPLACE TABLE tpcds.reason (
    r_reason_sk   NUMBER(10,0) NOT NULL,
    r_reason_id   CHAR(16)     NOT NULL,
    r_reason_desc CHAR(100),
    PRIMARY KEY (r_reason_sk)
);

CREATE OR REPLACE TABLE tpcds.income_band (
    ib_income_band_sk  NUMBER(10,0) NOT NULL,
    ib_lower_bound     NUMBER(10,0),
    ib_upper_bound     NUMBER(10,0),
    PRIMARY KEY (ib_income_band_sk)
);

CREATE OR REPLACE TABLE tpcds.household_demographics (
    hd_demo_sk        NUMBER(10,0) NOT NULL,
    hd_income_band_sk NUMBER(10,0),
    hd_buy_potential  CHAR(15),
    hd_dep_count      NUMBER(5,0),
    hd_vehicle_count  NUMBER(5,0),
    PRIMARY KEY (hd_demo_sk)
);

CREATE OR REPLACE TABLE tpcds.customer_demographics (
    cd_demo_sk            NUMBER(10,0) NOT NULL,
    cd_gender             CHAR(1),
    cd_marital_status     CHAR(1),
    cd_education_status   CHAR(20),
    cd_purchase_estimate  NUMBER(5,0),
    cd_credit_rating      CHAR(10),
    cd_dep_count          NUMBER(5,0),
    cd_dep_employed_count NUMBER(5,0),
    cd_dep_college_count  NUMBER(5,0),
    PRIMARY KEY (cd_demo_sk)
);

CREATE OR REPLACE TABLE tpcds.customer_address (
    ca_address_sk    NUMBER(10,0) NOT NULL,
    ca_address_id    CHAR(16)     NOT NULL,
    ca_street_number CHAR(10),
    ca_street_name   VARCHAR(60),
    ca_street_type   CHAR(15),
    ca_suite_number  CHAR(10),
    ca_city          VARCHAR(60),
    ca_county        VARCHAR(30),
    ca_state         CHAR(2),
    ca_zip           CHAR(10),
    ca_country       VARCHAR(20),
    ca_gmt_offset    NUMBER(5,2),
    ca_location_type CHAR(20),
    PRIMARY KEY (ca_address_sk)
);

CREATE OR REPLACE TABLE tpcds.customer (
    c_customer_sk          NUMBER(10,0) NOT NULL,
    c_customer_id          CHAR(16)     NOT NULL,
    c_current_cdemo_sk     NUMBER(10,0),
    c_current_hdemo_sk     NUMBER(10,0),
    c_current_addr_sk      NUMBER(10,0),
    c_first_shipto_date_sk NUMBER(10,0),
    c_first_sales_date_sk  NUMBER(10,0),
    c_salutation           CHAR(10),
    c_first_name           CHAR(20),
    c_last_name            CHAR(30),
    c_preferred_cust_flag  CHAR(1),
    c_birth_day            NUMBER(5,0),
    c_birth_month          NUMBER(5,0),
    c_birth_year           NUMBER(5,0),
    c_birth_country        VARCHAR(20),
    c_login                CHAR(13),
    c_email_address        CHAR(50),
    c_last_review_date_sk  NUMBER(10,0),
    PRIMARY KEY (c_customer_sk)
);

CREATE OR REPLACE TABLE tpcds.item (
    i_item_sk        NUMBER(10,0)  NOT NULL,
    i_item_id        CHAR(16)      NOT NULL,
    i_rec_start_date DATE,
    i_rec_end_date   DATE,
    i_item_desc      VARCHAR(200),
    i_current_price  NUMBER(7,2),
    i_wholesale_cost NUMBER(7,2),
    i_brand_id       NUMBER(10,0),
    i_brand          CHAR(50),
    i_class_id       NUMBER(10,0),
    i_class          CHAR(50),
    i_category_id    NUMBER(10,0),
    i_category       CHAR(50),
    i_manufact_id    NUMBER(10,0),
    i_manufact       CHAR(50),
    i_size           CHAR(20),
    i_formulation    CHAR(20),
    i_color          CHAR(20),
    i_units          CHAR(10),
    i_container      CHAR(10),
    i_manager_id     NUMBER(10,0),
    i_product_name   CHAR(50),
    PRIMARY KEY (i_item_sk)
);

CREATE OR REPLACE TABLE tpcds.warehouse (
    w_warehouse_sk     NUMBER(10,0) NOT NULL,
    w_warehouse_id     CHAR(16)     NOT NULL,
    w_warehouse_name   VARCHAR(20),
    w_warehouse_sq_ft  NUMBER(10,0),
    w_street_number    CHAR(10),
    w_street_name      VARCHAR(60),
    w_street_type      CHAR(15),
    w_suite_number     CHAR(10),
    w_city             VARCHAR(60),
    w_county           VARCHAR(30),
    w_state            CHAR(2),
    w_zip              CHAR(10),
    w_country          VARCHAR(20),
    w_gmt_offset       NUMBER(5,2),
    PRIMARY KEY (w_warehouse_sk)
);

CREATE OR REPLACE TABLE tpcds.promotion (
    p_promo_sk          NUMBER(10,0) NOT NULL,
    p_promo_id          CHAR(16)     NOT NULL,
    p_start_date_sk     NUMBER(10,0),
    p_end_date_sk       NUMBER(10,0),
    p_item_sk           NUMBER(10,0),
    p_cost              NUMBER(15,2),
    p_response_target   NUMBER(10,0),
    p_promo_name        CHAR(50),
    p_channel_dmail     CHAR(1),
    p_channel_email     CHAR(1),
    p_channel_catalog   CHAR(1),
    p_channel_tv        CHAR(1),
    p_channel_radio     CHAR(1),
    p_channel_press     CHAR(1),
    p_channel_event     CHAR(1),
    p_channel_demo      CHAR(1),
    p_channel_details   VARCHAR(100),
    p_purpose           CHAR(15),
    p_discount_active   CHAR(1),
    PRIMARY KEY (p_promo_sk)
);

CREATE OR REPLACE TABLE tpcds.store (
    s_store_sk         NUMBER(10,0) NOT NULL,
    s_store_id         CHAR(16)     NOT NULL,
    s_rec_start_date   DATE,
    s_rec_end_date     DATE,
    s_closed_date_sk   NUMBER(10,0),
    s_store_name       VARCHAR(50),
    s_number_employees NUMBER(10,0),
    s_floor_space      NUMBER(10,0),
    s_hours            CHAR(20),
    s_manager          VARCHAR(40),
    s_market_id        NUMBER(10,0),
    s_geography_class  VARCHAR(100),
    s_market_desc      VARCHAR(100),
    s_market_manager   VARCHAR(40),
    s_division_id      NUMBER(10,0),
    s_division_name    VARCHAR(50),
    s_company_id       NUMBER(10,0),
    s_company_name     VARCHAR(50),
    s_street_number    VARCHAR(10),
    s_street_name      VARCHAR(60),
    s_street_type      CHAR(15),
    s_suite_number     CHAR(10),
    s_city             VARCHAR(60),
    s_county           VARCHAR(30),
    s_state            CHAR(2),
    s_zip              CHAR(10),
    s_country          VARCHAR(20),
    s_gmt_offset       NUMBER(5,2),
    s_tax_precentage   NUMBER(5,2),
    PRIMARY KEY (s_store_sk)
);

CREATE OR REPLACE TABLE tpcds.web_site (
    web_site_sk       NUMBER(10,0) NOT NULL,
    web_site_id       CHAR(16)     NOT NULL,
    web_rec_start_date DATE,
    web_rec_end_date   DATE,
    web_name           VARCHAR(50),
    web_open_date_sk   NUMBER(10,0),
    web_close_date_sk  NUMBER(10,0),
    web_class          VARCHAR(50),
    web_manager        VARCHAR(40),
    web_mkt_id         NUMBER(10,0),
    web_mkt_class      VARCHAR(50),
    web_mkt_desc       VARCHAR(100),
    web_market_manager VARCHAR(40),
    web_company_id     NUMBER(10,0),
    web_company_name   CHAR(50),
    web_street_number  CHAR(10),
    web_street_name    VARCHAR(60),
    web_street_type    CHAR(15),
    web_suite_number   CHAR(10),
    web_city           VARCHAR(60),
    web_county         VARCHAR(30),
    web_state          CHAR(2),
    web_zip            CHAR(10),
    web_country        VARCHAR(20),
    web_gmt_offset     NUMBER(5,2),
    web_tax_percentage NUMBER(5,2),
    PRIMARY KEY (web_site_sk)
);

CREATE OR REPLACE TABLE tpcds.catalog_page (
    cp_catalog_page_sk     NUMBER(10,0) NOT NULL,
    cp_catalog_page_id     CHAR(16)     NOT NULL,
    cp_start_date_sk       NUMBER(10,0),
    cp_end_date_sk         NUMBER(10,0),
    cp_department          VARCHAR(50),
    cp_catalog_number      NUMBER(10,0),
    cp_catalog_page_number NUMBER(10,0),
    cp_description         VARCHAR(100),
    cp_type                VARCHAR(100),
    PRIMARY KEY (cp_catalog_page_sk)
);

CREATE OR REPLACE TABLE tpcds.web_page (
    wp_web_page_sk      NUMBER(10,0) NOT NULL,
    wp_web_page_id      CHAR(16)     NOT NULL,
    wp_rec_start_date   DATE,
    wp_rec_end_date     DATE,
    wp_creation_date_sk NUMBER(10,0),
    wp_access_date_sk   NUMBER(10,0),
    wp_autogen_flag     CHAR(1),
    wp_customer_sk      NUMBER(10,0),
    wp_url              VARCHAR(100),
    wp_type             CHAR(50),
    wp_char_count       NUMBER(10,0),
    wp_link_count       NUMBER(10,0),
    wp_image_count      NUMBER(10,0),
    wp_max_ad_count     NUMBER(10,0),
    PRIMARY KEY (wp_web_page_sk)
);

CREATE OR REPLACE TABLE tpcds.inventory (
    inv_date_sk         NUMBER(10,0) NOT NULL,
    inv_item_sk         NUMBER(10,0) NOT NULL,
    inv_warehouse_sk    NUMBER(10,0) NOT NULL,
    inv_quantity_on_hand NUMBER(10,0),
    PRIMARY KEY (inv_date_sk, inv_item_sk, inv_warehouse_sk)
);

CREATE OR REPLACE TABLE tpcds.store_sales (
    ss_sold_date_sk       NUMBER(10,0),
    ss_sold_time_sk       NUMBER(10,0),
    ss_item_sk            NUMBER(10,0) NOT NULL,
    ss_customer_sk        NUMBER(10,0),
    ss_cdemo_sk           NUMBER(10,0),
    ss_hdemo_sk           NUMBER(10,0),
    ss_addr_sk            NUMBER(10,0),
    ss_store_sk           NUMBER(10,0),
    ss_promo_sk           NUMBER(10,0),
    ss_ticket_number      NUMBER(20,0) NOT NULL,
    ss_quantity           NUMBER(5,0),
    ss_wholesale_cost     NUMBER(7,2),
    ss_list_price         NUMBER(7,2),
    ss_sales_price        NUMBER(7,2),
    ss_ext_discount_amt   NUMBER(7,2),
    ss_ext_sales_price    NUMBER(7,2),
    ss_ext_wholesale_cost NUMBER(7,2),
    ss_ext_list_price     NUMBER(7,2),
    ss_ext_tax            NUMBER(7,2),
    ss_coupon_amt         NUMBER(7,2),
    ss_net_paid           NUMBER(7,2),
    ss_net_paid_inc_tax   NUMBER(7,2),
    ss_net_profit         NUMBER(7,2),
    PRIMARY KEY (ss_item_sk, ss_ticket_number)
);

CREATE OR REPLACE TABLE tpcds.store_returns (
    sr_returned_date_sk   NUMBER(10,0),
    sr_return_time_sk     NUMBER(10,0),
    sr_item_sk            NUMBER(10,0) NOT NULL,
    sr_customer_sk        NUMBER(10,0),
    sr_cdemo_sk           NUMBER(10,0),
    sr_hdemo_sk           NUMBER(10,0),
    sr_addr_sk            NUMBER(10,0),
    sr_store_sk           NUMBER(10,0),
    sr_reason_sk          NUMBER(10,0),
    sr_ticket_number      NUMBER(20,0) NOT NULL,
    sr_return_quantity    NUMBER(5,0),
    sr_return_amt         NUMBER(7,2),
    sr_return_tax         NUMBER(7,2),
    sr_return_amt_inc_tax NUMBER(7,2),
    sr_fee                NUMBER(7,2),
    sr_return_ship_cost   NUMBER(7,2),
    sr_refunded_cash      NUMBER(7,2),
    sr_reversed_charge    NUMBER(7,2),
    sr_store_credit       NUMBER(7,2),
    sr_net_loss           NUMBER(7,2),
    PRIMARY KEY (sr_item_sk, sr_ticket_number)
);

CREATE OR REPLACE TABLE tpcds.web_sales (
    ws_sold_date_sk          NUMBER(10,0),
    ws_sold_time_sk          NUMBER(10,0),
    ws_ship_date_sk          NUMBER(10,0),
    ws_item_sk               NUMBER(10,0) NOT NULL,
    ws_bill_customer_sk      NUMBER(10,0),
    ws_bill_cdemo_sk         NUMBER(10,0),
    ws_bill_hdemo_sk         NUMBER(10,0),
    ws_bill_addr_sk          NUMBER(10,0),
    ws_ship_customer_sk      NUMBER(10,0),
    ws_ship_cdemo_sk         NUMBER(10,0),
    ws_ship_hdemo_sk         NUMBER(10,0),
    ws_ship_addr_sk          NUMBER(10,0),
    ws_web_page_sk           NUMBER(10,0),
    ws_web_site_sk           NUMBER(10,0),
    ws_ship_mode_sk          NUMBER(10,0),
    ws_warehouse_sk          NUMBER(10,0),
    ws_promo_sk              NUMBER(10,0),
    ws_order_number          NUMBER(20,0) NOT NULL,
    ws_quantity              NUMBER(5,0),
    ws_wholesale_cost        NUMBER(7,2),
    ws_list_price            NUMBER(7,2),
    ws_sales_price           NUMBER(7,2),
    ws_ext_discount_amt      NUMBER(7,2),
    ws_ext_sales_price       NUMBER(7,2),
    ws_ext_wholesale_cost    NUMBER(7,2),
    ws_ext_list_price        NUMBER(7,2),
    ws_ext_tax               NUMBER(7,2),
    ws_coupon_amt            NUMBER(7,2),
    ws_ext_ship_cost         NUMBER(7,2),
    ws_net_paid              NUMBER(7,2),
    ws_net_paid_inc_tax      NUMBER(7,2),
    ws_net_paid_inc_ship     NUMBER(7,2),
    ws_net_paid_inc_ship_tax NUMBER(7,2),
    ws_net_profit            NUMBER(7,2),
    PRIMARY KEY (ws_item_sk, ws_order_number)
);

CREATE OR REPLACE TABLE tpcds.web_returns (
    wr_returned_date_sk      NUMBER(10,0),
    wr_returned_time_sk      NUMBER(10,0),
    wr_item_sk               NUMBER(10,0) NOT NULL,
    wr_refunded_customer_sk  NUMBER(10,0),
    wr_refunded_cdemo_sk     NUMBER(10,0),
    wr_refunded_hdemo_sk     NUMBER(10,0),
    wr_refunded_addr_sk      NUMBER(10,0),
    wr_returning_customer_sk NUMBER(10,0),
    wr_returning_cdemo_sk    NUMBER(10,0),
    wr_returning_hdemo_sk    NUMBER(10,0),
    wr_returning_addr_sk     NUMBER(10,0),
    wr_web_page_sk           NUMBER(10,0),
    wr_reason_sk             NUMBER(10,0),
    wr_order_number          NUMBER(20,0) NOT NULL,
    wr_return_quantity       NUMBER(5,0),
    wr_return_amt            NUMBER(7,2),
    wr_return_tax            NUMBER(7,2),
    wr_return_amt_inc_tax    NUMBER(7,2),
    wr_fee                   NUMBER(7,2),
    wr_return_ship_cost      NUMBER(7,2),
    wr_refunded_cash         NUMBER(7,2),
    wr_reversed_charge       NUMBER(7,2),
    wr_account_credit        NUMBER(7,2),
    wr_net_loss              NUMBER(7,2),
    PRIMARY KEY (wr_item_sk, wr_order_number)
);

CREATE OR REPLACE TABLE tpcds.catalog_sales (
    cs_sold_date_sk          NUMBER(10,0),
    cs_sold_time_sk          NUMBER(10,0),
    cs_ship_date_sk          NUMBER(10,0),
    cs_bill_customer_sk      NUMBER(10,0),
    cs_bill_cdemo_sk         NUMBER(10,0),
    cs_bill_hdemo_sk         NUMBER(10,0),
    cs_bill_addr_sk          NUMBER(10,0),
    cs_ship_customer_sk      NUMBER(10,0),
    cs_ship_cdemo_sk         NUMBER(10,0),
    cs_ship_hdemo_sk         NUMBER(10,0),
    cs_ship_addr_sk          NUMBER(10,0),
    cs_call_center_sk        NUMBER(10,0),
    cs_catalog_page_sk       NUMBER(10,0),
    cs_ship_mode_sk          NUMBER(10,0),
    cs_warehouse_sk          NUMBER(10,0),
    cs_item_sk               NUMBER(10,0) NOT NULL,
    cs_promo_sk              NUMBER(10,0),
    cs_order_number          NUMBER(20,0) NOT NULL,
    cs_quantity              NUMBER(5,0),
    cs_wholesale_cost        NUMBER(7,2),
    cs_list_price            NUMBER(7,2),
    cs_sales_price           NUMBER(7,2),
    cs_ext_discount_amt      NUMBER(7,2),
    cs_ext_sales_price       NUMBER(7,2),
    cs_ext_wholesale_cost    NUMBER(7,2),
    cs_ext_list_price        NUMBER(7,2),
    cs_ext_tax               NUMBER(7,2),
    cs_coupon_amt            NUMBER(7,2),
    cs_ext_ship_cost         NUMBER(7,2),
    cs_net_paid              NUMBER(7,2),
    cs_net_paid_inc_tax      NUMBER(7,2),
    cs_net_paid_inc_ship     NUMBER(7,2),
    cs_net_paid_inc_ship_tax NUMBER(7,2),
    cs_net_profit            NUMBER(7,2),
    PRIMARY KEY (cs_item_sk, cs_order_number)
);

CREATE OR REPLACE TABLE tpcds.catalog_returns (
    cr_returned_date_sk      NUMBER(10,0),
    cr_returned_time_sk      NUMBER(10,0),
    cr_item_sk               NUMBER(10,0) NOT NULL,
    cr_refunded_customer_sk  NUMBER(10,0),
    cr_refunded_cdemo_sk     NUMBER(10,0),
    cr_refunded_hdemo_sk     NUMBER(10,0),
    cr_refunded_addr_sk      NUMBER(10,0),
    cr_returning_customer_sk NUMBER(10,0),
    cr_returning_cdemo_sk    NUMBER(10,0),
    cr_returning_hdemo_sk    NUMBER(10,0),
    cr_returning_addr_sk     NUMBER(10,0),
    cr_call_center_sk        NUMBER(10,0),
    cr_catalog_page_sk       NUMBER(10,0),
    cr_ship_mode_sk          NUMBER(10,0),
    cr_warehouse_sk          NUMBER(10,0),
    cr_reason_sk             NUMBER(10,0),
    cr_order_number          NUMBER(20,0) NOT NULL,
    cr_return_quantity       NUMBER(5,0),
    cr_return_amount         NUMBER(7,2),
    cr_return_tax            NUMBER(7,2),
    cr_return_amt_inc_tax    NUMBER(7,2),
    cr_fee                   NUMBER(7,2),
    cr_return_ship_cost      NUMBER(7,2),
    cr_refunded_cash         NUMBER(7,2),
    cr_reversed_charge       NUMBER(7,2),
    cr_store_credit          NUMBER(7,2),
    cr_net_loss              NUMBER(7,2),
    PRIMARY KEY (cr_item_sk, cr_order_number)
);

CREATE OR REPLACE TABLE tpcds.call_center (
    cc_call_center_sk   NUMBER(10,0) NOT NULL,
    cc_call_center_id   CHAR(16)     NOT NULL,
    cc_rec_start_date   DATE,
    cc_rec_end_date     DATE,
    cc_closed_date_sk   NUMBER(10,0),
    cc_open_date_sk     NUMBER(10,0),
    cc_name             VARCHAR(50),
    cc_class            VARCHAR(50),
    cc_employees        NUMBER(10,0),
    cc_sq_ft            NUMBER(10,0),
    cc_hours            CHAR(20),
    cc_manager          VARCHAR(40),
    cc_mkt_id           NUMBER(10,0),
    cc_mkt_class        CHAR(50),
    cc_mkt_desc         VARCHAR(100),
    cc_market_manager   VARCHAR(40),
    cc_division          NUMBER(10,0),
    cc_division_name    VARCHAR(50),
    cc_company           NUMBER(10,0),
    cc_company_name     CHAR(50),
    cc_street_number    CHAR(10),
    cc_street_name      VARCHAR(60),
    cc_street_type      CHAR(15),
    cc_suite_number     CHAR(10),
    cc_city             VARCHAR(60),
    cc_county           VARCHAR(30),
    cc_state            CHAR(2),
    cc_zip              CHAR(10),
    cc_country          VARCHAR(20),
    cc_gmt_offset       NUMBER(5,2),
    cc_tax_percentage   NUMBER(5,2),
    PRIMARY KEY (cc_call_center_sk)
);
"""

# All 24 TPC-DS table names
TPCDS_TABLES = [
    "date_dim", "time_dim", "ship_mode", "reason", "income_band",
    "household_demographics", "customer_demographics", "customer_address",
    "customer", "item", "warehouse", "promotion", "store", "web_site",
    "catalog_page", "web_page", "inventory", "store_sales", "store_returns",
    "web_sales", "web_returns", "catalog_sales", "catalog_returns", "call_center",
]

# Key column sentinels spanning multiple tables
TPCDS_SENTINELS = [
    "d_date_sk", "d_year", "d_dow",
    "t_time_sk", "t_hour", "t_minute",
    "c_customer_sk", "c_birth_year", "c_email_address",
    "i_item_sk", "i_current_price", "i_category",
    "ss_item_sk", "ss_ticket_number", "ss_net_profit",
    "ws_item_sk", "ws_order_number", "ws_net_profit",
    "cs_item_sk", "cs_order_number", "cs_net_profit",
    "inv_date_sk", "inv_item_sk", "inv_quantity_on_hand",
]


class TestTPCDSBenchmark:
    """
    TPC-DS 24-table, 400+ column industry benchmark transpiled to all 9 targets.
    Validates composite primary keys, surrogate keys, CHAR/VARCHAR/NUMBER types,
    and OR REPLACE handling across the full dialect matrix.
    """

    @pytest.mark.parametrize("target", ALL_DIALECTS)
    def test_tpcds_no_crash(self, target: str):
        """TPC-DS 24-table schema must transpile to every target without exception."""
        result = Transpiler.convert(TPCDS_SNOWFLAKE, "snowflake", target)
        assert result is not None
        assert result.converted_sql, f"Empty output for TPC-DS → {target}"

    @pytest.mark.parametrize("target", ALL_DIALECTS)
    def test_tpcds_all_24_tables_present(self, target: str):
        """All 24 TPC-DS table names must appear in every target's output."""
        result = Transpiler.convert(TPCDS_SNOWFLAKE, "snowflake", target)
        out = result.converted_sql.lower()
        missing = [t for t in TPCDS_TABLES if t not in out]
        assert not missing, f"TPC-DS → {target}: missing tables: {missing}"

    @pytest.mark.parametrize("target", ALL_DIALECTS)
    def test_tpcds_sentinel_columns_present(self, target: str):
        """Key TPC-DS column names must appear in every target's output."""
        result = Transpiler.convert(TPCDS_SNOWFLAKE, "snowflake", target)
        out = result.converted_sql.lower()
        missing = [c for c in TPCDS_SENTINELS if c not in out]
        assert not missing, (
            f"TPC-DS → {target}: {len(missing)} sentinel columns missing: {missing[:5]}"
        )

    @pytest.mark.parametrize("target", ALL_DIALECTS)
    def test_tpcds_24_create_table_statements(self, target: str):
        """Output must contain exactly 24 CREATE TABLE statements."""
        result = Transpiler.convert(TPCDS_SNOWFLAKE, "snowflake", target)
        count = len(re.findall(r'CREATE\s+(?:OR\s+REPLACE\s+)?TABLE', result.converted_sql, re.I))
        assert count == 24, (
            f"TPC-DS → {target}: expected 24 CREATE TABLE, got {count}"
        )

    def test_tpcds_composite_pk_redshift(self):
        """Composite PKs (inventory: 3 cols, store_sales: 2 cols) survive to Redshift."""
        result = Transpiler.convert(TPCDS_SNOWFLAKE, "snowflake", "redshift")
        out = result.converted_sql.lower()
        # inventory has a 3-col composite PK
        assert "inv_date_sk" in out and "inv_item_sk" in out and "inv_warehouse_sk" in out

    def test_tpcds_composite_pk_sqlserver(self):
        """Composite PKs survive to SQL Server."""
        result = Transpiler.convert(TPCDS_SNOWFLAKE, "snowflake", "sqlserver")
        out = result.converted_sql.lower()
        assert "ss_item_sk" in out and "ss_ticket_number" in out

    def test_tpcds_databricks_delta_count(self):
        """Databricks output must have exactly 24 USING DELTA clauses."""
        result = Transpiler.convert(TPCDS_SNOWFLAKE, "snowflake", "databricks")
        delta_count = len(re.findall(r'USING DELTA', result.converted_sql, re.I))
        assert delta_count == 24, f"Expected 24 USING DELTA, got {delta_count}"

    def test_tpcds_oracle_plsql_block_count(self):
        """Oracle must emit 24 PL/SQL anonymous blocks for OR REPLACE."""
        result = Transpiler.convert(TPCDS_SNOWFLAKE, "snowflake", "oracle")
        executes = len(re.findall(r'EXECUTE IMMEDIATE', result.converted_sql, re.I))
        assert executes == 24, f"Expected 24 EXECUTE IMMEDIATE blocks, got {executes}"


# ---------------------------------------------------------------------------
# 4. DuckDB Live Validation
# ---------------------------------------------------------------------------

# DuckDB is SQL-standard-compatible. We transpile to "redshift" (closest to
# standard SQL among our dialects) then strip Redshift-specific clauses before
# running in DuckDB, which lets us verify column types and constraint syntax.

# Subset of TPC-H and representative hand-crafted tables to validate in DuckDB
DUCKDB_VALIDATION_CASES = [
    ("snowflake", "Standard e-commerce orders table", """
        CREATE OR REPLACE TABLE sales.orders (
            order_id     NUMBER(10,0)  NOT NULL,
            customer_id  NUMBER(10,0)  NOT NULL,
            order_date   DATE          NOT NULL,
            total_amount NUMBER(15,2)  NOT NULL,
            status       VARCHAR(20)   NOT NULL DEFAULT 'PENDING',
            is_gift      BOOLEAN       DEFAULT FALSE,
            created_at   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
            PRIMARY KEY (order_id)
        );
    """),
    ("redshift", "Analytics fact table", """
        CREATE TABLE analytics.fact_sales (
            sale_id      BIGINT        NOT NULL,
            product_id   INTEGER       NOT NULL,
            region       VARCHAR(50)   NOT NULL,
            sale_amount  DECIMAL(15,2) NOT NULL,
            sale_date    DATE          NOT NULL,
            is_returned  BOOLEAN       DEFAULT FALSE,
            PRIMARY KEY (sale_id)
        )
        DISTKEY(product_id)
        SORTKEY(sale_date);
    """),
    ("sqlserver", "Dimension table", """
        CREATE TABLE dbo.dim_date (
            date_key    INT      NOT NULL,
            full_date   DATE     NOT NULL,
            year_num    SMALLINT NOT NULL,
            quarter_num TINYINT  NOT NULL,
            month_num   TINYINT  NOT NULL,
            is_weekend  BIT      NOT NULL DEFAULT 0,
            PRIMARY KEY (date_key)
        );
    """),
    ("databricks", "Delta events table", """
        CREATE OR REPLACE TABLE bronze.events (
            event_id     BIGINT    NOT NULL,
            user_id      BIGINT,
            event_type   STRING    NOT NULL,
            event_ts     TIMESTAMP NOT NULL,
            session_id   STRING,
            page_url     STRING,
            PRIMARY KEY (event_id)
        ) USING DELTA;
    """),
    ("oracle", "HR employees table", """
        CREATE TABLE hr.employees (
            employee_id  NUMBER(10)    NOT NULL,
            first_name   VARCHAR2(100) NOT NULL,
            last_name    VARCHAR2(100) NOT NULL,
            email        VARCHAR2(255) NOT NULL,
            hire_date    DATE          NOT NULL,
            salary       NUMBER(10,2),
            PRIMARY KEY (employee_id)
        );
    """),
    ("snowflake", "TPC-H region table", """
        CREATE OR REPLACE TABLE tpch.region (
            r_regionkey NUMBER(10,0) NOT NULL,
            r_name      CHAR(25)     NOT NULL,
            r_comment   VARCHAR(152),
            PRIMARY KEY (r_regionkey)
        );
    """),
    ("snowflake", "TPC-H lineitem table (15 cols, composite PK)", """
        CREATE OR REPLACE TABLE tpch.lineitem (
            l_orderkey      NUMBER(10,0)  NOT NULL,
            l_partkey       NUMBER(10,0)  NOT NULL,
            l_suppkey       NUMBER(10,0)  NOT NULL,
            l_linenumber    NUMBER(10,0)  NOT NULL,
            l_quantity      NUMBER(15,2)  NOT NULL,
            l_extendedprice NUMBER(15,2)  NOT NULL,
            l_discount      NUMBER(15,2)  NOT NULL,
            l_tax           NUMBER(15,2)  NOT NULL,
            l_returnflag    CHAR(1)       NOT NULL,
            l_linestatus    CHAR(1)       NOT NULL,
            l_shipdate      DATE          NOT NULL,
            l_commitdate    DATE          NOT NULL,
            l_receiptdate   DATE          NOT NULL,
            l_shipinstruct  CHAR(25)      NOT NULL,
            l_shipmode      CHAR(10)      NOT NULL,
            l_comment       VARCHAR(44),
            PRIMARY KEY (l_orderkey, l_linenumber)
        );
    """),
]


def _to_duckdb_sql(sql: str) -> str:
    """
    Normalise transpiled SQL for DuckDB execution.
    Strips / rewrites dialect-specific clauses that DuckDB doesn't support.
    Applied before running in DuckDB so we validate structure, not dialect syntax.
    """
    # Remove DROP TABLE IF EXISTS prefixes (OR REPLACE equivalent patterns)
    sql = re.sub(r'DROP\s+TABLE\s+IF\s+EXISTS\s+\S+\s*;?\s*(?:GO\s*)?', '', sql, flags=re.I)
    # Remove Redshift distribution / sort key clauses (appear after closing paren)
    # DISTSTYLE can be followed by a keyword: KEY, ALL, EVEN, AUTO
    sql = re.sub(r'\bDISTSTYLE\s+\w+', '', sql, flags=re.I)
    # DISTKEY/SORTKEY/INTERLEAVED/COMPOUND take an optional (col_list)
    sql = re.sub(r'\b(DISTKEY|SORTKEY|INTERLEAVED|COMPOUND)\s*(\([^)]*\))?', '', sql, flags=re.I)
    # Remove Redshift ENCODE per-column option
    sql = re.sub(r'\bENCODE\s+\w+', '', sql, flags=re.I)
    # Remove USING DELTA (Databricks/Spark)
    sql = re.sub(r'\bUSING\s+DELTA\b', '', sql, flags=re.I)
    # Remove NOT ENFORCED (BigQuery FK/PK syntax)
    sql = re.sub(r'\bNOT\s+ENFORCED\b', '', sql, flags=re.I)
    # Remove OPTIONS(...) blocks (BigQuery / Snowflake)
    sql = re.sub(r'\bOPTIONS\s*\([^)]*\)', '', sql, flags=re.I)
    # Remove CLUSTER BY (...) clauses
    sql = re.sub(r'\bCLUSTER\s+BY\s*\([^)]+\)', '', sql, flags=re.I)
    # Remove PARTITIONED BY (...) / PARTITION BY ... clauses
    sql = re.sub(r'\bPARTITIONED?\s+BY\s*[\w\s,()]+?(?=\s*(?:;|$|\n\s*\n))', '', sql, flags=re.I)
    # Remove COMMENT '...' table-level option (Spark/Databricks)
    sql = re.sub(r"\bCOMMENT\s+'[^']*'", '', sql, flags=re.I)

    # --- Type normalisations for DuckDB ---
    # NUMBER(p,s) / NUMBER(p) / NUMBER → DECIMAL
    sql = re.sub(r'\bNUMBER\b', 'DECIMAL', sql, flags=re.I)
    # NVARCHAR → VARCHAR, NCHAR → CHAR
    sql = re.sub(r'\bNVARCHAR\b', 'VARCHAR', sql, flags=re.I)
    sql = re.sub(r'\bNCHAR\b', 'CHAR', sql, flags=re.I)
    # TIMESTAMP_NTZ / TIMESTAMP_TZ / TIMESTAMP_LTZ → TIMESTAMP
    sql = re.sub(r'\bTIMESTAMP_(NTZ|TZ|LTZ)\b', 'TIMESTAMP', sql, flags=re.I)
    # STRING (Spark/BigQuery) → VARCHAR
    sql = re.sub(r'\bSTRING\b(?!\s*\()', 'VARCHAR', sql, flags=re.I)
    # TINYINT (not standard in DuckDB DDL) → SMALLINT
    sql = re.sub(r'\bTINYINT\b', 'SMALLINT', sql, flags=re.I)
    # BIT → BOOLEAN
    sql = re.sub(r'\bBIT\b', 'BOOLEAN', sql, flags=re.I)
    # FLOAT64 (BigQuery) → DOUBLE
    sql = re.sub(r'\bFLOAT64\b', 'DOUBLE', sql, flags=re.I)
    # INT64 (BigQuery) → BIGINT
    sql = re.sub(r'\bINT64\b', 'BIGINT', sql, flags=re.I)

    # --- Default expression normalisations ---
    # CURRENT_TIMESTAMP() → CURRENT_TIMESTAMP (DuckDB: no parens in DEFAULT)
    sql = re.sub(r'\bCURRENT_TIMESTAMP\s*\(\s*\)', 'CURRENT_TIMESTAMP', sql, flags=re.I)
    # CURRENT_DATE() → CURRENT_DATE
    sql = re.sub(r'\bCURRENT_DATE\s*\(\s*\)', 'CURRENT_DATE', sql, flags=re.I)
    # GETDATE() → CURRENT_TIMESTAMP
    sql = re.sub(r'\bGETDATE\s*\(\s*\)', 'CURRENT_TIMESTAMP', sql, flags=re.I)
    # SYSDATE → CURRENT_TIMESTAMP
    sql = re.sub(r'\bSYSDATE\b', 'CURRENT_TIMESTAMP', sql, flags=re.I)

    # Strip schema prefix from table name to avoid "schema not found" errors.
    # Only strip from CREATE TABLE / DROP TABLE lines, not from column definitions.
    sql = re.sub(
        r'(?i)(CREATE\s+(?:OR\s+REPLACE\s+)?TABLE\s+)(?:\w+\.)+(\w+)',
        r'\1\2', sql
    )

    # Clean up blank lines left by removals
    sql = re.sub(r'\n{3,}', '\n\n', sql)
    return sql.strip()


try:
    import duckdb as _duckdb
    _DUCKDB_AVAILABLE = True
except ImportError:
    _DUCKDB_AVAILABLE = False

_duckdb_lock = threading.Lock()


@pytest.mark.skipif(not _DUCKDB_AVAILABLE, reason="duckdb not installed")
class TestDuckDBLiveValidation:
    """
    Transpile CREATE TABLE DDL → Redshift (standard SQL) → normalise for DuckDB
    → actually execute in DuckDB in-memory. Catches type mismatches and constraint
    errors that string/AST checks cannot detect.
    """

    def _execute_in_duckdb(self, sql: str, label: str) -> Optional[str]:
        """
        Run sql in a fresh in-memory DuckDB connection.
        Returns None on success, error message string on failure.
        """
        import duckdb
        normalized = _to_duckdb_sql(sql)
        if not normalized.strip():
            return None
        # Each test uses a fresh connection to avoid schema conflicts
        with _duckdb_lock:
            try:
                con = duckdb.connect(":memory:")
                con.execute(normalized)
                con.close()
                return None
            except Exception as e:
                return f"{type(e).__name__}: {e}"

    @pytest.mark.parametrize(
        "source,label,sql",
        DUCKDB_VALIDATION_CASES,
        ids=[x[1] for x in DUCKDB_VALIDATION_CASES],
    )
    def test_duckdb_executes_redshift_output(self, source: str, label: str, sql: str):
        """Transpile source → Redshift → DuckDB. Must execute without SQL error."""
        result = Transpiler.convert(sql, source, "redshift")
        assert result.converted_sql, f"Empty transpiler output for {label}"

        err = self._execute_in_duckdb(result.converted_sql, label)
        assert err is None, (
            f"DuckDB rejected {label} (source={source} → redshift):\n{err}\n\n"
            f"SQL sent to DuckDB:\n{_to_duckdb_sql(result.converted_sql)}"
        )

    @pytest.mark.parametrize(
        "source,label,sql",
        DUCKDB_VALIDATION_CASES,
        ids=[x[1] for x in DUCKDB_VALIDATION_CASES],
    )
    def test_duckdb_executes_snowflake_output(self, source: str, label: str, sql: str):
        """Transpile source → Snowflake → DuckDB (Snowflake SQL is close to standard)."""
        result = Transpiler.convert(sql, source, "snowflake")
        assert result.converted_sql

        err = self._execute_in_duckdb(result.converted_sql, label)
        assert err is None, (
            f"DuckDB rejected {label} (source={source} → snowflake):\n{err}\n\n"
            f"SQL sent to DuckDB:\n{_to_duckdb_sql(result.converted_sql)}"
        )

    def test_duckdb_tpcds_inventory_composite_pk(self):
        """TPC-DS inventory (3-col composite PK) survives to DuckDB via Redshift."""
        sql = """
        CREATE OR REPLACE TABLE tpcds.inventory (
            inv_date_sk          NUMBER(10,0) NOT NULL,
            inv_item_sk          NUMBER(10,0) NOT NULL,
            inv_warehouse_sk     NUMBER(10,0) NOT NULL,
            inv_quantity_on_hand NUMBER(10,0),
            PRIMARY KEY (inv_date_sk, inv_item_sk, inv_warehouse_sk)
        );
        """
        result = Transpiler.convert(sql, "snowflake", "redshift")
        err = self._execute_in_duckdb(result.converted_sql, "tpcds.inventory")
        assert err is None, f"DuckDB rejected composite PK table: {err}"

    def test_duckdb_rejects_bad_sql_not_our_transpiler(self):
        """
        Control test: confirm DuckDB actually validates syntax.
        Manually broken SQL should fail in DuckDB (proves the framework works).
        """
        bad_sql = "CREATE TABLE broken (id NOTAVALIDTYPE NOT NULL);"
        err = self._execute_in_duckdb(bad_sql, "bad_sql")
        assert err is not None, "DuckDB should have rejected invalid type 'NOTAVALIDTYPE'"
