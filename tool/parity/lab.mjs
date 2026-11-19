import { readFileSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

export function labTarget() {
  if (!process.env.MAREA_QA_WORKDIR) throw Error('Set MAREA_QA_WORKDIR to the disposable workdir printed by tool/parity/prepare.mjs.');
  const workdir = resolve(process.env.MAREA_QA_WORKDIR);
  const info = statSync(workdir);
  if (process.getuid && (info.uid !== process.getuid() || (info.mode & 0o077) !== 0)) {
    throw Error('QA workdir must be private to the current user.');
  }
  const lab = JSON.parse(readFileSync(join(workdir, 'lab.json'), 'utf8'));
  const config = readFileSync(join(workdir, 'supabase/config.toml'), 'utf8');
  if (!/^marea-parity-[0-9a-f]{12}$/.test(lab.project) ||
      !config.split(/\r?\n/).includes('project_id = "' + lab.project + '"')) throw Error('Invalid QA project identifier.');
  return { ...lab, workdir };
}

export function liveTarget() {
  const lab = labTarget();
  const result = spawnSync('supabase', ['status', '--workdir', lab.workdir, '--output', 'json'], { encoding: 'utf8' });
  if (result.status !== 0) throw Error('The isolated Supabase stack is unavailable.');
  const status = JSON.parse(result.stdout);
  const base = 'http://127.0.0.1:' + lab.port;
  if (status.API_URL !== base || !status.SERVICE_ROLE_KEY || !status.ANON_KEY) {
    throw Error('The CLI must report the expected loopback API and local test keys.');
  }
  return { ...lab, base, publicKey: status.ANON_KEY, admin: status.SERVICE_ROLE_KEY };
}

// Read-only release gates keep the linked target for existing callers. Every
// live fixture flow requires labTarget() before doing any read or write.
export function contractTarget() {
  return process.env.MAREA_QA_WORKDIR ? ['--local', '--workdir', labTarget().workdir] : ['--linked'];
}
