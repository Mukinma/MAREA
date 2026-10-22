"""Actual rejected inputs/constraints, in disposable clones, with no persistent delta."""
import uuid,time
import e2a_r7 as L
from e2a_r7_cases import expect_sql_error,literal,write

def run():
 sources={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';before=L.capture(pg);cases=[]
  def reject(label,q,state,role=None):
   result=expect_sql_error(pg,q,state,role);cases.append({'case':label,**result})
  op='marea_person_repair_operator';batch=str(uuid.uuid4());uid=L.val(pg,"SELECT to_jsonb(auth_user_id) FROM collaboration.persons WHERE auth_user_id IS NOT NULL ORDER BY id LIMIT 1;")
  for label,ids in [('empty','ARRAY[]::uuid[]'),('null','NULL::uuid[]'),('null_item','ARRAY[NULL]::uuid[]'),('duplicates','ARRAY['+literal(uid)+','+literal(uid)+']::uuid[]'),('over_bound','ARRAY['+','.join(literal(str(uuid.uuid4())) for _ in range(101))+']::uuid[]')]:
   reject('manifest_'+label,'SELECT collaboration.stage_person_repair('+literal(batch)+','+ids+');','22023',op)
  reject('null_batch','SELECT collaboration.stage_person_repair(NULL,ARRAY['+literal(uid)+']::uuid[]);','22023',op)
  reject('explicit_dry_run_required','SELECT collaboration.reconcile_persons('+literal(batch)+',\''+'0'*64+'\',NULL);','22004',op)
  reject('manifest_required','SELECT collaboration.reconcile_persons('+literal(batch)+',\''+'0'*64+'\',true);','P0002',op)
  reject('invalid_sync_source','SELECT collaboration.ensure_person_for_auth('+literal(uid)+',\'client\');','22023')
  reject('duplicate_mapping','INSERT INTO collaboration.persons(id,auth_user_id) VALUES(\''+str(uuid.uuid4())+'\','+literal(uid)+');','23505')
  reject('duplicate_person_pk','INSERT INTO collaboration.persons(id,auth_user_id) SELECT id,NULL FROM collaboration.persons LIMIT 1;','23505')
  reject('control_fk','INSERT INTO collaboration.person_controls(person_id,sync_blocked,obligations_blocked,created_source) VALUES(\''+str(uuid.uuid4())+'\',false,false,\'FIXTURE\');','23503')
  reject('control_pk','INSERT INTO collaboration.person_controls(person_id,sync_blocked,obligations_blocked,created_source) SELECT person_id,false,false,\'FIXTURE\' FROM collaboration.person_controls LIMIT 1;','23505')
  reject('control_consistency','INSERT INTO collaboration.person_controls(person_id,sync_blocked,obligations_blocked,created_source) VALUES(\''+str(uuid.uuid4())+'\',true,true,\'FIXTURE\');','23514')
  reject('manifest_result_pair','INSERT INTO collaboration.person_repair_manifests(batch_id,auth_ids,manifest_hash,result) VALUES('+literal(batch)+',ARRAY['+literal(uid)+']::uuid[],\''+'0'*64+'\',\'{}\');','23514')
  reject('forged_claim_no_private_access',"SET LOCAL request.jwt.claims='{\"role\":\"service_role\",\"sub\":\""+uid+"\"}'; SELECT * FROM collaboration.persons;",'42501','authenticated')
  L.require(L.capture(pg)==before,'Negative constraint/input tests changed data/catalog/sequences')
  sources[a]={'result':'PASS','cases':cases,'count':len(cases),'snapshot_exactly_equal_before_after':True}
 L.save('06b-constraint-input-negative.json',{'result':'PASS','sources':sources})
if __name__=='__main__':
 try:run()
 except Exception as e:L.save('FAILURE-'+str(time.time_ns())+'.json',{'result':'FAIL_STOPPED','error':str(e)});L.stop();raise
