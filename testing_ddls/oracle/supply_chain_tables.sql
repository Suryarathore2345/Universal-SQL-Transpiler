-- Oracle: Supply Chain & Logistics Tables

CREATE TABLE supply_chain.warehouses (
    warehouse_id    NUMBER(10) NOT NULL,
    warehouse_code  VARCHAR2(20) NOT NULL,
    warehouse_name  VARCHAR2(200) NOT NULL,
    address         VARCHAR2(300),
    city            VARCHAR2(100),
    country_code    CHAR(2),
    capacity_sqm    NUMBER(10,2),
    manager_name    VARCHAR2(200),
    phone           VARCHAR2(30),
    is_active       NUMBER(1) DEFAULT 1,
    CONSTRAINT pk_warehouses PRIMARY KEY (warehouse_id),
    CONSTRAINT uq_wh_code UNIQUE (warehouse_code)
);

CREATE TABLE supply_chain.suppliers (
    supplier_id     NUMBER(10) NOT NULL,
    supplier_code   VARCHAR2(30) NOT NULL,
    supplier_name   VARCHAR2(255) NOT NULL,
    country_code    CHAR(2),
    contact_name    VARCHAR2(200),
    contact_email   VARCHAR2(255),
    phone           VARCHAR2(30),
    payment_terms   VARCHAR2(30) DEFAULT 'NET30',
    lead_time_days  NUMBER(5) DEFAULT 7,
    quality_rating  NUMBER(3,1),
    is_active       NUMBER(1) DEFAULT 1,
    created_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_suppliers PRIMARY KEY (supplier_id),
    CONSTRAINT uq_supplier_code UNIQUE (supplier_code)
);

CREATE TABLE supply_chain.purchase_orders (
    po_id           NUMBER(19) NOT NULL,
    po_number       VARCHAR2(50) NOT NULL,
    supplier_id     NUMBER(10) NOT NULL,
    warehouse_id    NUMBER(10),
    status          VARCHAR2(30) DEFAULT 'DRAFT',
    order_date      DATE NOT NULL,
    expected_date   DATE,
    received_date   DATE,
    total_amount    NUMBER(14,2),
    currency        CHAR(3) DEFAULT 'USD',
    notes           CLOB,
    created_by      VARCHAR2(100),
    approved_by     VARCHAR2(100),
    approved_at     TIMESTAMP,
    created_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_po PRIMARY KEY (po_id),
    CONSTRAINT uq_po_number UNIQUE (po_number),
    CONSTRAINT fk_po_supplier FOREIGN KEY (supplier_id) REFERENCES supply_chain.suppliers(supplier_id),
    CONSTRAINT fk_po_warehouse FOREIGN KEY (warehouse_id) REFERENCES supply_chain.warehouses(warehouse_id)
);

CREATE TABLE supply_chain.po_lines (
    po_line_id      NUMBER(19) NOT NULL,
    po_id           NUMBER(19) NOT NULL,
    line_number     NUMBER(5) NOT NULL,
    product_id      NUMBER(19) NOT NULL,
    product_desc    VARCHAR2(255),
    ordered_qty     NUMBER(10) NOT NULL,
    received_qty    NUMBER(10) DEFAULT 0,
    unit_cost       NUMBER(12,2) NOT NULL,
    line_total      NUMBER(14,2) NOT NULL,
    expected_date   DATE,
    status          VARCHAR2(20) DEFAULT 'OPEN',
    CONSTRAINT pk_po_lines PRIMARY KEY (po_line_id),
    CONSTRAINT fk_pol_po FOREIGN KEY (po_id) REFERENCES supply_chain.purchase_orders(po_id)
);

CREATE TABLE supply_chain.inventory (
    inventory_id    NUMBER(19) NOT NULL,
    warehouse_id    NUMBER(10) NOT NULL,
    product_id      NUMBER(19) NOT NULL,
    lot_number      VARCHAR2(50),
    qty_on_hand     NUMBER(10) NOT NULL DEFAULT 0,
    qty_reserved    NUMBER(10) NOT NULL DEFAULT 0,
    qty_available   NUMBER(10) NOT NULL DEFAULT 0,
    unit_cost       NUMBER(12,2),
    expiry_date     DATE,
    last_counted_at TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_inventory PRIMARY KEY (inventory_id),
    CONSTRAINT fk_inv_warehouse FOREIGN KEY (warehouse_id) REFERENCES supply_chain.warehouses(warehouse_id)
);

CREATE TABLE supply_chain.shipments (
    shipment_id     NUMBER(19) NOT NULL,
    po_id           NUMBER(19),
    warehouse_id    NUMBER(10),
    carrier_name    VARCHAR2(100),
    tracking_number VARCHAR2(100),
    status          VARCHAR2(30) DEFAULT 'PENDING',
    ship_date       DATE,
    estimated_delivery DATE,
    actual_delivery DATE,
    weight_kg       NUMBER(8,3),
    freight_cost    NUMBER(10,2),
    created_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_shipments PRIMARY KEY (shipment_id)
);
