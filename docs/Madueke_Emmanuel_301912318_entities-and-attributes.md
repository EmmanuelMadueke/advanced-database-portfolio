# Entities and Attributes

Owner, author, and maintainer: **Emmanuel Madueke**.

This is a proposed logical inventory, preceding the ERD, physical types, and normalisation analysis. `PK` means primary key; `FK` means foreign key. Unless stated otherwise, each FK points to exactly one parent. Final nullability, deletion policies, and SQL constraints will be specified in the schema/data dictionary.

| Entity | Purpose | Proposed attributes |
| --- | --- | --- |
| Customer | Customer identity and contact details | customer_id (PK), first_name, last_name, email (unique), phone, created_at, is_active |
| Customer Address | Reusable customer delivery addresses | address_id (PK), customer_id (FK), recipient_name, recipient_phone, address_line_1, address_line_2 (optional), city, state_region, postal_code (optional), country_code |
| Category | Product grouping | category_id (PK), name (unique), description (optional) |
| Brand | Product brand | brand_id (PK), name (unique) |
| Product | Shared catalogue description | product_id (PK), category_id (FK), brand_id (FK), name, description, audience (women/men/unisex/kids), is_active, created_at |
| Size | Controlled size labels | size_id (PK), label (unique), description (optional) |
| Colour | Controlled colour labels | colour_id (PK), name (unique), hex_code (optional) |
| Product Variant | Purchasable product/size/colour combination | variant_id (PK), product_id (FK), size_id (FK), colour_id (FK), sku (unique), unit_price, is_active |
| Inventory | One stock balance per variant | variant_id (PK and FK), available_quantity, low_stock_threshold, updated_at |
| Shopping Cart | Customer cart lifecycle | cart_id (PK), customer_id (FK), status (active/converted/abandoned), created_at, updated_at |
| Cart Item | Variant quantity in a cart | cart_id (PK part, FK), variant_id (PK part, FK), quantity |
| Order | Customer purchase and delivery snapshot | order_id (PK), customer_id (FK), status, currency_code, total_amount, recipient_name, recipient_phone, address_line_1, address_line_2 (optional), city, state_region, postal_code (optional), country_code, created_at, paid_at (optional) |
| Order Item | Purchased variant and immutable sale details | order_id (PK part, FK), variant_id (PK part, FK), quantity, unit_price, product_name_snapshot, sku_snapshot, size_label_snapshot, colour_name_snapshot |
| Payment | Payment attempt and outcome | payment_id (PK), order_id (FK), method, provider_reference (optional, unique when present), amount, currency_code, status, created_at, completed_at (optional) |
| Delivery | Shipment progress | delivery_id (PK), order_id (FK, unique), carrier (optional), tracking_reference (optional), status, dispatched_at (optional), delivered_at (optional) |
| Administrator | Staff identity | administrator_id (PK), display_name, email (unique), is_active, created_at |

## Relationship summary

- Customer → addresses, carts, orders: one to zero-or-many; at most one cart is active.
- Category/Brand → products: one to zero-or-many.
- Product → variants: one to zero-or-many; a sellable product requires an active variant.
- Size/Colour → variants: one to zero-or-many.
- Variant ↔ Inventory: one to exactly one.
- Cart → cart items: one to zero-or-many; Variant → cart items: one to zero-or-many.
- Order → order items: one to one-or-many for completed orders; Variant → order items: one to zero-or-many.
- Order → payments: one to zero-or-many attempts, with at most one success.
- Order → delivery: one to zero-or-one.
- Administrator has no required relationship in this initial model. Staff attribution columns or audit entities need a defined use case before being added.

## Modelling notes

Customer Address is added to distinguish reusable addresses from the mandatory order snapshot. Inventory uses the variant key to prevent multiple balances for a single variant. Cart Item and Order Item are associative entities with composite keys. A unique product/size/colour constraint complements each variant's surrogate key.

Current price belongs to Product Variant because variants may have different prices. Line totals can be computed from quantity and purchase-time price. Order total is a deliberately stored aggregate whose consistency must be enforced. Snapshot fields intentionally preserve historical facts; their justification belongs in the normalisation analysis.

NGN is the initial currency. Names for physical tables should avoid reserved words such as ORDER. No plaintext passwords or payment credentials are proposed. These choices require verification during schema implementation; no tables have been created yet.
