-- Owner, author, maintainer: Emmanuel Madueke
-- Stock report: stock_filter is all, low_stock, out_of_stock, or available.
\set ON_ERROR_STOP on
\if :{?stock_filter}
\else
\set stock_filter all
\endif

WITH stock AS (
 SELECT v.sku,p.name AS product_name,v.is_active AS variant_active,p.is_active AS product_active,
        inv.available_quantity,inv.low_stock_threshold,
        CASE WHEN inv.available_quantity=0 THEN 'out_of_stock'
             WHEN inv.available_quantity<=inv.low_stock_threshold THEN 'low_stock'
             ELSE 'available' END AS stock_status
 FROM retail.product_variants v JOIN retail.products p USING(product_id)
 JOIN retail.inventory inv USING(variant_id)
)
SELECT * FROM stock WHERE :'stock_filter'='all' OR stock_status=:'stock_filter'
ORDER BY sku;
