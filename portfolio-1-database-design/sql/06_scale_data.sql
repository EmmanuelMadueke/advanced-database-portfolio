-- Owner, author, maintainer: Emmanuel Madueke
-- OPTIONAL synthetic enlargement for later performance experiments.
-- Run once after 05_sample_data.sql. Default: 10,000 extra orders; 2,500 paid.
-- This is not execution-plan/performance evidence.
\set ON_ERROR_STOP on
\if :{?scale_orders}
\else
\set scale_orders 10000
\endif
BEGIN;
SET LOCAL search_path=retail,pg_catalog;
CREATE TEMP TABLE scale_config AS SELECT :scale_orders::integer AS orders;
DO $$ BEGIN
 IF (SELECT orders FROM scale_config) NOT BETWEEN 4 AND 100000 THEN RAISE EXCEPTION 'scale_orders must be 4..100000'; END IF;
 IF NOT EXISTS(SELECT 1 FROM retail.customers WHERE email='ada@example.test') THEN RAISE EXCEPTION 'load sample data first'; END IF;
 IF EXISTS(SELECT 1 FROM retail.customers WHERE email LIKE 'scale-%@example.test') THEN RAISE EXCEPTION 'scale seed already loaded'; END IF;
END $$;
INSERT INTO customers(first_name,last_name,email,phone)
SELECT 'Demo','Shopper '||g,'scale-'||lpad(g::text,4,'0')||'@example.test','081'||lpad(g::text,8,'0')
FROM generate_series(1,1000) g;
INSERT INTO customer_addresses(customer_id,recipient_name,recipient_phone,address_line_1,city,state_region,country_code)
SELECT customer_id,first_name||' '||last_name,phone,'Synthetic address '||email,'Lagos','Lagos','NG'
FROM customers WHERE email LIKE 'scale-%@example.test';
INSERT INTO products(category_id,brand_id,name,description,audience)
SELECT c.category_id,b.brand_id,'Scale Garment '||lpad(g::text,3,'0'),'Synthetic catalogue record for query experiments','unisex'
FROM generate_series(1,200) g JOIN categories c ON c.name='Clothing' JOIN brands b ON b.name='Lagos Threads';
INSERT INTO product_variants(product_id,size_id,colour_id,sku,unit_price)
SELECT p.product_id,s.size_id,c.colour_id,'SCALE-'||right(p.name,3)||'-'||s.label||'-'||upper(c.name),
 retail.checked_money(10000+(right(p.name,3)::integer%20)*500)
FROM products p CROSS JOIN sizes s CROSS JOIN colours c
WHERE p.name LIKE 'Scale Garment %' AND s.label IN ('S','M','L') AND c.name IN ('Black','White');
-- Enough stock for the allowed maximum; no manual deductions after finalisation.
INSERT INTO inventory(variant_id,available_quantity,low_stock_threshold)
SELECT variant_id,100000,10 FROM product_variants WHERE sku LIKE 'SCALE-%';
DO $$
DECLARE customers_array bigint[]; variants_array bigint[]; cid bigint; aid bigint; vid bigint; oid bigint; g integer;
BEGIN
 SELECT array_agg(customer_id ORDER BY email) INTO customers_array FROM retail.customers WHERE email LIKE 'scale-%@example.test';
 SELECT array_agg(variant_id ORDER BY sku) INTO variants_array FROM retail.product_variants WHERE sku LIKE 'SCALE-%';
 FOR g IN 1..(SELECT orders FROM scale_config) LOOP
   cid:=customers_array[1+((g-1)%cardinality(customers_array))];
   vid:=variants_array[1+((g-1)%cardinality(variants_array))];
   SELECT address_id INTO STRICT aid FROM retail.customer_addresses WHERE customer_id=cid;
   oid:=retail.create_order(cid,aid,ARRAY[vid],ARRAY[1]);
   IF g%4=0 THEN PERFORM retail.finalise_order(oid,'SCALE-PAY-'||lpad(g::text,6,'0'),'card'); END IF;
 END LOOP;
END $$;
SET CONSTRAINTS ALL IMMEDIATE;
DROP TABLE scale_config;
COMMIT;
ANALYZE retail.customers;
ANALYZE retail.products;
ANALYZE retail.product_variants;
ANALYZE retail.orders;
ANALYZE retail.order_items;
ANALYZE retail.payments;
