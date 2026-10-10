-- Owner, author, maintainer: Emmanuel Madueke
-- Synthetic fashion-store data. Run once as owner after 01–04 on an empty retail schema.
\set ON_ERROR_STOP on
BEGIN;
SET LOCAL search_path=retail,pg_catalog;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM retail.customers) OR EXISTS(SELECT 1 FROM retail.products) OR
    EXISTS(SELECT 1 FROM retail.orders) THEN
   RAISE EXCEPTION 'sample seed requires an empty retail database';
 END IF;
END $$;

INSERT INTO categories(name,description) VALUES
 ('Clothing','Everyday clothing'),('Footwear','Shoes and sandals'),('Accessories','Bags and fashion accessories');
INSERT INTO brands(name) VALUES('Lagos Threads'),('Coastline Wear'),('Urban Steps');
INSERT INTO sizes(label,description) VALUES
 ('S','Small clothing'),('M','Medium clothing'),('L','Large clothing'),
 ('40','Footwear size 40'),('41','Footwear size 41'),('42','Footwear size 42'),('One Size','Universal accessory size');
INSERT INTO colours(name,hex_code) VALUES
 ('Black','#000000'),('White','#FFFFFF'),('Blue','#0000FF'),('Brown','#8B4513');
INSERT INTO administrators(display_name,email) VALUES
 ('Catalogue Manager','catalogue@example.test'),('Fulfilment Manager','fulfilment@example.test');

INSERT INTO customers(first_name,last_name,email,phone)
SELECT first_name,last_name,email,phone FROM (VALUES
 ('Ada','Okafor','ada@example.test','08000000001'),
 ('Tunde','Bello','tunde@example.test','08000000002'),
 ('Zainab','Yusuf','zainab@example.test','08000000003'),
 ('Chidi','Nwosu','chidi@example.test','08000000004'),
 ('Bisi','Adeleke','bisi@example.test','08000000005'),
 ('Ife','Eze','ife@example.test','08000000006'),
 ('Amina','Musa','amina@example.test','08000000007'),
 ('Femi','Lawal','femi@example.test','08000000008'),
 ('Ngozi','Uche','ngozi@example.test','08000000009'),
 ('Seyi','Ojo','seyi@example.test','08000000010'),
 ('Nneka','Obi','nneka@example.test','08000000011'),
 ('Ibrahim','Ali','ibrahim@example.test','08000000012')) AS c(first_name,last_name,email,phone);
INSERT INTO customer_addresses(customer_id,recipient_name,recipient_phone,address_line_1,city,state_region,country_code)
SELECT customer_id,first_name||' '||last_name,phone,
 'Demo address '||row_number() OVER(ORDER BY email),
 CASE WHEN email IN ('ada@example.test','tunde@example.test','bisi@example.test','femi@example.test') THEN 'Lagos'
      WHEN email IN ('amina@example.test','ibrahim@example.test','zainab@example.test','seyi@example.test') THEN 'Abuja' ELSE 'Enugu' END,
 CASE WHEN email IN ('ada@example.test','tunde@example.test','bisi@example.test','femi@example.test') THEN 'Lagos'
      WHEN email IN ('amina@example.test','ibrahim@example.test','zainab@example.test','seyi@example.test') THEN 'FCT' ELSE 'Enugu' END,
 'NG' FROM customers;

INSERT INTO products(category_id,brand_id,name,description,audience)
SELECT c.category_id,b.brand_id,x.name,x.description,x.audience
FROM (VALUES
 ('Clothing','Lagos Threads','Classic T-Shirt','Cotton crew-neck T-shirt','unisex'),
 ('Clothing','Lagos Threads','Linen Shirt','Lightweight linen shirt','men'),
 ('Clothing','Coastline Wear','Midi Dress','Casual midi dress','women'),
 ('Clothing','Coastline Wear','Kids Hoodie','Warm everyday hoodie','kids'),
 ('Footwear','Urban Steps','Canvas Sneakers','Casual lace-up sneakers','unisex'),
 ('Footwear','Urban Steps','Leather Sandals','Everyday leather sandals','men'),
 ('Accessories','Lagos Threads','Tote Bag','Reusable fashion tote','unisex'),
 ('Accessories','Coastline Wear','Leather Belt','Adjustable fashion belt','unisex')
) x(category,brand,name,description,audience)
JOIN categories c ON c.name=x.category JOIN brands b ON b.name=x.brand;

-- Initial balances are also defined in tests/sample_data.sql for independent reconciliation.
INSERT INTO product_variants(product_id,size_id,colour_id,sku,unit_price)
SELECT p.product_id,s.size_id,c.colour_id,x.sku,retail.checked_money(x.price)
FROM (VALUES
 ('Classic T-Shirt','S','Black','TEE-BLK-S',12000.00),
 ('Classic T-Shirt','M','Black','TEE-BLK-M',12000.00),
 ('Classic T-Shirt','L','Black','TEE-BLK-L',12000.00),
 ('Classic T-Shirt','M','White','TEE-WHT-M',12500.00),
 ('Linen Shirt','M','White','LIN-WHT-M',22000.00),
 ('Linen Shirt','L','Blue','LIN-BLU-L',22500.00),
 ('Midi Dress','S','Blue','DRS-BLU-S',28000.00),
 ('Midi Dress','M','Black','DRS-BLK-M',29000.00),
 ('Kids Hoodie','S','Blue','HOD-BLU-S',15000.00),
 ('Kids Hoodie','M','Black','HOD-BLK-M',15500.00),
 ('Canvas Sneakers','40','White','SNK-WHT-40',35000.00),
 ('Canvas Sneakers','41','Black','SNK-BLK-41',35000.00),
 ('Canvas Sneakers','42','White','SNK-WHT-42',36000.00),
 ('Leather Sandals','41','Brown','SND-BRN-41',26000.00),
 ('Leather Sandals','42','Black','SND-BLK-42',26500.00),
 ('Tote Bag','One Size','Black','TOT-BLK-OS',9000.00),
 ('Tote Bag','One Size','White','TOT-WHT-OS',9500.00),
 ('Leather Belt','One Size','Brown','BLT-BRN-OS',18000.00)
) x(product,size,colour,sku,price)
JOIN products p ON p.name=x.product JOIN sizes s ON s.label=x.size JOIN colours c ON c.name=x.colour;
INSERT INTO inventory(variant_id,available_quantity,low_stock_threshold)
SELECT variant_id,CASE sku
 WHEN 'TEE-BLK-S' THEN 15 WHEN 'TEE-BLK-M' THEN 20 WHEN 'TEE-BLK-L' THEN 0 WHEN 'TEE-WHT-M' THEN 12
 WHEN 'LIN-WHT-M' THEN 10 WHEN 'LIN-BLU-L' THEN 3 WHEN 'DRS-BLU-S' THEN 8 WHEN 'DRS-BLK-M' THEN 2
 WHEN 'HOD-BLU-S' THEN 12 WHEN 'HOD-BLK-M' THEN 8 WHEN 'SNK-WHT-40' THEN 6 WHEN 'SNK-BLK-41' THEN 7
 WHEN 'SNK-WHT-42' THEN 0 WHEN 'SND-BRN-41' THEN 5 WHEN 'SND-BLK-42' THEN 4
 WHEN 'TOT-BLK-OS' THEN 20 WHEN 'TOT-WHT-OS' THEN 10 WHEN 'BLT-BRN-OS' THEN 5 END,3
FROM product_variants;
INSERT INTO shopping_carts(customer_id)
SELECT customer_id FROM customers WHERE email IN ('ada@example.test','tunde@example.test','zainab@example.test','chidi@example.test');
SELECT retail.set_cart_item(sc.cart_id,v.variant_id,x.quantity)
FROM (VALUES ('ada@example.test','TEE-BLK-M',2),('ada@example.test','TOT-WHT-OS',1),
 ('tunde@example.test','LIN-BLU-L',1),('zainab@example.test','DRS-BLU-S',1)) x(email,sku,quantity)
JOIN customers c USING(email) JOIN shopping_carts sc USING(customer_id) JOIN product_variants v USING(sku);

INSERT INTO shopping_carts(customer_id,status)
SELECT customer_id,CASE email WHEN 'ada@example.test' THEN 'converted' ELSE 'abandoned' END
FROM customers WHERE email IN ('ada@example.test','ife@example.test');

-- Natural keys resolve identities; no hardcoded generated order/customer IDs.
DO $$
DECLARE r record; cid bigint; aid bigint; vids bigint[]; oid bigint;
BEGIN
 FOR r IN SELECT * FROM (VALUES
  ('ada@example.test',ARRAY['TEE-BLK-M','TOT-BLK-OS'],ARRAY[2,1],'delivered','card','DEMO-001',false),
  ('tunde@example.test',ARRAY['LIN-WHT-M','SND-BRN-41'],ARRAY[1,1],'dispatched','bank_transfer','DEMO-002',false),
  ('zainab@example.test',ARRAY['DRS-BLU-S'],ARRAY[1],'processing','wallet','DEMO-003',false),
  ('chidi@example.test',ARRAY['SNK-BLK-41','TEE-WHT-M'],ARRAY[1,1],'paid','card','DEMO-004',false),
  ('bisi@example.test',ARRAY['TOT-WHT-OS'],ARRAY[2],'pending','card','DEMO-005',true),
  ('ife@example.test',ARRAY['BLT-BRN-OS'],ARRAY[1],'cancelled','card','DEMO-006',true),
  ('amina@example.test',ARRAY['HOD-BLU-S','TEE-BLK-S'],ARRAY[1,1],'delivered','wallet','DEMO-007',false),
  ('femi@example.test',ARRAY['LIN-BLU-L'],ARRAY[1],'paid','bank_transfer','DEMO-008',true),
  ('ngozi@example.test',ARRAY['DRS-BLK-M'],ARRAY[1],'pending','card','DEMO-009',false),
  ('seyi@example.test',ARRAY['SNK-WHT-40'],ARRAY[1],'dispatched','card','DEMO-010',false),
  ('nneka@example.test',ARRAY['TOT-BLK-OS','BLT-BRN-OS'],ARRAY[1,1],'delivered','wallet','DEMO-011',false),
  ('ibrahim@example.test',ARRAY['SND-BLK-42'],ARRAY[1],'cancelled','bank_transfer','DEMO-012',false)
 ) x(email,skus,quantities,target_status,method,reference,failed_first) LOOP
   SELECT customer_id INTO STRICT cid FROM retail.customers WHERE email=r.email;
   SELECT address_id INTO STRICT aid FROM retail.customer_addresses WHERE customer_id=cid;
   SELECT array_agg(v.variant_id ORDER BY u.ordinality) INTO vids
   FROM unnest(r.skus) WITH ORDINALITY u(sku,ordinality) JOIN retail.product_variants v USING(sku);
   oid:=retail.create_order(cid,aid,vids,r.quantities);
   IF r.failed_first THEN PERFORM retail.record_failed_payment(oid,r.reference||'-FAIL',r.method); END IF;
   IF r.target_status IN ('paid','processing','dispatched','delivered') THEN
     PERFORM retail.finalise_order(oid,r.reference,r.method);
   END IF;
   IF r.target_status='processing' THEN
     UPDATE retail.orders SET status='processing' WHERE order_id=oid;
     INSERT INTO retail.deliveries(order_id) VALUES(oid);
   ELSIF r.target_status IN ('dispatched','delivered') THEN
     PERFORM retail.dispatch_order(oid,'Demo Courier','TRACK-'||r.reference);
     IF r.target_status='delivered' THEN PERFORM retail.deliver_order(oid); END IF;
   ELSIF r.target_status='pending' AND NOT r.failed_first THEN
     INSERT INTO retail.payments(order_id,method,provider_reference,amount)
     SELECT oid,r.method,r.reference||'-PENDING',total_amount FROM retail.orders WHERE order_id=oid;
   ELSIF r.target_status='cancelled' THEN PERFORM retail.cancel_order(oid);
   END IF;
 END LOOP;
END $$;
-- Forces deferred checks before recording successful completion.
SET CONSTRAINTS ALL IMMEDIATE;
COMMIT;
