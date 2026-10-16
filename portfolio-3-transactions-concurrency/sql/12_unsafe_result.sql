-- Owner, author, maintainer: Emmanuel Madueke
SELECT json_build_object('pid',pg_backend_pid(),
 'stock',(SELECT available_quantity FROM unsafe_checkout.stock WHERE sku='LAST-SHIRT-M-BLACK'),
 'purchases',(SELECT count(*) FROM unsafe_checkout.accepted_purchases),
 'buyers',(SELECT count(DISTINCT buyer) FROM unsafe_checkout.accepted_purchases),
 'units_sold',(SELECT coalesce(sum(quantity),0) FROM unsafe_checkout.accepted_purchases));
SELECT buyer,sku,quantity FROM unsafe_checkout.accepted_purchases ORDER BY buyer;
