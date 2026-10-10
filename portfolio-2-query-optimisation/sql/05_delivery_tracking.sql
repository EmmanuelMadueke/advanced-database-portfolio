-- Owner, author, maintainer: Emmanuel Madueke
-- Existing shipment progress, with optional delivery status selection.
\set ON_ERROR_STOP on
\if :{?delivery_filter}
\else
\set delivery_filter all
\endif

SELECT o.order_id,c.email,o.status AS order_status,d.status AS delivery_status,
       d.carrier,d.tracking_reference,d.dispatched_at,d.delivered_at
FROM retail.deliveries d JOIN retail.orders o USING(order_id)
JOIN retail.customers c USING(customer_id)
WHERE :'delivery_filter'='all' OR d.status=:'delivery_filter'
ORDER BY d.delivery_id;
