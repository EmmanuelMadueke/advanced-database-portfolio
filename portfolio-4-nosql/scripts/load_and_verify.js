// Owner, author, maintainer: Emmanuel Madueke
// Run with mongosh from the repository root; does not overwrite collections/evidence.
const fs=require('node:fs'), path=require('node:path'), crypto=require('node:crypto');
const assert=require('node:assert/strict');
const root=path.resolve('portfolio-4-nosql');
const out=path.resolve(process.env.PROFILE_OUTPUT_DIR || path.join(root,'evidence/implementation'));
const read=p=>JSON.parse(fs.readFileSync(p,'utf8'));
const sha=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const sourcePath=path.join(out,'source-products.json');
const curatedPath=path.join(root,'data/enrichment.json');
const validatorPath=path.join(root,'model/profile-validator.json');
const source=read(sourcePath),curated=read(curatedPath),validator=read(validatorPath);
const {prepare}=require(path.join(root,'scripts/prepare_profiles.cjs'));
const expected=prepare(source,curated);
const importerChecks=require(path.join(root,'tests/import_rules.cjs'))(source,curated);
assert(/^fashion_profiles(?:_[a-z0-9_]+)?$/.test(db.getName()), 'use dedicated fashion_profiles database');
assert(!db.getCollectionNames().includes('product_profiles'),'collection already exists; use a fresh disposable database');
for(const name of ['manifest.json','profiles.ejson','collection-options.ejson']) assert(!fs.existsSync(path.join(out,name)), 'refusing to overwrite '+name);
function bson(doc) {
 const d=JSON.parse(JSON.stringify(doc)); d.schema_version=NumberInt(d.schema_version);
 if(d.profile_type==='clothing') d.attributes.composition.forEach(c=>c.percent=NumberInt(c.percent));
 return d;
}
assert.equal(db.createCollection('product_profiles',{validator,validationLevel:'strict',validationAction:'error'}).ok,1);
const collection=db.getCollection('product_profiles');
collection.insertMany(expected.map(bson),{ordered:true});
print('Loaded '+expected.length+' profiles into '+db.getName());
let serverChecks=0;
function reject(label,doc,code=121) {
 try { collection.insertOne(bson(doc)); }
 catch(e) {assert.equal(e.code,code,label); print('PASS MongoDB: '+label+' (code '+code+')'); serverChecks++; return;}
 collection.deleteOne({_id:doc._id});
 throw new Error('invalid document accepted: '+label);
}
let nextId=900000;
function invalid(base,mutate) {const d=JSON.parse(JSON.stringify(base));d._id=String(nextId++); mutate(d);return d;}
reject('missing name',invalid(expected[0],d=>delete d.sql_context.name));
reject('category/type mismatch',invalid(expected[0],d=>d.sql_context.category='Footwear'));
reject('forbidden stock field',invalid(expected[0],d=>d.stock=1));
reject('negative dimensions',invalid(expected[2],d=>d.attributes.dimensions_cm.width=-1));
reject('unknown attribute',invalid(expected[1],d=>d.attributes.unsupported=true));
reject('blank label',invalid(expected[0],d=>d.sql_context.name=' '));
reject('duplicate tag',invalid(expected[0],d=>d.tags=['everyday','everyday']));
reject('composition percent out of range',invalid(expected[0],d=>d.attributes.composition[0].percent=101));
reject('duplicate product identity',expected[0],11000);
// Verify update enforcement without altering valid stored data.
let rejectedUpdate=false;
try { collection.updateOne({_id:expected[0]._id},{$set:{'sql_context.is_active':'yes'}}); }
catch(e) { assert.equal(e.code,121); rejectedUpdate=true; }
assert(rejectedUpdate,'invalid update was not rejected');
print('PASS MongoDB: invalid update rejected (code 121)'); serverChecks++;
const actual=collection.find().sort({_id:1}).toArray();
const plain=EJSON.serialize(actual,{relaxed:true});
const sorted=[...expected].sort((a,b)=>a._id.localeCompare(b._id));
function canonical(x) {
 if(Array.isArray(x)) return '['+x.map(canonical).join(',')+']';
 if(x && typeof x==='object') return '{'+Object.keys(x).sort().map(k=>JSON.stringify(k)+':'+canonical(x[k])).join(',')+'}';
 return JSON.stringify(x);
}
assert.equal(canonical(plain),canonical(sorted));
print('PASS reconciliation: exact selected IDs, copied SQL context, and enrichment match; no missing/orphan/extra profiles');
assert.equal(collection.countDocuments({$nor:[validator]}),0);
print('PASS reconciliation: zero documents fail the installed validator');
const info=db.getCollectionInfos({name:'product_profiles'})[0];
assert.equal(info.options.validationLevel,'strict');assert.equal(info.options.validationAction,'error');
const manifest={source_database:source.source_database,source_server:source.server_version,
 exported_at:source.exported_at,imported_at:new Date().toISOString(),source_sha256:sha(sourcePath),
 enrichment_sha256:sha(curatedPath),validator_sha256:sha(validatorPath),
 target_database:db.getName(),mongodb_version:db.version(),mongosh_version:version(),
 schema_version:1,source_product_count:source.products.length,selected_product_ids:expected.map(p=>p._id),
 document_count:actual.length,importer_checks:importerChecks,mongodb_rejection_checks:serverChecks,reconciliation_checks:2};
fs.writeFileSync(path.join(out,'profiles.ejson'),EJSON.stringify(actual,null,2,{relaxed:false})+'\n',{flag:'wx'});
fs.writeFileSync(path.join(out,'collection-options.ejson'),EJSON.stringify(info.options,null,2,{relaxed:false})+'\n',{flag:'wx'});
fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify(manifest,null,2)+'\n',{flag:'wx'});
print(JSON.stringify(manifest,null,2));
print('PASS: '+importerChecks+' importer checks, '+serverChecks+' MongoDB rejection checks, 2 reconciliation checks.');
