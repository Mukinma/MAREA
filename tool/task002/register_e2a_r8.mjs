// Append only scoped local evidence; preserve historical baseline and product assessments.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {parse,stringify} from '../traceability/node_modules/yaml/dist/index.js';
const root=new URL('../../',import.meta.url).pathname;
const run='docs/evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8';
const pax='docs/evidence/2026-10-19/task002/run-20261019T143903Z-e2a-r3';
const target=root+'docs/MAREA_REQUIREMENTS_STATUS.yaml';
const oldText=await fs.readFile(target,'utf8'),previous=await fs.readFile(root+run+'/prior-canonical.yaml','utf8');
assert.equal(oldText,previous,'Canonical drift: do not overwrite');
const d=parse(oldText),before=structuredClone(d),task=d.next_tasks.find(x=>x.id==='TASK-002');
assert.equal(d.evidence.length,318);assert.equal(d.requirements.length,684);assert.equal(d.test_cases.length,21);
for(const f of ['06-functional-GREEN.json','06b-constraint-input-negative.json','07-integrity-conservation.json','08-final-cold-recovery.json','10-workspace-preservation.json','99-stopped.json'])assert.equal(JSON.parse(await fs.readFile(root+run+'/'+f,'utf8')).result,'PASS',f);
const now=new Date().toISOString();
const entries=[
 ['PAX-AUTH','LOCAL_SCOPED_AUTHORIZATION','TWO_STAGE_AUTHORIZATION',run+'/AUTHORIZATION.md','Autorización humana de PAX y sólo E2-A en copias nuevas; sin más incrementos.',['tool/task002/e2a_r8.py']],
 ['PAX-TRANSPORT','TEST_EXECUTION','PASS',pax+'/pax/05-PAX-cycle.json','Ciclo PAX sintético exacto mtime/atime ns; negativos y archivos dañados rechazados.',[pax+'/pax/07-actual-negative-archives.json',pax+'/pax/03-precision-RED.json','tool/task002/pax_transport.py','tool/task002/test_pax_transport.py']],
 ['PAX-HISTORY','LOCAL_LAB_DIAGNOSTIC','PRESERVED_FAILED_ATTEMPTS',run+'/ATTEMPT-HISTORY.json','Intentos fallidos cerrados e inmutables; causas y correcciones acotadas sin reutilización.',[pax+'/08-namespace-restart-regression.json',run+'/11-independent-review.md']],
 ['R8-PREFLIGHT','LOCAL_LAB_PREFLIGHT','PASS',run+'/02-full-preflight.json','Gate vacío y completo antes de restaurar/servicios; fuentes E1 y recuperación inicial de DB/Storage.',[run+'/01-empty-preflight.json',run+'/03-new-E1-baselines.json','tool/task002/e2a_r8.py']],
 ['R8-IMPLEMENTATION','LOCAL_LAB_IMPLEMENTATION','PASS',run+'/05-A-transactional-installation.json','A privado: ensayo con reparación y rollback exacto, commit en dos copias; nada de producto remoto.',[run+'/20261019152036_e2a_private_identity.sql']],
 ['R8-FUNCTIONAL','TEST_EXECUTION','PASS',run+'/06-functional-GREEN.json','T01–06/T08 y sólo reparación T44: Auth real, negativos, colisiones, idempotencia/concurrencia; no T07.',[run+'/04-functional-RED.json',run+'/06b-constraint-input-negative.json','tool/task002/e2a_r8_cases.py','tool/task002/e2a_r8_constraints.py']],
 ['R8-CONSERVATION','LOCAL_LAB_CONSERVATION','PASS',run+'/07-integrity-conservation.json','Todas las filas originales conservadas; INSERT fixtures y secuencias exactos, ACL mínimos, Storage idéntico.',[run+'/10-workspace-preservation.json','tool/task002/e2a_r8_verify.py']],
 ['R8-RECOVERY','LOCAL_LAB_RECOVERY','PASS',run+'/08-final-cold-recovery.json','Recuperación PAX física y arranque PostgreSQL con igualdad lógica completa tras A.',[run+'/03-new-E1-baselines.json','tool/task002/e2a_r8_close.py']],
 ['R8-HARNESS','TEST_EXECUTION','PASS',run+'/09-unit-tests.log','Pruebas de guardas/aislamiento/PAX; sólo verificación del laboratorio, sin validar RF integrales.',['tool/task002/test_e2a_r8_gate.py']],
 ['R8-REPORT','LOCAL_INCREMENT_ACCEPTANCE_REPORT','E2A_VALIDATED_LOCAL_ONLY',run+'/REPORT.md','E2-A aceptado sólo en laboratorio sintético; ejecución detenida, resto E2/TASK-002 incompletos.',[run+'/99-stopped.json','tool/task002/register_e2a_r8.mjs']]
];
const newIDs=[];
for(const [suffix,kind,result,path,description,extra] of entries){
 const id='E-TASK002-'+suffix+'-20261019';assert(!d.evidence.some(x=>x.id===id));newIDs.push(id);
 const refs=[];for(const p of [...new Set([path,...extra])])refs.push({path:p,sha256:crypto.createHash('sha256').update(await fs.readFile(root+p)).digest('hex')});
 d.evidence.push({id,kind,path,captured_at:now,result,description,scope:'PAX_AND_E2_A_ONLY_NEW_ISOLATED_SYNTHETIC_LOCAL_COPIES',environment:'Docker local pinned; no original volumes, product data or remote environment',complete_requirement_validation:false,E2A_implementation_validated:suffix.startsWith('R8-')&&!['R8-PREFLIGHT','R8-HARNESS'].includes(suffix),remote_modified:false,file_refs:refs});
 d.evidence_normative_bindings.push({evidence_id:id,normative_version:'SRS-5.1.1',scope:'SCOPED_PAX_AND_E2_A_LOCAL_NOT_COMPLETE_PRODUCT_VALIDATION'});
}
task.documentary_history.push({at:now,previous:structuredClone(task.documentary_progress),reason:'Human authorized PAX fix and new E2-A only. PAX, final recovery, private A, negative/concurrent cases and conservation verified; stopped before S0. All old evidence/assessments preserved.',evidence_ids:newIDs});
Object.assign(task.documentary_progress,{product_implementation:'E1_E2A_PRIVADOS_VALIDADOS_SOLO_LABORATORIO',complete:false,E2:'A_VALIDADO_LOCAL_RESTO_NO_AUTORIZADO',E2_authorized:false,E2_A:'IMPLEMENTADO_VALIDADO_SOLO_COPIAS_LOCALES_SINTETICAS',E2_A_authorized:false,E2_A_resume_authorized:false,E2_A_requires_new_specific_human_approval:true,E2_A_executor:'R8_COMPLETED_STOPPED_NO_NEXT_INCREMENT',E2_A_last_attempt:run,E2_A_last_attempt_preflight:'PASS_EMPTY_AND_COMPLETE_BEFORE_DATA',E2_A_blocker:null,E2_A_local_validation:{functional:'PASS',negative:'PASS',concurrency:'PASS',backup_restore:'PASS',conservation:'PASS',account_deletions:0,T07_executed:false,real_data_compatibility_proven:false},next_increment:{id:'S0',authorized:false,requires_specific_human_approval:true},remote_authorized:false,flutter_authorized:false});
task.documentary_progress.evidence_ids.push(...newIDs);
task.documentary_progress.E2_A_authorization.fulfilled_local_only=true;
assert.deepEqual(d.requirements,before.requirements);assert.deepEqual(d.test_cases,before.test_cases);assert.deepEqual(d.evidence.slice(0,318),before.evidence);
const baseline=oldText.match(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m)[0];
let next=stringify(d,{lineWidth:0});next=next.replace(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m,baseline);
const checked=parse(next);assert.deepEqual(checked.requirements,before.requirements);assert.deepEqual(checked.evidence.slice(0,318),before.evidence);assert.equal(next.match(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m)[0],baseline);
await fs.writeFile(target,next);console.log(JSON.stringify({result:'PASS_APPEND_ONLY',historical_evidence_preserved:318,new_evidence:newIDs.length,requirements_unchanged:684,test_cases_unchanged:21,TASK002_complete:false}));
