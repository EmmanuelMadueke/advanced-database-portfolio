# Portfolio 3 — Transactions and Concurrency

Owner, author, and maintainer: **Emmanuel Madueke**.

## Current stage

The checkout transaction boundary is defined in [transaction-boundary.md](transaction-boundary.md), based on the implemented fashion-store routines and integrity rules. The COMMIT demonstration has now passed eight persistence checks through a fresh connection. The ROLLBACK demonstration has also passed six fresh-connection checks. A [two-session READ COMMITTED demonstration](isolation.md) has now passed seven checks. An [isolated unsafe last-unit race](unsafe-concurrency.md) reproduced overselling with eight checks. The [protected concurrency comparison](protected-concurrency.md) passed eleven checks, including observed lock waiting, loser rollback, stock conservation, and idempotent finalisation replay. Portfolio 3 implementation and evidence are complete.

## Activity checklist

- [x] Define the checkout transaction boundary.
- [x] Demonstrate COMMIT and verify persisted order, items, payment, and stock together.
- [x] Demonstrate ROLLBACK after a checkout failure.
- [x] Demonstrate isolation with two database sessions.
- [x] Demonstrate a controlled concurrency issue in an isolated unsafe example.
- [x] Repeat with concurrency control and document retry handling.
- [x] Retain reproducible session scripts, outputs, and conclusions.

## Starting point

Use the existing [PostgreSQL setup](../docs/setup.md) and [sample data](../docs/sample-data.md). The unscaled sample is sufficient for the planned transaction demonstrations; Portfolio 2 reporting indexes are optional and are not part of checkout correctness.

The existing [operations](../portfolio-1-database-design/sql/03_operations.sql), [integrity triggers](../portfolio-1-database-design/sql/02_integrity.sql), and [controlled writer role](../portfolio-1-database-design/sql/04_permissions.sql) supply the implementation being examined. Portfolio 1's [integrity tests](../portfolio-1-database-design/tests/integrity.sql) provide earlier single-session checks; they do not replace this activity's planned persistence and concurrency evidence.

The completed NoSQL work is in [Portfolio 4](../portfolio-4-nosql/README.md).

## COMMIT demonstration

On 14 October 2026, a purchase of two shirts at NGN 12,000 each and one jacket at NGN 25,000 committed as one order for **NGN 49,000**. The controlled writer role created and finalised the order in one READ COMMITTED transaction. A new connection passed eight persistence assertions: one paid order, two correct lines and snapshots, one matching successful payment, and stock changes from 10 → 8 shirts and 5 → 4 jackets. [Actual evidence and limitations](evidence/README.md) are retained.

### Reproduce

Use a **new disposable database**, not the Portfolio 1 sample/scale database. Follow [setup](../docs/setup.md) to configure PostgreSQL connection variables and put psql/createdb on PATH. From the repository root:

```sh
export PGDATABASE=fashion_commit_demo
createdb "$PGDATABASE"
psql -X -v ON_ERROR_STOP=1 \
  -f portfolio-1-database-design/sql/01_schema.sql \
  -f portfolio-1-database-design/sql/02_integrity.sql \
  -f portfolio-1-database-design/sql/03_operations.sql \
  -f portfolio-1-database-design/sql/04_permissions.sql
psql -X -f portfolio-3-transactions-concurrency/sql/01_commit_fixture.sql
psql -X -f portfolio-3-transactions-concurrency/sql/02_commit_purchase.sql
psql -X -f portfolio-3-transactions-concurrency/sql/03_verify_commit.sql
```

Each psql command starts a separate connection. Stop on any nonzero exit; every script enables ON_ERROR_STOP. The fixture and purchase are intended to run once; the verifier can be repeated on the unchanged database. Use a new database name if the previous one exists. Do not drop an existing database just to rerun the example. Rows deliberately remain committed for inspection; stop the temporary cluster after inspection using the setup instructions.

The fixture setup commits separately from the purchase. The final two calls to create_order and finalise_order share a single explicit purchase transaction. The fixed synthetic provider reference identifies this demonstration; a duplicate attempt is not a second valid purchase. IDs are selected dynamically, and no timestamps or outputs are fabricated.

## ROLLBACK demonstration

On 16 October 2026, the same two-line NGN 49,000 purchase was successfully constructed inside a transaction, including a simulated successful payment and stock deductions. An injected exception immediately before COMMIT triggered the caller's explicit ROLLBACK. Six checks through a fresh connection confirmed **zero orders, items, or payments**, restored stock of **10 shirts and 5 jackets**, and preservation of the previously committed fixtures. [Actual failure and verification evidence](evidence/README.md#rollback-demonstration--16-october-2026) are saved.

For reproduction, create a **new database** such as `fashion_rollback_demo` and install Portfolio 1 scripts 01–04 using the commands above. Then run these as separate psql invocations, stopping on any nonzero exit:

```sh
psql -X -f portfolio-3-transactions-concurrency/sql/01_commit_fixture.sql
psql -X -f portfolio-3-transactions-concurrency/sql/04_rollback_purchase.sql
psql -X -f portfolio-3-transactions-concurrency/sql/05_verify_rollback.sql
```

Do not run 02_commit_purchase.sql in this database. The shared fixture retains its COMMIT-prefixed synthetic names; these are catalogue identifiers, not evidence of a committed purchase. The expected error is generated deliberately after finalisation to exercise full-transaction rollback. No real provider is called and no charge is reversed. The script checks the expected SQLSTATE, while the verifier independently checks persisted data. The failure scenario and verifier can be repeated on the unchanged fixture; generated IDs may differ.

## Evidence coverage

| Requirement | Retained work |
| --- | --- |
| Transaction boundary | [Scope and consistency contract](transaction-boundary.md) |
| COMMIT | [Eight fresh-connection checks](evidence/commit-verification.txt) |
| ROLLBACK | [Six fresh-connection checks](evidence/rollback-verification.txt) |
| Isolation | [Two-session schedule and seven checks](isolation.md) |
| Concurrency issue | [Unsafe race and eight checks](unsafe-concurrency.md) |
| Concurrency control | [Protected race and eleven checks](protected-concurrency.md) |

These are distinct demonstrations, not a claim that every possible transaction schedule has been verified. Raw outputs, reproducible SQL, and limitations are retained for each stage. Emmanuel's personal review/reflection remains separate from tool-run checks.

## Screenshot evidence

See the [assessment screenshot gallery](../evidence/screenshots/README.md) for captures of retained outputs and diagrams. Captures are labelled separately from the original execution dates; Portfolio 5 remains a discussion.
