import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {copyFile, lstat, mkdir, mkdtemp, readFile, rm, symlink, writeFile} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {dirname, join, resolve} from 'node:path';
import {test} from 'node:test';
import {fileURLToPath} from 'node:url';
import {makePlan} from '../../tool/ar-live-pilot/plan.mjs';

const now = '2026-11-02T12:00:00.000Z';
const source = fileURLToPath(new URL('../../tool/ar-live-pilot/plan.mjs', import.meta.url));
function uuidFactory() {
  let counter = 0;
  return () => `11111111-1111-4111-8111-${String(++counter).padStart(12, '0')}`;
}
function plan(options = {}) {
  return makePlan({now, runId: 'ra-20261102-abc123', uuidFactory: uuidFactory(), ...options});
}
function assertOffline(value) {
  assert.equal(value.remotelyExecuted, false);
  assert.equal(value.scope.remoteRequestsExecuted, 0);
  assert.equal(value.readiness.remoteCreationReady, false);
  assert.equal(value.readiness.publicationReady, false);
  assert.equal(value.readiness.physicalRecognitionVerified, false);
  const text = JSON.stringify(value);
  for (const forbidden of ['tested_version', 'p_tracking_seconds', 'service_role', 'SUPABASE_',
    'password', 'access_token', 'refresh_token', 'https://', 'http://']) assert.equal(text.includes(forbidden), false);
}
async function cliFixture(t) {
  const root = await mkdtemp(join(tmpdir(), 'marea-ar-offline-plan-'));
  t.after(async () => {
    assert.equal(dirname(resolve(root)).toLowerCase(), resolve(tmpdir()).toLowerCase());
    assert.match(root, /marea-ar-offline-plan-[^\\/]+$/);
    await rm(root, {recursive: true, force: true});
  });
  const directory = join(root, 'tool', 'ar-live-pilot');
  await mkdir(directory, {recursive: true});
  const script = join(directory, 'plan.mjs');
  await copyFile(source, script);
  return {root, script, output: join(root, 'outputs', 'ar-live-pilot', 'plan.json')};
}
function run(script, args = []) {
  return spawnSync(process.execPath, [script, ...args], {encoding: 'utf8', timeout: 10000,
    env: {PATH: process.env.PATH, SYSTEMROOT: process.env.SYSTEMROOT}});
}

test('offline plan is deterministic with injected time and UUIDs and contains no credentials', () => {
  const first = plan(), second = plan();
  assert.deepEqual(first, second);
  assertOffline(first);
  assert.equal(first.mode, 'offline_preview');
  assert.equal(first.scope.allowExistingRecordUpdates, false);
  assert.equal(first.scope.allowExistingRecordDeletes, false);
  assert.equal(first.scope.allowRoleChanges, false);
  assert.equal(first.scope.allowAdministratorCreation, false);
});

test('two proposed new accounts use ordinary business/general types, with no claimed live identity', () => {
  const value = plan();
  assert.equal(value.accounts.owner.profile.user_type, 'Negocio');
  assert.equal(value.accounts.visitor.profile.user_type, 'Usuario general');
  for (const account of Object.values(value.accounts)) {
    assert.equal(account.identityStatus, 'proposed_offline_not_created');
    assert.ok(account.profile.full_name.startsWith('Prueba RA MAREA'));
    assert.match(account.profile.username, /^[a-z0-9_]{3,30}$/);
    assert.equal('role' in account.profile, false);
    assert.equal('email' in account.profile, false);
  }
  assert.notEqual(value.accounts.owner.id, value.accounts.visitor.id);
  assert.equal(value.scope.mustRebindAccountIdsAfterSignup, true);
});

test('mission is future, geolocated, marked as a non-event and owned by the same proposed organizer', () => {
  const value = plan(), mission = value.mission;
  assert.equal(mission.author_id, value.accounts.owner.id);
  assert.equal(mission.author_id, value.tour.owner_id);
  assert.ok(Date.parse(mission.starts_at) > Date.parse(value.generatedAt));
  assert.equal(Date.parse(mission.starts_at) - Date.parse(value.generatedAt), 7 * 24 * 60 * 60 * 1000);
  assert.deepEqual([mission.location_latitude, mission.location_longitude], [19.4326, -99.1332]);
  assert.equal(mission.location_precision, 'approximate');
  assert.equal(mission.status, 'open');
  assert.match(mission.body, /No es un evento real/);
  assert.match(mission.location, /ubicación ficticia/);
  assert.ok(mission.title.startsWith('Prueba RA MAREA'));
  assert.ok(mission.title.length <= 100);
});

test('tour is an incomplete draft with UUID graph and owned reference path, never fabricated media or tracking', () => {
  const value = plan(), tour = value.tour;
  const scene = tour.document.zones[0].scenes[0], point = scene.points[0];
  assert.equal(tour.state, 'draft');
  assert.equal(tour.document.start_scene_id, scene.id);
  assert.deepEqual(tour.document.ar_order, [point.id]);
  assert.equal(point.ar.width_cm, 20);
  assert.match(point.ar.reference_version, /^[a-f0-9-]{36}$/);
  assert.match(point.ar.reference_path, new RegExp(`^${value.accounts.owner.id}/references/[a-f0-9-]{36}\\.jpg$`));
  assert.equal(value.storage[0].path, point.ar.reference_path);
  assert.equal(value.storage[0].owner_id, tour.owner_id);
  assert.equal(value.storage[0].bucket, 'tour-assets');
  assert.equal(value.storage[0].uploadStatus, 'not_uploaded');
  for (const absent of ['job_id', 'panorama_path', 'preview_path', 'thumbnail_path']) assert.equal(absent in scene, false);
  assert.equal('verified' in tour.space, false);
  assert.equal('public_revision_id' in tour, false);
  assertOffline(value);
});

test('required physical, panorama and review prerequisites remain explicitly pending', () => {
  const value = plan();
  assert.deepEqual(value.missingPrerequisites, value.prerequisites.map(item => item.code));
  assert.ok(value.prerequisites.every(item => item.status === 'pending_verification'));
  for (const required of ['real_gpano_or_guided_spherical_capture',
    'successful_processing_job_and_attached_result', 'physical_ar_tracking_current_reference_version',
    'legitimate_space_and_publication_review', 'actual_new_account_ids_and_session_access']) {
    assert.ok(value.missingPrerequisites.includes(required));
  }
  const tracking = value.prerequisites.find(item => item.code === 'physical_ar_tracking_current_reference_version');
  assert.match(tracking.requirement, /3 segundos reales/);
  assert.match(tracking.requirement, /versión.*nueva requiere otra prueba/);
});

test('all proposed UUIDs are unique and date arithmetic remains future across a year boundary', () => {
  const value = plan({now: new Date('2026-12-31T23:59:59Z')});
  assert.equal(value.mission.starts_at, '2027-01-07T23:59:59.000Z');
  assert.equal(value.tour.document.ends_at, '2027-01-14T23:59:59.000Z');
  const scene = value.tour.document.zones[0].scenes[0];
  const identifiers = [value.accounts.owner.id, value.accounts.visitor.id, value.mission.id, value.tour.id,
    value.tour.document.zones[0].id, scene.id, scene.points[0].id,
    scene.points[0].ar.reference_version, value.storage[0].path.split('/')[2].slice(0, -4)];
  assert.equal(new Set(identifiers).size, identifiers.length);
});

test('unsafe run identifiers and non-UTC, impossible or overflowing dates fail without reflecting input', () => {
  for (const runId of ['', '../escape', 'name@example.invalid', 'A', 'a'.repeat(21), 'x/../y', 'x\nsecret']) {
    assert.throws(() => plan({runId}), {
      name: 'TypeError', message: 'A safe run identifier and UUID factory are required.',
    });
  }
  for (const badNow of [undefined, NaN, Infinity, '2026-02-30T12:00:00Z', '2026-11-02',
    '2026-11-02T12:00:00', new Date('bad'), 8640000000000000]) {
    assert.throws(() => plan({now: badNow}), TypeError);
  }
});

test('a broken UUID factory cannot generate duplicate, non-UUID or path-bearing ownership values', () => {
  for (const factory of [() => '../foreign', () => '00000000-0000-0000-0000-000000000000',
    () => '11111111-1111-4111-8111-111111111111', null]) {
    assert.throws(() => plan({uuidFactory: factory}), TypeError);
  }
});

test('CLI preview writes no file by default and cannot execute remote operations', async t => {
  const {script, output} = await cliFixture(t);
  const result = run(script, ['--run-id', 'preview-only']);
  assert.equal(result.status, 0, result.stderr);
  const value = JSON.parse(result.stdout);
  assertOffline(value);
  await assert.rejects(lstat(output), {code: 'ENOENT'});
});

test('explicit --out creates only the fixed offline JSON and refuses to overwrite it', async t => {
  const {script, output} = await cliFixture(t);
  const result = run(script, ['--run-id', 'saved-preview', '--out', 'outputs/ar-live-pilot/plan.json']);
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(JSON.parse(await readFile(output, 'utf8')), JSON.parse(result.stdout));
  const first = await readFile(output, 'utf8');
  assert.notEqual(run(script, ['--out']).status, 0);
  assert.equal(await readFile(output, 'utf8'), first);
});

test('CLI rejects arbitrary output paths and unsupported action flags', async t => {
  const {script, output} = await cliFixture(t);
  for (const args of [['--out', '../escape.json'], ['--execute'], ['--deploy'], ['--run-id'], ['--out', '--out']]) {
    const result = run(script, args);
    assert.notEqual(result.status, 0);
    assert.equal(JSON.parse(result.stdout).remotelyExecuted, false);
  }
  await assert.rejects(lstat(output), {code: 'ENOENT'});
});

test('CLI rejects output directory symlinks and preserves unrelated local files', async t => {
  const {root, script} = await cliFixture(t);
  const outside = join(root, 'unrelated');
  await mkdir(outside);
  await writeFile(join(outside, 'keep.txt'), 'user data');
  await symlink(outside, join(root, 'outputs'), process.platform === 'win32' ? 'junction' : 'dir');
  const result = run(script, ['--out']);
  assert.notEqual(result.status, 0);
  assert.equal(await readFile(join(outside, 'keep.txt'), 'utf8'), 'user data');
  await assert.rejects(lstat(join(outside, 'ar-live-pilot', 'plan.json')), {code: 'ENOENT'});
});
