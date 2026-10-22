// Register E2 planning only. Never change requirement assessments or grant execution permission.
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';
const {parse,stringify}=await import(pathToFileURL(path.join(process.cwd(),'tool/traceability/node_modules/yaml/dist/index.js')));
const run='docs/evidence/2026-10-19/task002/run-20261019T061500Z-e2-design';const target='docs/MAREA_REQUIREMENTS_STATUS.yaml';
const raw=fs.readFileSync(target,'utf8');const c=parse(raw),o=parse(fs.readFileSync(run+'/prior-canonical.yaml','utf8'));
assert.deepEqual(c,o,'Canonical drift before documentary registration');
const baseline=raw.match(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m)[0];const at=new Date().toISOString();
const specs=[
 ['AUTH','USER_INSTRUCTION','AUTHORIZATION.md','Autorización exclusiva de análisis/planificación E2; no permiso de implementación ni ejecución.',[]],
 ['INVENTORY','DESK_DEPENDENCY_ANALYSIS','@docs/task002/E2-DEPENDENCY-INVENTORY.json','Inventario derivado de snapshots E1 y 85 fuentes, 36 FK de perfil/10 de misión/56 rutinas; sin nueva consulta DB o equivalencia remota.',['03-design-consistency.json']],
 ['DESIGN','TECHNICAL_DESIGN_PROPOSAL','@docs/task002/E2-TECHNICAL-DESIGN.md','Arquitectura/alternativas, diez decisiones humanas pendientes, secuencia con S0 y 49 casos futuros NO EJECUTADOS; revisión independiente incorporada.',['@docs/task002/E2-AUTHORIZATION-DOSSIER.md','@docs/task002/E2-IMPLEMENTATION-PLAN.md','@docs/task002/E2-TEST-MATRIX.md','02-independent-review.md']],
 ['REPORT','DOCUMENTARY_PLANNING_REPORT','REPORT.md','Expediente E2 entregado sólo como análisis; siguiente autorización propuesta A aún no concedida. E1 y requisitos/historial intactos.',['04-traceability-tests.log']],
];const ids=[];
const resolve=p=>p.startsWith('@')?p.slice(1):`${run}/${p}`;
for(const [suffix,kind,file,description,others] of specs){
 const id=`E-TASK002-E2-${suffix}-20261019`;assert(!c.evidence.some(x=>x.id===id));ids.push(id);
 const paths=[file,...others].map(resolve);
 c.evidence.push({id,kind,path:paths[0],captured_at:at,result:'DOCUMENTADO_NO_IMPLEMENTADO_NO_EJECUTADO',description,
  environment:'Desk analysis of repository and preserved local synthetic E1 snapshots; no runtime/remote query',
  scope:'E2_ANALYSIS_PLANNING_ONLY_NO_EXECUTION_PERMISSION',complete_requirement_validation:false,
  functional_E2_tests_executed:0,E2_execution_authorized:false,remote_modified:false,
  file_refs:paths.map(p=>({path:p,sha256:crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex')}))});
 c.evidence_normative_bindings.push({evidence_id:id,normative_version:'SRS-5.1.1',scope:'E2_DESIGN_ONLY_NOT_IMPLEMENTATION_OR_PRODUCT_VALIDATION'});
}
const t=c.next_tasks.find(x=>x.id==='TASK-002');const previous=structuredClone(t.documentary_progress);
t.documentary_history.push({at,previous,reason:'Human requested E2 technical design and authorization dossier in analysis/planning mode only. E1 validation and all prior evidence preserved; no implementation permission inferred.',evidence_ids:ids});
Object.assign(t.documentary_progress,{E2:'DISEÑO_PROPUESTO_PENDIENTE_DECISIONES_Y_AUTORIZACION',E2_authorized:false,E2_A_authorized:false,
 E2_pending_decisions:Array.from({length:10},(_,i)=>'D'+String(i+1).padStart(2,'0')),E2_dossier:'docs/task002/E2-AUTHORIZATION-DOSSIER.md',
 evidence_ids:[...previous.evidence_ids,...ids],complete:false});
assert.equal(t.documentary_progress.E1,previous.E1);assert.deepEqual(t.documentary_progress.E1_authorization,previous.E1_authorization);
assert.deepEqual(c.requirements,o.requirements);assert.deepEqual(c.test_cases,o.test_cases);assert.deepEqual(c.normative_context,o.normative_context);assert.deepEqual(c.evidence.slice(0,o.evidence.length),o.evidence);
fs.writeFileSync(target,stringify(c,{lineWidth:0,aliasDuplicateObjects:false}).replace(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m,baseline));
console.log(JSON.stringify({prior_evidence_preserved:o.evidence.length,new_documentary_evidence:ids,E2_authorized:false,E2_cases_executed:0,requirements_unchanged:c.requirements.length,TASK002_complete:false},null,2));
