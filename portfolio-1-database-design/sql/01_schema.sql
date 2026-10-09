-- Owner, author, maintainer: Emmanuel Madueke
-- Run with psql -v ON_ERROR_STOP=1 against a fresh portfolio database.
BEGIN;
CREATE SCHEMA retail;
REVOKE ALL ON SCHEMA retail FROM PUBLIC;
SET LOCAL search_path = retail, pg_catalog;

CREATE TABLE customers (
  customer_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  first_name varchar(100) NOT NULL CHECK ((first_name IS NULL OR (btrim(first_name) <> '' AND first_name = btrim(first_name)))),
  last_name varchar(100) NOT NULL CHECK ((last_name IS NULL OR (btrim(last_name) <> '' AND last_name = btrim(last_name)))),
  email varchar(254) NOT NULL CHECK ((email IS NULL OR (btrim(email) <> '' AND email = btrim(email)))),
  phone varchar(32) NOT NULL CHECK ((phone IS NULL OR (btrim(phone) <> '' AND phone = btrim(phone)))),
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP NOT NULL,
  is_active boolean DEFAULT true NOT NULL,
  UNIQUE (email),
  CHECK (email = lower(btrim(email)))
);

CREATE TABLE customer_addresses (
  address_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  customer_id bigint NOT NULL REFERENCES customers(customer_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  recipient_name varchar(200) NOT NULL CHECK ((recipient_name IS NULL OR (btrim(recipient_name) <> '' AND recipient_name = btrim(recipient_name)))),
  recipient_phone varchar(32) NOT NULL CHECK ((recipient_phone IS NULL OR (btrim(recipient_phone) <> '' AND recipient_phone = btrim(recipient_phone)))),
  address_line_1 varchar(255) NOT NULL CHECK ((address_line_1 IS NULL OR (btrim(address_line_1) <> '' AND address_line_1 = btrim(address_line_1)))),
  address_line_2 varchar(255) CHECK ((address_line_2 IS NULL OR (btrim(address_line_2) <> '' AND address_line_2 = btrim(address_line_2)))),
  city varchar(100) NOT NULL CHECK ((city IS NULL OR (btrim(city) <> '' AND city = btrim(city)))),
  state_region varchar(100) NOT NULL CHECK ((state_region IS NULL OR (btrim(state_region) <> '' AND state_region = btrim(state_region)))),
  postal_code varchar(20) CHECK ((postal_code IS NULL OR (btrim(postal_code) <> '' AND postal_code = btrim(postal_code)))),
  country_code varchar(2) NOT NULL CHECK ((country_code IS NULL OR (btrim(country_code) <> '' AND country_code = btrim(country_code))) AND country_code ~ '^[A-Z]{2}$')
);

CREATE TABLE categories (
  category_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  name varchar(160) NOT NULL CHECK ((name IS NULL OR (btrim(name) <> '' AND name = btrim(name)))),
  description text CHECK ((description IS NULL OR (btrim(description) <> '' AND description = btrim(description))))
);

CREATE TABLE brands (
  brand_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  name varchar(160) NOT NULL CHECK ((name IS NULL OR (btrim(name) <> '' AND name = btrim(name))))
);

CREATE TABLE products (
  product_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  category_id bigint NOT NULL REFERENCES categories(category_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  brand_id bigint NOT NULL REFERENCES brands(brand_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  name varchar(160) NOT NULL CHECK ((name IS NULL OR (btrim(name) <> '' AND name = btrim(name)))),
  description text NOT NULL CHECK ((description IS NULL OR (btrim(description) <> '' AND description = btrim(description)))),
  audience varchar(10) NOT NULL CHECK ((audience IS NULL OR (btrim(audience) <> '' AND audience = btrim(audience))) AND audience IN ('women', 'men', 'unisex', 'kids')),
  is_active boolean DEFAULT true NOT NULL,
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE sizes (
  size_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  label varchar(40) NOT NULL CHECK ((label IS NULL OR (btrim(label) <> '' AND label = btrim(label)))),
  description text CHECK ((description IS NULL OR (btrim(description) <> '' AND description = btrim(description))))
);

CREATE TABLE colours (
  colour_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  name varchar(160) NOT NULL CHECK ((name IS NULL OR (btrim(name) <> '' AND name = btrim(name)))),
  hex_code varchar(7) CHECK ((hex_code IS NULL OR (btrim(hex_code) <> '' AND hex_code = btrim(hex_code))) AND hex_code IS NULL OR hex_code ~ '^#[0-9A-Fa-f]{6}$')
);

CREATE TABLE product_variants (
  variant_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  product_id bigint NOT NULL REFERENCES products(product_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  size_id bigint NOT NULL REFERENCES sizes(size_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  colour_id bigint NOT NULL REFERENCES colours(colour_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  sku varchar(64) NOT NULL CHECK ((sku IS NULL OR (btrim(sku) <> '' AND sku = btrim(sku)))),
  unit_price numeric(14,2) NOT NULL CHECK (unit_price >= 0 AND unit_price <> 'NaN'::numeric),
  is_active boolean DEFAULT true NOT NULL,
  UNIQUE (sku),
  UNIQUE (product_id, size_id, colour_id)
);

CREATE TABLE inventory (
  variant_id bigint NOT NULL PRIMARY KEY REFERENCES product_variants(variant_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  available_quantity integer DEFAULT 0 NOT NULL CHECK (available_quantity >= 0),
  low_stock_threshold integer DEFAULT 5 NOT NULL CHECK (low_stock_threshold >= 0),
  updated_at timestamptz DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE shopping_carts (
  cart_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  customer_id bigint NOT NULL REFERENCES customers(customer_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  status varchar(20) DEFAULT 'active' NOT NULL CHECK ((status IS NULL OR (btrim(status) <> '' AND status = btrim(status))) AND status IN ('active', 'converted', 'abandoned')),
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at timestamptz DEFAULT CURRENT_TIMESTAMP NOT NULL,
  CHECK (updated_at >= created_at)
);

CREATE TABLE cart_items (
  cart_id bigint NOT NULL REFERENCES shopping_carts(cart_id) ON UPDATE RESTRICT ON DELETE CASCADE,
  variant_id bigint NOT NULL REFERENCES product_variants(variant_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  quantity integer NOT NULL CHECK (quantity > 0),
  PRIMARY KEY (cart_id, variant_id)
);

CREATE TABLE orders (
  order_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  customer_id bigint NOT NULL REFERENCES customers(customer_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  status varchar(20) DEFAULT 'pending' NOT NULL CHECK ((status IS NULL OR (btrim(status) <> '' AND status = btrim(status))) AND status IN ('pending', 'paid', 'processing', 'dispatched', 'delivered', 'cancelled')),
  currency_code varchar(3) DEFAULT 'NGN' NOT NULL CHECK ((currency_code IS NULL OR (btrim(currency_code) <> '' AND currency_code = btrim(currency_code))) AND currency_code = 'NGN'),
  total_amount numeric(14,2) DEFAULT 0.00 NOT NULL CHECK (total_amount >= 0 AND total_amount <> 'NaN'::numeric),
  recipient_name varchar(200) NOT NULL CHECK ((recipient_name IS NULL OR (btrim(recipient_name) <> '' AND recipient_name = btrim(recipient_name)))),
  recipient_phone varchar(32) NOT NULL CHECK ((recipient_phone IS NULL OR (btrim(recipient_phone) <> '' AND recipient_phone = btrim(recipient_phone)))),
  address_line_1 varchar(255) NOT NULL CHECK ((address_line_1 IS NULL OR (btrim(address_line_1) <> '' AND address_line_1 = btrim(address_line_1)))),
  address_line_2 varchar(255) CHECK ((address_line_2 IS NULL OR (btrim(address_line_2) <> '' AND address_line_2 = btrim(address_line_2)))),
  city varchar(100) NOT NULL CHECK ((city IS NULL OR (btrim(city) <> '' AND city = btrim(city)))),
  state_region varchar(100) NOT NULL CHECK ((state_region IS NULL OR (btrim(state_region) <> '' AND state_region = btrim(state_region)))),
  postal_code varchar(20) CHECK ((postal_code IS NULL OR (btrim(postal_code) <> '' AND postal_code = btrim(postal_code)))),
  country_code varchar(2) NOT NULL CHECK ((country_code IS NULL OR (btrim(country_code) <> '' AND country_code = btrim(country_code))) AND country_code ~ '^[A-Z]{2}$'),
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP NOT NULL,
  paid_at timestamptz,
  CHECK ((status IN ('pending','cancelled') AND paid_at IS NULL) OR (status IN ('paid','processing','dispatched','delivered') AND paid_at IS NOT NULL AND paid_at >= created_at))
);

CREATE TABLE order_items (
  order_id bigint NOT NULL REFERENCES orders(order_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  variant_id bigint NOT NULL REFERENCES product_variants(variant_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  quantity integer NOT NULL CHECK (quantity > 0),
  unit_price numeric(14,2) NOT NULL CHECK (unit_price >= 0 AND unit_price <> 'NaN'::numeric),
  product_name_snapshot varchar(160) NOT NULL CHECK ((product_name_snapshot IS NULL OR (btrim(product_name_snapshot) <> '' AND product_name_snapshot = btrim(product_name_snapshot)))),
  sku_snapshot varchar(64) NOT NULL CHECK ((sku_snapshot IS NULL OR (btrim(sku_snapshot) <> '' AND sku_snapshot = btrim(sku_snapshot)))),
  size_label_snapshot varchar(40) NOT NULL CHECK ((size_label_snapshot IS NULL OR (btrim(size_label_snapshot) <> '' AND size_label_snapshot = btrim(size_label_snapshot)))),
  colour_name_snapshot varchar(160) NOT NULL CHECK ((colour_name_snapshot IS NULL OR (btrim(colour_name_snapshot) <> '' AND colour_name_snapshot = btrim(colour_name_snapshot)))),
  PRIMARY KEY (order_id, variant_id)
);

CREATE TABLE payments (
  payment_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  order_id bigint NOT NULL REFERENCES orders(order_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  method varchar(20) NOT NULL CHECK ((method IS NULL OR (btrim(method) <> '' AND method = btrim(method))) AND method IN ('card', 'bank_transfer', 'wallet')),
  provider_reference varchar(120) CHECK ((provider_reference IS NULL OR (btrim(provider_reference) <> '' AND provider_reference = btrim(provider_reference)))),
  amount numeric(14,2) NOT NULL CHECK (amount >= 0 AND amount <> 'NaN'::numeric),
  currency_code varchar(3) DEFAULT 'NGN' NOT NULL CHECK ((currency_code IS NULL OR (btrim(currency_code) <> '' AND currency_code = btrim(currency_code))) AND currency_code = 'NGN'),
  status varchar(20) DEFAULT 'pending' NOT NULL CHECK ((status IS NULL OR (btrim(status) <> '' AND status = btrim(status))) AND status IN ('pending', 'succeeded', 'failed')),
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP NOT NULL,
  completed_at timestamptz,
  UNIQUE (provider_reference),
  CHECK ((status = 'pending' AND completed_at IS NULL) OR (status IN ('succeeded','failed') AND completed_at IS NOT NULL AND completed_at >= created_at)),
  CHECK (status <> 'succeeded' OR provider_reference IS NOT NULL)
);

CREATE TABLE deliveries (
  delivery_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  order_id bigint NOT NULL REFERENCES orders(order_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  carrier varchar(100) CHECK ((carrier IS NULL OR (btrim(carrier) <> '' AND carrier = btrim(carrier)))),
  tracking_reference varchar(120) CHECK ((tracking_reference IS NULL OR (btrim(tracking_reference) <> '' AND tracking_reference = btrim(tracking_reference)))),
  status varchar(20) DEFAULT 'pending' NOT NULL CHECK ((status IS NULL OR (btrim(status) <> '' AND status = btrim(status))) AND status IN ('pending', 'dispatched', 'delivered')),
  dispatched_at timestamptz,
  delivered_at timestamptz,
  UNIQUE (order_id),
  CHECK ((status = 'pending' AND dispatched_at IS NULL AND delivered_at IS NULL) OR (status = 'dispatched' AND dispatched_at IS NOT NULL AND delivered_at IS NULL) OR (status = 'delivered' AND dispatched_at IS NOT NULL AND delivered_at IS NOT NULL AND delivered_at >= dispatched_at))
);

CREATE TABLE administrators (
  administrator_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  display_name varchar(200) NOT NULL CHECK ((display_name IS NULL OR (btrim(display_name) <> '' AND display_name = btrim(display_name)))),
  email varchar(254) NOT NULL CHECK ((email IS NULL OR (btrim(email) <> '' AND email = btrim(email)))),
  is_active boolean DEFAULT true NOT NULL,
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP NOT NULL,
  UNIQUE (email),
  CHECK (email = lower(btrim(email)))
);

CREATE UNIQUE INDEX categories_canonical_name ON categories (lower(btrim(name)));

CREATE UNIQUE INDEX brands_canonical_name ON brands (lower(btrim(name)));

CREATE UNIQUE INDEX sizes_canonical_name ON sizes (lower(btrim(label)));

CREATE UNIQUE INDEX colours_canonical_name ON colours (lower(btrim(name)));

CREATE UNIQUE INDEX one_active_cart ON shopping_carts(customer_id) WHERE status = 'active';

CREATE UNIQUE INDEX one_successful_payment ON payments(order_id) WHERE status = 'succeeded';

COMMIT;
