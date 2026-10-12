// Opt-in hosted verification. Fixtures belong only to temporary .invalid users.
// Credentials stay in memory; a recovery journal contains only fixture IDs.
import {readFile,writeFile,mkdtemp,rm} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {spawnSync} from 'node:child_process';
import {randomBytes,randomUUID} from 'node:crypto';
import assert from 'node:assert/strict';
if(!process.argv.includes('--run')){console.log('Usage: node tool/check_live_feed_correction.mjs --run');process.exit(0);}
const config=JSON.parse(await readFile(new URL('../config/supabase.production.json',import.meta.url),'utf8'));
const base=config.SUPABASE_URL,publicKey=config.SUPABASE_ANON_KEY,ref=new URL(base).hostname.split('.')[0];
const cli=args=>{const result=spawnSync('supabase',args,{encoding:'utf8'});if(result.status!==0)throw Error('Administrative CLI unavailable');return JSON.parse(result.stdout);};
const resultRows=result=>Array.isArray(result)?result:result.rows;
const admin=resultRows(cli(['projects','api-keys','--project-ref',ref,'--output','json'])).find(k=>k.name==='service_role')?.api_key;
assert.ok(admin,'Administrative credentials unavailable');
const users=[],media=[],journal=await mkdtemp(join(tmpdir(),'marea-feed-correction-'));
let checks=0;
const check=(value,label)=>{assert.ok(value,label);checks++;};
const record=()=>writeFile(join(journal,'resources.json'),JSON.stringify({users:users.map(u=>({id:u.id,email:u.email})),media}),{mode:0o600});
async function request(path,{user,method='GET',body,bytes,privileged=false,headers={}}={}){
 const key=privileged?admin:publicKey;
 return fetch(base+path,{method,headers:{apikey:key,Authorization:`Bearer ${user?.token??key}`,'Content-Type':'application/json',...headers},body:bytes??(body===undefined?undefined:JSON.stringify(body)),signal:AbortSignal.timeout(30000)});
}
async function json(path,options,label=path){const r=await request(path,options);if(!r.ok)throw Error(`${label} failed (${r.status})`);const text=await r.text();return text?JSON.parse(text):null;}
const rpc=(user,name,body)=>json('/rest/v1/rpc/'+name,{user,method:'POST',body},name);
const denied=async(user,name,body,label)=>check(!(await request('/rest/v1/rpc/'+name,{user,method:'POST',body})).ok,label);
const rows=(user,table,query)=>json(`/rest/v1/${table}?${query}`,{user});
async function signIn(user){user.token=(await json('/auth/v1/token?grant_type=password',{method:'POST',body:{email:user.email,password:user.password}},'temporary sign-in')).access_token;}
async function patch(table,id,body){return json(`/rest/v1/${table}?id=eq.${id}`,{privileged:true,method:'PATCH',body},'temporary fixture patch');}
try {
 const policy=await rpc(undefined,'registration_policy',{}),run=randomBytes(5).toString('hex');
 for(let i=0;i<3;i++){
  const user={email:`marea-correction-${run}-${i}@example.invalid`,password:randomBytes(24).toString('base64url')};
  const created=await json('/auth/v1/admin/users',{privileged:true,method:'POST',body:{email:user.email,password:user.password,email_confirm:true,user_metadata:{full_name:'Comprobación temporal de corrección',username:`fix_${run}_${i}`,user_type:i===0?'Negocio':'Usuario general',registration_flow:'minimal-v1',accepted_terms:true,adult_confirmed:true,terms_version:policy.terms.version,privacy_version:policy.privacy.version}}},'create temporary user');
  user.id=created.id;users.push(user);await record();await signIn(user);
 }
 const [owner,viewer,other]=users;
 const mission=await rpc(owner,'create_mission',{mission_input:{title:'Misión de comprobación temporal',body:'Solo prueba aislada.',category:'arte',location:'Ciudad de México',starts_at:new Date(Date.now()+86400000).toISOString(),capacity:2,target_type:null,image_path:null,requirements:'',conditions:'Prueba temporal',compensation_type:'unpaid',compensation_amount_cents:null,location_latitude:19.4326,location_longitude:-99.1332,location_precision:'exact',location_city:{name:'Ciudad de México',point:{latitude:19.4326,longitude:-99.1332}}}});
 check((await rows(viewer,'missions',`id=eq.${mission}&select=location_city`))[0].location_city.name==='Ciudad de México','mission city stored');
 await rpc(viewer,'set_mission_saved',{mission_id:mission,is_saved:true});
 await rpc(viewer,'set_mission_saved',{mission_id:mission,is_saved:false});
 check((await rows(viewer,'mission_saves',`mission_id=eq.${mission}&select=mission_id`)).length===0,'mission save undo');
 await rpc(viewer,'set_mission_reaction',{mission_uuid:mission,reaction_type:'like'});
 await rpc(viewer,'set_mission_reaction',{mission_uuid:mission,reaction_type:'support'});
 const stats=(await rpc(viewer,'mission_social_stats',{mission_ids:[mission]}))[0];
 check(stats.reaction_count===1&&stats.my_reaction==='support','one confirmed reaction replacement');
 const operation=randomUUID(),input={mission_uuid:mission,comment_body:'Comentario temporal concurrente.',operation_uuid:operation};
 const ids=await Promise.all(Array.from({length:8},()=>rpc(viewer,'create_mission_comment',input)));
 check(ids.every(id=>id===ids[0]),'independent hosted concurrent comment retries return one id');
 check((await rows(viewer,'mission_comments',`mission_id=eq.${mission}&select=id`)).length===1,'one concurrent comment row');
 await denied(viewer,'create_mission_comment',{...input,comment_body:'Payload diferente.'},'changed retry payload denied');
 const notices=await rows(owner,'notifications',`mission_id=eq.${mission}&select=kind,source_id`);
 check(notices.some(n=>n.kind==='reaction')&&notices.some(n=>n.kind==='comment'&&n.source_id===ids[0]),'compatible notification kinds and mission comment source');
 await denied(other,'delete_mission_comment',{comment_uuid:ids[0]},'foreign commenter deletion denied');
 await rpc(owner,'delete_mission_comment',{comment_uuid:ids[0]});
 check(await rpc(viewer,'create_mission_comment',input)===ids[0],'moderated retry returns original receipt');
 check((await rows(viewer,'mission_comments',`mission_id=eq.${mission}&select=id`)).length===0,'late retry cannot resurrect removed comment');
 await rpc(viewer,'create_mission_comment',{mission_uuid:mission,comment_body:'Nueva conversación.',operation_uuid:randomUUID()});
 await rpc(other,'set_mission_reaction',{mission_uuid:mission,reaction_type:'inspire'});
 await rpc(viewer,'set_profile_follow',{author_uuid:owner.id,following:true});
 const posts=await json('/rest/v1/posts',{user:owner,method:'POST',body:{kind:'community',title:'Publicación de comprobación temporal',body:'Solo prueba.',category:'arte'},headers:{Prefer:'return=representation'}});
 await rpc(viewer,'set_post_reaction',{post_uuid:posts[0].id,reaction_type:'like'});
 const trending=await rpc(viewer,'home_feed',{filters:{mode:'trending',kind:'all',category:null,latitude:null,longitude:null,radius_km:10},page_cursor:null});
 const missionRank=trending.entries.findIndex(e=>e.content.id===mission),postRank=trending.entries.findIndex(e=>e.content.id===posts[0].id);
 check(missionRank>=0&&postRank>=0&&missionRank<postRank,'distinct mission social actors outrank one post actor');
 await patch('missions',mission,{hidden:true});
 check((await rows(viewer,'mission_comments',`mission_id=eq.${mission}&select=id`)).length===0,'hidden mission comments inaccessible');
 await denied(viewer,'set_mission_reaction',{mission_uuid:mission,reaction_type:'like'},'hidden social write denied');
 check((await rpc(viewer,'mission_social_stats',{mission_ids:[mission]})).length===0,'hidden stats absent');
 await patch('missions',mission,{hidden:false});
 const cached=await json('/functions/v1/geocoding',{method:'POST',body:{mode:'content_city',contentKind:'mission',contentId:mission,latitude:19.4326,longitude:-99.1332},user:viewer},'persisted city geocoding');
 check(cached.city.name==='Ciudad de México','stored content city resolves without provider fetch');
 check((await request('/functions/v1/geocoding',{method:'POST',body:{mode:'content_city',contentKind:'mission',contentId:mission,latitude:19.4326,longitude:-99.1332}})).status===401,'content city requires valid user');
 await json('/functions/v1/delete-account',{user:owner,method:'POST',body:{}},'temporary owner account deletion');owner.deleted=true;
 for(const table of ['mission_reactions','mission_comments','mission_comment_operations']) check((await json(`/rest/v1/${table}?mission_id=eq.${mission}&select=*`,{privileged:true})).length===0,`${table} cascades with mission/account`);
 console.log(`${checks} hosted correction checks passed, including eight concurrent HTTP comment retries.`);
} finally {
 let failed=false;
 for(const user of users){if(user.deleted)continue;const r=await request('/auth/v1/admin/users/'+user.id,{privileged:true,method:'DELETE'}).catch(()=>null);if(!r?.ok)failed=true;}
 if(failed)throw Error(`Temporary fixture cleanup requires attention; recovery IDs: ${join(journal,'resources.json')}`);
 await rm(journal,{recursive:true,force:true});
}
