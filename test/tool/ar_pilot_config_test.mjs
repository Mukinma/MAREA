import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {copyFile, link, mkdir, mkdtemp, readFile, rm, symlink, writeFile} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {dirname, join, resolve} from 'node:path';
import {test} from 'node:test';
import {fileURLToPath} from 'node:url';

import {
  checkDevelopmentConfig,
  loadDevelopmentConfig,
  loadValidatedDevelopmentConfig,
  PilotConfigError,
  validateDevelopmentConfig,
} from '../../tool/ar-pilot/config.mjs';

const devRef = 'aaaaaaaaaaaaaaaaaaaa';
const prodRef = 'bbbbbbbbbbbbbbbbbbbb';
const publicKey = 'sb_publishable_development0123456789abcdef';
const production = {
  SUPABASE_URL: `https://${prodRef}.supabase.co`,
  SUPABASE_ANON_KEY: 'sb_publishable_production0123456789abcdef',
};
const development = {
  SUPABASE_URL: `https://${devRef}.supabase.co/`,
  SUPABASE_ANON_KEY: publicKey,
};
const moduleFile = fileURLToPath(new URL('../../tool/ar-pilot/config.mjs', import.meta.url));
const validate = (config, productionConfig = production) =>
  validateDevelopmentConfig(config, {productionConfig});
const jwt = (payload) => [
  Buffer.from(JSON.stringify({alg: 'HS256', typ: 'JWT'})).toString('base64url'),
  Buffer.from(JSON.stringify(payload)).toString('base64url'),
  Buffer.from('test-signature-only').toString('base64url'),
].join('.');

async function fixture(t, {dev = development, prod = production} = {}) {
  const root = await mkdtemp(join(tmpdir(), 'marea-ar-config-'));
  t.after(async () => {
    // Delete only the exact temporary workspace created for this fixture.
    assert.equal(dirname(resolve(root)).toLowerCase(), resolve(tmpdir()).toLowerCase());
    assert.match(root, /marea-ar-config-[^\\/]+$/);
    await rm(root, {recursive: true, force: true});
  });
  await mkdir(join(root, 'config'));
  if (dev !== undefined) {
    await writeFile(join(root, 'config', 'supabase.development.json'), JSON.stringify(dev));
  }
  if (prod !== undefined) {
    await writeFile(join(root, 'config', 'supabase.production.json'), JSON.stringify(prod));
  }
  return root;
}

function noSecrets(value) {
  const text = JSON.stringify(value);
  for (const forbidden of [publicKey, production.SUPABASE_ANON_KEY, prodRef, devRef]) {
    assert.equal(text.includes(forbidden), false, 'a report exposed config data');
  }
}

test('a separate canonical hosted project accepts publishable and anon keys', () => {
  for (const key of [publicKey, jwt({role: 'anon', ref: devRef}), jwt({role: 'anon'})]) {
    assert.deepEqual(validate({...development, SUPABASE_ANON_KEY: key}), {
      ok: true, status: 'ready', reasons: [], target: 'hosted',
    });
  }
});

test('literal loopback and RFC1918 addresses support local Supabase on a phone', () => {
  for (const url of [
    'http://localhost:54321', 'http://127.0.0.1:54321/', 'http://[::1]:54321',
    'http://10.0.2.2:54321', 'http://172.16.0.1:54321',
    'http://172.31.255.254:54321', 'http://192.168.1.20:54321',
    'https://192.168.1.20:54321',
  ]) {
    const result = validate({...development, SUPABASE_URL: url});
    assert.equal(result.ok, true, result.reasons.join(','));
    assert.equal(result.target, 'local');
  }
});

test('remote HTTP, aliases, noncanonical hosts and URL decorations are blocked', () => {
  for (const url of [
    `http://${devRef}.supabase.co`, 'http://example.com', 'https://example.com',
    'https://8.8.8.8', 'http://172.15.255.255', 'http://172.32.0.0',
    'http://169.254.1.1', 'http://100.64.0.1', 'http://localhost.example.com',
    'http://127.1', 'http://2130706433', 'http://0177.0.0.1',
    'http://[::ffff:127.0.0.1]', 'http://192.168.001.2',
    `https://user:password@${devRef}.supabase.co`,
    `https://${devRef}.supabase.co?query=secret`,
    `https://${devRef}.supabase.co#fragment`,
    `https://${devRef}.supabase.co/path`, `https://${devRef}.supabase.co/a/..`,
    `https://${devRef}.supabase.co//`, `https://${devRef}.supabase.co:8443`,
    `https://${devRef}.supabase.co.`, `https://${devRef}.storage.supabase.co`,
    ` https://${devRef}.supabase.co`, `https://${devRef}.supabase.co\n`,
  ]) {
    assert.equal(validate({...development, SUPABASE_URL: url}).ok, false, 'unsafe URL accepted');
  }
});

test('the production project and production keys cannot be selected', () => {
  for (const config of [
    {...development, SUPABASE_URL: production.SUPABASE_URL},
    {...development, SUPABASE_URL: `https://${prodRef.toUpperCase()}.SUPABASE.CO:443/`},
    {...development, SUPABASE_ANON_KEY: production.SUPABASE_ANON_KEY},
    {...development, SUPABASE_ANON_KEY: jwt({role: 'anon', ref: prodRef})},
  ]) {
    const result = validate(config);
    assert.equal(result.ok, false);
    assert(result.reasons.some((reason) => reason.startsWith('production_')));
    noSecrets(result);
  }
});

test('JWTs from another project and administrative or authenticated keys fail closed', () => {
  for (const key of [
    'sb_secret_administrative0123456789abcdef', 'service_role',
    jwt({role: 'service_role', ref: devRef}), jwt({role: 'authenticated', ref: devRef}),
    jwt({ref: devRef}), jwt({role: 'anon', ref: 'cccccccccccccccccccc'}),
    jwt({role: 'anon', ref: null}), jwt({role: 'anon', ref: 123}),
    'sb_publishable_', 'sb_publishable_short', 'sb_publishable_invalid/suffix0123456789',
    'not-a-key', 'a.b.c', '', null, 42,
  ]) {
    assert.equal(validate({...development, SUPABASE_ANON_KEY: key}).ok, false);
  }
});

test('placeholder configuration, missing fields and extra credential fields fail closed', () => {
  for (const config of [
    null, [], {}, {SUPABASE_URL: development.SUPABASE_URL},
    {...development, SUPABASE_URL: 'https://REEMPLAZAR_PROYECTO_DESARROLLO.supabase.co'},
    {...development, SUPABASE_ANON_KEY: 'REEMPLAZAR_CLAVE_PUBLICABLE'},
    {...development, SUPABASE_ANON_KEY: 'sb_publishable_REPLACE_ME0123456789abcdef'},
    {...development, SUPABASE_SERVICE_ROLE_KEY: 'private-value'},
    {...development, APP_PUBLIC_URL: 'https://production.example.com'},
  ]) {
    const result = validate(config);
    assert.equal(result.ok, false);
    noSecrets(result);
  }
});

test('missing or unusable production identity blocks hosted and local targets', () => {
  for (const prod of [undefined, null, {}, {SUPABASE_URL: 'https://example.com'}]) {
    for (const url of [development.SUPABASE_URL, 'http://127.0.0.1:54321']) {
      const result = validate({...development, SUPABASE_URL: url}, prod);
      // An explicitly undefined fixture must not use validate's default argument.
      const checked = prod === undefined
        ? validateDevelopmentConfig({...development, SUPABASE_URL: url})
        : result;
      assert.equal(checked.ok, false);
      assert(checked.reasons.includes('production_identity_unavailable'));
    }
  }
});

test('the fixed-file loader returns config only in memory and never modifies inputs', async (t) => {
  const root = await fixture(t);
  const path = join(root, 'config', 'supabase.development.json');
  const before = await readFile(path);
  const result = await loadValidatedDevelopmentConfig({projectRoot: root});
  assert.equal(result.report.ok, true);
  assert.equal(result.productionOrigin, production.SUPABASE_URL);
  assert.deepEqual(result.config, {...development, SUPABASE_URL: development.SUPABASE_URL.slice(0, -1)});
  assert.deepEqual(await readFile(path), before);
  noSecrets(result.report);
  const flat = await loadDevelopmentConfig({projectRoot: root});
  assert.equal(flat.supabaseAnonKey, publicKey);
  assert.equal(flat.environment, 'development');
});

test('only the exact development filename is accepted, never example or production fallbacks', async (t) => {
  const root = await fixture(t);
  const path = join(root, 'config', 'supabase.development.json');
  await rm(path);
  await writeFile(join(root, 'config', 'supabase.development.example.json'), JSON.stringify(development));
  await writeFile(join(root, 'config', 'supabase.local.json'), JSON.stringify(development));
  const result = await loadValidatedDevelopmentConfig({projectRoot: root});
  assert.equal(result.config, null);
  assert(result.report.reasons.includes('development_config_unreadable_or_unsafe'));
  noSecrets(result.report);
});

test('missing production, malformed JSON and oversized files return redacted reports', async (t) => {
  const root = await fixture(t);
  const prodPath = join(root, 'config', 'supabase.production.json');
  await rm(prodPath);
  let result = await loadValidatedDevelopmentConfig({projectRoot: root});
  assert.equal(result.report.ok, false);
  assert.equal(result.config, null);
  await assert.rejects(loadDevelopmentConfig({projectRoot: root}), (error) => {
    assert(error instanceof PilotConfigError);
    noSecrets(error);
    return true;
  });
  await writeFile(prodPath, JSON.stringify(production));
  const devPath = join(root, 'config', 'supabase.development.json');
  for (const text of [`{${publicKey}`, ' '.repeat(65537)]) {
    await writeFile(devPath, text);
    result = await loadValidatedDevelopmentConfig({projectRoot: root});
    assert.equal(result.config, null);
    assert.equal(result.report.ok, false);
    noSecrets(result.report);
  }
});

test('symlinked files and directory junctions cannot redirect config reads', async (t) => {
  const root = await fixture(t);
  const devPath = join(root, 'config', 'supabase.development.json');
  const prodPath = join(root, 'config', 'supabase.production.json');
  await rm(devPath);
  try {
    await symlink(prodPath, devPath, 'file');
  } catch (error) {
    if (error.code !== 'EPERM') throw error;
    // Windows may disallow file symlinks. Junctions remain testable without
    // developer-mode privileges, and exercise the parent-path protection.
  }
  let result = await loadValidatedDevelopmentConfig({projectRoot: root});
  assert.equal(result.report.ok, false);
  assert.equal(result.config, null);
  await rm(devPath, {force: true});
  await writeFile(devPath, JSON.stringify(development));
  const aliasRoot = await mkdtemp(join(tmpdir(), 'marea-ar-config-'));
  t.after(async () => {
    assert.equal(dirname(resolve(aliasRoot)).toLowerCase(), resolve(tmpdir()).toLowerCase());
    assert.match(aliasRoot, /marea-ar-config-[^\\/]+$/);
    await rm(aliasRoot, {recursive: true, force: true});
  });
  await symlink(join(root, 'config'), join(aliasRoot, 'config'), process.platform === 'win32' ? 'junction' : 'dir');
  result = await loadValidatedDevelopmentConfig({projectRoot: aliasRoot});
  assert.equal(result.report.ok, false);
  assert.equal(result.config, null);
});

test('hardlinked config files cannot alias another environment', async (t) => {
  const root = await fixture(t);
  const devPath = join(root, 'config', 'supabase.development.json');
  await rm(devPath);
  await link(join(root, 'config', 'supabase.production.json'), devPath);
  const result = await loadValidatedDevelopmentConfig({projectRoot: root});
  assert.equal(result.report.ok, false);
  assert.equal(result.config, null);
});

test('BOM from Windows UTF-8 config files is accepted without weakening validation', async (t) => {
  const root = await fixture(t);
  await writeFile(join(root, 'config', 'supabase.development.json'), `\uFEFF${JSON.stringify(development)}`);
  assert.equal((await checkDevelopmentConfig({projectRoot: root})).ok, true);
});

test('CLI --check exits 0 for valid config and 1 for blocked config without secret output', async (t) => {
  const root = await fixture(t);
  const copied = join(root, 'tool', 'ar-pilot', 'config.mjs');
  await mkdir(dirname(copied), {recursive: true});
  await copyFile(moduleFile, copied);
  for (const [valid, args] of [[true, ['--check']], [false, ['--unknown']]]) {
    const result = spawnSync(process.execPath, [copied, ...args], {encoding: 'utf8', cwd: root});
    assert.equal(result.status, valid ? 0 : 1, result.stderr);
    const parsed = JSON.parse(result.stdout);
    assert.equal(parsed.ok, valid);
    noSecrets(parsed);
    assert.equal(result.stderr, '');
  }
  await writeFile(join(root, 'config', 'supabase.development.json'), JSON.stringify(production));
  const blocked = spawnSync(process.execPath, [copied, '--check'], {encoding: 'utf8', cwd: root});
  assert.equal(blocked.status, 1);
  noSecrets(JSON.parse(blocked.stdout));
  assert.equal(blocked.stderr, '');
});

test('relative roots and unexpected filesystem errors produce safe failures', async () => {
  for (const projectRoot of ['.', '', null, 1, '\\\\network-host\\share', '//network-host/share']) {
    const result = await loadValidatedDevelopmentConfig({projectRoot});
    assert.equal(result.report.ok, false);
    assert.equal(result.config, null);
    noSecrets(result.report);
  }
});
