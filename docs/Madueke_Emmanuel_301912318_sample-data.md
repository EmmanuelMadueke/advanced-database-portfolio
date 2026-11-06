# Reproducible Sample Data

Owner, author, and maintainer: **Emmanuel Madueke**.

All records are synthetic. Names, brands, products, demo addresses, placeholder phone numbers, and `example.test` email addresses are not obtained from real customers or a retailer. Prices are illustrative NGN amounts, not researched market prices.

## Fashion-store demonstration dataset

[05_sample_data.sql](../portfolio-1-database-design/sql/05_sample_data.sql) loads the following into a fresh schema:

| Entity | Rows |
| --- | ---: |
| Customers / saved addresses | 12 / 12 |
| Categories / brands | 3 / 3 |
| Sizes / colours | 7 / 4 |
| Products / variants / inventory | 8 / 18 / 18 |
| Administrators | 2 |
| Shopping carts / cart items | 6 / 4 |
| Orders / order items | 12 / 17 |
| Payment attempts / deliveries | 12 / 6 |

The catalogue includes T-shirts, shirts, dresses, hoodies, sneakers, sandals, totes, and belts. Each purchasable size/colour combination has its own SKU and stock balance. Products and lookups are resolved by natural values rather than hardcoded identity numbers. Prices are validated with `checked_money` before insertion.

## Scenarios and expected results

| Scenario | Expected final state |
| --- | --- |
| Inventory | 2 out-of-stock variants; 2 low-stock variants; other variants above threshold |
| Carts | 4 active, 1 converted, 1 abandoned; 4 active-cart lines |
| Orders | 2 pending, 2 paid, 1 processing, 2 dispatched, 3 delivered, 2 cancelled |
| Payments | 8 succeeded, 3 failed, 1 pending; one paid order has a failed attempt followed by success |
| Deliveries | 1 pending, 2 dispatched, 3 delivered |
| Recognised sales | NGN 268,000.00 across paid/processing/dispatched/delivered orders |

Pending and cancelled orders do not reduce stock. Failed or pending attempts are not recognised sales. Paid quantities reduce only the matching variant balance. A multi-item order stores separate lines and purchase-time unit prices. Revenue is calculated from eligible orders or successful payments independently; joining all payment attempts to order items without filtering can duplicate amounts.

Orders are built and paid using `create_order`, `finalise_order`, `record_failed_payment`, and cancellation/dispatch/delivery routines. Catalogue/customer insertion and the paid → processing step use owner maintenance SQL, with the same triggers and deferred validation active. No triggers are disabled. The historical cart rows demonstrate lifecycle values; they are not claimed to have a traced checkout relationship because the schema has no cart–order link.

## Verification and reproduction

Install scripts 01–04 using [setup instructions](setup.md), then run as the schema owner:

```sh
psql -X -v ON_ERROR_STOP=1 -f portfolio-1-database-design/sql/05_sample_data.sql
psql -X -v ON_ERROR_STOP=1 -f portfolio-1-database-design/tests/sample_data.sql
```

The seed is a single transaction, forces deferred validation, and commits its records. It refuses an already populated customer/product/order dataset; it is intentionally not a reset or an upsert script. Use a new disposable database to repeat it. Generated IDs can differ after prior tests consume sequence values; natural references and final business results remain the same. Creation/payment/dispatch timestamps reflect the execution time, so byte-for-byte timestamp reproduction is not claimed.

Ten read-only assertions verify all entity counts, lifecycle coverage, cart/stock cases, order totals, successful payment amounts, and every initial stock balance minus paid quantities. These checks run before the optional enlargement. [Actual output](../portfolio-1-database-design/evidence/sample-check-output.txt) includes inventory, order, and payment reports; [seed output](../portfolio-1-database-design/evidence/sample-seed-output.txt) shows successful COMMIT.

## Optional larger workload for Portfolio 2

[06_scale_data.sql](../portfolio-1-database-design/sql/06_scale_data.sql) appends 1,000 synthetic shoppers, 200 generic clothing products, 1,200 variants, and by default 10,000 one-item orders. Every fourth extra order is paid through the finalisation routine; the rest remain pending. Its high initial stock is a workload fixture, not a realistic retail prediction. Correctness indexes remain present; ANALYZE updates statistics after loading.

```sh
psql -X -v ON_ERROR_STOP=1 -f portfolio-1-database-design/sql/06_scale_data.sql
psql -X -v ON_ERROR_STOP=1 -f portfolio-1-database-design/tests/scale_data.sql
```

Both accept `-v scale_orders=N` (4–100,000); pass the same N to the loader and checks. The default combined dataset has 1,012 customers, 208 products, 1,218 variants, 10,012 orders, 10,017 order items, and 2,512 payment attempts. Four additional assertions check counts, totals, successful payments, and stock reconciliation.

This deterministic workload has limitations: timestamps are concentrated around loading; round-robin selection and every-fourth success correlate buyers/variants with status; category and price diversity are narrow. It supplies a larger starting dataset, not representative production traffic or performance conclusions. Query-specific distributions, date ranges, execution plans, and measurements must be documented during Portfolio 2.

## Current completion

The seed scripts, checks, evidence, and reproduction notes complete the sample-data task and remaining Portfolio 1 evidence. Portfolio 2 query development and optimisation are next. Full two-session concurrency and dedicated transaction demonstrations remain Portfolio 3 work.
