"""Stage-specific exact PAX backup and recovery, reusing verified transport."""
import json,sys
import orgc_lab as L
from org0_cases import lit,login,call,deny
from s0_recovery import pax_backup
from pax_transport import compare

def run(stage):
 receipt='09b-ORG0-conservation-final.json' if stage=='ORG0' else '21-C-conservation.json';L.require(json.loads((L.RUN/receipt).read_text())['result']=='PASS','Final conservation required before backup')
 label='ORG0-final-v2-verified' if stage=='ORG0' else 'C-final-verified';results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';expected=json.loads((L.PRIVATE/(a+'-'+label+'.json')).read_text());L.require(L.capture(pg)==expected,'Pre-backup logical drift')
  db=L.cold_backup(a,label);st=pax_backup(f'{L.OWNER}-{a}-storage-copy',a+'-'+stage+'-final-storage',f'{L.OWNER}-{stage.lower()}-recovery-{a}-storage');co=pax_backup(f'{L.OWNER}-{a}-control-v2-copy',a+'-'+stage+'-final-control',f'{L.OWNER}-{stage.lower()}-recovery-{a}-control-v2')
  dataset=a+'-'+label+'-recovery';rec=f'{L.OWNER}-{dataset}-pg';L.docker('start',rec);L.ready(rec);L.runtime_net(dataset,{5432});L.require(L.capture(rec)==expected,'Recovered DB drift')
  f=json.loads((L.PRIVATE/(a+'-ORG0-active-fixture.json')).read_text());org=lit(f['orgs']['primary']);L.require(call(rec,'owner','SELECT collaboration.org_authorize('+org+",'mission.manage');")['authorized'],'Restored authorized owner rejected');deny(rec,'editor','SELECT collaboration.org_authorize('+org+",'mission.manage');");deny(rec,'admin','SELECT collaboration.org_authorize('+org+",'mission.manage');")
  L.require(L.val(rec,"SELECT count(*) FROM pg_trigger WHERE tgname LIKE 'aa_s0_%' AND tgenabled='O';")==40,'Restored S0 guards drift')
  L.require(L.capture(rec)==expected,'Restored probes changed DB')
  for stem,art in [('storage',st),('control',co)]:compare(json.loads((L.PRIVATE/(a+'-'+stage+'-final-'+stem+'.manifest.json')).read_text()),L.pax_snapshot(art['restored_copy']))
  L.docker('stop','--time','10',rec);results[a]={'result':'PASS','DB':db,'Storage':st,'coordination':co,'positive_real_SQL_identity_after_restore':True,'revoked_members_denied_after_restore':True,'DB_logical_and_physical_snapshots_exact':True,'S0_guards':40,'remote_or_purge_executed':False}
 L.save('10-ORG0-recovery.json' if stage=='ORG0' else '22-C-recovery.json',{'result':'PASS','sources':results,'not_E2_R_integrated_acceptance':True})
 if stage=='ORG0':
  # Re-open only these current-run working copies after their own recovery.
  for a in ['a','b']:
   pg=f'{L.OWNER}-{a}-pg';L.docker('start',pg);L.ready(pg);L.runtime_net(a,{5432});L.require(L.capture(pg)==json.loads((L.PRIVATE/(a+'-'+label+'.json')).read_text()),'Working-copy restart drift')
  L.save('12-ORG0-ACCEPTANCE.json',{'result':'PASS','stage':'ORG0_ONLY','gates':['05-ORG0-installation.json','07-ORG0-GREEN.json','08-ORG0-concurrency-states.json','08b-ORG0-expiry-integrity.json','09b-ORG0-conservation-final.json','10-ORG0-recovery.json'],'C_started':False,'C_conditional_authorization_now_satisfied':True,'product_or_TASK002_acceptance':False})
 else:L.save('99-stopped.json',{'result':'PASS','containers':L.stop(),'next_increment_started':False})
if __name__=='__main__':
 try:run(sys.argv[1])
 except Exception as e:
  import time
  L.save('RECOVERY-ATTEMPT-'+str(time.time_ns())+'.json',{'result':'BLOCKED','error':str(e)});L.stop();raise
