#!/usr/bin/env python3
"""TASK-002 E diagnostics only. Cold copy of known local TASK001 fixtures; no proposed DDL."""
import os,json,subprocess,hashlib,datetime,time,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
RUN=ROOT/'docs/evidence/2026-10-18/task002/run-20261019T051800Z'
PRIVATE=Path('/Users/crisis/Proyectos/marea-backups/task002-e-20261019T051800Z')
OWNER='task002-e-20261019t051800z'
HELPER=json.loads((ROOT/'tool/staging/network-image.lock.json').read_text())['image_id']
PG=json.loads((ROOT/'tool/staging/images.lock.json').read_text())['images'][0]['id']
SOURCES={'a':'marea-task001-d7522760bb90','b':'marea-task001-fd0edb3330b2'}
os.umask(0o077)
ENV={k:v for k,v in os.environ.items() if k in ['PATH','HOME','LANG','TMPDIR']}
def docker(*args,input=None,binary=False,timeout=120,check=True):
 r=subprocess.run(['docker',*args],input=input,capture_output=True,text=not binary,env=ENV,timeout=timeout)
 if check and r.returncode:
  stamp=str(time.time_ns());(PRIVATE/('error-'+stamp+'.log')).write_bytes(r.stderr if binary else r.stderr.encode());raise RuntimeError('Docker operation failed; private error '+stamp)
 return r

def inspect(name,kind=None):
 args=['inspect']+(['--type',kind] if kind else [])+[name];return json.loads(docker(*args).stdout)[0]
def owned(name):
 assert name.startswith(OWNER+'-');c=inspect(name);assert c['Config']['Labels'].get('marea.task002.owner')==OWNER;assert c['Image']==PG;assert c['HostConfig']['NetworkMode']=='none' and not c['HostConfig'].get('PortBindings');assert not c['HostConfig']['Privileged'];return c

def guard():
 assert docker('context','inspect','--format','{{.Endpoints.docker.Host}}').stdout.strip()=='unix:///Users/crisis/.docker/run/docker.sock'
 assert docker('version','--format','{{.Server.Version}}').stdout.strip()=='29.8.2'
 for img in [HELPER,PG]:assert inspect(img,'image')['Id']==img
 assert PRIVATE.is_dir() and PRIVATE.stat().st_mode&0o077==0

def volume(name):
 assert name.startswith(OWNER+'-');assert docker('volume','inspect',name,check=False).returncode!=0
 docker('volume','create','--label','marea.task002.owner='+OWNER,name)

def helper(code,mounts,args=()):
 return docker('run','--rm','--pull','never','--network','none','--read-only','--user','0:0','--cap-drop','ALL','--cap-add','DAC_OVERRIDE','--cap-add','CHOWN','--cap-add','FOWNER','--security-opt','no-new-privileges',*[a for m in mounts for a in ['--mount',m]],'--entrypoint','python',HELPER,'-c',code,*args)

MANIFEST=r'''
def tree(root):
 rows=[]
 for p in sorted(root.rglob('*')):
  st=p.lstat();row={'path':str(p.relative_to(root)),'mode':st.st_mode&0o7777,'uid':st.st_uid,'gid':st.st_gid,'mtime':round(st.st_mtime,6)}
  if p.is_symlink():row.update(type='link',target=os.readlink(p))
  elif p.is_file():
   h=hashlib.sha256()
   with p.open('rb') as f:
    for b in iter(lambda:f.read(1048576),b''):h.update(b)
   row.update(type='file',size=st.st_size,sha256=h.hexdigest())
  elif p.is_dir():row.update(type='directory')
  else:raise RuntimeError('Special file in backup')
  rows.append(row)
 return rows
'''
def export_volume(source,destfile):
 assert source in [p+s for p in ['supabase_db_','supabase_storage_'] for s in SOURCES.values()]
 cs=json.loads((PRIVATE/'docker-before-private.json').read_text())
 for c in cs:
  if any(m.get('Name')==source and m.get('RW') for m in c['Mounts']):assert not inspect(c['Id'])['State']['Running']
 assert not (PRIVATE/destfile).exists()
 code="import pathlib,json,hashlib,tarfile,os,sys\n"+MANIFEST+r'''
root=pathlib.Path('/source');before=tree(root)
assert not any(x['type']=='link' for x in before),'External links need explicit backup review'
with tarfile.open('/backup/'+sys.argv[1],'w',format=tarfile.PAX_FORMAT) as t:t.add(root,arcname='data',recursive=True)
after=tree(root);assert before==after
out=pathlib.Path('/backup/'+sys.argv[1]+'.manifest.json');out.write_text(json.dumps(before,sort_keys=True,separators=(',',':')))
h=hashlib.sha256()
with open('/backup/'+sys.argv[1],'rb') as f:
 for b in iter(lambda:f.read(1048576),b''):h.update(b)
print(json.dumps({'result':'PASS','entries':len(before),'files':sum(x['type']=='file' for x in before),'bytes':sum(x.get('size',0) for x in before),'tree_sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'archive_sha256':h.hexdigest(),'source_stable':True}))
'''
 return json.loads(helper(code,[f'type=volume,src={source},dst=/source,readonly',f'type=bind,src={PRIVATE},dst=/backup'],[destfile]).stdout)

def verify_archive(archive,expected_sha256):
 assert Path(archive).name==archive and not (PRIVATE/archive).is_symlink()
 h=hashlib.sha256()
 with (PRIVATE/archive).open('rb') as f:
  for b in iter(lambda:f.read(1048576),b''):h.update(b)
 if h.hexdigest()!=expected_sha256:raise ValueError('Archive digest mismatch; restore refused before volume creation')
 return h.hexdigest()

def restore_volume(archive,name,expected_sha256):
 verify_archive(archive,expected_sha256)
 volume(name)
 code="import pathlib,json,hashlib,tarfile,os,sys\n"+MANIFEST+r'''
root=pathlib.Path('/dest');assert not list(root.iterdir())
with tarfile.open('/backup/'+sys.argv[1]) as t:
 for m in t.getmembers():
  assert m.name=='data' or m.name.startswith('data/');assert '..' not in pathlib.PurePosixPath(m.name).parts and not m.issym() and not m.islnk()
 t.extractall('/tmp-extract' if False else '/dest',filter='fully_trusted')
# Volume contains the complete root under /dest/data, including root metadata.
expected=json.loads(pathlib.Path('/backup/'+sys.argv[1]+'.manifest.json').read_text());actual=tree(root/'data');assert expected==actual
print(json.dumps({'result':'PASS','entries':len(actual),'file_content_and_metadata_equal':True,'tree_sha256':hashlib.sha256(json.dumps(actual,sort_keys=True,separators=(',',':')).encode()).hexdigest()}))
'''
 return json.loads(helper(code,[f'type=volume,src={name},dst=/dest',f'type=bind,src={PRIVATE},dst=/backup,readonly'],[archive]).stdout)

def cold():
 results={}
 for alias,project in SOURCES.items():
  results[alias]={}
  for kind,prefix in [('db','supabase_db_'),('storage','supabase_storage_')]:
   filename=f'{alias}-{kind}-cold.tar';backup=export_volume(prefix+project,filename);results[alias][kind]={'source_project':project,'backup':backup,'restores':{}}
   for stage in ['work','recovery']:
    name=f'{OWNER}-{alias}-{stage}-{kind}';restored=restore_volume(filename,name,backup['archive_sha256']);results[alias][kind]['restores'][stage]={'volume':name,**restored}
   (RUN/'04-cold-backup-restore.json').write_text(json.dumps({'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'scope':'Historical local synthetic labs only','result':'IN_PROGRESS','sources':results},indent=2)+'\n')
 (RUN/'04-cold-backup-restore.json').write_text(json.dumps({'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'result':'PASS','sources':results,'complete_requirement_validation':False},indent=2)+'\n');print('Cold DB/Storage archives restored twice for both sources; exact file/metadata manifests match.')

def start_db(alias,stage):
 assert alias in SOURCES and stage in ['work','recovery']
 name=f'{OWNER}-{alias}-{stage}-postgres';v=f'{OWNER}-{alias}-{stage}-db'
 assert inspect(v,'volume')['Labels']['marea.task002.owner']==OWNER
 assert docker('inspect',name,check=False).returncode!=0
 script="printf 'local all all trust\\nhost all all all reject\\n' > /tmp/diag-hba; touch /tmp/diag.conf; exec postgres -D /pg/data -c config_file=/tmp/diag.conf -c hba_file=/tmp/diag-hba -c listen_addresses= -c unix_socket_directories=/tmp -c shared_preload_libraries=pg_stat_statements,pg_cron -c cron.launch_active_jobs=off -c default_transaction_read_only=on -c ssl=off -c archive_mode=off -c max_connections=30"
 docker('run','-d','--pull','never','--name',name,'--label','marea.task002.owner='+OWNER,'--network','none','--read-only','--user','100:101','--cap-drop','ALL','--security-opt','no-new-privileges','--mount',f'type=volume,src={v},dst=/pg','--tmpfs','/tmp:rw,noexec,nosuid,size=64m,mode=1777','--shm-size','128m','--entrypoint','sh',PG,'-ec',script)
 for _ in range(40):
  c=owned(name)
  if not c['State']['Running']:
   (PRIVATE/(name+'-boot.log')).write_text(docker('logs',name,check=False).stderr);raise RuntimeError('Clone boot failed: '+name)
  q=docker('exec',name,'pg_isready','-h','/tmp','-U','supabase_admin','-d','postgres',check=False)
  if q.returncode==0:return name
  time.sleep(.25)
 raise RuntimeError('Clone readiness timeout')

def sql(name,query,readonly=True,binary=False):
 owned(name);role='supabase_admin'
 if readonly:query='BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY; SET LOCAL statement_timeout=\'30s\';\n'+query+'\nROLLBACK;'
 return docker('exec','-i',name,'psql','-X','-h','/tmp','-U',role,'-d','postgres','-v','ON_ERROR_STOP=1','-Atq',input=query,binary=binary)

def boot():
 for a in SOURCES:
  for stage in ['work','recovery']:print(start_db(a,stage))
if __name__=='__main__':
 guard()
 if sys.argv[1:] == ['cold']:cold()
 elif sys.argv[1:] == ['boot']:boot()
 else:raise SystemExit('Usage: e_diagnostics.py cold|boot; fixed authorized local run only')
