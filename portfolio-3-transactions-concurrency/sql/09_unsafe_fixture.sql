-- Owner, author, maintainer: Emmanuel Madueke
-- Deliberately unsafe teaching model in a NEW disposable database only.
-- Does not install or modify retail tables, routines, or permissions.
\set ON_ERROR_STOP on
BEGIN;
CREATE SCHEMA unsafe_checkout;
REVOKE ALL ON SCHEMA unsafe_checkout FROM PUBLIC;
CREATE TABLE unsafe_checkout.stock (
 sku text PRIMARY KEY,
 available_quantity integer NOT NULL CHECK (available_quantity>=0)
);
CREATE TABLE unsafe_checkout.accepted_purchases (
 purchase_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 buyer text NOT NULL UNIQUE,
 sku text NOT NULL REFERENCES unsafe_checkout.stock(sku),
 quantity integer NOT NULL CHECK (quantity>0)
);
INSERT INTO unsafe_checkout.stock VALUES('LAST-SHIRT-M-BLACK',1);
COMMIT;
SELECT * FROM unsafe_checkout.stock;
