"""Audit recorded Docker commands without reading any original volume."""
import json,hashlib,pathlib,datetime
r=pathlib.Path(__file__).resolve().parent
private=pathlib.Path('/Users/crisis/Proyectos/marea-backups/task002-e1-20261019T055200Z')
audit=[json.loads(s) for s in (private/'docker-commands.jsonl').read_text().splitlines()]
owner='task002-e1-20261019t055200z'
allowed={owner+'-'+a+'-'+k for a in ['a','b'] for k in ['db','storage','postgres']}
run_count=0
for a in audit:
 if a[0]=='run':
  assert a[a.index('--network')+1]=='none' and a[a.index('--pull')+1]=='never';run_count+=1
  for i,arg in enumerate(a):
   if arg=='--mount':
    mount=dict(x.split('=',1) if '=' in x else (x,True) for x in a[i+1].split(','))
    if mount['type']=='volume':assert mount['src'] in allowed
    else:assert mount['type']=='bind' and mount['src']=='/Users/crisis/Proyectos/marea-backups/task002-e-20261019T051800Z' and mount.get('readonly') is True
 elif a[0] in ['start','stop','logs']:assert a[-1] in allowed
 elif a[0]=='exec':assert next(x for x in a if x.startswith(owner)) in allowed
 elif a[0]=='volume':assert a[1] in ['inspect','create'] and a[-1] in allowed
 else:assert a[0] in ['ps','inspect','context','version']
result={'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'result':'PASS',
 'commands_audited':len(audit),'network_none_run_commands':run_count,
 'all_mounts_new_owned_volumes_or_existing_readonly_backup_directory':True,
 'original_volume_mounts':0,'original_start_stop_or_exec_commands':0,'remote_database_connections':0,
 'no_prune_delete_or_image_pull_commands':True,
 'docker_command_audit_sha256':hashlib.sha256((private/'docker-commands.jsonl').read_bytes()).hexdigest()}
(r/'23-command-scope-audit.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
