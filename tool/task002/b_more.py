"""Structural manifests, scoped cases, deterministic locks and S0 compatibility."""
import concurrent.futures,hashlib,json,time,uuid,sys
import b_lab as L
import s0_services as S
from b_cases import lit,write,valwrite,deny,request,progress,fixture,app_q

def wait_sleep(pg,label):
 for _ in range(60):
  if L.val(pg,'SELECT count(*) FROM pg_stat_activity WHERE application_name='+lit(label)+" AND wait_event='PgSleep';")==1:return
  time.sleep(.05)
 raise RuntimeError('Deterministic database barrier not reached')

def manifest_red():
 L.require(json.loads((L.RUN/'09-core-GREEN.json').read_text())['result']=='PASS','Complete core phase required before manifest')
 results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';f=fixture(a);r=json.loads((L.PRIVATE/(a+'-B-main-receipt.json')).read_text())['request_id'];before=L.capture(pg)
  q="BEGIN;SET LOCAL transaction_read_only=off;SET LOCAL ROLE marea_deletion_operator;SELECT collaboration.prepare_person_deletion_manifest("+lit(r)+",1,'SYNTHETIC-B1');RESET ROLE;SELECT count(*) FROM collaboration.deletion_manifest_items WHERE request_id="+lit(r)+" AND category='CANDIDATURE' AND resource_id="+lit(f['application_before'])+';ROLLBACK;'
  out=L.sql(pg,q,write=True);L.require(out.stdout.splitlines()[-1]=='0','Incoming candidature omission not RED');L.require(L.capture(pg)==before,'Manifest RED did not roll back');results[a]={'result':'EXPECTED_RED','incoming_candidature_missing_from_manifest':True,'rollback_exact':True}
 L.save('10-manifest-RED.json',{'result':'EXPECTED_RED','sources':results})

def concurrency():
 results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';f=fixture(a);u=f['users'];ops=f['ops']
  q="SET LOCAL application_name='b_request_race';SELECT collaboration.request_person_deletion("+lit(u['race'])+','+lit(ops['race'])+",1,'USER_REQUEST');SELECT pg_sleep(3);"
  with concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:
   held=pool.submit(write,pg,q,'marea_deletion_operator');wait_sleep(pg,'b_request_race');deny(pg,app_q(u['before'],f['missions']['race']),'55P03','service_role');done=held.result(timeout=10);L.require(done.returncode==0,'Held request failed')
  deny(pg,app_q(u['before'],f['missions']['race']),'55000','service_role');race=request(pg,u['race'],ops['race'])
  q="SET LOCAL application_name='b_application_first';"+app_q(u['before'],f['missions']['other'],f['application_other'])+'SELECT pg_sleep(3);'
  with concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:
   held=pool.submit(write,pg,q,'service_role');wait_sleep(pg,'b_application_first');deny(pg,'SELECT collaboration.request_person_deletion('+lit(u['other'])+','+lit(ops['other'])+",1,'USER_REQUEST');",'55P03');done=held.result(timeout=10);L.require(done.returncode==0,'Held candidature failed')
  other=request(pg,u['other'],ops['other']);L.require(other==request(pg,u['other'],ops['other']),'Bounded retry duplicated request')
  before=L.capture(pg);r=write(pg,'SELECT collaboration.request_person_deletion('+lit(u['before'])+','+lit(str(uuid.uuid4()))+",1,'USER_REQUEST');DO $$ BEGIN RAISE EXCEPTION 'SYNTHETIC_POST_REQUEST_FAILURE'; END $$;",'marea_deletion_operator',False);L.require(r.returncode!=0 and 'SYNTHETIC_POST_REQUEST_FAILURE' in r.stderr and L.capture(pg)==before,'Post-request failure was not atomic')
  results[a]={'result':'PASS','request_first_candidature_bounded_timeout_then_denied':True,'candidature_first_committed_then_request_bounded_retry':True,'new_request_ids':[race['request_id'],other['request_id']],'post_request_failure_all_tables_rollback_exact':True,'deadlocks':0,'timeouts_SQLSTATE':'55P03','successful_purge':False}
 L.save('12-concurrency.json',{'result':'PASS','sources':results})

def compatibility():
 from b_stages import require_receipts
 require_receipts('13-cases-manifests-GREEN.json')
 import s0_fence_v3 as F
 for name in ['S0-GUARD-MANIFEST-v3.json']:
  if not (L.RUN/name).exists():(L.RUN/name).write_bytes((L.SOURCE_RUN/name).read_bytes())
 results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';before=L.capture(pg);guards=F.assert_guards(a);copy=f'{L.OWNER}-{a}-control-v2-copy'
  raw=L.docker('exec',copy,'python','-c',"import os,sys;f=os.open('/dest/data/state.json',os.O_RDONLY|os.O_NOATIME);sys.stdout.buffer.write(os.read(f,1048576));os.close(f)",binary=True).stdout;state=json.loads(raw);L.require(state['guard_manifest_sha256']==L.sha(L.RUN/'S0-GUARD-MANIFEST-v3.json') and state['physical_readonly'] is True,'S0 state/source mismatch')
  S.storage_start(a,'storage-B-readonly',readonly=True);F.ingress_start(a,hashlib.sha256(raw).hexdigest(),'ingress-B')
  # Real API on the restored file backend, current valid service credential.
  obj=L.val(pg,"SELECT jsonb_build_object('bucket',bucket_id,'name',name) FROM storage.objects WHERE bucket_id='mission-images' ORDER BY name LIMIT 1;")
  tree=L.pax_snapshot(f'{L.OWNER}-{a}-storage-copy');read=S.request(a,5000,'/object/authenticated/'+obj['bucket']+'/'+obj['name'],token=S.jwt(a));L.require(read['status']==200,'Restored Storage read not real')
  denied=S.request(a,5000,'/object/'+obj['bucket'],'DELETE',data={'prefixes':[obj['name']]},token=S.jwt(a));L.require(denied['status']==500 and '55000' in denied['body'].get('message',''),'S0 API fence weakened')
  gate=S.request(a,9000,'/storage/v1/object/'+obj['bucket'],'DELETE',data={'prefixes':[obj['name']]},token=S.jwt(a));L.require(gate['status']==503,'S0 ingress reopened destructive route')
  L.require(L.capture(pg)==before and L.pax_snapshot(f'{L.OWNER}-{a}-storage-copy')==tree,'Compatibility probes changed data/bytes')
  results[a]={'result':'PASS','S0_guards_unchanged':len(guards['triggers']),'actual_API_read_HTTP':200,'actual_API_delete_HTTP':500,'ingress_delete_HTTP':503,'all_data_and_physical_fields_exact':True,'new_API_mount_readonly':True,'business_RPC_bodies_modified':False,'S0_ingress_not_a_B_client_API':True}
 L.save('14-S0-compatibility.json',{'result':'PASS','sources':results})

if __name__=='__main__':
 try:
  {'manifest-red':manifest_red,'concurrency':concurrency,'compatibility':compatibility}[sys.argv[1]]()
 except Exception as e:L.save('MORE-ATTEMPT-'+str(time.time_ns())+'.json',{'result':'STOPPED_FOR_DIAGNOSIS','error':str(e)});raise
