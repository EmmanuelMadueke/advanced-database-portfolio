# Protected last-unit checkout

Owner, author, and maintainer: **Emmanuel Madueke**.

On 16 October 2026, the existing protected retail checkout prevented the last-unit overselling reproduced in the unsafe example. Eleven checks passed on PostgreSQL 18.1: two buyers initially saw one shirt, the second buyer demonstrably waited for the first, and only one paid order/payment persisted. Final stock was zero. Replaying the winner's finalisation returned the same payment without another deduction.

## Control applied

The [existing finalise_order routine](../portfolio-1-database-design/sql/03_operations.sql) takes inventory FOR UPDATE locks in variant-ID order and checks current availability before deducting stock. The locks remain through payment/order updates until the caller ends the transaction. This experiment applies that implementation to the competing-buyers scenario; no new checkout function or schema change was needed.

Creating a pending order does not reserve stock. Both customers therefore create their own pending orders while the shirt balance is still one. Finalisation determines which purchase can proceed. B cannot complete the conflicting inventory lock while A holds it. After A commits, B checks the depleted balance and raises the routine's insufficient-stock exception. Its caller explicitly rolls back the entire new purchase, including the earlier order creation.

PostgreSQL documents that conflicting row lockers wait until the holding transaction ends; READ COMMITTED locking can then use the updated row. [Explicit locking documentation](https://www.postgresql.org/docs/18/explicit-locking.html#LOCKING-ROWS).

## Observed schedule

| Step | Observed outcome |
| --- | --- |
| Prepare A and B | Two customers, distinct orders and sessions; both READ COMMITTED under fashion_portfolio_writer; both initially see stock 1 |
| A finalises without committing | Paid order for one shirt, NGN 12,000; locks retained |
| B attempts finalisation | Monitor observes B PID 80538 blocked by A PID 80536, wait type Lock, event transactionid |
| A commits after confirmed blocking | B resumes and raises insufficient-stock/inactive-variant exception, SQLSTATE P0001 |
| B rolls back | Its new order, items, and any transaction changes disappear |
| Fresh verifier PID 80542 | One paid order, one line/unit, one matching succeeded payment; stock 0; no loser order; unrelated jacket stock remains 5 |
| A retries known order | Same payment ID returned; all verified purchase/stock values unchanged |

The catalogue remains active and unchanged, so the observed exception corresponds to stock depletion, although the routine uses a combined stock/inactive message. The monitor reports a transaction-ID lock wait, not a printed inventory tuple ID. Its observation, the routine source, and the two-order schedule together establish the relevant inventory contention; no precise wait-duration measurement is claimed.

## Comparison with the unsafe example

| Property | Unsafe teaching model | Protected retail routine |
| --- | --- | --- |
| Initial shirt units | 1 | 1 |
| Both buyers initially observe 1 | Yes | Yes |
| Decision when writing | Trust cached client quantity | Lock inventory and check current balance |
| Committed accepted purchases / paid orders | 2 | 1 |
| Final available units | 0 | 0 |
| Available + purchased units | 2, violates initial stock | 1, preserves initial stock |
| Losing buyer | Incorrectly accepted | Rejected; full transaction rolled back |

The unsafe model records simplified accepted allocations; the protected version uses full order/item/payment tables. This is a comparison of the allocation invariant, not identical schemas, a performance comparison, or evidence that retail previously lacked locking.

## Failure and retry handling

The depleted-stock P0001 result is a business rejection: roll back and report that the item is unavailable. Do not blindly retry it. P0001 also covers other application exceptions; the test checks both the SQLSTATE and the expected message rather than treating every P0001 as insufficient stock.

For a deadlock (40P01) or serialization failure (40001), a future caller should roll back and retry the complete transaction with a bounded retry policy, reconsidering all reads/decisions. PostgreSQL recommends complete-transaction retries for serialization failures and notes that deadlocks may also merit retry. [Failure-handling documentation](https://www.postgresql.org/docs/18/mvcc-serialization-failure-handling.html). No deadlock, serialization-failure injection, or automatic retry loop was implemented in this stage.

The demonstrated retry is narrower: finalise_order on a known already-paid order returns its existing successful payment. If the commit acknowledgement is lost, reconcile the known order before attempting another purchase. Repeating create_order is not idempotent. Real payment-provider reconciliation remains outside this simulated database workflow.

## Reproduce

Use a new disposable database such as fashion_protected_demo. Configure connection variables and install Portfolio 1 scripts 01–04 using the [setup instructions](../docs/Madueke_Emmanuel_301912318_setup.md). Do not load the normal sample/scale dataset. From the repository root:

```sh
psql -X -f portfolio-3-transactions-concurrency/sql/13_protected_fixture.sql
python3 portfolio-3-transactions-concurrency/tests/protected_race.py
```

The fixture includes 01_commit_fixture.sql, then commits a starting shirt balance of one and a second synthetic customer/address. Its first output reflects the shared fixture's stock 10/5; its final output records the actual race fixture stock 1/5. Stop on errors; use a new database for a repeat. The purchase remains committed for inspection. Set PSQL_BIN if needed; Python dependencies are all standard-library modules.

The [coordinator](tests/protected_race.py) uses two buyer connections, a separate monitoring connection, and a fresh verification connection. The owner connection may inspect pg_stat_activity and pg_blocking_pids; purchase transactions switch to the restricted writer role. B runs asynchronously while the monitor polls actual lock state. A's commit is gated on confirmed blocking, not elapsed time. Polling has a five-second deadline, and session statements have a ten-second timeout. A timeout is a test failure, not a successful contention result. Unexpected errors stop the run; cleanup closes unfinished transactions. Already committed changes remain if a later assertion fails.

The saved [prepare SQL](sql/14_protected_prepare.sql), [winner SQL](sql/15_protected_winner.sql), [loser SQL](sql/16_protected_loser.sql), and [result query](sql/17_protected_result.sql) support manual replay too: prepare both connections, finalise A without committing, start B's finalisation, confirm blocking from a monitor, then commit A. Let B finish its rejection/rollback and inspect the result through a new connection. The loser script permits only the expected failing statement before re-enabling stop-on-error.

## Evidence and limitations

- [Schema installation](evidence/protected-install.txt)
- [Fixture setup](evidence/protected-fixture.txt)
- [Actual lock observation, rejection, reconciliation, and replay checks](evidence/protected-sessions.txt)

This verifies one controlled last-unit schedule at READ COMMITTED. It does not establish fairness, throughput, all multi-variant interleavings, deadlock freedom, or external payment correctness. Deterministic inventory lock ordering reduces risk but does not prove every possible caller is deadlock-free. No independent student verification is claimed.
