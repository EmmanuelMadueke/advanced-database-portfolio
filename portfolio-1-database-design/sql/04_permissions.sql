-- Owner, author, maintainer: Emmanuel Madueke
-- Requires CREATEROLE for first use. NOLOGIN demo role; no passwords/secrets.
-- This dedicated role is for trusted portfolio workflow tests, not customer authentication.
BEGIN;
DO $$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='fashion_portfolio_writer') THEN
   CREATE ROLE fashion_portfolio_writer NOLOGIN;
 END IF;
 IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='fashion_portfolio_writer'
            AND (rolsuper OR rolcreaterole OR rolcreatedb OR rolcanlogin OR rolbypassrls)) THEN
   RAISE EXCEPTION 'existing demo role has unexpected elevated attributes';
 END IF;
END $$;
GRANT USAGE ON SCHEMA retail TO fashion_portfolio_writer;
GRANT SELECT ON ALL TABLES IN SCHEMA retail TO fashion_portfolio_writer;
-- Direct DML remains unavailable. Catalogue/identity setup is owner maintenance.
GRANT EXECUTE ON FUNCTION retail.create_order(bigint,bigint,bigint[],integer[]),
 retail.finalise_order(bigint,text,text),retail.record_failed_payment(bigint,text,text),
 retail.cancel_order(bigint),retail.dispatch_order(bigint,text,text),
 retail.deliver_order(bigint),retail.set_cart_item(bigint,bigint,integer)
TO fashion_portfolio_writer;
COMMIT;
