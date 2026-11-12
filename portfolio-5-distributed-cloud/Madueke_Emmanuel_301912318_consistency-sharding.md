# Consistency and sharding for the fashion store

Owner, author, and maintainer: **Emmanuel Madueke**.

## Decision and scope

Keep the proposed PostgreSQL checkout database **unsharded**, with the primary/standby roles defined in [replication and availability](Madueke_Emmanuel_301912318_replication-availability.md). Keep MongoDB profiles in one proposed replica set. Evaluate sharding as a future option, not a current deployment requirement: the portfolio has a synthetic SQL workload and three document profiles, with no production capacity evidence requiring shards.

All routing, recovery, and partitioning policies below are proposed. Existing local tests do not establish distributed consistency, and no shard, replica-session guarantee, or cross-partition transaction was executed for this stage.

## Consistency by operation

| Store operation | Proposed authority/read route | Consistency requirement and consequence |
| --- | --- | --- |
| Place order and deduct stock | PostgreSQL primary P, controlled transaction | Read/lock current inventory and commit order/payment together; a browsing response never reserves stock |
| Immediately view a newly placed order | Current authoritative SQL primary, after COMMIT succeeds | Avoid a lagging report replica hiding a just-committed order |
| Management trend reports | Asynchronous standby R when acceptable | Expose data freshness and pause/reroute reports when lag exceeds the agreed limit; no numeric limit has been specified |
| Browse material/care details | MongoDB primary initially | Descriptive content may be stale relative to SQL; prices and availability still come from SQL |
| Edit and then inspect enrichment | Proposed MongoDB session/acknowledgement policy | Define read-after-write requirements explicitly before allowing secondary reads |
| Reconcile an uncertain purchase | Authoritative SQL order/payment state and, in a real system, the payment provider | Do not infer failure from timeout or absence on a stale replica; do not create a second purchase blindly |

### Durable replication is not immediate read visibility

With synchronous_commit=on and a configured synchronous standby, PostgreSQL acknowledgement waits for standby WAL flush, not replay. remote_apply waits for replay on the synchronous standby, but does not make every asynchronous reader current. Therefore the proposed choice to read recent orders from the primary remains useful even with synchronous durability. [PostgreSQL acknowledgement modes](https://www.postgresql.org/docs/18/runtime-config-wal.html#GUC-SYNCHRONOUS-COMMIT).

For example, A buys the last shirt and receives a successful COMMIT response. R has not replayed that transaction and still shows stock 1 or no new order. That report does not undo A's purchase. A second checkout must reach the authoritative writer, where the implemented stock check rejects unavailable inventory. The [local protected-race evidence](../portfolio-3-transactions-concurrency/protected-concurrency.md) supports that routine's behaviour on one primary; it does not measure replica lag.

Primary routing must follow validated failover, not a permanent hostname pointing at the old writer. If promotion safety or required acknowledgement cannot be established, pause checkout. This deliberately sacrifices write availability for the affected operation rather than accepting competing stock histories. Descriptive browsing may have a different availability policy; the design does not assign one blanket consistency label to the entire application.

### MongoDB sessions and copied SQL facts

Majority acknowledgement alone does not guarantee that an arbitrary secondary read immediately sees a writer's change. MongoDB documents causal guarantees using causally consistent sessions with majority read and write concerns; the application must preserve the required session/order context. This is a possible future policy for an editor's read-after-write workflow, not a feature exercised by the standalone portfolio container. [MongoDB causal consistency requirements](https://www.mongodb.com/docs/manual/core/causal-consistency-read-write-concerns/).

No MongoDB read concern makes copied SQL catalogue fields current. The implemented export/import guarantees agreement with one recorded SQL snapshot only. If SQL deactivates a product after export, all MongoDB replicas could faithfully replicate the same outdated active flag. That is cross-store staleness, separate from replication lag. The [implemented reconciliation contract](../portfolio-4-nosql/Madueke_Emmanuel_301912318_implementation.md) remains authoritative about what has actually been verified.

A future live refresh would need durable change capture/delivery, stable product identity, version ordering, duplicate handling, deletion handling, and reconciliation after missed events. Its delay would need monitoring independently of replica lag. None of that automation exists here; a proposed fallback to SQL descriptions is also unimplemented.

## Replication, table partitioning, and sharding

Replication maintains copies for availability/read workloads; it does not itself divide the authoritative write workload into independent partitions. PostgreSQL declarative partitioning divides a logical table into partitions using range, list, or hash rules. That alone is not a distributed checkout implementation across independent PostgreSQL servers. [PostgreSQL table partitioning](https://www.postgresql.org/docs/18/ddl-partitioning.html).

Date partitioning of old orders could be considered for retention/report maintenance, but it would require schema, uniqueness, query, and migration review. It would not solve contention for one popular variant. No table partitioning is implemented in this portfolio.

## Candidate data-distribution keys

These are case-study design options, not chosen shard configurations.

| Data / candidate key | Potential locality | Main cost for this store |
| --- | --- | --- |
| SQL orders by customer_id | A customer's order history together | Shared inventory is not owned by one customer; checkout still crosses ownership boundaries |
| SQL inventory by variant_id | One stock authority per variant | A basket with shirt and shoes may touch different shards; one popular variant remains a hot key |
| SQL orders by order date | Time-window reports and archival boundaries | Current orders concentrate activity in the newest partition; mixed-date customer history spans partitions |
| MongoDB profiles by category | Category browsing together | Only three categories in this model and potentially uneven demand; weak standalone distribution key |
| MongoDB profiles by hashed `_id` | Exact product lookup can target its owning shard | Material/tag searches without product ID may need multiple shards; popular single-profile traffic remains concentrated |

MongoDB recommends considering key cardinality, frequency, monotonicity, and query patterns. The small category set is therefore a poor basis for horizontal growth. Candidate distribution must be assessed with actual workload data, rather than assuming more shards balance demand. [Shard-key selection](https://www.mongodb.com/docs/manual/core/sharding-choose-a-shard-key/).

Hashed product identity is the more plausible MongoDB candidate if later scale requires sharding: it distributes by hash rather than preserving ID ranges, while equality lookup on the key can be targeted. Queries lacking that key, including this portfolio's material filter and tag coverage, sacrifice locality. The profile IDs are strings, so their lexicographic range order must not be mistaken for numerical order. [Hashed-sharding trade-offs](https://www.mongodb.com/docs/manual/core/hashed-sharding/).

A sharded MongoDB topology would also require routing and metadata services, with shards deployed as replica sets. It would replace the simple replica-set topology with additional operational responsibilities; a query index such as profile_composition_lookup is not itself a sharding configuration. [Sharded-cluster components](https://www.mongodb.com/docs/manual/core/sharded-cluster-components/).

## Cross-partition checkout example

Suppose a future inventory design places a shirt on shard X and shoes on shard Y. A customer requests both. X accepts a deduction, but Y is unavailable or reports insufficient stock. Independently committing X would violate the current all-or-nothing basket boundary.

A future design must choose and implement a protocol: either a supported coordinated transaction across the affected data, or an explicit reservation/state-machine workflow with expiry, compensation, and payment reconciliation. Reservations would require race-safe acquisition and release, durable progress records, and idempotent recovery. They are not equivalent to the current immediate stock deduction and cannot be added merely by changing connection strings.

The existing finalise_order locks rows in one PostgreSQL database. Its local lock ordering and transaction do not automatically coordinate different servers. Global order/payment identifiers, uniqueness, references, and retries would all need reassessment. An external card charge would still require reconciliation even if all database participants could commit atomically.

For the current store, retaining the single logical SQL writer keeps that tested boundary intact. Consider distributing write ownership only after measuring a bottleneck and establishing which transactions can remain local. Descriptive-profile sharding would not by itself remove SQL checkout contention.

## Decision criteria and remaining evidence

Before changing this design, collect workload size/growth, hot-product frequency, query distribution, replica lag, read-after-write failures, lock waits, and recovery behaviour. Use those observations to set freshness and recovery targets. Test failure between each proposed cross-partition step before claiming atomicity or compensation correctness.

This stage concludes that recent-order reads should use the authoritative SQL writer, lag-tolerant reports may use R, and catalogue-copy freshness must be managed separately. Sharding remains a future option with explicit transaction costs. The completed [architecture and failure scenarios](Madueke_Emmanuel_301912318_architecture-scenarios.md) illustrate these choices; the [conclusions](Madueke_Emmanuel_301912318_conclusions.md) consolidate their limits and evidence coverage.
