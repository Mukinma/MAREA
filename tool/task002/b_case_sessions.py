"""Case authorization with genuine fixture login identities, never admin SET ROLE."""
import json,time,uuid
import b_lab as L
from b_cases import lit,write,valwrite,deny,request,progress,fixture
READERS=['marea_b_fixture_reader_a','marea_b_fixture_reader_b']
def login_sql(pg,q,role=READERS[0],check=True):
 L.require_preflight();L.owned(pg);L.require(role in READERS,'Fixture login only')
 return L.docker('exec','-i',pg,'psql','-X','-h','/tmp','-U',role,'-d','postgres','-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose','-Atq',input="BEGIN;SET LOCAL transaction_read_only=off;SET LOCAL statement_timeout='10s';"+q+'COMMIT;',check=check)
def denied(pg,q):
 r=login_sql(pg,q,check=False);L.require(r.returncode!=0 and '42501' in r.stderr,'Case session rejection missing: '+r.stderr[-200:])
def run():
 L.require(json.loads((L.RUN/'12-concurrency.json').read_text())['result']=='PASS','Concurrency phase required');results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';f=fixture(a);main=json.loads((L.PRIVATE/(a+'-B-main-receipt.json')).read_text())['request_id'];identity=json.loads(login_sql(pg,"SELECT jsonb_build_object('session_user',session_user,'effective_role',current_user,'role_guc',current_setting('role'));").stdout)
  L.require(identity=={'session_user':READERS[0],'effective_role':READERS[0],'role_guc':'none'},'Case test did not authenticate genuine fixture identity')
  other=request(pg,f['users']['other'],f['ops']['other']);valwrite(pg,'SELECT collaboration.prepare_person_deletion_manifest('+lit(other['request_id'])+',1,NULL);');p=progress(pg,f['users']['other'],other['request_id']);L.require(p['policy_status']=='MISSING_POLICY' and not p['purge_ready'],'Missing policy not protected')
  ids={k:str(uuid.uuid4()) for k in ['valid','foreign','expired','revoked','expired_policy','beyond_policy']};L.private(a+'-B-case-fixture-v2.json',{'ids':ids,'main':main,'authenticated_fixture_role':READERS[0]})
  for k,cid in ids.items():
   role=READERS[1] if k=='foreign' else READERS[0];expiry="clock_timestamp()-interval '1 second'" if k=='expired' else "clock_timestamp()+interval '2 hours'" if k=='beyond_policy' else "clock_timestamp()+interval '10 minutes'";policy='SYNTHETIC-EXPIRED' if k=='expired_policy' else 'SYNTHETIC-B1';active='false' if k=='revoked' else 'true'
   write(pg,'INSERT INTO collaboration.deletion_cases(id,request_id,assigned_role,purpose,policy_id,expires_at,active) VALUES('+lit(cid)+','+lit(main)+','+lit(role)+",'DELETION_REVIEW',"+lit(policy)+','+expiry+','+active+');')
  start=L.val(pg,"SELECT count(*) FROM collaboration.deletion_audit WHERE event='CASE_READ';")
  positive=json.loads(login_sql(pg,'SELECT collaboration.deletion_case_progress('+lit(ids['valid'])+",'DELETION_REVIEW');").stdout);L.require(set(positive)=={'request_id','stage','version','completed','purge_ready','resource_count','pending_dependency_count'} and not positive['completed'],'Case leaked unapproved fields')
  for k in ['foreign','expired','revoked','expired_policy','beyond_policy']:denied(pg,'SELECT collaboration.deletion_case_progress('+lit(ids[k])+",'DELETION_REVIEW');")
  denied(pg,'SELECT collaboration.deletion_case_progress('+lit(str(uuid.uuid4()))+",'DELETION_REVIEW');");denied(pg,'SELECT collaboration.deletion_case_progress('+lit(ids['valid'])+",'MARKETING');")
  denied(pg,"SELECT set_config('marea.case_actor','marea_b_fixture_reader_b',true);SELECT collaboration.deletion_case_progress("+lit(ids['foreign'])+",'DELETION_REVIEW');")
  denied(pg,'SET LOCAL ROLE marea_deletion_operator;')
  denied(pg,'SELECT * FROM collaboration.deletion_requests;');denied(pg,'UPDATE collaboration.deletion_cases SET active=true;')
  L.require(L.val(pg,"SELECT count(*) FROM collaboration.deletion_audit WHERE event='CASE_READ';")==start+1,'Case audit not exact')
  # Transactional constraints and private ACL remain independent of the transport.
  deny(pg,'SELECT collaboration.assert_person_purge_ready('+lit(main)+');','55000')
  results[a]={'result':'PASS','E2_T46':'PASS_STRUCTURAL_REAL_DATABASE_IDENTITY','identity':identity,'assigned_case_read_audited':1,'prior_fixture_case_reads_preserved':start,'case_and_privilege_rejections':11,'minimal_response_fields':sorted(positive),'missing_policy_protected':True,'synthetic_policy_never_authorizes_purge':True,'actual_profile_evidence_or_paths_exposed':False,'fixture_LOGIN_roles_only':READERS}
 L.save('13-cases-manifests-GREEN.json',{'result':'PASS','sources':results,'TASK003_and_Flutter_session_integration':'BLOCKED_NOT_IMPLEMENTED'})
if __name__=='__main__':
 try:run()
 except Exception as e:L.save('CASE-SESSION-ATTEMPT-'+str(time.time_ns())+'.json',{'result':'STOPPED_FOR_DIAGNOSIS','error':str(e)});raise
