// Read-only source inventory. This is not a SQL parser or a deployed-schema attestation.
import {readFileSync, readdirSync, lstatSync} from 'node:fs';
import {join, relative, resolve} from 'node:path';
import {createHash} from 'node:crypto';
const root = resolve(new URL('../..', import.meta.url).pathname);
const sha = bytes => createHash('sha256').update(bytes).digest('hex');
function walk(path) {
  return readdirSync(path).sort().flatMap(name => {
    const p=join(path,name), s=lstatSync(p);
    if(s.isSymbolicLink()) throw new Error('Source symlink not inspected');
    return s.isDirectory()?walk(p):[p];
  });
}
export function inventory() {
  const files = [...walk(join(root,'supabase','migrations')), ...walk(join(root,'supabase','functions')), join(root,'supabase','config.toml')];
  const sources = files.map(path => {const bytes=readFileSync(path), text=bytes.toString('utf8'); return {path:relative(root,path),sha256:sha(bytes),lines:text.split('\n').length,text};});
  const sql = sources.filter(s=>s.path.endsWith('.sql'));
  const select = expression => sql.flatMap(s => [...s.text.matchAll(expression)].map(m=>({path:s.path,line:s.text.slice(0,m.index).split('\n').length,statement:m[0].trim()})));
  return {
    modality:'inspeccion', deployed_schema_verified:false, equivalence_remote:false,
    source_files:sources.map(({text,...s})=>s),
    destructive_ddl:select(/^\s*(?:drop\s+(?:policy|function|table|trigger|view|index|schema)\b[^;]*;|alter\s+table\b[^;]*\bdrop\s+(?:constraint|column)\b[^;]*;)/gmi),
    jobs:select(/^\s*select\s+cron\.schedule\([^;]*;/gmi),
    tables:select(/create\s+table\s+(?:if\s+not\s+exists\s+)?[\w.]+/gi),
    rls:select(/alter\s+table\s+[\w.]+\s+(?:enable|force)\s+row\s+level\s+security/gi),
    grants:select(/(?:grant|revoke)\s+[^;]+;/gi),
    policies:select(/create\s+policy\s+[^;]+;/gi),
    rpc_declarations:select(/create\s+(?:or\s+replace\s+)?function\s+[\w.]+\([^)]*\)\s+returns\s+[^\n]+/gi),
    realtime:select(/alter\s+publication\s+[^;]+;/gi),
    buckets_expected:['profile-media','post-images','mission-images','showcase-media','story-images','tour-inputs','tour-assets'],
    edge_auth_source:{'delete-account':{verify_jwt:true,actor:'getUser'},'profile-media':{verify_jwt:true,actor:'getUser'},'send-push':{verify_jwt:false,actor:'worker secret'},'tour-dispatch':{verify_jwt:false,actor:'worker secret and Google IAM'},'story-cleanup':{verify_jwt:false,actor:'worker secret'},geocoding:{verify_jwt:false,actor:'search/reverse public; content_city getUser + RLS'}},
    replay_review_requirements:['Review local-object DROP operations before replay','Disable and supervise cron; keep Vault empty and business egress blocked','Record local geocoding-provider disabling separately from original SQL'],
    limits:'Lexical source declarations may include superseded definitions. This command only inspects source, never executes migrations or reflects runtime health. Effective schema and executed results are separate db-inventory and suite receipts.'
  };
}
if (process.argv[1] === new URL(import.meta.url).pathname) console.log(JSON.stringify(inventory(),null,2));
