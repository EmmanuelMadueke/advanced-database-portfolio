# AI-use Working Record

Project owner, author, and maintainer: **Emmanuel Madueke**.

## Requirements and modelling

Codex helped interpret the assessment brief and fashion-store case study, organise the portfolio checklist, and draft requirements, business rules, and proposed entities/attributes. It checked the drafts for consistency with the supplied case study.

## Entity relationship diagram

Codex drafted the ERD from the requirements and business rules, including attributes, proposed primary/foreign keys, and crow’s-foot relationships. It checked the 16 entities and 15 direct relationships, SVG structure, and document links. The table-style rendering was visually inspected, and the relationship summary footer was checked structurally.

Emmanuel Madueke supplied a reference diagram to guide the table-style presentation, reviewed the revised appearance, and requested an explicit summary of relationship ratios and optionality. He also required progressive development records and GitHub commits to support the assessment's evidence requirements.

## Relational schema and data dictionary

Codex mapped the ERD to 16 PostgreSQL tables and specified column types, defaults, nullability, keys, uniqueness, deletion policies, and row checks. It documented planned transaction routines and triggers for cross-table totals, payment consistency, inventory, and lifecycle rules, consulting official PostgreSQL documentation. Documentation checks compared table/column coverage with the entity inventory and checked local links. These checks do not establish database runtime correctness.

## PostgreSQL implementation and checks

Codex created table definitions, integrity/lifecycle triggers, controlled purchase/cart/delivery functions, and demonstration-role permissions. It verified them on an isolated PostgreSQL 18.1 cluster using temporary synthetic fixtures. All 35 single-session assertions passed, covering invalid writes, snapshots, purchase finalisation/replay, delivery states, and rollback. Actual output and reproduction instructions are saved in Portfolio 1. These are tool-run checks; no independent student runtime verification is asserted.

## Sample data and reconciliation

Codex drafted synthetic fashion-store seed data covering stock, carts, order states, payment outcomes/retries, and deliveries, using the implemented write routines. It ran 10 sample checks against a fresh PostgreSQL 18.1 database, reconciling inventory and NGN 268,000.00 in successful sales. An optional 10,000-order synthetic workload passed four additional count/total/payment/stock checks. Scripts, actual outputs, reproduction steps, and distribution/timestamp limitations are documented. These datasets contain no real customer records and do not establish performance conclusions.

## Portfolio 2 query development

Codex drafted twelve read-only SQL reports covering catalogue filters, stock, customer history, open orders, deliveries, sales, and unresolved payments. It used pre-aggregated payment attempts to avoid duplicate history rows and historical monetary values for revenue, with explicit Lagos calendar boundaries. Thirty tool-run result checks passed on the unscaled sample dataset, including NGN 268,000 reconciliation, retries, empty periods, endpoint and timezone checks, and literal input handling. Actual output and reproduction instructions are saved in Portfolio 2. Execution plans and optimisation measurements are recorded in the subsequent stages below.

## Portfolio 2 baseline plans

Codex collected five repeated measured EXPLAIN (ANALYZE, BUFFERS, TIMING OFF, FORMAT JSON) plans for each of five reports, with warm-ups, on the default scale dataset. It recorded server/settings, exact row counts, statistics, all existing index definitions, result fingerprints, and per-run measurements. Independent successful payments reconciled to NGN 36,908,000.00. The baseline notes identify history scans and sales-row estimate differences without claiming an optimisation improvement. Cache, timing instrumentation, sample distribution, and host-noise limitations are documented.

## Portfolio 2 optimisation

Codex used the captured plans to select three reporting indexes and a lateral customer-history rewrite. It rebuilt the unavailable temporary database and captured a fresh baseline, indexes-only phase, and rewrite phase under matching conditions. All five ordered-result fingerprints matched; 30 sample checks and seven varied history comparisons passed. It documented measured plan/buffer changes, index sizes, unmeasured write costs, and the visibility/cache limitations of the experiment. No improvement was attributed to unchanged catalogue/open-order plans solely from timing variation.

Emmanuel directed progression through the checklist and required README/checklist updates so completed work and the next assessment task stay clear. Independent student review of these performance findings has not yet been recorded.

## Portfolio 3 transaction boundary

Codex reviewed the existing checkout functions, integrity triggers, writer permissions, and integrity test source, then documented a single transaction around order creation, simulated successful payment, and inventory deductions. It distinguished rollback of a new purchase from failure to finalise a previously committed pending order, and recorded deferred validation, lock ordering, replay limits, cart exclusions, and the external-payment boundary. PostgreSQL documentation was used to check transaction, constraint, and locking semantics. This stage supplies expected outcomes for subsequent demonstrations; no new runtime or student verification is claimed.

## Verification status

Emmanuel's recorded review covers the ERD presentation. Independent student verification remains to be recorded after it occurs. Schema installation and the documented single-session integrity/workflow checks have passed. Sample and optional scale data have been loaded and reconciled by tool-run checks. Baseline execution plans and repeated local measurements are recorded. Optimisation comparisons and result-equivalence checks have passed. Two-session concurrency evidence remains pending.

## Sources

- MIT 8103 Advanced Database Systems continuous assessment brief, September cohort 2026 (local PDF in guide/).
- Repository case study, README, requirements, business rules, and entity inventory.

- PostgreSQL documentation: [constraints](https://www.postgresql.org/docs/18/ddl-constraints.html), [numeric types](https://www.postgresql.org/docs/18/datatype-numeric.html), [date/time types](https://www.postgresql.org/docs/18/datatype-datetime.html), and [partial indexes](https://www.postgresql.org/docs/18/indexes-partial.html).

- PostgreSQL 18 documentation: [psql](https://www.postgresql.org/docs/18/app-psql.html), [date/time functions](https://www.postgresql.org/docs/18/functions-datetime.html), and [transaction isolation](https://www.postgresql.org/docs/18/transaction-iso.html).

- PostgreSQL 18 documentation: [EXPLAIN](https://www.postgresql.org/docs/18/sql-explain.html), [reading plans](https://www.postgresql.org/docs/18/using-explain.html), and [ANALYZE](https://www.postgresql.org/docs/18/sql-analyze.html).
