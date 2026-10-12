import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {stripTypeScriptTypes} from 'node:module';
import vm from 'node:vm';

function harness({delayRead=false,delayClaim=false,finishFails=false,fetchFails=false,fetchDuration=0}={}) {
 let now=0,wallOffset=0,handler,reads=0,leaseId=null,leaseUntil=0,nextAllowed=0,release,reached;
 const starts=[],cache=new Map();
 const blocked=new Promise(resolve=>reached=resolve),gate=new Promise(resolve=>release=resolve);
 const client={rpc:async(name,args)=>{
  if(name==='claim_geocoding_request') {
   if(delayClaim) {now=21500;delayClaim=false;}
   const ok=(leaseId===null||now>=leaseUntil)&&now>=nextAllowed;
   if(ok){leaseId=args.request_id;leaseUntil=now+30000;}
   return {data:ok,error:null};
  }
  if(finishFails)return {error:new Error('finish_failed')};
  if(leaseId===args.request_id){leaseId=null;leaseUntil=0;nextAllowed=now+1000;}
  return {error:null};
 },from(){let key;const builder={select(){return builder},eq(field,value){if(field==='cache_key')key=value;return builder},async single(){return {data:{base_url:'https://test/',user_agent:'MAREA',enabled:true},error:null}},async maybeSingle(){
  const snapshot=cache.get(key);reads++;
  if(delayRead&&reads===3){reached();await gate;}
  return {data:snapshot===undefined?null:{payload:snapshot},error:null};
 },async upsert(value){cache.set(value.cache_key,value.payload);return {error:null}}};return builder}};
 const source=stripTypeScriptTypes(readFileSync(new URL('./index.ts',import.meta.url),'utf8').replace(/^import .*;\n/gm,''));
 class FakeDate extends Date {static now(){return now-wallOffset;}}
 vm.runInNewContext(source,{Deno:{env:{get:()=> 'present'},serve:h=>handler=h},createClient:()=>client,normalizePlace:x=>x,fetch:async()=>{starts.push(now);now+=fetchDuration;if(fetchFails){fetchFails=false;throw new Error('offline');}return new Response(JSON.stringify({display_name:'X',lat:'1',lon:'1',address:{city:'X'}}))},Response,URL,AbortSignal,crypto,setTimeout:(callback,delay)=>{now+=delay;queueMicrotask(callback);},Date:FakeDate,performance:{now:()=>now},JSON});
 return {call:(latitude=1)=>handler(new Request('https://test/',{method:'POST',body:JSON.stringify({mode:'reverse',latitude,longitude:1})})),setNow:value=>now=value,setWallOffset:value=>wallOffset=value,blocked,release:()=>release(),starts,lease:()=>leaseId};
}

test('worker delayed beyond lease expiry cannot fetch after a replacement worker',async()=>{
 const f=harness({delayRead:true});const old=f.call();await f.blocked;
 f.setNow(31000);assert.equal((await f.call(2)).status,200);
 f.setNow(31300);f.release();assert.equal((await old).status,429);
 assert.deepEqual(f.starts,[31000]);
});
test('near-expiring lease keeps the full upstream timeout plus safety budget',async()=>{
 const f=harness({delayRead:true});const old=f.call();await f.blocked;
 f.setNow(21500);f.release();assert.equal((await old).status,429);assert.deepEqual(f.starts,[]);
});
test('claim RPC latency is counted from before the claim, not its delayed result',async()=>{
 const f=harness({delayClaim:true});assert.equal((await f.call()).status,429);assert.deepEqual(f.starts,[]);
});
test('failed upstream and failed finish cannot release a lease or overlap replacement requests',async()=>{
 const f=harness({finishFails:true,fetchFails:true});assert.equal((await f.call()).status,503);assert.ok(f.lease());
 f.setNow(500);assert.equal((await f.call(2)).status,429);assert.deepEqual(f.starts,[0]);
 f.setNow(31000);assert.equal((await f.call(2)).status,200);assert.deepEqual(f.starts,[0,31000]);assert.ok(f.lease());
});

test('latest permitted upstream start plus failed finish leaves replacement safely spaced',async()=>{
 const f=harness({delayRead:true,finishFails:true,fetchDuration:8000});const old=f.call();await f.blocked;
 f.setNow(19500);f.release();assert.equal((await old).status,200);assert.ok(f.lease());
 f.setNow(31000);assert.equal((await f.call(2)).status,200);
 assert.deepEqual(f.starts,[19500,31000]);assert.ok(f.starts[1]-f.starts[0]>=1000);
});

test('elapsed lease budget uses a monotonic clock when the wall clock moves backward',async()=>{
 const f=harness({delayRead:true});const old=f.call();await f.blocked;
 f.setNow(31300);f.setWallOffset(30000);f.release();
 assert.equal((await old).status,429);assert.deepEqual(f.starts,[]);
});
