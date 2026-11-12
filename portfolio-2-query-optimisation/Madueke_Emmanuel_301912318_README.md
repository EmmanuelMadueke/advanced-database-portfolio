# Portfolio 2 — Query Processing and Optimisation

Owner, author, and maintainer: **Emmanuel Madueke**.

## Current stage

The first checklist item, meaningful SQL queries, is complete. Twelve read-only reports have been implemented and verified on PostgreSQL 18.1 against the unscaled fashion-store sample data. Thirty result checks passed; actual outputs are saved below. Baseline execution plans and measurement conditions are now recorded for five reports on the default scale dataset. Three reporting indexes and a customer-history rewrite have now been tested in a controlled three-phase comparison. Result equivalence, plan changes, storage costs, and limitations are documented in the [optimisation findings](optimisation/Madueke_Emmanuel_301912318_README.md). Portfolio 2 is complete.

## Queries

| File | Business question | Defaults / sample outcome |
| --- | --- | --- |
| [01_catalogue.sql](sql/01_catalogue.sql) | Which stocked variants match category, brand, audience, size, colour, and price? | Clothing / Lagos Threads / unisex / M / Black / NGN 0–20,000 → TEE-BLK-M |
| [02_inventory.sql](sql/02_inventory.sql) | What is current stock, including low/out-of-stock variants? | stock_filter=all → 18 variants; low_stock and out_of_stock each return 2 |
| [03_customer_history.sql](sql/03_customer_history.sql) | What orders and payment outcomes belong to a customer? | femi@example.test → 1 order, 2 attempts, 1 failure, successful purchase NGN 22,500 |
| [04_open_orders.sql](sql/04_open_orders.sql) | Which orders await payment, fulfilment, or delivery? | 7 pending/paid/processing/dispatched orders |
| [05_delivery_tracking.sql](sql/05_delivery_tracking.sql) | What is the progress of existing shipments? | delivery_filter=all → 6 shipments; dispatched → 2 |
| [06_best_selling_variants.sql](sql/06_best_selling_variants.sql) | Which variants sell the most units? | 12 sold variants, 14 units; TEE-BLK-M and TOT-BLK-OS each sell 2 |
| [07_sales_by_product.sql](sql/07_sales_by_product.sql) | How much does each sold product contribute? | 8 products; Canvas Sneakers revenue NGN 70,000 |
| [08_sales_by_category.sql](sql/08_sales_by_category.sql) | How much revenue belongs to each current category? | Clothing 136,000; Footwear 96,000; Accessories 36,000 NGN |
| [09_monthly_sales.sql](sql/09_monthly_sales.sql) | What are monthly sales, including zero-sales months? | 12 months in 2026; October has 8 eligible orders and NGN 268,000 |
| [10_revenue_summary.sql](sql/10_revenue_summary.sql) | What are revenue, paid order count, and average order value? | 8 eligible orders; NGN 268,000 total; NGN 33,500 average |
| [11_customer_activity.sql](sql/11_customer_activity.sql) | What did each customer spend during the selected period? | All 12 customers; 4 have zero recognised spending |
| [12_payment_exceptions.sql](sql/12_payment_exceptions.sql) | Which unpaid/cancelled orders have failed or pending attempts? | 3 attempts; excludes Femi's failed attempt followed by success |

## Reporting rules

Recognised sales include paid, processing, dispatched, and delivered orders, as specified in BR19. Pending/cancelled orders and failed/pending payment attempts contribute no revenue. This is the portfolio's operational sales definition, not an accounting standard. Monetary reports use purchase-time item prices or stored order totals, never current catalogue prices.

Period reports use `paid_at`, with `from_date` inclusive and `until_date` exclusive at midnight in Africa/Lagos. Monthly labels are Lagos calendar months, and zero-sales months/categories are retained. Partial first/last months include only sales within the selected dates. Defaults are 1 January 2026 through 1 January 2027; set variables to match your data if it was loaded in another year. Same/reversed date ranges yield empty selections; validate dates/filter values in any future application input layer.

Product/category labels use current catalogue classification. Reclassification can change category breakdowns; historical classifications are not modelled. `purchase_orders` counts distinct orders per group and is not additive across categories/products when an order spans groups. Best sellers rank by units, then revenue, with SKU resolving ties; the query returns all sold variants.

Customer history aggregates attempts before joining, so retries do not duplicate orders. Payment exception output deliberately has one row per unresolved attempt. Stock reports include inactive catalogue records and show flags; purchasable catalogue results require active product/variant and positive inventory. Existing shipment reports exclude orders without a delivery record; open orders retain them with NULL delivery fields.

## Reproduce

Use [Portfolio 1 setup](../docs/Madueke_Emmanuel_301912318_setup.md) and [seed instructions](../docs/Madueke_Emmanuel_301912318_sample-data.md). Connect to a database containing scripts 01–05. The saved expected outcomes and result-check suite require the unscaled sample dataset.

```sh
psql -X -v ON_ERROR_STOP=1 -f portfolio-2-query-optimisation/sql/run_all.sql
psql -X -v ON_ERROR_STOP=1 -v stock_filter=low_stock \
  -f portfolio-2-query-optimisation/sql/02_inventory.sql
psql -X -v ON_ERROR_STOP=1 -v customer_email=femi@example.test \
  -f portfolio-2-query-optimisation/sql/03_customer_history.sql
psql -X -v ON_ERROR_STOP=1 -v from_date=2026-10-01 -v until_date=2026-11-01 \
  -f portfolio-2-query-optimisation/sql/10_revenue_summary.sql
python3 portfolio-2-query-optimisation/tests/query_results.py
```

`run_all.sql` takes one REPEATABLE READ, READ ONLY snapshot for all reports. Query files also run individually and preserve command-line variables instead of resetting them. Values use psql's quoted-literal substitution (`:'variable'`); the quoted-email test verifies input is treated as a literal. These are psql scripts rather than raw SQL files; extract SELECT/WITH statements and use bound parameters when moving them into an application/client that does not support psql commands.

The Python check runner uses psql CSV output and the original query files; it does not duplicate their SELECT statements or modify records. Configure normal PGHOST/PGPORT/PGDATABASE/PGUSER environment values. Set PSQL_BIN to the executable path if it is not on PATH. It infers the seed year for period checks and forces read-only connections. No password belongs in tracked configuration.

## Evidence and limitations

- [Actual query results](evidence/Madueke_Emmanuel_301912318_sample-query-results.txt)
- [Thirty result checks](evidence/Madueke_Emmanuel_301912318_query-check-output.txt)
- [Evidence context](evidence/Madueke_Emmanuel_301912318_README.md)

Checks verify known totals, filters, failed-payment retries, empty results, zero-sales groups/months, date endpoints, timezone invariance, and literal handling. They establish correctness on the documented sample data, not query efficiency. Sample timestamps are concentrated around loading; broad historical/date-distribution testing remains limited. The optional scale dataset is available for the next experiment stage, but these results were captured before enlargement.

## Baseline plans

[Baseline results and plan observations](evidence/baseline/Madueke_Emmanuel_301912318_README.md) retain five measured plans per selected query, environment/index metadata, buffer counts, and result fingerprints. [The collection protocol](benchmarks/Madueke_Emmanuel_301912318_README.md) explains reproduction and limitations. This is the scale dataset; it is separate from the unscaled sample correctness outputs above.

The [optimisation experiment](optimisation/Madueke_Emmanuel_301912318_README.md) retains a fresh before/indexes-only/indexes-and-rewrite comparison and reproducible SQL. Thirty sample checks and seven history-equivalence cases passed. The completed transaction work is in [Portfolio 3](../portfolio-3-transactions-concurrency/Madueke_Emmanuel_301912318_README.md).

## References

PostgreSQL 18 documentation: [psql variables and script execution](https://www.postgresql.org/docs/18/app-psql.html), [date/time functions](https://www.postgresql.org/docs/18/functions-datetime.html), and [transaction isolation](https://www.postgresql.org/docs/18/transaction-iso.html).

## Screenshot evidence

See the [assessment screenshot gallery](../evidence/screenshots/Madueke_Emmanuel_301912318_README.md) for captures of retained outputs and diagrams. Captures are labelled separately from the original execution dates; Portfolio 5 remains a discussion.
