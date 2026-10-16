# SQL and NoSQL suitability for the fashion store

Owner, author, and maintainer: **Emmanuel Madueke**.

## Decision supported by this portfolio

Retain PostgreSQL as the authoritative store for products/variants, prices, inventory, customers, orders, payments, and deliveries. Use the implemented MongoDB profiles to demonstrate structured catalogue enrichment: composition and care for clothing, materials and fastening for footwear, and features/dimensions for accessories.

This division follows the verified workloads, not a general claim that SQL is rigid or NoSQL lacks transactions. MongoDB works for the descriptive use case, but this small portfolio does not establish that operating a second database is necessary for a production store.

## Comparison grounded in the implementation

| Concern | PostgreSQL implementation | MongoDB implementation | Implication for this store |
| --- | --- | --- | --- |
| Structure and flexibility | Sixteen related tables represent shared facts, variants, and transactional entities | Three product profiles use common fields and separate validated attribute branches | Nested attributes fit descriptive reads; new attributes still need deliberate validation/version changes |
| Integrity | Keys, CHECK constraints, lifecycle guards, deferred consistency triggers, and controlled routines | Strict/error collection validator, unique `_id`, importer business checks, and export reconciliation | Choose the enforcement layer explicitly; flexible documents are not uncontrolled documents |
| Atomic business operation | Checkout groups order, items, stock, and simulated payment in one transaction | Initial profile import is a sequence of collection/insertion operations | The implemented import is not an all-or-nothing checkout replacement |
| Concurrency | Two buyers compete for one unit; row locking/rechecking permits one purchase and rolls back the loser | Profile validation and reads were tested; no competing MongoDB writers were demonstrated | Checkout safety is supported by the SQL experiment, not inferred from either database label |
| Reference integrity | Foreign keys connect related SQL entities | String `_id` refers to an exported SQL product; no cross-store foreign key exists | Import and reconciliation must detect missing, ambiguous, or orphan references |
| Duplication | Shared brand/category facts reside in related tables; purchase snapshots deliberately preserve history | Name/category/brand/audience/active status are copied into profiles | Browsing context can become stale; MongoDB copies are not live purchasing authority |
| Queries | Joins and aggregates support history, stock, revenue, and fulfilment | Nested predicates, `$elemMatch`, and a tag aggregation support descriptive selection | Each demonstrated query answers its own business question; tag coverage is not sales reporting |
| Index trade-offs | Scale-dataset experiments measured targeted history/revenue changes | Composition index exists, but automatic planning retained the identity-index scan on three profiles | Index usefulness depends on workload; the two experiments are not a comparable performance benchmark |
| Operations | SQL schema/routines, permissions, and reproducible seed scripts | Additional Docker runtime, validator, curated input, export, loader, manifest, and reconciliation | Two stores add operational work as well as modelling choice |

The [SQL schema and tests](../portfolio-1-database-design/README.md), [SQL query experiments](../portfolio-2-query-optimisation/optimisation/README.md), [protected checkout](../portfolio-3-transactions-concurrency/protected-concurrency.md), [MongoDB implementation](implementation.md), and [MongoDB query evidence](queries/README.md) support these project-specific observations.

## What the checks establish

The protected PostgreSQL checkout passed eleven controlled concurrency checks: B waited for A, then rejected depleted stock and rolled back. One order/payment remained and finalisation replay did not deduct stock again. This verifies the documented last-unit schedule, not all schedules or deadlock freedom.

The MongoDB load passed ten importer checks, ten database rejection checks, two reconciliation checks, and four fresh-connection checks. Database rejection included a missing name, incompatible category, forbidden stock field, negative dimension, duplicate identity, and invalid update. The importer separately enforced whole composition totals, canonical material labels, and bigint identity rules. A direct writer bypassing the importer would not inherit all importer-only guarantees.

Sixteen query/index checks verified five finds, one aggregation, boundary/empty results, and unchanged data/results after index creation. A further diagnostic check verified hinted-result equivalence. In the shirt profile, cotton is 95% and elastane 5%: independent array predicates can falsely match elastane>=90, while `$elemMatch` correctly returns no result. Document modelling still requires careful query semantics.

The unhinted composition query examined three keys and three documents both before and after index creation. An explicit diagnostic hint examined one key/document but added a sort. The new index occupied 20,480 bytes in the fixture. These observations establish an available access path, not a measured production speedup. SQL's larger performance dataset and MongoDB's three-profile fixture cannot establish which database is faster.

## Consistency and synchronisation as implemented

The export captures all eight SQL products in one read-only statement snapshot. The loader selects exactly the three intended product/brand/category matches, uses their actual IDs as strings, and imports copied SQL context alongside curated enrichment. Example design IDs are not trusted: the real IDs differed. The manifest records source/enrichment/validator hashes, actual timestamps, selected IDs, target database, and counts. A fresh connection verified persisted profiles against these inputs.

This is **snapshot consistency with the recorded export**. There is no automatic refresh, event consumer, scheduled reconciliation, or guarantee that a later SQL change will reach MongoDB. Describing it simply as eventual consistency would imply convergence that has not been implemented.

| Later SQL change | Effect on current profile | Required maintenance / intended application behaviour |
| --- | --- | --- |
| Rename product or brand | Copied label stays old | Produce a fresh export and rebuild/reconcile a disposable target; in-place refresh is not implemented |
| Reclassify a product | Category and attribute branch may conflict | Review enrichment and validate the new branch before importing |
| Deactivate/delete a product | Existing profile may still appear active or reference an absent row | Reconcile the selected source set; live SQL checks must govern purchasing |
| Change price or sell stock | No such values are copied into profiles | Retrieve and validate them through SQL at checkout |
| Rebuild SQL and reuse generated IDs | Old numeric-looking IDs may identify different products | Treat the export as a new dataset; use a fresh target and manifest, not name-based silent remapping |

The current loader deliberately refuses an existing collection, supporting an auditable initial load rather than pretending to implement safe updates. A failed import can leave partial data and requires inspection/new disposable-target reproduction. PostgreSQL and MongoDB do not share an atomic transaction in this implementation. A production refresh process and application fallback behaviour remain designs, not tested features.

## Transaction capability is not the dividing line

MongoDB documents atomic single-document writes and also supports multi-document transactions in suitable replica-set or sharded deployments. The current standalone container does not demonstrate those deployments or transactions. Keeping checkout in PostgreSQL follows the existing tested implementation and avoids a new cross-store consistency problem; it is not a claim that MongoDB cannot support transactional workloads. [MongoDB atomicity and transactions](https://www.mongodb.com/docs/manual/core/write-operations-atomicity/).

Likewise, PostgreSQL supports structured JSONB values, JSON operators, and indexes. A product-enrichment table linked by product_id, with JSONB attributes and appropriate checks, is a credible single-database alternative. That could avoid cross-store product references and a second runtime while retaining flexible descriptions. Such an alternative has not been implemented or benchmarked here. [PostgreSQL JSON types](https://www.postgresql.org/docs/18/datatype-json.html).

## Suitability conclusion and limits

MongoDB successfully demonstrated bounded embedded profiles, server validation, nested/array queries, aggregation, and a compound multikey index. PostgreSQL successfully demonstrated the relational business model, reporting, and protected checkout. The portfolio therefore retains their assigned roles for the assessment.

For a production decision at this small scale, prefer the simpler existing PostgreSQL system unless independent catalogue requirements justify the operational cost of MongoDB. That is an architectural judgement from the demonstrated complexity, not a performance measurement. No cloud availability, sharding, failover, live synchronisation, or independent student verification has been established by Portfolio 4. Those boundaries are explicit in the [evidence and reproduction](README.md#evidence-coverage) rather than being presented as completed capabilities.
