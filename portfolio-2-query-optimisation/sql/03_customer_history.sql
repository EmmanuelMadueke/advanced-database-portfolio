-- Owner, author, maintainer: Emmanuel Madueke
-- One row per order, including payment retries without multiplying order totals.
\set ON_ERROR_STOP on
\if :{?customer_email}
\else
\set customer_email femi@example.test
\endif

WITH attempts AS (
 SELECT order_id,count(*) AS payment_attempts,
        count(*) FILTER(WHERE status='failed') AS failed_attempts,
        max(provider_reference) FILTER(WHERE status='succeeded') AS successful_reference
 FROM retail.payments GROUP BY order_id
)
SELECT c.email,o.order_id,o.created_at,o.status AS order_status,o.total_amount,o.currency_code,
       coalesce(a.payment_attempts,0) AS payment_attempts,coalesce(a.failed_attempts,0) AS failed_attempts,
       a.successful_reference,d.status AS delivery_status,d.tracking_reference
FROM retail.customers c JOIN retail.orders o USING(customer_id)
LEFT JOIN attempts a USING(order_id) LEFT JOIN retail.deliveries d USING(order_id)
WHERE c.email=lower(btrim(:'customer_email'))
ORDER BY o.created_at DESC,o.order_id DESC;
