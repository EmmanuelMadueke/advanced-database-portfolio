-- Owner, author, maintainer: Emmanuel Madueke
SELECT json_build_object('pid',pg_backend_pid(),
 'stock',(SELECT available_quantity FROM retail.inventory JOIN retail.product_variants USING(variant_id) WHERE sku='COMMIT-SHIRT'),
 'jacket_stock',(SELECT available_quantity FROM retail.inventory JOIN retail.product_variants USING(variant_id) WHERE sku='COMMIT-JACKET'),
 'orders',(SELECT count(*) FROM retail.orders),
 'paid_orders',(SELECT count(*) FROM retail.orders WHERE status='paid'),
 'items',(SELECT count(*) FROM retail.order_items),
 'units',(SELECT coalesce(sum(quantity),0) FROM retail.order_items),
 'payments',(SELECT count(*) FROM retail.payments),
 'successes',(SELECT count(*) FROM retail.payments WHERE status='succeeded' AND amount=12000 AND provider_reference='P3-PROTECTED-A'),
 'loser_orders',(SELECT count(*) FROM retail.orders JOIN retail.customers USING(customer_id) WHERE email='second@example.test'),
 'reconciled',(SELECT bool_and(o.total_amount=12000 AND o.total_amount=p.amount AND o.currency_code=p.currency_code AND o.paid_at=p.completed_at)
 FROM retail.orders o JOIN retail.payments p USING(order_id)));
