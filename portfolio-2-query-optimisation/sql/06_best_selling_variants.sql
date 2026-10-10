-- Owner, author, maintainer: Emmanuel Madueke
-- Rank sold variants by units, then revenue. Uses purchase-time prices.
\set ON_ERROR_STOP on
\if :{?from_date}
\else
\set from_date 2026-01-01
\endif
\if :{?until_date}
\else
\set until_date 2027-01-01
\endif

SELECT v.sku,p.name AS current_product_name,sum(i.quantity) AS units_sold,
       count(DISTINCT o.order_id) AS purchase_orders,
       sum(i.quantity::numeric*i.unit_price) AS revenue_ngn
FROM retail.order_items i JOIN retail.orders o USING(order_id)
JOIN retail.product_variants v USING(variant_id) JOIN retail.products p USING(product_id)
WHERE o.status IN ('paid','processing','dispatched','delivered')
  AND o.paid_at >= (:'from_date'::date::timestamp AT TIME ZONE 'Africa/Lagos')
  AND o.paid_at < (:'until_date'::date::timestamp AT TIME ZONE 'Africa/Lagos')
GROUP BY v.variant_id,v.sku,p.product_id,p.name
ORDER BY units_sold DESC,revenue_ngn DESC,v.sku;
