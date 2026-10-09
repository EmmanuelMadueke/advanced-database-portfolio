# Data Dictionary

Owner, author, and maintainer: **Emmanuel Madueke**.

Design target: PostgreSQL. All 16 ERD entities are mapped below. These are planned definitions; no tables have been created or tested. See [relational schema](relational-schema.md) for composite keys, deletion policies, cross-column checks, and business-rule enforcement.

`NULL allowed: No` means NOT NULL, including all PK/FK columns. Optional strings use NULL for missing values, not empty strings. Surrogate PKs use `bigint GENERATED ALWAYS AS IDENTITY`; child keys reuse their parent's type. Length limits are project choices, not universal business standards. All monetary columns use NGN and two decimal places. Identity defaults require no extension. Email is stored trimmed/lowercase; the project deliberately treats case variants as the same identity. Customer and administrator email uniqueness is separate.

## customers

Customer identity and contact details.

| Column | PostgreSQL type | NULL allowed | Default | Keys and validation |
| --- | --- | --- | --- | --- |
| `customer_id` | `bigint` | No | Generated identity (ALWAYS) | PK |
| `first_name` | `varchar(100)` | No | — | Nonblank when supplied; trim input |
| `last_name` | `varchar(100)` | No | — | Nonblank when supplied; trim input |
| `email` | `varchar(254)` | No | — | Trimmed, lowercase; UNIQUE per identity table; nonblank; Nonblank when supplied; trim input |
| `phone` | `varchar(32)` | No | — | Nonblank when supplied; trim input |
| `created_at` | `timestamptz` | No | CURRENT_TIMESTAMP | Required value |
| `is_active` | `boolean` | No | true | Required value |

## customer_addresses

Reusable customer delivery addresses.

| Column | PostgreSQL type | NULL allowed | Default | Keys and validation |
| --- | --- | --- | --- | --- |
| `address_id` | `bigint` | No | Generated identity (ALWAYS) | PK |
| `customer_id` | `bigint` | No | — | FK → `customers.customer_id` |
| `recipient_name` | `varchar(200)` | No | — | Nonblank when supplied; trim input |
| `recipient_phone` | `varchar(32)` | No | — | Nonblank when supplied; trim input |
| `address_line_1` | `varchar(255)` | No | — | Nonblank when supplied; trim input |
| `address_line_2` | `varchar(255)` | Yes | — | Nonblank when supplied; trim input |
| `city` | `varchar(100)` | No | — | Nonblank when supplied; trim input |
| `state_region` | `varchar(100)` | No | — | Nonblank when supplied; trim input |
| `postal_code` | `varchar(20)` | Yes | — | Nonblank when supplied; trim input |
| `country_code` | `varchar(2)` | No | — | Two uppercase ASCII letters; semantic country validation in input routine |

## categories

Product grouping.

| Column | PostgreSQL type | NULL allowed | Default | Keys and validation |
| --- | --- | --- | --- | --- |
| `category_id` | `bigint` | No | Generated identity (ALWAYS) | PK |
| `name` | `varchar(160)` | No | — | UNIQUE; case-sensitive unless stated below; Nonblank when supplied; trim input; Case-insensitive unique index on lower(trimmed value) |
| `description` | `text` | Yes | — | Required value |

## brands

Product brand.

| Column | PostgreSQL type | NULL allowed | Default | Keys and validation |
| --- | --- | --- | --- | --- |
| `brand_id` | `bigint` | No | Generated identity (ALWAYS) | PK |
| `name` | `varchar(160)` | No | — | UNIQUE; case-sensitive unless stated below; Nonblank when supplied; trim input; Case-insensitive unique index on lower(trimmed value) |

## products

Shared catalogue description.

| Column | PostgreSQL type | NULL allowed | Default | Keys and validation |
| --- | --- | --- | --- | --- |
| `product_id` | `bigint` | No | Generated identity (ALWAYS) | PK |
| `category_id` | `bigint` | No | — | FK → `categories.category_id` |
| `brand_id` | `bigint` | No | — | FK → `brands.brand_id` |
| `name` | `varchar(160)` | No | — | Nonblank when supplied; trim input |
| `description` | `text` | No | — | Required value |
| `audience` | `varchar(10)` | No | — | women / men / unisex / kids |
| `is_active` | `boolean` | No | true | Required value |
| `created_at` | `timestamptz` | No | CURRENT_TIMESTAMP | Required value |

## sizes

Controlled size labels.

| Column | PostgreSQL type | NULL allowed | Default | Keys and validation |
| --- | --- | --- | --- | --- |
| `size_id` | `bigint` | No | Generated identity (ALWAYS) | PK |
| `label` | `varchar(40)` | No | — | UNIQUE; case-sensitive unless stated below; Nonblank when supplied; trim input; Case-insensitive unique index on lower(trimmed value) |
| `description` | `text` | Yes | — | Required value |

## colours

Controlled colour labels.

| Column | PostgreSQL type | NULL allowed | Default | Keys and validation |
| --- | --- | --- | --- | --- |
| `colour_id` | `bigint` | No | Generated identity (ALWAYS) | PK |
| `name` | `varchar(160)` | No | — | UNIQUE; case-sensitive unless stated below; Nonblank when supplied; trim input; Case-insensitive unique index on lower(trimmed value) |
| `hex_code` | `varchar(7)` | Yes | — | NULL or # followed by six hexadecimal digits |

## product_variants

Purchasable product/size/colour combination.

| Column | PostgreSQL type | NULL allowed | Default | Keys and validation |
| --- | --- | --- | --- | --- |
| `variant_id` | `bigint` | No | Generated identity (ALWAYS) | PK |
| `product_id` | `bigint` | No | — | FK → `products.product_id` |
| `size_id` | `bigint` | No | — | FK → `sizes.size_id` |
| `colour_id` | `bigint` | No | — | FK → `colours.colour_id` |
| `sku` | `varchar(64)` | No | — | UNIQUE; case-sensitive unless stated below; Nonblank when supplied; trim input |
| `unit_price` | `numeric(14,2)` | No | — | Finite, nonnegative; reject NaN; reject >2 fractional digits before writing |
| `is_active` | `boolean` | No | true | Required value |

## inventory

One stock balance per variant.

| Column | PostgreSQL type | NULL allowed | Default | Keys and validation |
| --- | --- | --- | --- | --- |
| `variant_id` | `bigint` | No | — | PK; FK → `product_variants.variant_id` |
| `available_quantity` | `integer` | No | 0 | ≥ 0 |
| `low_stock_threshold` | `integer` | No | 5 (initial policy) | ≥ 0 |
| `updated_at` | `timestamptz` | No | CURRENT_TIMESTAMP | Write routine refreshes on change |

## shopping_carts

Customer cart lifecycle.

| Column | PostgreSQL type | NULL allowed | Default | Keys and validation |
| --- | --- | --- | --- | --- |
| `cart_id` | `bigint` | No | Generated identity (ALWAYS) | PK |
| `customer_id` | `bigint` | No | — | FK → `customers.customer_id` |
| `status` | `varchar(20)` | No | 'active' | CHECK in: active / converted / abandoned |
| `created_at` | `timestamptz` | No | CURRENT_TIMESTAMP | Required value |
| `updated_at` | `timestamptz` | No | CURRENT_TIMESTAMP | Write routine refreshes on change |

## cart_items

Variant quantity in a cart.

| Column | PostgreSQL type | NULL allowed | Default | Keys and validation |
| --- | --- | --- | --- | --- |
| `cart_id` | `bigint` | No | — | PK component; FK → `shopping_carts.cart_id` |
| `variant_id` | `bigint` | No | — | PK component; FK → `product_variants.variant_id` |
| `quantity` | `integer` | No | — | > 0 |

## orders

Customer purchase and delivery snapshot.

| Column | PostgreSQL type | NULL allowed | Default | Keys and validation |
| --- | --- | --- | --- | --- |
| `order_id` | `bigint` | No | Generated identity (ALWAYS) | PK |
| `customer_id` | `bigint` | No | — | FK → `customers.customer_id` |
| `status` | `varchar(20)` | No | 'pending' | CHECK in: pending / paid / processing / dispatched / delivered / cancelled |
| `currency_code` | `varchar(3)` | No | 'NGN' | CHECK = 'NGN' |
| `total_amount` | `numeric(14,2)` | No | 0.00 (draft order) | Finite, nonnegative; reject NaN; reject >2 fractional digits before writing |
| `recipient_name` | `varchar(200)` | No | — | Nonblank when supplied; trim input |
| `recipient_phone` | `varchar(32)` | No | — | Nonblank when supplied; trim input |
| `address_line_1` | `varchar(255)` | No | — | Nonblank when supplied; trim input |
| `address_line_2` | `varchar(255)` | Yes | — | Nonblank when supplied; trim input |
| `city` | `varchar(100)` | No | — | Nonblank when supplied; trim input |
| `state_region` | `varchar(100)` | No | — | Nonblank when supplied; trim input |
| `postal_code` | `varchar(20)` | Yes | — | Nonblank when supplied; trim input |
| `country_code` | `varchar(2)` | No | — | Two uppercase ASCII letters; semantic country validation in input routine |
| `created_at` | `timestamptz` | No | CURRENT_TIMESTAMP | Required value |
| `paid_at` | `timestamptz` | Yes | — | Required value |

## order_items

Purchased variant and immutable sale details.

| Column | PostgreSQL type | NULL allowed | Default | Keys and validation |
| --- | --- | --- | --- | --- |
| `order_id` | `bigint` | No | — | PK component; FK → `orders.order_id` |
| `variant_id` | `bigint` | No | — | PK component; FK → `product_variants.variant_id` |
| `quantity` | `integer` | No | — | > 0 |
| `unit_price` | `numeric(14,2)` | No | — | Finite, nonnegative; reject NaN; reject >2 fractional digits before writing |
| `product_name_snapshot` | `varchar(160)` | No | — | Nonblank when supplied; trim input; Immutable after purchase finalisation |
| `sku_snapshot` | `varchar(64)` | No | — | Nonblank when supplied; trim input; Immutable after purchase finalisation |
| `size_label_snapshot` | `varchar(40)` | No | — | Nonblank when supplied; trim input; Immutable after purchase finalisation |
| `colour_name_snapshot` | `varchar(160)` | No | — | Nonblank when supplied; trim input; Immutable after purchase finalisation |

## payments

Payment attempt and outcome.

| Column | PostgreSQL type | NULL allowed | Default | Keys and validation |
| --- | --- | --- | --- | --- |
| `payment_id` | `bigint` | No | Generated identity (ALWAYS) | PK |
| `order_id` | `bigint` | No | — | FK → `orders.order_id` |
| `method` | `varchar(20)` | No | — | CHECK in: card / bank_transfer / wallet (simulated) |
| `provider_reference` | `varchar(120)` | Yes | — | UNIQUE; case-sensitive unless stated below; Nonblank when supplied; trim input |
| `amount` | `numeric(14,2)` | No | — | Finite, nonnegative; reject NaN; reject >2 fractional digits before writing |
| `currency_code` | `varchar(3)` | No | 'NGN' | CHECK = 'NGN' |
| `status` | `varchar(20)` | No | 'pending' | CHECK in: pending / succeeded / failed |
| `created_at` | `timestamptz` | No | CURRENT_TIMESTAMP | Required value |
| `completed_at` | `timestamptz` | Yes | — | Required value |

## deliveries

Shipment progress.

| Column | PostgreSQL type | NULL allowed | Default | Keys and validation |
| --- | --- | --- | --- | --- |
| `delivery_id` | `bigint` | No | Generated identity (ALWAYS) | PK |
| `order_id` | `bigint` | No | — | FK → `orders.order_id`; UNIQUE; case-sensitive unless stated below |
| `carrier` | `varchar(100)` | Yes | — | Nonblank when supplied; trim input |
| `tracking_reference` | `varchar(120)` | Yes | — | Nonblank when supplied; trim input |
| `status` | `varchar(20)` | No | 'pending' | CHECK in: pending / dispatched / delivered |
| `dispatched_at` | `timestamptz` | Yes | — | Required value |
| `delivered_at` | `timestamptz` | Yes | — | Required value |

## administrators

Staff identity.

| Column | PostgreSQL type | NULL allowed | Default | Keys and validation |
| --- | --- | --- | --- | --- |
| `administrator_id` | `bigint` | No | Generated identity (ALWAYS) | PK |
| `display_name` | `varchar(200)` | No | — | Nonblank when supplied; trim input |
| `email` | `varchar(254)` | No | — | Trimmed, lowercase; UNIQUE per identity table; nonblank; Nonblank when supplied; trim input |
| `is_active` | `boolean` | No | true | Required value |
| `created_at` | `timestamptz` | No | CURRENT_TIMESTAMP | Required value |
