-- Snowflake: Audit, Security, and Change Tracking Tables

CREATE OR REPLACE TABLE audit.audit_log (
    log_id          BIGINT NOT NULL AUTOINCREMENT,
    event_time      TIMESTAMP_NTZ NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    user_name       VARCHAR(200) NOT NULL,
    user_role       VARCHAR(100),
    session_id      VARCHAR(100),
    ip_address      VARCHAR(45),
    action          VARCHAR(50) NOT NULL,
    resource_type   VARCHAR(100) NOT NULL,
    resource_id     VARCHAR(200),
    resource_schema VARCHAR(100),
    old_values      VARIANT,
    new_values      VARIANT,
    status          VARCHAR(20) DEFAULT 'SUCCESS',
    error_message   TEXT,
    PRIMARY KEY (log_id)
)
CLUSTER BY (DATE_TRUNC('day', event_time), user_name);

CREATE OR REPLACE TABLE audit.query_history (
    query_id        VARCHAR(100) NOT NULL,
    query_text      TEXT NOT NULL,
    user_name       VARCHAR(200) NOT NULL,
    database_name   VARCHAR(100),
    schema_name     VARCHAR(100),
    warehouse_name  VARCHAR(100),
    start_time      TIMESTAMP_NTZ NOT NULL,
    end_time        TIMESTAMP_NTZ,
    duration_ms     BIGINT,
    rows_produced   BIGINT,
    bytes_scanned   BIGINT,
    status          VARCHAR(30),
    error_code      VARCHAR(20),
    error_message   TEXT,
    PRIMARY KEY (query_id)
);

CREATE OR REPLACE TABLE audit.data_access_log (
    access_id       BIGINT NOT NULL AUTOINCREMENT,
    accessed_at     TIMESTAMP_NTZ NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    user_name       VARCHAR(200) NOT NULL,
    table_schema    VARCHAR(100) NOT NULL,
    table_name      VARCHAR(200) NOT NULL,
    access_type     VARCHAR(20) NOT NULL,
    row_count       BIGINT,
    columns_accessed VARCHAR(2000),
    query_id        VARCHAR(100),
    classification  VARCHAR(50),
    PRIMARY KEY (access_id)
);

CREATE OR REPLACE TABLE audit.role_assignments (
    assignment_id   BIGINT NOT NULL AUTOINCREMENT,
    grantee_type    VARCHAR(20) NOT NULL,
    grantee_name    VARCHAR(200) NOT NULL,
    role_name       VARCHAR(200) NOT NULL,
    privilege       VARCHAR(50),
    object_type     VARCHAR(50),
    object_name     VARCHAR(300),
    granted_by      VARCHAR(200),
    granted_at      TIMESTAMP_NTZ NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    revoked_at      TIMESTAMP_NTZ,
    revoked_by      VARCHAR(200),
    is_active       BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (assignment_id)
);

CREATE OR REPLACE TABLE audit.data_classification (
    classification_id INTEGER NOT NULL AUTOINCREMENT,
    table_schema    VARCHAR(100) NOT NULL,
    table_name      VARCHAR(200) NOT NULL,
    column_name     VARCHAR(200) NOT NULL,
    classification  VARCHAR(50) NOT NULL,
    sub_category    VARCHAR(50),
    pii_flag        BOOLEAN DEFAULT FALSE,
    phi_flag        BOOLEAN DEFAULT FALSE,
    pci_flag        BOOLEAN DEFAULT FALSE,
    masking_policy  VARCHAR(200),
    classified_by   VARCHAR(100),
    classified_at   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    reviewed_at     TIMESTAMP_NTZ,
    PRIMARY KEY (classification_id)
);

CREATE OR REPLACE TABLE audit.schema_change_log (
    change_id       BIGINT NOT NULL AUTOINCREMENT,
    changed_at      TIMESTAMP_NTZ NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    object_type     VARCHAR(50) NOT NULL,
    object_schema   VARCHAR(100),
    object_name     VARCHAR(200) NOT NULL,
    change_type     VARCHAR(30) NOT NULL,
    ddl_statement   TEXT,
    changed_by      VARCHAR(200) NOT NULL,
    session_id      VARCHAR(100),
    is_destructive  BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (change_id)
);
