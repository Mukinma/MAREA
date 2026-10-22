import{assertCurrentIsolation}from'./current-isolation.mjs';
import{settledExit}from'./process-wait.mjs';
import {latestProof} from './proofs.mjs';
import {readFileSync,writeFileSync,readdirSync,existsSync,openSync,closeSync} from 'node:fs';
import {join,resolve} from 'node:path';
import {spawnSync,spawn} from 'node:child_process';
import {createHash} from 'node:crypto';
import {assertOwnedRuntime,childEnvironment} from './guard.mjs';
import {docker} from './local-stack.mjs';
const sha=b=>createHash('sha256').update(b).digest('hex');
export function database(path) {
 const m=assertOwnedRuntime(path);if(m.version!==2||existsSync(join(path,'.task001-blocked.json')))throw Error('Fresh owned unblocked runtime required');
 assertCurrentIsolation(path,m);
 const c=JSON.parse(docker(['inspect','supabase_db_'+m.project_id]).stdout)[0];
 if(c.Config.Labels['com.supabase.cli.project']!==m.project_id||!c.State.Running||Object.keys(c.NetworkSettings.Networks).join()!==m.network)throw Error('Owned database identity failed');
 return {m,c,sql:(text,allowFailure=false,role='postgres')=>{
  if(!['postgres','supabase_admin'].includes(role))throw Error('Unknown setup/inspection role');
  const r=spawnSync('docker',['exec','-i',c.Id,'psql','-X','-U',role,'-d','postgres','-v','ON_ERROR_STOP=1','-At'],{input:text,env:childEnvironment(),encoding:'utf8',maxBuffer:64*1024*1024});
  if(r.error||(!allowFailure&&r.status!==0))throw Error('Local SQL failed; no SQL output disclosed');return r;
 }};
}
const cronQuery="select row_to_json(s) from (select name,setting,source,sourcefile,context,pending_restart from pg_settings where name='cron.launch_active_jobs') s;";
function checkCron(sql){const out=sql(cronQuery,false,'supabase_admin').stdout.trim();if(!out)throw Error('Cron unknown');const c=JSON.parse(out);if(c.setting!=='off'||c.pending_restart||c.context!=='sighup'||c.source!=='configuration file')throw Error('Cron enabled or not effectively applied');return c;}
export async function replay(path) {
 const {m,c,sql}=database(path);if(existsSync(join(path,'schema-receipt.json'))||readdirSync(path).some(f=>f.startsWith('migration-')))throw Error('Replay cannot be repeated on an existing database; prepare a fresh runtime');
 const files=readdirSync('supabase/migrations').filter(n=>n.endsWith('.sql')).sort();
 const review=JSON.parse(readFileSync('tool/staging/migrations.lock.json'));
 if(files.length!==21||JSON.stringify(files)!==JSON.stringify(review.map(x=>x.file)))throw Error('Migration order drift');
 for(const f of review)if(sha(readFileSync(join('supabase/migrations',f.file)))!==f.sha256)throw Error('Reviewed migration changed');
 const count=sql("select count(*) from auth.users; select count(*) from pg_tables where schemaname='public'; select count(*) from vault.secrets;").stdout.trim();if(count!=='0\n0\n0')throw Error('Database is not empty');
 writeFileSync(join(path,'replay-attempt-'+Date.now()+'.json'),JSON.stringify({at:new Date().toISOString(),project:m.project_id}),{flag:'wx',mode:0o600});
 sql("ALTER SYSTEM SET cron.launch_active_jobs='off';",false,'supabase_admin');sql('select pg_reload_conf();',false,'supabase_admin');
 let before;for(let i=0;i<30;i++){try{before=checkCron(sql);break;}catch(e){if(i===29)throw e;await new Promise(r=>setTimeout(r,100));}}
 const fd=openSync(join(path,'cron-monitor-private.log'),'wx',0o600);
 const watcher=spawn('docker',['exec','-i',c.Id,'psql','-X','-U','supabase_admin','-d','postgres','-At','-v','ON_ERROR_STOP=1'],{env:childEnvironment(),stdio:['pipe',fd,fd]});
 watcher.stdin.end(cronQuery+'\n\\watch 0.1\n');
 const steps=[];let failure;
 try {
  for(const f of review){
   const pre=checkCron(sql);const bytes=readFileSync(join('supabase/migrations',f.file));
   if(sha(bytes)!==f.sha256)throw Error('Original bytes changed before replay');
   const r=sql(bytes,true);writeFileSync(join(path,'migration-'+f.file+'.log'),r.stdout+r.stderr,{flag:'wx',mode:0o600});
   const post=checkCron(sql);steps.push({file:f.file,sha256:f.sha256,exit_code:r.status,cron_before:pre,cron_after:post,log_sha256:sha(r.stdout+r.stderr)});
   if(r.status!==0)throw Error('Historical migration failed: '+f.file+'; original replay stopped');
   if(watcher.exitCode!==null)throw Error('Cron supervisor stopped');
   const users=sql('select count(*) from auth.users;select count(*) from vault.secrets;').stdout.trim();if(users!=='0\n0')throw Error('Unexpected business or Vault data');
  }
  // Local-only overlay, separately recorded: no original source modification.
  sql('update public.geocoding_provider set enabled=false;');
  sql("NOTIFY pgrst, 'reload schema';");
 }catch(e){failure=e.message;}
 finally{if(watcher.exitCode===null&&watcher.signalCode===null){const exited=settledExit(watcher);watcher.kill('SIGTERM');await exited;}closeSync(fd);}
 const monitor=readFileSync(join(path,'cron-monitor-private.log'),'utf8');const samples=monitor.split('\n').filter(x=>x.startsWith('{')).map(x=>JSON.parse(x));
 if(!samples.length||samples.some(x=>x.setting!=='off'||x.pending_restart))failure=failure||'Cron supervision invalid';
 const final=checkCron(sql);const executions=sql("select case when to_regclass('cron.job_run_details') is null then -1 else (select count(*) from cron.job_run_details) end;").stdout.trim();
 if(executions!=='0')failure=failure||'Automatic cron executions or unknown history';
 const result={id:'E-TASK001-SCHEMA-'+m.project_id,at:new Date().toISOString(),result:failure?'BLOQUEADO':'PASS',modality:'real',project_id:m.project_id,original_hashes:review,steps,cron:{before,after:final,samples:samples.length,all_off:samples.every(s=>s.setting==='off'&&!s.pending_restart),monitor_sha256:sha(monitor),automatic_executions:Number(executions),supervision:'Separate PostgreSQL backend, 100 ms sampling + checks before/after each original file; reviewed sources cannot change GUC'},local_overlays:['ALTER SYSTEM cron.launch_active_jobs=off + reload before first migration','geocoding_provider.enabled=false after originals'],failure,remote_modified:false,complete_requirement_validation:false};
 writeFileSync(join(path,failure?'schema-blocked-receipt.json':'schema-receipt.json'),JSON.stringify(result,null,2)+'\n',{flag:'wx',mode:0o600});
 if(failure){writeFileSync(join(path,'.task001-blocked.json'),JSON.stringify({reason:failure,at:new Date().toISOString()}),{flag:'wx',mode:0o600});throw Error(failure);}
 return {result:'PASS',migrations:steps.length,cron_samples:samples.length,cron_runs:0};
}
if(process.argv[1]===new URL(import.meta.url).pathname){try{console.log(JSON.stringify(await replay(resolve(process.argv[2]||''))));}catch(e){console.error(e.message);process.exitCode=1;}}
