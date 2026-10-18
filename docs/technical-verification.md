# Technical verification preparation

Owner, author, and maintainer: **Emmanuel Madueke**.

Prepared on **18 October 2026** from the implemented portfolio and retained evidence. These are preparation notes and answer checkpoints, not a record of an assessment, rehearsal, or independent student verification. Explain each answer in your own words and open its supporting artifact.

## Start with the system

Describe an online fashion retailer whose customers buy size/colour variants. PostgreSQL owns catalogue facts, stock, purchases, payment attempts and delivery; MongoDB holds descriptive enrichment. Payments are simulated. The proposed distributed design was discussed, not deployed.

Use the [three-page summary](../submission/lms-summary.pdf) as the overview, then navigate from the [assessment evidence map](assessment-audit.md) to the relevant source or output. Distinguish what the code does, what a particular test established, and what remains untested.

## Portfolio 1: model and integrity

**Why separate products from variants?** A product can have multiple size/colour combinations, each with its own stock and price. Show the variant identity and uniqueness constraints in the [schema](../portfolio-1-database-design/sql/01_schema.sql), then trace a variant to inventory and an order item on the [ERD](../diagrams/conceptual-erd.svg).

**Does adding a surrogate primary key make a table normalised?** No. Dependencies among other attributes still matter. Use the flattened catalogue example in [normalisation](normalization.md): product details depend on product identity, while category names belong to categories. Explain a partial dependency and a transitive dependency rather than just listing normal forms.

**Why retain purchase-time prices and addresses?** Historical purchases should not change when the current catalogue or customer address changes. Explain the deliberate snapshots and stored-total redundancy, and how validation protects consistency. Do not claim that every stored value is derived afresh from today's catalogue.

**What can a CHECK constraint enforce, and what needs more?** Show a row-level quantity/stock check, a foreign key, and a cross-row total/payment rule in the [integrity implementation](../portfolio-1-database-design/sql/02_integrity.sql). Explain why deferred validation permits intermediate states while a purchase is built. The [35-check output](../evidence/reproducibility-2026-10-17/integrity.txt) tests specific rules, not every possible bad input.

## Portfolio 2: query correctness and performance

**How do payment retries avoid inflating sales?** Distinguish an order from its payment attempts. Explain the report's eligible order states and historical amounts; show how aggregation avoids multiplying order rows by attempts. Use the [query catalogue](../portfolio-2-query-optimisation/README.md) and [history rewrite](../portfolio-2-query-optimisation/optimisation/03_customer_history.sql).

**What changed in the history optimisation?** Three reporting indexes were tested, followed by a targeted lateral aggregate for selected customer orders. Read the [analysis](../portfolio-2-query-optimisation/optimisation/README.md) and [fresh comparison](../evidence/reproducibility-2026-10-17/compare-final.txt). Explain one plan change and why it reduces work. The fresh history median was 1.444 → 0.116 ms; this is a local observation, not a promised production latency.

**How was the comparison controlled?** Same dataset/settings across the three phases, a warm-up plus five measured plans per report, and unchanged complete ordered-result fingerprints. Identify a limitation: synthetic data, warm caches, uncontrolled host activity, or unmeasured write costs. A faster unchanged plan alone does not prove an index benefit. Use the [fresh plans](../evidence/reproducibility-2026-10-17/README.md) rather than mixing timings from different runs.

## Portfolio 3: transactions and concurrency

**Where does the transaction begin and end?** The caller groups `create_order` and `finalise_order` in one explicit transaction. The functions do not commit separately. Explain the sequence in the [transaction boundary](../portfolio-3-transactions-concurrency/transaction-boundary.md), including validation before reporting successful COMMIT. Real external payment processing is outside this simulated database transaction.

**What did rollback prove?** An injected failure followed construction of the purchase. A new connection verified no retained order/items/payment and restored stock. Open the [rollback output](../evidence/reproducibility-2026-10-17/rollback-verify.txt). Contrast rolling back a newly created purchase with failure to finalise a pending order committed earlier.

**Why did stock zero still permit overselling in the unsafe race?** Two buyers read the same stock-one value and both accepted a purchase. Final nonnegative stock alone misses the fact that two units were sold from one. Trace the [unsafe schedule](../portfolio-3-transactions-concurrency/unsafe-concurrency.md), then explain the stronger stock-conservation and purchase-count checks.

**How does the corrected routine prevent that race?** `finalise_order` locks the order and relevant inventory rows, rechecks availability under locks, and updates stock and purchase state together. Inspect the [routine](../portfolio-1-database-design/sql/03_operations.sql) and [protected session log](../evidence/reproducibility-2026-10-17/protected-sessions.txt). Buyer B was observed waiting, then rejected after A consumed the last unit. Ordered locking is not proof that every possible schedule is deadlock-free.

**What does READ COMMITTED guarantee in this demonstration?** The observer did not see A's uncommitted purchase; its next statement after A committed saw the purchase, even within the observer's existing transaction. Read the [isolation schedule](../portfolio-3-transactions-concurrency/isolation.md). This visibility test alone does not prevent a competing-writer race.

**Is checkout fully idempotent?** Replaying finalisation for a known paid order returns the existing payment without another deduction. Repeating new-order creation is a different operation. Explain the [documented retry boundary](../portfolio-3-transactions-concurrency/transaction-boundary.md); request-level identity and external-payment reconciliation remain future work.

## Portfolio 4: document modelling

**Why use MongoDB here, and could PostgreSQL also work?** Enrichment has category-specific nested descriptive attributes. Embedding a bounded profile makes those attributes convenient to retrieve together. SQL still owns transactional facts. Explain the [SQL/NoSQL comparison](../portfolio-4-nosql/sql-nosql-comparison.md), including the PostgreSQL JSONB alternative, without claiming that MongoDB was necessary or generally faster.

**Does MongoDB enforce the SQL relationship?** No foreign key crosses the stores. The importer resolves identities and reconciles profiles against one exported snapshot. Strict validation checks document shape; other rules, such as composition totals, are importer responsibilities. Use the [import manifest](../evidence/reproducibility-2026-10-17/mongo-import/manifest.json) and [implementation](../portfolio-4-nosql/implementation.md). Later SQL changes do not automatically refresh the documents.

**Why use `$elemMatch`, and what did the index experiment establish?** Material and percentage must match the same composition element. Explain why separate predicates can give the wrong answer. The automatic planner retained the identity scan on three profiles; a hinted composition-index plan examined one document and preserved results. The [query explanation](../portfolio-4-nosql/queries/README.md) does not claim a speedup.

## Portfolio 5: proposed distributed operation

**Why can synchronous replication still leave stale reads?** The proposed SQL acknowledgement waits for required standby WAL flush, not replay visibility. Recent-order reads therefore use the current writer. Reports on the asynchronous replica may lag. Explain this using the [consistency discussion](../portfolio-5-distributed-cloud/consistency-sharding.md).

**What happens when the primary or synchronous standby fails?** Primary recovery requires exclusive authority, fencing and validated promotion; the proposal restores a synchronous partner before reopening writes. Losing the required standby while the primary runs can stall commits. A timeout does not prove rollback. Walk through the [failure scenarios](../portfolio-5-distributed-cloud/architecture-scenarios.md) without claiming a measured recovery time.

**Why defer sharding?** No production workload demonstrates a need. A basket spanning inventory shards would require a new coordination or reservation/recovery design; local row locks do not coordinate independent servers. Distinguish replication, table partitioning and sharding using the [candidate-key analysis](../portfolio-5-distributed-cloud/consistency-sharding.md).

## Practical rehearsal and honest evidence

1. Choose one question per activity and explain it without reading the answer checkpoints aloud.
2. Open the relevant source and one retained output. Identify the expected behaviour, observed result and limitation.
3. For a runtime rehearsal, follow the [fresh reproduction instructions](../evidence/reproducibility-2026-10-17/README.md) in disposable environments. Existing scripts may refuse repeated installation or overwrite; use new databases/output paths rather than deleting evidence.
4. Record only the work actually performed: date, artifact reviewed or command executed, observed outcome, uncertainty and follow-up. No completed rehearsal is recorded here.
5. Be ready to explain the AI-use declaration: Emmanuel supplied direction and reviewed the ERD presentation; retained database runs were tool-executed. Do not represent these notes or saved logs as independent student execution.

Assessor access, final reference/declaration review, and LMS submission remain separate checklist items. Preparing this guide does not mark those tasks or Emmanuel's preparation complete.
