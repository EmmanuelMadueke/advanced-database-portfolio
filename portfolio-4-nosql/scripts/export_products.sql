-- Owner, author, maintainer: Emmanuel Madueke
-- One read-only statement provides a consistent source snapshot, with string IDs.
SELECT json_build_object(
 'source_database',current_database(), 'server_version',version(),
 'exported_at',clock_timestamp(),
 'products',(SELECT coalesce(json_agg(row_to_json(p) ORDER BY p.product_id::bigint),'[]'::json)
 FROM (SELECT p.product_id::text AS product_id,p.name,c.name AS category,b.name AS brand,
 p.audience,p.is_active FROM retail.products p JOIN retail.categories c USING(category_id)
 JOIN retail.brands b USING(brand_id)) p));
