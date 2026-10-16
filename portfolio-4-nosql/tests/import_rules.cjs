// Owner, author, maintainer: Emmanuel Madueke
const assert=require('node:assert/strict');
const {prepare,validId}=require('../scripts/prepare_profiles.cjs');
module.exports=function(source,curated) {
 let count=0;
 function reject(label,fn,pattern) {assert.throws(fn,pattern); console.log('PASS importer: '+label); count++;}
 function change(fn) {const c=JSON.parse(JSON.stringify(curated)); fn(c); return ()=>prepare(source,c);}
 reject('composition total',change(c=>c[0].attributes.composition[0].percent=94),/total 100/);
 reject('duplicate material',change(c=>c[0].attributes.composition[1].material='cotton'),/duplicate canonical/);
 reject('noncanonical tag',change(c=>c[0].tags=['Everyday']),/noncanonical/);
 reject('nonfinite dimensions',change(c=>c[2].attributes.dimensions_cm.width=Infinity),/finite/);
 reject('bigint overflow',()=>validId('9223372036854775808'),/identity/);
 reject('leading-zero ID',()=>validId('01'),/identity/);
 reject('missing SQL product',()=>prepare({...source,products:[]},curated),/exactly one/);
 const ambiguous=JSON.parse(JSON.stringify(source)); ambiguous.products.push({...source.products[0],product_id:'90001'});
 reject('ambiguous source lookup',()=>prepare(ambiguous,curated),/exactly one/);
 reject('duplicate selected product',()=>prepare(source,[...curated,curated[0]]),/duplicate selected/);
 // Verify matching follows source IDs, not illustrative IDs.
 const remapped=JSON.parse(JSON.stringify(source)); remapped.products.forEach((p,i)=>p.product_id=String(80001+i));
 assert(prepare(remapped,curated).every(p=>BigInt(p._id)>=80001n));
 console.log('PASS importer: remapped source IDs preserved'); count++;
 return count;
};
