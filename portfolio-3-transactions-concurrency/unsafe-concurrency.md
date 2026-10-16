# Controlled concurrency issue: two buyers, one shirt

Owner, author, and maintainer: **Emmanuel Madueke**.

On 16 October 2026, two overlapping READ COMMITTED transactions both accepted a purchase of the same last shirt. A fresh connection confirmed two committed one-unit purchases, although the initial stock was one. The stock column ended at zero, so its nonnegative CHECK constraint did not detect the overselling. Eight checks confirmed reproduction of this deliberately unsafe behaviour.

## Scope

This uses a simplified fashion-store teaching model in the separate fashion_unsafe_demo database and unsafe_checkout schema. It contains one stock row for LAST-SHIRT-M-BLACK and an accepted_purchases table. Accepted purchase rows represent allocation decisions, not the full retail order/payment workflow. No real customers or payments are involved.

The example runs as the disposable database owner to permit deliberately unsafe writes. It does not grant the existing writer role direct table access, remove retail constraints, or modify create_order/finalise_order. The protected checkout already locks inventory; this experiment demonstrates the defect that a naive alternative could introduce, not a discovered failure in that protected implementation.

## Actual interleaving

| Step | Session A, PID 41486 | Session B, PID 41488 | Committed result |
| --- | --- | --- | --- |
| Start | Begin READ COMMITTED; read stock 1 into a client variable | Begin READ COMMITTED; read stock 1 into a client variable | One unit; no purchases |
| First purchase | Write cached 1 − 1 = 0; insert purchase; COMMIT | Remain open with cached stock 1 | Stock 0; one purchase |
| Second purchase | Finished | Check cached 1, write cached 1 − 1 = 0; insert purchase; COMMIT | Stock 0; two purchases |
| Verify | Separate connection PID 41490 | — | Two distinct buyers purchased one unit each |

The transactions overlap during the reads; the coordinator deliberately schedules their writes one after the other. This is a valid concurrent interleaving, not a claim that both UPDATE statements executed simultaneously or that lock waiting was measured. Completion markers enforce both reads before either write, without relying on sleeps.

The defect is the read/check/write gap. B uses the previously observed stock value rather than rechecking availability when writing. Its UPDATE locates the row only by SKU and assigns a stale constant. PostgreSQL's normal UPDATE lock does not make that earlier application decision current. This is a lost stock deduction and an overselling outcome: both assignments set zero while both purchase records persist.

The required accounting invariant is:

```text
remaining stock + units allocated = initial stock
observed:       0 + 2             != 1
```

Every individual row remains valid: stock is nonnegative, quantities are positive, buyers are distinct, and the SKU foreign key exists. These constraints do not enforce the cross-table allocation invariant. READ COMMITTED gives each statement a fresh snapshot; it does not refresh a value already cached by the client. [PostgreSQL transaction isolation](https://www.postgresql.org/docs/18/transaction-iso.html#XACT-READ-COMMITTED).

## Reproduce

Configure the PostgreSQL tools and connection variables using [setup](../docs/setup.md). Create a new disposable database; no retail schema or sample seed is required for this isolated example. From the repository root:

```sh
export PGDATABASE=fashion_unsafe_demo
createdb "$PGDATABASE"
psql -X -f portfolio-3-transactions-concurrency/sql/09_unsafe_fixture.sql
python3 portfolio-3-transactions-concurrency/tests/unsafe_race.py
```

Stop if a command fails. Use PSQL_BIN if psql is not on PATH. The runner uses the standard library and reuses the Session coordinator from isolation.py; importing it does not run the earlier isolation experiment. Both buyer sessions remain open between read and acceptance. A third connection verifies the committed result. Assertions fail on unexpected observations, and cleanup closes unfinished connections. The final unsafe purchases intentionally remain for inspection; use a new database for another run. The fixture refuses to overwrite an existing schema.

For manual execution, open two psql connections to the same fresh database, then:

1. In A, set `\set buyer 'Buyer A'`; in B, set `\set buyer 'Buyer B'`.
2. In both connections, execute `\i portfolio-3-transactions-concurrency/sql/10_unsafe_read.sql`. Confirm both read 1 before proceeding.
3. In A, execute `\i portfolio-3-transactions-concurrency/sql/11_unsafe_accept.sql` and wait for completion.
4. In B, execute the same acceptance script using its retained stale value.
5. In a fresh connection, execute `\i portfolio-3-transactions-concurrency/sql/12_unsafe_result.sql`.

[Fixture output](evidence/unsafe-fixture.txt) and [session output with eight checks](evidence/unsafe-sessions.txt) retain actual results. SQL and the [runner](tests/unsafe_race.py) are reproducible; no history or outputs are fabricated.

## Next: apply control and repeat

The next stage will demonstrate prevention using inventory row locking or a conditional stock decrement, with purchase recording in the same transaction and a current availability check. It must show that only one buyer succeeds, stock remains zero, and no rejected buyer's purchase persists. The existing protected checkout should be exercised for comparison, with blocking/failure/retry outcomes recorded as appropriate.

That corrected concurrent run remains pending. The current eight passing checks mean the intended defect was reproduced, not that this unsafe implementation is correct. No throughput, deadlock, or independent student verification claim is made.
