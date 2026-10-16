-- Owner, author, maintainer: Emmanuel Madueke
-- Run after 01_commit_fixture.sql in a NEW database; do not run the COMMIT purchase first.
-- Deliberately fail after successful simulated finalisation, then explicitly roll back.
\set ON_ERROR_STOP on
\pset pager off
SELECT version();
BEGIN ISOLATION LEVEL READ COMMITTED;
SET LOCAL ROLE fashion_portfolio_writer;
SET LOCAL TIME ZONE 'Africa/Lagos';
SHOW transaction_isolation;
SELECT current_user AS purchase_role, pg_backend_pid() AS rollback_session;
SELECT customer_id FROM retail.customers WHERE email='commit@example.test' \gset
SELECT address_id FROM retail.customer_addresses WHERE customer_id=:customer_id \gset
SELECT variant_id AS shirt_id FROM retail.product_variants WHERE sku='COMMIT-SHIRT' \gset
SELECT variant_id AS jacket_id FROM retail.product_variants WHERE sku='COMMIT-JACKET' \gset
SELECT retail.create_order(:customer_id,:address_id,
 ARRAY[:shirt_id,:jacket_id]::bigint[],ARRAY[2,1]) AS order_id \gset
SELECT retail.finalise_order(:order_id,'P3-ROLLBACK-001','card') AS payment_id \gset
SET CONSTRAINTS ALL IMMEDIATE;
\echo Purchase constructed and validated; still inside transaction.
SELECT order_id,status,total_amount,currency_code FROM retail.orders WHERE order_id=:order_id;
SELECT sku,available_quantity FROM retail.product_variants JOIN retail.inventory USING(variant_id) ORDER BY sku;
SELECT payment_id,status,amount,provider_reference FROM retail.payments WHERE payment_id=:payment_id;
-- Disable stop-on-error for exactly the expected failing statement so ROLLBACK can run.
\set ON_ERROR_STOP off
DO $$ BEGIN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='simulated checkout failure before commit'; END $$;
\set failure_state :SQLSTATE
\set ON_ERROR_STOP on
ROLLBACK;
SELECT :'failure_state'='P0001' AS expected_failure \gset
\if :expected_failure
  \echo PASS: expected checkout failure P0001 observed; explicit ROLLBACK completed.
\else
  \echo FAIL: unexpected failure state :failure_state
  \quit 1
\endif
\echo Run 05_verify_rollback.sql in a NEW psql connection.
