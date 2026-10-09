# AI-use Working Record

Project owner, author, and maintainer: **Emmanuel Madueke**.

## Requirements and modelling

Codex helped interpret the assessment brief and fashion-store case study, organise the portfolio checklist, and draft requirements, business rules, and proposed entities/attributes. It checked the drafts for consistency with the supplied case study.

## Entity relationship diagram

Codex drafted the ERD from the requirements and business rules, including attributes, proposed primary/foreign keys, and crow’s-foot relationships. It checked the 16 entities and 15 direct relationships, SVG structure, and document links. The table-style rendering was visually inspected, and the relationship summary footer was checked structurally.

Emmanuel Madueke supplied a reference diagram to guide the table-style presentation, reviewed the revised appearance, and requested an explicit summary of relationship ratios and optionality. He also required progressive development records and GitHub commits to support the assessment's evidence requirements.

## Relational schema and data dictionary

Codex mapped the ERD to 16 PostgreSQL tables and specified column types, defaults, nullability, keys, uniqueness, deletion policies, and row checks. It documented planned transaction routines and triggers for cross-table totals, payment consistency, inventory, and lifecycle rules, consulting official PostgreSQL documentation. Documentation checks compared table/column coverage with the entity inventory and checked local links. These checks do not establish database runtime correctness.

## PostgreSQL implementation and checks

Codex created table definitions, integrity/lifecycle triggers, controlled purchase/cart/delivery functions, and demonstration-role permissions. It verified them on an isolated PostgreSQL 18.1 cluster using temporary synthetic fixtures. All 35 single-session assertions passed, covering invalid writes, snapshots, purchase finalisation/replay, delivery states, and rollback. Actual output and reproduction instructions are saved in Portfolio 1. These are tool-run checks; no independent student runtime verification is asserted.

## Verification status

Emmanuel's recorded review covers the ERD presentation. Independent student verification remains to be recorded after it occurs. Schema installation and the documented single-session integrity/workflow checks have passed. Realistic seed data, measured performance results, and two-session concurrency evidence remain pending.

## Sources

- MIT 8103 Advanced Database Systems continuous assessment brief, September cohort 2026 (local PDF in guide/).
- Repository case study, README, requirements, business rules, and entity inventory.

- PostgreSQL documentation: [constraints](https://www.postgresql.org/docs/18/ddl-constraints.html), [numeric types](https://www.postgresql.org/docs/18/datatype-numeric.html), [date/time types](https://www.postgresql.org/docs/18/datatype-datetime.html), and [partial indexes](https://www.postgresql.org/docs/18/indexes-partial.html).
