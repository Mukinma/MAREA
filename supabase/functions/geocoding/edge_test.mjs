import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {stripTypeScriptTypes} from 'node:module';
import vm from 'node:vm';
import {normalizePlace} from './geocoding.ts';
const {PGlite}=await import(process.env.MAREA_PGLITE_MODULE || '@electric-sql/pglite');

async function fixture() {
 const db=new PGlite();
 await db.exec(`create role anon;create role authenticated;create role service_role;create table public.posts(id uuid primary key,location_latitude double precision,location_longitude double precision);create table public.missions(like public.posts including all);create table public.mission_drafts(id uuid primary key,data jsonb);create function public.create_mission(mission_input jsonb) returns uuid language sql as $$select null::uuid$$;create function public.update_mission(mission_id uuid,mission_input jsonb) returns void language sql as $$select$$;create function public.save_mission_draft(draft_id uuid,draft_input jsonb) returns uuid language sql as $$select draft_id$$;`);
 await db.exec(readFileSync(new URL('../../migrations/021_content_cities.sql',import.meta.url),'utf8'));
 const updates=[],diagnostics=[];
 const client=(authorized=false)=>({auth:{getUser:async()=>({data:{user:authorized?{id:'user'}:null},error:null})},rpc:async(name,args)=>{try{return {data:(await db.query(`select public.${name}($1) as value`,[args.request_id])).rows[0].value,error:null}}catch(error){return {data:null,error}}},from(table){
  let filters={},patch;
  const builder={select(){return builder},eq(key,value){filters[key]=value;return builder},is(key,value){filters[key]=value;return builder},update(value){patch=value;return builder},async single(){return {data:(await db.query(`select * from public.geocoding_provider`)).rows[0],error:null}},async maybeSingle(){
   if(patch){
    updates.push({table,filters,patch});
    const result=await db.query(`update public.${table} set location_city=$1,location_city_resolved_at=$2 where id=$3 and location_latitude=$4 and location_longitude=$5 and location_city_resolved_at is null returning id`,[patch.location_city,patch.location_city_resolved_at,filters.id,filters.location_latitude,filters.location_longitude]);
    return {data:result.rows[0]??null,error:null};
   }
   if(table==='geocoding_cache')return {data:(await db.query('select payload from public.geocoding_cache where cache_key=$1',[filters.cache_key])).rows[0]??null,error:null};
   // External RLS transport: one visible record, hidden records are unavailable.
   return {data:authorized?(await db.query(`select * from public.${table} where id=$1`,[filters.id])).rows[0]??null:null,error:null};
  },async upsert(value){await db.query('insert into public.geocoding_cache(cache_key,payload) values($1,$2) on conflict(cache_key) do update set payload=excluded.payload',[value.cache_key,value.payload]);return {error:null}},then(resolve,reject){
   updates.push({table,filters,patch});
   return db.query(`update public.${table} set location_city=$1,location_city_resolved_at=$2 where id=$3 and location_latitude=$4 and location_longitude=$5 and location_city_resolved_at is null`,[patch.location_city,patch.location_city_resolved_at,filters.id,filters.location_latitude,filters.location_longitude]).then(()=>resolve({error:null}),reject);
  }};return builder;
 }});
 let handler, fetchImpl=async()=>new Response(JSON.stringify({display_name:'Calle Uno, Puebla',lat:'19',lon:'-98',address:{city:'Puebla'}}),{status:200});
 const source=stripTypeScriptTypes(readFileSync(new URL('./index.ts',import.meta.url),'utf8').replace(/^import .*;\n/gm,''));
 vm.runInNewContext(source,{Deno:{env:{get:key=>({SUPABASE_URL:'https://test.supabase.co',SUPABASE_ANON_KEY:'anon',SUPABASE_SERVICE_ROLE_KEY:'service'})[key]},serve:value=>handler=value},createClient:(_url,key,options)=>client(key==='service'||options?.global?.headers.Authorization==='Bearer valid'),normalizePlace,fetch:(...args)=>fetchImpl(...args),Response,URL,AbortSignal,crypto,setTimeout,Date,performance,JSON,console:{warn:event=>diagnostics.push(JSON.parse(event))}});
 const call=async(body,token)=>handler(new Request('https://test/geocoding',{method:'POST',body:JSON.stringify(body),headers:token?{Authorization:`Bearer ${token}`}:{}}));
 return {db,call,updates,diagnostics,setFetch:value=>fetchImpl=value};
}

test('anonymous picker requests share the database cache and global one-second lease across search/reverse',async()=>{
 const f=await fixture();let calls=0;const starts=[];
 f.setFetch(async(url,options)=>{calls++;starts.push(Date.now());assert.match(options.headers['User-Agent'],/MAREA.*https:\/\//);await new Promise(resolve=>setTimeout(resolve,50));return new Response(JSON.stringify(url.pathname.endsWith('search')?[{display_name:'Puebla',lat:'19',lon:'-98',address:{city:'Puebla'}}]:{display_name:'Calle Uno, Puebla',lat:'19',lon:'-98',address:{city:'Puebla'}}));});
 try {
  const responses=await Promise.all([f.call({mode:'search',query:'Puebla'}),f.call({mode:'reverse',latitude:19,longitude:-98})]);
  assert.deepEqual(responses.map(r=>r.status),[200,200]);assert.equal(calls,2);assert.ok(starts[1]-starts[0]>=1000,'different endpoint requests must respect the shared throttle');
  assert.equal((await f.call({mode:'reverse',latitude:19,longitude:-98})).status,200);assert.equal(calls,2,'cache hit must not contact provider');
 }finally{await f.db.close();}
});
test('content city uses a visible stored point and persists a successful unknown once',async()=>{
 const f=await fixture();const id='00000000-0000-0000-0000-000000000099';let calls=0;
 await f.db.query('insert into public.posts(id,location_latitude,location_longitude) values($1,19,-98)',[id]);
 f.setFetch(async()=>{calls++;return new Response(JSON.stringify({display_name:'Rural road',lat:'19',lon:'-98',address:{road:'Rural road'}}));});
 try{
  const input={mode:'content_city',contentKind:'post',contentId:id,latitude:19,longitude:-98};
  assert.equal((await f.call(input)).status,401);
  assert.equal((await f.call(input,'invalid')).status,401);
  assert.equal((await f.call({...input,contentId:'00000000-0000-0000-0000-000000000001'},'valid')).status,404);
  assert.equal((await f.call({...input,latitude:20},'valid')).status,409);assert.equal(calls,0);
  const result=await f.call(input,'valid');assert.equal(result.status,200);assert.deepEqual(await result.json(),{city:null});
  assert.ok((await f.db.query('select location_city_resolved_at from public.posts')).rows[0].location_city_resolved_at);
  assert.equal((await f.call(input,'valid')).status,200);assert.equal(calls,1);assert.equal(f.updates.length,1);
 }finally{await f.db.close();}
});
test('moving content during reverse lookup cannot persist or return the previous points city',async()=>{
 const f=await fixture();const id='00000000-0000-0000-0000-000000000099';
 await f.db.query('insert into public.posts(id,location_latitude,location_longitude) values($1,19,-98)',[id]);
 f.setFetch(async()=>{await f.db.query('update public.posts set location_latitude=20 where id=$1',[id]);return new Response(JSON.stringify({display_name:'Old address',lat:'19',lon:'-98',address:{city:'Old city'}}));});
 try{
  const result=await f.call({mode:'content_city',contentKind:'post',contentId:id,latitude:19,longitude:-98},'valid');
  assert.equal(result.status,409);
  const row=(await f.db.query('select location_city,location_city_resolved_at from public.posts')).rows[0];
  assert.equal(row.location_city,null);assert.equal(row.location_city_resolved_at,null);
 }finally{await f.db.close();}
});
test('distinct nearby content points cannot reuse a rounded provider cache key',async()=>{
 const f=await fixture();let calls=0;
 f.setFetch(async()=>{calls++;return new Response(JSON.stringify({display_name:'Address',lat:'19',lon:'-98',address:{city:calls===1?'Original':'Moved'}}));});
 try{
  assert.equal((await f.call({mode:'reverse',latitude:19,longitude:-98})).status,200);
  const result=await f.call({mode:'reverse',latitude:19.0000001,longitude:-98});
  assert.equal((await result.json()).place.city.name,'Moved');assert.equal(calls,2);
 }finally{await f.db.close();}
});
test('known city persistence records the stored content point rather than the nearby provider object',async()=>{
 const f=await fixture();const id='00000000-0000-0000-0000-000000000099';
 await f.db.query('insert into public.posts(id,location_latitude,location_longitude) values($1,19,-98)',[id]);
 f.setFetch(async()=>new Response(JSON.stringify({display_name:'Nearby address',lat:'19.0001',lon:'-97.9999',address:{city:'Puebla'}})));
 try{
  const result=await f.call({mode:'content_city',contentKind:'post',contentId:id,latitude:19,longitude:-98},'valid');
  assert.equal(result.status,200);assert.deepEqual((await result.json()).city,{name:'Puebla',point:{latitude:19,longitude:-98}});
  assert.deepEqual((await f.db.query('select location_city from public.posts')).rows[0].location_city,{name:'Puebla',point:{latitude:19,longitude:-98}});
 }finally{await f.db.close();}
});

test('provider failures log only safe stage, error name and HTTP status',async()=>{
 const f=await fixture();
 f.setFetch(async()=>new Response('private upstream body',{status:403}));
 try{
  const result=await f.call({mode:'reverse',latitude:19,longitude:-98});assert.equal(result.status,503);
  assert.deepEqual(f.diagnostics[0],{event:'geocoding_failed',stage:'provider_fetch',errorName:'Error',upstreamStatus:403});
 }finally{await f.db.close();}
});
