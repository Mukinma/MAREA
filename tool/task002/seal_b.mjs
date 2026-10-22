// Final documentary verification; no database or Docker mutation.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {parse} from '../traceability/node_modules/yaml/dist/index.js';
const root=new URL('../../',import.meta.url).pathname,run='docs/evidence/2026-10-19/task002/run-20261019T212928Z-e2b';
const read=p=>fs.readFile(root+p),sha=b=>crypto.createHash('sha256').update(b).digest('hex'),commands=[];
function execute(command,args){const r=spawnSync(command,args,{cwd:root,encoding:'utf8'});assert.equal(r.status,0,r.stderr||r.stdout);return r.stdout;}
for(const command of ['validate','check'])commands.push({command,output:execute('node',['tool/traceability/cli.mjs',command]).trim(),exit:0});
const derived=['docs/MAREA_TRACKING.md','docs/MAREA_AUDIT_REPORT.md','docs/MAREA_TRACEABILITY.md','docs/MAREA_CHANGELOG.md'];
async function views(){return Promise.all(derived.map(async path=>({path,sha256:sha(await read(path)),mtime_ns:(await fs.stat(root+path,{bigint:true})).mtimeNs.toString()})));}
const beforeViews=await views(),render=execute('node',['tool/traceability/cli.mjs','render']);assert.match(render,/0 archivos modificados/);assert.deepEqual(await views(),beforeViews);commands.push({command:'second_render',output:render.trim(),exit:0});
const tests=execute('node',['--test','--test-reporter=tap','tool/traceability/traceability.test.mjs']);assert.match(tests,/# fail 0/);assert.match(tests,/# tests 34/);await fs.writeFile(root+run+'/20-traceability-tests.log',tests,{flag:'wx'});
const current=await read('docs/MAREA_REQUIREMENTS_STATUS.yaml'),oldText=(await read(run+'/prior-canonical.yaml')).toString(),d=parse(current.toString()),old=parse(oldText);
for(const key of ['baseline','state_transitions','requirements','test_cases','test_runs','normative_context','normative_versions','preservation','clause_anchors'])assert.deepEqual(d[key],old[key],key);
assert.equal(current.toString().match(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m)[0],oldText.match(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m)[0]);
assert.equal(d.evidence.length,348);assert.deepEqual(d.evidence.slice(0,338),old.evidence);assert.deepEqual(d.evidence_normative_bindings.slice(0,old.evidence_normative_bindings.length),old.evidence_normative_bindings);
assert(d.evidence.slice(338).every(e=>e.complete_requirement_validation===false));
assert.deepEqual(d.next_tasks.filter(x=>x.id!=='TASK-002'),old.next_tasks.filter(x=>x.id!=='TASK-002'));
const task=d.next_tasks.find(x=>x.id==='TASK-002'),prior=old.next_tasks.find(x=>x.id==='TASK-002');
assert.deepEqual(task.documentary_history.slice(0,prior.documentary_history.length),prior.documentary_history);
for(const [key,value] of Object.entries(prior.documentary_progress))if(key.startsWith('E2_A')||key.startsWith('E2_S0'))assert.deepEqual(task.documentary_progress[key],value,key);
assert.equal(task.documentary_progress.complete,false);assert.equal(task.documentary_progress.next_increment.authorized,false);assert.equal(task.documentary_progress.flutter_authorized,false);assert.equal(task.documentary_progress.remote_authorized,false);
const initial=JSON.parse(await read(run+'/00-before.json')),allowed=new Set(['docs/MAREA_REQUIREMENTS_STATUS.yaml',...derived]),modified=[];
for(const [path,h] of Object.entries(initial.files)){
 assert(!path.endsWith('.raw'));const now=sha(await read(path));if(now!==h){assert(allowed.has(path),'Unauthorized source change '+path);modified.push({path,previous_sha256:h,sha256:now});}
}
assert(modified.some(x=>x.path==='docs/MAREA_REQUIREMENTS_STATUS.yaml'));
assert(modified.some(x=>x.path==='docs/MAREA_AUDIT_REPORT.md')); 
assert.equal(execute('git',['rev-parse','HEAD']).trim(),initial.head);assert.equal(execute('git',['diff','--cached','--name-only']).trim(),initial.staged);assert.equal(execute('git',['diff','--name-only']).trim(),'');
await fs.writeFile(root+run+'/20-metrics.json',execute('node',['tool/traceability/cli.mjs','metrics']),{flag:'wx'});
const proof={result:'PASS',at:new Date().toISOString(),commands,traceability_tests:34,traceability_tests_failed:0,second_render_bytes_and_mtime_unchanged:true,baseline_bytes_unchanged:true,requirements_unchanged:684,canonical_test_cases_unchanged:21,test_runs_unchanged:true,historical_evidence_objects_preserved:338,new_scoped_evidence:10,evidence_count:348,historical_normative_bindings_preserved:true,TASK001_and_all_other_tasks_unchanged:true,prior_TASK002_history_preserved:true,E2A_and_S0_status_unchanged:true,complete_requirement_promotions:0,TASK002_complete:false,next_increment_authorized:false,modified_preexisting_files:modified,HEAD:initial.head,commits_created:0,staged_changes:false,SRS_sha256:sha(await read('docs/MAREA_SRS.md')),report_sha256:sha(await read(run+'/REPORT.md')),canonical_sha256:sha(current),views:beforeViews};
await fs.writeFile(root+run+'/20-traceability.json',JSON.stringify(proof,null,2)+'\n',{flag:'wx'});
const manifest={at:new Date().toISOString(),scope:'New B tools and evidence only; private archives/credentials and Docker raw image excluded',files:[],modified_preexisting_files:modified};
async function walk(relative){for(const entry of await fs.readdir(root+relative,{withFileTypes:true})){
 if(entry.name==='__pycache__'||entry.name.endsWith('.raw'))continue;
 const path=relative+'/'+entry.name;if(entry.isDirectory())await walk(path);else if(entry.isFile()&&!initial.files[path]&&path!==run+'/21-artifact-manifest.json'){const b=await read(path);manifest.files.push({path,bytes:b.length,sha256:sha(b)});}
}}
await walk('tool/task002');await walk(run);manifest.files.sort((a,b)=>a.path.localeCompare(b.path));
await fs.writeFile(root+run+'/21-artifact-manifest.json',JSON.stringify(manifest,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({result:'PASS',historical_evidence_preserved:338,new_scoped_evidence:10,requirements_unchanged:684,new_files_bound:manifest.files.length,second_render_unchanged:true,TASK002_complete:false}));
