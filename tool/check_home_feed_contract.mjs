// Read-only hosted contract gate. Credentials remain owned by the Supabase CLI.
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const query=spawnSync('supabase',['db','query','--linked','--output','json','--file',fileURLToPath(new URL('./home_feed_contract.sql',import.meta.url))],{encoding:'utf8'});
if(query.status!==0){console.error('Home feed backend could not be checked. Apply migrations 016–019 and configure the cleanup worker.');process.exit(1);}
let row;
try{const result=JSON.parse(query.stdout);row=Array.isArray(result)?result[0]:result.rows?.[0];}catch{}
const fields=['migrations_ready','rls_ready','functions_ready','private_writes_ready','storage_ready','acceptance_ready','cleanup_schedule_ready','cleanup_config_ready'];
const missing=fields.filter(field=>row?.[field]!==true);
if(missing.length){console.error(`Home feed backend is not ready: ${missing.join(', ')}.`);process.exit(1);}
console.log('Home feed backend ready: combined feed, stories, following, private storage and hourly cleanup.');
