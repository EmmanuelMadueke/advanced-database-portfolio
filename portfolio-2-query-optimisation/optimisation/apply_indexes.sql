-- Owner, author, maintainer: Emmanuel Madueke
-- Apply once after seed scripts 01–06. Preserve all existing correctness indexes.
BEGIN;
-- Find one customer's orders without reading every order.
CREATE INDEX reporting_orders_customer_history
ON retail.orders(customer_id, created_at DESC, order_id DESC);
-- Retrieve/aggregate attempts for selected orders; includes only report fields.
CREATE INDEX reporting_payments_order
ON retail.payments(order_id) INCLUDE (status, provider_reference);
-- Eligible sales only; supports paid-date filtering and covers summary/group joins.
CREATE INDEX reporting_orders_paid_date
ON retail.orders(paid_at) INCLUDE (order_id, total_amount)
WHERE status IN ('paid','processing','dispatched','delivered');
COMMIT;
