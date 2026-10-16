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
SELECT pg_temp.assert_true('new order rolled back', (SELECT count(*)=0 FROM retail.orders));
SELECT pg_temp.assert_true('both purchase lines rolled back', (SELECT count(*)=0 FROM retail.order_items));
SELECT pg_temp.assert_true('simulated successful payment rolled back', (SELECT count(*)=0 FROM retail.payments));
SELECT pg_temp.assert_true('shirt stock restored to 10',
 (SELECT available_quantity=10 FROM retail.inventory JOIN retail.product_variants USING(variant_id) WHERE sku='COMMIT-SHIRT'));
SELECT pg_temp.assert_true('jacket stock restored to 5',
 (SELECT available_quantity=5 FROM retail.inventory JOIN retail.product_variants USING(variant_id) WHERE sku='COMMIT-JACKET'));
SELECT pg_temp.assert_true('committed fixture customer and catalogue preserved',
 (SELECT count(*)=1 FROM retail.customers WHERE email='commit@example.test') AND
 (SELECT count(*)=2 FROM retail.product_variants) AND (SELECT count(*)=2 FROM retail.inventory));
SELECT (SELECT count(*) FROM retail.orders) AS orders,
       (SELECT count(*) FROM retail.order_items) AS items,
       (SELECT count(*) FROM retail.payments) AS payments;
SELECT sku,available_quantity FROM retail.inventory JOIN retail.product_variants USING(variant_id) ORDER BY sku;
COMMIT;
\echo 6 ROLLBACK persistence checks passed in a fresh connection.
