import assert from 'node:assert/strict';
import {lstat, mkdir, mkdtemp, readFile, rm, writeFile} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {dirname, join, resolve} from 'node:path';
import {test} from 'node:test';
import {makePlan} from '../../tool/ar-live-pilot/plan.mjs';
import {createTourAndMissionDrafts} from '../../tool/ar-live-pilot/drafts.mjs';

const origin = 'https://aaaaaaaaaaaaaaaaaaaa.supabase.co';
const publicKey = 'sb_publishable_public0123456789abcdefghijklmnop';
const ownerId = '22222222-2222-4222-8222-222222222222';
const visitorId = '33333333-3333-4333-8333-333333333333';
const now = Date.parse('2026-11-02T12:00:00Z');
function token(claims = {}) {
  const payload = {sub: ownerId, role: 'authenticated', iss: `${origin}/auth/v1`,
    aud: 'authenticated', exp: Math.floor(now / 1000) + 3600, ...claims};
  return `${Buffer.from('{}').toString('base64url')}.${Buffer.from(JSON.stringify(payload)).toString('base64url')}.signature`;
}
function newPlan(planNow = now) {
  let counter = 0;
  return makePlan({now: planNow, runId: 'ra-live-test', uuidFactory: () =>
    `11111111-1111-4111-8111-${String(++counter).padStart(12, '0')}`});
}
function account(plan, which, id) {
  const email = `${which}-private@example.invalid`;
  const response = {id, email, created_at: new Date(now).toISOString(),
    user_metadata: plan.accounts[which].profile, identities: [{id: 'email-identity', provider: 'email', user_id: id}]};
  return {email, password: 'do-not-print-fixture-password', userId: id, status: 'created', response,
    ...(which === 'owner' ? {session: {access_token: token(), refresh_token: 'do-not-print-refresh'}} : {})};
}
async function fixture(t, {plan = newPlan()} = {}) {
  const root = await mkdtemp(join(tmpdir(), 'marea-ar-private-drafts-'));
  t.after(async () => {
    assert.equal(dirname(resolve(root)).toLowerCase(), resolve(tmpdir()).toLowerCase());
    assert.match(root, /marea-ar-private-drafts-[^\\/]+$/);
    await rm(root, {recursive: true, force: true});
  });
  for (const path of ['config', 'outputs/ar-live-pilot', '.dart_tool/ar-live-pilot']) await mkdir(join(root, path), {recursive: true});
  const accounts = {runId: plan.runId, productionOrigin: origin, createdAt: new Date(now).toISOString(),
    accounts: {owner: account(plan, 'owner', ownerId), visitor: account(plan, 'visitor', visitorId)}};
  const files = {root, plan, accounts,
    accountFile: join(root, '.dart_tool', 'ar-live-pilot', 'accounts.json'),
    planFile: join(root, 'outputs', 'ar-live-pilot', 'plan.json'),
    resourcesFile: join(root, '.dart_tool', 'ar-live-pilot', 'resources.json')};
  await writeFile(join(root, 'config', 'supabase.production.json'), JSON.stringify({SUPABASE_URL: origin, SUPABASE_ANON_KEY: publicKey}), {mode: 0o600});
  await writeFile(files.planFile, JSON.stringify(plan), {mode: 0o600});
  await writeFile(files.accountFile, JSON.stringify(accounts), {mode: 0o600});
  await writeFile(join(root, 'outputs', 'ar-live-pilot', 'reference.jpg'), Buffer.from([0xff, 0xd8, 0xff, 0xd9]), {mode: 0o600});
  return files;
}
function json(value, status = 200) { return new Response(JSON.stringify(value), {status}); }
function fetchMock(files, {calls = [], route} = {}) {
  return async (url, options) => {
    const address = new URL(url), path = address.pathname;
    calls.push({url: String(url), options});
    assert.equal(address.origin, origin);
    assert.equal(options.redirect, 'manual');
    assert.equal(options.headers.apikey, publicKey);
    assert.equal(options.headers.Authorization, `Bearer ${files.accounts.accounts.owner.session.access_token}`);
    assert.equal(options.method === 'GET' || options.method === 'POST', true);
    if (options.method === 'POST') {
      const journal = JSON.parse(await readFile(files.resourcesFile, 'utf8'));
      assert.equal(journal.ownerId, ownerId);
      assert.equal(journal.status, 'creating_private_drafts');
      assert.equal(Object.values(journal.steps).filter(status => status === 'in_flight').length, 1);
    }
    const override = await route?.(address, options);
    if (override !== undefined) return override;
    if (path === '/auth/v1/user') return json({...files.accounts.accounts.owner.response,
      role: 'authenticated', email_confirmed_at: new Date(now).toISOString()});
    if (path === '/rest/v1/rpc/tours_get') {
      assert.equal(address.searchParams.get('p_tour'), files.plan.tour.id);
      assert.equal(address.searchParams.get('p_edit'), 'true');
      return json(null);
    }
    if (path === '/rest/v1/mission_drafts') {
      assert.equal(address.searchParams.get('id'), `eq.${files.plan.mission.id}`);
      assert.equal(address.searchParams.get('select'), 'id,author_id');
      return json([]);
    }
    if (path.startsWith('/storage/v1/object/tour-assets/')) {
      assert.equal(options.headers['x-upsert'], 'false');
      assert.equal(options.headers['Content-Type'], 'image/jpeg');
      assert.ok(Buffer.isBuffer(options.body));
      return json({Key: path.replace('/storage/v1/object/', '')});
    }
    if (path === '/rest/v1/rpc/tours_save') return json({id: files.plan.tour.id, owner_id: ownerId, state: 'draft', public_revision_id: null});
    if (path === '/rest/v1/rpc/save_mission_draft') return json(files.plan.mission.id);
    assert.fail('A request escaped the exact creation allowlist.');
  };
}
function options(files, extra = {}) { return {projectRoot: files.root, createNewDrafts: true, now, ...extra}; }
function assertRedacted(report) {
  const serialized = JSON.stringify(report);
  for (const value of [origin, publicKey, 'owner-private@example.invalid', 'visitor-private@example.invalid',
    'do-not-print-fixture-password', 'do-not-print-refresh', token()]) assert.equal(serialized.includes(value), false);
}

test('without explicit creation flag no files or remote sessions are touched', async () => {
  let calls = 0;
  const report = await createTourAndMissionDrafts({projectRoot: 'not-an-absolute-root', fetchImpl: async () => calls++});
  assert.equal(report.status, 'blocked');
  assert.equal(report.reason, 'explicit_new_drafts_flag_required');
  assert.equal(report.remotelyExecuted, false);
  assert.equal(calls, 0);
});

test('creates only one owned reference and two PRIVATE drafts after identity and collision checks', async t => {
  const files = await fixture(t), calls = [];
  const report = await createTourAndMissionDrafts(options(files, {fetchImpl: fetchMock(files, {calls})}));
  assert.equal(report.status, 'created_private_drafts');
  assert.deepEqual(report.createdIds, {tourId: files.plan.tour.id, missionDraftId: files.plan.mission.id});
  assert.deepEqual(calls.map(call => call.options.method), ['GET', 'GET', 'GET', 'POST', 'POST', 'POST']);
  const tourBody = JSON.parse(calls[4].options.body), missionBody = JSON.parse(calls[5].options.body);
  const reference = tourBody.p_document.zones[0].scenes[0].points[0].ar;
  assert.ok(reference.reference_path.startsWith(`${ownerId}/references/`));
  assert.equal(reference.reference_version, files.plan.tour.document.zones[0].scenes[0].points[0].ar.reference_version);
  assert.equal('tested_version' in reference, false);
  assert.equal('owner_id' in tourBody, false);
  for (const field of ['id', 'author_id', 'status']) assert.equal(field in missionBody.draft_input, false);
  assert.equal(missionBody.draft_id, files.plan.mission.id);
  assert.equal(missionBody.draft_input.location_city, null);
  assert.ok(!JSON.stringify(calls.map(call => call.url)).match(/publish|submit|ar_report|claim|admin|cancel|delete/));
  const resources = JSON.parse(await readFile(files.resourcesFile, 'utf8'));
  assert.equal(resources.status, 'created_private_drafts');
  assert.ok(Object.values(resources.steps).every(status => status === 'created'));
  assert.equal(JSON.stringify(resources).includes('access_token'), false);
  assert.equal(JSON.stringify(resources).includes('password'), false);
  if (process.platform !== 'win32') assert.equal((await lstat(files.resourcesFile)).mode & 0o777, 0o600);
  assertRedacted(report);
});

test('an existing tour or existing mission draft blocks every POST and leaves no resource journal', async t => {
  for (const collision of ['tour', 'mission']) {
    const files = await fixture(t), calls = [];
    const report = await createTourAndMissionDrafts(options(files, {fetchImpl: fetchMock(files, {calls, route: address => {
      if (collision === 'tour' && address.pathname.endsWith('/tours_get')) return json({id: files.plan.tour.id});
      if (collision === 'mission' && address.pathname.endsWith('/mission_drafts')) return json([{id: files.plan.mission.id, author_id: ownerId}]);
    }})}));
    assert.equal(report.status, 'blocked');
    assert.ok(calls.every(call => call.options.method === 'GET'));
    await assert.rejects(lstat(files.resourcesFile), {code: 'ENOENT'});
  }
});

test('RLS denial or malformed collision read blocks uploads and both draft writes', async t => {
  for (const failure of [() => json({code: '42501'}, 403), () => json({unexpected: true})]) {
    const files = await fixture(t), calls = [];
    const report = await createTourAndMissionDrafts(options(files, {fetchImpl: fetchMock(files, {calls, route: address =>
      address.pathname.endsWith('/mission_drafts') ? failure() : undefined})}));
    assert.equal(report.status, 'blocked');
    assert.ok(calls.every(call => call.options.method === 'GET'));
    await assert.rejects(lstat(files.resourcesFile), {code: 'ENOENT'});
  }
});

test('wrong run, wrong origin, old/hidden signup and proposed user identities fail before networking', async t => {
  const alterations = [
    accounts => {accounts.runId = 'different-run';},
    accounts => {accounts.productionOrigin = 'https://bbbbbbbbbbbbbbbbbbbb.supabase.co';},
    accounts => {accounts.accounts.owner.status = 'existing';},
    accounts => {accounts.accounts.owner.response.identities = [];},
    accounts => {accounts.accounts.owner.response.created_at = '2025-01-01T00:00:00Z';},
    accounts => {accounts.accounts.owner.response.user_metadata.username = 'another_user';},
  ];
  for (const alter of alterations) {
    const files = await fixture(t); alter(files.accounts);
    await writeFile(files.accountFile, JSON.stringify(files.accounts));
    let calls = 0;
    const report = await createTourAndMissionDrafts(options(files, {fetchImpl: async () => calls++}));
    assert.equal(report.status, 'blocked');
    assert.equal(calls, 0);
    assertRedacted(report);
  }
});

test('foreign, privileged, mismatched-subject and expired sessions cannot make any request', async t => {
  for (const access_token of [token({iss: 'https://bbbbbbbbbbbbbbbbbbbb.supabase.co/auth/v1'}),
    token({role: 'service_role'}), token({sub: visitorId}), token({exp: Math.floor(now / 1000) - 1})]) {
    const files = await fixture(t);
    files.accounts.accounts.owner.session.access_token = access_token;
    await writeFile(files.accountFile, JSON.stringify(files.accounts));
    let calls = 0;
    const report = await createTourAndMissionDrafts(options(files, {fetchImpl: async () => calls++}));
    assert.equal(report.status, 'blocked');
    assert.equal(calls, 0);
    assertRedacted(report);
    assert.equal(JSON.stringify(report).includes(access_token), false);
  }
});

test('actual auth identity and confirmation must agree with the newly created owner', async t => {
  for (const override of [{id: visitorId}, {email: 'someone-else@example.invalid'}, {email_confirmed_at: null}]) {
    const files = await fixture(t), calls = [];
    const report = await createTourAndMissionDrafts(options(files, {fetchImpl: fetchMock(files, {calls, route: address =>
      address.pathname === '/auth/v1/user' ? json({...files.accounts.accounts.owner.response,
        email_confirmed_at: new Date(now).toISOString(), ...override}) : undefined})}));
    assert.equal(report.status, 'blocked');
    assert.equal(calls.length, 1);
    assert.equal(calls[0].options.method, 'GET');
    assertRedacted(report);
  }
});

test('plan modifications, invented tracking, fabricated panorama and expired mission are rejected offline', async t => {
  for (const alter of [plan => {plan.tour.document.zones[0].scenes[0].points[0].ar.tested_version = 'invented';},
    plan => {plan.tour.document.zones[0].scenes[0].job_id = ownerId;},
    plan => {plan.tour.state = 'published';}, plan => {plan.mission.author_id = visitorId;}]) {
    const files = await fixture(t); alter(files.plan);
    await writeFile(files.planFile, JSON.stringify(files.plan));
    let calls = 0;
    const report = await createTourAndMissionDrafts(options(files, {fetchImpl: async () => calls++}));
    assert.equal(report.status, 'blocked');
    assert.equal(calls, 0);
  }
  const files = await fixture(t, {plan: newPlan(now - 8 * 86400000)});
  let calls = 0;
  const report = await createTourAndMissionDrafts(options(files, {fetchImpl: async () => calls++}));
  assert.equal(report.reason, 'plan_mission_date_expired');
  assert.equal(calls, 0);
});

test('exclusive existing resources journal is preserved and prevents all repeat POSTs', async t => {
  const files = await fixture(t), calls = [], existing = '{"userLocalChange":"preserve"}';
  await writeFile(files.resourcesFile, existing);
  const report = await createTourAndMissionDrafts(options(files, {fetchImpl: fetchMock(files, {calls})}));
  assert.equal(report.reason, 'resource_journal_exists_or_unavailable_no_retry');
  assert.ok(calls.every(call => call.options.method === 'GET'));
  assert.equal(await readFile(files.resourcesFile, 'utf8'), existing);
});

test('upload conflict/redirect aborts further writes and preserves an uncertain no-retry journal', async t => {
  for (const response of [() => json({message: 'duplicate'}, 409),
    () => new Response(null, {status: 302, headers: {Location: 'https://bbbbbbbbbbbbbbbbbbbb.supabase.co/'}})]) {
    const files = await fixture(t), calls = [];
    const report = await createTourAndMissionDrafts(options(files, {fetchImpl: fetchMock(files, {calls, route: address =>
      address.pathname.startsWith('/storage/') ? response() : undefined})}));
    assert.equal(report.status, 'partial_or_uncertain_no_retry');
    assert.equal(calls.filter(call => call.options.method === 'POST').length, 1);
    assert.equal(JSON.parse(await readFile(files.resourcesFile, 'utf8')).steps.referenceUpload, 'failed_or_uncertain');
    assertRedacted(report);
  }
});

test('an ambiguous POST timeout cannot trigger a retry or a later draft write', async t => {
  const files = await fixture(t), calls = [];
  const report = await createTourAndMissionDrafts(options(files, {timeoutMs: 10,
    fetchImpl: fetchMock(files, {calls, route: address => address.pathname.startsWith('/storage/')
      ? new Promise(() => {}) : undefined})}));
  assert.equal(report.status, 'partial_or_uncertain_no_retry');
  assert.equal(report.reason, 'remote_timeout');
  assert.equal(calls.filter(call => call.options.method === 'POST').length, 1);
  const previous = await readFile(files.resourcesFile, 'utf8'), repeatCalls = [];
  const repeat = await createTourAndMissionDrafts(options(files, {fetchImpl: fetchMock(files, {calls: repeatCalls})}));
  assert.equal(repeat.reason, 'resource_journal_exists_or_unavailable_no_retry');
  assert.ok(repeatCalls.every(call => call.options.method === 'GET'));
  assert.equal(await readFile(files.resourcesFile, 'utf8'), previous);
});

test('mismatched draft response prevents the next write and never claims creation of a public Mission', async t => {
  const files = await fixture(t), calls = [];
  const report = await createTourAndMissionDrafts(options(files, {fetchImpl: fetchMock(files, {calls, route: address =>
    address.pathname.endsWith('/tours_save') ? json({id: files.plan.tour.id, owner_id: visitorId, state: 'draft'}) : undefined})}));
  assert.equal(report.status, 'partial_or_uncertain_no_retry');
  assert.equal(calls.filter(call => call.options.method === 'POST').length, 2);
  assert.deepEqual(report.createdIds, {});
  assertRedacted(report);
});
