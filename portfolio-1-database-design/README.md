# Portfolio 1 — Database Design and Modelling

Owner, author, and maintainer: **Emmanuel Madueke**.

## Current evidence

- [Requirements](../docs/requirements.md)
- [Business rules](../docs/business-rules.md)
- [Entities and attributes](../docs/entities-and-attributes.md)
- [Conceptual ERD documentation](../docs/conceptual-erd.md)
- [Relational schema specification](../docs/relational-schema.md)
- [Data dictionary](../docs/data-dictionary.md)
- [Normalisation analysis](../docs/normalization.md)
- [Standalone ERD image](../diagrams/conceptual-erd.svg)

The conceptual model is complete as a proposed design. The relational schema and data dictionary are specified for PostgreSQL. Normalisation analysis is complete with explicit redundancy and fixed-currency caveats. The SQL implementation and 35 integrity/workflow assertions have passed on PostgreSQL 18.1. Realistic sample data is still pending; Portfolio 1 is not complete yet.

## Viewing the diagram

Open the [full-size SVG image](../diagrams/conceptual-erd.svg) in a browser and zoom as needed. It uses attribute tables, PK/FK labels, and crow’s-foot relationships. Only the image is retained; there is no diagram-generation script.

## SQL implementation and verification

1. [Table definitions and correctness indexes](sql/01_schema.sql)
2. [Integrity and lifecycle triggers](sql/02_integrity.sql)
3. [Controlled checkout, cart, and delivery operations](sql/03_operations.sql)
4. [Demonstration role permissions](sql/04_permissions.sql)

See [setup and reproduction instructions](../docs/setup.md), [integrity tests](tests/integrity.sql), and [actual outputs](evidence/README.md). Tests use temporary fixtures, force deferred validation, and roll back their rows. Realistic seed data and full two-session concurrency demonstrations remain separate tasks.
