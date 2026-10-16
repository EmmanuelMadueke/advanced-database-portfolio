-- Owner, author, maintainer: Emmanuel Madueke
-- Deliberate defect: use stale client value without rechecking current stock.
-- Requires buyer psql variable and the same connection as 10_unsafe_read.sql.
\set ON_ERROR_STOP on
SELECT :observed_stock >= 1 AS accepted \gset
\if :accepted
 UPDATE unsafe_checkout.stock SET available_quantity=:observed_stock-1
 WHERE sku='LAST-SHIRT-M-BLACK';
 INSERT INTO unsafe_checkout.accepted_purchases(buyer,sku,quantity)
 VALUES(:'buyer','LAST-SHIRT-M-BLACK',1);
 COMMIT;
 \echo Accepted purchase committed for :buyer using observed stock :observed_stock
\else
 ROLLBACK;
 \echo FAIL: expected last-unit fixture unavailable
 \quit 1
\endif
