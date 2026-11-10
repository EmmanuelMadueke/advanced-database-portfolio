# Optimisation findings

Owner, author, and maintainer: **Emmanuel Madueke**.

Three reporting indexes and a customer-history rewrite were tested on PostgreSQL 18.1 with 10,012 orders, 10,017 order items, 2,512 payments, and 1,218 variants. The original 28 correctness indexes remain intact. This completes the Portfolio 2 optimisation experiment; results describe this synthetic local workload.

## Changes and reasons

[apply_indexes.sql](apply_indexes.sql) installs three optional reporting indexes. [rollback_indexes.sql](rollback_indexes.sql) removes only those indexes.

| Index | Purpose | Measured size |
| --- | --- | --- |
| reporting_orders_customer_history | Find orders by customer, with creation time and ID available in history order | 416 KiB |
| reporting_payments_order | Find attempts by order; INCLUDE status and provider_reference supplies history aggregates | 160 KiB |
| reporting_orders_paid_date | Search paid_at among paid/processing/dispatched/delivered orders; INCLUDE order_id and total_amount supports sales reports | 120 KiB |

The history index changed the orders access to a bitmap lookup of ten customer orders; the measured plan still sorts the result. No sort-elimination benefit is claimed. With indexes alone, the original history query still aggregates all 2,512 payments. [03_customer_history.sql](03_customer_history.sql) instead uses a LEFT JOIN LATERAL aggregate for each selected order. It preserves one row per order, failed-attempt counts, successful references, and zero-attempt output while letting the payment index serve ten small lookups. The original SQL remains in sql/ for comparison; use the optimisation file explicitly to run the rewrite.

PostgreSQL documents [LATERAL evaluation](https://www.postgresql.org/docs/18/queries-table-expressions.html) and [partial-index predicate matching](https://www.postgresql.org/docs/18/indexes-partial.html). The paid-date index uses the same eligible statuses as these reports. A broader status query cannot assume that this partial index contains all required rows.

## Controlled comparison

The October 10 temporary database was no longer available. A fresh dataset was loaded on October 13, 2026, and VACUUM (ANALYZE) ran once before the new baseline. The same database, data, statistics, and settings were then used for all three phases, without another vacuum/statistics refresh between them. The older baseline remains historical evidence; its timings and timestamp-dependent result fingerprints are not the comparison baseline here.

Each phase has one warm-up and five measured runs per query. Values below are median execution milliseconds, with observed min–max in parentheses. All phases use warm caches and EXPLAIN instrumentation; host activity is uncontrolled.

| Report | Before | Indexes only | Indexes + history rewrite |
| --- | --- | --- | --- |
| Catalogue | 0.616 (0.593–0.619) | 0.614 (0.604–0.620) | 0.605 (0.592–0.611) |
| Customer history | 1.380 (1.311–1.609) | 0.635 (0.622–0.671) | 0.109 (0.105–0.120) |
| Open orders | 3.664 (3.518–5.795) | 3.160 (3.080–3.250) | 3.169 (3.043–3.496) |
| Best-selling variants | 3.758 (3.535–3.865) | 2.715 (2.592–2.792) | 2.747 (2.663–2.839) |
| Revenue summary | 1.049 (0.980–1.223) | 0.196 (0.186–0.199) | 0.194 (0.185–0.210) |

History's final median is 92.1% lower; revenue's is 81.5% lower. These are observed local changes, not production guarantees. Index-only and final phases differ in SQL only for history; variations in the other reports do not measure an effect of that rewrite.

| Report | Root shared-buffer hits, before → final | Plan interpretation |
| --- | --- | --- |
| Catalogue | 1,626 → 1,626 | Same access strategy; timing variation does not establish improvement |
| History | 597 → 43 | Full orders/payment scans replaced by customer-order lookup and payment index-only scans; indexes alone used 89 hits |
| Open orders | 541 → 541 | Same broad scan strategy; no demonstrated index benefit |
| Best-selling variants | 702 → 197 | Paid orders use the partial index; all 10,017 order items still scanned |
| Revenue | 520 → 15 | Index-only access returns 2,508 eligible paid orders rather than scanning all 10,012 orders |

Buffer figures are from the first measured run and are inclusive root counts, not sums of plan nodes. The recorded payment and paid-date index-only scans have zero heap fetches. The initial vacuum made this read-mostly experiment favourable to index-only access. Under writes, visibility changes can require heap fetches; PostgreSQL explains this dependency in its [index-only scan documentation](https://www.postgresql.org/docs/18/indexes-index-only-scans.html). Indexes do not automatically correct the seed's correlated-data row-estimate errors.

## Correctness and trade-offs

All five complete ordered-result fingerprints and row counts match across phases. Thirty checks passed on a separate unscaled sample database with the history override. Seven original-versus-rewrite cases also matched on the scale database, covering retries, no attempts, pending payments, paid history, and an absent customer. These are tool-run checks, not a claim of independent student verification or proof for every possible dataset.

The three indexes occupy 712,704 bytes (696 KiB) in this fixture. They add insertion/update work, WAL, and maintenance requirements. Orders enter the paid partial index when payment succeeds; relevant status/date/total changes can require maintenance. Included payment status/reference values also cost space and update work. Write latency and WAL volume were not benchmarked. A customer with a very large history may benefit less from repeated lateral lookups than this ten-order example.

Retain all three as optional reporting indexes for the demonstrated workload and retain the targeted history rewrite. No additional catalogue or broad-open-order index was justified by this experiment. Existing variant keys already support joins; adding duplicate indexes would incur costs without demonstrated benefit. Future production decisions need varied date distributions, concurrent writes, larger histories, and workload-specific measurements.

## Reproduce

From the repository root, use [setup instructions](../../docs/setup.md) to create a fresh database and load Portfolio 1 scripts 01–06 in order. Configure PGHOST, PGPORT, PGDATABASE, PGUSER and PSQL_BIN as needed. Use the default scale size and a 2026 seed date for these fixed report periods. Set psql on PATH for the commands below. Do not modify data or refresh statistics between captures. Each output directory must be new.

```sh
psql -X -v ON_ERROR_STOP=1 -c 'VACUUM (ANALYZE);'
python3 portfolio-2-query-optimisation/benchmarks/capture_plans.py --output /tmp/fashion-before
psql -X -v ON_ERROR_STOP=1 -f portfolio-2-query-optimisation/optimisation/apply_indexes.sql
python3 portfolio-2-query-optimisation/benchmarks/capture_plans.py --output /tmp/fashion-indexes
python3 portfolio-2-query-optimisation/benchmarks/capture_plans.py --query-dir portfolio-2-query-optimisation/optimisation --output /tmp/fashion-final
python3 portfolio-2-query-optimisation/benchmarks/compare_plans.py /tmp/fashion-before /tmp/fashion-indexes
python3 portfolio-2-query-optimisation/benchmarks/compare_plans.py /tmp/fashion-before /tmp/fashion-final
python3 portfolio-2-query-optimisation/tests/history_equivalence.py
```

On a separate database loaded with scripts 01–05 only, run:

```sh
QUERY_OVERRIDE_DIR=portfolio-2-query-optimisation/optimisation python3 portfolio-2-query-optimisation/tests/query_results.py
```

The override directory replaces numbered query files only; other reports fall back to sql/. [Saved evidence](../evidence/optimisation/README.md) contains all three phases and successful checks. [Measurement protocol](../benchmarks/README.md) explains parameters, instrumentation, and limitations.
