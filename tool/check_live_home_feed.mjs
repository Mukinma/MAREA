// Opt-in hosted verification. Fixtures belong only to temporary .invalid users.
// Credentials stay in memory; a recovery journal contains only fixture IDs.
import {readFile,writeFile,mkdtemp,rm} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {spawnSync} from 'node:child_process';
import {randomBytes,randomUUID} from 'node:crypto';
import assert from 'node:assert/strict';
if(!process.argv.includes('--run')){console.log('Usage: node tool/check_live_home_feed.mjs --run');process.exit(0);}
const config=JSON.parse(await readFile(new URL('../config/supabase.production.json',import.meta.url),'utf8'));
const base=config.SUPABASE_URL,publicKey=config.SUPABASE_ANON_KEY,ref=new URL(base).hostname.split('.')[0];
const cli=args=>{const result=spawnSync('supabase',args,{encoding:'utf8'});if(result.status!==0)throw Error('Administrative CLI unavailable');return JSON.parse(result.stdout);};
const resultRows=result=>Array.isArray(result)?result:result.rows;
const admin=resultRows(cli(['projects','api-keys','--project-ref',ref,'--output','json'])).find(k=>k.name==='service_role')?.api_key;
assert.ok(admin,'Administrative credentials unavailable');
const workerSecret=resultRows(cli(['db','query','--linked','--output','json',"select decrypted_secret as value from vault.decrypted_secrets where name='marea_story_worker_secret'"]))?.[0]?.value;
assert.ok(workerSecret,'Cleanup worker unavailable');
const users=[],media=[],journal=await mkdtemp(join(tmpdir(),'marea-home-feed-'));
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
try{
 const policy=await rpc(undefined,'registration_policy',{}),run=randomBytes(5).toString('hex');
 for(let i=0;i<3;i++){
  const user={email:`marea-feed-${run}-${i}@example.invalid`,password:randomBytes(24).toString('base64url')};
  const created=await json('/auth/v1/admin/users',{privileged:true,method:'POST',body:{email:user.email,password:user.password,email_confirm:true,user_metadata:{full_name:'Prueba temporal de Inicio',username:`feed_${run}_${i}`,user_type:i===0?'Negocio':'Usuario general',registration_flow:'minimal-v1',accepted_terms:true,adult_confirmed:true,terms_version:policy.terms.version,privacy_version:policy.privacy.version}}},'create temporary user');
  user.id=created.id;users.push(user);await record();await signIn(user);
 }
 const [owner,viewer,other]=users;
 await denied(viewer,'set_profile_follow',{author_uuid:viewer.id,following:true},'self following denied');
 await Promise.all([rpc(viewer,'set_profile_follow',{author_uuid:owner.id,following:true}),rpc(viewer,'set_profile_follow',{author_uuid:owner.id,following:true})]);
 check((await rows(viewer,'profile_follows',`author_id=eq.${owner.id}&select=author_id`)).length===1,'concurrent following idempotent');
 check((await rows(other,'profile_follows',`author_id=eq.${owner.id}&select=author_id`)).length===0,'following private');
 const postData=Array.from({length:32},(_,i)=>({kind:'community',title:`Feed temporal ${run} ${i}`,body:'Contenido exclusivo para comprobación.',category:'arte',location:'CDMX',location_latitude:19.4326,location_longitude:-99.1332,location_precision:'approximate'}));
 const posts=await json('/rest/v1/posts',{user:owner,method:'POST',body:postData,headers:{Prefer:'return=representation'}},'create temporary posts');
 const missionInput={title:`Misión temporal ${run}`,body:'Misión exclusiva para comprobación.',category:'arte',location:'CDMX',starts_at:new Date(Date.now()+86400000).toISOString(),capacity:1,target_type:null,image_path:null,requirements:'',conditions:'Prueba temporal',compensation_type:'unpaid',compensation_amount_cents:null,location_latitude:19.4326,location_longitude:-99.1332,location_precision:'approximate'};
 const mission=await rpc(owner,'create_mission',{mission_input:missionInput});
 const filters={mode:'following',kind:'all',category:null,latitude:null,longitude:null,radius_km:10};
 const first=await rpc(viewer,'home_feed',{filters,page_cursor:null});
 const second=await rpc(viewer,'home_feed',{filters,page_cursor:first.cursor});
 check(first.entries.length===30&&second.entries.length===3,'combined 30-item cursor pages');
 check(first.entries[0].kind==='mission','created_at chronology mixes content');
 check(new Set([...first.entries,...second.entries].map(e=>e.kind+e.content.id)).size===33,'stable pagination with tied post times');
 await denied(other,'home_feed',{filters,page_cursor:first.cursor},'foreign cursor denied');
 check((await rpc(viewer,'home_feed',{filters:{...filters,kind:'mission'},page_cursor:null})).entries.length===1,'mission content filter');
 check((await rpc(viewer,'home_feed',{filters:{...filters,category:'musica'},page_cursor:null})).entries.length===0,'empty category explicit');
 await patch('profiles',viewer.id,{interests:['musica']});
 check(!(await rpc(viewer,'home_feed',{filters:{...filters,mode:'forYou'},page_cursor:null})).entries.some(e=>e.content.author_id===owner.id),'stored interests applied');
 await patch('profiles',viewer.id,{interests:[]});
 const far=await rpc(viewer,'home_feed',{filters:{...filters,mode:'nearby',latitude:0,longitude:0},page_cursor:null});
 check(!far.entries.some(e=>e.content.author_id===owner.id),'nearby excludes distant fixtures');
 const near=await rpc(viewer,'home_feed',{filters:{...filters,mode:'nearby',latitude:19.43,longitude:-99.13},page_cursor:null});
 check(near.entries.some(e=>e.content.author_id===owner.id),'nearby includes fixtures within 10km');
 await rpc(viewer,'set_post_reaction',{post_uuid:posts[0].id,reaction_type:'like'});
 const trends=await rpc(viewer,'home_feed',{filters:{...filters,mode:'trending'},page_cursor:null});
 check(trends.entries.some(e=>e.content.id===posts[0].id),'real reactions enter trends');
 const application=await rpc(viewer,'submit_mission_application',{mission_id:mission,application_input:{message:'Colaboraré.',availability_confirmed:true,evidence:[],operation_id:randomUUID()}});
 await rpc(owner,'confirm_mission_selection',{mission_id:mission,application_ids:[application]});
 const full=(await rpc(viewer,'home_feed',{filters:{...filters,kind:'mission'},page_cursor:null})).entries[0].content;
 check(full.accepted_count===1&&full.capacity===1,'full missions retain real occupancy');
 await denied(other,'submit_mission_application',{mission_id:mission,application_input:{message:'Otro intento.',availability_confirmed:true,evidence:[],operation_id:randomUUID()}},'full mission application restricted');
 await rpc(owner,'set_mission_status',{mission_id:mission,new_status:'cancelled',cancellation_reason:'Fin de prueba temporal'});
 check((await rpc(viewer,'home_feed',{filters:{...filters,kind:'mission'},page_cursor:null})).entries.length===0,'cancelled missions excluded');
 const story=randomUUID(),path=`${owner.id}/${story}.png`;
 media.push({bucket:'story-images',path});await record();
 await json('/storage/v1/object/story-images/'+path,{user:owner,method:'POST',bytes:Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6QyQAAAAASUVORK5CYII=','base64'),headers:{'Content-Type':'image/png'}},'story upload');
 check(!(await request('/storage/v1/object/sign/story-images/'+path,{user:other,method:'POST',body:{expiresIn:60}})).ok,'unpublished story image private');
 const input={story_uuid:story,story_body:'Historia temporal con foto.',story_image:path};
 const published=await Promise.all(Array.from({length:4},()=>rpc(owner,'publish_story',input)));
 check(published.every(id=>id===story),'concurrent story publication idempotent');
 const listed=(await rpc(viewer,'list_stories',{})).stories.find(s=>s.id===story);
 check(listed&&!listed.seen&&Date.parse(listed.expires_at)-Date.parse(listed.created_at)===86400000,'server expiration exactly 24 hours');
 await json('/storage/v1/object/sign/story-images/'+path,{user:viewer,method:'POST',body:{expiresIn:60}},'live private image signing');checks++;
 check(!(await request('/storage/v1/object/public/story-images/'+path)).ok,'bucket not public');
 await rpc(viewer,'mark_story_seen',{story_uuid:story});
 await signIn(viewer);
 check((await rpc(viewer,'list_stories',{})).stories.find(s=>s.id===story)?.seen,'story views persist after sign-in');
 check((await rows(viewer,'profile_follows',`author_id=eq.${owner.id}&select=author_id`)).length===1,'following persists after sign-in');
 await denied(viewer,'delete_story',{story_uuid:story},'foreign deletion denied');
 await denied(viewer,'moderate_story',{story_uuid:story,hide:true},'nonadmin moderation denied');
 await denied(owner,'publish_story',{...input,story_body:'Altered retry'},'publication payload immutable');
 await rpc(viewer,'report_story',{story_uuid:story,report_reason:'Reporte temporal para comprobar permisos.'});
 check((await rows(other,'story_reports',`story_id=eq.${story}&select=story_id`)).length===0,'reports private');
 await patch('stories',story,{expires_at:new Date(Date.now()-1000).toISOString()});
 check(!(await rpc(owner,'list_stories',{})).stories.some(s=>s.id===story),'expired story unavailable to author');
 check(!(await request('/storage/v1/object/sign/story-images/'+path,{user:owner,method:'POST',body:{expiresIn:60}})).ok,'expired image cannot be signed');
 check((await request('/functions/v1/story-cleanup',{method:'POST',body:{}})).status===403,'cleanup worker rejects clients');
 await json('/functions/v1/story-cleanup',{method:'POST',body:{},headers:{'x-story-worker-secret':workerSecret}},'authorized cleanup');
 check((await rows(owner,'stories',`id=eq.${story}&select=id`)).length===0,'cleanup removes expired story');
 await rpc(owner,'publish_story',input);
 check(!(await rpc(viewer,'list_stories',{})).stories.some(s=>s.id===story),'late retry cannot resurrect a cleaned story');
 check(!(await request(`/rest/v1/story_publications?id=eq.${story}&select=id`,{user:owner})).ok,'publication receipt private to server');
 const textStory=randomUUID();await rpc(owner,'publish_story',{story_uuid:textStory,story_body:'Historia solo de texto.',story_image:null});
 await rpc(owner,'delete_story',{story_uuid:textStory});
 check(!(await rpc(viewer,'list_stories',{})).stories.some(s=>s.id===textStory),'deletion hides immediately');
 // Deletion exercises the deployed account cleanup including story files/follows.
 const accountStory=randomUUID(),accountPath=`${owner.id}/${accountStory}.png`;
 media.push({bucket:'story-images',path:accountPath});await record();
 await json('/storage/v1/object/story-images/'+accountPath,{user:owner,method:'POST',bytes:Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6QyQAAAAASUVORK5CYII=','base64'),headers:{'Content-Type':'image/png'}},'account story upload');
 await rpc(owner,'publish_story',{story_uuid:accountStory,story_body:'Historia para comprobar eliminación de cuenta.',story_image:accountPath});
 await json('/functions/v1/delete-account',{user:owner,method:'POST',body:{}},'temporary account deletion');owner.deleted=true;
 check((await rows(viewer,'profile_follows',`author_id=eq.${owner.id}&select=author_id`)).length===0,'account deletion cascades following');
 check(!(await rpc(viewer,'list_stories',{})).stories.some(s=>s.author_id===owner.id),'account deletion removes stories');
 check(!(await request('/storage/v1/object/sign/story-images/'+accountPath,{privileged:true,method:'POST',body:{expiresIn:60}})).ok,'account deletion removes private files');
 check((await json(`/rest/v1/story_publications?author_id=eq.${owner.id}&select=id`,{privileged:true})).length===0,'account deletion removes operation receipts');
 console.log(`${checks} live home feed checks passed: pagination, filters, follows, trends, mission occupancy, stories, RLS, cleanup and account deletion.`);
}finally{
 let failed=false;
 for(const item of media){const r=await request('/storage/v1/object/'+item.bucket,{privileged:true,method:'DELETE',body:{prefixes:[item.path]}}).catch(()=>null);if(!r?.ok)failed=true;}
 for(const user of users){if(user.deleted)continue;const r=await request('/auth/v1/admin/users/'+user.id,{privileged:true,method:'DELETE'}).catch(()=>null);if(!r?.ok)failed=true;}
 if(failed)throw Error(`Temporary fixture cleanup requires attention; recovery IDs: ${join(journal,'resources.json')}`);
 await rm(journal,{recursive:true,force:true});
}
