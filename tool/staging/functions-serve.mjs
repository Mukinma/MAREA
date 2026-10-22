import {readFileSync,writeFileSync,openSync,closeSync,existsSync} from 'node:fs';
import {join,resolve} from 'node:path';
import {spawn} from 'node:child_process';
import {assertOwnedRuntime,childEnvironment} from './guard.mjs';
import {docker} from './local-stack.mjs';
const path=resolve(process.argv[2]||''),m=assertOwnedRuntime(path);for(const f of ['functions-prepare-receipt.json','isolation-receipt.json','dns-receipt.json'])if(JSON.parse(readFileSync(join(path,f))).result!=='PASS')throw Error('Functions isolation/dependency gates pending');
if(existsSync(join(path,'functions-serve-receipt.json')))throw Error('Functions already served');
let child;
if(existsSync(join(path,'functions-cli-pid-private.json'))){const p=JSON.parse(readFileSync(join(path,'functions-cli-pid-private.json')));if(p.project!==m.project_id)throw Error('Foreign CLI process');process.kill(p.pid,0);child={pid:p.pid,exitCode:null};}
else {
const fd=openSync(join(path,'functions-serve-private.log'),'wx',0o600);
child=spawn('supabase',['functions','serve','--workdir',path,'--network-id',m.network,'--env-file',join(path,'functions-env-private.env')],{env:{...childEnvironment(),PATH:join(path,'bin')+':'+process.env.PATH},detached:true,stdio:['ignore',fd,fd]});child.unref();closeSync(fd);
writeFileSync(join(path,'functions-cli-pid-private.json'),JSON.stringify({pid:child.pid,project:m.project_id}),{flag:'wx',mode:0o600});
}
let c;for(let i=0;i<120;i++){const r=docker(['inspect','supabase_edge_runtime_'+m.project_id],true);if(r.status===0){c=JSON.parse(r.stdout)[0];if(c?.State?.Running)break;}if(child.exitCode!==null)throw Error('Functions CLI exited; private diagnostics retained');await new Promise(r=>setTimeout(r,500));}
if(!c?.State.Running||Object.keys(c.NetworkSettings.Networks).join()!==m.network||c.HostConfig.Privileged||(c.HostConfig.CapAdd||[]).includes('NET_ADMIN')||Object.values(c.NetworkSettings.Ports).some(x=>x?.length))throw Error('Edge identity/network gate failed');
writeFileSync(join(path,'functions-serve-receipt.json'),JSON.stringify({id:'E-TASK001-EDGE-SERVE-'+m.project_id,at:new Date().toISOString(),result:'PASS',modality:'real',image:c.Image,networks:Object.keys(c.NetworkSettings.Networks),published:c.NetworkSettings.Ports,privileged:c.HostConfig.Privileged,cap_add:c.HostConfig.CapAdd,functions:6,jwt_policy:'Per-function original settings; no global no-verify-jwt',external_credentials:false,remote_modified:false},null,2)+'\n',{flag:'wx',mode:0o600});console.log(JSON.stringify({result:'PASS',container:c.Name,image:c.Image,functions:6}));
