-- Owner, author, maintainer: Emmanuel Madueke
-- Read-only checks after optional 06_scale_data.sql; use same scale_orders value.
\set ON_ERROR_STOP on
\if :{?scale_orders}
\else
\set scale_orders 10000
\endif
BEGIN;
CREATE TEMP TABLE expected_scale AS SELECT :scale_orders::integer AS orders;
DO $$
DECLARE n integer;
BEGIN
 SELECT orders INTO n FROM expected_scale;
 IF (SELECT count(*) FROM retail.customers)<>1012 OR
    (SELECT count(*) FROM retail.products)<>208 OR
    (SELECT count(*) FROM retail.product_variants)<>1218 OR
    (SELECT count(*) FROM retail.orders)<>n+12 OR
    (SELECT count(*) FROM retail.order_items)<>n+17 OR
    (SELECT count(*) FROM retail.payments)<>n/4+12 THEN RAISE EXCEPTION 'scale counts mismatch'; END IF;
 RAISE NOTICE 'PASS: scale counts (% additional orders)',n;
 IF EXISTS(SELECT 1 FROM retail.orders o LEFT JOIN (
 SELECT order_id,sum(quantity::numeric*unit_price) total FROM retail.order_items GROUP BY order_id) x USING(order_id)
 WHERE o.total_amount<>coalesce(x.total,0)) THEN RAISE EXCEPTION 'scale totals mismatch'; END IF;
 RAISE NOTICE 'PASS: scale order totals';
 IF EXISTS(WITH bought AS (SELECT i.variant_id,sum(i.quantity) units FROM retail.order_items i JOIN retail.orders o USING(order_id)
 WHERE o.status IN ('paid','processing','dispatched','delivered') GROUP BY i.variant_id)
 SELECT 1 FROM retail.product_variants v JOIN retail.inventory inv USING(variant_id) LEFT JOIN bought b USING(variant_id)
 WHERE v.sku LIKE 'SCALE-%' AND inv.available_quantity<>100000-coalesce(b.units,0)) THEN RAISE EXCEPTION 'scale stock mismatch'; END IF;
 RAISE NOTICE 'PASS: scale inventory reconciliation';
 IF (SELECT sum(total_amount) FROM retail.orders WHERE status IN ('paid','processing','dispatched','delivered')) IS DISTINCT FROM
    (SELECT sum(amount) FROM retail.payments WHERE status='succeeded') THEN RAISE EXCEPTION 'scale payments mismatch'; END IF;
 RAISE NOTICE 'PASS: scale payment reconciliation';
END $$;
SELECT 'customers' AS relation,count(*) FROM retail.customers UNION ALL
SELECT 'products',count(*) FROM retail.products UNION ALL SELECT 'variants',count(*) FROM retail.product_variants UNION ALL
SELECT 'orders',count(*) FROM retail.orders UNION ALL SELECT 'order_items',count(*) FROM retail.order_items UNION ALL
SELECT 'payments',count(*) FROM retail.payments;
SELECT status,count(*) FROM retail.orders GROUP BY status ORDER BY status;
ROLLBACK;
