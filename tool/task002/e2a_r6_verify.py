"""Exact scoped conservation of existing records/objects; no ignored drift."""
import collections,copy,json,re
import e2a_r6 as L
NEW_ROLES={'marea_person_sync_owner','marea_person_repair_operator'}
NEW_TABLES={'person_controls','person_repair_manifests'}
NEW_POLICIES={'e2a_sync_auth_status_read','e2a_sync_deletion_status_read','e2a_person_private_read','e2a_person_private_insert','e2a_control_private_read','e2a_control_private_insert','e2a_manifest_read','e2a_manifest_insert','e2a_manifest_execute'}
NEW_FUNCTIONS={'person_sync_status(uuid)','ensure_person_for_auth(uuid,text)','person_after_auth_insert()','stage_person_repair(uuid,uuid[])','reconcile_persons(uuid,text,boolean)'}
def encoded(x):return json.dumps(x,sort_keys=True,separators=(',',':'))
def delta(before,after):
 b=collections.Counter(map(encoded,before));a=collections.Counter(map(encoded,after));L.require(not b-a,'Existing object changed/removed: '+str(list((b-a).elements()))[:240]);return [json.loads(x) for x in (a-b).elements()]
def strip_new_acl(records):
 records=copy.deepcopy(records)
 for x in records:
  if 'acl' in x and x['acl'] is not None:
   entries=x['acl'][1:-1].split(',');entries=[e for e in entries if e.split('=',1)[0] not in NEW_ROLES]
   x['acl']='{'+','.join(sorted(entries))+'}' if entries else None
 return records

def schema_conservation(before,after):
 report={};b=before['catalog'];a=after['catalog']
 for k in b:
  if not isinstance(b[k],list):L.require(b[k]==a[k],'Catalog drift '+k);continue
  bv,av=b[k],a[k]
  if k=='tables':bv,av=strip_new_acl(bv),strip_new_acl(av)
  additions=delta(bv,av);report[k]={'preserved':len(bv),'added':len(additions)}
  for x in additions:
   ok=(k=='roles' and x['rolname'] in NEW_ROLES or
       k=='tables' and x['schema']=='collaboration' and x['name'] in NEW_TABLES or
       k=='columns' and x['table_schema']=='collaboration' and x['table_name'] in NEW_TABLES or
       k=='constraints' and x['schema']=='collaboration' and x['relation'].split('.')[-1] in NEW_TABLES or
       k=='policies' and x['policyname'] in NEW_POLICIES and x['roles']==['marea_person_sync_owner'] or
       k=='grants' and x['grantee'] in NEW_ROLES and x['table_schema']=='collaboration' or
       k=='routines' and x['schema']=='collaboration' and x['signature'] in NEW_FUNCTIONS or
       k=='triggers' and (x['name']=='zz_e2a_person_after_auth' or x['internal'] and 'person_controls' in x['definition']))
   L.require(ok,'Unapproved catalog addition '+k+': '+encoded(x)[:220])
 e0,e1=before['extra'],after['extra']
 for k in e0:
  bv,av=e0[k],e1[k]
  if k in ['schemas','column_acl']:bv,av=strip_new_acl(bv),strip_new_acl(av)
  # Existing null ACL columns are absent from initial snapshot, so remove new-role-only entries.
  if k=='column_acl':av=[x for x in av if x['acl'] is not None];bv=[x for x in bv if x['acl'] is not None]
  additions=delta(bv,av);report['extra.'+k]={'preserved':len(bv),'added':len(additions)}
  for x in additions:
   ok=(k=='all_routines' and x['schema']=='collaboration' and x['signature'].removeprefix('collaboration.') in NEW_FUNCTIONS or
       k=='indexes' and x['schemaname']=='collaboration' and x['tablename'] in NEW_TABLES or
       k=='private_columns' and x['table_name'] in NEW_TABLES)
   L.require(ok,'Unapproved extra addition '+k+': '+encoded(x)[:220])
 return report

def verify():
 all_results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';base=json.loads((L.PRIVATE/(a+'-E1-base.json')).read_text());pre=json.loads((L.PRIVATE/(a+'-before-A.json')).read_text());ddl=json.loads((L.PRIVATE/(a+'-after-A.json')).read_text());final=L.capture(pg)
  L.private(a+'-conservation-final.json',final)
  ddl_diff=schema_conservation(pre,ddl);schema_conservation(pre,final)
  allowed={'auth.users','auth.identities','auth.sessions','auth.refresh_tokens','auth.audit_log_entries','public.profiles','public.legal_acceptances','collaboration.persons'}
  rows=[]
  for name,hashes in base['row_hashes'].items():
   added=delta(hashes,final['row_hashes'][name]);L.require(not added or name in allowed,'Unexpected row delta '+name)
   rows.append({'table':name,'existing':len(hashes),'preserved':len(hashes),'fixture_insertions':len(added),'original_updates_or_deletions':0})
  # Exact sequence accounting: legal nextval occurs for successful inserts, 3 collision
  # INSERTs rolled back after handle_new_user, and 2 late injected HTTP faults.
  s0={x['name']:x for x in base['sequences']};s1={x['name']:x for x in final['sequences']};seq=[]
  for name,old in s0.items():
   now=s1[name];change=now['last_value']-old['last_value'];table='public.legal_acceptances' if name=='public.legal_acceptances_id_seq' else 'auth.refresh_tokens' if name=='auth.refresh_tokens_id_seq' else None
   n=next(x['fixture_insertions'] for x in rows if x['table']==table) if table else 0
   expected=n+(5 if table=='public.legal_acceptances' else 0)
   L.require(change==expected and now['is_called']==old['is_called'],'Sequence delta not explained '+name+': '+str((change,expected)))
   seq.append({'sequence':name,'initial':old['last_value'],'final':now['last_value'],'successful_fixture_rows':n,'rolled_back_nextvals':change-n,'expected_delta':expected})
  # Existing grant entries remain identical after removing ONLY the two new grantees.
  acl=L.val(pg,"""SELECT jsonb_build_object(
   'client_schema',(SELECT coalesce(bool_or(has_schema_privilege(r,'collaboration','USAGE')),false) FROM unnest(ARRAY['anon','authenticated','service_role'])r),
   'role_memberships',(SELECT count(*) FROM pg_auth_members m JOIN pg_roles r ON r.oid=m.roleid WHERE r.rolname IN ('marea_person_sync_owner','marea_person_repair_operator')),
   'owner_auth_update',has_column_privilege('marea_person_sync_owner','auth.users','id','UPDATE'),
   'owner_auth_email_read',has_column_privilege('marea_person_sync_owner','auth.users','email','SELECT'),
   'operator_ensure',has_function_privilege('marea_person_repair_operator','collaboration.ensure_person_for_auth(uuid,text)','EXECUTE'),
   'owner_person_update',has_table_privilege('marea_person_sync_owner','collaboration.persons','UPDATE'),
   'new_functions',(SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='collaboration'),
   'private_tables_rls',(SELECT bool_and(relrowsecurity AND NOT relforcerowsecurity) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='collaboration' AND relkind='r'),
   'function_hardening',(SELECT bool_and(p.prosecdef AND 'search_path=""'=ANY(p.proconfig) AND r.rolname='marea_person_sync_owner' AND NOT r.rolbypassrls) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace JOIN pg_roles r ON r.oid=p.proowner WHERE n.nspname='collaboration'));
   """)
  L.require(acl=={'client_schema':False,'role_memberships':0,'owner_auth_update':False,'owner_auth_email_read':False,'operator_ensure':False,'owner_person_update':False,'new_functions':5,'private_tables_rls':True,'function_hardening':True},'Private hardening mismatch: '+str(acl))
  # Enumerate every ACL entry granted to either new role, including columns and schemas.
  direct=L.val(pg,"""SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY object,grantee,privilege),'[]') FROM (
   SELECT 'schema:'||n.nspname object,r.rolname grantee,a.privilege_type privilege,a.is_grantable grantable FROM pg_namespace n CROSS JOIN LATERAL aclexplode(n.nspacl)a JOIN pg_roles r ON r.oid=a.grantee WHERE r.rolname LIKE 'marea_person_%'
   UNION ALL SELECT 'table:'||n.nspname||'.'||c.relname,r.rolname,a.privilege_type,a.is_grantable FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace CROSS JOIN LATERAL aclexplode(c.relacl)a JOIN pg_roles r ON r.oid=a.grantee WHERE r.rolname LIKE 'marea_person_%'
   UNION ALL SELECT 'column:'||n.nspname||'.'||c.relname||'.'||v.attname,r.rolname,a.privilege_type,a.is_grantable FROM pg_attribute v JOIN pg_class c ON c.oid=v.attrelid JOIN pg_namespace n ON n.oid=c.relnamespace CROSS JOIN LATERAL aclexplode(v.attacl)a JOIN pg_roles r ON r.oid=a.grantee WHERE r.rolname LIKE 'marea_person_%'
   UNION ALL SELECT 'function:'||p.oid::regprocedure::text,r.rolname,a.privilege_type,a.is_grantable FROM pg_proc p CROSS JOIN LATERAL aclexplode(p.proacl)a JOIN pg_roles r ON r.oid=a.grantee WHERE r.rolname LIKE 'marea_person_%'
  )x;""")
  expected=[];owner='marea_person_sync_owner';operator='marea_person_repair_operator'
  def grant(obj,role,*privileges):
   for privilege in privileges:expected.append({'object':obj,'grantee':role,'privilege':privilege,'grantable':False})
  for schema in ['auth','public','collaboration']:grant('schema:'+schema,owner,'USAGE')
  grant('schema:collaboration',operator,'USAGE')
  for table in ['persons','person_controls','person_repair_manifests']:grant('table:collaboration.'+table,owner,'INSERT','SELECT')
  for column in ['auth.users.id','auth.users.deleted_at','public.account_deletion_requests.user_id','public.account_deletion_requests.requested_at']:grant('column:'+column,owner,'SELECT')
  for column in ['executed_at','result']:grant('column:collaboration.person_repair_manifests.'+column,owner,'UPDATE')
  for function in NEW_FUNCTIONS:grant('function:collaboration.'+function,owner,'EXECUTE')
  for function in ['stage_person_repair(uuid,uuid[])','reconcile_persons(uuid,text,boolean)']:grant('function:collaboration.'+function,operator,'EXECUTE')
  L.require(sorted(map(encoded,direct))==sorted(map(encoded,expected)),'New role ACL differs from exact minimal whitelist')
  # Storage hasn't been served or modified; every physical field remains exact.
  from pax_transport import compare
  expected=json.loads((L.PRIVATE/(a+'-storage-manifest.json')).read_text())['tree'];compare(expected,L.pax_snapshot(f'{L.OWNER}-{a}-storage-copy'))
  all_results[a]={'result':'PASS','DDL_catalog_delta':ddl_diff,'row_conservation_and_separate_fixtures':rows,'sequence_accounting':seq,'effective_hardening':acl,'new_role_direct_ACL_exact':direct,'Storage_bytes_metadata_ns_unchanged':True,'business_RLS_FK_routines_unchanged':True}
 L.save('07-integrity-conservation.json',{'result':'PASS','sources':all_results})
if __name__=='__main__':
 try:verify()
 except Exception as e:
  L.save('FAILURE-'+str(__import__('time').time_ns())+'.json',{'result':'FAIL_STOPPED','error':str(e)});L.stop();raise
