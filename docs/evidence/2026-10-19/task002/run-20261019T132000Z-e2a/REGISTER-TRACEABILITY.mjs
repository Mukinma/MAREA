// Scoped D01/A authorization and actual isolation blockage; no requirement promotion.
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';
const {parse,stringify}=await import(pathToFileURL(path.join(process.cwd(),'tool/traceability/node_modules/yaml/dist/index.js')));
const run='docs/evidence/2026-10-19/task002/run-20261019T132000Z-e2a',target='docs/MAREA_REQUIREMENTS_STATUS.yaml';
const raw=fs.readFileSync(target,'utf8'),c=parse(raw),prior=parse(fs.readFileSync(run+'/prior-canonical.yaml','utf8'));
assert.deepEqual(c,prior,'Canonical drift; refuse registration');
const baseline=raw.match(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m)[0],at=new Date().toISOString();
const specs=[
 ['AUTH','USER_CONFIRMATION','AUTHORIZATION.md','APROBADO_D01_AUTORIZADO_SOLO_E2A_LOCAL','Human approves D01 and conceptually E2, authorizes A only. No other stages/remote permission.',['LEDGER.md']],
 ['PREPARATION','LOCAL_LAB_PREPARATION','02-partial-preparation.json','PREPARACION_PARCIAL_NO_ACEPTADA','New A baseline reproduced from verified E1 inputs and cold backup restored before Auth; B, fixtures and A DDL not reached.',['01-preflight.json']],
 ['ISOLATION','LOCAL_ISOLATION_PRECONDITION','FAILURE-1792416399489362000.json','BLOQUEADO_PRECONDICION_AISLAMIENTO','Helper interface guard failed before HTTP. No alternative network attempted; all new containers stopped.',['STOP-AFTER-FAILURE-1792416399517860000.json','@tool/task002/e2a_lab.py']],
 ['REPORT','BLOCKED_INCREMENT_REPORT','REPORT.md','E2A_NO_IMPLEMENTADO_NO_ACEPTADO','A blocked by isolation; no A roles/functions/trigger/SQL applied and no signup fixtures or Auth/profile DELETE; next infra authorization required.',['04-traceability-tests.log']],
];
// The stop filename is generated; bind exactly the one actual successful stop receipt.
const stops=fs.readdirSync(run).filter(p=>p.startsWith('STOP-AFTER-FAILURE-'));assert.equal(stops.length,1);
specs[2][5][0]=stops[0];const ids=[];
for(const [suffix,kind,file,result,description,others] of specs){
 const id=`E-TASK002-E2A-${suffix}-20261019`;assert(!c.evidence.some(x=>x.id===id));ids.push(id);
 const paths=[file,...others].map(p=>p.startsWith('@')?p.slice(1):run+'/'+p);
 c.evidence.push({id,kind,path:paths[0],captured_at:at,result,description,environment:'New local synthetic A/recovery copies only; effective network isolation guard failed, execution stopped',
  scope:'E2_A_ONLY_BLOCKED_BEFORE_IMPLEMENTATION',complete_requirement_validation:false,E2A_implementation_validated:false,E2A_functional_cases_passed:0,remote_modified:false,
  file_refs:paths.map(p=>({path:p,sha256:crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex')}))});
 c.evidence_normative_bindings.push({evidence_id:id,normative_version:'SRS-5.1.1',scope:'SCOPED_AUTHORIZATION_AND_BLOCKAGE_NOT_PRODUCT_VALIDATION'});
}
const t=c.next_tasks.find(x=>x.id==='TASK-002'),previous=structuredClone(t.documentary_progress);
t.documentary_history.push({at,previous,reason:'Human approves D01/A local only; preparation stopped at failed effective isolation predicate before A implementation/fixtures. No broader scope attempted.',evidence_ids:ids});
Object.assign(t.documentary_progress,{E2_architecture:'APROBADA_CONCEPTUALMENTE',E2_D01:'APROBADO',E2_A_authorized:true,E2_A:'BLOQUEADO_PRECONDICION_AISLAMIENTO_NO_IMPLEMENTADO',
 E2_A_authorization:{scope:'NEW_LOCAL_SYNTHETIC_COPIES_PRIVATE_IDENTITY_SYNC_REPAIR_ONLY',D01_approved:true,Auth_profile_deletion_authorized:false,other_stages_authorized:false,remote_authorized:false},
 E2_pending_decisions:previous.E2_pending_decisions.filter(x=>x!=='D01'),evidence_ids:[...previous.evidence_ids,...ids],complete:false});
assert.deepEqual(c.requirements,prior.requirements);assert.deepEqual(c.test_cases,prior.test_cases);assert.deepEqual(c.normative_context,prior.normative_context);
assert.deepEqual(c.evidence.slice(0,prior.evidence.length),prior.evidence);
fs.writeFileSync(target,stringify(c,{lineWidth:0,aliasDuplicateObjects:false}).replace(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m,baseline));
console.log(JSON.stringify({old_evidence_preserved:prior.evidence.length,new_evidence:ids,D01:'APPROVED',A:'BLOCKED_NOT_IMPLEMENTED',TASK002_complete:false},null,2));
