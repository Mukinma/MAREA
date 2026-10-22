"""Resume partial RED by proven phase; never repeat registered identity fixtures."""
import json,time,uuid
import s0_lab as L
import s0_services as S
from s0_cases import refs,upload,write,lit

def run():
 L.require(json.loads((L.RUN/'09-services-resumed.json').read_text())['result']=='PASS','Services gate required')
 L.require(not (L.RUN/'06-T49-RED.json').exists(),'RED receipt already sealed')
 for a in ['a','b']:
  if (L.PRIVATE/(a+'-green-baseline.json')).exists():continue
  recovery=json.loads((L.PRIVATE/(a+'-phase-recovery.json')).read_text());L.require(len(recovery['fixtures'])==1,'Ambiguous fixture identity')
  f=recovery['fixtures'][0];user=f['user'];path=user+'/'+str(uuid.uuid4())+'.png';missions=[str(uuid.uuid4()),str(uuid.uuid4())];pg=f'{L.OWNER}-{a}-pg'
  L.private(a+'-fixture.json',{'user':user,'session':f['session'],'path':path,'missions':missions,'provenance':'previous confirmed Auth signup; never repeated'})
  upload(a,path)
  for i,mid in enumerate(missions):
   write(pg,"INSERT INTO public.missions SELECT (jsonb_populate_record(NULL::public.missions,to_jsonb(m)||jsonb_build_object('id',"+lit(mid)+",'author_id',"+lit(user)+",'title','Synthetic S0 protected "+str(i)+"','image_path',"+lit(path)+",'starts_at',clock_timestamp()+interval '20 days','created_at',clock_timestamp(),'status','open','hidden',false,'conditions_locked_at',NULL,'cancellation_reason',NULL,'lifecycle_event_version',1))).* FROM public.missions m WHERE m.status='open' LIMIT 1;")
  before=refs(a);tree=L.pax_snapshot(f'{L.OWNER}-{a}-storage-copy');L.require(len(before['missions'])==2 and before['object'] is not None,'Fixture incomplete');L.private(a+'-red-before.json',{'refs':before,'tree':tree,'db':L.capture(pg)})
  listed=S.request(a,5000,'/object/list/mission-images','POST',data={'prefix':user,'limit':100,'offset':0},token=S.jwt(a));L.require(listed['status']==200 and any(x['name']==path.split('/')[1] for x in listed['body']),'Legacy prefix did not identify protected asset')
  r=S.request(a,5000,'/object/mission-images','DELETE',data={'prefixes':[path]},token=S.jwt(a));after=refs(a);tree_after=L.pax_snapshot(f'{L.OWNER}-{a}-storage-copy');L.private(a+'-red-after.json',{'refs':after,'tree':tree_after,'http':r})
  was=[x for x in tree if '/'+path+'/' in x['path'] and x['kind']=='file'];now=[x for x in tree_after if '/'+path+'/' in x['path'] and x['kind']=='file']
  L.require(r['status']==200 and was and not now and after['object'] is None and after['missions']==before['missions'],'RED did not prove actual dangerous deletion')
  upload(a,path);repaired=refs(a);L.require(repaired['object'] is not None and repaired['missions']==before['missions'],'Compensating fixture upload failed')
  L.private(a+'-green-baseline.json',{'refs':repaired,'tree':L.pax_snapshot(f'{L.OWNER}-{a}-storage-copy'),'db':L.capture(pg)})
 results={}
 for a in ['a','b']:
  b=json.loads((L.PRIVATE/(a+'-red-before.json')).read_text());r=json.loads((L.PRIVATE/(a+'-red-after.json')).read_text());g=json.loads((L.PRIVATE/(a+'-green-baseline.json')).read_text())
  L.require(b['refs']['object'] is not None and r['refs']['object'] is None and r['http']['status']==200 and b['refs']['missions']==r['refs']['missions']==g['refs']['missions'],'Saved RED mismatch')
  L.require(g['refs']['object'] is not None and g['refs']['object']['id']!=b['refs']['object']['id'],'Compensation identity must remain explicit')
  results[a]={'result':'EXPECTED_RED','HTTP_remove':200,'real_physical_bytes_deleted':True,'protected_references_left':2,'Auth_delete_performed':False,'only_new_synthetic_fixture_changed':True,'compensating_API_upload':True,'object_identity_changed_explicitly':True}
 L.save('06-T49-RED.json',{'result':'EXPECTED_RED','sources':results,'S0_implemented':False,'original_rows_conserved':True})
if __name__=='__main__':
 try:run()
 except Exception as e:L.save('RED-RESUME-FAIL-'+str(time.time_ns())+'.json',{'result':'BLOCKED','error':str(e)});L.stop();raise
