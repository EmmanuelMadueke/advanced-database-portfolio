-- Owner, author, maintainer: Emmanuel Madueke
-- Run on the fresh schema as its owner. Fixture work is rolled back.
\set ON_ERROR_STOP on
BEGIN;
SET LOCAL search_path=retail,pg_catalog;
CREATE FUNCTION pg_temp.assert_true(label text,condition boolean) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
 IF condition IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL: %',label; END IF;
 RAISE NOTICE 'PASS: %',label;
END $$;
CREATE FUNCTION pg_temp.expect_rejected(label text,command text,state text,message_fragment text DEFAULT '')
RETURNS void LANGUAGE plpgsql AS $$
DECLARE rejected boolean:=false; actual_state text; actual_message text;
BEGIN
 BEGIN
   EXECUTE command;
   SET CONSTRAINTS ALL IMMEDIATE;
 EXCEPTION WHEN OTHERS THEN
   GET STACKED DIAGNOSTICS actual_state=RETURNED_SQLSTATE,actual_message=MESSAGE_TEXT;
   IF actual_state<>state OR position(message_fragment IN actual_message)=0 THEN
     RAISE EXCEPTION 'FAIL: %: unexpected [%] %',label,actual_state,actual_message;
   END IF;
   rejected:=true;
 END;
 IF NOT rejected THEN RAISE EXCEPTION 'FAIL: % accepted invalid operation',label; END IF;
 RAISE NOTICE 'PASS: % (rejected with %)',label,state;
END $$;

INSERT INTO customers(customer_id,first_name,last_name,email,phone) OVERRIDING SYSTEM VALUE
VALUES(9001,'Test','Customer','fixture@example.test','08000000000');
INSERT INTO customer_addresses(address_id,customer_id,recipient_name,recipient_phone,address_line_1,city,state_region,country_code)
OVERRIDING SYSTEM VALUE VALUES(9001,9001,'Test Customer','08000000000','1 Test Street','Lagos','Lagos','NG');
INSERT INTO categories(category_id,name) OVERRIDING SYSTEM VALUE VALUES(9001,'Fixture Clothing');
INSERT INTO brands(brand_id,name) OVERRIDING SYSTEM VALUE VALUES(9001,'Fixture Brand');
INSERT INTO sizes(size_id,label) OVERRIDING SYSTEM VALUE VALUES(9001,'Fixture M');
INSERT INTO colours(colour_id,name) OVERRIDING SYSTEM VALUE VALUES(9001,'Fixture Black'),(9002,'Fixture White'),(9003,'Fixture Red');
INSERT INTO products(product_id,category_id,brand_id,name,description,audience) OVERRIDING SYSTEM VALUE
VALUES(9001,9001,9001,'Fixture Shirt','Integrity test garment','unisex');
INSERT INTO product_variants(variant_id,product_id,size_id,colour_id,sku,unit_price) OVERRIDING SYSTEM VALUE
VALUES(9001,9001,9001,9001,'FIX-BLACK',100.00),(9002,9001,9001,9002,'FIX-WHITE',200.00);
INSERT INTO inventory VALUES(9001,10,2,CURRENT_TIMESTAMP),(9002,1,2,CURRENT_TIMESTAMP);
INSERT INTO shopping_carts(cart_id,customer_id) OVERRIDING SYSTEM VALUE VALUES(9001,9001);
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;

SELECT pg_temp.assert_true('16 base tables',
 (SELECT count(*)=16 FROM information_schema.tables WHERE table_schema='retail' AND table_type='BASE TABLE'));
SELECT pg_temp.expect_rejected('invalid customer FK',
 $$INSERT INTO shopping_carts(customer_id) VALUES(999999)$$,'23503');
SELECT pg_temp.expect_rejected('duplicate variant combination',
 $$INSERT INTO product_variants(product_id,size_id,colour_id,sku,unit_price) VALUES(9001,9001,9001,'DUP',100)$$,'23505');
SELECT pg_temp.expect_rejected('case-insensitive category uniqueness',
 $$INSERT INTO categories(name) VALUES('fixture clothing')$$,'23505');
SELECT pg_temp.expect_rejected('one active cart',
 $$INSERT INTO shopping_carts(customer_id) VALUES(9001)$$,'23505');
SELECT pg_temp.expect_rejected('negative stock',
 $$UPDATE inventory SET available_quantity=-1 WHERE variant_id=9001$$,'23514');
SELECT pg_temp.expect_rejected('invalid cart quantity',
 $$INSERT INTO cart_items VALUES(9001,9001,0)$$,'23514');
SELECT pg_temp.expect_rejected('NaN price',
 $$UPDATE product_variants SET unit_price='NaN' WHERE variant_id=9001$$,'23514');
SELECT pg_temp.expect_rejected('missing inventory at transaction boundary',
 $$INSERT INTO product_variants(product_id,size_id,colour_id,sku,unit_price) VALUES(9001,9001,9003,'NO-STOCK',100)$$,'P0001','variant requires inventory');
SELECT pg_temp.expect_rejected('inventory cannot be removed',
 $$DELETE FROM inventory WHERE variant_id=9001$$,'P0001','variant requires inventory');
SELECT pg_temp.expect_rejected('excess fractional money',
 $$SELECT retail.checked_money(1.001)$$,'P0001','monetary value');
SELECT pg_temp.expect_rejected('restricted order start status',
 $$INSERT INTO orders(customer_id,status,paid_at,recipient_name,recipient_phone,address_line_1,city,state_region,country_code)
 VALUES(9001,'paid',clock_timestamp(),'Test','123','Test','Lagos','Lagos','NG')$$,'P0001','start pending');

SET LOCAL ROLE fashion_portfolio_writer;
SELECT pg_temp.expect_rejected('writer cannot directly alter stock',
 $$UPDATE retail.inventory SET available_quantity=100 WHERE variant_id=9001$$,'42501');
SELECT pg_temp.expect_rejected('writer cannot rewrite order history',
 $$DELETE FROM retail.orders$$,'42501');
SELECT retail.set_cart_item(9001,9001,2);
SELECT retail.set_cart_item(9001,9001,3);
SELECT pg_temp.assert_true('cart upsert combines line',
 (SELECT count(*)=1 AND max(quantity)=3 FROM retail.cart_items WHERE cart_id=9001));
SELECT retail.set_cart_item(9001,9001,0);
SELECT pg_temp.assert_true('cart removal',NOT EXISTS(SELECT 1 FROM retail.cart_items WHERE cart_id=9001));
SELECT retail.create_order(9001,9001,ARRAY[9001]::bigint[],ARRAY[2]) AS first_order \gset
SELECT retail.record_failed_payment(:first_order,'FAIL-FIX');
SELECT pg_temp.assert_true('failed payment does not deduct stock',
 (SELECT available_quantity=10 FROM retail.inventory WHERE variant_id=9001));
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
RESET ROLE;
UPDATE product_variants SET unit_price=125.00 WHERE variant_id=9001;
UPDATE customer_addresses SET address_line_1='2 Changed Street' WHERE address_id=9001;
SELECT pg_temp.expect_rejected('incorrect aggregate rejected',
 format('UPDATE retail.orders SET total_amount=1 WHERE order_id=%s',:first_order),'P0001','total does not match');
SELECT pg_temp.expect_rejected('invalid status transition',
 format('UPDATE retail.orders SET status=''delivered'' WHERE order_id=%s',:first_order),'P0001','invalid order transition');
SELECT pg_temp.expect_rejected('invalid payment amount',
 format($cmd$DO $block$ DECLARE pid bigint; t timestamptz:=clock_timestamp(); BEGIN
 INSERT INTO retail.payments(order_id,method,provider_reference,amount) VALUES(%s,'card','WRONG-AMOUNT',1) RETURNING payment_id INTO pid;
 UPDATE retail.payments SET status='succeeded',completed_at=t WHERE payment_id=pid;
 UPDATE retail.orders SET status='paid',paid_at=t WHERE order_id=%s;
 END $block$$cmd$,:first_order,:first_order),'P0001','must match order amount');
SET LOCAL ROLE fashion_portfolio_writer;
SELECT retail.finalise_order(:first_order,'SUCCESS-FIX') AS payment_id \gset
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
SELECT pg_temp.assert_true('successful purchase updates stock',
 (SELECT available_quantity=8 FROM retail.inventory WHERE variant_id=9001));
SELECT pg_temp.assert_true('finalisation captures current price',
 (SELECT total_amount=250 AND status='paid' FROM retail.orders WHERE order_id=:first_order));
SELECT pg_temp.assert_true('destination snapshot survives saved-address edit',
 (SELECT address_line_1='1 Test Street' FROM retail.orders WHERE order_id=:first_order));
SELECT pg_temp.assert_true('finalisation replay returns same payment',
 retail.finalise_order(:first_order,'SUCCESS-FIX')=:payment_id);
SELECT pg_temp.assert_true('replay does not deduct again',
 (SELECT available_quantity=8 FROM retail.inventory WHERE variant_id=9001));
SELECT retail.dispatch_order(:first_order,'Test Courier','TRACK-FIX');
SELECT retail.deliver_order(:first_order);
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
SELECT pg_temp.assert_true('order and delivery finish together',
 (SELECT o.status='delivered' AND d.status='delivered' FROM retail.orders o JOIN retail.deliveries d USING(order_id) WHERE o.order_id=:first_order));
RESET ROLE;
SELECT pg_temp.expect_rejected('purchased line cannot change',
 format('UPDATE retail.order_items SET quantity=3 WHERE order_id=%s',:first_order),'P0001','only pending order items');
SELECT pg_temp.expect_rejected('terminal payment cannot change',
 format('UPDATE retail.payments SET amount=999 WHERE payment_id=%s',:payment_id),'P0001','terminal payment');
UPDATE product_variants SET unit_price=150.00 WHERE variant_id=9001;
SELECT pg_temp.assert_true('paid price snapshot survives catalogue edit',
 (SELECT unit_price=125.00 FROM retail.order_items WHERE order_id=:first_order));
SET LOCAL ROLE fashion_portfolio_writer;
SELECT retail.create_order(9001,9001,ARRAY[9002]::bigint[],ARRAY[1]) AS stock_order \gset
RESET ROLE;
SELECT pg_temp.expect_rejected('duplicate provider reference',
 format('INSERT INTO retail.payments(order_id,method,provider_reference,amount) VALUES(%s,''card'',''SUCCESS-FIX'',200)',:stock_order), '23505');
SET LOCAL ROLE fashion_portfolio_writer;
SELECT retail.create_order(9001,9001,ARRAY[9001,9002]::bigint[],ARRAY[1,1]) AS mixed_order \gset
RESET ROLE;
UPDATE retail.inventory SET available_quantity=0 WHERE variant_id=9002;
SET LOCAL ROLE fashion_portfolio_writer;
SELECT pg_temp.expect_rejected('checkout rechecks stock',
 format('SELECT retail.finalise_order(%s,''NO-STOCK-FIX'')',:stock_order),'P0001','insufficient stock');
SELECT pg_temp.assert_true('failed checkout leaves pending order and no success',
 (SELECT status='pending' AND NOT EXISTS (SELECT 1 FROM retail.payments WHERE order_id=:stock_order AND status='succeeded') FROM retail.orders WHERE order_id=:stock_order));
SELECT pg_temp.expect_rejected('multi-item checkout rolls back earlier deduction',
 format('SELECT retail.finalise_order(%s,''MIXED-FAIL-FIX'')',:mixed_order),'P0001','insufficient stock');
SELECT pg_temp.assert_true('multi-item failure restores earlier stock and snapshots',
 (SELECT available_quantity=8 FROM retail.inventory WHERE variant_id=9001) AND
 (SELECT status='pending' FROM retail.orders WHERE order_id=:mixed_order) AND
 NOT EXISTS(SELECT 1 FROM retail.payments WHERE order_id=:mixed_order));
SELECT retail.cancel_order(:stock_order);
SELECT pg_temp.expect_rejected('cancelled order cannot be paid',
 format('SELECT retail.finalise_order(%s,''CANCEL-FIX'')',:stock_order),'P0001','only pending order');
RESET ROLE;
SET CONSTRAINTS ALL IMMEDIATE;
ROLLBACK;
SELECT 'Fixture rolled back; no test customers/orders remain.' AS result;
