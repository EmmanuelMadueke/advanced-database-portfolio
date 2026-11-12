# Baseline Measurement Protocol

Owner, author, maintainer: **Emmanuel Madueke**.

Use the sample plus default scale dataset from Portfolio 1 scripts 01–06: 10,012 orders and 1,218 variants. The collector refuses a different order/variant count. Do not modify data while capturing/comparing plans. No additional optimisation indexes are created by the collector.

Before capturing, run ANALYZE on all tables referenced by the selected reports to update planner statistics. The recorded baseline refreshed customers, products, categories, brands, variants, sizes, colours, inventory, orders, order_items, payments, and deliveries. Preserve those statistics/settings and the existing correctness indexes for later comparison; a newly seeded database may produce different sampled statistics and timestamps.

Configure the PostgreSQL connection using normal environment variables, then run from the repository root:

```sh
python3 portfolio-2-query-optimisation/benchmarks/capture_plans.py
```

Set PSQL_BIN if psql is not on PATH. Output defaults to `portfolio-2-query-optimisation/evidence/baseline/`. Existing output directories are refused so saved evidence is not silently overwritten; use `--output /tmp/fashion-baseline-repeat` for another run. `--runs 5` controls measured repetitions, with a minimum of three.

## Selected reports and parameters

- Catalogue (01): Clothing / Lagos Threads / unisex / M / Black, NGN 0–20,000. This now includes the additional scale catalogue.
- Customer history (03): `scale-0004@example.test`, which has ten paid scale orders.
- Open orders (04): default states, representing a broad result set.
- Best-selling variants (06): the paid-in-2026 period, grouped by variant.
- Revenue summary (10): the same paid-in-2026 period.

Dates use `from_date=2026-01-01`, `until_date=2027-01-01`, with explicit Africa/Lagos boundaries in the reports. These are fixed experiment parameters. A future dataset loaded outside 2026 needs a deliberately revised protocol, not a claim of identical reproduction.

## Measurement details

The script reads each original query file and retains its psql variable defaults/substitutions. It collects one unmeasured warm-up and five measured EXPLAIN (ANALYZE, BUFFERS, TIMING OFF, FORMAT JSON) plans per query. TIMING OFF omits individual node timings but retains total execution time, rows, loops, and buffer counts. Each run uses a fresh psql connection with read-only transactions, an explicit session timezone, and a 30-second statement timeout. Connection/network/output-transfer time is excluded from PostgreSQL's Execution Time. Execution remains instrumented; measurements are not a direct application latency benchmark.

Seed loading, statistics refresh, a result-fingerprint query, and warm-up precede measurements. Caches are not reset, so this is a warm-cache baseline. No competing workload is deliberately started; unrelated host activity is uncontrolled. Measurements are grouped by query rather than randomised. Compare both medians and variation, and repeat under matching conditions if results are noisy.

Raw plan JSON retains every measured plan plus the warm-up. CSV records per-run planning/execution milliseconds, returned rows, shared cache hits/reads, and temporary block counts. Top-level buffer counts already include child usage; do not sum them again across the tree. Environment metadata records version, settings, exact/estimated rows, table statistics, status/date/category distribution, and all existing index definitions. Result fingerprints and query-source hashes support later equivalence checks against the same unchanged dataset; a fingerprint alone is not proof of correctness on all inputs.

The existing primary-key, uniqueness, and conditional-uniqueness indexes enforce business rules and stay in the baseline. Foreign keys do not imply that every referencing column has its own index. No forced scan preferences or disabled correctness indexes are used.

## Interpretation limits

The scale seed has narrow categories/prices, every-fourth-order success, correlated customer/variant selection, and concentrated event dates. Five small local runs do not establish production behaviour or statistical significance. A sequential scan can be appropriate for a broad selection. Selective history lookup, broad fulfilment lists, and aggregated sales provide different workloads to compare in the next stage.

## References

PostgreSQL 18: [EXPLAIN options and overhead](https://www.postgresql.org/docs/18/sql-explain.html), [reading plans](https://www.postgresql.org/docs/18/using-explain.html), and [ANALYZE statistics](https://www.postgresql.org/docs/18/sql-analyze.html).

## Optimisation comparisons

The [October 13 experiment](../optimisation/Madueke_Emmanuel_301912318_README.md) uses a fresh before capture after one VACUUM (ANALYZE), followed by index installation and a rewrite phase on the same unchanged database. This differs from the historical October 10 ANALYZE-only baseline; compare within the new three-phase experiment.

Pass `--query-dir portfolio-2-query-optimisation/optimisation` to use numbered SQL overrides, with other queries falling back to sql/. Metadata records the source hash of each executed query and all-visible table page counts. `python3 portfolio-2-query-optimisation/benchmarks/compare_plans.py BEFORE_DIR AFTER_DIR` checks counts, settings, parameters, server, distributions, existing index definitions, and full ordered-result hashes before printing timing/buffer comparisons. These checks complement inspection of raw plans and do not prove the absence of every possible environment change.
