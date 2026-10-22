"""Exact legacy equality and allowlisted ORG-0 structural delta."""
import json,collections,re
import orgc_lab as L
from org0_cases import lit
NEW={'marea_org_owner','marea_org_operator','marea_org_actor'}|{'marea_org_fixture_'+x for x in ['owner','admin','editor','member','outsider','last']}
TABLES={'organizations','organization_memberships','org_session_bindings','org_operations','org_audit'}
def enc(x):return json.dumps(x,sort_keys=True,separators=(',',':'))
def normalize(item):
 x=json.loads(json.dumps(item))
 if isinstance(x,dict) and x.get('acl') is not None:x['acl']='{'+','.join(s for s in x['acl'].strip('{}').split(',') if s.split('=',1)[0] not in NEW)+'}'
 return x
def delta(old,new,label):
 a=collections.Counter(map(enc,new));b=collections.Counter(map(enc,old));L.require(not b-a,'Existing catalog/data changed '+label);return [json.loads(x) for x in (a-b).elements()]
def run():
 for f in ['07-ORG0-GREEN.json','08-ORG0-concurrency-states.json','08b-ORG0-expiry-integrity.json']:L.require(json.loads((L.RUN/f).read_text())['result']=='PASS','ORG0 tests required')
 results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';before=json.loads((L.PRIVATE/(a+'-orgc-base.json')).read_text());now=L.capture(pg);changes={}
  L.require(now['sequences']==before['sequences'],'Sequence changed in private ORG0 stage')
  for t,h in before['row_hashes'].items():L.require(now['row_hashes'][t]==h,'Original rows changed '+t)
  for section in ['catalog','extra']:
   for key,old in before[section].items():
    cur=now[section][key]
    if not isinstance(old,list):L.require(cur==old,'Catalog scalar '+key);continue
    after=[normalize(x) for x in cur];prior=[normalize(x) for x in old]
    if key=='column_acl':after=[x for x in after if x['acl']!='{}']
    extras=delta(prior,after,section+'.'+key)
    for x in extras:
     good=False
     if key=='roles':good=x['rolname'] in NEW and not any(x[k] for k in ['rolsuper','rolcreaterole','rolcreatedb','rolreplication','rolbypassrls']) and x['rolcanlogin']==x['rolname'].startswith('marea_org_fixture_')
     elif key=='memberships':good=x['role_name']=='marea_org_actor' and x['member'].startswith('marea_org_fixture_') and not x['admin_option']
     elif key=='tables':good=x['schema']=='collaboration' and x['name'] in TABLES and x['rls'] is True
     elif key=='policies':good=x['policyname'].startswith('org0_') and x['roles']==['marea_org_owner']
     elif key=='constraints':good=x['schema']=='collaboration' and any(x['relation'].split('.')[-1]==t for t in TABLES) and (x['type']!='f' or x['validated'] and x['delete_action']=='r')
     elif key=='private_columns':good=x['table_name'] in TABLES
     elif key=='indexes':good=x['schemaname']=='collaboration' and x['tablename'] in TABLES
     elif key=='all_routines':good=x['schema']=='collaboration' and x['signature'].startswith('collaboration.org_') and x['owner']=='marea_org_owner' and 'search_path=""' in (x['settings'] or []) and not any(r+'=' in str(x['acl']) for r in ['anon','authenticated','service_role']) and re.search(r'(^|[,{])=X/',str(x['acl'])) is None
     L.require(good,'Unexpected catalog addition '+section+'.'+key+': '+enc(x)[:240])
    changes[section+'.'+key]=len(extras)
  counts={k:len(v) for k,v in now['row_hashes'].items() if k not in before['row_hashes']};L.require(counts=={'collaboration.org_audit':16,'collaboration.org_operations':16,'collaboration.org_session_bindings':6,'collaboration.organization_memberships':9,'collaboration.organizations':3},'Unexpected new private rows '+str(counts))
  L.require(changes['catalog.tables']==5 and changes['catalog.roles']==9 and changes['extra.all_routines']==12,'Unexpected ORG0 objects')
  acl=L.val(pg,"SELECT to_jsonb(bool_and(NOT has_table_privilege(r.rolname,c.oid,'SELECT') AND NOT has_table_privilege(r.rolname,c.oid,'INSERT') AND NOT has_table_privilege(r.rolname,c.oid,'UPDATE') AND NOT has_table_privilege(r.rolname,c.oid,'DELETE'))) FROM pg_roles r CROSS JOIN pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE r.rolname IN('anon','authenticated','service_role','marea_org_operator','marea_org_actor','marea_org_fixture_owner','marea_org_fixture_editor') AND n.nspname='collaboration' AND c.relname IN('organizations','organization_memberships','org_session_bindings','org_operations','org_audit');");L.require(acl is True,'Raw private CRUD granted')
  for kind,stem in [('storage','B-final-storage'),('control-v2','B-final-control')]:L.require(L.pax_snapshot(f'{L.OWNER}-{a}-{kind}-copy')==json.loads((L.SOURCE_PRIVATE/(a+'-'+stem+'.manifest.json')).read_text()),'Physical tree drift '+kind)
  L.private(a+'-ORG0-final-v2-verified.json',now);results[a]={'result':'PASS','all_legacy_row_hashes_exact':True,'legacy_rows':sum(map(len,before['row_hashes'].values())),'all_sequences_equal':True,'old_roles_RLS_FKs_routine_bodies_preserved':True,'catalog_additions':changes,'private_row_counts':counts,'raw_private_CRUD_denied':True,'Storage_coordination_bytes_attributes_ns_unchanged':True,'purges':0}
 L.save('09b-ORG0-conservation-final.json',{'result':'PASS','sources':results,'existing_client_privileges_expanded':False})
if __name__=='__main__':run()
