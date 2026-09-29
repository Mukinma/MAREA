// Real PostgreSQL policies/RPCs in an isolated database; never touches hosted accounts.
import {readFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
const {PGlite} = await import(process.env.MAREA_PGLITE_MODULE || '@electric-sql/pglite');
const db = new PGlite(); let checks = 0;
const eq = (actual, expected, label) => { assert.deepEqual(actual, expected, label); checks++; };
const reject = async (sql, label) => { await assert.rejects(db.exec(sql), undefined, label); checks++; };
const scalar = async (sql) => Object.values((await db.query(sql)).rows[0])[0];
const ids = ['11111111-1111-4111-8111-111111111111','22222222-2222-4222-8222-222222222222','33333333-3333-4333-8333-333333333333','44444444-4444-4444-8444-444444444444','55555555-5555-4555-8555-555555555555'];
const login = async (id) => db.exec(`reset role; set role authenticated; select set_config('request.jwt.claim.sub','${id}',false)`);
const system = async () => db.exec("reset role; select set_config('request.jwt.claim.sub','',false)");
const complete = (type) => `select public.complete_initial_profile('${type}',array['arte'],array['colaborar'])`;
const payload = (kind, extra={}) => JSON.stringify({kind,title:'Mi ficha',body:'Descripción de la ficha',category:'arte',status:'published',available:true,image_paths:[],...extra});
const save = (kind, extra={}, id=null) => `select public.save_showcase('${payload(kind,extra).replaceAll("'","''")}'::jsonb,${id ? `'${id}'::uuid` : 'null'})`;
try {
await db.exec(`create role anon; create role authenticated; create role service_role bypassrls;
create schema auth; create schema storage; grant usage on schema public,auth,storage to anon,authenticated,service_role;
create table auth.users(id uuid primary key,raw_user_meta_data jsonb not null default '{}');
create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text,name text);
alter table storage.objects enable row level security; grant select,insert,update,delete on storage.objects to authenticated;
create function storage.foldername(name text) returns text[] language sql immutable as $$ select string_to_array(name,'/') $$;`);
await db.exec(await readFile(new URL('../supabase/migrations/001_initial_schema.sql',import.meta.url),'utf8'));
for (const [i,id] of ids.entries()) await db.query('insert into auth.users values($1,$2)',[id,{full_name:`Persona ${i}`,username:`persona${i}`}]);
await db.exec(`update public.profiles set user_type='Artista / creador' where id='${ids[0]}'`);
for (const name of ['002_account_completion','003_community','004_post_locations','005_mission_lifecycle']) await db.exec(await readFile(new URL(`../supabase/migrations/${name}.sql`,import.meta.url),'utf8'));
await db.exec(`insert into public.posts(author_id,kind,title,body,category) values('${ids[0]}','project','Proyecto histórico','Un proyecto anterior','arte')`);
try { await db.exec(await readFile(new URL('../supabase/migrations/006_profile_experience.sql',import.meta.url),'utf8')); } catch(e) { if(e.code!=='ENOENT') throw e; }

try { await db.exec(await readFile(new URL('../supabase/migrations/007_minimal_registration.sql',import.meta.url),'utf8')); } catch(e) { if(e.code!=='ENOENT') throw e; }
await login(ids[0]);
await db.exec("select public.complete_initial_profile('Artista / creador','{}','{}')");
eq(await scalar('select interests from public.profiles'),[],'preferences optional at initial confirmation');
await db.exec("update public.profiles set interests=array['musica'],goals=array['colaborar'],setup_step=1");
eq(await scalar('select setup_step from public.profiles'),1,'guide progress persists');
await reject("update public.profiles set user_type='Negocio'",'confirmed type cannot change');
await reject("update public.profiles set initial_profile_completed_at=null",'confirmation timestamp protected');
await reject("update public.profiles set interests=array['unknown']",'unknown preferences rejected');
await reject("update public.profiles set setup_step=4",'guide progress bounded by type');
eq(await scalar('select count(*)::int from public.posts'),1,'historical content preserved');
await system();
await db.exec(`insert into public.legal_documents values ('terms','v1','Test terms',repeat('Tests only. ',15),now()),('privacy','v1','Test privacy',repeat('Tests only. ',15),now()); update public.registration_settings set terms_version='v1',privacy_version='v1',signup_enabled=true,support_email='test@example.com';`);
const metadata={full_name:'Marca',username:'test',registration_flow:'minimal-v1',terms_version:'v1',privacy_version:'v1',accepted_terms:true,adult_confirmed:true,role:'admin'};
for(const [i,type] of ['Usuario general','Artista / creador','Emprendedor','Negocio'].entries()) {
 const id=`aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa${i}`;
 await db.query('insert into auth.users values($1,$2)',[id,{...metadata,username:`marca${i}`,user_type:type}]);
 const profile=(await db.query('select user_type,role,interests,initial_profile_completed_at from public.profiles where id=$1',[id])).rows[0];
 eq(profile.user_type,type,'typed signup preserved'); eq(profile.role,'user','signup cannot grant admin'); eq(profile.interests,[],'no invented preferences'); eq(profile.initial_profile_completed_at!==null,true,'ready without forced guide');
 await login(id); await reject("select public.complete_initial_profile('Negocio','{}','{}')",'signup type confirmed exactly once');
 await db.exec("insert into public.posts(kind,title,body,category) values('community','Hola','Mi primera publicación','arte')");
 await system();
}
await assert.rejects(db.query('insert into auth.users values($1,$2)',['bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',{...metadata,user_type:'admin'}])); checks++;
await assert.rejects(db.query('insert into auth.users values($1,$2)',['bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',{...metadata,user_type:'Negocio',adult_confirmed:false}])); checks++;
await db.query('insert into auth.users values($1,$2)',['bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',{...metadata,registration_flow:undefined,username:'legacy'}]);
eq(await scalar("select initial_profile_completed_at from public.profiles where username='legacy'"),null,'legacy signup needs explicit type confirmation');
await login(ids[0]);
await db.exec(`update public.profiles set setup_step=2 where id='${ids[1]}'`);
await system(); eq(await scalar(`select setup_step from public.profiles where id='${ids[1]}'`),0,'other account progress protected by RLS');
await login(ids[0]);
const publicProfile=(await db.query(`select * from public.community_profiles(array['${ids[0]}'::uuid])`)).rows[0];
for(const key of ['interests','goals','setup_step','role']) eq(key in publicProfile,false,'private guide data excluded from directory');
console.log(`${checks} access checks passed (isolated PostgreSQL; hosted Supabase not contacted).`);
} finally {await db.close();}
