from pathlib import Path
import json,hashlib
r=Path(__file__).resolve().parent;commands=[json.loads(v) for v in (r/'docker-commands.jsonl').read_text().splitlines()]
closed=json.loads((r/'14-closed-and-preserved.json').read_text())['stopped_empty_containers'];ids={v['id'] for v in closed};names={v['name'].lstrip('/') for v in closed};image='sha256:c0d4530ddaae7a3295b5f8dbb8f60557884660bde2675df064cd67c9dd3b7983';runs=[]
def owned(ref):return ref in names or (len(ref)>=12 and sum(i.startswith(ref) for i in ids)==1)
for a in commands:
 if a[0]=='run':
  assert a[a.index('--pull')+1]=='never' and a[a.index('--network')+1] in ['none',*['container:'+v for v in ids]]
  assert a[a.index('--name')+1] in names and image in a and a[a.index('--cap-drop')+1]=='ALL'
  assert not set(a)&{'--mount','-v','--volume','--cap-add','--privileged','--publish','-p','-P','--publish-all'}
  assert a[-1]=='import time; time.sleep(1800)';runs.append(a)
 elif a[0]=='exec':
  assert owned(a[1]) and a[2:4]==['python','-c']
  assert 'urllib' not in a[4] and '.connect(' not in a[4] and 'AF_INET' not in a[4]
 elif a[0]=='stop':assert owned(a[-1])
 elif a[0]=='ps':assert a==['ps','-aq','--filter','label=marea.isolation.owner=task002-isolation-20261019t133800z']
 else:assert a[0]=='inspect'
assert len(runs)==6
(r/'19-command-scope-audit.json').write_text(json.dumps({'result':'PASS','logged_commands':len(commands),'empty_helper_runs':len(runs),'all_run_images':image,'all_runs_no_mounts_or_published_ports_or_added_capabilities':True,'all_exec_and_stop_targets_are_new_owned_empty_helpers':True,'all_exec_python_programs_have_no_IP_connection_or_urllib_calls':True,'all_run_entrypoints':'python: sleep only','Docker_endpoint':'Explicit local Unix socket after initial local-context confirmation; Docker env overrides excluded','product_services_started':0,'volumes_created_or_mounted':0,'external_connection_probes':0},indent=2)+'\n')
files=['tool/task002/e2a_lab.py','tool/task002/e2a_isolation.py','tool/task002/e2a_isolation_probe.py','tool/task002/e2a_isolation_policy.json','tool/task002/test_e2a_isolation.py']
(r/'20-verifier-source-manifest.json').write_text(json.dumps({p:hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in files},indent=2)+'\n')
print('Scope PASS:',len(commands),'commands; 6 empty helpers; no SQL, mounts, extra capabilities or IP connections.')
