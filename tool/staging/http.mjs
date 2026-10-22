import{assertCurrentIsolation}from'./current-isolation.mjs';
import {latestProof} from './proofs.mjs';
import {readFileSync,lstatSync,existsSync} from 'node:fs';
import {join} from 'node:path';
import {createHash} from 'node:crypto';
import {assertOwnedRuntime,assertLocalUrl} from './guard.mjs';
export function localClient(path) {
 const marker=assertOwnedRuntime(path);if(marker.version!==2||existsSync(join(path,'.task001-blocked.json')))throw Error('Owned unblocked v2 runtime required');
 assertCurrentIsolation(path,marker);
 for(const f of ['schema-receipt.json'])if(JSON.parse(readFileSync(join(path,f))).result!=='PASS')throw Error('Healthy schema and isolation gates required');
 const kp=join(path,'local-keys-private.json');const st=lstatSync(kp);if(st.isSymbolicLink()||st.mode&0o077)throw Error('Private local keys required');
 const keys=JSON.parse(readFileSync(kp));assertLocalUrl(keys.API_URL,marker.api_port);
 const base=`http://127.0.0.1:${marker.api_port}`;
 async function request(route,{actor=null,method='GET',data,headers={},raw,token,key}={}) {
  if(!route.startsWith('/')||route.startsWith('//')||route.includes('\\'))throw Error('Relative local API route required');
  const url=new URL(route,base);if(url.origin!==base)throw Error('Foreign destination');
  const bearer=token||(actor==='service'?keys.SERVICE_ROLE_KEY:actor?.access_token)||keys.ANON_KEY;
  const res=await fetch(url,{method,headers:{apikey:key||keys.ANON_KEY,Authorization:'Bearer '+bearer,...(data!==undefined?{'Content-Type':'application/json'}:{}),...headers},body:raw??(data!==undefined?JSON.stringify(data):undefined),redirect:'error',signal:AbortSignal.timeout(15000)});
  const bytes=Buffer.from(await res.arrayBuffer());const bytes_sha256=createHash('sha256').update(bytes).digest('hex');const text=bytes.toString('utf8');let body;try{body=JSON.parse(text);}catch{body=text;}
  return {status:res.status,ok:res.ok,body,bytes_sha256,bytes_length:bytes.length};
 }
 const rpc=(name,data,actor)=>request('/rest/v1/rpc/'+name,{method:'POST',data,actor});
 async function login(user){const r=await request('/auth/v1/token?grant_type=password',{method:'POST',data:{email:user.email,password:user.password}});if(!r.ok||!r.body.access_token)throw Error('Synthetic login failed');const claims=JSON.parse(Buffer.from(r.body.access_token.split('.')[1],'base64url'));if(!Number.isFinite(claims.exp)||claims.sub!==user.id)throw Error('Local session claims mismatch');return {...r.body,expires_at:claims.exp};}
 return {marker,base,keys,request,rpc,login};
}
