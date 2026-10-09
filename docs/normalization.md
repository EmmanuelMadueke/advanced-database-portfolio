# Normalisation Analysis

Owner, author, and maintainer: **Emmanuel Madueke**.

This analysis evaluates the [relational schema](relational-schema.md) and [data dictionary](data-dictionary.md). It covers functional dependencies, candidate keys, and 1NF–3NF using fashion-store examples. It is design reasoning, not evidence of executed SQL.

## Definitions and assumptions

`X → Y` means that equal X values imply equal Y values in every valid instance of a relation. A candidate key is a minimal set of attributes determining the whole row; a primary key is the candidate chosen for identification. A prime attribute belongs to at least one candidate key.

1NF requires single values at each row/column intersection rather than repeating groups. 2NF additionally requires each non-prime attribute to depend on the whole of every candidate key, rather than a proper subset. For 3NF, each nontrivial dependency X → A must have X as a superkey or A as a prime attribute. These concepts follow the textbook discussions of [functional dependencies](https://opentextbc.ca/dbdesign01/chapter/chapter-11-functional-dependencies/) and [normalisation](https://opentextbc.ca/dbdesign01/chapter/chapter-12-normalization/).

Dependencies here come from the project's rules, not accidental uniqueness in sample data. A customer's phone, product name, delivery tracking reference, or postal code is not assumed unique. A city name does not determine a state/country, and a postal code does not determine a complete address under this model. Snapshot values describe a sale, not the current master record.

For readable analysis, optional SQL attributes are treated as optional facts; nullable uniqueness is not promoted to a candidate key for the entire relation. Case-insensitive lookup keys are interpreted under the specified canonical comparison. Fixed NGN columns are discussed explicitly below rather than silently omitted from the analysis.

## Illustrative decomposition

The following is a teaching example, not a previously implemented table:

```text
PurchaseSheet(
  order_id, customer_id, customer_email, order_created_at,
  items = [{variant_id, quantity, purchase_price}],
  payments = [{payment_id, amount, status}]
)
```

The item/payment lists violate 1NF. Expanding both independently into a single table would multiply rows: two items and three payment attempts would produce six rows for one order. Instead, create separate order, item, and payment relations.

Consider a flattened catalogue relation:

```text
VariantCatalogue(product_id, size_id, colour_id,
                 product_name, category_id, category_name,
                 brand_id, brand_name, size_label, colour_name,
                 sku, current_price)
```

The business key is `(product_id, size_id, colour_id)`; SKU is another candidate key. Product details depend on product_id alone, size_label on size_id, and colour_name on colour_id. A surrogate variant_id would not remove these dependencies.

Separate Product, Size, Colour, and Product Variant to eliminate those partial dependencies. Product still has `product_id → category_id → category_name` and `product_id → brand_id → brand_name` if lookup names are retained in Product. Separate Category and Brand to remove those transitive dependencies.

For these illustrative splits, the shared determinant is a key of the extracted parent relation. Joining the child to its uniquely identified parent reconstructs the original current-catalogue facts without introducing spurious rows. The parent/child FKs preserve the references. This argument covers these splits; it is not a claim that all 16 tables came from a single universal-table decomposition. Independent items and payment attempts remain separate to avoid fan-out errors.

## 1NF in the proposed schema

Every proposed column contains a single value at the chosen level of meaning. Products do not store comma-separated size/colour combinations; variants represent combinations as separate rows. A cart stores one row per selected variant in cart_items, and an order stores one row per purchased variant in order_items. Saved addresses and payment attempts are separate rows.

An address_line_1 or description may contain several words and still be one text value; atomicity does not require splitting every sentence. Phone numbers, postal codes, and references are text values rather than quantities. PKs identify rows, and repeated item columns such as item_1/item_2 do not occur.

## 2NF and composite keys

In `cart_items`, `(cart_id, variant_id) → quantity`. A cart can contain several variants and a variant can occur in many carts, so neither component determines quantity. Customer ownership belongs in shopping_carts; product names and current prices belong in catalogue relations.

In `order_items`, `(order_id, variant_id) → quantity, unit_price, product_name_snapshot, sku_snapshot, size_label_snapshot, colour_name_snapshot`. A variant can be sold in different orders at different prices or under different historical labels. Neither variant_id alone nor order_id alone determines the complete purchased line. Snapshot dependencies are qualified further below.

Product Variant has a surrogate primary key, but also the composite candidate key `(product_id, size_id, colour_id)`. Its variant-specific price, SKU, identity, and active flag depend on that full combination. Product name, brand/category data, and size/colour labels are excluded because they would depend on a subset.

Other tables have single-attribute candidate keys under the stated rules, so there is no proper nonempty subset to create a conventional partial-key dependency. The constant currency exception is addressed separately.

## Relation-by-relation dependencies and assessment

In the table, “remaining attributes” means every other column listed in the data dictionary. Conclusions exclude the explicit fixed-currency exception and assume no undeclared dependencies.

| Relation | Candidate keys | Principal dependencies | Assessment |
| --- | --- | --- | --- |
| customers | customer_id; normalised email | Each key → remaining attributes | 3NF; names/phone do not determine email or identity |
| customer_addresses | address_id | address_id → customer_id and address fields | 3NF; one customer may have several addresses |
| categories | category_id; name under canonical comparison | Each key → remaining attributes | 3NF; optional description is a category fact |
| brands | brand_id; name under canonical comparison | Each key → remaining attributes | 3NF |
| products | product_id | product_id → category_id, brand_id, name, description, audience, is_active, created_at | 3NF; category/brand names are in parent tables |
| sizes | size_id; label under canonical comparison | Each key → remaining attributes | 3NF |
| colours | colour_id; name under canonical comparison | Each key → remaining attributes | 3NF; no uniqueness assumed for hex_code |
| product_variants | variant_id; sku; (product_id, size_id, colour_id) | Each key → remaining attributes | 3NF under variant-specific pricing; all candidate keys considered |
| inventory | variant_id | variant_id → available_quantity, low_stock_threshold, updated_at | 3NF; threshold is per variant, not globally fixed |
| shopping_carts | cart_id | cart_id → customer_id, status, created_at, updated_at | 3NF; customer_id is not a key across historical carts |
| cart_items | (cart_id, variant_id) | Full key → quantity | 3NF; no partial dependency |
| orders | order_id | order_id → customer_id, status, destination snapshot, timestamps, total_amount | Core 3NF; stored aggregate and fixed currency qualified below |
| order_items | (order_id, variant_id) | Full key → quantity and purchase-time facts | 3NF under event-specific snapshot assumptions; caveat below |
| payments | payment_id | payment_id → order_id, method, reference, amount, status, timestamps | Core 3NF; nullable reference, conditional success, and currency qualified below |
| deliveries | delivery_id; order_id | Each key → remaining attributes | 3NF; single-shipment scope makes order_id a candidate key |
| administrators | administrator_id; normalised email | Each key → remaining attributes | 3NF; display_name is not unique |

A partial unique index makes customer_id unique only among active carts, and order_id unique only among successful payments. Neither is a candidate key of the complete relation. provider_reference identifies a payment when supplied, but NULL is allowed for other attempts; it is not a total candidate key.

Status domains and allowed transitions constrain valid states; they do not imply that status determines a unique timestamp, quantity, or other business value.

## Historical snapshots and controlled redundancy

### Purchase-time price and labels

Current variant price is a catalogue fact. Purchase-time price is an order-line fact. A shirt variant may sell for NGN 12,000 in one order and NGN 13,500 later. Thus `variant_id → purchase-time unit_price` is not a valid dependency across order_items.

Product/SKU/size/colour snapshots intentionally retain descriptions from the purchase event. Under the current rules, these master values can change between purchases, and snapshots are not required to match current values after finalisation. Consequently, variant_id alone does not determine their historical values. Repetition across orders preserves history and is not automatically a normal-form violation.

No invariant currently states that every SKU has one immutable historical label or that all variants of a product purchased in one order must share one label snapshot. If implementation introduces those rules, additional dependencies may arise. For example, a permanently immutable SKU could make variant_id determine sku_snapshot, creating a partial dependency in the composite-key order_items relation. That would need explicit acknowledgement as controlled denormalisation or a versioned catalogue redesign. This analysis must be revisited if those invariants change.

### Delivery destination

An order's destination is the address selected for that purchase. It is not determined by customer_id because a customer can place orders to different addresses. Saved customer addresses may change or be removed. Keeping the snapshot in orders prevents those changes from rewriting history; repeated address text is not by itself a transitive dependency.

### Stored order total

The total is calculated as `SUM(quantity × unit_price)` over the order's items, with an empty draft total of zero. Storing it creates cross-table aggregate redundancy. Within orders, it is still determined by order_id; the aggregate duplication alone is not an intra-relation 3NF violation.

The total is retained for payment comparison and reporting. No performance benefit is claimed without measurement. Planned order-write routines and deferred validators must reconcile it after relevant writes. Their implementation and tests are pending. Per-line totals are calculated, not additionally stored.

### Fixed NGN currency

orders.currency_code and payments.currency_code are constrained to NGN. Under a strict FD treatment, the empty determinant determines this constant (`∅ → currency_code`). Neither currency column is prime and the empty determinant is not a superkey, so these physical relations are not unqualified formal 3NF examples when this constant dependency is included (and it also affects strict 2NF treatment).

The fields are retained deliberately to make monetary records explicit and comparable at payment validation. Removing them and declaring currency once in configuration would avoid this redundancy. A future multi-currency design would require revised business rules; it is not presumed here. The project therefore claims a 3NF-oriented core with this documented physical exception rather than claiming every column is strictly normalised.

## Anomalies avoided and remaining obligations

| Risk in a combined table | Design response |
| --- | --- |
| Category/brand name repeated across products causes inconsistent updates | Store each lookup once and reference its key |
| Product cannot be added until an order exists | Catalogue and order relations are independent |
| Deleting the final order line removes product/customer facts | Retain customer/catalogue parents and restrict historical deletion |
| Customer details repeated across all carts | Cart references customers rather than duplicating contact data |
| Multiple payment attempts duplicate each purchased quantity in reports | Keep attempts separate; sales queries must avoid multiplying item rows |
| Catalogue/address updates alter historical orders | Preserve event snapshots and enforce their immutability |
| Stored total disagrees with line totals | Planned aggregate validation; not guaranteed by normalisation alone |

Normalisation does not prevent overselling, invalid state transitions, or incorrect payment totals. Those require the keys, constraints, transaction controls, and enforcement routines specified in the relational design. Inventory's one-to-one separation is an operational boundary for stock updates, not a decomposition required by 3NF. No higher-normal-form certification is claimed.

## Completion and next step

The proposed relations have been analysed against declared dependencies, including alternate/composite keys and documented exceptions. This completes the normalisation documentation task. Next: verify the development environment, implement the PostgreSQL schema, seed realistic data, and produce actual integrity evidence.

## References

Adrienne Watt, *Database Design – 2nd Edition*, Chapters [11: Functional Dependencies](https://opentextbc.ca/dbdesign01/chapter/chapter-11-functional-dependencies/) and [12: Normalization](https://opentextbc.ca/dbdesign01/chapter/chapter-12-normalization/), BCcampus Open Education. Definitions are paraphrased; fashion-store examples and conclusions apply this project's stated rules.
