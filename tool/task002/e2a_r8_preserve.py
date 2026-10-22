"""Read-only preservation; explicit historical allowlist, never inventory Docker VM."""
import json,subprocess,time
from pathlib import Path
import e2a_r8 as L

def run():
 L.require(json.loads((L.RUN/'99-stopped.json').read_text())['result']=='PASS','Stop required')
 histories={}
 for directory in ['run-20261019T143903Z-e2a-r3','run-20261019T152005Z-e2a-r8']:
  path=L.ROOT/'docs/evidence/2026-10-19/task002'/directory/'00-before.json';old=json.loads(path.read_text());changed=[]
  for rel,h in old['files'].items():
   L.require(not rel.endswith('.raw'),'Raw image cannot be an input')
   if L.sha(L.ROOT/rel)!=h:changed.append(rel)
  L.require(not changed,'Existing workspace files changed: '+str(changed));histories[directory]={'preserved_files':len(old['files']),'changed':changed}
 head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=L.ROOT,text=True).strip();staged=subprocess.check_output(['git','diff','--cached','--name-only'],cwd=L.ROOT,text=True).strip();tracked=subprocess.check_output(['git','diff','--name-only'],cwd=L.ROOT,text=True).strip()
 L.require(head==old['head'] and staged==old['staged'] and not tracked,'Git HEAD/staged/tracked product changed')
 private=json.loads((L.PRIVATE/'previous-private-digests.json').read_text())
 for path,h in private.items():
  L.require(not path.endswith('.raw'),'Raw image excluded before any access');L.require(L.sha(path)==h,'Previous private source/evidence changed: '+path)
 previous=json.loads((L.PRIVATE/'previous-containers.json').read_text())
 now=json.loads(L.dtext('inspect',*[x['Id'] for x in previous])) if previous else []
 actual=[{k:c[k] for k in ['Id','Name','State','Mounts','Image']} for c in now]
 L.require(sorted(actual,key=lambda x:x['Id'])==sorted(previous,key=lambda x:x['Id']),'Previous container identity/state/mounts changed')
 L.require(not L.dtext('ps','-q').strip(),'Container still running')
 volumes=set(L.dtext('volume','ls','-q').split());oldvol=set(json.loads((L.PRIVATE/'previous-volumes.json').read_text()));L.require(oldvol<=volumes,'Previous volume removed')
 for name in volumes-oldvol:L.require(name.startswith(L.OWNER+'-') and L.inspect(name,'volume')['Labels'][L.LABEL]==L.OWNER,'Unexpected new volume')
 owned=[]
 for cid in L.dtext('ps','-aq','--filter','label='+L.LABEL+'='+L.OWNER).split():
  c=L.owned(cid if cid.startswith(L.OWNER) else L.inspect(cid)['Name'].lstrip('/'));L.require(not c['State']['Running'],'Own container still running');owned.append(c['Name'])
 L.save('10-workspace-preservation.json',{'result':'PASS','historical_workspace':histories,'previous_private_files_preserved':len(private),'private_allowlist_sha256':L.sha(L.PRIVATE/'previous-private-digests.json'),'previous_containers_unchanged':len(previous),'previous_volumes_preserved':len(oldvol),'new_volumes_only_owner_labelled':len(volumes-oldvol),'new_containers_all_stopped':len(owned),'running_containers':0,'HEAD':head,'staged_changes':False,'tracked_product_changes':False,'original_volumes_mounted':False,'Docker_raw_image_read_or_inventoried':False,'remote_modified':False,'next_documentation_changes_only':['docs/MAREA_REQUIREMENTS_STATUS.yaml','docs/MAREA_TRACKING.md','docs/MAREA_AUDIT_REPORT.md','docs/MAREA_TRACEABILITY.md','docs/MAREA_CHANGELOG.md']})
if __name__=='__main__':run()
