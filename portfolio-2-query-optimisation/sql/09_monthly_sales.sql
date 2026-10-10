-- Owner, author, maintainer: Emmanuel Madueke
-- Lagos calendar months, including months with zero sales; half-open selected dates.
\set ON_ERROR_STOP on
\if :{?from_date}
\else
\set from_date 2026-01-01
\endif
\if :{?until_date}
\else
\set until_date 2027-01-01
\endif

WITH months AS (
 SELECT generate_series(date_trunc('month',:'from_date'::date::timestamp),
        date_trunc('month',(:'until_date'::date-1)::timestamp),interval '1 month')::date AS month_start
 WHERE :'from_date'::date<:'until_date'::date
), sales AS (
 SELECT date_trunc('month',o.paid_at AT TIME ZONE 'Africa/Lagos')::date AS month_start,
        count(*) AS paid_orders,sum(o.total_amount) AS revenue_ngn
 FROM retail.orders o WHERE o.status IN ('paid','processing','dispatched','delivered')
  AND o.paid_at >= (:'from_date'::date::timestamp AT TIME ZONE 'Africa/Lagos')
  AND o.paid_at < (:'until_date'::date::timestamp AT TIME ZONE 'Africa/Lagos')
 GROUP BY 1
)
SELECT m.month_start,coalesce(s.paid_orders,0) AS paid_orders,coalesce(s.revenue_ngn,0) AS revenue_ngn
FROM months m LEFT JOIN sales s USING(month_start)
ORDER BY m.month_start;
