// Explicitly bounded creation of NEW PRIVATE pilot drafts with the newly created
// organizer's ordinary session. No publication, role, SQL, processing or deletion
// endpoint is available here. A durable no-retry journal precedes every POST.
import {createHash} from 'node:crypto';
import {constants} from 'node:fs';
import {lstat, open, realpath} from 'node:fs/promises';
import {dirname, isAbsolute, join, resolve} from 'node:path';
import {isDeepStrictEqual} from 'node:util';
import {fileURLToPath} from 'node:url';
import {makePlan} from './plan.mjs';

const defaultRoot = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const fiveMinutes = 5 * 60 * 1000;
class Blocked extends Error {
  constructor(code) { super(code); this.code = code; }
}
const block = code => { throw new Blocked(code); };
function object(value) { return value !== null && typeof value === 'object' && !Array.isArray(value); }
function samePath(a, b) { return process.platform === 'win32' ? a.toLowerCase() === b.toLowerCase() : a === b; }

async function safePath(root, components, {directory = false} = {}) {
  if (typeof root !== 'string' || !isAbsolute(root)) block('project_root_invalid');
  let current = resolve(root);
  for (const component of ['', ...components]) {
    if (component) current = join(current, component);
    const stat = await lstat(current);
    const isLast = component === components.at(-1);
    if (stat.isSymbolicLink() || !samePath(await realpath(current), current) ||
        (isLast && !directory ? !stat.isFile() : !stat.isDirectory())) block('unsafe_local_input_path');
    if (isLast && !directory && stat.nlink !== 1) block('unsafe_local_input_file');
  }
  return current;
}
async function readInput(root, components, maxBytes, json = true) {
  const path = await safePath(root, components);
  const before = await lstat(path);
  if (before.size > maxBytes) block('local_input_too_large');
  const handle = await open(path, constants.O_RDONLY | (constants.O_NOFOLLOW ?? 0));
  try {
    const opened = await handle.stat();
    if (opened.dev !== before.dev || opened.ino !== before.ino || opened.nlink !== 1 || !opened.isFile()) {
      block('unsafe_local_input_file');
    }
    const bytes = await handle.readFile();
    if (bytes.length > maxBytes) block('local_input_too_large');
    return json ? JSON.parse(bytes.toString('utf8').replace(/^\uFEFF/, '')) : bytes;
  } finally { await handle.close(); }
}
function productionOrigin(value) {
  if (typeof value !== 'string' || !/^https:\/\/[a-z0-9]{20}\.supabase\.co\/?$/.test(value)) {
    block('production_origin_invalid');
  }
  return new URL(value).origin;
}
function publicKey(value, origin) {
  if (typeof value !== 'string' || value !== value.trim()) block('public_key_required');
  if (/^sb_publishable_[A-Za-z0-9_-]{20,}$/.test(value)) return value;
  if (!/^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/.test(value)) block('public_key_required');
  let payload;
  try { payload = JSON.parse(Buffer.from(value.split('.')[1], 'base64url').toString('utf8')); }
  catch { block('public_key_required'); }
  if (payload.role !== 'anon' || (payload.ref && payload.ref !== new URL(origin).hostname.split('.')[0])) {
    block('public_key_required');
  }
  return value;
}
function canonicalPlan(plan) {
  try {
    const scene = plan.tour.document.zones[0].scenes[0], point = scene.points[0];
    const reference = point.ar.reference_path.split('/')[2].replace(/\.jpg$/, '');
    const ids = [plan.accounts.owner.id, plan.accounts.visitor.id, plan.mission.id, plan.tour.id,
      plan.tour.document.zones[0].id, scene.id, point.id, reference, point.ar.reference_version];
    const canonical = makePlan({now: plan.generatedAt, runId: plan.runId, uuidFactory: () => ids.shift()});
    if (!isDeepStrictEqual(plan, canonical)) block('plan_modified_or_out_of_scope');
    return canonical;
  } catch (error) {
    if (error instanceof Blocked) throw error;
    block('plan_modified_or_out_of_scope');
  }
}
function accountFromJournal(account, planned, createdAt, now) {
  if (!object(account) || account.status !== 'created' || !uuid.test(account.userId ?? '') ||
      typeof account.email !== 'string') block('new_account_journal_required');
  const response = account.response?.user ?? account.response;
  if (!object(response) || response.id !== account.userId ||
      typeof response.email !== 'string' || response.email.toLowerCase() !== account.email.toLowerCase() ||
      !Array.isArray(response.identities) || response.identities.length === 0) block('new_account_signup_evidence_required');
  const accountCreated = Date.parse(response.created_at);
  if (!Number.isFinite(accountCreated) || accountCreated < createdAt - fiveMinutes || accountCreated > now + fiveMinutes) {
    block('account_not_created_during_this_run');
  }
  for (const field of ['full_name', 'username', 'user_type']) {
    if (response.user_metadata?.[field] !== planned.profile[field]) block('new_account_metadata_mismatch');
  }
  return {id: account.userId, email: account.email.toLowerCase(), response};
}
function sessionFromJournal(account, owner, origin, now) {
  const token = account.session?.access_token;
  if (typeof token !== 'string' || token.length > 16384 ||
      !/^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/.test(token)) block('owner_session_required');
  let claims;
  try { claims = JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString('utf8')); }
  catch { block('owner_session_invalid'); }
  if (claims.sub !== owner.id || claims.role !== 'authenticated' || claims.iss !== `${origin}/auth/v1` ||
      (claims.aud !== 'authenticated' && !(Array.isArray(claims.aud) && claims.aud.includes('authenticated'))) ||
      !Number.isFinite(claims.exp) || claims.exp * 1000 <= now + 60000) block('owner_session_invalid_or_expired');
  return {token, expiresAt: claims.exp * 1000};
}

async function jsonResponse(response) {
  const max = 2 * 1024 * 1024;
  if (Number(response.headers?.get('content-length')) > max) block('remote_response_too_large');
  const reader = response.body?.getReader();
  let text;
  if (reader) {
    const chunks = []; let total = 0;
    for (;;) {
      const chunk = await reader.read();
      if (chunk.done) break;
      total += chunk.value.byteLength;
      if (total > max) { await reader.cancel(); block('remote_response_too_large'); }
      chunks.push(Buffer.from(chunk.value));
    }
    text = Buffer.concat(chunks).toString('utf8');
  } else {
    text = await response.text();
    if (Buffer.byteLength(text) > max) block('remote_response_too_large');
  }
  try { return JSON.parse(text); }
  catch { block('remote_response_invalid'); }
}

export async function createTourAndMissionDrafts({
  projectRoot = defaultRoot, fetchImpl = globalThis.fetch, createNewDrafts = false,
  timeoutMs = 10000, now = Date.now(),
} = {}) {
  const report = {status: 'blocked', remotelyExecuted: false, createdIds: {}};
  const started = performance.now();
  let resourceHandle, resources, activeStep;
  const persist = async () => {
    const bytes = Buffer.from(`${JSON.stringify(resources, null, 2)}\n`);
    await resourceHandle.truncate(0);
    let offset = 0;
    while (offset < bytes.length) {
      const {bytesWritten} = await resourceHandle.write(bytes, offset, bytes.length - offset, offset);
      if (!bytesWritten) block('resource_journal_write_failed');
      offset += bytesWritten;
    }
    await resourceHandle.sync();
  };
  try {
    if (createNewDrafts !== true) block('explicit_new_drafts_flag_required');
    if (!Number.isInteger(timeoutMs) || timeoutMs < 1 || timeoutMs > 60000 ||
        !Number.isFinite(now) || typeof fetchImpl !== 'function') block('invalid_options');
    const config = await readInput(projectRoot, ['config', 'supabase.production.json'], 65536);
    const origin = productionOrigin(config.SUPABASE_URL);
    const key = publicKey(config.SUPABASE_ANON_KEY, origin);
    const plan = canonicalPlan(await readInput(projectRoot, ['outputs', 'ar-live-pilot', 'plan.json'], 1024 * 1024));
    const accounts = await readInput(projectRoot, ['.dart_tool', 'ar-live-pilot', 'accounts.json'], 1024 * 1024);
    const runCreated = Date.parse(accounts.createdAt);
    if (accounts.runId !== plan.runId || accounts.productionOrigin !== origin || !Number.isFinite(runCreated) ||
        runCreated > now + fiveMinutes) block('account_run_or_origin_mismatch');
    if (!Date.parse(plan.mission.starts_at) || Date.parse(plan.mission.starts_at) <= now) block('plan_mission_date_expired');
    const owner = accountFromJournal(accounts.accounts?.owner, plan.accounts.owner, runCreated, now);
    const visitor = accountFromJournal(accounts.accounts?.visitor, plan.accounts.visitor, runCreated, now);
    const proposedIds = [plan.accounts.owner.id, plan.accounts.visitor.id];
    if (owner.id === visitor.id || proposedIds.includes(owner.id) || proposedIds.includes(visitor.id)) block('real_new_auth_ids_required');
    const session = sessionFromJournal(accounts.accounts.owner, owner, origin, now);
    const jpeg = await readInput(projectRoot, ['outputs', 'ar-live-pilot', 'reference.jpg'], 20 * 1024 * 1024, false);
    if (jpeg.length < 4 || jpeg[0] !== 0xff || jpeg[1] !== 0xd8 ||
        jpeg[jpeg.length - 2] !== 0xff || jpeg[jpeg.length - 1] !== 0xd9) block('reference_jpeg_required');
    const originalReference = plan.tour.document.zones[0].scenes[0].points[0].ar.reference_path;
    const referencePath = `${owner.id}/references/${originalReference.split('/')[2]}`;
    const uploadPath = `/storage/v1/object/tour-assets/${referencePath}`;
    const allowed = new Set([
      'GET /auth/v1/user', 'GET /rest/v1/rpc/tours_get', 'GET /rest/v1/mission_drafts',
      `POST ${uploadPath}`, 'POST /rest/v1/rpc/tours_save', 'POST /rest/v1/rpc/save_mission_draft',
    ]);
    const request = async (method, path, {parameters = {}, body, binary = false} = {}) => {
      if (!allowed.has(`${method} ${path}`)) block('remote_operation_out_of_scope');
      if (session.expiresAt <= now + performance.now() - started + 5000) block('owner_session_invalid_or_expired');
      const url = new URL(path, origin);
      if (url.origin !== origin) block('remote_origin_mismatch');
      for (const [name, value] of Object.entries(parameters)) url.searchParams.set(name, value);
      const headers = {apikey: key, Authorization: `Bearer ${session.token}`, Accept: 'application/json'};
      if (body !== undefined) headers['Content-Type'] = binary ? 'image/jpeg' : 'application/json';
      if (binary) headers['x-upsert'] = 'false';
      const controller = new AbortController();
      let timer;
      const deadline = new Promise((_, reject) => {
        timer = setTimeout(() => { controller.abort(); reject(new Blocked('remote_timeout')); }, timeoutMs);
      });
      const operation = (async () => {
        report.remotelyExecuted = true;
        const response = await fetchImpl(url, {method, headers, redirect: 'manual',
          signal: controller.signal, ...(body !== undefined ? {body: binary ? body : JSON.stringify(body)} : {})});
        if (response.status >= 300 && response.status < 400) {
          await response.body?.cancel(); block('remote_redirect_rejected');
        }
        if (response.status < 200 || response.status >= 300) {
          await response.body?.cancel(); block('remote_request_rejected');
        }
        return jsonResponse(response);
      })();
      try { return await Promise.race([operation, deadline]); }
      finally { clearTimeout(timer); }
    };

    // All collision and identity checks precede the first upload or RPC write.
    const authenticated = await request('GET', '/auth/v1/user');
    if (authenticated?.id !== owner.id || typeof authenticated.email !== 'string' ||
        authenticated.email.toLowerCase() !== owner.email || !authenticated.email_confirmed_at ||
        authenticated.created_at !== owner.response.created_at ||
        (authenticated.role && authenticated.role !== 'authenticated')) block('authenticated_owner_mismatch_or_unconfirmed');
    for (const field of ['full_name', 'username', 'user_type']) {
      if (authenticated.user_metadata?.[field] !== plan.accounts.owner.profile[field]) block('authenticated_owner_metadata_mismatch');
    }
    const existingTour = await request('GET', '/rest/v1/rpc/tours_get', {
      parameters: {p_tour: plan.tour.id, p_edit: 'true'},
    });
    if (existingTour !== null) block('planned_tour_already_exists_or_unverified');
    const existingMission = await request('GET', '/rest/v1/mission_drafts', {
      parameters: {id: `eq.${plan.mission.id}`, select: 'id,author_id', limit: '1'},
    });
    if (!Array.isArray(existingMission) || existingMission.length !== 0) block('planned_mission_draft_already_exists_or_unverified');

    const privateDirectory = await safePath(projectRoot, ['.dart_tool', 'ar-live-pilot'], {directory: true});
    try {
      resourceHandle = await open(join(privateDirectory, 'resources.json'),
        constants.O_RDWR | constants.O_CREAT | constants.O_EXCL | (constants.O_NOFOLLOW ?? 0), 0o600);
    } catch { block('resource_journal_exists_or_unavailable_no_retry'); }
    resources = {version: 1, runId: plan.runId, productionOrigin: origin,
      createdAt: new Date(now).toISOString(), ownerId: owner.id, status: 'reserved',
      tourId: plan.tour.id, missionDraftId: plan.mission.id,
      reference: {bucket: 'tour-assets', path: referencePath,
        referenceVersion: plan.tour.document.zones[0].scenes[0].points[0].ar.reference_version,
        sha256: createHash('sha256').update(jpeg).digest('hex')},
      steps: {referenceUpload: 'not_started', tourDraft: 'not_started', missionDraft: 'not_started'}};
    await persist();
    const post = async (step, path, options, validate) => {
      activeStep = step;
      resources.status = 'creating_private_drafts';
      resources.steps[step] = 'in_flight';
      await persist();
      const value = await request('POST', path, options);
      if (!validate(value)) block('creation_response_mismatch');
      resources.steps[step] = 'created';
      await persist();
      activeStep = null;
      return value;
    };
    await post('referenceUpload', uploadPath, {body: jpeg, binary: true}, value =>
      value?.Key === `tour-assets/${referencePath}` || value?.Key === referencePath ||
      value?.key === `tour-assets/${referencePath}` || value?.key === referencePath);
    const document = structuredClone(plan.tour.document);
    document.zones[0].scenes[0].points[0].ar.reference_path = referencePath;
    await post('tourDraft', '/rest/v1/rpc/tours_save', {body: {
      p_tour: plan.tour.id, p_title: plan.tour.title, p_space: plan.tour.space, p_document: document,
    }}, value => value?.id === plan.tour.id && value?.owner_id === owner.id && value?.state === 'draft' && value?.public_revision_id == null);
    report.createdIds.tourId = plan.tour.id;
    const {id: ignoredId, author_id: ignoredAuthor, status: ignoredStatus, ...missionInput} = plan.mission;
    await post('missionDraft', '/rest/v1/rpc/save_mission_draft', {body: {
      draft_id: plan.mission.id, draft_input: missionInput,
    }}, value => value === plan.mission.id);
    report.createdIds.missionDraftId = plan.mission.id;
    resources.status = 'created_private_drafts';
    await persist();
    report.status = 'created_private_drafts';
    return report;
  } catch (error) {
    report.reason = error instanceof Blocked ? error.code : 'local_or_remote_operation_failed';
    if (resourceHandle && resources) {
      report.status = 'partial_or_uncertain_no_retry';
      resources.status = 'partial_or_uncertain_no_retry';
      resources.reason = report.reason;
      if (activeStep) resources.steps[activeStep] = 'failed_or_uncertain';
      try { await persist(); } catch { /* Keep the existing exclusive journal; never retry writes. */ }
    }
    return report;
  } finally { await resourceHandle?.close(); }
}

if (process.argv[1] && samePath(resolve(process.argv[1]), fileURLToPath(import.meta.url))) {
  const enabled = process.argv.length === 3 && process.argv[2] === '--create-new-drafts';
  const report = await createTourAndMissionDrafts({createNewDrafts: enabled});
  process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
  process.exitCode = report.status === 'created_private_drafts' ? 0 : 1;
}
