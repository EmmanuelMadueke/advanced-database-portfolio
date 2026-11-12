# Product profile implementation evidence

Owner, author, and maintainer: **Emmanuel Madueke**.

This directory retains actual synthetic-data outputs. The export/import timestamps are UTC in the files; they were recorded on 16 October 2026 UTC. Use the stored timestamps for precise timing rather than inferring dates from filesystem metadata.

- [PostgreSQL installation](postgres-install.txt): scripts 01–05 in fresh fashion_nosql_source.
- [Source snapshot](source-products.json): eight catalogue rows, actual IDs and SQL context.
- [Image digest and architecture](container-image.txt).
- [Successful import and 22 checks](load-checks.txt): 10 importer, 10 MongoDB rejection, 2 reconciliation checks.
- [Fresh-connection verification](persisted-checks.txt): four checks after the load process exited.
- [Manifest](manifest.json): versions, hashes, IDs, timestamps, target database, counts.
- [Stored BSON documents](profiles.ejson) and [installed validation options](collection-options.ejson).
- Diagnostic outputs: [module logging error](initial-loader-error.txt), [update-test harness error](initial-update-test-error.txt), [cross-context comparison error](initial-comparison-error.txt). These are development corrections, not passing verification evidence.

The final successful target is fashion_profiles_complete; earlier diagnostic targets are separate databases. No student review or runtime verification is attributed to Emmanuel. See [implementation and reproduction](../../Madueke_Emmanuel_301912318_implementation.md) for limitations, the CLI/in-session shell-version discrepancy, and the next stage.
