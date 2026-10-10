# Schema and Integrity Evidence

Owner, author, and maintainer: **Emmanuel Madueke**.

Recorded on 9 October 2026 against a fresh, isolated PostgreSQL 18.1 database.

- [Schema output](schema-output.txt): all four installation scripts completed, including 16 table definitions, indexes, triggers, functions, and grants.
- [Integrity output](integrity-output.txt): 35 assertions passed. Rejections check expected SQLSTATE/message fragments so an unrelated failure cannot pass silently.
- [Database summary](database-summary.txt): 16 base tables, 99 columns, Africa/Lagos timezone, and zero fixture customers after rollback.

Covered checks include foreign keys, variant/lookup/cart/reference uniqueness, invalid quantities/stock/NaN prices, mandatory inventory, raw monetary precision, restricted writer permissions, order/payment totals, status transitions, successful checkout, repeat finalisation, failed/multi-item rollback, historical snapshots, cancellation, and delivery completion.

These text files are actual command output, not illustrative screenshots. Fixture data is synthetic and temporary. The tests validate final transaction state using SET CONSTRAINTS ALL IMMEDIATE; successful fixture work is then rolled back. No claim is made here about two-session isolation or concurrent buyers. Reproduction commands and limitations are in [setup documentation](../../docs/setup.md).

## Sample-data evidence

- [Sample seed output](sample-seed-output.txt): synthetic fashion-store records loaded and committed.
- [Sample validation output](sample-check-output.txt): all 10 assertions passed, with order/payment/stock reports.
- [Scale seed output](scale-seed-output.txt): optional default 10,000-order workload loaded and committed.
- [Scale validation output](scale-check-output.txt): all 4 reconciliation assertions passed and combined counts recorded.

Dataset scenarios, expected results, and limitations are in [sample-data documentation](../../docs/sample-data.md). These outputs demonstrate data loading and correctness; they are not query-performance or two-session concurrency evidence.
