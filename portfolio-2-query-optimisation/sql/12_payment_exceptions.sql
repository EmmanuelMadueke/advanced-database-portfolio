-- Owner, author, maintainer: Emmanuel Madueke
-- Pending or cancelled orders with failed/pending attempts; successful retries excluded.
\set ON_ERROR_STOP on

SELECT o.order_id,c.email,o.status AS order_status,p.payment_id,p.status AS payment_status,
       p.method,p.amount,p.provider_reference,p.created_at
FROM retail.payments p JOIN retail.orders o USING(order_id)
JOIN retail.customers c USING(customer_id)
WHERE p.status IN ('pending','failed') AND o.status IN ('pending','cancelled')
ORDER BY o.order_id,p.payment_id;
