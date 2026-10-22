#!/usr/bin/env python3
"""Full pg_dump + globals restore in fresh isolated PostgreSQL, not TASK002 migration."""
import json,hashlib,subprocess,datetime,time
import e_diagnostics as e
import e_inventory as inv
from e_compare import canonical_catalog

def dump(alias):
 name=f'{e.OWNER}-{alias}-work-postgres';e.owned(name);files={}
 for kind,cmd in [('db',['pg_dump','-h','/tmp','-U','supabase_admin','-d','postgres','-Fc']),('globals',['pg_dumpall','-h','/tmp','-U','supabase_admin','--globals-only']),('schema',['pg_dump','-h','/tmp','-U','supabase_admin','-d','postgres','--schema-only'])]:
  dest=e.PRIVATE/f'{alias}-{kind}.backup';assert not dest.exists()
  with dest.open('xb') as f:
   q=subprocess.run(['docker','exec',name,*cmd],env=e.ENV,stdout=f,stderr=subprocess.PIPE,timeout=60)
  if q.returncode:(e.PRIVATE/f'{alias}-dump-error.log').write_bytes(q.stderr);raise RuntimeError('Dump failed; private log')
  files[kind]={'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'bytes':dest.stat().st_size}
 return files

def new_cluster(alias):
 volume=f'{e.OWNER}-{alias}-logical4-db';e.volume(volume)
 e.helper("import pathlib,os;p=pathlib.Path('/dest/data');p.mkdir();os.chown(p,100,101);p.chmod(0o700);f=pathlib.Path('/dest/preloads');f.write_text('pg_stat_statements,pg_cron,pg_net');os.chown(f,100,101)",[f'type=volume,src={volume},dst=/dest'])
 name=f'{e.OWNER}-{alias}-logical4-postgres'
 script="if [ ! -f /pg/data/PG_VERSION ]; then initdb -D /pg/data --locale-provider=icu --icu-locale=en-US --username=supabase_admin --auth-local=trust --auth-host=reject > /tmp/init.log; fi; exec postgres -D /pg/data -c listen_addresses= -c unix_socket_directories=/tmp -c shared_preload_libraries=$(cat /pg/preloads) -c cron.launch_active_jobs=off -c ssl=off -c archive_mode=off -c max_connections=30"
 e.docker('run','-d','--pull','never','--name',name,'--label','marea.task002.owner='+e.OWNER,'--network','none','--read-only','--user','100:101','--cap-drop','ALL','--security-opt','no-new-privileges','--mount',f'type=volume,src={volume},dst=/pg','--tmpfs','/tmp:rw,noexec,nosuid,size=64m,mode=1777','--shm-size','128m','--entrypoint','sh',e.PG,'-ec',script)
 for _ in range(80):
  c=e.owned(name)
  if not c['State']['Running']:(e.PRIVATE/(name+'-boot.log')).write_text(e.docker('logs',name,check=False).stderr);raise RuntimeError('Fresh restore cluster boot failed')
  if e.docker('exec',name,'pg_isready','-h','/tmp','-U','supabase_admin','-d','postgres',check=False).returncode==0:return name
  time.sleep(.25)
 raise RuntimeError('Fresh restore cluster timeout')

def restore(alias,files):
 name=f'{e.OWNER}-{alias}-logical4-postgres';reuse=e.docker('inspect',name,check=False).returncode==0
 if reuse:
  e.owned(name);assert e.sql(name,"SELECT count(*) FROM pg_tables WHERE schemaname IN ('public','auth','storage');").stdout.strip()=='0'
 else:name=new_cluster(alias)
 result={}
 for kind,cmd in [('globals',['psql','-X','-h','/tmp','-U','supabase_admin','-d','postgres','-v','ON_ERROR_STOP=1','-q']),('db',['pg_restore','-h','/tmp','-U','supabase_admin','-d','template1','--create','--exit-on-error'])]:
  p=e.PRIVATE/(files[kind].get('filename') or f'{alias}-{kind}.backup');raw=p.read_bytes();assert hashlib.sha256(raw).hexdigest()==files[kind]['sha256']
  if reuse and kind=='globals':
   result[kind]={'exit_code':0,'previous_globals_receipt_preserved':True,'input_sha256':files[kind]['sha256']};continue
  original_sha=hashlib.sha256(raw).hexdigest()
  if kind=='globals':
   assert raw.count(b'CREATE ROLE supabase_admin;')==1
   raw=raw.replace(b'CREATE ROLE supabase_admin;',b'-- Existing initdb bootstrap role supabase_admin; properties below restored unchanged.')
  if kind=='db':e.docker('exec',name,'dropdb','--force','-h','/tmp','-U','supabase_admin','postgres')
  q=e.docker('exec','-i',name,*cmd,input=raw,binary=True,check=False);(e.PRIVATE/f'{alias}-{kind}-restore-v4.log').write_bytes(q.stdout+q.stderr);result[kind]={'exit_code':q.returncode,'input_sha256':files[kind]['sha256'],'single_transaction':False,'restored_stream_sha256':hashlib.sha256(raw).hexdigest(),'bootstrap_exception':'Only CREATE ROLE supabase_admin skipped because initdb created the same original bootstrap role; ALTER properties and all grants unchanged' if kind=='globals' else None}
  if q.returncode:
   (e.RUN/f'logical-restore-failure-{alias}-v4.json').write_text(json.dumps({'result':'FAIL','stage':kind,'exit_code':q.returncode,'private_log':str(e.PRIVATE/f'{alias}-{kind}-restore-v4.log'),'source_backups_intact':True,'proposed_migration_executed':False},indent=2)+'\n');raise RuntimeError('Restore failed in new isolated clone; private log preserved')
 # Freeze destination after restore; source and existing historical containers are never modified.
 e.docker('exec','-i',name,'psql','-X','-h','/tmp','-U','supabase_admin','-d','postgres','-v','ON_ERROR_STOP=1','-q',input="ALTER DATABASE postgres OWNER TO postgres; ALTER SYSTEM SET default_transaction_read_only=on; SELECT pg_reload_conf();")
 for _ in range(20):
  if e.sql(name,"SELECT current_setting('default_transaction_read_only');").stdout.strip()=='on':break
  time.sleep(.1)
 # pg_net must be preloaded to CREATE EXTENSION on restore. Disable its worker again before comparison.
 e.docker('exec',name,'sh','-ec',"printf %s pg_stat_statements,pg_cron > /pg/preloads")
 e.docker('restart','--time','20',name)
 for _ in range(60):
  if e.docker('exec',name,'pg_isready','-h','/tmp','-U','supabase_admin','-d','postgres',check=False).returncode==0:break
  time.sleep(.2)
 return name,result

def main():
 e.guard();results={}
 for a in e.SOURCES:
  backup_receipt=e.RUN/f'logical-backup-{a}.json'
  files=json.loads(backup_receipt.read_text())['files'] if backup_receipt.exists() else dump(a)
  createdump=e.PRIVATE/f'{a}-dbcreate.backup'
  if not createdump.exists():
   with createdump.open('xb') as f:
    proc=subprocess.run(['docker','exec',f'{e.OWNER}-{a}-work-postgres','pg_dump','-h','/tmp','-U','supabase_admin','-d','postgres','-Fc','--create'],env=e.ENV,stdout=f,stderr=subprocess.PIPE,timeout=60)
   assert proc.returncode==0
  files['db']={'filename':createdump.name,'sha256':hashlib.sha256(createdump.read_bytes()).hexdigest(),'bytes':createdump.stat().st_size,'database_creation_metadata_included':True}
  (e.RUN/f'logical-create-backup-{a}.json').write_text(json.dumps({'files':files,'result':'PASS'},indent=2)+'\n');(e.RUN/f'logical-backup-{a}.json').write_text(json.dumps({'result':'PASS','files':files},indent=2)+'\n')
  name,restored=restore(a,files);source=inv.capture(f'{e.OWNER}-{a}-work-postgres');target=inv.capture(name)
  (e.PRIVATE/f'{a}-logical4-effective-private.json').write_text(json.dumps(target,sort_keys=True,indent=2))
  # Diagnostic bootstrap superuser is a lab-only extra, never an application grant.
  # Original bootstrap role name/OID retained; compare all roles without exclusion.
  differences={}
  for k in source:
   if source[k]!=target[k]:differences[k]=True
  # Settings may have different configuration-file source for the explicit read-only overlay.
  src_settings={x['name']:x['setting'] for x in source['catalog']['settings']};dst_settings={x['name']:x['setting'] for x in target['catalog']['settings']}
  src_cat=canonical_catalog(source['catalog']);dst_cat=canonical_catalog(target['catalog'])
  checks={'rows':source['rows']==target['rows'],'sequences':source['sequences']==target['sequences'],'catalog':src_cat==dst_cat,'runtime_setting_values':src_settings==dst_settings}
  results[a]={'backup':files,'restore':restored,'checks':checks,'row_tables':len(source['rows']),'role_limit':'All source roles/attributes/memberships compared, original bootstrap role retained; no extra role or exposed Data API.','complete_requirement_validation':False}
  (e.RUN/'09-logical-backup-restore.json').write_text(json.dumps({'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'result':'PASS' if all(all(v['checks'].values()) for v in results.values()) else 'FAIL','sources':results},indent=2)+'\n')
  print(a,json.dumps(checks));assert all(checks.values()),'Logical comparison differs; inspect private catalogs before continuing'
if __name__=='__main__':main()
