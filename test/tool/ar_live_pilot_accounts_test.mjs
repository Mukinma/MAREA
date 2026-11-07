import assert from 'node:assert/strict';
import {lstat, mkdir, mkdtemp, readFile, rm, symlink, writeFile} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {dirname, join, resolve} from 'node:path';
import {test} from 'node:test';

import {provisionAccounts} from '../../tool/ar-live-pilot/accounts.mjs';
import {makePlan} from '../../tool/ar-live-pilot/plan.mjs';

const origin = `https://${'b'.repeat(20)}.supabase.co`;
const key = 'sb_publishable_production-fixture0123456789';
const mailbox = 'owner.controlled@example.edu.mx';
const returnedIds = ['22222222-2222-4222-8222-222222222221', '22222222-2222-4222-8222-222222222222'];
const policy = {signup_enabled: true,
  terms: {version: 'test-terms-v1', body: 'Terms from server'},
  privacy: {version: 'test-privacy-v1', body: 'Privacy from server'}};
const settings = {disable_signup: false, mailer_autoconfirm: false, external: {email: true}};

function json(value, status = 200) {
  return new Response(JSON.stringify(value), {status, headers: {'Content-Type': 'application/json'}});
}

async function fixture(t, alter = () => {}) {
  const root = await mkdtemp(join(tmpdir(), 'marea-ar-account-test-'));
  t.after(async () => {
    assert.equal(dirname(resolve(root)).toLowerCase(), resolve(tmpdir()).toLowerCase());
    assert.match(root, /marea-ar-account-test-[^\\/]+$/);
    await rm(root, {recursive: true, force: true});
  });
  const plan = makePlan({now: new Date(), runId: 'ra-account-test'});
  const configuration = {SUPABASE_URL: origin, SUPABASE_ANON_KEY: key};
  alter(plan, configuration);
  await mkdir(join(root, 'config'));
  await mkdir(join(root, 'outputs', 'ar-live-pilot'), {recursive: true});
  await writeFile(join(root, 'config', 'supabase.production.json'), JSON.stringify(configuration));
  await writeFile(join(root, 'outputs', 'ar-live-pilot', 'plan.json'), JSON.stringify(plan));
  return {root, plan, journal: join(root, '.dart_tool', 'ar-live-pilot', 'accounts.json')};
}

function signupResponse(body, index = 0) {
  return {user: {id: returnedIds[index], email: body.email, role: 'authenticated',
    user_metadata: body.data, app_metadata: {provider: 'email'},
    identities: [{provider: 'email', user_id: returnedIds[index], identity_data: {email: body.email}}],
    email_confirmed_at: null}};
}

function transport({policyValue = policy, settingsValue = settings, onSignup} = {}) {
  const calls = [];
  return {
    calls,
    fetchImpl: async (url, options) => {
      assert.equal(url.origin, origin);
      assert.equal(options.redirect, 'manual');
      assert.equal(options.headers.apikey, key);
      assert.equal('Authorization' in options.headers, false);
      const path = url.pathname;
      calls.push({path, options});
      if (path === '/rest/v1/rpc/registration_policy') {
        assert.equal(options.method, 'GET');
        return json(policyValue);
      }
      if (path === '/auth/v1/settings') {
        assert.equal(options.method, 'GET');
        return json(settingsValue);
      }
      assert.equal(path, '/auth/v1/signup', 'a forbidden API was called');
      assert.equal(options.method, 'POST');
      const body = JSON.parse(options.body);
      const index = calls.filter(call => call.options.method === 'POST').length - 1;
      return onSignup ? await onSignup(body, index) : json(signupResponse(body, index));
    },
  };
}

function options(root, fetchImpl, extra = {}) {
  return {projectRoot: root, mailbox, fetchImpl, createNewAccounts: true, ...extra};
}

function redact(report, journal) {
  const text = JSON.stringify(report);
  for (const secret of [origin, key, mailbox, ...Object.values(journal?.accounts ?? {}).flatMap(account =>
    [account.email, account.password, account.response?.access_token, account.response?.refresh_token].filter(Boolean))]) {
    assert.equal(text.includes(secret), false, 'private account data leaked into report');
  }
}

test('explicit opt-in is required before files, network or account creation', async () => {
  const report = await provisionAccounts({mailbox, fetchImpl: () => assert.fail('network call without authorization')});
  assert.equal(report.status, 'blocked');
  assert.equal(report.errorCode, 'explicit_create_flag_required');
});

test('only two ordinary signups occur, with credentials durably recorded before each POST', async (t) => {
  const {root, plan, journal} = await fixture(t);
  const client = transport({onSignup: async (body, index) => {
    const persisted = JSON.parse(await readFile(journal, 'utf8'));
    const actor = index === 0 ? 'owner' : 'visitor';
    assert.equal(persisted.productionOrigin, origin);
    assert.equal(persisted.accounts[actor].attempted, true);
    assert.equal(persisted.accounts[actor].status, 'attempted');
    for (const account of Object.values(persisted.accounts)) {
      assert(Buffer.from(account.password, 'base64url').length >= 24);
    }
    assert.equal(body.password, persisted.accounts[actor].password);
    assert.equal(body.email, persisted.accounts[actor].email);
    assert.match(body.email, /^owner\.controlled\+pra_ra_account_test_[ov]@example\.edu\.mx$/);
    assert.deepEqual(body.data, {...persisted.accounts[actor].profile, registration_flow: 'minimal-v1',
      terms_version: policy.terms.version, privacy_version: policy.privacy.version,
      adult_confirmed: true, accepted_terms: true});
    assert.equal('id' in body, false);
    assert.equal('role' in body.data, false);
    assert.equal(body.data.user_type, index === 0 ? 'Negocio' : 'Usuario general');
    assert.equal(body.data.username, plan.accounts[actor].profile.username);
    return json(signupResponse(body, index));
  }});
  const report = await provisionAccounts(options(root, client.fetchImpl));
  assert.equal(report.status, 'created');
  assert.deepEqual(client.calls.map(call => [call.options.method, call.path]), [
    ['GET', '/rest/v1/rpc/registration_policy'], ['GET', '/auth/v1/settings'],
    ['POST', '/auth/v1/signup'], ['POST', '/auth/v1/signup'],
  ]);
  const persisted = JSON.parse(await readFile(journal, 'utf8'));
  assert.equal(persisted.accounts.owner.userId, returnedIds[0]);
  assert.equal(persisted.accounts.visitor.userId, returnedIds[1]);
  assert.notEqual(persisted.accounts.owner.userId, plan.accounts.owner.id);
  assert.equal(persisted.accounts.owner.confirmNeeded, true);
  assert.equal(persisted.accounts.visitor.confirmNeeded, true);
  assert.notEqual(persisted.accounts.owner.password, persisted.accounts.visitor.password);
  if (process.platform !== 'win32') assert.equal((await lstat(journal)).mode & 0o777, 0o600);
  redact(report, persisted);
});

test('an existing journal is never overwritten and cannot trigger another signup', async (t) => {
  const {root, journal} = await fixture(t);
  const firstClient = transport();
  assert.equal((await provisionAccounts(options(root, firstClient.fetchImpl))).status, 'created');
  const before = await readFile(journal);
  const secondClient = transport({onSignup: () => assert.fail('signup retried')});
  const report = await provisionAccounts(options(root, secondClient.fetchImpl));
  assert.equal(report.status, 'blocked');
  assert.equal(report.errorCode, 'journal_exists_or_unsafe');
  assert.deepEqual(await readFile(journal), before);
});

test('disabled registration or missing legal versions cannot create accounts', async (t) => {
  const {root} = await fixture(t);
  for (const policyValue of [
    {...policy, signup_enabled: false}, {...policy, terms: null},
    {...policy, terms: {...policy.terms, version: ''}},
    {...policy, privacy: {...policy.privacy, body: ' '}},
  ]) {
    const client = transport({policyValue});
    const report = await provisionAccounts(options(root, client.fetchImpl));
    assert.equal(report.errorCode, 'registration_policy_not_ready');
    assert.equal(client.calls.length, 1);
  }
});

test('disabled or unknown email signup settings fail closed', async (t) => {
  const {root} = await fixture(t);
  for (const settingsValue of [
    {...settings, disable_signup: true}, {...settings, external: {email: false}}, {}, null,
  ]) {
    const client = transport({settingsValue});
    const report = await provisionAccounts(options(root, client.fetchImpl));
    assert.equal(report.errorCode, 'email_signup_not_enabled');
    assert.equal(client.calls.length, 2);
  }
});

test('an administrator, third actor, existing binding or stale mission invalidates the plan before network', async (t) => {
  for (const alter of [
    plan => { plan.accounts.owner.profile.role = 'admin'; },
    plan => { plan.accounts.owner.role = 'admin'; },
    plan => { plan.accounts.visitor.profile.user_type = 'Negocio'; },
    plan => { plan.accounts.reviewer = plan.accounts.owner; },
    plan => { plan.accounts.owner.identityStatus = 'created'; },
    plan => { plan.accounts.owner.profile.username = 'a'.repeat(25); },
    plan => { plan.scope.allowExistingRecordUpdates = true; },
    plan => { plan.mission.starts_at = new Date(0).toISOString(); },
  ]) {
    const {root} = await fixture(t, alter);
    const report = await provisionAccounts(options(root, () => assert.fail('invalid plan contacted backend')));
    assert.equal(report.errorCode, 'plan_invalid');
  }
});

test('remote HTTP, custom hosts and server credentials cannot authorize production signup', async (t) => {
  for (const alter of [
    (_, config) => { config.SUPABASE_URL = origin.replace('https:', 'http:'); },
    (_, config) => { config.SUPABASE_URL = 'https://example.com'; },
    (_, config) => { config.SUPABASE_ANON_KEY = 'sb_secret_backend0123456789'; },
    (_, config) => { config.SUPABASE_ANON_KEY = [
      Buffer.from('{}').toString('base64url'),
      Buffer.from(JSON.stringify({role: 'service_role'})).toString('base64url'), 'signature'].join('.'); },
  ]) {
    const {root} = await fixture(t, alter);
    const report = await provisionAccounts(options(root, () => assert.fail('invalid config contacted backend')));
    assert.equal(report.errorCode, 'public_production_config_required');
  }
});

test('malformed or overlong controlled mailbox is rejected before network', async (t) => {
  const {root} = await fixture(t);
  for (const invalid of ['', 'someone@example.edu.mx\n', 'not-an-email', '.bad@example.edu.mx',
    'bad..local@example.edu.mx', `${'a'.repeat(60)}@example.edu.mx`]) {
    const report = await provisionAccounts(options(root, () => assert.fail('invalid mailbox contacted backend'), {mailbox: invalid}));
    assert.equal(report.errorCode, 'controlled_mailbox_required');
  }
});

test('redirects during preflight are refused without following a server-supplied URL', async (t) => {
  const {root} = await fixture(t);
  let calls = 0;
  const report = await provisionAccounts(options(root, async (_, options) => {
    calls++;
    assert.equal(options.redirect, 'manual');
    return new Response('', {status: 302, headers: {Location: 'https://forbidden.example.com'}});
  }));
  assert.equal(report.errorCode, 'redirect_rejected');
  assert.equal(calls, 1);
});

test('an ambiguous failed POST leaves attempted credentials and never retries or creates the visitor', async (t) => {
  const {root, journal} = await fixture(t);
  const client = transport({onSignup: () => { throw new Error(`network error with ${mailbox} and ${key}`); }});
  const report = await provisionAccounts(options(root, client.fetchImpl));
  assert.equal(report.status, 'incomplete');
  const saved = JSON.parse(await readFile(journal, 'utf8'));
  assert.equal(saved.accounts.owner.attempted, true);
  assert.equal(saved.accounts.owner.status, 'blocked_after_attempt');
  assert.equal(saved.accounts.visitor.attempted, false);
  assert.equal(client.calls.filter(call => call.options.method === 'POST').length, 1);
  redact(report, saved);
  const again = transport({onSignup: () => assert.fail('ambiguous POST retried')});
  assert.equal((await provisionAccounts(options(root, again.fetchImpl))).errorCode, 'journal_exists_or_unsafe');
});

test('known Auth errors are reported as codes, while server details and unexpected codes stay private', async (t) => {
  for (const code of ['over_email_send_rate_limit', `unexpected-${mailbox}`]) {
    const {root, journal} = await fixture(t);
    const client = transport({onSignup: () => json({code, msg: `details ${key} ${mailbox}`}, 429)});
    const report = await provisionAccounts(options(root, client.fetchImpl));
    assert.equal(report.errorCode, code === 'over_email_send_rate_limit' ? code : 'http_rejected');
    const saved = JSON.parse(await readFile(journal, 'utf8'));
    assert.equal(saved.accounts.owner.response.code, code);
    redact(report, saved);
  }
});

test('empty fake identities, wrong email, elevated roles and invalid IDs cannot become trusted bindings', async (t) => {
  for (const alter of [
    value => { value.user.identities = []; },
    value => { value.user.email = 'someone-else@example.edu.mx'; },
    value => { value.user.role = 'service_role'; },
    value => { value.user.app_metadata.role = 'admin'; },
    value => { value.user.user_metadata.role = 'admin'; },
    value => { value.user.id = 'not-a-uuid'; },
    value => { value.user.identities[0].provider = 'google'; },
  ]) {
    const {root, journal} = await fixture(t);
    const client = transport({onSignup: body => {
      const response = signupResponse(body);
      alter(response);
      return json(response);
    }});
    const report = await provisionAccounts(options(root, client.fetchImpl));
    assert.equal(report.errorCode, 'new_identity_not_verified');
    const saved = JSON.parse(await readFile(journal, 'utf8'));
    assert.equal(saved.accounts.owner.userId, null);
    assert.equal(saved.accounts.visitor.attempted, false);
    assert.equal(report.accounts[0].newUserId, null);
    redact(report, saved);
  }
});

test('a duplicate returned identity cannot bind both actors; sessions remain only in the private journal', async (t) => {
  const {root, journal} = await fixture(t);
  const client = transport({onSignup: (body, index) => {
    const response = signupResponse(body, 0);
    response.access_token = 'server-issued-private-token';
    response.refresh_token = 'server-issued-private-refresh';
    response.user.email_confirmed_at = index ? null : new Date().toISOString();
    return json(response);
  }});
  const report = await provisionAccounts(options(root, client.fetchImpl));
  assert.equal(report.status, 'incomplete');
  assert.equal(report.accounts[0].confirmNeeded, false);
  assert.equal(report.accounts[1].newUserId, null);
  const saved = JSON.parse(await readFile(journal, 'utf8'));
  assert.equal(saved.accounts.owner.response.access_token, 'server-issued-private-token');
  redact(report, saved);
});

test('network timeout bounds a POST even if the transport ignores abort, without automatic retry', async (t) => {
  const {root, journal} = await fixture(t);
  const client = transport({onSignup: () => new Promise(() => {})});
  const report = await provisionAccounts(options(root, client.fetchImpl, {timeoutMs: 20}));
  assert.equal(report.errorCode, 'timeout');
  assert.equal(report.accounts[1].status, 'not_attempted');
  const saved = JSON.parse(await readFile(journal, 'utf8'));
  assert.equal(saved.accounts.owner.attempted, true);
  redact(report, saved);
});

test('a redirected signup is treated as attempted and never follows the redirect', async (t) => {
  const {root, journal} = await fixture(t);
  const client = transport({onSignup: () => new Response('', {status: 307, headers: {Location: 'https://another.example.com'}})});
  const report = await provisionAccounts(options(root, client.fetchImpl));
  assert.equal(report.errorCode, 'redirect_rejected');
  assert.equal(client.calls.length, 3);
  assert.equal(JSON.parse(await readFile(journal, 'utf8')).accounts.owner.attempted, true);
});

test('a junction cannot redirect the private journal or config outside the project', async (t) => {
  const {root} = await fixture(t);
  const outside = await mkdtemp(join(tmpdir(), 'marea-ar-account-test-'));
  t.after(async () => {
    assert.equal(dirname(resolve(outside)).toLowerCase(), resolve(tmpdir()).toLowerCase());
    assert.match(outside, /marea-ar-account-test-[^\\/]+$/);
    await rm(outside, {recursive: true, force: true});
  });
  await symlink(outside, join(root, '.dart_tool'), process.platform === 'win32' ? 'junction' : 'dir');
  const client = transport({onSignup: () => assert.fail('unsafe journal reached signup')});
  assert.equal((await provisionAccounts(options(root, client.fetchImpl))).errorCode, 'journal_exists_or_unsafe');
  await assert.rejects(readFile(join(outside, 'ar-live-pilot', 'accounts.json')));
  await rm(join(root, '.dart_tool'));
  await rm(join(root, 'config'), {recursive: true});
  await mkdir(join(outside, 'config'));
  await writeFile(join(outside, 'config', 'supabase.production.json'), JSON.stringify({SUPABASE_URL: origin, SUPABASE_ANON_KEY: key}));
  await symlink(join(outside, 'config'), join(root, 'config'), process.platform === 'win32' ? 'junction' : 'dir');
  const blocked = await provisionAccounts(options(root, () => assert.fail('unsafe config contacted backend')));
  assert.equal(blocked.errorCode, 'configuration_or_plan_unavailable');
});
