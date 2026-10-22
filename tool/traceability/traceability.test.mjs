import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync, writeFileSync, readFileSync, rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {createHash} from 'node:crypto';
import {extractCatalog, validate, evidenceFreshness, metrics, replaceGenerated, render} from './traceability.mjs';
import {extractSupplemental} from './versioning.mjs';

function versionedFixture(){
 const f=fixture();f.data.baseline.srs.version='5.0';
 writeFileSync(join(f.root,'historical.md'),text);
 writeFileSync(join(f.root,'canonical.json'),JSON.stringify(f.data));
 writeFileSync(join(f.root,'approval.md'),'Human authorizes document reconciliation only.');
 f.data.schema_version=2;
 f.data.normative_versions=[{id:'SRS-5.0',version:'5.0',path:'historical.md',sha256:sha(text)},{id:'SRS-5.1.1',version:'5.1.1',path:'srs.md',sha256:sha(text)}];
 f.data.normative_context={design_version:'SRS-5.1.1',effective_version:'SRS-5.0',adoption_status:'PENDIENTE_COMPATIBILIDAD_LOCAL',authorization_evidence_id:'EAUTH'};
 f.data.preservation={canonical_snapshot:{path:'canonical.json',sha256:sha(readFileSync(join(f.root,'canonical.json')))}};
 f.data.clause_anchors=[];f.data.test_cases=[];
 f.data.evidence.push({id:'EAUTH',kind:'USER_CONFIRMATION',captured_at:'2026-10-14T00:00:00Z',description:'Explicit scoped authorization',path:'approval.md',file_refs:[{path:'approval.md',sha256:sha(readFileSync(join(f.root,'approval.md')))}]});
 f.data.evidence_normative_bindings=[{evidence_id:'E1',normative_version:'SRS-5.0'},{evidence_id:'EAUTH',normative_version:'SRS-5.1.1'}];
 for(const r of f.data.requirements){r.source_history=[{normative_version:'SRS-5.0',source:structuredClone(r.source),description:r.description}];r.source.normative_version='SRS-5.1.1';r.assessment_normative_version='SRS-5.0';}
 return f;
}

test('schema 2 protects historical baseline while validating a distinct design source',()=>{const f=versionedFixture();try{assert.deepEqual(validate(f.data,f.root),[]);assert.equal(metrics(f.data,f.root).BASE.verified_current,0);}finally{f.dispose();}});
test('schema 2 rejects lost historical evidence and history',()=>{const f=versionedFixture();try{f.data.evidence=f.data.evidence.filter(e=>e.id!=='E1');f.data.requirements[0].history=[];assert.match(validate(f.data,f.root).join('\n'),/historical evidence/);assert.match(validate(f.data,f.root).join('\n'),/historical history/);}finally{f.dispose();}});
test('schema 2 verifies historical source bytes, snapshot bytes and authorization',()=>{const f=versionedFixture();try{writeFileSync(join(f.root,'historical.md'),'tampered');writeFileSync(join(f.root,'canonical.json'),'{}');f.data.normative_context.authorization_evidence_id='MISSING';const errors=validate(f.data,f.root).join('\n');assert.match(errors,/normative version changed/);assert.match(errors,/canonical snapshot changed/);assert.match(errors,/normative authorization/);}finally{f.dispose();}});
test('schema 2 does not accept synthetic compatibility as authorization for remote adoption',()=>{const f=versionedFixture();try{f.data.normative_context.effective_version='SRS-5.1.1';assert.match(validate(f.data,f.root).join('\n'),/effective baseline/);}finally{f.dispose();}});
test('schema 2 rendering distinguishes historical baseline, design and pending adoption',()=>{const f=versionedFixture();try{const view=render(f.data,f.root)['docs/MAREA_TRACKING.md'];assert.match(view,/5\.1\.1/);assert.match(view,/PENDIENTE_COMPATIBILIDAD_LOCAL/);}finally{f.dispose();}});
test('expanded AUX identities use frozen hashes rather than table positions',()=>{const source='## 3.1. Estados\n| `Mission` | A |\n| `AgreementRevision` | NUEVA |\n| `Outcome` | B |\n';const line='| `Outcome` | B |';const c=extractCatalog(source,{expanded:true,anchors:[{id:'TR-S3.1-006',section:'3.1',sha256:sha(line)}]});assert.equal(c.find(x=>x.text===line).id,'TR-S3.1-006');});
test('supplemental decisions and cases preserve IDs and RF relationships without becoming RF',()=>{const c=extractSupplemental('| `DECISION-51-01` | Problema | Regla |\n| `TC-51-006` | `RF-10-001, CTR5-01` | Firmar | Activar |');assert.deepEqual(c.map(x=>x.kind),['DECISION','TC']);assert.deepEqual(c[1].requirement_ids,['RF-10-001','CTR5-01']);assert.equal(c[1].line_start,2);});
test('schema 2 rejects unreviewed or missing AUX anchors',()=>{const f=versionedFixture();try{const extra='\n## 3.7. Revisión\n- La propuesta no sustituye obligaciones.\n';writeFileSync(join(f.root,'srs.md'),text+extra);f.data.normative_versions[1].sha256=sha(text+extra);assert.match(validate(f.data,f.root).join('\n'),/missing frozen clause anchor/);}finally{f.dispose();}});
test('schema 2 never silently changes an old baseline or source association',()=>{const f=versionedFixture();try{f.data.baseline.id='REPLACED';f.data.requirements[0].source_history=[];assert.match(validate(f.data,f.root).join('\n'),/historical baseline altered/);assert.match(validate(f.data,f.root).join('\n'),/historical normative source lost/);}finally{f.dispose();}});
test('document reconciliation cannot rewrite old criteria or drop requirement evidence links',()=>{const f=versionedFixture();try{f.data.requirements[0].acceptance_criteria[0].description='rewritten';f.data.requirements[0].evidence_ids=[];const errors=validate(f.data,f.root).join('\n');assert.match(errors,/historical assessment altered.*acceptance_criteria/);assert.match(errors,/historical assessment altered.*evidence_ids/);}finally{f.dispose();}});
test('scoped normative authorization must have current verified bytes',()=>{const f=versionedFixture();try{f.data.evidence.find(e=>e.id==='EAUTH').file_refs[0].sha256='0'.repeat(64);assert.match(validate(f.data,f.root).join('\n'),/normative authorization changed/);}finally{f.dispose();}});
test('reconciliation cannot relabel a historical product assessment as the design version',()=>{const f=versionedFixture();try{f.data.requirements[0].assessment_normative_version='SRS-5.1.1';assert.match(validate(f.data,f.root).join('\n'),/historical assessment normative binding/);}finally{f.dispose();}});
test('changed normative content cannot lose its pending re-audit classification',()=>{const f=versionedFixture();try{const changed=text.replace('Permitir acceso público.','Permitir acceso público con reglas nuevas.');writeFileSync(join(f.root,'srs.md'),changed);f.data.normative_versions[1].sha256=sha(changed);const c=extractCatalog(changed)[0],r=f.data.requirements[0];r.source.sha256=sha(c.text);r.description=c.description;r.normative_review={status:'FRAGMENTO_CONSERVADO_NO_REVALIDADO'};assert.match(validate(f.data,f.root).join('\n'),/normative re-audit required/);}finally{f.dispose();}});

const sha = s => createHash('sha256').update(s).digest('hex');
const text = '# SRS\n## 5. Catálogo\n### M01 — Cuenta\n- **RF-01-001** | `BASE` | Permitir acceso público.\n- **RF-01-002** | `PILOTO` | Recuperar sesión.\n## 6. Controles\n- **CT-SEC-ID-001** | Proteger sesión.\n';
function fixture() {
  const root = mkdtempSync(join(tmpdir(), 'marea-trace-test-'));
  writeFileSync(join(root, 'srs.md'), text);
  writeFileSync(join(root, 'app.dart'), 'implementation v1');
  const req = (id, phase) => ({id,original_id:id,kind:id.startsWith('RF')?'RF':'CT',description:extractCatalog(text).find(c=>c.id===id).description,module:id.startsWith('RF')?'M01':null,phase,
    phase_source:phase?{id,line:phase==='BASE'?4:5}:null,phase_proposal:phase?null:{status:'PENDIENTE_APROBACION',reason:'Sin fase normativa'},
    source:{path:'srs.md',...Object.fromEntries(Object.entries(extractCatalog(text).find(c=>c.id===id)).filter(([k])=>['line_start','line_end','section'].includes(k))),sha256:sha(extractCatalog(text).find(c=>c.id===id).text)},priority:null,owner:null,
    validity:{state:'VIGENTE',reason:'Norma vigente'},implementation:{state:'IMPLEMENTADO',reason:'Flujo localizado'},
    verification:{state:'VALIDADO',reason:'Prueba completa'},value:{state:'JUSTIFICADO',reason:'Norma'},
    platforms:Object.fromEntries(['web','android','ios'].map(p=>[p,{applicability:'APLICA',reason:'Requerido',implementation:{state:'IMPLEMENTADO',reason:'Flujo'},verification:{state:'VALIDADO',reason:'Prueba'},distribution:{state:null,reason:'Sin release',evidence_ids:[]}}])),
    acceptance_criteria:[{id:id+'/C01',description:'Aceptación',implementation:'IMPLEMENTADO',reason:'Flujo',files:['app.dart'],tests:[]}],
    progress:{percent:null,method:null},dependencies:[],implementation_files:['app.dart'],database_objects:[],tests:[],evidence_ids:['E1'],known_defects:[],blocker:null,
    reviewed_at:'2026-10-13T00:00:00-06:00',next_action:'Mantener',history:[{type:'INITIAL_ASSESSMENT',at:'2026-10-13T00:00:00-06:00',reason:'Auditoría inicial',platform_snapshot:Object.fromEntries(['web','android','ios'].map(p=>[p,{applicability:'APLICA',implementation:'IMPLEMENTADO',verification:'VALIDADO',distribution:null}])),snapshot:{validity:'VIGENTE',implementation:'IMPLEMENTADO',verification:'VALIDADO',value:'JUSTIFICADO'}}]});
  const data = {schema_version:1,baseline:{id:'AUDIT-2026-10-13',reviewed_at:'2026-10-13T00:00:00-06:00',srs:{path:'srs.md',sha256:sha(text)},git_revision:'abc'},
    requirements:[req('RF-01-001','BASE'),req('RF-01-002','PILOTO'),req('CT-SEC-ID-001',null)],
    evidence:[{id:'E1',kind:'TEST_EXECUTION',result:'PASS',captured_at:'2026-10-13T00:00:00-06:00',description:'Pruebas completas',complete_requirement_validation:true,platforms:['web','android','ios'],file_refs:[{path:'app.dart',sha256:sha('implementation v1')}]}],
    findings:[],decisions:[],orphans:[],limitations:[],test_runs:[],components:[],state_transitions:{}};
  return {root,data,dispose:()=>rmSync(root,{recursive:true,force:true})};
}
test('extracts original IDs and explicit phases without assigning a phase to controls',()=>{
  const c=extractCatalog(text); assert.equal(c.length,3); assert.equal(c[0].phase,'BASE'); assert.equal(c[1].phase,'PILOTO'); assert.equal(c[2].phase,null);
});
test('detects lost and duplicated normative IDs',()=>{const f=fixture();try{
  assert.deepEqual(validate(f.data,f.root),[]);
  f.data.requirements.pop(); assert.ok(validate(f.data,f.root).some(x=>x.includes('missing ID')));
  f.data.requirements.push(f.data.requirements[0]); assert.ok(validate(f.data,f.root).some(x=>x.includes('duplicate ID')));
}finally{f.dispose();}});
test('rejects unknown states, references and paths',()=>{const f=fixture();try{
  f.data.requirements[0].implementation.state='DONE'; f.data.requirements[0].dependencies=['RF-99-999'];f.data.requirements[0].implementation_files=['missing.dart'];
  const errors=validate(f.data,f.root).join('\n');assert.match(errors,/invalid implementation/);assert.match(errors,/unknown dependency/);assert.match(errors,/missing path/);
}finally{f.dispose();}});
test('SRS changes fail protection check',()=>{const f=fixture();try{writeFileSync(join(f.root,'srs.md'),text+'changed');assert.ok(validate(f.data,f.root).some(x=>x.includes('protected SRS')));}finally{f.dispose();}});
test('reserved validity decisions require explicit approval',()=>{const f=fixture();try{f.data.requirements[0].validity.state='DESCARTADO';assert.ok(validate(f.data,f.root).some(x=>x.includes('approval required')));}finally{f.dispose();}});
test('phase ambiguity remains in total and outside phase metrics',()=>{const f=fixture();try{f.data.requirements[1].phase=null;f.data.requirements[1].phase_source=null;f.data.requirements[1].phase_proposal={status:'PENDIENTE_APROBACION',reason:'Ambigua'};const m=metrics(f.data,f.root);assert.equal(m.PRODUCTO_COMPLETO.denominator,2);assert.equal(m.BASE.denominator,1);assert.equal(m.PILOTO.denominator,0);assert.equal(m.PRODUCTO_COMPLETO.ambiguous_phase,1);}finally{f.dispose();}});
test('phase assignment contrary to SRS is rejected',()=>{const f=fixture();try{f.data.requirements[1].phase='BASE';assert.ok(validate(f.data,f.root).some(x=>x.includes('phase without normative support')));}finally{f.dispose();}});
test('stale evidence stays historical and stops counting as current validation without changing states',()=>{const f=fixture();try{
  assert.equal(metrics(f.data,f.root).BASE.verified_current,1);writeFileSync(join(f.root,'app.dart'),'implementation v2');
  assert.equal(evidenceFreshness(f.data.evidence[0],f.root).state,'POTENCIALMENTE_OBSOLETA');const m=metrics(f.data,f.root);assert.equal(m.BASE.verified_historical,1);assert.equal(m.BASE.verified_current,0);assert.equal(f.data.requirements[0].verification.state,'VALIDADO');
}finally{f.dispose();}});
test('failed mandatory test forbids complete validation',()=>{const f=fixture();try{f.data.evidence[0].result='FAIL';assert.equal(metrics(f.data,f.root).BASE.verified_current,0);assert.ok(validate(f.data,f.root).some(x=>x.includes('failed evidence')));}finally{f.dispose();}});
test('percentage requires reproducible criterion calculation',()=>{const f=fixture();try{f.data.requirements[0].progress.percent=50;assert.ok(validate(f.data,f.root).some(x=>x.includes('unjustified progress')));}finally{f.dispose();}});
test('manual text survives generation byte for byte',()=>{
 const old='Manual decision\r\n<!-- MAREA:GENERATED:BEGIN -->\nold\n<!-- MAREA:GENERATED:END -->\nEvidence outside\r\n';
 const result=replaceGenerated(old,'new');assert.ok(result.startsWith('Manual decision\r\n'));assert.ok(result.endsWith('Evidence outside\r\n'));assert.match(result,/\nnew\n/);
 assert.equal(replaceGenerated(result,'new'),result);
});
test('existing files without markers are preserved and damaged markers rejected',()=>{
 assert.ok(replaceGenerated('manual\r\n','generated').startsWith('manual\r\n'));
 assert.throws(()=>replaceGenerated('<!-- MAREA:GENERATED:BEGIN -->','x'),/delimiter/);
 assert.throws(()=>replaceGenerated('<!-- MAREA:GENERATED:END -->\n<!-- MAREA:GENERATED:BEGIN -->','x'),/delimiter/);
});
test('rendering is deterministic and cannot target SRS',()=>{const f=fixture();try{const before=JSON.stringify(f.data);const a=render(f.data,f.root);assert.deepEqual(a,render(f.data,f.root));assert.equal(JSON.stringify(f.data),before);assert.equal(readFileSync(join(f.root,'srs.md'),'utf8'),text);assert.ok(!Object.keys(a).some(p=>p.includes('SRS')));}finally{f.dispose();}});
test('preserves descriptions of standalone contract bullets',()=>{
 const c=extractCatalog('## 3. Contratos\n- **CTR5-01** Oferta con TTL de 72 horas.\n');
 assert.match(c[0].description,/72 horas/);
});
test('invalid finding and related requirement references cannot pass',()=>{const f=fixture();try{
 f.data.requirements[0].known_defects=['FND-MISSING'];f.data.requirements[0].related_requirements=['RF-99-999'];
 f.data.findings=[{id:'FND1',requirement_ids:[],files:[],evidence_ids:['E-MISSING']}];
 assert.match(validate(f.data,f.root).join('\n'),/unknown defect/);assert.match(validate(f.data,f.root).join('\n'),/unknown related/);assert.match(validate(f.data,f.root).join('\n'),/unknown evidence/);
}finally{f.dispose();}});
test('platform status changes need recorded history',()=>{const f=fixture();try{
 const r=f.data.requirements[0];r.history[0].platform_snapshot=Object.fromEntries(Object.entries(r.platforms).map(([p,x])=>[p,{applicability:x.applicability,implementation:x.implementation.state,verification:x.verification.state,distribution:x.distribution.state}]));r.platforms.ios.implementation.state='PARCIAL';
 assert.match(validate(f.data,f.root).join('\n'),/platform changed without/);
}finally{f.dispose();}});
test('reconfirmation preserves old hash and can restore evidence applicability',()=>{const f=fixture();try{
 const e=f.data.evidence[0],original=e.file_refs[0].sha256;writeFileSync(join(f.root,'app.dart'),'implementation v2');
 e.reconfirmation={by:'reviewer',at:'2026-10-13T01:00:00-06:00',reason:'Prueba aplicable a cambio editorial confirmado',file_hashes:{'app.dart':sha('implementation v2')}};
 assert.equal(evidenceFreshness(e,f.root).state,'ACTUAL_RECONFIRMADA');assert.equal(e.file_refs[0].sha256,original);assert.equal(metrics(f.data,f.root).BASE.verified_current,1);
}finally{f.dispose();}});
test('stale failed evidence is retained but does not block later current validation',()=>{const f=fixture();try{
 const old=f.data.evidence[0];old.result='FAIL';writeFileSync(join(f.root,'app.dart'),'implementation v2');
 f.data.evidence.push({...old,id:'E2',result:'PASS',file_refs:[{path:'app.dart',sha256:sha('implementation v2')}]});for(const r of f.data.requirements)r.evidence_ids.push('E2');
 assert.deepEqual(validate(f.data,f.root),[]);assert.equal(metrics(f.data,f.root).BASE.verified_current,1);assert.equal(old.result,'FAIL');
}finally{f.dispose();}});
test('human answers recompute their figures from canonical states',()=>{const f=fixture();try{
 f.data.answers=[{number:1,question:'Implementación',answer:'999/999 obsolete manual figure'}];
 const output=render(f.data,f.root)['docs/MAREA_TRACKING.md'];assert.doesNotMatch(output,/999\/999/);assert.match(output,/2\/2 RF/);
}finally{f.dispose();}});
test('catalog identity and complete source metadata are mandatory',()=>{const f=fixture();try{
 const r=f.data.requirements[0];r.kind='AUX';r.source={line_start:4};r.history=[{type:'INITIAL_ASSESSMENT'}];
 const errors=validate(f.data,f.root).join('\n');assert.match(errors,/catalog identity/);assert.match(errors,/source metadata/);assert.match(errors,/history metadata/);
}finally{f.dispose();}});
test('complete validation binds both implementation and associated test sources',()=>{const f=fixture();try{
 writeFileSync(join(f.root,'acceptance.dart'),'test v1');for(const r of f.data.requirements)r.tests=['acceptance.dart'];
 assert.equal(metrics(f.data,f.root).BASE.verified_current,0);
 f.data.evidence[0].file_refs.push({path:'acceptance.dart',sha256:sha('test v1')});assert.equal(metrics(f.data,f.root).BASE.verified_current,1);
 writeFileSync(join(f.root,'acceptance.dart'),'test v2');assert.equal(metrics(f.data,f.root).BASE.verified_current,0);
}finally{f.dispose();}});
