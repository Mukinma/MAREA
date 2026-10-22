#!/usr/bin/env python3
"""New E2-A executor. No imports/calls/unlocking of the historical executor."""
import datetime,hashlib,json,os,re,secrets,subprocess,sys,time,tarfile
from pathlib import Path
from e_diagnostics import MANIFEST,PG,HELPER
from e_inventory import CATALOG,quoted
from e_compare import canonical_catalog
from e1_lab import EXTRA,row_query
from e2a_isolation import capture_empty,validate_pair,validate_snapshot,require,canonical_netlink,policy
ROOT=Path(__file__).resolve().parents[2]
RUN=ROOT/'docs/evidence/2026-10-19/task002/run-20261019T140102Z-e2a-r2'
PRIVATE=Path('/Users/crisis/Proyectos/marea-backups/task002-e2a-r2-20261019T140102Z')
BACKUPS=Path('/Users/crisis/Proyectos/marea-backups/task002-e-20261019T051800Z')
E=ROOT/'docs/evidence/2026-10-18/task002/run-20261019T051800Z'
E1=ROOT/'docs/evidence/2026-10-18/task002/run-20261019T055200Z-e1'
ISO=ROOT/'docs/evidence/2026-10-19/task002/run-20261019T133800Z-isolation'
OWNER='task002-e2a-r2-20261019t140102z';LABEL='marea.e2a.r2.owner'
AUTH='sha256:c0c25187a6b835e65a6f6e6c6b39d090e832d40e6de5186f2c038e0411944232'
ENDPOINT='unix:///Users/crisis/.docker/run/docker.sock'
ENV={k:v for k,v in os.environ.items() if k in ['PATH','HOME','LANG','TMPDIR']}
os.umask(0o077)
def sha(p):
 h=hashlib.sha256()
 with Path(p).open('rb') as f:
  for b in iter(lambda:f.read(1048576),b''):h.update(b)
 return h.hexdigest()
def save(name,obj):
 p=RUN/name;require(not p.exists(),'Receipt exists: '+name);p.write_text(json.dumps({'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),**obj},indent=2)+'\n')
def private(name,obj):
 p=PRIVATE/name;require(not p.exists(),'Private snapshot exists');p.write_text(json.dumps(obj,sort_keys=True,indent=2)+'\n')
def docker(*args,input=None,check=True,binary=False,timeout=120):
 with (PRIVATE/'docker-commands.jsonl').open('a') as f:f.write(json.dumps(list(args))+'\n')
 r=subprocess.run(['docker','--host',ENDPOINT,*args],input=input,text=not binary,capture_output=True,env=ENV,timeout=timeout)
 if check and r.returncode:
  p=PRIVATE/f'error-{time.time_ns()}.log';p.write_bytes((r.stdout+r.stderr) if binary else (r.stdout+r.stderr).encode());raise RuntimeError('Docker failure: '+p.name)
 return r
def inspect(name,kind=None):return json.loads(docker('inspect',*(['--type',kind] if kind else []),name).stdout)[0]
def dtext(*args):return docker(*args).stdout
def preflight_before_data(empty,full,data):
 for check in [empty,full]:
  receipt=check();require(isinstance(receipt,dict) and receipt.get('result')=='PASS','preflight not proven')
 return data()
def require_full_preflight():
 require(not list(RUN.glob('FAILURE-*.json')),'E2-A stopped after integrity failure; new authorization and new run required')
 p=RUN/'02-full-preflight.json';require(p.exists(),'Complete preflight required before data/service')
 x=json.loads(p.read_text());require(x['result']=='PASS' and x['endpoint']==ENDPOINT,'Invalid preflight')
 require(sha(RUN/'01-empty-preflight.json')==x['empty_receipt_sha256'],'Empty preflight changed')
 for path,h in x['verifier_hashes'].items():require(sha(ROOT/path)==h,'Verifier drift')
 require(sha(__file__)==x['executor_sha256'],'Executor drift')
 return x

def base_args(name,network,user='1000:1000',image=HELPER):
 require(name.startswith(OWNER+'-'),'Foreign container refused')
 return ['--pull','never','--name',name,'--label',LABEL+'='+OWNER,'--network',network,'--read-only','--user',user,'--cap-drop','ALL','--security-opt','no-new-privileges']
def empty_preflight():
 require(PRIVATE.stat().st_mode&0o077==0,'Private dir permissions')
 require(dtext('version','--format','{{.Server.Version}}').strip()=='29.8.2','Docker drift')
 require(not dtext('ps','-q').strip(),'Unexpected running containers')
 for im in [PG,AUTH,HELPER]:require(inspect(im,'image')['Id']==im,'Pinned image missing')
 for path,h in json.loads((ISO/'20-verifier-source-manifest.json').read_text()).items():require(sha(ROOT/path)==h,'Approved verifier/historical guard changed')
 a=OWNER+'-empty-anchor';s=OWNER+'-empty-shared';i=OWNER+'-empty-independent'
 for name,mode in [(a,'none'),(s,'container:'+a),(i,'none')]:
  args=base_args(name,mode)
  if mode=='none':args+=['--sysctl','net.ipv4.ip_forward=0','--sysctl','net.ipv6.conf.all.forwarding=0']
  docker('run','-d',*args,'--entrypoint','python',HELPER,'-c','import time;time.sleep(1800)')
 captured={name:capture_empty(name,dtext) for name in [a,s,i]};private('empty-capture.json',captured)
 pair=validate_pair(captured[a],captured[s]);ind=validate_snapshot(captured[i],'none')
 require(captured[a]['kernel']['netns']!=captured[i]['kernel']['netns'],'Independent namespace collision')
 for name in [s,a,i]:docker('stop','--time','2',name)
 x={'result':'PASS','pair':pair,'independent':ind,'before_any_restore_or_product_service':True,'no_mounts':True,'no_added_capabilities':True,'Auth_Postgres_started':False}
 save('01-empty-preflight.json',x);return x

def full_preflight():
 require(not dtext('ps','-q').strip(),'Preflight helpers not stopped')
 require(sha(E/'04-cold-backup-restore.json')=='d46b994aa2a332d789b8d8ab4ee3755664aaebba01fce3ec8a65f858d9ae7ef5','Backup receipt drift')
 sources=json.loads((E/'04-cold-backup-restore.json').read_text())['sources'];e1=json.loads((E1/'04-transactional-execution.json').read_text())['sources']
 for a in ['a','b']:
  require(sha(E1/f'E1-LAB-{a.upper()}-EXECUTABLE.sql')==e1[a]['sql_sha256'],'E1 SQL drift')
  for kind in ['db','storage']:
   require(sha(BACKUPS/f'{a}-{kind}-cold.tar')==sources[a][kind]['backup']['archive_sha256'],'Backup digest drift')
   require(sha(BACKUPS/f'{a}-{kind}-cold.tar.manifest.json')==sources[a][kind]['backup']['tree_sha256'],'Backup manifest drift')
 all_ids=dtext('ps','-aq').split();all_containers=json.loads(dtext('inspect',*all_ids)) if all_ids else []
 previous=[c for c in all_containers if not c['Name'].startswith('/'+OWNER+'-')]
 private('previous-containers.json',[{k:c[k] for k in ['Id','Name','State','Mounts','Image']} for c in previous])
 private('previous-volumes.json',sorted(dtext('volume','ls','-q').split()))
 x={'result':'PASS','endpoint':ENDPOINT,'empty_receipt_sha256':sha(RUN/'01-empty-preflight.json'),'verifier_hashes':json.loads((ISO/'20-verifier-source-manifest.json').read_text()),'executor_sha256':sha(__file__),'backup_and_E1_SQL_hashes_verified':True,'original_volumes_mounted':False}
 save('02-full-preflight.json',x);return x

def owned(name):
 require(name.startswith(OWNER+'-'),'Foreign destination');c=inspect(name);h=c['HostConfig']
 require(c['Config']['Labels'].get(LABEL)==OWNER and c['Image'] in [PG,AUTH,HELPER],'Owner/image mismatch')
 require(h['ReadonlyRootfs'] and not h['Privileged'] and h['CapDrop']==['ALL'] and not h.get('CapAdd') and h['SecurityOpt']==['no-new-privileges'],'Unsafe permissions')
 require(not h.get('PortBindings') and not c['NetworkSettings']['Ports'] and not h['PublishAllPorts'],'Published ports')
 for m in c['Mounts']:require(m['Type']=='volume' and m['Name'].startswith(OWNER+'-') and inspect(m['Name'],'volume')['Labels'][LABEL]==OWNER,'Foreign mount')
 if h['NetworkMode']=='none':require(h['Sysctls']=={'net.ipv4.ip_forward':'0','net.ipv6.conf.all.forwarding':'0'},'Forwarding config')
 else:
  require(h['NetworkMode'].startswith('container:'),'Network not isolated')
  parent=inspect(h['NetworkMode'].split(':',1)[1]);require(parent['Name'].startswith('/'+OWNER+'-') and parent['HostConfig']['NetworkMode']=='none','Foreign/unsafe namespace')
 return c

def copier(volume,user):
 name=volume+'-copy';require_full_preflight();require(docker('volume','inspect',volume,check=False).returncode!=0,'Volume exists')
 docker('volume','create','--label',LABEL+'='+OWNER,volume)
 docker('run','-d',*base_args(name,'none',user),'--sysctl','net.ipv4.ip_forward=0','--sysctl','net.ipv6.conf.all.forwarding=0','--mount',f'type=volume,src={volume},dst=/dest','--entrypoint','python',HELPER,'-c','import time;time.sleep(7200)');owned(name);return name

def volume_tree(name):
 owned(name);return json.loads(dtext('exec',name,'python','-c','import pathlib,hashlib,json,os\n'+MANIFEST+"\nprint(json.dumps(tree(pathlib.Path('/dest/data')),sort_keys=True))"))
def restore(archive,manifest,volume,user):
 require_full_preflight()
 with tarfile.open(archive) as t:
  for m in t:
   require((m.name=='data' or m.name.startswith('data/')) and '..' not in Path(m.name).parts and not m.issym() and not m.islnk(),'Invalid backup member')
 name=copier(volume,user)
 require(json.loads(dtext('exec',name,'python','-c',"import os,json;print(json.dumps(os.listdir('/dest')))"))==[],'Destination not empty')
 with Path(archive).open('rb') as f:
  # Bounded streaming by subprocess stdin; no archive bytes in Python memory/logs.
  with (PRIVATE/'docker-commands.jsonl').open('a') as log:log.write(json.dumps(['cp','-a','-',name+':/dest'])+'\n')
  r=subprocess.run(['docker','--host',ENDPOINT,'cp','-a','-',name+':/dest'],stdin=f,capture_output=True,env=ENV,timeout=120)
 require(r.returncode==0,'Archive copy failed')
 require(volume_tree(name)==json.loads(Path(manifest).read_text()),'Restored tree mismatch')
 return name

def boot(a,recovery=False,volume_name=None,instance=None):
 require_full_preflight();name=instance or f'{OWNER}-{a}-'+('recovery-pg' if recovery else 'pg');v=volume_name or f'{OWNER}-{a}-'+('recovery-db' if recovery else 'db')
 require(inspect(v,'volume')['Labels'][LABEL]==OWNER,'Volume ownership')
 script="printf 'local all all trust\\nhost postgres supabase_auth_admin 127.0.0.1/32 trust\\nhost all all all reject\\n' >/tmp/e2a-hba; touch /tmp/e2a.conf; exec postgres -D /pg/data -c config_file=/tmp/e2a.conf -c hba_file=/tmp/e2a-hba -c listen_addresses=127.0.0.1 -c unix_socket_directories=/tmp -c shared_preload_libraries=pg_stat_statements,pg_cron -c cron.launch_active_jobs=off -c default_transaction_read_only=on -c ssl=off -c archive_mode=off -c max_connections=30"
 docker('run','-d',*base_args(name,'none','100:101'),'--sysctl','net.ipv4.ip_forward=0','--sysctl','net.ipv6.conf.all.forwarding=0','--mount',f'type=volume,src={v},dst=/pg','--tmpfs','/tmp:rw,noexec,nosuid,size=64m,mode=1777','--shm-size','128m','--entrypoint','sh',PG,'-ec',script)
 ready(name);return name

def ready(name):
 for _ in range(80):
  require(owned(name)['State']['Running'],'Service stopped')
  if docker('exec',name,'pg_isready','-h','/tmp','-U','supabase_admin','-d','postgres',check=False).returncode==0:return
  time.sleep(.2)
 raise RuntimeError('Postgres readiness failure')
def sql(name,q,write=False,check=True):
 require_full_preflight();owned(name)
 require(not re.search(r'(?is)\b(delete\s+from\s+(auth\.users|public\.profiles)|truncate)\b',q),'Out-of-scope deletion')
 if not write:q="BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY;SET LOCAL statement_timeout='30s';\n"+q+'\nROLLBACK;'
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

def runtime_net(a,ports):
 from e2a_r2_network import validate_runtime
 pg=f'{OWNER}-{a}-pg';anchor=owned(pg);name=f'{OWNER}-{a}-probe'
 if docker('inspect',name,check=False).returncode:
  docker('run','-d',*base_args(name,'container:'+pg),'--entrypoint','python',HELPER,'-c','import time;time.sleep(7200)')
 owned(name)
 # capture_empty captures filesystem-free helper; validator permits only named loopback services.
 x=capture_empty(name,dtext);result=validate_runtime(x,anchor,ports)
 actual=dtext('exec',pg,'readlink','/proc/self/ns/net').strip();require(actual==result['netns'],'PG/probe namespace mismatch')
 private('network-'+a+'-'+str(time.time_ns())+'.json',{'snapshot':x,'result':result});return result

def cold_backup(a,label):
 pg=f'{OWNER}-{a}-pg';owned(pg);expected=capture(pg);docker('stop','--time','30',pg)
 copy=f'{OWNER}-{a}-db-copy';owned(copy);before=volume_tree(copy)
 archive=PRIVATE/f'{a}-{label}.tar'
 with archive.open('xb') as f:
  with (PRIVATE/'docker-commands.jsonl').open('a') as log:log.write(json.dumps(['cp','-a',copy+':/dest/data','-'])+'\n')
  r=subprocess.run(['docker','--host',ENDPOINT,'cp','-a',copy+':/dest/data','-'],stdout=f,stderr=subprocess.PIPE,env=ENV,timeout=120)
 require(r.returncode==0 and before==volume_tree(copy),'Backup not stable')
 manifest=PRIVATE/f'{a}-{label}.manifest.json';manifest.write_text(json.dumps(before,sort_keys=True,separators=(',',':')))
 recvol=f'{OWNER}-{a}-'+label+'-recovery-db';restore(archive,manifest,recvol,'100:101')
 # Same boot method on a fresh destination, never a historical container.
 name=f'{OWNER}-{a}-{label}-recovery-pg';require(docker('inspect',name,check=False).returncode!=0,'Recovery name already exists')
 recovery=boot(a,True,volume_name=recvol,instance=name);require(capture(recovery)==expected,'Recovery catalog/data mismatch');docker('stop','--time','30',recovery)
 return {'archive_sha256':sha(archive),'manifest_sha256':sha(manifest),'tree_verified_on_new_volume':recvol,'restored_Postgres_booted_and_logical_snapshot_equal':True}

def bootstrap():
 require_full_preflight();sources=json.loads((E/'04-cold-backup-restore.json').read_text())['sources'];results={}
 for a in ['a','b']:
  for kind,user in [('db','100:101'),('storage','0:0')]:restore(BACKUPS/f'{a}-{kind}-cold.tar',BACKUPS/f'{a}-{kind}-cold.tar.manifest.json',f'{OWNER}-{a}-{kind}',user)
  pg=boot(a);runtime_net(a,{5432});s=capture(pg);baseline=json.loads((BACKUPS/f'{a}-effective-v2-private.json').read_text())
  cat=json.loads(json.dumps(s['catalog']))
  for setting in cat['settings']:
   if setting['name']=='listen_addresses':setting['setting']=''
  require({k:s[k] for k in ['rows','sequences']}=={k:baseline[k] for k in ['rows','sequences']} and cat==baseline['catalog'],'Source catalog/data drift')
  sql(pg,(E1/f'E1-LAB-{a.upper()}-EXECUTABLE.sql').read_text(),write=True)
  s=capture(pg);hist=json.loads((Path('/Users/crisis/Proyectos/marea-backups/task002-e1-20261019T055200Z')/f'{a}-after.json').read_text());hc=json.loads(json.dumps(hist['catalog']))
  for setting in hc['settings']:
   if setting['name']=='listen_addresses':setting['setting']='127.0.0.1'
  require(canonical_catalog(s['catalog'])==canonical_catalog(hc),'E1 catalog drift')
  require([r for r in s['rows'] if r['table']!='collaboration.persons']==[r for r in hist['rows'] if r['table']!='collaboration.persons'],'E1 legacy drift')
  require(val(pg,'SELECT count(*) FROM collaboration.persons p JOIN auth.users u ON u.id=p.auth_user_id WHERE p.id=p.auth_user_id;')==6,'E1 identities')
  private(a+'-E1-base.json',s);backup=cold_backup(a,'E1-verified')
  # Recovery is validated byte-for-byte before any increment DDL. Restart only this new PG.
  docker('start',pg);ready(pg);require(capture(pg)==s,'Backup/restart changed baseline')
  results[a]={'E1_reproduced':True,'new_created_at_declared':True,'legacy_and_catalog_match':True,'backup_restore':backup,'storage_tree_preserved':True}
 save('03-new-E1-baselines.json',{'result':'PASS','sources':results,'Auth_started':False,'E2A_DDL_applied':False})

def auth_start(a):
 require_full_preflight();runtime_net(a,{5432});pg=f'{OWNER}-{a}-pg';name=f'{OWNER}-{a}-auth'
 cfg={'GOTRUE_API_HOST':'127.0.0.1','GOTRUE_API_PORT':'9999','API_EXTERNAL_URL':'http://127.0.0.1:9999','GOTRUE_SITE_URL':'http://127.0.0.1:9999','GOTRUE_DB_DRIVER':'postgres','GOTRUE_DB_DATABASE_URL':'postgres://supabase_auth_admin@127.0.0.1:5432/postgres?sslmode=disable&options=-c%20default_transaction_read_only%3Doff','GOTRUE_DB_CLEANUP_ENABLED':'false','GOTRUE_JWT_SECRET':secrets.token_hex(32),'GOTRUE_JWT_AUD':'authenticated','GOTRUE_JWT_DEFAULT_GROUP_NAME':'authenticated','GOTRUE_JWT_ADMIN_ROLES':'service_role','GOTRUE_JWT_EXP':'60','GOTRUE_EXTERNAL_EMAIL_ENABLED':'true','GOTRUE_DISABLE_SIGNUP':'false','GOTRUE_MAILER_AUTOCONFIRM':'true','GOTRUE_EXTERNAL_ANONYMOUS_USERS_ENABLED':'false','GOTRUE_SMTP_HOST':'127.0.0.1','GOTRUE_SMTP_PORT':'1025','GOTRUE_SMTP_ADMIN_EMAIL':'auth@e2a.invalid','GOTRUE_RATE_LIMIT_EMAIL_SENT':'1000','GOTRUE_RATE_LIMIT_TOKEN_REFRESH':'1000','GOTRUE_SECURITY_CAPTCHA_ENABLED':'false','GOTRUE_LOG_LEVEL':'info'}
 path=PRIVATE/(a+'-auth.env');require(not path.exists(),'Auth env exists');path.write_text('\n'.join(k+'='+v for k,v in cfg.items())+'\n')
 docker('run','-d',*base_args(name,'container:'+pg),'--tmpfs','/tmp:rw,noexec,nosuid,size=16m','--env-file',str(path),'--entrypoint','auth',AUTH)
 for _ in range(40):
  require(owned(name)['State']['Running'],'Auth startup failed')
  if http(a,'/health',method='GET')['status']==200:return
  time.sleep(.25)
 raise RuntimeError('Auth health failure')

def http(a,path,data=None,method='POST'):
 require_full_preflight();require(path in ['/health','/signup'] and method in ['GET','POST'],'Only signup/health HTTP')
 runtime_net(a,{5432,9999});pg=f'{OWNER}-{a}-pg'
 code="""import urllib.request,urllib.error,json,sys
x=json.load(sys.stdin);req=urllib.request.Request('http://127.0.0.1:9999'+x['path'],data=json.dumps(x['data']).encode() if x['data'] is not None else None,method=x['method'],headers={'Content-Type':'application/json'})
try:
 r=urllib.request.urlopen(req,timeout=15);status=r.status;body=r.read().decode()
except urllib.error.HTTPError as e:status=e.code;body=e.read().decode()
except Exception as e:status=0;body=type(e).__name__
try:body=json.loads(body)
except ValueError:pass
print(json.dumps({'status':status,'body':body}))
"""
 # Isolated ephemeral HTTP helper, no mounted files, no network except PG namespace.
 r=docker('run','--rm','-i','--pull','never','--label',LABEL+'='+OWNER,'--network','container:'+pg,'--read-only','--user','1000:1000','--cap-drop','ALL','--security-opt','no-new-privileges','--entrypoint','python',HELPER,'-c',code,input=json.dumps({'path':path,'data':data,'method':method}))
 return json.loads(r.stdout)

def signup(a,label,overrides=None,standard=False):
 pg=f'{OWNER}-{a}-pg';p=val(pg,'SELECT public.registration_policy();')
 meta={'full_name':'Synthetic E2A '+label,'username':'r2_'+a+'_'+label.replace('-','_'),'user_type':'Artista / creador','adult_confirmed':True,'accepted_terms':True,'terms_version':p['terms']['version'],'privacy_version':p['privacy']['version']}
 if not standard:meta['registration_flow']='minimal-v1'
 meta.update(overrides or {});body={'email':f'{a}-{label}@e2ar2.invalid','password':secrets.token_urlsafe(24),'data':meta}
 before=capture(pg);response=http(a,'/signup',body);after=capture(pg)
 private(a+'-signup-'+label+'.json',{'request':body,'response':response,'before':before,'after':after})
 return response,body,before,after

def stop():
 stopped=[]
 for i in dtext('ps','-aq','--filter','label='+LABEL+'='+OWNER).split():
  c=inspect(i);require(c['Name'].startswith('/'+OWNER+'-') and c['Image'] in [PG,AUTH,HELPER],'Foreign stop')
  if c['State']['Running']:docker('stop','--time','10',i)
  stopped.append({'name':c['Name'],'stopped':not inspect(i)['State']['Running']})
 return stopped

if __name__=='__main__':
 try:
  if sys.argv[1:]==['preflight']:preflight_before_data(empty_preflight,full_preflight,lambda:print('PASS empty/full gates; no data restored'))
  elif sys.argv[1:]==['bootstrap']:bootstrap()
  elif sys.argv[1:]==['stop']:save('99-stopped.json',{'result':'PASS','containers':stop()})
  else:raise SystemExit('preflight | bootstrap | stop')
 except Exception as e:
  save('FAILURE-'+str(time.time_ns())+'.json',{'result':'FAIL_STOPPED','error':str(e),'no_scope_expansion':True})
  stop();raise
