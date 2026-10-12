// Isolated redesign verification. Never contacts hosted Supabase.
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
await db.exec(await readFile(new URL('../supabase/migrations/016_home_feed.sql',import.meta.url),'utf8'));
await db.exec(await readFile(new URL('../supabase/migrations/018_story_publication_retries.sql',import.meta.url),'utf8'));
await db.exec(await readFile(new URL('../supabase/migrations/019_story_receipt_upgrade.sql',import.meta.url),'utf8'));
try { await db.exec(await readFile(new URL('../supabase/migrations/020_mission_social.sql',import.meta.url),'utf8')); } catch(e) { if(e.code!=='ENOENT') throw e; }
check(await scalar("select to_regclass('public.mission_reactions') is not null"),true,'mission reactions are persisted');
await system();
const m=await scalar(`insert into public.missions(author_id,title,body,category,location,starts_at,capacity) values('${a}','Misión social','Colaboración','arte','CDMX',now()+interval '2 days',3) returning id`);
await login(b);
await db.exec(`select public.set_mission_reaction('${m}','inspire'); select public.set_mission_reaction('${m}','inspire')`);
check(await scalar(`select reaction_count::int from public.mission_social_stats(array['${m}'::uuid])`),1,'reaction retries persist one selection');
await db.exec(`select public.set_mission_reaction('${m}','support')`);
check(await scalar(`select my_reaction from public.mission_social_stats(array['${m}'::uuid])`),'support','change replaces reaction');
check(await scalar(`select count(*)::int from public.mission_social_stats(array['${m}'::uuid,'${legacyMission}'::uuid])`),2,'batch stats include all requested visible missions');
await rejects(`insert into public.mission_reactions(mission_id,user_id,kind) values('${m}','${b}','like')`,'client cannot bypass reaction RPC');
await rejects(`insert into public.mission_comments(mission_id,author_id,body,operation_id) values('${m}','${b}','Forge',gen_random_uuid())`,'client cannot bypass comment RPC');

await rejects(`select public.set_mission_reaction('${m}','invented')`,'reject invalid reaction');
const op='55555555-5555-4555-8555-555555555555';
const comments=await Promise.all([scalar(`select public.create_mission_comment('${m}','Hola misión','${op}')`),scalar(`select public.create_mission_comment('${m}','Hola misión','${op}')`)]);
check(comments[0],comments[1],'concurrent retries return same comment');
const comment=comments[0];
check(await scalar(`select comment_count::int from public.mission_social_stats(array['${m}'::uuid])`),1,'concurrent comments do not duplicate');
await rejects(`select public.create_mission_comment('${m}','Distinto','${op}')`,'operation rejects changed body');
await rejects(`select public.create_mission_comment('${legacyMission}','Hola misión','${op}')`,'operation rejects changed mission');
await rejects(`select public.create_mission_comment('${m}',' ',gen_random_uuid())`,'blank body rejected');
await rejects(`select public.create_mission_comment('${m}',repeat('x',1001),gen_random_uuid())`,'long body rejected');
await login(a);
check(await scalar(`select count(*)::int from public.notifications where mission_id='${m}' and kind in ('reaction','comment')`),2,'backward compatible notification kinds');
check(await scalar(`select source_id::text from public.notifications where mission_id='${m}' and kind='comment'`),comment,'comment notification source');
await login(c);
await rejects(`select public.delete_mission_comment('${comment}')`,'other user cannot delete');
await db.exec(`reset role; select set_config('request.jwt.claim.sub','${a}',false)`);
check(await scalar(`select score::int from public.home_feed_candidates('{"mode":"trending","kind":"mission"}') where id='${m}'`),1,'one distinct actor across reaction and comment');
await login(c);await db.exec(`select public.create_mission_comment('${m}','Otra voz',gen_random_uuid())`);
await db.exec(`reset role; select set_config('request.jwt.claim.sub','${a}',false)`);
check(await scalar(`select score::int from public.home_feed_candidates('{"mode":"trending","kind":"mission"}') where id='${m}'`),2,'different comment author adds one trending actor');
await db.exec(`update public.mission_comments set created_at=now()-interval '8 days' where author_id='${c}'`);
check(await scalar(`select score::int from public.home_feed_candidates('{"mode":"trending","kind":"mission"}') where id='${m}'`),1,'old comments excluded from seven day ranking');
await db.exec(`delete from public.mission_comments where author_id='${c}'`);

await login(a); await db.exec(`select public.delete_mission_comment('${comment}')`);
check(await scalar(`select comment_count::int from public.mission_social_stats(array['${m}'::uuid])`),0,'organizer deletes comment');
await login(b);
check(await scalar(`select public.create_mission_comment('${m}','Hola misión','${op}')`),comment,'retry after moderation returns original operation receipt');
check(await scalar(`select count(*)::int from public.mission_comments where id='${comment}'`),0,'stale retry cannot resurrect removed conversation');

await login(b);
const own=await scalar(`select public.create_mission_comment('${m}','Autor',gen_random_uuid())`);
await db.exec(`select public.delete_mission_comment('${own}')`);
const moderated=await scalar(`select public.create_mission_comment('${m}','Moderación',gen_random_uuid())`);
await login(admin); await db.exec(`select public.delete_mission_comment('${moderated}')`);
await system(); await db.exec(`update public.missions set hidden=true where id='${m}'`);
await login(b);
check(await scalar(`select count(*)::int from public.mission_social_stats(array['${m}'::uuid])`),0,'hidden mission stats unavailable');
check(await scalar(`select count(*)::int from public.mission_reactions where mission_id='${m}'`),0,'hidden mission reactions unreadable');
await rejects(`select public.set_mission_reaction('${m}','like')`,'hidden mission reaction denied');
await rejects(`select public.create_mission_comment('${m}','Oculta',gen_random_uuid())`,'hidden mission comment denied');
await system(); await db.exec(`update public.missions set hidden=false where id='${m}'; insert into public.account_deletion_requests(user_id) values('${a}')`);
await login(b);
await rejects(`select public.set_mission_reaction('${m}','like')`,'deleting organizer cannot receive reactions');
check(await scalar(`select count(*)::int from public.mission_reactions where mission_id='${m}'`),0,'deleting organizer interactions unreadable');
await system();await db.exec(`delete from public.account_deletion_requests where user_id='${a}'; insert into public.account_deletion_requests(user_id) values('${b}')`);
await login(b); await rejects(`select public.create_mission_comment('${m}','Cuenta',gen_random_uuid())`,'deleting account cannot comment');
await login(a);
check(await scalar(`select reaction_count::int from public.mission_social_stats(array['${m}'::uuid])`),0,'deleting reactor excluded from totals');
await system();await db.exec(`delete from public.account_deletion_requests where user_id='${b}'`);
await login(b);await db.exec(`select public.set_mission_reaction('${m}',null)`);
await login(a);check(await scalar(`select count(*)::int from public.notifications where mission_id='${m}'`),0,'removal retracts reaction notification');
await login(b);await db.exec(`select public.create_mission_comment('${m}','Cascada',gen_random_uuid()); select public.set_mission_reaction('${m}','like')`);
await system();await db.exec(`delete from public.missions where id='${m}'`);
check(await scalar('select count(*)::int from public.mission_reactions'),0,'mission deletion cascades reactions');
check(await scalar('select count(*)::int from public.mission_comments'),0,'mission deletion cascades comments');
check(await scalar('select count(*)::int from public.mission_comment_operations'),0,'mission deletion cascades operation receipts');
const accountMission=await scalar(`insert into public.missions(author_id,title,body,category,location,starts_at,capacity) values('${a}','Cuenta social','Colaboración','arte','CDMX',now()+interval '2 days',3) returning id`);
await login(b); await db.exec(`select public.set_mission_reaction('${accountMission}','like'); select public.create_mission_comment('${accountMission}','Mi cuenta',gen_random_uuid())`);
await system();await db.exec(`delete from auth.users where id='${b}'`);
check(await scalar('select count(*)::int from public.mission_reactions'),0,'account deletion cascades reactions');
check(await scalar('select count(*)::int from public.mission_comments'),0,'account deletion cascades comments');
check(await scalar('select count(*)::int from public.mission_comment_operations'),0,'account deletion cascades receipts');

await db.exec('set role anon');await rejects('select * from public.mission_comments','anonymous cannot read');
await rejects(`select public.set_mission_reaction('${accountMission}','like')`,'anonymous cannot react');
await rejects(`select public.create_mission_comment('${accountMission}','Anónimo',gen_random_uuid())`,'anonymous cannot comment');

console.log(`Mission social database: ${assertions} checks passed.`);
} finally { await db.close(); }
