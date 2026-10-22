#!/opt/homebrew/bin/python3
"""Local CLI adapter: retain owned volumes and snapshot before automatic cleanup."""
import json,os,subprocess,sys,time
from pathlib import Path
root=Path(__file__).resolve().parent.parent
m=json.loads((root/'.docker-preserve-private.json').read_text());docker=m['docker'];args=sys.argv[1:]
def run(a,check=True):
    r=subprocess.run([docker,*a],capture_output=True,text=True)
    if check and r.returncode:raise RuntimeError('Owned Docker retention operation failed')
    return r
if args and args[0]=='start':
    for name in args[1:]:
        if name.startswith('-'):continue
        c=json.loads(run(['inspect',name]).stdout)[0]
        if c['Config']['Labels'].get('com.supabase.cli.project')!=m['project']:raise RuntimeError('Foreign start refused')
        for mount in c['Mounts']:
            if mount['Type']!='volume':continue
            volume=mount['Name']
            if not volume.endswith('_'+m['project']):raise RuntimeError('Foreign volume refused')
            keeper='marea-retain-'+volume
            if run(['inspect',keeper],False).returncode:
                run(['run','-d','--name',keeper,'--label','marea.task001.owner='+m['project'],'--network',m['network'],'--read-only','--cap-drop','ALL','--security-opt','no-new-privileges','--mount','type=volume,src='+volume+',dst=/retain,readonly,volume-nocopy','--entrypoint','python',m['image'],'-c','import time; time.sleep(2147483647)'])
            held=json.loads(run(['inspect',keeper]).stdout)[0]
            if not held['State']['Running']:raise RuntimeError('Volume retention not active')
if 'prune' in args:
    if not any(x=='label=com.supabase.cli.project='+m['project'] for x in args):raise RuntimeError('Unscoped prune refused')
if any(x in args for x in ('stop','rm','prune')):
    ids=run(['ps','-aq','--filter','label=com.supabase.cli.project='+m['project']]).stdout.split()
    snap=root/'rollback-private';snap.mkdir(mode=0o700,exist_ok=True)
    for cid in ids:
        for operation in ('inspect','logs'):
            r=run([operation,cid],False)
            target=snap/(str(time.time_ns())+'-'+cid+'-'+operation+'.log')
            target.write_text(r.stdout+r.stderr)
            target.chmod(0o600)
os.execv(docker,[docker,*args])
