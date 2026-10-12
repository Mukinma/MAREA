// Read-only readiness gate; never prints credentials, locations or user data.
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const r=spawnSync('supabase',['db','query','--linked','--output','json','--file',fileURLToPath(new URL('./feed_correction_contract.sql',import.meta.url))],{encoding:'utf8'});
if(r.status!==0){console.error('Correction backend cannot be verified. Apply migrations020–021.');process.exit(1);}
let row;try{const v=JSON.parse(r.stdout);row=Array.isArray(v)?v[0]:v.rows?.[0];}catch{}
const fields=['migrations_ready','rls_ready','social_rpc_ready','private_writes_ready','provider_private','city_ready'];
const missing=fields.filter(f=>row?.[f]!==true);
if(missing.length){console.error(`Correction backend not ready: ${missing.join(', ')}.`);process.exit(1);}
console.log('Correction backend ready: mission social RPC/RLS, city metadata and private global geocoder.');
