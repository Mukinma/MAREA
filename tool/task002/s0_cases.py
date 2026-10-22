"""Real HTTP and physical oracle for S0; no account purges or SQL object deletion."""
import base64,collections,concurrent.futures,hashlib,json,time,uuid
import s0_lab_v2 as L
import s0_services as S
PNG=base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aX1sAAAAASUVORK5CYII=')
def lit(x):return "'"+str(x).replace("'","''")+"'"
def write(pg,q,check=True):return L.sql(pg,"BEGIN;SET LOCAL transaction_read_only=off;SET LOCAL lock_timeout='2s';SET LOCAL statement_timeout='15s';"+q+'COMMIT;',write=True,check=check)
def private_fixture(a):return json.loads((L.PRIVATE/(a+'-fixture.json')).read_text())
def refs(a):
 f=private_fixture(a);pg=f'{L.OWNER}-{a}-pg';return L.val(pg,"SELECT jsonb_build_object('missions',(SELECT jsonb_agg(to_jsonb(m) ORDER BY id) FROM public.missions m WHERE id=ANY(ARRAY["+','.join(lit(i) for i in f['missions'])+"]::uuid[])),'object',(SELECT to_jsonb(o) FROM storage.objects o WHERE bucket_id='mission-images' AND name="+lit(f['path'])+"));")
def upload(a,path):
 r=S.request(a,5000,'/object/mission-images/'+path,'POST',body=PNG,token=S.jwt(a),headers={'Content-Type':'image/png','x-upsert':'false'});L.require(r['status'] in [200,201],'Fixture upload failed: '+str(r));return r

def red():
 L.require(not any((L.PRIVATE/(a+'-fixture.json')).exists() for a in ['a','b']),'RED partly executed; use phase-aware continuation, never replay signups')
 L.require(json.loads((L.RUN/'08-incident-recovery.json').read_text())['result']=='PASS','Incident recovery proof required before retry')
 results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';initial=L.capture(pg);S.auth_start(a,'auth-v3');L.require(L.capture(pg)==initial,'Auth startup drift');S.rest_start(a,'rest-v3');L.require(L.capture(pg)==initial,'REST startup drift')
  policy=L.val(pg,'SELECT public.registration_policy();');label='s0_'+a+'_'+uuid.uuid4().hex[:6]
  body={'email':label+'@s0.invalid','password':L.secrets.token_urlsafe(24),'data':{'full_name':'Synthetic S0 '+a,'username':label,'registration_flow':'minimal-v1','user_type':'Artista / creador','adult_confirmed':True,'accepted_terms':True,'terms_version':policy['terms']['version'],'privacy_version':policy['privacy']['version']}}
  response=S.request(a,9999,'/signup','POST',data=body);L.require(response['status']==200,'Auth fixture signup failed')
  L.private(a+'-signup-retry-confirmed.json',{'request':body,'response':response})
  user=response['body']['user']['id'];token=response['body']['access_token'];claims=json.loads(base64.urlsafe_b64decode(token.split('.')[1]+'==='));path=user+'/'+str(uuid.uuid4())+'.png';upload(a,path)
  missions=[str(uuid.uuid4()),str(uuid.uuid4())]
  for i,mid in enumerate(missions):
   q="INSERT INTO public.missions SELECT (jsonb_populate_record(NULL::public.missions,to_jsonb(m)||jsonb_build_object('id',"+lit(mid)+",'author_id',"+lit(user)+",'title','Synthetic S0 protected "+str(i)+"','image_path',"+lit(path)+",'starts_at',clock_timestamp()+interval '20 days','created_at',clock_timestamp(),'status','open','hidden',false,'conditions_locked_at',NULL,'cancellation_reason',NULL,'lifecycle_event_version',1))).* FROM public.missions m WHERE m.status='open' LIMIT 1;"
   write(pg,q)
  L.private(a+'-fixture.json',{'user':user,'session':claims['session_id'],'path':path,'missions':missions,'signup_request':body})
  before=refs(a);L.require(len(before['missions'])==2 and before['object'] is not None,'Protected fixture missing');tree=L.pax_snapshot(f'{L.OWNER}-{a}-storage-copy');L.private(a+'-red-before.json',{'refs':before,'tree':tree,'db':L.capture(pg)})
  listed=S.request(a,5000,'/object/list/mission-images','POST',data={'prefix':user,'limit':100,'offset':0},token=S.jwt(a));L.require(listed['status']==200 and any(x['name']==path.split('/')[1] for x in listed['body']),'Legacy prefix did not select protected image')
  removed=S.request(a,5000,'/object/mission-images','DELETE',data={'prefixes':[path]},token=S.jwt(a));after=refs(a);tree_after=L.pax_snapshot(f'{L.OWNER}-{a}-storage-copy');L.private(a+'-red-after.json',{'refs':after,'tree':tree_after,'http':removed})
  was=[x for x in tree if '/'+path+'/' in x['path'] and x['kind']=='file'];now=[x for x in tree_after if '/'+path+'/' in x['path'] and x['kind']=='file']
  L.require(removed['status']==200 and was and not now and after['object'] is None and after['missions']==before['missions'],'RED did not reproduce real dangerous deletion')
  # Compensate only the newly inserted RED fixture through Storage API. New object
  # ID/version are recorded, never normalized to pretend exact historic recovery.
  upload(a,path);repaired=refs(a);L.require(repaired['object'] is not None and repaired['missions']==before['missions'],'RED fixture compensation failed')
  L.private(a+'-green-baseline.json',{'refs':repaired,'tree':L.pax_snapshot(f'{L.OWNER}-{a}-storage-copy'),'db':L.capture(pg)})
  results[a]={'result':'EXPECTED_RED','HTTP_remove':removed['status'],'real_bytes_deleted':True,'references_survived':2,'Auth_delete_performed':False,'fixture_only':True,'compensating_API_upload':True,'original_object_id':before['object']['id'],'compensated_object_id':repaired['object']['id'],'object_identity_change_explicit':True}
 L.save('06-T49-RED.json',{'result':'EXPECTED_RED','sources':results,'S0_implemented':False})
if __name__=='__main__':
 import sys
 try:
  if sys.argv[1:]==['red']:red()
  else:raise SystemExit('red')
 except Exception as e:
  L.save('CASE-FAIL-'+str(time.time_ns())+'.json',{'result':'STOPPED','error':str(e)});L.stop();raise
