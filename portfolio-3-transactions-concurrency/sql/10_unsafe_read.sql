-- Owner, author, maintainer: Emmanuel Madueke
-- Both buyers read before either writes. Keep each connection open.
\set ON_ERROR_STOP on
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT available_quantity AS observed_stock FROM unsafe_checkout.stock
WHERE sku='LAST-SHIRT-M-BLACK' \gset
SELECT json_build_object('pid',pg_backend_pid(), 'isolation',current_setting('transaction_isolation'),
 'observed_stock',:observed_stock);
