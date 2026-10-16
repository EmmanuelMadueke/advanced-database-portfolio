-- Owner, author, maintainer: Emmanuel Madueke
-- Session A: execute, then keep connection open until observer has read.
\set ON_ERROR_STOP on
BEGIN ISOLATION LEVEL READ COMMITTED;
SET LOCAL ROLE fashion_portfolio_writer;
SET LOCAL TIME ZONE 'Africa/Lagos';


SELECT customer_id FROM retail.customers WHERE email='commit@example.test' \gset
SELECT address_id FROM retail.customer_addresses WHERE customer_id=:customer_id \gset
SELECT variant_id AS shirt_id FROM retail.product_variants WHERE sku='COMMIT-SHIRT' \gset
SELECT variant_id AS jacket_id FROM retail.product_variants WHERE sku='COMMIT-JACKET' \gset
SELECT retail.create_order(:customer_id,:address_id,
 ARRAY[:shirt_id,:jacket_id]::bigint[],ARRAY[2,1]) AS order_id \gset
SELECT retail.finalise_order(:order_id,'P3-ISOLATION-001','card') AS payment_id \gset
SET CONSTRAINTS ALL IMMEDIATE;
