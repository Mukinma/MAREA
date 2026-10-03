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
  create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text,name text);
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


for (const name of ['006_profile_experience','007_minimal_registration','008_recover_minimal_registration','009_post_reactions','010_post_comments','011_post_collaboration','012_mission_map','013_missions_redesign']) await db.exec(await readFile(new URL(`../supabase/migrations/${name}.sql`,import.meta.url),'utf8'));

await db.exec(`update public.profiles set initial_profile_completed_at=now()`);
await login(a);
const input={title:'Misión nueva',body:'Colaboración',category:'arte',location:'CDMX',starts_at:new Date(Date.now()+86400000).toISOString(),capacity:2,compensation_type:'paid',compensation_amount_cents:12345};
const rpc = async (name,args) => Object.values((await db.query(`select public.${name}(${args.map((_,i)=>'$'+(i+1)).join(',')})`,args)).rows[0])[0];
const row = async id => (await db.query('select * from public.missions where id=$1',[id])).rows[0];
const rejectsCall = async (name,args,label) => {await assert.rejects(rpc(name,args),undefined,label); assertions++;};

const composerDraft='a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0';
const composerPayload={title:'',body:'',category:'otros',target_type:null,capacity:101,capacity_text:'101',requirements:'',conditions:'',location:'',starts_at:null,starts_date:'2026-10-01T00:00:00.000',starts_hour:23,starts_minute:59,image_path:null,location_latitude:null,location_longitude:null,location_precision:null,compensation_type:'paid',compensation_amount_cents:0,compensation_amount_text:'0.'};
check(await rpc('save_mission_draft',[composerDraft,composerPayload]),composerDraft,'real composer payload numeric time and incomplete form saved');
check(await scalar(`select data from public.mission_drafts where id='${composerDraft}'`),composerPayload,'all raw and canonical composer values restored verbatim');
await rpc('save_mission_draft',[composerDraft,{...composerPayload,starts_hour:null,starts_minute:null,starts_date:null}]);
for(const patch of [{title:123},{title:'x'.repeat(101)},{body:'x'.repeat(3001)},{location:'x'.repeat(181)},{requirements:'x'.repeat(3001)},{conditions:'x'.repeat(3001)},{category:'bogus'},{target_type:'bogus'},{location_precision:'bogus'},{compensation_type:'bogus'},{capacity:'5'},{capacity:1.5},{capacity:2147483648},{compensation_amount_cents:1.5},{compensation_amount_cents:10000000000},{starts_hour:'23'},{starts_hour:24},{starts_hour:-1},{starts_hour:12.5},{starts_minute:60},{starts_minute:-1},{starts_minute:'0'},{starts_date:0},{starts_date:'2026-02-31'},{starts_date:'2026-10-01T10:00:00.000'},{starts_at:'invalid date'},{starts_at:'infinity'},{location_latitude:91},{location_longitude:-181},{location_latitude:'19.4'},{image_path:{}},{capacity_text:5},{compensation_amount_text:'x'.repeat(101)}]) {
 await rejectsCall('save_mission_draft',[composerDraft,{...composerPayload,...patch}],'malformed or oversized canonical draft rejected');
}
await rpc('delete_mission_draft',[composerDraft]);

const draft='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
check(await rpc('save_mission_draft',[draft,{title:'Idea'}]),draft,'incomplete draft saved');
check(await scalar('select count(*)::int from public.mission_drafts'),1,'owner reads drafts');
await login(b);
check(await scalar('select count(*)::int from public.mission_drafts'),0,'draft private');
await rejectsCall('save_mission_draft',[draft,{title:'Robada'}],'foreign draft protected');
await rejectsCall('publish_mission_draft',[draft,input],'foreign publication protected');
await login(a);
const m=await rpc('publish_mission_draft',[draft,input]);
check(await rpc('publish_mission_draft',[draft,input]),m,'publication retry returns same mission');
await rejectsCall('delete_mission_draft',[draft],'published draft retry journal cannot be deleted');
check((await row(m)).compensation_amount_cents,12345,'compensation persisted');
await rejectsCall('save_mission_draft',[draft,{title:'Cambio'}],'published draft frozen');
for(const patch of [{compensation_type:'paid',compensation_amount_cents:0},{compensation_type:'paid',compensation_amount_cents:9999999901},{compensation_type:'unpaid',compensation_amount_cents:5},{compensation_type:'other'}]) await rejectsCall('create_mission',[{...input,...patch}],'invalid compensation rejected');
const legacy=await rpc('create_mission',[{...input,compensation_type:null,compensation_amount_cents:null}]);
check((await row(legacy)).compensation_type,null,'legacy compensation remains null');
await login(b);
await rpc('set_mission_saved',[m,true]); await rpc('set_mission_saved',[m,true]);
check(await scalar('select count(*)::int from public.mission_saves'),1,'save retry idempotent');
await login(a); check(await scalar('select count(*)::int from public.mission_saves'),0,'save private');
await login(b);
const op='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const appInput={message:'Quiero colaborar',availability_confirmed:true,evidence:[{title:'Mi enlace',url:'https://example.com/work'}],operation_id:op};
const app=await rpc('submit_mission_application',[m,appInput]);
check(await rpc('submit_mission_application',[m,appInput]),app,'submission retry returns same application');
await rejectsCall('submit_mission_application',[m,{...appInput,message:'Changed'}],'operation payload immutable');
check(await scalar(`select availability_confirmed from public.mission_applications where id='${app}'`),true,'availability persisted');
check(await scalar(`select jsonb_array_length(evidence) from public.mission_applications where id='${app}'`),1,'evidence persisted');
await login(c); check(await scalar(`select count(*)::int from public.mission_applications where id='${app}'`),0,'application private');
for(const patch of [{availability_confirmed:false},{evidence:[{title:'Bad',url:'http://example.com'}]},{evidence:[{title:'Both',url:'https://example.com',showcase_id:op}]},{evidence:[1,2,3,4]}]) await rejectsCall('submit_mission_application',[m,{...appInput,...patch,operation_id:'cccccccc-cccc-4ccc-8ccc-cccccccccccc'}],'invalid application rejected');

for(const sample of [{title:123,url:'https://example.com'},{title:{text:'Bad'},url:'https://example.com'},{title:'Bad',url:'https://user:password@example.com'},{title:'Bad',url:'https://example.com/'+'a'.repeat(2000)},{title:'Bad',url:'https://example.com',showcase_id:23}]) await rejectsCall('submit_mission_application',[m,{...appInput,evidence:[sample],operation_id:'c0c0c0c0-c0c0-40c0-80c0-c0c0c0c0c0c0'}],'evidence JSON types and URL agree with Dart model');
await rejectsCall('submit_mission_application',[m,{...appInput,message:123,evidence:[],operation_id:'c0c0c0c0-c0c0-40c0-80c0-c0c0c0c0c0c0'}],'structured message must be a JSON string');

const appC=await rpc('submit_mission_application',[m,{...appInput,operation_id:'cccccccc-cccc-4ccc-8ccc-cccccccccccc',evidence:[]}]);
await login(a);
check(await scalar(`select count(*)::int from public.notifications where kind='mission_application' and mission_id='${m}'`),2,'one notification per real submission');
await rpc('update_mission',[m,{title:'Texto editable'}]);
check((await row(m)).compensation_amount_cents,12345,'missing compensation fields preserve locked compensation');
await rejectsCall('update_mission',[m,{compensation_type:null,compensation_amount_cents:null}],'explicit null cannot erase locked compensation');
await rejectsCall('update_mission',[m,{compensation_type:'unpaid',compensation_amount_cents:null}],'compensation locked');
await rpc('set_mission_finalist',[m,app,true]); await rpc('set_mission_finalist',[m,app,true]);
check(await scalar('select count(*)::int from public.mission_finalists'),1,'finalist idempotent');
check(await scalar(`select status from public.mission_applications where id='${app}'`),'pending','finalist preserves public state');
await login(b); check(await scalar('select count(*)::int from public.mission_finalists'),0,'finalists owner only');
await rejectsCall('confirm_mission_selection',[m,[app]],'participant cannot select');
await login(a); await rpc('confirm_mission_selection',[m,[app,appC]]); await rpc('confirm_mission_selection',[m,[app,appC]]);
check(await scalar(`select count(*)::int from public.mission_applications where mission_id='${m}' and status='accepted'`),2,'bulk selection accepted');
check((await row(m)).status,'open','selection keeps mission open');
await login(b); check(await scalar(`select count(*)::int from public.notifications where kind='mission_accepted'`),1,'selection retry deduplicates notification');
await rpc('withdraw_application',[app]);
check(await rpc('submit_mission_application',[m,appInput]),app,'old submission retry does not reapply withdrawal');
check(await scalar(`select status from public.mission_applications where id='${app}'`),'withdrawn','old retry preserves withdrawn');
const reapplied=await rpc('submit_mission_application',[m,{...appInput,operation_id:'dddddddd-dddd-4ddd-8ddd-dddddddddddd'}]); check(reapplied,app,'new operation reapplies withdrawn row');
await login(a);
check(await scalar(`select count(*)::int from public.notifications where kind='mission_application' and source_id='${app}'`),2,'reapply emits separate real event');
check(await scalar(`select count(*)::int from public.notifications where kind='mission_withdrawn'`),1,'withdraw notifies owner');
await rpc('set_mission_status',[m,'closed',null]); await rpc('set_mission_status',[m,'closed',null]);
await login(b); check(await scalar(`select count(*)::int from public.notifications where kind='mission_closed'`),1,'close retry deduplicated');
await login(a); await rpc('set_mission_status',[m,'open',null]); await rpc('set_mission_status',[m,'closed',null]);
await login(b); check(await scalar(`select count(*)::int from public.notifications where kind='mission_closed'`),2,'second lifecycle transition emits event');
// Selection must rollback all rows when the group exceeds remaining capacity.
await login(a); const one=await rpc('create_mission',[{...input,capacity:1}]);
await login(b); const oneB=await rpc('apply_to_mission',[one,'Legacy compatible']);
await login(c); const oneC=await rpc('apply_to_mission',[one,'Legacy compatible']);
await login(a); await rejectsCall('confirm_mission_selection',[one,[oneB,oneC]],'over capacity group rejected atomically');
check(await scalar(`select count(*)::int from public.mission_applications where mission_id='${one}' and status='accepted'`),0,'failed group did not partially accept');
await rpc('confirm_mission_selection',[one,[oneB]]); await rejectsCall('confirm_mission_selection',[one,[oneC]],'subsequent selection respects occupied capacity');
// Own published visible showcase only; references survive removal for the UI's unavailable state.
await system(); const showcase=await scalar(`insert into public.showcase_items(owner_id,kind,title,body,category,status,available) values('${b}','project','Obra','Descripción','arte','published',true) returning id`);
await login(b); const evidenceMission=legacy;
const showcaseApp=await rpc('submit_mission_application',[evidenceMission,{...appInput,evidence:[{title:'Obra',showcase_id:showcase}],operation_id:'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'}]);
await login(c); await rejectsCall('submit_mission_application',[evidenceMission,{...appInput,evidence:[{title:'Ajena',showcase_id:showcase}],operation_id:'ffffffff-ffff-4fff-8fff-ffffffffffff'}],'foreign showcase denied');
await system(); await db.exec(`update public.showcase_items set hidden=true where id='${showcase}'`);
await login(b); check(await scalar(`select jsonb_array_length(evidence) from public.mission_applications where id='${showcaseApp}'`),1,'hidden showcase preserves reference history');


// Completion notices target accepted and pending participants after the mission starts.
await login(a); const completing=await rpc('create_mission',[input]);
await login(b); const completingApp=await rpc('apply_to_mission',[completing,'Colaboraré']);
await login(a); await rpc('review_application',[completingApp,'accepted']);
await system();
// Move the fixture clock without waiting or changing application eligibility logic.
await db.exec(`alter table public.missions disable trigger validate_mission_lifecycle; update public.missions set starts_at=now()-interval '1 hour' where id='${completing}'; alter table public.missions enable trigger validate_mission_lifecycle`);
await login(a); await rpc('set_mission_status',[completing,'completed',null]); await rpc('set_mission_status',[completing,'completed',null]);
await login(b); check(await scalar(`select count(*)::int from public.notifications where mission_id='${completing}' and kind='mission_completed'`),1,'completion retry deduplicated');
// Owner-only finalist writes, forbidden direct mutations, hidden/deleting references.
await login(c); await rejectsCall('set_mission_finalist',[m,app,true],'non-owner finalist writes rejected');
for (const table of ['mission_drafts','mission_saves','mission_finalists','mission_application_operations']) {
 await rejects(`delete from public.${table}`,'direct new table mutation denied');
}
await login(a); await rpc('set_mission_finalist',[m,app,true]);
check(await scalar(`select count(*)::int from public.notifications where kind='mission_withdrawn'`),1,'finalist writes add no participant events');
await rpc('review_application',[app,'rejected']); await rpc('review_application',[app,'rejected']);
check(await scalar(`select count(*)::int from public.mission_finalists where application_id='${app}'`),0,'rejected candidate removed from finalists');
await login(b); check(await scalar(`select count(*)::int from public.notifications where kind='mission_rejected'`),1,'review retry produces one notification');
await rejectsCall('submit_mission_application',[legacy,{...appInput,evidence:[{title:'Hidden',showcase_id:showcase}],operation_id:'fefefefe-fefe-4efe-8efe-fefefefefefe'}],'hidden showcase cannot be attached');
await login(a); await rejectsCall('create_mission',[{...input,compensation_amount_cents:1.5}],'fractional cents rejected');
await rejectsCall('create_mission',[{...input,compensation_type:null,compensation_amount_cents:5}],'null type with cents rejected');
await rejectsCall('save_mission_draft',['acacacac-acac-4cac-8cac-acacacacacac',{capacity_text:'x'.repeat(101)}],'oversize raw draft fields rejected');
const partial='adadadad-adad-4dad-8dad-adadadadadad';
await rpc('save_mission_draft',[partial,{starts_date:'',starts_hour:2,starts_minute:null,capacity_text:'',compensation_amount_text:'12.'}]);
check(await scalar(`select data->>'compensation_amount_text' from public.mission_drafts where id='${partial}'`),'12.','partial numeric text preserved');
await rejectsCall('publish_mission_draft',[partial,{...input,capacity_text:'2'}],'raw draft-only keys rejected at publication');
await rpc('set_mission_status',[m,'cancelled','Cambio de planes']); await rpc('set_mission_status',[m,'cancelled','Cambio de planes']);
await login(c); check(await scalar(`select count(*)::int from public.notifications where kind='mission_cancelled'`),1,'cancel notifies active candidate only once');
await login(b); check(await scalar(`select count(*)::int from public.notifications where kind='mission_cancelled'`),0,'rejected candidate omitted from cancellation');
// Saved filtering happens before pagination, retaining historical visible missions.
check((await db.query('select * from public.list_saved_missions()')).rows.length,1,'saved list includes cancelled mission');
await rpc('set_mission_saved',[legacy,true]);
check((await db.query("select * from public.list_saved_missions(query_text=>'impossible')")).rows.length,0,'saved search filters server-side');
await login(a);
check((await db.query('select * from public.list_saved_missions()')).rows.length,0,'saved listing private');
const paged=[];
for(let i=0;i<32;i++) paged.push(await rpc('create_mission',[{...input,title:`Guardada ${i}`,category:i<2?'musica':'arte'}]));
await login(b); for(const id of paged) await rpc('set_mission_saved',[id,true]);
check((await db.query("select * from public.list_saved_missions(query_text=>'Guardada',category_filter=>'musica')")).rows.length,2,'saved category filter before page');
check((await db.query("select * from public.list_saved_missions(query_text=>'Guardada',page_offset=>30)")).rows.length,2,'saved pagination');
await login(admin); await db.exec(`select public.moderate_content('${paged[0]}','mission',true)`);
await login(b); check((await db.query("select * from public.list_saved_missions(query_text=>'Guardada',category_filter=>'musica')")).rows.length,1,'hidden saved mission omitted');
await rpc('set_mission_saved',[m,false]); check(await scalar(`select count(*)::int from public.mission_saves where mission_id='${m}'`),0,'unsave remains possible for historical mission');
await system();
await db.exec(`create schema supabase_migrations;create table supabase_migrations.schema_migrations(version text primary key);insert into supabase_migrations.schema_migrations select lpad(i::text,3,'0') from generate_series(1,13) i`);
const gate=(await db.query(await readFile(new URL('./backend_contract.sql',import.meta.url),'utf8'))).rows[0];
for(const key of ['migrations_ready','mission_tables_ready','mission_permissions_ready','mission_functions_ready','mission_notifications_ready']) check(gate[key],true,`real SQL gate ${key}`);

await login(a); const draftImage=`${a}/55555555-5555-4555-8555-555555555555.png`;
await db.query("insert into storage.objects(bucket_id,name) values('mission-images',$1)",[draftImage]);
const photoDraft='abababab-abab-4bab-8bab-abababababab'; await rpc('save_mission_draft',[photoDraft,{image_path:draftImage}]);
await db.query("delete from storage.objects where name=$1",[draftImage]); check(await scalar(`select count(*)::int from storage.objects where name='${draftImage}'`),1,'draft image cannot be deleted');
await login(c); check(await scalar(`select count(*)::int from storage.objects where name='${draftImage}'`),0,'draft image private');
await login(a); await rpc('delete_mission_draft',[photoDraft]); await db.query('delete from storage.objects where name=$1',[draftImage]); check(await scalar(`select count(*)::int from storage.objects where name='${draftImage}'`),0,'deleted draft releases image');

// Published journals preserve retry metadata, but only live missions retain covers.
await db.query("insert into storage.objects(bucket_id,name) values('mission-images',$1)",[draftImage]);
const coveredDraft='a1a1a1a1-a1a1-41a1-81a1-a1a1a1a1a1a1';
await rpc('save_mission_draft',[coveredDraft,{image_path:draftImage}]);
const coveredMission=await rpc('publish_mission_draft',[coveredDraft,{...input,image_path:draftImage}]);
await login(admin); await rpc('moderate_content',[coveredMission,'mission',true]);
await login(c); check(await scalar(`select count(*)::int from storage.objects where name='${draftImage}'`),0,'moderated published cover remains private');
await login(a); await rpc('update_mission',[coveredMission,{image_path:null}]);
await db.query('delete from storage.objects where name=$1',[draftImage]);
check(await scalar(`select count(*)::int from storage.objects where name='${draftImage}'`),0,'published draft journal does not pin a replaced cover');
await db.query("insert into storage.objects(bucket_id,name) values('mission-images',$1)",[draftImage]);
const deletedDraft='a2a2a2a2-a2a2-42a2-82a2-a2a2a2a2a2a2';
await rpc('save_mission_draft',[deletedDraft,{image_path:draftImage}]);
const deletedMission=await rpc('publish_mission_draft',[deletedDraft,{...input,image_path:draftImage}]);
await db.query('delete from public.missions where id=$1',[deletedMission]);
await db.query('delete from storage.objects where name=$1',[draftImage]);
check(await scalar(`select count(*)::int from storage.objects where name='${draftImage}'`),0,'deleted mission cover released despite publication journal');
check(await scalar(`select published_at is not null and published_mission_id is null from public.mission_drafts where id='${deletedDraft}'`),true,'deleted mission preserves retry tombstone');
await rejectsCall('publish_mission_draft',[deletedDraft,input],'deleted mission cannot be resurrected by publish retry');

for (const signature of ['save_mission_draft(uuid,jsonb)','publish_mission_draft(uuid,jsonb)','delete_mission_draft(uuid)','submit_mission_application(uuid,jsonb)','set_mission_saved(uuid,boolean)','set_mission_finalist(uuid,uuid,boolean)','confirm_mission_selection(uuid,uuid[])','list_saved_missions(text,text,text,integer)']) {
 check(await scalar(`select has_function_privilege('authenticated','public.${signature}','EXECUTE')`),true,`${signature} authenticated`);
 check(await scalar(`select has_function_privilege('anon','public.${signature}','EXECUTE')`),false,`${signature} anonymous denied`);
}
await system(); await db.exec(`delete from auth.users where id='${a}'`);
check(await scalar('select count(*)::int from public.mission_drafts'),0,'deletion cascades drafts');
check(await scalar('select count(*)::int from public.mission_finalists'),0,'deletion cascades finalists');
check(await scalar('select count(*)::int from public.mission_saves'),0,'deletion cascades saves');
check(await scalar('select count(*)::int from public.mission_application_operations'),0,'account deletion cascades operation journals');
console.log(`Missions redesign database verified: ${assertions} assertions.`);
} finally { await db.close(); }
