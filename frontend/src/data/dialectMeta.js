/**
 * Dialect metadata: brand colors, gradient pairs, sample DDL per source dialect.
 * Brand colors verified against official documentation / brand kits.
 */

// ── Brand colors ──────────────────────────────────────────────────────────
export const DIALECT_COLORS = {
  redshift:   { primary: '#FF9900', secondary: '#FF6B35', glow: 'rgba(255,153,0,0.15)' },
  snowflake:  { primary: '#29B5E8', secondary: '#0099CC', glow: 'rgba(41,181,232,0.15)' },
  sqlserver:  { primary: '#CC2927', secondary: '#E8423F', glow: 'rgba(204,41,39,0.15)'  },
  synapse:    { primary: '#8764B8', secondary: '#0078D4', glow: 'rgba(135,100,184,0.15)'},
  fabric_dw:  { primary: '#00B294', secondary: '#00D4A8', glow: 'rgba(0,178,148,0.15)'  },
  databricks: { primary: '#FF3621', secondary: '#FF6B47', glow: 'rgba(255,54,33,0.15)'  },
  oracle:     { primary: '#F80000', secondary: '#CC0000', glow: 'rgba(248,0,0,0.15)'    },
  bigquery:   { primary: '#4285F4', secondary: '#34A853', glow: 'rgba(66,133,244,0.15)' },
}

// ── Sample DDL per SOURCE dialect ─────────────────────────────────────────
// Each uses that dialect's native syntax so the user sees realistic input.

export const DIALECT_SAMPLES = {
  redshift: `-- Amazon Redshift DDL
CREATE TABLE public.orders (
    order_id    BIGINT          IDENTITY(1,1),
    customer_id INTEGER         NOT NULL,
    amount      DECIMAL(18, 2)  NOT NULL,
    status      VARCHAR(32)     DEFAULT 'pending',
    created_at  TIMESTAMP       NOT NULL,
    PRIMARY KEY (order_id)
)
DISTSTYLE KEY
DISTKEY (customer_id)
SORTKEY (created_at);`,

  snowflake: `-- Snowflake DDL
CREATE OR REPLACE TABLE orders_db.public.orders (
    order_id    NUMBER          AUTOINCREMENT PRIMARY KEY,
    customer_id NUMBER(10,0)    NOT NULL,
    amount      NUMBER(18, 2)   NOT NULL,
    status      VARCHAR(32)     DEFAULT 'pending',
    created_at  TIMESTAMP_NTZ   NOT NULL
)
CLUSTER BY (TO_DATE(created_at));`,

  sqlserver: `-- Microsoft SQL Server DDL
CREATE TABLE dbo.orders (
    order_id    BIGINT          IDENTITY(1,1) NOT NULL,
    customer_id INT             NOT NULL,
    amount      DECIMAL(18, 2)  NOT NULL,
    status      NVARCHAR(32)    DEFAULT 'pending',
    created_at  DATETIME2(6)    NOT NULL,
    CONSTRAINT PK_orders PRIMARY KEY CLUSTERED (order_id)
);`,

  synapse: `-- Azure Synapse Analytics DDL
CREATE TABLE dbo.orders (
    order_id    BIGINT          NOT NULL,
    customer_id INT             NOT NULL,
    amount      DECIMAL(18, 2)  NOT NULL,
    status      NVARCHAR(32)    DEFAULT 'pending',
    created_at  DATETIME2       NOT NULL
)
WITH (
    DISTRIBUTION = HASH(customer_id),
    CLUSTERED COLUMNSTORE INDEX
);`,

  fabric_dw: `-- Microsoft Fabric Data Warehouse DDL
CREATE TABLE dbo.orders (
    order_id    BIGINT          NOT NULL,
    customer_id INT             NOT NULL,
    amount      DECIMAL(18, 2)  NOT NULL,
    status      VARCHAR(32)     NOT NULL,
    created_at  DATETIME2       NOT NULL,
    PRIMARY KEY (order_id)
)
WITH (CLUSTER BY (created_at));`,

  databricks: `-- Databricks (Delta Lake) DDL
CREATE OR REPLACE TABLE main.public.orders (
    order_id    BIGINT          GENERATED ALWAYS AS IDENTITY,
    customer_id INT             NOT NULL,
    amount      DECIMAL(18, 2)  NOT NULL,
    status      STRING          DEFAULT 'pending',
    created_at  TIMESTAMP       NOT NULL
)
USING DELTA
PARTITIONED BY (DATE(created_at))
TBLPROPERTIES ('delta.autoOptimize.optimizeWrite' = 'true');`,

  oracle: `-- Oracle Database DDL
CREATE TABLE orders (
    order_id    NUMBER          GENERATED ALWAYS AS IDENTITY,
    customer_id NUMBER(10)      NOT NULL,
    amount      NUMBER(18, 2)   NOT NULL,
    status      VARCHAR2(32)    DEFAULT 'pending',
    created_at  TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT PK_orders PRIMARY KEY (order_id)
);`,

  bigquery: `-- Google BigQuery DDL
CREATE OR REPLACE TABLE \`project.dataset.orders\` (
    order_id    INT64           NOT NULL,
    customer_id INT64           NOT NULL,
    amount      NUMERIC         NOT NULL,
    status      STRING,
    created_at  TIMESTAMP       NOT NULL
)
PARTITION BY DATE(created_at)
CLUSTER BY customer_id;`,
}
