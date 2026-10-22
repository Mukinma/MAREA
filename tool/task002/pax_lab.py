"""Stage 1 ONLY: empty/synthetic helpers, no project data or historical mounts."""
import json,os,subprocess,hashlib,tarfile,time
from pathlib import Path
from e2a_isolation import capture_empty,validate_snapshot,require,IMAGE
ROOT=Path(__file__).resolve().parents[2];RUN=ROOT/'docs/evidence/2026-10-19/task002/run-20261019T143903Z-e2a-r3/pax';PRIVATE=Path('/Users/crisis/Proyectos/marea-backups/task002-e2a-r3-20261019T143903Z');OWNER='task002-pax-20261019t143903z';LABEL='marea.pax.r3.owner';ENDPOINT='unix:///Users/crisis/.docker/run/docker.sock';ENV={k:v for k,v in os.environ.items() if k in ['PATH','HOME','LANG','TMPDIR']}
def docker(*args,input=None,binary=False,check=True):
 with (PRIVATE/'pax-commands.jsonl').open('a') as f:f.write(json.dumps(args)+'\n')
 r=subprocess.run(['docker','--host',ENDPOINT,*args],input=input,text=not binary,capture_output=True,env=ENV,timeout=60)
 if check:require(r.returncode==0,'PAX Docker failure: '+r.stderr[:300].decode() if binary else 'PAX Docker failure: '+r.stderr[:300])
 return r

def inspect(name):return json.loads(docker('inspect',name).stdout)[0]
def args(name):return ['--pull','never','--name',name,'--label',LABEL+'='+OWNER,'--network','none','--sysctl','net.ipv4.ip_forward=0','--sysctl','net.ipv6.conf.all.forwarding=0','--read-only','--user','1000:1000','--cap-drop','ALL','--security-opt','no-new-privileges']
def save(name,obj):
 p=RUN/name;require(not p.exists(),'No overwrite');p.write_text(json.dumps(obj,indent=2)+'\n')
FIXTURE=r'''
import pathlib,os,json
root=pathlib.Path('/work/data');root.mkdir();(root/'nested').mkdir();(root/'nested'/'restricted').mkdir()
(root/'a.bin').write_bytes(b'PAX synthetic\x00\xff\n');(root/'empty').write_bytes(b'');(root/'nested'/'restricted'/'read only.txt').write_text('only synthetic data\n');(root/('n'*110+'-ñ.txt')).write_text('unicode and long PAX path')
os.link(root/'a.bin',root/'nested'/'hardlink');os.symlink('../a.bin',root/'nested'/'symlink')
for path,mode in [(root,0o750),(root/'nested',0o755),(root/'nested'/'restricted',0o550),(root/'a.bin',0o640),(root/'empty',0o600),(root/'nested'/'restricted'/'read only.txt',0o440)]:os.chmod(path,mode)
paths=[root,*sorted(root.rglob('*'))]
# Every inode gets a known non-microsecond timestamp. Hardlinks share metadata.
for p in paths:os.utime(p,ns=(1699999900765432101,1700000000123456789),follow_symlinks=False)
print(json.dumps({'entries':len(paths),'mtime_ns':os.lstat(root/'a.bin').st_mtime_ns,'atime_ns':os.lstat(root/'a.bin').st_atime_ns,'synthetic_only':True}))
'''
def start_and_red():
 require(not docker('ps','-q').stdout.strip(),'Existing running containers')
 source=OWNER+'-source';docker('run','-d',*args(source),'--tmpfs','/work:rw,noexec,nosuid,size=16m,mode=1777','--entrypoint','python',IMAGE,'-c','import time;time.sleep(7200)')
 x=capture_empty(source,lambda *a:docker(*a).stdout);proof=validate_snapshot(x,'none');save('01-empty-isolation.json',{'result':'PASS','proof':proof,'snapshot':x})
 created=json.loads(docker('exec',source,'python','-c',FIXTURE).stdout);save('02-fixture.json',created)
 old=PRIVATE/'synthetic-legacy-docker-cp.tar'
 with old.open('xb') as f:
  r=subprocess.run(['docker','--host',ENDPOINT,'cp','-a',source+':/work/data','-'],stdout=f,stderr=subprocess.PIPE,env=ENV,timeout=60)
 require(r.returncode==0,'Legacy fixture export failed')
 with tarfile.open(old) as t:
  m=next(m for m in t if m.name.rstrip('/')=='data/a.bin');actual=int(float(m.pax_headers.get('mtime',m.mtime))*1000000000)
 require(actual!=created['mtime_ns'],'Legacy unexpectedly precise; re-evaluate RED')
 save('03-precision-RED.json',{'result':'EXPECTED_RED','expected_mtime_ns':created['mtime_ns'],'archive_mtime_ns':actual,'source':'Disposable synthetic fixture only','project_data_used':False})
 print('RED reproduced with synthetic fractional timestamps; empty isolation PASS.')
if __name__=='__main__':start_and_red()

def green():
 import sys,copy,io
 from pax_transport import archive_manifest,compare,IntegrityError
 module=(ROOT/'tool/task002/pax_transport.py').read_text();source=OWNER+'-source'
 before=json.loads(docker('exec',source,'python','-c',module+"\nimport json;print(json.dumps(snapshot('/work/data')))\n").stdout)
 archive=PRIVATE/'synthetic-PAX.tar'
 with archive.open('xb') as f:
  r=subprocess.run(['docker','--host',ENDPOINT,'exec',source,'python','-c',module+"\nimport sys;export_archive('/work/data',sys.stdout.buffer)\n"],stdout=f,stderr=subprocess.PIPE,env=ENV,timeout=60)
 require(r.returncode==0,'PAX export failure: '+r.stderr.decode()[:300])
 with archive.open('rb') as f:archived=archive_manifest(f)
 compare(before,archived)
 destination=OWNER+'-restored';volume=OWNER+'-synthetic-target'
 docker('volume','create','--label',LABEL+'='+OWNER,volume)
 docker('run','-d',*args(destination),'--mount',f'type=volume,src={volume},dst=/dest','--entrypoint','python',IMAGE,'-c','import time;time.sleep(7200)')
 def stream(command):
  with archive.open('rb') as f:r=subprocess.run(['docker','--host',ENDPOINT,*command],stdin=f,capture_output=True,env=ENV,timeout=60)
  require(r.returncode==0,'PAX restore phase failure: '+r.stderr.decode()[:300])
 stream(['cp','-a','-',destination+':/dest'])
 stream(['exec','-i',destination,'python','-c',module+"\nimport sys;restore_metadata('/dest/data',sys.stdin.buffer)\n"])
 after=json.loads(docker('exec',destination,'python','-c',module+"\nimport json;print(json.dumps(snapshot('/dest/data')))\n").stdout);compare(before,after)
 source_after=json.loads(docker('exec',source,'python','-c',module+"\nimport json;print(json.dumps(snapshot('/work/data')))\n").stdout);compare(before,source_after)
 negatives=[]
 for label,mutate in [('missing',lambda x:x.pop()),('precision_loss',lambda x:x[1].update(mtime_ns=x[1]['mtime_ns']//1000000000*1000000000)),('owner',lambda x:x[1].update(uid=1001)),('permissions',lambda x:x[1].update(mode=0o777)),('bytes',lambda x:x[1].update(sha256='0'*64)),('atime_precision',lambda x:x[1].update(atime_ns=x[1]['atime_ns']//1000000000*1000000000))]:
  damaged=copy.deepcopy(after);mutate(damaged)
  try:compare(before,damaged)
  except IntegrityError:negatives.append({'case':label,'result':'PASS_REJECTED'})
  else:raise RuntimeError('Negative accepted: '+label)
 # Actual post-restore byte and permission corruption are detected too.
 for label,code in [('actual_bytes',"p=pathlib.Path('/dest/data/a.bin');p.write_bytes(b'altered synthetic fixture')"),('actual_permissions',"os.chmod('/dest/data/empty',0o640)")]:
  docker('exec',destination,'python','-c','import pathlib,os;'+code)
  changed=json.loads(docker('exec',destination,'python','-c',module+"\nimport json;print(json.dumps(snapshot('/dest/data')))\n").stdout)
  try:compare(before,changed)
  except IntegrityError:negatives.append({'case':label,'result':'PASS_REJECTED'})
  else:raise RuntimeError('Live negative accepted')
 save('05-PAX-cycle.json',{'result':'PASS','archive_sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'entries':len(before),'source':before,'PAX_archive':archived,'restored':after,'exact_mtime_atime_ns':True,'safe_symlink_and_hardlink_topology_preserved':True,'source_unchanged':True,'negative_cases':negatives,'project_data_used':False,'integrity_comparisons_weakened':False,'timestamp_scope':'mtime/atime exact ns; inode ctime/birthtime not restorable; directory allocation size not a tar attribute'})
 for name in [source,destination]:docker('stop','--time','1',name);require(not inspect(name)['State']['Running'],'PAX helper still running')
 save('06-closed.json',{'result':'PASS','containers_stopped':[source,destination],'new_volume_retained':volume,'historical_mounts':0,'data_project_used':False})
 print('PASS PAX export/archive/restore exact nanoseconds, links, bytes, modes, uid/gid; 8 negative cases rejected.')
