// Isolated PostgreSQL tests. Never connects to a hosted Supabase project.
import {readFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
const {PGlite} = await import(process.env.MAREA_PGLITE_MODULE || '@electric-sql/pglite');
const db = new PGlite();
let checks = 0;
const eq = (actual, expected) => { assert.deepEqual(actual, expected); checks++; };
const reject = async sql => { await assert.rejects(db.exec(sql)); checks++; };
const ids = ['11111111-1111-4111-8111-111111111111', '22222222-2222-4222-8222-222222222222'];
const migration = name => readFile(new URL(`../supabase/migrations/${name}.sql`, import.meta.url), 'utf8');
const login = id => db.exec(`reset role; set role authenticated; select set_config('request.jwt.claim.sub','${id}',false)`);
const rows = async sql => (await db.query(sql)).rows;
const snapshot = () => rows("select id, to_jsonb(p) - 'wave_colors' as data from public.profiles p order by id");
try {
  await db.exec(`create role anon; create role authenticated; create role service_role bypassrls;
    create schema auth; create schema storage;
    grant usage on schema public,auth,storage to anon,authenticated,service_role;
    create table auth.users(id uuid primary key, raw_user_meta_data jsonb not null default '{}');
    create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
    create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
    create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text,name text);
    alter table storage.objects enable row level security;
    grant select,insert,update,delete on storage.objects to authenticated;
    create function storage.foldername(name text) returns text[] language sql immutable as $$ select string_to_array(name,'/') $$;`);
  await db.exec(await migration('001_initial_schema'));
  for (const [i,id] of ids.entries()) {
    await db.query('insert into auth.users values($1,$2)', [id, {full_name:`Wave test ${i}`,username:`wavetest${i}`}]);
  }
  for (const name of ['002_account_completion','003_community','004_post_locations','005_mission_lifecycle','006_profile_experience','007_minimal_registration']) {
    await db.exec(await migration(name));
  }
  await db.exec(`update public.profiles set interests=array['arte','musica'] where id='${ids[0]}'`);
  const before = await snapshot();
  const policies = await rows("select policyname,roles,cmd,qual,with_check from pg_policies where schemaname='public' and tablename='profiles' order by policyname");
  await login(ids[1]);
  const oldDirectory = (await rows(`select * from public.community_profiles(array['${ids[0]}'::uuid])`))[0];
  await db.exec('reset role');
  await db.exec(await migration('034_profile_wave_colors'));
  eq(await snapshot(), before); // Includes all original timestamps, media, and private fields.
  eq(await rows("select policyname,roles,cmd,qual,with_check from pg_policies where schemaname='public' and tablename='profiles' order by policyname"), policies);
  eq((await rows('select wave_colors from public.profiles')) .map(r => r.wave_colors.map(Number)),
    ids.map(() => [4280923848,4289325541]));
  await login(ids[0]);
  await db.exec(`update public.profiles set wave_colors = array[4279383126,4289449455]::bigint[] where id='${ids[0]}'`);
  eq((await rows('select wave_colors from public.profiles'))[0].wave_colors.map(Number), [4279383126,4289449455]);
  for (const value of ['null', 'array[]::bigint[]', 'array[1,2]::bigint[]', 'array[4279383126,null]::bigint[]', 'array[4279383126,4294967296]::bigint[]', 'array[4279383126,4289449455,4289449455]::bigint[]', 'array[[4279383126,4289449455]]::bigint[]', "'[0:1]={4279383126,4289449455}'::bigint[]"]) {
    await reject(`update public.profiles set wave_colors=${value} where id='${ids[0]}'`);
  }
  await db.exec("reset role; select set_config('request.jwt.claim.sub','',false); set role anon");
  await reject(`select * from public.community_profiles(array['${ids[0]}'::uuid])`);
  await reject(`update public.profiles set wave_colors=array[4279383126,4289449455]::bigint[]`);
  await login(ids[1]);
  eq(await rows(`update public.profiles set wave_colors=array[4289325541,4280923848]::bigint[] where id='${ids[0]}' returning id`), []);
  eq(await rows(`select id from public.profiles where id='${ids[0]}'`), []);
  const directory = (await rows(`select * from public.community_profiles(array['${ids[0]}'::uuid])`))[0];
  eq(directory.wave_colors.map(Number), [4279383126,4289449455]);
  const {wave_colors, ...unchangedDirectory} = directory;
  eq(unchangedDirectory, oldDirectory);
  for (const field of ['role','interests','goals','email','setup_step']) eq(field in directory, false);
  await login(ids[0]); // Fresh owner session reads persisted colors.
  eq((await rows('select wave_colors from public.profiles'))[0].wave_colors.map(Number), [4279383126,4289449455]);
  await db.exec('reset role');
  const after = await snapshot();
  // The owner's explicit color update may update only its normal updated_at trigger.
  for (const item of after) {
    const original = before.find(row => row.id === item.id);
    delete item.data.updated_at; delete original.data.updated_at;
  }
  eq(after, before);
  const beforeInterestsMigration = await snapshot();
  await db.exec(await migration('035_profile_public_interests'));
  eq(await snapshot(), beforeInterestsMigration);
  await login(ids[1]);
  const publicOwner = (await rows(`select * from public.community_profiles(array['${ids[0]}'::uuid])`))[0];
  eq(publicOwner.interests, ['arte','musica']);
  eq(publicOwner.wave_colors.map(Number), [4279383126,4289449455]);
  const publicVisitor = (await rows(`select * from public.community_profiles(array['${ids[1]}'::uuid])`))[0];
  eq(publicVisitor.interests, []);
  for (const field of ['role','goals','email','setup_step']) eq(field in publicOwner, false);
  eq(await rows(`update public.profiles set interests=array['moda'] where id='${ids[0]}' returning id`), []);
  await db.exec("reset role; select set_config('request.jwt.claim.sub','',false); set role anon");
  await reject('select * from public.community_profiles()');
  console.log(`${checks} profile wave checks passed (isolated PostgreSQL; no remote writes).`);
} finally {
  await db.close();
}
