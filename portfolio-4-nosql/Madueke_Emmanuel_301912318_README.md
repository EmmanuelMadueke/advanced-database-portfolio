# Portfolio 4 — NoSQL and Advanced Data Models

Owner, author, and maintainer: **Emmanuel Madueke**.

## Current stage

**Selected use case: product catalogue enrichment in MongoDB.** Documents supply category-specific descriptive details for the existing fashion-store products. PostgreSQL remains responsible for transactional catalogue facts, inventory, checkout, payments, and delivery.

[Use-case decision and justification](Madueke_Emmanuel_301912318_use-case.md) explains the scope, intended reads, data ownership, synchronisation plan, and alternatives. The [implementation](Madueke_Emmanuel_301912318_implementation.md) now runs on MongoDB 8.0.34 with three SQL-linked profiles, strict validation, 22 import/validation/reconciliation checks, and four fresh-connection checks. The [query and aggregation stage](queries/Madueke_Emmanuel_301912318_README.md) now includes five finds, one aggregation, 16 checks, and a separately verified diagnostic index plan. No performance gain is claimed.

## Activity checklist

- [x] Choose and justify a NoSQL use case from the same fashion store.
- [x] Design the document model and validation rules.
- [x] Implement and populate the NoSQL database.
- [x] Demonstrate queries, aggregation, and a justified index.
- [x] Complete the SQL/NoSQL comparison using actual implementation findings.
- [x] Save implementation evidence and reproduction instructions.

The [document model](Madueke_Emmanuel_301912318_document-model.md), [candidate validator](model/profile-validator.json), and [three illustrative profiles](model/example-profiles.json) define the implemented structure. The validator has now been installed and tested against MongoDB; actual profiles use source IDs resolved from SQL, not the illustrative IDs.

The [SQL/NoSQL suitability comparison](sql-nosql-comparison.md) brings together the verified results, snapshot-synchronisation limits, and SQL alternatives. **Portfolio 4 is complete.** The completed distributed/cloud discussion is in [Portfolio 5](../portfolio-5-distributed-cloud/Madueke_Emmanuel_301912318_README.md).

## Existing foundations

- [Fashion-store case study](../docs/Madueke_Emmanuel_301912318_case-study.md)
- [Relational data dictionary](../docs/Madueke_Emmanuel_301912318_data-dictionary.md)
- [Synthetic catalogue and sample data](../docs/Madueke_Emmanuel_301912318_sample-data.md)
- [Protected checkout evidence](../portfolio-3-transactions-concurrency/protected-concurrency.md)

MongoDB Community 8.0.34 is verified in a local Docker container with a pinned image digest. Reproduction and observed shell versions are recorded in implementation.md. No cloud account or paid service is used.

## Evidence coverage

| Requirement | Retained evidence and explanation |
| --- | --- |
| Use-case choice | [Scope, justification, and ownership](Madueke_Emmanuel_301912318_use-case.md) |
| Document model | [Identifiers, embedding, validation, and units](Madueke_Emmanuel_301912318_document-model.md) |
| Setup and representative data | [Reproduction](Madueke_Emmanuel_301912318_implementation.md), [manifest](evidence/implementation/manifest.json), [stored BSON](evidence/implementation/profiles.ejson) |
| Validation and reconciliation | [22 load checks](evidence/implementation/load-checks.txt), [four fresh-connection checks](evidence/implementation/persisted-checks.txt) |
| Queries and aggregation | [Definitions and results](queries/Madueke_Emmanuel_301912318_README.md), [16 checks](evidence/queries/check-output.txt) |
| Index and limitations | [Unhinted/hinted evidence](evidence/queries/Madueke_Emmanuel_301912318_README.md) |
| SQL/NoSQL suitability | [Comparison and synchronisation boundaries](sql-nosql-comparison.md) |

The final comparison is a documentation synthesis of retained results; no new database execution was needed for that stage. Tests are tool-run evidence. Emmanuel's personal review/reflection and the final assessment-wide audit remain separate tasks.

## Screenshot evidence

See the [assessment screenshot gallery](../evidence/screenshots/Madueke_Emmanuel_301912318_README.md) for captures of retained outputs and diagrams. Captures are labelled separately from the original execution dates; Portfolio 5 remains a discussion.
