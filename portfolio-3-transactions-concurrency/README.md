# Portfolio 3 — Transactions and Concurrency

Owner, author, and maintainer: **Emmanuel Madueke**.

## Current stage

The checkout transaction boundary is defined in [transaction-boundary.md](transaction-boundary.md), based on the implemented fashion-store routines and integrity rules. This stage is a source review and design document; no new database execution or two-session demonstration is claimed.

## Activity checklist

- [x] Define the checkout transaction boundary.
- [ ] Demonstrate COMMIT and verify persisted order, items, payment, and stock together.
- [ ] Demonstrate ROLLBACK after a checkout failure.
- [ ] Demonstrate isolation with two database sessions.
- [ ] Demonstrate a controlled concurrency issue in an isolated unsafe example.
- [ ] Repeat with concurrency control and document retry handling.
- [ ] Retain reproducible session scripts, outputs, and conclusions.

## Starting point

Use the existing [PostgreSQL setup](../docs/setup.md) and [sample data](../docs/sample-data.md). The unscaled sample is sufficient for the planned transaction demonstrations; Portfolio 2 reporting indexes are optional and are not part of checkout correctness.

The existing [operations](../portfolio-1-database-design/sql/03_operations.sql), [integrity triggers](../portfolio-1-database-design/sql/02_integrity.sql), and [controlled writer role](../portfolio-1-database-design/sql/04_permissions.sql) supply the implementation being examined. Portfolio 1's [integrity tests](../portfolio-1-database-design/tests/integrity.sql) provide earlier single-session checks; they do not replace this activity's planned persistence and concurrency evidence.

Next: demonstrate COMMIT using isolated synthetic fixtures, then verify the committed purchase from a fresh connection.
