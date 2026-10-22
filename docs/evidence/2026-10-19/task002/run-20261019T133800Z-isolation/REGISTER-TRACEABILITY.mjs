import fs from 'node:fs';import crypto from 'node:crypto';import assert from 'node:assert/strict';
import {parse,stringify} from '../../../../../tool/traceability/node_modules/yaml/dist/index.js';
const run='docs/evidence/2026-10-19/task002/run-20261019T133800Z-isolation',target='docs/MAREA_REQUIREMENTS_STATUS.yaml';
const raw=fs.readFileSync(target,'utf8'),c=parse(raw),prior=parse(fs.readFileSync(run+'/prior-canonical.yaml','utf8'));
assert.deepEqual(c,prior,'Canonical drift; stop');
const at=new Date().toISOString(),baseline=raw.match(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m)[0];
const specs=[
 ['AUTH','USER_CONFIRMATION','AUTHORIZATION.md','AUTORIZADO_SOLO_DIAGNOSTICO_AISLAMIENTO','Empty disposable containers and verifier only; no E2-A resumption.',[]],
 ['DIAG','LOCAL_ISOLATION_DIAGNOSTIC','03-reproduction.json','FALSO_POSITIVO_REPRODUCIDO','Kernel built-in inert tunnel templates cause the legacy enumeration predicate to fail; no retrospective certification of old namespaces.',['04-netlink.json','13-kernel-provenance.json','e2a_lab.before.py']],
 ['VERIFIER','LOCAL_EMPTY_LAB_ISOLATION_VERIFICATION','10-live-verification.json','PASS_SOLO_CONTENEDORES_VACIOS','Fixed exact-profile verifier plus disabled forwarding validate fresh empty namespaces; old E2-A executor hard blocked.',['09-live-verified-capture.json','15-exact-existing-verifier.patch','20-verifier-source-manifest.json','@tool/task002/e2a_isolation.py','@tool/task002/e2a_isolation_probe.py','@tool/task002/e2a_isolation_policy.json','@tool/task002/e2a_lab.py']],
 ['TESTS','TEST_EXECUTION','12-isolation-tests.json','PASS','12 verifier test methods and 51 parameterized subcases; no product acceptance or Auth execution.',['11-isolation-tests.log','16-tests-optimized-python.log','17-archived-bootstrap-denied.log','18-traceability-tests.log','@tool/task002/test_e2a_isolation.py']],
 ['REPORT','SCOPED_DIAGNOSTIC_REPORT','REPORT.md','E2A_BLOQUEADO_NO_IMPLEMENTADO','Isolation diagnosis completed only in empty helpers; new human approval required to resume A. Empty DNS JSON representation differences disclosed.',['14-closed-and-preserved.json','14-preservation-first-check-drift.json','19-command-scope-audit.json']],
];
const ids=[];
for(const [suffix,kind,file,result,description,others] of specs){
 const id='E-TASK002-ISOLATION-'+suffix+'-20261019';assert(!c.evidence.some(e=>e.id===id));ids.push(id);
 const paths=[file,...others].map(p=>p.startsWith('@')?p.slice(1):run+'/'+p);
 c.evidence.push({id,kind,path:paths[0],captured_at:at,result,description,environment:'New empty isolated local helpers, no mounts or product data',scope:'ISOLATION_DIAGNOSTIC_ONLY_NO_E2A_RESUMPTION',complete_requirement_validation:false,E2A_implementation_validated:false,remote_modified:false,
 file_refs:paths.map(path=>({path,sha256:crypto.createHash('sha256').update(fs.readFileSync(path)).digest('hex')}))});
 c.evidence_normative_bindings.push({evidence_id:id,normative_version:'SRS-5.1.1',scope:'ISOLATION_DIAGNOSTIC_NOT_PRODUCT_VALIDATION'});
}
const t=c.next_tasks.find(t=>t.id==='TASK-002'),previous=structuredClone(t.documentary_progress);
t.documentary_history.push({at,previous,reason:'Isolation-only authorization: root cause reproduced and empty-lab verifier validated; E2-A resumption expressly not authorized. Historical evidence immutable; no product requirement promotion.',evidence_ids:ids});
Object.assign(t.documentary_progress,{E2_A:'BLOQUEADO_NO_IMPLEMENTADO',E2_A_authorized:false,E2_A_resume_authorized:false,E2_A_requires_new_specific_human_approval:true,E2_A_isolation_diagnostic:'CORREGIDO_VERIFICADO_SOLO_CONTENEDORES_VACIOS',E2_A_isolation_diagnostic_scope:'NO_DATA_NO_VOLUMES_NO_AUTH_NO_SQL_NO_E2A_RESUMPTION',E2_A_historical_authorization_preserved:true,E2_A_executor:'ARCHIVED_HARD_BLOCKED',evidence_ids:[...previous.evidence_ids,...ids],complete:false});
for(const key of Object.keys(prior).filter(k=>!['evidence','evidence_normative_bindings','next_tasks'].includes(k)))assert.deepEqual(c[key],prior[key],key);
assert.deepEqual(c.evidence.slice(0,prior.evidence.length),prior.evidence);
assert.deepEqual(c.evidence_normative_bindings.slice(0,prior.evidence_normative_bindings.length),prior.evidence_normative_bindings);
assert.deepEqual(c.next_tasks.filter(x=>x.id!=='TASK-002'),prior.next_tasks.filter(x=>x.id!=='TASK-002'));
fs.writeFileSync(target,stringify(c,{lineWidth:0,aliasDuplicateObjects:false}).replace(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m,baseline));
console.log(JSON.stringify({old_evidence_unchanged:prior.evidence.length,new_evidence:ids,requirements_unchanged:c.requirements.length,test_cases_unchanged:c.test_cases.length,E2A:'BLOCKED_NOT_IMPLEMENTED',resume_authorized:false},null,2));
