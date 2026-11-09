# COMMIT demonstration evidence — 14 October 2026

Owner, author, and maintainer: **Emmanuel Madueke**.

A dedicated disposable database, fashion_commit_demo, was installed on the isolated PostgreSQL 18.1 cluster. Only Portfolio 1 scripts 01–04 and the new COMMIT fixture were loaded; sample/scale/reporting datasets were not modified.

| Evidence | Observed result |
| --- | --- |
| [Installation](commit-install.txt) | Schema, integrity rules, operations, and permissions installed |
| [Initial fixture error](commit-fixture-initial-error.txt) | Required product description was omitted; fixture transaction aborted before any purchase |
| [Corrected fixture](commit-fixture.txt) | Starting stock: shirts 10, jackets 5; orders/items/payments all zero |
| [Purchase](commit-purchase.txt) | READ COMMITTED, restricted writer role, two lines, NGN 49,000, explicit COMMIT acknowledged |
| [Fresh-connection verification](commit-verification.txt) | Eight assertions passed; order/payment/snapshots persisted, stock 8 and 4 |

The initial fixture was corrected by supplying product descriptions and rerun after its failed connection closed. The failed fixture inserts rolled back, but identity sequences advanced; fresh reproduction may therefore assign different fixture IDs. This setup error is not the planned checkout ROLLBACK demonstration.

The purchase used backend 91602 and verification used backend 91603. The verifier ran a REPEATABLE READ, READ ONLY transaction under fashion_portfolio_writer; its temporary assertion helper was created beforehand and did not change retail data. It checked paid order count/total, line quantities/prices/product names, line-total reconciliation, successful payment reference/method/amount/currency/time, both stock balances, delivery address, and size/colour snapshots.

The logs contain actual psql output, including formatting whitespace. The eight checks are tool-run evidence of committed state visible through a new connection. They do not establish crash recovery, independent student verification, rollback behaviour, or concurrent last-unit safety. No external payment was processed.

## ROLLBACK demonstration — 16 October 2026

The dedicated fashion_rollback_demo database was installed separately from the COMMIT demonstration and loaded with the same starting fixture. The purchase used the restricted writer role at READ COMMITTED, then deliberately raised SQLSTATE P0001 after successful simulated finalisation and deferred validation, before COMMIT. This is an injected caller-side checkout failure, not an insufficient-stock failure or a real payment-provider failure.

| Evidence | Observed result |
| --- | --- |
| [Installation](rollback-install.txt) | Portfolio 1 scripts 01–04 installed in the new database |
| [Starting fixture](rollback-fixture.txt) | Zero purchase rows, shirts 10, jackets 5 |
| [Failure and rollback](rollback-purchase.txt) | Uncommitted paid order NGN 49,000, succeeded payment, stock 8/4; expected exception followed by explicit ROLLBACK |
| [Fresh verification](rollback-verification.txt) | Six assertions passed: no orders/items/payments, stock restored to 10/5, committed fixtures preserved |

The purchase connection was backend 84227; the subsequent verifier was backend 84228. The verifier used a REPEATABLE READ, READ ONLY transaction under the writer role. Its final COMMIT closes that read-only verification transaction; it does not commit the failed purchase.

The failure script disables ON_ERROR_STOP for exactly the intentionally failing statement, records its SQLSTATE, re-enables stop-on-error, explicitly rolls back, and rejects an unexpected SQLSTATE. There is no savepoint or exception handler preserving part of the purchase. The earlier create_order and finalise_order calls returned successfully; the full outer rollback removes their changes. The simulation demonstrates why successful function return is not equivalent to successful COMMIT.

The deliberate ERROR line is expected evidence, not a failed test run. Identity sequence values may advance despite rollback. No concurrency, deadlock, crash recovery, or external-charge reversal is demonstrated. Previously committed pending-order failure and insufficient-stock cases are separate scenarios; this evidence covers a newly created purchase rolled back in full.

## Two-session isolation — 16 October 2026

[Installation](isolation-install.txt), [fixture](isolation-fixture.txt), and [session-by-session observations](isolation-sessions.txt) record the separate fashion_isolation_demo database. Seven checks passed: B could not see A's uncommitted purchase but saw it in the next statement after A committed, without restarting B's READ COMMITTED transaction. See [interpretation, SQL, and reproduction](../isolation.md). Competing-writer behaviour remains to be demonstrated.

## Unsafe last-unit race — 16 October 2026

[Fixture output](unsafe-fixture.txt) and [session output](unsafe-sessions.txt) record the separate fashion_unsafe_demo database. Two READ COMMITTED buyers read the same last unit before either wrote, then both committed accepted purchases using stale stock values. A fresh connection found stock zero and two units sold from an initial one. Eight assertions passed by confirming the intended defect. The existing retail implementation was not modified. See [analysis, scope, and reproduction](../unsafe-concurrency.md). Corrected concurrent behaviour remains pending.

## Protected last-unit race — 16 October 2026

[Installation](protected-install.txt), [fixture](protected-fixture.txt), and [session evidence](protected-sessions.txt) record the separate fashion_protected_demo database. Eleven checks passed using the existing retail checkout routines. The monitor confirmed B waited on A; after A committed, B rejected depleted stock and rolled back. A fresh verifier found one paid order/payment, no loser order, stock zero, and conserved units. Replaying A's finalisation returned the same payment without changing state. [Analysis and reproduction](../protected-concurrency.md) distinguish measured outcomes from planned retry policy and broader concurrency limits.
