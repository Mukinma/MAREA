import {readFileSync,existsSync,realpathSync} from 'node:fs';
import {resolve,relative,isAbsolute} from 'node:path';
import {createHash} from 'node:crypto';
import {isDeepStrictEqual} from 'node:util';
import {parseDocument} from 'yaml';

const sha=b=>createHash('sha256').update(b).digest('hex');
function checked(root,ref,errors,label){
 if(!ref||typeof ref.path!=='string'||isAbsolute(ref.path)||ref.path.split('/').includes('..')){errors.push(label+': invalid path');return null;}
 const p=resolve(root,ref.path);
 if(!existsSync(p)||relative(realpathSync(root),realpathSync(p)).startsWith('..')){errors.push(label+': missing or escaped path');return null;}
 const bytes=readFileSync(p);if(sha(bytes)!==ref.sha256){errors.push(label+' changed');return null;}return bytes;
}
export function designSource(data){return data.schema_version===2?data.normative_versions?.find(v=>v.id===data.normative_context?.design_version):data.baseline?.srs;}
export function extractSupplemental(text){
 return text.split('\n').flatMap((line,i)=>{const match=line.match(/^\| `((?:DECISION-51-\d{2}|TC-51-\d{3}))` \|/);if(!match)return [];
 const cells=line.split('|').slice(1,-1).map(x=>x.trim());return [{id:match[1],kind:match[1].startsWith('TC-')?'TC':'DECISION',line_start:i+1,line_end:i+1,text:line,sha256:sha(line),description:cells.slice(1).join(' | '),requirement_ids:[...new Set(line.match(/(?:RF-\d{2}-\d{3}|CT-[A-Z]+-[A-Z]+-\d{3}|CTR5-\d{2}|ADR42-\d{2}|AT5-\d{2}|AC-\d{2}|RB-\d{2})/g)??[])]}];});
}
export function validateVersioning(data,root,extractCatalog){
 if(data.schema_version!==2)return [];
 const errors=[],versions=data.normative_versions??[],ctx=data.normative_context??{},ids=new Set();
 for(const v of versions){if(!v.id||ids.has(v.id))errors.push('duplicate normative version');ids.add(v.id);checked(root,v,errors,'normative version');}
 const design=designSource(data),effective=versions.find(v=>v.id===ctx.effective_version);
 if(!design)errors.push('missing design normative version');
 if(!effective||effective.sha256!==data.baseline?.srs?.sha256||effective.version!==data.baseline?.srs?.version)errors.push('effective baseline must remain bound to its verified historical source');
 if(ctx.adoption_status!=='PENDIENTE_COMPATIBILIDAD_LOCAL')errors.push('unsupported normative adoption; separate future approval and compatibility verification required');
 const auth=data.evidence?.find(e=>e.id===ctx.authorization_evidence_id);
 if(auth?.kind!=='USER_CONFIRMATION'||!auth.path||!auth.file_refs?.length)errors.push('missing normative authorization');
 else{
  if(!auth.file_refs.some(ref=>ref.path===auth.path))errors.push('missing normative authorization path binding');
  for(const ref of auth.file_refs)checked(root,ref,errors,'normative authorization');
 }
 const snapshot=checked(root,data.preservation?.canonical_snapshot,errors,'canonical snapshot');
 if(snapshot){
  const doc=parseDocument(snapshot.toString('utf8'),{uniqueKeys:true});if(doc.errors.length){errors.push('invalid historical canonical snapshot');return errors;}
  const old=doc.toJS({maxAliasCount:0});
  if(!isDeepStrictEqual(old.baseline,data.baseline))errors.push('historical baseline altered');
  for(const collection of ['evidence','findings','decisions','orphans','components','test_runs','limitations'])for(const previous of old[collection]??[]){
   const current=data[collection]?.find(x=>x.id===previous.id);if(!isDeepStrictEqual(previous,current))errors.push(`historical ${collection==='evidence'?'evidence':collection} altered or lost: ${previous.id}`);
  }
  for(const previous of old.next_tasks??[])if(previous.id==='TASK-001'&&!isDeepStrictEqual(previous,data.next_tasks?.find(t=>t.id===previous.id)))errors.push('historical TASK-001 altered');
  for(const previous of old.requirements??[]){const r=data.requirements?.find(r=>r.id===previous.id);if(!r){errors.push('historical requirement lost: '+previous.id);continue;}
   if(r.assessment_normative_version!==effective?.id)errors.push('historical assessment normative binding altered: '+r.id);
   // This profile is deliberately documentary-only. Later product assessments need
   // a separately authorized evolution, not silent rewriting during reconciliation.
   for(const field of ['validity','implementation','verification','value','platforms','acceptance_criteria','evidence_ids','implementation_files','database_objects','tests','known_defects','progress'])if(!isDeepStrictEqual(r[field],previous[field]))errors.push(`historical assessment altered: ${r.id} ${field}`);
   if(!isDeepStrictEqual(previous.history,r.history?.slice(0,previous.history.length)))errors.push('historical history altered: '+r.id);
   if(!r.source_history?.some(h=>h.normative_version===effective?.id&&isDeepStrictEqual(h.source,previous.source)&&h.description===previous.description))errors.push('historical normative source lost: '+r.id);
  }
  const historical=new Map((old.requirements??[]).map(r=>[r.id,r]));
  const affected=new Set((data.requirements??[]).filter(r=>!historical.has(r.id)||r.source?.sha256!==historical.get(r.id).source?.sha256).map(r=>r.id));
  let expanded=true;while(expanded){expanded=false;for(const r of data.requirements??[])if(!affected.has(r.id)&&(r.dependencies??[]).some(id=>affected.has(id))){affected.add(r.id);expanded=true;}}
  for(const r of data.requirements??[])if(affected.has(r.id)&&r.normative_review?.status!=='PENDIENTE_REAUDITORIA')errors.push('normative re-audit required: '+r.id);
 }
 const bytes=design&&checked(root,design,errors,'design source');
 if(bytes){
  const raw=extractCatalog(bytes.toString('utf8'),{expanded:true}),aux=raw.filter(c=>c.kind==='AUX'),anchors=data.clause_anchors??[];
  const seen=new Set();
  for(const a of anchors){const key=a.section+':'+a.sha256;if(seen.has(key)||!/^TR-S[\d.]+-\d{3}$/.test(a.id)||a.review_status!=='REVISADA')errors.push('invalid frozen clause anchor '+a.id);seen.add(key);if(!aux.some(c=>c.section===a.section&&sha(c.text)===a.sha256))errors.push('unknown frozen clause anchor '+a.id);}
  for(const c of aux)if(!anchors.some(a=>a.section===c.section&&a.sha256===sha(c.text)))errors.push('missing frozen clause anchor '+c.section+':'+c.line_start);
  const supplemental=extractSupplemental(bytes.toString('utf8'));
  for(const c of supplemental){const record=(c.kind==='TC'?data.test_cases:data.decisions)?.find(x=>x.id===c.id);
   if(!record||record.normative_source?.sha256!==c.sha256||record.normative_source?.line_start!==c.line_start||record.normative_source?.line_end!==c.line_end||record.normative_source?.path!==design.path||record.normative_source?.normative_version!==design.id||record.description!==c.description)errors.push('invalid supplemental normative source '+c.id);
   if(c.kind==='TC'){
    if(!isDeepStrictEqual(record?.requirement_ids,c.requirement_ids))errors.push('invalid test requirement mapping '+c.id);
    if(record?.status!=='PENDIENTE'||record?.complete_requirement_validation!==false)errors.push('test execution not authorized in document reconciliation '+c.id);
   }
  }
  for(const t of data.test_cases??[])if(!supplemental.some(c=>c.kind==='TC'&&c.id===t.id))errors.push('unknown normative test '+t.id);
 }
 for(const r of data.requirements??[])if(r.source?.normative_version!==design?.id||!ids.has(r.assessment_normative_version))errors.push('invalid requirement normative binding '+r.id);
 for(const b of data.evidence_normative_bindings??[])if(!data.evidence?.some(e=>e.id===b.evidence_id)||!ids.has(b.normative_version))errors.push('invalid evidence normative binding '+b.evidence_id);
 for(const e of data.evidence??[])if(!data.evidence_normative_bindings?.some(b=>b.evidence_id===e.id))errors.push('missing evidence normative binding '+e.id);
 return errors;
}
