// Explicit, scoped documentary reconciliation. Never calls DB/network/product code.
import {readFileSync,writeFileSync,existsSync} from 'node:fs';
import {resolve} from 'node:path';
import {parseDocument,stringify} from 'yaml';
import {extractCatalog,hash,validate} from './traceability.mjs';
import {extractSupplemental} from './versioning.mjs';
const root=resolve(new URL('../..',import.meta.url).pathname);
const run='docs/evidence/2026-10-13/task002/run-20261014T003000Z';
const read=p=>readFileSync(resolve(root,p));
const original=parseDocument(read(run+'/CANONICAL-v5.0.yaml').toString(),{uniqueKeys:true}).toJS({maxAliasCount:0});
if(original.schema_version!==1||original.baseline.srs.sha256!=='44087ec119772779a7972063299f248ae60009b26119a5c9b179ee75a7911152')throw Error('Unverified historical canonical source');
const srsPath='docs/MAREA_SRS.md',srs=read(srsPath).toString(),at=new Date().toISOString();
if(!srs.includes('version: 5.1.1\n')||!srs.includes('### 0.2. Autorización documental'))throw Error('Wrong authorized documentary source');
const anchors=JSON.parse(read(run+'/clause-anchors.json'));
const catalog=extractCatalog(srs,{expanded:true,anchors});
const data=structuredClone(original);data.schema_version=2;
data.normative_versions=[
 {id:'SRS-5.0',version:'5.0',path:run+'/SRS-5.0.md',sha256:hash(read(run+'/SRS-5.0.md')),status:'BASELINE_HISTORICA_EFECTIVA'},
 {id:'SRS-5.1.0',version:'5.1.0',path:run+'/SRS-5.1.0.md',sha256:hash(read(run+'/SRS-5.1.0.md')),status:'CANDIDATA_HISTORICA'},
 {id:'SRS-5.1.1',version:'5.1.1',path:srsPath,sha256:hash(read(srsPath)),status:'DISENO_AUTORIZADO_CONDICIONADO'}];
data.normative_context={design_version:'SRS-5.1.1',effective_version:'SRS-5.0',adoption_status:'PENDIENTE_COMPATIBILIDAD_LOCAL',documentary_reconciliation:'COMPLETA',authorization_evidence_id:'E-TASK002-AUTH',recorded_at:at,remote_authorized:false,local_migrations_authorized:false,flutter_authorized:false};
data.preservation={canonical_snapshot:{path:run+'/CANONICAL-v5.0.yaml',sha256:hash(read(run+'/CANONICAL-v5.0.yaml'))},manifest:{path:run+'/00-preservation-before.json',sha256:hash(read(run+'/00-preservation-before.json'))}};
data.clause_anchors=anchors.map(({id,section,sha256,review_status,review_basis,previous_sha256})=>({id,section,sha256,review_status,review_basis,previous_sha256}));
data.evidence_normative_bindings=original.evidence.map(e=>({evidence_id:e.id,normative_version:'SRS-5.0',scope:'HISTORICAL_CONTEXT_NOT_V511_VALIDATION'}));
function evidence(id,kind,path,description,refs=[]){const e={id,kind,path,description,captured_at:at,result:kind==='USER_CONFIRMATION'?'AUTORIZACION_ACOTADA':'DOCUMENTADO',complete_requirement_validation:false,remote_modified:false,file_refs:[{path,sha256:hash(read(path))},...refs.map(path=>({path,sha256:hash(read(path))}))]};data.evidence.push(e);data.evidence_normative_bindings.push({evidence_id:id,normative_version:'SRS-5.1.1',scope:'DOCUMENTARY_ONLY'});}
evidence('E-TASK002-AUTH','USER_CONFIRMATION',run+'/AUTHORIZATION.md','Human authorizes N/T only; E/U0 proposals; no product/migrations/remote/commits.');
evidence('E-TASK002-N','NORMATIVE_REVIEW',run+'/01-N-verification.json','Explicit scoped normative consolidation; no product implementation.',[srsPath,run+'/SRS-5.0.md',run+'/SRS-5.1.0.md']);
evidence('E-TASK002-T-DESIGN','DOCUMENT_REVIEW',run+'/T-TOOLING-DESIGN.md','Versioned documentary tooling design recorded before changes.');
const changed=new Set();
const snapshot=r=>Object.fromEntries(['validity','implementation','verification','value'].map(d=>[d,r[d].state]));
const platforms=r=>Object.fromEntries(Object.entries(r.platforms).map(([p,x])=>[p,{applicability:x.applicability,implementation:x.implementation.state,verification:x.verification.state,distribution:x.distribution.state}]));
for(const r of data.requirements){const c=catalog.find(c=>c.id===r.id);if(!c)throw Error('Historical requirement has no reviewed match: '+r.id);
 const modified=r.source.sha256!==hash(c.text);if(modified)changed.add(r.id);
 r.source_history=[{normative_version:'SRS-5.0',source:structuredClone(r.source),description:r.description}];
 r.source={path:srsPath,normative_version:'SRS-5.1.1',section:c.section,line_start:c.line_start,line_end:c.line_end,sha256:hash(c.text)};r.description=c.description;r.assessment_normative_version='SRS-5.0';
 r.normative_review={status:modified?'PENDIENTE_REAUDITORIA':'FRAGMENTO_CONSERVADO_NO_REVALIDADO',reason:modified?'Cláusula modificada; evaluación de producto histórica, no se presume implementación nueva.':'Texto normativo conservado; evidencia histórica no certifica dependencias nuevas.'};
 r.history.push({type:'NORMATIVE_RECONCILIATION',at,reason:'Fuente v5.1.1 reconciliada con correspondencia revisada; criterios, dimensiones y evidencia TASK-001 preservados.',snapshot:snapshot(r),platform_snapshot:platforms(r),evidence_ids:['E-TASK002-N'],normative_version:'SRS-5.1.1'});
}
for(const c of catalog.filter(c=>!data.requirements.some(r=>r.id===c.id))){
 const r={id:c.id,kind:c.kind,original_id:c.kind==='AUX'?null:c.id,module:c.module,phase:c.phase,phase_source:null,phase_proposal:{status:'PENDIENTE_APROBACION',reason:'Cláusula sin fase explícita individual.'},description:c.description,
 source:{path:srsPath,normative_version:'SRS-5.1.1',section:c.section,line_start:c.line_start,line_end:c.line_end,sha256:hash(c.text)},source_history:[],assessment_normative_version:'SRS-5.1.1',normative_review:{status:'PENDIENTE_REAUDITORIA',reason:'Nueva cláusula, sin auditoría de implementación.'},
 validity:{state:'VIGENTE',reason:'Obligación de diseño candidato; adopción condicionada.'},implementation:{state:'NO_AUDITADO',reason:'Integración documental no localiza implementación.'},verification:{state:'NO_EVALUADO',reason:'Sin pruebas de producto.'},value:{state:'POR_VALIDAR',reason:'Sin validación de valor independiente.'},
 platforms:Object.fromEntries(['web','android','ios'].map(p=>[p,{applicability:'POR_CONFIRMAR',reason:'Revisión por plataforma pendiente.',implementation:{state:'NO_AUDITADO',reason:'Sin auditoría nueva.'},verification:{state:'NO_EVALUADO',reason:'Sin ejecución.'},distribution:{state:null,reason:'Sin distribución acreditada.',evidence_ids:[]}}])),
 acceptance_criteria:[{id:c.id+'/C01',description:c.description,implementation:'NO_AUDITADO',reason:'Criterio normativo pendiente de descomposición y pruebas suficientes.',files:[],tests:[]}],progress:{percent:null,method:null},dependencies:[],related_requirements:[],implementation_files:[],database_objects:[],tests:[],evidence_ids:['E-TASK002-N'],known_defects:[],priority:null,owner:null,blocker:null,reviewed_at:at,next_action:'Auditar criterio integral en hitos autorizados; no implementar en N/T.'};
 r.history=[{type:'INITIAL_ASSESSMENT',at,reason:'Registro nuevo sólo normativo.',snapshot:snapshot(r),platform_snapshot:platforms(r)}];data.requirements.push(r);
}
let impacted=new Set(changed),progress=true;while(progress){progress=false;for(const r of data.requirements)if(!impacted.has(r.id)&&(r.dependencies??[]).some(id=>impacted.has(id))){impacted.add(r.id);progress=true;}}
for(const r of data.requirements)if(impacted.has(r.id)&&!changed.has(r.id)){r.normative_review={status:'PENDIENTE_REAUDITORIA',reason:'Dependencia normativa afectada; no se presume nueva cobertura.'};}
const supplemental=extractSupplemental(srs);
data.test_cases=supplemental.filter(c=>c.kind==='TC').map(c=>({id:c.id,description:c.description,requirement_ids:c.requirement_ids,normative_source:{path:srsPath,normative_version:'SRS-5.1.1',line_start:c.line_start,line_end:c.line_end,sha256:c.sha256},status:'PENDIENTE',complete_requirement_validation:false,organizer_variants:['TC-51-001','TC-51-003'].includes(c.id)?['PERSONAL']:['TC-51-015','TC-51-016'].includes(c.id)?['ORGANIZACIONAL']:['PERSONAL','ORGANIZACIONAL'],task_dependencies:['TC-51-012','TC-51-015','TC-51-017'].includes(c.id)?['TASK-002','TASK-003']:['TASK-002'],execution_ids:[],reason:'Sin ejecución de producto en N/T; casos dependientes de revocación/privacidad conservan límites TASK-003.'}));
for(const c of supplemental.filter(c=>c.kind==='DECISION'))data.decisions.push({id:c.id,title:'Corrección normativa v5.1',description:c.description,normative_source:{path:srsPath,normative_version:'SRS-5.1.1',line_start:c.line_start,line_end:c.line_end,sha256:c.sha256},status:'APROBADA_CONDICIONADA',approved_by_type:'HUMAN',approval_evidence_id:'E-TASK002-AUTH',approved_at:at,resolution:'Aprobación conceptual para diseño/N/T; no autoriza migración, Flutter, remoto ni adopción efectiva anticipada.',evidence_ids:['E-TASK002-AUTH'],requirement_ids:[],files:[srsPath]});
data.decisions.push({id:'DECISION-T002-REVISION-TTL',title:'Plazo provisional del piloto',description:'Siete días naturales calculados por servidor en UTC, acortados por ejecución; aceptación retroactiva prohibida.',status:'APROBADA_PROVISIONAL',approved_by_type:'HUMAN',approval_evidence_id:'E-TASK002-AUTH',approved_at:at,resolution:'Revisar cercanía a ejecución, límite exacto, expiración y rechazo antes de habilitar.',requirement_ids:['RF-10-005','CTR5-03'],evidence_ids:['E-TASK002-AUTH'],files:[srsPath]});
const task=data.next_tasks.find(t=>t.id==='TASK-002');task.documentary_progress={N:'CONSOLIDADO_DOCUMENTALMENTE',T:'RECONCILIADO',E:'PROPUESTA_PENDIENTE_APROBACION_TECNICA',U0:'PROPUESTA_PENDIENTE_REVISION',product_implementation:'NO_INICIADA_EN_ESTA_ETAPA',complete:false,remote_authorized:false,flutter_authorized:false};
task.requirement_ids=[...new Set([...task.requirement_ids,'CTR5-02','RF-02-005','RF-02-006','RF-02-007','RF-08-010','RF-08-011','RF-09-011','RF-09-012','RF-09-013','RF-10-003','RF-10-005','RF-10-006','RF-10-009','RF-10-010','RF-10-014'])];
task.acceptance='N/T documentales + E aprobado técnicamente + migraciones/pruebas locales posteriores + U0 aprobado antes de Flutter; ambas modalidades; validación integral condicionada a TASK-003 y QA aplicable. Sin autorización remota.';
data.executive_summary=original.executive_summary+' TASK-002 consolida SRS v5.1.1 y trazabilidad documental con autorización acotada. Sus contratos aplican al organizador autorizado personal u organizacional. E/U0 son propuestas: no se ejecutaron migraciones ni código funcional. La baseline efectiva histórica v5.0 y TASK-001 se conservan; adopción v5.1.1 pendiente de compatibilidad. Datos sintéticos no prueban todos los datos reales ni autorizan remoto.';
const errors=validate(data,root);if(errors.length)throw Error(errors.slice(0,30).join('\n'));
const report={at,result:'PASS_DOCUMENTARY_RECONCILIATION',original_requirements:original.requirements.length,current_requirements:data.requirements.length,original_explicit_ids:catalog.filter(c=>c.kind!=='AUX').length,new_aux_clauses:data.requirements.length-original.requirements.length,changed_fragments:[...changed],impacted_dependencies:[...impacted].filter(id=>!changed.has(id)),test_cases:data.test_cases.length,historical_evidence:original.evidence.length,baseline_preserved:true,product_modified:false,migrations_executed:false,remote_modified:false,complete_requirement_validation:false};
if(!process.argv.includes('--apply')){console.log(JSON.stringify(report,null,2));process.exit(0);}
const existing=parseDocument(read('docs/MAREA_REQUIREMENTS_STATUS.yaml').toString()).toJS({maxAliasCount:0});if(existing.schema_version!==1)throw Error('Already reconciled; verify current canonical instead of replaying integration');
const baselineBlock=read(run+'/CANONICAL-v5.0.yaml').toString().match(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m)?.[0];if(!baselineBlock)throw Error('Historical baseline text missing');
let output='# Fuente canónica versionada; baseline e historial TASK-001 preservados. No regenerar desde heurísticas.\n'+stringify(data,{lineWidth:0,aliasDuplicateObjects:false});output=output.replace(/^baseline:\n[\s\S]*?(?=^state_transitions:)/m,baselineBlock);
writeFileSync(resolve(root,'docs/MAREA_REQUIREMENTS_STATUS.yaml'),output);writeFileSync(resolve(root,run+'/05-reconciliation.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({result:report.result,requirements:report.current_requirements,tests:report.test_cases}));
