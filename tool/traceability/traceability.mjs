import {readFileSync, existsSync, realpathSync} from 'node:fs';
import {resolve, relative, isAbsolute} from 'node:path';
import {createHash} from 'node:crypto';
import {designSource,validateVersioning} from './versioning.mjs';
export const STATES={
 validity:['VIGENTE','EN_REVISION','FUERA_DE_ALCANCE','NO_APLICA','DESCARTADO','DUPLICADO','REEMPLAZADO'],
 implementation:['NO_AUDITADO','NO_INICIADO','EN_PROGRESO','PARCIAL','IMPLEMENTADO','BLOQUEADO','PAUSADO','REQUIERE_RETRABAJO','RETIRADO'],
 verification:['NO_EVALUADO','PENDIENTE_PRUEBAS','EN_PRUEBAS','PRUEBAS_FALLIDAS','VALIDADO','VALIDADO_CON_LIMITACIONES'],
 value:['JUSTIFICADO','POR_VALIDAR','REDUNDANTE','INNECESARIO','SIN_USO','OBSOLETO','IMPLEMENTACION_NO_SOLICITADA'],
 distribution:['NO_INTEGRADO','LOCAL','DESARROLLO','STAGING','PRODUCCION']};
export const hash=bytes=>createHash('sha256').update(bytes).digest('hex');
export const BEGIN='<!-- MAREA:GENERATED:BEGIN -->',END='<!-- MAREA:GENERATED:END -->';
const read=(root,path)=>readFileSync(resolve(root,path),'utf8');
const explicitId=/^(?:- \*\*((?:RF-\d{2}-\d{3}|CT-[A-Z]+-[A-Z]+-\d{3}|RB-\d{2}|CTR5-\d{2}))\b|#{3,4} ((?:ADR42|AC)-\d{2})\b|\| `((?:ADR41|AT5)-\d{2}|G\d|B\d{2})`)/;
export function extractCatalog(text,{expanded=false,anchors=[]}={}){
 const lines=text.split('\n'),out=[],counts={};let section='',module=null;
 const aux=new Set(['1.1','1.2','2','2.1','3.1','3.2','3.3','3.4','3.5','4.1','4.2','4.3','4.4','4.5','10.1','11.3','12.2','12.3']);
 if(expanded)for(const section of ['0','0.1','0.2','3.6','3.7','3.8','3.9','3.10','3.11','9.3'])aux.add(section);
 for(let i=0;i<lines.length;i++){
  const line=lines[i],heading=line.match(/^#{2,4} (\d+(?:\.\d+)*)\.?\s/);if(heading)section=heading[1];
  const mod=line.match(/^### (M\d{2})\b/);if(mod)module=mod[1];const match=line.match(explicitId);
  if(match){const id=match[1]||match[2]||match[3],kind=id.startsWith('CT-')?'CT':/^G\d$/.test(id)?'G':/^B\d{2}$/.test(id)?'B':id.split('-')[0];let end=i;
   if(match[2]){const level=line.match(/^#+/)[0].length;while(end+1<lines.length&&!new RegExp(`^#{1,${level}} `).test(lines[end+1]))end++;}
   const phase=kind==='RF'?(line.match(/\| `(BASE|PILOTO|POST|CONDICIONAL)` \|/)?.[1]??null):null;
   const description=kind==='RF'?line.split('|').slice(2).join('|').trim():kind==='CTR5'?line.replace(/^- \*\*CTR5-\d{2}\*\*\s*/, '').trim():match[1]?line.split('|').slice(1).join('|').trim():match[3]?line.split('|').slice(3,-1).join('|').trim():lines.slice(i,end+1).join('\n').trim();
   out.push({id,kind,module:kind==='RF'?module:null,phase,description,section,line_start:i+1,line_end:end+1,text:lines.slice(i,end+1).join('\n')});continue;}
  if(!aux.has(section)||!line.trim()||line.startsWith('#'))continue;
  const bullet=/^(?:- |\d+\. )/.test(line),row=line.startsWith('|')&&!/\|\s*-+/.test(line)&&['1.1','2','3.1','3.4',...(expanded?['3.8','3.10']:[])].includes(section)&&!/^\| (Fase|Entidad|Acción|Origen legado|Recurso)/.test(line);
  const paragraph=section==='3.3'&&line.startsWith('Material:')||section==='12.3'&&line.startsWith('`VALIDADO`')||section==='3.1'&&line.startsWith('**Proyecciones')||section==='3.4'&&line.startsWith('**Permisos');
  const extra=expanded&&((section==='0.1'&&line.startsWith('**Puertas'))||(section==='0.2'&&line.startsWith('El responsable'))||(section==='3.10'&&line.startsWith('La política jurídica'))||(section==='3.8'&&line.startsWith('**Invariante')));
  if(bullet||row||paragraph||extra){counts[section]=(counts[section]??0)+1;const anchor=anchors.find(a=>a.section===section&&a.sha256===hash(line));out.push({id:anchor?.id??`TR-S${section}-${String(counts[section]).padStart(3,'0')}`,kind:'AUX',module:null,phase:null,description:line.replace(/^(?:- |\d+\. )/,''),section,line_start:i+1,line_end:i+1,text:line});}
 }return out;
}
function pathError(root,path){
 if(typeof path!=='string'||isAbsolute(path)||path.split('/').includes('..'))return `invalid path ${path}`;
 const target=resolve(root,path);if(!existsSync(target))return `missing path ${path}`;
 if(relative(realpathSync(root),realpathSync(target)).startsWith('..'))return `path escapes repository ${path}`;return null;
}
export function evidenceFreshness(e,root){
 const refs=e.file_refs??[],changed=refs.filter(ref=>pathError(root,ref.path)||hash(readFileSync(resolve(root,ref.path)))!==ref.sha256).map(ref=>ref.path);
 if(changed.length){const c=e.reconfirmation,confirmed=c?.reason&&c?.by&&c?.at&&changed.every(p=>!pathError(root,p)&&c.file_hashes?.[p]===hash(readFileSync(resolve(root,p))));return {state:confirmed?'ACTUAL_RECONFIRMADA':'POTENCIALMENTE_OBSOLETA',changed};}
 return {state:refs.length||e.kind==='USER_CONFIRMATION'?'ACTUAL':'NO_COMPROBABLE',changed};
}
export function validate(data,root){
 const errors=[],rs=data.requirements??[],evs=data.evidence??[],byId=new Map(rs.map(r=>[r.id,r])),ev=new Map(evs.map(e=>[e.id,e])),seen=new Set();
 if(![1,2].includes(data.schema_version))errors.push('invalid schema_version');
 errors.push(...validateVersioning(data,root,extractCatalog));
 const others=[...(data.findings??[]),...(data.decisions??[]),...(data.orphans??[]),...(data.components??[]),...(data.test_runs??[]),...(data.test_cases??[])];
 for(const e of [...rs,...evs,...others]){if(!e.id||seen.has(e.id))errors.push(`duplicate ID or missing ID ${e.id}`);seen.add(e.id);}
 const norm=designSource(data);
 let catalog=[];if(pathError(root,norm?.path))errors.push('missing protected SRS');else{const s=read(root,norm.path);if(hash(readFileSync(resolve(root,norm.path)))!==norm.sha256)errors.push('protected SRS changed; explicit approval and new normative version required');catalog=extractCatalog(s,{expanded:data.schema_version===2,anchors:data.clause_anchors??[]});}
 const source=new Map(catalog.map(c=>[c.id,c]));if(source.size!==catalog.length)errors.push('duplicate ID in normative source');
 for(const c of catalog)if(!byId.has(c.id))errors.push(`missing ID ${c.id}`);
 for(const r of rs){const c=source.get(r.id);if(!c)errors.push(`unknown normative ID ${r.id}`);
  if(c&&(r.kind!==c.kind||r.module!==c.module||r.original_id!==(c.kind==='AUX'?null:c.id)))errors.push(`${r.id}: invalid catalog identity`);
  if(c&&(r.source?.path!==norm.path||r.source?.line_end!==c.line_end||r.source?.section!==c.section||r.source?.sha256!==hash(c.text)||r.description!==c.description))errors.push(`${r.id}: invalid source metadata`);
  if(c&&r.source?.line_start!==c.line_start)errors.push(`${r.id}: invalid source line`);
  if(c&&r.source?.sha256&&r.source.sha256!==hash(c.text))errors.push(`${r.id}: normative excerpt changed`);
  if(c&&r.phase!=null&&(r.phase!==c.phase||!r.phase_source))errors.push(`${r.id}: phase without normative support`);
  if(r.phase==null&&r.phase_proposal?.status!=='PENDIENTE_APROBACION')errors.push(`${r.id}: ambiguous phase lacks proposal`);
  for(const d of ['validity','implementation','verification','value']){if(!STATES[d].includes(r[d]?.state))errors.push(`${r.id}: invalid ${d}`);if(!r[d]?.reason)errors.push(`${r.id}: missing ${d} justification`);}
  if(['DESCARTADO','REEMPLAZADO','FUERA_DE_ALCANCE'].includes(r.validity?.state)){const d=(data.decisions??[]).find(d=>d.id===r.validity.approval_id);if(d?.status!=='APROBADA'||d?.approved_by_type!=='HUMAN'||!d?.approved_at||!ev.has(d?.approval_evidence_id))errors.push(`${r.id}: approval required for reserved validity`);}
  for(const field of ['canonical_id','successor_id'])if(r.validity?.[field]&&!byId.has(r.validity[field]))errors.push(`${r.id}: unknown ${field}`);
  if(r.validity?.state==='DUPLICADO'&&!r.validity.canonical_id)errors.push(`${r.id}: missing canonical_id`);
  if(r.validity?.state==='REEMPLAZADO'&&!r.validity.successor_id)errors.push(`${r.id}: missing successor_id`);
  for(const id of r.dependencies??[])if(!byId.has(id)||id===r.id)errors.push(`${r.id}: unknown dependency ${id}`);
  for(const id of r.related_requirements??[])if(!byId.has(id)||id===r.id)errors.push(`${r.id}: unknown related requirement ${id}`);
  for(const id of r.known_defects??[])if(!(data.findings??[]).some(f=>f.id===id))errors.push(`${r.id}: unknown defect ${id}`);
  for(const id of r.evidence_ids??[])if(!ev.has(id))errors.push(`${r.id}: unknown evidence ${id}`);
  for(const p of [...(r.implementation_files??[]),...(r.tests??[])]){const error=pathError(root,p);if(error)errors.push(`${r.id}: ${error}`);}
  const cs=r.acceptance_criteria??[];if(!cs.length)errors.push(`${r.id}: missing acceptance criteria`);
  for(const criterion of cs){if(!criterion.id||seen.has(criterion.id))errors.push(`${r.id}: duplicate ID criterion ${criterion.id}`);seen.add(criterion.id);if(!STATES.implementation.includes(criterion.implementation)||!criterion.description||!criterion.reason)errors.push(`${r.id}: invalid criterion`);for(const p of [...(criterion.files??[]),...(criterion.tests??[])]){const error=pathError(root,p);if(error)errors.push(`${criterion.id}: ${error}`);}}
  if(r.implementation?.state==='IMPLEMENTADO'&&cs.some(c=>c.implementation!=='IMPLEMENTADO'))errors.push(`${r.id}: incomplete mandatory criteria`);
  if(r.progress?.percent!=null&&(r.progress.method!=='CRITERIA_EQUAL_COUNT'||!cs.length||r.progress.percent!==Math.round(10000*cs.filter(c=>c.implementation==='IMPLEMENTADO').length/cs.length)/100))errors.push(`${r.id}: unjustified progress`);
  for(const p of ['web','android','ios']){const x=r.platforms?.[p];if(!x||!['APLICA','NO_APLICA','POR_CONFIRMAR'].includes(x.applicability)||!x.reason)errors.push(`${r.id}: invalid platform ${p}`);
   for(const d of ['implementation','verification'])if(!STATES[d].includes(x?.[d]?.state)||!x?.[d]?.reason)errors.push(`${r.id}: invalid ${p} ${d}`);
   if(x?.distribution?.state!=null&&!STATES.distribution.includes(x.distribution.state))errors.push(`${r.id}: invalid distribution ${p}`);
   if(!x?.distribution?.reason)errors.push(`${r.id}: missing distribution justification ${p}`);
   if(x?.distribution?.state!=null&&!(x.distribution.evidence_ids??[]).length)errors.push(`${r.id}: distribution without evidence ${p}`);
   for(const id of x?.distribution?.evidence_ids??[])if(!ev.has(id))errors.push(`${r.id}: unknown distribution evidence ${id}`);}
  if(r.verification?.state==='VALIDADO'&&(r.evidence_ids??[]).some(id=>ev.get(id)?.kind==='TEST_EXECUTION'&&ev.get(id)?.result==='FAIL'&&evidenceFreshness(ev.get(id),root).state.startsWith('ACTUAL')))errors.push(`${r.id}: failed evidence contradicts validation`);
  const history=r.history??[];for(const h of history){if(!h.at||!Number.isFinite(Date.parse(h.at))||!h.reason||!h.snapshot||!h.platform_snapshot||['validity','implementation','verification','value'].some(d=>!STATES[d].includes(h.snapshot?.[d]))||['web','android','ios'].some(p=>!h.platform_snapshot?.[p]))errors.push(`${r.id}: missing history metadata`);}
  if(!history.length||history[0].type!=='INITIAL_ASSESSMENT')errors.push(`${r.id}: missing initial assessment`);
  const snap=Object.fromEntries(['validity','implementation','verification','value'].map(d=>[d,r[d]?.state]));if(history.at(-1)?.snapshot&&Object.entries(snap).some(([k,v])=>history.at(-1).snapshot[k]!==v))errors.push(`${r.id}: state changed without matching history`);
  if(history.at(-1)?.platform_snapshot){const ps=Object.fromEntries(Object.entries(r.platforms).map(([p,x])=>[p,{applicability:x.applicability,implementation:x.implementation.state,verification:x.verification.state,distribution:x.distribution.state}]));if(Object.entries(ps).some(([p,x])=>Object.entries(x).some(([k,v])=>history.at(-1).platform_snapshot[p]?.[k]!==v)))errors.push(`${r.id}: platform changed without matching history`);}
  for(let i=1;i<history.length;i++){const h=history[i],prev=history[i-1];if(!h.at||!h.reason||Date.parse(h.at)<Date.parse(prev.at))errors.push(`${r.id}: invalid history transition`);if(h.snapshot?.implementation!==prev.snapshot?.implementation&&!(data.state_transitions?.[prev.snapshot?.implementation]??[]).includes(h.snapshot?.implementation))errors.push(`${r.id}: illegal implementation transition`);}
  if(['BLOQUEADO','PAUSADO'].includes(r.implementation?.state)&&!r.blocker?.reason)errors.push(`${r.id}: missing blocker`);
 }
 for(const e of evs){if(!e.description||!e.kind||!e.captured_at)errors.push(`${e.id}: incomplete evidence`);if(e.path){const error=pathError(root,e.path);if(error)errors.push(`${e.id}: ${error}`);}for(const ref of e.file_refs??[]){const error=pathError(root,ref.path);if(error)errors.push(`${e.id}: ${error}`);if(!/^[a-f0-9]{64}$/.test(ref.sha256??''))errors.push(`${e.id}: invalid sha256`);}}
 for(const e of others){for(const id of e.evidence_ids??[])if(!ev.has(id))errors.push(`${e.id}: unknown evidence ${id}`);if(e.evidence_id&&!ev.has(e.evidence_id))errors.push(`${e.id}: unknown evidence ${e.evidence_id}`);for(const id of e.requirement_ids??[])if(!byId.has(id))errors.push(`${e.id}: unknown requirement reference ${id}`);for(const p of e.files??[]){const error=pathError(root,p);if(error)errors.push(`${e.id}: ${error}`);}}
 function visit(id,trail){if(trail.includes(id)){errors.push(`relation cycle ${[...trail,id].join(' -> ')}`);return;}const r=byId.get(id);for(const next of [...(r?.dependencies??[]),r?.validity?.canonical_id,r?.validity?.successor_id].filter(Boolean))if(byId.has(next))visit(next,[...trail,id]);}
 for(const r of rs)visit(r.id,[]);return [...new Set(errors)];
}
const active=r=>['VIGENTE','EN_REVISION'].includes(r.validity.state);
function currentValidation(r,data,root,platform=null){
 if(data.schema_version===2&&(data.normative_context?.adoption_status!=='ADOPTADA'||r.assessment_normative_version!==data.normative_context.design_version))return false;
 if(r.implementation.state!=='IMPLEMENTADO'||r.verification.state!=='VALIDADO'||!r.acceptance_criteria?.length||r.acceptance_criteria.some(c=>c.implementation!=='IMPLEMENTADO'))return false;
 const evs=data.evidence.filter(e=>(r.evidence_ids??[]).includes(e.id)),actual=e=>evidenceFreshness(e,root).state.startsWith('ACTUAL');
 if(evs.some(e=>e.kind==='TEST_EXECUTION'&&e.result==='FAIL'&&actual(e)))return false;
 const ps=platform?[platform]:['web','android','ios'].filter(p=>r.platforms[p].applicability==='APLICA');
 if(!ps.length||!platform&&Object.values(r.platforms).some(p=>p.applicability==='POR_CONFIRMAR'))return false;
 return ps.every(p=>r.platforms[p].verification.state==='VALIDADO'&&r.platforms[p].implementation.state==='IMPLEMENTADO'&&evs.some(e=>e.kind==='TEST_EXECUTION'&&e.result==='PASS'&&e.complete_requirement_validation===true&&(e.platforms??[]).includes(p)&&[...(r.implementation_files??[]),...(r.tests??[])].every(path=>(e.file_refs??[]).some(ref=>ref.path===path))&&actual(e)));
}
function summarize(rows,data,root,platform=null){
 const rs=rows.filter(active).filter(r=>!platform||r.platforms[platform].applicability!=='NO_APLICA'),state=r=>platform?r.platforms[platform].implementation.state:r.implementation.state,states={};for(const r of rs)states[state(r)]=(states[state(r)]??0)+1;
 const audited=rs.filter(r=>state(r)!=='NO_AUDITADO').length;
 return {denominator:rs.length,total:rows.length,excluded:rows.filter(r=>!active(r)||platform&&r.platforms[platform].applicability==='NO_APLICA').map(r=>({id:r.id,reason:r.validity.reason})),audited,not_audited:rs.length-audited,implementation_complete:states.IMPLEMENTADO??0,affirmative_implementation_identified:rs.filter(r=>state(r)==='IMPLEMENTADO'&&r.implementation.nature==='AFFIRMATIVE_IMPLEMENTATION_IDENTIFIED').length,prohibition_satisfied:rs.filter(r=>state(r)==='IMPLEMENTADO'&&r.implementation.nature==='PROHIBITION_SATISFIED').length,verified_historical:rs.filter(r=>r.implementation.state==='IMPLEMENTADO'&&(platform?r.platforms[platform].verification.state:r.verification.state)==='VALIDADO').length,verified_current:rs.filter(r=>currentValidation(r,data,root,platform)).length,test_linked:rs.filter(r=>r.tests?.length).length,ambiguous_phase:rs.filter(r=>r.phase==null).length,states};
}
export function metrics(data,root){
 const rf=data.requirements.filter(r=>r.kind==='RF'),m={};for(const p of ['BASE','PILOTO','PRODUCTO_COMPLETO'])m[p]=summarize(p==='PRODUCTO_COMPLETO'?rf:rf.filter(r=>r.phase===p),data,root);
 m.phase_unresolved_catalog=data.requirements.filter(r=>r.phase==null).map(r=>r.id);for(const phase of ['BASE','PILOTO'])m[phase].other_phase_exclusions=rf.filter(r=>r.phase!==phase).map(r=>({id:r.id,phase:r.phase,reason:r.phase==null?'Fase pendiente de aprobación':'Fase normativa distinta'}));
 m.catalog={total:data.requirements.length,audited:data.requirements.filter(r=>r.implementation.state!=='NO_AUDITADO').length,ambiguous_phase:data.requirements.filter(r=>r.phase==null).length};
 if(data.schema_version===2)m.normative={...data.normative_context,review_pending:data.requirements.filter(r=>r.normative_review?.status==='PENDIENTE_REAUDITORIA').length,test_cases:(data.test_cases??[]).length};
 m.modules={};for(const name of [...new Set(rf.map(r=>r.module))].sort())m.modules[name]=summarize(rf.filter(r=>r.module===name),data,root);
 m.platforms={};for(const p of ['web','android','ios'])m.platforms[p]=summarize(rf,data,root,p);
 m.stale_evidence=data.evidence.filter(e=>evidenceFreshness(e,root).state==='POTENCIALMENTE_OBSOLETA').map(e=>e.id);m.orphan_candidates=data.orphans.length;m.unnecessary_confirmed=data.orphans.filter(o=>o.value==='INNECESARIO'&&(data.decisions??[]).some(d=>d.id===o.approval_id&&d.status==='APROBADA'&&d.approved_by_type==='HUMAN'&&d.approved_at)).length;return m;
}
export function replaceGenerated(original,body){
 const starts=original.split(BEGIN).length-1,ends=original.split(END).length-1,block=BEGIN+'\n'+body.trimEnd()+'\n'+END;
 if(!starts&&!ends)return original+(original.endsWith('\n')?'\n':'\n\n')+block+'\n';
 if(starts!==1||ends!==1||original.indexOf(END)<original.indexOf(BEGIN))throw new Error('invalid generated delimiter structure');
 return original.slice(0,original.indexOf(BEGIN))+block+original.slice(original.indexOf(END)+END.length);
}
export {render} from './render.mjs';
