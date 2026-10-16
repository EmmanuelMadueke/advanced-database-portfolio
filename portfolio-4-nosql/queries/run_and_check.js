// Owner, author, maintainer: Emmanuel Madueke
// Requires the verified three-profile fixture and only its default _id index.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),crypto=require('node:crypto');
const root=path.resolve('portfolio-4-nosql');
const input=path.resolve(process.env.PROFILE_OUTPUT_DIR || path.join(root,'evidence/implementation'));
const out=path.resolve(process.env.QUERY_OUTPUT_DIR || path.join(root,'evidence/queries'));
const q=require(path.join(root,'queries/catalogue.cjs'));
const manifest=JSON.parse(fs.readFileSync(path.join(input,'manifest.json'),'utf8'));
assert.equal(db.getName(),manifest.target_database);
assert(!fs.existsSync(out),'query output directory already exists');
const c=db.product_profiles;
assert.equal(c.countDocuments({}),3,'requires three-profile fixture');
const beforeIndexes=c.getIndexes();
assert.equal(beforeIndexes.length,1,'requires baseline with only _id index');
assert.equal(beforeIndexes[0].name,'_id_');
const plain=x=>EJSON.serialize(x,{relaxed:true});
function canonical(x) {
 if(Array.isArray(x)) return '['+x.map(canonical).join(',')+']';
 if(x&&typeof x==='object') return '{'+Object.keys(x).sort().map(k=>JSON.stringify(k)+':'+canonical(x[k])).join(',')+'}';
 return JSON.stringify(x);
}
const initial=plain(c.find().sort({_id:1}).toArray());
const saved=plain(EJSON.parse(fs.readFileSync(path.join(input,'profiles.ejson'),'utf8')));
assert.equal(canonical(initial),canonical(saved),'stored profiles must match recorded fixture');
const shirt=initial.find(d=>d.sql_context.name==='Classic T-Shirt');
assert(shirt,'shirt profile missing');
const specs=[['product_lookup',q.lookup(shirt._id)],['cotton_clothing',q.material()],
 ['lace_up_footwear',q.footwear()],['pocket_accessories',q.accessory()],['everyday_profiles',q.tagged()]];
const before={};
for(const [name,filter] of specs) before[name]=plain(c.find(filter,q.projection).sort({_id:1}).toArray());
before.tag_coverage=plain(c.aggregate(q.tagSummary).toArray());
let checks=0;
function check(label,ok) {assert(ok,label);checks++;print('PASS: '+label);}
const names=rows=>rows.map(d=>d.sql_context.name).sort().join('|');
check('lookup returns requested shirt',names(before.product_lookup)==='Classic T-Shirt');
check('cotton at least 90 percent',names(before.cotton_clothing)==='Classic T-Shirt');
check('lace-up footwear',names(before.lace_up_footwear)==='Canvas Sneakers');
check('pocket accessory at least 30 cm wide',names(before.pocket_accessories)==='Tote Bag');
check('everyday tag spans two categories',names(before.everyday_profiles)==='Classic T-Shirt|Tote Bag');
check('tag aggregation exact counts and order',canonical(before.tag_coverage)===canonical([
 {tag:'everyday',profile_count:2},{tag:'casual',profile_count:1},{tag:'reusable',profile_count:1}]));
check('cotton 95 percent boundary included',c.countDocuments(q.material('cotton',95))===1);
check('cotton 96 percent excludes shirt',c.countDocuments(q.material('cotton',96))===0);
check('same-element matching excludes elastane 90 percent',c.countDocuments(q.material('elastane',90))===0);
const misleading=c.countDocuments({profile_type:'clothing','attributes.composition.material':'elastane','attributes.composition.percent':{$gte:90}});
check('separate array predicates demonstrate cross-element false match',misleading===1);
check('absent product returns no profile',c.countDocuments(q.lookup('9223372036854775807'))===0);
check('absent tag returns empty',c.countDocuments(q.tagged('formal'))===0);
check('width 34 inclusive, 35 excluded',c.countDocuments(q.accessory(34))===1 && c.countDocuments(q.accessory(35))===0);
const planBefore=c.find(q.material(),q.projection).sort({_id:1}).explain('executionStats');
const statsBefore=db.runCommand({collStats:'product_profiles'});
fs.mkdirSync(out,{recursive:true});
const save=(name,data)=>fs.writeFileSync(path.join(out,name),EJSON.stringify(data,null,2,{relaxed:false})+'\n',{flag:'wx'});
save('results-before.ejson',before);save('plan-before.ejson',planBefore);
const index=c.createIndex(q.indexKeys,{name:q.indexName});
assert.equal(index,q.indexName);
const planAfter=c.find(q.material(),q.projection).sort({_id:1}).explain('executionStats');
const after={};
for(const [name,filter] of specs) after[name]=plain(c.find(filter,q.projection).sort({_id:1}).toArray());
after.tag_coverage=plain(c.aggregate(q.tagSummary).toArray());
check('all six complete ordered outputs unchanged after index creation',canonical(before)===canonical(after));
check('profiles unchanged by queries/index creation',canonical(initial)===canonical(plain(c.find().sort({_id:1}).toArray())));
const statsAfter=db.runCommand({collStats:'product_profiles'});
const afterIndexes=c.getIndexes();
check('original identity index retained and exactly one reporting index added',afterIndexes.length===2 && afterIndexes.some(i=>i.name==='_id_') && afterIndexes.some(i=>i.name===q.indexName));
save('results-after.ejson',after);save('plan-after.ejson',planAfter);
function planSummary(plan) {
 const s=plan.executionStats;
 return {returned:s.nReturned,keys_examined:s.totalKeysExamined,documents_examined:s.totalDocsExamined,execution_ms:s.executionTimeMillis,winning_plan:plan.queryPlanner.winningPlan};
}
const summary={captured_at:new Date().toISOString(),mongodb_version:db.version(),database:db.getName(),
 profile_count:initial.length,checks,query_sha256:crypto.createHash('sha256').update(fs.readFileSync(path.join(root,'queries/catalogue.cjs'))).digest('hex'),
 result_sha256:crypto.createHash('sha256').update(canonical(before)).digest('hex'),
 before:planSummary(planBefore),after:planSummary(planAfter),
 indexes_before:beforeIndexes,indexes_after:afterIndexes,
 index_bytes_before:statsBefore.indexSizes,index_bytes_after:statsAfter.indexSizes};
save('summary.ejson',summary);
print(EJSON.stringify(summary,null,2,{relaxed:true}));
print(checks+' query/index checks passed. Single explain runs on three profiles are not a latency benchmark.');
