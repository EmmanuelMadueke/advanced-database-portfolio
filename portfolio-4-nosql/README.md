# Portfolio 4 — NoSQL and Advanced Data Models

Owner, author, and maintainer: **Emmanuel Madueke**.

## Current stage

**Selected use case: product catalogue enrichment in MongoDB.** Documents will supply category-specific descriptive details for the existing fashion-store products. PostgreSQL remains responsible for transactional catalogue facts, inventory, checkout, payments, and delivery.

[Use-case decision and justification](use-case.md) explains the scope, intended reads, data ownership, synchronisation plan, and alternatives. This is a design decision; no MongoDB server connection, collection, validator, query output, or performance result has yet been verified.

## Activity checklist

- [x] Choose and justify a NoSQL use case from the same fashion store.
- [x] Design the document model and validation rules.
- [ ] Implement and populate the NoSQL database.
- [ ] Demonstrate queries, aggregation, and a justified index.
- [ ] Complete the SQL/NoSQL comparison using actual implementation findings.
- [ ] Save implementation evidence and reproduction instructions.

The [document model](document-model.md), [candidate validator](model/profile-validator.json), and [three illustrative profiles](model/example-profiles.json) now define the next implementation. Their JSON structure has been checked locally; MongoDB validation has not been run.

Next: verify the MongoDB runtime, implement collection setup/import, and populate profiles using actual SQL IDs and reconciliation.

## Existing foundations

- [Fashion-store case study](../docs/case-study.md)
- [Relational data dictionary](../docs/data-dictionary.md)
- [Synthetic catalogue and sample data](../docs/sample-data.md)
- [Protected checkout evidence](../portfolio-3-transactions-concurrency/protected-concurrency.md)

The MongoDB server version, installation route, and runtime availability will be recorded when verified. The earlier development inventory found mongosh, but that does not establish a working MongoDB server. No cloud account or paid service is required by this use-case decision.
