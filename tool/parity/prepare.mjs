// Prepare a fresh CLI workdir. The repository and linked projects are never CLI targets.
import { cpSync, mkdirSync, mkdtempSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { randomBytes } from 'node:crypto';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const source = fileURLToPath(new URL('../../supabase/', import.meta.url));
const port = Number(process.argv[2] || 57421);
if (!Number.isInteger(port) || port < 1024 || port > 65529) throw Error('Use an available unprivileged base port.');
process.umask(0o077);
const workdir = mkdtempSync(join(tmpdir(), 'marea-parity-'));
const project = 'marea-parity-' + randomBytes(6).toString('hex');
const target = join(workdir, 'supabase');
mkdirSync(join(target, 'migrations'), { recursive: true });
cpSync(join(source, 'functions'), join(target, 'functions'), { recursive: true });

// CLI history has a unique version key. Group the two historical 034 and 035 pairs
// in filename order inside the disposable copy, preserving every original SQL byte.
const groups = new Map();
for (const file of readdirSync(join(source, 'migrations')).sort()) {
  const match = /^(\d+)_.*\.sql$/.exec(file);
  if (!match) continue;
  const files = groups.get(match[1]) || [];
  files.push(file);
  groups.set(match[1], files);
}
for (const [version, files] of groups) {
  const name = files.length === 1 ? files[0] : version + '_combined_local_history.sql';
  writeFileSync(join(target, 'migrations', name),
    Buffer.concat(files.flatMap(file => [readFileSync(join(source, 'migrations', file)), Buffer.from('\n')])));
}
const storySecret = randomBytes(32).toString('hex');
const original = readFileSync(join(source, 'config.toml'), 'utf8').replace(/^project_id = "marea"/m, 'project_id = "' + project + '"');
const config = [
  original, '[api]', 'port = ' + port, '[db]', 'port = ' + (port + 1),
  'shadow_port = ' + (port + 2), 'major_version = 17', '[db.seed]', 'enabled = false',
  '[studio]', 'enabled = false', '[analytics]', 'enabled = false',
  '[inbucket]', 'port = ' + (port + 3), '[auth.rate_limit]', 'sign_in_sign_ups = 1000',
  '[edge_runtime]', 'inspector_port = ' + (port + 4), '[edge_runtime.secrets]',
  'STORY_WORKER_SECRET = "' + storySecret + '"',
].join('\n') + '\n';
writeFileSync(join(target, 'config.toml'), config);
writeFileSync(join(workdir, 'lab.json'), JSON.stringify({ project, port, storySecret }));
console.log(workdir);
