-- Owner, author, maintainer: Emmanuel Madueke
-- Recognised revenue, paid order count, and average order value for selected dates.
\set ON_ERROR_STOP on
\if :{?from_date}
\else
\set from_date 2026-01-01
\endif
\if :{?until_date}
\else
\set until_date 2027-01-01
\endif

SELECT count(*) AS paid_orders,coalesce(sum(o.total_amount),0) AS revenue_ngn,
       coalesce(round(avg(o.total_amount),2),0) AS average_order_ngn
FROM retail.orders o WHERE o.status IN ('paid','processing','dispatched','delivered')
  AND o.paid_at >= (:'from_date'::date::timestamp AT TIME ZONE 'Africa/Lagos')
  AND o.paid_at < (:'until_date'::date::timestamp AT TIME ZONE 'Africa/Lagos');
