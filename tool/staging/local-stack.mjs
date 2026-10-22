import {spawnSync,spawn} from 'node:child_process';
import {mkdirSync,writeFileSync,readFileSync,existsSync,readdirSync,chmodSync,openSync,closeSync,lstatSync} from 'node:fs';
import {randomBytes,createHash} from 'node:crypto';
import {join,resolve} from 'node:path';
import {createServer} from 'node:net';
import {assertOwnedRuntime,assertLocalUrl,childEnvironment,runtimeRoot} from './guard.mjs';
const hash=x=>createHash('sha256').update(x).digest('hex');
const base=resolve('tool/staging');
const lock=()=>JSON.parse(readFileSync(join(base,'network-image.lock.json')));
export function docker(args,allowFailure=false) {
 const r=spawnSync('docker',args,{env:childEnvironment(),encoding:'utf8',maxBuffer:64*1024*1024});
 if(r.error||(!allowFailure&&r.status!==0))throw Error('Docker operation failed: '+args.slice(0,2).join(' '));return r;
}
const inspect=name=>JSON.parse(docker(['inspect',name]).stdout)[0];
function save(path,name,data) {writeFileSync(join(path,name),JSON.stringify(data,null,2)+'\n',{mode:0o600,flag:'wx'});}
async function available(p) {return new Promise(r=>{const s=createServer();s.once('error',()=>r(false));s.listen(p,'127.0.0.1',()=>s.close(()=>r(true)));});}
export function overlaps(a,b){
 const range=x=>{const [ip,prefix]=x.split('/');const p=Number(prefix),oct=ip.split('.').map(Number);if(prefix===undefined||!Number.isInteger(p)||p<0||p>32||oct.length!==4||oct.some(o=>!Number.isInteger(o)||o<0||o>255))throw Error('Invalid IPv4 subnet');const value=oct.reduce((v,o)=>(v<<8n)+BigInt(o),0n);const size=1n<<BigInt(32-p),start=value/size*size;return [start,start+size-1n];};const [as,ae]=range(a),[bs,be]=range(b);return as<=be&&bs<=ae;
}
export async function prepare() {
 process.umask(0o077);
 mkdirSync(runtimeRoot,{recursive:true,mode:0o700});const root=lstatSync(runtimeRoot);if(root.isSymbolicLink()||(root.mode&0o077)||root.uid!==process.getuid())throw Error('Private owned runtime root required');
 let port;for(const p of [61001,62001,63001]) {let free=true;for(const n of [p,p+1,p+2,p+3,p+4])free=(await available(n))&&free;if(free){port=p;break;}}
 if(!port)throw Error('Approved port sets unavailable');
 const id='marea-task001-'+randomBytes(6).toString('hex'),path=join(runtimeRoot,id);
 mkdirSync(path,{mode:0o700});mkdirSync(join(path,'bin'),{mode:0o700});mkdirSync(join(path,'relay'),{mode:0o755});chmodSync(join(path,'relay'),0o755);
 const marker={version:2,project_id:id,network:id,ingress_network:id+'-ingress',api_port:port,db_port:port+1,mail_port:port+3,network_image:lock().image_id};
 const init=spawnSync('supabase',['init','--workdir',path],{env:childEnvironment(),encoding:'utf8'});
 writeFileSync(join(path,'init-private.log'),init.stdout+init.stderr,{mode:0o600});if(init.status!==0)throw Error('Init failed');
 chmodSync(join(path,'supabase'),0o700);
 const config=`project_id = "${id}"
[api]
enabled = true
port = ${port}
schemas = ["public", "graphql_public"]
extra_search_path = ["public", "extensions"]
[db]
port = ${port+1}
shadow_port = ${port+2}
major_version = 17
[db.pooler]
enabled = false
[db.migrations]
enabled = false
schema_paths = []
[db.seed]
enabled = false
sql_paths = []
[realtime]
enabled = true
[studio]
enabled = false
[inbucket]
enabled = true
port = ${port+3}
[storage]
enabled = true
file_size_limit = "50MiB"
[auth]
enabled = true
site_url = "http://127.0.0.1:${port+4}"
additional_redirect_urls = []
jwt_expiry = 60
enable_signup = true
enable_anonymous_sign_ins = false
[auth.email]
enable_signup = true
enable_confirmations = false
[edge_runtime]
enabled = false
[analytics]
enabled = false
`;
 writeFileSync(join(path,'supabase/config.toml'),config,{mode:0o600});marker.config_sha256=hash(config);save(path,'.marea-task001.json',marker);
 const realDocker=spawnSync('/usr/bin/which',['docker'],{encoding:'utf8'}).stdout.trim();
 save(path,'.docker-preserve-private.json',{docker:realDocker,project:id,network:id,image:marker.network_image});
 writeFileSync(join(path,'bin/docker'),readFileSync(join(base,'docker-preserve.py')),{mode:0o700});
 assertOwnedRuntime(path);save(path,'prepare-receipt.json',{result:'PASS',at:new Date().toISOString(),project_id:id,ports:{api:port,db:port+1,mail:port+3},schema:'EMPTY',remote_modified:false});
 return {result:'PASS',runtime:path,project_id:id};
}
function services(m) {const ids=docker(['ps','-aq','--filter','label=com.supabase.cli.project='+m.project_id]).stdout.trim().split('\n').filter(Boolean);return ids.length?JSON.parse(docker(['inspect',...ids]).stdout):[];}
function firewall(path,m,subnet,targets=null) {
 const name=m.project_id+'-net-admin-'+Date.now();
 let script='iptables -P OUTPUT DROP; iptables -F OUTPUT; iptables -P FORWARD DROP; ip6tables -P OUTPUT DROP; ip6tables -F OUTPUT; ip6tables -P FORWARD DROP; iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT;';
 for(const t of targets||[])script+=`iptables -A OUTPUT -p tcp -d ${t.ip} --dport ${t.port} -j ACCEPT;`;
 script+='iptables-save; ip6tables-save;';
 let r;try{r=docker(['run','--name',name,'--label','marea.task001.owner='+m.project_id,'--network','container:'+m.project_id+'-relay','--user','0:0','--read-only','--cap-drop','ALL','--cap-add','NET_ADMIN','--security-opt','no-new-privileges','--entrypoint','/bin/sh',m.network_image,'-ec',script],true);
 }finally{if(r)writeFileSync(join(path,'firewall-'+name+'.log'),r.stdout+r.stderr,{mode:0o600});const found=docker(['inspect','--type','container',name],true);if(found.status===0){const c=JSON.parse(found.stdout)[0];if(c.Config.Labels?.['marea.task001.owner']!==m.project_id)throw Error('Foreign helper cleanup refused');docker(['rm','-f',name]);}}
 if(!r||r.status!==0||docker(['inspect','--type','container',name],true).status===0)throw Error('Relay firewall/cleanup failed; no business permitted');
 return {helper_removed:true,rules:r.stdout};
}
function updateRoutes(path,m,subnet) {
 const routes={};for(const c of services(m)) {
  if(Object.keys(c.NetworkSettings.Networks).some(n=>n!==m.network))throw Error('External network on service');
  const addr=c.NetworkSettings.Networks[m.network]?.IPAddress;
  const type=c.Name.startsWith('/supabase_db_')?[61002,5432]:c.Name.startsWith('/supabase_kong_')?[61001,8000]:c.Name.startsWith('/supabase_inbucket_')?[61004,8025]:null;
  if(type&&addr)routes[type[0]]={ip:addr,port:type[1]};
 }
 writeFileSync(join(path,'relay/routes.json'),JSON.stringify({internal_subnet:subnet,routes}),{mode:0o644});chmodSync(join(path,'relay/routes.json'),0o644);return routes;
}
export async function start(path) {
 const m=assertOwnedRuntime(path);if(m.network_image!==lock().image_id)throw Error('Network image drift');if(existsSync(join(path,'.task001-blocked.json')))throw Error('Blocked runtime preserved; prepare a new one');
 if(existsSync(join(path,'start-receipt.json')))throw Error('Already initialized; use report');
 const subnet=`172.30.${Math.floor(m.api_port/1000)}.0/24`;
 // Refuse overlap rather than modifying an existing network or selecting a foreign stack.
 for(const nid of docker(['network','ls','-q']).stdout.split(/\s+/).filter(Boolean)) {
  const n=JSON.parse(docker(['network','inspect',nid]).stdout)[0];
  if(n.IPAM?.Config?.some(c=>c.Subnet&&!c.Subnet.includes(':')&&overlaps(c.Subnet,subnet)))throw Error('Owned subnet conflict');
 }
 docker(['network','create','--internal','--opt','com.docker.network.bridge.gateway_mode_ipv4=isolated','--opt','com.docker.network.bridge.host_binding_ipv4=127.0.0.1','--subnet',subnet,'--label','marea.task001.owner='+m.project_id,m.network]);
 docker(['network','create','--opt','com.docker.network.bridge.host_binding_ipv4=127.0.0.1','--label','marea.task001.owner='+m.project_id,m.ingress_network]);
 docker(['run','-d','--name',m.project_id+'-relay','--label','marea.task001.owner='+m.project_id,'--network',m.ingress_network,'--user','10001:10001','--read-only','--cap-drop','ALL','--security-opt','no-new-privileges','--mount',`type=bind,src=${join(path,'relay')},dst=/config,readonly`,'-p',`127.0.0.1:${m.api_port}:61001`,'-p',`127.0.0.1:${m.db_port}:61002`,'-p',`127.0.0.1:${m.mail_port}:61004`,m.network_image]);
 docker(['network','connect',m.network,m.project_id+'-relay']);
 const initial=firewall(path,m,subnet);writeFileSync(join(path,'relay/firewall-ready'),'configured',{mode:0o644});
 const fd=openSync(join(path,'start-private.log'),'wx',0o600);
 const child=spawn('supabase',['start','--workdir',path,'--network-id',m.network,'--exclude','edge-runtime,studio,logflare,vector,supavisor'],{env:{...childEnvironment(),PATH:join(path,'bin')+':'+process.env.PATH},stdio:['ignore',fd,fd]});
 let finished=false,observations=[],watcherError,lastRoutes='';
 const exit=new Promise((resolve,reject)=>{child.once('error',reject);child.once('exit',code=>{finished=true;resolve(code);});});
 const watcher=(async()=>{try{while(!finished){const routes=updateRoutes(path,m,subnet);if(JSON.stringify(routes)!==lastRoutes){firewall(path,m,subnet,Object.values(routes));lastRoutes=JSON.stringify(routes);}observations.push({at:new Date().toISOString(),routes:Object.keys(routes)});await new Promise(r=>setTimeout(r,250));}}catch(e){watcherError=true;child.kill('SIGTERM');save(path,'route-blocked-'+Date.now()+'.json',{at:new Date().toISOString(),reason:'Route watcher failed; graceful stop requested; no business permitted'});}})();
 const code=await exit;await watcher;closeSync(fd);
 if(code!==0||watcherError){save(path,'.task001-blocked.json',{at:new Date().toISOString(),reason:'Supabase start failed; retained volumes and private diagnostics',exit_code:code});throw Error('Supabase start failed; preserved runtime');}
 const routes=updateRoutes(path,m,subnet);if(Object.keys(routes).length!==3)throw Error('Missing relay upstream');
 const final=firewall(path,m,subnet,Object.values(routes));
 const status=spawnSync('supabase',['status','--workdir',path,'-o','json'],{env:childEnvironment(),encoding:'utf8'});if(status.status!==0)throw Error('Status failed');
 const keys=JSON.parse(status.stdout);assertLocalUrl(keys.API_URL,m.api_port);save(path,'local-keys-private.json',keys);
 const cs=services(m);for(const c of cs)if(!c.State.Running||(c.State.Health&&c.State.Health.Status!=='healthy'))throw Error('Unhealthy service');
 const relay=inspect(m.project_id+'-relay');for(const ports of Object.values(relay.NetworkSettings.Ports))for(const p of ports||[])if(p.HostIp!=='127.0.0.1')throw Error('Non-loopback bind');
 const r=await fetch(`http://127.0.0.1:${m.api_port}/auth/v1/health`,{headers:{apikey:keys.ANON_KEY},redirect:'error',signal:AbortSignal.timeout(5000)});if(!r.ok)throw Error('Auth health failed');
 save(path,'start-receipt.json',{at:new Date().toISOString(),result:'PASS',project_id:m.project_id,internal_subnet:subnet,services:cs.map(c=>({name:c.Name,image:c.Image,health:c.State.Health?.Status||'running',networks:Object.keys(c.NetworkSettings.Networks),published:c.NetworkSettings.Ports})),relay:{image:relay.Image,ports:relay.NetworkSettings.Ports,cap_add:relay.HostConfig.CapAdd,privileged:relay.HostConfig.Privileged},firewall:{initial,final},volume_retention:true,remote_modified:false,business_isolation:'Behavioral tests required before H4',bootstrap_observations:observations});
 return {result:'PASS',project_id:m.project_id,healthy_services:cs.length,isolation:'Behavioral verification pending'};
}
export function report(path) {
 const m=assertOwnedRuntime(path);return {project_id:m.project_id,healthy:existsSync(join(path,'start-receipt.json')),isolation_verified:existsSync(join(path,'isolation-receipt.json')),schema_ready:existsSync(join(path,'schema-receipt.json')),blocked:existsSync(join(path,'.task001-blocked.json')),remote_modified:false};
}
export async function stop(path) {
 const m=assertOwnedRuntime(path);for(const c of services(m))if(Object.keys(c.NetworkSettings.Networks).some(n=>n!==m.network))throw Error('Foreign attachment; stop refused');
 const pidFile=join(path,'functions-cli-pid-private.json');if(existsSync(pidFile)){const rec=JSON.parse(readFileSync(pidFile));if(rec.project!==m.project_id||!Number.isInteger(rec.pid)||rec.pid<=1)throw Error('Foreign function process; stop refused');const ps=spawnSync('ps',['-p',String(rec.pid),'-o','command='],{encoding:'utf8'}).stdout.trim();if(ps){if(!ps.includes('functions serve')||!ps.includes(path))throw Error('Foreign function process; stop refused');process.kill(rec.pid,'SIGTERM');for(let i=0;i<120;i++){if(docker(['inspect','--type','container','supabase_edge_runtime_'+m.project_id],true).status!==0)break;await new Promise(r=>setTimeout(r,500));}if(docker(['inspect','--type','container','supabase_edge_runtime_'+m.project_id],true).status===0)throw Error('Graceful functions shutdown pending; stack retained');}}

 for(const c of services(m))docker(['stop',c.Id]);
 const relay=docker(['inspect',m.project_id+'-relay'],true);if(relay.status===0)docker(['stop',m.project_id+'-relay']);
 return {result:'PASS',volumes_preserved:true,retainers_preserved:true};
}
