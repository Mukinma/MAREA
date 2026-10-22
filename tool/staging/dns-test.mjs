import {latestProof,blockIsolation} from './proofs.mjs';
import {readFileSync,writeFileSync,readdirSync,existsSync} from 'node:fs';
import {join,resolve} from 'node:path';
import {spawn} from 'node:child_process';
import {assertOwnedRuntime,childEnvironment} from './guard.mjs';
import {docker} from './local-stack.mjs';
const path=resolve(process.argv[2]||'');const m=assertOwnedRuntime(path);
const stamp=Date.now();process.once('uncaughtException',()=>{blockIsolation(path,'DNS infrastructure failure; business prohibited');process.exit(1);});process.once('unhandledRejection',()=>{blockIsolation(path,'DNS infrastructure failure; business prohibited');process.exit(1);});const receipt=latestProof(path,'isolation');
const script=`import socket,struct,json,sys,time
qname='registry-1.docker.io'
q=b'\\x12\\x34'+struct.pack('!HHHHH',256,1,0,0,0)+b''.join(bytes([len(x)])+x.encode() for x in qname.split('.'))+b'\\0'+struct.pack('!HH',1,1)
s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);s.settimeout(2)
try:
 s.sendto(q,('127.0.0.11',53));b=s.recv(4096);answer=struct.unpack('!H',b[6:8])[0];rcode=b[3]&15;resolved=rcode==0 and answer>0
except OSError:resolved=False;answer=0;rcode=None
print(json.dumps({'resolved':resolved,'answers':answer,'rcode':rcode}))`;
async function probe(ns,i){return new Promise((ok,fail)=>{const c=spawn('docker',['run','--name',m.project_id+'-dns-'+stamp+'-'+i,'--label','marea.task001.owner='+m.project_id,'--network',ns,'--read-only','--user','10001:10001','--cap-drop','ALL','--entrypoint','python',m.network_image,'-B','-c',script],{env:childEnvironment(),stdio:['ignore','pipe','pipe']});let out='';c.stdout.on('data',b=>out+=b);c.on('error',fail);c.on('exit',code=>code===0?ok(JSON.parse(out)):fail(Error('DNS diagnostic failure')));});}
const control=await probe(m.ingress_network,'control');if(!control.resolved)throw Error('Infrastructure DNS positive control unavailable');
const results=[];for(const [i,r] of receipt.results.entries()){const observed=await probe('container:'+r.namespace,i);results.push({name:r.name,namespace:r.namespace,...observed,result:observed.resolved?'FAIL':'PASS'});}
const result=results.every(r=>r.result==='PASS')?'PASS':'BLOQUEADO';writeFileSync(join(path,existsSync(join(path,'dns-receipt.json'))?'dns-receipt-'+stamp+'.json':'dns-receipt.json'),JSON.stringify({id:'E-TASK001-DNS-'+m.project_id,at:new Date().toISOString(),result,modality:'real',control,results,subcases_executed:results.length+1,limits:['Official Docker registry DNS used as infrastructure positive control; no business request or credential.'],remote_modified:false},null,2)+'\n',{flag:'wx',mode:0o600});console.log(JSON.stringify({result,subcases_executed:results.length+1,results}));if(result!=='PASS'){blockIsolation(path,'DNS isolation failure; business prohibited');process.exitCode=1;}
