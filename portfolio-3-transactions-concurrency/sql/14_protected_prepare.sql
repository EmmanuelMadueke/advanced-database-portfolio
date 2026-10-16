-- Owner, author, maintainer: Emmanuel Madueke
-- Run in both sessions before either finalises; set email independently.
\set ON_ERROR_STOP on
BEGIN ISOLATION LEVEL READ COMMITTED;
SET LOCAL ROLE fashion_portfolio_writer;
SELECT customer_id FROM retail.customers WHERE email=:'email' \gset
SELECT address_id FROM retail.customer_addresses WHERE customer_id=:customer_id \gset
SELECT variant_id FROM retail.product_variants WHERE sku='COMMIT-SHIRT' \gset
SELECT retail.create_order(:customer_id,:address_id,ARRAY[:variant_id]::bigint[],ARRAY[1]) AS order_id \gset
SELECT json_build_object('pid',pg_backend_pid(),'isolation',current_setting('transaction_isolation'),
 'role',current_user,'order_id',:order_id,
 'stock',(SELECT available_quantity FROM retail.inventory WHERE variant_id=:variant_id));
