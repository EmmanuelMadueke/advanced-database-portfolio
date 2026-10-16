# Query and index evidence

Owner, author, and maintainer: **Emmanuel Madueke**.

These outputs were captured from MongoDB 8.0.34, fashion_profiles_complete.product_profiles, with the three previously verified profiles. The actual capture timestamp is retained in summary.ejson.

- [Sixteen checks and summary](check-output.txt)
- [Complete results before](results-before.ejson) and [after](results-after.ejson)
- [Unhinted plan before](plan-before.ejson) and [after](plan-after.ejson)
- [Summary, hashes, index definitions and sizes](summary.ejson)
- [Explicitly hinted diagnostic plan](plan-hinted.ejson) and [one additional equivalence check](hinted-check-output.txt)

Normal planning retained the `_id_` scan (3 keys/3 documents). The separately hinted diagnostic used the composition index (1 key/1 document) plus a sort. No speedup is claimed from these single runs. All six normal outputs and stored profiles were unchanged. See [query semantics, index rationale, and reproduction](../../queries/README.md).
