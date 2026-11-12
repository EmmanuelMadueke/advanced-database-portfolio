# Baseline Execution Plans

Owner, author, maintainer: **Emmanuel Madueke**.

Captured on 10 October 2026 using PostgreSQL 18.1, the sample plus default scale seed, and no added optimisation indexes. The database contains 10,012 orders, 10,017 item rows, 2,512 payment attempts, 1,012 customers, and 1,218 variants. Its 28 existing indexes are the schema’s primary/unique/canonical/conditional-uniqueness indexes.

## Measured results

Each report has one warm-up and five measured runs. Execution values are PostgreSQL server times under EXPLAIN instrumentation with TIMING OFF; connection and output-transfer time is excluded. Buffer values below are from the first measured plan, including its children.

| Query | Returned rows | Median execution (ms) | Min–max (ms) | Shared hits | Shared reads |
| --- | ---: | ---: | --- | ---: | ---: |
| [01_catalogue](01_catalogue.json) | 201 | 0.620 | 0.597–0.640 | 1,626 | 0 |
| [03_customer_history](03_customer_history.json) | 10 | 1.262 | 1.240–1.356 | 597 | 0 |
| [04_open_orders](04_open_orders.json) | 10,007 | 3.266 | 3.233–3.290 | 541 | 0 |
| [06_best_selling_variants](06_best_selling_variants.json) | 312 | 3.654 | 3.610–6.306 | 702 | 0 |
| [10_revenue_summary](10_revenue_summary.json) | 1 | 1.044 | 1.000–1.277 | 520 | 0 |

The measured plans read no shared blocks from storage. These are warm-cache local observations; the best-seller run range includes a 6.306 ms observation, so a single fastest run would hide variation. Five repetitions are descriptive evidence, not statistical proof of production latency.

## Plan observations

- Catalogue: existing variant-combination and inventory primary-key indexes are used, alongside scans of small lookup/product tables. The selected filters return 201 variants.
- Customer history: customer email uses its unique index, but the plan scans all 10,012 orders and 2,512 payment attempts to return ten orders for scale-0004@example.test. A customer/order lookup index and the scope of payment aggregation are candidates for the next experiment.
- Open orders: 10,007 of 10,012 orders qualify. Sequential scans and a sort serve this broad result; an index experiment must account for that low selectivity.
- Best sellers: orders and items are scanned, joined, aggregated, and sorted into 312 sold variants. The order scan estimates 628 eligible rows and returns 2,508.
- Revenue summary: the order scan also estimates 628 rows and returns 2,508. Status, nullable paid timestamps, and the concentrated payment-date distribution are related in this synthetic data; investigate statistics and access paths rather than assuming a particular optimisation will help.

Independent successful-payment totals reconcile with the summary: **2,508 successful payments, NGN 36,908,000.00**, and **2,514 sold units**. See [dataset reconciliation](dataset-reconciliation.txt).

## Conditions and retained evidence

- [Environment](environment.json): server version/settings, exact/estimated rows, statistics timestamps, distributions, and every baseline index definition.
- [Per-run measurements](measurements.csv): planning/execution times, rows, buffer and temporary-block counts for all 25 measured runs.
- The five query JSON files retain warm-up and all measured plan trees, parameters, source hashes, output row counts, samples, and complete-result fingerprints.
- [Measurement protocol and reproduction](../../benchmarks/Madueke_Emmanuel_301912318_README.md): selected parameters, warm-up, ANALYZE, read-only connections, and cache conditions.

Planner preferences were left at their recorded defaults; work_mem was 4 MB, shared_buffers 128 MB, and track_io_timing was off. No concurrent workload was deliberately introduced. Host activity and caching were uncontrolled. All successful payments in this dataset occur on 10 October 2026, and the deterministic scale generator correlates status with customer/variant selection. These limitations constrain conclusions from date filters and workload selectivity.

## Next experiment

Create justified optimisation indexes or query rewrites, preserve business-rule indexes and data, compare result fingerprints, and repeat the same collection protocol. Compare plan structure, row estimates, buffers, planning time, and execution variation. No before/after improvement is claimed at this stage.
