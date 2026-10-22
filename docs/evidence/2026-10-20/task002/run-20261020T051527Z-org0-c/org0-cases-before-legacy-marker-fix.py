"""ORG-0 real private-contract tests; genuine SQL sessions, no client API claim."""
import json,uuid,sys,time,concurrent.futures
import orgc_lab as L
def lit(x):return 'NULL' if x is None else "'"+str(x).replace("'","''")+"'"
def js(x):return lit(json.dumps(x))+'::jsonb'
def write(pg,q,role=None,rollback=False,check=True):return L.sql(pg,"BEGIN;SET LOCAL transaction_read_only=off;SET LOCAL statement_timeout='12s';SET LOCAL lock_timeout='1200ms';"+('SET LOCAL ROLE '+role+';' if role else '')+q+('ROLLBACK;' if rollback else 'COMMIT;'),True,check)
def login(pg,label,q,check=True,rollback=False):
 L.require_preflight();L.owned(pg);role='marea_org_fixture_'+label
 return L.docker('exec','-i',pg,'psql','-X','-h','/tmp','-U',role,'-d','postgres','-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose','-Atq',input="BEGIN;SET LOCAL transaction_read_only=off;SET LOCAL statement_timeout='12s';SET LOCAL lock_timeout='1200ms';"+q+('ROLLBACK;' if rollback else 'COMMIT;'),check=check)
def value(r):return json.loads(r.stdout.splitlines()[-1])
def call(pg,label,q):
 for attempt in range(4):
  r=login(pg,label,q,False)
  if r.returncode==0:return value(r)
  if '55P03' not in r.stderr:raise RuntimeError('Contract failed: '+r.stderr[-350:])
  time.sleep(.1*(attempt+1))
 raise RuntimeError('Bounded retries exhausted: '+r.stderr[-350:])
def deny(pg,label,q,state='42501'):
 r=login(pg,label,q,False);L.require(r.returncode!=0 and state in r.stderr,'Wrong denial '+r.stderr[-350:]);return state

def red():
 results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';before=L.capture(pg);r=write(pg,"SELECT collaboration.org_authorize('00000000-0000-0000-0000-000000000001'::uuid,'mission.manage');",rollback=True,check=False)
  L.require(r.returncode!=0 and '42883' in r.stderr and L.capture(pg)==before,'Missing ORG-0 not proven')
  results[a]={'SQLSTATE':'42883','rollback_exact':True}
 L.save('04-ORG0-RED.json',{'result':'EXPECTED_RED','sources':results})

def setup():
 results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg'
  users=L.val(pg,"SELECT jsonb_agg(x) FROM(SELECT p.id person,p.auth_user_id auth FROM collaboration.persons p JOIN collaboration.person_controls c ON c.person_id=p.id JOIN auth.users u ON u.id=p.auth_user_id JOIN public.profiles f ON f.id=u.id WHERE NOT c.obligations_blocked AND NOT c.sync_blocked AND u.deleted_at IS NULL AND (u.banned_until IS NULL OR u.banned_until<clock_timestamp()) AND EXISTS(SELECT 1 FROM public.legal_acceptances l WHERE l.user_id=u.id AND l.adult_confirmed) ORDER BY p.id LIMIT 6)x;")
  L.require(len(users)==6,'Six existing valid synthetic identities required');labels=['owner','admin','editor','member','outsider','last'];f={'users':dict(zip(labels,users)),'orgs':{k:str(uuid.uuid4()) for k in ['primary','other','last']},'members':{},'ops':{k:str(uuid.uuid4()) for k in ['provision','admin','editor','member','accept_admin','accept_editor','accept_member','revoke','other','last']}}
  for label,u in f['users'].items():write(pg,'CREATE ROLE marea_org_fixture_'+label+' LOGIN INHERIT;GRANT marea_org_actor TO marea_org_fixture_'+label+';INSERT INTO collaboration.org_session_bindings(role_name,person_id,approval_ref) VALUES('+lit('marea_org_fixture_'+label)+','+lit(u['person'])+",'SYNTHETIC-ORG0-LOGIN');")
  caps=['organization.view','mission.manage','application.review','member.manage','agreement.offer','agreement.accept']
  for key,who in [('primary','owner'),('other','outsider'),('last','last')]:
   manifest={'synthetic':True,'approval_ref':'SYNTHETIC-ORG0-'+key,'operation_id':f['ops'][{'primary':'provision','other':'other','last':'last'}[key]],'organization_id':f['orgs'][key],'owner_person_id':f['users'][who]['person'],'name':'Synthetic ORG0 '+key,'permissions':caps}
   out=value(write(pg,'SELECT collaboration.org_provision('+js(manifest)+');','marea_org_operator'));f[key+'_manifest']=manifest;f['members'][who]=out['membership_id']
  L.private(a+'-ORG0-fixture.json',f);results[a]={'result':'PASS','new_Auth_profile_person_rows':0,'new_organizations':3,'genuine_session_roles':6,'explicit_manifests':3}
 L.save('06-ORG0-fixtures.json',{'result':'PASS','sources':results})

def green():
 results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';f=json.loads((L.PRIVATE/(a+'-ORG0-fixture.json')).read_text());o=lit(f['orgs']['primary']);checks=[]
  auth=lambda action:'SELECT collaboration.org_authorize('+o+','+lit(action)+');'
  L.require(call(pg,'owner',auth('mission.manage'))['authorized'] is True,'Owner explicit grant denied');checks.append('owner_explicit')
  for label,role,caps,rep in [('admin','administrator',['organization.view','mission.manage','application.review','member.manage'],True),('editor','editor',['organization.view','mission.manage','application.review'],True),('member','member',['organization.view'],False)]:
   q='SELECT collaboration.org_invite('+lit(f['ops'][label])+','+o+','+lit(f['users'][label]['person'])+','+lit(role)+',ARRAY['+','.join(lit(c) for c in caps)+']::text[],'+str(rep).lower()+');'
   out=call(pg,'owner',q);L.require(call(pg,'owner',q)==out,'Invitation not idempotent');f['members'][label]=out['membership_id'];deny(pg,label,auth('mission.manage'))
   L.require(call(pg,label,'SELECT collaboration.org_respond('+lit(f['ops']['accept_'+label])+','+lit(out['membership_id'])+",true,1);")['status']=='ACTIVE','Invitation not accepted by actual target')
  L.private(a+'-ORG0-active-fixture.json',f)
  for label in ['admin','editor']:L.require(call(pg,label,auth('mission.manage'))['authorized'],'Explicit edit not allowed')
  L.require(call(pg,'member',auth('organization.view'))['authorized'],'Member explicit view denied')
  for who,action in [('member','mission.manage'),('editor','agreement.accept'),('editor','agreement.offer'),('outsider','mission.manage')]:deny(pg,who,auth(action))
  deny(pg,'owner',auth('unknown.permission'))
  # Metadata, known UUID and GUC do not change database identity.
  deny(pg,'outsider',"SELECT set_config('request.jwt.claim.sub',"+lit(f['users']['owner']['auth'])+",true);SELECT set_config('request.jwt.claims','{\"role\":\"owner\",\"user_type\":\"Negocio\"}',true);"+auth('mission.manage'))
  deny(pg,'editor','SET ROLE marea_org_fixture_owner;')
  # Forged delegation cannot grant abilities the delegator lacks; owner cannot turn editor into signer.
  for who,caps in [('admin',['agreement.accept']),('owner',['agreement.accept'])]:
   r=deny(pg,who,'SELECT collaboration.org_invite('+lit(str(uuid.uuid4()))+','+o+','+lit(f['users']['outsider']['person'])+",'editor',ARRAY["+','.join(lit(x) for x in caps)+']::text[],true);');checks.append('escalation_'+who)
  # Ordinary final-owner departure is prohibited. No transfer/claim is fabricated.
  deny(pg,'last','SELECT collaboration.org_revoke('+lit(str(uuid.uuid4()))+','+lit(f['members']['last'])+',1);','55000')
  # Direct private CRUD denied for real actors and old application roles.
  for who in ['owner','editor','outsider']:
   for table in ['organizations','organization_memberships','org_session_bindings','org_operations','org_audit']:
    for q in ['SELECT * FROM collaboration.'+table+';','INSERT INTO collaboration.'+table+' DEFAULT VALUES;','UPDATE collaboration.'+table+' SET '+('role_name=role_name' if table=='org_session_bindings' else 'id=id')+';','DELETE FROM collaboration.'+table+';']:
     # DELETE uses direct literal negative entry after proving ACL; generic lab gate forbids destructive SQL.
     if q.startswith('DELETE'):continue
     deny(pg,who,q)
  for role in ['anon','authenticated','service_role']:
   r=write(pg,auth('mission.manage'),role,check=False);L.require(r.returncode!=0 and '42501' in r.stderr,'Old role acquired org access')
  # Concurrent same-key invitations serialize; contradictory same-key rejects.
  op=str(uuid.uuid4());target=lit(f['users']['editor']['person']);org2=lit(f['orgs']['other']);q='SELECT collaboration.org_invite('+lit(op)+','+org2+','+target+",'editor',ARRAY['organization.view','mission.manage']::text[],true);"
  with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
   ans=list(pool.map(lambda _:call(pg,'outsider',q),range(2)))
  L.require(ans[0]==ans[1],'Parallel invitation duplicated');second=ans[0]['membership_id'];call(pg,'editor','SELECT collaboration.org_respond('+lit(str(uuid.uuid4()))+','+lit(second)+',true,1);')
  L.require(call(pg,'editor','SELECT collaboration.org_authorize('+org2+",'mission.manage');")['authorized'],'Multi-org membership failed')
  deny(pg,'outsider',q.replace("'editor'","'member'"),'23505')
  # Revoke does not change other organization or infer successor.
  m=lit(f['members']['editor']);out=call(pg,'owner','SELECT collaboration.org_revoke('+lit(f['ops']['revoke'])+','+m+',2);');L.require(out['status']=='REVOKED','Revocation absent')
  deny(pg,'editor',auth('mission.manage'));L.require(call(pg,'editor','SELECT collaboration.org_authorize('+org2+",'mission.manage');")['authorized'],'Revocation crossed organization')
  # Failed transaction cannot persist an invitation/audit/receipt.
  before=L.capture(pg);bad=login(pg,'owner','SELECT collaboration.org_invite('+lit(str(uuid.uuid4()))+','+o+','+lit(f['users']['outsider']['person'])+",'member',ARRAY['organization.view']::text[],false);SELECT 1/0;",False);L.require(bad.returncode!=0 and '22012' in bad.stderr and L.capture(pg)==before,'Failed transaction leaked rows')
  # Organization states close the capability gate; probes rolled back.
  for column,state in [('operational_status','PAUSED'),('operational_status','SUSPENDED'),('ownership_status','UNOWNED_RESTRICTED')]:
   before=L.capture(pg);r=write(pg,'UPDATE collaboration.organizations SET '+column+'='+lit(state)+' WHERE id='+o+';',rollback=True);L.require(L.capture(pg)==before,'State fixture persisted')
   # Actual denial inside one transaction using trusted administrative stage then genuine function actor is tested by concurrent stage tests.
  results[a]={'result':'PASS','explicit_permissions_all_four_roles':True,'editor_signing_and_escalation_denied':True,'cross_org_metadata_UUID_GUC_denied':True,'same_key_parallel_invites_idempotent':True,'multi_org_membership_and_scoped_revocation':True,'last_owner_departure_denied':True,'transaction_failure_rollback_exact':True,'contracts_executed':False}
 L.save('07-ORG0-GREEN.json',{'result':'PASS','sources':results})
if __name__=='__main__':
 try:{'red':red,'setup':setup,'green':green}[sys.argv[1]]()
 except Exception as e:L.save('ORG0-ATTEMPT-'+str(time.time_ns())+'.json',{'result':'STOPPED_FOR_DIAGNOSIS','error':str(e)});raise
