// Isolated PostgreSQL/WASM fixtures only. Never contacts a hosted Supabase.
import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
const { PGlite } = await import(process.env.MAREA_PGLITE_MODULE || '@electric-sql/pglite');
const db = new PGlite();
const owner = '11111111-1111-4111-8111-111111111111';
const visitor = '22222222-2222-4222-8222-222222222222';
const scene = '44444444-4444-4444-8444-444444444444';
const zone = '55555555-5555-4555-8555-555555555555';
const markerId = '66666666-6666-4666-8666-666666666666';
const imageVersion = '77777777-7777-4777-8777-777777777777';
let assertions = 0;
const eq = (actual, expected, label) => { assert.deepEqual(actual, expected, label); assertions++; };
const scalar = async (sql, params = []) => Object.values((await db.query(sql, params)).rows[0])[0];
const rejects = async (sql, params = [], pattern = undefined) => {
  await assert.rejects(db.query(sql, params), pattern); assertions++;
};
const login = async (id) => {
  await db.exec('reset role; set role authenticated');
  await db.query("select set_config('request.jwt.claim.sub', $1, false)", [id]);
};
const system = () => db.exec('reset role');
const migrate = async (file) => db.exec(await readFile(new URL(`../supabase/migrations/${file}.sql`, import.meta.url), 'utf8'));
try {
  // Same minimal Supabase fixture used by check_tours_database; real tour/marker
  // functions and policies below are loaded from migrations, not reimplemented.
  await db.exec(`
    create role anon; create role authenticated; create role service_role bypassrls;
    create schema auth; create schema storage;
    grant usage on schema public,auth,storage to anon,authenticated,service_role;
    create function auth.uid() returns uuid language sql stable as $$
      select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
    create table public.profiles(id uuid primary key,role text default 'user');
    create table public.account_deletion_requests(user_id uuid primary key references public.profiles(id));
    create table public.profile_media_operations(id uuid,user_id uuid,expires_at timestamptz);
    create function public.community_is_admin() returns boolean language sql security definer as $$
      select exists(select 1 from public.profiles where id=auth.uid() and role='admin') $$;
    create function public.community_active_account() returns uuid language plpgsql security definer as $$ begin
      if auth.uid() is null or not exists(select 1 from public.profiles where id=auth.uid())
        or exists(select 1 from public.account_deletion_requests where user_id=auth.uid())
        then raise exception 'account_required'; end if; return auth.uid(); end $$;
    revoke all on function public.community_active_account() from public,anon,authenticated;
    create table public.posts(id uuid primary key,author_id uuid,title text,kind text,hidden boolean default false);
    create table public.missions(id uuid primary key,author_id uuid,title text,hidden boolean default false);
    create table public.showcase_items(id uuid primary key,owner_id uuid,title text,status text,hidden boolean default false,available boolean default true);
    create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
    create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text,name text,metadata jsonb,unique(bucket_id,name));
    alter table storage.objects enable row level security;
    grant select,insert,update,delete on storage.objects to authenticated;
    grant select on storage.objects to anon;
    create function storage.foldername(name text) returns text[] language sql immutable as $$ select string_to_array(name,'/') $$;
    insert into public.profiles(id) values('${owner}'),('${visitor}');
  `);
  for (const file of ['015_tours', '041_ar_markers', '042_tour_horizontal_panoramas',
    '20261118100001_direct_tour_publication', '20261118100002_direct_marker_publication',
    '20261119062601_direct_sphere_import']) await migrate(file);
  for (const legacy of [false, true]) {
    await login(owner);
    const draft = await scalar('select tours_save(null,$1,$2,$3)', ['Foto 360°', { name: 'Mi casa' }, { zones: [], ar_order: [] }]);
    const { id: capture } = await scalar("select tours_capture_begin($1,$2,'import')", [draft.id, scene]);
    const args = [owner, capture, imageVersion];
    const target = 'select tours_sphere_import_target($1,$2,$3)';
    const finish = 'select tours_sphere_import_finish($1,$2,$3,$4,4096,2048)';
    const source = `${owner}/${capture}/${imageVersion}.jpg`;
    const panorama = `${owner}/imports/${capture}/${imageVersion}.jpg`;
    await db.query("insert into storage.objects(bucket_id,name,metadata) values('tour-inputs',$1,$2)", [source, { size: 250000, mimetype: 'image/jpeg' }]);
    let queued;
    if (legacy) queued = await scalar('select tours_capture_submit($1,$2)', [capture, {
      mode: 'import', frames: [{ id: imageVersion, path: source, width: 4096, height: 2048, yaw: 0, pitch: 0, roll: 0, hfov: 360, vfov: 180 }],
    }]);
    await rejects(target, args, /permission denied/);
    await rejects(finish, [...args, markerId], /permission denied/);
    await system();
    await db.query("insert into public.profile_media_operations values($1,$2,now()+interval '10 minutes')", [capture, owner]);
    await db.exec('set role service_role');
    await rejects(target, [visitor, capture, imageVersion], /capture_owner_required/);
    eq((await scalar(target, args)).source_path, source, 'service receives the server-derived original path');
    await rejects(finish, [...args, markerId], /media_operation_unavailable/);
    await rejects(finish, [...args, capture], /import_file_required/);
    await system();
    await db.query("insert into storage.objects(bucket_id,name) values('tour-assets',$1)", [panorama]);
    await db.exec('set role service_role');
    const ready = await scalar(finish, [...args, capture]);
    eq(ready.state, 'ready', 'only a validated import becomes ready without a queued job');
    eq(ready.attempts, 0, 'no processing attempt was required');
    eq(ready.result.panorama_path, panorama, 'validated JPEG is a normal viewer asset');
    if (legacy) eq(ready.id, queued.id, 'an already queued import keeps the same job ID');
    eq((await scalar(finish, [...args, capture])).id, ready.id, 'finalizing a second time reuses the same job');
    await rejects(target, [owner, capture, markerId], /capture_immutable/);
    await login(visitor);
    eq(await scalar("select count(*)::int from storage.objects where bucket_id='tour-assets' and name=$1", [panorama]), 0, 'viewer JPEG stays private in a draft');
    await login(owner);
    await scalar('select tours_attach_result($1,$2,$3)', [draft.id, scene, ready.id]);
    await scalar('select tours_publish($1)', [draft.id]);
    await login(visitor);
    eq(await scalar("select count(*)::int from storage.objects where bucket_id='tour-assets' and name=$1", [panorama]), 1, 'visitor sees the JPEG only after publication');
    eq(await scalar("select count(*)::int from storage.objects where bucket_id='tour-inputs' and name=$1", [source]), 0, 'visitor never sees the original upload');
  }
  await login(owner);
  let tour = await scalar('select tours_save(null,$1,$2,$3)', ['Mi recorrido', { name: 'Mi casa' }, { zones: [], ar_order: [] }]);
  await rejects('select tours_publish($1)', [tour.id], /tour_incomplete/);
  // Ready media fixture: only the trusted worker can create this state in real use.
  await system();
  const cap = await scalar(`insert into private.tour_captures(tour_id,owner_id,scene_id,mode)
    values($1,$2,$3,'import') returning id`, [tour.id, owner, scene]);
  const job = await scalar(`insert into private.tour_jobs(capture_id,owner_id,state)
    values($1,$2,'succeeded') returning id`, [cap, owner]);
  const result = Object.fromEntries(['panorama', 'preview', 'thumbnail'].map(key => [`${key}_path`, `${owner}/jobs/${job}/${key}.jpg`]));
  await db.query('update private.tour_jobs set result=$1 where id=$2', [result, job]);
  for (const path of Object.values(result)) await db.query("insert into storage.objects(bucket_id,name) values('tour-assets',$1)", [path]);
  const doc = { zones: [{ id: zone, name: 'Recorrido', scenes: [{ id: scene, name: 'Principal', job_id: job, ...result, points: [], connections: [] }] }], ar_order: [], start_scene_id: scene };
  await login(owner);
  tour = await scalar('select tours_save($1,$2,$3,$4)', [tour.id, 'Mi recorrido', { name: 'Mi casa' }, doc]);
  const published = await scalar('select tours_publish($1)', [tour.id]);
  eq(published.state, 'published', 'non-admin publishes without evidence/context');
  eq(published.public_revision_id, published.revision_id, 'current revision is public');
  eq((await scalar('select tours_submit($1)', [tour.id])).revision_id, published.revision_id, 'old submit API and response retries are idempotent');
  eq((await scalar('select tours_requests()')).length, 0, 'no administrative review request');
  await login(visitor);
  eq((await scalar('select tours_get($1)', [tour.id])).title, 'Mi recorrido', 'another user sees publication immediately');
  await rejects('select tours_publish($1)', [tour.id], /tour_owner_required/);
  await rejects('select tours_save($1,$2,$3,$4)', [null, 'Media ajena', { name: 'Casa' }, doc], /invalid_scene_job/);
  await login(owner);
  await db.query('select tours_pause($1,true)', [tour.id]);
  await db.query('select tours_publish($1)', [tour.id]);
  eq((await scalar('select tours_get($1,true)', [tour.id])).paused, true, 'publishing retry does not remove pause');
  await db.query('select tours_pause($1,false)', [tour.id]);
  // Legacy submissions migrate on user action, without mutating frozen snapshots.
  await system();
  await db.query("update public.tours set state='submitted' where id=$1", [tour.id]);
  await db.query(`insert into public.tour_requests(tour_id,revision_id,requester_id,kind)
    values($1,$2,$3,'publication')`, [tour.id, published.revision_id, owner]);
  await login(owner);
  const resumed = await scalar('select tours_publish($1)', [tour.id]);
  eq(resumed.state, 'published', 'legacy pending submission publishes directly');
  assert.notEqual(resumed.revision_id, published.revision_id); assertions++;
  eq((await scalar('select tours_requests()'))[0].status, 'superseded', 'old pending approval is closed');
  await system();
  eq(await scalar('select count(*)::int from public.tour_revisions where tour_id=$1', [tour.id]), 2, 'old revision remains intact');
  await db.query("insert into public.posts(id,author_id,title,kind) values($1,$2,'Otro local','space')", [zone, visitor]);
  await login(owner);
  await scalar('select tours_save($1,$2,$3,$4)', [tour.id, 'Mi recorrido', { id: zone, name: 'Otro local' }, doc]);
  await rejects('select tours_publish($1)', [tour.id], /space_permission_required/);
  await login(visitor);
  eq((await scalar('select tours_get($1)', [tour.id])).title, 'Mi recorrido', 'failed publication keeps previous public version');
  // Legacy space-owner consent is sufficient; no administrator is needed.
  await system();
  await db.query(`insert into public.tour_revisions(id,tour_id,owner_id,title,space,document)
    select revision_id,id,owner_id,title,space,private.tour_public_document(document)
    from public.tours where id=$1`, [tour.id]);
  const consent = await scalar(`insert into public.tour_requests(tour_id,revision_id,requester_id,reviewer_id,kind,payload)
    select id,revision_id,owner_id,$2,'space',space from public.tours where id=$1 returning id`, [tour.id, visitor]);
  const duplicateConsent = await scalar(`insert into public.tour_requests(tour_id,revision_id,requester_id,reviewer_id,kind,payload)
    select id,revision_id,owner_id,$2,'space',space from public.tours where id=$1 returning id`, [tour.id, visitor]);
  await login(visitor);
  await db.query('select tours_review($1,true,\'Permiso del autor\')', [consent]);
  await db.query('select tours_review($1,true,\'Permiso actualizado del autor\')', [duplicateConsent]);
  await login(owner);
  eq((await scalar('select tours_publish($1)', [tour.id])).state, 'published', 'space author consent needs no subsequent admin approval');
  await scalar('select tours_save($1,$2,$3,$4)', [tour.id, 'Mi recorrido', { id: zone, name: 'Otro local', latitude: 19, longitude: -103 }, doc]);
  await rejects('select tours_publish($1)', [tour.id], /space_permission_required/);
  await login(visitor);
  await db.query('select tours_permission_revoke($1)', [duplicateConsent]);
  await login(owner);
  await scalar('select tours_save($1,$2,$3,$4)', [tour.id, 'Mi recorrido', { id: zone, name: 'Otro local' }, doc]);
  await rejects('select tours_publish($1)', [tour.id], /space_permission_required/);
  await rejects('select tours_pause($1,false)', [tour.id], /space_permission_required/);

  const path = `${owner}/${markerId}/${imageVersion}.jpg`;
  await system();
  await db.query("insert into storage.objects(bucket_id,name) values('ar-marker-images',$1)", [path]);
  const insertMarker = `insert into public.ar_markers(id,owner_id,name,width_cm,reference_path)
    values($1,$2,'Mi menú',20,$3) returning to_jsonb(ar_markers.*)`;
  const markerArgs = [markerId, owner, path];
  await login(owner);
  await rejects(insertMarker, markerArgs, /permission denied for function community_active_account/);
  await system();
  await migrate('20261119072912_fix_marker_owner_write_policy');
  await login(visitor);
  await rejects(insertMarker, markerArgs, /row-level security/);
  await login(owner);
  await rejects('select public.community_active_account()', [], /permission denied/);
  let marker = await scalar(insertMarker, markerArgs);
  eq(marker.published, false, 'untested upload remains private');
  await rejects('select ar_markers_set_publication($1,$2,true,false)', [markerId, marker.reference_version], /marker_recognition_required/);
  await rejects(`update public.ar_markers set published=true where id=$1`, [markerId], /permission denied/);
  await login(visitor);
  eq(await scalar('select count(*)::int from public.ar_markers'), 0, 'another account cannot see the untested image');
  await rejects('select ar_markers_confirm_recognition($1,$2,\'android\',3)', [markerId, marker.reference_version], /marker_owner_required/);
  await login(owner);
  await rejects('select ar_markers_confirm_recognition($1,$2,\'android\',2)', [markerId, marker.reference_version], /marker_recognition_required/);
  marker = await scalar('select ar_markers_confirm_recognition($1,$2,\'android\',3)', [markerId, marker.reference_version]);
  eq(marker.published, true, 'saving real recognition publishes directly');
  eq(marker.active, false, 'public marker does not require GPS or enable notifications');
  await login(visitor);
  eq(await scalar('select count(*)::int from public.ar_markers'), 1, 'public marker visible to visitor');
  eq(await scalar("select count(*)::int from storage.objects where bucket_id='ar-marker-images'"), 1, 'public reference image readable');
  await rejects('select ar_markers_set_publication($1,$2,false,false)', [markerId, marker.reference_version], /marker_owner_required/);
  await db.exec('reset role; set role anon');
  eq(await scalar('select count(*)::int from public.ar_markers'), 1, 'anonymous public marker policy works');
  eq(await scalar("select count(*)::int from storage.objects where bucket_id='ar-marker-images'"), 1, 'anonymous visitor can read published reference');
  await rejects('select tours_publish($1)', [tour.id], /permission denied/);
  await rejects('select ar_markers_set_publication($1,$2,true,false)', [markerId, marker.reference_version], /permission denied/);
  await login(owner);
  eq(await scalar("update public.ar_markers set description='Nuevo menú' where id=$1 returning published", [markerId]), true, 'text edits remain public without review');
  await rejects('select ar_markers_set_publication($1,$2,true,true)', [markerId, marker.reference_version], /marker_precise_location_required/);
  await db.query('update public.ar_markers set latitude=19,longitude=-103,location_exact=true,location_accuracy=5 where id=$1', [markerId]);
  marker = await scalar('select ar_markers_set_publication($1,$2,true,true)', [markerId, marker.reference_version]);
  eq(marker.active, true, 'tested public marker can enable precise proximity notification');
  await rejects('select ar_markers_set_publication($1,$2,true,false)', [markerId, imageVersion], /marker_reference_changed/);
  marker = await scalar('update public.ar_markers set width_cm=21 where id=$1 returning to_jsonb(ar_markers.*)', [markerId]);
  eq([marker.published, marker.active, marker.tested_version], [false, false, null], 'changing physical reference revokes old publication and proof');
  await login(visitor);
  eq(await scalar('select count(*)::int from public.ar_markers'), 0, 'obsolete reference is no longer public');
  console.log(`${assertions} direct-publication assertions passed in isolated PostgreSQL. Hosted Supabase not contacted.`);
} finally {
  await db.close();
}
