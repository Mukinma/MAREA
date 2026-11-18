import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const { PGlite } = await import(process.env.MAREA_PGLITE_MODULE || '@electric-sql/pglite');
const db = new PGlite();
const owner = '11111111-1111-4111-8111-111111111111';
const reporter = '22222222-2222-4222-8222-222222222222';
const admin = '33333333-3333-4333-8333-333333333333';
const migrate = async (name) => db.exec(await readFile(
  new URL(`../supabase/migrations/${name}.sql`, import.meta.url),
  'utf8',
));
const asUser = (id) => db.exec(
  `reset role; set role authenticated; select set_config('request.jwt.claim.sub', '${id}', false)`,
);
const asSystem = () => db.exec("reset role; select set_config('request.jwt.claim.sub', '', false)");
const scalar = async (sql) => Object.values((await db.query(sql)).rows[0])[0];
const receipts = async (column) => (await db.query(
  `select ${column} from public.report_receipts order by kind`,
)).rows;

try {
  await db.exec(`
    create role anon; create role authenticated; create role service_role bypassrls;
    create schema auth; create schema storage; create schema private;
    grant usage on schema public, auth, storage to anon, authenticated, service_role;
    create table auth.users (id uuid primary key, raw_user_meta_data jsonb not null default '{}');
    create function auth.uid() returns uuid language sql stable as $$
      select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
    $$;
    create table storage.buckets (
      id text primary key, name text, public boolean, file_size_limit bigint, allowed_mime_types text[]
    );
    create table storage.objects (
      id uuid primary key default gen_random_uuid(), bucket_id text, name text,
      created_at timestamptz default now()
    );
    alter table storage.objects enable row level security;
    grant select, insert, update, delete on storage.objects to authenticated;
    create function storage.foldername(name text) returns text[] language sql immutable as $$
      select string_to_array(name, '/')
    $$;
  `);
  await migrate('001_initial_schema');
  for (const [id, username] of [[owner, 'owner'], [reporter, 'reporter'], [admin, 'moderator']]) {
    await db.query('insert into auth.users(id, raw_user_meta_data) values($1, $2)', [
      id, { full_name: username, username },
    ]);
  }
  for (const migration of [
    '002_account_completion', '003_community', '004_post_locations',
    '005_mission_lifecycle', '006_profile_experience',
  ]) await migrate(migration);
  await db.exec(`
    update public.profiles set initial_profile_completed_at = now();
    update public.profiles set role = 'admin' where id = '${admin}';
  `);
  const post = await scalar(`insert into public.posts(author_id, kind, title, body, category)
    values('${owner}', 'community', 'Publicación', 'Contenido', 'arte') returning id`);
  await asUser(reporter);
  await db.exec(`insert into public.content_reports(post_id, reason) values('${post}', 'Una razón válida')`);
  await asSystem();

  await migrate('20261118072730_settings_reports');
  await asUser(reporter);
  assert.deepEqual(await receipts('kind, state'), [{ kind: 'post', state: 'open' }]);
  const accountReport = await scalar(`select public.report_profile('${owner}', 'Una cuenta abusiva')`);
  assert.equal(await scalar(`select public.report_profile('${owner}', 'Un reintento')`), accountReport);
  await assert.rejects(db.exec(`select public.report_profile('${reporter}', 'Reporte propio')`), /invalid_account_report/);
  await assert.rejects(db.exec(`select public.mark_report_reviewed('${accountReport}', true)`), /moderation_denied/);
  assert.equal(await scalar('select count(*)::int from public.profile_reports'), 0);
  await asUser(owner);
  assert.deepEqual(await receipts('kind, state'), []);

  await asUser(admin);
  assert.equal(await scalar('select count(*)::int from public.profile_reports'), 1);
  assert.deepEqual(await receipts('kind, state'), []);
  await db.exec(`select public.mark_report_reviewed('${accountReport}', true)`);
  await asSystem();
  await db.exec(`delete from public.posts where id = '${post}'`);
  await asUser(reporter);
  assert.deepEqual(await receipts('kind, state, target_unavailable'), [
    { kind: 'account', state: 'resolved', target_unavailable: false },
    { kind: 'post', state: 'open', target_unavailable: true },
  ]);
  await asSystem();
  await db.exec(`delete from auth.users where id = '${reporter}'`);
  assert.equal(await scalar('select count(*)::int from public.report_receipts'), 0);
  console.log('Settings report receipts, moderation, and RLS passed.');
} finally {
  await db.close();
}
