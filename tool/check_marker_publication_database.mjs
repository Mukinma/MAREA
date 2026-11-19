import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';

const {PGlite} = await import(process.env.MAREA_PGLITE_MODULE || '@electric-sql/pglite');
const db = new PGlite();
const owner = '11111111-1111-4111-8111-111111111111';
const visitor = '22222222-2222-4222-8222-222222222222';
const admin = '33333333-3333-4333-8333-333333333333';
const id = '44444444-4444-4444-8444-444444444444';
const path = `${owner}/${id}/55555555-5555-4555-8555-555555555555.jpg`;
const query = (sql, args = []) => db.query(sql, args);
const scalar = async (sql, args = []) => Object.values((await query(sql, args)).rows[0])[0];
const actor = async (id) => {
  await db.exec('reset role; set role authenticated');
  await query("select set_config('request.jwt.claim.sub',$1,false)", [id]);
};
const migration = (name) => readFile(new URL(`../supabase/migrations/${name}`, import.meta.url), 'utf8');

try {
  await db.exec(`
    create role anon; create role authenticated;
    create schema auth; create schema storage; create schema private;
    grant usage on schema auth, storage to anon, authenticated;
    create function auth.uid() returns uuid language sql stable as
      $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
    create table public.profiles(id uuid primary key, role text, user_type text);
    create table public.account_deletion_requests(user_id uuid primary key);
    create function public.community_active_account() returns uuid language sql security definer
      set search_path='' as $$select id from public.profiles where id=auth.uid()
        and not exists(select 1 from public.account_deletion_requests where user_id=auth.uid())$$;
    create function public.community_is_admin() returns boolean language sql security definer
      set search_path='' as $$select exists(select 1 from public.profiles where id=auth.uid() and role='admin')$$;
    revoke all on function public.community_active_account(), public.community_is_admin()
      from public, anon, authenticated;
    grant execute on function public.community_is_admin() to authenticated;
    create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
    create table storage.objects(bucket_id text,name text,primary key(bucket_id,name));
    alter table storage.objects enable row level security;
    grant select,insert,delete on storage.objects to authenticated;
    insert into profiles values ('${owner}','user','Negocio'),('${visitor}','user','Usuario general'),('${admin}','admin','Usuario general');
  `);
  await db.exec(await migration('041_ar_markers.sql'));
  await db.exec(await migration('20261119000000_marker_publication.sql'));
  await actor(owner);
  await query("insert into storage.objects values ('ar-marker-images',$1)", [path]);
  await query(`insert into ar_markers (id,owner_id,name,width_cm,reference_path,latitude,longitude,location_exact,location_accuracy)
    values($1,$2,'Mural',25,$3,19,-99,true,20)`, [id, owner, path]);
  const version = await scalar('select reference_version from ar_markers');
  await assert.rejects(query('select ar_marker_submit($1)', [id]));
  await scalar('select ar_markers_confirm_recognition($1,$2,$3,$4)', [id, version, 'android', 3]);
  await query('update ar_markers set location_accuracy=21 where id=$1', [id]);
  await assert.rejects(query('select ar_marker_submit($1)', [id]));
  await query('update ar_markers set location_accuracy=20 where id=$1', [id]);

  await actor(visitor);
  assert.equal(await scalar('select count(*)::int from ar_markers'), 0);
  assert.equal(await scalar('select count(*)::int from storage.objects'), 0);

  await actor(visitor);
  await assert.rejects(query("select ar_marker_submit($1)", [id]));
  await assert.rejects(query("select * from ar_marker_review_queue(0)"));
  await actor(owner);
  const submitted = await scalar('select ar_marker_submit($1)', [id]);
  assert.equal(submitted.active, false);
  assert.equal((await scalar('select ar_marker_submit($1)', [id])).submitted_at, submitted.submitted_at);

  await actor(admin);
  assert.equal(await scalar('select count(*)::int from ar_marker_review_queue(0)'), 1);
  assert.equal(await scalar('select count(*)::int from storage.objects'), 1);
  await actor(owner);
  await assert.rejects(query('select ar_marker_review($1,$2,true,null)', [id, submitted.updated_at]));
  await query("update ar_markers set name='Mural editado' where id=$1", [id]);
  const revised = await scalar('select ar_marker_submit($1)', [id]);
  await actor(admin);
  await assert.rejects(query('select ar_marker_review($1,$2,true,null)', [id, submitted.updated_at]));
  const rejected = await scalar('select ar_marker_review($1,$2,false,$3)', [id, revised.updated_at, 'Verifica el nombre']);
  assert.equal(rejected.review_reason, 'Verifica el nombre');
  assert.equal(rejected.active, false);

  await actor(owner);
  await query("update ar_markers set name='Mural principal' where id=$1", [id]);
  const ready = await scalar('select ar_marker_submit($1)', [id]);
  await actor(admin);
  assert.equal((await scalar('select ar_marker_review($1,$2,true,null)', [id, ready.updated_at])).active, true);
  await actor(visitor);
  assert.equal(await scalar('select name from ar_markers'), 'Mural principal');
  assert.equal(await scalar('select count(*)::int from storage.objects'), 1);
  await actor(owner);
  assert.equal(await scalar('with deleted as (delete from storage.objects where name=$1 returning 1) select count(*)::int from deleted', [path]), 0);
  assert.equal((await scalar('select ar_marker_withdraw($1)', [id])).active, false);
  await actor(visitor);
  assert.equal(await scalar('select count(*)::int from ar_markers'), 0);
  assert.equal(await scalar('select count(*)::int from storage.objects'), 0);
  await db.exec('reset role');
  await query('insert into public.account_deletion_requests values ($1)', [owner]);
  await actor(owner);
  await assert.rejects(query("insert into storage.objects values ('ar-marker-images',$1)", [
    `${owner}/${id}/66666666-6666-4666-8666-666666666666.jpg`,
  ]));
  await assert.rejects(query("update ar_markers set name='New' where id=$1", [id]));
  console.log('Marker publication and storage policy checks passed.');
} finally {
  await db.close();
}
