// Confirm only the newly created pilot identities. No admin, existing account,
// publication, cleanup or arbitrary endpoint is accepted by this module.
import {constants} from 'node:fs';
import {open, lstat} from 'node:fs/promises';
import {join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {readPilotJson, readPublicProductionConfig} from './accounts.mjs';

const root = fileURLToPath(new URL('../../', import.meta.url));
const actors = ['owner', 'visitor'];
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const errors = new Set(['otp_expired', 'otp_disabled', 'email_not_confirmed', 'over_request_rate_limit', 'validation_failed']);
function result(status, checks = []) { return {status, accounts: checks}; }
function claims(token) {
  try { return JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString('utf8')); }
  catch { return null; }
}
async function request(base, key, path, {token, body, fetchImpl}) {
  try {
    const response = await fetchImpl(new URL(path, base), {
      method: body ? 'POST' : 'GET', redirect: 'manual', signal: AbortSignal.timeout(15000),
      headers: {apikey: key, 'Content-Type': 'application/json', ...(token ? {Authorization: `Bearer ${token}`} : {})},
      ...(body ? {body: JSON.stringify(body)} : {}),
    });
    if (response.status >= 300 && response.status < 400) return {ok: false, errorCode: 'redirect_rejected'};
    const data = await response.json();
    return response.ok ? {ok: true, data} : {ok: false, errorCode: errors.has(data?.code) ? data.code : 'confirmation_rejected'};
  } catch { return {ok: false, errorCode: 'confirmation_unavailable'}; }
}

export async function confirmPilotAccounts({projectRoot = root, codes, fetchImpl = globalThis.fetch, confirmNewAccounts = false} = {}) {
  if (!confirmNewAccounts || !codes || Object.keys(codes).some(actor => !actors.includes(actor)) ||
      !Object.keys(codes).length || Object.values(codes).some(code => !/^\d{6,12}$/.test(code))) {
    return result('blocked');
  }
  let journal, config;
  try {
    journal = await readPilotJson(projectRoot, ['.dart_tool', 'ar-live-pilot', 'accounts.json']);
    config = readPublicProductionConfig(await readPilotJson(projectRoot, ['config', 'supabase.production.json']));
  } catch { return result('blocked'); }
  if (!config || journal.version !== 1 || journal.productionOrigin !== config.origin) return result('blocked');
  for (const actor of Object.keys(codes)) {
    const account = journal.accounts?.[actor], original = account?.response?.user ?? account?.response;
    if (account?.status !== 'created' || !uuid.test(account.userId ?? '') || original?.id !== account.userId ||
        original.email !== account.email || !Array.isArray(original.identities) || !original.identities.length ||
        !account.profile?.full_name?.startsWith('Prueba RA MAREA') ||
        original.user_metadata?.username !== account.profile.username ||
        original.user_metadata?.user_type !== account.profile.user_type ||
        account.profile.user_type !== (actor === 'owner' ? 'Negocio' : 'Usuario general')) return result('blocked');
  }
  const path = join(projectRoot, '.dart_tool', 'ar-live-pilot', 'accounts.json');
  const handle = await open(path, constants.O_RDWR | (constants.O_NOFOLLOW ?? 0));
  const checked = await lstat(path), opened = await handle.stat();
  if (checked.isSymbolicLink() || !opened.isFile() || opened.nlink !== 1 || checked.ino !== opened.ino) {
    await handle.close(); return result('blocked');
  }
  const checks = [];
  try {
    for (const actor of Object.keys(codes)) {
      const account = journal.accounts[actor];
      const existing = Boolean(account.session);
      let session = account.session;
      if (!session) {
        const verified = await request(config.origin, config.key, '/auth/v1/verify', {
          fetchImpl, body: {email: account.email, token: codes[actor], type: 'signup'},
        });
        if (!verified.ok) { checks.push({actor, status: 'pending_confirmation', errorCode: verified.errorCode}); continue; }
        session = verified.data;
      }
      const identity = claims(session?.access_token);
      if (identity?.sub !== account.userId || identity.role !== 'authenticated' ||
          identity.iss !== `${config.origin}/auth/v1` || !(identity.exp * 1000 > Date.now())) {
        checks.push({actor, status: 'identity_rejected'}); continue;
      }
      const user = await request(config.origin, config.key, '/auth/v1/user', {fetchImpl, token: session.access_token});
      if (!user.ok || user.data.id !== account.userId || user.data.email !== account.email ||
          !(user.data.email_confirmed_at || user.data.confirmed_at)) {
        checks.push({actor, status: 'identity_rejected'}); continue;
      }
      const profile = await request(config.origin, config.key,
        `/rest/v1/profiles?id=eq.${account.userId}&select=id,role,user_type,username`, {fetchImpl, token: session.access_token});
      if (!profile.ok || profile.data?.length !== 1 || profile.data[0].id !== account.userId ||
          profile.data[0].role !== 'user' || profile.data[0].user_type !== account.profile.user_type ||
          profile.data[0].username !== account.profile.username) {
        checks.push({actor, status: 'ordinary_profile_unverified'}); continue;
      }
      account.session = session;
      account.confirmNeeded = false;
      account.confirmedAt = new Date().toISOString();
      const bytes = Buffer.from(`${JSON.stringify(journal, null, 2)}\n`);
      let offset = 0;
      while (offset < bytes.length) {
        const written = await handle.write(bytes, offset, bytes.length - offset, offset);
        if (!written.bytesWritten) throw new Error('journal_write_failed');
        offset += written.bytesWritten;
      }
      await handle.truncate(bytes.length);
      await handle.sync();
      checks.push({actor, status: existing ? 'already_confirmed' : 'confirmed', newUserId: account.userId, ordinaryProfileVerified: true});
    }
    return result(checks.every(check => ['confirmed', 'already_confirmed'].includes(check.status)) ? 'confirmed' : 'incomplete', checks);
  } finally { await handle.close(); }
}

// Codes are supplied on stdin, not as command-line arguments or stored fields.
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  if (!process.argv.includes('--confirm-new-accounts')) {
    console.log(JSON.stringify(result('blocked'))); process.exitCode = 1;
  } else {
    try {
      let input = '';
      for await (const chunk of process.stdin) { input += chunk; if (input.length > 512) throw new Error('invalid_input'); }
      const report = await confirmPilotAccounts({codes: JSON.parse(input), confirmNewAccounts: true});
      console.log(JSON.stringify(report)); process.exitCode = report.status === 'confirmed' ? 0 : 1;
    } catch { console.log(JSON.stringify(result('blocked'))); process.exitCode = 1; }
  }
}
