"""T49 with a real Storage transaction suspended immediately before file backend deletion."""
import concurrent.futures,hashlib,json,time
import s0_lab as L
import s0_services as S
import s0_fence as F
from s0_cases import refs,private_fixture

def run(sql_path):
 L.require(json.loads((L.RUN/'06-T49-RED.json').read_text())['result']=='EXPECTED_RED','Real RED required')
 sources={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';f=private_fixture(a)
  protected={'refs':refs(a),'tree':L.pax_snapshot(f'{L.OWNER}-{a}-storage-copy'),'db':L.capture(pg)}
  L.private(a+'-T49-before.json',protected)
  L.docker('stop','--time','5',f'{L.OWNER}-{a}-storage-v4')
  hook="""const fs=require('node:fs');const {FileBackend}=require('/app/dist/storage/backend/file.js');
for(const method of ['deleteObject','deleteObjects']){const old=FileBackend.prototype[method];FileBackend.prototype[method]=async function(...args){if(JSON.stringify(args).includes(TARGET)){fs.writeFileSync('/tmp/hit',JSON.stringify({method,args}));while(!fs.existsSync('/tmp/release'))await new Promise(r=>setTimeout(r,20));}return await old.apply(this,args);};}
""".replace('TARGET',json.dumps(f['path']))
  held=S.storage_start(a,'storage-held',hook=hook);L.private(a+'-test-hook.json',{'sha256':hashlib.sha256(hook.encode()).hexdigest(),'source':hook,'installed_file_backend_sha256':L.sha(L.PRIVATE/'storage-dist/storage/backend/file.js')})
  with concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:
   future=pool.submit(S.request,a,5000,'/object/mission-images','DELETE',{'prefixes':[f['path']]},None,S.jwt(a))
   for _ in range(100):
    if L.docker('exec',held,'test','-f','/tmp/hit',check=False).returncode==0:break
    if future.done():raise RuntimeError('Cleanup returned before reaching actual physical frontier: '+str(future.result()))
    time.sleep(.05)
   else:raise RuntimeError('Actual FileBackend frontier not observed')
   hit=json.loads(L.dtext('exec',held,'cat','/tmp/hit'));L.private(a+'-T49-frontier.json',hit)
   L.require(refs(a)==protected['refs'],'Uncommitted metadata unexpectedly visible before cut')
   activation=F.activate(a,held,sql_path,protected);inflight=future.result(timeout=15)
  L.require(inflight['status']==0,'Old API unexpectedly completed instead of being invalidated')
  F.ingress_start(a,activation['digest'])
  retry=S.request(a,5000,'/object/mission-images','DELETE',data={'prefixes':[f['path']]},token=S.jwt(a))
  L.require(retry['status']>=400,'Late privileged retry not explicitly denied')
  L.require(refs(a)==protected['refs'],'Protected references/object metadata changed after retry')
  L.require(L.pax_snapshot(f'{L.OWNER}-{a}-storage-copy')==protected['tree'],'Protected physical tree changed after cut')
  current=L.capture(pg);L.require(current['row_hashes']==protected['db']['row_hashes'] and current['sequences']==protected['db']['sequences'],'T49 changed data/sequences')
  L.private(a+'-T49-after.json',{'snapshot':current,'refs':refs(a),'tree':L.pax_snapshot(f'{L.OWNER}-{a}-storage-copy'),'activation':activation,'old_request_result':inflight,'late_retry':retry})
  sources[a]={'result':'PASS','case':'E2-T49','frontier':hit['method'],'old_API_PID':activation['old_api_pid'],'old_API_exit':activation['old_api_exit_code'],'old_DB_sessions':activation['old_Storage_DB_sessions'],'old_request_HTTP':inflight['status'],'late_privileged_retry_HTTP':retry['status'],'shared_resource_count':2,'physical_bytes_hashes_modes_owners_mtime_atime_ns_equal':True,'references_and_storage_metadata_equal':True,'all_rows_sequences_equal':True,'active_epoch':activation['state']['epoch'],'state_digest':activation['digest'],'guard_count':len(activation['guards']['triggers']),'mount_readonly':True,'DDL_rollback_exact':True,'no_Auth_deletion':True}
 L.save('10-T49-GREEN.json',{'result':'PASS','sources':sources,'scope':'S0 local quiescent cut only; no account deletion lifecycle'})
if __name__=='__main__':
 import sys
 try:run(sys.argv[1])
 except Exception as e:
  L.save('GREEN-FAIL-'+str(time.time_ns())+'.json',{'result':'BLOCKED','error':str(e),'historical_results_preserved':True});L.stop();raise
