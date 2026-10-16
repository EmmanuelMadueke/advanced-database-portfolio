# Portfolio 4 — NoSQL and Advanced Data Models

Owner, author, and maintainer: **Emmanuel Madueke**.

## Current stage

**Selected use case: product catalogue enrichment in MongoDB.** Documents will supply category-specific descriptive details for the existing fashion-store products. PostgreSQL remains responsible for transactional catalogue facts, inventory, checkout, payments, and delivery.

[Use-case decision and justification](use-case.md) explains the scope, intended reads, data ownership, synchronisation plan, and alternatives. The [implementation](implementation.md) now runs on MongoDB 8.0.34 with three SQL-linked profiles, strict validation, 22 import/validation/reconciliation checks, and four fresh-connection checks. Business-query demonstrations and performance work remain pending.

## Activity checklist

- [x] Choose and justify a NoSQL use case from the same fashion store.
- [x] Design the document model and validation rules.
- [x] Implement and populate the NoSQL database.
- [ ] Demonstrate queries, aggregation, and a justified index.
- [ ] Complete the SQL/NoSQL comparison using actual implementation findings.
- [ ] Save implementation evidence and reproduction instructions.

The [document model](document-model.md), [candidate validator](model/profile-validator.json), and [three illustrative profiles](model/example-profiles.json) now define the next implementation. The validator has now been installed and tested against MongoDB; actual profiles use source IDs resolved from SQL, not the illustrative IDs.

Next: demonstrate case-specific queries, aggregation, and a justified index.

## Existing foundations

- [Fashion-store case study](../docs/case-study.md)
- [Relational data dictionary](../docs/data-dictionary.md)
- [Synthetic catalogue and sample data](../docs/sample-data.md)
- [Protected checkout evidence](../portfolio-3-transactions-concurrency/protected-concurrency.md)

MongoDB Community 8.0.34 is verified in a local Docker container with a pinned image digest. Reproduction and observed shell versions are recorded in implementation.md. No cloud account or paid service is used.
