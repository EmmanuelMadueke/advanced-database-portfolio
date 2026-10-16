// Owner, author, maintainer: Emmanuel Madueke
// Read-only verification from a new mongosh connection after import.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const assert=require('node:assert/strict');
const root=path.resolve('portfolio-4-nosql');
const out=path.resolve(process.env.PROFILE_OUTPUT_DIR || path.join(root,'evidence/implementation'));
const read=p=>JSON.parse(fs.readFileSync(p,'utf8'));
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const m=read(path.join(out,'manifest.json'));
assert.equal(db.getName(),m.target_database);
for(const [file,key] of [[path.join(out,'source-products.json'),'source_sha256'],[path.join(root,'data/enrichment.json'),'enrichment_sha256'],[path.join(root,'model/profile-validator.json'),'validator_sha256']]) assert.equal(hash(file),m[key]);
print('PASS persisted: source, enrichment, and validator hashes match manifest');
function canonical(x) {
 if(Array.isArray(x)) return '['+x.map(canonical).join(',')+']';
 if(x&&typeof x==='object') return '{'+Object.keys(x).sort().map(k=>JSON.stringify(k)+':'+canonical(x[k])).join(',')+'}';
 return JSON.stringify(x);
}
const expected=require(path.join(root,'scripts/prepare_profiles.cjs')).prepare(read(path.join(out,'source-products.json')),read(path.join(root,'data/enrichment.json'))).sort((a,b)=>a._id.localeCompare(b._id));
const actual=EJSON.serialize(db.product_profiles.find().sort({_id:1}).toArray(),{relaxed:true});
assert.equal(canonical(actual),canonical(expected));assert.equal(actual.length,m.document_count);
print('PASS persisted: exact profiles and SQL references match from fresh connection');
const info=db.getCollectionInfos({name:'product_profiles'})[0];
assert.equal(info.options.validationLevel,'strict');assert.equal(info.options.validationAction,'error');
assert.equal(canonical(EJSON.serialize(info.options.validator,{relaxed:true})),canonical(read(path.join(root,'model/profile-validator.json'))));
print('PASS persisted: strict/error validator matches saved definition');
assert.equal(db.product_profiles.countDocuments({$nor:[info.options.validator]}),0);
print('PASS persisted: all stored documents satisfy validator');
print('4 fresh-connection checks passed. MongoDB '+db.version()+', mongosh '+version());
