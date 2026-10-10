-- Owner, author, maintainer: Emmanuel Madueke
-- Awaiting payment, fulfilment, or delivery; excludes delivered and cancelled.
\set ON_ERROR_STOP on

SELECT o.order_id,c.email,o.status AS order_status,o.total_amount,o.created_at,
       d.status AS delivery_status,d.tracking_reference
FROM retail.orders o JOIN retail.customers c USING(customer_id)
LEFT JOIN retail.deliveries d USING(order_id)
WHERE o.status IN ('pending','paid','processing','dispatched')
ORDER BY o.created_at,o.order_id;
