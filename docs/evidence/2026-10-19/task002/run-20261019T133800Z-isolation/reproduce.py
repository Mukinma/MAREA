"""Empty pinned helpers only. No mounts, volumes, SQL, Auth, or network connects."""
import json, os, subprocess
from pathlib import Path

RUN = Path(__file__).resolve().parent
IMAGE = 'sha256:c0d4530ddaae7a3295b5f8dbb8f60557884660bde2675df064cd67c9dd3b7983'
OWNER = 'task002-isolation-20261019t133800z'
ENV = {k:v for k,v in os.environ.items() if k in ['PATH','HOME','LANG','TMPDIR']}

COLLECT = r'''
import socket,os,json,pathlib,subprocess,sys
def read(p):
 try:return pathlib.Path(p).read_text()
 except OSError as e:return {'error':str(e)}
def command(args):
 try:
  r=subprocess.run(args,capture_output=True,text=True)
  return {'argv':args,'returncode':r.returncode,'stdout':r.stdout,'stderr':r.stderr}
 except OSError as e:return {'argv':args,'error':str(e)}
names=socket.if_nameindex()
paths=['/proc/net/dev','/proc/net/route','/proc/net/ipv6_route','/proc/net/if_inet6','/proc/net/fib_trie','/proc/net/tcp','/proc/net/tcp6','/proc/net/udp','/proc/net/udp6','/proc/self/status','/proc/sys/net/ipv4/ip_forward','/proc/sys/net/ipv6/conf/all/forwarding']
out={'python':sys.version,'socket_file':socket.__file__,'if_nameindex_module':socket.if_nameindex.__module__,'if_nameindex':names,'legacy_predicate':[x[1] for x in names]==['lo'],'netns':os.readlink('/proc/self/ns/net'),'netns_inode':os.stat('/proc/self/ns/net').st_ino,'pid1_netns':os.readlink('/proc/1/ns/net'),'proc':{p:read(p) for p in paths},'sysfs':{}}
for p in sorted(pathlib.Path('/sys/class/net').iterdir()):
 out['sysfs'][p.name]=({'symlink':os.readlink(p),**{f:read(str(p/f)) for f in ['ifindex','iflink','address','flags','operstate','type','mtu']}} if p.is_symlink() else {'control_entry':read(str(p))})
out['commands']=[command(a) for a in [['ip','-details','link','show'],['ip','-4','addr','show'],['ip','-6','addr','show'],['ip','-4','route','show','table','all'],['ip','-6','route','show','table','all'],['ip','-4','rule','show'],['ip','-6','rule','show']]]
print(json.dumps(out,sort_keys=True))
'''

def docker(*args):
 with (RUN/'docker-commands.jsonl').open('a') as f:f.write(json.dumps(args)+'\n')
 return subprocess.check_output(['docker','--host','unix:///Users/crisis/.docker/run/docker.sock',*args],env=ENV,text=True)

def create(suffix,network):
 name=OWNER+'-'+suffix
 return docker('run','-d','--pull','never','--name',name,'--label','marea.isolation.owner='+OWNER,'--network',network,'--read-only','--user','1000:1000','--cap-drop','ALL','--security-opt','no-new-privileges','--entrypoint','python',IMAGE,'-c','import time; time.sleep(1800)').strip()

def capture(name):
 c=json.loads(docker('inspect',name))[0]
 return {'inspect':c,'kernel':json.loads(docker('exec',name,'python','-c',COLLECT))}

if __name__=='__main__':
 assert not (RUN/'03-reproduction.json').exists()
 a=create('anchor','none');b=create('shared','container:'+a);c=create('independent','none')
 data={name:capture(i) for name,i in [('anchor',a),('shared',b),('independent',c)]}
 (RUN/'03-reproduction.json').write_text(json.dumps(data,indent=2)+'\n')
 print(json.dumps({n:{k:v['kernel'][k] for k in ['if_nameindex','legacy_predicate','netns','sysfs']} for n,v in data.items()},indent=2))
