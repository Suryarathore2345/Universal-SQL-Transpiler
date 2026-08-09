-- ============================================================================
-- Oracle OE (Order Entry) Schema - Types, Tables, Sequences, Indexes
-- Source: oracle-samples/db-sample-schemas (MIT License)
-- Includes object types, relational tables, and cross-schema references to HR
-- ============================================================================

-- ============================================================================
-- OBJECT TYPES
-- ============================================================================

CREATE TYPE cust_address_typ
  OID '82A4AF6A4CD1656DE034080020E0EE3D'
  AS OBJECT
    ( street_address     VARCHAR2(40)
    , postal_code        VARCHAR2(10)
    , city               VARCHAR2(30)
    , state_province     VARCHAR2(10)
    , country_id         CHAR(2)
    );
/

CREATE TYPE phone_list_typ
  OID '82A4AF6A4CD2656DE034080020E0EE3D'
  AS VARRAY(5) OF VARCHAR2(25);
/

-- ============================================================================
-- TABLES
-- ============================================================================

-- customers table (uses object types cust_address_typ, phone_list_typ)
CREATE TABLE customers
    ( customer_id        NUMBER(6)
    , cust_first_name    VARCHAR2(20) CONSTRAINT cust_fname_nn NOT NULL
    , cust_last_name     VARCHAR2(20) CONSTRAINT cust_lname_nn NOT NULL
    , cust_address       cust_address_typ
    , phone_numbers      phone_list_typ
    , nls_language       VARCHAR2(3)
    , nls_territory      VARCHAR2(30)
    , credit_limit       NUMBER(9,2)
    , cust_email         VARCHAR2(40)
    , account_mgr_id     NUMBER(6)
    , cust_geo_location  MDSYS.SDO_GEOMETRY
    , CONSTRAINT         customer_credit_limit_max
                         CHECK (credit_limit <= 5000)
    , CONSTRAINT         customer_id_min
                         CHECK (customer_id > 0)
    ) ;

CREATE UNIQUE INDEX customers_pk
   ON customers (customer_id) ;

ALTER TABLE customers
ADD ( CONSTRAINT customers_pk
      PRIMARY KEY (customer_id)
    ) ;

-- ----------------------------------------------------------------------------

-- warehouses table (uses XMLType and spatial data)
CREATE TABLE warehouses
    ( warehouse_id       NUMBER(3)
    , warehouse_spec     SYS.XMLTYPE
    , warehouse_name     VARCHAR2(35)
    , location_id        NUMBER(4)
    , wh_geo_location    MDSYS.SDO_GEOMETRY
    ) ;

CREATE UNIQUE INDEX warehouses_pk
ON warehouses (warehouse_id) ;

ALTER TABLE warehouses
ADD (CONSTRAINT warehouses_pk PRIMARY KEY (warehouse_id)
    );

-- ----------------------------------------------------------------------------

-- order_items table
CREATE TABLE order_items
    ( order_id           NUMBER(12)
    , line_item_id       NUMBER(3)  NOT NULL
    , product_id         NUMBER(6)  NOT NULL
    , unit_price         NUMBER(8,2)
    , quantity           NUMBER(8)
    ) ;

CREATE UNIQUE INDEX order_items_pk
ON order_items (order_id, line_item_id) ;

CREATE UNIQUE INDEX order_items_uk
ON order_items (order_id, product_id) ;

ALTER TABLE order_items
ADD ( CONSTRAINT order_items_pk PRIMARY KEY (order_id, line_item_id)
    );

-- ----------------------------------------------------------------------------

-- orders table (uses TIMESTAMP WITH LOCAL TIME ZONE)
CREATE TABLE orders
    ( order_id           NUMBER(12)
    , order_date         TIMESTAMP WITH LOCAL TIME ZONE
CONSTRAINT order_date_nn NOT NULL
    , order_mode         VARCHAR2(8)
    , customer_id        NUMBER(6) CONSTRAINT order_customer_id_nn NOT NULL
    , order_status       NUMBER(2)
    , order_total        NUMBER(8,2)
    , sales_rep_id       NUMBER(6)
    , promotion_id       NUMBER(6)
    , CONSTRAINT         order_mode_lov
                         CHECK (order_mode in ('direct','online'))
    , constraint         order_total_min
                         check (order_total >= 0)
    ) ;

CREATE UNIQUE INDEX order_pk
ON orders (order_id) ;

ALTER TABLE orders
ADD ( CONSTRAINT order_pk
      PRIMARY KEY (order_id)
    );

-- ----------------------------------------------------------------------------

-- inventories table (concatenated primary key)
CREATE TABLE inventories
  ( product_id         NUMBER(6)
  , warehouse_id       NUMBER(3) CONSTRAINT inventory_warehouse_id_nn NOT NULL
  , quantity_on_hand   NUMBER(8)
CONSTRAINT inventory_qoh_nn NOT NULL
  , CONSTRAINT inventory_pk PRIMARY KEY (product_id, warehouse_id)
  ) ;

-- ----------------------------------------------------------------------------

-- product_information table (uses INTERVAL datatype and CHECK IN constraint)
CREATE TABLE product_information
    ( product_id          NUMBER(6)
    , product_name        VARCHAR2(50)
    , product_description VARCHAR2(2000)
    , category_id         NUMBER(2)
    , weight_class        NUMBER(1)
    , warranty_period     INTERVAL YEAR TO MONTH
    , supplier_id         NUMBER(6)
    , product_status      VARCHAR2(20)
    , list_price          NUMBER(8,2)
    , min_price           NUMBER(8,2)
    , catalog_url         VARCHAR2(50)
    , CONSTRAINT          product_status_lov
                          CHECK (product_status in ('orderable'
                                                  ,'planned'
                                                  ,'under development'
                                                  ,'obsolete')
                               )
    ) ;

ALTER TABLE product_information
ADD ( CONSTRAINT product_information_pk PRIMARY KEY (product_id)
    );

-- ----------------------------------------------------------------------------

-- product_descriptions table (uses NVARCHAR2 for NLS)
CREATE TABLE product_descriptions
    ( product_id             NUMBER(6)
    , language_id            VARCHAR2(3)
    , translated_name        NVARCHAR2(50)
CONSTRAINT translated_name_nn NOT NULL
    , translated_description NVARCHAR2(2000)
CONSTRAINT translated_desc_nn NOT NULL
    );

CREATE UNIQUE INDEX prd_desc_pk
ON product_descriptions(product_id,language_id) ;

ALTER TABLE product_descriptions
ADD ( CONSTRAINT product_descriptions_pk
	PRIMARY KEY (product_id, language_id));

-- ============================================================================
-- FOREIGN KEY CONSTRAINTS (cross-schema to HR)
-- ============================================================================

ALTER TABLE orders
ADD ( CONSTRAINT orders_sales_rep_fk
      FOREIGN KEY (sales_rep_id)
      REFERENCES hr.employees(employee_id)
      ON DELETE SET NULL
    ) ;

ALTER TABLE orders
ADD ( CONSTRAINT orders_customer_id_fk
      FOREIGN KEY (customer_id)
      REFERENCES customers(customer_id)
      ON DELETE SET NULL
    ) ;

ALTER TABLE warehouses
ADD ( CONSTRAINT warehouses_location_fk
      FOREIGN KEY (location_id)
      REFERENCES hr.locations(location_id)
      ON DELETE SET NULL
    ) ;

ALTER TABLE customers
ADD ( CONSTRAINT customers_account_manager_fk
      FOREIGN KEY (account_mgr_id)
      REFERENCES hr.employees(employee_id)
      ON DELETE SET NULL
    ) ;

ALTER TABLE inventories
ADD ( CONSTRAINT inventories_warehouses_fk
      FOREIGN KEY (warehouse_id)
      REFERENCES warehouses (warehouse_id)
      ENABLE NOVALIDATE
    ) ;

ALTER TABLE inventories
ADD ( CONSTRAINT inventories_product_id_fk
      FOREIGN KEY (product_id)
      REFERENCES product_information (product_id)
    ) ;

ALTER TABLE order_items
ADD ( CONSTRAINT order_items_order_id_fk
      FOREIGN KEY (order_id)
      REFERENCES orders(order_id)
      ON DELETE CASCADE
enable novalidate
    ) ;

ALTER TABLE order_items
ADD ( CONSTRAINT order_items_product_id_fk
      FOREIGN KEY (product_id)
      REFERENCES product_information(product_id)
    ) ;

ALTER TABLE product_descriptions
ADD ( CONSTRAINT pd_product_id_fk
      FOREIGN KEY (product_id)
      REFERENCES product_information(product_id)
    ) ;

-- ============================================================================
-- CROSS-SCHEMA SYNONYMS
-- ============================================================================

CREATE SYNONYM countries FOR hr.countries;
CREATE SYNONYM locations FOR hr.locations;
CREATE SYNONYM departments FOR hr.departments;
CREATE SYNONYM jobs FOR hr.jobs;
CREATE SYNONYM employees FOR hr.employees;
CREATE SYNONYM job_history FOR hr.job_history;

-- ============================================================================
-- SEQUENCES
-- ============================================================================

CREATE SEQUENCE orders_seq
 START WITH     1000
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- ============================================================================
-- TRIGGER
-- ============================================================================

-- Auto-generates line_item_id for new order items
CREATE OR REPLACE TRIGGER insert_ord_line
  BEFORE INSERT ON order_items
  FOR EACH ROW
  DECLARE
    new_line number;
  BEGIN
    SELECT (NVL(MAX(line_item_id),0)+1) INTO new_line
      FROM order_items
      WHERE order_id = :new.order_id;
    :new.line_item_id := new_line;
  END;
/
