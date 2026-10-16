-- Owner, author, maintainer: Emmanuel Madueke
-- New disposable database with Portfolio 1 scripts 01–04 only.
\set ON_ERROR_STOP on
\ir 01_commit_fixture.sql
BEGIN;
UPDATE retail.inventory SET available_quantity=1
WHERE variant_id=(SELECT variant_id FROM retail.product_variants WHERE sku='COMMIT-SHIRT');
INSERT INTO retail.customers(first_name,last_name,email,phone)
VALUES('Second','Buyer','second@example.test','08000000001') RETURNING customer_id \gset
INSERT INTO retail.customer_addresses(customer_id,recipient_name,recipient_phone,address_line_1,city,state_region,country_code)
VALUES(:customer_id,'Second Buyer','08000000001','2 Demo Street','Lagos','Lagos','NG');
COMMIT;
SELECT sku,available_quantity FROM retail.product_variants JOIN retail.inventory USING(variant_id) ORDER BY sku;
