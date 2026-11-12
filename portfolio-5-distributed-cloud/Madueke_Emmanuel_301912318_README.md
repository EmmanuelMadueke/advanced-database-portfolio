# Portfolio 5 — Distributed and Cloud Database Exercise

Owner, author, and maintainer: **Emmanuel Madueke**.

## Current stage

**Selected path: a sourced distributed/cloud architecture discussion for the existing online fashion store.** The [scope and evidence plan](Madueke_Emmanuel_301912318_scope.md) defines the architecture questions, assumptions, and deliverables.

This completed discussion builds on the implemented PostgreSQL checkout and MongoDB catalogue enrichment. Replication, failover, and sharding are proposed discussion topics; no distributed deployment has been created or tested for this activity.

## Activity checklist

- [x] Choose a discussion or practical setup path.
- [x] Explain replication and availability, including outage/failover behaviour.
- [x] Explain consistency and sharding, including stock and customer-order visibility.
- [x] Produce a sourced architecture diagram and concrete failure scenarios.
- [x] Consolidate design assumptions, operational trade-offs, references, and conclusions.

The [replication and availability analysis](Madueke_Emmanuel_301912318_replication-availability.md) now defines proposed node roles, acknowledgement choices, failover safeguards, and outage responses using official sources.

The [consistency and sharding analysis](Madueke_Emmanuel_301912318_consistency-sharding.md) now explains read routes, replica versus cross-store staleness, candidate keys, and the cost of splitting checkout across partitions. The proposed initial deployment remains unsharded.

The [architecture diagram and eight concrete scenarios](Madueke_Emmanuel_301912318_architecture-scenarios.md) now show the proposed topology, safe recovery policies, and future validation needs. No distributed failure scenario has been executed.

The [conclusions and evidence coverage](Madueke_Emmanuel_301912318_conclusions.md) consolidate decisions, proposed settings, unresolved operational requirements, and official references. **Portfolio 5 is complete for the discussion path.**

The [assessment audit](../docs/Madueke_Emmanuel_301912318_assessment-audit.md) now maps all five activities to the brief. Next: final reproducibility review; summary, reflection, and submission remain pending.

## Existing evidence used as the starting point

- [Relational database setup](../docs/Madueke_Emmanuel_301912318_setup.md)
- [Protected last-unit checkout](../portfolio-3-transactions-concurrency/protected-concurrency.md)
- [MongoDB implementation](../portfolio-4-nosql/Madueke_Emmanuel_301912318_implementation.md)
- [SQL/NoSQL comparison and synchronisation limits](../portfolio-4-nosql/sql-nosql-comparison.md)

Those activities establish local database behaviour. They do not establish multi-node availability, recovery times, replica consistency, or cloud deployment.

## Screenshot evidence

See the [assessment screenshot gallery](../evidence/screenshots/Madueke_Emmanuel_301912318_README.md) for captures of retained outputs and diagrams. Captures are labelled separately from the original execution dates; Portfolio 5 remains a discussion.
