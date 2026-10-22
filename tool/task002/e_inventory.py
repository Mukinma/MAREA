#!/usr/bin/env python3
"""Read-only effective catalog/data digests on isolated restored E clones."""
import json,hashlib,datetime
from pathlib import Path
import e_diagnostics as e
CATALOG=r'''
SELECT jsonb_build_object(
 'tables',(SELECT jsonb_agg(to_jsonb(x) ORDER BY schema,name) FROM (SELECT n.nspname schema,c.relname name,c.relkind,c.relowner::regrole::text owner,c.relrowsecurity rls,c.relforcerowsecurity force_rls,c.relacl::text acl FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname NOT LIKE 'pg_%' AND n.nspname<>'information_schema' AND c.relkind IN ('r','p','S'))x),
 'columns',(SELECT jsonb_agg(to_jsonb(x) ORDER BY table_schema,table_name,ordinal_position) FROM information_schema.columns x WHERE table_schema IN ('public','private','auth','storage','cron','net','vault')),
 'constraints',(SELECT jsonb_agg(to_jsonb(x) ORDER BY schema,relation,name) FROM (SELECT n.nspname schema,c.conrelid::regclass::text relation,c.conname name,c.contype type,c.confrelid::regclass::text referenced_relation,c.confdeltype delete_action,c.convalidated validated,pg_get_constraintdef(c.oid) definition FROM pg_constraint c JOIN pg_namespace n ON n.oid=c.connamespace WHERE n.nspname NOT LIKE 'pg_%' AND n.nspname<>'information_schema')x),
 'policies',(SELECT jsonb_agg(to_jsonb(x) ORDER BY schemaname,tablename,policyname) FROM pg_policies x WHERE schemaname NOT LIKE 'pg_%'),
 'routines',(SELECT jsonb_agg(to_jsonb(x) ORDER BY schema,signature) FROM (SELECT n.nspname schema,p.oid::regprocedure::text signature,p.prosecdef security_definer,p.proacl::text acl,p.proconfig settings,pg_get_functiondef(p.oid) definition FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname IN ('public','private','auth','storage') AND p.prokind IN ('f','p'))x),
 'triggers',(SELECT jsonb_agg(to_jsonb(x) ORDER BY relation,name) FROM (SELECT t.tgrelid::regclass::text relation,t.tgname name,t.tgisinternal internal,t.tgenabled enabled,pg_get_triggerdef(t.oid) definition FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','private','auth','storage'))x),
 'views',(SELECT jsonb_agg(to_jsonb(x) ORDER BY schemaname,viewname) FROM pg_views x WHERE schemaname IN ('public','private','auth','storage')),
 'view_dependencies',(SELECT jsonb_agg(to_jsonb(x) ORDER BY view_name,source) FROM (SELECT DISTINCT v.oid::regclass::text view_name,c.oid::regclass::text source FROM pg_rewrite rw JOIN pg_class v ON v.oid=rw.ev_class JOIN pg_depend d ON d.classid='pg_rewrite'::regclass AND d.objid=rw.oid JOIN pg_class c ON d.refclassid='pg_class'::regclass AND c.oid=d.refobjid JOIN pg_namespace n ON n.oid=v.relnamespace WHERE n.nspname IN ('public','private') AND v.relkind='v' AND c.oid<>v.oid)x),
 'grants',(SELECT jsonb_agg(to_jsonb(x) ORDER BY table_schema,table_name,grantee,privilege_type) FROM information_schema.table_privileges x WHERE table_schema IN ('public','private','auth','storage')),
 'roles',(SELECT jsonb_agg(to_jsonb(x) ORDER BY rolname) FROM (SELECT rolname,rolsuper,rolinherit,rolcreaterole,rolcreatedb,rolcanlogin,rolreplication,rolbypassrls,rolconnlimit,rolvaliduntil,rolconfig FROM pg_roles)x),
 'memberships',(SELECT jsonb_agg(to_jsonb(x) ORDER BY role_name,member) FROM (SELECT r.rolname role_name,m.rolname member,g.rolname grantor,a.admin_option,a.inherit_option,a.set_option FROM pg_auth_members a JOIN pg_roles r ON r.oid=a.roleid JOIN pg_roles m ON m.oid=a.member JOIN pg_roles g ON g.oid=a.grantor)x),
 'extensions',(SELECT jsonb_agg(to_jsonb(x) ORDER BY extname) FROM (SELECT extname,extversion,extnamespace::regnamespace::text schema FROM pg_extension)x),
 'event_triggers',(SELECT jsonb_agg(to_jsonb(x) ORDER BY evtname) FROM (SELECT evtname,evtevent,evtenabled,evtfoid::regproc::text function,evttags FROM pg_event_trigger)x),
 'database', (SELECT jsonb_build_object('encoding',pg_encoding_to_char(encoding),'collation',datcollate,'ctype',datctype,'provider',datlocprovider,'locale',to_jsonb(d)->'datlocale','collation_version',datcollversion,'owner',datdba::regrole::text,'acl',datacl::text) FROM pg_database d WHERE datname='postgres'),
 'settings',(SELECT jsonb_agg(to_jsonb(x) ORDER BY name) FROM (SELECT name,setting,source,pending_restart FROM pg_settings WHERE name IN ('server_version','cron.launch_active_jobs','shared_preload_libraries','default_transaction_read_only','listen_addresses','archive_mode'))x),
 'safety',jsonb_build_object('cron_runs',(SELECT count(*) FROM cron.job_run_details),'vault_secrets',(SELECT count(*) FROM vault.secrets),'push_enabled',(SELECT enabled FROM private.push_settings WHERE singleton),'geocoding_enabled',(SELECT enabled FROM public.geocoding_provider WHERE id),'non_synthetic_users',(SELECT count(*) FROM auth.users WHERE email IS NULL OR email !~ '\.invalid$'))
);
'''

def quoted(x):return '"'+x.replace('"','""')+'"'
def capture(name):
 cat=json.loads(e.sql(name,CATALOG).stdout);assert cat['safety']=={'cron_runs':0,'vault_secrets':0,'push_enabled':False,'geocoding_enabled':False,'non_synthetic_users':0},cat['safety']
 settings={x['name']:x['setting'] for x in cat['settings']};assert settings['cron.launch_active_jobs']=='off' and settings['default_transaction_read_only']=='on' and settings['listen_addresses']=='';assert 'pg_net' not in settings['shared_preload_libraries']
 queries=[];tables=[t for t in cat['tables'] if t['relkind'] in ['r','p']]
 for t in tables:
  table=quoted(t['schema'])+'.'+quoted(t['name']);label=t['schema']+'.'+t['name'];queries.append(f"SELECT jsonb_build_object('table','{label}','rows',count(*),'sha256',encode(sha256(convert_to(coalesce(string_agg(to_jsonb(t)::text,E'\\n' ORDER BY to_jsonb(t)::text COLLATE \"C\"),''),'UTF8')),'hex')) FROM {table} t;")
 rows=[json.loads(line) for line in e.sql(name,'\n'.join(queries)).stdout.splitlines() if line.startswith('{')]
 seq=[]
 for t in cat['tables']:
  if t['relkind']=='S':
   x=json.loads(e.sql(name,"SELECT jsonb_build_object('last_value',last_value,'is_called',is_called) FROM "+quoted(t['schema'])+'.'+quoted(t['name'])+' t;').stdout);seq.append({'name':t['schema']+'.'+t['name'],**x})
 return {'catalog':cat,'rows':rows,'sequences':seq}

def effective():
 results={}
 for a in e.SOURCES:
  work=capture(f'{e.OWNER}-{a}-work-postgres');recovery=capture(f'{e.OWNER}-{a}-recovery-postgres');assert work==recovery,'Restored clone logical mismatch'
  (e.PRIVATE/f'{a}-effective-v2-private.json').write_text(json.dumps(work,sort_keys=True,indent=2))
  cat=work['catalog'];fk=[x for x in cat['constraints'] if x['type']=='f'];dependent=[{'signature':x['signature'],'definition_sha256':hashlib.sha256(x['definition'].encode()).hexdigest()} for x in cat['routines'] if any(s in x['definition'] for s in ['author_id','delete_account','request_account_deletion','mission-images'])]
  results[a]={'source_project':e.SOURCES[a],'tables':work['rows'],'sequences':work['sequences'],'all_fk':fk,'policies':cat['policies'],'roles':cat['roles'],'memberships':cat['memberships'],'tables_rls':[t for t in cat['tables'] if t['schema'] in ['public','private','auth','storage']],'trigger_definitions':cat['triggers'],'view_dependencies':cat['view_dependencies'],'routine_dependencies':dependent,'extensions':cat['extensions'],'safety':cat['safety'],'runtime_settings':cat['settings'],'counts':{k:len(cat[k] or []) for k in ['tables','constraints','policies','routines','triggers','views','grants','roles','memberships']},'catalog_sha256':hashlib.sha256(json.dumps(cat,sort_keys=True,separators=(',',':')).encode()).hexdigest(),'physical_recovery_logical_identity':True}
  (e.RUN/'08-effective-inventory-canonical.json').write_text(json.dumps({'result':'IN_PROGRESS','sources':results},indent=2)+'\n')
 (e.RUN/'08-effective-inventory-canonical.json').write_text(json.dumps({'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'result':'PASS','sources':results,'scope':'Two historical local synthetic runtimes; no remote equivalence','complete_requirement_validation':False},indent=2)+'\n')
 print(json.dumps({a:{'catalog_counts':x['counts'],'mission_rows':next(t['rows'] for t in x['tables'] if t['table']=='public.missions'),'physical_recovery_logical_identity':True} for a,x in results.items()},indent=2))
if __name__=='__main__':e.guard();effective()
