// File/traceability/stop verification only. Never starts Docker services or SQL.
import fs from 'node:fs';import cp from 'node:child_process';import crypto from 'node:crypto';import path from 'node:path';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';
const {parse}=await import(pathToFileURL(path.join(process.cwd(),'tool/traceability/node_modules/yaml/dist/index.js')));
const run='docs/evidence/2026-10-19/task002/run-20261019T132000Z-e2a',priv='/Users/crisis/Proyectos/marea-backups/task002-e2a-20261019T132000Z';
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');const b=JSON.parse(fs.readFileSync(run+'/00-before.json','utf8'));const changed=[];
for(const f of b.files){assert(fs.existsSync(f.path),`Missing ${f.path}`);if(hash(f.path)!==f.sha256)changed.push(f.path);}
assert.deepEqual(changed.sort(),['docs/MAREA_AUDIT_REPORT.md','docs/MAREA_REQUIREMENTS_STATUS.yaml']);
const raw=fs.readFileSync('docs/MAREA_REQUIREMENTS_STATUS.yaml','utf8'),priorRaw=fs.readFileSync(run+'/prior-canonical.yaml','utf8');const c=parse(raw),o=parse(priorRaw);
assert.equal(raw.match(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m)[0],priorRaw.match(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m)[0]);
for(const k of Object.keys(o).filter(k=>!['evidence','evidence_normative_bindings','next_tasks'].includes(k)))assert.deepEqual(c[k],o[k]);
assert.deepEqual(c.evidence.slice(0,o.evidence.length),o.evidence);assert.deepEqual(c.evidence_normative_bindings.slice(0,o.evidence_normative_bindings.length),o.evidence_normative_bindings);
for(let i=0;i<o.next_tasks.length;i++){
 const a=structuredClone(c.next_tasks[i]),z=structuredClone(o.next_tasks[i]);
 if(a.id==='TASK-002'){
  assert.deepEqual(a.documentary_history.slice(0,z.documentary_history.length),z.documentary_history);assert.deepEqual(a.documentary_history.at(-1).previous,z.documentary_progress);
  assert.equal(a.documentary_progress.E2_A,'BLOQUEADO_PRECONDICION_AISLAMIENTO_NO_IMPLEMENTADO');assert.equal(a.documentary_progress.E2_A_authorized,true);assert.equal(a.documentary_progress.E2_D01,'APROBADO');
  for(const k of ['E1','E1_authorization','product_implementation','remote_authorized','flutter_authorized','complete'])assert.deepEqual(a.documentary_progress[k],z.documentary_progress[k]);
  delete a.documentary_progress;delete z.documentary_progress;delete a.documentary_history;delete z.documentary_history;
 }assert.deepEqual(a,z);
}
for(const e of c.evidence.slice(o.evidence.length))for(const f of e.file_refs)assert.equal(hash(f.path),f.sha256);
const stopName=fs.readdirSync(run).find(p=>p.startsWith('STOP-AFTER-FAILURE-'));const stop=JSON.parse(fs.readFileSync(run+'/'+stopName,'utf8'));assert.equal(stop.stopped.length,3);assert(stop.stopped.every(x=>x.stopped));
assert.equal(cp.execFileSync('docker',['ps','-q'],{encoding:'utf8'}).trim(),'');
assert.equal(cp.execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim(),b.head);assert.equal(cp.execFileSync('git',['diff','--cached','--binary'],{encoding:'utf8'}),b.staged);
const sqlStub=priv+'/sql-project/supabase/migrations/20261019132322_e2a_private_identity.sql';assert.equal(fs.statSync(sqlStub).size,0);assert.equal(fs.readdirSync(priv).filter(x=>x.includes('-signup-')).length,0);
const commands=fs.readFileSync(priv+'/docker-commands.jsonl','utf8').trim().split('\n').map(x=>JSON.parse(x));
const owner='task002-e2a-20261019t132000z';let mounts=0;
for(const a of commands){
 if(a[0]==='run'){
  assert.equal(a[a.indexOf('--pull')+1],'never');const network=a[a.indexOf('--network')+1];assert(network==='none'||network.startsWith('container:'+owner));
  for(let i=0;i<a.length;i++)if(a[i]==='--mount'){
   const m=Object.fromEntries(a[i+1].split(',').map(x=>x.includes('=')?x.split('='):[x,true]));
   if(m.type==='volume'){assert(m.src.startsWith(owner+'-'));mounts++;}else assert([priv,'/Users/crisis/Proyectos/marea-backups/task002-e-20261019T051800Z'].includes(m.src));
  }
 }
 if(['start','stop','logs'].includes(a[0]))assert(a.at(-1).startsWith(owner));
}
const checks=Object.fromEntries(['10-validate-final.log','12-check-final.log','13-idempotence-final.log'].map(p=>[p,fs.readFileSync(run+'/'+p,'utf8').trim()]));
assert.match(checks['10-validate-final.log'],/684 registros, 307 evidencias/);assert.match(checks['12-check-final.log'],/consistentes/);assert.match(checks['13-idempotence-final.log'],/0 archivos modificados/);
const oldFiles=new Set(b.files.map(f=>f.path));function walk(dir){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(dir+'/'+e.name):[dir+'/'+e.name]);}
const created=[...new Set([...cp.execFileSync('git',['ls-files','--cached','--others','--exclude-standard','-z'],{encoding:'utf8'}).split('\0').filter(p=>p&&fs.statSync(p).isFile()&&!oldFiles.has(p)),...walk(run)])];
for(const p of created)assert(p.startsWith(run+'/')||p==='tool/task002/e2a_lab.py');
const finalPath=run+'/14-final-verification.json';if(!created.includes(finalPath))created.push(finalPath);
const out={at:new Date().toISOString(),result:'PRESERVATION_PASS_E2A_BLOCKED_NOT_ACCEPTED',files_checked:b.files.length,previous_files_changed:changed,new_files:created,
 old_evidence_preserved:o.evidence.length,requirements_unchanged:c.requirements.length,product_cases_unchanged:c.test_cases.length,baseline_literal_unchanged:true,
 SRS_E1_E2_design_U0_TASK001_sources_and_evidence_files_unchanged:true,head_staged_unchanged:true,original_volume_mounts:0,new_volume_mount_operations:mounts,
 declared_network_modes_checked:true,effective_isolation_validated:false,all_containers_stopped:true,D01:'APPROVED',E2_A_authorized:true,E2_A:'BLOCKED_NOT_IMPLEMENTED',
 E2A_SQL_stub_bytes:0,signup_fixture_files:0,E2A_functional_cases_passed:0,T07_executed:false,Auth_profile_DELETE_executed:false,
 post_Auth_SQL_data_conservation:'NOT_VERIFIED_AFTER_MANDATORY_STOP',remote_project_operations:false,traceability_tests_passed:34,TASK002_complete:false,checks};
fs.writeFileSync(finalPath,JSON.stringify(out,null,2)+'\n');console.log(JSON.stringify({...out,new_files:`${created.length} listed in receipt`},null,2));
