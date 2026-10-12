// Location metadata verification against the real community migrations. Never contacts hosted Supabase.
import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
const { PGlite } = await import(process.env.MAREA_PGLITE_MODULE || '@electric-sql/pglite');
const db = new PGlite();
let assertions = 0;
const check = (actual, expected, label) => { assert.deepEqual(actual, expected, label); assertions++; };
const rejects = async (sql, label) => { await assert.rejects(db.exec(sql), undefined, label); assertions++; };
const scalar = async (sql) => Object.values((await db.query(sql)).rows[0])[0];
const a='11111111-1111-4111-8111-111111111111', b='22222222-2222-4222-8222-222222222222', c='33333333-3333-4333-8333-333333333333', admin='44444444-4444-4444-8444-444444444444';
const login = async (id) => db.exec(`reset role; set role authenticated; select set_config('request.jwt.claim.sub','${id}',false);`);
const system = async () => db.exec(`reset role; select set_config('request.jwt.claim.sub','',false);`);
const post = (kind='community', extra='') => `insert into public.posts(kind,title,body,category,location${extra ? ',image_path' : ''}) values('${kind}','Una publicación','Una descripción','arte',${['space','event'].includes(kind) ? "'Ciudad de México'" : 'null'}${extra ? `,'${extra}'` : ''}) returning id`;
const mission = (target='null', capacity=1) => `insert into public.missions(title,body,category,location,starts_at,capacity,target_type) values('Una misión','Colaboración local','arte','Ciudad de México',now()+interval '2 days',${capacity},${target}) returning id`;
try {
await db.exec(`
  create role anon; create role authenticated; create role service_role bypassrls;
  create schema auth; create schema storage;
  grant usage on schema public,auth,storage to anon,authenticated,service_role;
  create table auth.users(id uuid primary key,raw_user_meta_data jsonb not null default '{}');
  create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
  create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
  create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text,name text,created_at timestamptz default now());
  alter table storage.objects enable row level security;
  grant select,insert,update,delete on storage.objects to authenticated;
  create function storage.foldername(name text) returns text[] language sql immutable as $$ select string_to_array(name,'/') $$;
`);
await db.exec(await readFile(new URL('../supabase/migrations/001_initial_schema.sql',import.meta.url),'utf8'));
for (const [id,name] of [[a,'ana'],[b,'beto'],[c,'cora'],[admin,'moderador']]) {
  await db.query('insert into auth.users(id,raw_user_meta_data) values($1,$2)',[id,{full_name:name,username:name,role:'admin'}]);
}
await db.exec(await readFile(new URL('../supabase/migrations/002_account_completion.sql',import.meta.url),'utf8'));
await db.exec(await readFile(new URL('../supabase/migrations/003_community.sql',import.meta.url),'utf8'));
await db.exec(await readFile(new URL('../supabase/migrations/004_post_locations.sql',import.meta.url),'utf8'));
await db.exec(`update public.profiles set role='admin' where id='${admin}';`);
// Fixtures accepted by old migrations must be upgraded without losing text.
const legacyPost=await scalar(`insert into public.posts(author_id,kind,title,body,category,location,location_latitude) values('${a}','community','Legacy location','Texto','arte','Centro',19) returning id`);
const legacyMission=await scalar(`insert into public.missions(author_id,title,body,category,location,starts_at,capacity) values('${a}','Legacy mission','Texto','arte','CDMX',now()+interval '2 days',3) returning id`);
await db.exec(`insert into public.mission_applications(mission_id,applicant_id,message) values('${legacyMission}','${b}','Antes de migración')`);
try { await db.exec(await readFile(new URL('../supabase/migrations/005_mission_lifecycle.sql',import.meta.url),'utf8')); } catch (e) { if (e.code !== 'ENOENT') throw e; }


for (const name of ['006_profile_experience','007_minimal_registration','008_recover_minimal_registration','009_post_reactions','010_post_comments','011_post_collaboration','012_mission_map','013_missions_redesign','014_android_push','015_tours']) await db.exec(await readFile(new URL(`../supabase/migrations/${name}.sql`,import.meta.url),'utf8'));

await db.exec(`update public.profiles set initial_profile_completed_at=now()`);
await login(a);
await system();
for(const name of ['016_home_feed','018_story_publication_retries','019_story_receipt_upgrade','020_mission_social','021_content_cities']) await db.exec(await readFile(new URL(`../supabase/migrations/${name}.sql`,import.meta.url),'utf8'));
await login(a);
const rpc = async (name,args) => Object.values((await db.query(`select public.${name}(${args.map((_,i)=>'$'+(i+1)).join(',')})`,args)).rows[0])[0];
const city={name:'Puebla',region:'Puebla',country:'México',countryCode:'mx'};
const input={title:'Misión con ciudad',body:'Colaboración local',category:'arte',location:'Calle Uno, Puebla',starts_at:new Date(Date.now()+86400000).toISOString(),capacity:2,compensation_type:'negotiable',compensation_amount_cents:null,location_latitude:19,location_longitude:-98,location_precision:'exact',location_city:city};
const m=await rpc('create_mission',[input]);
check(await scalar(`select location_city from public.missions where id='${m}'`),city,'create mission preserves structured city');
check(await scalar(`select location from public.missions where id='${m}'`),'Calle Uno, Puebla','full address retained');
const listed=await rpc('list_missions',[null,'',null,null,'all',0,m]);
check(listed.location_city,city,'list missions includes city metadata');
await rpc('update_mission',[m,{title:'Título nuevo'}]);
check(await scalar(`select location_city from public.missions where id='${m}'`),city,'unrelated mission edits retain city');
await login(b);
await rejects(`select public.update_mission('${m}','{"location_city":{"name":"Forged"}}')`,'foreign mission metadata protected');
await login(a);
const draft='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
await rpc('save_mission_draft',[draft,{location_city:city,title:'Borrador'}]);
check(await scalar(`select data->'location_city' from public.mission_drafts where id='${draft}'`),city,'draft restores city');
const published=await rpc('publish_mission_draft',[draft,input]);
check(await scalar(`select location_city from public.missions where id='${published}'`),city,'publish mission draft persists city');
await rejects(`select public.create_mission_before_city('{}')`,'internal function not callable by clients');
const p=await scalar(`insert into public.posts(kind,title,body,category,location,location_latitude,location_longitude,location_precision,location_city) values('community','Evento local','Texto','arte','Calle Uno',19,-98,'exact','{"name":"Puebla"}') returning id`);
check(await scalar(`select location_city->>'name' from public.posts where id='${p}'`),'Puebla','post column grants permit city persistence');
await db.exec(`update public.posts set location_latitude=20,location_city='{"name":"Morelia","point":{"latitude":20,"longitude":-98}}' where id='${p}'`);
check(await scalar(`select location_city->>'name' from public.posts where id='${p}'`),'Morelia','moving a post preserves freshly supplied city');
await db.exec(`update public.posts set location_latitude=21 where id='${p}'`);
check(await scalar(`select location_city from public.posts where id='${p}'`),null,'moving without a new city invalidates old metadata');
await rejects(`update public.posts set location_city_resolved_at=now() where id='${p}'`,'clients cannot forge server resolution markers');
await system();await db.exec(`update public.posts set hidden=true where id='${p}'`);
await login(b);check(await scalar(`select count(*)::int from public.posts where id='${p}'`),0,'RLS hides moderated content from unrelated readers');
console.log(`Location full migration checks passed (${assertions} assertions)`);
} finally { await db.close(); }
