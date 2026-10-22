#!/usr/bin/env node
import {mkdirSync, writeFileSync, readFileSync, existsSync, readdirSync, lstatSync, openSync, closeSync} from 'node:fs';
import {randomBytes, createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {join, resolve} from 'node:path';
import {createServer} from 'node:net';
import {assertOwnedRuntime, assertLocalUrl, childEnvironment, runtimeRoot} from './guard.mjs';

process.umask(0o077);
const command = process.argv[2];
const runtime = process.argv[3];
const version = '2.117.0';
const hash = value => createHash('sha256').update(value).digest('hex');
function run(bin, args, workdir, logName) {
  const fd = logName ? openSync(join(workdir, logName), 'wx', 0o600) : undefined;
  let result;
  try {result = spawnSync(bin, args, {cwd: workdir, env: childEnvironment(), encoding: 'utf8', maxBuffer: 64 * 1024 * 1024, stdio: fd === undefined ? 'pipe' : ['ignore', fd, fd]});}
  finally {if (fd !== undefined) closeSync(fd);}
  if (result.error || result.status !== 0) throw new Error(`${bin} ${args[0]} failed; private log preserved${logName ? ` (${logName})` : ''}`);
  return result.stdout;
}
function pinnedTools() {
  if (Number(process.versions.node.split('.')[0]) !== 24) throw new Error('Requires Node 24');
  if (run('supabase', ['--version']).trim() !== version) throw new Error(`Requires inspected Supabase CLI ${version}; no automatic upgrades`);
  const context = JSON.parse(run('docker', ['context','inspect']))[0];
  if (!context.Endpoints?.docker?.Host?.startsWith('unix://')) throw new Error('Only a local Unix Docker daemon is allowed');
  const info=JSON.parse(run('docker', ['info', '--format', '{{json .}}']));
  const pinned=JSON.parse(readFileSync('tool/staging/images.lock.json'));
  if(info.ServerVersion!==pinned.docker||process.versions.node!==pinned.node)throw Error('Pinned infrastructure version drift');
  for(const i of [...pinned.images,JSON.parse(readFileSync('tool/staging/functions-image.lock.json'))])if(JSON.parse(run('docker',['image','inspect',i.tag]))[0].Id!==i.id)throw Error('Cached official image drift; no uncontrolled pull');
  const own=JSON.parse(readFileSync('tool/staging/network-image.lock.json'));if(JSON.parse(run('docker',['image','inspect',own.image_id]))[0].Id!==own.image_id)throw Error('Network image unavailable');
  return info;
}
function receipt(path, name, data) {
  writeFileSync(join(path, `${name}-${Date.now()}.json`), JSON.stringify({at: new Date().toISOString(), ...data}, null, 2) + '\n', {mode: 0o600, flag: 'wx'});
}
async function freePort(port) {
  await new Promise((ok, fail) => {const server = createServer(); server.once('error', () => fail(new Error(`Port ${port} unavailable; no alternate stack selected`))); server.listen(port, '0.0.0.0', () => server.close(ok));});
}
function ownedNetwork(marker) {
  const net = JSON.parse(run('docker', ['network', 'inspect', marker.network]))[0];
  if (!net.Internal || net.Driver !== 'bridge' || net.Labels?.['marea.task001.owner'] !== marker.project_id) throw new Error('Network ownership/internal isolation check failed');
  for (const c of Object.values(net.Containers || {})) if (!c.Name.startsWith('supabase_') || !c.Name.endsWith(`_${marker.project_id}`)) throw new Error('Foreign container on owned network');
  return net;
}
function ownContainers(marker) {
  const ids = run('docker', ['ps', '-aq', '--filter', `label=com.supabase.cli.project=${marker.project_id}`]).trim().split('\n').filter(Boolean);
  return ids.length ? JSON.parse(run('docker', ['inspect', ...ids])) : [];
}
function verifyContainers(marker) {
  ownedNetwork(marker);
  const containers = ownContainers(marker);
  if (!containers.length) throw new Error('Owned stack not running');
  for (const c of containers) {
    if (!c.State.Running || (c.State.Health && c.State.Health.Status !== 'healthy')) throw new Error('Owned service not healthy');
    const networks = Object.keys(c.NetworkSettings.Networks);
    if (networks.length !== 1 || networks[0] !== marker.network) throw new Error('Service has an external or foreign network');
  }
  return containers;
}
async function prepare() {
  pinnedTools();
  mkdirSync(runtimeRoot, {recursive: true, mode: 0o700});
  if (lstatSync(runtimeRoot).isSymbolicLink() || (lstatSync(runtimeRoot).mode & 0o077)) throw new Error('Runtime root must be private and not a symlink');
  for (const port of [61001,61002,61003,61004,61005]) await freePort(port);
  const id = `marea-task001-${randomBytes(6).toString('hex')}`;
  const path = join(runtimeRoot, id);
  mkdirSync(path, {mode: 0o700});
  const marker = {version: 1, project_id: id, network: id, api_port: 61001, db_port: 61002};
  writeFileSync(join(path, '.marea-task001.json'), JSON.stringify(marker, null, 2), {mode: 0o600, flag: 'wx'});
  run('supabase', ['init', '--workdir', path], path, 'init-private.log');
  const configPath = join(path, 'supabase', 'config.toml');
  // Keep the generated template as a private diagnostic; the active config contains no provider settings.
  writeFileSync(join(path, 'config-generated-private.toml'), readFileSync(configPath), {mode: 0o600, flag: 'wx'});
  const config = `project_id = "${id}"
[api]
enabled = true
port = 61001
schemas = ["public", "graphql_public"]
extra_search_path = ["public", "extensions"]
max_rows = 1000
[db]
port = 61002
shadow_port = 61003
major_version = 17
[db.pooler]
enabled = false
[db.migrations]
enabled = true
schema_paths = []
[db.seed]
enabled = false
sql_paths = []
[realtime]
enabled = true
[studio]
enabled = false
[inbucket]
enabled = true
port = 61004
[storage]
enabled = true
file_size_limit = "50MiB"
[auth]
enabled = true
site_url = "http://127.0.0.1:61005"
additional_redirect_urls = []
jwt_expiry = 60
enable_signup = true
enable_anonymous_sign_ins = false
[auth.email]
enable_signup = true
enable_confirmations = false
[edge_runtime]
enabled = false
[analytics]
enabled = false
`;
  writeFileSync(configPath, config, {mode: 0o600});
  marker.config_sha256 = hash(config);
  writeFileSync(join(path, '.marea-task001.json'), JSON.stringify(marker, null, 2), {mode: 0o600});
  assertOwnedRuntime(path);
  receipt(path, 'prepare', {result: 'PASS', project_id: id, config_sha256: hash(config), supabase_cli: version, schema: 'EMPTY; MAREA migrations not copied', remote_modified: false});
  return {result: 'PASS', runtime: path, project_id: id};
}
async function main() {
  if (!['doctor','prepare','start','seed','test','report','stop'].includes(command) || process.argv.length > 4) throw new Error('Usage: node tool/staging/cli.mjs doctor|prepare|start|seed|test|report|stop [owned-runtime]');
  if (command === 'prepare') {if (runtime) throw new Error('prepare chooses a new private runtime; destination overrides forbidden'); pinnedTools(); return (await import('./local-stack.mjs')).prepare();}
  if (command === 'doctor') {
    const docker = pinnedTools();
    if (runtime) assertOwnedRuntime(runtime);
    return {result: 'PASS', supabase_cli: version, docker_server: docker.ServerVersion, docker_cpus: docker.NCPU, docker_memory_bytes: docker.MemTotal, remote_modified: false};
  }
  if (!runtime) throw new Error('An explicit owned runtime is required');
  const path = resolve(runtime);
  const marker = assertOwnedRuntime(path);
  if (marker.version===2) {
    pinnedTools();
    const stack=await import('./local-stack.mjs');
    if(command==='report')return (await import('./health.mjs')).health(path);
    if (['start','stop'].includes(command)) return stack[command](path);
    if (['seed','test'].includes(command)) return (await import('./workflow.mjs'))[command](path);
    throw new Error('Unsupported workflow');
  }
  if (command === 'report') return {result: 'INSPECTION', project_id: marker.project_id, receipts: readdirSync(path).filter(x => /^(prepare|start|stop|blocked)-\d+\.json$/.test(x)), schema_ready: false, seed_implemented: false, business_tests_implemented: false, business_tests: 'BLOCKED until non-destructive schema replay', remote_modified: false};
  pinnedTools();
  if (command === 'seed' || command === 'test') {
    throw new Error('BLOCKED: no approved non-destructive MAREA schema replay; no fixtures or business tests executed');
  }
  if (command === 'start' && existsSync(join(path,'.task001-blocked.json'))) throw new Error('H3 is blocked; preserve runtime and review the recorded cause before any new start');
  if (command === 'stop') {
    ownedNetwork(marker);
    for (const c of ownContainers(marker)) if (Object.keys(c.NetworkSettings.Networks).some(n => n !== marker.network)) throw new Error('Foreign network attachment; stop refused');
    run('supabase', ['stop','--project-id',marker.project_id,'--workdir',path], path, `stop-private-${Date.now()}.log`);
    receipt(path, 'stop', {result: 'PASS', project_id: marker.project_id, volumes_preserved: true});
    return {result: 'PASS', volumes_preserved: true};
  }
  for (const port of [61001,61002,61003,61004,61005]) await freePort(port);
  if (!existsSync(join(path, 'supabase', 'config.toml'))) throw new Error('prepare is required');
  const migrationDir = join(path, 'supabase', 'migrations');
  if (existsSync(migrationDir) && readdirSync(migrationDir).some(x => x.endsWith('.sql'))) throw new Error('Unreviewed SQL in runtime; start refused');
  const existing = spawnSync('docker', ['network','inspect',marker.network], {env: childEnvironment(), encoding:'utf8'});
  if (existing.status !== 0) run('docker', ['network','create','--internal','--label',`marea.task001.owner=${marker.project_id}`,marker.network]);
  ownedNetwork(marker);
  run('supabase', ['start','--workdir',path,'--network-id',marker.network,'--exclude','edge-runtime,studio,logflare,vector,supavisor'], path, `start-private-${Date.now()}.log`);
  const containers = verifyContainers(marker);
  const status = JSON.parse(run('supabase', ['status','--workdir',path,'-o','json']));
  assertLocalUrl(status.API_URL, marker.api_port);
  const response = await fetch(new URL('auth/v1/health', status.API_URL + '/'), {headers:{apikey:status.ANON_KEY}, redirect:'error', signal:AbortSignal.timeout(5000)});
  const body = await response.json();
  if (!response.ok || !body.version) throw new Error('Local Auth health did not return a service version');
  const summaries = containers.map(c => ({name:c.Name, image:c.Config.Image, image_id:c.Image, health:c.State.Health?.Status || 'running', ports:c.NetworkSettings.Ports}));
  const images = [...new Set(containers.map(c => c.Image))].map(id => {
    const i = JSON.parse(run('docker',['image','inspect',id]))[0]; return {id, repo_digests:i.RepoDigests};
  });
  receipt(path, 'start', {result:'PASS', project_id:marker.project_id, internal_network:true, containers:summaries, images, auth_version:body.version, schema:'EMPTY', functions_served:false, business_egress:'Network configured; behavioral probe still required', remote_modified:false});
  return {result:'PASS', project_id:marker.project_id, services:summaries.length, auth_health:'PASS', business_egress:'Behavioral probe pending', schema:'EMPTY'};
}
try {console.log(JSON.stringify(await main(), null, 2));} catch (error) {
  if (runtime) {
    try {const marker = assertOwnedRuntime(runtime); receipt(resolve(runtime),'blocked',{result:'BLOQUEADO', command, project_id:marker.project_id, reason:error.message, remote_modified:false});} catch {}
  }
  console.error(error.message); process.exitCode = 1;
}
