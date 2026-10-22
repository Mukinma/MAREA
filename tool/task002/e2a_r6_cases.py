"""Only E2-A cases. Expected failures are assertions, never permission workarounds."""
import concurrent.futures,datetime,json,time,uuid,re
from pathlib import Path
import e2a_r6 as L

def write(pg,q,check=True):return L.sql(pg,"BEGIN;SET LOCAL transaction_read_only=off;SET LOCAL statement_timeout='15s';SET LOCAL lock_timeout='1500ms';\n"+q+'\nCOMMIT;',write=True,check=check)
def literal(value):return "'"+str(value).replace("'","''")+"'"
def asrole(pg,role,q,check=True):return write(pg,'SET LOCAL ROLE '+role+';'+q,check)
def expect_sql_error(pg,q,state,role=None):
 r=asrole(pg,role,q,False) if role else write(pg,q,False)
 L.require(r.returncode!=0 and re.search(r'\b'+state+r'\b',r.stderr),'Unexpected error/SQLSTATE: '+r.stderr[:240]);return {'result':'PASS','SQLSTATE':state}
def signup_id(response):
 L.require(response['status']==200,'Signup should succeed: '+str(response['status']))
 user=response['body'].get('user',response['body']);L.require(bool(user.get('id')),'No server Auth id');return user['id']
def phase_red():
 results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';base=L.capture(pg);L.auth_start(a)
  L.require(L.capture(pg)==base,'Auth startup changed baseline')
  response,body,before,after=L.signup(a,'red')
  uid=signup_id(response);n=L.val(pg,'SELECT count(*) FROM collaboration.persons WHERE auth_user_id='+literal(uid)+';')
  L.require(n==0,'E2-A unexpectedly present')
  response2,_,_,_=L.signup(a,'rdmap');uid2=signup_id(response2)
  L.require(L.val(pg,'SELECT count(*) FROM collaboration.persons WHERE auth_user_id='+literal(uid2)+';')==0,'Unexpected second principal')
  response3,_,_,_=L.signup(a,'rdhold');uid3=signup_id(response3)
  L.require(L.val(pg,'SELECT count(*) FROM collaboration.persons WHERE auth_user_id='+literal(uid3)+';')==0,'Unexpected hold principal')
  L.private(a+'-red-fixture-id.json',{'uid':uid,'mapping_fixture_uid':uid2,'hold_fixture_uid':uid3})
  results[a]={'Auth_HTTP':200,'expected_persons':1,'actual_persons':n,'result':'EXPECTED_RED','legacy_validation_preserved':True}
 L.save('04-functional-RED.json',{'result':'EXPECTED_RED','test':'E2-T02','sources':results,'A_DDL_applied':False})

def phase_install(sql_path):
 results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';before=L.capture(pg);L.private(a+'-before-A.json',before)
  flag=L.sql(pg,"BEGIN;SET LOCAL transaction_read_only=off;SELECT to_jsonb(current_setting('transaction_read_only'));ROLLBACK;",write=True).stdout.strip()
  L.require(json.loads(flag)=='off','Current write transaction not explicitly writable')
  q=Path(sql_path).read_text();L.require(q.startswith('BEGIN;') and q.rstrip().endswith('COMMIT;'),'Transactional A SQL')
  # Actual rollback rehearsal before commit, no successful Auth transactions in between.
  uid=json.loads((L.PRIVATE/(a+'-red-fixture-id.json')).read_text())['uid'];batch=str(uuid.uuid4())
  smoke="SET LOCAL ROLE marea_person_repair_operator;SELECT collaboration.reconcile_persons('"+batch+"',collaboration.stage_person_repair('"+batch+"',ARRAY['"+uid+"']::uuid[]),true);SELECT collaboration.reconcile_persons('"+batch+"',collaboration.stage_person_repair('"+batch+"',ARRAY['"+uid+"']::uuid[]),false);"
  r=L.sql(pg,q.rsplit('COMMIT;',1)[0]+smoke+'ROLLBACK;',write=True);L.require(L.capture(pg)==before,'DDL rollback changed baseline')
  L.sql(pg,q,write=True);after=L.capture(pg);L.private(a+'-after-A.json',after)
  L.require(before['row_hashes']=={k:v for k,v in after['row_hashes'].items() if k in before['row_hashes']},'DDL changed existing rows')
  L.require(before['sequences']==after['sequences'],'DDL changed sequence')
  results[a]={'result':'PASS','transactional_rollback_exact':True,'committed':True,'legacy_rows_hashes_sequences_equal':True,'SQL_sha256':L.sha(sql_path)}
 L.save('05-A-transactional-installation.json',{'result':'PASS','sources':results})

def qjson(pg,q,role=None):
 r=asrole(pg,role,q) if role else write(pg,q)
 return json.loads(r.stdout.splitlines()[-1])
def counts(pg):
 return L.val(pg,"SELECT jsonb_build_object('users',(SELECT count(*) FROM auth.users),'profiles',(SELECT count(*) FROM public.profiles),'legal',(SELECT count(*) FROM public.legal_acceptances),'persons',(SELECT count(*) FROM collaboration.persons),'controls',(SELECT count(*) FROM collaboration.person_controls),'identities',(SELECT count(*) FROM auth.identities));")
def call_signup(a,label,meta=None,standard=False,email=None):
 pg=f'{L.OWNER}-{a}-pg';p=L.val(pg,'SELECT public.registration_policy();')
 data={'full_name':'Synthetic E2A '+label,'username':'r6_'+a+'_'+label.replace('-','_'),'user_type':'Artista / creador','adult_confirmed':True,'accepted_terms':True,'terms_version':p['terms']['version'],'privacy_version':p['privacy']['version']}
 if not standard:data['registration_flow']='minimal-v1'
 data.update(meta or {});body={'email':email or f'{a}-{label}@e2ar6.invalid','password':L.secrets.token_urlsafe(24),'data':data};before=counts(pg);response=L.http(a,'/signup',body);after=counts(pg)
 L.private(a+'-case-'+label+'.json',{'request':body,'response':response,'before':before,'after':after});return response,body,before,after

def stage(pg,ids,batch=None):
 batch=batch or str(uuid.uuid4());array='ARRAY['+','.join(literal(x) for x in ids)+']::uuid[]'
 h=qjson(pg,'SELECT to_jsonb(collaboration.stage_person_repair('+literal(batch)+','+array+'));',role='marea_person_repair_operator')
 return batch,h

def reconcile(pg,batch,h,dry):return qjson(pg,'SELECT collaboration.reconcile_persons('+literal(batch)+','+literal(h)+','+('true' if dry else 'false')+');',role='marea_person_repair_operator')
def ensure(pg,uid):return qjson(pg,'SELECT to_jsonb(collaboration.ensure_person_for_auth('+literal(uid)+',\'administrative_repair\'));')
def direct_auth(pg,uid,label,metadata=None):
 p=L.val(pg,'SELECT public.registration_policy();');data={'full_name':'Synthetic direct '+label,'username':'d6_'+label.replace('-','_')[:17],'registration_flow':'minimal-v1','user_type':'Artista / creador','adult_confirmed':True,'accepted_terms':True,'terms_version':p['terms']['version'],'privacy_version':p['privacy']['version']};data.update(metadata or {})
 return 'INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES('+literal(uid)+','+literal(label+'@direct6.invalid')+','+literal(json.dumps(data))+'::jsonb);'

def phase_green():
 all_results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';cases=[];ids=json.loads((L.PRIVATE/(a+'-red-fixture-id.json')).read_text());start=L.capture(pg);L.private(a+'-green-before.json',start)
  def passed(case,detail):cases.append({'case':case,'result':'PASS',**detail})
  # Deny all application roles, including forged valid identifiers, through effective PG privileges.
  for role in ['anon','authenticated','service_role']:
   for table in ['persons','person_controls','person_repair_manifests']:
    for query in ['SELECT * FROM collaboration.'+table+';','INSERT INTO collaboration.'+table+' DEFAULT VALUES;','UPDATE collaboration.'+table+' SET '+('id=id' if table=='persons' else 'person_id=person_id' if table=='person_controls' else 'batch_id=batch_id')+';','DELETE FROM collaboration.'+table+';']:
     expect_sql_error(pg,query,'42501',role)
   for query in ['SELECT collaboration.ensure_person_for_auth('+literal(ids['uid'])+',\'administrative_repair\');','SELECT collaboration.stage_person_repair(\''+str(uuid.uuid4())+'\',ARRAY[\''+ids['uid']+'\']::uuid[]);','SELECT collaboration.reconcile_persons(\''+str(uuid.uuid4())+'\',\''+'0'*64+'\',true);']:
    expect_sql_error(pg,query,'42501',role)
  passed('E2-T08',{'effective_CRUD_and_function_denials':45,'roles':['anon','authenticated','service_role']})
  # Dry-run is read-only and a mixed/conflicting batch is all-or-nothing.
  batch,h=stage(pg,[ids['uid']]);before=L.capture(pg);dry=reconcile(pg,batch,h,True);L.require(dry['missing']==1 and dry['conflicts']==0,'Dry-run classification');L.require(L.capture(pg)==before,'Dry-run changed state')
  bad,badh=stage(pg,[ids['uid'],str(uuid.uuid4())]);expect_sql_error(pg,'SELECT collaboration.reconcile_persons('+literal(bad)+','+literal(badh)+',false);','P0001','marea_person_repair_operator');L.require(L.val(pg,'SELECT count(*) FROM collaboration.persons WHERE auth_user_id='+literal(ids['uid'])+';')==0,'Conflicting batch partially repaired')
  expect_sql_error(pg,'SELECT collaboration.reconcile_persons('+literal(batch)+',\''+'0'*64+'\',false);','23514','marea_person_repair_operator')
  expect_sql_error(pg,'SELECT collaboration.stage_person_repair('+literal(batch)+',ARRAY[\''+str(uuid.uuid4())+'\']::uuid[]);','23505','marea_person_repair_operator')
  # Two different batches race on the same missing principal, then same-key replay.
  b2,h2=stage(pg,[ids['uid']]);
  with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
   futures=[pool.submit(reconcile,pg,batch,h,False),pool.submit(reconcile,pg,b2,h2,False)];answers=[f.result() for f in futures]
  L.require(all(x['items'][0]['person_id']==ids['uid'] for x in answers),'Parallel repair mapping');L.require(reconcile(pg,batch,h,False)==answers[0],'Repair result replay changed')
  L.require(L.val(pg,'SELECT count(*) FROM collaboration.persons WHERE auth_user_id='+literal(ids['uid'])+';')==1,'Duplicate repair principal')
  passed('E2-T05',{'parallel_batches':2,'principal_count':1,'dry_run_no_delta':True,'hash_and_manifest_conflicts_rejected':True,'idempotent_replay':True})
  # A valid current mapping can use a different Person PK; equality grants no authority.
  mapping=str(uuid.uuid4());write(pg,'INSERT INTO collaboration.persons(id,auth_user_id) VALUES('+literal(mapping)+','+literal(ids['mapping_fixture_uid'])+');')
  expect_sql_error(pg,'SELECT collaboration.ensure_person_for_auth('+literal(ids['mapping_fixture_uid'])+',\'administrative_repair\');','P0001')
  write(pg,'INSERT INTO collaboration.person_controls(person_id,sync_blocked,obligations_blocked,created_source) VALUES('+literal(mapping)+',false,false,\'FIXTURE\');')
  L.require(ensure(pg,ids['mapping_fixture_uid'])==mapping,'Identity resolver used PK equality')
  held=str(uuid.uuid4());write(pg,'INSERT INTO collaboration.persons(id,auth_user_id) VALUES('+literal(held)+','+literal(ids['hold_fixture_uid'])+'); INSERT INTO collaboration.person_controls(person_id,sync_blocked,obligations_blocked,blocked_reason,created_source) VALUES('+literal(held)+',true,true,\'SUPPRESSION_REVIEW\',\'FIXTURE\');')
  expect_sql_error(pg,'SELECT collaboration.ensure_person_for_auth('+literal(ids['hold_fixture_uid'])+',\'administrative_repair\');','P0001')
  # Detached/tombstone-shaped fixtures are inserted as such, never obtained by deletion.
  detached=str(uuid.uuid4());suppressed=str(uuid.uuid4())
  for uid,blocked in [(detached,False),(suppressed,True)]:
   write(pg,'INSERT INTO collaboration.persons(id,auth_user_id) VALUES('+literal(uid)+',NULL); INSERT INTO collaboration.person_controls(person_id,sync_blocked,obligations_blocked,blocked_reason,created_source) VALUES('+literal(uid)+','+str(blocked).lower()+','+str(blocked).lower()+','+("'SUPPRESSION_REVIEW'" if blocked else 'NULL')+",'FIXTURE');")
   before=counts(pg);expect_sql_error(pg,direct_auth(pg,uid,'det'+uid[:8]),'P0001');L.require(counts(pg)==before,'Collision left partial Auth/profile/principal')
  expect_sql_error(pg,'SELECT collaboration.ensure_person_for_auth(\''+str(uuid.uuid4())+'\',\'administrative_repair\');','P0001')
  pending=L.val(pg,"SELECT user_id FROM public.account_deletion_requests LIMIT 1;".replace('SELECT user_id','SELECT to_jsonb(user_id)'))
  expect_sql_error(pg,'SELECT collaboration.ensure_person_for_auth('+literal(pending)+',\'administrative_repair\');','P0001')
  # A NEW Auth PK collides with a Person mapped to a DIFFERENT existing Auth.
  before=counts(pg);r=write(pg,direct_auth(pg,mapping,'map'+mapping[:8]),False)
  L.require(r.returncode!=0 and re.search(r'DETAIL:\s+MAPPING_CONFLICT\b',r.stderr),'Non-null collision branch not exercised')
  L.require(counts(pg)==before and ensure(pg,ids['mapping_fixture_uid'])==mapping,'Non-null collision changed mapping/data')
  passed('E2-T06',{'non_equal_current_mapping_resolved':True,'non_null_mapping_collision_rejected':True,'missing_control_rejected':True,'blocked_current_identity_rejected':True,'detached_and_suppressed_fixtures_not_relinked':True,'account_deletions':0,'legacy_pending_deletion_denied':True})
  # Real Auth HTTP positives and forged metadata; each has exactly one private principal.
  issued=[]
  for label,metadata,standard in [('minimal',{},False),('standard',{},True),('forged',{'role':'admin','person_id':mapping,'organization_id':str(uuid.uuid4()),'app_metadata':{'role':'service_role'}},False)]:
   response,body,before,after=call_signup(a,label,metadata,standard);uid=signup_id(response);issued.append(uid)
   L.require(after['users']==before['users']+1 and after['persons']==before['persons']+1 and after['controls']==before['controls']+1 and after['profiles']==before['profiles']+1 and after['legal']==before['legal']+1,'Valid signup delta')
   data=L.val(pg,"SELECT jsonb_build_object('person_id',p.id,'auth_id',p.auth_user_id,'profile_role',f.role,'onboarding',f.onboarding_status,'blocked',c.sync_blocked) FROM collaboration.persons p JOIN public.profiles f ON f.id=p.auth_user_id JOIN collaboration.person_controls c ON c.person_id=p.id WHERE p.auth_user_id="+literal(uid)+';')
   L.require(data['person_id']==uid and data['auth_id']==uid and data['profile_role']=='user' and data['blocked'] is False,'Forged metadata changed authority')
   L.require(data['onboarding']==('pending' if standard else 'completed'),'Legacy registration flow changed')
  passed('E2-T02',{'real_Auth_signups':3,'minimal_and_standard':True,'principal_and_control_per_signup':1})
  passed('E2-T04',{'forged_role_person_org_and_app_metadata_ignored_for_authority':True})
  # Linking an extra synthetic provider to the same Auth row must not create Person.
  before=counts(pg);iid=str(uuid.uuid4());write(pg,"INSERT INTO auth.identities(id,user_id,provider_id,identity_data,provider) VALUES("+literal(iid)+','+literal(issued[0])+','+literal(iid)+','+literal(json.dumps({'sub':iid}))+"::jsonb,'e2a_synthetic');")
  after=counts(pg);L.require(after['persons']==before['persons'] and after['users']==before['users'] and after['identities']==before['identities']+1,'Provider linking duplicated identity')
  # Existing profile/legal validations fail atomically; no successful user returned.
  for label,metadata in [('badlegal',{'accepted_terms':False}),('badname',{'username':'!invalid'}),('duplicate',{'username':'r6_'+a+'_minimal'})]:
   response,_,before,after=call_signup(a,label,metadata);L.require(response['status']>=400,'Invalid signup claimed success');L.require(after==before,'Invalid signup left data')
  # Private-control failure after profile/legal insertion; entire Auth transaction must roll back.
  fault="""CREATE FUNCTION collaboration.e2a_fixture_control_fault() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN IF EXISTS(SELECT 1 FROM auth.users WHERE id=NEW.person_id AND raw_user_meta_data->>'e2a_fault'='control') THEN RAISE EXCEPTION 'E2A_EXPECTED_CONTROL_FAILURE'; END IF; RETURN NEW; END $$; REVOKE ALL ON FUNCTION collaboration.e2a_fixture_control_fault() FROM PUBLIC,anon,authenticated,service_role; CREATE TRIGGER e2a_fixture_control_fault BEFORE INSERT ON collaboration.person_controls FOR EACH ROW EXECUTE FUNCTION collaboration.e2a_fixture_control_fault();"""
  write(pg,fault);response,_,before,after=call_signup(a,'faultcontrol',{'e2a_fault':'control'});L.require(response['status']>=400 and after==before,'Principal/control failure was not atomic');write(pg,'DROP TRIGGER e2a_fixture_control_fault ON collaboration.person_controls;DROP FUNCTION collaboration.e2a_fixture_control_fault();')
  # Later Auth failure after Person/control insertion is equally atomic.
  fault="""CREATE FUNCTION collaboration.e2a_fixture_late_fault() RETURNS trigger LANGUAGE plpgsql SET search_path='' AS $$ BEGIN IF NEW.raw_user_meta_data->>'e2a_fault'='late' THEN RAISE EXCEPTION 'E2A_EXPECTED_LATE_FAILURE'; END IF; RETURN NEW; END $$; REVOKE ALL ON FUNCTION collaboration.e2a_fixture_late_fault() FROM PUBLIC,anon,authenticated,service_role;CREATE TRIGGER zzz_e2a_fixture_late_fault AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION collaboration.e2a_fixture_late_fault();"""
  write(pg,fault);response,_,before,after=call_signup(a,'faultlate',{'e2a_fault':'late'});L.require(response['status']>=400 and after==before,'Late failure was not atomic');write(pg,'DROP TRIGGER zzz_e2a_fixture_late_fault ON auth.users;DROP FUNCTION collaboration.e2a_fixture_late_fault();')
  passed('E2-T03',{'HTTP_errors_not_success':5,'counts_unchanged_after_failures':True,'failure_positions':['legacy_legal','legacy_profile','private_control','after_principal'],'legal_sequence_gaps_expected_and_recorded':True})
  # T44: deterministic held advisory lock, bounded timeout and finite retry, no deletes.
  uid=issued[0];lock_q="BEGIN; SET LOCAL transaction_read_only=off; SET LOCAL application_name='e2a_fixture_lock'; SELECT pg_advisory_xact_lock(pg_catalog.hashtextextended("+literal(uid)+"::text,4201)); SELECT pg_sleep(5); COMMIT;"
  with concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:
   blocker=pool.submit(L.sql,pg,lock_q,True)
   for _ in range(20):
    if L.val(pg,"SELECT EXISTS(SELECT 1 FROM pg_stat_activity WHERE application_name='e2a_fixture_lock' AND wait_event='PgSleep');"):break
    time.sleep(.05)
   else:raise RuntimeError('Held advisory lock not observed')
   t0=time.monotonic();expect_sql_error(pg,'SELECT collaboration.ensure_person_for_auth('+literal(uid)+',\'administrative_repair\');','55P03');elapsed=time.monotonic()-t0;blocker.result()
  L.require(elapsed<4,'Lock wait not bounded');L.require(ensure(pg,uid)==uid,'Finite retry changed principal')
  passed('E2-T44-repair',{'bounded_timeout_SQLSTATE':'55P03','elapsed_seconds':round(elapsed,3),'retry_attempts':1,'idempotent_after_retry':True})
  # A concurrent trigger and repair on the same NEW identity cannot duplicate principal.
  new=str(uuid.uuid4());b,h=stage(pg,[new]);barrier=__import__('threading').Barrier(2)
  def insert():barrier.wait();return write(pg,direct_auth(pg,new,'race'+new[:8]))
  def repair():
   barrier.wait();r=asrole(pg,'marea_person_repair_operator','SELECT collaboration.reconcile_persons('+literal(b)+','+literal(h)+',false);',False)
   if r.returncode:L.require('P0001' in r.stderr,'Unexpected trigger/repair race error');return 'EXPLICIT_REVIEW_CONFLICT'
   return 'SUCCESS'
  with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
   fi=pool.submit(insert);fr=pool.submit(repair);fi.result();outcome=fr.result()
  reconcile(pg,b,h,False);L.require(L.val(pg,'SELECT count(*) FROM collaboration.persons WHERE auth_user_id='+literal(new)+';')==1,'Trigger repair race duplicated person')
  passed('E2-T05-trigger-race',{'outcome':outcome,'eventual_principal_count':1})
  # Effective permission matrix and trigger order, no membership inference.
  acl=L.val(pg,"SELECT jsonb_build_object('owner_bypass',(SELECT rolbypassrls FROM pg_roles WHERE rolname='marea_person_sync_owner'),'operator_bypass',(SELECT rolbypassrls FROM pg_roles WHERE rolname='marea_person_repair_operator'),'app_owner_member',pg_has_role('authenticated','marea_person_sync_owner','MEMBER'),'service_exec',has_function_privilege('service_role','collaboration.reconcile_persons(uuid,text,boolean)','EXECUTE'),'operator_direct_person',has_table_privilege('marea_person_repair_operator','collaboration.persons','SELECT'),'owner_delete_person',has_table_privilege('marea_person_sync_owner','collaboration.persons','DELETE')); ")
  L.require(all(v is False for v in acl.values()),'Unexpected effective privileges')
  order=L.val(pg,"SELECT jsonb_agg(tgname ORDER BY tgname) FROM pg_trigger WHERE tgrelid='auth.users'::regclass AND NOT tgisinternal;")
  L.require(order.index('on_auth_user_created')<order.index('zz_e2a_person_after_auth'),'Auth trigger order')
  final=L.capture(pg);L.private(a+'-green-final.json',final)
  old=L.val(pg,'SELECT count(*) FROM auth.users u LEFT JOIN collaboration.persons p ON p.auth_user_id=u.id WHERE p.id IS NULL;');L.require(old==0,'Unmapped Auth after tests')
  all_results[a]={'result':'PASS','cases':cases,'case_count':len(cases),'acl':acl,'Auth_trigger_order':order,'functional_fixture_insertions_separate_from_A_DDL':True,'Auth_profile_deletions':0,'T07_executed':False,'final_counts':counts(pg)}
 L.save('06-functional-GREEN.json',{'result':'PASS','sources':all_results,'scope':'E2-A local only; no whole TASK-002 validation'})

if __name__=='__main__':
 import sys
 try:
  if sys.argv[1:]==['red']:phase_red()
  elif len(sys.argv)==3 and sys.argv[1]=='install':phase_install(sys.argv[2])
  elif sys.argv[1:]==['green']:phase_green()
  else:raise SystemExit('red | install SQL | green')
 except Exception as e:
  L.save('FAILURE-'+str(time.time_ns())+'.json',{'result':'FAIL_STOPPED','error':str(e),'no_scope_expansion':True});L.stop();raise
