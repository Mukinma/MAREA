"""Final-review RED/GREEN with real legacy RPCs; every probe rolls back."""
import concurrent.futures,json,time,uuid,sys
import b_lab as L
from b_cases import fixture,lit,write,mission_q,app_q
from b_more import wait_sleep

def setup():
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';f=fixture(a);owner=L.val(pg,"SELECT to_jsonb(p.auth_user_id) FROM collaboration.persons p JOIN collaboration.person_controls c ON c.person_id=p.id JOIN auth.users u ON u.id=p.auth_user_id JOIN public.notification_preferences n ON n.user_id=u.id WHERE NOT c.obligations_blocked AND u.deleted_at IS NULL AND NOT EXISTS(SELECT 1 FROM public.account_deletion_requests d WHERE d.user_id=u.id) ORDER BY p.id LIMIT 1;");L.require(owner and owner!=f['users']['before'],'Distinct active real owner required')
  x={'owner':owner,'candidate':f['users']['before'],'mission':str(uuid.uuid4()),'application':str(uuid.uuid4())};L.private(a+'-B-review-fixture.json',x);write(pg,mission_q(owner,x['mission']),'service_role');write(pg,app_q(x['candidate'],x['mission'],x['application']),'service_role')
 L.save('18a-review-fixtures.json',{'result':'PASS','new_mission_and_application_per_copy':1,'new_Auth_users':0,'new_notification_preferences':0,'legacy_RPC_fixture_not_Agreement':True})

def run(phase):
 results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';f=fixture(a);x=json.loads((L.PRIVATE/(a+'-B-review-fixture.json')).read_text());baseline=L.capture(pg);cases=[]
  for column,value in [('applicant_id',f['users']['main']),('mission_id',f['missions']['main']),('id',str(uuid.uuid4()))]:
   q="BEGIN;SET LOCAL transaction_read_only=off;SET LOCAL ROLE service_role;WITH changed AS(UPDATE public.mission_applications SET "+column+'='+lit(value)+' WHERE id='+lit(x['application'])+' RETURNING id) SELECT count(*) FROM changed;ROLLBACK;'
   r=L.sql(pg,q,write=True,check=False);L.require(L.capture(pg)==baseline,'Identity probe changed persistent data')
   if phase=='RED':L.require(r.returncode==0 and r.stdout.strip()=='1','Identity bypass not reproduced')
   else:L.require(r.returncode!=0 and '55000' in r.stderr and 'CANDIDATURE_IDENTITY_REBINDING_REQUIRES_D' in r.stderr,'Identity rebind not fenced')
   cases.append({'column':column,'result':'EXPECTED_RED' if phase=='RED' else 'PASS','rollback_exact':True})
  label='b_review_'+phase.lower();candidate='b_withdraw_'+phase.lower()
  prefix="BEGIN;SET LOCAL transaction_read_only=off;SET LOCAL statement_timeout='10s';SET LOCAL deadlock_timeout='100ms';SET LOCAL application_name="
  reviewer=prefix+lit(label)+";SET LOCAL ROLE authenticated;SELECT set_config('request.jwt.claim.sub',"+lit(x['owner'])+",true);SELECT id FROM public.missions WHERE id="+lit(x['mission'])+" FOR UPDATE;SELECT pg_sleep(2);SELECT public.review_application("+lit(x['application'])+",'accepted');ROLLBACK;"
  withdraw=prefix+lit(candidate)+";SET LOCAL ROLE authenticated;SELECT set_config('request.jwt.claim.sub',"+lit(x['candidate'])+",true);SELECT public.withdraw_application("+lit(x['application'])+');ROLLBACK;'
  with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
   rev=pool.submit(L.sql,pg,reviewer,True,False);wait_sleep(pg,label);wd=pool.submit(L.sql,pg,withdraw,True,False);observed=False
   for _ in range(40):
    if L.val(pg,'SELECT count(*) FROM pg_stat_activity WHERE application_name='+lit(candidate)+" AND wait_event_type='Lock';")==1:observed=True;break
    time.sleep(.025)
   rr=rev.result(timeout=12);wr=wd.result(timeout=12)
  L.private(a+'-review-'+phase+'.json',{'review':{'exit':rr.returncode,'stderr':rr.stderr},'withdraw':{'exit':wr.returncode,'stderr':wr.stderr},'candidate_wait_on_mission_observed':observed});L.require(observed and L.capture(pg)==baseline,'Interleaving not controlled or rollback drift')
  if phase=='RED':L.require('40P01' in rr.stderr+wr.stderr,'Legacy lock inversion did not reproduce actual deadlock')
  else:L.require(rr.returncode!=0 and '55P03' in rr.stderr and '40P01' not in rr.stderr+wr.stderr and wr.returncode==0,'Lock fix did not reject safely/release legacy withdrawal')
  results[a]={'result':'EXPECTED_RED' if phase=='RED' else 'PASS','identity_cases':cases,'real_review_withdraw_RPC_interleaving':True,'candidate_wait_observed':True,'SQLSTATE':'40P01' if phase=='RED' else '55P03','withdraw_succeeds_then_rolls_back':wr.returncode==0,'full_rollback_exact':True,'legacy_acceptance_committed':False,'Agreement_validation_claimed':False}
 L.save('18b-review-RED.json' if phase=='RED' else '18c-review-GREEN.json',{'result':'EXPECTED_RED' if phase=='RED' else 'PASS','sources':results})
if __name__=='__main__':
 try:
  if sys.argv[1:]==['setup']:setup()
  else:run(sys.argv[1])
 except Exception as e:L.save('REVIEW-ATTEMPT-'+str(time.time_ns())+'.json',{'result':'STOPPED_FOR_DIAGNOSIS','error':str(e)});raise
