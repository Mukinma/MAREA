"""Quiescent full backup/restore, then real Storage rejection on recovered volumes."""
import hashlib,json,subprocess,time
from pathlib import Path
import s0_lab_v2 as L
import s0_services as S
import s0_fence_v3 as F
from s0_cases import private_fixture,PNG
from pax_transport import archive_manifest,compare

def pax_backup(copy,label,destination):
 before=L.pax_snapshot(copy);archive=L.PRIVATE/(label+'.tar');code=(L.ROOT/'tool/task002/pax_transport.py').read_text()+"\nimport sys;export_archive('/dest/data',sys.stdout.buffer)\n"
 with (L.PRIVATE/'docker-commands.jsonl').open('a') as log:log.write(json.dumps(['exec',copy,'python','-c',code])+'\n')
 with archive.open('xb') as f:r=subprocess.run(['docker','--host',L.ENDPOINT,'exec',copy,'python','-c',code],stdout=f,stderr=subprocess.PIPE,env=L.ENV,timeout=120)
 L.require(r.returncode==0,'Final PAX export failed: '+r.stderr.decode()[:120]);compare(before,L.pax_snapshot(copy))
 with archive.open('rb') as f:compare(before,archive_manifest(f))
 manifest=L.PRIVATE/(label+'.manifest.json');manifest.write_text(json.dumps(before,sort_keys=True))
 restored=L.restore_pax(archive,before,destination,'0:0')
 return {'archive_sha256':L.sha(archive),'manifest_sha256':L.sha(manifest),'restored_volume':destination,'restored_copy':restored,'all_bytes_attributes_and_ns_equal':True,'entries':len(before)}

def stop_services():
 result=[]
 for cid in L.dtext('ps','-q','--filter','label='+L.LABEL+'='+L.OWNER).split():
  c=L.inspect(cid)
  if c['Image'] in [L.AUTH,L.STORAGE,L.POSTGREST,L.DENO]:
   L.owned(c['Name'].lstrip('/'));L.docker('stop','--time','3',cid);L.require(not L.inspect(cid)['State']['Running'],'Service not quiescent');result.append(c['Name'])
 return result

def run():
 L.require(json.loads((L.RUN/'25-data-conservation-v3.json').read_text())['result']=='PASS','Conservation required before recovery')
 stopped=stop_services();results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';expected=json.loads((L.PRIVATE/(a+'-S0-v3-conservation-verified.json')).read_text());L.require(L.capture(pg)==expected,'Quiescent final state changed')
  db=L.cold_backup(a,'S0-v3-final-verified');storage=pax_backup(f'{L.OWNER}-{a}-storage-copy',a+'-S0-v3-final-storage',f'{L.OWNER}-v3-recovery-{a}-storage');control=pax_backup(F.state_copy(a),a+'-S0-v3-final-control',f'{L.OWNER}-v3-recovery-{a}-control-v2')
  dataset='v3-recovery-'+a;recovery=L.boot(dataset,volume_name=db['tree_verified_on_new_volume']);L.runtime_net(dataset,{5432});L.require(L.capture(recovery)==expected,'Second restored PG boot drift')
  # State read with O_NOATIME; never change a restored timestamp to inspect it.
  code="import os,sys;f=os.open('/dest/data/state.json',os.O_RDONLY|os.O_NOATIME);sys.stdout.buffer.write(os.read(f,1048576));os.close(f)"
  raw=L.docker('exec',control['restored_copy'],'python','-c',code,binary=True).stdout;state=json.loads(raw);expected_state=json.loads((L.PRIVATE/(a+'-ACTIVE-state-v3.json')).read_text());L.require(state==expected_state and state['guard_manifest_sha256']==L.sha(F.MANIFEST),'Recovery coordination state mismatch')
  from s0_space_fix import probe
  for table in ['tours','tour_revisions']:
   denial=probe(dataset,table);L.require(denial.returncode!=0 and '55000' in denial.stderr and 'S0_DESTRUCTIVE_TRANSITION_FENCED' in denial.stderr,'Restored space reference guard failed')
  L.require(L.capture(recovery)==expected,'Restored space probes drift')
  guards=F.assert_guards(dataset);original_guards=json.loads((L.PRIVATE/(a+'-T49-v2-after.json')).read_text())['activation']['guards'];L.require(guards['function']==original_guards['function'],'Restored guard function changed')
  S.storage_start(dataset,'restored-fenced-storage',readonly=True);F.ingress_start(dataset,hashlib.sha256(raw).hexdigest(),'restored-ingress')
  f=private_fixture(a);valid=S.jwt(dataset)
  read=S.request(dataset,5000,'/object/authenticated/mission-images/'+f['path'],token=valid);L.require(read['status']==200 and read['sha256']==hashlib.sha256(PNG).hexdigest(),'Restored physical read failed')
  denied=S.request(dataset,5000,'/object/mission-images','DELETE',data={'prefixes':[f['path']]},token=valid);L.require(denied['status']==500 and denied['body'].get('code')=='DatabaseError' and '55000' in denied['body'].get('message',''),'Restored API not protected by actual S0 guard')
  blocked=S.request(dataset,9000,'/storage/v1/object/mission-images','DELETE',data={'prefixes':[f['path']]},token=valid);L.require(blocked['status']==503,'Restored ingress reopened destructive route')
  unconfirmed=S.request(dataset,9000,'/functions/v1/delete-account','POST',data={},token=S.jwt(dataset,'authenticated',f['user'],f['session']));L.require(unconfirmed['status']==503 and unconfirmed['body'].get('request_recorded') is not True and unconfirmed['body'].get('completed') is False,'Missing recovered Auth/REST claimed a successful request or purge')
  L.require(L.capture(recovery)==expected,'Recovery probes changed data/catalog/sequences')
  for artifact in [storage,control]:
   expected_tree=json.loads((L.PRIVATE/(a+('-S0-v3-final-storage.manifest.json' if artifact is storage else '-S0-v3-final-control.manifest.json'))).read_text());compare(expected_tree,L.pax_snapshot(artifact['restored_copy']))
  L.private(a+'-recovery-probes-v3.json',{'read':read,'Storage_delete':denied,'ingress_delete':blocked,'missing_dependencies':unconfirmed})
  results[a]={'result':'PASS','DB':db,'Storage':storage,'coordination':control,'restored_guard_count':len(guards['triggers']),'restored_API_read_HTTP':200,'restored_API_delete_HTTP':500,'SQLSTATE':'55000','restored_ingress_delete_HTTP':503,'missing_recovered_dependencies_fail_closed':True,'final_logical_and_physical_snapshots_equal':True}
  for suffix in ['restored-ingress','restored-fenced-storage','pg']:
   name=f'{L.OWNER}-{dataset}-{suffix}';L.owned(name);L.docker('stop','--time','3',name)
 L.save('26-final-recovery-v3.json',{'result':'PASS','services_quiesced_before_backup':stopped,'sources':results,'remote_exposure':False,'product_activation_authorized':False})
 # Helpers sleep, so stop them with a bounded one-second grace after all data is safe.
 closed=[]
 for cid in L.dtext('ps','-aq','--filter','label='+L.LABEL+'='+L.OWNER).split():
  c=L.inspect(cid);L.owned(c['Name'].lstrip('/'))
  if c['State']['Running']:L.docker('stop','--time','1' if c['Image']==L.HELPER else '10',cid)
  L.require(not L.inspect(cid)['State']['Running'],'Container remained active');closed.append(c['Name'])
 L.save('99-stopped-v3.json',{'result':'PASS','containers':closed,'S0_execution_stopped':True,'next_increment_started':False})
if __name__=='__main__':
 try:run()
 except Exception as e:L.save('RECOVERY-FAIL-'+str(time.time_ns())+'.json',{'result':'BLOCKED','error':str(e)});L.stop();raise
