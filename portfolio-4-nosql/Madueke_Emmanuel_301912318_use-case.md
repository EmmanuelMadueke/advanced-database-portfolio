# NoSQL use-case decision: product catalogue enrichment

Owner, author, and maintainer: **Emmanuel Madueke**.

## Decision and business purpose

Use **MongoDB**, a document database, for descriptive product profiles that complement the existing PostgreSQL catalogue. The same store sells clothing, footwear, and accessories, but useful purchase descriptions differ across those categories. The current relational products table has one general description; the proposed extension makes selected descriptive facts structured and queryable.

This is an explicit portfolio extension to the case study, not a claim that these attributes were already requested or implemented. Planned values will be synthetic product descriptions, not verified manufacturer specifications.

| Existing product example | Proposed enrichment | Intended use |
| --- | --- | --- |
| Classic T-Shirt | Fabric composition, fit, care instructions | Find cotton-rich clothing and display washing guidance |
| Canvas Sneakers | Upper/sole materials, fastening style | Filter footwear by material and fastening |
| Tote Bag | Dimensions, lining, carrying features | Display capacity-related details and find bags with selected features |

Product detail retrieval, descriptive filtering, and summaries of catalogue content form the workload. One profile per relational product is the initial modelling direction. Sizes, colours, variant prices, and live availability remain in PostgreSQL; variant-specific descriptive exceptions must be addressed explicitly during document-model design if needed.

## Why a document database fits

MongoDB supports documents with different fields and nested structures. This suits related product details whose shape varies by category, without requiring every shirt to have shoe-specific fields or every bag to have garment-care fields. Flexibility still needs explicit rules: shared identifiers and required fields will be validated, along with category-appropriate attribute types. [MongoDB data modelling](https://www.mongodb.com/docs/manual/data-modeling/) and [schema validation](https://www.mongodb.com/docs/manual/core/schema-validation/).

Care instructions, material components, and bounded descriptive lists are normally read with the profile and are candidates for embedding. MongoDB describes embedding as useful when related data is retrieved together. Exact structures and bounds will be designed in the next stage. [Embedded data guidance](https://www.mongodb.com/docs/manual/data-modeling/embedding/).

This decision provides a meaningful document-model exercise, not evidence that MongoDB is faster or that SQL cannot represent these attributes. No performance measurement or scale requirement supports such a claim yet.

## Data ownership and system boundary

| Information | Authoritative source | Planned MongoDB treatment |
| --- | --- | --- |
| Product identity, name, general description, category, brand, audience, active flag | PostgreSQL | Reference product identity; copy only selected descriptive context needed for the exercises |
| Structured enrichment: materials, care, dimensions, feature tags | MongoDB profile in the proposed system | Curated synthetic seed is the reproducible source for this portfolio |
| Variant SKU, size, colour, price, stock | PostgreSQL | No live stock or price copy in the proposed scope |
| Customers, addresses, carts, orders, payments, delivery, sales | PostgreSQL | Outside the document collection |

The profile's relational reference will identify products by product_id, with its representation defined in the next stage. Product names are display labels, not durable cross-store keys. Imports must use IDs from the actual PostgreSQL dataset rather than assuming generated IDs are identical in every fresh database.

A future product page would combine a profile with current SQL variants/prices/availability. Enrichment filters would return product references for relational filtering or retrieval. The portfolio will demonstrate database operations; no storefront or cross-database application is currently implemented. Checkout must continue to validate availability and price through the existing SQL routines, regardless of any catalogue description shown earlier.

## Duplication, synchronisation, and failure policy

Copying a category or brand label into a profile makes descriptive queries easier but creates a second representation that can become stale. The planned portfolio import will use an explicit PostgreSQL export followed by a reproducible MongoDB load, recording the export/import context. Refresh should update copied SQL fields while preserving curated enrichment, or rebuild the disposable demonstration collection from both recorded sources. The exact process and checks remain to be implemented.

There is no automatic foreign key or transaction spanning these two databases in this plan. Import verification must check referenced product IDs, missing profiles, orphan profiles, and copied-field agreement against the chosen export. A SQL deletion or deactivation requires reconciliation of the profile; the document alone must not be treated as proof that a product can be purchased.

Assumption for the exercise: catalogue changes are paused during export/load verification, and all documents are synthetic. A fixed export is a snapshot, not a live synchronisation mechanism. A production system would need an explicit refresh/event-delivery design and monitoring; those are outside this stage.

If enrichment is unavailable, the proposed application could still show the SQL catalogue's general description and perform SQL checkout. This is an intended separation of responsibilities, not an implemented or tested fallback.

## Alternatives and trade-offs

PostgreSQL JSONB could hold structured enrichment alongside the relational product, with JSON processing and indexing while avoiding a second database. It is a credible simpler production alternative for this small project. [PostgreSQL JSON types](https://www.postgresql.org/docs/18/datatype-json.html). Typed category-specific relational tables are another option when attributes are stable and strong relational constraints matter most.

MongoDB is selected here to demonstrate a distinct NoSQL model and its validation/query/aggregation capabilities against the assessment's fashion-store scenario. The cost is another runtime, separate validation, reference reconciliation, and possible duplication. The final comparison will use implementation evidence rather than claiming a universal winner.

Order/delivery event documents were considered but are deferred: the existing workflow already represents those states, and an event-history model would introduce additional event ordering and consistency questions. Flexible product descriptions give this activity a clearer, bounded extension.

## Planned evidence and next step

The implementation should demonstrate a product-profile lookup, category-specific nested/array filters, an aggregation over descriptive attributes, rejection of invalid documents, and an index justified by an actual query. Reconciliation should show that the selected profiles refer to the same relational catalogue and that copied context matches the recorded export. These are planned acceptance criteria, not completed tests.

Next: design the document model, including product ID representation, common and category-specific fields, units, validation, embedding versus referencing, and representative sample documents. Runtime setup, exact MongoDB version, collections, imports, and execution evidence remain pending.
