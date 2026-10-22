import {writeFileSync,readFileSync} from 'node:fs';
import {join,resolve} from 'node:path';
import {database} from './replay.mjs';
export function inventory(path){
 const {m,sql}=database(path);const query=`select jsonb_build_object(
 'tables',(select jsonb_agg(to_jsonb(t)) from (select n.nspname schema,c.relname name,c.relrowsecurity rls,c.relforcerowsecurity force_rls,c.relowner::regrole::text owner from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('public','private') and c.relkind='r' order by 1,2)t),
 'grants',(select jsonb_agg(to_jsonb(t)) from (select table_schema,table_name,grantee,privilege_type from information_schema.table_privileges where table_schema in ('public','private','storage') order by 1,2,3,4)t),
 'column_grants',(select jsonb_agg(to_jsonb(t)) from (select table_schema,table_name,column_name,grantee,privilege_type from information_schema.column_privileges where table_schema in ('public','private') and grantee in ('anon','authenticated','service_role') order by 1,2,3,4,5)t),
 'policies',(select jsonb_agg(to_jsonb(t)) from (select schemaname,tablename,policyname,roles,cmd,qual,with_check from pg_policies where schemaname in ('public','private','storage') order by 1,2,3)t),
 'functions',(select jsonb_agg(to_jsonb(t)) from (select n.nspname schema,p.proname name,p.oid::regprocedure::text signature,pg_get_function_arguments(p.oid) arguments,pg_get_function_result(p.oid) returns,p.prosecdef security_definer,p.proacl::text acl,has_function_privilege('anon',p.oid,'EXECUTE') anon,has_function_privilege('authenticated',p.oid,'EXECUTE') authenticated,has_function_privilege('service_role',p.oid,'EXECUTE') service_role from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in ('public','private') order by 1,2,3)t),
 'buckets',(select jsonb_agg(to_jsonb(t)) from (select id,public,file_size_limit,allowed_mime_types from storage.buckets order by id)t),
 'realtime',(select jsonb_agg(to_jsonb(t)) from (select pubname,schemaname,tablename from pg_publication_tables order by 1,2,3)t),
 'cron_jobs',(select jsonb_agg(jsonb_build_object('name',jobname,'schedule',schedule,'active',active)) from cron.job),
 'cron_effective',(select setting from pg_settings where name='cron.launch_active_jobs'),
 'cron_runs',(select count(*) from cron.job_run_details),
 'vault_secret_count',(select count(*) from vault.secrets),
 'push_enabled',(select enabled from private.push_settings where singleton),
 'geocoding_enabled',(select enabled from public.geocoding_provider where id));`;
 const data=JSON.parse(sql(query,false,'supabase_admin').stdout.trim());if(data.cron_effective!=='off'||data.cron_runs!==0||data.vault_secret_count!==0||data.push_enabled||data.geocoding_enabled)throw Error('Local integration isolation drift');
 data.id='E-TASK001-INVENTORY-'+m.project_id;data.at=new Date().toISOString();data.modality='real';data.remote_equivalence=false;
 writeFileSync(join(path,'db-inventory-'+Date.now()+'.json'),JSON.stringify(data,null,2)+'\n',{flag:'wx',mode:0o600});return data;
}
if(process.argv[1]===new URL(import.meta.url).pathname){try{const i=inventory(resolve(process.argv[2]||''));console.log(JSON.stringify({tables:i.tables.length,functions:i.functions.length,buckets:i.buckets.length,cron:i.cron_effective,cron_runs:i.cron_runs}));}catch(e){console.error(e.message);process.exitCode=1;}}
