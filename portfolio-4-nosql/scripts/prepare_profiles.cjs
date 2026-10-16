// Owner, author, maintainer: Emmanuel Madueke
// Pure import preparation; no database access. Database shape validation follows.
const assert = require('node:assert/strict');
const clone = x => JSON.parse(JSON.stringify(x));
function validId(id) {
  assert(typeof id === 'string' && /^[1-9][0-9]{0,18}$/.test(id) && BigInt(id)<=9223372036854775807n,
    'invalid SQL bigint identity');
}
function canonical(values) {
  assert(Array.isArray(values), 'label array required');
  for (const s of values) assert(typeof s==='string' && s.length>0 && s===s.trim() && s===s.toLowerCase(), 'noncanonical label');
  assert(new Set(values).size===values.length, 'duplicate canonical label');
}
function prepare(source, curated) {
  assert(Array.isArray(source.products) && Array.isArray(curated) && curated.length>0, 'source and enrichment arrays required');
  const sourceIds = new Set();
  for (const p of source.products) { validId(p.product_id); assert(!sourceIds.has(p.product_id),'duplicate source ID'); sourceIds.add(p.product_id); }
  const selected = new Set();
  return curated.map(e => {
    const matches=source.products.filter(p=>['name','category','brand'].every(k=>p[k]===e.selector[k]));
    assert(matches.length===1,'selector must match exactly one source product');
    const p=matches[0];
    assert(!selected.has(p.product_id),'duplicate selected product'); selected.add(p.product_id);
    const mapping={clothing:'Clothing',footwear:'Footwear',accessory:'Accessories'};
    assert(mapping[e.profile_type]===p.category,'profile type/category mismatch');
    canonical(e.tags);
    const a=e.attributes;
    if(e.profile_type==='clothing') {
      canonical(a.composition.map(c=>c.material));
      assert(a.composition.every(c=>Number.isInteger(c.percent)&&c.percent>0&&c.percent<=100) && a.composition.reduce((s,c)=>s+c.percent,0)===100, 'composition must total 100 whole percent');
    } else if(e.profile_type==='footwear') {
      canonical(a.upper_materials); canonical(a.sole_materials);
    } else {
      canonical(a.materials); canonical(a.features);
      if(a.dimensions_cm) for(const n of Object.values(a.dimensions_cm)) assert(typeof n==='number' && Number.isFinite(n),'dimensions must be finite numbers');
    }
    return {_id:p.product_id,schema_version:1,profile_type:e.profile_type,
      sql_context:Object.fromEntries(['name','category','brand','audience','is_active'].map(k=>[k,p[k]])),
      tags:clone(e.tags),attributes:clone(a)};
  });
}
module.exports={prepare,validId};
