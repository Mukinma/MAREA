"""Final physical recovery and stop. No next increment can run here."""
import json,time
import e2a_r8 as L

def run():
 for receipt in ['06-functional-GREEN.json','06b-constraint-input-negative.json','07-integrity-conservation.json']:
  L.require(json.loads((L.RUN/receipt).read_text())['result']=='PASS','Final recovery requires complete preceding verification')
 sources={}
 for a in ['a','b']:
  network=L.runtime_net(a,{5432,9999})
  sources[a]={'network':network,'backup_restore':L.cold_backup(a,'A-final-verified')}
 L.save('08-final-cold-recovery.json',{'result':'PASS','sources':sources,'DB_full_logical_catalog_acl_data_sequence_recovered':True,'Storage_recovery_already_verified_and_unchanged':True,'no_next_increment':True})
 L.save('99-stopped.json',{'result':'PASS','containers':L.stop(),'E2_A_execution_finished':True,'next_increment_started':False})
if __name__=='__main__':
 try:run()
 except Exception as e:L.save('FAILURE-'+str(time.time_ns())+'.json',{'result':'FAIL_STOPPED','error':str(e)});L.stop();raise
