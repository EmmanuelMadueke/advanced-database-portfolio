-- Owner, author, maintainer: Emmanuel Madueke
-- Execute all reports in one consistent read-only snapshot.
\set ON_ERROR_STOP on
BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY;
\echo 01_catalogue
\ir 01_catalogue.sql
\echo 02_inventory
\ir 02_inventory.sql
\echo 03_customer_history
\ir 03_customer_history.sql
\echo 04_open_orders
\ir 04_open_orders.sql
\echo 05_delivery_tracking
\ir 05_delivery_tracking.sql
\echo 06_best_selling_variants
\ir 06_best_selling_variants.sql
\echo 07_sales_by_product
\ir 07_sales_by_product.sql
\echo 08_sales_by_category
\ir 08_sales_by_category.sql
\echo 09_monthly_sales
\ir 09_monthly_sales.sql
\echo 10_revenue_summary
\ir 10_revenue_summary.sql
\echo 11_customer_activity
\ir 11_customer_activity.sql
\echo 12_payment_exceptions
\ir 12_payment_exceptions.sql
COMMIT;
