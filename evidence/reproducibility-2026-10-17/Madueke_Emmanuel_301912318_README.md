# Fresh portfolio reproduction — 17 October 2026

Owner, author, and maintainer: **Emmanuel Madueke**.

## Outcome and execution context

The documented Portfolio 1–4 workflows completed successfully against fresh disposable databases on source commit `5ba7d37`. All **52 recorded commands exited zero**, including startup and shutdown. Portfolio 5 received documentation checks only. These are tool-run results, not a claim of Emmanuel's independent verification.

[Run manifest](Madueke_Emmanuel_301912318_run-manifest.json) records actual UTC start/completion times, exact command arguments, database selection, exit codes, and connection/output environment. Each step's stdout and stderr are retained in the correspondingly named text file. Commands ran sequentially and stopped on failure; cleanup stopped the runtimes. Historical activity outputs were not overwritten. No implementation correction was needed.

PostgreSQL 18.1 ran in a new temporary cluster using a local Unix socket on port 55433 with TCP disabled. Separate databases isolated sample/scale, COMMIT, ROLLBACK, isolation, protected-race, and unsafe-race work. The sample source was exported to MongoDB input **before** loading scale data. [Server version](postgres-version.txt) and [Docker version](Madueke_Emmanuel_301912318_docker-version.txt) retain the observed versions.

MongoDB 8.0.34 ran in new container `fashion-final-20261017` on localhost port 57018, using the same pinned official image digest as the implementation instructions. The target was `fashion_profiles_final`; the [import manifest](mongo-import/manifest.json) records versions, source database, actual timestamps, hashes, and selected SQL IDs. The in-session mongosh version was 2.5.10. This is a standalone development instance, not a replica-set or cloud test.

## Results and retained evidence

| Coverage | Fresh evidence | Outcome |
| --- | --- | --- |
| Schema installation and integrity | [Install](Madueke_Emmanuel_301912318_sample-install.txt), [integrity](Madueke_Emmanuel_301912318_integrity.txt) | 35 assertions passed; fixture rolled back |
| Sample and scale seeds | [Sample checks](Madueke_Emmanuel_301912318_sample-check.txt), [scale checks](Madueke_Emmanuel_301912318_scale-check.txt) | 10 and 4 assertions passed |
| Twelve SQL reports | [Actual results](Madueke_Emmanuel_301912318_query-results.txt), [original checks](Madueke_Emmanuel_301912318_query-check.txt), [rewrite checks](Madueke_Emmanuel_301912318_query-rewrite-check.txt) | 30 checks passed for each query selection |
| Optimisation experiment | [Indexes comparison](Madueke_Emmanuel_301912318_compare-indexes.txt), [final comparison](Madueke_Emmanuel_301912318_compare-final.txt), [history equivalence](Madueke_Emmanuel_301912318_history-equivalence.txt) | Five result fingerprints/counts match in both comparisons; 28 original indexes retained; seven history cases agree |
| COMMIT | [Purchase](Madueke_Emmanuel_301912318_commit-purchase.txt), [fresh-connection verification](Madueke_Emmanuel_301912318_commit-verify.txt) | Eight checks passed |
| ROLLBACK | [Injected failure and rollback](Madueke_Emmanuel_301912318_rollback-purchase.txt), [fresh-connection verification](Madueke_Emmanuel_301912318_rollback-verify.txt) | Six checks passed; expected injected error is part of the passing demonstration |
| Isolation | [Session output](isolation-sessions.txt) | Seven checks passed |
| Unsafe race | [Session output](Madueke_Emmanuel_301912318_unsafe-sessions.txt) | Eight checks reproduced overselling in the isolated teaching schema |
| Protected race | [Session output](Madueke_Emmanuel_301912318_protected-sessions.txt) | Eleven checks passed, including observed blocking, one purchase, and unchanged known-order replay |
| MongoDB import | [Load](mongo-load.txt), [persisted check](mongo-persisted.txt), [stored profiles](mongo-import/profiles.ejson) | 22 load checks and four persistence checks passed |
| MongoDB queries/index | [Query output](mongo-queries.txt), [hinted diagnostic](mongo-hint.txt) | 16 checks and hinted-result equivalence passed |
| Documentation | [Local link and SVG checks](Madueke_Emmanuel_301912318_documentation-checks.txt) | Relative paths resolved; SVG XML parsed. No external URL or distributed-runtime verification |
| Cleanup | [MongoDB stop](mongo-stop.txt), [PostgreSQL stop](pg-stop.txt) | Both stopped successfully; retained data was not deleted |

The `plans-before/`, `plans-indexes/`, and `plans-final/` directories contain raw repeated EXPLAIN captures and environment/index metadata. The `mongo-import/` and `mongo-queries/` directories retain the actual inputs, hashes, validation options, results, and plans produced by the existing scripts.

## Observed differences and limits

The fresh median history execution time changed from **1.444 ms to 0.116 ms**, and revenue from **1.055 ms to 0.191 ms**. These reproduce the direction of the earlier local findings without requiring identical timings. All comparisons use this run's unchanged dataset and settings, not a mixture of old and new captures. Each phase uses a warm-up and five measured plans per report; timings remain synthetic, warm-cache, instrumented observations.

The MongoDB `_id_` index occupied 4,096 bytes in this run, compared with 20,480 bytes in the earlier recorded run; the optional composition index occupied 20,480 bytes. Allocated size is an observed fixture property, not a fixed per-index guarantee. The hinted diagnostic again examined one document and returned the same result. Three profiles and individual explain executions do not establish a performance benefit.

The successful rerun does not test every transaction schedule, production access control, real payment processing, live cross-store refresh, database replication, regional recovery, or assessor access. Generated IDs, timestamps, process IDs, socket paths, storage allocation, and timings can vary. No student reflection or final submission is implied.

## Repeat the review

Use the existing [SQL setup](../../docs/Madueke_Emmanuel_301912318_setup.md), [sample-data steps](../../docs/Madueke_Emmanuel_301912318_sample-data.md), [optimisation protocol](../../portfolio-2-query-optimisation/optimisation/Madueke_Emmanuel_301912318_README.md), [transaction instructions](../../portfolio-3-transactions-concurrency/Madueke_Emmanuel_301912318_README.md), and [MongoDB instructions](../../portfolio-4-nosql/Madueke_Emmanuel_301912318_implementation.md). The manifest provides this run's exact invocation order, including the dedicated concurrency fixtures and MongoDB query scripts.

Choose new temporary cluster/output paths, database names, and a container name/available localhost port. Keep the connection variables aligned with those choices. Do not replay the recorded temporary paths blindly or overwrite this evidence. Run the original and rewritten query checks on the unscaled sample, export the eight-product snapshot before scale loading, then run the scale comparisons without changing data/statistics between phases. Stop the disposable services after inspection.
