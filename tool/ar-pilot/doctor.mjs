import {access} from 'node:fs/promises';
import {delimiter, join} from 'node:path';
import {fileURLToPath} from 'node:url';
import {checkDevelopmentConfig} from './config.mjs';

const projectRoot = fileURLToPath(new URL('../../', import.meta.url));
async function exists(path) { try { await access(path); return true; } catch { return false; } }
async function available(name) {
  const extensions = process.platform === 'win32' ? ['', '.exe', '.bat', '.cmd'] : [''];
  for (const directory of (process.env.PATH ?? '').split(delimiter)) {
    if (!directory) continue;
    for (const extension of extensions) if (await exists(join(directory, `${name}${extension}`))) return true;
  }
  return false;
}
const configuration = await checkDevelopmentConfig({projectRoot});
const tools = Object.fromEntries(await Promise.all(['git', 'flutter', 'node', 'python', 'docker', 'supabase'].map(async name => [name, await available(name)])));
console.log(JSON.stringify({
  status: configuration.ok ? 'configuration_ready_backend_not_checked' : 'needs_development_configuration',
  configuration,
  tools,
  mediaValidatorEnvironment: await exists(join(projectRoot, '.venv-tours', process.platform === 'win32' ? 'Scripts/python.exe' : 'bin/python')),
  entrypoint: 'lib/main.dart',
  androidApplicationId: 'com.marea.app.dev',
  backendContacted: false,
  note: 'La configuración válida no acredita migraciones, permisos, cuentas ni procesamiento.',
}, null, 2));
