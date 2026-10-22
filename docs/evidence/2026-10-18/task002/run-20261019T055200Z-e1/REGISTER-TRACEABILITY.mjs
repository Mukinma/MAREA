// Fixed evidence registration for the authorized E1 local run; never raises requirement status.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const root=process.cwd();
const {parseDocument,stringify}=await import(pathToFileURL(path.join(root,'tool/traceability/node_modules/yaml/dist/index.js')));
const run='docs/evidence/2026-10-18/task002/run-20261019T055200Z-e1';
const canonical='docs/MAREA_REQUIREMENTS_STATUS.yaml';
const original=fs.readFileSync(canonical,'utf8');
const baseline=original.match(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m)[0];
const doc=parseDocument(original);const c=doc.toJS({maxAliasCount:0});
const prior=parseDocument(fs.readFileSync(`${run}/prior-canonical.yaml`,'utf8')).toJS({maxAliasCount:0});
assert.deepEqual(c,prior,'Refuse unexpected canonical drift before evidence registration');
const task=c.next_tasks.find(x=>x.id==='TASK-002');const previous=structuredClone(task.documentary_progress);
const at=new Date().toISOString();
const specs=[
 ['AUTH','USER_CONFIRMATION','AUTHORIZATION.md','Autorización humana exclusiva E1 en nuevas copias sintéticas locales; E2/Flutter/remoto no autorizados.',[]],
 ['PREFLIGHT','LOCAL_E1_PREFLIGHT','01-preflight.json','Socket/imágenes/backups/manifiestos, cuatro restores nuevos y catálogo sin drift antes del DDL.',['02-restoration.json','03-schema-and-digests-before.json']],
 ['IMPLEMENTATION','LOCAL_E1_SCHEMA_EXECUTION','04-transactional-execution.json','Dos transacciones E1 confirmadas, seis principales por copia, ensayo previo de rollback total y rechazo de reejecución.',['E1-LAB-A-EXECUTABLE.sql','E1-LAB-B-EXECUTABLE.sql','E1-LAB-A-DIFF.patch','E1-LAB-B-DIFF.patch','@tool/task002/e1_lab.py']],
 ['ACCESS-TESTS','LOCAL_E1_NEGATIVE_SQL_TESTS','05-permissions-constraints-tests.json','16 denegaciones CRUD reales anon/authenticated y 12 constraints negativas; RLS/ACL efectivos; ocho guardas finales.',['08-executor-guard-tests.log','11-comparator-regression-red.log','12-comparator-regression-green.log','18-executor-final-tests.log','@tool/task002/test_e1_lab.py']],
 ['CONSERVATION','LOCAL_E1_LEGACY_CONSERVATION','06-legacy-and-storage-conservation.json','100 tablas y siete secuencias por copia, catálogo legado y Storage preservados; sin operar sobre originales.',['07-backup-and-proposal-preservation.json','17-final-isolation-and-close.json']],
 ['VERIFIER-HISTORY','LOCAL_E1_VERIFIER_INCIDENTS','10-readonly-failure-diagnosis.json','Paradas del verificador preservadas: nombre visible regclass y orden JSON; corrección de herramienta, sin cambio SQL ni ampliación de alcance.',['FAILURE.json','RESUMPTION-FAILURE.json','09-isolation-and-close.json','13-bounded-verifier-resumption.json','14-final-isolation-and-close.json','16-bounded-verifier-resumption-serialization.json']],
 ['REPORT','LOCAL_E1_TECHNICAL_REPORT','REPORT.md','E1 implementado y validado únicamente en dos copias locales sintéticas; altas futuras/borrado/retención pendientes; TASK-002 incompleta.',['15-traceability-tests.log']],
];
const ids=[];
for(const [suffix,kind,file,description,others] of specs){
 const id=`E-TASK002-E1-${suffix}-20261018`;assert(!c.evidence.some(e=>e.id===id));ids.push(id);
 const paths=[file,...others].map(p=>p.startsWith('@')?p.slice(1):`${run}/${p}`);
 const file_refs=paths.map(p=>({path:p,sha256:crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex')}));
 c.evidence.push({id,kind,path:paths[0],captured_at:at,result:suffix==='AUTH'?'AUTORIZADO_SOLO_E1_LOCAL':suffix==='VERIFIER-HISTORY'?'FAILURES_PRESERVED_VERIFIER_CORRECTED':'PASS',description,
  modality:'real',environment:'Two new local synthetic physical restores; Docker Unix, network none, no original-volume access or remote equivalence',
  complete_requirement_validation:false,remote_modified:false,scope:'E1_LOCAL_ONLY_NO_E2_FLUTTER_REMOTE',file_refs});
 c.evidence_normative_bindings.push({evidence_id:id,normative_version:'SRS-5.1.1',scope:'LOCAL_E1_ONLY_NOT_INTEGRAL_PRODUCT_REQUIREMENT_VALIDATION'});
}
task.documentary_history.push({at,previous,reason:'Explicit human E1-only authorization executed in new isolated synthetic copies; no mission reference/cascade changes. Historical evidence and requirement dimensions remain frozen.',evidence_ids:ids});
Object.assign(task.documentary_progress,{E1:'IMPLEMENTADO_VALIDADO_SOLO_COPIAS_LOCALES_SINTETICAS',product_implementation:'E1_PRIVADO_ADITIVO_SOLO_LABORATORIO',complete:false,
 E1_authorization:{authorized:true,scope:'PERSONAL_PRINCIPAL_ONLY_NEW_SYNTHETIC_LOCAL_COPIES',E2_authorized:false,remote_authorized:false,flutter_authorized:false},
 pending_controls:['future_identity_synchronization','account_deletion','personal_principal_retention','E2_conservation_adapters_storage','TASK003_revocation_dependency'],
 evidence_ids:[...previous.evidence_ids,...ids]});
assert.deepEqual(c.requirements,prior.requirements);assert.deepEqual(c.test_cases,prior.test_cases);
assert.deepEqual(c.normative_context,prior.normative_context);
assert.deepEqual(c.evidence.slice(0,prior.evidence.length),prior.evidence);
let output=stringify(c,{lineWidth:0,aliasDuplicateObjects:false});
output=output.replace(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m,baseline);
fs.writeFileSync(canonical,output);
console.log(JSON.stringify({old_evidence_unchanged:prior.evidence.length,new_evidence:ids,requirements_unchanged:c.requirements.length,product_cases_unchanged:c.test_cases.length,task002_complete:false},null,2));
