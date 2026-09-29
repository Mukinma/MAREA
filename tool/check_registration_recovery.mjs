// Exercise the upgrade from the deployed 006 schema in isolated PostgreSQL.
import {readFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
const {PGlite} = await import(process.env.MAREA_PGLITE_MODULE || '@electric-sql/pglite');
const db = new PGlite();
let checks = 0;
const eq = (actual, expected, label) => {assert.deepEqual(actual, expected, label); checks++;};
const migration = async name => db.exec(await readFile(new URL(`../supabase/migrations/${name}.sql`, import.meta.url), 'utf8'));
const types = ['Usuario general', 'Artista / creador', 'Emprendedor', 'Negocio'];
const ids = Array.from({length: 12}, (_, i) => `aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa${i.toString(16)}`);
try {
  await db.exec(`create role anon; create role authenticated; create role service_role bypassrls;
    create schema auth; create schema storage;
    grant usage on schema public,auth,storage to anon,authenticated,service_role;
    create table auth.users(id uuid primary key,raw_user_meta_data jsonb not null default '{}');
    create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
    create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
    create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text,name text);
    alter table storage.objects enable row level security;
    grant select,insert,update,delete on storage.objects to authenticated;
    create function storage.foldername(name text) returns text[] language sql immutable as $$ select string_to_array(name,'/') $$;`);
  await migration('001_initial_schema');
  for (const [i,id] of ids.entries()) {
    await db.query('insert into auth.users values($1,$2)', [id, {
      full_name: `Persona ${i}`, username: `persona${i}`, role: 'admin',
      registration_flow: i === 5 ? undefined : 'minimal-v1',
      user_type: i === 4 ? 'invalid' : i === 9 ? types[0] : i === 10 ? types[2] : i === 11 ? types[1] : types[i % 4],
    }]);
  }
  for (const name of ['002_account_completion','003_community','004_post_locations','005_mission_lifecycle','006_profile_experience']) await migration(name);
  await db.exec(`update public.profiles set bio='Conservar bio',interests=array['arte'],goals=array['colaborar'];
    update public.profiles set user_type='Negocio',initial_profile_completed_at='2026-09-01',onboarding_status='completed' where id='${ids[6]}';
    insert into public.account_deletion_requests(user_id) values('${ids[7]}');
    update public.profiles set user_type='Negocio',location='Ubicación histórica' where id='${ids[8]}';
    update public.profiles set user_type='Artista / creador',contact_url='https://example.com/contacto' where id='${ids[9]}';
    update public.profiles set user_type='Artista / creador',open_to_collaboration=true where id='${ids[10]}';
    update public.profiles set user_type='Negocio',business_hours='{"mon":"09:00-18:00"}' where id='${ids[11]}';
    insert into public.legal_documents values ('terms','v1','Test terms',repeat('Tests only. ',15),now()),('privacy','v1','Test privacy',repeat('Tests only. ',15),now());
    insert into public.legal_acceptances(user_id,terms_version,privacy_version,adult_confirmed) values('${ids[0]}','v1','v1',true);
    insert into public.posts(author_id,kind,title,body,category) values('${ids[0]}','community','Contenido anterior','Conservar texto','arte');`);
  const before = (await db.query('select * from public.profiles order by id')).rows;
  const consentsBefore = (await db.query('select * from public.legal_acceptances')).rows;
  await migration('007_minimal_registration');
  const recovery = await readFile(new URL('../supabase/migrations/008_recover_minimal_registration.sql',import.meta.url),'utf8');
  await db.exec(recovery);
  const after = (await db.query('select * from public.profiles order by id')).rows;
  for (let i = 0; i < 4; i++) {
    eq(after[i].user_type, types[i], 'registered type restored');
    eq(after[i].initial_profile_completed_at !== null, true, 'recovered account confirmed');
    eq(after[i].onboarding_status, 'completed', 'recovered account enters home');
    for (const field of ['full_name','username','bio','role','interests','goals','created_at']) eq(after[i][field],before[i][field],`preserves ${field}`);
  }
  for (let i = 4; i < ids.length; i++) {
    for (const field of Object.keys(before[i])) eq(after[i][field],before[i][field],`ineligible account ${i} unchanged: ${field}`);
  }
  eq((await db.query('select count(*)::int as n from public.posts')).rows[0].n,1,'historical content preserved');
  eq((await db.query('select * from public.legal_acceptances')).rows,consentsBefore,'existing legal acceptance preserved without fabrication');
  await db.exec(recovery);
  eq((await db.query('select * from public.profiles order by id')).rows,after,'recovery is idempotent');
  await db.exec(`set role authenticated; select set_config('request.jwt.claim.sub','${ids[0]}',false)`);
  await assert.rejects(db.exec("select public.complete_initial_profile('Negocio','{}','{}')")); checks++;
  await db.exec("update public.profiles set full_name='Nombre guardado',setup_step=1,interests='{}',goals='{}'");
  eq((await db.query('select setup_step from public.profiles')).rows[0].setup_step,1,'guide can save after recovery');
  await db.exec(`select set_config('request.jwt.claim.sub','${ids[5]}',false)`);
  await db.exec("select public.complete_initial_profile('Artista / creador','{}','{}')");
  eq((await db.query('select user_type from public.profiles')).rows[0].user_type,'Artista / creador','legacy account confirms once with empty preferences');
  await db.exec('reset role; create schema supabase_migrations; create table supabase_migrations.schema_migrations(version text);');
  await db.query("insert into supabase_migrations.schema_migrations select unnest($1::text[])",[['001','002','003','004','005','006','007','008']]);
  const contract = await readFile(new URL('./backend_contract.sql',import.meta.url),'utf8');
  eq(Object.values((await db.query(contract)).rows[0]).every(value=>value===true),true,'release gate accepts complete backend');
  await db.exec('alter table auth.users disable trigger on_auth_user_created');
  eq((await db.query(contract)).rows[0].signup_trigger_ready,false,'release gate rejects disabled signup trigger');
  await db.exec('alter table auth.users enable trigger on_auth_user_created');
  await db.exec('drop trigger on_auth_user_created on auth.users');
  eq((await db.query(contract)).rows[0].signup_trigger_ready,false,'release gate rejects missing signup trigger');
  console.log(`${checks} recovery checks passed (isolated PostgreSQL).`);
} finally {await db.close();}
