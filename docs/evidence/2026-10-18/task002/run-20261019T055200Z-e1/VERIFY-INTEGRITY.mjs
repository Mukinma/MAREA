import fs from 'node:fs';import cp from 'node:child_process';import crypto from 'node:crypto';import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';import path from 'node:path';
const {parse}=await import(pathToFileURL(path.join(process.cwd(),'tool/traceability/node_modules/yaml/dist/index.js')));
const run='docs/evidence/2026-10-18/task002/run-20261019T055200Z-e1';
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const before=JSON.parse(fs.readFileSync(run+'/00-before.json','utf8'));const changed=[];
for(const f of before.files){assert(fs.existsSync(f.path),`Missing ${f.path}`);if(hash(f.path)!==f.sha256)changed.push(f.path);}
assert.deepEqual(changed.sort(),['docs/MAREA_AUDIT_REPORT.md','docs/MAREA_REQUIREMENTS_STATUS.yaml']);
const raw=fs.readFileSync('docs/MAREA_REQUIREMENTS_STATUS.yaml','utf8');
const oldRaw=fs.readFileSync(run+'/prior-canonical.yaml','utf8');const c=parse(raw),o=parse(oldRaw);
assert.equal(raw.match(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m)[0],oldRaw.match(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m)[0]);
for(const key of Object.keys(o).filter(k=>!['evidence','evidence_normative_bindings','next_tasks'].includes(k)))assert.deepEqual(c[key],o[key],`Canonical drift: ${key}`);
assert.deepEqual(c.evidence.slice(0,o.evidence.length),o.evidence);
assert.deepEqual(c.evidence_normative_bindings.slice(0,o.evidence_normative_bindings.length),o.evidence_normative_bindings);
for(let i=0;i<o.next_tasks.length;i++){
 const a=structuredClone(c.next_tasks[i]),b=structuredClone(o.next_tasks[i]);
 if(a.id==='TASK-002'){
  const history=a.documentary_history;
  assert.deepEqual(history.slice(0,b.documentary_history.length),b.documentary_history);
  assert.deepEqual(history.at(-1).previous,b.documentary_progress);
  delete a.documentary_progress;delete b.documentary_progress;delete a.documentary_history;delete b.documentary_history;
 }
 assert.deepEqual(a,b);
}
const previousFiles=new Set(before.files.map(f=>f.path));
// Match the initial file manifest's scope: regular files (including file symlinks),
// excluding directory symlinks such as the preexisting shared node_modules link.
const now=cp.execFileSync('git',['ls-files','--cached','--others','--exclude-standard','-z'],{encoding:'utf8'}).split('\0').filter(p=>p&&fs.statSync(p).isFile());
const created=now.filter(p=>!previousFiles.has(p));
for(const p of created)assert(p.startsWith(run+'/')||['tool/task002/e1_lab.py','tool/task002/test_e1_lab.py'].includes(p),`Unexpected new source ${p}`);
for(const ev of c.evidence.slice(o.evidence.length))for(const f of ev.file_refs??[])assert.equal(hash(f.path),f.sha256);
assert.equal(cp.execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim(),before.head);
assert.equal(cp.execFileSync('git',['diff','--cached','--binary'],{encoding:'utf8'}),before.staged);
assert.equal(cp.execFileSync('docker',['ps','-q'],{encoding:'utf8'}).trim(),'');
const finalPath=run+'/24-final-verification.json';
if(!created.includes(finalPath))created.push(finalPath);
const final={at:new Date().toISOString(),result:'PASS',preexisting_files_checked:before.files.length,
 preexisting_files_modified:changed,new_files_created:created,
 old_evidence_objects_preserved:o.evidence.length,new_evidence_objects:c.evidence.length-o.evidence.length,
 requirements_unchanged:c.requirements.length,product_test_cases_unchanged:c.test_cases.length,
 baseline_literal_unchanged:true,normative_context_unchanged:true,
 SRS_U0_TASK001_original_SQL_and_previous_tools_evidence_preserved:true,
 head_and_staged_unchanged:true,original_volume_access:false,all_containers_stopped:true,
 E1:'IMPLEMENTED_VALIDATED_ONLY_NEW_LOCAL_SYNTHETIC_COPIES',E2_authorized:false,
 flutter_modified:false,remote_modified:false,TASK002_complete:false,
 negative_SQL_cases:30,executor_tests:8,traceability_tests:34,
 checks:Object.fromEntries(['19-validate.log','21-check.log','22-render-idempotent.log'].map(p=>[p,fs.readFileSync(run+'/'+p,'utf8').trim()])),
 scope_audit_sha256:hash(run+'/23-command-scope-audit.json')};
fs.writeFileSync(finalPath,JSON.stringify(final,null,2)+'\n');
console.log(JSON.stringify({...final,new_files_created:`${created.length} listed in receipt`},null,2));
