-- Owner, author, maintainer: Emmanuel Madueke
-- Session A holds locks until the coordinator sends COMMIT.
\set ON_ERROR_STOP on
SELECT retail.finalise_order(:order_id,'P3-PROTECTED-A','card') AS payment_id \gset
SET CONSTRAINTS ALL IMMEDIATE;
SELECT order_id,status,total_amount FROM retail.orders WHERE order_id=:order_id;
