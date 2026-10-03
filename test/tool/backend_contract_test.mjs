import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,writeFile,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const ready={mission_tables_ready:true,mission_permissions_ready:true,mission_functions_ready:true,mission_notifications_ready:true,map_contract_ready:true,migrations_ready:true,guide_column_ready:true,guide_grant_ready:true,preferences_grants_ready:true,confirmation_ready:true,signup_trigger_ready:true,social_tables_ready:true,social_permissions_ready:true,social_functions_ready:true,realtime_ready:true};
async function run(fixture,status=0) {
  const directory=await mkdtemp(join(tmpdir(),'marea-contract-'));
  try {
    await writeFile(join(directory,'supabase'), '#!/bin/sh\nprintf \'%s\' "$MAREA_QUERY_FIXTURE"\nexit "$MAREA_QUERY_STATUS"\n',{mode:0o700});
    return spawnSync(process.execPath,[fileURLToPath(new URL('../../tool/check_backend_contract.mjs',import.meta.url))],{
      encoding:'utf8',env:{...process.env,PATH:`${directory}:${process.env.PATH}`,MAREA_QUERY_FIXTURE:JSON.stringify(fixture),MAREA_QUERY_STATUS:String(status)},
    });
  } finally {await rm(directory,{recursive:true,force:true});}
}
for(const [label,fixture] of [['human JSON',[ready]],['agent JSON',{rows:[ready]}]]) {
  test(`ready contract works in ${label}`,async()=>{
    const result=await run(fixture);
    assert.equal(result.status,0,result.stderr);
    assert.match(result.stdout,/Backend contract ready/);
  });
}
test('missing signup trigger blocks release',async()=>{
  const result=await run([{...ready,signup_trigger_ready:false}]);
  assert.equal(result.status,1);
  assert.match(result.stderr,/signup_trigger_ready/);
});
test('CLI failure does not report a ready contract',async()=>{
  const result=await run({rows:[ready]},1);
  assert.equal(result.status,1);
  assert.match(result.stderr,/could not be checked/);
});
test('missing social contract blocks release',async()=>{
  const result=await run([{...ready,social_tables_ready:false,social_permissions_ready:false,social_functions_ready:false,realtime_ready:false}]);
  assert.equal(result.status,1);
  assert.match(result.stderr,/social_tables_ready/);
});

test('missing geographic RPC contract blocks release',async()=>{
  const result=await run([{...ready,map_contract_ready:false}]);
  assert.equal(result.status,1);
  assert.match(result.stderr,/map_contract_ready/);
});

for (const field of ['mission_tables_ready','mission_permissions_ready','mission_functions_ready','mission_notifications_ready']) test(`missing ${field} blocks release`,async()=>{
 const result=await run([{...ready,[field]:false}]); assert.equal(result.status,1); assert.match(result.stderr,new RegExp(field));
});
