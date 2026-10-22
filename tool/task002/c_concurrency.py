"""Mission-context revocation uses the real ORG0 transaction boundary."""
import json,uuid,concurrent.futures
import orgc_lab as L
from org0_cases import lit,call,login,deny
from org0_more import wait_sleep

def run():
 out={}
 for a in ['a','b']:
  pg=L.OWNER+'-'+a+'-pg';f=json.loads((L.PRIVATE/(a+'-ORG0-active-fixture.json')).read_text());c=json.loads((L.PRIVATE/(a+'-C-fixture.json')).read_text());o=lit(f['orgs']['primary']);mid=lit(c['organization']['mission']);p=lit(f['users']['last']['person']);m=call(pg,'owner','SELECT collaboration.org_invite('+lit(str(uuid.uuid4()))+','+o+','+p+",'editor',ARRAY['mission.manage','application.review']::text[],true);")['membership_id'];call(pg,'last','SELECT collaboration.org_respond('+lit(str(uuid.uuid4()))+','+lit(m)+',true,1);')
  L.require(call(pg,'last','SELECT collaboration.mission_authorize('+mid+",'mission.manage');")['context']=='ORGANIZATION','Explicit org context failed')
  label='c_authorized_rep_before_revoke';q="SET LOCAL application_name="+lit(label)+';SELECT collaboration.mission_authorize('+mid+",'mission.manage');SELECT pg_sleep(1);"
  with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
   first=pool.submit(login,pg,'last',q);wait_sleep(pg,label);deny(pg,'owner','SELECT collaboration.org_revoke('+lit(str(uuid.uuid4()))+','+lit(m)+',2);','55P03');L.require(first.result(timeout=12).returncode==0,'Authorized mission transaction not completed')
  result=call(pg,'owner','SELECT collaboration.org_revoke('+lit(str(uuid.uuid4()))+','+lit(m)+',2);');L.require(result['status']=='REVOKED','Mission representative not revoked');deny(pg,'last','SELECT collaboration.mission_authorize('+mid+",'mission.manage');")
  L.require(call(pg,'last','SELECT collaboration.mission_authorize('+lit(c['personal']['mission'])+",'mission.manage');")['context']=='PERSONAL','Organizational revocation removed personal ownership')
  L.private(a+'-C-extra-membership.json',{'id':m,'person_id':f['users']['last']['person'],'organization_id':f['orgs']['primary'],'final_status':'REVOKED','version':3,'permissions':['mission.manage','application.review'],'new_org_operations':3})
  out[a]={'result':'PASS','actual_mission_resolver_vs_membership_revocation':True,'inflight_linearizes_before_revoke':True,'contention':'55P03','exrepresentative_after_commit':'42501','personal_context_remains_valid':True,'new_private_membership_fixture':1,'org_operations_audit':3,'TASK003_HTTP_socket_Storage_revocation':'NOT_IMPLEMENTED'}
 L.save('20-C-concurrency-context.json',{'result':'PASS','sources':out})
if __name__=='__main__':run()
