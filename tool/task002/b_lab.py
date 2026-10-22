"""B-only adapter over verified S0 primitives. New identities, gates and volumes.
No historical executor source is changed. Each process configures this library
once, before any Docker operation; tests must run B in its own interpreter.
"""
import json,hashlib,re,sys,time
from pathlib import Path
import s0_lab_v2 as C
CONFIG=json.loads(Path('/tmp/marea-b-config.json').read_text())
ROOT=C.ROOT;RUN=Path(CONFIG['run']);PRIVATE=Path(CONFIG['private']);OWNER=CONFIG['owner'];LABEL='marea.e2b.owner'
SOURCE_RUN=ROOT/'docs/evidence/2026-10-19/task002/run-20261019T185927Z-e2s0'
SOURCE_PRIVATE=Path('/Users/crisis/Proyectos/marea-backups/task002-s0-20261019T185927Z')
C.RUN=RUN;C.PRIVATE=PRIVATE;C.OWNER=OWNER;C.LABEL=LABEL
def require_preflight():
 C.require(not list(RUN.glob('FAILURE-*.json')),'B stopped; no data operations')
 p=RUN/'02-full-preflight.json';C.require(p.exists(),'Complete B preflight required')
 x=json.loads(p.read_text());C.require(x['result']=='PASS' and x['endpoint']==C.ENDPOINT,'B gate failed')
 C.require(C.sha(RUN/'01-empty-preflight.json')==x['empty_sha256'],'Empty gate drift')
 for path,h in x['source_bindings'].items():C.require(C.sha(ROOT/path)==h,'Verified primitive/source drift: '+path)
 C.require(C.sha(__file__)==x['adapter_sha256'],'B adapter drift')
 return x
C.require_full_preflight=require_preflight
def sql(name,q,write=False,check=True):
 require_preflight();C.owned(name)
 if write:
  C.require(not re.search(r'(?is)\bdelete\s+from\s+|\btruncate\s+(?:table\s+)?[a-z_]',q),'Destructive SQL forbidden in B runner')
 else:q="BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY;SET LOCAL statement_timeout='30s';\n"+q+'\nROLLBACK;'
 return C.docker('exec','-i',name,'psql','-X','-h','/tmp','-U','supabase_admin','-d','postgres','-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose','-Atq',input=q,check=check)
# Reuse capture/val dynamically with B's stricter no-purge SQL gate.
C.sql=sql
for name in ['sha','save','private','docker','inspect','dtext','owned','base_args','ready','runtime_net','capture','val','pax_snapshot','restore_pax','copier','boot','cold_backup','stop','require','PG','HELPER','AUTH','STORAGE','DENO','POSTGREST','ENDPOINT','ENV']:
 globals()[name]=getattr(C,name)

def preflight():
 require(PRIVATE.stat().st_mode&0o077==0,'Private permissions')
 require(not dtext('ps','-q').strip(),'Unexpected running container')
 require(dtext('version','--format','{{.Server.Version}}').strip()=='29.8.2','Docker version drift')
 for im in [PG,HELPER,AUTH,STORAGE,DENO,POSTGREST]:require(inspect(im,'image')['Id']==im,'Pinned image missing')
 names=[OWNER+'-empty-anchor',OWNER+'-empty-shared',OWNER+'-empty-independent']
 for n,mode in [(names[0],'none'),(names[1],'container:'+names[0]),(names[2],'none')]:
  args=base_args(n,mode)
  if mode=='none':args+=['--sysctl','net.ipv4.ip_forward=0','--sysctl','net.ipv6.conf.all.forwarding=0']
  docker('run','-d',*args,'--entrypoint','python',HELPER,'-c','import time;time.sleep(3600)')
 snaps={n:C.capture_empty(n,dtext) for n in names};private('empty-preflight.json',snaps)
 pair=C.validate_pair(snaps[names[0]],snaps[names[1]]);ind=C.validate_snapshot(snaps[names[2]],'none');require(snaps[names[0]]['kernel']['netns']!=snaps[names[2]]['kernel']['netns'],'Namespace collision')
 for n in reversed(names):docker('stop','--time','1',n)
 save('01-empty-preflight.json',{'result':'PASS','pair':pair,'independent':ind,'before_restore_and_all_product_services':True,'no_mounts':True})
 prior=json.loads((SOURCE_RUN/'26-final-recovery-v3.json').read_text());require(prior['result']=='PASS','S0 recovery source not validated')
 require(json.loads((SOURCE_RUN/'30-traceability.json').read_text())['result']=='PASS','S0 seal missing')
 for a in ['a','b']:
  for key,file in [('DB',a+'-S0-v3-final-verified'),('Storage',a+'-S0-v3-final-storage'),('coordination',a+'-S0-v3-final-control')]:
   x=prior['sources'][a][key];require(sha(SOURCE_PRIVATE/(file+'.tar'))==x['archive_sha256'],'Archive drift '+key);require(sha(SOURCE_PRIVATE/(file+'.manifest.json'))==x['manifest_sha256'],'Manifest drift '+key)
 ids=dtext('ps','-aq').split();cs=json.loads(dtext('inspect',*ids)) if ids else [];private('previous-containers.json',[{k:c[k] for k in ['Id','Name','State','Mounts','Image']} for c in cs if not c['Name'].startswith('/'+OWNER+'-')]);private('previous-volumes.json',sorted(dtext('volume','ls','-q').split()))
 paths=['tool/task002/s0_lab_v2.py','tool/task002/s0_sql_policy.py','tool/task002/pax_transport.py','tool/task002/e2a_isolation.py','tool/task002/e2a_isolation_policy.json','tool/task002/e2a_r2_network.py','tool/task002/e_inventory.py','tool/task002/e1_lab.py',str(SOURCE_RUN.relative_to(ROOT)/'26-final-recovery-v3.json'),str(SOURCE_RUN.relative_to(ROOT)/'31-artifact-manifest.json')]
 bindings={p:sha(ROOT/p) for p in paths}
 save('02-full-preflight.json',{'result':'PASS','endpoint':ENDPOINT,'adapter_sha256':sha(__file__),'source_bindings':bindings,'empty_sha256':sha(RUN/'01-empty-preflight.json'),'source_archives_verified':True,'source':'S0-v3-final-verified','original_volumes_mounted':False})

def bootstrap():
 require_preflight();results={}
 for a in ['a','b']:
  for src,dest,user in [('verified','db','100:101'),('storage','storage','0:0'),('control','control-v2','0:0')]:
   stem=a+('-S0-v3-final-verified' if src=='verified' else '-S0-v3-final-'+src);archive=SOURCE_PRIVATE/(stem+'.tar');manifest=json.loads((SOURCE_PRIVATE/(stem+'.manifest.json')).read_text());restore_pax(archive,manifest,f'{OWNER}-{a}-{dest}',user)
  pg=boot(a);runtime_net(a,{5432});expected=json.loads((SOURCE_PRIVATE/(a+'-S0-v3-conservation-verified.json')).read_text());require(capture(pg)==expected,'Source catalog/rows drift');private(a+'-B-base.json',expected)
  backup=cold_backup(a,'B-source-verified');docker('start',pg);ready(pg);runtime_net(a,{5432});require(capture(pg)==expected,'Recovery/startup drift')
  results[a]={'result':'PASS','S0_snapshot_equal':True,'new_empty_DB_Storage_control_destinations':True,'source_backup_restore':backup}
 save('03-new-clones-recovery.json',{'result':'PASS','sources':results,'B_implemented':False})

if __name__=='__main__':
 try:
  if sys.argv[1:]==['preflight']:preflight()
  elif sys.argv[1:]==['bootstrap']:bootstrap()
  else:raise SystemExit('preflight | bootstrap')
 except Exception as e:save('FAILURE-'+str(time.time_ns())+'.json',{'result':'BLOCKED','error':str(e)});stop();raise
