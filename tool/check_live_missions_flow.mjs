// Opt-in hosted verification. Creates only three temporary .invalid users and
// resources belonging to them. Never modifies or prints existing account data.
// Administrative credentials and temporary passwords/tokens stay in memory.
import {readFile,writeFile,mkdtemp,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import {randomBytes,randomUUID} from 'node:crypto';
import assert from 'node:assert/strict';
if(!process.argv.includes('--run')){
 console.log('Usage: node tool/check_live_missions_flow.mjs --run');
 console.log('Requires deployed migrations 001–013. Creates and cleans three temporary users; completion check waits up to 16 seconds.');
 process.exit(0);
}
const gate=spawnSync(process.execPath,[fileURLToPath(new URL('./check_backend_contract.mjs',import.meta.url))],{encoding:'utf8'});
if(gate.status!==0)throw Error('Backend contract is not ready; apply migrations before running live mission verification.');
const config=JSON.parse(await readFile(new URL('../config/supabase.production.json',import.meta.url),'utf8'));
const base=config.SUPABASE_URL,publicKey=config.SUPABASE_ANON_KEY;
const ref=new URL(base).hostname.split('.')[0];
const keyResult=spawnSync('supabase',['projects','api-keys','--project-ref',ref,'--output','json'],{encoding:'utf8'});
if(keyResult.status!==0)throw Error('Administrative CLI unavailable');
const keys=JSON.parse(keyResult.stdout);
const admin=(Array.isArray(keys)?keys:keys.rows)?.find(k=>k.name==='service_role')?.api_key;
if(!admin)throw Error('Administrative credentials unavailable');
const users=[],media=[];
const checkpoint=await mkdtemp(join(tmpdir(),'marea-missions-live-'));
let checks=0;
const check=(value,label)=>{assert.ok(value,label);checks++;};
const pause=ms=>new Promise(resolve=>setTimeout(resolve,ms));
async function record(){
 await writeFile(join(checkpoint,'resources.json'),JSON.stringify({users:users.map(u=>({id:u.id,email:u.email})),media}),{mode:0o600});
}
async function request(path,{user,method='GET',body,bytes,headers={},privileged=false}={}){
 const key=privileged?admin:publicKey;
 return fetch(base+path,{method,headers:{apikey:key,Authorization:`Bearer ${user?.token??key}`,'Content-Type':'application/json',...headers},body:bytes??(body===undefined?undefined:JSON.stringify(body)),signal:AbortSignal.timeout(30000)});
}
async function json(path,options,label='request'){
 const response=await request(path,options);
 if(!response.ok)throw Error(`${label} failed (${response.status})`);
 const text=await response.text();return text?JSON.parse(text):null;
}
const rpc=(user,name,body)=>json(`/rest/v1/rpc/${name}`,{user,method:'POST',body},name);
const denied=async(user,name,body,label)=>check(!(await request(`/rest/v1/rpc/${name}`,{user,method:'POST',body})).ok,label);
const rows=(user,table,query)=>json(`/rest/v1/${table}?${query}`,{user});
const applications=(user,id)=>rows(user,'mission_applications',`mission_id=eq.${id}&select=id,applicant_id,status,availability_confirmed,evidence`);
const notices=(user,id,kind)=>rows(user,'notifications',`mission_id=eq.${id}&kind=eq.${kind}&select=id,source_id`);
async function signIn(user){
 const session=await json('/auth/v1/token?grant_type=password',{method:'POST',body:{email:user.email,password:user.password}},'temporary sign-in');
 user.token=session.access_token;
}
async function upload(user,bucket){
 const path=`${user.id}/${randomUUID()}.png`;
 // A tiny valid PNG fixture; no remote photographs or user files are involved.
 const bytes=Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6QyQAAAAASUVORK5CYII=','base64');
 media.push({bucket,path});await record();
 await json(`/storage/v1/object/${bucket}/${path}`,{user,method:'POST',bytes,headers:{'Content-Type':'image/png'}},'upload temporary fixture');
 return path;
}
try{
 const policy=await rpc(undefined,'registration_policy',{});
 const run=randomBytes(5).toString('hex');
 const types=['Negocio','Artista / creador','Usuario general'];
 for(let i=0;i<3;i++){
  const user={email:`marea-missions-${run}-${i}@example.invalid`,password:randomBytes(24).toString('base64url')};
  const created=await json('/auth/v1/admin/users',{privileged:true,method:'POST',body:{email:user.email,password:user.password,email_confirm:true,user_metadata:{full_name:'Prueba temporal de misiones',username:`mission_${run}_${i}`,user_type:types[i],registration_flow:'minimal-v1',accepted_terms:true,adult_confirmed:true,terms_version:policy.terms.version,privacy_version:policy.privacy.version}}},'create temporary user');
  user.id=created.id;users.push(user);await record();await signIn(user);
 }
 const [owner,visitor,outsider]=users;
 const image=await upload(owner,'mission-images');
 const draftId=randomUUID();
 const draft={title:'',body:'',category:'otros',target_type:null,capacity:101,capacity_text:'101',requirements:'',conditions:'',location:'',starts_at:null,starts_date:'2030-01-01T00:00:00.000',starts_hour:23,starts_minute:59,image_path:image,location_latitude:null,location_longitude:null,location_precision:null,compensation_type:'paid',compensation_amount_cents:0,compensation_amount_text:'0.'};
 const savedDrafts=await Promise.all([rpc(owner,'save_mission_draft',{draft_id:draftId,draft_input:draft}),rpc(owner,'save_mission_draft',{draft_id:draftId,draft_input:draft})]);
 check(savedDrafts.every(id=>id===draftId),'concurrent draft save is idempotent and accepts real partial numeric-time payload');
 check((await rows(owner,'mission_drafts',`id=eq.${draftId}&select=data`))[0].data.starts_hour===23,'draft raw time persisted');
 check((await rows(visitor,'mission_drafts',`id=eq.${draftId}&select=id`)).length===0,'draft private');
 await denied(visitor,'save_mission_draft',{draft_id:draftId,draft_input:{title:'Foreign mutation'}},'foreign draft update denied');
 await denied(visitor,'publish_mission_draft',{draft_id:draftId,mission_input:{}},'foreign draft publication denied');
 check(!(await request(`/storage/v1/object/sign/mission-images/${image}`,{user:visitor,method:'POST',body:{expiresIn:60}})).ok,'unpublished draft cover private');
 const missionInput={title:`Verificación temporal ${run}`,body:'Misión exclusiva para verificación automática.',category:'arte',location:'Ciudad de México',starts_at:new Date(Date.now()+86400000).toISOString(),capacity:1,target_type:null,image_path:image,requirements:'Muestras opcionales',conditions:'Prueba temporal',compensation_type:'paid',compensation_amount_cents:25050};
 const published=await Promise.all([rpc(owner,'publish_mission_draft',{draft_id:draftId,mission_input:missionInput}),rpc(owner,'publish_mission_draft',{draft_id:draftId,mission_input:missionInput})]);
 const missionId=published[0];check(published.every(id=>id===missionId),'concurrent publication creates one mission');
 check((await rows(owner,'missions',`id=eq.${missionId}&select=compensation_type,compensation_amount_cents`))[0].compensation_amount_cents===25050,'compensation persisted');
 await denied(owner,'delete_mission_draft',{draft_id:draftId},'publication retry journal retained');
 await denied(owner,'create_mission',{mission_input:{...missionInput,compensation_amount_cents:0}},'invalid paid compensation denied');
 await Promise.all([rpc(visitor,'set_mission_saved',{mission_id:missionId,is_saved:true}),rpc(visitor,'set_mission_saved',{mission_id:missionId,is_saved:true})]);
 check((await rows(visitor,'mission_saves',`mission_id=eq.${missionId}&select=mission_id`)).length===1,'concurrent save deduplicated');
 check((await rows(outsider,'mission_saves',`mission_id=eq.${missionId}&select=mission_id`)).length===0,'saves private');
 check((await rpc(visitor,'list_saved_missions',{query_text:run})).some(m=>m.id===missionId),'saved mission query uses server search');
 const showcaseImage=await upload(visitor,'showcase-media');
 const showcase=await rpc(visitor,'save_showcase',{item_input:{kind:'project',title:'Obra temporal',body:'Muestra propia de prueba',category:'arte',status:'published',available:true,image_paths:[showcaseImage]},item_id:null});
 const operationId=randomUUID();
 const applicationInput={message:'Quiero colaborar en esta prueba.',availability_confirmed:true,evidence:[{title:'Mi obra',showcase_id:showcase},{title:'Mi enlace',url:'https://example.invalid/portfolio'}],operation_id:operationId};
 const submitted=await Promise.all([rpc(visitor,'submit_mission_application',{mission_id:missionId,application_input:applicationInput}),rpc(visitor,'submit_mission_application',{mission_id:missionId,application_input:applicationInput})]);
 const visitorApp=submitted[0];check(submitted.every(id=>id===visitorApp),'concurrent application retry returns same row');
 await denied(visitor,'submit_mission_application',{mission_id:missionId,application_input:{...applicationInput,message:'Altered retry'}},'operation input immutable');
 await denied(outsider,'submit_mission_application',{mission_id:missionId,application_input:{...applicationInput,operation_id:randomUUID()}},'foreign showcase denied');
 await denied(outsider,'submit_mission_application',{mission_id:missionId,application_input:{...applicationInput,operation_id:randomUUID(),evidence:[],availability_confirmed:false}},'availability required');
 const outsiderOperation=randomUUID();
 const outsiderInput={message:'También colaboraré.',availability_confirmed:true,evidence:[],operation_id:outsiderOperation};
 const outsiderApp=await rpc(outsider,'submit_mission_application',{mission_id:missionId,application_input:outsiderInput});
 check((await applications(visitor,missionId)).length===1&&(await applications(visitor,missionId))[0].evidence.length===2,'applicant reads only own structured candidature');
 check((await applications(outsider,missionId)).length===1&&(await applications(outsider,missionId))[0].id===outsiderApp,'other candidate cannot read private evidence');
 check((await applications(owner,missionId)).length===2,'organizer reads both candidatures');
 check((await notices(owner,missionId,'mission_application')).length===2,'one notice per real candidature');
 await rpc(owner,'update_mission',{mission_id:missionId,mission_input:{title:'Título temporal actualizado'}});
 check((await rows(owner,'missions',`id=eq.${missionId}&select=compensation_amount_cents`))[0].compensation_amount_cents===25050,'legacy partial edit preserves compensation');
 await denied(owner,'update_mission',{mission_id:missionId,mission_input:{compensation_type:null,compensation_amount_cents:null}},'compensation locked after application');
 await rpc(owner,'set_mission_finalist',{mission_id:missionId,application_id:visitorApp,is_finalist:true});
 await rpc(owner,'set_mission_finalist',{mission_id:missionId,application_id:visitorApp,is_finalist:true});
 check((await rows(owner,'mission_finalists',`mission_id=eq.${missionId}&select=application_id`)).length===1,'finalist retry deduplicated');
 check((await rows(visitor,'mission_finalists',`mission_id=eq.${missionId}&select=application_id`)).length===0,'finalist list private to organizer');
 check((await notices(visitor,missionId,'mission_accepted')).length===0,'finalist does not notify participant');
 await denied(visitor,'confirm_mission_selection',{mission_id:missionId,application_ids:[visitorApp]},'participant cannot select');
 await denied(owner,'confirm_mission_selection',{mission_id:missionId,application_ids:[visitorApp,outsiderApp]},'over-capacity group rejected');
 check((await applications(owner,missionId)).every(a=>a.status==='pending'),'failed group selection changes no candidate');
 const selection=await Promise.allSettled([rpc(owner,'confirm_mission_selection',{mission_id:missionId,application_ids:[visitorApp]}),rpc(owner,'confirm_mission_selection',{mission_id:missionId,application_ids:[outsiderApp]})]);
 check(selection.filter(r=>r.status==='fulfilled').length===1,'concurrent selection respects one remaining place');
 const roster=await applications(owner,missionId);const winner=roster.find(a=>a.status==='accepted'),loser=roster.find(a=>a.status==='pending');
 check(roster.filter(a=>a.status==='accepted').length===1,'one accepted candidate after concurrency');
 const winnerUser=users.find(u=>u.id===winner.applicant_id),loserUser=users.find(u=>u.id===loser.applicant_id);
 const winnerInput=winner.id===visitorApp?applicationInput:outsiderInput;
 await rpc(owner,'confirm_mission_selection',{mission_id:missionId,application_ids:[winner.id]});
 check((await notices(winnerUser,missionId,'mission_accepted')).length===1,'selection retry produces no extra notice');
 check((await rows(owner,'missions',`id=eq.${missionId}&select=status`))[0].status==='open','selection leaves mission open');
 await rpc(winnerUser,'withdraw_application',{application_id:winner.id});
 check((await notices(owner,missionId,'mission_withdrawn')).length===1,'withdrawal notifies organizer');
 await rpc(winnerUser,'submit_mission_application',{mission_id:missionId,application_input:winnerInput});
 check((await applications(winnerUser,missionId))[0].status==='withdrawn','lost-response retry does not undo withdrawal');
 const reapplied=await rpc(winnerUser,'submit_mission_application',{mission_id:missionId,application_input:{...winnerInput,operation_id:randomUUID()}});
 check(reapplied===winner.id,'fresh operation reapplies same history row');
 check((await notices(owner,missionId,'mission_application')).filter(n=>n.source_id===winner.id).length===2,'reapplication emits separate real event');
 await rpc(owner,'review_application',{application_id:loser.id,decision:'rejected'});
 await rpc(owner,'review_application',{application_id:loser.id,decision:'rejected'});
 check((await notices(loserUser,missionId,'mission_rejected')).length===1,'rejection retry deduplicated');
 await rpc(owner,'set_mission_status',{mission_id:missionId,new_status:'closed',cancellation_reason:null});
 await rpc(owner,'set_mission_status',{mission_id:missionId,new_status:'closed',cancellation_reason:null});
 check((await notices(winnerUser,missionId,'mission_closed')).length===1,'close retry deduplicated');
 check((await notices(loserUser,missionId,'mission_closed')).length===0,'inactive rejected candidate excluded from lifecycle notice');
 await rpc(owner,'set_mission_status',{mission_id:missionId,new_status:'open',cancellation_reason:null});
 check((await notices(winnerUser,missionId,'mission_reopened')).length===1,'reopen notifies active candidate');
 await rpc(owner,'set_mission_status',{mission_id:missionId,new_status:'closed',cancellation_reason:null});
 check((await notices(winnerUser,missionId,'mission_closed')).length===2,'second real closure emits new event');
 await denied(owner,'set_mission_status',{mission_id:missionId,new_status:'cancelled',cancellation_reason:'No'},'cancellation reason validated');
 await rpc(owner,'set_mission_status',{mission_id:missionId,new_status:'cancelled',cancellation_reason:'Fin de verificación temporal'});
 await rpc(owner,'set_mission_status',{mission_id:missionId,new_status:'cancelled',cancellation_reason:'Fin de verificación temporal'});
 check((await notices(winnerUser,missionId,'mission_cancelled')).length===1,'cancellation retry deduplicated');
 await denied(owner,'set_mission_status',{mission_id:missionId,new_status:'open',cancellation_reason:null},'terminal mission cannot reopen');
 check((await rpc(visitor,'list_saved_missions',{query_text:'Título temporal actualizado'}))[0].status==='cancelled','saved history remains available');
 // A separate short-lived fixture naturally reaches its start time; no privileged
 // bypass of lifecycle/condition locks and no existing mission edits are needed.
 const startAt=Date.now()+15000;
 const completion=await rpc(owner,'create_mission',{mission_input:{...missionInput,title:'Finalización temporal',image_path:null,starts_at:new Date(startAt).toISOString()}});
 const completionApp=await rpc(visitor,'submit_mission_application',{mission_id:completion,application_input:{...applicationInput,evidence:[],operation_id:randomUUID()}});
 await rpc(owner,'confirm_mission_selection',{mission_id:completion,application_ids:[completionApp]});
 await denied(owner,'set_mission_status',{mission_id:completion,new_status:'completed',cancellation_reason:null},'completion before start denied');
 await pause(Math.max(0,startAt+1000-Date.now()));
 await rpc(owner,'set_mission_status',{mission_id:completion,new_status:'completed',cancellation_reason:null});
 await rpc(owner,'set_mission_status',{mission_id:completion,new_status:'completed',cancellation_reason:null});
 check((await notices(visitor,completion,'mission_completed')).length===1,'completion emits one event per active candidate');
 await json('/auth/v1/logout',{user:visitor,method:'POST'},'temporary sign-out');await signIn(visitor);
 check((await rows(visitor,'mission_saves',`mission_id=eq.${missionId}&select=mission_id`)).length===1,'saved mission persists across sign-in');
 check((await applications(visitor,missionId)).length===1,'application history persists across sign-in');
 await json(`/rest/v1/missions?id=eq.${missionId}`,{user:owner,method:'DELETE'},'delete temporary mission');
 check((await rows(owner,'mission_applications',`mission_id=eq.${missionId}&select=id`)).length===0,'mission removal cascades private candidatures');
 check((await rows(owner,'notifications',`mission_id=eq.${missionId}&select=id`)).length===0,'mission removal cascades recipient events');
 await denied(owner,'publish_mission_draft',{draft_id:draftId,mission_input:missionInput},'publication retry cannot resurrect deleted mission');
 await json('/storage/v1/object/mission-images',{user:owner,method:'DELETE',body:{prefixes:[image]}},'remove released mission cover');
 check(!(await request(`/storage/v1/object/sign/mission-images/${image}`,{user:owner,method:'POST',body:{expiresIn:60}})).ok,'published journal does not pin deleted mission cover');
 console.log(`${checks} live mission checks passed: concurrent publication/submission/selection, draft and evidence privacy, immutable compensation, lifecycle notices, persistence and cascades.`);
}finally{
 let cleanupFailed=false;
 for(const {bucket,path} of media){
  let ok=false;
  for(let attempt=0;attempt<3&&!ok;attempt++){
   const response=await request(`/storage/v1/object/${bucket}`,{privileged:true,method:'DELETE',body:{prefixes:[path]}}).catch(()=>null);
   ok=response?.ok===true;if(!ok)await pause(300);
  }
  if(!ok)cleanupFailed=true;
 }
 for(const user of users){
  let ok=false;
  for(let attempt=0;attempt<3&&!ok;attempt++){
   const response=await request(`/auth/v1/admin/users/${user.id}`,{privileged:true,method:'DELETE'}).catch(()=>null);
   ok=response?.ok===true;if(!ok)await pause(300);
  }
  if(!ok)cleanupFailed=true;
 }
 if(cleanupFailed)throw Error(`Temporary mission cleanup requires attention; recovery IDs are in ${join(checkpoint,'resources.json')}.`);
 await rm(checkpoint,{recursive:true,force:true});
}
