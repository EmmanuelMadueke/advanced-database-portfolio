# Optimisation evidence — 13 October 2026

Owner, author, and maintainer: **Emmanuel Madueke**.

These captures use one rebuilt PostgreSQL 18.1 scale database, with a single VACUUM (ANALYZE) before the first phase. No data changes occurred between phases. The October 10 baseline is preserved separately.

- [Before](before/): original queries and 28 correctness indexes.
- [Indexes only](indexes_only/): original queries and three added reporting indexes.
- [Indexes and rewrite](indexes_and_rewrite/): the same indexes with the customer-history override.

Each directory contains environment.json, measurements.csv, and five query JSON files with full-result hashes, sample rows, a warm-up, and five measured plans. Across the three phases there are 75 measured plans and 15 warm-ups.

- [Index installation](index-install.txt)
- [Index sizes](index-sizes.csv)
- [Index-only comparison](index-comparison.txt)
- [Final comparison](final-comparison.txt)
- [Thirty sample checks](sample-checks.txt), on a separate unscaled database
- [Seven history-equivalence cases](history-equivalence.txt), on the scale database

See [findings and reproduction](../../optimisation/Madueke_Emmanuel_301912318_README.md) for interpretation and costs. Outputs are actual tool-run evidence; timings are local observations.
