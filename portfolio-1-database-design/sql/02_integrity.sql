-- Owner, author, maintainer: Emmanuel Madueke
-- Run after 01_schema.sql. These triggers validate final transaction state.
BEGIN;
SET LOCAL search_path = retail, pg_catalog;

CREATE FUNCTION retail.guard_order() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, retail AS $$
BEGIN
 IF TG_OP = 'INSERT' THEN
   IF NEW.status <> 'pending' THEN RAISE EXCEPTION 'orders must start pending'; END IF;
 ELSE
   IF NEW.order_id <> OLD.order_id OR NEW.customer_id <> OLD.customer_id THEN
     RAISE EXCEPTION 'order identity is immutable';
   END IF;
   IF NEW.status <> OLD.status AND NOT (
     (OLD.status='pending' AND NEW.status IN ('paid','cancelled')) OR
     (OLD.status='paid' AND NEW.status='processing') OR
     (OLD.status='processing' AND NEW.status='dispatched') OR
     (OLD.status='dispatched' AND NEW.status='delivered')) THEN
     RAISE EXCEPTION 'invalid order transition: % to %', OLD.status, NEW.status;
   END IF;
   IF OLD.status <> 'pending' AND
      (to_jsonb(NEW)-'status') IS DISTINCT FROM (to_jsonb(OLD)-'status') THEN
     RAISE EXCEPTION 'finalised order facts are immutable';
   END IF;
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER order_guard BEFORE INSERT OR UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION retail.guard_order();

CREATE FUNCTION retail.guard_child() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, retail AS $$
DECLARE oid bigint; state text;
BEGIN
 oid := CASE WHEN TG_OP='DELETE' THEN OLD.order_id ELSE NEW.order_id END;
 IF TG_OP='UPDATE' AND NEW.order_id <> OLD.order_id THEN
   RAISE EXCEPTION 'child order identity is immutable';
 END IF;
 SELECT status INTO state FROM retail.orders WHERE order_id=oid FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'parent order does not exist'; END IF;
 IF TG_TABLE_NAME='order_items' THEN
   IF state <> 'pending' THEN RAISE EXCEPTION 'only pending order items can change'; END IF;
   IF TG_OP='UPDATE' AND NEW.variant_id <> OLD.variant_id THEN
     RAISE EXCEPTION 'replace pending lines instead of changing their key';
   END IF;
 ELSIF TG_TABLE_NAME='payments' THEN
   IF TG_OP='DELETE' THEN RAISE EXCEPTION 'payment history cannot be deleted'; END IF;
   IF TG_OP='INSERT' AND (NEW.status <> 'pending' OR state <> 'pending') THEN
     RAISE EXCEPTION 'payment attempts must start pending on a pending order';
   END IF;
   IF TG_OP='UPDATE' THEN
     IF OLD.status <> 'pending' THEN RAISE EXCEPTION 'terminal payment is immutable'; END IF;
     IF state <> 'pending' THEN RAISE EXCEPTION 'payment changes require pending order'; END IF;
     IF NEW.payment_id <> OLD.payment_id OR NEW.created_at <> OLD.created_at THEN
       RAISE EXCEPTION 'payment identity/time is immutable';
     END IF;
   END IF;
 ELSIF TG_TABLE_NAME='deliveries' THEN
   IF TG_OP='DELETE' THEN RAISE EXCEPTION 'delivery history cannot be deleted'; END IF;
   IF TG_OP='INSERT' AND NEW.status <> 'pending' THEN
     RAISE EXCEPTION 'delivery must start pending';
   END IF;
   IF TG_OP='UPDATE' THEN
     IF NEW.delivery_id <> OLD.delivery_id THEN RAISE EXCEPTION 'delivery identity is immutable'; END IF;
     IF NEW.status <> OLD.status AND NOT (
        (OLD.status='pending' AND NEW.status='dispatched') OR
        (OLD.status='dispatched' AND NEW.status='delivered')) THEN
        RAISE EXCEPTION 'invalid delivery transition';
     END IF;
     IF OLD.status='delivered' AND NEW IS DISTINCT FROM OLD THEN
       RAISE EXCEPTION 'delivered shipment is immutable';
     END IF;
     IF OLD.status='dispatched' AND (NEW.dispatched_at IS DISTINCT FROM OLD.dispatched_at) THEN
       RAISE EXCEPTION 'dispatch time is immutable';
     END IF;
   END IF;
 END IF;
 RETURN CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
END $$;
CREATE TRIGGER item_guard BEFORE INSERT OR UPDATE OR DELETE ON order_items
FOR EACH ROW EXECUTE FUNCTION retail.guard_child();
CREATE TRIGGER payment_guard BEFORE INSERT OR UPDATE OR DELETE ON payments
FOR EACH ROW EXECUTE FUNCTION retail.guard_child();
CREATE TRIGGER delivery_guard BEFORE INSERT OR UPDATE OR DELETE ON deliveries
FOR EACH ROW EXECUTE FUNCTION retail.guard_child();

CREATE FUNCTION retail.validate_order() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, retail AS $$
DECLARE oid bigint; o retail.orders%ROWTYPE; d retail.deliveries%ROWTYPE;
        n integer; total numeric; successes integer; p retail.payments%ROWTYPE;
BEGIN
 oid := CASE WHEN TG_OP='DELETE' THEN OLD.order_id ELSE NEW.order_id END;
 SELECT * INTO o FROM retail.orders WHERE order_id=oid FOR UPDATE;
 IF NOT FOUND THEN RETURN NULL; END IF;
 SELECT count(*),coalesce(sum(quantity::numeric*unit_price),0) INTO n,total
 FROM retail.order_items WHERE order_id=oid;
 IF o.total_amount <> total THEN RAISE EXCEPTION 'order total does not match items'; END IF;
 SELECT count(*) INTO successes FROM retail.payments WHERE order_id=oid AND status='succeeded';
 IF o.status IN ('pending','cancelled') THEN
   IF successes <> 0 THEN RAISE EXCEPTION 'unpaid order cannot have successful payment'; END IF;
 ELSE
   IF n=0 OR successes<>1 THEN RAISE EXCEPTION 'paid order needs items and one success'; END IF;
   SELECT * INTO p FROM retail.payments WHERE order_id=oid AND status='succeeded';
   IF p.amount<>o.total_amount OR p.currency_code<>o.currency_code OR p.completed_at<>o.paid_at THEN
     RAISE EXCEPTION 'successful payment must match order amount, currency and paid time';
   END IF;
 END IF;
 SELECT * INTO d FROM retail.deliveries WHERE order_id=oid;
 IF o.status IN ('dispatched','delivered') THEN
   IF NOT FOUND OR d.status<>o.status THEN RAISE EXCEPTION 'order and delivery state mismatch'; END IF;
 ELSIF FOUND AND d.status<>'pending' THEN RAISE EXCEPTION 'shipment requires dispatched order';
 END IF;
 IF d.dispatched_at IS NOT NULL AND
    (o.paid_at IS NULL OR d.dispatched_at<o.created_at OR d.dispatched_at<o.paid_at) THEN
   RAISE EXCEPTION 'shipment precedes order/payment';
 END IF;
 RETURN NULL;
END $$;
CREATE CONSTRAINT TRIGGER order_consistency AFTER INSERT OR UPDATE ON orders
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION retail.validate_order();
CREATE CONSTRAINT TRIGGER item_consistency AFTER INSERT OR UPDATE OR DELETE ON order_items
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION retail.validate_order();
CREATE CONSTRAINT TRIGGER payment_consistency AFTER INSERT OR UPDATE OR DELETE ON payments
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION retail.validate_order();
CREATE CONSTRAINT TRIGGER delivery_consistency AFTER INSERT OR UPDATE OR DELETE ON deliveries
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION retail.validate_order();

CREATE FUNCTION retail.validate_inventory() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, retail AS $$
DECLARE vid bigint;
BEGIN
 vid := CASE WHEN TG_OP='DELETE' THEN OLD.variant_id ELSE NEW.variant_id END;
 IF EXISTS (SELECT 1 FROM retail.product_variants WHERE variant_id=vid) AND
    NOT EXISTS (SELECT 1 FROM retail.inventory WHERE variant_id=vid) THEN
   RAISE EXCEPTION 'variant requires inventory at commit';
 END IF;
 -- Rekeying must not leave the old variant without inventory.
 IF TG_OP='UPDATE' AND NEW.variant_id<>OLD.variant_id AND
    EXISTS (SELECT 1 FROM retail.product_variants WHERE variant_id=OLD.variant_id) AND
    NOT EXISTS (SELECT 1 FROM retail.inventory WHERE variant_id=OLD.variant_id) THEN
   RAISE EXCEPTION 'old variant requires inventory';
 END IF;
 RETURN NULL;
END $$;
CREATE CONSTRAINT TRIGGER variant_inventory AFTER INSERT ON product_variants
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION retail.validate_inventory();
CREATE CONSTRAINT TRIGGER inventory_presence AFTER DELETE ON inventory
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION retail.validate_inventory();
CREATE CONSTRAINT TRIGGER inventory_rekey AFTER UPDATE ON inventory
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
WHEN (OLD.variant_id IS DISTINCT FROM NEW.variant_id)
EXECUTE FUNCTION retail.validate_inventory();

CREATE FUNCTION retail.guard_cart_item() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog, retail AS $$
DECLARE cid bigint; state text;
BEGIN
 cid := CASE WHEN TG_OP='DELETE' THEN OLD.cart_id ELSE NEW.cart_id END;
 IF TG_OP='UPDATE' AND (NEW.cart_id,NEW.variant_id) IS DISTINCT FROM (OLD.cart_id,OLD.variant_id) THEN
   RAISE EXCEPTION 'cart line key is immutable';
 END IF;
 SELECT status INTO state FROM retail.shopping_carts WHERE cart_id=cid FOR UPDATE;
 -- Permit cascaded deletion after the parent has been removed.
 IF NOT FOUND AND TG_OP='DELETE' THEN RETURN OLD; END IF;
 IF state IS DISTINCT FROM 'active' THEN RAISE EXCEPTION 'cart must be active'; END IF;
 UPDATE retail.shopping_carts SET updated_at=clock_timestamp() WHERE cart_id=cid;
 RETURN CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
END $$;
CREATE TRIGGER cart_item_guard BEFORE INSERT OR UPDATE OR DELETE ON cart_items
FOR EACH ROW EXECUTE FUNCTION retail.guard_cart_item();

REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA retail FROM PUBLIC;
COMMIT;
