# Checkout transaction boundary

Owner, author, and maintainer: **Emmanuel Madueke**.

## Scope and assumptions

The operation is a simulated successful purchase from the same online fashion store used throughout the portfolio. A trusted caller supplies a customer, that customer's address, variant IDs, positive quantities, and a synthetic payment reference. No external payment gateway is called. Customer/address/catalogue/inventory records already exist.

For the first demonstration, order creation and finalisation will share one explicit transaction at READ COMMITTED. The caller owns BEGIN, COMMIT, and error handling; the two database functions do not commit independently. The BEGIN/COMMIT in the installation script installs the functions and is not the boundary of a subsequent purchase.

PostgreSQL transactions group database changes atomically. Explicit transaction control is needed to group separate calls that would otherwise each commit under autocommit. A failed purchase should trigger a full ROLLBACK of this boundary. [PostgreSQL transaction tutorial](https://www.postgresql.org/docs/18/tutorial-transactions.html).

## Included changes and sequence

| Step | Existing implementation | Effect within the transaction |
| --- | --- | --- |
| 1. Begin | Caller starts READ COMMITTED transaction | Establish one purchase boundary |
| 2. Create pending order | retail.create_order | Validate active customer and owned address; copy delivery address into orders; create order_items and calculate total |
| 3. Lock and recheck | retail.finalise_order | Lock the order, protect catalogue facts, lock relevant inventory rows in variant-ID order, then recheck availability and active flags |
| 4. Finalise purchase facts | retail.finalise_order | Refresh line prices/descriptions from the protected catalogue, deduct each quantity, recalculate order total |
| 5. Record simulated success | retail.finalise_order | Insert payment, mark it succeeded, and mark order paid with matching timestamps |
| 6. Validate final state | Deferred consistency triggers | Require matching line total, successful payment, currency, and paid time |
| 7. Commit | Caller | Persist the purchase together; only report success after COMMIT succeeds |

Source: [create_order and finalise_order](../portfolio-1-database-design/sql/03_operations.sql). The initial availability check in create_order is advisory: it does not reserve inventory. The final check under inventory locks determines whether the purchase can proceed. Prices are refreshed during finalisation, so a pending order is not a guaranteed price quote. Customer confirmation of changed prices would require application behaviour beyond this simulation.

The intended caller sequence below is pseudocode, not an executable evidence script:

```text
BEGIN ISOLATION LEVEL READ COMMITTED
    order_id = create_order(customer, owned_address, variants, quantities)
    payment_id = finalise_order(order_id, synthetic_reference, 'card')
    SET CONSTRAINTS ALL IMMEDIATE
COMMIT
on database error, including failed validation:
    ROLLBACK
```

Keep constraint triggers deferred while the functions construct intermediate states. SET CONSTRAINTS ALL IMMEDIATE is placed after both functions to force outstanding validation before the commit attempt. COMMIT remains the success boundary. Constraint triggers follow deferred/immediate timing, while ordinary CHECK and NOT NULL constraints are checked immediately. [PostgreSQL SET CONSTRAINTS](https://www.postgresql.org/docs/18/sql-set-constraints.html).

## Consistency contract

For a committed successful purchase:

- The order contains at least one line; each quantity is positive and each variant exists.
- The order total equals the sum of quantity × purchase-time unit price.
- Exactly one succeeded payment matches the order's total, currency, and paid timestamp.
- Each purchased variant's available stock decreases by its ordered quantity and remains nonnegative.
- The order is paid; purchase facts are protected against later changes by the lifecycle guards.

The [schema](../portfolio-1-database-design/sql/01_schema.sql) supplies keys, uniqueness, and row checks. [Consistency triggers](../portfolio-1-database-design/sql/02_integrity.sql) enforce order/payment relationships and lifecycle rules. Stock deduction is performed by the finalisation routine; there is no stock movement ledger or trigger proving that every privileged manual stock change corresponds to a purchase. The [demo writer role](../portfolio-1-database-design/sql/04_permissions.sql) permits controlled routines and SELECT, without direct table writes. It is a trusted testing role, not customer authentication or customer-level authorisation.

## Failure and retry outcomes

| Situation | Expected database outcome |
| --- | --- |
| Invalid address, inactive variant, insufficient stock, duplicate payment reference, or later constraint failure in the combined transaction | Full rollback removes this purchase's new order/items/payment and reverses any earlier deductions in the transaction |
| One line was deducted before a later line fails | Full rollback reverses that earlier deduction too; no partial purchase persists |
| A previously committed pending order is finalised in a new transaction that fails | The old pending order/items remain; changes made by the failed finalisation are rolled back |
| A committed paid order is finalised again | Routine returns the existing successful payment ID, without a second deduction/payment |
| record_failed_payment is intentionally committed for a pending order | Failed attempt remains for audit; stock is unchanged and order remains pending |

The paid-order replay branch returns the existing payment before checking the newly supplied reference/method. Its idempotency is scoped to the known order ID; it does not deduplicate repeated create_order calls. If the client loses the COMMIT response, inspect the known order/payment state before retrying. A production checkout request key is not implemented.

A failed attempt recorded within a transaction that is rolled back disappears with that transaction. Retaining a failure audit requires an intentionally committed pending-order/failed-payment workflow. This is a separate business outcome from rolling back a newly created purchase. Identity sequence gaps are possible after aborted inserts and do not mean that a partial order persisted.

## Locks and isolation

finalise_order obtains an order-row FOR UPDATE lock, shared catalogue locks, and FOR UPDATE locks on inventory in ascending variant-ID order. Locks remain until transaction end. Another finalisation of the same order or inventory can wait; ordinary reads do not become stock reservations. Consistent inventory lock order reduces deadlock risk but does not establish that every possible transaction is deadlock-free. [PostgreSQL explicit locking](https://www.postgresql.org/docs/18/explicit-locking.html).

The planned two-session experiment will explicitly record READ COMMITTED and show visibility and lock waiting. It must demonstrate the last-unit outcome rather than infer concurrency safety from single-session checks. A deadlock or serialization error calls for rollback and a bounded retry of the whole transaction after checking payment outcome; insufficient stock requires a business response, not an unconditional retry. No retry loop is currently implemented.

## Outside this boundary

Shopping-cart conversion/clearing is not performed by create_order or finalise_order: they accept explicit variant/quantity arrays. The demo will not claim that a cart was converted. Delivery dispatch and receipt use later transactions after payment. Cancellation currently applies only to pending orders; refunds and paid-order cancellation are outside the implemented lifecycle.

A database rollback cannot undo an external card charge. The simulated payment record is part of this database transaction, but a real provider would require a separate protocol for idempotent requests, callbacks, reconciliation, and compensation when payment succeeds but stock/database completion fails. Such a protocol is not implemented. Do not hold inventory locks across a user interaction or network payment request in a future application.

## Evidence planned for subsequent items

The COMMIT demonstration will record stock and row counts before purchase, run the combined boundary, and verify the order, snapshots, one payment, and exact stock reduction from a fresh connection. The ROLLBACK demonstration will force a later failure and verify that all purchase changes disappear. Multi-line rollback, repeat finalisation, visibility, competing last-unit purchases, and lock/retry outcomes will be documented in the appropriate later stages.

This document was checked against the existing function bodies, constraints, triggers, permissions, and earlier integrity test source. It defines expected behaviour; no new runtime or concurrent-session results are asserted here.
