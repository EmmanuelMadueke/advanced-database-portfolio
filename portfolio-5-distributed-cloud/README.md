# Portfolio 5 — Distributed and Cloud Database Exercise

Owner, author, and maintainer: **Emmanuel Madueke**.

## Current stage

**Selected path: a sourced distributed/cloud architecture discussion for the existing online fashion store.** The [scope and evidence plan](scope.md) defines the architecture questions, assumptions, and deliverables.

This activity will build on the implemented PostgreSQL checkout and MongoDB catalogue enrichment. Replication, failover, and sharding are proposed discussion topics; no distributed deployment has been created or tested for this activity.

## Activity checklist

- [x] Choose a discussion or practical setup path.
- [x] Explain replication and availability, including outage/failover behaviour.
- [x] Explain consistency and sharding, including stock and customer-order visibility.
- [x] Produce a sourced architecture diagram and concrete failure scenarios.
- [ ] Consolidate design assumptions, operational trade-offs, references, and conclusions.

The [replication and availability analysis](replication-availability.md) now defines proposed node roles, acknowledgement choices, failover safeguards, and outage responses using official sources.

The [consistency and sharding analysis](consistency-sharding.md) now explains read routes, replica versus cross-store staleness, candidate keys, and the cost of splitting checkout across partitions. The proposed initial deployment remains unsharded.

The [architecture diagram and eight concrete scenarios](architecture-scenarios.md) now show the proposed topology, safe recovery policies, and future validation needs. No distributed failure scenario has been executed.

Next: consolidate design assumptions, operational trade-offs, references, and conclusions.

## Existing evidence used as the starting point

- [Relational database setup](../docs/setup.md)
- [Protected last-unit checkout](../portfolio-3-transactions-concurrency/protected-concurrency.md)
- [MongoDB implementation](../portfolio-4-nosql/implementation.md)
- [SQL/NoSQL comparison and synchronisation limits](../portfolio-4-nosql/sql-nosql-comparison.md)

Those activities establish local database behaviour. They do not establish multi-node availability, recovery times, replica consistency, or cloud deployment.
