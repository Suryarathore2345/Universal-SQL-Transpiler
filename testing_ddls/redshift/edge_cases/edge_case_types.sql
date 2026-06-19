-- Redshift edge-case DDL: data type mappings
-- Tests every major type our transpiler converts

CREATE TABLE reporting.type_mapping_test (
    -- Integer types
    col_smallint        SMALLINT,
    col_int             INTEGER,
    col_int2            INT2,
    col_int4            INT4,
    col_bigint          BIGINT,
    col_int8            INT8,

    -- Numeric
    col_decimal         DECIMAL(18, 4),
    col_numeric         NUMERIC(12, 2),
    col_real            REAL,
    col_float4          FLOAT4,
    col_float8          FLOAT8,
    col_double          DOUBLE PRECISION,

    -- Character
    col_char            CHAR(10),
    col_varchar         VARCHAR(256),
    col_nvarchar        NVARCHAR(512),
    col_text            TEXT,
    col_char1           CHARACTER(5),
    col_varchar2        CHARACTER VARYING(100),

    -- Date/time
    col_date            DATE,
    col_timestamp       TIMESTAMP,
    col_timestamptz     TIMESTAMPTZ,
    col_timestamp_ntz   TIMESTAMP WITHOUT TIME ZONE,
    col_timestamp_tz    TIMESTAMP WITH TIME ZONE,
    col_time            TIME,
    col_timetz          TIMETZ,

    -- Boolean
    col_bool            BOOLEAN,

    -- Special Redshift types
    col_super           SUPER,
    col_hllsketch       HLLSKETCH,
    col_varbyte         VARBYTE(256)
);

CREATE TABLE reporting.constraint_test (
    id          BIGINT          NOT NULL,
    code        VARCHAR(20)     NOT NULL,
    name        VARCHAR(100)    NOT NULL DEFAULT 'Unknown',
    sort_order  INTEGER         DEFAULT 0,
    is_active   BOOLEAN         DEFAULT TRUE,
    created_at  TIMESTAMP       DEFAULT GETDATE(),
    category    VARCHAR(50),
    CONSTRAINT pk_constraint_test PRIMARY KEY (id),
    CONSTRAINT uq_code UNIQUE (code)
)
DISTSTYLE KEY
DISTKEY (id)
SORTKEY (is_active, created_at);

-- Table with ENCODE compression
CREATE TABLE reporting.encoded_table (
    id          BIGINT   ENCODE ZSTD,
    name        VARCHAR(100) ENCODE ZSTD,
    value       DECIMAL(15,4) ENCODE DELTA32K,
    category    VARCHAR(50) ENCODE BYTEDICT,
    created_at  TIMESTAMP ENCODE DELTA
)
DISTSTYLE EVEN
SORTKEY (created_at);
