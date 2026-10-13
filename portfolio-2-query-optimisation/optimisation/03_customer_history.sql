-- Owner, author, maintainer: Emmanuel Madueke
-- Aggregate attempts only for each selected order, retaining zero-attempt orders.
\set ON_ERROR_STOP on
\if :{?customer_email}
\else
\set customer_email femi@example.test
\endif

SELECT c.email,o.order_id,o.created_at,o.status AS order_status,o.total_amount,o.currency_code,
       coalesce(a.payment_attempts,0) AS payment_attempts,coalesce(a.failed_attempts,0) AS failed_attempts,
       a.successful_reference,d.status AS delivery_status,d.tracking_reference
FROM retail.customers c JOIN retail.orders o USING(customer_id)
LEFT JOIN LATERAL (
 SELECT count(*) AS payment_attempts,
        count(*) FILTER(WHERE p.status='failed') AS failed_attempts,
        max(p.provider_reference) FILTER(WHERE p.status='succeeded') AS successful_reference
 FROM retail.payments p WHERE p.order_id=o.order_id
) a ON true
LEFT JOIN retail.deliveries d USING(order_id)
WHERE c.email=lower(btrim(:'customer_email'))
ORDER BY o.created_at DESC,o.order_id DESC;
