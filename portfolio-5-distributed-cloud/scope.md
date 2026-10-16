# Portfolio 5 scope and evidence plan

Owner, author, and maintainer: **Emmanuel Madueke**.

## Assessment path

Choose the **discussion path**. Section 4 of the supplied MIT 8103 assessment brief permits a distributed/cloud database discussion or setup using the same case study, with replication, sharding, availability, consistency, or deployment evidence. The brief is retained locally in the ignored guide directory as mit-8103-advanced-database-systems-ca-september-cohort-2026.pdf. This activity will address all four named architecture topics; a hosted service is not required for the selected path.

The discussion will consider a proposed cloud deployment of the same fashion store. PostgreSQL remains authoritative for stock, prices, orders, payments, and deliveries. MongoDB remains an enrichment store for descriptive product profiles. No new business scenario is introduced.

## Why this path

Portfolios 1–4 already retain practical relational design, query, transaction/concurrency, and document-database evidence. Portfolio 5 adds a reasoned analysis of behaviour across database nodes and failures. A local replication setup would provide useful runtime evidence but would not itself establish cloud failure-domain separation or production availability. A hosted setup would introduce provider configuration and operating assumptions beyond the existing local environment.

The selected discussion path allows these trade-offs to be examined explicitly without presenting an untested cloud service as a completed deployment. This choice is based on the permitted assessment scope, not a claim that distributed implementation is unnecessary in a real store.

## Starting facts and proposed design boundary

| Area | Verified starting point | Discussion to develop |
| --- | --- | --- |
| SQL checkout | One local PostgreSQL 18.1 instance; controlled checkout, rollback, visibility, and last-unit locking demonstrated | Proposed primary/standby roles, read routing, recovery, and write ownership during failure |
| Catalogue enrichment | One local standalone MongoDB 8.0.34 container; validated profiles and queries demonstrated | Proposed replica-set roles and descriptive-read availability |
| Cross-store data | Explicit SQL export and MongoDB initial load; snapshot reconciliation only | How stale descriptions affect browsing, and what a future refresh mechanism would need |
| Scale | Synthetic SQL workload and three MongoDB profiles | Whether partitioning is warranted, candidate shard keys, and cross-partition costs |
| Cloud | No cloud account, managed database, or multi-zone deployment configured | Provider-neutral placement across proposed failure domains and associated assumptions |

The final diagram must distinguish proposed components from the existing local implementations. Adding replicas in a diagram does not constitute evidence of successful replication or failover.

## Business assumptions

- Checkout correctness takes priority over accepting a purchase when authoritative stock cannot be safely confirmed.
- Descriptive catalogue content may tolerate some staleness, but prices and stock must be checked through the authoritative checkout path.
- Customers should receive a clear outcome when a purchase is rejected or its commit result is uncertain; successful response handling must not cause duplicate orders or deductions.
- No measured uptime target, recovery-time objective, recovery-point objective, or production workload has been supplied. Any illustrative target must be labelled as an assumption, not a measured guarantee.
- External payment processing remains outside database rollback. The existing routines simulate payment outcomes; real provider reconciliation would require additional application design.
- No requirement currently establishes a need for sharding. The discussion must evaluate the cost of adding it, including transactions involving multiple variants.

## Planned deliverables and review criteria

| Deliverable | What it must explain | Appropriate evidence |
| --- | --- | --- |
| Replication and availability analysis | SQL write/read roles, MongoDB replica roles, failure detection, failover, and behaviour during outages | Official documentation, explicit assumptions, and a component/role mapping |
| Consistency and sharding analysis | Replica lag, read-after-write visibility, stock protection, candidate partition keys, and multi-item checkout | Concrete fashion-store examples and justified trade-offs |
| Architecture diagram | Proposed database nodes, read/write paths, failure domains, and enrichment refresh boundary | Diagram with an explanation and source references; no deployed-status labels |
| Failure scenarios | Primary outage, stale replica, connectivity loss, and uncertain checkout outcome | For each: trigger, affected operation, expected proposed response, risk, and recovery step |
| Conclusions | What the design can reasonably offer, operational responsibilities, and what remains unverified | Traceable references and clear limits rather than fabricated test outputs |

The later analysis should compare asynchronous and synchronous replication choices where relevant, distinguish replication from backup/recovery, and explain how a proposed failover prevents two active writers. It should avoid treating a cloud label as an availability guarantee or assuming that a replica removes the need for transaction controls.

## Source and evidence policy

Use official PostgreSQL and MongoDB documentation for database behaviour. If a provider-specific service becomes necessary to explain a claim, cite its official documentation and label the service as an example rather than an installed resource. Record references next to the claims they support.

Existing portfolio outputs can support statements about the local implementations only. Scenario outcomes in Portfolio 5 will be labelled proposed or expected until actually tested. This activity will not invent screenshots, configuration exports, measurements, failure logs, or personal verification. No runtime changes are needed to complete this first scope-selection item.

Next: write the replication and availability analysis, then develop consistency/sharding and the final architecture/failure-scenario evidence in subsequent checklist stages.
