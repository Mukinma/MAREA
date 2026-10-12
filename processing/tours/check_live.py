"""Opt-in REAL hosted verification using only disposable synthetic test accounts."""
from __future__ import annotations
import argparse
import base64
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import secrets
import subprocess
import sys
import time
from urllib.parse import quote,urljoin,urlparse
import uuid
import requests
from PIL import Image
from local_runner import read_config,cycle
from worker import Backend,validate_gpano

ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser();parser.add_argument('--run',action='store_true');parser.add_argument('--image',default='marea/tour-stitch:local-pilot');args=parser.parse_args()
if not args.run:parser.exit(message='Opt-in: python processing/tours/check_live.py --run\n')
config=read_config(ROOT/'config/.env.tours-local')
public=json.loads((ROOT/'config/supabase.production.json').read_text())
base=config['SUPABASE_URL'];admin=config['SUPABASE_SERVICE_ROLE_KEY'];anon=public['SUPABASE_ANON_KEY']
backend=Backend(base,admin);users=[];checks=[];run=secrets.token_hex(5);completed=False
out=ROOT/'output/tours-pilot';out.mkdir(parents=True,exist_ok=True)
checkpoint=out/('resources-'+run+'.json')

def record():
    checkpoint.write_text(json.dumps({'run':run,'users':[{'id':u['id'],'email':u['email']} for u in users]},indent=2));checkpoint.chmod(0o600)
def check(value,label):
    if not value:raise AssertionError(label)
    checks.append(label);print('PASS '+label,flush=True)
def request(path,user=None,method='GET',body=None,data=None,headers=None,privileged=False):
    key=admin if privileged else anon
    return requests.request(method,base+path,headers={'apikey':key,'Authorization':'Bearer '+(user['token'] if user else key),'Content-Type':'application/json',**(headers or {})},json=body,data=data,timeout=(10,60))
def api(path,**kw):
    r=request(path,**kw)
    if not r.ok:raise RuntimeError(f'Hosted request rejected: {path.split("?")[0]} HTTP {r.status_code}: {r.json().get("message",r.json().get("error",""))[:120]}')
    return r.json() if r.content else None
def rpc(user,name,body=None):return api('/rest/v1/rpc/'+name,user=user,method='POST',body=body or {})
def sql(query):
    r=subprocess.run(['supabase','db','query','--linked','--output','json',query],capture_output=True,text=True)
    if r.returncode:raise RuntimeError('Administrative verification query failed; output withheld')
    return json.loads(r.stdout)['rows']
def denied(user,name,body,label):check(not request('/rest/v1/rpc/'+name,user=user,method='POST',body=body).ok,label)
def upload(user,bucket,path,data):
    api('/storage/v1/object/'+bucket+'/'+path,user=user,method='POST',data=data,headers={'Content-Type':'image/jpeg'})
def sign(user,bucket,path):
    result=api('/storage/v1/object/sign/'+bucket+'/'+path,user=user,method='POST',body={'expiresIn':60})
    return base+'/storage/v1'+result['signedURL']
def tus(user,path,data):
    headers={'apikey':anon,'Authorization':'Bearer '+user['token'],'Tus-Resumable':'1.0.0'}
    metadata={'bucketName':'tour-inputs','objectName':path,'contentType':'image/jpeg','cacheControl':'3600'}
    created=requests.post(base+'/storage/v1/upload/resumable',headers={**headers,'Upload-Length':str(len(data)),'Upload-Metadata':','.join(k+' '+base64.b64encode(v.encode()).decode() for k,v in metadata.items())},timeout=60)
    check(created.status_code==201,'TUS private upload created')
    url=urljoin(base,created.headers['Location'])
    if urlparse(url).netloc!=urlparse(base).netloc:raise AssertionError('Untrusted TUS URL')
    chunk=6*1024*1024
    with requests.Session() as first:
        r=first.patch(url,headers={**headers,'Content-Type':'application/offset+octet-stream','Upload-Offset':'0'},data=data[:chunk],timeout=60)
        check(r.status_code==204,'TUS first 6MiB chunk committed')
    # Client interruption: discard the response/checkpoint offset and close session.
    with requests.Session() as resumed:
        head=resumed.head(url,headers=headers,timeout=30)
        offset=int(head.headers.get('Upload-Offset',-1))
        check(head.ok and offset==chunk,'TUS resumes from remote offset on a new connection')
        r=resumed.patch(url,headers={**headers,'Content-Type':'application/offset+octet-stream','Upload-Offset':str(offset)},data=data[offset:],timeout=60)
        check(r.status_code==204 and int(r.headers['Upload-Offset'])==len(data),'TUS resumed upload completed')
    received=requests.get(sign(user,'tour-inputs',path),timeout=60)
    check(received.ok and hashlib.sha256(received.content).digest()==hashlib.sha256(data).digest(),'TUS stored bytes equal original after interruption')
def save(owner,tour,document,space):return rpc(owner,'tours_save',{'p_tour':tour,'p_title':'TEST synthetic 360 tour '+run,'p_space':space,'p_document':document})
def begin(owner,tour,scene,mode):return rpc(owner,'tours_capture_begin',{'p_tour':tour,'p_scene':scene,'p_mode':mode})['id']
def submit(owner,cap,frames,mode):return rpc(owner,'tours_capture_submit',{'p_capture':cap,'p_manifest':{'mode':mode,'frames':frames}})
def import_job(owner,tour,scene,source):
    cap=begin(owner,tour,scene,'import');ident=str(uuid.uuid4());path=f'{owner["id"]}/{cap}/{ident}.jpg'
    upload(owner,'tour-inputs',path,source)
    return submit(owner,cap,[{'id':ident,'path':path,'width':4096,'height':2048,'yaw':0,'pitch':0,'roll':0,'hfov':360,'vfov':180}],'import')
def job(owner,ident):return rpc(owner,'tours_job_get',{'p_job':ident})
def cleanup(user):
    r=request('/functions/v1/delete-account',user=user,method='POST',body={})
    if r.status_code!=204:raise RuntimeError('Disposable account cleanup failed: '+str(r.status_code))
    remaining=sql(f"select count(*)::int n from storage.objects where bucket_id in ('tour-inputs','tour-assets') and split_part(name,'/',1)='{user['id']}'")[0]['n']
    if remaining:raise RuntimeError('Disposable account deletion left tour media')
    if request('/auth/v1/admin/users/'+user['id'],privileged=True).status_code!=404:
        raise RuntimeError('Disposable authentication account still exists')

try:
    baseline=sql("select count(*)::int n from private.tour_jobs where state in ('queued','processing')")[0]['n']
    check(baseline==0,'queue empty before disposable verification; no existing jobs touched')
    policy=rpc(None,'registration_policy')
    for i in range(3):
        password=secrets.token_urlsafe(32);email=f'marea-tours-{run}-{i}@example.invalid'
        u=api('/auth/v1/admin/users',privileged=True,method='POST',body={'email':email,'password':password,'email_confirm':True,'user_metadata':{'full_name':'Synthetic tour verification','username':f'tour_{run}_{i}','user_type':'Negocio' if i==0 else 'Usuario general','registration_flow':'minimal-v1','accepted_terms':True,'adult_confirmed':True,'terms_version':policy['terms']['version'],'privacy_version':policy['privacy']['version']}})
        entry={'id':u['id'],'email':email};users.append(entry);record()
        entry['token']=api('/auth/v1/token?grant_type=password',method='POST',body={'email':email,'password':password})['access_token']
    owner,visitor,reviewer=users
    sql(f"update public.profiles set role='admin' where id='{reviewer['id']}'::uuid and username='tour_{run}_2' returning id")
    check(rpc(reviewer,'community_is_admin'),'only disposable reviewer granted administrative test role')
    tour=str(uuid.uuid4());scene=str(uuid.uuid4());scene2=str(uuid.uuid4());point=str(uuid.uuid4())
    document={'zones':[{'id':str(uuid.uuid4()),'name':'Synthetic test zone','scenes':[{'id':scene,'name':'Position A','initial_yaw':0,'connections':[],'points':[{'id':point,'name':'Synthetic point','description':'Software fixture; no physical AR approval.','yaw':179.5,'pitch':0}]}]}],'start_scene_id':scene,'ar_order':[]}
    space={'name':'TEST synthetic place','location_label':'Synthetic fixture','latitude':19.4326,'longitude':-99.1332,'context':'Software verification only. This is not evidence of a real business.','evidence_paths':[]}
    saved=save(owner,tour,document,space);document=saved['document'];space=saved['space']
    check(rpc(visitor,'tours_get',{'p_tour':tour,'p_edit':False}) is None,'draft invisible to other account')
    denied(visitor,'tours_save',{'p_tour':tour,'p_title':'Foreign','p_space':space,'p_document':document},'foreign editing rejected')
    denied(owner,'tours_claim_jobs',{},'user cannot claim service queue')
    cap=begin(owner,tour,scene,'photos');frames=[]
    fixture=json.loads((out/'fixtures/fixture.json').read_text())['frames']
    for i,f in enumerate(fixture):
        ident=str(uuid.uuid4());path=f'{owner["id"]}/{cap}/{ident}.jpg';data=(out/'fixtures'/f['file']).read_bytes()
        if i==0:
            # Valid JPEG with deterministic trailing bytes creates >6MiB TUS test data.
            data+=b'MAREA synthetic TUS padding.'*(340000)
            tus(owner,path,data)
        else:upload(owner,'tour-inputs',path,data)
        frames.append({k:v for k,v in f.items() if k!='file'}|{'id':ident,'path':path})
    check(not request('/storage/v1/object/sign/tour-inputs/'+frames[0]['path'],user=visitor,method='POST',body={'expiresIn':60}).ok,'original photographs private across accounts')
    check(not requests.get(base+'/storage/v1/object/public/tour-inputs/'+frames[0]['path'],timeout=30).ok,'original bucket cannot be read publicly')
    first=submit(owner,cap,frames,'photos')
    check(submit(owner,cap,frames,'photos')['id']==first['id'],'capture resubmission is idempotent')
    altered=json.loads(json.dumps(frames));altered[0]['yaw']=-179
    denied(owner,'tours_capture_submit',{'p_capture':cap,'p_manifest':{'mode':'photos','frames':altered}},'submitted capture immutable')
    unauthorized=request('/functions/v1/tour-dispatch',method='POST',body={})
    authorized=requests.post(base+'/functions/v1/tour-dispatch',headers={'Authorization':'Bearer '+config['TOUR_WORKER_SECRET']},timeout=30)
    check(unauthorized.status_code==401 and authorized.status_code==503,'dispatcher unauthorized/configuration-pending responses')
    check(job(owner,first['id'])['state']=='queued','unconfigured dispatcher did not claim queued capture')
    results=cycle(ROOT/'config/.env.tours-local',args.image,config)
    ready=job(owner,first['id']);check(ready['state']=='ready' and results[0]['state']=='ready','real Docker photographic processing confirmed ready in hosted Supabase')
    panorama=requests.get(sign(owner,'tour-assets',ready['result']['panorama_path']),timeout=60)
    check(panorama.ok,'processed panorama downloadable by owner')
    (out/'remote-panorama.jpg').write_bytes(panorama.content)
    check(validate_gpano(out/'remote-panorama.jpg')==(4096,2048),'hosted result has valid full GPano dimensions')
    check(not request('/storage/v1/object/sign/tour-assets/'+ready['result']['panorama_path'],user=visitor,method='POST',body={'expiresIn':60}).ok,'unpublished result private')
    saved=rpc(owner,'tours_attach_result',{'p_tour':tour,'p_scene':scene,'p_job':first['id']});document=saved['document']
    # Add second viewpoint and verify two independent simultaneous lease claims.
    document['zones'][0]['scenes'].append({'id':scene2,'name':'Position B','connections':[],'points':[],'initial_yaw':0})
    document=save(owner,tour,document,space)['document']
    second=import_job(owner,tour,scene2,panorama.content)
    spare=import_job(owner,tour,str(uuid.uuid4()),panorama.content)
    concurrent=import_job(owner,tour,str(uuid.uuid4()),panorama.content)
    with ThreadPoolExecutor(max_workers=2) as pool:
        batches=list(pool.map(lambda _:Backend(base,admin).rpc('tours_claim_jobs',{}),range(2)))
    claimed=[j for batch in batches for j in batch]
    check(len(claimed)==2 and len({j['id'] for j in claimed})==2,'concurrent real connections claim two distinct leases')
    check(backend.rpc('tours_claim_jobs',{})==[],'global capacity prevents a third active claim')
    leases={j['id']:j for j in claimed};sparelease=leases[spare['id']]
    rpc(owner,'tours_job_cancel',{'p_job':spare['id']})
    check(not backend.current(spare['id'],sparelease['lease_id']),'cancellation invalidates current lease')
    check(not backend.finish(spare['id'],sparelease['lease_id'],'succeeded',ready['result']),'cancelled old execution cannot commit outputs')
    # Run second already-claimed lease with the exact production container.
    from local_runner import run_one
    thirdlease=next(j for j in backend.rpc('tours_claim_jobs',{}) if j['id']==concurrent['id'])
    with ThreadPoolExecutor(max_workers=2) as pool:
        parallel=list(pool.map(lambda j:run_one(j,ROOT/'config/.env.tours-local',args.image,config),[leases[second['id']],thirdlease]))
    check(all(r['state']=='ready' and r['container_exit']==0 for r in parallel),'two real Docker containers commit independent hosted results with clean exits')
    check(job(owner,second['id'])['state']=='ready','import container committed hosted result')
    receipt=backend.receipt(second['id'],leases[second['id']]['lease_id'])
    check(backend.finish(second['id'],leases[second['id']]['lease_id'],'succeeded',receipt['result']),'duplicate/lost-response finish reconciles idempotently')
    check(not backend.finish(second['id'],str(uuid.uuid4()),'succeeded',receipt['result']),'wrong execution cannot adopt a ready result')
    # Hosted terminal needs_recapture, using an ordinary JPEG without GPano.
    import io
    ordinary=io.BytesIO()
    with Image.open(io.BytesIO(panorama.content)) as im:im.save(ordinary,format='JPEG',quality=85)
    invalid=import_job(owner,tour,str(uuid.uuid4()),ordinary.getvalue())
    rejected=cycle(ROOT/'config/.env.tours-local',args.image,config)
    check(rejected[0]['state']=='not_ready' and job(owner,invalid['id'])['state']=='needs_recapture','ordinary 2:1 JPEG is rejected by actual container and hosted job state')
    document=rpc(owner,'tours_attach_result',{'p_tour':tour,'p_scene':scene2,'p_job':second['id']})['document']
    for a,b in ((scene,scene2),(scene2,scene)):
        item=next(s for s in document['zones'][0]['scenes'] if s['id']==a)
        item['connections']=[{'id':str(uuid.uuid4()),'target_scene_id':b,'label':'Next synthetic position','instruction':'Test connection; no physical directions.','yaw':0,'pitch':0}]
    reference=f'{owner["id"]}/references/{uuid.uuid4()}.jpg'
    upload(owner,'tour-assets',reference,(out/'fixtures/frame000.jpg').read_bytes())
    space['evidence_paths']=[reference]
    document['zones'][0]['scenes'][0]['points'][0]['ar']={'reference_path':reference,'width_cm':20,'reference_version':str(uuid.uuid4())}
    saved=save(owner,tour,document,space);document=saved['document'];space=saved['space']
    check(document['zones'][0]['scenes'][0]['points'][0]['ar']['tested_version'] is None,'automated test does not accredit physical AR')
    submitted=rpc(owner,'tours_submit',{'p_tour':tour})
    check(submitted['state']=='submitted','first publication requires independent review')
    requests_list=[r for r in rpc(reviewer,'tours_requests') if r['tour_id']==tour]
    space_req=next(r for r in requests_list if r['kind']=='space');pub_req=next(r for r in requests_list if r['kind']=='publication')
    denied(owner,'tours_review',{'p_request':space_req['id'],'p_approve':True,'p_reason':''},'business owner cannot self-accredit space')
    denied(reviewer,'tours_review',{'p_request':pub_req['id'],'p_approve':True,'p_reason':''},'publication requires space authorization first')
    rpc(reviewer,'tours_review',{'p_request':space_req['id'],'p_approve':True,'p_reason':'Synthetic automated verification only'})
    rpc(reviewer,'tours_review',{'p_request':pub_req['id'],'p_approve':True,'p_reason':'Synthetic automated verification only'})
    published=rpc(visitor,'tours_get',{'p_tour':tour,'p_edit':False})
    check(published and published['public_revision_id'],'authorized revision visible to visitor')
    check('context' not in published['space'] and 'evidence_paths' not in published['space'],'public tour strips private evidence and context')
    check(published['document']['zones'][0]['scenes'][0]['points'][0]['ar'] is None,'untested AR omitted from published snapshot')
    for item in published['document']['zones'][0]['scenes']:
        for key in ('panorama_path','preview_path','thumbnail_path'):
            downloaded=requests.get(sign(visitor,'tour-assets',item[key]),timeout=60)
            check(downloaded.ok,'visitor reads published '+item['name']+' '+key)
            if key=='preview_path':(out/('remote-preview-'+item['id']+'.jpg')).write_bytes(downloaded.content)
    check(not request('/storage/v1/object/sign/tour-inputs/'+frames[0]['path'],user=visitor,method='POST',body={'expiresIn':60}).ok,'publication never reveals original photographs')
    published['fixture_notice']='Actual Docker output of synthetic geometry; offline visual snapshot after disposable test cleanup.'
    (out/'published-view.json').write_text(json.dumps(published,indent=2))
    rpc(visitor,'tours_progress',{'p_tour':tour,'p_revision':published['public_revision_id'],'p_progress':{'scene_id':scene2,'visited':[],'skipped':[],'revision_id':published['public_revision_id']}})
    check(rpc(owner,'tours_progress',{'p_tour':tour,'p_revision':published['public_revision_id']}) is None and rpc(visitor,'tours_progress',{'p_tour':tour,'p_revision':published['public_revision_id']})['scene_id']==scene2,'visitor progress isolated through authenticated RPC')
    check(not request('/rest/v1/tour_progress?select=revision_id',user=owner).ok,'progress table cannot bypass authenticated RPC')
    # Editing does not replace active snapshot, even for the owner's public list.
    draft=save(owner,tour,document,space)
    check(draft['revision_id']!=published['public_revision_id'] and rpc(visitor,'tours_get',{'p_tour':tour})['revision_id']==published['revision_id'],'draft revision separate from active published version')
    # Recovery clock is deliberately accelerated ONLY for a disposable test job.
    recovery=import_job(owner,tour,str(uuid.uuid4()),panorama.content)
    recoveredlease=next(j for j in backend.rpc('tours_claim_jobs',{}) if j['id']==recovery['id'])
    sql(f"update private.tour_jobs set lease_until=clock_timestamp()-interval '1 second' where id='{recovery['id']}'::uuid and owner_id='{owner['id']}'::uuid returning id")
    reclaimed=next(j for j in backend.rpc('tours_claim_jobs',{}) if j['id']==recovery['id'])
    check(reclaimed['lease_id']!=recoveredlease['lease_id'] and not backend.current(recovery['id'],recoveredlease['lease_id']),'expired lease recovered over real database connections')
    check(run_one(reclaimed,ROOT/'config/.env.tours-local',args.image,config)['state']=='ready','recovered capture finishes through actual container')
    # A transient retry is queued, bounded and processed with a new lease.
    retry=import_job(owner,tour,str(uuid.uuid4()),panorama.content)
    retry_lease=next(j for j in backend.rpc('tours_claim_jobs',{}) if j['id']==retry['id'])
    backend.finish(retry['id'],retry_lease['lease_id'],'retry',error='network')
    check(job(owner,retry['id'])['state']=='queued' and job(owner,retry['id'])['attempts']==1,'transient error requeues instead of claiming success')
    sql(f"update private.tour_jobs set scheduled_at=clock_timestamp() where id='{retry['id']}'::uuid and owner_id='{owner['id']}'::uuid returning id")
    check(cycle(ROOT/'config/.env.tours-local',args.image,config)[0]['state']=='ready','transient retry completes in Docker')
    # New confirmed capture prevents attaching an older panorama for this position.
    replacement=import_job(owner,tour,scene,panorama.content)
    denied(owner,'tours_attach_result',{'p_tour':tour,'p_scene':scene,'p_job':first['id']},'new capture prevents attaching stale panorama')
    replacement_lease=next(j for j in backend.rpc('tours_claim_jobs',{}) if j['id']==replacement['id'])
    # Active write guard forces deletion to defer; cancellation is immediate.
    check(backend.begin_write(replacement['id'],replacement_lease['lease_id']),'test lease output write guard acquired')
    deleting=request('/functions/v1/delete-account',user=owner,method='POST',body={})
    check(deleting.status_code==409,'deletion waits for active output write guard')
    check(not backend.current(replacement['id'],replacement_lease['lease_id']),'deletion immediately invalidates running lease')
    check(not backend.begin_write(replacement['id'],replacement_lease['lease_id']),'deleted account worker cannot restart output writes')
    backend.end_write(replacement['id'],replacement_lease['lease_id'])
    cleanup(owner);owner['cleaned']=True
    check(not backend.finish(replacement['id'],replacement_lease['lease_id'],'succeeded',ready['result']),'deleted account cannot be resurrected by late completion')
    check(sql(f"select count(*)::int n from storage.objects where bucket_id in ('tour-inputs','tour-assets') and split_part(name,'/',1)='{owner['id']}'")[0]['n']==0,'deployed delete-account removed all nested originals and outputs')
    completed=True
finally:
    failures=[]
    for u in users:
        if u.get('cleaned'):continue
        try:cleanup(u);u['cleaned']=True
        except Exception as error:failures.append(type(error).__name__)
    record()
    (out/'live-result.json').write_text(json.dumps({'passed':completed and all(u.get('cleaned') for u in users),'checks':checks,'count':len(checks),'cleanup_complete':all(u.get('cleaned') for u in users),'cleanup_errors':failures,'fixtures':'synthetic geometry; not phone capture or physical AR'},indent=2))
    if failures:print('Cleanup requires retry for disposable checkpoint '+checkpoint.name,flush=True)
if failures:raise RuntimeError('Disposable verification cleanup requires retry; see resource checkpoint')
print(f'Hosted tours verification passed: {len(checks)} checks; disposable accounts cleaned.',flush=True)
