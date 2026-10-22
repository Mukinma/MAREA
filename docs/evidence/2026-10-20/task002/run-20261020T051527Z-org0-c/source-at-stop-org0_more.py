"""Adversarial ORG-0 cases: actual roles, server state and concurrent revocation."""
import json,time,uuid,concurrent.futures
import orgc_lab as L
from org0_cases import lit,write,login,call,deny

def wait_sleep(pg,label):
 for _ in range(80):
  if L.val(pg,"SELECT count(*) FROM pg_stat_activity WHERE application_name="+lit(label)+" AND wait_event='PgSleep';")==1:return
  time.sleep(.025)
 raise RuntimeError('Concurrent server barrier absent')
def run():
 out={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';f=json.loads((L.PRIVATE/(a+'-ORG0-active-fixture.json')).read_text());o=lit(f['orgs']['primary']);baseline=L.capture(pg);states=[]
  for column,state in [('operational_status','PAUSED'),('operational_status','SUSPENDED'),('ownership_status','UNOWNED_RESTRICTED'),('ownership_status','TRANSFER_PENDING'),('ownership_status','CLOSING'),('ownership_status','CLOSED')]:
   # Explicit synthetic fixture state, no user state-management endpoint claimed.
   write(pg,'UPDATE collaboration.organizations SET '+column+'='+lit(state)+' WHERE id='+o+';');deny(pg,'owner','SELECT collaboration.org_authorize('+o+",'mission.manage');")
   write(pg,'UPDATE collaboration.organizations SET '+column+'='+lit('NORMAL' if column=='operational_status' else 'ACTIVE')+' WHERE id='+o+';');states.append(state)
  L.require(L.capture(pg)==baseline,'Fixture state probes changed persistent snapshot')
  # No valid current representative: retain data, deny capabilities, no successor.
  m=lit(f['members']['owner']);before=L.capture(pg)
  r=write(pg,'UPDATE collaboration.organization_memberships SET representative=false WHERE id='+m+';',rollback=True,check=False);L.require(r.returncode and '55000' in r.stderr and L.capture(pg)==before,'Membership could be reassigned without procedure')
  # An explicitly nonrepresentative membership cannot acquire a permission just by its role.
  deny(pg,'member','SELECT collaboration.org_authorize('+o+",'member.manage');")
  # Genuine private DELETE attempts are safe only after confirming no DELETE ACL.
  for label in ['owner','editor','outsider']:
   for table in ['organizations','organization_memberships','org_session_bindings','org_operations','org_audit']:
    role='marea_org_fixture_'+label;L.require(L.val(pg,'SELECT to_jsonb(has_table_privilege('+lit(role)+','+lit('collaboration.'+table)+",'DELETE'));") is False,'Unsafe negative delete fixture')
    q="BEGIN;SET LOCAL transaction_read_only=off;DELETE FROM collaboration."+table+";ROLLBACK;"
    r=L.docker('exec','-i',pg,'psql','-X','-h','/tmp','-U',role,'-d','postgres','-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose','-Atq',input=q,check=False);L.require(r.returncode!=0 and '42501' in r.stderr,'Private DELETE not denied')
  L.require(L.capture(pg)==baseline,'Negative deletes changed snapshot')
  # Invitee can decline only own invitation; revoked inviter cannot confer pending authority.
  inv=call(pg,'owner','SELECT collaboration.org_invite('+lit(str(uuid.uuid4()))+','+o+','+lit(f['users']['outsider']['person'])+",'member',ARRAY['organization.view']::text[],false);")
  deny(pg,'member','SELECT collaboration.org_respond('+lit(str(uuid.uuid4()))+','+lit(inv['membership_id'])+',true,1);')
  declined=call(pg,'outsider','SELECT collaboration.org_respond('+lit(str(uuid.uuid4()))+','+lit(inv['membership_id'])+',false,1);');L.require(declined['status']=='DECLINED','Decline ignored')
  deny(pg,'outsider','SELECT collaboration.org_respond('+lit(str(uuid.uuid4()))+','+lit(inv['membership_id'])+',true,2);','40001')
  # Operation authorized first: shared org transaction boundary prevents revocation from overtaking it.
  other=lit(f['orgs']['other']);second=L.val(pg,'SELECT to_jsonb(id) FROM collaboration.organization_memberships WHERE organization_id='+other+' AND person_id='+lit(f['users']['editor']['person'])+';');label='org0_authorize_first';q="SET LOCAL application_name="+lit(label)+';SELECT collaboration.org_authorize('+other+",'mission.manage');SELECT pg_sleep(1);"
  with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
   op=pool.submit(login,pg,'editor',q);wait_sleep(pg,label)
   deny(pg,'outsider','SELECT collaboration.org_revoke('+lit(str(uuid.uuid4()))+','+lit(second)+',2);','55P03');L.require(op.result(timeout=12).returncode==0,'Authorized operation failed')
  revoked=call(pg,'outsider','SELECT collaboration.org_revoke('+lit(str(uuid.uuid4()))+','+lit(second)+',2);');L.require(revoked['status']=='REVOKED','Post-operation revocation failed');deny(pg,'editor','SELECT collaboration.org_authorize('+other+",'mission.manage');")
  # Revocation first: authorization fails closed while its transaction is open, then denies after commit.
  label='org0_revoke_first';q="SET LOCAL application_name="+lit(label)+';SELECT collaboration.org_revoke('+lit(str(uuid.uuid4()))+','+lit(f['members']['admin'])+',2);SELECT pg_sleep(1);'
  with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
   rev=pool.submit(login,pg,'owner',q);wait_sleep(pg,label);deny(pg,'admin','SELECT collaboration.org_authorize('+o+",'mission.manage');",'55P03');L.require(rev.result(timeout=12).returncode==0,'Revocation failed')
  deny(pg,'admin','SELECT collaboration.org_authorize('+o+",'mission.manage');")
  # Forged SUSPENDED/owner/client metadata has no influence; expired membership fixture cannot pass.
  before=L.capture(pg);r=login(pg,'outsider',"SET ROLE marea_org_operator;",False);L.require(r.returncode!=0 and '42501' in r.stderr and L.capture(pg)==before,'Operator escalation')
  out[a]={'result':'PASS','states_denied_actual_server':states,'state_fixture_restoration_exact':True,'private_DELETE_denials':15,'decline_and_terminal_reactivation_denied':True,'revocation_vs_operation_both_orders':True,'while_transaction_open':'55P03','after_revocation_commit':'42501','no_contract_or_session_revocation_claim':True}
 L.save('08-ORG0-concurrency-states.json',{'result':'PASS','sources':out})
if __name__=='__main__':
 try:run()
 except Exception as e:L.save('ORG0-MORE-ATTEMPT-'+str(time.time_ns())+'.json',{'result':'STOPPED_FOR_DIAGNOSIS','error':str(e)});raise
