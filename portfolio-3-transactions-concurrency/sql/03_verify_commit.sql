-- Owner, author, maintainer: Emmanuel Madueke
-- A fresh psql connection verifies persisted state, without modifying retail data.
\set ON_ERROR_STOP on
\pset pager off
CREATE FUNCTION pg_temp.assert_true(label text,condition boolean) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
 IF condition IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL: %',label; END IF;
 RAISE NOTICE 'PASS: %',label;
END $$;
BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY;
SET LOCAL ROLE fashion_portfolio_writer;
SELECT current_user AS verification_role,pg_backend_pid() AS verification_session;
SELECT pg_temp.assert_true('one paid order persisted with NGN 49000 total',
 (SELECT count(*)=1 AND bool_and(status='paid' AND total_amount=49000 AND currency_code='NGN' AND paid_at IS NOT NULL) FROM retail.orders));
SELECT pg_temp.assert_true('two correct purchase lines persisted',
 (SELECT count(*)=2 AND bool_and(
   (sku_snapshot='COMMIT-SHIRT' AND quantity=2 AND unit_price=12000 AND product_name_snapshot='Commit Shirt') OR
   (sku_snapshot='COMMIT-JACKET' AND quantity=1 AND unit_price=25000 AND product_name_snapshot='Commit Jacket'))
  FROM retail.order_items));
SELECT pg_temp.assert_true('order total reconciles to lines',
 (SELECT o.total_amount=sum(i.quantity*i.unit_price) FROM retail.orders o JOIN retail.order_items i USING(order_id) GROUP BY o.order_id));
SELECT pg_temp.assert_true('one matching successful payment persisted',
 (SELECT count(*)=1 AND bool_and(p.status='succeeded' AND p.provider_reference='P3-COMMIT-001'
  AND p.method='card' AND p.amount=o.total_amount AND p.currency_code=o.currency_code AND p.completed_at=o.paid_at)
 FROM retail.payments p JOIN retail.orders o USING(order_id)));
SELECT pg_temp.assert_true('shirt stock decreased from 10 to 8',
 (SELECT available_quantity=8 FROM retail.inventory JOIN retail.product_variants USING(variant_id) WHERE sku='COMMIT-SHIRT'));
SELECT pg_temp.assert_true('jacket stock decreased from 5 to 4',
 (SELECT available_quantity=4 FROM retail.inventory JOIN retail.product_variants USING(variant_id) WHERE sku='COMMIT-JACKET'));
SELECT pg_temp.assert_true('delivery address snapshot persisted',
 (SELECT recipient_name='Commit Customer' AND recipient_phone='08000000000' AND address_line_1='1 Demo Street'
  AND city='Lagos' AND state_region='Lagos' AND country_code='NG' FROM retail.orders));
SELECT pg_temp.assert_true('size and colour snapshots persisted',
 (SELECT count(*)=2 AND bool_and(size_label_snapshot='Commit M' AND colour_name_snapshot='Commit Black') FROM retail.order_items));
SELECT o.order_id,o.status,o.total_amount,p.payment_id,p.status AS payment_status,p.amount
FROM retail.orders o JOIN retail.payments p USING(order_id);
SELECT sku,available_quantity FROM retail.inventory JOIN retail.product_variants USING(variant_id) ORDER BY sku;
COMMIT;
\echo 8 COMMIT persistence checks passed in a fresh connection.
