-- Owner, author, maintainer: Emmanuel Madueke
-- Read-only assertions for the unscaled 05 sample dataset, followed by reports.
\set ON_ERROR_STOP on
BEGIN;
SET LOCAL search_path=retail,pg_catalog;
CREATE FUNCTION pg_temp.assert_sample(label text,condition boolean) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
 IF condition IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL: %',label; END IF;
 RAISE NOTICE 'PASS: %',label;
END $$;
SELECT pg_temp.assert_sample('sample entity counts',
 (SELECT count(*)=12 FROM customers) AND (SELECT count(*)=12 FROM customer_addresses) AND
 (SELECT count(*)=3 FROM categories) AND (SELECT count(*)=3 FROM brands) AND
 (SELECT count(*)=7 FROM sizes) AND (SELECT count(*)=4 FROM colours) AND
 (SELECT count(*)=8 FROM products) AND (SELECT count(*)=18 FROM product_variants) AND
 (SELECT count(*)=18 FROM inventory) AND (SELECT count(*)=6 FROM shopping_carts) AND
 (SELECT count(*)=4 FROM cart_items) AND (SELECT count(*)=12 FROM orders) AND
 (SELECT count(*)=17 FROM order_items) AND (SELECT count(*)=12 FROM payments) AND
 (SELECT count(*)=6 FROM deliveries) AND (SELECT count(*)=2 FROM administrators));
SELECT pg_temp.assert_sample('all six order states represented',
 (SELECT count(DISTINCT status)=6 FROM orders));
SELECT pg_temp.assert_sample('payment outcomes and retry represented',
 (SELECT count(*)=8 FROM payments WHERE status='succeeded') AND
 (SELECT count(*)=3 FROM payments WHERE status='failed') AND
 (SELECT count(*)=1 FROM payments WHERE status='pending') AND
 EXISTS(SELECT 1 FROM orders o WHERE EXISTS(SELECT 1 FROM payments p WHERE p.order_id=o.order_id AND p.status='failed')
 AND EXISTS(SELECT 1 FROM payments p WHERE p.order_id=o.order_id AND p.status='succeeded')));
SELECT pg_temp.assert_sample('delivery outcomes represented',
 (SELECT count(*)=3 FROM deliveries WHERE status='delivered') AND
 (SELECT count(*)=2 FROM deliveries WHERE status='dispatched') AND
 (SELECT count(*)=1 FROM deliveries WHERE status='pending'));
SELECT pg_temp.assert_sample('active and historical carts represented',
 (SELECT count(*)=4 FROM shopping_carts WHERE status='active') AND
 (SELECT count(*)=1 FROM shopping_carts WHERE status='converted') AND
 (SELECT count(*)=1 FROM shopping_carts WHERE status='abandoned'));
SELECT pg_temp.assert_sample('stock categories represented',
 (SELECT count(*)=2 FROM inventory WHERE available_quantity=0) AND
 (SELECT count(*)=2 FROM inventory WHERE available_quantity>0 AND available_quantity<=low_stock_threshold));
SELECT pg_temp.assert_sample('order totals equal independently aggregated line totals',NOT EXISTS(
 SELECT 1 FROM orders o LEFT JOIN (SELECT order_id,sum(quantity::numeric*unit_price) total FROM order_items GROUP BY order_id) x USING(order_id)
 WHERE o.total_amount<>coalesce(x.total,0)));
SELECT pg_temp.assert_sample('paid order totals reconcile to NGN 268000.00',
 (SELECT sum(total_amount)=268000.00 FROM orders WHERE status IN ('paid','processing','dispatched','delivered')) AND
 (SELECT sum(amount)=268000.00 FROM payments WHERE status='succeeded'));
SELECT pg_temp.assert_sample('paid orders have exactly one matching successful payment',NOT EXISTS(
 SELECT 1 FROM orders o LEFT JOIN payments p ON p.order_id=o.order_id AND p.status='succeeded'
 WHERE (o.status IN ('paid','processing','dispatched','delivered') AND
 (p.payment_id IS NULL OR p.amount<>o.total_amount OR p.currency_code<>o.currency_code)) OR
 (o.status IN ('pending','cancelled') AND p.payment_id IS NOT NULL)));
SELECT pg_temp.assert_sample('inventory reconciles to initial stock minus successful purchases',NOT EXISTS(
 WITH initial(sku,quantity) AS (VALUES
 ('TEE-BLK-S',15),('TEE-BLK-M',20),('TEE-BLK-L',0),('TEE-WHT-M',12),
 ('LIN-WHT-M',10),('LIN-BLU-L',3),('DRS-BLU-S',8),('DRS-BLK-M',2),
 ('HOD-BLU-S',12),('HOD-BLK-M',8),('SNK-WHT-40',6),('SNK-BLK-41',7),
 ('SNK-WHT-42',0),('SND-BRN-41',5),('SND-BLK-42',4),('TOT-BLK-OS',20),('TOT-WHT-OS',10),('BLT-BRN-OS',5)),
 purchased AS (SELECT i.variant_id,sum(i.quantity) units FROM order_items i JOIN orders o USING(order_id)
 WHERE o.status IN ('paid','processing','dispatched','delivered') GROUP BY i.variant_id)
 SELECT 1 FROM initial x JOIN product_variants v USING(sku) JOIN inventory inv USING(variant_id)
 LEFT JOIN purchased p USING(variant_id) WHERE inv.available_quantity<>x.quantity-coalesce(p.units,0)));
SELECT status,count(*) AS orders,sum(total_amount) AS order_amount_ngn FROM orders GROUP BY status ORDER BY status;
SELECT status,count(*) AS attempts,sum(amount) AS attempted_amount_ngn FROM payments GROUP BY status ORDER BY status;
SELECT v.sku,inv.available_quantity,inv.low_stock_threshold,
 CASE WHEN inv.available_quantity=0 THEN 'out_of_stock'
 WHEN inv.available_quantity<=inv.low_stock_threshold THEN 'low_stock' ELSE 'available' END AS stock_status
FROM product_variants v JOIN inventory inv USING(variant_id) ORDER BY v.sku;
SELECT c.email,o.status,o.total_amount,p.status AS payment_status,p.provider_reference,d.status AS delivery_status
FROM orders o JOIN customers c USING(customer_id) LEFT JOIN payments p USING(order_id)
LEFT JOIN deliveries d USING(order_id) ORDER BY c.email,p.provider_reference;
ROLLBACK;
