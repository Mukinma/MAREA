import {readFileSync,writeFileSync} from 'node:fs';
import {join,resolve} from 'node:path';
import {randomUUID} from 'node:crypto';
import {localClient} from './http.mjs';
const path=resolve(process.argv[2]||''),api=localClient(path),f=JSON.parse(readFileSync(join(path,'fixtures-private.json'))),results=[],stamp=Date.now();
const delay=ms=>new Promise(r=>setTimeout(r,ms));
function record(scenario_id,subcase,result,observed){results.push({scenario_id,subcase,result,modality:'real',observed});writeFileSync(join(path,'session-results-'+stamp+'.json'),JSON.stringify({id:'E-TASK001-SESSION-'+api.marker.project_id+'-'+stamp,at:new Date().toISOString(),results,complete_requirement_validation:false,remote_modified:false},null,2)+'\n',{mode:0o600});}
const owner=await api.login(f.users.owner),candidate=await api.login(f.users.candidateA);const messages=[];
const ws=new WebSocket(`ws://127.0.0.1:${api.marker.api_port}/realtime/v1/websocket?apikey=${encodeURIComponent(api.keys.ANON_KEY)}&vsn=1.0.0`);
const topic='realtime:task001-'+randomUUID();ws.addEventListener('message',e=>{try{messages.push(JSON.parse(e.data));}catch{}});
await new Promise((ok,fail)=>{ws.addEventListener('open',ok,{once:true});ws.addEventListener('error',()=>fail(Error('Local Realtime transport unavailable')),{once:true});setTimeout(()=>fail(Error('Local Realtime transport timed out')),10000).unref();});
ws.send(JSON.stringify({topic,event:'phx_join',payload:{config:{broadcast:{ack:false,self:false},presence:{key:''},postgres_changes:[{event:'*',schema:'public',table:'notifications',filter:'recipient_id=eq.'+f.users.owner.id}]},access_token:owner.access_token},ref:'1',join_ref:'1'}));
let joined=false;for(let i=0;i<100;i++){if(messages.some(m=>m.event==='phx_reply'&&m.ref==='1'&&m.payload.status==='ok')){joined=true;break;}await delay(100);}
const heartbeat=setInterval(()=>{if(ws.readyState===1)ws.send(JSON.stringify({topic:'phoenix',event:'heartbeat',payload:{},ref:String(Date.now())}));},5000);
try {
 if(!joined){record('T001-SESSION-REALTIME','authenticated channel join','FAIL',{join:false});}
 else {
  for(let i=0;i<150&&!messages.some(m=>m.event==='system'&&m.payload?.status==='ok'&&m.payload?.extension==='postgres_changes');i++)await delay(100);
  record('T001-SESSION-REALTIME','authenticated private notification channel joined','PASS',{joined:true});
  const mr=await api.request('/rest/v1/missions?select=id&author_id=eq.'+f.users.owner.id+'&limit=1',{actor:'service'});if(!mr.ok||!mr.body.length)throw Error('Synthetic Realtime resource missing');const mid=mr.body[0].id;
  async function notify(body){const r=await api.rpc('create_mission_comment',{mission_uuid:mid,comment_body:body,operation_uuid:randomUUID()},candidate);if(!r.ok)throw Error('Synthetic notification operation failed');return r.body;}
  const id=await notify('Synthetic Realtime positive control');let delivered=false;
  const received=ident=>messages.some(m=>m.event==='postgres_changes'&&m.payload?.data?.record?.source_id===ident);
  for(let i=0;i<100;i++){if(received(id)){delivered=true;break;}await delay(100);}
  record('T001-SESSION-REALTIME','positive own notification received over open socket',delivered?'PASS':'FAIL',{received:delivered});
  if(delivered){
   const logout=await api.request('/auth/v1/logout?scope=global',{method:'POST',actor:owner});if(!logout.ok)throw Error('Local logout setup failed');
   const second=await notify('Synthetic event after session revocation');await delay(2500);const leaked=received(second);const post=await api.request('/rest/v1/notifications?select=id&source_id=eq.'+second,{actor:'service'});if(!post.ok||post.body.length!==1)throw Error('Realtime postcondition missing');
   record('T001-SESSION-REALTIME','revocation on same socket; no voluntary reconnect',leaked?'FAIL':'PASS',{event_persisted:1,received_after_revocation:leaked,socket_open:ws.readyState===1,reconnections:0,observation_ms:2500});
  }
 }
}finally{writeFileSync(join(path,'realtime-events-private-'+stamp+'.json'),JSON.stringify(messages),{flag:'wx',mode:0o600});clearInterval(heartbeat);ws.close();}
// Verify the actual JWT claim, plus documented PostgREST skew allowance. No SDK refresh.
const expiring=await api.login(f.users.third);const claims=JSON.parse(Buffer.from(expiring.access_token.split('.')[1],'base64url'));
const before=await api.request('/rest/v1/profiles?id=eq.'+f.users.third.id,{actor:expiring});if(!before.ok||before.body.length!==1)throw Error('JWT positive control unavailable');
record('T001-SESSION-JWT','JWT positive control with actual exp claim','PASS',{duration_seconds:claims.exp-claims.iat,initial_rows:1});
await delay(Math.max(0,claims.exp*1000-Date.now()+32000));
const expired=await api.request('/rest/v1/profiles?id=eq.'+f.users.third.id,{actor:expiring});record('T001-SESSION-JWT','actual exp plus 32 seconds; refresh disabled',!expired.ok?'PASS':'FAIL',{status:expired.status,refresh_used:false,exp_claim_used:true,skew_wait_seconds:32});
console.log(JSON.stringify({subcases_executed:results.length,counts:Object.fromEntries(['PASS','FAIL'].map(k=>[k,results.filter(r=>r.result===k).length])),receipt:'session-results-'+stamp+'.json'}));
