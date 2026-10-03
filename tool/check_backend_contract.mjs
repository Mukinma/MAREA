// Read-only gate against the already linked project. The CLI owns credentials.
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const query = spawnSync('supabase',['db','query','--linked','--output','json','--file',fileURLToPath(new URL('./backend_contract.sql',import.meta.url))], {encoding:'utf8'});
if (query.status !== 0) {
  console.error('Backend contract could not be checked. Verify CLI access and apply the required migrations before building.');
  process.exit(1);
}
let row;
try {
  const result = JSON.parse(query.stdout);
  row = Array.isArray(result) ? result[0] : result.rows?.[0];
} catch { /* Fail closed. */ }
const fields = ['mission_tables_ready','mission_permissions_ready','mission_functions_ready','mission_notifications_ready','migrations_ready','map_contract_ready','guide_column_ready','guide_grant_ready','preferences_grants_ready','confirmation_ready','signup_trigger_ready','social_tables_ready','social_permissions_ready','social_functions_ready','realtime_ready'];
const missing = fields.filter(field => row?.[field] !== true);
if (missing.length) {
  console.error(`Backend is not ready: ${missing.join(', ')}. Apply migrations 001–013 before distributing a build.`);
  process.exit(1);
}
console.log('Backend contract ready: migrations, signup, confirmation, social, map and mission contracts match the client.');
