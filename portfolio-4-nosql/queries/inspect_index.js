// Owner, author, maintainer: Emmanuel Madueke
// Explicit diagnostic hint; this is not the normal query planner's choice.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve('portfolio-4-nosql');
const input=path.resolve(process.env.PROFILE_OUTPUT_DIR || path.join(root,'evidence/implementation'));
const out=path.resolve(process.env.QUERY_OUTPUT_DIR || path.join(root,'evidence/queries'));
const manifest=JSON.parse(fs.readFileSync(path.join(input,'manifest.json'),'utf8'));
assert.equal(db.getName(),manifest.target_database);
assert(!fs.existsSync(path.join(out,'plan-hinted.ejson')),'refusing to overwrite hinted plan');
const q=require(path.join(root,'queries/catalogue.cjs'));
const c=db.product_profiles;
const normal=c.find(q.material(),q.projection).sort({_id:1}).toArray();
const hinted=c.find(q.material(),q.projection).sort({_id:1}).hint(q.indexName).toArray();
assert.equal(EJSON.stringify(normal),EJSON.stringify(hinted));
const plan=c.find(q.material(),q.projection).sort({_id:1}).hint(q.indexName).explain('executionStats');
fs.writeFileSync(path.join(out,'plan-hinted.ejson'),EJSON.stringify(plan,null,2,{relaxed:false})+'\n',{flag:'wx'});
print('PASS: explicit index hint returns the same ordered result as the unhinted query');
print(EJSON.stringify({diagnostic_only:true,keys:plan.executionStats.totalKeysExamined,
 documents:plan.executionStats.totalDocsExamined,returned:plan.executionStats.nReturned,
 winning_plan:plan.queryPlanner.winningPlan},null,2,{relaxed:true}));
