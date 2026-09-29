// Authorized integration test: only creates and cleans its own temporary users/posts.
// Credentials stay in memory; no existing account or message data is printed.
import {readFile,writeFile,unlink} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import {randomBytes,randomUUID} from 'node:crypto';
import assert from 'node:assert/strict';
if(!process.argv.includes('--run')){console.log('Usage: node tool/check_live_social_flow.mjs --run');process.exit(0);}
const config=JSON.parse(await readFile(new URL('../config/supabase.production.json',import.meta.url),'utf8'));
const base=config.SUPABASE_URL,publicKey=config.SUPABASE_ANON_KEY;
const ref=new URL(base).hostname.split('.')[0];
const keyResult=spawnSync('supabase',['projects','api-keys','--project-ref',ref,'--output','json'],{encoding:'utf8'});
if(keyResult.status!==0)throw Error('Administrative CLI unavailable');
const admin=JSON.parse(keyResult.stdout).find(k=>k.name==='service_role')?.api_key;
if(!admin)throw Error('Administrative credentials unavailable');
const users=[];let checks=0,postId,socket;
const check=(value,label)=>{assert.ok(value,label);checks++;};
async function request(path,{user,method='GET',body,headers={},privileged=false}={}){
 const key=privileged?admin:publicKey;
 const response=await fetch(base+path,{method,headers:{apikey:key,Authorization:`Bearer ${user?.token??key}`,'Content-Type':'application/json',...headers},body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(30000)});
 return response;
}
async function json(path,options,label='request'){const r=await request(path,options);if(!r.ok)throw Error(`${label} failed (${r.status})`);const text=await r.text();return text?JSON.parse(text):null;}
const rpc=(user,name,body)=>json(`/rest/v1/rpc/${name}`,{user,method:'POST',body},name);
async function signIn(user){const session=await json('/auth/v1/token?grant_type=password',{method:'POST',body:{email:user.email,password:user.password}},'temporary sign-in');user.token=session.access_token;}
const stats=async(user)=> (await rpc(user,'post_social_stats',{post_ids:[postId]}))[0];
async function realtime(user){
 const wsUrl=new URL(base.replace('https:','wss:')+'/realtime/v1/websocket');wsUrl.searchParams.set('apikey',publicKey);wsUrl.searchParams.set('vsn','1.0.0');
 socket=new WebSocket(wsUrl);
 let receive;
 const event=new Promise(resolve=>{receive=resolve;});
 const joined=new Promise((resolve,reject)=>{
  const timer=setTimeout(()=>reject(Error('Realtime join timed out')),15000);
  socket.addEventListener('open',()=>socket.send(JSON.stringify({topic:'realtime:social-test',event:'phx_join',ref:'1',payload:{config:{broadcast:{self:false},presence:{key:''},postgres_changes:[{event:'*',schema:'public',table:'notifications',filter:`recipient_id=eq.${user.id}`}],private:false},access_token:user.token}})));
  socket.addEventListener('message',message=>{const data=JSON.parse(message.data);if(data.event==='phx_reply'&&data.ref==='1'){clearTimeout(timer);data.payload.status==='ok'?resolve():reject(Error('Realtime join rejected'));}if(data.event==='postgres_changes')receive(data.payload);});
  socket.addEventListener('error',()=>{clearTimeout(timer);reject(Error('Realtime connection failed'));});
 });
 await joined;return {event};
}
try{
 const policy=await rpc(undefined,'registration_policy',{});const run=randomBytes(5).toString('hex');
 for(let i=0;i<3;i++){
  const user={email:`marea-social-${run}-${i}@example.invalid`,password:randomBytes(24).toString('base64url')};
  const created=await json('/auth/v1/admin/users',{privileged:true,method:'POST',body:{email:user.email,password:user.password,email_confirm:true,user_metadata:{full_name:'Prueba social temporal',username:`social_${run}_${i}`,user_type:'Usuario general',registration_flow:'minimal-v1',accepted_terms:true,adult_confirmed:true,terms_version:policy.terms.version,privacy_version:policy.privacy.version}}},'create temporary user');
  user.id=created.id;users.push(user);await writeFile('/tmp/marea-v7-social-test-users.json',JSON.stringify(users.map(u=>({id:u.id,email:u.email}))),{mode:0o600});await signIn(user);
 }
 const [owner,visitor,outsider]=users;
 const [post]=await json('/rest/v1/posts',{user:owner,method:'POST',body:{kind:'community',title:'Prueba social temporal',body:'Contenido creado exclusivamente para verificación.',category:'arte',allows_collaboration:true},headers:{Prefer:'return=representation'}},'create temporary post');postId=post.id;
 check(post.allows_collaboration===true,'explicit collaboration persists');
 const {event}=await realtime(owner);
 await Promise.all([rpc(visitor,'set_post_reaction',{post_uuid:postId,reaction_type:'inspire'}),rpc(visitor,'set_post_reaction',{post_uuid:postId,reaction_type:'inspire'})]);
 const realtimeEvent=await Promise.race([event,new Promise((_,reject)=>setTimeout(()=>reject(Error('Realtime notification timed out')),15000))]);
 check(Boolean(realtimeEvent),'recipient receives server notification through Realtime');socket.close();socket=null;
 check((await stats(visitor)).reaction_count===1,'concurrent retry has one reaction');
 let notifs=await json('/rest/v1/notifications?select=*',{user:owner});check(notifs.length===1,'concurrent reaction retry has one notification');const reactionId=notifs[0].id;
 await rpc(visitor,'set_post_reaction',{post_uuid:postId,reaction_type:'support'});
 notifs=await json('/rest/v1/notifications?select=*',{user:owner});check(notifs.length===1&&notifs[0].id===reactionId,'reaction change updates same event');
 await rpc(visitor,'set_post_reaction',{post_uuid:postId,reaction_type:null});check((await json('/rest/v1/notifications?select=id',{user:owner})).length===0,'removal deletes notification');
 await rpc(owner,'set_post_reaction',{post_uuid:postId,reaction_type:'like'});check((await json('/rest/v1/notifications?select=id',{user:owner})).length===0,'no self notification');
 const operation=randomUUID();
 const comments=await Promise.all([rpc(visitor,'create_post_comment',{post_uuid:postId,comment_body:'Comentario con reintento',operation_uuid:operation}),rpc(visitor,'create_post_comment',{post_uuid:postId,comment_body:'Comentario con reintento',operation_uuid:operation})]);
 check(comments[0]===comments[1]&&(await stats(owner)).comment_count===1,'concurrent comments are idempotent');
 check((await request('/rest/v1/rpc/create_post_comment',{user:visitor,method:'POST',body:{post_uuid:postId,comment_body:' ',operation_uuid:randomUUID()}})).status>=400,'blank comment rejected');
 check((await request('/rest/v1/rpc/create_post_comment',{user:visitor,method:'POST',body:{post_uuid:postId,comment_body:'x'.repeat(1001),operation_uuid:randomUUID()}})).status>=400,'long comment rejected');
 const interest=await Promise.all([rpc(visitor,'send_post_interest',{post_uuid:postId,interest_message:'Me interesa participar.'}),rpc(visitor,'send_post_interest',{post_uuid:postId,interest_message:'Me interesa participar.'})]);
 check(interest[0]===interest[1]&&(await stats(visitor)).interest_sent,'one private interest after concurrent retry');
 check((await json('/rest/v1/post_collaboration_interests?select=message',{user:outsider})).length===0,'outsider cannot read private interests');
 check((await json('/rest/v1/post_collaboration_interests?select=message',{user:owner}))[0].message==='Me interesa participar.','author can read private message');
 check((await json('/rest/v1/notifications?select=id',{user:outsider})).length===0,'outsider cannot read recipient notifications');
 const before=(await json('/rest/v1/notifications?select=created_at&order=created_at.desc&limit=1',{user:owner}))[0].created_at;
 await rpc(outsider,'create_post_comment',{post_uuid:postId,comment_body:'Una entrada concurrente nueva',operation_uuid:randomUUID()});
 await rpc(owner,'mark_notifications_read',{before_time:before});
 notifs=await json('/rest/v1/notifications?select=read_at',{user:owner});check(notifs.filter(n=>n.read_at===null).length===1,'mark-all preserves new events beyond watermark');
 await json('/rest/v1/post_saves',{user:visitor,method:'POST',body:{post_id:postId}},'save post');
 await json('/auth/v1/logout',{user:visitor,method:'POST'},'sign-out');await signIn(visitor);
 check((await stats(visitor)).interest_sent&&(await stats(visitor)).comment_count===2,'social data persists in new session');
 check((await json(`/rest/v1/post_saves?post_id=eq.${postId}&select=post_id`,{user:visitor})).length===1,'saved post persists in new session');
 const forbidden=await request('/rest/v1/rpc/delete_post_comment',{user:outsider,method:'POST',body:{comment_uuid:comments[0]}});check(!forbidden.ok,'unrelated visitor cannot remove comment');
 await rpc(owner,'delete_post_comment',{comment_uuid:comments[0]});check((await stats(owner)).comment_count===1,'post owner can moderate comment');
 await json(`/rest/v1/posts?id=eq.${postId}`,{user:owner,method:'DELETE'},'delete temporary post');
 check((await json(`/rest/v1/notifications?post_id=eq.${postId}&select=id`,{privileged:true})).length===0,'post removal cascades events');
 check((await json(`/rest/v1/post_collaboration_interests?post_id=eq.${postId}&select=id`,{privileged:true})).length===0,'post removal cascades interests');
 console.log(`${checks} live social checks passed: persistence, concurrent retry, recipient privacy, Realtime and cascades.`);
}finally{
 if(socket)socket.close();let failed=false;
 for(const user of users){const r=await request(`/auth/v1/admin/users/${user.id}`,{privileged:true,method:'DELETE'}).catch(()=>null);if(!r?.ok)failed=true;}
 if(failed)throw Error('Temporary social account cleanup requires attention');
 await unlink('/tmp/marea-v7-social-test-users.json').catch(()=>{});
}
