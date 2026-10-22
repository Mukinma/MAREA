"""One final-review fix pass. Actual stale snapshots and replay preconditions."""
import json,uuid,time,concurrent.futures,sys
import orgc_lab as L
from org0_cases import lit,js,write,call,login,value,deny
from org0_more import wait_sleep
from c_cases import operator

def red():
 out={}
 for a in ['a','b']:
  pg=L.OWNER+'-'+a+'-pg';f=json.loads((L.PRIVATE/(a+'-ORG0-active-fixture.json')).read_text());c=json.loads((L.PRIVATE/(a+'-C-fixture.json')).read_text());org=str(uuid.uuid4());manifest={'synthetic':True,'approval_ref':'SYNTHETIC-REVIEW-STALE-SNAPSHOT','operation_id':str(uuid.uuid4()),'organization_id':org,'owner_person_id':f['users']['owner']['person'],'name':'Synthetic review snapshot','permissions':['organization.view','mission.manage','member.manage']};value(write(pg,'SELECT collaboration.org_provision('+js(manifest)+');','marea_org_operator'));membership=call(pg,'owner','SELECT collaboration.org_invite('+lit(str(uuid.uuid4()))+','+lit(org)+','+lit(f['users']['editor']['person'])+",'editor',ARRAY['mission.manage']::text[],true);")['membership_id'];call(pg,'editor','SELECT collaboration.org_respond('+lit(str(uuid.uuid4()))+','+lit(membership)+',true,1);')
  label='org_review_old_snapshot';q="BEGIN ISOLATION LEVEL REPEATABLE READ;SET LOCAL transaction_read_only=off;SET LOCAL statement_timeout='10s';SET LOCAL application_name="+lit(label)+";SELECT count(*) FROM pg_class;SELECT pg_sleep(1.5);SELECT collaboration.org_authorize("+lit(org)+",'mission.manage');COMMIT;"
  def stale():return L.docker('exec','-i',pg,'psql','-X','-h','/tmp','-U','marea_org_fixture_editor','-d','postgres','-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose','-Atq',input=q,check=False)
  with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
   answer=pool.submit(stale);wait_sleep(pg,label);call(pg,'owner','SELECT collaboration.org_revoke('+lit(str(uuid.uuid4()))+','+lit(membership)+',2);');r=answer.result(timeout=12)
  L.require(r.returncode==0 and json.loads(r.stdout.splitlines()[-1])['authorized'],'Old-snapshot authorization defect not reproduced');deny(pg,'editor','SELECT collaboration.org_authorize('+lit(org)+",'mission.manage');")
  winner=json.loads((L.PRIVATE/(a+'-C-classifier-winner.json')).read_text());before=L.capture(pg)
  for version in ['NULL','999']:
   r=operator(pg,'SELECT collaboration.mission_classify('+lit(winner['manifest_id'])+','+version+');');L.require(value(r)==winner,'Wrong-version replay defect not reproduced')
  L.require(L.capture(pg)==before,'Replay RED mutated state');L.private(a+'-review-snapshot-fixture.json',{'organization_id':org,'membership_id':membership,'org_new_operations':4,'org_new_memberships':2,'org_new_organizations':1,'classification_manifest':winner['manifest_id']});out[a]={'result':'EXPECTED_RED','RR_snapshot_established_before_committed_revocation':True,'stale_authorization_wrongly_allowed':True,'read_committed_denies_revoked':True,'NULL_999_classification_replay_wrongly_accepted':True,'replay_no_delta':True}
 L.save('23-review-RED.json',{'result':'EXPECTED_RED','sources':out})

def green():
 out={}
 for a in ['a','b']:
  pg=L.OWNER+'-'+a+'-pg';f=json.loads((L.PRIVATE/(a+'-ORG0-active-fixture.json')).read_text());r=json.loads((L.PRIVATE/(a+'-review-snapshot-fixture.json')).read_text());before=L.capture(pg)
  for level in ['REPEATABLE READ','SERIALIZABLE']:
   q='BEGIN ISOLATION LEVEL '+level+";SET LOCAL transaction_read_only=off;SELECT count(*) FROM pg_class;SELECT collaboration.org_authorize("+lit(f['orgs']['primary'])+",'mission.manage');ROLLBACK;";ans=L.docker('exec','-i',pg,'psql','-X','-h','/tmp','-U','marea_org_fixture_owner','-d','postgres','-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose','-Atq',input=q,check=False);L.require(ans.returncode and '0A000' in ans.stderr and 'FRESH_READ_COMMITTED_REQUIRED' in ans.stderr,'Stale-snapshot isolation level accepted')
  deny(pg,'editor','SELECT collaboration.org_authorize('+lit(r['organization_id'])+",'mission.manage');")
  for version in ['NULL','999']:
   ans=operator(pg,'SELECT collaboration.mission_classify('+lit(r['classification_manifest'])+','+version+');',False);L.require(ans.returncode and '40001' in ans.stderr,'Replay version precondition bypass')
  correct=value(operator(pg,'SELECT collaboration.mission_classify('+lit(r['classification_manifest'])+',1);'));L.require(correct['manifest_id']==r['classification_manifest'],'Valid replay broken');L.require(call(pg,'owner','SELECT collaboration.org_authorize('+lit(f['orgs']['primary'])+",'mission.manage');")['authorized'],'Current valid actor broken');L.require(L.capture(pg)==before,'Final review probes mutated data');out[a]={'result':'PASS','RR_SERIALIZABLE_denied_0A000':True,'current_revoked_denied_42501':True,'NULL_999_replay_denied_40001':True,'valid_read_committed_and_replay_pass':True,'snapshot_exact':True}
 L.save('25-review-GREEN.json',{'result':'PASS','sources':out})
if __name__=='__main__':
 if sys.argv[1]=='patch':
  from orgc_patch import install
  install('tool/task002/orgc_review_fix.sql','orgc_final_review_fix','24-review-installation.json')
 else:{'red':red,'green':green}[sys.argv[1]]()
