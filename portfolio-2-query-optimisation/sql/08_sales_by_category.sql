-- Owner, author, maintainer: Emmanuel Madueke
-- Sales grouped by current catalogue category; zero-sale categories included.
\set ON_ERROR_STOP on
\if :{?from_date}
\else
\set from_date 2026-01-01
\endif
\if :{?until_date}
\else
\set until_date 2027-01-01
\endif

WITH category_sales AS (
 SELECT p.category_id,sum(i.quantity) AS units_sold,
        count(DISTINCT o.order_id) AS purchase_orders,
        sum(i.quantity::numeric*i.unit_price) AS revenue_ngn
 FROM retail.order_items i JOIN retail.orders o USING(order_id)
 JOIN retail.product_variants v USING(variant_id) JOIN retail.products p USING(product_id)
 WHERE o.status IN ('paid','processing','dispatched','delivered')
  AND o.paid_at >= (:'from_date'::date::timestamp AT TIME ZONE 'Africa/Lagos')
  AND o.paid_at < (:'until_date'::date::timestamp AT TIME ZONE 'Africa/Lagos')
 GROUP BY p.category_id
)
SELECT c.name AS current_category,coalesce(s.units_sold,0) AS units_sold,
       coalesce(s.purchase_orders,0) AS purchase_orders,coalesce(s.revenue_ngn,0) AS revenue_ngn
FROM retail.categories c LEFT JOIN category_sales s USING(category_id)
ORDER BY revenue_ngn DESC,c.name;
