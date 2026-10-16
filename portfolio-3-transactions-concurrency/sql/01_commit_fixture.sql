-- Owner, author, maintainer: Emmanuel Madueke
-- Run as owner after Portfolio 1 scripts 01–04 in a new disposable database.
\set ON_ERROR_STOP on
\pset pager off
BEGIN;
SET LOCAL search_path=retail,pg_catalog;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM customers) OR EXISTS(SELECT 1 FROM products) OR EXISTS(SELECT 1 FROM orders)
 THEN RAISE EXCEPTION 'COMMIT fixture requires empty retail tables'; END IF;
END $$;
INSERT INTO customers(first_name,last_name,email,phone)
VALUES('Commit','Customer','commit@example.test','08000000000') RETURNING customer_id \gset
INSERT INTO customer_addresses(customer_id,recipient_name,recipient_phone,address_line_1,city,state_region,country_code)
VALUES(:customer_id,'Commit Customer','08000000000','1 Demo Street','Lagos','Lagos','NG');
INSERT INTO categories(name) VALUES('Commit Clothing') RETURNING category_id \gset
INSERT INTO brands(name) VALUES('Commit Fashion') RETURNING brand_id \gset
INSERT INTO sizes(label) VALUES('Commit M') RETURNING size_id \gset
INSERT INTO colours(name) VALUES('Commit Black') RETURNING colour_id \gset
INSERT INTO products(category_id,brand_id,name,description,audience)
VALUES(:category_id,:brand_id,'Commit Shirt','Synthetic shirt for COMMIT demonstration','unisex') RETURNING product_id \gset
INSERT INTO product_variants(product_id,size_id,colour_id,sku,unit_price)
VALUES(:product_id,:size_id,:colour_id,'COMMIT-SHIRT',12000) RETURNING variant_id \gset
INSERT INTO inventory(variant_id,available_quantity,low_stock_threshold) VALUES(:variant_id,10,2);
INSERT INTO products(category_id,brand_id,name,description,audience)
VALUES(:category_id,:brand_id,'Commit Jacket','Synthetic jacket for COMMIT demonstration','unisex') RETURNING product_id \gset
INSERT INTO product_variants(product_id,size_id,colour_id,sku,unit_price)
VALUES(:product_id,:size_id,:colour_id,'COMMIT-JACKET',25000) RETURNING variant_id \gset
INSERT INTO inventory(variant_id,available_quantity,low_stock_threshold) VALUES(:variant_id,5,2);
COMMIT;
\echo Fixture committed; no purchase yet.
SELECT sku,unit_price,available_quantity FROM retail.product_variants JOIN retail.inventory USING(variant_id) ORDER BY sku;
SELECT (SELECT count(*) FROM retail.orders) AS orders,
       (SELECT count(*) FROM retail.order_items) AS items,
       (SELECT count(*) FROM retail.payments) AS payments;
