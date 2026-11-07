import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp, mkdir, writeFile, readFile, access, rm, symlink} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {prepareDevelopment, initializeDevelopment} from '../../tool/ar-pilot/prepare.mjs';

const key = `sb_publishable_${'x'.repeat(24)}`;
const production = {SUPABASE_URL: `https://${'b'.repeat(20)}.supabase.co`, SUPABASE_ANON_KEY: 'private-production-fixture'};
const development = {SUPABASE_URL: `https://${'a'.repeat(20)}.supabase.co`, SUPABASE_ANON_KEY: key};
async function fixture(t) {
  const projectRoot = await mkdtemp(join(tmpdir(), 'marea-ar-prepare-'));
  t.after(() => rm(projectRoot, {recursive: true, force: true}));
  await mkdir(join(projectRoot, 'config'));
  for (const [name, value] of [['production', production], ['development', development], ['development.example', development]]) {
    await writeFile(join(projectRoot, `config/supabase.${name}.json`), JSON.stringify(value));
  }
  return projectRoot;
}
test('preparation produces development-only defines and keeps credentials out of report', async t => {
  const projectRoot = await fixture(t);
  const report = await prepareDevelopment({projectRoot});
  assert.equal(report.ok, true);
  assert.equal(JSON.stringify(report).includes(key), false);
  const generated = JSON.parse(await readFile(join(projectRoot, '.dart_tool/ar-pilot/defines.json')));
  assert.equal(generated.MAREA_ENV, 'development');
  assert.equal(generated.SUPABASE_URL, development.SUPABASE_URL);
  assert.equal(generated.MAREA_PRODUCTION_SUPABASE_URL, production.SUPABASE_URL);
  assert.equal(generated.APP_PUBLIC_URL, 'http://localhost:7358/');
  assert.equal(Object.keys(generated).some(name => name.includes('FIREBASE') || name.includes('SERVICE_ROLE')), false);
});
test('an invalidated configuration retires previous generated defines', async t => {
  const projectRoot = await fixture(t);
  assert.equal((await prepareDevelopment({projectRoot})).ok, true);
  await writeFile(join(projectRoot, 'config/supabase.development.json'), JSON.stringify(production));
  assert.equal((await prepareDevelopment({projectRoot})).ok, false);
  await assert.rejects(access(join(projectRoot, '.dart_tool/ar-pilot/defines.json')));
});
test('initialization never overwrites an existing development configuration', async t => {
  const projectRoot = await fixture(t);
  const before = await readFile(join(projectRoot, 'config/supabase.development.json'), 'utf8');
  assert.equal((await initializeDevelopment({projectRoot})).ok, false);
  assert.equal(await readFile(join(projectRoot, 'config/supabase.development.json'), 'utf8'), before);
  await rm(join(projectRoot, 'config/supabase.development.json'));
  assert.equal((await initializeDevelopment({projectRoot})).ok, true);
});
test('generated configuration cannot be redirected through a directory junction', async t => {
  const projectRoot = await fixture(t);
  const outside = await mkdtemp(join(tmpdir(), 'marea-ar-outside-'));
  t.after(() => rm(outside, {recursive: true, force: true}));
  await symlink(outside, join(projectRoot, '.dart_tool'), process.platform === 'win32' ? 'junction' : 'dir');
  assert.equal((await prepareDevelopment({projectRoot})).ok, false);
  await assert.rejects(access(join(outside, 'ar-pilot/defines.json')));
  await rm(join(projectRoot, '.dart_tool'));
});
