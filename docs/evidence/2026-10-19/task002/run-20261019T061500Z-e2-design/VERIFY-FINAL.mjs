// Documentary acceptance only: no Docker, SQL, network or product mutation.
import fs from 'node:fs';import cp from 'node:child_process';import path from 'node:path';import crypto from 'node:crypto';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';
const {parse}=await import(pathToFileURL(path.join(process.cwd(),'tool/traceability/node_modules/yaml/dist/index.js')));
const run='docs/evidence/2026-10-19/task002/run-20261019T061500Z-e2-design';
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const before=JSON.parse(fs.readFileSync(run+'/00-before.json','utf8'));const changed=[];
for(const f of before.files){assert(fs.existsSync(f.path),`Missing ${f.path}`);if(hash(f.path)!==f.sha256)changed.push(f.path);}
assert.deepEqual(changed.sort(),['docs/MAREA_AUDIT_REPORT.md','docs/MAREA_REQUIREMENTS_STATUS.yaml']);
const raw=fs.readFileSync('docs/MAREA_REQUIREMENTS_STATUS.yaml','utf8');const oldRaw=fs.readFileSync(run+'/prior-canonical.yaml','utf8');const c=parse(raw),o=parse(oldRaw);
assert.equal(raw.match(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m)[0],oldRaw.match(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m)[0]);
for(const key of Object.keys(o).filter(k=>!['evidence','evidence_normative_bindings','next_tasks'].includes(k)))assert.deepEqual(c[key],o[key],`Unexpected canonical drift ${key}`);
assert.deepEqual(c.evidence.slice(0,o.evidence.length),o.evidence);
assert.deepEqual(c.evidence_normative_bindings.slice(0,o.evidence_normative_bindings.length),o.evidence_normative_bindings);
for(let i=0;i<o.next_tasks.length;i++){
 const a=structuredClone(c.next_tasks[i]),b=structuredClone(o.next_tasks[i]);
 if(a.id==='TASK-002'){
  assert.deepEqual(a.documentary_history.slice(0,b.documentary_history.length),b.documentary_history);
  assert.deepEqual(a.documentary_history.at(-1).previous,b.documentary_progress);
  for(const [k,v] of Object.entries(b.documentary_progress))if(k!=='evidence_ids')assert.deepEqual(a.documentary_progress[k],v,`Prior progress changed: ${k}`);
  assert.equal(a.documentary_progress.E2_authorized,false);assert.equal(a.documentary_progress.E2_A_authorized,false);assert.equal(a.documentary_progress.complete,false);
  delete a.documentary_progress;delete b.documentary_progress;delete a.documentary_history;delete b.documentary_history;
 }
 assert.deepEqual(a,b);
}
for(const ev of c.evidence.slice(o.evidence.length)){
 assert.equal(ev.functional_E2_tests_executed,0);assert.equal(ev.E2_execution_authorized,false);
 for(const f of ev.file_refs)assert.equal(hash(f.path),f.sha256,`Evidence drift ${f.path}`);
}
const expectedDocs=['E2-TECHNICAL-DESIGN.md','E2-AUTHORIZATION-DOSSIER.md','E2-IMPLEMENTATION-PLAN.md','E2-TEST-MATRIX.md','E2-DEPENDENCY-INVENTORY.json'].map(p=>'docs/task002/'+p);
const oldFiles=new Set(before.files.map(f=>f.path));
function walk(dir){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(dir+'/'+e.name):[dir+'/'+e.name]);}
const created=[...new Set([...cp.execFileSync('git',['ls-files','--cached','--others','--exclude-standard','-z'],{encoding:'utf8'}).split('\0').filter(p=>p&&fs.statSync(p).isFile()&&!oldFiles.has(p)),...walk(run)])];
for(const p of created){assert(p.startsWith(run+'/')||expectedDocs.includes(p),`Unexpected new source ${p}`);assert(!p.endsWith('.sql'),'Executable SQL was not authorized');}
const inv=JSON.parse(fs.readFileSync('docs/task002/E2-DEPENDENCY-INVENTORY.json','utf8'));
for(const f of inv.source_refs)assert.equal(hash(f.path),f.sha256);
for(const a of ['a','b'])assert.equal(hash(`/Users/crisis/Proyectos/marea-backups/task002-e1-20261019T055200Z/${a}-after.json`),inv.sources[a].snapshot_file_sha256);
const matrix=fs.readFileSync('docs/task002/E2-TEST-MATRIX.md','utf8');
const tests=[...matrix.matchAll(/^\| E2-T(\d+) /gm)].map(x=>Number(x[1]));assert.deepEqual(tests,Array.from({length:49},(_,i)=>i+1));
const plan=fs.readFileSync('docs/task002/E2-IMPLEMENTATION-PLAN.md','utf8');
assert(plan.includes('T07 y la parte de baja de T44 se difieren'));assert(plan.includes('recibo C estructural'));assert(plan.includes('T49'));
assert.equal(cp.execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim(),before.head);
assert.equal(cp.execFileSync('git',['diff','--cached','--binary'],{encoding:'utf8'}),before.staged);
const checks=Object.fromEntries(['10-validate-final.log','12-check-final.log','13-idempotence-final.log'].map(p=>[p,fs.readFileSync(run+'/'+p,'utf8').trim()]));
assert.match(checks['10-validate-final.log'],/684 registros, 303 evidencias/);assert.match(checks['12-check-final.log'],/consistentes/);assert.match(checks['13-idempotence-final.log'],/0 archivos modificados/);
assert.match(fs.readFileSync(run+'/04-traceability-tests.log','utf8'),/pass 34/);
const finalPath=run+'/15-complete-file-verification.json';if(!created.includes(finalPath))created.push(finalPath);
const result={at:new Date().toISOString(),result:'PASS_DOCUMENTARY_ONLY',files_checked:before.files.length,initial_manifest_scope:'Git-listed regular files plus explicit CLI cache; prior ignored logs were not rewritten or executed; traceability validates its registered evidence',previous_files_modified:changed,new_files:created,new_file_list_includes_ignored_run_logs:true,
 old_evidence_preserved:o.evidence.length,new_documentary_evidence:c.evidence.length-o.evidence.length,
 requirements_unchanged:c.requirements.length,product_test_cases_unchanged:c.test_cases.length,baseline_literal_unchanged:true,
 E1_artifacts_and_private_snapshots_unchanged:true,SRS_U0_TASK001_proposals_product_sources_and_prior_tools_preserved:true,
 head_and_staged_unchanged:true,E2_tests_planned:tests.length,E2_functional_tests_executed:0,traceability_tool_tests_passed:34,
 Docker_SQL_Auth_Storage_execution_this_turn:false,product_data_modified:false,E2_executed:false,E2_authorized:false,E2_A_authorized:false,
 remote_projects_accessed_or_modified:false,Flutter_RPC_migrations_modified:false,TASK002_complete:false,checks,
 current_design_files:expectedDocs.map(p=>({path:p,sha256:hash(p)}))};
fs.writeFileSync(finalPath,JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify({...result,new_files:`${created.length} listed in receipt`,current_design_files:'5 hashed artifacts in receipt'},null,2));
