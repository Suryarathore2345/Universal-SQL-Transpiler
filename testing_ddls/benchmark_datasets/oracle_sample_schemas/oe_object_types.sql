-- ============================================================================
-- Oracle OE (Order Entry) Schema - OC Subschema Object Types and Object Tables
-- Source: oracle-samples/db-sample-schemas (MIT License)
-- Advanced Oracle features: object types, type inheritance, nested tables,
-- REF types, object views, INSTEAD OF triggers, type bodies
-- ============================================================================

-- ============================================================================
-- OBJECT TYPES
-- ============================================================================

CREATE TYPE warehouse_typ
 OID '82A4AF6A4CD3656DE034080020E0EE3D'
 AS OBJECT
    ( warehouse_id       NUMBER(3)
    , warehouse_name     VARCHAR2(35)
    , location_id        NUMBER(4)
    ) ;
/

CREATE TYPE inventory_typ
 OID '82A4AF6A4CD4656DE034080020E0EE3D'
 AS OBJECT
    ( product_id          NUMBER(6)
    , warehouse           warehouse_typ
    , quantity_on_hand    NUMBER(8)
    ) ;
/

CREATE TYPE inventory_list_typ
 OID '82A4AF6A4CD5656DE034080020E0EE3D'
 AS TABLE OF inventory_typ;
/

CREATE TYPE product_information_typ
 OID '82A4AF6A4CD6656DE034080020E0EE3D'
 AS OBJECT
    ( product_id           NUMBER(6)
    , product_name         VARCHAR2(50)
    , product_description  VARCHAR2(2000)
    , category_id          NUMBER(2)
    , weight_class         NUMBER(1)
    , warranty_period      INTERVAL YEAR(2) TO MONTH
    , supplier_id          NUMBER(6)
    , product_status       VARCHAR2(20)
    , list_price           NUMBER(8,2)
    , min_price            NUMBER(8,2)
    , catalog_url          VARCHAR2(50)
    , inventory_list       inventory_list_typ
    ) ;
/

CREATE TYPE order_item_typ
 OID '82A4AF6A4CD7656DE034080020E0EE3D'
 AS OBJECT
    ( order_id           NUMBER(12)
    , line_item_id       NUMBER(3)
    , unit_price         NUMBER(8,2)
    , quantity           NUMBER(8)
    , product_ref  REF   product_information_typ
    ) ;
/

CREATE TYPE order_item_list_typ
 OID '82A4AF6A4CD8656DE034080020E0EE3D'
 AS TABLE OF order_item_typ;
/

-- Forward declaration of customer_typ
CREATE TYPE customer_typ
 OID '82A4AF6A4CD9656DE034080020E0EE3D';
/

CREATE TYPE order_typ
 OID '82A4AF6A4CDA656DE034080020E0EE3D'
 AS OBJECT
    ( order_id           NUMBER(12)
    , order_mode         VARCHAR2(8)
    , customer_ref  REF  customer_typ
    , order_status       NUMBER(2)
    , order_total        NUMBER(8,2)
    , sales_rep_id       NUMBER(6)
    , order_item_list    order_item_list_typ
    ) ;
/

CREATE TYPE order_list_typ
 OID '82A4AF6A4CDB656DE034080020E0EE3D'
 AS TABLE OF order_typ;
/

-- Full definition of customer_typ (replaces forward declaration)
CREATE OR REPLACE TYPE customer_typ
 AS OBJECT
    ( customer_id        NUMBER(6)
    , cust_first_name    VARCHAR2(20)
    , cust_last_name     VARCHAR2(20)
    , cust_address       cust_address_typ
    , phone_numbers      phone_list_typ
    , nls_language       VARCHAR2(3)
    , nls_territory      VARCHAR2(40)
    , credit_limit       NUMBER(9,2)
    , cust_email         VARCHAR2(40)
    , cust_orders        order_list_typ
    )
NOT FINAL;
/

-- ============================================================================
-- TYPE INHERITANCE (NOT INSTANTIABLE, UNDER)
-- ============================================================================

CREATE TYPE category_typ
 OID '82A4AF6A4CDC656DE034080020E0EE3D'
 AS OBJECT
    ( category_name           VARCHAR2(50)
    , category_description    VARCHAR2(1000)
    , category_id             NUMBER(2)
    , NOT instantiable
      MEMBER FUNCTION category_describe RETURN VARCHAR2
      )
  NOT INSTANTIABLE NOT FINAL;
/

CREATE TYPE subcategory_ref_list_typ
 OID '82A4AF6A4CDD656DE034080020E0EE3D'
 AS TABLE OF REF category_typ;
/

CREATE TYPE product_ref_list_typ
 OID '82A4AF6A4CDE656DE034080020E0EE3D'
 AS TABLE OF number(6);
/

-- Subtype of customer_typ
CREATE TYPE corporate_customer_typ
 OID '82A4AF6A4CDF656DE034080020E0EE3D'
 UNDER customer_typ
      ( account_mgr_id     NUMBER(6)
      );
/

-- Subtype of category_typ with OVERRIDING method
CREATE TYPE leaf_category_typ
 OID '82A4AF6A4CE0656DE034080020E0EE3D'
 UNDER category_typ
    (
    product_ref_list    product_ref_list_typ
    , OVERRIDING MEMBER FUNCTION  category_describe RETURN VARCHAR2
    );
/

CREATE TYPE BODY leaf_category_typ AS
    OVERRIDING MEMBER FUNCTION  category_describe RETURN VARCHAR2 IS
    BEGIN
       RETURN  'leaf_category_typ';
    END;
   END;
/

CREATE TYPE composite_category_typ
 OID '82A4AF6A4CE1656DE034080020E0EE3D'
 UNDER category_typ
      (
    subcategory_ref_list subcategory_ref_list_typ
      , OVERRIDING MEMBER FUNCTION  category_describe RETURN VARCHAR2
      )
  NOT FINAL;
/

CREATE TYPE BODY composite_category_typ  AS
    OVERRIDING MEMBER FUNCTION category_describe RETURN VARCHAR2 IS
    BEGIN
      RETURN 'composite_category_typ';
    END;
   END;
/

CREATE TYPE catalog_typ
 OID '82A4AF6A4CE2656DE034080020E0EE3D'
 UNDER composite_category_typ
      (
    MEMBER FUNCTION getCatalogName RETURN VARCHAR2
       , OVERRIDING MEMBER FUNCTION category_describe RETURN VARCHAR2
      );
/

CREATE TYPE BODY catalog_typ AS
  OVERRIDING MEMBER FUNCTION category_describe RETURN varchar2 IS
  BEGIN
    RETURN 'catalog_typ';
  END;
  MEMBER FUNCTION getCatalogName RETURN varchar2 IS
  BEGIN
    RETURN self.category_name;
  END;
END;
/

-- ============================================================================
-- OBJECT TABLE (with nested tables)
-- ============================================================================

CREATE TABLE categories_tab OF category_typ
    ( category_id PRIMARY KEY)
  NESTED TABLE TREAT
 (OBJECT_VALUE AS leaf_category_typ).product_ref_list
    STORE AS product_ref_list_nestedtab
  NESTED TABLE TREAT
 (OBJECT_VALUE AS composite_category_typ).subcategory_ref_list
    STORE AS subcategory_ref_list_nestedtab;

-- ============================================================================
-- OBJECT VIEWS (with REF, CAST, MULTISET)
-- ============================================================================

CREATE OR REPLACE VIEW oc_inventories OF inventory_typ
 WITH OBJECT OID (product_id)
 AS SELECT i.product_id,
           warehouse_typ(w.warehouse_id, w.warehouse_name, w.location_id),
           i.quantity_on_hand
    FROM inventories i, warehouses w
    WHERE i.warehouse_id=w.warehouse_id;

CREATE OR REPLACE VIEW oc_product_information OF product_information_typ
 WITH OBJECT OID (product_id)
 AS SELECT p.product_id, p.product_name, p.product_description, p.category_id,
           p.weight_class, p.warranty_period, p.supplier_id, p.product_status,
           p.list_price, p.min_price, p.catalog_url,
           CAST(MULTISET(SELECT i.product_id,i.warehouse,i.quantity_on_hand
                         FROM oc_inventories i
                         WHERE p.product_id=i.product_id)
                AS inventory_list_typ)
    FROM product_information p;

CREATE OR REPLACE VIEW oc_customers OF customer_typ
 WITH OBJECT OID (customer_id)
 AS SELECT c.customer_id, c.cust_first_name, c.cust_last_name, c.cust_address,
           c.phone_numbers,c.nls_language,c.nls_territory,c.credit_limit,
           c.cust_email,
           CAST(MULTISET(SELECT o.order_id, o.order_mode,
                               MAKE_REF(oc_customers,o.customer_id),
                               o.order_status,
                               o.order_total,o.sales_rep_id,
                               CAST(MULTISET(SELECT l.order_id,l.line_item_id,
                                                    l.unit_price,l.quantity,
                                             MAKE_REF(oc_product_information,
                                                      l.product_id)
                                             FROM order_items l
                                             WHERE o.order_id = l.order_id)
                                    AS order_item_list_typ)
                         FROM orders o
                         WHERE c.customer_id = o.customer_id)
                AS order_list_typ)
     FROM customers c;

CREATE OR REPLACE VIEW oc_corporate_customers OF corporate_customer_typ
  UNDER oc_customers
    AS SELECT c.customer_id, c.cust_first_name, c.cust_last_name,
              c.cust_address, c.phone_numbers,c.nls_language,c.nls_territory,
              c.credit_limit, c.cust_email,
              CAST(MULTISET(SELECT o.order_id, o.order_mode,
                               MAKE_REF(oc_customers,o.customer_id),
                               o.order_status,
                               o.order_total,o.sales_rep_id,
                               CAST(MULTISET(SELECT l.order_id,l.line_item_id,
                                         l.unit_price,l.quantity,
                                         make_ref(oc_product_information,
                                                    l.product_id)
                                             FROM order_items l
                                             WHERE o.order_id = l.order_id)
                                    AS order_item_list_typ)
                            FROM orders o
                            WHERE c.customer_id = o.customer_id)
              AS order_list_typ), c.account_mgr_id
     FROM customers c;

CREATE OR REPLACE VIEW oc_orders OF order_typ WITH OBJECT OID (order_id)
 AS SELECT o.order_id, o.order_mode,MAKE_REF(oc_customers,o.customer_id),
        o.order_status,o.order_total,o.sales_rep_id,
       CAST(MULTISET(SELECT l.order_id,l.line_item_id,l.unit_price,l.quantity,
                       make_ref(oc_product_information,l.product_id)
                     FROM order_items l
                     WHERE o.order_id = l.order_id)
            AS order_item_list_typ)
    FROM orders o;

-- ============================================================================
-- INSTEAD-OF TRIGGERS (for object views)
-- ============================================================================

CREATE OR REPLACE TRIGGER orders_trg INSTEAD OF INSERT
 ON oc_orders FOR EACH ROW
BEGIN
   INSERT INTO ORDERS (order_id, order_mode, order_total,
                       sales_rep_id, order_status)
               VALUES (:NEW.order_id, :NEW.order_mode,
                       :NEW.order_total, :NEW.sales_rep_id,
                       :NEW.order_status);
END;
/

CREATE OR REPLACE TRIGGER orders_items_trg INSTEAD OF INSERT ON NESTED
 TABLE order_item_list OF oc_orders FOR EACH ROW
DECLARE
    prod  product_information_typ;
BEGIN
    SELECT DEREF(:NEW.product_ref) INTO prod FROM DUAL;
    INSERT INTO order_items VALUES (prod.product_id, :NEW.order_id,
                                    :NEW.line_item_id, :NEW.unit_price,
                                    :NEW.quantity);
END;
/
