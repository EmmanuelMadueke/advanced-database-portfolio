# Replication and availability for the fashion store

Owner, author, and maintainer: **Emmanuel Madueke**.

## Status and proposed topology

This is a sourced architecture discussion, not a deployed configuration. The existing evidence covers one local PostgreSQL instance and one standalone MongoDB container. No failover, replica lag, recovery time, or cloud-zone failure has been measured.

Propose three independent availability zones within one region. Zone independence, network connectivity, and sufficient capacity are design assumptions; no cloud provider or service has been selected. A region-wide outage is outside this initial topology's availability scope.

| Proposed component | Initial placement and role | Store operation |
| --- | --- | --- |
| PostgreSQL primary P | Zone A, sole SQL writer | Checkout, payment/order transitions, authoritative stock, recent customer orders |
| PostgreSQL standby S | Zone B, designated synchronous standby and preferred promotion candidate | Durable second copy of acknowledged checkout changes |
| PostgreSQL standby R | Zone C, asynchronous hot standby | Lag-tolerant management reports; additional recovery copy |
| SQL failover control and routing | Independent control-plane participants across the three zones | Exclusive writer ownership, fencing, promotion, and endpoint changes; tooling not yet selected |
| MongoDB M1/M2/M3 | One data-bearing voting member per zone; initially M1 primary | Replicated descriptive product profiles |
| Application service | Proposed instances in more than one zone | Route operations according to required freshness; reconcile uncertain purchase outcomes |
| Backups and manifests | Storage independent of database nodes, with separate retention/access controls | Restore data and reconcile the SQL/MongoDB source relationship |

These labels define roles for the later diagram. Elections or promotion can change the node performing a role. Replicating a database does not synchronise SQL data with MongoDB: the implemented cross-store process remains export/import against a fixed snapshot.

## PostgreSQL replication choice

PostgreSQL streaming replication transfers WAL to standbys; it is asynchronous by default. Hot standbys can serve reads, but asynchronous copies can lag and may lack recent commits after primary loss. This supports using R for reports rather than authorising purchases. [PostgreSQL streaming and standby documentation](https://www.postgresql.org/docs/18/warm-standby.html).

For this proposal, configure S as the required synchronous standby and use synchronous_commit=on for checkout, with durable storage settings retained. With a configured synchronous standby, this mode waits for remote WAL flush before acknowledging commit. It does not wait for replay visibility; remote_apply would add that wait. Setting synchronous_commit alone without a synchronous standby does not create remote durability. [PostgreSQL commit acknowledgement settings](https://www.postgresql.org/docs/18/runtime-config-wal.html#GUC-SYNCHRONOUS-COMMIT).

The selected trade-off is greater commit latency and dependency on S in exchange for a durable second copy of acknowledged purchases. If S or its network path fails, affected commits can wait. Proposed application timeouts must treat the outcome as uncertain until reconciled; a timeout is not proof of rollback. Do not automatically switch checkout to asynchronous acknowledgements. Replacement/standby reconfiguration needs an explicit operational decision and validation.

## SQL failover and writer ownership

PostgreSQL supplies standby promotion, but the surrounding failure detection and failover coordination require additional machinery. A returning old primary must not continue accepting writes against an independently promoted server. PostgreSQL's failover documentation specifically highlights preventing both servers from believing they are primary. [PostgreSQL failover](https://www.postgresql.org/docs/18/warm-standby-failover.html).

The proposed control plane must obtain exclusive authority, fence the old writer at the infrastructure level, and confirm S's recovery position before promotion. A connection check alone cannot distinguish a dead server from a network partition. Route new writes only to the validated new primary; do not reopen checkout if fencing is uncertain. After promotion, establish a healthy synchronous partner before resuming the selected remote-durability policy. Rejoin the former primary only after bringing it into agreement with the new timeline.

R is not an interchangeable promotion target: as an asynchronous replica, it may lack acknowledged changes that reached S. If only R survives, assess recoverable WAL and data loss explicitly instead of claiming lossless failover. No numerical recovery-point or recovery-time guarantee is supported by this design discussion.

## MongoDB replica set and acknowledgement

Propose three data-bearing voting members, one per zone, rather than an arbiter replacing a data copy. MongoDB documents a three-member primary/secondary/secondary layout as a standard replica-set architecture. [Three-member replica sets](https://www.mongodb.com/docs/manual/core/replica-set-architecture-three-members/).

A reachable majority is required to elect a primary. Loss of one member can leave two able to form that majority; loss of two cannot. During election there is a period without a writable primary, and an isolated minority must not be treated as an alternative write authority. This is expected behaviour, not a measured outage duration here. [MongoDB replica-set elections](https://www.mongodb.com/docs/manual/core/replica-set-elections/).

Propose explicit majority write concern for enrichment changes with appropriate journal durability. This reduces exposure to losing acknowledged changes during election compared with primary-only acknowledgement. A majority acknowledgement is not proof that every member is current, nor does it refresh copied SQL fields. The current standalone import did not test these guarantees. [Replica-set write concern](https://www.mongodb.com/docs/manual/core/replica-set-write-concern/).

Use primary read preference initially for enrichment to keep routing simple. If later requirements favour secondary reads for descriptive browsing, accept and expose possible staleness; read preference alone is not a read-after-write or cross-store consistency guarantee. [MongoDB read preference](https://www.mongodb.com/docs/manual/core/read-preference/).

## Expected impact on store operations

The following are proposed responses, not executed failure tests.

| Failure or degradation | Affected operation | Proposed response and residual risk |
| --- | --- | --- |
| SQL primary P is lost | Checkout and authoritative order reads | Pause affected requests, fence P, validate/promote S, restore the synchronous partner and write route. Reconcile uncertain orders before retrying |
| S is unavailable while P remains reachable | Checkout commit acknowledgement | Preserve the chosen synchronous policy; bound client waiting and report uncertain outcomes honestly. Restore S or validate a replacement; no silent durability downgrade |
| R falls behind or is lost | Management reports | Remove R from reporting traffic or label results stale. Route to P only if capacity permits; reports do not approve stock deductions |
| SQL network partition | Writer ownership and checkout | Only the side with validated control authority and a safe database path may serve writes. Fence or pause when that cannot be established |
| MongoDB primary becomes unavailable | Enrichment writes and primary-directed reads | Driver/service waits for an eligible new primary within its timeout policy. SQL checkout remains separate; enrichment outages may reduce browsing detail |
| MongoDB lacks a voting majority | Enrichment writes | Do not claim write availability. A future UI may fall back to SQL's general product description; such a fallback has not been implemented |
| Region-wide outage | Both database services and application | This proposal offers no regional disaster failover. Recovery requires separately retained backups and a further regional recovery design |

Existing SQL checkout still performs stock checks and row locking after failover. Replication does not replace that logic. Likewise, order-ID finalisation replay is narrower than retrying a whole checkout: create_order is not an idempotent request API. Application-level request identity and real payment reconciliation remain future work.

## Replication, backup, and operational readiness

A replica can reproduce an accidental deletion; it is not a retained historical backup. Propose SQL base backups plus WAL archiving for point-in-time recovery, and verify restores before assigning recovery objectives. [PostgreSQL continuous archiving and recovery](https://www.postgresql.org/docs/18/continuous-archiving.html). Curated enrichment, SQL exports, and manifests also need retained versions. The current three profiles can be rebuilt from those inputs, but unexported future edits would need their own backup policy.

Before deployment, operators would need to select and validate the failover/control-plane tool, separate failure domains, secure replication connections, monitor WAL retention and replica progress, monitor MongoDB member/majority health, and test application reconnect behaviour. Proposed measurements include checkout acknowledgement latency, detection/promotion/reconnection times, observed data loss, and restore results. None has been collected here, so this document makes no uptime SLA or zero-loss guarantee across arbitrary failures.

Next: analyse consistency and sharding in detail, including replica lag, customer order visibility, partition keys, and multi-variant checkout across partitions. The architecture diagram and consolidated failure scenarios remain subsequent deliverables.
