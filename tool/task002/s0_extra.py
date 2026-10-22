"""Negative, concurrent, retry and crash tests against the running S0 laboratory."""
import base64,concurrent.futures,hashlib,json,time,uuid
import s0_lab_v2 as L
import s0_services as S
import s0_fence as F
from s0_cases import refs,private_fixture,write,lit,PNG

def intact(a,baseline):
 L.require(refs(a)==baseline['refs'],'Protected references/metadata unexpectedly changed')
 L.require(L.pax_snapshot(f'{L.OWNER}-{a}-storage-copy')==baseline['tree'],'Protected physical tree unexpectedly changed')

def marker(pg,user):return L.val(pg,'SELECT count(*) FROM public.account_deletion_requests WHERE user_id='+lit(user)+';')

def lost_response(a,token):
 L.runtime_net(a,S.PORTS)
 code="""import json,socket,sys,time
x=json.load(sys.stdin);s=socket.create_connection(('127.0.0.1',9000),timeout=10)
s.sendall(('POST /functions/v1/delete-account HTTP/1.1\\r\\nHost: 127.0.0.1\\r\\nAuthorization: Bearer '+x['token']+'\\r\\nContent-Length: 0\\r\\nConnection: close\\r\\n\\r\\n').encode());time.sleep(5);s.close();print(json.dumps({'sent':True,'response_bytes_read':0}))
"""
 r=L.docker('run','--rm','-i','--pull','never','--label',L.LABEL+'='+L.OWNER,'--network','container:'+L.OWNER+'-'+a+'-pg','--read-only','--user','1000:1000','--cap-drop','ALL','--security-opt','no-new-privileges','--entrypoint','python',L.HELPER,'-c',code,input=json.dumps({'token':token}));return json.loads(r.stdout)

def run():
 L.require(json.loads((L.RUN/'10-T49-GREEN.json').read_text())['result']=='PASS','T49 required')
 L.require(json.loads((L.RUN/'14-CORS-GREEN.json').read_text())['result']=='PASS','Correct browser preflight required')
 results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';f=private_fixture(a);baseline=json.loads((L.PRIVATE/(a+'-T49-v2-before.json')).read_text());start=L.capture(pg);cases=[]
  def passed(name,**detail):cases.append({'case':name,'result':'PASS',**detail})
  def denied(name,port,path,method='DELETE',data=None,body=None,headers=None,token=None):
   r=S.request(a,port,path,method,data,body,S.jwt(a) if token is None else token,headers);L.private(a+'-extra-'+name+'.json',r);L.require(r['status']>=400,'Expected explicit API denial '+name+': '+str(r))
   if port==5000:
    detail=json.dumps(r.get('body',{}));L.require(r['status'] not in [401,404,405,422] and 'must have required property' not in detail and 'must NOT have' not in detail,'Unexercised/invalid Storage route '+name+': '+detail)
   intact(a,baseline);passed(name,HTTP=r['status'],API_error=r.get('body',{}).get('code') if isinstance(r.get('body'),dict) else None);return r
  # Real backend APIs, using a currently valid service-role credential, independent of ingress.
  for name,path,data,method in [('single','/object/mission-images/'+f['path'],None,'DELETE'),('bulk','/object/mission-images',{'prefixes':[f['path']]},'DELETE'),('empty_bucket','/bucket/mission-images/empty',{},'POST'),('delete_bucket','/bucket/mission-images',None,'DELETE'),('copy','/object/copy',{'bucketId':'mission-images','sourceKey':f['path'],'destinationKey':f['user']+'/'+str(uuid.uuid4())+'.png'},'POST'),('move','/object/move',{'bucketId':'mission-images','sourceKey':f['path'],'destinationKey':f['user']+'/'+str(uuid.uuid4())+'.png'},'POST')]:denied(name,5000,path,method,data)
  denied('overwrite',5000,'/object/mission-images/'+f['path'],'POST',body=PNG,headers={'Content-Type':'image/png','x-upsert':'true'})
  # Relevant original buckets: each test selects an actual existing object, never a missing path.
  objects=L.val(pg,"SELECT jsonb_agg(to_jsonb(x)) FROM (SELECT DISTINCT ON(bucket_id) bucket_id,name FROM storage.objects ORDER BY bucket_id,name)x;")
  for i,obj in enumerate(objects):denied('existing_bucket_'+str(i),5000,'/object/'+obj['bucket_id'],'DELETE',{'prefixes':[obj['name']]})
  # Direct ordinary privileged SQL cannot bypass the constant trigger with user GUCs.
  for role in ['service_role','supabase_storage_admin']:
   r=write(pg,'SET LOCAL ROLE '+role+";SET LOCAL marea.s0.bypass='true';DELETE FROM storage.objects WHERE bucket_id='mission-images' AND name="+lit(f['path'])+';',False)
   L.require(r.returncode!=0 and '55000' in r.stderr and 'S0_DESTRUCTIVE_TRANSITION_FENCED' in r.stderr,'Privileged SQL did not reach/deny constant guard');intact(a,baseline);passed('SQL_'+role,SQLSTATE='55000')
  r=write(pg,"SET LOCAL ROLE service_role;SET LOCAL session_replication_role='replica';",False);L.require(r.returncode!=0 and '42501' in r.stderr,'service_role can disable triggers');passed('no_replication_role_bypass',SQLSTATE='42501')
  # Auth admin is genuinely authorized to read this fixture, but cannot purge it.
  admin=S.request(a,9999,'/admin/users/'+f['user'],token=S.jwt(a));L.require(admin['status']==200 and admin['body']['id']==f['user'],'Admin credential not valid')
  denied('Auth_admin_delete',9999,'/admin/users/'+f['user'],'DELETE',{'should_soft_delete':False})
  denied('profile_direct_delete',3000,'/profiles?id=eq.'+f['user'],'DELETE')
  # Independent physical backstop, same uid/caps as the real API, no metadata SQL substitute.
  api=f'{L.OWNER}-{a}-storage-fenced-v2';c=L.owned(api);L.require([m['RW'] for m in c['Mounts'] if m['Destination']=='/files']==[False],'Read-only mount precondition missing')
  target=next(x for x in baseline['tree'] if '/'+f['path']+'/' in x['path'] and x['kind']=='file' and x['sha256']==hashlib.sha256(PNG).hexdigest())
  code="const fs=require('node:fs');try{fs.unlinkSync(process.argv[1]);console.log(JSON.stringify({deleted:true}));process.exitCode=2;}catch(e){console.log(JSON.stringify({deleted:false,code:e.code}));}"
  r=L.docker('exec',api,'node','-e',code,'/files/'+target['path']);physical=json.loads(r.stdout);L.require(physical=={'deleted':False,'code':'EROFS'},'Physical read-only backstop failed');intact(a,baseline);passed('physical_root_uid_backstop',errno='EROFS')
  # New legacy producers and every mutating storage protocol enter the same maintenance gate.
  for name in ['story-cleanup','profile-media','tour-dispatch']:
   denied('producer_'+name,9000,'/functions/v1/'+name,'POST',{})
  for name,method,path in [('REST','DELETE','/storage/v1/object/mission-images'),('TUS','POST','/storage/v1/upload/resumable'),('S3','DELETE','/storage/v1/s3/mission-images/'+f['path'])]:denied('ingress_'+name,9000,path,method,{'prefixes':[f['path']]})
  actor=lambda:S.jwt(a,'authenticated',f['user'],f['session'])
  credential=S.request(a,9999,'/user',token=actor());L.require(credential['status']==200 and credential['body']['id']==f['user'],'Actor credential invalid')
  # Unknown/inconsistent coordination never unlocks the API nor creates a request marker.
  saved=F.state_bytes(a);state=json.loads(saved)
  for label,value in [('unknown',{'schema_version':1,'status':'UNKNOWN'}),('inconsistent',{**state,'physical_readonly':False}),('preparing',{**state,'status':'PREPARING'})]:
   F.put_state(a,value);denied('state_'+label,9000,'/functions/v1/delete-account','POST',{},token=actor());L.require(marker(pg,f['user'])==0,'Unknown state admitted request')
  F.put_state(a,state);L.require(F.state_bytes(a)==saved,'Coordination state not exactly restored');first=F.reconcile_active(a);L.require(F.reconcile_active(a)==first,'Activation reconciliation not idempotent');passed('activation_reconciliation',epoch=first['epoch'])
  # Real failure before an external Auth response: no marker or false success.
  auth=f'{L.OWNER}-{a}-auth-v5';L.docker('stop','--time','3',auth);r=denied('Auth_unavailable',9000,'/functions/v1/delete-account','POST',{},token=actor());L.require(r['body'].get('request_recorded') is not True and marker(pg,f['user'])==0,'Unconfirmed external request claimed receipt');L.docker('start',auth)
  for _ in range(30):
   if S.request(a,9999,'/health')['status']==200:break
   time.sleep(.1)
  else:raise RuntimeError('Auth did not recover')
  # Commit precedes client discard: the client deliberately never reads a response.
  with concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:
   pending=pool.submit(lost_response,a,actor());seen=False
   for _ in range(40):
    if marker(pg,f['user'])==1:seen=not pending.done();break
    time.sleep(.05)
   result=pending.result()
  L.require(seen and result['response_bytes_read']==0,'Lost response was not observed after durable commit')
  request_before=L.val(pg,'SELECT to_jsonb(r) FROM public.account_deletion_requests r WHERE user_id='+lit(f['user'])+';')
  def duplicate():return S.request(a,9000,'/functions/v1/delete-account','POST',data={'owner_id':str(uuid.uuid4()),'completed':True},token=actor())
  with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:responses=[fut.result() for fut in [pool.submit(duplicate),pool.submit(duplicate)]]
  responses.append(duplicate());L.private(a+'-duplicate-request-responses.json',responses)
  L.require(all(r['status']==503 and r['body'].get('request_recorded') is True and r['body'].get('completed') is False for r in responses),'Legacy client received false purge or missing receipt')
  request_after=L.val(pg,'SELECT to_jsonb(r) FROM public.account_deletion_requests r WHERE user_id='+lit(f['user'])+';');L.require(request_before==request_after and marker(pg,f['user'])==1,'Duplicate request mutated/duplicated marker')
  passed('lost_response_and_concurrent_retries',concurrent=2,sequential_retry=1,markers=1,response_bytes_read=0,all_POST_HTTP=503,completed=False)
  # Worker/API and ingress restart with persistent epoch; a valid credential remains denied.
  valid_service=S.jwt(a,ttl=600);read=S.request(a,5000,'/object/authenticated/mission-images/'+f['path'],token=valid_service);L.require(read['status']==200 and read['sha256']==hashlib.sha256(PNG).hexdigest(),'Read path broken')
  L.docker('stop','--time','3',api);S.storage_start(a,'storage-fenced-restarted',readonly=True)
  L.docker('stop','--time','3',f'{L.OWNER}-{a}-ingress-cors');F.ingress_start(a,first['digest'],'ingress-restarted')
  denied('late_valid_credential_after_restart',5000,'/object/mission-images','DELETE',{'prefixes':[f['path']]},token=valid_service)
  L.require(F.reconcile_active(a)==first,'Restart changed fence epoch/state');read=S.request(a,9000,'/storage/v1/object/authenticated/mission-images/'+f['path'],token=valid_service);L.require(read['status']==200 and read['sha256']==hashlib.sha256(PNG).hexdigest(),'Read proxy broken after restart');passed('read_available_after_restart',HTTP=200,sha256=read['sha256'])
  intact(a,baseline);final=L.capture(pg)
  for table,hashes in start['row_hashes'].items():
   if table=='public.account_deletion_requests':
    import collections
    L.require(not collections.Counter(hashes)-collections.Counter(final['row_hashes'][table]) and len(final['row_hashes'][table])==len(hashes)+1,'Request delta incorrect')
   else:L.require(hashes==final['row_hashes'][table],'Unexpected row mutation: '+table)
  L.require(start['sequences']==final['sequences'] and start['catalog']==final['catalog'] and start['extra']==final['extra'],'Schema/ACL/sequence drift in extra tests')
  L.private(a+'-S0-extra-final.json',final);results[a]={'result':'PASS','cases':cases,'case_count':len(cases),'new_request_markers':1,'all_other_rows_catalog_sequences_unchanged':True,'physical_tree_exactly_equal':True,'Auth_profiles_deleted':0}
 L.save('15-additional-tests.json',{'result':'PASS','sources':results,'account_lifecycle_complete':False})
if __name__=='__main__':
 try:run()
 except Exception as e:
  L.save('EXTRA-FAIL-'+str(time.time_ns())+'.json',{'result':'BLOCKED','error':str(e),'do_not_ignore_real_data_loss':True});L.stop();raise
