import sys,json,subprocess,os
from pathlib import Path
sys.path.insert(0,str(Path.cwd()/'tool/task002'))
from e2a_isolation import capture_empty,validate_pair,IsolationError,IMAGE
RUN=Path(__file__).resolve().parent;OWNER='task002-netcycle-20261019t143903z';ENV={k:v for k,v in os.environ.items() if k in ['PATH','HOME','LANG','TMPDIR']};BASE=['docker','--host','unix:///Users/crisis/.docker/run/docker.sock']
def docker(*args):
 with (RUN/'namespace-commands.jsonl').open('a') as f:f.write(json.dumps(args)+'\n')
 return subprocess.check_output(BASE+list(args),text=True,env=ENV,timeout=30)
def start(name,network):
 args=['run','-d','--pull','never','--name',name,'--label','marea.netcycle.owner='+OWNER,'--network',network,'--read-only','--user','1000:1000','--cap-drop','ALL','--security-opt','no-new-privileges']
 if network=='none':args+=['--sysctl','net.ipv4.ip_forward=0','--sysctl','net.ipv6.conf.all.forwarding=0']
 docker(*args,'--entrypoint','python',IMAGE,'-c','import time;time.sleep(1800)')
a=OWNER+'-anchor';s=OWNER+'-stale';f=OWNER+'-fresh';start(a,'none');start(s,'container:'+a)
a0=capture_empty(a,docker);s0=capture_empty(s,docker);initial=validate_pair(a0,s0)
docker('stop','--time','1',a);docker('start',a)
a1=capture_empty(a,docker);s1=capture_empty(s,docker)
try:validate_pair(a1,s1)
except IsolationError as e:negative={'result':'PASS_REJECTED_STALE_NAMESPACE','error':str(e)}
else:raise RuntimeError('Stale namespace accepted')
start(f,'container:'+a);f1=capture_empty(f,docker);fresh=validate_pair(a1,f1)
for n in [s,f,a]:docker('stop','--time','1',n)
result={'result':'PASS','initial':initial,'after_restart_anchor':a1['kernel']['netns'],'stale_probe':s1['kernel']['netns'],'stale_rejected':negative,'fresh_probe':fresh,'all_empty_no_mounts_no_project_data':True,'all_stopped':True,'snapshots':{'anchor_before':a0,'stale_before':s0,'anchor_after':a1,'stale_after':s1,'fresh_after':f1}}
(RUN/'08-namespace-restart-regression.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k!='snapshots'},indent=2))
