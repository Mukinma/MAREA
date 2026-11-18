// Isolated PostgreSQL verification. Never contacts hosted MAREA.
import assert from 'node:assert/strict';
import { readFile, readdir } from 'node:fs/promises';

const { PGlite } = await import(process.env.MAREA_PGLITE_MODULE || '@electric-sql/pglite');
const db = new PGlite();
const migrations = new URL('../supabase/migrations/', import.meta.url);
const ana = '11111111-1111-4111-8111-111111111111';
const beto = '22222222-2222-4222-8222-222222222222';
const cora = '33333333-3333-4333-8333-333333333333';

async function scalar(sql, args = []) {
  return Object.values((await db.query(sql, args)).rows[0])[0];
}

async function rpc(name, ...args) {
  const parameters = args.map((_, index) => '$' + (index + 1)).join(',');
  return scalar('select public.' + name + '(' + parameters + ')', args);
}

async function login(id) {
  await db.exec('reset role; set role authenticated');
  await db.query("select set_config('request.jwt.claim.sub', $1, false)", [id]);
}

try {
  await db.exec(`
    create role anon; create role authenticated; create role service_role bypassrls;
    create schema auth; create schema storage;
    grant usage on schema public,auth,storage to anon,authenticated,service_role;
    create table auth.users(id uuid primary key,raw_user_meta_data jsonb not null default '{}');
    create function auth.uid() returns uuid language sql stable
      as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
    create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
    create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text,name text,created_at timestamptz default now());
    alter table storage.objects enable row level security;
    grant select,insert,update,delete on storage.objects to authenticated;
    create function storage.foldername(name text) returns text[] language sql immutable
      as $$ select string_to_array(name,'/') $$;
  `);
  const history = (await readdir(migrations)).filter((name) =>
    /^0(0[1-9]|1[0-6]|2[2-9]|3[0-3])_.*\.sql$/.test(name),
  ).sort();
  for (const name of history) {
    await db.exec(await readFile(new URL(name, migrations), 'utf8'));
    if (name === '001_initial_schema.sql') {
      for (const [id, username] of [[ana, 'ana'], [beto, 'beto'], [cora, 'cora']]) {
        await db.query('insert into auth.users values ($1,$2)', [id, {full_name: username, username}]);
      }
    }
  }
  await db.exec('update public.profiles set initial_profile_completed_at = now()');

  // Existing requests and blocks must survive the upgrade.
  await login(ana);
  const existing = await rpc('request_chat', beto);
  await rpc('set_chat_block', cora, true);
  await db.exec('reset role');
  await db.exec(await readFile(new URL('20261118000003_chat_privacy.sql', migrations), 'utf8'));
  await login(ana);
  assert.deepEqual(await rpc('get_chat_privacy'), {
    request_audience: 'everyone',
    blocked_accounts: [{id: cora, full_name: 'cora', username: 'cora'}],
  });
  await assert.rejects(rpc('set_chat_request_audience', 'invalid'), /invalid_chat_request_audience/);
  await assert.rejects(db.exec('select * from public.chat_request_preferences'), /permission denied/);
  await assert.rejects(db.exec('select * from public.chat_blocks'), /permission denied/);

  await login(beto);
  assert.deepEqual(await rpc('get_chat_privacy'), {
    request_audience: 'everyone',
    blocked_accounts: [],
  });
  await rpc('set_chat_request_audience', 'nobody');
  await rpc('accept_chat', existing);
  await login(ana);
  assert.equal(await rpc('request_chat', beto), existing);
  assert.ok(await rpc('send_chat_message', existing, 'Hola'));

  await login(cora);
  await assert.rejects(rpc('request_chat', beto), /chat_request_not_allowed/);
  await assert.rejects(rpc('request_chat', ana), /chat_blocked/);
  await rpc('set_profile_follow', beto, true);
  await login(beto);
  await rpc('set_chat_request_audience', 'following');
  await login(cora);
  await assert.rejects(rpc('request_chat', beto), /chat_request_not_allowed/);
  await login(beto);
  await rpc('set_profile_follow', cora, true);
  await login(cora);
  const pending = await rpc('request_chat', beto);
  await login(beto);
  // Reversing a request must return the same conversation and create no second notification.
  assert.equal(await rpc('request_chat', cora), pending);
  await rpc('set_chat_block', cora, true);
  await rpc('set_chat_block', ana, true);
  await assert.rejects(rpc('accept_chat', pending), /chat_blocked/);
  await assert.rejects(rpc('send_chat_message', existing, 'Hola'), /chat_blocked/);
  await assert.rejects(rpc('request_chat', cora), /chat_blocked/);
  assert.equal(await scalar('select status from public.chat_conversations where id=$1', [pending]), 'pending');
  await login(cora);
  assert.deepEqual((await rpc('get_chat_privacy')).blocked_accounts, []);
  await assert.rejects(rpc('request_chat', beto), /chat_blocked/);
  await login(ana);
  await assert.rejects(rpc('send_chat_message', existing, 'Hola'), /chat_blocked/);
  await login(beto);
  await rpc('set_chat_block', cora, false);
  await rpc('set_chat_block', cora, false);
  await rpc('accept_chat', pending);
  assert.deepEqual((await rpc('get_chat_privacy')).blocked_accounts.map((row) => row.id), [ana]);

  await db.exec('reset role; set role anon');
  await assert.rejects(rpc('get_chat_privacy'), /permission denied/);
  await assert.rejects(rpc('set_chat_request_audience', 'everyone'), /permission denied/);
  console.log('Chat privacy database checks passed.');
} finally {
  await db.close();
}
