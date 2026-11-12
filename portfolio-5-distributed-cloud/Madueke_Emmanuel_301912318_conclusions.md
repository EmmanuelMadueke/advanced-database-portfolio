# Distributed/cloud design conclusions and evidence coverage

Owner, author, and maintainer: **Emmanuel Madueke**.

## Conclusion

For this fashion store, retain one logical PostgreSQL writer for checkout and one MongoDB replica set for descriptive enrichment, with neither store sharded initially. The proposed three-zone design adds replicated copies and recovery options while preserving the transaction boundary demonstrated locally. It also introduces acknowledgement latency, failure coordination, monitoring, and recovery responsibilities that the local implementation has not tested.

**Portfolio 5 completes the assessment's discussion path. It does not establish a working distributed deployment.** No cloud configuration, replica runtime output, failover measurement, recovery objective, or uptime guarantee is supplied. The [scope](Madueke_Emmanuel_301912318_scope.md) records the permitted path and original assumptions; the [diagram and scenarios](Madueke_Emmanuel_301912318_architecture-scenarios.md) show how the proposed design applies to the same fashion-store case study.

## Consolidated decisions and trade-offs

| Decision | Case-study reason | Cost or limitation | Supporting analysis |
| --- | --- | --- | --- |
| Keep PostgreSQL authoritative for stock, price, orders, payments, and delivery | Preserve one transaction boundary for purchase records and stock deductions | The writer remains a capacity and availability dependency | [Consistency by operation](Madueke_Emmanuel_301912318_consistency-sharding.md#consistency-by-operation) |
| Require synchronous standby S for checkout acknowledgement; retain asynchronous R for reports | Retain a durable second copy of acknowledged purchases and isolate eligible reporting reads | Additional commit latency; loss of S can stall commits; R can be stale | [Replication choice](Madueke_Emmanuel_301912318_replication-availability.md#postgresql-replication-choice) |
| Fence the former writer and validate S before promotion; restore a synchronous partner before reopening writes | Avoid conflicting inventory histories and preserve the selected acknowledgement policy | Safe recovery can take longer than simply promoting a node; control tooling is unselected | [Writer ownership](Madueke_Emmanuel_301912318_replication-availability.md#sql-failover-and-writer-ownership) |
| Read recent customer orders and approve purchases through the current SQL writer | Avoid treating an old replica view as an absent purchase or available stock | Primary read load remains; routing must follow safe failover | [Replica visibility](Madueke_Emmanuel_301912318_consistency-sharding.md#durable-replication-is-not-immediate-read-visibility) |
| Use three data-bearing MongoDB voters, majority writes, and primary reads initially | Provide a proposed recovery path for descriptive profiles | Elections interrupt access; loss of majority prevents the chosen write service | [MongoDB policy](Madueke_Emmanuel_301912318_replication-availability.md#mongodb-replica-set-and-acknowledgement) |
| Keep SQL-to-MongoDB freshness separate from database replication | Replicating an imported profile does not refresh its SQL-derived fields | Live refresh and application fallback are unimplemented | [Copied SQL facts](Madueke_Emmanuel_301912318_consistency-sharding.md#mongodb-sessions-and-copied-sql-facts) |
| Defer sharding and table partitioning | No measured production workload establishes a need; baskets can contain multiple variants | Future growth may require redesign, especially across inventory owners | [Candidate keys](Madueke_Emmanuel_301912318_consistency-sharding.md#candidate-data-distribution-keys) and [checkout example](Madueke_Emmanuel_301912318_consistency-sharding.md#cross-partition-checkout-example) |
| Retain backups separately and validate restoration | Replicas can propagate destructive changes | Storage, retention, access controls, and restore procedures require further implementation | [Operational readiness](Madueke_Emmanuel_301912318_replication-availability.md#replication-backup-and-operational-readiness) |

These choices prioritise correct checkout state when safe write ownership or required acknowledgement cannot be established. They do not promise uninterrupted purchasing through every zone failure. In particular, losing the designated synchronous standby can affect checkout even while the primary remains healthy.

## Proposed settings and unresolved assumptions

This is a decision record, **not an executable configuration**. There are no deployed endpoints, credentials, cloud resource identifiers, or configuration exports for this activity.

| Area | Proposed policy or assumption | Still required before deployment |
| --- | --- | --- |
| Placement | One region, three independent zones; application instances across zones | Provider selection, verified failure-domain separation, network design, capacity and cost assessment |
| SQL acknowledgement | Required synchronous standby S plus `synchronous_commit=on`; R asynchronous | Actual standby identity and configuration, durable storage checks, replication security, WAL retention, failure testing |
| SQL recovery | Exclusive authority, fencing, validated promotion, restored synchronous partner, then write routing | Control-plane product, fence mechanism, endpoint/session handling, runbooks and operator ownership |
| MongoDB | Three data-bearing voting members; majority write concern with appropriate journal durability; primary read preference | Replica-set configuration, authentication, driver behaviour, timeout and reconnection tests |
| Read freshness | Recent orders on writer; reports on R only within agreed freshness limits | Numeric limits, monitoring, capacity-aware rerouting and user-facing behaviour |
| Cross-store refresh | Existing fixed-snapshot export/import only | Refresh ownership, version/deletion handling, reconciliation and delay monitoring if live updates are introduced |
| Ambiguous purchases | Reconcile known order state before retrying | Request-level idempotency and real payment-provider reconciliation; current payment outcomes are simulated |
| Recovery objectives | No numerical RPO, RTO, or uptime commitment | Business targets, backup retention/location, restore tests and measured recovery outcomes |

Synchronous WAL flush must not be presented as immediate standby read visibility. Majority acknowledgement must not be presented as every MongoDB member being current. Neither policy establishes freshness between SQL and MongoDB. The earlier analyses link these distinctions to the official documentation.

## Deliverable coverage

| Discussion deliverable | Retained evidence | Status and boundary |
| --- | --- | --- |
| Same case study and chosen path | [Scope and evidence plan](Madueke_Emmanuel_301912318_scope.md) | Completed discussion scope; fashion-store operations retained |
| Replication and availability | [Node roles, acknowledgement, outage responses, and recovery](Madueke_Emmanuel_301912318_replication-availability.md) | Sourced analysis completed; no replica or cloud deployment |
| Consistency and sharding | [Read routes, staleness, shard-key options, and cross-partition checkout](Madueke_Emmanuel_301912318_consistency-sharding.md) | Trade-offs completed; no distributed transaction or shard implementation |
| Architecture | [SVG diagram](diagrams/Madueke_Emmanuel_301912318_proposed-architecture.svg) and [source mapping](Madueke_Emmanuel_301912318_architecture-scenarios.md#scope-and-diagram) | Image supplied, structurally checked and visually reviewed; proposed topology |
| Concrete failure/consistency examples | [Eight scenarios](Madueke_Emmanuel_301912318_architecture-scenarios.md#concrete-scenarios) | Triggers, expected responses, recovery and future validation described; none executed |
| Assumptions, operational responsibilities, references, conclusions | This document and claim-level references in the analyses | Discussion complete; deployment and final submission work remain separate |

## What existing implementation evidence supports

The [PostgreSQL setup](../docs/Madueke_Emmanuel_301912318_setup.md) and [protected checkout demonstration](../portfolio-3-transactions-concurrency/protected-concurrency.md) support the local schema, integrity rules, and single-database concurrency behaviour. They do not prove safe promotion, replica read freshness, or multi-node transaction behaviour.

The [MongoDB implementation](../portfolio-4-nosql/Madueke_Emmanuel_301912318_implementation.md) and [SQL/NoSQL comparison](../portfolio-4-nosql/sql-nosql-comparison.md) support the validated standalone profiles and fixed-snapshot reconciliation contract. They do not prove election recovery, majority acknowledgement, or live cross-store convergence.

The workload is synthetic and the document collection contains three profiles. Those results cannot establish production sizing, cloud cost, or the need for sharding. Personal reflection and claims of student verification must be supplied from Emmanuel's actual experience.

## Reference guide

Detailed claims retain their source links beside the relevant discussion. This index groups the primary references for review; PostgreSQL links target version 18, while MongoDB manual pages may evolve independently of the locally tested 8.0.34 runtime.

| Topic | Official references | Used in |
| --- | --- | --- |
| SQL replication and visibility | [Warm standby](https://www.postgresql.org/docs/18/warm-standby.html), [WAL/commit settings](https://www.postgresql.org/docs/18/runtime-config-wal.html) | Replication, consistency, scenarios 1–3 |
| SQL recovery and backups | [Failover](https://www.postgresql.org/docs/18/warm-standby-failover.html), [Continuous archiving](https://www.postgresql.org/docs/18/continuous-archiving.html) | Recovery policy, scenarios 1, 4, and 8 |
| SQL partitioning | [Declarative partitioning](https://www.postgresql.org/docs/18/ddl-partitioning.html) | Distinguishing table partitioning from distributed sharding |
| MongoDB availability | [Three-member replica sets](https://www.mongodb.com/docs/manual/core/replica-set-architecture-three-members/), [Elections](https://www.mongodb.com/docs/manual/core/replica-set-elections/), [Write concern](https://www.mongodb.com/docs/manual/core/replica-set-write-concern/) | Replica roles, scenario 5 |
| MongoDB reads | [Read preference](https://www.mongodb.com/docs/manual/core/read-preference/), [Causal consistency](https://www.mongodb.com/docs/manual/core/causal-consistency-read-write-concerns/) | Read policy and session requirements |
| MongoDB sharding | [Key selection](https://www.mongodb.com/docs/manual/core/sharding-choose-a-shard-key/), [Hashed sharding](https://www.mongodb.com/docs/manual/core/hashed-sharding/), [Cluster components](https://www.mongodb.com/docs/manual/core/sharded-cluster-components/) | Candidate keys and operating costs |

## Completion and remaining work

This stage consolidates existing sourced analysis; verification is limited to document consistency, local link/anchor checks, and repository whitespace checks. No database runtime tests were added or repeated for this documentation stage.

The next portfolio-wide task is the final assessment-deliverable audit across all five activities. Reproducibility review, the LMS summary, Emmanuel's individual reflection, declaration review, assessor access, and submission remain pending in the local checklist. Completion of this discussion does not mark those tasks complete.
