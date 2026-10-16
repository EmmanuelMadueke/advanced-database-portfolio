# Portfolio 5 — Distributed and Cloud Database Exercise

Owner, author, and maintainer: **Emmanuel Madueke**.

## Current stage

**Selected path: a sourced distributed/cloud architecture discussion for the existing online fashion store.** The [scope and evidence plan](scope.md) defines the architecture questions, assumptions, and deliverables.

This activity will build on the implemented PostgreSQL checkout and MongoDB catalogue enrichment. Replication, failover, and sharding are proposed discussion topics; no distributed deployment has been created or tested for this activity.

## Activity checklist

- [x] Choose a discussion or practical setup path.
- [x] Explain replication and availability, including outage/failover behaviour.
- [ ] Explain consistency and sharding, including stock and customer-order visibility.
- [ ] Produce a sourced architecture diagram and concrete failure scenarios.
- [ ] Consolidate design assumptions, operational trade-offs, references, and conclusions.

The [replication and availability analysis](replication-availability.md) now defines proposed node roles, acknowledgement choices, failover safeguards, and outage responses using official sources.

Next: explain consistency and sharding, including replica lag, customer order visibility, and cross-partition checkout.

## Existing evidence used as the starting point

- [Relational database setup](../docs/setup.md)
- [Protected last-unit checkout](../portfolio-3-transactions-concurrency/protected-concurrency.md)
- [MongoDB implementation](../portfolio-4-nosql/implementation.md)
- [SQL/NoSQL comparison and synchronisation limits](../portfolio-4-nosql/sql-nosql-comparison.md)

Those activities establish local database behaviour. They do not establish multi-node availability, recovery times, replica consistency, or cloud deployment.
