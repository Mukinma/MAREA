#!/usr/bin/env python3
"""E2-A only: fixed new lab, no original volume access or Auth/profile DELETE."""
import collections,datetime,hashlib,json,os,re,secrets,subprocess,sys,time,uuid
from pathlib import Path
from e_diagnostics import MANIFEST,PG,HELPER
from e_inventory import CATALOG,quoted
from e_compare import canonical_catalog
from e1_lab import EXTRA,row_query
ROOT=Path(__file__).resolve().parents[2]
RUN=ROOT/'docs/evidence/2026-10-19/task002/run-20261019T132000Z-e2a'
PRIVATE=Path('/Users/crisis/Proyectos/marea-backups/task002-e2a-20261019T132000Z')
OLD=Path('/Users/crisis/Proyectos/marea-backups/task002-e-20261019T051800Z')
E1=ROOT/'docs/evidence/2026-10-18/task002/run-20261019T055200Z-e1'
E=ROOT/'docs/evidence/2026-10-18/task002/run-20261019T051800Z'
OWNER='task002-e2a-20261019t132000z';LABEL='marea.task002.e2a.owner'
AUTH='sha256:c0c25187a6b835e65a6f6e6c6b39d090e832d40e6de5186f2c038e0411944232'
SQL_NAME='20261019132322_e2a_private_identity.sql'
SQL_PATH=RUN/SQL_NAME
ENV={k:v for k,v in os.environ.items() if k in ['PATH','HOME','LANG','TMPDIR']}
os.umask(0o077)
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def jhash(x):return hashlib.sha256(json.dumps(x,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def save(name,obj):
 p=RUN/name;assert not p.exists(),'No evidence overwrite: '+name
 p.write_text(json.dumps({'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),**obj},indent=2)+'\n')
def private(name,obj): (PRIVATE/name).write_text(json.dumps(obj,sort_keys=True,indent=2))
def docker(*args,input=None,check=True,timeout=120):
 with (PRIVATE/'docker-commands.jsonl').open('a') as f:f.write(json.dumps(list(args))+'\n')
 r=subprocess.run(['docker',*args],input=input,text=True,capture_output=True,env=ENV,timeout=timeout)
 if check and r.returncode:
  f=PRIVATE/f'error-{time.time_ns()}.log';f.write_text(r.stdout+r.stderr);raise RuntimeError('Docker error; private '+f.name)
 return r
def inspect(name,kind=None):return json.loads(docker('inspect',*(['--type',kind] if kind else []),name).stdout)[0]
def dest(name):assert re.fullmatch(re.escape(OWNER)+r'-[ab]-(db|storage|recovery-db|pg|recovery-pg|auth)',name),'Foreign destination refused'
def owned(name):
 dest(name);c=inspect(name);assert c['Config']['Labels'].get(LABEL)==OWNER
 assert c['Image'] in [PG,AUTH] and c['HostConfig']['ReadonlyRootfs'] and not c['HostConfig']['Privileged']
 assert not c['HostConfig'].get('PortBindings') and not c['NetworkSettings']['Ports']
 if c['Image']==PG:
  assert c['HostConfig']['NetworkMode']=='none' and c['Config']['User']=='100:101'
  assert all(m['Name'].startswith(OWNER+'-') and m['Type']=='volume' for m in c['Mounts'])
 else:
  pg=inspect(name.removesuffix('-auth')+'-pg');assert c['HostConfig']['NetworkMode']=='container:'+pg['Id']
  assert not c['Mounts']
 return c
def volume(name):
 dest(name);assert docker('volume','inspect',name,check=False).returncode!=0
 docker('volume','create','--label',LABEL+'='+OWNER,name)
def helper(code,v,args=(),write=False,work_write=False):
 dest(v);assert inspect(v,'volume')['Labels'][LABEL]==OWNER
 return docker('run','--rm','--pull','never','--label',LABEL+'='+OWNER,'--network','none','--read-only','--user','0:0','--cap-drop','ALL','--cap-add','DAC_OVERRIDE','--cap-add','CHOWN','--cap-add','FOWNER','--security-opt','no-new-privileges','--mount',f'type=volume,src={v},dst=/dest'+('' if write else ',readonly'),'--mount',f'type=bind,src={OLD},dst=/old,readonly','--mount',f'type=bind,src={PRIVATE},dst=/work'+('' if work_write else ',readonly'),'--entrypoint','python',HELPER,'-c',code,*args)
def restore(archive,manifest,expected,v,root='/old'):
 source=(OLD if root=='/old' else PRIVATE)/archive
 assert sha(source)==expected['archive_sha256'] and sha(source.parent/manifest)==expected['tree_sha256']
 volume(v)
 code='import pathlib,json,hashlib,tarfile,os,sys\n'+MANIFEST+r'''
root=pathlib.Path('/dest');assert not list(root.iterdir())
with tarfile.open(sys.argv[1]) as t:
 for m in t.getmembers():assert (m.name=='data' or m.name.startswith('data/')) and '..' not in pathlib.PurePosixPath(m.name).parts and not m.issym() and not m.islnk()
 t.extractall('/dest',filter='fully_trusted')
actual=tree(root/'data');assert actual==json.loads(pathlib.Path(sys.argv[2]).read_text())
print(json.dumps({'entries':len(actual),'tree_sha256':hashlib.sha256(json.dumps(actual,sort_keys=True,separators=(',',':')).encode()).hexdigest()}))
'''
 return json.loads(helper(code,v,[root+'/'+archive,root+'/'+manifest],write=True).stdout)
def boot(a,recovery=False):
 name=f'{OWNER}-{a}-'+('recovery-pg' if recovery else 'pg');v=f'{OWNER}-{a}-'+('recovery-db' if recovery else 'db')
 assert inspect(v,'volume')['Labels'][LABEL]==OWNER
 script="printf 'local all all trust\\nhost postgres supabase_auth_admin 127.0.0.1/32 trust\\nhost all all all reject\\n' >/tmp/e2a-hba; touch /tmp/e2a.conf; exec postgres -D /pg/data -c config_file=/tmp/e2a.conf -c hba_file=/tmp/e2a-hba -c listen_addresses=127.0.0.1 -c unix_socket_directories=/tmp -c shared_preload_libraries=pg_stat_statements,pg_cron -c cron.launch_active_jobs=off -c default_transaction_read_only=on -c ssl=off -c archive_mode=off -c max_connections=30"
 docker('run','-d','--pull','never','--name',name,'--label',LABEL+'='+OWNER,'--network','none','--read-only','--user','100:101','--cap-drop','ALL','--security-opt','no-new-privileges','--mount',f'type=volume,src={v},dst=/pg','--tmpfs','/tmp:rw,noexec,nosuid,size=64m,mode=1777','--shm-size','128m','--entrypoint','sh',PG,'-ec',script)
 ready(name);return name
def ready(name):
 for _ in range(80):
  assert owned(name)['State']['Running'],'Lab stopped during readiness'
  if docker('exec',name,'pg_isready','-h','/tmp','-U','supabase_admin','-d','postgres',check=False).returncode==0:return
  time.sleep(.2)
 raise RuntimeError('Readiness precondition failed')
def sql(name,q,write=False,check=True):
 owned(name)
 if not write:q="BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY; SET LOCAL statement_timeout='30s';\n"+q+'\nROLLBACK;'
 return docker('exec','-i',name,'psql','-X','-h','/tmp','-U','supabase_admin','-d','postgres','-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose','-Atq',input=q,check=check)
def val(name,q):return json.loads(sql(name,q).stdout)
def capture(name):
 cat=val(name,CATALOG);settings={x['name']:x['setting'] for x in cat['settings']}
 assert settings['listen_addresses']=='127.0.0.1' and settings['default_transaction_read_only']=='on' and settings['cron.launch_active_jobs']=='off'
 assert 'pg_net' not in settings['shared_preload_libraries'] and cat['safety']=={'cron_runs':0,'vault_secrets':0,'push_enabled':False,'geocoding_enabled':False,'non_synthetic_users':0}
 rows=[];hashes={};seq=[]
 for t in cat['tables']:
  table=quoted(t['schema'])+'.'+quoted(t['name']);label=t['schema']+'.'+t['name']
  if t['relkind']=='S':seq.append({'name':label,**val(name,'SELECT jsonb_build_object(\'last_value\',last_value,\'is_called\',is_called) FROM '+table)});continue
  rows.append(val(name,row_query(table,label)))
  hashes[label]=val(name,"SELECT coalesce(jsonb_agg(encode(sha256(convert_to(to_jsonb(t)::text,'UTF8')),'hex') ORDER BY to_jsonb(t)::text COLLATE \"C\"),'[]') FROM "+table+' t;')
 extra=val(name,EXTRA)
 extra['column_acl']=val(name,"SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY schema,relation,column_name),'[]') FROM (SELECT n.nspname schema,c.relname relation,a.attname column_name,a.attacl::text acl FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE a.attnum>0 AND NOT a.attisdropped AND a.attacl IS NOT NULL AND n.nspname NOT LIKE 'pg_%' AND n.nspname<>'information_schema')x;")
 extra['private_columns']=val(name,"SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY table_name,ordinal_position),'[]') FROM information_schema.columns x WHERE table_schema='collaboration';")
 return {'catalog':cat,'rows':rows,'row_hashes':hashes,'sequences':seq,'extra':extra}
def auth_start(a):
 name=f'{OWNER}-{a}-auth';pg=f'{OWNER}-{a}-pg';owned(pg)
 cfg={'GOTRUE_API_HOST':'127.0.0.1','GOTRUE_API_PORT':'9999','API_EXTERNAL_URL':'http://127.0.0.1:9999','GOTRUE_SITE_URL':'http://127.0.0.1:9999','GOTRUE_DB_DRIVER':'postgres','GOTRUE_DB_DATABASE_URL':'postgres://supabase_auth_admin@127.0.0.1:5432/postgres?sslmode=disable&options=-c%20default_transaction_read_only%3Doff','GOTRUE_DB_CLEANUP_ENABLED':'false','GOTRUE_JWT_SECRET':secrets.token_hex(32),'GOTRUE_JWT_AUD':'authenticated','GOTRUE_JWT_DEFAULT_GROUP_NAME':'authenticated','GOTRUE_JWT_ADMIN_ROLES':'service_role','GOTRUE_JWT_EXP':'60','GOTRUE_EXTERNAL_EMAIL_ENABLED':'true','GOTRUE_DISABLE_SIGNUP':'false','GOTRUE_MAILER_AUTOCONFIRM':'true','GOTRUE_EXTERNAL_ANONYMOUS_USERS_ENABLED':'false','GOTRUE_SMTP_HOST':'127.0.0.1','GOTRUE_SMTP_PORT':'1025','GOTRUE_SMTP_ADMIN_EMAIL':'auth@e2a.invalid','GOTRUE_RATE_LIMIT_EMAIL_SENT':'1000','GOTRUE_RATE_LIMIT_TOKEN_REFRESH':'1000','GOTRUE_SECURITY_CAPTCHA_ENABLED':'false','GOTRUE_LOG_LEVEL':'info'}
 path=PRIVATE/f'{a}-auth.env';path.write_text('\n'.join(k+'='+v for k,v in cfg.items())+'\n')
 docker('run','-d','--pull','never','--name',name,'--label',LABEL+'='+OWNER,'--network','container:'+pg,'--read-only','--user','1000:1000','--cap-drop','ALL','--security-opt','no-new-privileges','--tmpfs','/tmp:rw,noexec,nosuid,size=16m','--env-file',str(path),AUTH)
 for _ in range(40):
  c=owned(name)
  if not c['State']['Running']:
   (PRIVATE/f'{a}-auth-boot.log').write_text(docker('logs',name,check=False).stdout+docker('logs',name,check=False).stderr);raise RuntimeError('Auth startup failed; stop without environment expansion')
  if http(a,'/health',method='GET',check=False)['status']==200:return
  time.sleep(.25)
 raise RuntimeError('Auth health timeout')
def http(a,path,data=None,method='POST',check=True):
 assert path in ['/health','/signup'] and method in ['GET','POST'],'Only signup/health allowed'
 pg=f'{OWNER}-{a}-pg';owned(pg)
 code="""import urllib.request,urllib.error,json,sys,socket
assert [x[1] for x in socket.if_nameindex()]==['lo'],'Non-loopback interface'
x=json.load(sys.stdin);req=urllib.request.Request('http://127.0.0.1:9999'+x['path'],data=json.dumps(x['data']).encode() if x['data'] is not None else None,method=x['method'],headers={'Content-Type':'application/json'})
try:
 r=urllib.request.urlopen(req,timeout=15);status=r.status;body=r.read().decode()
except urllib.error.HTTPError as e:status=e.code;body=e.read().decode()
except Exception as e:status=0;body=type(e).__name__
try:body=json.loads(body)
except ValueError:pass
print(json.dumps({'status':status,'body':body}))
"""
 r=docker('run','--rm','-i','--pull','never','--label',LABEL+'='+OWNER,'--network','container:'+pg,'--read-only','--user','1000:1000','--cap-drop','ALL','--security-opt','no-new-privileges','--entrypoint','python',HELPER,'-c',code,input=json.dumps({'path':path,'data':data,'method':method}))
 return json.loads(r.stdout)
def cold_backup(a):
 pg=f'{OWNER}-{a}-pg';owned(pg);docker('stop','--time','30',pg)
 code='import pathlib,json,hashlib,tarfile,os,sys\n'+MANIFEST+r'''
root=pathlib.Path('/dest/data');before=tree(root)
with tarfile.open('/work/'+sys.argv[1],'w',format=tarfile.PAX_FORMAT) as t:t.add(root,arcname='data')
assert before==tree(root)
out=pathlib.Path('/work/'+sys.argv[1]+'.manifest.json');out.write_text(json.dumps(before,sort_keys=True,separators=(',',':')))
print(json.dumps({'archive_sha256':hashlib.sha256(pathlib.Path('/work/'+sys.argv[1]).read_bytes()).hexdigest(),'tree_sha256':hashlib.sha256(out.read_bytes()).hexdigest()}))
'''
 archive=f'{a}-E1-reproduced-cold.tar';backup=json.loads(helper(code,f'{OWNER}-{a}-db',[archive],work_write=True).stdout)
 restore(archive,archive+'.manifest.json',backup,f'{OWNER}-{a}-recovery-db',root='/work')
 docker('start',pg);ready(pg);recovery=boot(a,True)
 before=capture(pg);assert capture(recovery)==before
 owned(recovery);docker('stop','--time','30',recovery)
 return backup
def preflight():
 assert PRIVATE.stat().st_mode&0o077==0 and docker('context','inspect','--format','{{.Endpoints.docker.Host}}').stdout.strip()=='unix:///Users/crisis/.docker/run/docker.sock'
 assert docker('version','--format','{{.Server.Version}}').stdout.strip()=='29.8.2' and not docker('ps','-q').stdout.strip()
 for img in [PG,AUTH,HELPER]:assert inspect(img,'image')['Id']==img
 assert sha(E/'04-cold-backup-restore.json')=='d46b994aa2a332d789b8d8ab4ee3755664aaebba01fce3ec8a65f858d9ae7ef5'
 archives=json.loads((E/'04-cold-backup-restore.json').read_text())['sources']
 execution=json.loads((E1/'04-transactional-execution.json').read_text())['sources']
 for a in ['a','b']:
  assert sha(E1/f'E1-LAB-{a.upper()}-EXECUTABLE.sql')==execution[a]['sql_sha256']
  for kind in ['db','storage']:
   assert sha(OLD/f'{a}-{kind}-cold.tar')==archives[a][kind]['backup']['archive_sha256']
   assert sha(OLD/f'{a}-{kind}-cold.tar.manifest.json')==archives[a][kind]['backup']['tree_sha256']
 ids=docker('ps','-aq').stdout.split();old=json.loads(docker('inspect',*ids).stdout) if ids else []
 private('previous-containers.json',[{k:c[k] for k in ['Id','Name','State','Mounts','Image']} for c in old])
 save('01-preflight.json',{'result':'PASS','local_socket':True,'docker':'29.8.2','running_before':0,'pinned_images':[PG,AUTH,HELPER],'original_volume_access':False,'archives_and_E1_SQL_verified':True})
 return archives
def bootstrap():
 archives=preflight();result={}
 for a in ['a','b']:
  for kind in ['db','storage']:restore(f'{a}-{kind}-cold.tar',f'{a}-{kind}-cold.tar.manifest.json',archives[a][kind]['backup'],f'{OWNER}-{a}-{kind}')
  pg=boot(a);s=capture(pg);expected=json.loads((OLD/f'{a}-effective-v2-private.json').read_text())
  cat=json.loads(json.dumps(s['catalog']))
  for setting in cat['settings']:
   if setting['name']=='listen_addresses':setting['setting']=''
  assert {k:s[k] for k in ['rows','sequences']}=={k:expected[k] for k in ['rows','sequences']}
  assert cat==expected['catalog'],'Cold source catalog drift'
  q=(E1/f'E1-LAB-{a.upper()}-EXECUTABLE.sql').read_text();sql(pg,q,write=True)
  s=capture(pg);hist=json.loads((Path('/Users/crisis/Proyectos/marea-backups/task002-e1-20261019T055200Z')/f'{a}-after.json').read_text())
  hc=json.loads(json.dumps(hist['catalog']))
  for setting in hc['settings']:
   if setting['name']=='listen_addresses':setting['setting']='127.0.0.1'
  assert canonical_catalog(s['catalog'])==canonical_catalog(hc),'E1 catalog mismatch'
  assert [x for x in s['rows'] if x['table']!='collaboration.persons']==[x for x in hist['rows'] if x['table']!='collaboration.persons']
  assert val(pg,"SELECT count(*) FROM collaboration.persons p JOIN auth.users u ON u.id=p.auth_user_id WHERE p.id=p.auth_user_id;")==6
  backup=cold_backup(a);private(f'{a}-E1-base.json',capture(pg));auth_start(a)
  assert capture(pg)==json.loads((PRIVATE/f'{a}-E1-base.json').read_text()),'Auth startup changed baseline before fixtures'
  result[a]={'E1_catalog_and_legacy_data_match':True,'new_created_at_declared':True,'new_E1_backup_restored_exactly':backup,'Auth_health':200,'network':'none; shared loopback only; no published ports','auth_cleanup_enabled':False}
 save('02-new-E1-baseline-and-recovery.json',{'result':'PASS','sources':result})
 print('Two new E1 baselines verified; their cold backups restored on new recovery clones. Auth healthy in loopback-only namespaces.',flush=True)
def signup(a,label,metadata_overrides=None):
 pg=f'{OWNER}-{a}-pg';policy=val(pg,'SELECT public.registration_policy();')
 meta={'full_name':'Synthetic E2A '+label,'username':'e2a_'+a+'_'+label.replace('-','_'),'user_type':'Artista / creador','registration_flow':'minimal-v1','adult_confirmed':True,'accepted_terms':True,'terms_version':policy['terms']['version'],'privacy_version':policy['privacy']['version']}
 meta.update(metadata_overrides or {});payload={'email':f'{a}-{label}@e2a132000.invalid','password':secrets.token_urlsafe(24),'data':meta}
 before=val(pg,'SELECT last_value FROM public.legal_acceptances_id_seq;');r=http(a,'/signup',payload)
 after=val(pg,'SELECT last_value FROM public.legal_acceptances_id_seq;')
 private(f'{a}-signup-{label}.json',{'request':payload,'response':r,'legal_sequence_delta':after-before})
 return r,payload,after-before
def red():
 results={}
 for a in ['a','b']:
  r,_,delta=signup(a,'red-valid');assert r['status']==200 and r['body'].get('user',{}).get('id')
  id=r['body']['user']['id'];pg=f'{OWNER}-{a}-pg';actual=val(pg,f"SELECT count(*) FROM collaboration.persons WHERE auth_user_id='{id}';")
  assert actual==0,'Feature unexpectedly present before implementation'
  results[a]={'test':'E2-T02 Auth signup creates principal','result':'EXPECTED_RED','HTTP':200,'expected_principals':1,'actual_principals':actual,'legal_sequence_delta':delta}
 save('03-T02-RED.json',{'result':'EXPECTED_RED','sources':results,'fixture_Auth_inserts_authorized':True})
 print('RED verified through real Auth signup: baseline creates no principal; fixture users retained, never deleted.',flush=True)
def stop(receipt_name='99-close.json'):
 results=[]
 for a in ['a','b']:
  for suffix in ['auth','pg','recovery-pg']:
   name=f'{OWNER}-{a}-{suffix}'
   if docker('inspect',name,check=False).returncode:continue
   c=owned(name)
   if c['State']['Running']:docker('stop','--time','30',name)
   c=owned(name);assert not c['State']['Running'];r=docker('logs',name,check=False);(PRIVATE/(name+'-server.log')).write_text(r.stdout+r.stderr);results.append({'name':name,'stopped':True})
 for old in json.loads((PRIVATE/'previous-containers.json').read_text()):assert {k:inspect(old['Id'])[k] for k in old}==old,'Previous container metadata changed'
 save(receipt_name,{'result':'PASS','stopped':results,'previous_container_metadata_unchanged':True,'original_volumes_accessed':False,'all_new_volumes_retained':True})
if __name__=='__main__':
 try:
  if sys.argv[1:]==['bootstrap']:bootstrap()
  elif sys.argv[1:]==['red']:red()
  elif sys.argv[1:]==['stop']:stop()
  else:raise SystemExit('bootstrap | red | stop')
 except Exception as ex:
  save('FAILURE-'+str(time.time_ns())+'.json',{'result':'FAIL_STOPPED','error':str(ex),'no_scope_expansion':True})
  if (PRIVATE/'previous-containers.json').exists():stop('STOP-AFTER-FAILURE-'+str(time.time_ns())+'.json')
  raise
