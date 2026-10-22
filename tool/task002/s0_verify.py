"""Scoped equality of original data, schema and physical objects; fixture deltas explicit."""
import collections,hashlib,json,posixpath,time
import s0_lab_v2 as L
import s0_fence as F
from s0_cases import private_fixture

def enc(x):return json.dumps(x,sort_keys=True,separators=(',',':'))
def additions(before,after,label):
 a=collections.Counter(map(enc,after));b=collections.Counter(map(enc,before));L.require(not b-a,'Existing '+label+' changed/removed');return [json.loads(x) for x in (a-b).elements()]

def run():
 L.require(json.loads((L.RUN/'15-additional-tests.json').read_text())['result']=='PASS','Complete functional/negative tests required')
 results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';base=json.loads((L.PRIVATE/(a+'-S0-base.json')).read_text());now=L.capture(pg);L.private(a+'-S0-final-verified.json',now);report={}
  for section in ['catalog','extra']:
   for key,old in base[section].items():
    current=now[section][key]
    if not isinstance(old,list):L.require(old==current,'Catalog drift '+key);continue
    added=additions(old,current,section+'.'+key)
    for item in added:
     allowed=section=='catalog' and key=='triggers' and item['name'].startswith('aa_s0_') and 'EXECUTE FUNCTION collaboration.s0_deny_mutation()' in item['definition'] or section=='extra' and key=='all_routines' and item['signature']=='collaboration.s0_deny_mutation()' and item['owner']=='supabase_admin' and item['security_definer'] is False and item['acl']=='{supabase_admin=X/supabase_admin}'
     L.require(allowed,'Unexpected catalog addition '+section+'.'+key+': '+enc(item)[:250])
    report[section+'.'+key]={'original':len(old),'added':len(added),'removed_or_modified':0}
  L.require(report['catalog.triggers']['added']==40 and report['extra.all_routines']['added']==1,'S0 exact DDL delta mismatch');F.reconcile_active(a)
  delta={};original_rows=0
  for table,hashes in base['row_hashes'].items():
   extra=additions(hashes,now['row_hashes'][table],table);original_rows+=len(hashes)
   if extra:delta[table]=len(extra)
  n=2 if a=='a' else 1
  expected={'auth.users':n,'auth.identities':n,'auth.sessions':n,'auth.refresh_tokens':n,'auth.mfa_amr_claims':n,'auth.audit_log_entries':2*n,'public.profiles':n,'public.legal_acceptances':n,'collaboration.persons':n,'collaboration.person_controls':n,'public.missions':2,'storage.objects':1,'public.account_deletion_requests':1}
  L.require(delta==expected,'Fixture delta unexplained: '+str(delta))
  sequences=[];final_seq={s['name']:s for s in now['sequences']}
  for old in base['sequences']:
   cur=final_seq[old['name']];growth=n if old['name'] in ['auth.refresh_tokens_id_seq','public.legal_acceptances_id_seq'] else 0
   L.require(cur['last_value']==old['last_value']+growth and cur['is_called']==old['is_called'],'Unexplained sequence '+old['name']);sequences.append({'name':old['name'],'initial':old['last_value'],'final':cur['last_value'],'fixture_nextvals':growth})
  f=private_fixture(a);initial=json.loads((L.PRIVATE/(a+'-storage-manifest.json')).read_text())['tree'];protected=json.loads((L.PRIVATE/(a+'-T49-v2-before.json')).read_text())['tree'];current=L.pax_snapshot(f'{L.OWNER}-{a}-storage-copy');L.require(current==protected,'Any physical field changed during S0 tests')
  oldpaths={x['path']:x for x in initial};newpaths={x['path']:x for x in current};new_entries=[x for x in current if x['path'] not in oldpaths];ancestors=set()
  for entry in new_entries:
   p=posixpath.dirname(entry['path'])
   while p:ancestors.add(p);p=posixpath.dirname(p)
  prefix='data/stub/stub/mission-images/'+f['user'];L.require(all(x['path']==prefix or x['path'].startswith(prefix+'/') for x in new_entries),'Unexpected physical fixture addition')
  parent_times=[]
  for path,old in oldpaths.items():
   L.require(path in newpaths,'Original physical entry missing');cur=newpaths[path]
   differences=[k for k in set(old)|set(cur) if old.get(k)!=cur.get(k)]
   if differences:
    L.require(old['kind']==cur['kind']=='dir' and path in ancestors and set(differences)<={'atime_ns','mtime_ns'},'Original physical asset/permission changed: '+path)
    parent_times.append({'path':path,'before':{k:old[k] for k in differences},'after':{k:cur[k] for k in differences},'cause':'New RED fixture directory creation/removal/compensating upload before S0; unchanged since full T49 baseline'})
  results[a]={'result':'PASS','original_rows_preserved_by_hash':original_rows,'catalog':report,'exact_fixture_insertions':delta,'sequence_accounting':sequences,'original_physical_entries_preserved':len(initial),'fixture_physical_entries':len(new_entries),'ancestor_directory_time_deltas_before_S0':parent_times,'all_physical_fields_equal_since_T49_baseline':True,'Auth_profile_deletions':0,'missions_author_FK_unchanged':True,'roles_grants_policies_existing_routines_unchanged':True,'no_B_or_other_increment':True}
 L.save('19-data-conservation.json',{'result':'PASS','sources':results})
if __name__=='__main__':
 try:run()
 except Exception as e:L.save('VERIFY-FAIL-'+str(time.time_ns())+'.json',{'result':'BLOCKED','error':str(e)});L.stop();raise
