import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { randomBytes } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { liveTarget } from './lab.mjs';

const { base, publicKey, admin, workdir, project, storySecret } = liveTarget();
const privateFile = (name, data) => writeFileSync(join(workdir, name), JSON.stringify(data, null, 2) + '\n', { mode: 0o600 });
const production = JSON.parse(readFileSync(new URL('../../config/supabase.production.json', import.meta.url), 'utf8'));
privateFile('defines.json', {
  MAREA_ENV: 'development',
  SUPABASE_URL: base,
  SUPABASE_ANON_KEY: publicKey,
  MAREA_PRODUCTION_SUPABASE_URL: production.SUPABASE_URL,
  APP_PUBLIC_URL: process.env.MAREA_QA_PUBLIC_URL || 'http://localhost:8080',
});
async function request(path, key, body) {
  const response = await fetch(base + path, {
    method: 'POST', headers: { apikey: key, Authorization: 'Bearer ' + key, 'Content-Type': 'application/json' },
    body: JSON.stringify(body), signal: AbortSignal.timeout(15000),
  });
  if (!response.ok) throw Error(path + ' returned HTTP ' + response.status);
  return response.json();
}
// Provision only the settings that a newly installed project leaves unset.
if (!/^[0-9a-f]{64}$/.test(storySecret)) throw Error('Invalid generated worker secret.');
const seed = spawnSync('docker', ['exec', '-i', 'supabase_db_' + project, 'psql',
  '-U', 'postgres', '-d', 'postgres', '-v', 'ON_ERROR_STOP=1', '-q'], {
  encoding: 'utf8', input: `begin;
    insert into public.legal_documents(kind,version,title,body,published_at)
    select k,'qa-v1','Documento de prueba',repeat('Texto sintético de QA local. ',8),now()
    from unnest(array['terms','privacy']) k on conflict do nothing;
    update public.registration_settings set signup_enabled=true,terms_version='qa-v1',
      privacy_version='qa-v1',support_email='qa@example.invalid';
    select vault.create_secret('${storySecret}', 'marea_story_worker_secret')
      where not exists(select 1 from vault.secrets where name='marea_story_worker_secret');
    select vault.create_secret('http://supabase_kong_${project}:8000/functions/v1/story-cleanup', 'marea_story_cleanup_url')
      where not exists(select 1 from vault.secrets where name='marea_story_cleanup_url');
    commit;`,
});
if (seed.status !== 0) throw Error('Could not provision the local registration and cleanup fixture.');
const policy = await request('/rest/v1/rpc/registration_policy', publicKey, {});
const accountFile = join(workdir, 'ui-accounts.json');
const users = existsSync(accountFile) ? JSON.parse(readFileSync(accountFile, 'utf8')) : {};
for (const [role, name, type] of [
  ['owner', 'Taller de Marea', 'Negocio'],
  ['viewer', 'Ana de Marea', 'Usuario general'],
  ['observer', 'Leo de Marea', 'Artista / creador'],
]) {
  if (!users[role]) {
    const username = 'qa_' + role + '_' + randomBytes(3).toString('hex');
    const email = username + '@example.invalid';
    const password = randomBytes(20).toString('base64url');
    const created = await request('/auth/v1/admin/users', admin, {
      email, password, email_confirm: true,
      user_metadata: { username, full_name: name, user_type: type, registration_flow: 'minimal-v1',
        accepted_terms: true, adult_confirmed: true, terms_version: policy.terms.version, privacy_version: policy.privacy.version },
    });
    users[role] = { id: created.id, email, password, username };
    privateFile('ui-accounts.json', users);
  }
  const { email, password, id } = users[role];
  const session = await request('/auth/v1/token?grant_type=password', publicKey, { email, password });
  if (session.user?.id !== id) throw Error('Unexpected QA account.');
}
console.log('Confirmed 3 local UI logins. Private files: ' + join(workdir, 'defines.json') + ' and ' + accountFile);
