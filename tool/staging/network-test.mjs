import {blockIsolation} from './proofs.mjs';
import {writeFileSync,readFileSync,existsSync} from 'node:fs';
import {join,resolve} from 'node:path';
import {spawn} from 'node:child_process';
import {createHash} from 'node:crypto';
import {assertOwnedRuntime,childEnvironment} from './guard.mjs';
import {docker} from './local-stack.mjs';
const path=resolve(process.argv[2]||'');const m=assertOwnedRuntime(path);
if(m.version!==2||!existsSync(join(path,'start-receipt.json')))throw Error('Healthy owned relay stack required');
process.once('uncaughtException',()=>{blockIsolation(path,'Isolation infrastructure failure; business prohibited');process.exit(1);});process.once('unhandledRejection',()=>{blockIsolation(path,'Isolation infrastructure failure; business prohibited');process.exit(1);});
const image=JSON.parse(readFileSync('tool/staging/network-image.lock.json')).image_id;
if(m.network_image!==image)throw Error('Network image drift');
const ins=name=>JSON.parse(docker(['inspect',name]).stdout)[0];
const net=JSON.parse(docker(['network','inspect',m.network]).stdout)[0];
if(!net.Internal||net.Labels['marea.task001.owner']!==m.project_id||net.Options['com.docker.network.bridge.gateway_mode_ipv4']!=='isolated'||net.EnableIPv6)throw Error('Isolation topology drift');
const stamp=Date.now();const canary=m.project_id+'-canary';
if(docker(['inspect','--type','container',canary],true).status!==0) 
docker(['run','-d','--name',canary,'--label','marea.task001.owner='+m.project_id,'--network',m.ingress_network,'--read-only','--cap-drop','ALL','--security-opt','no-new-privileges','--entrypoint','python',image,'-B','-c',"import http.server; http.server.HTTPServer(('0.0.0.0',8080),http.server.SimpleHTTPRequestHandler).serve_forever()"]);
const canaryIp=ins(canary).NetworkSettings.Networks[m.ingress_network].IPAddress;
const dbIp=ins('supabase_db_'+m.project_id).NetworkSettings.Networks[m.network].IPAddress;
const script=`import socket,json,sys,time
socket.setdefaulttimeout(1)
out=[]
for label,host,port,want in json.loads(sys.argv[1]):
 t=time.monotonic();s=None
 try:
  s=socket.create_connection((host,port),1);ok=True;reason='CONNECTED'
 except OSError as e:ok=False;reason=e.errno or str(e)
 finally:
  if s:s.close()
 out.append({'case':label,'connected':ok,'expected_connected':want,'result':'PASS' if ok==want else 'FAIL','reason':reason,'seconds':round(time.monotonic()-t,3)})
print(json.dumps(out))`;
let seq=0;
async function probe(ns,targets) {
 const args=['run','--name',m.project_id+'-probe-'+stamp+'-'+seq++,'--label','marea.task001.owner='+m.project_id,'--network',ns,'--user','10001:10001','--read-only','--cap-drop','ALL','--security-opt','no-new-privileges','--entrypoint','python',image,'-B','-c',script,JSON.stringify(targets)];
 const r=await new Promise((resolve,reject)=>{const p=spawn('docker',args,{env:childEnvironment(),stdio:['ignore','pipe','pipe']});let out='',err='';p.stdout.on('data',b=>out+=b);p.stderr.on('data',b=>err+=b);p.on('error',reject);p.on('exit',code=>resolve({code,out,err}));});
 if(r.code!==0)throw Error('Namespace probe failed; private diagnostics retained');return JSON.parse(r.out);
}
let control;
for(let i=0;i<10;i++){control=await probe(m.ingress_network,[['reachable-canary',canaryIp,8080,true],['reachable-host-control','host.docker.internal',61202,true]]);if(control.every(x=>x.result==='PASS'))break;await new Promise(r=>setTimeout(r,250));}
if(!control.every(x=>x.result==='PASS'))throw Error('Negative control target is not demonstrably reachable');
const ids=docker(['ps','-aq','--filter','label=com.supabase.cli.project='+m.project_id]).stdout.split(/\s+/).filter(Boolean);
const cs=JSON.parse(docker(['inspect',...ids]).stdout);const relay=ins(m.project_id+'-relay');
const results=[];
for(const c of [...cs,relay]) {
 const isRelay=c.Id===relay.Id;
 if(c.HostConfig.Privileged||(c.HostConfig.CapAdd||[]).includes('NET_ADMIN'))throw Error('Temporary network privilege retained');
 if(!isRelay && (Object.keys(c.NetworkSettings.Networks).length!==1||!c.NetworkSettings.Networks[m.network]))throw Error('Foreign service network');
 const extra=isRelay?[['allowed-local-kong',ins('supabase_kong_'+m.project_id).NetworkSettings.Networks[m.network].IPAddress,8000,true],['allowed-local-mail',ins('supabase_inbucket_'+m.project_id).NetworkSettings.Networks[m.network].IPAddress,8025,true]]:[];
 const cases=await probe('container:'+c.Id,[...extra,['allowed-local-postgres',dbIp,5432,true],['denied-ingress-canary',canaryIp,8080,false],['denied-host','host.docker.internal',61202,false],['denied-bridge-gateway',net.IPAM.Config[0].Gateway||net.IPAM.Config[0].Subnet.replace('.0/24','.1'),61202,false],['denied-external-ipv4','1.1.1.1',443,false],['denied-external-ipv6','2606:4700:4700::1111',443,false]]);
 results.push({name:c.Name,namespace:c.Id,privileged:c.HostConfig.Privileged,cap_add:c.HostConfig.CapAdd||[],cases});
}
// Read rules with a temporary namespace-only helper, then remove it immediately.
const helper=m.project_id+'-net-admin-proof-'+stamp;let rules;
try{rules=docker(['run','--name',helper,'--label','marea.task001.owner='+m.project_id,'--network','container:'+relay.Id,'--user','0:0','--read-only','--cap-drop','ALL','--cap-add','NET_ADMIN','--security-opt','no-new-privileges','--entrypoint','/bin/sh',image,'-ec','iptables-save -c; ip6tables-save -c;'],true);
}finally{if(rules)writeFileSync(join(path,'firewall-proof-private-'+stamp+'.log'),rules.stdout+rules.stderr,{flag:'wx',mode:0o600});const found=docker(['inspect','--type','container',helper],true);if(found.status===0){const c=JSON.parse(found.stdout)[0];if(c.Config.Labels?.['marea.task001.owner']!==m.project_id)throw Error('Foreign helper removal refused');docker(['rm','-f',helper]);}}
const helperRemoved=docker(['inspect','--type','container',helper],true).status!==0;if(!rules||rules.status!==0||!helperRemoved)throw Error('Namespace proof/privilege cleanup failed');
const allPass=helperRemoved&&results.every(r=>r.cases.every(c=>c.result==='PASS'));
const receipt={id:'E-TASK001-ISOLATION-'+m.project_id,captured_at:new Date().toISOString(),result:allPass?'PASS':'BLOQUEADO',modality:'real',project_id:m.project_id,network:{internal:true,gateway_mode:'isolated',ipv6:false},controls:control,results,subcases_executed:control.length+results.reduce((a,r)=>a+r.cases.length,0),helpers_removed:helperRemoved,firewall_rules_sha256:createHash('sha256').update(rules.stdout).digest('hex'),firewall_rules:rules.stdout,remote_modified:false,limits:['Connection probes use the actual service network namespaces without credentials or business data; product authorization not tested here.']};
writeFileSync(join(path,existsSync(join(path,'isolation-receipt.json'))?'isolation-receipt-'+stamp+'.json':'isolation-receipt.json'),JSON.stringify(receipt,null,2)+'\n',{flag:'wx',mode:0o600});
console.log(JSON.stringify({result:receipt.result,subcases_executed:receipt.subcases_executed,failures:results.flatMap(r=>r.cases.filter(c=>c.result!=='PASS').map(c=>({name:r.name,...c}))),helpers_removed:helperRemoved}));
if(!allPass){writeFileSync(join(path,'.task001-blocked.json'),JSON.stringify({at:new Date().toISOString(),reason:'Isolation failure; business prohibited'}),{flag:'wx',mode:0o600});process.exitCode=1;}
