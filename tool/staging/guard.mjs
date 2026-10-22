import {lstatSync, realpathSync, readFileSync, existsSync} from 'node:fs';
import {homedir} from 'node:os';
import {join, resolve, relative, isAbsolute} from 'node:path';
import {createHash} from 'node:crypto';

export const runtimeRoot = join(homedir(), '.local', 'share', 'marea-task001');
export function childEnvironment(source = process.env) {
  return Object.fromEntries(['PATH', 'HOME', 'TMPDIR', 'LANG', 'LC_ALL'].filter(k => source[k]).map(k => [k, source[k]]));
}
export function assertLocalUrl(value, port) {
  const url = new URL(value);
  if (url.protocol !== 'http:' || url.hostname !== '127.0.0.1' || url.port !== String(port) || url.username || url.password || url.pathname !== '/' || url.search || url.hash) throw new Error('Only the owned loopback endpoint is allowed');
  return url;
}
function privatePath(path, directory = false) {
  const stat = lstatSync(path);
  if (stat.isSymbolicLink() || (directory ? !stat.isDirectory() : !stat.isFile()) || (stat.mode & 0o077) || stat.uid !== process.getuid()) throw new Error('Runtime paths must be private, owned and not symlinks');
}
export function assertOwnedRuntime(value, root = runtimeRoot) {
  const runtime = resolve(value);
  const trusted = realpathSync(root);
  const rel = relative(trusted, runtime);
  if (!rel || rel.startsWith('..') || isAbsolute(rel) || realpathSync(runtime) !== runtime) throw new Error('Runtime is outside its trusted root or uses symlinks');
  privatePath(runtime, true);
  const markerPath = join(runtime, '.marea-task001.json');
  privatePath(markerPath);
  const marker = JSON.parse(readFileSync(markerPath, 'utf8'));
  if (![1,2].includes(marker.version) || !/^marea-task001-[a-f0-9]{12}$/.test(marker.project_id) || marker.network !== marker.project_id || ![61001,62001,63001].includes(marker.api_port) || marker.db_port !== marker.api_port+1 || (marker.version===1 && marker.api_port!==61001) || (marker.version===2 && marker.ingress_network!==marker.project_id+'-ingress')) throw new Error('Foreign runtime marker');
  if (existsSync(join(runtime, 'supabase', '.temp', 'project-ref'))) throw new Error('Linked projects are forbidden');
  const config = join(runtime, 'supabase', 'config.toml');
  if (existsSync(config)) {
    privatePath(join(runtime, 'supabase'), true);
    privatePath(config);
    const text = readFileSync(config, 'utf8');
    if (createHash('sha256').update(text).digest('hex') !== marker.config_sha256) throw new Error('Runtime configuration drift; prepare a new runtime');
    if (!text.includes(`project_id = "${marker.project_id}"`) || /env\(|https:\/\//.test(text.replace(/^\s*#.*$/gm, ''))) throw new Error('Foreign or external runtime configuration');
  }
  return marker;
}
