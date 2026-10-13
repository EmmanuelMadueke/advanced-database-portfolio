-- Owner, author, maintainer: Emmanuel Madueke
-- Removes only the three reporting indexes introduced by this activity.
BEGIN;
DROP INDEX IF EXISTS retail.reporting_orders_customer_history;
DROP INDEX IF EXISTS retail.reporting_payments_order;
DROP INDEX IF EXISTS retail.reporting_orders_paid_date;
COMMIT;
