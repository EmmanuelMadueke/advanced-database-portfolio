-- Owner, author, maintainer: Emmanuel Madueke
-- Controlled, simulated purchase operations. No external payment gateway.
BEGIN;
SET LOCAL search_path=retail,pg_catalog;

CREATE FUNCTION retail.checked_money(value numeric) RETURNS numeric
LANGUAGE plpgsql IMMUTABLE SET search_path=pg_catalog,retail AS $$
BEGIN
 IF value IS NULL OR value='NaN'::numeric OR value<0 OR value>=1000000000000
    OR value<>round(value,2) THEN RAISE EXCEPTION 'invalid two-decimal monetary value'; END IF;
 RETURN value;
END $$;

CREATE FUNCTION retail.create_order(customer bigint,address bigint,variants bigint[],quantities integer[])
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,retail AS $$
DECLARE oid bigint; a retail.customer_addresses%ROWTYPE; i integer; v record;
BEGIN
 IF variants IS NULL OR quantities IS NULL OR cardinality(variants)=0 OR
    array_ndims(variants)<>1 OR array_ndims(quantities)<>1 OR
    array_lower(variants,1)<>1 OR array_lower(quantities,1)<>1 OR
    cardinality(variants)<>cardinality(quantities) THEN RAISE EXCEPTION 'nonempty matching arrays required'; END IF;
 IF EXISTS (SELECT 1 FROM unnest(variants) x GROUP BY x HAVING count(*)>1) THEN
   RAISE EXCEPTION 'duplicate variants in order request';
 END IF;
 PERFORM 1 FROM retail.customers WHERE customer_id=customer AND is_active FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'active customer required'; END IF;
 SELECT * INTO a FROM retail.customer_addresses WHERE address_id=address AND customer_id=customer FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'address must belong to customer'; END IF;
 INSERT INTO retail.orders(customer_id,recipient_name,recipient_phone,address_line_1,address_line_2,
   city,state_region,postal_code,country_code)
 VALUES(customer,a.recipient_name,a.recipient_phone,a.address_line_1,a.address_line_2,
   a.city,a.state_region,a.postal_code,a.country_code) RETURNING order_id INTO oid;
 FOR i IN 1..cardinality(variants) LOOP
   IF variants[i] IS NULL OR quantities[i] IS NULL OR quantities[i]<=0 THEN RAISE EXCEPTION 'invalid order line'; END IF;
   SELECT pv.*,p.name AS product_name,s.label AS size_label,c.name AS colour_name,inv.available_quantity
   INTO v FROM retail.product_variants pv JOIN retail.products p USING(product_id)
   JOIN retail.sizes s USING(size_id) JOIN retail.colours c USING(colour_id)
   JOIN retail.inventory inv USING(variant_id)
   WHERE pv.variant_id=variants[i] AND pv.is_active AND p.is_active;
   IF NOT FOUND OR v.available_quantity<quantities[i] THEN RAISE EXCEPTION 'variant unavailable at order creation'; END IF;
   INSERT INTO retail.order_items VALUES(oid,variants[i],quantities[i],v.unit_price,
     v.product_name,v.sku,v.size_label,v.colour_name);
 END LOOP;
 UPDATE retail.orders SET total_amount=retail.checked_money(
   (SELECT sum(quantity::numeric*unit_price) FROM retail.order_items WHERE order_id=oid)) WHERE order_id=oid;
 RETURN oid;
END $$;

CREATE FUNCTION retail.finalise_order(oid bigint,reference text,payment_method text DEFAULT 'card')
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,retail AS $$
DECLARE o retail.orders%ROWTYPE; line record; pid bigint; paid_time timestamptz;
BEGIN
 SELECT * INTO o FROM retail.orders WHERE order_id=oid FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'order not found'; END IF;
 IF o.status IN ('paid','processing','dispatched','delivered') THEN
   SELECT payment_id INTO pid FROM retail.payments WHERE order_id=oid AND status='succeeded';
   RETURN pid; -- Idempotent replay: no second deduction/payment.
 END IF;
 IF o.status<>'pending' THEN RAISE EXCEPTION 'only pending order can be finalised'; END IF;
 IF reference IS NULL OR btrim(reference)='' THEN RAISE EXCEPTION 'payment reference required'; END IF;
 IF NOT EXISTS (SELECT 1 FROM retail.order_items WHERE order_id=oid) THEN RAISE EXCEPTION 'empty order'; END IF;
 -- Protect catalogue facts while taking the purchase-time snapshot.
 PERFORM p.product_id FROM retail.products p WHERE p.product_id IN
   (SELECT v.product_id FROM retail.product_variants v JOIN retail.order_items i USING(variant_id) WHERE i.order_id=oid)
   ORDER BY p.product_id FOR SHARE;
 PERFORM v.variant_id FROM retail.product_variants v JOIN retail.order_items i USING(variant_id)
   WHERE i.order_id=oid ORDER BY v.variant_id FOR SHARE OF v;
 PERFORM s.size_id FROM retail.sizes s WHERE s.size_id IN
   (SELECT v.size_id FROM retail.product_variants v JOIN retail.order_items i USING(variant_id) WHERE i.order_id=oid)
   ORDER BY s.size_id FOR SHARE;
 PERFORM c.colour_id FROM retail.colours c WHERE c.colour_id IN
   (SELECT v.colour_id FROM retail.product_variants v JOIN retail.order_items i USING(variant_id) WHERE i.order_id=oid)
   ORDER BY c.colour_id FOR SHARE;
 PERFORM inv.variant_id FROM retail.inventory inv JOIN retail.order_items i USING(variant_id)
   WHERE i.order_id=oid ORDER BY inv.variant_id FOR UPDATE OF inv;
 FOR line IN SELECT i.*, inv.available_quantity, v.unit_price AS current_price,v.sku,
     v.is_active AS variant_active,p.is_active AS product_active,p.name AS product_name,
     s.label AS size_label,c.name AS colour_name
   FROM retail.order_items i JOIN retail.product_variants v USING(variant_id)
   JOIN retail.products p USING(product_id) JOIN retail.sizes s USING(size_id)
   JOIN retail.colours c USING(colour_id) JOIN retail.inventory inv USING(variant_id)
   WHERE i.order_id=oid ORDER BY i.variant_id LOOP
   IF NOT line.variant_active OR NOT line.product_active OR line.available_quantity<line.quantity THEN
     RAISE EXCEPTION 'insufficient stock or inactive variant %',line.variant_id;
   END IF;
   UPDATE retail.order_items SET unit_price=line.current_price,product_name_snapshot=line.product_name,
      sku_snapshot=line.sku,size_label_snapshot=line.size_label,colour_name_snapshot=line.colour_name
      WHERE order_id=oid AND variant_id=line.variant_id;
   UPDATE retail.inventory SET available_quantity=available_quantity-line.quantity,updated_at=clock_timestamp()
      WHERE variant_id=line.variant_id;
 END LOOP;
 UPDATE retail.orders SET total_amount=retail.checked_money(
    (SELECT sum(quantity::numeric*unit_price) FROM retail.order_items WHERE order_id=oid)) WHERE order_id=oid;
 INSERT INTO retail.payments(order_id,method,provider_reference,amount,currency_code)
 SELECT oid,payment_method,btrim(reference),total_amount,currency_code FROM retail.orders WHERE order_id=oid
 RETURNING payment_id INTO pid;
 paid_time:=clock_timestamp();
 UPDATE retail.payments SET status='succeeded',completed_at=paid_time WHERE payment_id=pid;
 UPDATE retail.orders SET status='paid',paid_at=paid_time WHERE order_id=oid;
 RETURN pid;
END $$;

CREATE FUNCTION retail.record_failed_payment(oid bigint,reference text,payment_method text DEFAULT 'card')
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,retail AS $$
DECLARE pid bigint;
BEGIN
 PERFORM 1 FROM retail.orders WHERE order_id=oid AND status='pending' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'failed attempt requires pending order'; END IF;
 INSERT INTO retail.payments(order_id,method,provider_reference,amount,currency_code)
 SELECT oid,payment_method,nullif(btrim(reference),''),total_amount,currency_code FROM retail.orders WHERE order_id=oid
 RETURNING payment_id INTO pid;
 UPDATE retail.payments SET status='failed',completed_at=clock_timestamp() WHERE payment_id=pid;
 RETURN pid;
END $$;

CREATE FUNCTION retail.cancel_order(oid bigint) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,retail AS $$
BEGIN
 UPDATE retail.orders SET status='cancelled' WHERE order_id=oid AND status='pending';
 IF NOT FOUND THEN RAISE EXCEPTION 'only pending orders can be cancelled'; END IF;
END $$;

CREATE FUNCTION retail.dispatch_order(oid bigint,carrier_name text,tracking text) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,retail AS $$
DECLARE state text;
BEGIN
 SELECT status INTO state FROM retail.orders WHERE order_id=oid FOR UPDATE;
 IF NOT FOUND OR state NOT IN ('paid','processing') THEN RAISE EXCEPTION 'paid/processing order required'; END IF;
 IF state='paid' THEN UPDATE retail.orders SET status='processing' WHERE order_id=oid; END IF;
 INSERT INTO retail.deliveries(order_id) VALUES(oid) ON CONFLICT(order_id) DO NOTHING;
 UPDATE retail.deliveries SET carrier=carrier_name,tracking_reference=tracking,status='dispatched',dispatched_at=clock_timestamp()
 WHERE order_id=oid;
 UPDATE retail.orders SET status='dispatched' WHERE order_id=oid;
END $$;

CREATE FUNCTION retail.deliver_order(oid bigint) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,retail AS $$
BEGIN
 PERFORM 1 FROM retail.orders WHERE order_id=oid AND status='dispatched' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'dispatched order required'; END IF;
 UPDATE retail.deliveries SET status='delivered',delivered_at=clock_timestamp() WHERE order_id=oid;
 UPDATE retail.orders SET status='delivered' WHERE order_id=oid;
END $$;

CREATE FUNCTION retail.set_cart_item(cid bigint,vid bigint,qty integer) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,retail AS $$
BEGIN
 IF qty IS NULL OR qty<0 THEN RAISE EXCEPTION 'cart quantity must be nonnegative'; END IF;
 PERFORM 1 FROM retail.shopping_carts WHERE cart_id=cid AND status='active' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'active cart required'; END IF;
 IF qty=0 THEN DELETE FROM retail.cart_items WHERE cart_id=cid AND variant_id=vid;
 ELSE
   INSERT INTO retail.cart_items VALUES(cid,vid,qty)
   ON CONFLICT(cart_id,variant_id) DO UPDATE SET quantity=excluded.quantity;
 END IF;
END $$;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA retail FROM PUBLIC;
COMMIT;
