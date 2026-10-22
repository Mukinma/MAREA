// Scoped laboratory receipt only; preserve every historical requirement and test.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {parse,stringify} from '../traceability/node_modules/yaml/dist/index.js';
const root=new URL('../../',import.meta.url).pathname,run='docs/evidence/2026-10-19/task002/run-20261019T185927Z-e2s0';
const target=root+'docs/MAREA_REQUIREMENTS_STATUS.yaml',text=await fs.readFile(target,'utf8');
assert.equal(text,await fs.readFile(root+run+'/prior-canonical.yaml','utf8'),'Canonical drift');
const d=parse(text),before=structuredClone(d),task=d.next_tasks.find(x=>x.id==='TASK-002');
assert.equal(d.evidence.length,328);assert.equal(d.requirements.length,684);assert.equal(d.test_cases.length,21);
for(const file of ['01-empty-preflight.json','02-full-preflight.json','03-clones-recovery.json','10-T49-GREEN.json','15-additional-tests.json','23-space-reference-GREEN.json','25-data-conservation-v3.json','26-final-recovery-v3.json','27-workspace-preservation.json','99-stopped-v3.json'])assert.equal(JSON.parse(await fs.readFile(root+run+'/'+file,'utf8')).result,'PASS',file);
const now=new Date().toISOString(),entries=[
 ['AUTH','LOCAL_SCOPED_AUTHORIZATION','LOCAL_S0_ONLY','AUTHORIZATION.md','Autorización exclusiva S0 sintético; sin activación operativa ni otros incrementos.',[]],
 ['PREFLIGHT','LOCAL_LAB_PREFLIGHT','PASS','02-full-preflight.json','Preflight vacío/completo antes de datos; imágenes fijadas, namespaces y clones E2-A recuperados.',['01-empty-preflight.json','03-clones-recovery.json','@tool/task002/s0_lab.py','@tool/task002/s0_lab_v2.py']],
 ['IMPLEMENTATION','LOCAL_LAB_IMPLEMENTATION','PASS','23-space-reference-GREEN.json','Corte real y barreras SQL/bytes RO; versión corregida incluye space. Sólo mantenimiento local.',['20261019191834_e2s0_local_fence.sql','20261019205128_e2s0_space_reference_review.sql','S0-GUARD-MANIFEST-v3.json','28-SQL-artifact-provenance.json','@tool/task002/s0_fence_v3.py','@tool/task002/s0/ingress.ts']],
 ['T49','TEST_EXECUTION','PASS','10-T49-GREEN.json','T49 real A/B: FileBackend detenido antes de borrar, transacción revertida, reintento privilegiado rechazado, bytes y referencias exactos. Corrección posterior sólo refuerza dos guardas.',['06-T49-RED.json','T49-a-cut.json','T49-b-cut.json','@tool/task002/s0_green.py']],
 ['NEGATIVE','TEST_EXECUTION','PASS','15-additional-tests.json','70 comprobaciones reales A/B: APIs privilegiadas, siete buckets, fallos/reintentos, respuesta descartada tras commit, concurrencia e idempotencia.',['14-CORS-GREEN.json','17-SQL-denial-classification.json','@tool/task002/s0_extra_v2.py']],
 ['REVIEW','TEST_EXECUTION','PASS','23-space-reference-GREEN.json','P1 de referencias space reproducido con rollback y corregido; SQL y PATCH reales denegados. Historial previo intacto.',['22-space-reference-RED.json','REVIEW.md','@tool/task002/s0_space_fix.py']],
 ['CONSERVATION','LOCAL_LAB_CONSERVATION','PASS','25-data-conservation-v3.json','550/554 filas originales conservadas; delta exacto de fixtures, sólo 40 guardas y una función; Storage íntegro desde T49.',['27-workspace-preservation.json','29-CLI-cache-restoration.json','@tool/task002/s0_verify_v3.py','@tool/task002/s0_preserve.py']],
 ['RECOVERY','LOCAL_LAB_RECOVERY','PASS','26-final-recovery-v3.json','PAX exacto DB/Storage/coordinación en nuevos volúmenes; boot, lecturas reales y rechazos SQL/API en versión corregida.',['20-final-recovery.json','@tool/task002/s0_recovery_v3.py']],
 ['HARNESS','TEST_EXECUTION','PASS','24-unit-tests-v3.log','54 pruebas de herramientas; no sustituyen T49 ni validación integral de requisitos.',['11-verifier-amendment.json','@tool/task002/test_s0_sql_policy.py']],
 ['REPORT','LOCAL_INCREMENT_ACCEPTANCE_REPORT','S0_VALIDATED_LOCAL_ONLY','REPORT.md','S0 validado sólo en copias sintéticas aisladas y detenido; E2-B y TASK-002 siguen pendientes.',['99-stopped-v3.json','DIAGNOSIS.md','LEDGER.md','@tool/task002/register_s0.mjs']]
];
const ids=[];
for(const [suffix,kind,result,file,description,extra] of entries){
 const id='E-TASK002-S0-'+suffix+'-20261019';assert(!d.evidence.some(x=>x.id===id));ids.push(id);
 const paths=[run+'/'+file,...extra.map(x=>x.startsWith('@')?x.slice(1):run+'/'+x)],refs=[];
 for(const path of [...new Set(paths)])refs.push({path,sha256:crypto.createHash('sha256').update(await fs.readFile(root+path)).digest('hex')});
 d.evidence.push({id,kind,path:run+'/'+file,captured_at:now,result,description,scope:'E2_S0_ONLY_NEW_SYNTHETIC_ISOLATED_LOCAL_COPIES',environment:'Pinned local Docker; file Storage provider; no historical volumes or remote products',complete_requirement_validation:false,remote_modified:false,file_refs:refs});
 d.evidence_normative_bindings.push({evidence_id:id,normative_version:'SRS-5.1.1',scope:'SCOPED_S0_LOCAL_CONTAINMENT_NOT_COMPLETE_PRODUCT_VALIDATION'});
}
task.documentary_history.push({at:now,previous:structuredClone(task.documentary_progress),reason:'Human authorized S0 local only. Real T49, privileged negatives, P1 space correction, exact final recovery and conservation passed. Stopped before all subsequent increments; no product requirement promotion.',evidence_ids:ids});
Object.assign(task.documentary_progress,{product_implementation:'E1_E2A_S0_VALIDADOS_SOLO_LABORATORIO',complete:false,E2:'A_S0_VALIDADOS_LOCAL_RESTO_NO_AUTORIZADO',E2_authorized:false,E2_S0:'IMPLEMENTADO_VALIDADO_SOLO_COPIAS_LOCALES_SINTETICAS',E2_S0_authorized:false,E2_S0_authorization_fulfilled_local_only:true,E2_S0_executor:'COMPLETED_STOPPED_NO_NEXT_INCREMENT',E2_S0_last_attempt:run,E2_S0_local_validation:{T49:'PASS_REAL_STORAGE_API_A_B',privileged_negative:'PASS',concurrency_retry:'PASS',backup_restore_corrected_version:'PASS',conservation:'PASS',final_review_P1:'CORRECTED_RED_GREEN',account_deletions:0,complete_account_lifecycle:false,real_data_compatibility_proven:false,product_activation:false},next_increment:{id:'B',authorized:false,requires_specific_human_approval:true,dependencies:['D02','D03','D08','TASK-003 aplicable; motores contractuales reales','D/M antes de purga integrada']},remote_authorized:false,flutter_authorized:false});
task.documentary_progress.evidence_ids.push(...ids);
for(const key of ['requirements','test_cases','test_runs','baseline','normative_context','normative_versions','preservation','clause_anchors','state_transitions'])assert.deepEqual(d[key],before[key],key);
assert.deepEqual(d.evidence.slice(0,328),before.evidence);assert.deepEqual(d.next_tasks.filter(x=>x.id!=='TASK-002'),before.next_tasks.filter(x=>x.id!=='TASK-002'));
const baseline=text.match(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m)[0];
let next=stringify(d,{lineWidth:0}).replace(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m,baseline);
assert.deepEqual(parse(next).evidence.slice(0,328),before.evidence);
await fs.writeFile(target,next);console.log(JSON.stringify({result:'PASS_APPEND_ONLY',historical_evidence_preserved:328,new_scoped_evidence:10,requirements_unchanged:684,canonical_test_cases_unchanged:21,TASK002_complete:false}));
