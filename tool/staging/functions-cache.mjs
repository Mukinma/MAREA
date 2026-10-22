// Infrastructure-only compilation: no evaluated handlers, secrets or provider credentials.
import {readFileSync,writeFileSync,openSync,closeSync,existsSync,mkdirSync} from 'node:fs';
import {join,resolve} from 'node:path';
import {spawnSync} from 'node:child_process';
import {assertOwnedRuntime,childEnvironment} from './guard.mjs';
import {docker} from './local-stack.mjs';
const path=resolve(process.argv[2]||''),m=assertOwnedRuntime(path),stamp=Date.now();
if(!existsSync(join(path,'supabase/functions/profile-media/index.ts')))throw Error('Reviewed function copy required');
const image='denoland/deno@sha256:3bf75873714baa410dcf7fabaf76d806d20f0ac8a7579df11577b4ed97416e34';
const names=['delete-account','profile-media','send-push','tour-dispatch','story-cleanup','geocoding'];
const volume='supabase_edge_runtime_'+m.project_id;
const deps=join(path,'dependency-locks');mkdirSync(deps,{recursive:true,mode:0o700});
const pinnedLock=readFileSync('tool/staging/functions-dependencies.lock.json');const lockPath=join(deps,'functions-deno.lock');if(existsSync(lockPath))writeFileSync(join(deps,'before-frozen-'+stamp+'.lock'),readFileSync(lockPath),{flag:'wx',mode:0o600});writeFileSync(lockPath,pinnedLock,{mode:0o600});
const fd=openSync(join(path,'cache-private-'+stamp+'.log'),'wx',0o600);
const r=spawnSync('docker',['run','--pull','never','--name',m.project_id+'-type-cache-'+stamp,'--label','marea.task001.owner='+m.project_id,'--network',m.ingress_network,'--cap-drop','ALL','--security-opt','no-new-privileges','-e','DENO_DIR=/root/.cache/deno','--mount',`type=bind,src=${join(path,'supabase/functions')},dst=/src,readonly`,'--mount',`type=bind,src=${deps},dst=/receipt`,'--mount',`type=volume,src=${volume},dst=/root/.cache/deno`,image,'cache','--no-config','--lock=/receipt/functions-deno.lock','--frozen','npm:@types/node@22.5.4',...names.map(n=>'/src/'+n+'/index.ts')],{env:childEnvironment(),stdio:['ignore',fd,fd]});closeSync(fd);
if(r.status!==0)throw Error('Dependency graph caching failed; private log preserved');
writeFileSync(join(path,'functions-cache-receipt-'+stamp+'.json'),JSON.stringify({at:new Date().toISOString(),result:'PASS',modality:'real',image,command:'deno cache --no-config --lock (six original entrypoints)',handler_execution:false,credentials_supplied:false,remote_modified:false}),{flag:'wx',mode:0o600});
console.log(JSON.stringify({result:'PASS',functions:6,handler_execution:false}));
