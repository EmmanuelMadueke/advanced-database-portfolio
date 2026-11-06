# Development Setup and Verification

Owner, author, and maintainer: **Emmanuel Madueke**.

## Verified environment — 9 October 2026

| Tool | Observed status |
| --- | --- |
| PostgreSQL server/client | 18.1; binaries at `/Library/PostgreSQL/18/bin` on the current Mac |
| Git | 2.50.1 (Apple Git-155) |
| Python | 3.14.4; used for documentation checks, not required to run SQL |
| Docker | Client 29.1.3 installed; daemon availability not verified |
| pgAdmin | Installed application found; connection/UI workflow not tested |
| MongoDB shell | `mongosh` found; server/version/setup still pending for Portfolio 4 |

PostgreSQL was not on PATH. Verification used a separate temporary cluster and fresh databases, listening on a local Unix socket at port 55432 with TCP disabled. Existing databases were not modified. [Database summary](../portfolio-1-database-design/evidence/database-summary.txt) records the actual server version, timezone, table/column counts, and absence of retained test customers.

## Run against a fresh database

Requirements: PostgreSQL 18 tools, a database owner who can create schemas/functions, and CREATEROLE for first installation of the NOLOGIN demonstration role. Run from the repository root. Use a disposable database: these scripts create `retail` once and are not rerunnable migrations. They fail rather than dropping an existing schema.

On this Mac, add the verified tools to PATH if necessary:

```sh
export PATH="/Library/PostgreSQL/18/bin:$PATH"
```

For an isolated local test cluster, keep the following variables in the same terminal:

```sh
portfolio_pg_root=$(mktemp -d /tmp/fashion-portfolio.XXXXXX)
mkdir "$portfolio_pg_root/socket"
initdb -D "$portfolio_pg_root/data" -A trust --no-locale -E UTF8
pg_ctl -D "$portfolio_pg_root/data" -l "$portfolio_pg_root/server.log" \
  -o "-k $portfolio_pg_root/socket -p 55432 -h ''" -w start
export PGHOST="$portfolio_pg_root/socket"
export PGPORT=55432
export PGDATABASE=fashion_portfolio
createdb "$PGDATABASE"
```

This trust-authentication cluster is solely for disposable local fixtures; it is not a production configuration. An existing PostgreSQL connection may be used instead by setting its normal connection environment and creating a fresh database. Do not include passwords in tracked files or command examples.

Install and test:

```sh
psql -X -v ON_ERROR_STOP=1 \
  -f portfolio-1-database-design/sql/01_schema.sql \
  -f portfolio-1-database-design/sql/02_integrity.sql \
  -f portfolio-1-database-design/sql/03_operations.sql \
  -f portfolio-1-database-design/sql/04_permissions.sql
psql -X -v ON_ERROR_STOP=1 \
  -f portfolio-1-database-design/tests/integrity.sql
```

`-X` avoids local psql configuration affecting the run. ON_ERROR_STOP makes a failed statement terminate the run. Each installation file commits separately; if installation fails after an earlier file committed, investigate the error and use a new disposable database for a clean full rerun.

When using the isolated cluster, stop it afterwards:

```sh
pg_ctl -D "$portfolio_pg_root/data" -m fast -w stop
```

## Permissions and scope

The owner performs catalogue, identity, and fixture maintenance. The dedicated `fashion_portfolio_writer` role has SELECT access and explicit EXECUTE access to controlled purchase/cart/delivery functions, with no direct DML grants. It is NOLOGIN; tests use SET ROLE from the owner connection. It must be a dedicated role without unrelated grants or inherited privileged memberships. The installer refuses an existing role with elevated attributes; it does not audit every inherited grant. Customer authentication, row-level privacy, and production staff permissions are outside this demonstration.

SECURITY DEFINER routines use a fixed search path and reference protected tables by schema. The retail schema denies PUBLIC access, and function execution is revoked from PUBLIC before selected functions are granted. Protected function ownership should remain with the trusted schema owner.

Typed monetary columns may round incoming values to their declared scale before a table CHECK runs. The `checked_money` helper rejects invalid raw numeric values, and write routines use it for calculated totals. Direct owner catalogue imports must validate original prices with this helper before casting/inserting; the implementation does not claim table CHECK alone rejects excess fractional precision.

Country-code constraints validate two uppercase letters only. Semantic country-list validation for owner-maintained addresses is not implemented. No real card credentials or customer secrets are used.

## Verification limits and next task

Schema creation and 35 integrity/workflow assertions passed on PostgreSQL 18.1. The tests force deferred validators at checkpoints and roll back fixture rows. Identity sequences can still advance after rolled-back inserts; generated order/payment IDs are captured dynamically. This is not yet a Portfolio 3 COMMIT/isolation/concurrency demonstration.

Reproducible sample data and optional scale data are supplied in [sample-data documentation](sample-data.md). Subsequent portfolios now contain management queries, measured plans, two-session demonstrations, MongoDB implementation, and distributed/cloud discussion. The [final reproduction evidence](../evidence/reproducibility-2026-10-17/README.md) records a fresh run of the implemented workflows. Broader retry/deadlock schedules and distributed runtime behaviour remain untested.

## Subsequent NoSQL runtime verification

Docker Engine 29.1.3 and MongoDB Community 8.0.34 have now been verified for Portfolio 4. See [MongoDB implementation and reproduction](../portfolio-4-nosql/implementation.md) for the pinned image, actual source export, validation evidence, and shell-version observations. Earlier setup tables describe the environment as observed on their stated date.
