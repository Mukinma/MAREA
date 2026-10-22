// Explicit, owned healthy runtime only. Preserve every prior artifact before configured-secret restart.
import {readFileSync,renameSync,existsSync,writeFileSync} from 'node:fs';
import {join,resolve} from 'node:path';
import {spawnSync} from 'node:child_process';
import {assertOwnedRuntime,childEnvironment} from './guard.mjs';
import {docker} from './local-stack.mjs';
const path=resolve(process.argv[2]||''),m=assertOwnedRuntime(path),stamp=Date.now();
if(existsSync(join(path,'.task001-blocked.json')))throw Error('Blocked runtime cannot restart');
const rec=JSON.parse(readFileSync(join(path,'functions-cli-pid-private.json')));const ps=spawnSync('ps',['-p',String(rec.pid),'-o','command='],{encoding:'utf8'}).stdout;
if(rec.project!==m.project_id||(ps.trim()&&(!ps.includes('functions serve')||!ps.includes(path))))throw Error('Foreign process; restart refused');
let c;const initial=docker(['inspect','--type','container','supabase_edge_runtime_'+m.project_id],true);if(initial.status===0){c=JSON.parse(initial.stdout)[0];if(Object.keys(c.NetworkSettings.Networks).join()!==m.network)throw Error('Foreign network');}
if(ps.trim())process.kill(rec.pid,'SIGTERM');
for(let i=0;i<600;i++){if(docker(['inspect','--type','container','supabase_edge_runtime_'+m.project_id],true).status!==0)break;await new Promise(r=>setTimeout(r,100));}
if(docker(['inspect','--type','container','supabase_edge_runtime_'+m.project_id],true).status===0)throw Error('CLI did not stop; preserved state; no forced cleanup');
for(const file of ['functions-cli-pid-private.json','functions-serve-receipt.json','functions-serve-private.log'])renameSync(join(path,file),join(path,'before-secret-restart-'+stamp+'-'+file));
writeFileSync(join(path,'functions-restart-receipt-'+stamp+'.json'),JSON.stringify({id:'E-TASK001-EDGE-RESTART-'+stamp,at:new Date().toISOString(),result:'PASS',reason:'Synthetic worker secrets configured explicitly; no provider credentials; runtime source unchanged',old_container:c?.Id||'already stopped by previously requested graceful CLI shutdown',private_snapshots_preserved:true,remote_modified:false}),{flag:'wx',mode:0o600});
const r=spawnSync('node',['tool/staging/functions-serve.mjs',path],{env:childEnvironment(),encoding:'utf8'});if(r.status!==0)throw Error('Owned Edge restart failed; diagnostics retained');console.log(r.stdout.trim());
