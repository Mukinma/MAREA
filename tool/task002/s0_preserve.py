"""Read-only conservation of pre-S0 sources; never inventory the Docker VM."""
import json,subprocess
import s0_lab_v2 as L

def run():
 L.require(json.loads((L.RUN/'26-final-recovery-v3.json').read_text())['result']=='PASS','Corrected recovery required')
 L.require(json.loads((L.RUN/'99-stopped-v3.json').read_text())['result']=='PASS','Stop required')
 initial=json.loads((L.RUN/'00-before.json').read_text())
 for path,h in initial['files'].items():
  L.require(not path.endswith('.raw'),'Raw excluded before access');L.require(L.sha(L.ROOT/path)==h,'Pre-existing workspace file changed: '+path)
 private=json.loads((L.A_PRIVATE/'previous-private-digests.json').read_text())
 for path,h in private.items():
  L.require(not path.endswith('.raw'),'Raw excluded before access');L.require(L.sha(path)==h,'Historical private artifact changed: '+path)
 source_receipt=json.loads((L.A_RUN/'08-final-cold-recovery.json').read_text())
 for a in ['a','b']:
  expected=source_receipt['sources'][a]['backup_restore']
  L.require(L.sha(L.A_PRIVATE/f'{a}-A-final-verified.tar')==expected['archive_sha256'],'E2-A DB archive changed')
  L.require(L.sha(L.A_PRIVATE/f'{a}-A-final-verified.manifest.json')==expected['manifest_sha256'],'E2-A DB manifest changed')
  manifest=json.loads((L.A_PRIVATE/f'{a}-storage-manifest.json').read_text())
  L.require(L.sha(L.A_PRIVATE/f'{a}-storage-PAX.tar')==manifest['archive_sha256'],'E2-A Storage archive changed')
  L.require(json.loads((L.A_PRIVATE/f'{a}-conservation-final.json').read_text())==json.loads((L.PRIVATE/f'{a}-S0-base.json').read_text()),'E2-A logical source changed')
 previous=json.loads((L.PRIVATE/'previous-containers.json').read_text())
 actual=json.loads(L.dtext('inspect',*[x['Id'] for x in previous])) if previous else []
 actual=[{k:c[k] for k in ['Id','Name','State','Mounts','Image']} for c in actual]
 L.require(sorted(actual,key=lambda x:x['Id'])==sorted(previous,key=lambda x:x['Id']),'Historical container state changed')
 L.require(not L.dtext('ps','-q').strip(),'A container remains running')
 oldvol=set(json.loads((L.PRIVATE/'previous-volumes.json').read_text()));volumes=set(L.dtext('volume','ls','-q').split());L.require(oldvol<=volumes,'Historical volume removed')
 for name in volumes-oldvol:L.require(name.startswith(L.OWNER+'-') and L.inspect(name,'volume')['Labels'][L.LABEL]==L.OWNER,'Foreign new volume')
 owned=[]
 for cid in L.dtext('ps','-aq','--filter','label='+L.LABEL+'='+L.OWNER).split():
  c=L.owned(L.inspect(cid)['Name'].lstrip('/'));L.require(not c['State']['Running'],'S0 container active');owned.append(c['Name'])
 git=lambda *args:subprocess.check_output(['git',*args],cwd=L.ROOT,text=True).strip()
 L.require(git('rev-parse','HEAD')==initial['head'] and git('diff','--cached','--name-only')==initial['staged'] and git('diff','--name-only')=='','Product/Git changed')
 L.save('27-workspace-preservation.json',{'result':'PASS','preexisting_workspace_files_preserved':len(initial['files']),'previous_private_allowlist_preserved':len(private),'E2_A_DB_Storage_archives_manifests_and_logical_sources_unchanged':True,'previous_containers_identity_state_mounts_unchanged':len(previous),'historical_volumes_preserved':len(oldvol),'new_volumes_only_owner_labelled':len(volumes-oldvol),'S0_containers_all_stopped':len(owned),'running_containers':0,'original_volumes_mounted':False,'Docker_raw_image_read_or_inventoried':False,'SRS_product_sources_unchanged':True,'HEAD':initial['head'],'commits_created':0,'staged_changes':False,'remote_modified':False,'next_increment_started':False})
if __name__=='__main__':run()
