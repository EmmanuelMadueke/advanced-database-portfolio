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

## Portfolio 3 COMMIT demonstration

Codex created isolated synthetic fixtures, an explicit checkout transaction using the controlled writer role, and a separate-connection verifier. It ran them on PostgreSQL 18.1: eight assertions passed for the NGN 49,000 order, two lines and snapshots, matching successful payment, and exact stock deductions. An initial missing required fixture description was corrected; both the failed setup output and successful outputs are retained. The demonstration verifies committed state through a fresh connection, not crash recovery or concurrency. No independent student verification is claimed.

## Portfolio 3 ROLLBACK demonstration

Codex reused the synthetic fixture in a separate database and injected a SQL exception after simulated checkout finalisation, before COMMIT. It recorded the uncommitted order/payment and stock deductions, checked the expected SQLSTATE, issued explicit ROLLBACK, and verified persisted state through a fresh connection. Six assertions passed: no purchase rows remained, both stock balances were restored, and committed fixtures remained. Documentation distinguishes this injected failure from insufficient stock, external payment reversal, and concurrent-session evidence. No independent student verification is claimed.

## Portfolio 3 two-session isolation

Codex created a standard-library Python coordinator for two persistent psql connections and separate SQL for the writer, observer, and shared snapshot query. Seven tool-run checks passed at READ COMMITTED: the observer saw no uncommitted checkout changes and then saw the complete purchase after the writer committed, within the observer's same transaction. Completion markers controlled ordering without sleep-based timing. Actual session output and manual reproduction steps are retained. This verifies visibility, not competing-writer safety or independent student review.

## Portfolio 3 controlled concurrency issue

Codex created an isolated unsafe stock/allocation model and coordinated two READ COMMITTED buyers so both read the last unit before either wrote. Eight checks confirmed two committed purchases with final stock zero from an initial one, including verification in a fresh connection. It documented the stale-read lost deduction, why nonnegative stock alone misses overselling, and the distinction from the protected retail routines. The existing session coordinator was made importable without executing its isolation experiment. Actual SQL, session output, and manual reproduction steps are retained; the corrected concurrent comparison remains pending.

## Portfolio 3 protected concurrency

Codex exercised the existing inventory-locking checkout with two buyers in a fresh database. A monitoring connection confirmed that B waited on A before A committed. Eleven checks passed for stock-depletion rejection, full loser rollback, one successful purchase, stock conservation, and unchanged state when replaying the known paid order. It retained actual output and documented the comparison with the simplified unsafe model, the difference between business rejection and transient-error retries, and untested broader schedules. No new checkout implementation or independent student verification is claimed.

## Portfolio 4 NoSQL use-case selection

Codex reviewed the fashion-store case study and existing relational catalogue, then selected MongoDB product enrichment for category-specific materials, care, and descriptive features. It documented the proposed boundary with PostgreSQL, synthetic-data assumptions, planned export/load reconciliation, and the PostgreSQL JSONB alternative using official documentation. This is a sourced design decision; MongoDB runtime setup and implementation remain unverified.

## Portfolio 4 document model

Codex designed one enrichment profile per SQL product, string-preserved bigint identifiers, embedded category-specific attributes, and a candidate MongoDB JSON Schema validator. Three synthetic examples cover clothing, footwear, and accessories. It separated database validation from importer-only business checks and SQL-reference reconciliation, documented units and refresh rules, and consulted MongoDB's supported validation keywords. Local JSON/document checks do not establish MongoDB runtime validation; no server insertion or student verification is claimed.

## Portfolio 4 implementation and population

Codex verified Docker/MongoDB, installed the strict validator, exported actual SQL product identities, and loaded three synthetic enrichment profiles. Ten importer checks, ten MongoDB rejection checks, two reconciliation checks, and four fresh-connection checks passed. It saved input hashes, actual versions/timestamps, stored BSON, and execution outputs. The import resolved source IDs that differed from illustrative examples. Logging, asynchronous update-error handling, and cross-context comparison issues in the harness were corrected with diagnostic outputs retained. This verifies snapshot loading and validation, not live synchronisation or independent student review.

## Portfolio 4 queries, aggregation, and index

Codex implemented five catalogue predicates and a tag-coverage aggregation, executing the shared definitions in 16 checks. Tests covered same-element material/percentage semantics, boundaries, empty results, and unchanged documents/results after adding a compound multikey index. The automatic planner retained the identity-index scan on three profiles; a separately labelled hinted diagnostic scanned one document and passed result equivalence. Actual plans, index sizes, outputs, and limitations are retained. No production speedup or student verification is claimed.

## Verification status

Emmanuel's recorded review covers the ERD presentation. Independent student verification remains to be recorded after it occurs. Schema installation and the documented single-session integrity/workflow checks have passed. Sample and optional scale data have been loaded and reconciled by tool-run checks. Baseline execution plans and repeated local measurements are recorded. Optimisation comparisons and result-equivalence checks have passed. Two-session READ COMMITTED visibility checks have passed. An isolated unsafe two-buyer race has reproduced overselling. The protected concurrent comparison passed eleven checks, including confirmed blocking and a single successful buyer.

## Sources

- MIT 8103 Advanced Database Systems continuous assessment brief, September cohort 2026 (local PDF in guide/).
- Repository case study, README, requirements, business rules, and entity inventory.

- PostgreSQL documentation: [constraints](https://www.postgresql.org/docs/18/ddl-constraints.html), [numeric types](https://www.postgresql.org/docs/18/datatype-numeric.html), [date/time types](https://www.postgresql.org/docs/18/datatype-datetime.html), and [partial indexes](https://www.postgresql.org/docs/18/indexes-partial.html).

- PostgreSQL 18 documentation: [psql](https://www.postgresql.org/docs/18/app-psql.html), [date/time functions](https://www.postgresql.org/docs/18/functions-datetime.html), and [transaction isolation](https://www.postgresql.org/docs/18/transaction-iso.html).

- PostgreSQL 18 documentation: [EXPLAIN](https://www.postgresql.org/docs/18/sql-explain.html), [reading plans](https://www.postgresql.org/docs/18/using-explain.html), and [ANALYZE](https://www.postgresql.org/docs/18/sql-analyze.html).
