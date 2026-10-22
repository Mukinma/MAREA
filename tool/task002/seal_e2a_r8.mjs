// Final read-only checks and source binding after authorized documentary registration.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {parse} from '../traceability/node_modules/yaml/dist/index.js';
const root=new URL('../../',import.meta.url).pathname,run='docs/evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex'),read=p=>fs.readFile(root+p),commands=[];
const derived=['docs/MAREA_TRACKING.md','docs/MAREA_AUDIT_REPORT.md','docs/MAREA_TRACEABILITY.md','docs/MAREA_CHANGELOG.md'];
for(const command of ['validate','check']){
 const r=spawnSync('node',['tool/traceability/cli.mjs',command],{cwd:root,encoding:'utf8'});assert.equal(r.status,0,r.stderr);commands.push({command,exit:r.status,output:r.stdout.trim()});
}
const beforeViews=await Promise.all(derived.map(async p=>({path:p,sha256:sha(await read(p)),mtime_ns:(await fs.stat(root+p,{bigint:true})).mtimeNs.toString()})));
const render=spawnSync('node',['tool/traceability/cli.mjs','render'],{cwd:root,encoding:'utf8'});assert.equal(render.status,0,render.stderr);assert.match(render.stdout,/0 archivos modificados/);
commands.push({command:'second_render',exit:0,output:render.stdout.trim()});
const afterViews=await Promise.all(derived.map(async p=>({path:p,sha256:sha(await read(p)),mtime_ns:(await fs.stat(root+p,{bigint:true})).mtimeNs.toString()})));assert.deepEqual(afterViews,beforeViews);
const currentText=(await read('docs/MAREA_REQUIREMENTS_STATUS.yaml')).toString(),oldText=(await read(run+'/prior-canonical.yaml')).toString(),d=parse(currentText),old=parse(oldText);
for(const key of ['baseline','state_transitions','requirements','test_cases','test_runs','normative_context','normative_versions','preservation','clause_anchors'])assert.deepEqual(d[key],old[key],key);
assert.equal(currentText.match(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m)[0],oldText.match(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m)[0]);
assert.deepEqual(d.evidence.slice(0,318),old.evidence);assert.deepEqual(d.evidence_normative_bindings.slice(0,old.evidence_normative_bindings.length),old.evidence_normative_bindings);
assert.equal(d.evidence.length,328);assert(d.evidence.slice(318).every(e=>e.complete_requirement_validation===false));
assert.deepEqual(d.next_tasks.filter(x=>x.id!=='TASK-002'),old.next_tasks.filter(x=>x.id!=='TASK-002'));
const t=d.next_tasks.find(x=>x.id==='TASK-002'),ot=old.next_tasks.find(x=>x.id==='TASK-002');assert.deepEqual(t.documentary_history.slice(0,ot.documentary_history.length),ot.documentary_history);assert.equal(t.documentary_progress.complete,false);assert.equal(t.documentary_progress.next_increment.authorized,false);
const metrics=spawnSync('node',['tool/traceability/cli.mjs','metrics'],{cwd:root,encoding:'utf8'});assert.equal(metrics.status,0,metrics.stderr);await fs.writeFile(root+run+'/12-metrics.json',metrics.stdout,{flag:'wx'});
const initial=JSON.parse(await read('docs/evidence/2026-10-19/task002/run-20261019T143903Z-e2a-r3/00-before.json')),last=JSON.parse(await read(run+'/00-before.json'));
const allowed=new Set(['docs/MAREA_REQUIREMENTS_STATUS.yaml',...derived]),modified=[];
for(const [path,h] of Object.entries(last.files)){const now=sha(await read(path));if(now!==h){assert(allowed.has(path),'Unauthorized source change '+path);modified.push({path,previous_sha256:h,sha256:now});}}
for(const [path,h] of Object.entries(initial.files))if(!allowed.has(path))assert.equal(sha(await read(path)),h,path);
const git=(...args)=>{const r=spawnSync('git',args,{cwd:root,encoding:'utf8'});assert.equal(r.status,0);return r.stdout.trim();};assert.equal(git('rev-parse','HEAD'),initial.head);assert.equal(git('diff','--cached','--name-only'),initial.staged);assert.equal(git('diff','--name-only'),'');
const proof={result:'PASS',at:new Date().toISOString(),commands,second_render_bytes_and_mtime_unchanged:true,baseline_bytes_unchanged:true,requirements_unchanged:684,canonical_test_cases_unchanged:21,historical_evidence_objects_preserved:318,new_scoped_evidence:10,evidence_count:328,historical_normative_bindings_preserved:true,TASK001_and_all_other_tasks_unchanged:true,prior_TASK002_history_preserved:true,complete_requirement_promotions:0,TASK002_complete:false,next_increment_authorized:false,modified_preexisting_files:modified,SRS_sha256:sha(await read('docs/MAREA_SRS.md')),HEAD:initial.head,commits_created:0,staged_changes:false,initial_registration_correction:'Ten missing scoped normative associations added; first registration retained in TRACEABILITY-FIRST-REGISTRATION.yaml',report_sha256:sha(await read(run+'/REPORT.md')),canonical_sha256:sha(Buffer.from(currentText)),views:afterViews};
await fs.writeFile(root+run+'/12-traceability.json',JSON.stringify(proof,null,2)+'\n',{flag:'wx'});
const manifest={at:new Date().toISOString(),scope:'Files created since first R3 boundary plus actual allowed documentary modifications; private backup content excluded',files:[],modified_preexisting_files:modified};
async function walk(relative){for(const e of await fs.readdir(root+relative,{withFileTypes:true})){if(e.name==='__pycache__'||e.name.endsWith('.raw'))continue;const p=relative+'/'+e.name;if(e.isDirectory())await walk(p);else if(e.isFile()&&!initial.files[p]&&p!==run+'/13-artifact-manifest.json'){const b=await read(p);manifest.files.push({path:p,bytes:b.length,sha256:sha(b)});}}}
await walk('tool/task002');await walk('docs/evidence/2026-10-19/task002');manifest.files.sort((a,b)=>a.path.localeCompare(b.path));await fs.writeFile(root+run+'/13-artifact-manifest.json',JSON.stringify(manifest,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({result:'PASS',evidence:328,requirements_unchanged:684,modified_preexisting_files:modified.map(x=>x.path),new_files:manifest.files.length,TASK002_complete:false}));
