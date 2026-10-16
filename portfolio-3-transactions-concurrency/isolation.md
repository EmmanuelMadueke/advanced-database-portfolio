# Two-session isolation demonstration

Owner, author, and maintainer: **Emmanuel Madueke**.

On 16 October 2026, two persistent PostgreSQL 18.1 connections demonstrated READ COMMITTED visibility on the same fashion-store checkout. Session A performed the purchase; session B observed it inside one read-only transaction. Both used fashion_portfolio_writer. Seven assertions passed.

## Actual sequence and observations

The dedicated fashion_isolation_demo database contained only Portfolio 1 scripts 01–04 and the shared synthetic fixture. No prior demonstration purchase was loaded.

| Step | Session | Observed purchase state | Shirt / jacket stock |
| --- | --- | --- | --- |
| Begin READ COMMITTED READ ONLY; read starting state | B, PID 86313 | No orders, items, or payments | 10 / 5 |
| Begin READ COMMITTED; create and finalise; validate; keep transaction open | A, PID 86311 | Own uncommitted paid order, two items, one succeeded payment; NGN 49,000 | 8 / 4 |
| Read while A remains open | B, same transaction | No orders, items, or payments | 10 / 5 |
| COMMIT, then allow B's next query | A | Purchase committed | 8 / 4 |
| Read again without restarting B's transaction | B | One paid order, two items, one succeeded payment; NGN 49,000 | 8 / 4 |
| COMMIT read-only transaction | B | Observer transaction closed | No writes |

The [session log](evidence/isolation-sessions.txt) records actual PIDs, roles, isolation levels, observations, orchestration steps, and assertions. [Installation](evidence/isolation-install.txt) and [starting fixture](evidence/isolation-fixture.txt) outputs are retained.

This demonstrates that B does not read A's uncommitted purchase. B's next statement after A commits sees the newly committed state even though B's transaction remains open. This matches PostgreSQL's READ COMMITTED statement-snapshot behaviour; A can also read its own changes before commit. [PostgreSQL isolation documentation](https://www.postgresql.org/docs/18/transaction-iso.html#XACT-READ-COMMITTED).

Each observation is one SELECT returning order/item/payment counts, paid order and successful payment counts, total paid revenue, and both stock balances. These fields therefore share one statement snapshot. B's ordinary SELECT completed before A released its transaction; this experiment does not test a competing writer or a SELECT FOR UPDATE.

## Reproduce automatically

Create a new disposable database, configure PGHOST/PGPORT/PGDATABASE/PGUSER as needed, and install Portfolio 1 scripts 01–04 as described in the [activity README](README.md#reproduce). Use a database name such as fashion_isolation_demo. Do not run the COMMIT or ROLLBACK purchase scripts in it. From the repository root:

```sh
psql -X -f portfolio-3-transactions-concurrency/sql/01_commit_fixture.sql
python3 portfolio-3-transactions-concurrency/tests/isolation.py
```

Set PSQL_BIN if psql is not on PATH. Python uses only the standard library. The runner opens two persistent psql processes, executes the saved SQL, and waits for completion markers before advancing. It sends A's COMMIT only after B's uncommitted-state observation and assertions complete. No fixed sleeps determine transaction ordering. SQL errors stop psql; timeouts and failed assertions cause a nonzero exit. Connections close in cleanup, rolling back any unfinished transaction. A purchase already committed before a later verification error remains committed; inspect the database and reproduce in a new one.

Run once per fresh fixture: the final purchase intentionally persists. Reusing the database is rejected by the starting-state assertion. Stop the temporary cluster after inspection using the setup instructions.

## Reproduce manually in two terminals

Use two psql connections to the same freshly prepared database. Keep them open and follow this sequence from the repository root:

1. In B: `\i portfolio-3-transactions-concurrency/sql/07_isolation_observer.sql`, then `\i portfolio-3-transactions-concurrency/sql/08_isolation_observation.sql`.
2. In A: `\i portfolio-3-transactions-concurrency/sql/06_isolation_writer.sql`, then the same observation script. Leave A open without COMMIT.
3. In B: run the observation script again; expect the original zero-purchase state and stock 10/5.
4. In A: execute `COMMIT;` and wait for acknowledgement.
5. In B: run the observation script again; expect the complete purchase and stock 8/4. Then execute `COMMIT;` to close B's read-only transaction.

[Writer SQL](sql/06_isolation_writer.sql), [observer setup](sql/07_isolation_observer.sql), [observation SQL](sql/08_isolation_observation.sql), and [automated checks](tests/isolation.py) are retained. Stop and roll back on an unexpected manual error.

## Limits and next step

This is a coordinated visibility demonstration with overlapping transactions, not a throughput benchmark, competing-writer race, deadlock demonstration, or proof of serializability. It does not test REPEATABLE READ or SERIALIZABLE. No independent student verification is claimed. The next checklist item is an isolated unsafe last-unit purchase example; the existing protected checkout implementation will remain intact for the later controlled comparison.
