-- Snowflake: Logistics & Supply Chain Tables

CREATE OR REPLACE TABLE logistics.warehouses (
    warehouse_id    INTEGER NOT NULL AUTOINCREMENT,
    warehouse_code  VARCHAR(20) NOT NULL UNIQUE,
    warehouse_name  VARCHAR(200) NOT NULL,
    address         VARCHAR(300),
    city            VARCHAR(100),
    country_code    CHAR(2),
    capacity_sqm    DECIMAL(10,2),
    manager_name    VARCHAR(200),
    phone           VARCHAR(30),
    is_active       BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (warehouse_id)
);

CREATE OR REPLACE TABLE logistics.carriers (
    carrier_id      INTEGER NOT NULL AUTOINCREMENT,
    carrier_code    VARCHAR(20) NOT NULL UNIQUE,
    carrier_name    VARCHAR(200) NOT NULL,
    service_type    VARCHAR(50),
    tracking_url    VARCHAR(300),
    is_active       BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (carrier_id)
);

CREATE OR REPLACE TABLE logistics.shipments (
    shipment_id     BIGINT NOT NULL AUTOINCREMENT,
    order_id        BIGINT NOT NULL,
    carrier_id      INTEGER NOT NULL,
    warehouse_id    INTEGER,
    tracking_number VARCHAR(100),
    status          VARCHAR(30) DEFAULT 'PENDING',
    ship_date       DATE,
    estimated_delivery DATE,
    actual_delivery DATE,
    weight_kg       DECIMAL(8,3),
    dimensions_cm   VARCHAR(50),
    freight_cost    DECIMAL(10,2),
    insurance_value DECIMAL(12,2),
    signature_required BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (shipment_id)
);

CREATE OR REPLACE TABLE logistics.shipment_events (
    event_id        BIGINT NOT NULL AUTOINCREMENT,
    shipment_id     BIGINT NOT NULL,
    event_code      VARCHAR(30) NOT NULL,
    event_desc      VARCHAR(200),
    location_city   VARCHAR(100),
    location_country CHAR(2),
    latitude        DECIMAL(10,7),
    longitude       DECIMAL(10,7),
    occurred_at     TIMESTAMP_NTZ NOT NULL,
    source          VARCHAR(50),
    PRIMARY KEY (event_id),
    FOREIGN KEY (shipment_id) REFERENCES logistics.shipments(shipment_id)
);

CREATE OR REPLACE TABLE logistics.purchase_orders (
    po_id           BIGINT NOT NULL AUTOINCREMENT,
    po_number       VARCHAR(50) NOT NULL UNIQUE,
    vendor_id       INTEGER NOT NULL,
    warehouse_id    INTEGER,
    status          VARCHAR(30) DEFAULT 'DRAFT',
    order_date      DATE NOT NULL,
    expected_date   DATE,
    received_date   DATE,
    total_amount    DECIMAL(14,2),
    currency        CHAR(3) DEFAULT 'USD',
    notes           TEXT,
    created_by      VARCHAR(100),
    approved_by     VARCHAR(100),
    approved_at     TIMESTAMP_NTZ,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (po_id)
);

CREATE OR REPLACE TABLE logistics.po_lines (
    po_line_id      BIGINT NOT NULL AUTOINCREMENT,
    po_id           BIGINT NOT NULL,
    product_id      BIGINT NOT NULL,
    ordered_qty     INTEGER NOT NULL,
    received_qty    INTEGER DEFAULT 0,
    unit_cost       DECIMAL(12,2) NOT NULL,
    line_total      DECIMAL(14,2) NOT NULL,
    expected_date   DATE,
    status          VARCHAR(20) DEFAULT 'OPEN',
    PRIMARY KEY (po_line_id),
    FOREIGN KEY (po_id) REFERENCES logistics.purchase_orders(po_id)
);
