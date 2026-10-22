"""Exact B deltas, original hashes and ACL conservation; no destructive operations."""
import collections,json,re,time
import b_lab as L
from b_cases import fixture,lit
NEW={'marea_deletion_owner','marea_deletion_operator','marea_deletion_case_reader','marea_b_fixture_reader_a','marea_b_fixture_reader_b'}
def enc(x):return json.dumps(x,sort_keys=True,separators=(',',':'))
def acl(s):
 if s is None:return s
 return '{'+','.join(x for x in s.strip('{}').split(',') if x.split('=',1)[0] not in NEW)+'}'
def normalized(item):
 x=json.loads(json.dumps(item))
 if isinstance(x,dict) and 'acl' in x:x['acl']=acl(x['acl'])
 return x
def added(old,now,label):
 a=collections.Counter(map(enc,now));b=collections.Counter(map(enc,old));L.require(not b-a,'Original catalog item changed/removed: '+label);return [json.loads(x) for x in (a-b).elements()]

def run():
 for f in ['15a-notification-fixture-provenance.json','09-core-GREEN.json','12-concurrency.json','13-cases-manifests-GREEN.json','14-S0-compatibility.json']:L.require(json.loads((L.RUN/f).read_text())['result']=='PASS','Functional prerequisites missing')
 results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';base=json.loads((L.PRIVATE/(a+'-B-base.json')).read_text());now=L.capture(pg);f=fixture(a);changes={}
  for section in ['catalog','extra']:
   for key,old in base[section].items():
    cur=now[section][key]
    if not isinstance(old,list):L.require(old==cur,'Catalog scalar drift '+key);continue
    before=[normalized(x) for x in old];after=[normalized(x) for x in cur]
    if key=='column_acl':after=[x for x in after if x['acl']!='{}']
    extras=added(before,after,section+'.'+key)
    for x in extras:
     okay=False
     if key=='roles':okay=x['rolname'] in NEW and not any(x[k] for k in ['rolsuper','rolcreaterole','rolcreatedb','rolreplication','rolbypassrls']) and x['rolcanlogin']==x['rolname'].startswith('marea_b_fixture_')
     elif key=='memberships':okay=x['role_name']=='marea_deletion_case_reader' and x['member'].startswith('marea_b_fixture_reader_') and x['admin_option'] is False
     elif key=='tables':okay=x['schema']=='collaboration' and x['name'].startswith('deletion_') and x['rls'] is True
     elif key=='policies':okay=x['policyname'].startswith('e2b_') and x['roles']==['marea_deletion_owner']
     elif key=='triggers':okay=x['name']=='ab_e2b_obligation' and 'collaboration.deletion_obligation_guard()' in x['definition']
     elif key=='constraints':okay=x['schema']=='collaboration' and 'deletion_' in x['relation'] and (x['type']!='f' or x['validated'] and x['delete_action']=='r')
     elif key=='private_columns':okay=x['table_name'].startswith('deletion_')
     elif key=='indexes':okay=x['schemaname']=='collaboration' and x['tablename'].startswith('deletion_')
     elif key=='all_routines':okay=x['schema']=='collaboration' and x['owner']=='marea_deletion_owner' and x['settings'] is not None and 'search_path=""' in x['settings'] and not any(role+'=' in str(x['acl']) for role in ['anon','authenticated','service_role']) and re.search(r'(^|[,{])=X/',str(x['acl'])) is None
     L.require(okay,'Unexpected catalog addition '+section+'.'+key+': '+enc(x)[:180])
    changes[section+'.'+key]={'added':len(extras),'removed_or_modified_original':0}
  L.require(changes['catalog.tables']['added']==7 and changes['catalog.roles']['added']==5 and changes['extra.all_routines']['added']==9,'Unexpected B object count')
  # Exactly one original E2-A fixture control is intentionally blocked. Rebuild
  # its pre-B row and prove its original hash, preserving every other field.
  uid=f['unequal']['person'];reconstructed=L.val(pg,"SELECT to_jsonb(encode(sha256(convert_to((to_jsonb(c)||jsonb_build_object('sync_blocked',false,'obligations_blocked',false,'blocked_reason',NULL,'deletion_requested_at',NULL,'control_version',1))::text,'UTF8')),'hex')) FROM collaboration.person_controls c WHERE person_id="+lit(uid)+';')
  old_controls=list(base['row_hashes']['collaboration.person_controls']);L.require(reconstructed in old_controls,'Original control cannot be reconstructed exactly');old_controls.remove(reconstructed)
  control=L.val(pg,"SELECT to_jsonb(c) FROM collaboration.person_controls c WHERE person_id="+lit(uid)+';');L.require(control['sync_blocked'] and control['obligations_blocked'] and control['blocked_reason']=='DELETION_PENDING' and control['control_version']==2,'Unexpected original control update')
  deltas={};original=0
  for table,hashes in base['row_hashes'].items():
   original+=len(hashes);old=old_controls if table=='collaboration.person_controls' else hashes;extras=added(old,now['row_hashes'][table],table)
   if extras:deltas[table]=len(extras)
  expected={'auth.users':4,'auth.identities':4,'auth.sessions':4,'auth.refresh_tokens':4,'auth.mfa_amr_claims':4,'auth.audit_log_entries':8,'public.profiles':4,'public.legal_acceptances':4,'collaboration.persons':4,'collaboration.person_controls':5,'public.missions':4,'public.mission_applications':2,'public.notifications':2,'public.notification_preferences':2,'public.account_deletion_requests':4}
  L.require(deltas==expected,'Unexplained original-table delta '+str(deltas))
  newcounts={k:len(v) for k,v in now['row_hashes'].items() if k not in base['row_hashes']};expectednew={'collaboration.deletion_policies':2,'collaboration.deletion_requests':4,'collaboration.deletion_operations':6,'collaboration.deletion_manifest_items':6,'collaboration.deletion_dependency_inventory':98,'collaboration.deletion_cases':12 if a=='a' else 6,'collaboration.deletion_audit':8 if a=='a' else 7};L.require(newcounts==expectednew,'Unexpected B/fixture rows '+str(newcounts))
  sequences=[];after={x['name']:x for x in now['sequences']}
  for old in base['sequences']:
   current=after[old['name']];n=4 if old['name'] in ['auth.refresh_tokens_id_seq','public.legal_acceptances_id_seq'] else 0;L.require(current['last_value']==old['last_value']+n and current['is_called']==old['is_called'],'Unexplained sequence');sequences.append({'name':old['name'],'fixture_nextvals':n})
  tree=L.pax_snapshot(f'{L.OWNER}-{a}-storage-copy');source=json.loads((L.SOURCE_PRIVATE/(a+'-S0-v3-final-storage.manifest.json')).read_text());L.require(tree==source,'Storage changed during B')
  # Explicitly include private triggers, omitted by the inherited public catalog view.
  triggers=L.val(pg,"SELECT jsonb_agg(jsonb_build_object('relation',t.tgrelid::regclass::text,'name',t.tgname,'enabled',t.tgenabled,'function',t.tgfoid::regprocedure::text) ORDER BY t.tgrelid::regclass::text,t.tgname) FROM pg_trigger t WHERE t.tgname IN('ab_e2b_obligation','ab_e2b_control','e2b_append_only');");L.require(len(triggers)==8 and all(t['enabled']=='O' for t in triggers),'Private B triggers missing')
  private_acl=L.val(pg,"SELECT to_jsonb(bool_and(NOT has_table_privilege(r.rolname,c.oid,'SELECT') AND NOT has_table_privilege(r.rolname,c.oid,'INSERT') AND NOT has_table_privilege(r.rolname,c.oid,'UPDATE') AND NOT has_table_privilege(r.rolname,c.oid,'DELETE'))) FROM pg_roles r CROSS JOIN pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE r.rolname IN('anon','authenticated','service_role','marea_deletion_operator','marea_b_fixture_reader_a','marea_b_fixture_reader_b') AND n.nspname='collaboration' AND c.relname LIKE 'deletion_%' AND c.relkind='r';");L.require(private_acl is True,'Private client privileges broadened')
  L.private(a+'-B-final-verified.json',now);results[a]={'result':'PASS','original_rows':original,'original_rows_preserved_except_one_explicit_control_update':True,'original_control_update':{'person_id':uid,'original_hash_proven':reconstructed,'changed_fields':['sync_blocked','obligations_blocked','blocked_reason','deletion_requested_at','control_version']},'exact_original_table_insertions_and_control_replacement':deltas,'exact_new_private_rows':newcounts,'catalog':changes,'private_trigger_inventory':triggers,'private_raw_CRUD_denied_all_clients_and_operators':True,'original_roles_FKs_RLS_business_RPC_and_S0_preserved':True,'sequences':sequences,'Storage_all_bytes_and_attributes_ns_equal':True,'Auth_profile_media_purges':0}
 L.save('15-conservation.json',{'result':'PASS','sources':results,'new_private_roles_NOLOGIN':3,'synthetic_fixture_LOGIN_roles':2,'existing_role_privilege_expansions':0})
if __name__=='__main__':
 try:run()
 except Exception as e:L.save('VERIFY-ATTEMPT-'+str(time.time_ns())+'.json',{'result':'STOPPED_FOR_DIAGNOSIS','error':str(e)});raise
