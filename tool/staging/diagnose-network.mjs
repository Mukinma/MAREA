import {spawnSync} from 'node:child_process';
import {writeFileSync, existsSync} from 'node:fs';
import {resolve, join} from 'node:path';
import {childEnvironment} from './guard.mjs';
const out=resolve(process.argv[2]||'');
if (!out.includes('/docs/evidence/2026-10-13/task001/run-') || !existsSync(join(out,'01-backup.json'))) throw Error('Verified backup receipt required');
const suffix=Date.now().toString(36);
const image='public.ecr.aws/supabase/postgres@sha256:6942962433a569e87f228b4d4ab7e11db5deca64e43babb3a038443ad6c4f1bb';
const commands=[];
function docker(args, acceptFailure=false) {
 commands.push(['docker',...args]);
 const r=spawnSync('docker',args,{env:childEnvironment(),encoding:'utf8',timeout:15000,maxBuffer:1024*1024});
 if(r.error || (!acceptFailure&&r.status!==0)) throw Error(r.stderr||r.error?.message||'docker failed');
 return r;
}
const results=[];
for (const [mode,port] of [['internal',61201],['control',61202]]) {
 const name=`marea-task001-diag-${mode}-${suffix}`;
 const net=docker(['network','create',...(mode==='internal'?['--internal']:[]),'--opt','com.docker.network.bridge.host_binding_ipv4=127.0.0.1','--label',`marea.task001.diagnostic=${suffix}`,name]).stdout.trim();
 docker(['run','-d','--name',name,'--label',`marea.task001.diagnostic=${suffix}`,'--network',name,'--user','10001:10001','--read-only','--cap-drop','ALL','--security-opt','no-new-privileges','-p',`127.0.0.1:${port}:8080`,'--entrypoint','/bin/sh',image,'-c',"while true; do printf 'HTTP/1.1 200 OK\r\nContent-Length: 9\r\nConnection: close\r\n\r\nSYNTHETIC' | nc -l -p 8080; done"]);
 let peer;
 for(let i=0;i<10;i++) {
  peer=docker(['run','--name',`${name}-peer-${i}`,'--label',`marea.task001.diagnostic=${suffix}`,'--network',name,'--read-only','--cap-drop','ALL','--entrypoint','/usr/bin/curl',image,'--silent','--show-error','--max-time','2',`http://${name}:8080`],true);
  if(peer.status===0 && peer.stdout==='SYNTHETIC')break;
  await new Promise(r=>setTimeout(r,250));
 }
 if(peer.status!==0 || peer.stdout!=='SYNTHETIC')throw Error('Internal listener not healthy; preserve diagnostic resources');
 const c=JSON.parse(docker(['inspect',name]).stdout)[0];
 let host;try {const r=await fetch(`http://127.0.0.1:${port}`,{redirect:'error',signal:AbortSignal.timeout(2000)});host={ok:r.ok,body:await r.text()};}catch(e){host={ok:false,error:e.cause?.code||e.name};}
 results.push({mode,network_id:net,name,image,listener_peer:'PASS',requested:c.HostConfig.PortBindings,published:c.NetworkSettings.Ports,internal_ip:c.NetworkSettings.Networks[name].IPAddress,host});
}
const confirmed=results[0].host.ok===false&&(!results[0].published['8080/tcp'] || results[0].published['8080/tcp'].length===0)&&results[1].host.ok&&results[1].host.body==='SYNTHETIC';
const receipt={id:'E-TASK001-NETWORK-DIAG-20261013T174515Z',captured_at:new Date().toISOString(),modality:'real',result:confirmed?'PASS':'BLOQUEADO',root_cause_confirmed:confirmed,mechanism:'Docker omits host NAT publication for endpoint attached exclusively to an internal bridge without gateway; healthy internal listener is unreachable via requested host port.',results,commands,remote_modified:false,business_executed:false};
writeFileSync(join(out,'02-network-diagnosis.json'),JSON.stringify(receipt,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({result:receipt.result,root_cause_confirmed:confirmed,results}));
if(!confirmed)process.exitCode=1;
