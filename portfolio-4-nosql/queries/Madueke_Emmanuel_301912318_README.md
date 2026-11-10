# Product profile queries, aggregation, and index

Owner, author, and maintainer: **Emmanuel Madueke**.

Five catalogue queries and one aggregation now run against the three verified MongoDB profiles. Sixteen result/index checks passed; a separate diagnostic check confirmed that an explicit index hint preserves results. [Actual outputs and plans](../evidence/queries/README.md) are retained.

## Query definitions and meaning

[catalogue.cjs](catalogue.cjs) exports query predicates, the shared projection, and the aggregation pipeline. [run_and_check.js](run_and_check.js) executes those definitions directly, resolves the shirt's actual source ID from the recorded fixture, and verifies results. The projection retains identity, display name, profile type, tags, and attributes. All business queries require the copied SQL is_active flag; that snapshot flag does not establish live availability.

| Definition | Question | Recorded result |
| --- | --- | --- |
| lookup(id) | Retrieve the active profile for this source product ID | Classic T-Shirt, ID `2` in this export |
| material('cotton', 90) | Which active clothing contains at least 90% cotton? | Classic T-Shirt, 95% cotton |
| footwear('lace-up') | Which footwear uses laces? | Canvas Sneakers |
| accessory(30) | Which accessories have an inner pocket and width at least 30 cm? | Tote Bag, 34 cm wide |
| tagged('everyday') | Which profiles have the everyday tag? | Tote Bag and Classic T-Shirt |
| tagSummary | How many active selected profiles carry each tag? | everyday 2; casual 1; reusable 1 |

Find results sort by `_id` as a string for reproducible output; this is not numeric product-ID ordering. The aggregation sorts by count descending and tag ascending to resolve ties. Parameters are query values, not interpolated JavaScript source. These definitions are developer-facing examples, not an application input-validation layer.

The aggregation uses `$match`, `$unwind`, `$group`, `$project`, and `$sort`. Since tag arrays contain unique tags, each unwound tag contributes at most once per profile. Empty tag arrays contribute no tag rows. Counts describe curated coverage among three selected profiles, not sales or all eight source products. A profile may contribute to several tags, so counts are not additive into a distinct product total. See MongoDB's [$unwind reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/unwind/).

## Why element matching matters

The shirt contains cotton at 95% and elastane at 5%. Independent conditions on composition.material='elastane' and composition.percent>=90 incorrectly match this shirt because different elements can satisfy the conditions. The actual material query uses `$elemMatch` on attributes.composition, requiring the same element to satisfy both. The check suite confirms that elastane>=90 returns zero while the deliberately misleading separate-predicate example returns one. [MongoDB $elemMatch](https://www.mongodb.com/docs/manual/reference/operator/query/elemmatch/).

Other checks cover cotton's inclusive 95% boundary and exclusion at 96%, width 34 versus 35 cm, missing ID/tag results, complete aggregation counts/order, unchanged outputs after index creation, unchanged stored profiles, and retention of the identity index. Results cover the documented fixture; no inactive-profile fixture or broad performance dataset was added.

## Index choice and observed plans

The optional index `profile_composition_lookup` has keys:

```javascript
{
  profile_type: 1,
  'attributes.composition.material': 1,
  'attributes.composition.percent': 1
}
```

It serves the clothing/material/percentage predicate. The last two keys share the same composition array path, making this a compound multikey index. `$elemMatch` lets MongoDB combine bounds for material and percentage on that path. [Multikey index bounds](https://www.mongodb.com/docs/manual/core/indexes/index-types/index-multikey/multikey-index-bounds/).

| Capture | Winning access path | Keys examined | Documents examined | Returned |
| --- | --- | --- | --- | --- |
| Before, unhinted | `_id_` scan, fetch/filter | 3 | 3 | 1 |
| After, unhinted | `_id_` scan, fetch/filter | 3 | 3 | 1 |
| After, explicit diagnostic hint | Composition index, fetch/filter, sort | 1 | 1 | 1 |

The automatic planner did not select the new index in this tiny sorted query. The `_id_` scan supplies the requested ordering; the diagnostic composition plan adds a sort. The hinted plan shows bounds for clothing, cotton, and percent>=90, with isMultiKey=true. It still fetches documents to apply remaining conditions and return projected fields; this is not a covered query.

The new index occupies 20,480 bytes in the recorded collection statistics; the existing `_id_` index also occupies 20,480 bytes. These are allocated sizes for this fixture, not per-document costs. Composition changes add index-maintenance work and entries for array values. No write-overhead benchmark was run. The index supports the selected access pattern, but automatic adoption or a production latency benefit requires a larger representative workload. Retain it as an optional experiment index, not a demonstrated optimisation win.

Each plan capture is a single executionStats explain. Recorded execution times were 0 ms before and 1 ms after for the unhinted query; such tiny single-run values do not support a speed claim. No forced hint is added to normal query definitions. All six complete ordered results were identical before and after, and stored profiles were unchanged.

## Reproduce

Use the [implementation instructions](../implementation.md) to obtain the verified three-profile fixture. Start the retained container with `docker start fashion-portfolio-mongo` if needed. From the repository root, set PROFILE_OUTPUT_DIR to the implementation artifacts if using another source/target. The manifest must match the target database.

On a target with only the default `_id_` index, run:

```sh
export QUERY_OUTPUT_DIR=/tmp/fashion-profile-query-repeat
mongosh 'mongodb://127.0.0.1:57017/fashion_profiles_complete?directConnection=true&serverSelectionTimeoutMS=5000' \
  --quiet --file portfolio-4-nosql/queries/run_and_check.js
mongosh 'mongodb://127.0.0.1:57017/fashion_profiles_complete?directConnection=true&serverSelectionTimeoutMS=5000' \
  --quiet --file portfolio-4-nosql/queries/inspect_index.js
```

Use the target database recorded in your own manifest. The output directory must not exist. The runner refuses extra baseline indexes; it never removes existing indexes automatically. It adds only profile_composition_lookup and writes results, plans, hashes, index definitions/sizes, version, count, and execution statistics. The diagnostic script writes a separately labelled hinted plan and refuses overwrite.

For an intentional repeat on the existing demonstration target, first run [remove_index.js](remove_index.js) using the same connection to drop only the optional composition index. This leaves documents and `_id_` intact. Then use a new output directory. A failed run may leave the new index and partial evidence; inspect those before preparing a repeat. The completed experiment leaves its optional index installed. Stop the container after inspection.

Next: complete the SQL-versus-NoSQL suitability comparison using the implemented results, including duplication, validation, reference reconciliation, and the unproven performance benefit.
