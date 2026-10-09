# Requirements Analysis

Owner, author, and maintainer: **Emmanuel Madueke**.

## Scope and users

The online fashion retail store sells clothing, footwear, and accessories. This portfolio models its database rather than a complete storefront or live payment integration. Requirements derive from [the case study](case-study.md); modelling decisions below are proposed scope choices for the academic implementation.

Customers browse products, manage carts, place orders, and retrieve their own purchase and delivery history. Administrators maintain the catalogue, stock, and fulfilment records. Management users retrieve sales and inventory reports. Database access permissions will be addressed during implementation; declaring these users does not imply access control is already implemented.

## Functional requirements

| ID | Requirement | Main data |
| --- | --- | --- |
| FR01 | Register customers and retain contact details and reusable delivery addresses. | Customer, Customer Address |
| FR02 | Maintain products, categories, brands, sizes, and colours. Filter by category, gender/audience, size, colour, brand, and price. | Product and catalogue lookups |
| FR03 | Represent each size/colour combination as a uniquely identifiable purchasable variant. | Product Variant |
| FR04 | Track available quantity and a low-stock threshold per variant; report low and zero stock. | Inventory |
| FR05 | Add, update, remove, and retrieve variant quantities in a customer's active cart. | Shopping Cart, Cart Item |
| FR06 | Validate availability and prices at checkout, calculate totals, record delivery details, and create an order with items. | Order, Order Item, Inventory |
| FR07 | Record simulated payment attempts, amounts, statuses, and unique provider references without storing card credentials. | Payment |
| FR08 | Complete a successful purchase atomically, deducting stock once; reject insufficient stock and roll back partial changes. | Order, Order Item, Payment, Inventory |
| FR09 | Retrieve customer purchase history and current order/payment/delivery statuses. | Customer, Order, Payment, Delivery |
| FR10 | Process orders and maintain dispatch, delivery, and tracking details. | Order, Delivery |
| FR11 | Report sales by product, variant, category, and time period; rank best sellers and summarise customer purchases. | Order, Order Item, catalogue |
| FR12 | Demonstrate the same business scenario through query optimisation, concurrency, NoSQL, and distributed/cloud activities. | All portfolio activities |

## Integrity and operational requirements

- Enforce references, uniqueness, required fields, positive item quantities, and nonnegative money and stock values.
- Preserve purchased prices, product descriptions needed for order history, and delivery address snapshots after master data changes.
- Prevent concurrent purchases from overselling; document transaction boundaries and reproduce tests in two sessions.
- Use exact decimal monetary values and timezone-aware timestamps where supported. The initial dataset uses NGN only; currency conversion is outside scope.
- Provide deterministic sample data and enough additional data for credible performance comparisons. Retain scripts, actual outputs, and environment details.
- Do not commit secrets or store full card numbers, CVVs, or plaintext passwords. Customer authentication implementation is outside the initial database exercise.

## Proposed scope decisions

One product has one category, one brand, and a controlled audience value. Each variant has one size and one colour; lookup values such as “One Size” or “Not Applicable” cover products without conventional sizing. Each customer has at most one active cart. Each order has one delivery destination and at most one shipment. Multiple warehouses, split shipments, discounts, tax, shipping charges, refunds, and returns are excluded initially. The order total is the sum of quantity multiplied by the purchase-time unit price.

Payment is simulated. A pending order does not reserve stock. Successful purchase finalisation rechecks stock and records the successful payment and stock deduction in one local transaction. A failed attempt can be retained separately against a pending order; a failed finalisation transaction is rolled back. Production payment gateways need additional reconciliation beyond this model.

## Acceptance evidence to produce

| Area | Expected demonstration |
| --- | --- |
| Catalogue/cart | Different variants can be selected; duplicate cart lines for the same variant are rejected or combined. |
| Integrity | Invalid references, duplicate variants, invalid quantities, and negative stock are rejected. |
| Checkout | Successful finalisation persists matching order/items/payment and stock deduction; a failure leaves no partial finalisation. |
| Concurrency | Two buyers competing for one remaining unit cannot both succeed after controls are applied. |
| History | Changing a product price or customer address does not rewrite an existing order's recorded price or destination. |
| Reporting | Sales queries exclude unpaid/cancelled orders and reconcile with paid order totals. |

These are planned checks, not claims of completed tests.
