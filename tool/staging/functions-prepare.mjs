import {mkdirSync,readFileSync,writeFileSync,readdirSync,lstatSync,chmodSync,openSync,closeSync} from 'node:fs';
import {join,resolve} from 'node:path';
import {createHash,randomBytes} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {assertOwnedRuntime,childEnvironment} from './guard.mjs';
import {docker} from './local-stack.mjs';
const path=resolve(process.argv[2]||'');const m=assertOwnedRuntime(path);const image='public.ecr.aws/supabase/edge-runtime@sha256:c52405002a890ca9fcf77978671c57f3a988e03174afb277f84ac65bc917013c';
const functions=['delete-account','profile-media','send-push','tour-dispatch','story-cleanup','geocoding'];
const hashes=[];mkdirSync(join(path,'supabase/functions'),{mode:0o700});mkdirSync(join(path,'bundles'),{mode:0o700});
for(const name of functions){const target=join(path,'supabase/functions',name);mkdirSync(target,{mode:0o700});for(const file of readdirSync('supabase/functions/'+name).filter(f=>f.endsWith('.ts')&&!f.endsWith('_test.ts'))){const source=join('supabase/functions',name,file);if(!lstatSync(source).isFile())throw Error('Only regular reviewed function files');const b=readFileSync(source);writeFileSync(join(target,file),b,{flag:'wx',mode:0o600});hashes.push({path:source,sha256:createHash('sha256').update(b).digest('hex')});}}
const volume='supabase_edge_runtime_'+m.project_id;docker(['volume','create','--label','com.supabase.cli.project='+m.project_id,'--label','marea.task001.owner='+m.project_id,volume]);
// Freeze the full graph before offline compilation; code-only helper receives no credentials.
const cached=spawnSync('node',['tool/staging/functions-cache.mjs',path],{env:childEnvironment(),encoding:'utf8'});if(cached.status!==0)throw Error('Pinned dependency preparation failed; diagnostics retained');
// Infrastructure-only compilation also fills Edge-specific JSR manifests; no handlers or credentials.
// Exact bundle fingerprints below must equal the recorded baseline before any serve.
const fd=openSync(join(path,'bundle-private.log'),'wx',0o600);const command=functions.map(n=>`edge-runtime bundle --entrypoint /src/${n}/index.ts --output /bundles/${n}.eszip --timeout 120`).join(' && ');
const r=spawnSync('docker',['run','--pull','never','--name',m.project_id+'-edge-cache-'+Date.now(),'--label','marea.task001.owner='+m.project_id,'--network',m.ingress_network,'--cap-drop','ALL','--security-opt','no-new-privileges','--mount',`type=bind,src=${join(path,'supabase/functions')},dst=/src,readonly`,'--mount',`type=bind,src=${join(path,'bundles')},dst=/bundles`,'--mount',`type=volume,src=${volume},dst=/root/.cache/deno`,'--entrypoint','/bin/sh',image,'-ec',command],{env:childEnvironment(),stdio:['ignore',fd,fd]});closeSync(fd);
if(r.status!==0)throw Error('Official Edge dependency preparation failed; log retained, functions not served');
const lockedBundles=JSON.parse(readFileSync('tool/staging/functions-bundles.lock.json'));for(const b of lockedBundles.bundles)if(createHash('sha256').update(readFileSync(join(path,'bundles',b.file))).digest('hex')!==b.sha256)throw Error('Bundle drift; no functions served');
const config=join(path,'supabase/config.toml'),original=readFileSync(config,'utf8');writeFileSync(join(path,'config-before-functions-private.toml'),original,{flag:'wx',mode:0o600});
const extra=functions.map(n=>`\n[functions.${n}]\nverify_jwt = ${['delete-account','profile-media'].includes(n)}\n`).join('');writeFileSync(config,original+extra,{mode:0o600});m.config_sha256=createHash('sha256').update(original+extra).digest('hex');writeFileSync(join(path,'.marea-task001.json'),JSON.stringify(m,null,2)+'\n',{mode:0o600});assertOwnedRuntime(path);
const secrets=Object.fromEntries(['PUSH_WORKER_SECRET','TOUR_WORKER_SECRET','STORY_WORKER_SECRET'].map(n=>[n,randomBytes(32).toString('base64url')]));
writeFileSync(join(path,'worker-secrets-private.json'),JSON.stringify(secrets),{flag:'wx',mode:0o600});
writeFileSync(join(path,'functions-env-private.env'),Object.entries(secrets).map(([k,v])=>k+'='+v).join('\n')+'\n',{flag:'wx',mode:0o600});
writeFileSync(join(path,'functions-prepare-receipt.json'),JSON.stringify({id:'E-TASK001-EDGE-PREPARE-'+m.project_id,at:new Date().toISOString(),result:'PASS',image,source_hashes:hashes,bundles:readdirSync(join(path,'bundles')).map(n=>({file:n,sha256:createHash('sha256').update(readFileSync(join(path,'bundles',n))).digest('hex')})),dependency_execution:'Compilation only; handlers never evaluated; no secrets supplied',config_overlay:'Per-function JWT flags from reviewed production config; no global disable',remote_modified:false},null,2)+'\n',{flag:'wx',mode:0o600});console.log(JSON.stringify({result:'PASS',functions:functions.length,image}));
