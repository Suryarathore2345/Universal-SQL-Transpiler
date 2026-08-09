-- ============================================================================
-- Oracle OE (Order Entry) Schema - Views
-- Source: oracle-samples/db-sample-schemas (MIT License)
-- ============================================================================

-- View: products
-- Joins product_information with product_descriptions for NLS support
CREATE OR REPLACE VIEW products
AS
SELECT i.product_id
,      d.language_id
,      CASE WHEN d.language_id IS NOT NULL
            THEN d.translated_name
            ELSE TRANSLATE(i.product_name USING NCHAR_CS)
       END    AS product_name
,      i.category_id
,      CASE WHEN d.language_id IS NOT NULL
            THEN d.translated_description
            ELSE TRANSLATE(i.product_description USING NCHAR_CS)
       END    AS product_description
,      i.weight_class
,      i.warranty_period
,      i.supplier_id
,      i.product_status
,      i.list_price
,      i.min_price
,      i.catalog_url
FROM   product_information  i
,      product_descriptions d
WHERE  d.product_id  (+) = i.product_id
AND    d.language_id (+) = sys_context('USERENV','LANG');

-- View: sydney_inventory
CREATE OR REPLACE VIEW sydney_inventory
AS
SELECT p.product_id
,      p.product_name
,      i.quantity_on_hand
FROM   inventories i
,      warehouses  w
,      products    p
WHERE  p.product_id = i.product_id
AND    i.warehouse_id = w.warehouse_id
AND    w.warehouse_name = 'Sydney';

-- View: bombay_inventory
CREATE OR REPLACE VIEW bombay_inventory
AS
SELECT p.product_id
,      p.product_name
,      i.quantity_on_hand
FROM   inventories i
,      warehouses  w
,      products    p
WHERE  p.product_id = i.product_id
AND    i.warehouse_id = w.warehouse_id
AND    w.warehouse_name = 'Bombay';

-- View: toronto_inventory
CREATE OR REPLACE VIEW toronto_inventory
AS
SELECT p.product_id
,      p.product_name
,      i.quantity_on_hand
FROM   inventories i
,      warehouses  w
,      products    p
WHERE  p.product_id = i.product_id
AND    i.warehouse_id = w.warehouse_id
AND    w.warehouse_name = 'Toronto';

-- View: product_prices (GROUP BY aggregation)
CREATE OR REPLACE VIEW product_prices
AS
SELECT category_id
,      COUNT(*)        as "#_OF_PRODUCTS"
,      MIN(list_price) as low_price
,      MAX(list_price) as high_price
FROM   product_information
GROUP BY category_id;
