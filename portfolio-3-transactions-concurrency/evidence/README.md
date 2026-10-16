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
