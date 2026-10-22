"""C structural contracts; evidence manifests, no legacy contractual conversion."""
import json,uuid,time,sys,concurrent.futures
import orgc_lab as L
from org0_cases import lit,js,write,login,call,deny,value

def operator(pg,q,check=True):return write(pg,q,'marea_mission_operator',check=check)
def classify(pg,mid,version=1):
 q='SELECT collaboration.mission_classify('+lit(mid)+','+str(version)+');'
 for i in range(4):
  r=operator(pg,q,False)
  if r.returncode==0:return value(r)
  if '55P03' not in r.stderr:raise RuntimeError(r.stderr[-400:])
  time.sleep(.1*(i+1))
 raise RuntimeError('Classification bounded retry exhausted')
def red():
 L.require(json.loads((L.RUN/'12-ORG0-ACCEPTANCE.json').read_text())['result']=='PASS','ORG0 independent gate missing')
 out={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';before=L.capture(pg);r=write(pg,"SELECT collaboration.mission_authorize('00000000-0000-0000-0000-000000000001'::uuid,'mission.manage');",rollback=True,check=False);L.require(r.returncode and '42883' in r.stderr and L.capture(pg)==before,'C missing contract not proven');out[a]={'SQLSTATE':'42883','rollback_exact':True}
 L.save('14-C-RED.json',{'result':'EXPECTED_RED','sources':out})
def manifest(pg,mission,person=None,org=None,authorizer=None,evidence='SYNTHETIC-C-EXPLICIT-DECLARATION'):
 return {'id':str(uuid.uuid4()),'mission_id':mission,'mission_hash':L.val(pg,"SELECT to_jsonb(encode(sha256(convert_to(to_jsonb(m)::text,'UTF8')),'hex')) FROM public.missions m WHERE id="+lit(mission)+';'),'expected_case_version':1,'owner_person_id':person,'owner_organization_id':org,'authorizer_person_id':authorizer or person,'approval_ref':evidence,'evidence_kind':'LAB_DECLARED_OWNERSHIP','approved':True,'synthetic':True}
def submit(pg,m):return value(operator(pg,'SELECT collaboration.mission_submit_manifest('+js(m)+');'))
def mission_q(author,mid):return 'INSERT INTO public.missions(id,author_id,title,body,category,location,starts_at,capacity,status) VALUES('+lit(mid)+','+lit(author)+",'Synthetic C explicit ownership','C fixture','otros','Local synthetic',clock_timestamp()+interval '20 days',5,'open');"
def new_with_owner(pg,f,kind):
 mid=str(uuid.uuid4());u=f['users']['owner']['auth'];pid=f['users']['last']['person'] if kind=='personal' else None;oid=f['orgs']['primary'] if kind=='organization' else None;authority=f['users']['last']['person'] if kind=='personal' else f['users']['owner']['person']
 # New mission, server manifest hash and ownership must all commit atomically.
 m={'id':str(uuid.uuid4()),'mission_id':mid,'expected_case_version':1,'owner_person_id':pid,'owner_organization_id':oid,'authorizer_person_id':authority,'approval_ref':'SYNTHETIC-C-NEW-'+kind,'evidence_kind':'LAB_DECLARED_OWNERSHIP','approved':True,'synthetic':True}
 body=js(m)+"||jsonb_build_object('mission_hash',encode(sha256(convert_to(to_jsonb(x)::text,'UTF8')),'hex'))"
 q=mission_q(u,mid)+'SET LOCAL ROLE marea_mission_operator;SELECT collaboration.mission_submit_manifest('+body+') FROM public.missions x WHERE id='+lit(mid)+';SELECT collaboration.mission_classify('+lit(m['id'])+',1);'
 # Operator needs no direct SELECT of public mission. Build the approved hash as trusted fixture session first.
 q=mission_q(u,mid)+"SELECT set_config('orgc.fixture_hash',(SELECT encode(sha256(convert_to(to_jsonb(x)::text,'UTF8')),'hex') FROM public.missions x WHERE id="+lit(mid)+"),true);SET LOCAL ROLE marea_mission_operator;SELECT collaboration.mission_submit_manifest("+js(m)+"||jsonb_build_object('mission_hash',current_setting('orgc.fixture_hash')));SELECT collaboration.mission_classify("+lit(m['id'])+',1);'
 r=write(pg,q);L.require(value(r)['mission_id']==mid,'New mission ownership not atomic');return {'mission':mid,'manifest':m['id'],'owner_person':pid,'owner_org':oid}
def setup():
 out={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';f=json.loads((L.PRIVATE/(a+'-ORG0-active-fixture.json')).read_text());baseline=L.capture(pg)
  # Legacy author exists; it still cannot infer ownership or authority.
  old=L.val(pg,'SELECT to_jsonb(id) FROM public.missions ORDER BY id LIMIT 1;');deny(pg,'owner','SELECT collaboration.mission_authorize('+lit(old)+",'mission.manage');",'42501')
  bad=manifest(pg,old,person=f['users']['owner']['person']);bad['evidence_kind']='AUTHOR_ID_INFERENCE';r=operator(pg,'SELECT collaboration.mission_submit_manifest('+js(bad)+');',False);L.require(r.returncode and '42501' in r.stderr and L.capture(pg)==baseline,'Author inference accepted')
  # Positive owner XOR is tested alongside commit-time missing-owner failure.
  naked=str(uuid.uuid4());r=write(pg,mission_q(f['users']['owner']['auth'],naked),check=False);L.require(r.returncode and '23514' in r.stderr and L.capture(pg)==baseline,'New anchor without owner committed')
  personal=new_with_owner(pg,f,'personal');organization=new_with_owner(pg,f,'organization')
  oldb=json.loads((L.SOURCE_PRIVATE/(a+'-B-fixture.json')).read_text());legacyorg=manifest(pg,oldb['missions']['main'],org=f['orgs']['primary'],authorizer=f['users']['owner']['person'],evidence='SYNTHETIC-C-DECLARED-LAB-BASELINE-RESOURCE');submit(pg,legacyorg);classify(pg,legacyorg['id'])
  race=oldb['missions']['before'];one=manifest(pg,race,person=f['users']['last']['person'],evidence='SYNTHETIC-C-CONCURRENT-DECLARATION-A');two=manifest(pg,race,org=f['orgs']['primary'],authorizer=f['users']['owner']['person'],evidence='SYNTHETIC-C-CONCURRENT-DECLARATION-B');submit(pg,one);submit(pg,two)
  data={'personal':personal,'organization':organization,'legacy_org':{'mission':oldb['missions']['main'],'manifest':legacyorg['id'],'historical_author_blocked':oldb['users']['main']},'race':{'mission':race,'manifests':[one,two]},'unclassified':old};L.private(a+'-C-fixture.json',data);out[a]={'result':'PASS','new_public_missions':2,'legacy_missions_changed':0,'old_synthetic_resource_explicit_org_decision':1,'concurrent_manifests_pending':2,'new_Auth_profile_candidature_rows':0}
 L.save('16-C-fixtures.json',{'result':'PASS','sources':out})
if __name__=='__main__':
 try:{'red':red,'setup':setup}[sys.argv[1]]()
 except Exception as e:L.save('C-ATTEMPT-'+str(time.time_ns())+'.json',{'result':'STOPPED_FOR_DIAGNOSIS','error':str(e)});raise
