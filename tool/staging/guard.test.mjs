import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync, mkdirSync, writeFileSync, symlinkSync, rmSync, realpathSync, chmodSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {assertLocalUrl, assertOwnedRuntime, childEnvironment} from './guard.mjs';

test('remote destinations and URL credentials are rejected before any request', () => {
  for (const url of ['https://example.supabase.co', 'http://127.0.0.1.evil.invalid:61001', 'http://u:p@127.0.0.1:61001', 'http://127.0.0.1:54321', 'http://localhost:61001/path', 'http://[::1]:61001']) {
    assert.throws(() => assertLocalUrl(url, 61001));
  }
  assert.equal(assertLocalUrl('http://127.0.0.1:61001', 61001).hostname, '127.0.0.1');
});

test('only a private owned runtime is accepted; linked and symlink targets are rejected', () => {
  const root = realpathSync(mkdtempSync(join(tmpdir(), 'marea-guard-')));
  const runtime = join(root, 'runtime');
  mkdirSync(runtime, {mode: 0o700});
  const marker = {version: 1, project_id: 'marea-task001-012345abcdef', network: 'marea-task001-012345abcdef', api_port: 61001, db_port: 61002};
  try {
    assert.throws(() => assertOwnedRuntime(runtime, root));
    writeFileSync(join(runtime, '.marea-task001.json'), JSON.stringify(marker), {mode: 0o600});
    assert.equal(assertOwnedRuntime(runtime, root).project_id, marker.project_id);
    symlinkSync(runtime, join(root, 'alias'));
    assert.throws(() => assertOwnedRuntime(join(root, 'alias'), root));
    mkdirSync(join(runtime, 'supabase', '.temp'), {recursive: true});
    writeFileSync(join(runtime, 'supabase', '.temp', 'project-ref'), 'foreign');
    assert.throws(() => assertOwnedRuntime(runtime, root));
    assert.throws(() => assertOwnedRuntime(runtime, join(root, 'different-root')));
  } finally { rmSync(root, {recursive: true, force: true}); }
});

test('child processes receive no inherited Supabase, provider, or database credentials', () => {
  const env = childEnvironment({PATH: '/bin', HOME: '/tmp/user', SUPABASE_ACCESS_TOKEN: 'private', DATABASE_URL: 'private', GOOGLE_APPLICATION_CREDENTIALS: 'private', SECRET: 'private'});
  assert.equal(env.PATH, '/bin');
  for (const key of ['SUPABASE_ACCESS_TOKEN', 'DATABASE_URL', 'GOOGLE_APPLICATION_CREDENTIALS', 'SECRET']) assert.equal(env[key], undefined);
});

test('config drift, external provider configuration and public runtime permissions fail closed', () => {
  const root = realpathSync(mkdtempSync(join(tmpdir(), 'marea-guard-')));
  const runtime = join(root, 'runtime');
  mkdirSync(join(runtime, 'supabase'), {recursive:true, mode:0o700});
  const config = 'project_id = "marea-task001-012345abcdef"\n';
  const marker = {version:1, project_id:'marea-task001-012345abcdef', network:'marea-task001-012345abcdef',api_port:61001,db_port:61002,config_sha256:createHash('sha256').update(config).digest('hex')};
  const save = text => writeFileSync(join(runtime,'supabase','config.toml'),text,{mode:0o600});
  try {
    writeFileSync(join(runtime,'.marea-task001.json'),JSON.stringify(marker),{mode:0o600});
    save(config); assertOwnedRuntime(runtime,root);
    save(config+'[api]\nport = 54321\n'); assert.throws(()=>assertOwnedRuntime(runtime,root));
    const external = config+'provider = "https://example.invalid"\n';
    marker.config_sha256=createHash('sha256').update(external).digest('hex');
    writeFileSync(join(runtime,'.marea-task001.json'),JSON.stringify(marker));
    save(external); assert.throws(()=>assertOwnedRuntime(runtime,root));
    chmodSync(runtime,0o755); assert.throws(()=>assertOwnedRuntime(runtime,root));
  } finally {rmSync(root,{recursive:true,force:true});}
});

test('isolated relay runtimes accept only approved port sets and reject foreign ingress identity', () => {
  const root=realpathSync(mkdtempSync(join(tmpdir(),'marea-relay-'))), runtime=join(root,'runtime');
  mkdirSync(runtime,{mode:0o700});
  const id='marea-task001-abcdef012345';
  const marker={version:2,project_id:id,network:id,ingress_network:id+'-ingress',api_port:62001,db_port:62002};
  const save=()=>writeFileSync(join(runtime,'.marea-task001.json'),JSON.stringify(marker),{mode:0o600});
  try {
    save(); assert.equal(assertOwnedRuntime(runtime,root).api_port,62001);
    marker.ingress_network='foreign';save();assert.throws(()=>assertOwnedRuntime(runtime,root));
    marker.ingress_network=id+'-ingress';marker.api_port=54321;save();assert.throws(()=>assertOwnedRuntime(runtime,root));
  } finally {rmSync(root,{recursive:true,force:true});}
});
