# Business Rules and Relationships

Owner, author, and maintainer: **Emmanuel Madueke**.

These proposed rules refine [the requirements](requirements.md) for the initial implementation. They are not claims about an existing retailer.

## Catalogue and inventory

| ID | Rule |
| --- | --- |
| BR01 | A product belongs to exactly one category and one brand. A category or brand may have zero or many products. |
| BR02 | A product has zero or many variants while being prepared, and needs at least one active variant to be sold. |
| BR03 | Each variant belongs to exactly one product, one size, and one colour. The product/size/colour combination and SKU are unique. |
| BR04 | Each variant has exactly one inventory record. Available quantity and low-stock threshold are nonnegative integers. Zero means out of stock; positive quantity at or below the threshold means low stock. |
| BR05 | The variant holds its current selling price; the product has no separate competing price. Prices are nonnegative decimal amounts in NGN. |
| BR06 | Inactive products or variants cannot be purchased. Historical references are retained; referenced catalogue records are deactivated rather than deleted. |

## Customers and carts

| ID | Rule |
| --- | --- |
| BR07 | Customer email is unique under the chosen case-normalisation policy. A customer may have zero or many saved addresses, carts, and orders. Each belongs to exactly one customer. |
| BR08 | A customer has at most one active cart. A cart has zero or many items; each item references one variant with a positive integer quantity. A variant occurs at most once per cart. |
| BR09 | Cart contents do not reserve stock or guarantee price. Availability and current prices are checked when creating/finalising a purchase. |

## Orders, payments, and delivery

| ID | Rule |
| --- | --- |
| BR10 | A completed order contains at least one item. Each item belongs to one order and references one variant; the same variant appears at most once per order. |
| BR11 | Order items retain purchase-time unit price and product/SKU/size/colour labels. Quantity is positive. The order total equals the sum of quantity × unit price; it is calculated and verified transactionally. |
| BR12 | Every order stores a delivery destination snapshot independently of a customer's saved address. Later address changes do not change that snapshot. |
| BR13 | An order has zero or many payment attempts. Each attempt belongs to one order; provider references are unique when supplied. At most one successful payment is allowed per order, for its full total and currency. Partial payments are outside scope. |
| BR14 | Order states are pending, paid, processing, dispatched, delivered, or cancelled. Allowed progression is pending → paid → processing → dispatched → delivered, or pending → cancelled. Cancelling a paid order requires a refund/restock model and is excluded initially. |
| BR15 | Payment states are pending, succeeded, or failed. An attempt transitions from pending to succeeded or failed; terminal outcomes cannot be rewritten casually. |
| BR16 | Successful finalisation locks/checks the order and required inventory, records payment success, deducts stock once, and changes pending to paid atomically. A repeated finalisation must not deduct stock again. Failed attempts and cancelled pending orders do not consume stock. |
| BR17 | An order has zero or one delivery record and one shipment. Delivery states are pending, dispatched, or delivered. Dispatch requires a paid/processing order; delivery requires dispatch. Delivery and order states are updated together. |
| BR18 | Dispatch timestamps cannot precede order creation; delivery timestamps cannot precede dispatch. Tracking references may be absent before dispatch. |
| BR19 | Sales/revenue reports include paid, processing, dispatched, and delivered orders only. Pending/cancelled orders and failed payments do not count. Category/brand reporting uses current catalogue classification; historical reclassification reporting is outside scope. |

## Enforcement plan

Primary/foreign keys, unique constraints, NOT NULL, and CHECK constraints handle row-level rules. Conditional uniqueness handles active carts and successful payments where supported. Cross-row rules such as nonempty completed orders, matching payment totals, order totals, mandatory inventory, and valid status transitions require transaction logic, triggers, or controlled write procedures. Foreign keys alone cannot enforce them. The schema stage will document the selected mechanism for each rule.

Inventory locking must follow a consistent variant order for multi-item checkout to reduce deadlock risk. Any retry strategy will be documented and tested during the concurrency activity.

Administrator represents a staff identity for catalogue and fulfilment operations; administrators are not owners of customer orders. Detailed role permissions and staff-action auditing may be added if needed, but are not presumed implemented.
