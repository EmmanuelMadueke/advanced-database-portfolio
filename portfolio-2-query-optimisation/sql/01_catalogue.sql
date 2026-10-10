-- Owner, author, maintainer: Emmanuel Madueke
-- Available variants matching selected catalogue filters.
\set ON_ERROR_STOP on
\if :{?category}
\else
\set category Clothing
\endif
\if :{?brand}
\else
\set brand 'Lagos Threads'
\endif
\if :{?audience}
\else
\set audience unisex
\endif
\if :{?size}
\else
\set size M
\endif
\if :{?colour}
\else
\set colour Black
\endif
\if :{?min_price}
\else
\set min_price 0
\endif
\if :{?max_price}
\else
\set max_price 20000
\endif

SELECT v.sku,p.name AS product_name,c.name AS category,b.name AS brand,p.audience,
       s.label AS size,cl.name AS colour,v.unit_price,inv.available_quantity
FROM retail.product_variants v
JOIN retail.products p USING(product_id) JOIN retail.categories c USING(category_id)
JOIN retail.brands b USING(brand_id) JOIN retail.sizes s USING(size_id)
JOIN retail.colours cl USING(colour_id) JOIN retail.inventory inv USING(variant_id)
WHERE p.is_active AND v.is_active AND inv.available_quantity>0
  AND c.name=:'category' AND b.name=:'brand' AND p.audience=:'audience'
  AND s.label=:'size' AND cl.name=:'colour'
  AND v.unit_price>=:'min_price'::numeric AND v.unit_price<=:'max_price'::numeric
ORDER BY v.unit_price,v.sku;
