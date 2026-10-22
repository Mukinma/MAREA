"""Bounded S0 review correction; all RED fixture changes roll back, never purge."""
import hashlib,json,sys,time,uuid
import s0_lab_v2 as L
import s0_services as S
import s0_fence as OLD
from s0_cases import lit,private_fixture,PNG

def probe(a,table):
 pg=f'{L.OWNER}-{a}-pg';tid=str(uuid.uuid4());rid=str(uuid.uuid4())
 # Both resources exist inside this transaction with an actual stored evidence
 # path. No fixture or loss is committed; ROLLBACK is explicit even in RED.
 q="BEGIN;SET LOCAL transaction_read_only=off;SET LOCAL ROLE service_role;SET LOCAL statement_timeout='15s';"
 q+="INSERT INTO public.tours SELECT (jsonb_populate_record(NULL::public.tours,to_jsonb(t)||jsonb_build_object('id',"+lit(tid)+",'space',jsonb_build_object('evidence_paths',jsonb_build_array(o.name))))).* FROM public.tours t CROSS JOIN (SELECT name FROM storage.objects WHERE bucket_id='tour-assets' LIMIT 1)o LIMIT 1;"
 q+="INSERT INTO public.tour_revisions(id,tour_id,owner_id,title,space,document) SELECT "+lit(rid)+",id,owner_id,title,space,document FROM public.tours WHERE id="+lit(tid)+";"
 q+="WITH changed AS (UPDATE public."+table+" SET space=space-'evidence_paths' WHERE id="+lit(tid if table=='tours' else rid)+" AND jsonb_array_length(space->'evidence_paths')=1 RETURNING id) SELECT count(*) FROM changed;ROLLBACK;"
 return L.sql(pg,q,write=True,check=False)

def exact(a,expected):
 L.require(L.capture(f'{L.OWNER}-{a}-pg')==expected,'Review probe changed persistent data/catalog')
 tree=json.loads((L.PRIVATE/(a+'-T49-v2-before.json')).read_text())['tree']
 L.require(L.pax_snapshot(f'{L.OWNER}-{a}-storage-copy')==tree,'Review probe changed physical assets')

def red():
 results={}
 for a in ['a','b']:
  expected=json.loads((L.PRIVATE/(a+'-S0-final-verified.json')).read_text());exact(a,expected)
  OLD.assert_guards(a);cases=[]
  for table in ['tours','tour_revisions']:
   r=probe(a,table);L.private(a+'-space-RED-'+table+'.json',{'exit':r.returncode,'stdout':r.stdout,'stderr':r.stderr})
   L.require(r.returncode==0 and r.stdout.strip()=='1','Missing guard not reproduced on actual evidence reference')
   exact(a,expected);cases.append({'table':table,'role':'service_role','reference_removed_inside_transaction':1,'explicit_rollback':True,'persistent_snapshot_exact':True})
  results[a]={'result':'EXPECTED_RED','cases':cases}
 L.save('22-space-reference-RED.json',{'result':'EXPECTED_RED','finding':'UPDATE OF omitted space on tours and tour_revisions','no_committed_loss':True,'sources':results})

def green():
 import s0_fence_v3 as F
 L.require(json.loads((L.RUN/'22-space-reference-RED.json').read_text())['result']=='EXPECTED_RED','RED required')
 patch=L.RUN/'20261019210000_e2s0_space_reference_fix.sql';q=patch.read_text();results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';before=json.loads((L.PRIVATE/(a+'-S0-final-verified.json')).read_text());exact(a,before)
  old_state=json.loads(OLD.state_bytes(a));L.require(old_state==json.loads((L.PRIVATE/(a+'-ACTIVE-state.json')).read_text()),'Old coordination drift')
  OLD.put_state(a,{**old_state,'status':'PREPARING'})
  L.sql(pg,q.rsplit('COMMIT;',1)[0]+'ROLLBACK;',write=True);exact(a,before)
  L.sql(pg,q,write=True);after=L.capture(pg)
  # Only the two S0-added trigger definitions may change. No data, grants,
  # function, FK, RLS, mission ownership or pre-existing trigger changes.
  expected=json.loads(json.dumps(before));old_defs={}
  for section,key in [('catalog','triggers')]:
   for item in expected[section][key]:
    if item['name']=='aa_s0_reference' and item['relation'] in ['tours','tour_revisions']:
     old_defs[item['relation']]=item['definition'];item['definition']=item['definition'].replace('UPDATE OF document, revision_id, public_revision_id','UPDATE OF document, revision_id, public_revision_id, space').replace('UPDATE OF document ON','UPDATE OF document, space ON')
  L.require(after==expected,'Unexpected DDL delta in review fix');guards=F.assert_guards(a)
  for table in ['tours','tour_revisions']:
   r=probe(a,table);L.private(a+'-space-GREEN-'+table+'.json',{'exit':r.returncode,'stdout':r.stdout,'stderr':r.stderr})
   L.require(r.returncode!=0 and '55000' in r.stderr and 'S0_DESTRUCTIVE_TRANSITION_FENCED' in r.stderr,'space reference not fenced');exact(a,after)
  state={**old_state,'guard_manifest_sha256':L.sha(F.MANIFEST),'review_patch_sha256':L.sha(patch),'prior_state_sha256':hashlib.sha256((json.dumps(old_state,sort_keys=True)+'\n').encode()).hexdigest()}
  digest=F.put_state(a,state);L.private(a+'-ACTIVE-state-v3.json',state)
  S.storage_start(a,'storage-space-v3',readonly=True);S.rest_start(a,'rest-space-v3');S.auth_start(a,'auth-space-v3');F.ingress_start(a,digest,'ingress-space-v3')
  L.require(L.capture(pg)==after,'Service startup drift');F.reconcile_active(a)
  # Privileged HTTP PATCH must reach an existing row and the actual guard.
  tid=L.val(pg,'SELECT to_jsonb(id) FROM public.tours ORDER BY id LIMIT 1;')
  get=S.request(a,3000,'/tours?id=eq.'+tid+'&select=id',token=S.jwt(a));L.require(get['status']==200 and len(get['body'])==1,'Privileged REST fixture not visible')
  patched=S.request(a,3000,'/tours?id=eq.'+tid,'PATCH',data={'space':{}},token=S.jwt(a));L.private(a+'-space-PATCH-v3.json',patched)
  L.require(patched['status']>=400 and patched['body'].get('code')=='55000','Privileged PATCH bypassed space guard');exact(a,after)
  # Recheck unchanged physical barrier, persistent gate and duplicate contract.
  f=private_fixture(a);valid=S.jwt(a)
  read=S.request(a,5000,'/object/authenticated/mission-images/'+f['path'],token=valid);L.require(read['status']==200 and read['sha256']==hashlib.sha256(PNG).hexdigest(),'Post-fix read failed')
  denied=S.request(a,5000,'/object/mission-images','DELETE',data={'prefixes':[f['path']]},token=valid);L.require(denied['status']==500 and '55000' in denied['body'].get('message',''),'Post-fix Storage guard failed')
  response=S.request(a,9000,'/functions/v1/delete-account','POST',data={},token=S.jwt(a,'authenticated',f['user'],f['session']));L.require(response['status']==503 and response['body'].get('completed') is False and response['body'].get('request_recorded') is True,'Post-fix false purge or marker failure')
  exact(a,after);L.private(a+'-S0-v3-final-verified.json',after)
  results[a]={'result':'PASS','SQL_reference_denials':2,'REST_PATCH_SQLSTATE':'55000','DDL_rollback_exact':True,'changed_S0_triggers':2,'guard_count':len(guards['triggers']),'all_rows_sequences_grants_FKs_existing_functions_unchanged':True,'full_physical_tree_unchanged':True,'Storage_delete_HTTP':denied['status'],'Storage_read_HTTP':read['status'],'duplicate_marker_HTTP':response['status'],'completed':False,'epoch':state['epoch'],'digest':digest}
 L.save('23-space-reference-GREEN.json',{'result':'PASS','sources':results,'patch_sha256':L.sha(patch),'manifest_sha256':L.sha(F.MANIFEST),'original_T49_cut_still_valid_no_process_reopened_writable':True})

if __name__=='__main__':
 try:
  if sys.argv[1:]==['red']:red()
  elif sys.argv[1:]==['green']:green()
  else:raise SystemExit('red | green')
 except Exception as e:
  L.save('SPACE-FIX-FAIL-'+str(time.time_ns())+'.json',{'result':'BLOCKED','error':str(e)});L.stop();raise
