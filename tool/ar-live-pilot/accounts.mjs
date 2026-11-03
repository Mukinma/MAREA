// Explicitly authorized creation of TWO new ordinary pilot accounts only.
// No admin APIs, updates, deletes, resend, sign-in or automatic retries.
import {randomBytes} from 'node:crypto';
import {constants} from 'node:fs';
import {lstat, mkdir, open, realpath} from 'node:fs/promises';
import {dirname, isAbsolute, join, parse, relative, resolve, sep} from 'node:path';
import {fileURLToPath} from 'node:url';

const defaultRoot = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
export {readJson as readPilotJson, productionConfig as readPublicProductionConfig};
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const actors = ['owner', 'visitor'];
const knownAuthErrors = new Set([
  'user_already_exists', 'email_exists', 'email_address_invalid',
  'email_address_not_authorized', 'over_email_send_rate_limit',
  'over_request_rate_limit', 'weak_password', 'validation_failed',
  'signup_disabled', 'email_provider_disabled', 'hook_timeout',
]);

function object(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function samePath(left, right) {
  return process.platform === 'win32' ? left.toLowerCase() === right.toLowerCase() : left === right;
}

function sameFile(left, right) {
  return left.ino === right.ino && left.dev === right.dev;
}

async function safePath(path, kind) {
  let current = parse(path).root;
  const components = relative(current, path).split(sep);
  let result;
  for (let index = 0; index < components.length; index++) {
    current = join(current, components[index]);
    result = await lstat(current, {bigint: true});
    const directory = index < components.length - 1 || kind === 'directory';
    if (result.isSymbolicLink() || (directory ? !result.isDirectory() : !result.isFile())) {
      throw new Error('unsafe_path');
    }
  }
  if (!samePath(await realpath(path), path) || (kind === 'file' && result.nlink !== 1n)) {
    throw new Error('unsafe_path');
  }
  return result;
}

async function readJson(root, components) {
  const path = join(root, ...components);
  const before = await safePath(path, 'file');
  if (before.size > 128n * 1024n) throw new Error('file_too_large');
  const handle = await open(path, constants.O_RDONLY | (constants.O_NOFOLLOW ?? 0));
  try {
    const opened = await handle.stat({bigint: true});
    if (!sameFile(before, opened)) throw new Error('unsafe_path');
    const source = await handle.readFile('utf8');
    const after = await safePath(path, 'file');
    if (!sameFile(opened, after) || Buffer.byteLength(source) > 128 * 1024) {
      throw new Error('unsafe_path');
    }
    return JSON.parse(source.replace(/^\uFEFF/, ''));
  } finally {
    await handle.close();
  }
}

function productionConfig(value) {
  if (!object(value) || typeof value.SUPABASE_URL !== 'string' ||
      !/^https:\/\/[a-z0-9]{20}\.supabase\.co\/?$/.test(value.SUPABASE_URL)) {
    return null;
  }
  const origin = new URL(value.SUPABASE_URL).origin;
  const key = value.SUPABASE_ANON_KEY;
  if (typeof key !== 'string' || key.length > 16384) return null;
  if (/^sb_publishable_[A-Za-z0-9_-]{20,}$/.test(key)) return {origin, key};
  if (!/^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/.test(key)) return null;
  try {
    const payload = JSON.parse(Buffer.from(key.split('.')[1], 'base64url').toString('utf8'));
    if (!object(payload) || payload.role !== 'anon' ||
        (payload.ref !== undefined && payload.ref !== new URL(origin).hostname.split('.')[0])) return null;
    return {origin, key};
  } catch { return null; }
}

function validPlan(value, now) {
  if (!object(value) || value.version !== 1 || value.mode !== 'offline_preview' ||
      value.remotelyExecuted !== false || value.titlePrefix !== 'Prueba RA MAREA' ||
      typeof value.runId !== 'string' || !/^[a-z0-9][a-z0-9-]{0,19}$/.test(value.runId) ||
      !object(value.scope) || value.scope.target !== 'existing_production_new_test_records_only' ||
      value.scope.allowExistingRecordUpdates !== false || value.scope.allowExistingRecordDeletes !== false ||
      value.scope.allowAdministratorCreation !== false || value.scope.allowRoleChanges !== false ||
      value.scope.allowDeployment !== false || value.scope.mustRebindAccountIdsAfterSignup !== true ||
      !object(value.accounts) || Object.keys(value.accounts).sort().join(',') !== 'owner,visitor' ||
      !object(value.mission) || Date.parse(value.mission.starts_at) <= now ||
      !Number.isFinite(Date.parse(value.mission.starts_at))) return false;
  const identifiers = new Set();
  for (const actor of actors) {
    const account = value.accounts[actor], expectedType = actor === 'owner' ? 'Negocio' : 'Usuario general';
    if (!object(account) || typeof account.id !== 'string' || !uuid.test(account.id) ||
        identifiers.has(account.id.toLowerCase()) || account.identityStatus !== 'proposed_offline_not_created' ||
        Object.keys(account).some(key => !['id', 'identityStatus', 'profile'].includes(key)) ||
        !object(account.profile)) return false;
    const profile = account.profile;
    if (Object.keys(profile).some(key => !['full_name', 'username', 'user_type', 'bio'].includes(key)) ||
        typeof profile.full_name !== 'string' || !profile.full_name.startsWith('Prueba RA MAREA') ||
        profile.full_name.length > 80 || !/^[a-z0-9._]{3,24}$/.test(profile.username ?? '') ||
        !profile.username.startsWith(actor === 'owner' ? 'pra_o_' : 'pra_v_') ||
        profile.user_type !== expectedType) return false;
    identifiers.add(account.id.toLowerCase());
  }
  return value.accounts.owner.profile.username !== value.accounts.visitor.profile.username;
}

function aliases(mailbox, runId) {
  if (typeof mailbox !== 'string' || mailbox !== mailbox.trim() || mailbox.length > 254 ||
      !/^[a-z0-9._+-]+@[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?\.[a-z]{2,}$/i.test(mailbox)) return null;
  const [local, domain] = mailbox.toLowerCase().split('@');
  const base = local.split('+')[0];
  if (!base || base.startsWith('.') || base.endsWith('.') || base.includes('..') || domain.includes('..')) return null;
  const result = {};
  for (const actor of actors) {
    const address = `${base}+pra_${runId.replaceAll('-', '_')}_${actor === 'owner' ? 'o' : 'v'}@${domain}`;
    if (address.split('@')[0].length > 64 || address.length > 254) return null;
    result[actor] = address;
  }
  return result;
}

function policyVersions(value) {
  if (!object(value) || value.signup_enabled !== true) return null;
  for (const document of [value.terms, value.privacy]) {
    if (!object(document) || typeof document.version !== 'string' || !document.version.trim() ||
        document.version.length > 128 || typeof document.body !== 'string' || !document.body.trim()) return null;
  }
  return {termsVersion: value.terms.version, privacyVersion: value.privacy.version};
}

async function jsonResponse(response) {
  const limit = 512 * 1024;
  const advertised = response.headers?.get('content-length');
  if (advertised && Number(advertised) > limit) throw new Error('response_too_large');
  let source;
  if (response.body?.getReader) {
    const reader = response.body.getReader(), chunks = [];
    let bytes = 0;
    for (;;) {
      const result = await reader.read();
      if (result.done) break;
      bytes += result.value.byteLength;
      if (bytes > limit) {
        await reader.cancel();
        throw new Error('response_too_large');
      }
      chunks.push(Buffer.from(result.value));
    }
    source = Buffer.concat(chunks).toString('utf8');
  } else {
    source = await response.text();
    if (Buffer.byteLength(source) > limit) throw new Error('response_too_large');
  }
  return JSON.parse(source);
}

async function request({origin, key, path, method, body, fetchImpl, timeoutMs}) {
  const allowed = (method === 'GET' && ['/rest/v1/rpc/registration_policy', '/auth/v1/settings'].includes(path)) ||
    (method === 'POST' && path === '/auth/v1/signup');
  const url = new URL(path, origin);
  if (!allowed || url.origin !== origin) return {ok: false, errorCode: 'request_blocked'};
  const controller = new AbortController();
  let timer;
  const deadline = new Promise(resolveTimeout => {
    timer = setTimeout(() => {
      controller.abort();
      resolveTimeout({ok: false, errorCode: 'timeout'});
    }, timeoutMs);
  });
  const operation = (async () => {
    try {
      const response = await fetchImpl(url, {
        method, redirect: 'manual', signal: controller.signal,
        headers: {apikey: key, 'Content-Type': 'application/json', Accept: 'application/json'},
        ...(body ? {body: JSON.stringify(body)} : {}),
      });
      if (response.status >= 300 && response.status < 400) {
        await response.body?.cancel();
        return {ok: false, errorCode: 'redirect_rejected'};
      }
      const value = await jsonResponse(response);
      return {ok: response.status >= 200 && response.status < 300, value, status: response.status,
        ...(!(response.status >= 200 && response.status < 300) ? {errorCode: 'http_rejected'} : {})};
    } catch {
      return {ok: false, errorCode: controller.signal.aborted ? 'timeout' : 'network_or_response_error'};
    }
  })();
  try { return await Promise.race([operation, deadline]); }
  finally { clearTimeout(timer); }
}

async function journalFile(root, journal) {
  let directory = root;
  await safePath(root, 'directory');
  for (const component of ['.dart_tool', 'ar-live-pilot']) {
    directory = join(directory, component);
    try { await mkdir(directory, {mode: 0o700}); }
    catch (error) { if (error.code !== 'EEXIST') throw error; }
    await safePath(directory, 'directory');
  }
  const path = join(directory, 'accounts.json');
  // Existing journals are never adopted, overwritten or used for retries.
  const handle = await open(path, constants.O_RDWR | constants.O_CREAT | constants.O_EXCL |
    (constants.O_NOFOLLOW ?? 0), 0o600);
  const identity = await handle.stat({bigint: true});
  async function persist() {
    const current = await safePath(path, 'file');
    if (!sameFile(current, identity)) throw new Error('journal_changed');
    const bytes = Buffer.from(`${JSON.stringify(journal, null, 2)}\n`);
    let written = 0;
    while (written < bytes.length) {
      const result = await handle.write(bytes, written, bytes.length - written, written);
      if (!result.bytesWritten) throw new Error('journal_write_failed');
      written += result.bytesWritten;
    }
    await handle.truncate(bytes.length);
    await handle.sync();
  }
  try { await persist(); }
  catch (error) { await handle.close(); throw error; }
  return {persist, close: () => handle.close()};
}

function accountReport(actor, account) {
  return {
    actor, status: account.status, newUserId: account.userId ?? null,
    confirmNeeded: account.confirmNeeded ?? null,
    ...(account.errorCode ? {errorCode: account.errorCode} : {}),
  };
}

function result(status, accounts = {}, errorCode) {
  return {
    status,
    ...(errorCode ? {errorCode} : {}),
    accounts: actors.map(actor => accountReport(actor, accounts[actor] ?? {status: 'not_attempted'})),
  };
}

function verifiedNewUser(response, email, previousUserIds) {
  if (!object(response)) return null;
  const user = object(response.user) ? response.user : response;
  if (!object(user) || typeof user.id !== 'string' || !uuid.test(user.id) ||
      user.email !== email || !Array.isArray(user.identities) || user.identities.length === 0 ||
      previousUserIds.has(user.id.toLowerCase()) ||
      (user.role !== undefined && user.role !== 'authenticated') ||
      user.app_metadata?.role === 'admin' || user.app_metadata?.role === 'service_role' ||
      user.user_metadata?.role !== undefined) return null;
  if (user.identities.some(identity => !object(identity) || identity.provider !== 'email' ||
      (identity.user_id !== undefined && identity.user_id !== user.id) ||
      (identity.identity_data?.email !== undefined && identity.identity_data.email !== email))) return null;
  return user;
}

/** Returns redacted status only. Credentials and server responses stay private. */
export async function provisionAccounts({
  projectRoot = defaultRoot, mailbox, fetchImpl = globalThis.fetch,
  createNewAccounts = false, timeoutMs = 20000,
} = {}) {
  if (createNewAccounts !== true) return result('blocked', {}, 'explicit_create_flag_required');
  if (typeof projectRoot !== 'string' || !isAbsolute(projectRoot) || /^(?:\\\\|\/\/)/.test(projectRoot) ||
      typeof fetchImpl !== 'function' || !Number.isInteger(timeoutMs) || timeoutMs < 1 || timeoutMs > 60000) {
    return result('blocked', {}, 'invalid_options');
  }
  let config, plan;
  try {
    config = productionConfig(await readJson(projectRoot, ['config', 'supabase.production.json']));
    plan = await readJson(projectRoot, ['outputs', 'ar-live-pilot', 'plan.json']);
  } catch { return result('blocked', {}, 'configuration_or_plan_unavailable'); }
  if (!config) return result('blocked', {}, 'public_production_config_required');
  if (!validPlan(plan, Date.now())) return result('blocked', {}, 'plan_invalid');
  const emails = aliases(mailbox, plan.runId);
  if (!emails) return result('blocked', {}, 'controlled_mailbox_required');
  const baseRequest = {...config, fetchImpl, timeoutMs};
  const policy = await request({...baseRequest, path: '/rest/v1/rpc/registration_policy', method: 'GET'});
  if (!policy.ok) return result('blocked', {}, policy.errorCode);
  const versions = policyVersions(policy.value);
  if (!versions) return result('blocked', {}, 'registration_policy_not_ready');
  const settings = await request({...baseRequest, path: '/auth/v1/settings', method: 'GET'});
  if (!settings.ok) return result('blocked', {}, settings.errorCode);
  if (!object(settings.value) || settings.value.disable_signup !== false || settings.value.external?.email !== true) {
    return result('blocked', {}, 'email_signup_not_enabled');
  }
  const journal = {
    version: 1, runId: plan.runId, productionOrigin: config.origin,
    createdAt: new Date().toISOString(), policy: versions,
    accounts: Object.fromEntries(actors.map(actor => [actor, {
      email: emails[actor], password: randomBytes(32).toString('base64url'),
      userId: null, status: 'not_attempted', attempted: false,
      proposedId: plan.accounts[actor].id,
      profile: {
        full_name: plan.accounts[actor].profile.full_name,
        username: plan.accounts[actor].profile.username,
        user_type: plan.accounts[actor].profile.user_type,
      },
      response: null,
    }])),
  };
  let file;
  try { file = await journalFile(projectRoot, journal); }
  catch { return result('blocked', {}, 'journal_exists_or_unsafe'); }
  const returnedUserIds = new Set();
  try {
    for (const actor of actors) {
      const account = journal.accounts[actor];
      account.attempted = true;
      account.attemptedAt = new Date().toISOString();
      account.status = 'attempted';
      // A completed, synced journal entry is mandatory before each POST.
      await file.persist();
      const response = await request({
        ...baseRequest, path: '/auth/v1/signup', method: 'POST', body: {
          email: account.email, password: account.password,
          data: {...account.profile, registration_flow: 'minimal-v1',
            terms_version: versions.termsVersion, privacy_version: versions.privacyVersion,
            adult_confirmed: true, accepted_terms: true},
        },
      });
      account.response = response.value ?? null;
      if (!response.ok) {
        account.status = 'blocked_after_attempt';
        const authCode = response.value?.code ?? response.value?.error_code;
        account.errorCode = knownAuthErrors.has(authCode) ? authCode : response.errorCode;
        await file.persist();
        return result('incomplete', journal.accounts, account.errorCode);
      }
      const user = verifiedNewUser(response.value, account.email, returnedUserIds);
      if (!user) {
        account.status = 'blocked_after_attempt';
        account.errorCode = 'new_identity_not_verified';
        await file.persist();
        return result('incomplete', journal.accounts, account.errorCode);
      }
      returnedUserIds.add(user.id.toLowerCase());
      account.userId = user.id;
      account.status = 'created';
      account.confirmNeeded = !(user.email_confirmed_at || user.confirmed_at);
      await file.persist();
    }
    return result('created', journal.accounts);
  } catch {
    // Do not retry an ambiguous request or continue to the other actor.
    return result('incomplete', journal.accounts, 'journal_or_request_interrupted');
  } finally {
    // All authoritative writes were synced by persist(). A close error must
    // not expose an unredacted OS exception through the library API.
    await file.close().catch(() => {});
  }
}

if (process.argv[1] && samePath(resolve(process.argv[1]), fileURLToPath(import.meta.url))) {
  let mailbox, createNewAccounts = false, invalid = false;
  const arguments_ = process.argv.slice(2);
  for (let index = 0; index < arguments_.length; index++) {
    if (arguments_[index] === '--create-new-accounts' && !createNewAccounts) createNewAccounts = true;
    else if (arguments_[index] === '--mailbox' && mailbox === undefined) mailbox = arguments_[++index];
    else invalid = true;
  }
  let report;
  try {
    report = invalid ? result('blocked', {}, 'unsupported_arguments') :
      await provisionAccounts({mailbox, createNewAccounts});
  } catch { report = result('blocked', {}, 'operation_blocked'); }
  process.stdout.write(`${JSON.stringify(report)}\n`);
  process.exitCode = report.status === 'created' ? 0 : 1;
}
