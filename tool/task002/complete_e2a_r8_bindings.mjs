// Complete missing normative associations only; retain first registration for history.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {parse,stringify} from '../traceability/node_modules/yaml/dist/index.js';
const root=new URL('../../',import.meta.url).pathname,run='docs/evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8';
const p=root+'docs/MAREA_REQUIREMENTS_STATUS.yaml',text=await fs.readFile(p,'utf8'),d=parse(text),prior=parse(await fs.readFile(root+run+'/prior-canonical.yaml','utf8'));
const missing=d.evidence.filter(e=>!d.evidence_normative_bindings.some(b=>b.evidence_id===e.id));assert.equal(missing.length,10);assert.equal(d.evidence.length,328);
assert.deepEqual(d.evidence.slice(0,318),prior.evidence);assert.deepEqual(d.requirements,prior.requirements);assert.deepEqual(d.evidence_normative_bindings,prior.evidence_normative_bindings);
await fs.writeFile(root+run+'/TRACEABILITY-FIRST-REGISTRATION.yaml',text,{flag:'wx'});
for(const e of missing)d.evidence_normative_bindings.push({evidence_id:e.id,normative_version:'SRS-5.1.1',scope:'SCOPED_PAX_AND_E2_A_LOCAL_NOT_COMPLETE_PRODUCT_VALIDATION'});
const registrar='tool/task002/register_e2a_r8.mjs',sha=crypto.createHash('sha256').update(await fs.readFile(root+registrar)).digest('hex');
for(const e of d.evidence.slice(318))for(const ref of e.file_refs??[])if(ref.path===registrar)ref.sha256=sha;
const baseline=text.match(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m)[0];
let next=stringify(d,{lineWidth:0}).replace(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m,baseline);
await fs.writeFile(p,next);
await fs.writeFile(root+run+'/TRACEABILITY-BINDING-CORRECTION.json',JSON.stringify({result:'APPLIED_PENDING_VALIDATION',initial_validator_error:'10 missing evidence normative bindings',new_bindings_only:missing.map(e=>e.id),historical_evidence_preserved:318,requirements_unchanged:684,baseline_unchanged:true,complete_requirement_validation:false},null,2)+'\n',{flag:'wx'});
console.log('Completed ten scoped associations; original 318 preserved');
