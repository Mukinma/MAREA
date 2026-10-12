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
const rpc = async (name,args=[]) => Object.values((await db.query(`select public.${name}(${args.map((_,i)=>'$'+(i+1)).join(',')})`,args)).rows[0])[0];
await login(a);
await assert.rejects(rpc('set_profile_follow',[a,true]),/follow/); assertions++;
await rpc('set_profile_follow',[b,true]); await rpc('set_profile_follow',[b,true]);
check(await scalar('select count(*)::int from public.profile_follows'),1,'follow is idempotent');
await login(b); check(await scalar('select count(*)::int from public.profile_follows'),0,'following relationships are private');
const story='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
await rpc('publish_story',[story,'Mi historia',null]); await rpc('publish_story',[story,'Mi historia',null]);
// Simulate an old in-flight writer that crossed the receipt backfill.
await system();await db.query('delete from public.story_publications where id=$1',[story]);
await login(b);await rpc('publish_story',[story,'Mi historia',null]);
check(await scalar(`select count(*)::int from public.stories where id='${story}'`),1,'publication retries do not duplicate stories');
await assert.rejects(rpc('publish_story',[story,'Changed',null]),/conflict/); assertions++;
check(await scalar(`select expires_at-created_at=interval '24 hours' from public.stories where id='${story}'`),true,'exact 24-hour expiration');
await login(a);
await rpc('mark_story_seen',[story]); await rpc('mark_story_seen',[story]);
check((await rpc('list_stories')).stories[0].seen,true,'seen state persisted');
await assert.rejects(rpc('delete_story',[story]),/permission/); assertions++;
await assert.rejects(rpc('publish_story',['bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','x'.repeat(501),null]),/invalid/); assertions++;
await rpc('report_story',[story,'Contenido inapropiado']);
await assert.rejects(rpc('moderate_story',[story,true]),/permission/); assertions++;
await login(admin); await rpc('moderate_story',[story,true]);
await login(a); check((await rpc('list_stories')).stories.length,0,'hidden stories disappear');
await login(admin); await rpc('moderate_story',[story,false]);
await system(); await db.exec(`update public.stories set expires_at=now() where id='${story}'`);
await login(a); check((await rpc('list_stories')).stories.length,0,'expired stories disappear');
await assert.rejects(rpc('mark_story_seen',[story]),/unavailable/); assertions++;
await system();
await db.exec('delete from public.posts; delete from public.missions');
for(let i=0;i<35;i++) await db.query(`insert into public.posts(author_id,kind,title,body,category,created_at) values($1,'community',$2,'Texto','arte',now()-interval '1 hour')`,[b,'Post '+i]);
await db.exec('alter table public.missions disable trigger user');
await db.exec(`insert into public.missions(author_id,title,body,category,location,starts_at,capacity,created_at) values('${b}','Misión visible','Texto','arte','CDMX',now()+interval '1 day',1,now()),('${b}','Misión vencida','Texto','arte','CDMX',now()-interval '1 day',1,now())`);
await db.exec('alter table public.missions enable trigger user');
await login(a);
const filters={mode:'forYou',kind:'all',category:null,latitude:null,longitude:null,radius_km:10};
const page=await rpc('home_feed',[filters,null]);
check(page.entries.length,30,'joint pages contain 30 elements');
check(page.entries[0].kind,'mission','missions and posts share chronology');
check(page.entries[0].content.title,'Misión visible','expired missions excluded');
const next=await rpc('home_feed',[filters,page.cursor]);
check(next.entries.length,6,'remaining entries fetched without gaps');
check(new Set([...page.entries,...next.entries].map(e=>e.kind+e.content.id)).size,36,'tied timestamps do not duplicate entries');
check(next.cursor,null,'end of pagination explicit');
const followed=await rpc('home_feed',[{...filters,mode:'following'},null]); check(followed.entries.length,30,'following uses persisted authors');
await rpc('set_profile_follow',[b,false]); check((await rpc('home_feed',[{...filters,mode:'following'},null])).entries.length,0,'unfollowing updates feed');
check((await rpc('home_feed',[{...filters,category:'musica'},null])).entries.length,0,'empty filters do not show unrelated content');
await assert.rejects(rpc('home_feed',[{...filters,mode:'nearby'},null]),/location/); assertions++;

const imageStory='d0d0d0d0-d0d0-40d0-80d0-d0d0d0d0d0d0';
const imagePath=a+'/'+imageStory+'.png';
await db.query("insert into storage.objects(bucket_id,name) values('story-images',$1)",[imagePath]);
await rpc('publish_story',[imageStory,'Foto',imagePath]);
check(await scalar(`select count(*)::int from storage.objects where bucket_id='story-images' and name='${imagePath}'`),1,'live own image readable');
await system(); await db.query('update public.stories set expires_at=now() where id=$1',[imageStory]);
await login(a); check(await scalar(`select count(*)::int from storage.objects where bucket_id='story-images' and name='${imagePath}'`),0,'expired own images cannot be mistaken for orphan uploads');

const top=page.entries.find(e=>e.kind==='post').content.id;
await rpc('set_post_reaction',[top,'like']);
const trending=await rpc('home_feed',[{...filters,mode:'trending'},null]);
check(trending.entries[0].content.id,top,'trends use actual activity');
check(trending.entries.length,1,'trends omit zero-activity content');

// Acceptance today is recent activity even if the application is older.
await system();
const recentMission=await scalar(`insert into public.missions(author_id,title,body,category,location,starts_at,capacity) values('${b}','Aceptación reciente','Texto','arte','CDMX',now()+interval '1 day',1) returning id`);
const oldApplication=await scalar(`insert into public.mission_applications(mission_id,applicant_id,message,created_at) values('${recentMission}','${c}','Colaboraré',now()-interval '8 days') returning id`);
await login(b);await rpc('review_application',[oldApplication,'accepted']);
await login(a);
check((await rpc('home_feed',[{...filters,mode:'trending'},null])).entries.some(e=>e.content.id===recentMission),true,'recent acceptance counts by acceptance time');
await system();await db.query('delete from public.missions where id=$1',[recentMission]);
await login(a);

await login(b);
await assert.rejects(rpc('home_feed',[filters,page.cursor]),/cursor/); assertions++;
await login(a);
await assert.rejects(rpc('home_feed',[{...filters,kind:'post'},page.cursor]),/cursor/); assertions++;
await assert.rejects(db.exec("insert into public.stories(id,author_id,body,expires_at) values(gen_random_uuid(),auth.uid(),'Bypass',now()+interval '1 day')"),/permission/); assertions++;
await assert.rejects(db.exec(`insert into public.profile_follows(follower_id,author_id) values('${a}','${c}')`),/permission/); assertions++;
for(const patch of [{radius_km:100},{mode:'invalid'},{kind:'invalid'},{category:'invalid'},{mode:'nearby',latitude:91,longitude:0},{mode:'nearby',latitude:0,longitude:181}]) {
 await assert.rejects(rpc('home_feed',[{...filters,...patch},null]),/invalid/); assertions++;
}
await system();
const allPosts=(await db.query('select id from public.posts')).rows.map(row=>row.id);
await login(a);for(const id of allPosts)await rpc('set_post_reaction',[id,'like']);
const trendFirst=await rpc('home_feed',[{...filters,mode:'trending'},null]);
check(trendFirst.entries.length,30,'trending uses joint pages');
await system();
const tail=(await db.query('select entries->34 as item from public.home_feed_snapshots where id=$1',[trendFirst.cursor.snapshot])).rows[0].item;
await login(c);await rpc('set_post_reaction',[tail.id,'like']);
await login(a);
const trendNext=await rpc('home_feed',[{...filters,mode:'trending'},trendFirst.cursor]);
check(trendNext.entries.length,5,'trending retains remaining page after score changes');
check(new Set([...trendFirst.entries,...trendNext.entries].map(e=>e.content.id)).size,35,'rank changes never duplicate or skip items');
check((await rpc('home_feed',[{...filters,mode:'trending'},null])).entries[0].content.id,tail.id,'refresh adopts the new ranking');
await system();await db.exec(`update public.posts set hidden=true where id='${top}'`);
await login(a);check((await rpc('home_feed',[filters,page.cursor])).entries.every(e=>e.content.id!==top),true,'snapshot revalidates hidden content');
await system();await db.exec(`update public.posts set location='CDMX',location_latitude=19.4326,location_longitude=-99.1332,location_precision='approximate' where not hidden`);
await login(a);
check((await rpc('home_feed',[{...filters,mode:'nearby',latitude:19.43,longitude:-99.13},null])).entries.length,30,'nearby includes geocoded posts');
check((await rpc('home_feed',[{...filters,mode:'nearby',latitude:0,longitude:0},null])).entries.length,0,'nearby excludes distant posts and ungeocoded missions');
await system();await db.query("update public.profiles set interests=array['musica'] where id=$1",[a]);
await login(a);check((await rpc('home_feed',[filters,null])).entries.length,0,'for you honors stored interests');
check((await rpc('home_feed',[{...filters,category:'arte'},null])).entries.length,30,'an explicit category overrides personalization');
await system();await db.query("update public.profiles set interests='{}' where id=$1",[a]);
await db.query("update public.home_feed_snapshots set expires_at=now() where id=$1",[page.cursor.snapshot]);
await login(a);await assert.rejects(rpc('home_feed',[filters,page.cursor]),/cursor/);assertions++;
await login(b); await rpc('delete_story',[story]);

// The hourly worker removes rows; late publication retries must not resurrect them.
await system();await db.query('delete from public.stories where id=$1',[story]);
await login(b);await rpc('publish_story',[story,'Mi historia',null]);
check((await rpc('list_stories')).stories.some(s=>s.id===story),false,'cleanup does not erase publication idempotency');

await login(admin); check((await db.query('select * from public.reported_stories()')).rows.length,0,'deleted stories no longer require review');
for(const name of ['home_feed(jsonb,jsonb)','publish_story(uuid,text,text)','set_profile_follow(uuid,boolean)']) {
 await system(); check(await scalar(`select has_function_privilege('anon','public.${name}','EXECUTE')`),false,'anonymous RPC denied');
}
console.log(`Home feed database: ${assertions} checks passed`);
} catch(e) { console.error(e.stack, e.query ?? ''); process.exitCode=1; } finally { await db.close(); }
