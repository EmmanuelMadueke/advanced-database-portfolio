# Relational Schema Design

Owner, author, and maintainer: **Emmanuel Madueke**.

This document translates the [ERD](conceptual-erd.md) and [business rules](business-rules.md) into a PostgreSQL design. Its table and enforcement definitions are now implemented in the [Portfolio 1 SQL scripts](../portfolio-1-database-design/README.md) and verified on PostgreSQL 18.1. See [setup](setup.md) for evidence and remaining limitations.

## Relations and keys

All columns, types, nullability, and defaults are in the [data dictionary](data-dictionary.md). Physical names use lowercase snake_case and avoid reserved names such as ORDER.

| Relation | Primary key | Foreign keys | Additional uniqueness |
| --- | --- | --- | --- |
| customers | customer_id | — | email |
| customer_addresses | address_id | customer_id → customers | — |
| categories | category_id | — | case-insensitive category name |
| brands | brand_id | — | case-insensitive brand name |
| products | product_id | category_id → categories; brand_id → brands | — |
| sizes | size_id | — | case-insensitive size label |
| colours | colour_id | — | case-insensitive colour name |
| product_variants | variant_id | product_id → products; size_id → sizes; colour_id → colours | sku; (product_id, size_id, colour_id) |
| inventory | variant_id | variant_id → product_variants | PK provides one balance per variant |
| shopping_carts | cart_id | customer_id → customers | customer_id where status = active |
| cart_items | (cart_id, variant_id) | cart_id → shopping_carts; variant_id → product_variants | Composite PK prevents repeated variant in a cart |
| orders | order_id | customer_id → customers | — |
| order_items | (order_id, variant_id) | order_id → orders; variant_id → product_variants | Composite PK prevents repeated variant in an order |
| payments | payment_id | order_id → orders | provider_reference when non-NULL; order_id where status = succeeded |
| deliveries | delivery_id | order_id → orders | order_id |
| administrators | administrator_id | — | email |

Surrogate keys separate identity from editable names, email, and SKU. Cart Item and Order Item use composite keys because a variant appears once in each parent. There is no invented cart–order or staff–order FK. Purchase snapshots are copied into the order/item records rather than linked to mutable customer addresses or catalogue labels.

## Types and value policies

- `bigint` identity keys allow a substantial range while keeping all references consistent.
- `numeric(14,2)` stores exact two-decimal money, up to 999,999,999,999.99 NGN. Input routines reject excess fractional precision instead of silently relying on type rounding. Checks reject negative values and numeric NaN. Order aggregates must fit the same limit; overflow aborts the write.
- `integer` quantities must be positive for items and nonnegative for inventory/thresholds. No NULL quantity is allowed.
- `timestamptz` records instants; display/export sessions use Africa/Lagos or explicitly state their timezone. `CURRENT_TIMESTAMP` is a transaction timestamp, so tests must not assume it changes within a transaction. Updated timestamps need write logic, not just a default.
- Required text is trimmed and nonblank. Optional text is NULL when absent. Foreign keys and controlled vocabulary checks prevent arbitrary status/category references.
- Currency is fixed to NGN in orders/payments. Country codes are two uppercase letters with semantic validation by the address input routine. Address postal codes remain text to preserve formatting.
- Status fields use varchar plus CHECK constraints; a CHECK lists allowed values, while transition logic governs changes between values.

Exact numeric and timestamp behaviour follow [PostgreSQL numeric types](https://www.postgresql.org/docs/18/datatype-numeric.html) and [date/time types](https://www.postgresql.org/docs/18/datatype-datetime.html).

## Foreign-key update and deletion policy

All FKs use `ON UPDATE RESTRICT`: generated IDs are not edited. All FKs use `ON DELETE RESTRICT` except `cart_items.cart_id`, which uses `ON DELETE CASCADE` because a cart line has no independent history. Deleting a cart may therefore remove its lines; changing or removing items is allowed only while the cart is active through the write routines.

Customers, products, variants, and administrators are deactivated when appropriate. Orders, payments, deliveries, and purchased item history are retained. Saved customer addresses can be removed independently because orders contain snapshots. Inventory cannot be deleted independently of a live variant; the deferred integrity check below prevents missing balances. This conservative policy leaves housekeeping and retention design outside the initial scope.

## Row and conditional uniqueness constraints

In addition to the dictionary's column checks:

- `shopping_carts.updated_at >= created_at`; `inventory.updated_at` is refreshed whenever stock changes.
- `orders.paid_at` is NULL for pending/cancelled orders and required for paid/processing/dispatched/delivered orders; when supplied it is not before created_at.
- Pending payments have NULL completed_at; succeeded/failed payments require completed_at >= created_at. Succeeded payments require a nonblank provider_reference. Failed or pending attempts may lack a provider reference.
- Pending deliveries have NULL dispatched_at and delivered_at; dispatched deliveries have dispatched_at and NULL delivered_at; delivered deliveries have both, with delivered_at >= dispatched_at.
- Unique partial indexes enforce one active cart per customer and one successful payment per order. These are correctness indexes present in the optimisation baseline, not optional performance indexes.
- Ordinary UNIQUE(provider_reference) permits multiple NULL values. In this simulated single-provider scope, supplied references are globally unique and case-sensitive; SKU is also case-sensitive. Catalogue lookup names use unique expression indexes on lower(btrim(name/label)). Stored input remains trimmed.

PostgreSQL permits uniqueness restricted to selected rows through [partial indexes](https://www.postgresql.org/docs/18/indexes-partial.html). Primary keys, FKs, NOT NULL, UNIQUE, and CHECK semantics are described in [the constraints documentation](https://www.postgresql.org/docs/18/ddl-constraints.html).

## Enforcement of cross-table and lifecycle rules

CHECK constraints cannot guarantee other-row facts. The planned implementation combines restricted write routines, state/immutability triggers, and deferred constraint triggers. These controls are implemented in the SQL scripts; 35 single-session integrity/workflow assertions passed. Concurrent-session verification remains pending. The application/test role will not receive direct table DML for protected workflows. Owner-level maintenance can bypass routine permissions and is outside the normal operational path.

| Rules | Planned enforcement | Verification to produce |
| --- | --- | --- |
| BR01, BR03, BR07–08, BR10, BR13, BR17 | PK/FK/NOT NULL, composite/ordinary uniqueness, and partial unique indexes | Invalid references and duplicate variant/cart/payment/delivery attempts fail |
| BR02, BR06 | Active catalogue filtering and checkout validation; active product means enabled, not guaranteed to have stock/variants | Draft products cannot be purchased without an active eligible variant |
| BR04 | Create variant and stock together; deferred trigger on variant creation and inventory delete/rekey checks that every remaining variant has inventory at commit | Missing inventory causes commit failure; duplicate/negative balances fail |
| BR05, BR08, BR11 | Numeric/integer checks and precision validation; exact totals calculated by order write routines | Invalid prices/quantities fail; totals reconcile |
| BR09–12 | Build pending order/items and snapshots transactionally; immutable after finalisation; deferred total check runs for order insert/update and item insert/update/delete | Source edits preserve history; changed line totals cannot leave stale order totals |
| BR10–11 | Deferred order validator allows empty draft pending/cancelled orders only with total 0; paid and later states require ≥1 item and exact summed total | Empty finalisation or wrong aggregate fails at commit |
| BR13–16 | Lock parent order before payment/order-item mutations; terminal payment outcome trigger; deferred validator checks successful payment matches full total/currency and paid state | Wrong amount/currency or duplicate success fails; repeated finalisation changes no stock |
| BR14–15 | BEFORE UPDATE transition triggers permit only documented transitions; pending order/items may be edited, paid/cancelled facts are frozen | Invalid transitions and history edits fail |
| BR16 | Finalisation routine locks order then inventory rows in ascending variant_id; checks active catalogue and sufficient stock; records success, deducts stock, and sets paid together | Commit/rollback and two-session last-unit purchase evidence |
| BR17–18 | Dispatch/delivery routines update both records; deferred validation watches order/delivery mutations and checks statuses and dispatch >= order creation/paid time | Inconsistent shipment/order states or dates fail |
| BR19 | Sales views/queries filter paid/processing/dispatched/delivered orders and use item snapshots for money | Sales totals reconcile with eligible order totals |

The mandatory inventory check should be triggered by creation/deletion events rather than routine stock quantity changes; this avoids unnecessary contention on variant records. Each cross-table validator must observe the final transaction state, not an intermediate step. Parent-order locks serialise edits/finalisation on the same order; related triggers must acquire those locks before validating. Paid order-item insertion/deletion and changes to destination, totals, identity, or purchase snapshots are rejected. Orders/payments/deliveries cannot be hard-deleted by the normal write role.

Order/payment validation checks both directions: a successful payment requires an order in a paid-or-later state, and such an order requires exactly one matching success. Pending/cancelled orders have no success. Shipment validation permits no delivery or a pending delivery before dispatch; dispatched/delivered order states require the corresponding delivery state. Once finalised, the order's paid_at and the successful payment's completed_at are immutable. Dispatch cannot precede payment completion.

The order builder records current prices and labels. If catalogue prices change while an order remains pending, finalisation refreshes its purchase-time price/label snapshots and recomputes the total before recording simulated success. This aligns checkout with the current-price policy without changing existing paid orders. Required locks or snapshot rules for concurrent catalogue edits must be implemented and verified alongside the finalisation routine.

Failure records are separate committed payment attempts against a pending order; a rollback demonstration must not claim that failed-transaction inserts survive rollback. Pending orders do not reserve stock. A complete payment-gateway reconciliation model, refunds, and distributed transactions remain outside scope.

## Implementation order and current status

Create independent lookup/identity tables first; then customer addresses, products, variants, inventory, carts/items, orders/items, payments, and deliveries. Add any functions, triggers, and permissions after their referenced tables exist. Seed reference values before dependent records.

The schema specification, data dictionary, normalisation analysis, executable SQL, and initial integrity tests are complete. Next is realistic seed data, followed by additional activity-specific transaction and concurrency tests. Optimisation indexes beyond correctness requirements will be chosen from measured queries later.
