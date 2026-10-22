"""C invariants, actual FK/constraints, permission and classifier races."""
import json,time,uuid,concurrent.futures,sys
import orgc_lab as L
from org0_cases import lit,js,write,login,call,deny,value
from c_cases import operator,classify,submit,manifest

def fixtures(a):return (json.loads((L.PRIVATE/(a+'-ORG0-active-fixture.json')).read_text()),json.loads((L.PRIVATE/(a+'-C-fixture.json')).read_text()))
def relation_probe(phase):
 results={}
 for a in ['a','b']:
  pg=L.OWNER+'-'+a+'-pg';f,c=fixtures(a);target=L.val(pg,'SELECT to_jsonb(mission_id) FROM collaboration.mission_migration_cases WHERE migration_state=\'REVIEW_REQUIRED\' AND mission_id<>'+lit(c['race']['mission'])+' ORDER BY mission_id LIMIT 1;');mid=c['race']['manifests'][0]['id'];baseline=L.capture(pg)
  q='INSERT INTO collaboration.mission_ownership(mission_id,owner_person_id,manifest_id) VALUES('+lit(target)+','+lit(f['users']['last']['person'])+','+lit(mid)+');SET CONSTRAINTS ALL IMMEDIATE;'
  r=write(pg,q,rollback=True,check=False);L.require(L.capture(pg)==baseline,'Invalid sidecar probe changed data')
  if phase=='RED':L.require(r.returncode==0,'Unbound evidence bypass not reproduced '+r.stderr)
  else:L.require(r.returncode!=0 and '23514' in r.stderr,'Sidecar evidence not bound to resource')
  # Even matching evidence cannot bypass the classified case + durable receipt.
  q='INSERT INTO collaboration.mission_ownership(mission_id,owner_person_id,manifest_id) VALUES('+lit(c['race']['mission'])+','+lit(f['users']['last']['person'])+','+lit(mid)+');SET CONSTRAINTS ALL IMMEDIATE;'
  r=write(pg,q,rollback=True,check=False);L.require(L.capture(pg)==baseline,'Raw sidecar probe changed data')
  if phase=='RED':L.require(r.returncode==0,'Missing classification receipt bypass not reproduced')
  else:L.require(r.returncode!=0 and '23514' in r.stderr,'Ownership lacks deferred receipt/case check')
  results[a]={'result':'EXPECTED_RED' if phase=='RED' else 'PASS','wrong_manifest_resource':True,'matching_manifest_without_receipt':True,'full_rollback_equal':True}
 L.save('18a-C-evidence-RED.json' if phase=='RED' else '18c-C-evidence-GREEN.json',{'result':'EXPECTED_RED' if phase=='RED' else 'PASS','sources':results})

def green():
 results={}
 for a in ['a','b']:
  pg=L.OWNER+'-'+a+'-pg';f,c=fixtures(a);pers=lit(c['personal']['mission']);org=lit(c['organization']['mission']);baseline=L.capture(pg)
  L.require(call(pg,'last','SELECT collaboration.mission_authorize('+pers+",'mission.manage');")['context']=='PERSONAL','Personal positive failed')
  L.require(call(pg,'owner','SELECT collaboration.mission_authorize('+org+",'mission.manage');")['context']=='ORGANIZATION','Org positive failed')
  for who,mid in [('owner',pers),('editor',org),('admin',org),('outsider',org),('member',org)]:deny(pg,who,'SELECT collaboration.mission_authorize('+mid+",'mission.manage');")
  deny(pg,'owner','SELECT collaboration.mission_authorize('+org+",'agreement.accept');")
  deny(pg,'outsider',"SELECT set_config('request.jwt.claim.sub',"+lit(f['users']['owner']['auth'])+",true);SELECT collaboration.mission_authorize("+org+",'mission.manage');")
  # Effective XOR checks, before FK/unique processing.
  for pp,oo in [(None,None),(f['users']['last']['person'],f['orgs']['primary'])]:
   q='INSERT INTO collaboration.mission_ownership(mission_id,owner_person_id,owner_organization_id,manifest_id) VALUES('+pers+','+lit(pp)+','+lit(oo)+','+lit(c['personal']['manifest'])+');'
   r=write(pg,q,rollback=True,check=False);L.require(r.returncode and '23514' in r.stderr,'XOR not enforced')
  # Manifests themselves use real FK; no fake organization compiles into ownership.
  m=manifest(pg,c['race']['mission'],org=str(uuid.uuid4()),authorizer=f['users']['owner']['person']);q="INSERT INTO collaboration.mission_ownership_manifests(id,mission_id,mission_hash,expected_case_version,owner_organization_id,authorizer_person_id,approval_ref,evidence_kind,approved,synthetic,input_hash) VALUES("+lit(m['id'])+','+lit(m['mission_id'])+','+lit(m['mission_hash'])+',1,'+lit(m['owner_organization_id'])+','+lit(m['authorizer_person_id'])+",'SYNTHETIC-C-FK','LAB_DECLARED_OWNERSHIP',true,true,repeat('0',64));";r=write(pg,q,rollback=True,check=False);L.require(r.returncode and '23503' in r.stderr,'Real organization FK not enforced')
  # Legacy mutations cannot gain authority merely from author_id.
  r=write(pg,'UPDATE public.missions SET title=title||\' forged\' WHERE id='+pers+';','service_role',rollback=True,check=False);L.require(r.returncode and '55000' in r.stderr,'Legacy author mutation bypass')
  for table,column in [('mission_ownership','version'),('mission_ownership_manifests','expected_case_version')]:
   r=write(pg,'UPDATE collaboration.'+table+' SET '+column+'='+column+'+1;',rollback=True,check=False);L.require(r.returncode and '55000' in r.stderr,'Evidence update allowed')
  # Direct ACL, including DELETE privileges, for all prior client roles and genuine actors.
  for role in ['anon','authenticated','service_role','marea_org_fixture_owner','marea_org_fixture_editor','marea_mission_operator']:
   for table in ['mission_ownership','mission_ownership_manifests','mission_migration_cases','mission_classification_operations']:
    for statement in ['SELECT * FROM collaboration.'+table+';','INSERT INTO collaboration.'+table+' DEFAULT VALUES;','UPDATE collaboration.'+table+' SET '+('mission_id=mission_id' if table!='mission_classification_operations' else 'manifest_id=manifest_id')+';']:
     r=write(pg,statement,role,rollback=True,check=False);L.require(r.returncode and '42501' in r.stderr,'Raw private C access')
    L.require(L.val(pg,'SELECT to_jsonb(has_table_privilege('+lit(role)+','+lit('collaboration.'+table)+",'DELETE'));") is False,'Private DELETE capability')
  L.require(L.capture(pg)==baseline,'Negative C probes changed snapshot')
  # Distinct classifiers compete for a legacy synthetic resource explicitly declared in both manifests.
  mids=[m['id'] for m in c['race']['manifests']]
  def attempt(mid):
   for i in range(5):
    r=operator(pg,'SELECT collaboration.mission_classify('+lit(mid)+',1);',False)
    if r.returncode==0:return {'success':True,'receipt':value(r)}
    if '40001' in r.stderr:return {'success':False,'SQLSTATE':'40001'}
    L.require('55P03' in r.stderr,'Uncontrolled classifier conflict '+r.stderr[-200:]);time.sleep(.1*(i+1))
   raise RuntimeError('Classifier retries exhausted')
  with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:answers=list(pool.map(attempt,mids))
  L.require(sum(x['success'] for x in answers)==1,'Different classifier decisions did not resolve one winner');winner=next(x['receipt'] for x in answers if x['success']);before=L.capture(pg);L.require(classify(pg,winner['manifest_id'])==winner and L.capture(pg)==before,'Classifier replay changed state')
  L.private(a+'-C-classifier-winner.json',winner)
  # Positive candidatures are real SQL writes, rolled back with all notification side effects.
  for mission,candidate,expected in [(c['personal']['mission'],f['users']['owner']['auth'],None),(c['organization']['mission'],f['users']['last']['auth'],None),(c['legacy_org']['mission'],f['users']['last']['auth'],None),(c['personal']['mission'],f['users']['last']['auth'],'PERSONAL_SELF_APPLICATION_FORBIDDEN'),(c['organization']['mission'],f['users']['member']['auth'],'D10_RELATED_ELIGIBILITY_PENDING')]:
   before=L.capture(pg);q='INSERT INTO public.mission_applications(mission_id,applicant_id,message) VALUES('+lit(mission)+','+lit(candidate)+",'Synthetic C candidature');";r=write(pg,q,'service_role',rollback=True,check=False)
   if expected:L.require(r.returncode and '42501' in r.stderr and expected in r.stderr,'Candidate eligibility gate missing')
   else:L.require(r.returncode==0,'Actual candidate insert rejected '+r.stderr[-250:])
   L.require(L.capture(pg)==before,'Candidature fixture changed persistent data')
  # Every accepted legacy row remains byte-identical; attempt new unilateral acceptance only rolls back.
  before=L.capture(pg);aid=L.val(pg,'SELECT to_jsonb(id) FROM public.mission_applications WHERE mission_id='+lit(c['legacy_org']['mission'])+' ORDER BY id LIMIT 1;');L.require(aid,'Protected original candidature fixture missing');r=write(pg,"UPDATE public.mission_applications SET status='accepted' WHERE id="+lit(aid)+';','service_role',rollback=True,check=False);L.require(r.returncode and '55000' in r.stderr and 'UPDATE_REQUIRED_NO_CONTRACTUAL_ENGINE' in r.stderr and L.capture(pg)==before,'False new acceptance allowed')
  results[a]={'result':'PASS','personal_org_server_permission_positive':True,'creator_exrep_editor_cross_org_denied':True,'XOR_23514_and_org_FK_23503':True,'private_direct_ACL_denials':72,'classification_race_one_winner':True,'replay_exact':True,'real_candidature_insert_rollback_positive':3,'self_and_D10_related_denied':True,'blocked_historical_author_not_owner':True,'unilateral_acceptance_denied_original_accepted_unchanged':True,'contractual_tests':'NOT_IMPLEMENTED'}
 L.save('19-C-GREEN.json',{'result':'PASS','sources':results})
if __name__=='__main__':
 try:
  if sys.argv[1]=='evidence-red':relation_probe('RED')
  elif sys.argv[1]=='evidence-green':relation_probe('GREEN')
  elif sys.argv[1]=='patch':
   from orgc_patch import install
   install('tool/task002/c_evidence_binding.sql','e2c_evidence_binding','18b-C-evidence-installation.json')
  else:green()
 except Exception as e:L.save('C-MORE-ATTEMPT-'+str(time.time_ns())+'.json',{'result':'STOPPED_FOR_DIAGNOSIS','error':str(e)});raise
