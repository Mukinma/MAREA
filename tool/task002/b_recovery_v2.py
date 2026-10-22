"""B final cold recovery in new volumes with genuine restored control probes."""
import json,time
import b_lab as L
from b_cases import fixture,lit,valwrite,deny
from b_case_sessions import login_sql
from s0_recovery import pax_backup,stop_services
def run():
 L.require(json.loads((L.RUN/'15-conservation-v2.json').read_text())['result']=='PASS','Conservation before backup required');stopped=stop_services();results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';expected=json.loads((L.PRIVATE/(a+'-B-v2-final-verified.json')).read_text());L.require(L.capture(pg)==expected,'Quiescent B snapshot changed')
  db=L.cold_backup(a,'B-v2-final-verified');storage=pax_backup(f'{L.OWNER}-{a}-storage-copy',a+'-B-final-storage',f'{L.OWNER}-recovery-{a}-storage');control=pax_backup(f'{L.OWNER}-{a}-control-v2-copy',a+'-B-final-control',f'{L.OWNER}-recovery-{a}-control-v2')
  dataset='recovery-'+a;rec=L.boot(dataset,volume_name=db['tree_verified_on_new_volume']);L.runtime_net(dataset,{5432});L.require(L.capture(rec)==expected,'Recovered B logical state drift')
  f=fixture(a);rid=json.loads((L.PRIVATE/(a+'-B-main-receipt.json')).read_text())['request_id'];p=valwrite(rec,'SELECT collaboration.person_deletion_progress('+lit(f['users']['main'])+','+lit(rid)+');');L.require(p['consistent'] and p['completed'] is False and p['purge_ready'] is False,'Recovered B controls inconsistent')
  deny(rec,'SELECT collaboration.assert_person_purge_ready('+lit(rid)+');','55000');deny(rec,'UPDATE collaboration.person_controls SET obligations_blocked=false,control_version=control_version+1 WHERE person_id=(SELECT id FROM collaboration.persons WHERE auth_user_id='+lit(f['users']['main'])+');','55000',None)
  case=json.loads((L.PRIVATE/(a+'-B-case-fixture-v2.json')).read_text())['ids']['expired'];r=login_sql(rec,'SELECT collaboration.deletion_case_progress('+lit(case)+",'DELETION_REVIEW');",check=False);L.require(r.returncode!=0 and '42501' in r.stderr,'Recovered case expiry not enforced by real identity')
  L.require(L.capture(rec)==expected,'Recovery control probes mutated any data')
  from pax_transport import compare
  for kind,artifact in [('storage',storage),('control',control)]:compare(json.loads((L.PRIVATE/(a+'-B-final-'+kind+'.manifest.json')).read_text()),L.pax_snapshot(artifact['restored_copy']))
  L.docker('stop','--time','10',rec);results[a]={'result':'PASS','DB':db,'Storage':storage,'coordination':control,'B_progress_consistent_not_completed':True,'purge_unblock_and_expired_case_denied':True,'case_probe_authenticated_actual_fixture_login':True,'DB_logical_snapshot_and_physical_trees_exact':True,'successful_Auth_profile_media_purges':0}
 L.save('16-final-recovery.json',{'result':'PASS','sources':results,'quiesced_services':stopped,'not_an_E2_R_or_remote_readiness_claim':True})
 closed=[]
 for cid in L.dtext('ps','-aq','--filter','label='+L.LABEL+'='+L.OWNER).split():
  c=L.owned(L.inspect(cid)['Name'].lstrip('/'))
  if c['State']['Running']:L.docker('stop','--time','1' if c['Image']==L.HELPER else '10',cid)
  L.require(not L.inspect(cid)['State']['Running'],'B process remained active');closed.append(c['Name'])
 L.save('99-stopped.json',{'result':'PASS','containers':closed,'next_increment_started':False})
if __name__=='__main__':
 try:run()
 except Exception as e:L.save('RECOVERY-ATTEMPT-'+str(time.time_ns())+'.json',{'result':'BLOCKED','error':str(e)});L.stop();raise
