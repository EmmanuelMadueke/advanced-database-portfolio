# Query Result Evidence

Owner, author, and maintainer: **Emmanuel Madueke**.

Recorded on 10 October 2026 using PostgreSQL 18.1 and a fresh isolated database containing Portfolio 1 scripts 01–05. Scale data was not loaded. Generated timestamps reflect this run; the seed's business outcomes match the documented expectations.

- [sample-query-results.txt](Madueke_Emmanuel_301912318_sample-query-results.txt): actual output from all twelve reports in one read-only snapshot.
- [query-check-output.txt](Madueke_Emmanuel_301912318_query-check-output.txt): thirty assertions passed against the original SQL files, including parameter variations and reconciliation to NGN 268,000.

These sample-query files contain correctness evidence. Separate [scale-dataset baseline plans and timings](baseline/Madueke_Emmanuel_301912318_README.md) are now available; no optimisation indexes have been added. No two-session concurrency demonstration was performed here. Reproduction and remaining work are in the [Portfolio 2 README](../Madueke_Emmanuel_301912318_README.md).
