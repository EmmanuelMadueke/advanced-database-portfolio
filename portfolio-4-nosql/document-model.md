# Product enrichment document model

Owner, author, and maintainer: **Emmanuel Madueke**.

## Scope and status

The proposed collection is `product_profiles` in a dedicated portfolio MongoDB database. It holds one document per enriched PostgreSQL product from one identified source dataset. This stage defines the model, a [candidate MongoDB validator](model/profile-validator.json), and [three illustrative profiles](model/example-profiles.json). No collection has been created and MongoDB acceptance/rejection has not yet been tested.

The profiles describe the existing Classic T-Shirt, Canvas Sneakers, and Tote Bag. Their enrichment is synthetic. Example IDs 1, 5, and 7 illustrate the reference format; they are not a verified export and must be replaced with actual source product IDs during implementation. No import timestamps or runtime outputs are fabricated.

## Identity and source boundary

`_id` is the canonical decimal string of `retail.products.product_id`. A string preserves the full positive PostgreSQL bigint identifier without relying on JavaScript numeric precision. Do not convert the ID to a JavaScript Number. The importer must check the range 1–9223372036854775807 and produce the canonical string without signs, spaces, or leading zeros. The candidate validator checks the string shape and maximum length; it does not enforce the exact bigint upper bound.

Only one source dataset may populate a collection. An import manifest, to be implemented separately, will identify the SQL source/snapshot, export hash, extraction/import times, selected product IDs, schema version, and document count. It must contain no credentials. Rebuilding SQL can reuse generated IDs, so a new dataset requires a fresh disposable MongoDB collection/database and manifest; do not merge it into old profiles merely because numeric IDs match.

There is no duplicate `product_id` field to drift away from `_id`. Product names are labels, not identifiers. MongoDB's `_id` identity will prevent two documents using the same key in the planned collection; its existence does not prove that the key refers to a real SQL product. Source reconciliation provides that check.

## Common fields

All listed fields are required; null is not accepted. Unknown fields are rejected at every defined object level.

| Field | Planned BSON representation | Meaning / limits |
| --- | --- | --- |
| `_id` | string | SQL product ID, positive canonical decimal string, up to 19 digits |
| `schema_version` | int | Exactly 1; future versions require explicit validator/loader changes |
| `profile_type` | string enum | clothing, footwear, or accessory |
| `sql_context` | embedded object | Selected copied SQL facts; all fields below required |
| `sql_context.name` | string | Product display name, 1–160 characters |
| `sql_context.category` | enum | Clothing, Footwear, Accessories; must match profile_type |
| `sql_context.brand` | string | Brand display name, 1–160 characters |
| `sql_context.audience` | enum | women, men, unisex, kids |
| `sql_context.is_active` | bool | Copied product flag, not proof of current purchasability |
| `tags` | string array | 0–12 unique values, each 1–60 characters |
| `attributes` | embedded object | Exactly the fields allowed for the selected profile type |

Strings must begin and end with a non-whitespace character. Tags and material/feature labels use lowercase canonical spelling in the import contract; the validator does not perform case folding or synonym resolution. Empty tags/features mean no curated labels; optional dimensions are omitted when unknown rather than stored as null or zero.

General SQL description is not duplicated. Variant identities, sizes, colours, prices, stock, customers, and purchase history are not embedded in these profiles. The product-level assumptions apply to all its variants; variant-specific material differences are outside version 1 and require a new explicit model, not an arbitrary extra field.

## Category-specific attributes

| Type | Required attributes | Optional attributes / constraints |
| --- | --- | --- |
| clothing | composition, fit, care | No extra fields |
| footwear | upper_materials, sole_materials, fastening | No extra fields |
| accessory | materials, features | dimensions_cm may be omitted |

For clothing, composition contains 1–8 objects with material (1–60 characters) and percent (BSON int/long, 1–100). Percentages are whole percentages in version 1. The importer must reject duplicate material names and require the sum to be exactly 100; the candidate validator only validates each entry and rejects identical array elements. Thus two entries for cotton with different percentages could pass that validator and must fail importer checks. Fit is regular, slim, or relaxed. Care contains 1–10 unique instructions of up to 200 characters.

Footwear upper_materials and sole_materials each contain 1–8 unique strings of up to 60 characters. Fastening is lace-up, slip-on, buckle, or hook-and-loop. Material lists express presence, not percentages.

Accessories have 1–8 unique material strings and 0–12 unique features of up to 80 characters. If dimensions_cm is present, all of height, width, and depth are required, strictly positive, and at most 500 cm. Numeric BSON int, long, double, or decimal values are allowed; the importer must reject nonfinite values. Units are fixed by the field name. There is no generic size/dimension field with an ambiguous unit. A belt need not provide bag-style dimensions; the optional field is intended for appropriate products.

## Embedding versus referencing

Small material lists, care instructions, dimensions, and copied display context are embedded because they are read with one product and have bounded size. No separate MongoDB collections for materials, brands, or categories are planned for this exercise. MongoDB recommends choosing embedding or references around access patterns and duplication trade-offs. [Data-modelling guidance](https://www.mongodb.com/docs/manual/data-modeling/best-practices/).

The product is referenced across stores through `_id`; live transactional details remain in SQL. This avoids copying fast-changing stock into browsing profiles. Copied brand/category/name fields still require refresh and reconciliation. Changing a SQL category must also select and validate the correct attribute branch; a category label cannot simply be changed while retaining incompatible attributes.

## Validation and enforcement responsibilities

[profile-validator.json](model/profile-validator.json) is a MongoDB `$jsonSchema` predicate, not a generic JSON Schema file. It uses BSON types, required/properties, additionalProperties, bounds, uniqueItems, and oneOf category branches. The implementation should install it with strict validation and error action, then test the actual server behaviour. MongoDB supports a subset of JSON Schema draft 4 with BSON extensions; unsupported keywords such as `$ref` are intentionally absent. [MongoDB schema keywords](https://www.mongodb.com/docs/manual/reference/operator/query/jsonschema/) and [validation setup](https://www.mongodb.com/docs/manual/core/schema-validation/specify-json-schema/).

| Responsibility | Planned enforcement |
| --- | --- |
| Required fields, shapes, types, bounds, category branch, unknown fields | Collection validator |
| Unique profile identity | `_id` identity in the collection |
| Exact bigint range, canonical labels, composition total/material uniqueness, finite dimensions | Importer checks before writes |
| Reference exists, selected-product coverage, copied context agrees | Reconciliation against the captured SQL export |
| Schema evolution and enrichment preservation on refresh | Explicit versioned import process |

Use BSON Int32 for schema_version and whole composition percentages when loading through mongosh, rather than relying on implicit conversion of JSON numbers. The example file is JSON design data, not a finished mongosh seed. Business rules assigned to the importer are not enforced against arbitrary direct writes; restrict such writes in a future deployment. The runtime stage must retain both valid-insert results and deliberate rejection results, with failures attributed to the correct layer.

## Import and refresh contract

1. Export selected source products and joined category/brand context in one consistent SQL snapshot. For the first implementation, use the three example products; scope coverage to that explicit selection, not every product in the store.
2. Resolve the named examples to source IDs with an unambiguous lookup. Since product names are not unique constraints, require exactly one match for the chosen product/brand/category combination; reject ambiguity. Record IDs in the manifest and use them for subsequent matching.
3. Combine copied SQL facts with curated enrichment; validate all importer-only rules, then load with the validator enabled. Save exported facts and curated inputs so a disposable dataset can be rebuilt.
4. Verify counts/IDs, zero orphan or missing profiles within the selected set, and copied-field equality. A profile subset is intentional; absent profiles outside the selected set are not failed coverage.
5. For later refresh, preserve attributes/tags while updating source context and revalidating. If source identity changes, a product disappears, or category-specific enrichment becomes incompatible, stop and reconcile explicitly. Do not silently remap profiles by name.

The manifest, export, importer, and reconciliation scripts are planned work. This is batch synchronisation against a recorded snapshot, not live replication or an atomic cross-database transaction.

## Planned validation examples and queries

The three example profiles cover all branches. Future negative cases should include a missing name, a mismatched category/type, forbidden stock/price fields, a negative dimension, an unknown attribute, a duplicate `_id`, and invalid composition totals. The last case tests importer logic, not an asserted database guarantee.

Queries will include product lookup by `_id`, clothing with a specified material percentage, footwear by fastening, and accessory features/dimensions. Use an element-matching predicate when material name and percentage must belong to the same composition element. An aggregation can summarise curated tags/material coverage; it will describe the selected profiles, not sales or live inventory. Additional indexes will be justified with the implemented query workload; none is claimed as installed or measured here.

Next: verify the MongoDB runtime, implement collection setup and the source-aware loader, populate the three profiles, and save actual validation/reconciliation evidence.
