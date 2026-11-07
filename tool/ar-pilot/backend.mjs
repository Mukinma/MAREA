// Read-only, supplementary API preflight. It never replaces backend_contract.sql,
// checks RLS isolation, creates fixtures, reports AR tests or publishes content.
import {fileURLToPath} from 'node:url';
import {resolve} from 'node:path';
import {loadValidatedDevelopmentConfig} from './config.mjs';

const syntheticId = '00000000-0000-0000-0000-000000000000';
const defaultRoot = fileURLToPath(new URL('../../', import.meta.url));
const maximumBodyBytes = 4 * 1024 * 1024;

// Write operations are inspected only as OpenAPI metadata. No request ever uses
// their routes. GET RPCs below also execute in PostgREST read-only transactions.
export const pilotRpcContract = Object.freeze([
  {name: 'registration_policy', method: 'get', parameters: []},
  {name: 'list_missions', method: 'get', parameters: ['author_filter', 'mission_filter', 'scope_filter', 'page_offset']},
  {name: 'list_map_missions', method: 'get', parameters: ['south', 'west', 'north', 'east', 'query_text']},
  {name: 'tours_public_list', method: 'get', parameters: ['p_owner']},
  {name: 'tours_get', method: 'get', parameters: ['p_tour', 'p_edit']},
  {name: 'tours_save', method: 'post', parameters: ['p_tour', 'p_title', 'p_space', 'p_document']},
  {name: 'tours_submit', method: 'post', parameters: ['p_tour']},
  {name: 'tours_ar_report_test', method: 'post', parameters: ['p_tour', 'p_point', 'p_reference_version', 'p_platform', 'p_tracking_seconds']},
  {name: 'create_mission', method: 'post', parameters: ['mission_input']},
  {name: 'complete_initial_profile', method: 'post', parameters: ['profile_type', 'selected_interests', 'selected_goals']},
  {name: 'accept_current_legal', method: 'post', parameters: ['terms', 'privacy', 'adult']},
]);

const visibleRelationContract = [
  {name: 'profiles', fields: ['id', 'user_type', 'initial_profile_completed_at']},
  {name: 'legal_acceptances', fields: ['user_id', 'terms_version', 'privacy_version']},
];

const readProbes = [
  {name: 'registration_policy', parameters: {}, shape: 'legal_policy'},
  {name: 'tours_public_list', parameters: {p_owner: syntheticId}, shape: 'array'},
  {name: 'tours_get', parameters: {p_tour: syntheticId, p_edit: 'false'}, shape: 'null'},
  {name: 'list_missions', parameters: {
    author_filter: syntheticId, mission_filter: syntheticId,
    scope_filter: 'discover', page_offset: '0',
  }, shape: 'array'},
  {name: 'list_map_missions', parameters: {
    south: '85.00001', north: '85.00002', west: '-179.00002', east: '-179.00001',
    query_text: '__marea_ar_preflight_no_content__',
  }, shape: 'map_page'},
];
const allowedReadPaths = new Set(['/rest/v1/', ...readProbes.map(probe => `/rest/v1/rpc/${probe.name}`)]);
const knownErrors = new Set(['PGRST202', 'PGRST204', 'PGRST301', 'PGRST302', '42501', '25006', '42883']);

function reportSkeleton(now) {
  return {
    version: 1,
    checkedAt: new Date(now).toISOString(),
    status: 'incomplete',
    target: 'unverified',
    actor: 'anonymous',
    apiSurfaceVerified: false,
    rlsVerified: false,
    publicationVerified: false,
    physicalARVerified: false,
    checks: [],
    limitations: [
      'api_metadata_and_read_shapes_only',
      'missing_openapi_paths_may_be_hidden_by_role',
      'no_user_isolation_or_storage_permissions_tested',
      'no_migration_history_or_sql_function_bodies_verified',
      'no_account_creation_or_publication_or_physical_ar_tested',
    ],
  };
}

function validUserToken(token, base, now) {
  if (typeof token !== 'string' || token.length > 16384 ||
      !/^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/.test(token)) return false;
  try {
    const claims = JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString('utf8'));
    return claims.role === 'authenticated' &&
      claims.iss === `${base.origin}/auth/v1` &&
      /^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$/i.test(claims.sub ?? '') &&
      Number.isFinite(claims.exp) && claims.exp * 1000 > now &&
      (claims.aud === 'authenticated' ||
        (Array.isArray(claims.aud) && claims.aud.includes('authenticated')));
  } catch { return false; }
}

async function boundedJson(response) {
  const contentLength = response.headers?.get('content-length');
  if (contentLength !== null && contentLength !== undefined && Number(contentLength) > maximumBodyBytes) {
    await response.body?.cancel();
    return {kind: 'response_too_large'};
  }
  let text;
  if (response.body?.getReader) {
    const reader = response.body.getReader();
    const chunks = [];
    let bytes = 0;
    for (;;) {
      const chunk = await reader.read();
      if (chunk.done) break;
      bytes += chunk.value.byteLength;
      if (bytes > maximumBodyBytes) {
        await reader.cancel();
        return {kind: 'response_too_large'};
      }
      chunks.push(Buffer.from(chunk.value));
    }
    text = Buffer.concat(chunks).toString('utf8');
  } else {
    text = await response.text();
    if (Buffer.byteLength(text) > maximumBodyBytes) return {kind: 'response_too_large'};
  }
  try { return {kind: 'json', value: JSON.parse(text)}; }
  catch { return {kind: 'invalid_json'}; }
}

async function readJson({base, path, parameters = {}, key, userToken, fetchImpl, timeoutMs, openapi = false}) {
  // No server-provided URLs, references, spec.servers or redirects are followed.
  const url = new URL(path, base);
  if (url.origin !== base.origin || !allowedReadPaths.has(url.pathname) || url.username || url.password) {
    return {kind: 'request_blocked'};
  }
  for (const [name, value] of Object.entries(parameters)) url.searchParams.set(name, value);
  const controller = new AbortController();
  let timer;
  const deadline = new Promise(resolveTimeout => {
    timer = setTimeout(() => {
      controller.abort();
      resolveTimeout({kind: 'timeout'});
    }, timeoutMs);
  });
  const operation = (async () => {
    try {
      const headers = {apikey: key, Accept: openapi ? 'application/openapi+json' : 'application/json'};
      if (userToken) headers.Authorization = `Bearer ${userToken}`;
      const response = await fetchImpl(url, {
        method: 'GET', redirect: 'manual', headers, signal: controller.signal,
      });
      if (response.status >= 300 && response.status < 400) {
        await response.body?.cancel();
        return {kind: 'redirect_rejected', status: response.status};
      }
      const body = await boundedJson(response);
      return {...body, status: response.status};
    } catch {
      return {kind: controller.signal.aborted ? 'timeout' : 'network_error'};
    }
  })();
  try { return await Promise.race([operation, deadline]); }
  finally { clearTimeout(timer); }
}

function httpEvidence(id, response) {
  const result = {id, status: 'unverified', evidence: response.kind};
  if (Number.isInteger(response.status)) result.httpStatus = response.status;
  const code = response.value?.code;
  if (knownErrors.has(code)) result.errorCode = code;
  if (response.kind !== 'json') return result;
  if (response.status === 401 || response.status === 403 || code === '42501') {
    result.evidence = 'authorization_required_or_denied';
  } else if (code === 'PGRST202' || code === '42883') {
    result.status = 'failed';
    result.evidence = 'rpc_missing_or_signature_unavailable';
  } else if (response.status === 405 || code === '25006') {
    result.status = 'failed';
    result.evidence = 'read_only_get_not_supported';
  } else if (response.status < 200 || response.status >= 300) {
    result.evidence = 'http_error';
  }
  return result;
}

function resolveLocalSchema(document, schema) {
  if (!schema || typeof schema !== 'object') return null;
  if (!schema.$ref) return schema;
  if (typeof schema.$ref !== 'string' || !schema.$ref.startsWith('#/')) return null;
  let value = document;
  for (const part of schema.$ref.slice(2).split('/')) value = value?.[part.replaceAll('~1', '/').replaceAll('~0', '~')];
  return value && typeof value === 'object' && !value.$ref ? value : null;
}

function operationParameters(document, path, operation) {
  const names = new Set();
  for (const parameter of [
    ...(Array.isArray(path.parameters) ? path.parameters : []),
    ...(Array.isArray(operation.parameters) ? operation.parameters : []),
  ]) {
    const resolved = resolveLocalSchema(document, parameter);
    if (!resolved) continue;
    if (resolved.in === 'query' && typeof resolved.name === 'string') names.add(resolved.name);
    const schema = resolveLocalSchema(document, resolved.schema);
    if (resolved.in === 'body' && schema?.properties) Object.keys(schema.properties).forEach(name => names.add(name));
  }
  const requestBody = resolveLocalSchema(document, operation.requestBody);
  const bodySchema = resolveLocalSchema(document, requestBody?.content?.['application/json']?.schema);
  if (bodySchema?.properties) Object.keys(bodySchema.properties).forEach(name => names.add(name));
  return names;
}

function inspectOpenApi(response) {
  const root = httpEvidence('openapi', response);
  if (response.kind !== 'json' || response.status !== 200 ||
      !response.value || typeof response.value.paths !== 'object' || !response.value.paths || Array.isArray(response.value.paths) ||
      !(response.value.swagger === '2.0' || /^3\./.test(response.value.openapi ?? ''))) {
    if (response.kind === 'json' && response.status === 200) root.evidence = 'invalid_openapi_document';
    return [root];
  }
  root.status = 'verified';
  root.evidence = 'role_scoped_openapi_observed';
  const document = response.value;
  const checks = [root];
  for (const contract of pilotRpcContract) {
    const path = document.paths[`/rpc/${contract.name}`];
    // Some generators document a VOLATILE reader only under POST. Its signature
    // can be inspected there without invoking POST; a separate GET probe below
    // still has to succeed before the API surface is marked checked.
    const signatureViaPost = contract.method === 'get' && !path?.get && Boolean(path?.post);
    const operation = signatureViaPost ? path.post : path?.[contract.method];
    if (!operation) {
      checks.push({id: `rpc:${contract.name}`, status: 'unverified', evidence: 'not_visible_in_role_scoped_openapi'});
      continue;
    }
    const names = operationParameters(document, path, operation);
    const missing = contract.parameters.filter(name => !names.has(name));
    checks.push({id: `rpc:${contract.name}`, status: missing.length ? 'failed' : 'verified',
      evidence: missing.length ? 'openapi_parameters_mismatch'
        : signatureViaPost ? 'openapi_post_signature_observed_get_probed_separately'
        : 'openapi_method_and_parameters_observed',
      ...(missing.length ? {missingParameters: missing} : {}),
    });
  }
  for (const relation of visibleRelationContract) {
    const schema = document.definitions?.[relation.name] ?? document.components?.schemas?.[relation.name];
    const names = Object.keys(resolveLocalSchema(document, schema)?.properties ?? {});
    checks.push({id: `schema:${relation.name}`, status: relation.fields.every(name => names.includes(name)) ? 'verified' : 'unverified',
      evidence: relation.fields.every(name => names.includes(name)) ? 'openapi_columns_observed' : 'schema_columns_not_visible_or_incomplete'});
  }
  // legal_documents and registration_settings intentionally have no public SELECT.
  checks.push({id: 'schema:legal_documents', status: 'unverified', evidence: 'private_relation_not_inspectable_via_public_api'});
  return checks;
}

function documentReady(value) {
  return value && typeof value.version === 'string' && value.version.trim() &&
    typeof value.title === 'string' && value.title.trim() &&
    typeof value.body === 'string' && value.body.trim();
}

function inspectRead(probe, response, authenticated) {
  const result = httpEvidence(`read:${probe.name}`, response);
  if (response.kind !== 'json' || response.status < 200 || response.status >= 300) return result;
  if (!authenticated && probe.name !== 'registration_policy') {
    result.status = 'failed';
    result.evidence = 'authenticated_rpc_readable_without_user_token';
    return result;
  }
  const value = response.value;
  const valid = probe.shape === 'array' ? Array.isArray(value)
    : probe.shape === 'null' ? value === null
    : probe.shape === 'map_page' ? value && Array.isArray(value.missions) && Number.isInteger(value.total) && value.total >= 0
    : value && typeof value.signup_enabled === 'boolean' && 'terms' in value && 'privacy' in value;
  result.status = valid ? 'verified' : 'failed';
  result.evidence = valid ? `read_only_get_${probe.shape}_observed` : 'unexpected_read_response_shape';
  if (valid && probe.shape === 'legal_policy') {
    result.registrationEnabled = value.signup_enabled;
    result.legalDocumentsReady = Boolean(documentReady(value.terms) && documentReady(value.privacy));
    if (!result.registrationEnabled || !result.legalDocumentsReady) {
      result.status = 'failed';
      result.evidence = 'registration_closed_or_legal_documents_unavailable';
    }
  }
  return result;
}

export async function checkDevelopmentBackend({
  projectRoot = defaultRoot, fetchImpl = globalThis.fetch, timeoutMs = 10000,
  userToken, now = Date.now(),
} = {}) {
  const report = reportSkeleton(now);
  if (!Number.isInteger(timeoutMs) || timeoutMs < 1 || timeoutMs > 60000 || typeof fetchImpl !== 'function') {
    report.status = 'blocked';
    report.checks.push({id: 'options', status: 'failed', evidence: 'invalid_request_options'});
    return report;
  }
  let loaded;
  try { loaded = await loadValidatedDevelopmentConfig({projectRoot}); }
  catch {
    report.status = 'blocked';
    report.checks.push({id: 'config', status: 'failed', evidence: 'development_config_unavailable'});
    return report;
  }
  if (!loaded.report.ok || !loaded.config) {
    report.status = 'blocked';
    report.checks.push({id: 'config', status: 'failed', evidence: 'development_config_rejected',
      reasons: (loaded.report.reasons ?? []).filter(reason => typeof reason === 'string' && /^[a-z0-9_]+$/.test(reason))});
    return report;
  }
  const base = new URL(loaded.config.SUPABASE_URL);
  report.target = base.protocol === 'https:' ? 'development' : 'local';
  report.checks.push({id: 'config', status: 'verified', evidence: 'development_target_validated_against_production'});
  if (userToken !== undefined && !validUserToken(userToken, base, now)) {
    report.status = 'blocked';
    report.checks.push({id: 'actor', status: 'failed', evidence: 'invalid_or_foreign_or_privileged_user_token'});
    return report;
  }
  report.actor = userToken ? 'authenticated_user' : 'anonymous';
  const options = {base, key: loaded.config.SUPABASE_ANON_KEY, userToken, fetchImpl, timeoutMs};
  const spec = await readJson({...options, path: '/rest/v1/', openapi: true});
  report.checks.push(...inspectOpenApi(spec));
  for (const probe of readProbes) {
    const response = await readJson({...options, path: `/rest/v1/rpc/${probe.name}`, parameters: probe.parameters});
    report.checks.push(inspectRead(probe, response, Boolean(userToken)));
  }
  const required = report.checks.filter(check => check.id !== 'schema:legal_documents');
  report.apiSurfaceVerified = required.every(check => check.status === 'verified');
  report.status = report.apiSurfaceVerified ? 'api_checked' : 'incomplete';
  return report;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const report = await checkDevelopmentBackend({userToken: process.env.MAREA_AR_PILOT_USER_TOKEN});
  process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
  process.exitCode = report.apiSurfaceVerified ? 0 : 1;
}
