import {mkdir, readFile, writeFile, lstat, unlink} from 'node:fs/promises';
import {join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {loadValidatedDevelopmentConfig} from './config.mjs';

const root = fileURLToPath(new URL('../../', import.meta.url));

async function runtimeDirectory(projectRoot, create) {
  for (const path of [join(projectRoot, '.dart_tool'), join(projectRoot, '.dart_tool', 'ar-pilot')]) {
    try {
      const stat = await lstat(path);
      if (stat.isSymbolicLink() || !stat.isDirectory()) throw new Error('unsafe_directory');
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
      if (!create) return false;
      await mkdir(path);
    }
  }
  return true;
}

export async function prepareDevelopment({projectRoot = root} = {}) {
  const checked = await loadValidatedDevelopmentConfig({projectRoot});
  const directory = join(projectRoot, '.dart_tool', 'ar-pilot');
  const destination = join(directory, 'defines.json');
  if (!checked.report.ok) {
    // Retire only our generated file, so a previous configuration is not reused.
    try {
      if (await runtimeDirectory(projectRoot, false)) {
        const stat = await lstat(destination);
        if (stat.isFile() && !stat.isSymbolicLink()) await unlink(destination);
      }
    } catch (error) {
      if (error.code !== 'ENOENT') return {ok: false, status: 'blocked', reasons: ['generated_config_unavailable']};
    }
    return checked.report;
  }
  try {
    await runtimeDirectory(projectRoot, true);
    try {
      const stat = await lstat(destination);
      if (!stat.isFile() || stat.isSymbolicLink() || stat.nlink !== 1) throw new Error('unsafe_file');
      await unlink(destination);
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
    }
    await writeFile(destination, `${JSON.stringify({
      ...checked.config,
      MAREA_ENV: 'development',
      MAREA_PRODUCTION_SUPABASE_URL: checked.productionOrigin,
      APP_PUBLIC_URL: 'http://localhost:7358/',
    }, null, 2)}\n`, {flag: 'wx', mode: 0o600});
    return {ok: true, status: 'prepared', target: checked.report.target,
      androidApplicationId: 'com.marea.app.dev', callback: 'com.marea.app.dev://login-callback'};
  } catch {
    return {ok: false, status: 'blocked', reasons: ['generated_config_unavailable']};
  }
}

export async function initializeDevelopment({projectRoot = root} = {}) {
  try {
    const directory = join(projectRoot, 'config');
    if ((await lstat(directory)).isSymbolicLink()) throw new Error('unsafe_directory');
    const template = await readFile(join(directory, 'supabase.development.example.json'));
    await writeFile(join(directory, 'supabase.development.json'), template, {flag: 'wx', mode: 0o600});
    return {ok: true, status: 'template_created', needsProjectConfiguration: true};
  } catch (error) {
    return {ok: false, status: 'blocked', reasons: [error.code === 'EEXIST' ? 'development_config_exists' : 'development_config_unavailable']};
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const report = process.argv.includes('--init') ? await initializeDevelopment() : await prepareDevelopment();
  console.log(JSON.stringify(report, null, 2));
  if (!report.ok) process.exitCode = 1;
}
