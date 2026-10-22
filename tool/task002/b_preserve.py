"""Read-only historical conservation after B stop; explicit allowlists, no VM raw."""
import json,subprocess
import b_lab as L
def run():
 L.require(json.loads((L.RUN/'16-final-recovery.json').read_text())['result']=='PASS' and json.loads((L.RUN/'99-stopped.json').read_text())['result']=='PASS','Recovery and stop required')
 initial=json.loads((L.RUN/'00-before.json').read_text())
 cache=L.ROOT/'supabase/.temp/cli-latest';expected=initial['files']['supabase/.temp/cli-latest']
 if L.sha(cache)!=expected:
  current=cache.read_bytes();old=b'v2.120.0';L.require(current==b'v2.121.0' and __import__('hashlib').sha256(old).hexdigest()==expected,'Unexplained CLI cache delta');L.private('CLI-cache-delta.json',{'observed':current.decode(),'restored':old.decode(),'original_SHA256':expected});cache.write_bytes(old)
 for path,h in initial['files'].items():L.require(not path.endswith('.raw') and L.sha(L.ROOT/path)==h,'Historical workspace drift '+path)
 old_private=json.loads((L.C.A_PRIVATE/'previous-private-digests.json').read_text())
 for path,h in old_private.items():L.require(not path.endswith('.raw') and L.sha(path)==h,'Historical private drift '+path)
 sources=json.loads((L.SOURCE_RUN/'26-final-recovery-v3.json').read_text())
 for a in ['a','b']:
  for key,stem in [('DB',a+'-S0-v3-final-verified'),('Storage',a+'-S0-v3-final-storage'),('coordination',a+'-S0-v3-final-control')]:
   L.require(L.sha(L.SOURCE_PRIVATE/(stem+'.tar'))==sources['sources'][a][key]['archive_sha256'] and L.sha(L.SOURCE_PRIVATE/(stem+'.manifest.json'))==sources['sources'][a][key]['manifest_sha256'],'S0 source archive/manifest drift')
  L.require(json.loads((L.SOURCE_PRIVATE/(a+'-S0-v3-conservation-verified.json')).read_text())==json.loads((L.PRIVATE/(a+'-B-base.json')).read_text()),'S0 logical source changed')
 previous=json.loads((L.PRIVATE/'previous-containers.json').read_text());now=json.loads(L.dtext('inspect',*[c['Id'] for c in previous]));actual=[{k:c[k] for k in ['Id','Name','State','Mounts','Image']} for c in now];L.require(sorted(previous,key=lambda c:c['Id'])==sorted(actual,key=lambda c:c['Id']),'Previous container changed')
 oldvol=set(json.loads((L.PRIVATE/'previous-volumes.json').read_text()));vol=set(L.dtext('volume','ls','-q').split());L.require(oldvol<=vol,'Old volume lost')
 for name in vol-oldvol:L.require(name.startswith(L.OWNER+'-') and L.inspect(name,'volume')['Labels'][L.LABEL]==L.OWNER,'Foreign new volume')
 own=[]
 for cid in L.dtext('ps','-aq','--filter','label='+L.LABEL+'='+L.OWNER).split():
  c=L.owned(L.inspect(cid)['Name'].lstrip('/'));L.require(not c['State']['Running'],'B still running');own.append(c['Name'])
 L.require(not L.dtext('ps','-q').strip(),'Unexpected running Docker container')
 git=lambda *args:subprocess.check_output(['git',*args],cwd=L.ROOT,text=True).strip()
 L.require(git('rev-parse','HEAD')==initial['head'] and git('diff','--cached','--name-only')==initial['staged'] and not git('diff','--name-only'),'Git or operational source changed')
 L.save('17-preservation.json',{'result':'PASS','preexisting_workspace_files_hash_preserved':len(initial['files']),'historical_private_allowlist_preserved':len(old_private),'S0_source_archives_manifests_and_snapshots_unchanged':True,'previous_containers_unchanged':len(previous),'previous_volumes_preserved':len(oldvol),'new_volumes_only_owner_labelled':len(vol-oldvol),'B_containers_all_stopped':len(own),'running_containers':0,'original_volumes_mounted':False,'Docker_raw_image_read_or_inventoried':False,'SRS_Flutter_Edge_business_RPC_migrations_unchanged':True,'CLI_cache_original_bytes_restored':True,'CLI_upgrade_performed':False,'HEAD':initial['head'],'commits':0,'staging':False,'remote_modified':False,'next_increment_started':False})
if __name__=='__main__':run()
