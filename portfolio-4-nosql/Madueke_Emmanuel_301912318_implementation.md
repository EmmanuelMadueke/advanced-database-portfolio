# MongoDB implementation and population

Owner, author, and maintainer: **Emmanuel Madueke**.

The product-enrichment model is now implemented on MongoDB Community **8.0.34**. Three profiles were loaded from actual PostgreSQL catalogue references with the collection validator set to strict/error. Ten importer checks, ten database rejection checks, two reconciliation checks, and four fresh-connection persistence checks passed. Actual evidence is retained in [evidence/implementation](evidence/implementation/Madueke_Emmanuel_301912318_README.md).

## Runtime and data

MongoDB runs in an isolated Docker container, bound to localhost port 57017. The image is the official mongodb/mongodb-community-server 8.0-ubuntu2204 image, pinned to the digest recorded below; the observed architecture is linux/arm64. Docker Engine 29.1.3 and PostgreSQL 18.1 were used. The CLI `mongosh --version` reported 2.6.0, while the in-session `version()` function reported 2.5.10. Both observations are retained rather than treating them as identical; the manifest records the latter.

The SQL source database fashion_nosql_source was freshly installed using Portfolio 1 scripts 01–05. A single read-only SQL statement exported all eight product IDs and selected catalogue facts. The export contains only synthetic product data, database/version context, and an actual extraction timestamp. It contains no credentials or customer records.

| Imported profile | Actual SQL product ID / MongoDB `_id` | Source selection |
| --- | --- | --- |
| Classic T-Shirt | `2` | Clothing / Lagos Threads |
| Canvas Sneakers | `7` | Footwear / Urban Steps |
| Tote Bag | `1` | Accessories / Lagos Threads |

These differ from the illustrative model IDs. The loader resolves each product/brand/category selector to exactly one exported row and copies its ID as a string. It rejects missing/ambiguous matches and duplicate selected identities. An importer check also remaps all source IDs to verify that matching does not depend on the original example numbers.

The stored collection is fashion_profiles_complete.product_profiles. Curated fields come from [enrichment.json](data/enrichment.json); copied SQL context comes from [source-products.json](evidence/implementation/source-products.json). Schema version and composition percentages are converted explicitly to BSON Int32. [profiles.ejson](evidence/implementation/profiles.ejson) records actual stored BSON types.

## What was verified

| Layer | Checks |
| --- | --- |
| Import preparation, 10 | Wrong composition total, duplicate material, noncanonical tag, nonfinite dimension, bigint overflow, leading-zero ID, missing source, ambiguous source, duplicate selection, remapped-ID preservation |
| MongoDB, 10 | Missing name, mismatched category, forbidden stock, negative dimension, unknown attribute, blank name, duplicate tag, out-of-range percent, duplicate `_id`, invalid update |
| Reconciliation, 2 | Exact selected IDs/context/enrichment with no extra/missing/orphan selected profiles; zero documents violating the validator |
| Fresh connection, 4 | Input hashes match manifest; exact persisted profiles match preparation; installed strict/error validator matches file; all stored documents satisfy it |

Invalid shape writes were rejected with code 121, and duplicate identity with code 11000. Tests use separate unused IDs for invalid inserts; no successful test rows remain. Negative-test success means rejection occurred, not that invalid documents were stored. Composition totals and cross-database references remain importer/reconciliation responsibilities, not automatic MongoDB foreign keys or composition-sum constraints.

## Reproduce

Run from the repository root with Docker, mongosh, Python 3, and the PostgreSQL tools available. Follow [SQL setup](../docs/Madueke_Emmanuel_301912318_setup.md) to start a disposable PostgreSQL cluster, set connection variables, create a **new** source database, and install Portfolio 1 scripts 01–05 in order. Do not reuse a database containing test fixtures or scale data for the documented eight-product result.

Start the MongoDB container:

```sh
docker run --name fashion-portfolio-mongo \
  -p 127.0.0.1:57017:27017 -d \
  mongodb/mongodb-community-server@sha256:8e60bd7f7f5d54e31657a3ee08385dcad3a93ff8f1d1fb1ea6dd216c8454d33f
```

This is a localhost-only, unauthenticated disposable development instance containing synthetic data. It is not a production deployment. No cloud account is involved. If that container name already exists, inspect it and choose a new name/port for an independent run rather than deleting existing work. The created container was stopped after verification and retains its data; `docker start fashion-portfolio-mongo` resumes it.

Use a new output directory and fresh MongoDB database for each import:

```sh
export PROFILE_OUTPUT_DIR=/tmp/fashion-profile-repeat
python3 portfolio-4-nosql/scripts/export_products.py "$PROFILE_OUTPUT_DIR/source-products.json"
mongosh 'mongodb://127.0.0.1:57017/fashion_profiles_repeat?directConnection=true&serverSelectionTimeoutMS=5000' \
  --quiet --file portfolio-4-nosql/scripts/load_and_verify.js
mongosh 'mongodb://127.0.0.1:57017/fashion_profiles_repeat?directConnection=true&serverSelectionTimeoutMS=5000' \
  --quiet --file portfolio-4-nosql/scripts/verify_persisted.js
```

Set PSQL_BIN if psql is not on PATH. Ensure MongoDB has started before loading; connection failure is not a successful test. Stop on any nonzero command exit. The Python export refuses to overwrite a snapshot; the loader refuses an existing product_profiles collection or existing output artifacts. Database names must be fashion_profiles or begin fashion_profiles_ with lowercase letters/digits/underscores. The separate verifier can be repeated without modifying stored profiles.

The loader writes a manifest with source/enrichment/validator SHA-256 hashes, source and destination versions/names, actual timestamps, selected IDs, document count, and check counts. It also saves the installed collection options and stored profiles. The source export uses one statement snapshot; there is no background synchronisation. Evidence reconciliation is against that snapshot, not a promise that later SQL changes automatically appear in MongoDB.

After inspection:

```sh
docker stop fashion-portfolio-mongo
```

Stop the temporary PostgreSQL cluster using the SQL setup instructions. No automatic database/container deletion is part of reproduction.

## Corrections and limits

Three development failures are retained: a CommonJS module initially called mongosh-only print; a Node assertion callback did not observe mongosh's update exception; and strict Node object comparison rejected equivalent values across shell contexts. The corrected harness uses module console logging, a direct try/catch for the update, and canonical value comparison for reconciliation. Later attempts used fresh databases; the final successful run and its separate verifier are the evidence for completion. Earlier diagnostic databases remain isolated in the stopped container.

Collection creation and inserts are not one cross-database transaction. A mid-import failure may leave a collection or partial data: inspect it and use a new disposable target for reproduction. This stage implements initial snapshot loading, not in-place refresh, production access control, live event synchronisation, replica sets, or sharding. Source changes/deletions require explicit reconciliation/rebuild; no refresh automation is claimed.

Only the default `_id` index is needed for current identity checks. Business query demonstrations, aggregation, and an additional workload-justified index are the next checklist item. No NoSQL performance improvement is claimed from three profiles.

Runtime choice follows [MongoDB's Docker installation guidance](https://www.mongodb.com/docs/manual/administration/install-community-docker/); collection setup uses the documented [createCollection options](https://www.mongodb.com/docs/manual/reference/method/db.createcollection/).
