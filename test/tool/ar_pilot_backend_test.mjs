import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp, mkdir, writeFile, rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {dirname, join, resolve} from 'node:path';
import {checkDevelopmentBackend, pilotRpcContract} from '../../tool/ar-pilot/backend.mjs';

const devUrl = 'https://aaaaaaaaaaaaaaaaaaaa.supabase.co';
const productionUrl = 'https://bbbbbbbbbbbbbbbbbbbb.supabase.co';
const publicKey = 'sb_publishable_abcdefghijklmnopqrstuvwxyz0123456789';
const productionKey = 'sb_publishable_production0123456789abcdef';
const now = Date.parse('2026-11-02T12:00:00Z');

async function project(t, {url = devUrl, production = true} = {}) {
  const root = await mkdtemp(join(tmpdir(), 'marea-ar-readonly-'));
  t.after(async () => {
    assert.equal(dirname(resolve(root)).toLowerCase(), resolve(tmpdir()).toLowerCase());
    assert.match(root, /marea-ar-readonly-[^\\/]+$/);
    await rm(root, {recursive: true, force: true});
  });
  await mkdir(join(root, 'config'));
  if (production) await writeFile(join(root, 'config', 'supabase.production.json'),
    JSON.stringify({SUPABASE_URL: productionUrl, SUPABASE_ANON_KEY: productionKey}));
  await writeFile(join(root, 'config', 'supabase.development.json'),
    JSON.stringify({SUPABASE_URL: url, SUPABASE_ANON_KEY: publicKey}));
  return root;
}

function specification() {
  return {
    swagger: '2.0', paths: Object.fromEntries(pilotRpcContract.map(contract => [
      `/rpc/${contract.name}`, {[contract.method]: {parameters: contract.method === 'get'
        ? contract.parameters.map(name => ({name, in: 'query', type: 'string'}))
        : [{in: 'body', schema: {type: 'object', properties: Object.fromEntries(contract.parameters.map(name => [name, {type: 'string'}]))}}],
      }},
    ])),
    definitions: {
      profiles: {properties: {id: {}, user_type: {}, initial_profile_completed_at: {}}},
      legal_acceptances: {properties: {user_id: {}, terms_version: {}, privacy_version: {}}},
    },
  };
}
function json(value, status = 200) {
  return new Response(JSON.stringify(value), {status, headers: {'content-type': 'application/json'}});
}
function completeFetch(calls = [], spec = specification()) {
  return async (url, options) => {
    calls.push({url: String(url), options});
    const path = new URL(url).pathname;
    if (path === '/rest/v1/') return json(spec);
    if (path.endsWith('/registration_policy')) return json({
      signup_enabled: true,
      terms: {version: 'dev', title: 'Terms', body: 'Public development legal text'},
      privacy: {version: 'dev', title: 'Privacy', body: 'Public development privacy text'},
      support_email: 'private-from-report@example.invalid',
    });
    if (path.endsWith('/tours_get')) return json(null);
    if (path.endsWith('/list_map_missions')) return json({missions: [], total: 0});
    return json([]);
  };
}
function token(claims = {}) {
  const payload = {role: 'authenticated', aud: 'authenticated',
    sub: '11111111-1111-4111-8111-111111111111', iss: `${devUrl}/auth/v1`,
    exp: Math.floor(now / 1000) + 3600, ...claims};
  return `${Buffer.from('{}').toString('base64url')}.${Buffer.from(JSON.stringify(payload)).toString('base64url')}.test`;
}
function assertRedacted(report, extra = []) {
  const text = JSON.stringify(report);
  for (const secret of [devUrl, productionUrl, publicKey, productionKey, 'private-from-report@example.invalid', ...extra]) {
    assert.equal(text.includes(secret), false);
  }
  assert.equal(report.rlsVerified, false);
  assert.equal(report.publicationVerified, false);
  assert.equal(report.physicalARVerified, false);
}

test('complete authenticated metadata and read shapes verify only API surface using six GET requests', async t => {
  const projectRoot = await project(t);
  const calls = [], userToken = token();
  const report = await checkDevelopmentBackend({projectRoot, fetchImpl: completeFetch(calls), now, userToken});
  assert.equal(report.status, 'api_checked');
  assert.equal(report.apiSurfaceVerified, true);
  assert.equal(calls.length, 6);
  for (const {url, options} of calls) {
    assert.equal(new URL(url).origin, devUrl);
    assert.equal(options.method, 'GET');
    assert.equal(options.body, undefined);
    assert.equal(options.redirect, 'manual');
    assert.equal(options.headers.apikey, publicKey);
    assert.equal(options.headers.Authorization, `Bearer ${userToken}`);
    assert.ok(options.signal instanceof AbortSignal);
    assert.equal(/save|submit|report_test|create_mission|complete_initial_profile|accept_current_legal/.test(new URL(url).pathname), false);
  }
  assertRedacted(report, [userToken]);
  assert.equal(report.checks.find(check => check.id === 'schema:legal_documents').status, 'unverified');
});

test('HTTP200 for a protected RPC without a user token cannot pass an anonymous preflight', async t => {
  const projectRoot = await project(t);
  const calls = [];
  const report = await checkDevelopmentBackend({projectRoot, fetchImpl: completeFetch(calls), now});
  assert.equal(report.apiSurfaceVerified, false);
  assert.equal(report.status, 'incomplete');
  assert.equal(report.checks.find(check => check.id === 'read:tours_public_list').evidence,
    'authenticated_rpc_readable_without_user_token');
  assert.ok(calls.every(({options}) => options.headers.Authorization === undefined));
});

test('POST-only documentation of a reader supplies metadata while actual requests remain GET', async t => {
  const projectRoot = await project(t), spec = specification(), calls = [];
  spec.paths['/rpc/tours_public_list'] = {post: {parameters: [{in: 'body', schema: {properties: {p_owner: {type: 'string'}}}}]}};
  const report = await checkDevelopmentBackend({projectRoot, now, userToken: token(), fetchImpl: completeFetch(calls, spec)});
  assert.equal(report.apiSurfaceVerified, true);
  assert.equal(report.checks.find(check => check.id === 'rpc:tours_public_list').evidence,
    'openapi_post_signature_observed_get_probed_separately');
  assert.ok(calls.every(({options}) => options.method === 'GET'));
});

test('production target is rejected before any request', async t => {
  const projectRoot = await project(t, {url: productionUrl});
  let calls = 0;
  const report = await checkDevelopmentBackend({projectRoot, fetchImpl: async () => {calls++; throw Error();}, now});
  assert.equal(report.status, 'blocked');
  assert.equal(calls, 0);
  assertRedacted(report);
});

test('missing trusted production config blocks all requests', async t => {
  const projectRoot = await project(t, {production: false});
  let calls = 0;
  const report = await checkDevelopmentBackend({projectRoot, fetchImpl: async () => {calls++;}, now});
  assert.equal(report.status, 'blocked');
  assert.equal(calls, 0);
});

test('authorization failures stay unverified and PGRST202 stays unavailable', async t => {
  const projectRoot = await project(t);
  const report = await checkDevelopmentBackend({projectRoot, now, fetchImpl: async url => {
    const path = new URL(url).pathname;
    if (path.endsWith('/tours_public_list')) return json({code: 'PGRST202', message: `secret ${publicKey}`}, 404);
    return json({code: '42501', message: `private ${devUrl}`}, 403);
  }});
  assert.equal(report.status, 'incomplete');
  assert.equal(report.checks.find(check => check.id === 'openapi').status, 'unverified');
  assert.equal(report.checks.find(check => check.id === 'read:tours_get').evidence, 'authorization_required_or_denied');
  assert.equal(report.checks.find(check => check.id === 'read:tours_public_list').status, 'failed');
  assertRedacted(report);
});

test('redirects to production are rejected without following Location', async t => {
  const projectRoot = await project(t);
  const calls = [];
  const report = await checkDevelopmentBackend({projectRoot, now, fetchImpl: async (url, options) => {
    calls.push(String(url));
    assert.equal(options.redirect, 'manual');
    return new Response(null, {status: 302, headers: {Location: `${productionUrl}/rest/v1/`}});
  }});
  assert.equal(calls.length, 6);
  assert.ok(calls.every(url => url.startsWith(`${devUrl}/rest/v1/`)));
  assert.ok(report.checks.filter(check => check.id !== 'config').every(check => check.evidence === 'redirect_rejected'));
  assertRedacted(report);
});

test('OpenAPI servers, links and external schema refs never become network requests', async t => {
  const projectRoot = await project(t);
  const spec = specification();
  spec.servers = [{url: productionUrl}];
  spec.paths['/rpc/tours_save'].post.parameters = [{in: 'body', schema: {$ref: `${productionUrl}/evil`}}];
  const calls = [];
  const report = await checkDevelopmentBackend({projectRoot, now, fetchImpl: completeFetch(calls, spec)});
  assert.equal(calls.length, 6);
  assert.ok(calls.every(call => new URL(call.url).origin === devUrl));
  assert.equal(report.checks.find(check => check.id === 'rpc:tours_save').status, 'failed');
  assertRedacted(report);
});

test('request timeout also ends an injected fetch that ignores AbortSignal', async t => {
  const projectRoot = await project(t);
  const report = await checkDevelopmentBackend({projectRoot, now, timeoutMs: 5, fetchImpl: () => new Promise(() => {})});
  assert.equal(report.status, 'incomplete');
  assert.ok(report.checks.filter(check => check.id !== 'config').every(check => check.evidence === 'timeout'));
});

test('foreign, expired and privileged tokens block before fetching and are never logged', async t => {
  const projectRoot = await project(t);
  for (const userToken of [token({iss: `${productionUrl}/auth/v1`}), token({role: 'service_role'}), token({exp: 1}), publicKey]) {
    let calls = 0;
    const report = await checkDevelopmentBackend({projectRoot, now, userToken, fetchImpl: async () => {calls++;}});
    assert.equal(calls, 0);
    assert.equal(report.status, 'blocked');
    assertRedacted(report, [userToken]);
  }
});

test('optional existing user token is scoped to development issuer without any auth request', async t => {
  const projectRoot = await project(t);
  const calls = [], userToken = token();
  const report = await checkDevelopmentBackend({projectRoot, now, userToken, fetchImpl: completeFetch(calls)});
  assert.equal(report.actor, 'authenticated_user');
  assert.equal(report.status, 'api_checked');
  assert.ok(calls.every(({url, options}) => !new URL(url).pathname.startsWith('/auth/') && options.headers.Authorization === `Bearer ${userToken}`));
  assertRedacted(report, [userToken]);
});

test('closed signup and missing legal documents are reported without legal text', async t => {
  const projectRoot = await project(t);
  const normal = completeFetch();
  const report = await checkDevelopmentBackend({projectRoot, now, fetchImpl: (url, options) =>
    new URL(url).pathname.endsWith('/registration_policy')
      ? json({signup_enabled: false, terms: null, privacy: null}) : normal(url, options)});
  const legal = report.checks.find(check => check.id === 'read:registration_policy');
  assert.equal(legal.status, 'failed');
  assert.equal(legal.legalDocumentsReady, false);
  assert.equal(report.apiSurfaceVerified, false);
});

test('network failures, malformed specs and JSON cannot become passing checks or leak exception text', async t => {
  const projectRoot = await project(t);
  for (const fetchImpl of [
    async () => {throw Error(`${publicKey} ${productionUrl}`);},
    async () => json({swagger: '2.0', paths: []}),
    async () => new Response('private contents', {status: 200}),
  ]) {
    const report = await checkDevelopmentBackend({projectRoot, now, fetchImpl});
    assert.equal(report.apiSurfaceVerified, false);
    assertRedacted(report, ['private contents']);
  }
});

test('oversized responses are cancelled and remain unverified', async t => {
  const projectRoot = await project(t);
  const report = await checkDevelopmentBackend({projectRoot, now, fetchImpl: async () =>
    new Response('{}', {headers: {'content-length': String(5 * 1024 * 1024)}})});
  assert.ok(report.checks.filter(check => check.id !== 'config').every(check => check.evidence === 'response_too_large'));
  assert.equal(report.apiSurfaceVerified, false);
});
