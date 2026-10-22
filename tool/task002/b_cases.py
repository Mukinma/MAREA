"""Real PostgreSQL B contracts and Auth fixtures; no purge or client mock."""
import concurrent.futures,json,time,uuid,sys
import b_lab as L
import s0_services as S
def lit(x):return "NULL" if x is None else "'"+str(x).replace("'","''")+"'"
def write(pg,q,role=None,check=True):return L.sql(pg,"BEGIN;SET LOCAL transaction_read_only=off;SET LOCAL lock_timeout='1500ms';SET LOCAL statement_timeout='15s';"+('SET LOCAL ROLE '+role+';' if role else '')+q+'COMMIT;',write=True,check=check)
def valwrite(pg,q,role='marea_deletion_operator'):
 r=write(pg,q,role);return json.loads(r.stdout.splitlines()[-1])
def deny(pg,q,state,role='marea_deletion_operator'):
 r=write(pg,q,role,False);L.require(r.returncode!=0 and state in r.stderr,'Wrong SQL rejection: '+r.stderr[-300:]);return {'SQLSTATE':state,'result':'PASS'}
def request(pg,uid,op,version=1):return valwrite(pg,'SELECT collaboration.request_person_deletion('+lit(uid)+','+lit(op)+','+str(version)+",'USER_REQUEST');")
def progress(pg,uid,rid):return valwrite(pg,'SELECT collaboration.person_deletion_progress('+lit(uid)+','+lit(rid)+');')
def record(name,value):
 p=L.PRIVATE/name
 if p.exists():L.require(json.loads(p.read_text())==value,'Existing receipt differs')
 else:L.private(name,value)
def fixture(a):return json.loads((L.PRIVATE/(a+'-B-fixture.json')).read_text())
def mission_q(uid,mid):return "INSERT INTO public.missions(id,author_id,title,body,category,location,starts_at,capacity,status) VALUES("+lit(mid)+','+lit(uid)+",'Synthetic B mission','B fixture','otros','Local synthetic',clock_timestamp()+interval '20 days',10,'open');"
def app_q(uid,mid,aid=None):return "INSERT INTO public.mission_applications(id,mission_id,applicant_id,message) VALUES("+lit(aid or str(uuid.uuid4()))+','+lit(mid)+','+lit(uid)+",'Synthetic B candidature');"

def setup():
 from b_stages import require_receipts
 require_receipts('03-new-clones-recovery.json','07-parent-guard-GREEN.json')
 results={}
 for a in ['a','b']:
  L.require(not (L.PRIVATE/(a+'-B-fixture.json')).exists(),'Do not replay fixture setup');pg=f'{L.OWNER}-{a}-pg';before=L.capture(pg);S.auth_start(a,'auth-B');L.require(L.capture(pg)==before,'Auth startup drift');users={}
  policy=L.val(pg,'SELECT public.registration_policy();')
  for label in ['main','race','other','before']:
   name='b_'+a+'_'+label+'_'+uuid.uuid4().hex[:6];body={'email':name+'@b.invalid','password':uuid.uuid4().hex+'Aa1!','data':{'full_name':'Synthetic B '+label,'username':name,'registration_flow':'minimal-v1','user_type':'Artista / creador','adult_confirmed':True,'accepted_terms':True,'terms_version':policy['terms']['version'],'privacy_version':policy['privacy']['version']}}
   response=S.request(a,9999,'/signup','POST',data=body);L.private(a+'-B-signup-'+label+'.json',{'request':body,'response':response});L.require(response['status']==200,'Auth fixture signup failed');users[label]=response['body']['user']['id']
  unequal=L.val(pg,"SELECT jsonb_build_object('auth',p.auth_user_id,'person',p.id) FROM collaboration.persons p JOIN collaboration.person_controls c ON c.person_id=p.id JOIN auth.users u ON u.id=p.auth_user_id WHERE p.id<>p.auth_user_id AND NOT c.obligations_blocked AND u.deleted_at IS NULL ORDER BY p.id LIMIT 1;");L.require(unequal is not None,'Validated unequal mapping absent')
  ids={'users':users,'unequal':unequal,'ops':{k:str(uuid.uuid4()) for k in ['main','main2','main3','race','other','unequal']},'missions':{k:str(uuid.uuid4()) for k in ['main','race','other','before']},'application_before':str(uuid.uuid4()),'application_other':str(uuid.uuid4())}
  L.private(a+'-B-fixture.json',ids)
  for k in ['main','race','other','before']:write(pg,mission_q(users[k],ids['missions'][k]),'service_role')
  write(pg,app_q(users['before'],ids['missions']['main'],ids['application_before']),'service_role')
  write(pg,"CREATE ROLE marea_b_fixture_reader_a NOLOGIN INHERIT;CREATE ROLE marea_b_fixture_reader_b NOLOGIN INHERIT;GRANT marea_deletion_case_reader TO marea_b_fixture_reader_a,marea_b_fixture_reader_b;INSERT INTO collaboration.deletion_policies(id,category,purpose,responsible_role,retention_seconds,conservation_state,disposition,synthetic,approved_for_lab) VALUES('SYNTHETIC-B1','STRUCTURAL_REVIEW','DELETION_REVIEW','marea_deletion_case_reader',3600,'PROTECTED_PENDING_DECISION','REVIEW_REQUIRED',true,true);INSERT INTO collaboration.deletion_policies(id,category,purpose,responsible_role,retention_seconds,conservation_state,disposition,synthetic,approved_for_lab,created_at) VALUES('SYNTHETIC-EXPIRED','STRUCTURAL_REVIEW','DELETION_REVIEW','marea_deletion_case_reader',60,'PROTECTED_PENDING_DECISION','REVIEW_REQUIRED',true,true,clock_timestamp()-interval '2 hours');")
  L.private(a+'-B-after-fixtures.json',L.capture(pg));results[a]={'result':'PASS','real_Auth_signups':4,'new_missions':4,'new_candidatures':1,'explicit_synthetic_policies':2,'fixtures_separate_from_B_DDL':True}
 L.save('08-fixtures.json',{'result':'PASS','sources':results})

def core():
 results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';f=fixture(a);u=f['users'];ops=f['ops'];cases=[]
  # Response intentionally discarded after the real SQL commit. This is a
  # structural consumer-loss test, not an HTTP endpoint/integration claim.
  request(pg,u['main'],ops['main']);seen=L.val(pg,'SELECT to_jsonb(id) FROM collaboration.deletion_requests WHERE person_id=(SELECT id FROM collaboration.persons WHERE auth_user_id='+lit(u['main'])+');');L.require(seen is not None,'Commit not durable before retry')
  receipt=request(pg,u['main'],ops['main']);L.require(receipt['request_id']==seen and receipt['completed'] is False,'Discard/retry inconsistent');record(a+'-B-main-receipt.json',receipt)
  before=L.capture(pg);L.require(request(pg,u['main'],ops['main'])==receipt and L.capture(pg)==before,'Replay mutated receipt or state')
  deny(pg,'SELECT collaboration.request_person_deletion('+lit(u['main'])+','+lit(ops['main'])+",2,'USER_REQUEST');",'23505')
  deny(pg,'SELECT collaboration.request_person_deletion('+lit(u['other'])+','+lit(ops['main'])+",1,'USER_REQUEST');",'23505')
  with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:answers=[r.result() for r in [pool.submit(request,pg,u['main'],ops['main2']),pool.submit(request,pg,u['main'],ops['main3'])]]
  L.require(all(x==receipt for x in answers),'Concurrent requests duplicated or altered receipt');L.require(L.val(pg,'SELECT count(*) FROM collaboration.deletion_requests WHERE id='+lit(seen)+';')==1,'Duplicate request')
  p=progress(pg,u['main'],seen);L.require(p['consistent'] is True and p['completed'] is False and p['purge_ready'] is False,'Progress falsely completed or inconsistent');cases.append({'case':'E2-T10','result':'PASS','concurrent_requests':2,'response_discarded_after_SQL_commit':True,'HTTP_integration_claimed':False})
  deny(pg,'SELECT collaboration.person_deletion_progress('+lit(u['other'])+','+lit(seen)+');','42501')
  absent=progress(pg,u['main'],str(uuid.uuid4()));L.require(absent['request_exists'] is False and absent['completed'] is False and absent['purge_ready'] is False,'Missing state allowed completion')
  deny(pg,'SELECT collaboration.assert_person_purge_ready('+lit(seen)+');','55000');deny(pg,'SELECT collaboration.assert_person_purge_ready('+lit(str(uuid.uuid4()))+');','55000')
  deny(pg,"UPDATE collaboration.deletion_requests SET stage='COMPLETED' WHERE id="+lit(seen)+';','23514',None)
  deny(pg,'UPDATE collaboration.person_controls SET obligations_blocked=false,control_version=control_version+1 WHERE person_id=(SELECT id FROM collaboration.persons WHERE auth_user_id='+lit(u['main'])+');','55000',None)
  # Real existing RPC rejection + ordinary privileged raw writes, no fabricated contract engine.
  rpc=write(pg,"SELECT set_config('request.jwt.claim.sub',"+lit(u['main'])+",true);SELECT public.create_mission('{}'::jsonb);",'authenticated',False);L.require(rpc.returncode!=0 and 'account_deletion_pending' in rpc.stderr,'RPC did not reject at actual deletion block')
  deny(pg,mission_q(u['main'],str(uuid.uuid4())),'55000','service_role')
  deny(pg,app_q(u['main'],f['missions']['before']),'55000','service_role')
  deny(pg,app_q(u['other'],f['missions']['main']),'55000','service_role')
  cases.append({'case':'E2-T11_PARTIAL','result':'PASS_STRUCTURAL_ONLY','real_mission_RPC_and_raw_publication_candidatures_denied':True,'contracts_offers_reservations':'NO_IMPLEMENTADO'})
  # Mapping resolution, not Person/Auth PK equality; no identity relinking.
  neq=request(pg,f['unequal']['auth'],ops['unequal']);L.require(L.val(pg,'SELECT to_jsonb(person_id) FROM collaboration.deletion_requests WHERE id='+lit(neq['request_id'])+';')==f['unequal']['person'],'Person PK equality used as identity')
  deny(pg,'SELECT collaboration.request_person_deletion('+lit(f['unequal']['person'])+','+lit(str(uuid.uuid4()))+",1,'USER_REQUEST');",'P0002')
  deny(pg,'SELECT collaboration.ensure_person_for_auth('+lit(u['main'])+",'administrative_repair');",'P0001',None)
  # Corrupt or missing states fail closed, including forbidden raw application access.
  for role in ['anon','authenticated','service_role','marea_deletion_operator','marea_b_fixture_reader_a']:
   for table in ['deletion_requests','deletion_operations','deletion_manifest_items','deletion_dependency_inventory','deletion_cases','deletion_audit','deletion_policies']:
    for q in ['SELECT * FROM collaboration.'+table+';','INSERT INTO collaboration.'+table+' DEFAULT VALUES;']:
     deny(pg,q,'42501',role)
  for role in ['anon','authenticated','service_role','marea_b_fixture_reader_a']:
   deny(pg,'SELECT collaboration.request_person_deletion('+lit(u['before'])+','+lit(str(uuid.uuid4()))+",1,'USER_REQUEST');",'42501',role)
  cases.append({'case':'effective_privileges','result':'PASS','raw_reads_inserts_denied':70,'request_entry_denials':4,'roles_existing_clients_unchanged':True})
  # Negative account/profile deletes are literal fixture-only, rolled back,
  # checked against inherited S0 guards before entering the database.
  for table,role in [('auth.users','service_role'),('auth.users','supabase_auth_admin'),('public.profiles','service_role')]:
   guards=L.val(pg,"SELECT count(*) FROM pg_trigger WHERE tgrelid="+lit(table)+"::regclass AND tgname='aa_s0_delete' AND tgenabled='O';");L.require(guards==1,'Negative delete requires proven S0 guard');before=L.capture(pg)
   q="BEGIN;SET LOCAL transaction_read_only=off;SET LOCAL ROLE "+role+';DELETE FROM '+table+' WHERE id='+lit(u['main'])+';ROLLBACK;'
   r=L.docker('exec','-i',pg,'psql','-X','-h','/tmp','-U','supabase_admin','-d','postgres','-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose','-Atq',input=q,check=False)
   L.require(L.capture(pg)==before,'Negative delete changed any data');expected='42501' if table=='auth.users' and role=='service_role' else '55000'
   L.require(r.returncode!=0 and expected in r.stderr,'Unsafe negative delete not denied');L.require(expected=='42501' or 'S0_DESTRUCTIVE_TRANSITION_FENCED' in r.stderr,'S0 guard not exercised')
  get=S.request(a,9999,'/admin/users/'+u['main'],token=S.jwt(a));L.require(get['status']==200,'Invalid Auth admin credential');before=L.capture(pg);deleted=S.request(a,9999,'/admin/users/'+u['main'],'DELETE',data={'should_soft_delete':False},token=S.jwt(a));L.require(deleted['status']>=400 and L.capture(pg)==before,'Auth admin negative lost data')
  cases.append({'case':'E2-T09','result':'PASS_NEGATIVE_ONLY','ordinary_SQL_Auth_profile_and_real_Auth_API_denied':True,'successful_purges':0})
  record(a+'-B-core-final.json',L.capture(pg));results[a]={'result':'PASS','cases':cases,'request_id':seen,'source_unequal_request_id':neq['request_id'],'successfully_deleted_accounts':0}
 L.save('09-core-GREEN.json',{'result':'PASS','sources':results,'blocked':['complete_Auth_purge','Flutter','contractual_T11','TASK003_revocation','E2_D','E2_M']})

if __name__=='__main__':
 try:
  if sys.argv[1:]==['setup']:setup()
  elif sys.argv[1:]==['core']:core()
  else:raise SystemExit('setup | core')
 except Exception as e:L.save('CASE-ATTEMPT-'+str(time.time_ns())+'.json',{'result':'STOPPED_FOR_DIAGNOSIS','error':str(e)});raise
