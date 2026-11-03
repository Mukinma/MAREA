// Offline configuration guard. This module never initializes a client or sends
// requests. Reports deliberately contain no paths, origins, keys or JSON input.
import {constants} from 'node:fs';
import {lstat, open, realpath} from 'node:fs/promises';
import {dirname, isAbsolute, join, parse, relative, resolve, sep} from 'node:path';
import {fileURLToPath} from 'node:url';

const defaultProjectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const developmentFile = 'supabase.development.json';
const productionFile = 'supabase.production.json';
const maxConfigBytes = 64 * 1024;
const projectHost = /^([a-z0-9]{20})\.supabase\.co$/;
const placeholder = /(?:REEMPLAZAR|TU_PROYECTO|TU_PROJECT|TU_CLAVE|YOUR_PROJECT|YOUR_KEY|REPLACE_ME|CHANGE_ME)/i;

function object(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function report(reasons, target = null) {
  return {
    ok: reasons.length === 0,
    status: reasons.length === 0 ? 'ready' : 'blocked',
    reasons: [...new Set(reasons)],
    target,
  };
}

// No DNS lookup is used to classify local addresses. HTTP is allowed only for
// literal RFC1918 LAN IPv4 addresses or these exact loopback host spellings.
// LAN addresses support a phone reaching a developer-owned local Supabase.
function localHostname(hostname) {
  if (hostname === 'localhost' || hostname === '127.0.0.1' || hostname === '[::1]') {
    return true;
  }
  const parts = hostname.split('.');
  if (parts.length !== 4 || parts.some((part) => !/^(?:0|[1-9]\d{0,2})$/.test(part))) {
    return false;
  }
  const bytes = parts.map(Number);
  if (bytes.some((part) => part > 255)) return false;
  return bytes[0] === 10 ||
    (bytes[0] === 172 && bytes[1] >= 16 && bytes[1] <= 31) ||
    (bytes[0] === 192 && bytes[1] === 168);
}

function endpoint(value) {
  if (typeof value !== 'string' || value !== value.trim() || placeholder.test(value)) {
    return null;
  }
  // Check the source before URL normalization can erase /a/.. or separators.
  const source = /^(https?):\/\/([^/?#\\\s]+)\/?$/.exec(value);
  if (!source) return null;
  let url;
  try {
    url = new URL(value);
  } catch {
    return null;
  }
  if (url.username || url.password || url.search || url.hash || url.pathname !== '/') {
    return null;
  }
  const rawHost = source[2].startsWith('[')
    ? source[2].slice(0, source[2].indexOf(']') + 1).toLowerCase()
    : source[2].split(':')[0].toLowerCase();
  const host = url.hostname.toLowerCase();
  // Reject octal/decimal/short IPv4 spellings and encoded/alias hostnames.
  if (rawHost !== host) return null;
  if (localHostname(host)) {
    return {url, target: 'local', ref: null};
  }
  const match = projectHost.exec(host);
  if (url.protocol !== 'https:' || !match || url.port) return null;
  return {url, target: 'hosted', ref: match[1]};
}

function publicKey(value) {
  if (typeof value !== 'string' || value !== value.trim() || placeholder.test(value)) {
    return null;
  }
  if (/^sb_publishable_[A-Za-z0-9_-]{20,}$/.test(value)) {
    return {ref: null};
  }
  if (/sb_secret_|service_role/i.test(value)) return null;
  const parts = value.split('.');
  if (parts.length !== 3 || parts.some((part) => !/^[A-Za-z0-9_-]+$/.test(part))) {
    return null;
  }
  try {
    const header = JSON.parse(Buffer.from(parts[0], 'base64url').toString('utf8'));
    const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
    if (!object(header) || !object(payload) || payload.role !== 'anon') return null;
    if ('ref' in payload && (typeof payload.ref !== 'string' || !/^[a-z0-9]{20}$/.test(payload.ref))) {
      return null;
    }
    // This checks key type/project identity only, never a cryptographic claim.
    // Actual authentication belongs to the development backend.
    return {ref: payload.ref ?? null};
  } catch {
    return null;
  }
}

/** Pure validation. Only generic, safe metadata is returned. */
export function validateDevelopmentConfig(config, {productionConfig} = {}) {
  const reasons = [];
  const production = object(productionConfig)
    ? endpoint(productionConfig.SUPABASE_URL)
    : null;
  // A canonical hosted production identity is required even for a local target.
  // Missing/unreadable production configuration never grants an exception.
  if (!production || production.target !== 'hosted') {
    reasons.push('production_identity_unavailable');
  }
  if (!object(config)) {
    reasons.push('development_config_invalid');
    return report(reasons);
  }
  if (Object.keys(config).some((key) => !['SUPABASE_URL', 'SUPABASE_ANON_KEY'].includes(key))) {
    reasons.push('unexpected_config_fields');
  }
  const development = endpoint(config.SUPABASE_URL);
  const key = publicKey(config.SUPABASE_ANON_KEY);
  if (!development) reasons.push('development_endpoint_invalid');
  if (!key) reasons.push('public_key_required');
  if (development && production && (
    development.url.origin === production.url.origin ||
    development.url.hostname === production.url.hostname ||
    (development.ref && development.ref === production.ref)
  )) {
    reasons.push('production_target_forbidden');
  }
  if (production && typeof productionConfig.SUPABASE_ANON_KEY === 'string' &&
      config.SUPABASE_ANON_KEY === productionConfig.SUPABASE_ANON_KEY) {
    reasons.push('production_key_forbidden');
  }
  if (key?.ref && production && key.ref === production.ref) {
    reasons.push('production_key_forbidden');
  }
  if (key?.ref && development?.ref && key.ref !== development.ref) {
    reasons.push('key_project_mismatch');
  }
  return report(reasons, development?.target ?? null);
}

function samePath(left, right) {
  return process.platform === 'win32'
    ? left.toLowerCase() === right.toLowerCase()
    : left === right;
}

function sameFile(left, right) {
  return left.dev === right.dev && left.ino === right.ino;
}

async function guardedRead(projectRoot, filename) {
  const path = resolve(projectRoot, 'config', filename);
  let cursor = parse(path).root;
  const components = relative(cursor, path).split(sep);
  let initial;
  // Check all parents as well as the file: a config directory junction must not
  // silently redirect either fixed filename to another environment.
  for (let index = 0; index < components.length; index++) {
    cursor = join(cursor, components[index]);
    const stat = await lstat(cursor, {bigint: true});
    if (stat.isSymbolicLink() ||
        (index < components.length - 1 ? !stat.isDirectory() : !stat.isFile())) {
      throw new Error('unsafe_path');
    }
    initial = stat;
  }
  if (initial.nlink !== 1n || initial.size > BigInt(maxConfigBytes) ||
      !samePath(await realpath(path), path)) {
    throw new Error('unsafe_path');
  }
  const handle = await open(path, constants.O_RDONLY | (constants.O_NOFOLLOW ?? 0));
  try {
    const opened = await handle.stat({bigint: true});
    if (!opened.isFile() || !sameFile(opened, initial) ||
        opened.nlink !== 1n || opened.size > BigInt(maxConfigBytes)) {
      throw new Error('unsafe_path');
    }
    const text = await handle.readFile({encoding: 'utf8'});
    const after = await lstat(path, {bigint: true});
    if (after.isSymbolicLink() || !sameFile(after, opened) ||
        !samePath(await realpath(path), path) || Buffer.byteLength(text) > maxConfigBytes) {
      throw new Error('unsafe_path');
    }
    return JSON.parse(text.replace(/^\uFEFF/, ''));
  } finally {
    await handle.close();
  }
}

/**
 * Reads only the two fixed config files. Invalid configs never leave the guard.
 * `config` is for in-memory consumers; never include it in logs or JSON reports.
 */
export async function loadValidatedDevelopmentConfig({projectRoot = defaultProjectRoot} = {}) {
  let productionConfig, config;
  const reasons = [];
  if (typeof projectRoot !== 'string' || !isAbsolute(projectRoot) ||
      /^(?:\\\\|\/\/)/.test(projectRoot)) {
    return {report: report(['project_root_invalid']), config: null, productionOrigin: null};
  }
  try {
    productionConfig = await guardedRead(projectRoot, productionFile);
  } catch {
    reasons.push('production_config_unreadable_or_unsafe');
  }
  try {
    config = await guardedRead(projectRoot, developmentFile);
  } catch {
    reasons.push('development_config_unreadable_or_unsafe');
  }
  const validation = validateDevelopmentConfig(config, {productionConfig});
  const result = report([...reasons, ...validation.reasons], validation.target);
  return {
    report: result,
    productionOrigin: result.ok ? new URL(productionConfig.SUPABASE_URL).origin : null,
    config: result.ok ? {
      SUPABASE_URL: new URL(config.SUPABASE_URL).origin,
      SUPABASE_ANON_KEY: config.SUPABASE_ANON_KEY,
    } : null,
  };
}

export async function checkDevelopmentConfig(options) {
  return (await loadValidatedDevelopmentConfig(options)).report;
}

export class PilotConfigError extends Error {
  constructor(reasons) {
    super('Development pilot configuration blocked.');
    this.name = 'PilotConfigError';
    this.reasons = reasons;
  }
}

// Convenience API for consumers that prefer a thrown safe failure.
export async function loadDevelopmentConfig(options) {
  const {report: result, config} = await loadValidatedDevelopmentConfig(options);
  if (!result.ok) throw new PilotConfigError(result.reasons);
  return {
    supabaseUrl: config.SUPABASE_URL,
    supabaseAnonKey: config.SUPABASE_ANON_KEY,
    environment: result.target === 'local' ? 'local' : 'development',
  };
}

if (process.argv[1] && samePath(resolve(process.argv[1]), fileURLToPath(import.meta.url))) {
  const result = process.argv.length === 3 && process.argv[2] === '--check'
    ? await checkDevelopmentConfig()
    : report(['unsupported_arguments']);
  process.stdout.write(`${JSON.stringify(result)}\n`);
  process.exitCode = result.ok ? 0 : 1;
}
