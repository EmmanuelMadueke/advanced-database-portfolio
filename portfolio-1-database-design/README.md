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

The conceptual model is complete as a proposed design. The relational schema and data dictionary are specified for PostgreSQL. Normalisation analysis is complete with explicit redundancy and fixed-currency caveats. The SQL implementation and 35 integrity/workflow assertions have passed on PostgreSQL 18.1. Sample data, seed validation, and supporting evidence are complete; Portfolio 1 deliverables are now covered. Later activity evidence is linked from the root README; final reproducibility review remains pending.

## Viewing the diagram

Open the [full-size SVG image](../diagrams/conceptual-erd.svg) in a browser and zoom as needed. It uses attribute tables, PK/FK labels, and crow’s-foot relationships. Only the image is retained; there is no diagram-generation script.

## SQL implementation and verification

1. [Table definitions and correctness indexes](sql/01_schema.sql)
2. [Integrity and lifecycle triggers](sql/02_integrity.sql)
3. [Controlled checkout, cart, and delivery operations](sql/03_operations.sql)
4. [Demonstration role permissions](sql/04_permissions.sql)

See [setup and reproduction instructions](../docs/setup.md), [integrity tests](tests/integrity.sql), and [actual outputs](evidence/README.md). Tests use temporary fixtures, force deferred validation, and roll back their rows. The sample seed and checks are described below. Completed two-session demonstrations are documented in [Portfolio 3](../portfolio-3-transactions-concurrency/README.md).

## Sample data

- [Fashion-store seed](sql/05_sample_data.sql): 12 customers, 8 products, 18 variants, 12 orders, and all order/payment/delivery states.
- [Sample validation](tests/sample_data.sql): 10 assertions, including NGN 268,000.00 in recognised sales and stock reconciliation.
- [Optional scale seed](sql/06_scale_data.sql): 10,000 additional orders by default for later query experiments.
- [Scale validation](tests/scale_data.sql): counts, totals, payments, and inventory reconciliation.

See [dataset scenarios and reproduction](../docs/sample-data.md) and [actual output](evidence/README.md). Run sample validation before the optional scale seed. The seeds are committed data; validation scripts roll back only their own temporary helpers. Data is fictional and event timestamps reflect the run time.

## Screenshot evidence

See the [assessment screenshot gallery](../evidence/screenshots/README.md) for captures of retained outputs and diagrams. Captures are labelled separately from the original execution dates; Portfolio 5 remains a discussion.
