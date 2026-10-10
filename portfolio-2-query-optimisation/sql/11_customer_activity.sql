-- Owner, author, maintainer: Emmanuel Madueke
-- All customers with paid purchases in period, including zero-purchase customers.
\set ON_ERROR_STOP on
\if :{?from_date}
\else
\set from_date 2026-01-01
\endif
\if :{?until_date}
\else
\set until_date 2027-01-01
\endif

WITH purchases AS (
 SELECT o.customer_id,count(*) AS paid_orders,sum(o.total_amount) AS period_spend_ngn,
        max(o.paid_at) AS last_paid_at
 FROM retail.orders o WHERE o.status IN ('paid','processing','dispatched','delivered')
  AND o.paid_at >= (:'from_date'::date::timestamp AT TIME ZONE 'Africa/Lagos')
  AND o.paid_at < (:'until_date'::date::timestamp AT TIME ZONE 'Africa/Lagos') GROUP BY o.customer_id
)
SELECT c.email,c.first_name,c.last_name,coalesce(p.paid_orders,0) AS paid_orders,
       coalesce(p.period_spend_ngn,0) AS total_spend_ngn,p.last_paid_at
FROM retail.customers c LEFT JOIN purchases p USING(customer_id)
ORDER BY total_spend_ngn DESC,c.email;
