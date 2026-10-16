-- Owner, author, maintainer: Emmanuel Madueke
-- One statement gives all fields the same snapshot. Use in either session.
SELECT json_build_object(
 'pid',pg_backend_pid(), 'isolation',current_setting('transaction_isolation'),
 'role',current_user, 'read_only',current_setting('transaction_read_only'),
 'orders',(SELECT count(*) FROM retail.orders),
 'items',(SELECT count(*) FROM retail.order_items),
 'payments',(SELECT count(*) FROM retail.payments),
 'paid_orders',(SELECT count(*) FROM retail.orders WHERE status='paid'),
 'successes',(SELECT count(*) FROM retail.payments WHERE status='succeeded'),
 'revenue',(SELECT coalesce(sum(total_amount),0) FROM retail.orders WHERE status='paid'),
 'shirt',(SELECT available_quantity FROM retail.inventory JOIN retail.product_variants USING(variant_id) WHERE sku='COMMIT-SHIRT'),
 'jacket',(SELECT available_quantity FROM retail.inventory JOIN retail.product_variants USING(variant_id) WHERE sku='COMMIT-JACKET')
);
